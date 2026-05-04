In this folder the ontology was build using the modules prepared earlier using the following code.

```
robot merge --input ~/Projects/active/ont_mm/modules/gc_module.ttl --input ~/Projects/active/ont_mm/modules/prov_module.ttl --output ~/Projects/active/ont_mm/builds/gc_core.ttl
```

At this stage the bild ontology was checked with the following robot code.

```
robot report --input ~/Projects/active/ont_mm/builds/gc_core.ttl --format tsv
```

which gave a number of violations.

The first fix used the following robot code.

```
robot query \
  --input ~/Projects/active/ont_mm/builds/gc_core.ttl \
  --update ~/Projects/active/ont_mm/docs/fix_label.sparql \
  annotate \
  --prefix "dc: http://purl.org/dc/elements/1.1/" \
  --annotation dc:title "GC Core Ontology" \
  --annotation dc:description "A core ontology for quantum chemistry calculations combining the Gainesville Core Ontology and PROV-O provenance terms." \
  --annotation dc:license "https://creativecommons.org/licenses/by/4.0/" \
  --output ~/Projects/active/ont_mm/builds/gc_core.ttl
 ```
 
 But this still needed further repair 

