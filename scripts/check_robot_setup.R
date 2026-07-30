#' Check that `robot` is callable and using a Java version it actually supports
#'
#' ROBOT requires Java 11+. Several systems (this was found on a real
#' Windows corporate machine) have an older default Java on PATH (e.g.
#' 1.8) even when a newer one is also installed - robot then fails with
#' a confusing, unrelated-looking error deep inside a build, rather than
#' a clear "wrong Java version" message. This checks both things
#' up front, before any real build is attempted.
#'
#' @param robot_cmd Command to invoke robot (default "robot"; pass the
#'   full path, or "java -jar /path/to/robot.jar", if it's not on PATH -
#'   see the java_path parameter below for a cleaner way to handle a
#'   specific Java install).
#' @param java_path Optional explicit path to a compatible Java
#'   executable (e.g. "C:/Program Files/Eclipse Adoptium/jre-11.0.28.6-hotspot/bin/java.exe").
#'   If given, this is prepended to PATH for the check (and printed as
#'   the fix to apply permanently, via Sys.setenv(), if the check
#'   currently fails without it).
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
    stop(
      "No 'java' found on PATH at all. ROBOT needs Java 11 or newer.\n",
      "Install one (e.g. Eclipse Temurin), then either add it to PATH, ",
      "or call check_robot_setup(java_path = \"C:/path/to/java.exe\")."
    )
  }

  # java -version prints to stderr, format: 'openjdk version "1.8.0_492"' or similar
  version_line <- java_check[grepl("version", java_check, ignore.case = TRUE)][1]
  version_match <- regmatches(version_line, regexpr('"[0-9.]+', version_line))
  version_string <- sub('"', "", version_match)

  # Old-style versioning (1.8.x) means Java 8; modern versioning (11, 17, 21...)
  # gives the real major version directly.
  major_version <- if (grepl("^1\\.", version_string)) {
    as.integer(sub("^1\\.([0-9]+)\\..*", "\\1", version_string))
  } else {
    as.integer(sub("^([0-9]+).*", "\\1", version_string))
  }

  if (is.na(major_version) || major_version < 11) {
    stop(
      "Found Java version ", version_string, " (major version ", major_version, "), ",
      "but ROBOT requires Java 11 or newer.\n",
      "If you have a newer Java installed elsewhere, point at it directly:\n",
      '  check_robot_setup(java_path = "C:/path/to/java11/bin/java.exe")\n',
      "This was found on a real system where Java 8 was the PATH default ",
      "even with Java 11 also installed - this doesn't mean Java 11 is ",
      "missing, just that PATH is pointing at the wrong one."
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
      "Java ", version_string, " looks fine, but '", robot_cmd, "' itself ",
      "could not be run. Check robot is installed and either on PATH or ",
      "that robot_cmd points at it directly (e.g. a full path to robot.jar ",
      "invoked as 'java -jar ...').\n",
      if (!is.null(robot_check)) paste("Output was:\n", paste(robot_check, collapse = "\n")) else ""
    )
  }

  cat("Java version:", version_string, "- OK (11+)\n")
  cat("robot:", robot_check[1], "- OK\n")
  invisible(TRUE)
}
