👉 Start here if you're new — this example can be run in under 5 minutes.

# Examples – Quick Start

This folder contains a **minimal working example** of a molecular modelling workflow and its representation in the ontology.

It is the recommended starting point for new users.

---

## Overview

The example demonstrates how:

1. Input, intermediate, and output files are organised
2. Experimental constraints are defined
3. Results are generated and linked
4. Your own review notes and literature references become part of the graph
5. Everything is combined into a **single, queryable ontology**
6. The graph is validated against real data-quality rules

The workflow corresponds to the left-hand side of *Scheme 1* in the main project documentation.

---

## Folder Structure

```
examples/
├── data/            # Intermediate data files (.dat)
├── inputs/          # Input files (.inp)
├── outputs/         # Output log files (.log)
├── ont/             # Ontology templates, instances, and outputs
├── run_notes.tsv    # Your own review comments, optionally linked to a DOI
├── doi_notes.tsv    # Literature references, optionally linked back to an experiment
└── README.md
```

---

## What This Example Contains

### Files

Three simple modelling runs:

* `rem01`
* `rem01a`
* `rem01b`

Each includes:

* Input file → `inputs/`
* Intermediate data → `data/`
* Output log → `outputs/`

---

### Ontology Components (`ont/`)

The ontology is built from several components, each written as a `robot template` TSV and turned into `.ttl` automatically:

| Component   | Description                                      |
| ----------- | ------------------------------------------------- |
| Experiments | Links inputs → outputs                           |
| Constraints | Modelling conditions (e.g. distances, dihedrals) |
| Results     | Measured properties from calculations            |
| Annotations | Your own review notes, optionally linked to a literature DOI |

---

## How the Ontology is Built

**A real, honest note first:** this section used to walk through five
separate, hand-typed `robot template`/`robot merge` commands. That
approach had a real, documented failure mode - a shared template file
(e.g. `spectra_result_template_instances.tsv`) picking up a new row
from a later step, but the `.ttl` built from it *earlier* never being
regenerated, silently leaving the final merge using stale data with no
error at any point. `build_ontology_graph()` (in `ont_mm`) exists
specifically to eliminate this - it rebuilds every template type fresh,
every time, so there's no "did I remember to regenerate the shared
one?" bookkeeping left for you to get wrong. This is the real,
recommended way to build the graph now - not an alternative to the
manual steps, a replacement for them.

**Step 0 - check your setup** (only needs doing once per machine):

```r
source("ont_mm/scripts/check_robot_setup.R")
check_robot_setup()
```

Confirms `robot` is on your PATH and a compatible Java (11+) is being
used. If it reports the wrong Java version, see the function's own
documentation for how to point at a compatible one directly rather
than fighting your system `PATH`.

**Step 1 - extract and write instance data:**

```r
my_code_dir     <- "."   # wherever gamess_functions/ and ont_mm/ both live
my_input_dir    <- "examples/inputs/"
my_output_dir   <- "examples/outputs/"
my_ontology_dir <- "examples/ont/"

source(file.path(my_code_dir, "ont_mm/scripts/process_gamess_directory.R"))
# ... plus every writer/extractor process_gamess_directory() depends on -
# see the main README's own "Using This With Your Own Data" section for
# the complete list of files to source first.

process_gamess_directory(
  input_dir  = my_input_dir,
  output_dir = my_output_dir,
  ontology_dir = my_ontology_dir,
  experiment_template_file = file.path(my_code_dir, "ont_mm/templates/experiment_template.tsv")
)
```

This is what actually reads `rem01.log` etc. and writes the
`*_template_instances.tsv` files in `examples/ont/` - the raw
ingredients `build_ontology_graph()` turns into a real graph next.

**Step 1b (optional) - your own notes and literature:**

```r
source(file.path(my_code_dir, "gamess_functions/R/notes_to_annotations.R"))
rows <- notes_to_annotations(file.path(my_ontology_dir, "run_notes.tsv"))
write_annotations(rows, file.path(my_ontology_dir, "annotation_template_instances.tsv"))
```

`run_notes.tsv` in this folder is a real, working example - including
one row with the optional third column, linking `rem01b` to a real DOI
(the Gainesville Core ontology's own founding paper). `doi_notes.tsv`
shows the same link the other way round - see the main README's
`run_notes.tsv` section for the full explanation of this feature.

**Step 2 - build the graph:**

```r
source(file.path(my_code_dir, "ont_mm/scripts/build_ontology_graph.R"))

build_ontology_graph(
  ontology_dir = my_ontology_dir,
  release_file = file.path(my_code_dir, "ont_mm/releases/2026-08-08/gc_core.ttl"),
  output_file  = file.path(my_ontology_dir, "gc_core_full.ttl")
)
```

One function call replaces every `robot template`/`robot merge`
command this section used to walk through by hand - and every template
type is rebuilt fresh each time, so the staleness bug described above
simply can't happen. Watch the console output: it tells you which
template types were actually built vs. skipped (no instance data
found for that type) - this is normal, not every dataset has every
result type.

**Step 3 (recommended) - validate the graph:**

```r
source(file.path(my_code_dir, "gamess_functions/R/validate_graph_shacl.R"))

result <- validate_graph_shacl(
  graph_file  = file.path(my_ontology_dir, "gc_core_full.ttl"),
  shapes_file = file.path(my_code_dir, "ont_mm/shapes/gc_core_shapes.ttl")
)
```

Checks the graph against real data-quality rules - not just "is this
valid OWL," but "does the data actually make sense" (e.g. a
`gc:hasFloatValue` that's silently a string instead of a number would
still be valid OWL, but is wrong data - `robot report` wouldn't catch
this, SHACL does). Each shape in `gc_core_shapes.ttl` is tied to a real
bug found during this project's own development, not a theoretical
example. Requires `shacl` (part of [Apache
Jena](https://jena.apache.org/download/)) on your PATH - see the main
README's own SHACL section for setup details and a real, confirmed
Java-detection quirk worth knowing about if this fails unexpectedly.

---

## What You Get

The final ontology links:

* Input files → experiments
* Experiments → constraints
* Experiments → outputs
* Calculations → measured results
* Experiments → your own review notes, and optionally the literature they're based on

This creates a **fully traceable workflow graph**.

---

## Querying the Graph

**No SPARQL needed** - a full overview in one call:

```r
source(file.path(my_code_dir, "gamess_functions/R/summarize_graph.R"))
summarize_graph(file.path(my_ontology_dir, "gc_core_full.ttl"))
```

**A specific question**, e.g. every output file generated from a given input:

```r
source(file.path(my_code_dir, "gamess_functions/R/sparql_to_file.R"))

sparql_query(
  graph_file = file.path(my_ontology_dir, "gc_core_full.ttl"),
  query = "SELECT ?output WHERE {
             ?exp ex:hasInputFile ex:file_rem01_inp .
             ?output prov:wasGeneratedBy ?exp .
           }"
)
```

The equivalent raw SPARQL, if you want to run it directly via `robot query`:

```sparql
PREFIX ex: <http://example.org/>
PREFIX prov: <http://www.w3.org/ns/prov#>

SELECT ?output
WHERE {
  ?exp ex:hasInputFile ex:file_rem01_inp .
  ?output prov:wasGeneratedBy ?exp .
}
```

returns

```
output
http://example.org/file_rem01_dat
http://example.org/file_rem01_log
http://example.org/file_rem01a_inp
```

### Why does this query return multiple types of files?

This query retrieves all entities generated by experiments that used a given input file.

Because the ontology models full workflow provenance, outputs are not limited to final results. They include:

- Final computational outputs (e.g. `.dat`, `.log`)
- Intermediate artefacts that become inputs for subsequent steps (e.g. `.inp` files)

This reflects the fact that molecular modelling workflows are iterative, where outputs from one stage often become inputs to the next.

---

## Notes

* Prefixes are included automatically during template generation
* The ontology uses a simplified example namespace: `http://example.org/`
* File paths in this example are local and intended for demonstration only

---

## Next Steps

* Modify the `.tsv` instance files (or, better, your own real `.log`/`.inp` files and `process_gamess_directory()`) to represent your own workflow
* Add your own `run_notes.tsv`/`doi_notes.tsv` entries as you review real results
* Rebuild with `build_ontology_graph()` and re-validate with `validate_graph_shacl()` as your project grows
* Extend templates to include additional concepts (e.g. new constraints or result types)
