#' Generate energies/float-value template instance TSVs from GAMESS
#' log files' single-point electronic energies
#'
#' Mirrors process_thermo_results.R's pattern. Dedup here is simpler
#' than thermochemistry's: SinglePoint (RUNTYP=ENERGY) and
#' VibrationalAnalysis (RUNTYP=OPTIMIZE+HSSEND) are mutually exclusive
#' job types, so a given experiment can never need both an electronic-
#' energy-only SystemEnergies row and a thermochemistry one - checking
#' whether energies_<stem> already exists at all is sufficient, unlike
#' process_thermo_results.R which has to be more careful because
#' spectra_result is shared with the frequency writer.
#'
#' @param experiment_log_pairs A named character vector: names are
#'   experiment IDs (e.g. "ex:exp_sp01"), values are paths to the
#'   corresponding .log file.
#' @param output_dir Where to write/update the instance TSVs.
process_electronic_energy_results <- function(experiment_log_pairs, output_dir) {

  out_files <- list(
    spectra_result = file.path(output_dir, "spectra_result_template_instances.tsv"),
    energies       = file.path(output_dir, "energies_template_instances.tsv"),
    float_values   = file.path(output_dir, "float_value_template_instances.tsv")
  )

  headers <- list(
    spectra_result = c("ID", "Type", "hasResult"),
    energies       = c("ID", "Label", "Type", "hasZeroPointEnergy", "hasEnthalpy", "hasEntropy", "hasGibbsFreeEnergy", "hasElectronicEnergy"),
    float_values   = c("ID", "Label", "Type", "hasFloatValue", "hasUnit")
  )

  type_rows <- list(
    spectra_result = c("ID", "TYPE", "I gc:hasResult"),
    energies       = c("ID", "LABEL", "TYPE", "I gc:hasZeroPointEnergy", "I gc:hasEnthalpy", "I gc:hasEntropy", "I gc:hasGibbsFreeEnergy", "I gc:hasElectronicEnergy"),
    float_values   = c("ID", "LABEL", "TYPE", "I gc:hasFloatValue", "I gc:hasUnit")
  )

  all_rows <- list(spectra_result = list(), energies = list(), float_values = list())

  skipped <- character(0)
  processed <- character(0)

  for (exp_id in names(experiment_log_pairs)) {
    log_file <- experiment_log_pairs[[exp_id]]
    stem <- sub("^ex:exp_", "", exp_id)
    energies_id <- paste0("ex:energies_", stem)

    if (file.exists(out_files$energies)) {
      existing <- readLines(out_files$energies, warn = FALSE)
      if (any(grepl(paste0("^", energies_id, "\t"), existing))) {
        skipped <- c(skipped, exp_id)
        next
      }
    }

    energy_result <- tryCatch(
      extract_electronic_energy(log_file),
      error = function(e) {
        warning("Skipping ", exp_id, " (", log_file, "): ", conditionMessage(e))
        NULL
      }
    )
    if (is.null(energy_result)) next

    if (energy_result$n_scf_convergences > 1) {
      warning(exp_id, ": ", energy_result$n_scf_convergences,
              " SCF convergences found - this doesn't look like a genuine ",
              "single-point job. Writing the last one's energy anyway, but ",
              "double-check this experiment's classification.")
    }

    rows <- electronic_energy_to_templates(energy_result, exp_id, stem)
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
