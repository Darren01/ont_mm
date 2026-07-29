#' Build a queryable ontology graph from written instance data
#'
#' process_gamess_directory() (and the individual process_*() writers it
#' calls) only write instance TSV files - they don't turn those into an
#' actual queryable RDF graph. That gap has been closed by hand, one
#' `robot template` call per template plus a final `robot merge`, every
#' single round of this whole project. This automates that sequence.
#'
#' Only includes a template in the build if its _instances.tsv file
#' actually exists in ontology_dir - not every dataset will have every
#' result type (e.g. a dataset with no IRC data won't have
#' reaction_path_template_instances.tsv), and this shouldn't error on
#' that, just skip it and say so.
#'
#' Requires `robot` on your PATH - see
#' http://robot.obolibrary.org/ if you don't have it installed.
#'
#' @param ontology_dir Directory containing the *_template_instances.tsv
#'   files (what process_gamess_directory() and friends write to).
#' @param release_file Path to the base gc_core.ttl release to merge
#'   each template against (--merge-before --input).
#' @param output_file Path for the final merged graph.
#' @param robot_cmd Command to invoke robot (default "robot"; use
#'   "java -jar /path/to/robot.jar" if it's not on PATH).
#' @return Invisibly, a list: built (template names successfully turned
#'   into .ttl), skipped (template names with no instances file found).
#' @export
build_ontology_graph <- function(ontology_dir, release_file, output_file, robot_cmd = "robot") {

  if (!file.exists(release_file)) {
    stop("Release file not found: ", release_file)
  }

  # Every known template type, in a safe build order (though order
  # doesn't actually matter for --merge-before, since each is built
  # independently against the same release before the final merge).
  templates <- c(
    "experiment", "constraint", "results", "spectra_result", "spectra",
    "peak", "float_value", "energies", "reaction_path", "reaction_path_point",
    "molecule"
  )

  built <- character(0)
  skipped <- character(0)
  ttl_files <- character(0)

  for (t in templates) {
    instances_file <- file.path(ontology_dir, paste0(t, "_template_instances.tsv"))
    ttl_file <- file.path(ontology_dir, paste0(t, "_template.ttl"))

    if (!file.exists(instances_file)) {
      skipped <- c(skipped, t)
      next
    }

    args <- c(
      "template",
      "--template", instances_file,
      "--merge-before",
      "--input", release_file,
      "--ontology-iri", "http://purl.org/gc/core",
      "--prefix", shQuote("gc: http://purl.org/gc/"),
      "--prefix", shQuote("ex: http://example.org/"),
      "--output", ttl_file
    )
    if (t == "experiment") {
      args <- c(args, "--prefix", shQuote("prov: http://www.w3.org/ns/prov#"))
    }

    cat("Building", t, "...\n")
    result <- system2(robot_cmd, args, stdout = TRUE, stderr = TRUE)
    status <- attr(result, "status")

    if (!is.null(status) && status != 0) {
      warning("robot template failed for ", t, ":\n", paste(result, collapse = "\n"))
      next
    }

    built <- c(built, t)
    ttl_files <- c(ttl_files, ttl_file)
  }

  if (length(ttl_files) == 0) {
    stop("No templates were successfully built - nothing to merge. ",
         "Check that ontology_dir actually contains *_template_instances.tsv files.")
  }

  cat("\nMerging", length(ttl_files), "template(s) into final graph...\n")
  merge_args <- c("merge")
  for (f in ttl_files) {
    merge_args <- c(merge_args, "--input", f)
  }
  merge_args <- c(merge_args, "--output", output_file)

  merge_result <- system2(robot_cmd, merge_args, stdout = TRUE, stderr = TRUE)
  merge_status <- attr(merge_result, "status")
  if (!is.null(merge_status) && merge_status != 0) {
    stop("Final merge failed:\n", paste(merge_result, collapse = "\n"))
  }

  cat("\n=== Done ===\n")
  cat("Built:", if (length(built)) paste(built, collapse = ", ") else "(none)", "\n")
  cat("Skipped (no instance data found):", if (length(skipped)) paste(skipped, collapse = ", ") else "(none)", "\n")
  cat("Output graph:", output_file, "\n")

  invisible(list(built = built, skipped = skipped, output_file = output_file))
}
