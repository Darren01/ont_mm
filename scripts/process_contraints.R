process_constraints_fast_ordered <- function(
    tsv_file,
    input_dir,
    output_file,
    run_validation = TRUE
) {
  
  constraints <- read.table(
    tsv_file,
    header = TRUE,
    sep = "\t",
    stringsAsFactors = FALSE,
    fill = TRUE
  )
  
  # 🔒 deterministic file order
  input_files <- list.files(input_dir, full.names = TRUE)
  input_files <- sort(input_files)
  
  get_experiment_id <- function(file_path) {
    paste0("ex:", sub("\\..*$", "", basename(file_path)))
  }
  
  clean_numbers <- function(x) {
    nums <- unlist(strsplit(x, ","))
    nums <- gsub("[^0-9\\.]", "", nums)
    nums <- nums[nums != ""]
    as.numeric(nums)
  }
  
  rows_to_df <- function(rows) {
    if (length(rows) == 0) return(NULL)
    
    df <- do.call(rbind, lapply(rows, function(x) {
      as.data.frame(x, stringsAsFactors = FALSE)
    }))
    
    df$targetValue <- as.numeric(df$targetValue)
    
    char_cols <- setdiff(names(df), "targetValue")
    df[char_cols] <- lapply(df[char_cols], as.character)
    
    df
  }
  
  parse_constraints_fast <- function(file_path) {
    
    lines <- readLines(file_path, warn = FALSE)
    exp_id <- get_experiment_id(file_path)
    
    # 🔒 preserve line order
    zmat_lines <- lines[grepl("^\\s+\\$ZMAT", lines)]
    if (length(zmat_lines) == 0) return(NULL)
    
    rows <- list()
    idx <- 1
    
    for (line in zmat_lines) {
      
      if (!grepl("IFZMAT", line)) next
      
      ifzmat_text <- sub(".*IFZMAT\\(1\\)=([^F]+)FVALUE.*", "\\1", line)
      fvalue_text <- sub(".*FVALUE\\(1\\)=([^$]+)\\$END.*", "\\1", line)
      
      ifzmat_nums <- clean_numbers(ifzmat_text)
      fvalues <- clean_numbers(fvalue_text)
      
      if (length(ifzmat_nums) == 0 || length(fvalues) == 0) next
      
      i <- 1
      constraint_index <- 1
      
      while (i <= length(ifzmat_nums)) {
        
        type <- ifzmat_nums[i]
        value <- fvalues[constraint_index]
        if (is.na(value)) value <- 0
        
        make_exp <- function(cid) {
          list(
            ID = exp_id,
            Label = paste("Experiment", sub("^ex:", "", exp_id)),
            Type = "ex:GeometryOptimization",
            hasConstraint = cid,
            involvesAtom1 = "",
            involvesAtom2 = "",
            involvesAtom3 = "",
            involvesAtom4 = "",
            targetValue = 0,
            hasUnit = "",
            constraintMode = "",
            forceConstant = ""
          )
        }
        
        # ---------- DISTANCE ----------
        if (type == 1) {
          
          atom1 <- ifzmat_nums[i + 1]
          atom2 <- ifzmat_nums[i + 2]
          cid <- paste0(exp_id, "_dist_", atom1, "_", atom2)
          
          # 🔒 emit in exact same order as original
          rows[[idx]] <- list(
            ID = cid,
            Label = paste("Distance constraint", atom1, atom2),
            Type = "ex:DistanceConstraint",
            hasConstraint = "",
            involvesAtom1 = paste0("ex:atom_", atom1),
            involvesAtom2 = paste0("ex:atom_", atom2),
            involvesAtom3 = "",
            involvesAtom4 = "",
            targetValue = value,
            hasUnit = "angstrom",
            constraintMode = "fixed",
            forceConstant = ""
          )
          
          rows[[idx + 1]] <- make_exp(cid)
          
          idx <- idx + 2
          i <- i + 3
          
          # ---------- ANGLE ----------
        } else if (type == 2) {
          
          atom1 <- ifzmat_nums[i + 1]
          atom2 <- ifzmat_nums[i + 2]
          atom3 <- ifzmat_nums[i + 3]
          cid <- paste0(exp_id, "_angle_", atom1, "_", atom2, "_", atom3)
          
          rows[[idx]] <- list(
            ID = cid,
            Label = paste("Angle constraint", atom1, atom2, atom3),
            Type = "ex:AngleConstraint",
            hasConstraint = "",
            involvesAtom1 = paste0("ex:atom_", atom1),
            involvesAtom2 = paste0("ex:atom_", atom2),
            involvesAtom3 = paste0("ex:atom_", atom3),
            involvesAtom4 = "",
            targetValue = value,
            hasUnit = "degree",
            constraintMode = "fixed",
            forceConstant = ""
          )
          
          rows[[idx + 1]] <- make_exp(cid)
          
          idx <- idx + 2
          i <- i + 4
          
          # ---------- DIHEDRAL ----------
        } else if (type == 3) {
          
          atom1 <- ifzmat_nums[i + 1]
          atom2 <- ifzmat_nums[i + 2]
          atom3 <- ifzmat_nums[i + 3]
          atom4 <- ifzmat_nums[i + 4]
          cid <- paste0(exp_id, "_dih_", atom1, "_", atom2, "_", atom3, "_", atom4)
          
          rows[[idx]] <- list(
            ID = cid,
            Label = paste("Dihedral constraint", atom1, atom2, atom3, atom4),
            Type = "ex:DihedralConstraint",
            hasConstraint = "",
            involvesAtom1 = paste0("ex:atom_", atom1),
            involvesAtom2 = paste0("ex:atom_", atom2),
            involvesAtom3 = paste0("ex:atom_", atom3),
            involvesAtom4 = paste0("ex:atom_", atom4),
            targetValue = value,
            hasUnit = "degree",
            constraintMode = "fixed",
            forceConstant = ""
          )
          
          rows[[idx + 1]] <- make_exp(cid)
          
          idx <- idx + 2
          i <- i + 5
          
        } else {
          break
        }
        
        constraint_index <- constraint_index + 1
      }
    }
    
    rows_to_df(rows)
  }
  
  # 🔒 preserve file order in binding
  parsed_list <- lapply(input_files, parse_constraints_fast)
  parsed_list <- parsed_list[!vapply(parsed_list, is.null, logical(1))]
  
  all_constraints <- do.call(rbind, parsed_list)
  
  # 🔒 column alignment (same as original)
  all_constraints <- all_constraints[, names(constraints), drop = FALSE]
  
  # 🔒 dedup (order preserved)
  existing_pairs <- paste(constraints$ID, constraints$hasConstraint)
  new_pairs <- paste(all_constraints$ID, all_constraints$hasConstraint)
  
  keep <- !(new_pairs %in% existing_pairs)
  new_rows <- all_constraints[keep, , drop = FALSE]
  
  # 🔒 final order identical to original logic
  combined <- rbind(constraints, new_rows)
  combined[is.na(combined)] <- ""
  
  write.table(
    combined,
    file = output_file,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE
  )
  
  cat("DONE:", output_file, "\n")
  
  # =========================
  # VALIDATION (unchanged logic)
  # =========================
  
  if (run_validation) {
    
    validate_constraints_file <- function(file_path) {
      
      lines <- readLines(file_path)
      
      zmat_all <- grep("\\$ZMAT", lines, value = TRUE)
      zmat_active <- grep("^\\s+\\$ZMAT", lines, value = TRUE)
      zmat_ignored <- setdiff(zmat_all, zmat_active)
      
      ifzmat_present <- sum(grepl("IFZMAT", zmat_active))
      fvalue_present <- sum(grepl("FVALUE", zmat_active))
      
      parsed <- tryCatch(
        parse_constraints_fast(file_path),
        error = function(e) NULL
      )
      
      n_constraints <- if (!is.null(parsed)) nrow(parsed) else NA
      
      mismatch_flag <- FALSE
      mismatch_msg <- ""
      
      if (!is.null(parsed)) {
        if (ifzmat_present != fvalue_present) {
          mismatch_flag <- TRUE
          mismatch_msg <- "IFZMAT and FVALUE count mismatch"
        }
        if (n_constraints == 0 && ifzmat_present > 0) {
          mismatch_flag <- TRUE
          mismatch_msg <- "IFZMAT present but no constraints parsed"
        }
      }
      
      data.frame(
        file = basename(file_path),
        zmat_total = length(zmat_all),
        zmat_active = length(zmat_active),
        zmat_ignored = length(zmat_ignored),
        ifzmat_blocks = ifzmat_present,
        fvalue_blocks = fvalue_present,
        constraints_extracted = n_constraints,
        status = if (mismatch_flag) "WARNING" else "OK",
        message = mismatch_msg,
        stringsAsFactors = FALSE
      )
    }
    
    validation_report <- do.call(rbind, lapply(input_files, validate_constraints_file))
    
    return(list(
      data = combined,
      validation = validation_report
    ))
  }
  
  return(list(
    data = combined,
    validation = NULL
  ))
}