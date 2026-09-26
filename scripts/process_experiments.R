process_experiments <- function(
    template_file,
    input_dir,
    data_dir,
    output_dir,
    output_file,
    provenance_file = NULL
) {
  
  # =========================
  # Load template (2 rows only)
  # =========================
  
  template <- read.delim(
    template_file,
    header = FALSE,
    sep = "\t",
    stringsAsFactors = FALSE,
    fill = TRUE
  )
  
  header_row <- as.character(template[1, ])
  robot_row  <- as.character(template[2, ])
  
  n_cols <- length(header_row)
  
  # =========================
  # Build provenance map
  # =========================
  
  prov_map <- build_provenance(input_dir, provenance_file)
  
  # =========================
  # Helpers
  # =========================
  
  make_row <- function(...) {
    x <- c(...)
    length(x) <- n_cols   # enforce correct column count
    x[is.na(x)] <- ""
    x
  }
  
  make_url <- function(path) {
    if (file.exists(path)) {
      paste0("file:///", normalizePath(path, winslash = "/"))
    } else {
      ""
    }
  }

  # SHA-256 of the file's own real, current content - the point being
  # a genuine content fingerprint, not just a filename/path. Requires
  # the digest package (a standard, widely-used CRAN package for
  # exactly this, not something new or unusual). Returns "" if the
  # file doesn't exist, matching make_url()'s own behaviour above.
  make_hash <- function(path) {
    if (file.exists(path)) {
      digest::digest(path, file = TRUE, algo = "sha256")
    } else {
      ""
    }
  }
  
  # =========================
  # Files
  # =========================
  
  input_files <- list.files(input_dir, pattern = "\\.inp$", full.names = TRUE)
  input_files <- sort(input_files)
  
  rows <- list()
  idx <- 1
  
  # =========================
  # Add initial activity
  # =========================
  
  rows[[idx]] <- make_row(
    "ex:avogadro_build",
    "Structure built in Avogadro",
    "prov:Activity"
  )
  idx <- idx + 1
  
  # =========================
  # Main loop
  # =========================
  
  for (file in input_files) {
    
    name <- sub("\\.inp$", "", basename(file))
    
    exp_id   <- paste0("ex:exp_", name)
    input_id <- paste0("ex:file_", name, "_inp")
    data_id  <- paste0("ex:file_", name, "_dat")
    log_id   <- paste0("ex:file_", name, "_log")
    
    input_url <- make_url(file)
    data_url  <- make_url(file.path(data_dir, paste0(name, ".dat")))
    log_url   <- make_url(file.path(output_dir, paste0(name, ".log")))
    
    # provenance lookup
    prov_source <- prov_map$provWasGeneratedBy[
      prov_map$ID == input_id
    ]
    if (length(prov_source) == 0) prov_source <- ""
    
    # classify by RUNTYP/HSSEND rather than assuming every job is
    # a geometry optimisation
    classification <- classify_gamess_job(file)

    # Level of theory: method, basis set, solvent, and solvation model
    # as separate, structured fields for the graph itself (gc:hasMethod
    # etc), rather than only ever existing as a human-readable summary
    # string. Plus the raw RUNTYP/HSSEND classify_gamess_job() already
    # computes above - genuinely available all along, just never
    # written into the graph until now.
    #
    # Deliberately reads the .log file here, NOT the .inp file the
    # main loop variable itself points to: extract_level_of_theory_parts()
    # specifically looks for "INPUT CARD>" lines (GAMESS's own echo of
    # the input in its output), which only exist in the .log file -
    # confirmed directly: calling it with the raw .inp instead silently
    # returns NA for method/solvent/solvation_model (only basis_set
    # happens to still work, via a different parsing path).
    log_file_for_lot <- file.path(output_dir, paste0(name, ".log"))
    lot <- if (file.exists(log_file_for_lot)) {
      extract_level_of_theory_parts(log_file_for_lot)
    } else {
      list(method = NA, basis_set = NA, solvent = NA, solvation_model = NA)
    }
    hssend_str <- if (is.na(classification$hssend)) "" else tolower(as.character(classification$hssend))

    job_label <- switch(
      classification$job_type,
      "GeometryOptimization" = "Geometry optimisation",
      "SinglePoint"          = "Single point",
      "VibrationalAnalysis"  = "Vibrational analysis",
      "SaddlePoint"          = "Saddle point",
      "IRC"                  = paste0("IRC (", classification$irc_direction, ")"),
      "Unclassified job"
    )

    job_type_col <- if (is.na(classification$job_type)) {
      warning(
        "Could not classify ", name, " (RUNTYP=", classification$runtyp,
        ") - leaving Type blank for manual review"
      )
      ""
    } else {
      # gc: now that VibrationalAnalysis (and the hierarchy above it) has
      # been rebuilt into gc_core.ttl from gnvc_improved.owl - previously
      # this wrote "ex:X", which created a disconnected shadow class with
      # no relationship to the real GNVC-derived ontology
      paste0("gc:", classification$job_type)
    }

    # ---------- experiment ----------
    # hasInputFile: this experiment's own input file (correctly forward-
    # pointing now - previously always blank due to a column mismatch).
    # hasOutputFile: the files THIS experiment produced (data|log).
    rows[[idx]] <- make_row(
      exp_id,
      paste(job_label, name),
      job_type_col,
      input_id,
      paste(data_id, log_id, sep = "|"),
      "",
      "",
      "",   # sha256 - not applicable to the experiment itself, only to its files below
      lot$method,
      lot$basis_set,
      lot$solvent,
      lot$solvation_model,
      classification$runtyp,
      hssend_str
    )
    idx <- idx + 1
    
    # ---------- input ----------
    # wasGeneratedBy: the earlier activity/experiment that produced this
    # file (a real prov-o property, not a reuse of hasInputFile for the
    # opposite direction - that was the previous, confusing design).
    rows[[idx]] <- make_row(
      input_id,
      paste("Input file", name),
      "ex:InputFile",
      "",
      "",
      prov_source,
      input_url,
      make_hash(file)
    )
    idx <- idx + 1
    
    # ---------- data ----------
    rows[[idx]] <- make_row(
      data_id,
      paste("Output data", name),
      "ex:DataFile",
      "",
      "",
      exp_id,
      data_url,
      make_hash(file.path(data_dir, paste0(name, ".dat")))
    )
    idx <- idx + 1
    
    # ---------- log ----------
    rows[[idx]] <- make_row(
      log_id,
      paste("Output log", name),
      "ex:LogFile",
      "",
      "",
      exp_id,
      log_url,
      make_hash(file.path(output_dir, paste0(name, ".log")))
    )
    idx <- idx + 1
    
    # ---------- blank row ----------
    rows[[idx]] <- rep("", n_cols)
    idx <- idx + 1
  }
  
  # =========================
  # Combine safely
  # =========================
  
  data_matrix <- do.call(rbind, rows)
  
  out <- rbind(header_row, robot_row, data_matrix)
  
  # =========================
  # Write
  # =========================
  
  write.table(
    out,
    file = output_file,
    sep = "\t",
    row.names = FALSE,
    col.names = FALSE,
    quote = FALSE
  )
  
  cat("DONE:", output_file, "\n")
}
