#' Parse a major Java version number from `java -version` output
#'
#' Shared by check_robot_setup() and find_compatible_java() - kept in
#' one place rather than duplicated, same reasoning as every other
#' shared-helper consolidation in this project.
#'
#' @param java_check Character vector, the captured output of
#'   `system2("java", "-version", stdout = TRUE, stderr = TRUE)` (or
#'   the same run against a specific java executable).
#' @return A list: version_string (e.g. "1.8.0_492" or "11.0.28"),
#'   major_version (integer, e.g. 8 or 11). major_version is NA if the
#'   output couldn't be parsed at all.
#' @export
parse_java_version <- function(java_check) {
  version_line <- java_check[grepl("version", java_check, ignore.case = TRUE)][1]
  if (is.na(version_line)) {
    return(list(version_string = NA_character_, major_version = NA_integer_))
  }

  version_match <- regmatches(version_line, regexpr('"[0-9.]+', version_line))
  version_string <- sub('"', "", version_match)

  if (length(version_string) == 0 || !nzchar(version_string)) {
    return(list(version_string = NA_character_, major_version = NA_integer_))
  }

  # Old-style versioning (1.8.x) means Java 8; modern versioning (11, 17, 21...)
  # gives the real major version directly.
  major_version <- if (grepl("^1\\.", version_string)) {
    as.integer(sub("^1\\.([0-9]+)\\..*", "\\1", version_string))
  } else {
    as.integer(sub("^([0-9]+).*", "\\1", version_string))
  }

  list(version_string = version_string, major_version = major_version)
}


#' Scan common JDK install locations for a Java 11+ installation
#'
#' Doesn't rely on PATH at all - specifically for the case where a
#' compatible Java is genuinely installed but PATH points at an older
#' one instead (confirmed happening on a real Windows machine: Java 8
#' on PATH, Java 11 installed separately and simply never found).
#'
#' This can only scan locations - it can't install anything. If nothing
#' is found, the honest answer is that a compatible Java genuinely
#' isn't installed yet, not that this function failed to look hard
#' enough.
#'
#' @return A data.frame: path (to the java executable), version_string,
#'   major_version. Empty (0 rows) if nothing compatible was found.
#'   Printed as a readable summary as a side effect either way.
#' @export
find_compatible_java <- function() {

  is_windows <- .Platform$OS.type == "windows"

  candidate_dirs <- if (is_windows) {
    c(
      "C:/Program Files/Eclipse Adoptium",
      "C:/Program Files/Java",
      "C:/Program Files (x86)/Java",
      "C:/Program Files/Zulu",
      "C:/Program Files/Microsoft/jdk",
      "C:/Program Files/OpenJDK",
      "C:/Program Files/Amazon Corretto"
    )
  } else {
    c(
      "/usr/lib/jvm",
      "/opt/java",
      "/Library/Java/JavaVirtualMachines"  # macOS
    )
  }

  java_exe_name <- if (is_windows) "java.exe" else "java"

  found <- list()

  for (base in candidate_dirs) {
    if (!dir.exists(base)) next

    # Versioned installs typically live in a subfolder, e.g.
    # "jre-11.0.28.6-hotspot" - search a couple of levels deep for the
    # actual executable rather than assuming a fixed structure.
    candidates <- list.files(base, pattern = paste0("^", java_exe_name, "$"),
                              recursive = TRUE, full.names = TRUE)
    for (exe in candidates) {
      # macOS wraps the real java inside .../Contents/Home/bin/
      if (!is_windows && !grepl("/bin/java$", exe)) next
      found[[length(found) + 1]] <- exe
    }
  }

  if (length(found) == 0) {
    cat("No Java installations found in common locations.\n")
    cat("This means a compatible Java genuinely isn't installed yet, not\n")
    cat("that this scan missed it - if you know Java is installed somewhere\n")
    cat("unusual, pass that path directly to check_robot_setup(java_path = ...).\n")
    return(data.frame(path = character(0), version_string = character(0),
                       major_version = integer(0), stringsAsFactors = FALSE))
  }

  rows <- lapply(found, function(exe) {
    check <- tryCatch(
      system2(exe, "-version", stdout = TRUE, stderr = TRUE),
      error = function(e) NULL
    )
    if (is.null(check)) return(NULL)
    v <- parse_java_version(check)
    data.frame(path = exe, version_string = v$version_string,
               major_version = v$major_version, stringsAsFactors = FALSE)
  })
  rows <- rows[!vapply(rows, is.null, logical(1))]

  if (length(rows) == 0) {
    cat("Found Java executables but none would actually run - see above.\n")
    return(data.frame(path = character(0), version_string = character(0),
                       major_version = integer(0), stringsAsFactors = FALSE))
  }

  result <- do.call(rbind, rows)
  compatible <- result[!is.na(result$major_version) & result$major_version >= 11, ]

  cat("Found", nrow(result), "Java installation(s):\n")
  for (i in seq_len(nrow(result))) {
    ok <- !is.na(result$major_version[i]) && result$major_version[i] >= 11
    cat(" ", if (ok) "[OK, 11+]" else "[too old]", result$version_string[i], "-", result$path[i], "\n")
  }

  if (nrow(compatible) > 0) {
    cat("\nUse one of the [OK, 11+] paths above, e.g.:\n")
    cat('  check_robot_setup(java_path = "', compatible$path[1], '")\n', sep = "")
  } else {
    cat("\nNone of these are Java 11+. A compatible version needs installing.\n")
  }

  result
}


#' Check that `robot` is callable and using a Java version it actually supports
#'
#' ROBOT requires Java 11+. Several systems (this was found on a real
#' Windows corporate machine) have an older default Java on PATH (e.g.
#' 1.8) even when a newer one is also installed - robot then fails with
#' a confusing, unrelated-looking error deep inside a build, rather than
#' a clear "wrong Java version" message. This checks both things
#' up front, before any real build is attempted.
#'
#' If the default Java on PATH isn't compatible, this now automatically
#' scans common install locations (via find_compatible_java()) and
#' includes any compatible Java it finds directly in the error message -
#' rather than just telling you to go find one yourself.
#'
#' @param robot_cmd Command to invoke robot (default "robot"; pass the
#'   full path, or "java -jar /path/to/robot.jar", if it's not on PATH -
#'   see the java_path parameter below for a cleaner way to handle a
#'   specific Java install).
#' @param java_path Optional explicit path to a compatible Java
#'   executable (e.g. "C:/Program Files/Eclipse Adoptium/jre-11.0.28.6-hotspot/bin/java.exe").
#'   If given, this is prepended to PATH for the check.
#' @return Invisibly, TRUE if everything checks out; stops with a clear,
#'   actionable message otherwise.
#' @export
check_robot_setup <- function(robot_cmd = "robot", java_path = NULL) {

  if (!is.null(java_path)) {
    java_dir <- dirname(java_path)
    Sys.setenv(PATH = paste(java_dir, Sys.getenv("PATH"), sep = .Platform$path.sep))
  }

  # ---- 1. Is a Java on PATH at all? ----
  java_check <- tryCatch(
    system2("java", "-version", stdout = TRUE, stderr = TRUE),
    error = function(e) NULL
  )

  if (is.null(java_check)) {
    cat("No 'java' found on PATH at all. Scanning common install locations...\n\n")
    find_compatible_java()
    stop(
      "\nROBOT needs Java 11 or newer. See the scan above - if a compatible ",
      "one was found, use check_robot_setup(java_path = \"...\") with that path. ",
      "If nothing was found, Java needs installing (e.g. Eclipse Temurin)."
    )
  }

  v <- parse_java_version(java_check)

  if (is.na(v$major_version) || v$major_version < 11) {
    cat("Found Java ", v$version_string, ", but ROBOT needs 11+. ",
        "Scanning common install locations for something compatible...\n\n", sep = "")
    find_compatible_java()
    stop(
      "\nCurrent PATH points at Java ", v$version_string, " (too old). ",
      "See the scan above - if a compatible Java was found, use it via ",
      'check_robot_setup(java_path = "...").\n',
      "This was found on a real system where Java 8 was the PATH default ",
      "even with Java 11 also installed - the scan above exists specifically ",
      "for that situation."
    )
  }

  # ---- 2. Can robot itself actually run? ----
  robot_check <- tryCatch(
    system2(robot_cmd, "--version", stdout = TRUE, stderr = TRUE),
    error = function(e) NULL
  )
  robot_status <- attr(robot_check, "status")

  if (is.null(robot_check) || (!is.null(robot_status) && robot_status != 0)) {
    stop(
      "Java ", v$version_string, " looks fine, but '", robot_cmd, "' itself ",
      "could not be run. Check robot is installed and either on PATH or ",
      "that robot_cmd points at it directly (e.g. a full path to robot.jar ",
      "invoked as 'java -jar ...').\n",
      if (!is.null(robot_check)) paste("Output was:\n", paste(robot_check, collapse = "\n")) else ""
    )
  }

  cat("Java version:", v$version_string, "- OK (11+)\n")
  cat("robot:", robot_check[1], "- OK\n")
  invisible(TRUE)
}
