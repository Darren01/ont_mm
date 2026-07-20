#' Generate spectra/peak/float-value template instance TSVs from GAMESS
#' log files' IR spectra
#'
#' Mirrors process_experiments.R / process_contraints.R's existing pattern:
#' append new rows to existing instance TSVs (if present), skipping any
#' already-processed experiment (keyed on spectrum ID) rather than
#' duplicating.
#'
#' @param experiment_log_pairs A named character vector: names are
#'   experiment IDs (e.g. "ex:exp_rem01b"), values are paths to the
#'   corresponding .log file.
#' @param output_dir Where to write/update the four instance TSVs.
process_results <- function(experiment_log_pairs, output_dir) {

  out_files <- list(
    spectra_result = file.path(output_dir, "spectra_result_template_instances.tsv"),
    spectra        = file.path(output_dir, "spectra_template_instances.tsv"),
    peaks          = file.path(output_dir, "peak_template_instances.tsv"),
    float_values   = file.path(output_dir, "float_value_template_instances.tsv")
  )

  headers <- list(
    spectra_result = c("ID", "Type", "hasResult"),
    spectra        = c("ID", "Label", "Type", "hasFrequencyPeak"),
    peaks          = c("ID", "Label", "Type", "hasFrequency", "hasIntensity"),
    float_values   = c("ID", "Label", "Type", "hasFloatValue", "hasUnit")
  )

  type_rows <- list(
    spectra_result = c("ID", "TYPE", "I gc:hasResult"),
    spectra        = c("ID", "LABEL", "TYPE", "I gc:hasFrequencyPeak SPLIT=|"),
    peaks          = c("ID", "LABEL", "TYPE", "I gc:hasFrequency", "I gc:hasIntensity"),
    float_values   = c("ID", "LABEL", "TYPE", "I gc:hasFloatValue", "I gc:hasUnit")
  )

  # accumulate rows across all experiments processed in this call
  all_rows <- list(spectra_result = list(), spectra = list(),
                    peaks = list(), float_values = list())

  skipped <- character(0)
  processed <- character(0)

  for (exp_id in names(experiment_log_pairs)) {
    log_file <- experiment_log_pairs[[exp_id]]

    # skip if this experiment's spectrum already exists in spectra_result output
    if (file.exists(out_files$spectra_result)) {
      existing <- readLines(out_files$spectra_result, warn = FALSE)
      if (any(grepl(paste0("^", exp_id, "\t"), existing))) {
        skipped <- c(skipped, exp_id)
        next
      }
    }

    # Report geometry quality - does NOT block writing. A "needs_refinement"
    # result is not invalid data; it's a normal intermediate step in a
    # longer optimisation chain (see check_vibrational_quality.R). Data
    # gets written either way; this just flags what the person running
    # the pipeline should do next.
    quality <- tryCatch(
      check_vibrational_quality(log_file),
      error = function(e) {
        warning("Could not check vibrational quality for ", exp_id, ": ", conditionMessage(e))
        NULL
      }
    )
    if (!is.null(quality) && !is.na(quality$status)) {
      cat(exp_id, ":", quality$message, "\n")
    }

    ir <- tryCatch(
      extract_ir_spectrum(log_file),
      error = function(e) {
        warning("Skipping ", exp_id, " (", log_file, "): ", conditionMessage(e))
        NULL
      }
    )
    if (is.null(ir)) next

    rows <- ir_spectrum_to_templates(ir, exp_id)
    for (nm in names(rows)) {
      all_rows[[nm]][[exp_id]] <- rows[[nm]]
    }
    processed <- c(processed, exp_id)
  }

  # write/append each template's accumulated rows
  for (nm in names(out_files)) {
    if (length(all_rows[[nm]]) == 0) next
    combined <- do.call(rbind, all_rows[[nm]])

    if (file.exists(out_files[[nm]])) {
      write.table(combined, out_files[[nm]], sep = "\t", row.names = FALSE,
                  col.names = FALSE, quote = FALSE, append = TRUE)
    } else {
      writeLines(paste(headers[[nm]], collapse = "\t"), out_files[[nm]])
      write(paste(type_rows[[nm]], collapse = "\t"), out_files[[nm]], append = TRUE)
      write.table(combined, out_files[[nm]], sep = "\t", row.names = FALSE,
                  col.names = FALSE, quote = FALSE, append = TRUE)
    }
  }

  cat("Processed:", if (length(processed)) paste(processed, collapse = ", ") else "(none)", "\n")
  cat("Skipped (already present):", if (length(skipped)) paste(skipped, collapse = ", ") else "(none)", "\n")

  invisible(list(processed = processed, skipped = skipped))
}
