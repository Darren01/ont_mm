enrich_file_urls <- function(template_file,
                             input_dir,
                             data_dir,
                             output_dir,
                             file_path) {
  
  # ---------------- READ RAW ----------------
  lines <- readLines(file_path)
  
  # split into columns safely
  split_lines <- strsplit(lines, "\t", fixed = TRUE)
  
  # ensure all rows same length
  max_cols <- max(lengths(split_lines))
  
  split_lines <- lapply(split_lines, function(x) {
    length(x) <- max_cols
    x[is.na(x)] <- ""
    x
  })
  
  mat <- do.call(rbind, split_lines)
  
  # ---------------- COLUMN INDEX ----------------
  header <- mat[1, ]
  col_index <- function(name) which(header == name)
  
  id_col  <- col_index("ID")
  url_col <- col_index("fileURL")
  
  if (length(url_col) == 0) {
    stop("fileURL column not found")
  }
  
  # ---------------- URL HELPER ----------------
  make_url <- function(path) {
    if (!file.exists(path)) return("")
    paste0("file://", normalizePath(path, winslash = "/", mustWork = TRUE))
  }
  
  # ---------------- PROCESS ROWS ----------------
  for (i in 3:nrow(mat)) {
    
    id <- mat[i, id_col]
    
    if (id == "" || !grepl("^ex:file_", id)) next
    
    name <- sub("^ex:file_", "", id)
    name <- sub("_(inp|dat|log)$", "", name)
    
    if (grepl("_inp$", id)) {
      path <- file.path(input_dir, paste0(name, ".inp"))
    } else if (grepl("_dat$", id)) {
      path <- file.path(data_dir, paste0(name, ".dat"))
    } else if (grepl("_log$", id)) {
      path <- file.path(output_dir, paste0(name, ".log"))
    } else {
      next
    }
    
    mat[i, url_col] <- make_url(path)
  }
  
  # ---------------- WRITE BACK ----------------
  out_lines <- apply(mat, 1, function(x) paste(x, collapse = "\t"))
  
  writeLines(out_lines, file_path)
  
  cat("DONE:", file_path, "\n")
}