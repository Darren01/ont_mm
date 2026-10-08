# Sanity checks for scripts/filter_vibrational_modes.R: confirms the filter
# removes only what it is meant to - the peaks that are not diagnostic, and
# the frequency/intensity values belonging to those peaks - and leaves every
# other float value alone.
#
# Born out of a real bug introduced when the filter was added (September
# 2026) and caught in October 2026:
#   The filter rewrites float_value_template_instances.tsv in place, but
#   kept only the float values referenced by the peaks it kept. That table
#   also holds every energy value - electronic energy, ZPE, enthalpy,
#   entropy, Gibbs free energy and each reaction-path energy - and none of
#   those are referenced by a peak, so every one was silently deleted. The
#   energy nodes survived in the graph as empty shells (typed only
#   owl:NamedIndividual, with no value or unit), and competency questions
#   11 and 13 returned no values at all while still documented as
#   answerable. The peak counts looked exactly right throughout.
#
# Self-contained: builds its own small fixture (two experiments, with the
# same header rows as the real tables) in a temporary directory, and
# replaces identify_diagnostic_modes() with a stub so no .log files are
# needed. Worth re-running after any change to filter_vibrational_modes.R.
#
# A second, smaller bug in the same function was found at the same time:
# for an experiment whose log could not be found or diagnosed, the filter
# kept the experiment's spectrum row but deleted its peak rows, leaving the
# spectrum pointing at peaks that no longer existed. Such an experiment is
# reported and must be left exactly as it was - section 6 below.
#
# Paths can be overridden for testing a different copy of the script:
#   ONT_MM_PATH   (default ~/Projects/active/ont_mm)
#   FILTER_SCRIPT (default <ONT_MM_PATH>/scripts/filter_vibrational_modes.R)

ont_mm_path <- Sys.getenv("ONT_MM_PATH", "~/Projects/active/ont_mm")
script      <- Sys.getenv("FILTER_SCRIPT",
                          file.path(ont_mm_path, "scripts/filter_vibrational_modes.R"))
source(script)
cat("Checking:", script, "\n\n")

# ---- fixture ---------------------------------------------------------------
# expA: 8 modes, diagnostic ones are 1, 2 and 8.  expB: 6 modes, diagnostic 3, 4.
# expC: 4 modes, but its log cannot be diagnosed, so it must be left alone.
keep_modes <- list(expA = c(1L, 2L, 8L), expB = c(3L, 4L))
n_modes    <- c(expA = 8L, expB = 6L, expC = 4L)

identify_diagnostic_modes <- function(log_file) {
  k <- keep_modes[[sub("\\.log$", "", basename(log_file))]]
  if (is.null(k)) stop("log file not found")      # expC
  list(keep_modes = k)
}

peak_row  <- function(e, n) sprintf("ex:peak_%s_%d\tMode %d %s\tgc:FrequencyPeak\tex:freqval_%s_%d\tex:intval_%s_%d",
                                    e, n, n, e, e, n, e, n)
float_row <- function(id, unit) sprintf("%s\tvalue\tgc:FloatValue\t1.0\t%s", id, unit)

spectra <- vapply(names(n_modes), function(e)
  sprintf("ex:spectrum_%s\tVibrational spectrum %s\tgc:VibrationalSpectra\t%s", e, e,
          paste(sprintf("ex:peak_%s_%d", e, seq_len(n_modes[[e]])), collapse = "|")), "")
peaks <- unlist(lapply(names(n_modes), function(e) vapply(seq_len(n_modes[[e]]), function(n) peak_row(e, n), "")))
peak_floats <- unlist(lapply(names(n_modes), function(e) c(
  vapply(seq_len(n_modes[[e]]), function(n) float_row(sprintf("ex:freqval_%s_%d", e, n), "gc:cm-1"), ""),
  vapply(seq_len(n_modes[[e]]), function(n) float_row(sprintf("ex:intval_%s_%d",  e, n), "gc:debyeSquaredPerAmuAngstromSquared"), ""))))
energy_ids <- c("ex:zpe_expA", "ex:enthalpy_expA", "ex:entropy_expA", "ex:gibbs_expA",
                "ex:electronic_energy_expA", sprintf("ex:pathenergy_expA_%d", 1:3))
energy_floats <- vapply(energy_ids, function(id) float_row(id, "gc:hartree"), "", USE.NAMES = FALSE)

dir <- tempfile("filter_fixture_"); dir.create(dir)
write_table <- function(file, h1, h2, rows) writeLines(c(h1, h2, rows), file.path(dir, file))
write_table("spectra_template_instances.tsv",
            "ID\tLabel\tType\thasFrequencyPeak", "ID\tLABEL\tTYPE\tI gc:hasFrequencyPeak SPLIT=|", spectra)
write_table("peak_template_instances.tsv",
            "ID\tLabel\tType\thasFrequency\thasIntensity", "ID\tLABEL\tTYPE\tI gc:hasFrequency\tI gc:hasIntensity", peaks)
write_table("float_value_template_instances.tsv",
            "ID\tLabel\tType\thasFloatValue\thasUnit", "ID\tLABEL\tTYPE\tAT gc:hasFloatValue^^xsd:float\tI gc:hasUnit",
            c(peak_floats, energy_floats))

before <- lapply(c(spectra = "spectra", peak = "peak", float = "float_value"), function(t)
  readLines(file.path(dir, paste0(t, "_template_instances.tsv")))[-(1:2)])

suppressWarnings(invisible(capture.output(filter_vibrational_modes(dir, "/nonexistent"))))

after <- lapply(c(spectra = "spectra", peak = "peak", float = "float_value"), function(t)
  readLines(file.path(dir, paste0(t, "_template_instances.tsv")))[-(1:2)])
ids <- function(rows) vapply(strsplit(rows, "\t"), `[`, "", 1)

failures <- 0
check <- function(label, ok) {
  cat(sprintf("  [%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) failures <<- failures + 1
}

# ---- 1. only the diagnostic peaks remain -----------------------------------
cat("=== 1. Only the diagnostic peaks are kept (plus every peak of an undiagnosable experiment) ===\n")
expC_peaks <- sprintf("ex:peak_expC_%d", seq_len(n_modes[["expC"]]))
expected_peaks <- c(sprintf("ex:peak_expA_%d", keep_modes$expA), sprintf("ex:peak_expB_%d", keep_modes$expB), expC_peaks)
check(sprintf("peak table holds exactly the %d expected peaks", length(expected_peaks)),
      setequal(ids(after$peak), expected_peaks))

# ---- 2. peak values follow their peaks ------------------------------------
cat("\n=== 2. Frequency/intensity values: kept with kept peaks, removed with removed peaks ===\n")
kept_peak_floats <- c(sub("peak", "freqval", expected_peaks), sub("peak", "intval", expected_peaks))
peak_float_ids   <- ids(peak_floats)
check("every frequency/intensity value of a kept peak survives",
      all(kept_peak_floats %in% ids(after$float)))
check("no frequency/intensity value of a removed peak survives",
      !any(setdiff(peak_float_ids, kept_peak_floats) %in% ids(after$float)))

# ---- 3. everything that is not peak data is untouched ----------------------
cat("\n=== 3. Energy values (not peak data) are never removed ===\n")
check(sprintf("all %d energy/thermochemistry/path-energy rows survive", length(energy_ids)),
      all(energy_ids %in% ids(after$float)))
check("surviving energy rows are byte-for-byte unchanged",
      all(energy_floats %in% after$float))

# ---- 4. referential integrity ----------------------------------------------
cat("\n=== 4. Nothing is left pointing at something that was removed ===\n")
peak_fields <- strsplit(after$peak, "\t")
referenced_floats <- unlist(lapply(peak_fields, function(f) f[4:5]))
check("every float value a remaining peak refers to still exists",
      all(referenced_floats %in% ids(after$float)))
listed_peaks <- unlist(lapply(strsplit(after$spectra, "\t"), function(f) strsplit(f[4], "|", fixed = TRUE)[[1]]))
check("every peak a remaining spectrum lists still exists",
      all(listed_peaks %in% ids(after$peak)))

# ---- 5. nothing invented ---------------------------------------------------
cat("\n=== 5. The filter only removes - it never adds or alters a row ===\n")
check("peak rows are a subset of the original",  all(after$peak  %in% before$peak))
check("float rows are a subset of the original", all(after$float %in% before$float))

# ---- 6. an undiagnosable experiment is left alone --------------------------
cat("\n=== 6. An experiment that cannot be diagnosed is left exactly as it was ===\n")
check("every peak of the undiagnosable experiment is still there", all(expC_peaks %in% ids(after$peak)))
check("its peak rows are unchanged",
      setequal(after$peak[grepl("^ex:peak_expC_", after$peak)], before$peak[grepl("^ex:peak_expC_", before$peak)]))
check("its spectrum row is unchanged",
      identical(after$spectra[grepl("^ex:spectrum_expC\t", after$spectra)], before$spectra[grepl("^ex:spectrum_expC\t", before$spectra)]))

cat(sprintf("\n%s\n", if (failures == 0) "All checks passed." else sprintf("%d check(s) FAILED.", failures)))
if (failures > 0) quit(status = 1)
