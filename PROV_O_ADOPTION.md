# Case study: replacing locally-invented terms with real PROV-O equivalents

## Background

This project's own vocabulary sits in three tiers: universal W3C
standards (`prov:`, `skos:`, `dcterms:`), the domain-specific
Gainesville Core vocabulary (`gc:`), and this project's own,
locally-invented terms (`ex:`) - used only where neither of the first
two already covers something we needed. The third tier is the
weakest: a term one project invents has no guarantee of meaning
anything to another, and no guarantee it wasn't already solved
elsewhere.

An earlier pass at this project already started auditing which `gc:`
and `prov:` terms were relevant to the build (see `docs/gc_terms.txt`,
`docs/prov_terms.txt`) - `prov:used` was already on that list. That
audit wasn't carried through to an actual change at the time, and the
project moved on. This case study is that earlier thread, picked back
up and finished for two of this project's own `ex:` terms - and a
concrete argument for reviving the rest of it.

## The question

`ex:hasInputFile` and `ex:hasOutputFile` link an experiment to the
GAMESS (US) input file it was run from, and the log/data files it
produced. Both are this project's own, invented properties, never
formally defined anywhere. Given the earlier audit had already flagged
`prov:used` as relevant, the obvious question: does PROV-O - a real,
W3C-standard vocabulary this project already imports - already have
exact equivalents for both?

## The investigation

Checked directly against the real, official W3C PROV-O specification
(<https://www.w3.org/TR/prov-o/>) rather than assumed from memory.
PROV-O's own worked example is structurally identical to what this
project needed:

```turtle
:aggregationActivity a prov:Activity ;
    prov:used :crimeData, :nationalRegionsList .
```

`prov:used` (an `Activity` used an `Entity`) is the exact match for
`ex:hasInputFile`. Its formal, direct inverse, `prov:generated` (an
`Activity` generated an `Entity`), is the exact match for
`ex:hasOutputFile`.

Both turned out to already be fully declared in this project's own
`gc_core.ttl` - domain, range, and comment all present and correct -
since Gainesville Core itself already imports the PROV-O vocabulary.
No new import was needed at all; this was purely a matter of using
what was already there instead of what had been invented alongside
it.

Genuinely worth being precise about scope here: `prov:wasGeneratedBy`
was already in use elsewhere in this graph, but for a distinct,
different purpose - linking an *input* file back to the *earlier*
experiment that produced it, in a chained, multi-step workflow. That
usage was correct already and didn't change.

## The fix

One line, in `templates/experiment_template.tsv`'s own header:

```diff
-I ex:hasInputFile   I ex:hasOutputFile SPLIT=|
+I prov:used         I prov:generated SPLIT=|
```

## Would this break anyone currently using the graph?

Asked and answered honestly, since it matters beyond this one project:
anyone who rebuilds from a fresh pull is automatically, cleanly fixed
- the property name lives entirely in the template, so a normal
rebuild picks up the change with no extra steps. But it is a genuine,
silent breaking change for anyone holding a static, previously-saved
copy of the graph, or with their own queries written directly against
`ex:hasInputFile`/`ex:hasOutputFile` - those queries simply stop
matching anything, with no error at all. Renaming a term in a live,
already-published ontology has a real cost; it shouldn't be done
casually, but it's the right call when the replacement is an exact,
already-available standard rather than a genuinely different concept.

## Executing it: a real lesson in ontology-pipeline hygiene

This is the most concretely useful part of this case study for anyone
running a similar `robot template`-based pipeline, found the hard way,
through several rounds of "why hasn't this actually changed?"

The established rebuild routine for this project has always been:
delete the `*_instances.tsv` files and the final built graph, then
rebuild. That's sufficient when *data* changes. It is **not**
sufficient when a *property name itself* is being renamed or removed,
because two kinds of generated file silently persist the old
declaration across rebuilds unless deleted too:

1. **The per-template generated schema file** (`experiment_template.ttl`,
   built by `robot template` from the TSV). It does not appear to be
   regenerated from scratch by the graph-build step - it accumulates.
2. **The local, per-dataset copy of the merged-in ontology**
   (`gc_core.ttl` inside each dataset's own `ont/` folder), which
   likewise persisted a stale declaration until deleted directly.

Neither of these was ever a problem before, because no earlier change
to this project had actually removed a property - only added new ones
or changed data values. Renaming one was the first time this gap
actually mattered, and it took several rounds of grep-and-rebuild to
find both places.

**The practical rule going forward**: before rebuilding after a
property rename or removal, delete every generated `.ttl` file in the
dataset's `ont/` folder, not just the `*_instances.tsv` files and the
final graph.

A second, smaller lesson from the same debugging session: a naive,
unqualified `grep "hasInputFile"` is genuinely misleading here, since
the real, legitimate `gc:hasInputFile` (a different, pre-existing
Gainesville Core term this project simply never uses) shares the same
local name as this project's own, now-retired `ex:hasInputFile`.
Verifying a fix like this needs a namespace-qualified check
(`example.org/hasInputFile`, not just `hasInputFile`) - conflating the
two cost real time mid-fix.

## What actually changed

Verified directly, not assumed:

- Both graphs (`caa`, `aa`) and both their reasoned counterparts,
  rebuilt and confirmed: zero remaining `example.org/hasInputFile`
  or `example.org/hasOutputFile` triples in either; `prov:used`/
  `prov:generated` present and correct throughout.
- `GLOSSARY.md`, `README.md`, `COMPETENCY_QUESTIONS.md`,
  `examples/README.md`, and the SPARQL playground - ten separate
  locations across five files - updated to match, including two CQ
  queries (#7, #12) that needed a `prov:` prefix added since they'd
  never referenced it before.
- The playground's own "Provenance: trace a file" example re-tested
  against the real, rebuilt graph and confirmed still correct.

## What's next: reviving the rest of the audit

`docs/gc_terms.txt` already lists other `gc:` terms worth checking
this project's own usage against (`hasAtom`, `hasIndex`,
`hasInChIString`, `hasDftFunctional`, and more), and this same,
one-term-at-a-time process - check the real spec, confirm it's already
in `gc_core.ttl`, swap the template, rebuild with the schema-file
cleanup this case study surfaced, verify - is now a proven, repeatable
recipe for the rest of that list, not just a one-off fix for these two
terms.
