# Molecular Modelling Project Ontology

A domain ontology for representing and structuring molecular modelling workflows, with a focus on traceability, reproducibility, and data integration.

## Overview

Molecular modelling projects generate complex networks of files, parameters, and results. While these are often stored in well-defined directory structures, the relationships between them are rarely captured in a formal, machine-readable way.

This project develops an ontology to represent those relationships as a graph, enabling structured understanding of how modelling work is organised, executed, and interpreted.

The focus is on **pre-publication computational workflows** —the exploratory phase where models are built, tested, and refined.

## Motivation

Typical challenges in molecular modelling projects include:

* Track provenance of computed results
* Reproduce calculations reliably
* Understand dependencies between inputs, methods and outputs

This ontology addresses these by providing a formal framework linking:

* Files
* Computational constraints
* Generated results

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

## Objectives

* Define a consistent schema for molecular modelling projects
* Enable full traceability from results back to inputs
* Support reproducible and reusable computational workflows

## Approach

The ontology builds on established standards:

Gainesville Core Ontology (GC) for domain concepts
PROV-O for provenance modelling

Relevant terms are extracted, modularised, and combined into a coherent domain ontology.

## Repository Structure

*(To be defined as the project evolves)*

ont_mm
|--builds				# Combined ontology outputs
|  |--gc_core.ttl
|  |--ReadMe.md
|--docs					# Supporting queries and term lists
|  |--fix_annotations.sparql
|  |--fix_license.sparql
|  |--fix_label.sparql
|  |--gc_terms.txt
|  |--prov_terms.txt
|--modules				# Extracted ontology modules
|  |--gc_module.ttl
|  |--prov_module.ttl
|  |--ReadMe.md
|--ReadMe.md
|--scripts				# Processing and build scripts
|--source				# Source ontologies
|  |--catalog-v001.xml
|  |--EMPTY.owl
|  |--gc.owl				# Gainesville Core ontology
|  |--prov-o.owl			# Provenance ontology
|--templates				# Ontology templates

## Current Status

Early-stage development:

* Core structure defined
* Term extraction pipeline in place
* Initial ontology modules created

## Future Work

* Expand ontology coverage
* Add example modelling workflows
* Link ontology to real GAMESS outputs
* Integrate with analysis tools (e.g. R workflows)

## Long-term vision

To provide a reusable, extensible framework for structuring computational chemistry projects, bridging raw simulation data with higher-level analysis and interpretation.

## Author

[Darren Rhodes]

