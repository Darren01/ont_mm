#' Generate energies/float-value template instance TSVs from GAMESS
#' log files' thermochemistry data
#'
#' Mirrors process_results.R's pattern, with one important difference:
#' process_results() dedups by checking whether the experiment ID already
#' has ANY row in spectra_result_template_instances.tsv. That file is
#' now shared across result types (frequency work already writes to it),
#' so reusing that same check here would wrongly skip an experiment's
#' thermochemistry just because its frequency result was already
#' processed - a real experiment (e.g. rem01b, HSSEND=.t.) legitimately
#' needs BOTH a VibrationalSpectra result AND a SystemEnergies result,
#' as two separate hasResult rows (hasResult is not FunctionalProperty -
#' confirmed against source/gnvc_improved.owl before writing this).
#'
#' So dedup here checks energies_template_instances.tsv specifically -
#' a file that only ever contains SystemEnergies rows - rather than the
#' shared spectra_result file.
#'
#' @param experiment_log_pairs A named character vector: names are
#'   experiment IDs (e.g. "ex:exp_rem01b"), values are paths to the
#'   corresponding .log file.
#' @param output_dir Where to write/update the instance TSVs.
process_thermo_results <- function(experiment_log_pairs, output_dir) {

  out_files <- list(
    spectra_result = file.path(output_dir, "spectra_result_template_instances.tsv"),
    energies       = file.path(output_dir, "energies_template_instances.tsv"),
    float_values   = file.path(output_dir, "float_value_template_instances.tsv")
  )

  headers <- list(
    spectra_result = c("ID", "Type", "hasResult"),
    energies       = c("ID", "Label", "Type", "hasZeroPointEnergy", "hasEnthalpy", "hasEntropy", "hasGibbsFreeEnergy"),
    float_values   = c("ID", "Label", "Type", "hasFloatValue", "hasUnit")
  )

  type_rows <- list(
    spectra_result = c("ID", "TYPE", "I gc:hasResult"),
    energies       = c("ID", "LABEL", "TYPE", "I gc:hasZeroPointEnergy", "I gc:hasEnthalpy", "I gc:hasEntropy", "I gc:hasGibbsFreeEnergy"),
    float_values   = c("ID", "LABEL", "TYPE", "I gc:hasFloatValue", "I gc:hasUnit")
  )

  all_rows <- list(spectra_result = list(), energies = list(), float_values = list())

  skipped <- character(0)
  processed <- character(0)

  for (exp_id in names(experiment_log_pairs)) {
    log_file <- experiment_log_pairs[[exp_id]]
    label_suffix <- sub("^ex:exp_", "", exp_id)
    energies_id <- paste0("ex:energies_", label_suffix)

    # dedup against the energies-specific file, NOT spectra_result
    # (shared across result types - see docstring above)
    if (file.exists(out_files$energies)) {
      existing <- readLines(out_files$energies, warn = FALSE)
      if (any(grepl(paste0("^", energies_id, "\t"), existing))) {
        skipped <- c(skipped, exp_id)
        next
      }
    }

    thermo <- tryCatch(
      extract_thermochemistry(log_file),
      error = function(e) {
        warning("Skipping ", exp_id, " (", log_file, "): ", conditionMessage(e))
        NULL
      }
    )
    if (is.null(thermo)) next

    if (all(is.na(thermo[c("zpe", "enthalpy", "gibbs", "entropy")]))) {
      warning("Skipping ", exp_id, " - no thermochemistry data found in ", log_file,
              " (not a frequency/Hessian job, or GAMESS didn't complete that stage)")
      next
    }

    rows <- thermochemistry_to_templates(thermo, exp_id, label_suffix)
    for (nm in names(rows)) {
      all_rows[[nm]][[exp_id]] <- rows[[nm]]
    }
    processed <- c(processed, exp_id)
  }

  for (nm in names(out_files)) {
    if (length(all_rows[[nm]]) == 0) next
    combined <- do.call(rbind, all_rows[[nm]])
    if (nrow(combined) == 0) next

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
