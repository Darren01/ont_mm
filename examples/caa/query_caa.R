# Queries for the real caa dataset specifically.
source("../../../gamess_functions/R/sparql_to_file.R")   # adjust to your own checkout layout
graph <- "ont/caa_graph_20260905.ttl"

# ---------------------------------------------------------------------
# 1. Every experiment, by type - the basic inventory
# ---------------------------------------------------------------------
cat("=== Experiments by type ===\n")
res <- sparql_query(
  graph_file = graph,
  query = "SELECT ?exp ?type WHERE {
             ?exp a ?type .
             FILTER(?type IN (gc:GeometryOptimization, gc:SinglePoint,
                               gc:VibrationalAnalysis, gc:SaddlePoint, gc:IRC))
           } ORDER BY ?type ?exp"
)
print(res)

# ---------------------------------------------------------------------
# 2. Every experiment you've added a review note to - correctly
#    restricted to real experiment individuals only.
#
#    NOTE: uses skos:editorialNote, not rdfs:comment - annotations were
#    migrated to skos:editorialNote earlier in this project's history;
#    an rdfs:comment-based version of this query would silently return
#    nothing against the current graph, not error.
# ---------------------------------------------------------------------
cat("\n=== Experiments with your own review notes ===\n")
res <- sparql_query(
  graph_file = graph,
  query = "SELECT ?exp ?comment WHERE {
             ?exp a gc:MolecularComputation .
             ?exp skos:editorialNote ?comment .
           } ORDER BY ?exp"
)
print(res)

# ---------------------------------------------------------------------
# 3. Every constraint, with its target value and unit
#    Note: use FILTER(?target = 2.0) rather than a direct literal match
#    if filtering to a specific value - a bare number in a triple
#    pattern parses as xsd:decimal, which won't match our xsd:float
#    data as an exact term, even though FILTER's numeric comparison
#    works correctly across both.
# ---------------------------------------------------------------------
cat("\n=== Constraints ===\n")
res <- sparql_query(
  graph_file = graph,
  query = "SELECT ?constraint ?type ?target ?unit WHERE {
             ?constraint a ?type ; ex:targetValue ?target ; gc:hasUnit ?unit .
             FILTER(?type IN (ex:DistanceConstraint, ex:AngleConstraint, ex:DihedralConstraint))
           } ORDER BY ?constraint"
)
print(res)

# ---------------------------------------------------------------------
# 4. Any imaginary (negative) frequencies
# ---------------------------------------------------------------------
cat("\n=== Peaks with negative (imaginary) frequency ===\n")
res <- sparql_query(
  graph_file = graph,
  query = "SELECT ?spectrum ?freq WHERE {
             ?spectrum gc:hasFrequencyPeak ?peak .
             ?peak gc:hasFrequency ?fv .
             ?fv gc:hasFloatValue ?freq .
             FILTER(?freq < 0)
           }
  ORDER BY ?spectrum ?freq"
)
print(res)

# ---------------------------------------------------------------------
# 5. Cross-reference: annotated experiments that also have an
#    imaginary frequency. An empty result is a genuine finding, not a
#    bug - your currently-annotated experiments don't overlap with the
#    ones showing an imaginary frequency.
# ---------------------------------------------------------------------
cat("\n=== Annotated experiments with an imaginary frequency ===\n")
res <- sparql_query(
  graph_file = graph,
  query = "SELECT ?exp ?comment ?freq WHERE {
             ?exp a gc:MolecularComputation .
             ?exp skos:editorialNote ?comment .
             ?exp gc:hasResult ?spectrum .
             ?spectrum gc:hasFrequencyPeak ?peak .
             ?peak gc:hasFrequency ?fv .
             ?fv gc:hasFloatValue ?freq .
             FILTER(?freq < 0)
           }"
)
print(res)
