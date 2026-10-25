#!/usr/bin/env Rscript
# Barrier and reaction energy for every reaction path in the graph, plus a plot each.
#
# 1. Write all paths to a CSV with arq, using the "all reaction path energies"
#    query from COMPETENCY_QUESTIONS.md (question 13):
#      arq --data "$G" --query ~/queries/allpaths.rq --results CSV > all_paths.csv
# 2. Run:   Rscript scripts/path_barriers.R all_paths.csv path_results
#
# Needs base R only. Writes path_results/summary.csv and one PNG per path.

args    <- commandArgs(trailingOnly = TRUE)
infile  <- if (length(args) >= 1) args[1] else "all_paths.csv"
outdir  <- if (length(args) >= 2) args[2] else "path_results"
HARTREE_TO_KJ <- 2625.4996          # kJ/mol per hartree

d <- read.csv(infile, stringsAsFactors = FALSE)
missing <- setdiff(c("path", "index", "energy"), names(d))
if (length(missing) > 0)
  stop("Missing column(s) in ", infile, ": ", paste(missing, collapse = ", "),
       ". The query must return ?path ?index ?energy.")

# Be forgiving if a value arrives as "-306.3^^http://...#float" or quoted.
as_num <- function(x) as.numeric(sub("\\^\\^.*$", "", gsub('"', "", as.character(x))))
d$index  <- as_num(d$index)
d$energy <- as_num(d$energy)
if (anyNA(d$index) || anyNA(d$energy))
  stop("Some index or energy values are not numbers - look at the CSV.")

dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

short_name <- function(iri) sub("^.*[/#]", "", iri)

rows <- list()
for (p in unique(d$path)) {
  x <- d[d$path == p, ]
  x <- x[order(x$index), ]
  n <- nrow(x)
  e <- x$energy
  kJ <- (e - e[1]) * HARTREE_TO_KJ          # relative to the first point
  top <- which.max(e)                         # highest point = transition state

  rows[[length(rows) + 1]] <- data.frame(
    path                    = short_name(p),
    points                  = n,
    ts_index                = x$index[top],
    barrier_from_first_kJmol = round((e[top] - e[1]) * HARTREE_TO_KJ, 2),
    barrier_from_last_kJmol  = round((e[top] - e[n]) * HARTREE_TO_KJ, 2),
    reaction_energy_kJmol    = round((e[n] - e[1]) * HARTREE_TO_KJ, 2),
    ts_at_an_end            = top %in% c(1, n),
    stringsAsFactors = FALSE
  )

  png(file.path(outdir, paste0(gsub("[^A-Za-z0-9_.-]", "_", short_name(p)), ".png")),
      width = 900, height = 560, res = 110)
  plot(x$index, kJ, type = "l", lwd = 2,
       main = short_name(p),
       xlab = "Path point index",
       ylab = "Energy relative to first point (kJ/mol)")
  points(x$index[top], kJ[top], pch = 19, col = "red")
  abline(h = 0, lty = 3, col = "grey60")
  legend("topleft", bty = "n", pch = 19, col = "red",
         legend = sprintf("highest point: index %g, %.1f kJ/mol above first",
                          x$index[top], kJ[top]))
  invisible(dev.off())
}

summary_df <- do.call(rbind, rows)
write.csv(summary_df, file.path(outdir, "summary.csv"), row.names = FALSE)
print(summary_df, row.names = FALSE)
if (any(summary_df$ts_at_an_end))
  message("\nNote: for path(s) with ts_at_an_end = TRUE the highest point is the first or last ",
          "point, so there is no interior transition state - check the path is complete.")
message("\nWrote ", file.path(outdir, "summary.csv"), " and ", nrow(summary_df), " plot(s).")
