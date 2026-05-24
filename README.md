# Molecular Modelling Project Ontology (ont_mm)

A domain ontology for representing and structuring molecular modelling workflows, with a focus on **traceability**, **reproducibility**, and **data integration**.

## 🚀 Quick Start

👉 **New here? Start with the working example:**

examples/

Follow the guide in:

examples/README.md

In a few minutes, you will:

* Generate ontology instances from templates
* Build a complete workflow graph
* Run a working SPARQL query

This is the fastest way to understand how the ontology works in practice.

## Overview

Molecular modelling projects generate complex networks of files, parameters, and results. While these are often stored in well-defined directory structures, the relationships between them are rarely captured in a formal, machine-readable way.

This project develops an ontology to represent those relationships as a graph, enabling structured understanding of how modelling work is organised, executed, and interpreted.

The focus is on **pre-publication computational workflows** —the exploratory phase where models are built, tested, and refined.

![ontology map and build path](./images/ont_mm_scheme1.png "Scheme 1 Ontology map and build")

---

## Motivation

Typical challenges in molecular modelling projects include:

* Track provenance of computed results
* Reproduce calculations reliably
* Understand dependencies between inputs, methods and outputs

This ontology addresses these by providing a formal framework linking:

* Files
* Computational constraints
* Generated results
* Experiment sequences

---

## Scope

### 1. Files

* File types and naming conventions
* Relationships (inputs, outputs, intermediates)
* File dependencies within workflows

### 2. Constraints

* Computational methods and parameters
* Assumptions and modelling conditions
* Simulation configurations

### 3. Results

* Output data and derived properties
* Links to originating inputs and constraints
* Metadata for interpretation and validation

---

## Objectives

* Define a consistent schema for molecular modelling projects
* Enable full traceability from results back to inputs
* Support reproducible and reusable computational workflows
* Bridge raw simulation data and semantic representations

---

## Approach

The ontology builds on established standards:

Gainesville Core Ontology (GC) for domain concepts
PROV-O for provenance modelling

Relevant terms are extracted, modularised, and combined into a coherent domain ontology.

Structured data is generated using:

- **ROBOT templates** (TSV → RDF/OWL)  
- **R scripts** for parsing and transformation

---

## Template System (ROBOT)

All ontology instances are generated using ROBOT templates:

Row 1	→	Human-readable headers
Row 2	→	ROBOT template script
Row 3+	→	Data


Example:

ID	Label	Type	provWasGeneratedBy	hasInputFile	hasOutputFile	fileURL
ID	LABEL	TYPE	I prov:wasGeneratedBy	I ex:hasInputFile	I ex:hasOutputFile SPLIT=|	A ex:fileURL

---

## Repository Structure

*(To be defined as the project evolves)*

```text
ont_mm
|--builds				# Combined ontology outputs
|  |--gc_core.ttl
|  |--README.md
|--docs					# Supporting queries and term lists
|  |--fix_annotations.sparql
|  |--fix_license.sparql
|  |--fix_label.sparql
|  |--gc_terms.txt
|  |--prov_terms.txt
|--examples				# a worked example
|  |--data
|  |  |--rem01.dat
|  |  |--rem01a.dat
|  |  |--rem01b.dat
|  |--inputs
|  |  |--rem01.inp
|  |  |--rem01a.inp
|  |  |--rem01b.inp
|  |--ont
|  |  |--constraint_template_instances.tsv
|  |  |--constraint_template.ttl
|  |  |--experiment_template_instances.tsv
|  |  |--experiment_template.ttl
|  |  |--gc_core_full.ttl
|  |  |--results_template_instances.tsv
|  |  |--results_template.ttl
|  |--ont_script
|  |  |--constraint_template_instances_script.tsv
|  |--outputs
|  |  |--rem01.log
|  |  |--rem01a.log
|  |  |--rem01b.log
|  |--README.md
|--images
|  |--ont_mm_scheme1.excalidraw
|  |--ont_mm_scheme1.png
|--modules				# Extracted ontology modules
|  |--gc_module.ttl
|  |--prov_module.ttl
|  |--README.md
|--README.md
|--releases				# versioned ontologies
|  |--2026-05-08
|  |  |--gc_core.ttl
|--scripts				# Processing and build scripts
|  |--process_constraints.R
|--source				# Source ontologies
|  |--catalog-v001.xml
|  |--EMPTY.owl
|  |--gc.owl				# Gainesville Core ontology
|  |--prov-o.owl			# Provenance ontology
|--templates				# Ontology templates
|  |--constraint_template.tsv
|  |--experiment_template.tsv
|  |--results_template.tsv
```

## Current Status

Early-stage but functional:

* Core ontology structure defined
* Term extraction pipeline implemented
* Initial ontology modules created
* Templates for experiments, constraints, and results
* R scripts for generating structured data
* Working end-to-end example

## Future Work

* Introduce SHACL validation for template checking
* Expand ontology coverage
* Improve provenance handling (edge cases)
* Extend results modelling
* Add more SPARQL queries for validation and analysis

## Long-term vision

To provide a reusable framework for structuring computational chemistry workflows as semantic graphs, enabling:

* Reproducibility
* Provenance tracking
* Integration with knowledge systems
* Advanced querying and analysis

## Author

[Darren Rhodes]

## License

This project is licensed under the MIT License – see the [LICENSE](./LICENSE.txt) file for details.

## TOOLS

- [Gamess (US)](https://www.msg.chem.iastate.edu/gamess/)
- [robot](https://robot.obolibrary.org/)
- [RStudio](https://posit.co/download/rstudio-desktop)
- [turtle viewer](https://semantechs.co.uk/turtle-editor-viewer/)







