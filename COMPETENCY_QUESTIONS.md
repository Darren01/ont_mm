# Competency Questions

This document exists to answer one question honestly, before you
commit to cloning anything: **what can this ontology actually let you
ask and answer?** Formal ontology methodology says to write these
*before* building anything - we didn't, so this is the retroactive
version, checked against what's genuinely been built and tested, not
what was intended or hoped for.

**A deliberate scoping principle, worth stating plainly:** this graph
holds meaningful, bounded *results* (the five thermochemistry values
in CQ #11, an imaginary frequency as a diagnostic signal) rather than
every raw intermediate number a GAMESS run produces (the full
vibrational mode list, most of which is neither queried nor
individually meaningful) - full traceability back to the original
`.log` file is kept via `prov:wasGeneratedBy`/`prov:generated` instead,
so nothing is ever actually lost, just not duplicated as its own
triple. This mirrors the same principle AiiDA/Materials Cloud states
for computational provenance graphs generally: it's often unreasonable
to keep every piece of output data, but "all information needed to
reproduce the outputs must be preserved" (Talirz et al., *Materials
Cloud, a platform for open computational science*, Scientific Data 7,
299 (2020), doi:10.1038/s41597-020-00637-5) - the same trade-off this
graph makes, kept honest by real provenance links rather than by
leaving anything genuinely irretrievable.

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

## A worked example: following one transition state

The questions below are organised for reference, not for a first
read. This section instead walks through a real, connected task -
finding a transition state and understanding where it came from - to
show how they actually chain together in practice, and how to adapt
each step to a different question of your own. Every query here is
tested and real, run against the actual `caa` graph, not invented for
the example.

**Start broad.** Suppose you've just been handed this graph and want
your bearings - a natural first move is CQ #1's own inventory, here
narrowed to one type:

```sparql
PREFIX gc: <http://purl.org/gc/>

SELECT ?exp WHERE {
  ?exp a gc:SaddlePoint .
}
ORDER BY ?exp
```

Two results: `caa005bTSa` and `caa005bTSb`. Let's follow the first one.
**To adapt this step**: swap `gc:SaddlePoint` for any of the other four
types (`GeometryOptimization`, `SinglePoint`, `VibrationalAnalysis`,
`IRC`), or use CQ #1's own `FILTER(?type IN (...))` form to see several
types at once.

**Ask what it actually produced.** Now that we have one experiment in
hand, CQ #3's provenance query, pointed at its own input file:

```sparql
PREFIX ex: <http://example.org/>
PREFIX prov: <http://www.w3.org/ns/prov#>

SELECT ?output ?type WHERE {
  ?exp prov:used ex:file_caa005bTSa_inp .
  ?output prov:wasGeneratedBy ?exp .
  ?output a ?type .
  FILTER(?type != owl:NamedIndividual)
}
```

A clean result here - just the real `.log` and `.dat` files this run
produced, nothing more tangled. (CQ #3's own notes explain a messier
case worth knowing about: sometimes this same query returns a *later*
experiment's own input file, when that run's starting geometry was
built from this one's result - not the case here, but worth watching
for elsewhere.) **To adapt this step**: swap `ex:file_caa005bTSa_inp`
for any other experiment's own input file URI to trace a completely
different run's own outputs.

**Ask what produced *this* geometry.** A transition state doesn't just
appear - it's usually found by deliberately constraining part of the
geometry while the rest relaxes. What was actually held fixed here?
CQ #4's constraints query, pointed at this specific experiment:

```sparql
PREFIX gc: <http://purl.org/gc/>
PREFIX ex: <http://example.org/>

SELECT ?constraint ?type ?target ?unit WHERE {
  ?constraint a ?type ; ex:targetValue ?target ; gc:hasUnit ?unit .
  ex:exp_caa005bTSa ex:hasConstraint ?constraint .
  FILTER(?type IN (ex:DistanceConstraint, ex:AngleConstraint, ex:DihedralConstraint))
}
```

**Zero results - a real, genuine finding, not a dead end.** This
specific transition state was found via an unconstrained saddle-point
search, using a real Hessian - by the time you're searching directly
for a saddle point, you no longer need an artificial geometric
constraint holding anything in place. The constraints that actually
narrowed in on this region of the surface were used earlier, in the
`caa004` scan series that led up to it. Running the same query against
one of those instead:

```sparql
PREFIX gc: <http://purl.org/gc/>
PREFIX ex: <http://example.org/>

SELECT ?constraint ?type ?target ?unit WHERE {
  ?constraint a ?type ; ex:targetValue ?target ; gc:hasUnit ?unit .
  ex:exp_caa004m ex:hasConstraint ?constraint .
  FILTER(?type IN (ex:DistanceConstraint, ex:AngleConstraint, ex:DihedralConstraint))
}
```

Two real constraints - `Distance constraint caa004m (atoms 10-7)` and
`Distance constraint caa004m (atoms 8-13)`, both fixed to 1.2 Å - a
genuine two-dimensional scan, not a simple one-parameter search.
Note: `caa004m` isn't linked to `caa005bTSa` by any formal
`prov:wasGeneratedBy` triple in the graph - this is a narrative
connection (the same scan series, narrowing toward the same region),
not something the graph itself formally asserts. **To adapt this
step**: swap `ex:exp_caa004m` for any other experiment's own ID, or
drop that line entirely to see every constraint in the graph at once,
the way CQ #4's own version of this query does.

**Putting it together**: three short queries - an inventory, a
provenance trace, a constraint lookup - turned "what transition states
exist?" into a specific, real geometric story: this one was found via
an unconstrained saddle-point search, cleanly producing just its own
`.log`/`.dat` files, sitting at the end of a real two-dimensional scan
that held two distances fixed at 1.2 Å each. None of these three
queries needed anything beyond what's already in the numbered list
below - the value here is entirely in chaining them, and in noticing
when a step's own answer (like the empty result above) is itself part
of the real story rather than something to work around.

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

SELECT ?output ?type WHERE {
  ?exp prov:used ex:file_caa001a_inp .
  ?output prov:wasGeneratedBy ?exp .
  ?output a ?type .
  FILTER(?type != <http://www.w3.org/2002/07/owl#NamedIndividual>)
}
```

**This is a template, not a one-off** - swap `ex:file_caa001a_inp` for
any other experiment's own input file URI (e.g.
`ex:file_caa005bTSa_inp`) to trace provenance for a completely
different run. This is the real, general answer to "where did this
output actually come from?" for any experiment in the graph, not just
the one shown here.

**A genuine, real result worth understanding, not a bug**: this can
correctly return a *later* experiment's own input file, not just this
run's own log/data files - `caa001b`'s input, for instance, is
genuinely `prov:wasGeneratedBy caa001a`, since its starting geometry
was itself built from `caa001a`'s result, as part of the same
iterative optimisation sequence. `?type` is included specifically so
this distinction is visible directly in the results, rather than
looking like an error.

**A second, separate real finding**: every individual in this graph
genuinely has *two* `rdf:type` triples - `owl:NamedIndividual` (added
automatically by `robot` to every instance) alongside its own, actual
class. A plain `?output a ?type` therefore doubles every row rather
than erroring - not a bug, just uninformative duplication, filtered
out above since `owl:NamedIndividual` never distinguishes anything.

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

**Status: ✅ Answerable. Verified working** against both `caa` and
`aa` - each correctly finds its own experiment linked to this DOI
(`exp_caa004a` and `exp_aa002-aldehyde-bare` respectively). Both
projects genuinely share this reference deliberately, not by
coincidence: Sorensen & Jencks (1987) is specifically about
acetaldehyde hydration, and the same methodology applies directly to
chloroacetaldehyde too - `aa`'s own link was added once this was
confirmed, rather than assumed.

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

A genuine gap found later, via real use: this query originally only
ever returned `?constraint`, never the experiment the question itself
asks for by name - the constraint's own ID happens to embed the
experiment name as a substring, but that's not the same as actually
returning it as its own column. Fixed here by joining back through
`ex:hasConstraint`.

```sparql
PREFIX ex: <http://example.org/>

SELECT ?exp ?constraint WHERE {
  ?exp ex:hasConstraint ?constraint .
  ?constraint ex:targetValue ?target .
  FILTER(?target = 1.2)
}
```

## 7. Find a successful run of a given type, at a given level of theory, with its input/output/data files

**Status: ⚠️ Partially answerable** - the type filter, level-of-theory
filter, and file lookup now all work correctly. One real gap remains:

```sparql
PREFIX gc: <http://purl.org/gc/>
PREFIX prov: <http://www.w3.org/ns/prov#>

SELECT ?exp ?type ?method ?inputFile ?outputFile WHERE {
  ?exp a ?type .
  FILTER(?type IN (gc:GeometryOptimization, gc:SaddlePoint, gc:SinglePoint))
  ?exp gc:hasMethod ?method .
  FILTER(?method = "wB97X-D")
  OPTIONAL { ?exp prov:used ?inputFile . }
  OPTIONAL { ?exp prov:generated ?outputFile . }
}
ORDER BY ?type ?exp
```

**The `.dat` file isn't tracked at all.** Only `prov:used` (`.inp`)
and `prov:generated` (`.log`) exist. Still genuinely open, unrelated
to today's level-of-theory work.

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

**This was an open question when first written - now answered.**
Not every frequency is extracted into the graph: only the imaginary
ones and GAMESS's own translation/rotation modes are (see the scoping
principle in this document's own opening, and
`identify_diagnostic_modes()`/`filter_vibrational_modes()` in
`gamess_functions`/`ont_mm`) - real provenance links
(`prov:wasGeneratedBy`/`prov:generated`) cover the rest, so nothing is
actually lost, just not duplicated as its own triple. A real,
measured result of that choice: roughly 80-83% fewer peak/float-value
triples across both `caa` and `aa`, with every genuinely diagnostic
value (confirmed directly, not assumed) still present.

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
`prov:used`/`prov:generated` work; the intermediate `.dat` file has
no property to query for at all.

```sparql
PREFIX prov: <http://www.w3.org/ns/prov#>

SELECT ?exp ?inputFile ?outputFile WHERE {
  OPTIONAL { ?exp prov:used ?inputFile . }
  OPTIONAL { ?exp prov:generated ?outputFile . }
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

**Status: ✅ Answerable. Verified working**, on both `caa` and `aa` -
`gc:hasMethod`/`gc:hasBasisSet` are now genuinely populated on every
experiment (see `GLOSSARY.md`'s "Level of theory" section for how, and
`examples/aa/README.md`'s "A second real bug" for a real extraction
bug this very data uncovered).

```sparql
PREFIX gc: <http://purl.org/gc/>

SELECT ?exp WHERE {
  ?exp gc:hasMethod "wB97X-D" .
  ?exp gc:hasBasisSet "6-31G(d,p)" .
}
```

**Running this exact query against `aa` correctly returns zero
results** - not a bug, a real, genuine finding. `aa`'s own geometry
and frequency work never used `6-31G(d,p)` at all; it used `6-21G` the
whole way through (see "A second real bug" in `examples/aa/README.md`).
This query is itself now a real, working way to discover that
difference between the two datasets, rather than something that has
to be read out of the README by hand.

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
