#' Generate reaction-path template instance TSVs from matched forward/
#' backward GAMESS IRC logs
#'
#' Mirrors process_results.R/process_thermo_results.R's pattern. Dedups
#' against reaction_path_template_instances.tsv specifically (not the
#' shared spectra_result file) - same reasoning as
#' process_thermo_results.R: spectra_result is shared across every
#' writer, so checking it alone would wrongly skip a reaction whose
#' forward/backward experiments already have some other result recorded.
#'
#' @param reactions A data.frame with columns: forward_id, forward_log,
#'   backward_id, backward_log (one row per reaction/transition state).
#' @param output_dir Where to write/update the instance TSVs.
process_reaction_path_results <- function(reactions, output_dir) {

  out_files <- list(
    spectra_result       = file.path(output_dir, "spectra_result_template_instances.tsv"),
    reaction_path        = file.path(output_dir, "reaction_path_template_instances.tsv"),
    reaction_path_points = file.path(output_dir, "reaction_path_point_template_instances.tsv"),
    float_values         = file.path(output_dir, "float_value_template_instances.tsv")
  )

  headers <- list(
    spectra_result       = c("ID", "Type", "hasResult"),
    reaction_path         = c("ID", "Label", "Type", "hasReactionPathPoint"),
    reaction_path_points  = c("ID", "Label", "Type", "hasIndex", "hasPathEnergy"),
    float_values          = c("ID", "Label", "Type", "hasFloatValue", "hasUnit")
  )

  type_rows <- list(
    spectra_result       = c("ID", "TYPE", "I gc:hasResult"),
    reaction_path         = c("ID", "LABEL", "TYPE", "I gc:hasReactionPathPoint SPLIT=|"),
    reaction_path_points  = c("ID", "LABEL", "TYPE", "I gc:hasIndex", "I gc:hasPathEnergy"),
    float_values          = c("ID", "LABEL", "TYPE", "I gc:hasFloatValue", "I gc:hasUnit")
  )

  all_rows <- list(spectra_result = list(), reaction_path = list(),
                    reaction_path_points = list(), float_values = list())

  skipped <- character(0)
  processed <- character(0)

  for (i in seq_len(nrow(reactions))) {
    forward_id    <- reactions$forward_id[i]
    forward_log   <- reactions$forward_log[i]
    backward_id   <- reactions$backward_id[i]
    backward_log  <- reactions$backward_log[i]
    label_suffix  <- sub("^ex:exp_", "", forward_id)
    reactionpath_id <- paste0("ex:reactionpath_", label_suffix)

    # dedup against the reaction-path-specific file, NOT spectra_result
    if (file.exists(out_files$reaction_path)) {
      existing <- readLines(out_files$reaction_path, warn = FALSE)
      if (any(grepl(paste0("^", reactionpath_id, "\t"), existing))) {
        skipped <- c(skipped, reactionpath_id)
        next
      }
    }

    combined <- tryCatch(
      combine_irc_trajectories(forward_log, backward_log),
      error = function(e) {
        warning("Skipping ", reactionpath_id, ": ", conditionMessage(e))
        NULL
      }
    )
    if (is.null(combined)) next

    rows <- reaction_path_to_templates(combined, forward_id, backward_id, label_suffix)
    for (nm in names(rows)) {
      all_rows[[nm]][[reactionpath_id]] <- rows[[nm]]
    }
    processed <- c(processed, reactionpath_id)
  }

  for (nm in names(out_files)) {
    if (length(all_rows[[nm]]) == 0) next
    combined_rows <- do.call(rbind, all_rows[[nm]])
    if (nrow(combined_rows) == 0) next

    if (file.exists(out_files[[nm]])) {
      write.table(combined_rows, out_files[[nm]], sep = "\t", row.names = FALSE,
                  col.names = FALSE, quote = FALSE, append = TRUE)
    } else {
      writeLines(paste(headers[[nm]], collapse = "\t"), out_files[[nm]])
      write(paste(type_rows[[nm]], collapse = "\t"), out_files[[nm]], append = TRUE)
      write.table(combined_rows, out_files[[nm]], sep = "\t", row.names = FALSE,
                  col.names = FALSE, quote = FALSE, append = TRUE)
    }
  }

  cat("Processed:", if (length(processed)) paste(processed, collapse = ", ") else "(none)", "\n")
  cat("Skipped (already present):", if (length(skipped)) paste(skipped, collapse = ", ") else "(none)", "\n")

  invisible(list(processed = processed, skipped = skipped))
}
