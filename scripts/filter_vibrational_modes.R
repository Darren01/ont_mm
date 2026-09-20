#' Filter vibrational-mode data to only the diagnostically relevant modes
#'
#' A full vibrational analysis writes one peak (and its float-value
#' frequency/intensity) per 3N-6 mode into the TSVs
#' process_results()/ir_spectrum_to_templates() build - most of which
#' are neither queried nor individually meaningful (see
#' COMPETENCY_QUESTIONS.md's own scoping principle). This function
#' rewrites spectra/peak/float_value_template_instances.tsv in place,
#' keeping only the modes identify_diagnostic_modes() identifies as
#' worth keeping - any imaginary frequency, or GAMESS's own
#' translation/rotation modes - for every experiment already present.
#'
#' Deliberately its own, separate, explicit step - called after
#' process_gamess_directory() but before build_ontology_graph() - the
#' same visible, inspectable pattern as notes_to_annotations(), rather
#' than silently folded into the graph build itself. This is a
#' destructive, one-way filter (removed rows are genuinely gone from
#' these TSVs, though the original .log file remains the real source
#' of truth and is unaffected).
#'
#' @param ontology_dir Directory holding the three instance TSVs.
#' @param output_dir Directory holding the real .log files, needed to
#'   re-derive each experiment's own diagnostic modes.
#' @return Invisibly, a list: processed (experiment names filtered),
#'   skipped (experiments whose .log file couldn't be found or
#'   diagnosed - not silently dropped, reported), peaks_before,
#'   peaks_after (total peak-row counts across all experiments, for a
#'   quick sanity check on how much this actually removed).
#' @export
filter_vibrational_modes <- function(ontology_dir, output_dir) {

  spectra_file <- file.path(ontology_dir, "spectra_template_instances.tsv")
  peak_file    <- file.path(ontology_dir, "peak_template_instances.tsv")
  float_file   <- file.path(ontology_dir, "float_value_template_instances.tsv")

  # Read as raw lines, not read.delim() - these files' second line is
  # itself a robot-template header row (e.g. "ID  LABEL  TYPE  I
  # gc:hasFrequencyPeak SPLIT=|"), not data, and needs to be preserved
  # verbatim rather than parsed.
  spectra_lines <- readLines(spectra_file, warn = FALSE)
  peak_lines    <- readLines(peak_file, warn = FALSE)
  float_lines   <- readLines(float_file, warn = FALSE)

  spectra_header <- spectra_lines[1:2]
  peak_header    <- peak_lines[1:2]
  float_header   <- float_lines[1:2]

  spectra_data <- spectra_lines[-(1:2)]
  peak_data    <- peak_lines[-(1:2)]
  float_data   <- float_lines[-(1:2)]

  peaks_before <- length(peak_data)

  kept_peak_ids <- character(0)
  processed <- character(0)
  skipped <- character(0)
  new_spectra_data <- character(0)

  for (line in spectra_data) {
    if (nchar(trimws(line)) == 0) next
    fields <- strsplit(line, "\t", fixed = TRUE)[[1]]
    spectrum_id <- fields[1]

    exp_name <- sub("^ex:spectrum_", "", spectrum_id)
    log_file <- file.path(output_dir, paste0(exp_name, ".log"))

    diag <- tryCatch(
      identify_diagnostic_modes(log_file),
      error = function(e) {
        warning("Could not identify diagnostic modes for ", exp_name, ": ", conditionMessage(e))
        NULL
      }
    )

    if (is.null(diag)) {
      skipped <- c(skipped, exp_name)
      new_spectra_data <- c(new_spectra_data, line)
      next
    }

    peak_ids <- strsplit(fields[4], "|", fixed = TRUE)[[1]]
    peak_indices <- as.integer(sub(".*_(\\d+)$", "\\1", peak_ids))

    keep_mask <- peak_indices %in% diag$keep_modes
    kept_ids_this_exp <- peak_ids[keep_mask]

    kept_peak_ids <- c(kept_peak_ids, kept_ids_this_exp)
    processed <- c(processed, exp_name)

    fields[4] <- paste(kept_ids_this_exp, collapse = "|")
    new_spectra_data <- c(new_spectra_data, paste(fields, collapse = "\t"))
  }

  kept_peak_ids_set <- unique(kept_peak_ids)

  # ---- filter peaks, tracking which float values they still need ----
  needed_float_ids <- character(0)
  new_peak_data <- character(0)

  for (line in peak_data) {
    if (nchar(trimws(line)) == 0) next
    fields <- strsplit(line, "\t", fixed = TRUE)[[1]]
    peak_id <- fields[1]

    if (peak_id %in% kept_peak_ids_set) {
      new_peak_data <- c(new_peak_data, line)
      needed_float_ids <- c(needed_float_ids, fields[4], fields[5])  # hasFrequency, hasIntensity
    }
  }

  needed_float_ids_set <- unique(needed_float_ids)

  # ---- filter float values ----
  new_float_data <- character(0)
  for (line in float_data) {
    if (nchar(trimws(line)) == 0) next
    fields <- strsplit(line, "\t", fixed = TRUE)[[1]]
    float_id <- fields[1]

    if (float_id %in% needed_float_ids_set) {
      new_float_data <- c(new_float_data, line)
    }
  }

  writeLines(c(spectra_header, new_spectra_data), spectra_file)
  writeLines(c(peak_header, new_peak_data), peak_file)
  writeLines(c(float_header, new_float_data), float_file)

  cat("Processed:", if (length(processed)) paste(processed, collapse = ", ") else "(none)", "\n")
  cat("Skipped (log file not found or diagnostics failed):",
      if (length(skipped)) paste(skipped, collapse = ", ") else "(none)", "\n")
  cat("Peak rows:", peaks_before, "->", length(new_peak_data),
      sprintf("(%.0f%% reduction)", 100 * (1 - length(new_peak_data) / peaks_before)), "\n")

  invisible(list(
    processed = processed,
    skipped = skipped,
    peaks_before = peaks_before,
    peaks_after = length(new_peak_data)
  ))
}
