# Sanity checks for the ont_mm build pipeline: confirms experiment
# individuals are typed against real gc: classes (not the old disconnected
# ex: shadow classes), and that those classes carry their real hierarchy
# through template generation + merge.
#
# Born out of two real bugs caught in July 2026:
#   1. process_contraints.R independently, incorrectly re-typed every
#      experiment as ex:GeometryOptimization regardless of actual job type
#   2. robot template's --input alone doesn't fold the base ontology's own
#      axioms into the output - needs --merge-before too - so class
#      hierarchy silently went missing even though typing looked correct
#
# Worth re-running this after any change to process_experiments.R,
# process_contraints.R, or the robot template/merge commands in
# examples/README.md - both bugs above passed silently until checked here.

gamess_functions_path <- "~/Projects/active/gamess_functions"
ont_mm_path           <- "~/Projects/active/ont_mm"

source(file.path(gamess_functions_path, "R/sparql_to_file.R"))

graph_candidates <- list.files(file.path(ont_mm_path, "examples/ont"),
                                pattern = "^gc_core_full_.*\\.ttl$",
                                full.names = TRUE)
graph <- graph_candidates[order(graph_candidates, decreasing = TRUE)][1]
cat("Checking:", graph, "\n\n")

cat("=== 1. No experiment is typed against a disconnected ex: shadow class ===\n")
res1 <- sparql_query(
  graph_file = graph,
  query = "SELECT ?exp WHERE { ?exp a ex:GeometryOptimization . }"
)
if (nrow(res1) == 0) {
  cat("OK - no ex:GeometryOptimization survivors\n\n")
} else {
  cat("FAIL - found", nrow(res1), "experiment(s) still typed via the old ex: shadow class:\n")
  print(res1)
  cat("\n")
}

cat("=== 2. gc: job-type classes carry their real hierarchy ===\n")
for (cls in c("gc:GeometryOptimization", "gc:SinglePoint", "gc:VibrationalAnalysis")) {
  res <- sparql_query(
    graph_file = graph,
    query = sprintf("SELECT ?super WHERE { %s rdfs:subClassOf ?super . }", cls)
  )
  status <- if (nrow(res) > 0) "OK" else "FAIL - no superclass found"
  cat(sprintf("%-25s %s (%d parent(s))\n", cls, status, nrow(res)))
}
cat("\n")

cat("=== 3. Every experiment has exactly one job-type assertion ===\n")
res3 <- sparql_query(
  graph_file = graph,
  query = "SELECT ?exp ?type WHERE {
             ?exp a ?type .
             FILTER(?type IN (gc:GeometryOptimization, gc:SinglePoint, gc:VibrationalAnalysis))
           }"
)
print(res3)
dupes <- res3$exp[duplicated(res3$exp)]
if (length(dupes) == 0) {
  cat("OK - no experiment has more than one job-type assertion\n")
} else {
  cat("FAIL - these experiments have multiple conflicting job types:", unique(dupes), "\n")
}
