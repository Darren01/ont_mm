In this folder the ontology was build using the modules prepared earlier using the following code.

**Update (v0.8.2 onwards):** `gc_module.ttl` (the STAR-extracted subset) has
been retired. `source/gnvc_improved.owl` is now merged directly - see
`modules/README.md` for why this became possible and preferable. The merge
command is now:

```
robot merge \
  --input ~/Projects/active/ont_mm/source/gnvc_improved.owl \
  --input ~/Projects/active/ont_mm/modules/prov_module.ttl \
  --input ~/Projects/active/ont_mm/modules/pesscan_module.ttl \
  --output ~/Projects/active/ont_mm/builds/gc_core.ttl
```

**Correction (release 2026-10-07):** the merge above has always also
included `modules/pesscan_module.ttl` - the 2026-08-08 release contains
its terms (`ex:hasCalculation` and the OntoPESScan classes) - but the
command as first documented omitted it. Before building 2026-10-07 the
2026-08-08 release was rebuilt from its sources with this recipe (merge
as above, then the two `robot query --update` steps below, then
`robot annotate`) and compared with the committed file: the two are
triple-for-triple identical, so the recipe is reliable. Only the byte
layout differs, which is just ROBOT's output formatting.

(`prov_module.ttl` is unaffected by this change - it's a separate STAR
extraction from `prov-o.owl`, unrelated to `gc_terms.txt`/`gnvc_improved.owl`.)

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

The ontology was annotated with a version and stored in the /releases folder.

```
robot annotate \
  --input builds/gc_core.ttl \
  --ontology-iri "http://purl.org/gc/core" \
  --version-iri "http://purl.org/gc/core/2026-05-08/gc_core.ttl" \
  --prefix "dcterms: http://purl.org/dc/terms/" \
  --annotation dcterms:title "gc_core ontology" \
  --output releases/2026-05-08/gc_core.ttl
  ```

**Release 2026-10-07 (gnvc_improved.owl v0.8.8):** six properties that
listed several `rdfs:domain` classes as separate statements (read by
OWL as "all of", intended as "any of") now each have one union domain.
Compared with 2026-08-08 the release differs only by those 15 domain
statements becoming 6 unions, plus the version annotations. See the
GC-Ontology-Mirror changelog (v0.8.8) for the reasoning and evidence.
