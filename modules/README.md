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

## Retirement of gc_module.ttl (v0.8.2)

The STAR extraction step for the GC module was a workaround for two
problems that no longer apply: `gc.owl` (the pre-repair source) had
unresolved import issues that leaked unwanted content (e.g. periodic table
ontology elements) into anything that imported it wholesale, and the file
itself had structural defects (documented in `GC-Ontology-Mirror`'s own
README) that made direct use unreliable.

Both are now fixed. `gnvc_improved.owl` (the repaired GNVC fork,
`GC-Ontology-Mirror`) has no unresolved imports and has had nine structural
defects repaired since the STAR-extraction workaround was first introduced.
The whole point of that repair work was to make the full ontology directly
usable again - so as of v0.8.2, it is: `gc_module.ttl` is retired, and
`source/gnvc_improved.owl` is merged directly in `builds/README.md`'s
build process.

`gc_terms.txt` is kept for historical reference (and because
`prov_terms.txt`'s extraction process, above, is unaffected and still
needed) but no longer drives any active build step. This also removes the
recurring failure mode of Phase 3 development: a term used in a new
`gc_terms.txt`-based extraction being silently absent from the built
module because nobody remembered to add it (this happened repeatedly -
`gc:VibrationalAnalysis`, the class hierarchy terms, `gc:cm-1` - each only
discovered via a downstream SPARQL check, not at build time). Merging the
full ontology directly means every term that exists in the source is now
always available; no term list to keep in sync.



