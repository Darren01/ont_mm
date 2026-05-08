# Ontology Extraction and Cleanup Pipeline

This ontology build process uses ROBOT to extract and assemble a modular subset of terms and axioms from source ontologies.

Initially, separate term lists were prepared for classes and object properties. However, this approach resulted in incomplete extraction of logical axioms (such as domain and range constraints), because the MIREOT extraction method only retrieves minimal hierarchical information and does not include all relevant axioms.

To address this, the workflow was revised to:

Combine all required terms (classes and object properties) into a single term file
Use the --method STAR extraction method instead of MIREOT

The STAR method retrieves all axioms referencing the selected terms, ensuring that important logical constructs (e.g. domain and range axioms, restrictions) are preserved in the extracted module.

However, this more complete extraction also introduced additional, unintended content from imported ontologies. In this case, elements of a periodic table ontology were included due to logical dependencies (e.g. via property domains and ranges).

To resolve this, a cleanup step was initially introduced using SPARQL Update queries executed via the ROBOT query command. 

However, it was found that the best way to build the module ontology was not to carry any imports into it.

The required terms - both classes and properties - were collected in gc_terms.txt and extracted using the STAR method using the code shown below.

```
robot extract --method STAR --input ~/Projects/active/ont_mm/source/gc.owl --term-file ~/Projects/active/ont_mm/docs/gc_terms.txt --output ~/Projects/active/ont_mm/modules/gc_module.ttl
```
A similar process was used to extract the appropriate terms from the prov-o.owl source ontology where the required terms where collected in prov_terms.txt and extracted using the STAR method using the code shown below.

```
robot extract --method STAR --input ~/Projects/active/ont_mm/source/prov-o.owl --term-file ~/Projects/active/ont_mm/docs/prov_terms.txt --output ~/Projects/active/ont_mm/modules/prov_module.ttl
```



