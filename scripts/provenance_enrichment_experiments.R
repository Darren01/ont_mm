enrich_provenance <- function(input_dir,
                              file_path,
                              provenance_file = NULL) {
  
  # ---------------- READ RAW ----------------
  lines <- readLines(file_path, warn = FALSE)
  
  split_lines <- strsplit(lines, "\t", fixed = TRUE)
  
  max_cols <- max(sapply(split_lines, length))
  
  # 🔒 FORCE RECTANGULAR MATRIX
  mat <- matrix("", nrow = length(split_lines), ncol = max_cols)
  
  for (i in seq_along(split_lines)) {
    row <- split_lines[[i]]
    mat[i, seq_along(row)] <- row
  }
  
  # ---------------- HEADER ----------------
  header <- trimws(mat[1, ])
  
  if (!"ID" %in% header) {
    stop("Header broken: ID column not found")
  }
  
  # ---------------- ENSURE PROVENANCE COLUMN ----------------
  if (!"provWasGeneratedBy" %in% header) {
    
    type_col <- which(header == "Type")
    insert_pos <- type_col + 1
    
    # expand matrix safely
    new_mat <- matrix("", nrow = nrow(mat), ncol = ncol(mat) + 1)
    
    new_mat[, 1:type_col] <- mat[, 1:type_col]
    new_mat[, insert_pos] <- ""
    new_mat[, (insert_pos + 1):ncol(new_mat)] <- mat[, (type_col + 1):ncol(mat)]
    
    mat <- new_mat
    
    # fix header rows
    mat[1, insert_pos] <- "provWasGeneratedBy"
    mat[2, insert_pos] <- "I prov:wasGeneratedBy"
    
    header <- mat[1, ]
  }
  
  # ---------------- COLUMN INDEX ----------------
  id_col   <- which(header == "ID")
  prov_col <- which(header == "provWasGeneratedBy")
  
  # ---------------- BUILD PROVENANCE ----------------
  prov_map <- build_provenance(input_dir, provenance_file)
  
  # ---------------- APPLY ----------------
  for (i in 3:nrow(mat)) {
    
    id <- mat[i, id_col]
    
    if (id == "" || !grepl("^ex:file_", id)) next
    
    match <- prov_map$provWasGeneratedBy[
      prov_map$ID == id
    ]
    
    if (length(match) > 0) {
      mat[i, prov_col] <- match[1]
    }
  }
  
  # ---------------- WRITE BACK ----------------
  out_lines <- apply(mat, 1, function(x) {
    paste(x, collapse = "\t")
  })
  
  writeLines(out_lines, file_path)
  
  cat("DONE:", file_path, "\n")
}