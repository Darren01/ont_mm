#' Generate constraint_template_instances.tsv from GAMESS .inp files
#'
#' Thin orchestration layer - the actual parsing (extract_constraints())
#' and ontology mapping (constraints_to_templates()) now live in
#' gamess_functions, where GAMESS file parsing belongs. This script's
#' job is purely: match each .inp file to its correct experiment ID,
#' dedup against what's already written, and write the file.
#'
#' Previously this had its own embedded copy of the $ZMAT/IFZMAT parsing
#' logic, duplicated from (and inconsistent with) the rest of the
#' pipeline - flagged as an architectural gap from very early in this
#' project. Moving it also fixed a real, live bug: the old
#' get_experiment_id() derived "ex:rem01" from "rem01.inp" (stripping
#' everything from the first "."), which doesn't match "ex:exp_rem01" -
#' the ID convention used by process_experiments.R and everything built
#' on top of it. Run today, the old code would have silently linked
#' constraints to a disconnected, wrong individual. This version takes
#' experiment IDs explicitly rather than re-deriving them, so that bug
#' class can't recur here.
#'
#' @param experiment_files A named character vector: names are
#'   experiment IDs (e.g. "ex:exp_rem01b"), values are paths to the
#'   corresponding .inp file.
#' @param output_file Path to constraint_template_instances.tsv.
#' @return Invisibly, a list: processed, skipped (experiment IDs).
process_contraints <- function(experiment_files, output_file) {

  header   <- c("ID", "Label", "Type", "hasConstraint", "involvesAtom1",
                "involvesAtom2", "involvesAtom3", "involvesAtom4",
                "targetValue", "hasUnit", "constraintMode", "forceConstant")
  type_row <- c("ID", "LABEL", "TYPE", "I ex:hasConstraint", "I ex:involvesAtom1",
                "I ex:involvesAtom2", "I ex:involvesAtom3", "I ex:involvesAtom4",
                "A ex:targetValue", "I gc:hasUnit", "A gc:constraintMode", "A ex:forceConstant")

  existing_ids <- character(0)
  if (file.exists(output_file)) {
    existing <- readLines(output_file, warn = FALSE)
    # constraint rows start with "ex:constraint_"; existing IDs of that
    # form tell us which experiments already have constraints written
    existing_ids <- unique(sub("^(ex:constraint_[^\t]+).*", "\\1", grep("^ex:constraint_", existing, value = TRUE)))
  }

  all_rows <- list()
  processed <- character(0)
  skipped <- character(0)

  for (exp_id in names(experiment_files)) {
    file <- experiment_files[[exp_id]]
    stem <- sub("^ex:exp_", "", exp_id)

    already_present <- any(grepl(paste0("^ex:constraint_", stem, "_"), existing_ids))
    if (already_present) {
      skipped <- c(skipped, exp_id)
      next
    }

    constraints <- tryCatch(
      extract_constraints(file),
      error = function(e) {
        warning("Skipping ", exp_id, " (", file, "): ", conditionMessage(e))
        NULL
      }
    )
    if (is.null(constraints) || nrow(constraints) == 0) next

    rows <- constraints_to_templates(constraints, exp_id)
    all_rows[[exp_id]] <- rows
    processed <- c(processed, exp_id)
  }

  if (length(all_rows) > 0) {
    combined <- do.call(rbind, all_rows)

    if (file.exists(output_file)) {
      write.table(combined, output_file, sep = "\t", row.names = FALSE,
                  col.names = FALSE, quote = FALSE, append = TRUE)
    } else {
      writeLines(paste(header, collapse = "\t"), output_file)
      write(paste(type_row, collapse = "\t"), output_file, append = TRUE)
      write.table(combined, output_file, sep = "\t", row.names = FALSE,
                  col.names = FALSE, quote = FALSE, append = TRUE)
    }
  }

  cat("Processed:", if (length(processed)) paste(processed, collapse = ", ") else "(none)", "\n")
  cat("Skipped (already present):", if (length(skipped)) paste(skipped, collapse = ", ") else "(none)", "\n")

  invisible(list(processed = processed, skipped = skipped))
}
