build_provenance <- function(input_dir, provenance_file = NULL) {
  
  # -------------------------
  # Gather input files
  # -------------------------
  
  input_files <- list.files(input_dir, pattern = "\\.inp$", full.names = TRUE)
  input_files <- sort(input_files)
  
  if (length(input_files) == 0) {
    warning("No input files found")
    return(data.frame(
      ID = character(),
      provWasGeneratedBy = character(),
      stringsAsFactors = FALSE
    ))
  }
  
  names <- sub("\\.inp$", "", basename(input_files))
  ids   <- paste0("ex:file_", names, "_inp")
  
  # -------------------------
  # Parse filename structure
  # -------------------------
  
  parse_name <- function(x) {
    m <- regexec("^(.*?)([0-9]+)([a-z]?)$", x)
    parts <- regmatches(x, m)[[1]]
    
    if (length(parts) == 0) {
      return(list(prefix = x, num = NA, letter = ""))
    }
    
    list(
      prefix = parts[2],
      num = as.numeric(parts[3]),
      letter = parts[4]
    )
  }
  
  parsed <- lapply(names, parse_name)
  
  # -------------------------
  # Sequential logic
  # -------------------------
  
  is_sequential <- function(prev, curr) {
    
    if (prev$prefix != curr$prefix) return(FALSE)
    
    if (!is.na(prev$num) && !is.na(curr$num)) {
      
      # Case 1: numeric increment (01 → 02)
      if (curr$num == prev$num + 1 &&
          prev$letter == "" &&
          curr$letter == "") {
        return(TRUE)
      }
      
      # Case 2: same number, letter progression
      if (curr$num == prev$num) {
        
        # "" → "a"
        if (prev$letter == "" && curr$letter == "a") {
          return(TRUE)
        }
        
        # "a" → "b", etc.
        if (prev$letter != "" && curr$letter != "") {
          if (utf8ToInt(curr$letter) == utf8ToInt(prev$letter) + 1) {
            return(TRUE)
          }
        }
      }
    }
    
    FALSE
  }
  
  # -------------------------
  # Step 1: build default provenance
  # -------------------------
  
  prov <- character(length(ids))
  
  for (i in seq_along(ids)) {
    
    if (i == 1) {
      prov[i] <- "ex:avogadro_build"
      next
    }
    
    if (is_sequential(parsed[[i - 1]], parsed[[i]])) {
      prov[i] <- paste0("ex:exp_", names[i - 1])
    } else {
      prov[i] <- "ex:avogadro_build"
    }
  }
  
  prov_df <- data.frame(
    ID = ids,
    provWasGeneratedBy = prov,
    stringsAsFactors = FALSE
  )
  
  # -------------------------
  # Step 2: overlay provenance file safely
  # -------------------------
  
  if (!is.null(provenance_file) && file.exists(provenance_file)) {
    
    user_prov <- read.delim(provenance_file, stringsAsFactors = FALSE)
    
    if (!all(c("ID", "provWasGeneratedBy") %in% names(user_prov))) {
      stop("Provenance file must contain: ID, provWasGeneratedBy")
    }
    
    match_idx <- match(prov_df$ID, user_prov$ID)
    
    for (i in seq_along(match_idx)) {
      
      j <- match_idx[i]
      
      if (!is.na(j)) {
        
        val <- user_prov$provWasGeneratedBy[j]
        
        # ✅ Only override if valid (prevents gaps!)
        if (!is.na(val) && val != "") {
          prov_df$provWasGeneratedBy[i] <- val
        }
      }
    }
    
    # Optional warning for bad entries
    bad <- user_prov$ID[
      is.na(user_prov$provWasGeneratedBy) |
        user_prov$provWasGeneratedBy == ""
    ]
    
    if (length(bad) > 0) {
      warning("Ignoring empty provenance for IDs: ",
              paste(bad, collapse = ", "))
    }
    
    # Optional warning for unknown IDs
    unknown <- setdiff(user_prov$ID, prov_df$ID)
    if (length(unknown) > 0) {
      warning("Unknown IDs in provenance file: ",
              paste(unknown, collapse = ", "))
    }
  }
  
  return(prov_df)
}