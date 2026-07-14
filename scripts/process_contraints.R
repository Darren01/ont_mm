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
  input_files <- sort(list.files(input_dir, full.names = TRUE))
  
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
  
  # ✅ FIXED: now globally visible
  extract_zmat_blocks <- function(lines) {
    start_idx <- grep("\\$ZMAT", lines, ignore.case = TRUE)
    end_idx   <- grep("\\$END", lines, ignore.case = TRUE)
    
    blocks <- list()
    
    for (s in start_idx) {
      e <- end_idx[end_idx > s][1]
      if (!is.na(e)) {
        blocks[[length(blocks) + 1]] <- lines[s:e]
      }
    }
    
    blocks
  }
  
  parse_constraints_fast <- function(file_path) {
    
    lines <- readLines(file_path, warn = FALSE)
    exp_id <- get_experiment_id(file_path)
    
    zmat_blocks <- extract_zmat_blocks(lines)
    if (length(zmat_blocks) == 0) return(NULL)
    
    rows <- list()
    idx <- 1
    
    for (block_lines in zmat_blocks) {
      
      block <- paste(block_lines, collapse = " ")
      
      if (!grepl("IFZMAT", block)) next
      
      ifzmat_text <- sub(".*IFZMAT\\(1\\)=([^\\$]+?)FVALUE.*", "\\1", block)
      fvalue_text <- sub(".*FVALUE\\(1\\)=([^\\$]+?)\\$END.*", "\\1", block)
      
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
            # Type intentionally left blank: the experiment's type is
            # already asserted once, correctly, in
            # experiment_template_instances.tsv (via classify_gamess_job()).
            # This row only needs to attach hasConstraint - redeclaring
            # Type here duplicated that assertion and, being hardcoded,
            # silently contradicted it for anything that wasn't a
            # GeometryOptimization (e.g. rem01b, a VibrationalAnalysis).
            Type = "",
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
        
        if (type == 1) {
          
          atom1 <- ifzmat_nums[i + 1]
          atom2 <- ifzmat_nums[i + 2]
          cid <- paste0(exp_id, "_dist_", atom1, "_", atom2)
          
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
  
  parsed_list <- lapply(input_files, parse_constraints_fast)
  parsed_list <- parsed_list[!vapply(parsed_list, is.null, logical(1))]
  
  all_constraints <- do.call(rbind, parsed_list)
  
  all_constraints <- all_constraints[, names(constraints), drop = FALSE]
  
  existing_pairs <- paste(constraints$ID, constraints$hasConstraint)
  new_pairs <- paste(all_constraints$ID, all_constraints$hasConstraint)
  
  keep <- !(new_pairs %in% existing_pairs)
  new_rows <- all_constraints[keep, , drop = FALSE]
  
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
  
  if (run_validation) {
    
    validate_constraints_file <- function(file_path) {
      
      lines <- readLines(file_path)
      
      zmat_blocks <- extract_zmat_blocks(lines)
      
      zmat_total <- length(grep("\\$ZMAT", lines, ignore.case = TRUE))
      zmat_active <- length(zmat_blocks)
      zmat_ignored <- zmat_total - zmat_active
      
      ifzmat_present <- sum(vapply(zmat_blocks, function(b) {
        any(grepl("IFZMAT", b))
      }, logical(1)))
      
      fvalue_present <- sum(vapply(zmat_blocks, function(b) {
        any(grepl("FVALUE", b))
      }, logical(1)))
      
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
        zmat_total = zmat_total,
        zmat_active = zmat_active,
        zmat_ignored = zmat_ignored,
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
