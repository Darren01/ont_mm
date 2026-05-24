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
    
    # ---------- experiment ----------
    rows[[idx]] <- make_row(
      exp_id,
      paste("Geometry optimisation", name),
      "ex:GeometryOptimization",
      "",
      input_id,
      paste(data_id, log_id, sep = "|"),
      ""
    )
    idx <- idx + 1
    
    # ---------- input ----------
    rows[[idx]] <- make_row(
      input_id,
      paste("Input file", name),
      "ex:InputFile",
      prov_source,
      "",
      "",
      input_url
    )
    idx <- idx + 1
    
    # ---------- data ----------
    rows[[idx]] <- make_row(
      data_id,
      paste("Output data", name),
      "ex:DataFile",
      exp_id,
      "",
      "",
      data_url
    )
    idx <- idx + 1
    
    # ---------- log ----------
    rows[[idx]] <- make_row(
      log_id,
      paste("Output log", name),
      "ex:LogFile",
      exp_id,
      "",
      "",
      log_url
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