#' Process a whole directory of GAMESS jobs into the instantiated ontology
#'
#' Classifies every .log file, routes each experiment to the correct
#' writer(s) based on job type (and HSSEND for SaddlePoint), pairs IRC
#' forward/backward runs automatically, and runs constraint extraction
#' over every .inp file - all in one call, all landing in the same
#' instance data files.
#'
#' Routing rules (confirmed against real usage, not assumed):
#'   - VibrationalAnalysis, or SaddlePoint with HSSEND=.t.: frequency +
#'     thermochemistry writers. A SaddlePoint job only computes credible
#'     frequency/thermochemistry data if HSSEND=.t. was actually set -
#'     without it, the user wasn't expecting a credible result from that
#'     stage, just a stepping stone geometry for the next job.
#'   - SinglePoint: electronic energy writer.
#'   - GeometryOptimization, or SaddlePoint without HSSEND=.t.:
#'     experiment row only - no result writer. The geometry is only
#'     used as input to the next job, not as an ontology-facing result
#'     in its own right.
#'   - IRC: paired by classify_gamess_job()'s own detected direction
#'     (from the real FORWRD value in each file), NOT by filename -
#'     filenames can have typos (confirmed: this exact dataset had two).
#'     Files are grouped into candidate pairs by filename (stripping a
#'     trailing IRC direction suffix - the best available signal for
#'     WHICH two files belong together, since nothing else identifies
#'     that), but the actual forward/backward labelling within each
#'     pair always comes from the code-detected direction. A group that
#'     doesn't resolve to exactly one forward + one backward file is
#'     warned about and skipped, not guessed at.
#'   - Constraints: extracted from every .inp file found, regardless of
#'     job type, since constraint data belongs in the same instantiated
#'     ontology as everything else.
#'
#' @param input_dir Directory containing .inp files.
#' @param output_dir Directory containing .log files.
#' @param ontology_dir Where to write/append the instance TSVs.
#' @param experiment_template_file Path to the 2-row experiment template
#'   schema file, passed through to process_experiments().
#' @param data_dir Directory containing .dat files (for process_experiments()'s
#'   provenance tracking). Defaults to output_dir.
#' @param provenance_file Optional, passed through to process_experiments().
#' @return Invisibly, a list summarising what was processed under each
#'   category, and any IRC pairing issues found.
#' @export
process_gamess_directory <- function(input_dir, output_dir, ontology_dir,
                                      experiment_template_file,
                                      data_dir = output_dir,
                                      provenance_file = NULL) {

  summary <- list(
    geometry_optimization = character(0),
    single_point = character(0),
    vibrational = character(0),
    saddle_point_no_hessian = character(0),
    irc_pairs = character(0),
    irc_unpaired = character(0),
    unclassified = character(0)
  )

  # =========================================================
  # 1. Experiment rows for every .inp file (existing function)
  # =========================================================
  cat("=== Writing experiment rows ===\n")
  process_experiments(
    template_file = experiment_template_file,
    input_dir = input_dir,
    data_dir = data_dir,
    output_dir = output_dir,
    output_file = file.path(ontology_dir, "experiment_template_instances.tsv"),
    provenance_file = provenance_file
  )

  # =========================================================
  # 2. Classify every .log file
  # =========================================================
  cat("\n=== Classifying output logs ===\n")
  classified <- classify_gamess_jobs(output_dir, pattern = "\\.log$")

  if (nrow(classified) == 0) {
    warning("No .log files found in ", output_dir)
    return(invisible(summary))
  }

  classified$stem <- sub("\\.log$", "", basename(classified$file))
  classified$experiment_id <- paste0("ex:exp_", classified$stem)

  # =========================================================
  # 3. Route non-IRC experiments
  # =========================================================
  vib_like <- classified[
    !is.na(classified$job_type) &
    (classified$job_type == "VibrationalAnalysis" |
     (classified$job_type == "SaddlePoint" & classified$hssend %in% TRUE)), ]

  if (nrow(vib_like) > 0) {
    cat("\n=== Frequency + thermochemistry (", nrow(vib_like), " experiments) ===\n", sep = "")
    log_pairs <- setNames(vib_like$file, vib_like$experiment_id)
    process_results(log_pairs, output_dir = ontology_dir)
    process_thermo_results(log_pairs, output_dir = ontology_dir)
    summary$vibrational <- vib_like$experiment_id
  }

  single_point <- classified[!is.na(classified$job_type) & classified$job_type == "SinglePoint", ]
  if (nrow(single_point) > 0) {
    cat("\n=== Electronic energy (", nrow(single_point), " experiments) ===\n", sep = "")
    log_pairs <- setNames(single_point$file, single_point$experiment_id)
    process_electronic_energy_results(log_pairs, output_dir = ontology_dir)
    summary$single_point <- single_point$experiment_id
  }

  geom_only <- classified[!is.na(classified$job_type) & classified$job_type == "GeometryOptimization", ]
  summary$geometry_optimization <- geom_only$experiment_id

  saddle_no_hess <- classified[
    !is.na(classified$job_type) & classified$job_type == "SaddlePoint" & !(classified$hssend %in% TRUE), ]
  summary$saddle_point_no_hessian <- saddle_no_hess$experiment_id

  unclassified <- classified[is.na(classified$job_type), ]
  summary$unclassified <- unclassified$file

  # =========================================================
  # 4. IRC pairing
  # =========================================================
  irc_rows <- classified[!is.na(classified$job_type) & classified$job_type == "IRC", ]

  if (nrow(irc_rows) > 0) {
    cat("\n=== Pairing IRC runs (", nrow(irc_rows), " IRC files found) ===\n", sep = "")

    # Candidate grouping by filename - strips a trailing single f/b
    # before .log. This identifies WHICH files likely belong together
    # (the best available signal for that), but does NOT determine
    # direction - that always comes from classify_gamess_job()'s own
    # detected FORWRD value, checked below.
    irc_rows$candidate_base <- sub("[FfBb]\\.log$", "", basename(irc_rows$file))

    groups <- split(irc_rows, irc_rows$candidate_base)

    reactions <- list()
    for (base in names(groups)) {
      g <- groups[[base]]

      if (nrow(g) != 2) {
        warning("IRC group '", base, "' has ", nrow(g), " file(s), not 2 - skipping: ",
                paste(basename(g$file), collapse = ", "))
        summary$irc_unpaired <- c(summary$irc_unpaired, g$experiment_id)
        next
      }

      fwd <- g[g$irc_direction == "forward", ]
      bwd <- g[g$irc_direction == "backward", ]

      if (nrow(fwd) != 1 || nrow(bwd) != 1) {
        warning("IRC group '", base, "' doesn't resolve to exactly one forward + ",
                "one backward file by their own detected FORWRD values (found ",
                nrow(fwd), " forward, ", nrow(bwd), " backward) - skipping: ",
                paste(basename(g$file), collapse = ", "))
        summary$irc_unpaired <- c(summary$irc_unpaired, g$experiment_id)
        next
      }

      reactions[[base]] <- data.frame(
        forward_id = fwd$experiment_id, forward_log = fwd$file,
        backward_id = bwd$experiment_id, backward_log = bwd$file,
        stringsAsFactors = FALSE
      )
      summary$irc_pairs <- c(summary$irc_pairs, base)
    }

    if (length(reactions) > 0) {
      reactions_df <- do.call(rbind, reactions)
      process_reaction_path_results(reactions_df, output_dir = ontology_dir)
    }
  }

  # =========================================================
  # 5. Constraints - every .inp file, regardless of job type
  # =========================================================
  cat("\n=== Constraints ===\n")
  inp_files <- list.files(input_dir, pattern = "\\.inp$", full.names = TRUE)
  if (length(inp_files) > 0) {
    stems <- sub("\\.inp$", "", basename(inp_files))
    exp_ids <- paste0("ex:exp_", stems)
    experiment_files <- setNames(inp_files, exp_ids)
    process_contraints(experiment_files, file.path(ontology_dir, "constraint_template_instances.tsv"))
  }

  # =========================================================
  # 6. Summary
  # =========================================================
  cat("\n=== Summary ===\n")
  cat("Geometry optimisation (no result writer):", length(summary$geometry_optimization), "\n")
  cat("Single point:", length(summary$single_point), "\n")
  cat("Vibrational analysis / SaddlePoint+HSSEND (frequency + thermochemistry):", length(summary$vibrational), "\n")
  cat("SaddlePoint without HSSEND (no result writer):", length(summary$saddle_point_no_hessian), "\n")
  cat("IRC pairs successfully matched:", length(summary$irc_pairs), "\n")
  if (length(summary$irc_unpaired) > 0) {
    cat("IRC files NOT successfully paired (see warnings above):", length(summary$irc_unpaired), "\n")
  }
  if (length(summary$unclassified) > 0) {
    cat("Unclassified files (see warnings above):", length(summary$unclassified), "\n")
  }

  invisible(summary)
}
