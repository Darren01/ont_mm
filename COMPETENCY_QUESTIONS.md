# Competency Questions

This document exists to answer one question honestly, before you
commit to cloning anything: **what can this ontology actually let you
ask and answer?** Formal ontology methodology says to write these
*before* building anything - we didn't, so this is the retroactive
version, checked against what's genuinely been built and tested, not
what was intended or hoped for.

Every query below is tested against the real
[`caa` example dataset](./examples/caa/) - a complete, messy, real
computational chemistry project, not a toy. You can try any of these
yourself with zero setup at all in the
[SPARQL playground](./tools/sparql_playground.html) (download and open
directly in your browser), or run them properly against your own data
once you've built a graph.

**Status key:** ✅ answerable today · ⚠️ partially answerable, with a
real, specific gap · ❌ not answerable yet, but planned

**A real, important limitation of the playground tool, found by
actually running every query below against it:** `rdflib.js` (the
engine behind the playground) has a confirmed, open, unresolved bug
with `FILTER` - [its own GitHub issue #535](https://github.com/linkeddata/rdflib.js/issues/535)
states plainly that `FILTER(contains(...))` "does not filter
anything." Real testing here found the same for `FILTER(?var IN
(...))` and numeric comparisons. **The playground tool now works
around this itself** - it strips `FILTER(...)`/`LIMIT`/`OFFSET` from
your query before sending it to `rdflib.js`, and applies all three by
hand to the results afterwards, so the queries below work correctly
*in the playground specifically*. Run the same raw SPARQL text against
a real engine (`robot query`, Jena, etc.) and it should also work
there directly, without needing any of this. `STRAFTER`/`BIND`-style
expressions were also tested and found unreliable in `rdflib.js` -
the playground's own short-label toggle is the reliable way to get
short, readable labels within the tool itself.

Ordered roughly easiest to hardest - by how many hops through the
graph a question needs, not by how interesting the question is.

---

## 1. How many experiments of each type exist?

**Status: ✅ Answerable. Verified working.**

```sparql
PREFIX gc: <http://purl.org/gc/>

SELECT ?exp ?type WHERE {
  ?exp a ?type .
  FILTER(?type IN (gc:GeometryOptimization, gc:SinglePoint,
                    gc:VibrationalAnalysis, gc:SaddlePoint, gc:IRC))
}
ORDER BY ?type ?exp
```

## 2. What review notes has the researcher recorded, and for which experiments?

**Status: ✅ Answerable. Verified working.**

```sparql
PREFIX gc: <http://purl.org/gc/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

SELECT ?exp ?comment WHERE {
  ?exp a gc:MolecularComputation .
  ?exp skos:editorialNote ?comment .
}
ORDER BY ?exp
```

## 3. Which output files were generated from a given input file?

**Status: ✅ Answerable. Verified working.**

```sparql
PREFIX ex: <http://example.org/>
PREFIX prov: <http://www.w3.org/ns/prov#>

SELECT ?output WHERE {
  ?exp ex:hasInputFile ex:file_caa001a_inp .
  ?output prov:wasGeneratedBy ?exp .
}
```

**This is a template, not a one-off** - swap `ex:file_caa001a_inp` for
any other experiment's own input file URI (e.g.
`ex:file_caa005bTSa_inp`) to trace provenance for a completely
different run. This is the real, general answer to "where did this
output actually come from?" for any experiment in the graph, not just
the one shown here.

## 4. What geometric constraints were applied in a given experiment, and what were their target values and units?

**Status: ✅ Answerable. Verified working.**

```sparql
PREFIX gc: <http://purl.org/gc/>
PREFIX ex: <http://example.org/>

SELECT ?constraint ?type ?target ?unit WHERE {
  ?constraint a ?type ; ex:targetValue ?target ; gc:hasUnit ?unit .
  FILTER(?type IN (ex:DistanceConstraint, ex:AngleConstraint, ex:DihedralConstraint))
}
ORDER BY ?constraint
```

Shortening the long `?constraint`/`?type` URIs down to just their
readable local names: the playground's own short-label toggle does
this reliably within the tool. `STRAFTER`/`BIND` expressions were
tried as a SPARQL-native alternative and found *not* to work
reliably in `rdflib.js` - if you're running this query somewhere else
entirely (`robot query`, a real Jena endpoint), `STRAFTER(STR(?var),
"http://example.org/")` is the correct SPARQL 1.1 approach and should
work fine there.

## 5. Which experiments are linked to a specific published paper?

**Status: ✅ Answerable in principle - the mechanism itself is proven
working elsewhere in this project.** Currently returns no results
against the real `caa` graph - traced honestly: the source
`run_notes.tsv` no longer has a DOI recorded on any line (very likely
lost across this project's several rebuilds), not a bug in the
underlying linking mechanism. Kept in this document deliberately -
genuinely useful once literature links are added back.

```sparql
PREFIX dcterms: <http://purl.org/dc/terms/>

SELECT ?exp WHERE {
  ?exp dcterms:relation <https://doi.org/10.1021/ja00249a034> .
}
```

## 6. Which experiment used a specific, known constraint value?

**Status: ✅ Answerable. Verified working**, once the playground's
`FILTER` workaround was in place. A real, documented gotcha worth
knowing regardless of which tool runs this: a bare number in a triple
pattern parses as `xsd:decimal`, which won't match this project's
`xsd:float` data as an exact term - `FILTER`'s numeric comparison
works correctly across both, a direct triple-pattern match doesn't.

```sparql
PREFIX ex: <http://example.org/>

SELECT ?constraint WHERE {
  ?constraint ex:targetValue ?target .
  FILTER(?target = 1.2)
}
```

## 7. Find a successful run of a given type, at a given level of theory, with its input/output/data files

**Status: ⚠️ Partially answerable** - the type filter and file lookup
now work correctly with the playground's `FILTER` fix in place. Two
real gaps remain, unrelated to the `FILTER` issue:

```sparql
PREFIX gc: <http://purl.org/gc/>
PREFIX ex: <http://example.org/>

SELECT ?exp ?type ?inputFile ?outputFile WHERE {
  ?exp a ?type .
  FILTER(?type IN (gc:GeometryOptimization, gc:SaddlePoint, gc:SinglePoint))
  OPTIONAL { ?exp ex:hasInputFile ?inputFile . }
  OPTIONAL { ?exp ex:hasOutputFile ?outputFile . }
}
ORDER BY ?type ?exp
```

1. **No level-of-theory filter is possible.** The base ontology already
   *defines* `gc:hasMethod`/`gc:hasBasisSet` as valid properties - but
   no experiment in this graph actually has them populated. Planned,
   not yet done.
2. **The `.dat` file isn't tracked at all.** Only `hasInputFile`
   (`.inp`) and `hasOutputFile` (`.log`) exist. Also planned.

## 8. Which results show an imaginary (negative) frequency?

**Status: ✅ Answerable. Verified working**, once the playground's
`FILTER` fix was in place - this was one of the queries directly
confirming the `rdflib.js` bug in the first place (it originally
returned every frequency, not just the imaginary ones).

```sparql
PREFIX gc: <http://purl.org/gc/>

SELECT ?spectrum ?freq WHERE {
  ?spectrum gc:hasFrequencyPeak ?peak .
  ?peak gc:hasFrequency ?fv .
  ?fv gc:hasFloatValue ?freq .
  FILTER(?freq < 0)
}
ORDER BY ?spectrum ?freq
```

**A separate, bigger question worth its own discussion, not solved
here:** should every frequency really be extracted into the graph at
all, or would it be enough for the graph to point to *which file*
contains the frequency data, with extraction only happening on demand?
Real trade-off between a fully self-contained graph and a leaner one
that leans on the underlying files more - worth a dedicated
conversation later, not a quick decision here.

## 9. Does a given transition state show exactly one imaginary frequency, and a given minimum show zero?

**Status: ✅ Answerable. Verified working**, once the `FILTER` fix was
in place - same root cause as #8.

```sparql
PREFIX gc: <http://purl.org/gc/>

SELECT ?spectrum (COUNT(?freq) AS ?imaginaryCount) WHERE {
  ?spectrum gc:hasFrequencyPeak ?peak .
  ?peak gc:hasFrequency ?fv .
  ?fv gc:hasFloatValue ?freq .
  FILTER(?freq < 0)
}
GROUP BY ?spectrum
```

## 10. Which annotated experiments also show a data-quality issue (an imaginary frequency)?

**Status: ✅ Answerable. Verified working**, once the `FILTER` fix was
in place - a real, empty result here is a genuine finding about this
project's own data (its annotated experiments don't currently overlap
with the ones showing an imaginary frequency), not a bug.

```sparql
PREFIX gc: <http://purl.org/gc/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

SELECT ?exp ?comment ?freq WHERE {
  ?exp a gc:MolecularComputation .
  ?exp skos:editorialNote ?comment .
  ?exp gc:hasResult ?spectrum .
  ?spectrum gc:hasFrequencyPeak ?peak .
  ?peak gc:hasFrequency ?fv .
  ?fv gc:hasFloatValue ?freq .
  FILTER(?freq < 0)
}
```

## 11. What is the electronic energy, ZPE, enthalpy, entropy, and Gibbs free energy for a given experiment's result?

**Status: ✅ Answerable.** Every property confirmed to exist exactly as
written - genuinely deeper than it looks, since each thermodynamic
quantity is its own separate entity (the same reification pattern as
frequencies), not a literal sitting directly on the energies record.
The playground's short-label toggle now also rounds long decimal
values for display (e.g. `-766.3719959497` → `-766.372`), keeping the
full, unrounded value available on hover.

```sparql
PREFIX gc: <http://purl.org/gc/>

SELECT ?exp ?zpeVal ?enthalpyVal ?entropyVal ?gibbsVal ?electronicVal WHERE {
  ?exp gc:hasResult ?energies .
  OPTIONAL { ?energies gc:hasZeroPointEnergy ?zpe . ?zpe gc:hasFloatValue ?zpeVal . }
  OPTIONAL { ?energies gc:hasEnthalpy ?enthalpy . ?enthalpy gc:hasFloatValue ?enthalpyVal . }
  OPTIONAL { ?energies gc:hasEntropy ?entropy . ?entropy gc:hasFloatValue ?entropyVal . }
  OPTIONAL { ?energies gc:hasGibbsFreeEnergy ?gibbs . ?gibbs gc:hasFloatValue ?gibbsVal . }
  OPTIONAL { ?energies gc:hasElectronicEnergy ?elec . ?elec gc:hasFloatValue ?electronicVal . }
}
```

## 12. What is the full chain of files (input → intermediate data → output) for a given experiment?

**Status: ⚠️ Partially answerable - blocked by the same gap as #7.**
`hasInputFile`/`hasOutputFile` work; the intermediate `.dat` file has
no property to query for at all.

```sparql
PREFIX ex: <http://example.org/>

SELECT ?exp ?inputFile ?outputFile WHERE {
  OPTIONAL { ?exp ex:hasInputFile ?inputFile . }
  OPTIONAL { ?exp ex:hasOutputFile ?outputFile . }
}
```

## 13. What are the points along a given reaction path, in order, with their energies?

**Status: ⚠️ Partially answerable, genuinely untested.** `hasIndex`
gives real ordering directly; `hasPathEnergy` follows the same
reification pattern as everything else energy-related, needing one
more hop to `hasFloatValue`. Schema-verified but not yet actually run.

```sparql
PREFIX gc: <http://purl.org/gc/>

SELECT ?point ?index ?energyVal WHERE {
  ?path gc:hasReactionPathPoint ?point .
  ?point gc:hasIndex ?index .
  OPTIONAL { ?point gc:hasPathEnergy ?energy . ?energy gc:hasFloatValue ?energyVal . }
}
ORDER BY ?index
```

## 14. Which experiments used a specific method/basis-set combination?

**Status: ❌ Not answerable.** Same root gap as #7's level-of-theory
issue - `gc:hasMethod`/`gc:hasBasisSet` exist in the schema, populated
on no experiment.

## 15. What is the activation energy (forward/reverse barrier) and reaction energy for a given pathway?

**Status: ❌ Not really answerable as a single SPARQL query today.**
Every individual energy value needed is in the graph (see #11), but
the actual *subtraction* has always been done by hand or in R
(`compare_energies()`), not in SPARQL. Genuinely open, not solved.

---

## Noted for later, not built yet

- **A guided narrative walkthrough**: starting from #1's basic
  inventory, narrowing to a specific transition state, tracing its
  provenance (#3), then examining the geometric constraints that
  produced it (#4) - a real, connected story showing how these
  questions actually chain together in practice, rather than reading
  as a list of disconnected examples. Where this belongs in the
  document, and its full shape, still to be worked out.
- **Whether extracting every frequency into the graph is even the
  right design** (see the note under #8) - a real, open question about
  this project's own architecture, not just a documentation gap.
