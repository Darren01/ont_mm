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
  --ontology builds/gc_core.ttl \
  --ontology-iri "http://purl.org/gc/core" \
  --prefix "ex: http://example.org/" \
  --output examples/ont/experiment_template.ttl
```

---

### Step 2 — Generate Constraint Ontology

```
robot template \
  --template examples/ont/constraint_template_instances.tsv \
  --ontology builds/gc_core.ttl \
  --ontology-iri "http://purl.org/gc/core" \
  --prefix "gc: http://purl.org/gc/" \
  --prefix "ex: http://example.org/" \
  --output examples/ont/constraint_template.ttl
```

---

### Step 3 — Generate Results Ontology

```
robot template \
  --template examples/ont/results_template_instances.tsv \
  --ontology builds/gc_core.ttl \
  --ontology-iri "http://purl.org/gc/core" \
  --prefix "gc: http://purl.org/gc/" \
  --prefix "ex: http://example.org/" \
  --output examples/ont/results_template.ttl
```

---

### Step 4 — Merge into a Single Ontology

```
robot merge \
  --input examples/ont/constraint_template.ttl \
  --input examples/ont/experiment_template.ttl \
  --input examples/ont/results_template.ttl \
  --output examples/ont/gc_core_full.ttl
```

This produces the complete instantiated ontology:

```
examples/ont/gc_core_full.ttl
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

SELECT ?output
WHERE {
  ?exp ex:hasInputFile ex:file_rem01_inp .
  ?exp ex:hasOutputFile ?output .
}
```

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

