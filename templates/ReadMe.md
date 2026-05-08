The following templates are the schema for the files created during the molecular modelling work.

constraint_template.tsv
experiment_template.tsv
results_template_instances.tsv



robot template \
  --template ~/Projects/active/ont_mm/examples/experiment_template_instances.tsv \
  --ontology file:///home/darren/Projects/active/ont_mm/builds/gc_core.ttl \
  --ontology-iri "http://purl.org/gc/core" \
  --prefix "gc: http://purl.org/gc/" \
  --prefix "ex: http://example.org/" \
  --prefix "prov: http://www.w3.org/ns/prov#" \
  --prefix "xsd:http://www.w3.org/2001/XMLSchema#" \
  --output ~/Projects/active/ont_mm/templates/experiment_template_gc.owl
