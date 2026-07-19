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
4. Everything is combined into a **single, queryable ontology**

The workflow corresponds to the left-hand side of *Scheme 1* in the main project documentation.

---

## Folder Structure

```
examples/
├── data/        # Intermediate data files (.dat)
├── inputs/      # Input files (.inp)
├── outputs/     # Output log files (.log)
├── ont/         # Ontology templates, instances, and outputs
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

The ontology is built from three components:

| Component   | Description                                      |
| ----------- | ------------------------------------------------ |
| Constraints | Modelling conditions (e.g. distances, dihedrals) |
| Experiments | Links inputs → outputs                           |
| Results     | Measured properties from calculations            |

Each component has:

* A **template** (`*.ttl`)
* An **instance file** (`*.tsv`)

---

## How the Ontology is Built

This example uses ROBOT to convert tabular templates into OWL and then merge them.

---

### Step 1 — Generate Experiment Ontology

```
robot template \
  --template examples/ont/experiment_template_instances.tsv \
  --merge-before \
  --input releases/2026-07-19/gc_core.ttl \
  --ontology-iri "http://purl.org/gc/core" \
  --prefix "gc: http://purl.org/gc/" \
  --prefix "ex: http://example.org/" \
  --prefix "prov: http://www.w3.org/ns/prov#" \
  --output examples/ont/experiment_template.ttl
```

---

### Step 2 — Generate Constraint Ontology

```
robot template \
  --template examples/ont/constraint_template_instances.tsv \
  --merge-before \
  --input releases/2026-07-19/gc_core.ttl \
  --ontology-iri "http://purl.org/gc/core" \
  --prefix "gc: http://purl.org/gc/" \
  --prefix "ex: http://example.org/" \
  --output examples/ont/constraint_template.ttl
```

---

### Step 3 — Generate Results Ontology (bond distances, angles, dihedrals)

```
robot template \
  --template examples/ont/results_template_instances.tsv \
  --merge-before \
  --input releases/2026-07-19/gc_core.ttl \
  --ontology-iri "http://purl.org/gc/core" \
  --prefix "gc: http://purl.org/gc/" \
  --prefix "ex: http://example.org/" \
  --output examples/ont/results_template.ttl
```

---

### Step 4 — Generate Frequency/Intensity Results

Four linked templates, reflecting the real gc: reification chain
(experiment --hasResult--> VibrationalSpectra --hasFrequencyPeak-->
FrequencyPeak --hasFrequency/hasIntensity--> FloatValue). Run in this
order - each re-opens or references IDs created by the previous one.

```
robot template \
  --template examples/ont/spectra_result_template_instances.tsv \
  --merge-before \
  --input releases/2026-07-19/gc_core.ttl \
  --ontology-iri "http://purl.org/gc/core" \
  --prefix "gc: http://purl.org/gc/" \
  --prefix "ex: http://example.org/" \
  --output examples/ont/spectra_result_template.ttl

robot template \
  --template examples/ont/spectra_template_instances.tsv \
  --merge-before \
  --input releases/2026-07-19/gc_core.ttl \
  --ontology-iri "http://purl.org/gc/core" \
  --prefix "gc: http://purl.org/gc/" \
  --prefix "ex: http://example.org/" \
  --output examples/ont/spectra_template.ttl

robot template \
  --template examples/ont/peak_template_instances.tsv \
  --merge-before \
  --input releases/2026-07-19/gc_core.ttl \
  --ontology-iri "http://purl.org/gc/core" \
  --prefix "gc: http://purl.org/gc/" \
  --prefix "ex: http://example.org/" \
  --output examples/ont/peak_template.ttl

robot template \
  --template examples/ont/float_value_template_instances.tsv \
  --merge-before \
  --input releases/2026-07-19/gc_core.ttl \
  --ontology-iri "http://purl.org/gc/core" \
  --prefix "gc: http://purl.org/gc/" \
  --prefix "ex: http://example.org/" \
  --output examples/ont/float_value_template.ttl
```

---

### Step 4b — Generate Thermochemistry Results

A separate result chain (experiment --hasResult--> SystemEnergies
--hasZeroPointEnergy/hasEnthalpy/hasEntropy/hasGibbsFreeEnergy--> FloatValue),
three levels rather than frequency's four (SystemEnergies holds multiple
energy properties directly - no intermediate node like FrequencyPeak is
needed). Only produced for experiments where GAMESS actually completed a
thermochemistry table (RUNTYP=OPTIMIZE + HSSEND=.t., same jobs that also
get a frequency spectrum - both results coexist for the same experiment,
via two separate hasResult rows, since hasResult is not a
FunctionalProperty).

**Standing rule for any future writer that touches a shared template
(spectra_result_template_instances.tsv or float_value_template_instances.tsv,
and likely more as NMR/geometry writers are added): after running that
writer, re-run the `robot template` command for every shared file it
touched, not just the new template being introduced.** Treat "regenerate
every Step 4/4b/4c/... .ttl" as one atomic block that always runs in
full before Step 5's merge - trying to reason about which specific files
were "affected" by a given writer run is exactly the kind of manual
bookkeeping that has caused a silent, no-error staleness bug every time
it's been relied on so far in this project.

`spectra_result_template_instances.tsv` and `float_value_template_instances.tsv`
are shared with Step 4 - process_thermo_results() (gamess_functions)
appends to them rather than regenerating, and dedups against
`energies_template_instances.tsv` specifically rather than the shared
files, so re-running process_thermo_results() is always safe.

**Because `spectra_result_template_instances.tsv` is shared and just got
a new row appended to it, `spectra_result_template.ttl` (built in Step 4)
is now stale and must be regenerated too - not just the new
`energies_template.ttl` below. This is easy to miss (found the hard way:
the merge silently used the old, one-row version and `hasResult` only
pointed at the spectrum, not the new energies individual, with no error
at any step). Re-run Step 4's first command before continuing:**

```
robot template \
  --template examples/ont/spectra_result_template_instances.tsv \
  --merge-before \
  --input releases/2026-07-19/gc_core.ttl \
  --ontology-iri "http://purl.org/gc/core" \
  --prefix "gc: http://purl.org/gc/" \
  --prefix "ex: http://example.org/" \
  --prefix "prov: http://www.w3.org/ns/prov#" \
  --output examples/ont/spectra_result_template.ttl
```

Then generate the energies template itself:

```
robot template \
  --template examples/ont/energies_template_instances.tsv \
  --merge-before \
  --input releases/2026-07-19/gc_core.ttl \
  --ontology-iri "http://purl.org/gc/core" \
  --prefix "gc: http://purl.org/gc/" \
  --prefix "ex: http://example.org/" \
  --output examples/ont/energies_template.ttl
```

---

### Step 5 — Merge into a Single Ontology

```
robot merge \
  --input examples/ont/experiment_template.ttl \
  --input examples/ont/constraint_template.ttl \
  --input examples/ont/results_template.ttl \
  --input examples/ont/spectra_result_template.ttl \
  --input examples/ont/spectra_template.ttl \
  --input examples/ont/peak_template.ttl \
  --input examples/ont/float_value_template.ttl \
  --input examples/ont/energies_template.ttl \
  --output examples/ont/gc_core_full_2026-07-19.ttl
```

This produces the complete instantiated ontology:

```
examples/ont/gc_core_full_2026-07-19.ttl
```

---

## What You Get

The final ontology links:

* Input files → experiments
* Experiments → constraints
* Experiments → outputs
* Calculations → measured results

This creates a **fully traceable workflow graph**.

---

## Example Query

Retrieve all output files generated from a given input file:

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

output
http://example.org/file_rem01_dat
http://example.org/file_rem01_log
http://example.org/file_rem01a_inp

## Why does this query return multiple types of files?

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

* Modify the `.tsv` instance files to represent your own workflow
* Regenerate the ontology using the same commands
* Extend templates to include additional concepts (e.g. new constraints or result types)

---

## Scripting

* explain here about the R code and give the working example ... and where it fits into the scheme above ...
