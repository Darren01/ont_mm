#' Check that `shacl` (Apache Jena) is callable and correctly set up
#'
#' Mirrors check_robot_setup()'s diagnostic pattern - a real gap this
#' fills: Jena's setup has genuinely more ways to go wrong than
#' robot's, found the hard way across two different real machines:
#'
#' 1. Two different Jena downloads exist, easily confused - the
#'    correct one, "apache-jena-X.Y.Z.zip" (all command-line tools,
#'    including shacl), and "apache-jena-fuseki-X.Y.Z.zip" (Jena's
#'    SPARQL *server* only - genuinely doesn't contain shacl at all,
#'    confirmed directly from Jena's own project discussion). Getting
#'    the wrong one looks identical to a PATH problem from the
#'    outside - this function checks for it specifically, rather than
#'    leaving it to be rediscovered by trial and error.
#' 2. Windows uses shacl.bat, not shacl (auto-handled below - don't
#'    need to know this yourself).
#' 3. Windows' shacl.bat requires JENAROOT to be set explicitly - it
#'    does NOT auto-detect its own location the way the Linux/Mac
#'    shacl script does (confirmed directly from Jena's own shacl.bat
#'    source). This is a real, asymmetric difference from the
#'    Linux/Mac setup, not a Windows quirk you'd necessarily expect.
#' 4. A stale JAVA_HOME can break shacl even with everything else
#'    correct - already handled automatically inside
#'    validate_graph_shacl() itself, not re-checked here.
#'
#' @param shacl_cmd Command to invoke shacl. Default "shacl" - on
#'   Windows, ".bat" is tried automatically if the bare name doesn't
#'   work, so you don't need to know to add it yourself.
#' @param jena_home Optional explicit path to your Jena install
#'   folder (e.g. "C:/Users/you/Desktop/apache-jena-6.2.0"). If given,
#'   its bin/ (or bat/) folder is added to PATH for the check, and the
#'   folder itself is checked for the fuseki-only mistake before
#'   anything else is tried.
#' @return Invisibly, TRUE if everything checks out; stops with a
#'   clear, actionable message otherwise.
#' @export
check_jena_setup <- function(shacl_cmd = "shacl", jena_home = NULL) {

  is_windows <- .Platform$OS.type == "windows"

  # ---- 1. If a jena_home was given, check for the wrong-distribution
  # mistake directly, before trying anything else ----
  if (!is.null(jena_home)) {
    if (!dir.exists(jena_home)) {
      stop("jena_home does not exist: ", jena_home)
    }

    has_bin_shacl  <- file.exists(file.path(jena_home, "bin", "shacl"))
    has_bat_shacl  <- file.exists(file.path(jena_home, "bat", "shacl.bat"))
    looks_like_fuseki <- grepl("fuseki", basename(jena_home), ignore.case = TRUE)

    if (!has_bin_shacl && !has_bat_shacl) {
      stop(
        "No shacl", if (is_windows) ".bat" else "", " found inside ", jena_home, ".\n",
        if (looks_like_fuseki) paste0(
          "This looks like the Fuseki-only download (folder name contains ",
          "'fuseki') - that package is Jena's SPARQL *server* only and ",
          "genuinely doesn't include shacl or any other command-line ",
          "tools. You need the plain 'apache-jena-X.Y.Z.zip' instead ",
          "(no 'fuseki' in the name) from https://jena.apache.org/download/ - ",
          "a completely separate download, not an extra step for this one.\n"
        ) else paste0(
          "Expected to find it at ", file.path(jena_home, "bin", "shacl"),
          " (Linux/Mac) or ", file.path(jena_home, "bat", "shacl.bat"),
          " (Windows) - double check jena_home points at the right folder.\n"
        )
      )
    }

    tools_dir <- if (is_windows) file.path(jena_home, "bat") else file.path(jena_home, "bin")
    Sys.setenv(PATH = paste(tools_dir, Sys.getenv("PATH"), sep = .Platform$path.sep))

    # Windows' shacl.bat needs this set explicitly - it won't auto-detect
    # its own location the way the Linux/Mac script does.
    if (is_windows) {
      Sys.setenv(JENAROOT = jena_home)
    }
  }

  # ---- 2. Work out the right command name for this platform ----
  cmd <- shacl_cmd
  if (is_windows && shacl_cmd == "shacl") {
    cmd <- "shacl.bat"
  }

  # ---- 3. Can it actually run? ----
  check <- tryCatch(
    system2(cmd, "--help", stdout = TRUE, stderr = TRUE),
    error = function(e) NULL
  )
  status <- attr(check, "status")

  if (is.null(check) || (!is.null(status) && status != 0)) {
    hint <- if (is.null(jena_home)) {
      paste0(
        "\nNot found on PATH, and no jena_home was given to check ",
        "directly. Either add Jena's ", if (is_windows) "bat" else "bin",
        " folder to PATH yourself, or call this again with ",
        'check_jena_setup(jena_home = "path/to/your/apache-jena-X.Y.Z") ',
        "so the wrong-distribution check above can run."
      )
    } else {
      paste0(
        "\nFound shacl", if (is_windows) ".bat" else "", " in ", jena_home,
        " and added it to PATH, but it still didn't run cleanly. ",
        if (is_windows) paste0(
          "On Windows, shacl.bat needs JENAROOT set explicitly (this ",
          "function sets it automatically when jena_home is given, but ",
          "double-check it isn't being overridden elsewhere in your ",
          "environment)."
        ) else "",
        "\nOutput was:\n", if (!is.null(check)) paste(check, collapse = "\n") else "(no output at all)"
      )
    }
    stop("'", cmd, "' could not be run.", hint)
  }

  cat("shacl (", cmd, "): OK\n", sep = "")
  invisible(TRUE)
}
