In this folder the ontology was build using the modules prepared earlier using the following code.

```
robot merge --input ~/Projects/active/ont_mm/modules/gc_module.ttl --input ~/Projects/active/ont_mm/modules/prov_module.ttl --output ~/Projects/active/ont_mm/builds/gc_core.ttl
```

At this stage the build ontology was checked with the following robot code.

```
robot report --input ~/Projects/active/ont_mm/builds/gc_core.ttl --format tsv
```

which gave a number of violations which were fixed with the following robot code.

```
robot query --input ~/Projects/active/ont_mm/builds/gc_core.ttl --update ~/Projects/active/ont_mm/docs/add_metadata.sparql --output ~/Projects/active/ont_mm/builds/gc_core.ttl
robot query --input ~/Projects/active/ont_mm/builds/gc_core.ttl --update ~/Projects/active/ont_mm/docs/fix_label.sparql --output ~/Projects/active/ont_mm/builds/gc_core.ttl
 ```
 
This still had two errors with rdfs:label Atom@en and Atoms@en which can be fixed at a later stage.

