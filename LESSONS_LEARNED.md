# How not to build a domain ontology: lessons from ont_mm

`ont_mm` was built by a subject-matter expert (a computational chemist),
not a knowledge engineer. That is its strength, because it starts from
real GAMESS (US) runs and real questions. It also explains its mistakes.
They are listed here openly, so others can skip them.

Each lesson gives what happened, what to do instead, and where the
evidence is in this repository.

---

## A. Scoping

### 1. Competency questions came last, not first
**What happened.** The ontology and the graphs were built first. The
competency questions were written afterwards, against what already
existed ([COMPETENCY_QUESTIONS.md](./COMPETENCY_QUESTIONS.md) says so
in its first paragraph).
**Instead.** Write 5–10 questions before modelling anything. Turn each
one into a SPARQL query with an expected answer, and use those queries
as tests. A term no question needs is a term you can leave out for now.

### 2. The graph held data, not links to data
**What happened.** Early graphs stored bulky output, such as atom
coordinates and full vibrational mode lists, as triples. Most of it was
never queried, and it duplicated what the log files already hold.
**Instead.** Store the meaningful results (energies, an imaginary
frequency as a diagnostic). For everything else, store a provenance link
to the file that holds it (`prov:wasGeneratedBy`, `ex:fileURL`).
"Light" atoms now carry element and number only.

---

## B. Reuse, namespaces and upstream ontologies

### 3. Building on an unmaintained ontology
**What happened.** Gainesville Core (GC) was chosen because its authors
were pioneers in the field. But it is orphaned: its PURL does not
resolve, and nobody maintains it. Repairing it became a project of its
own (nine structural fixes, see
[GC-Ontology-Mirror](https://github.com/Darren01/GC-Ontology-Mirror)).
**Instead.** Before importing an ontology, check that it is maintained,
that its PURL resolves, and that it has a clear licence. If it fails
these checks, take its *ideas* and map them (see the
[SSSOM worksheet](./mappings/ont_mm-gc-to-canon.sssom.tsv)), rather than importing it as a
foundation.

### 4. New terms minted in someone else's namespace
**What happened.** 17 terms were added inside `http://purl.org/gc/`
even though GC 0.7 never had them (`gc:SaddlePoint`, `gc:IRC`,
`gc:ReactionPath`, `gc:hasEnthalpy`, `gc:hasPathEnergy`, …). One more,
`gc:constraintMode`, is used in the data but declared nowhere. A reader
cannot tell original GC from additions, and the additions would clash
if GC were ever revived.
**Instead.** Mint new terms in your own namespace, and map them to the
upstream term with SSSOM or `skos:closeMatch`. Never extend another
project's namespace.

### 5. Project terms defined only in Markdown
**What happened.** The `ex:` terms are carefully defined in
[GLOSSARY.md](./GLOSSARY.md), but not in the ontology itself. Six of
them (`ex:hasRuntyp`, `ex:hasSolvent`, `ex:hasSolvationModel`,
`ex:hasHssend`, `ex:targetValue`, `ex:fileURL`) are not even declared as
properties in the graph. Tools and reasoners cannot see a Markdown
definition.
**Instead.** Give every term `rdfs:label` and a definition
(`IAO:0000115`) in the ontology, and generate the glossary *from* it.

---

## C. Modelling

### 6. Several `rdfs:domain` statements mean AND, not OR
**What happened.** Six properties listed several domain classes as
separate statements. In OWL that means the subject must belong to *all*
of them at once, so the reasoner inferred nonsense. Fixed in release
2026-10-07 (v0.8.8) with one union domain.
**Instead.** If a property applies to A or B, declare
`rdfs:domain [ owl:unionOf (A B) ]`, or leave the domain off.

### 7. A class named after a result, used for a process
**What happened.** `gc:SaddlePoint` names a point on a potential energy
surface, but in the graph it classifies the *calculation* that searches
for one.
**Instead.** Ask the COB/BFO classification question first: is it a
process, an information entity, or a material entity? Then name it to
match (for example, "transition state search" for the process, and
"saddle point geometry" for its output).

### 8. One global identifier for something that depends on context
**What happened.** Constraint atoms are named `ex:atom_<n>` by their
position in the GAMESS input. So the same `ex:atom_10` is reused by 19
experiments in `caa`, where it means different atoms in different
molecules.
**Instead.** Mint identifiers in their context (experiment plus atom
index), or link to the atoms of the molecule the constraint belongs to.

### 9. Key settings stored as strings
**What happened.** Method and basis set are plain literals
(`"wB97X-D"`, `"6-31G(d,p)"`). That makes them hard to link, and easy
to get wrong (lesson 11).
**Instead.** Use terms from a shared vocabulary as values, for example
a basis-set ontology (see the
[basis-set-ontology-demo](https://github.com/cthoyt/basis-set-ontology-demo)).

### 10. Refuse rather than warn
**What happened (and went right).** SMILES with undefined
stereochemistry would produce a misleading InChI. The pipeline leaves
the field blank and records why in `species_report.tsv`.
**Keep doing this.** A blank identifier is better than a wrong one,
because readers rarely follow up warnings.

---

## D. Pipeline and data quality

### 11. Formal values expose errors that narrative hides
**What happened.** The extraction code mapped GAMESS `GBASIS=N21` to
`3-21G` regardless of `NGAUSS`. Every `aa001` run was stored as `3-21G`
when it was really `6-21G`. The narrative text was right all along; the
error surfaced only when the graph was queried
([examples/aa/README.md](./examples/aa/README.md), "A second real bug").
**Lesson.** This is a reason *for* the approach. But check extracted
values against source for at least one run of each kind.

### 12. A clean-up step silently deleted the results
**What happened.** `filter_vibrational_modes()` removed every float
value not attached to a kept peak. That included every energy, so
competency questions 11 and 13 returned nothing.
**Instead.** Run the competency-question queries as regression tests
after every rebuild. A test now exists
(`tests/verify_filter_vibrational_modes.R`).

### 13. Check the build inputs before blaming the tools
**What happened.** A fix did not appear after several rebuilds. The
cause was a path pointing at a second, out-of-date clone of the repo.
`robot` never caches anything ([PROV_O_ADOPTION.md](./PROV_O_ADOPTION.md)).
**Instead.** When output doesn't change, inspect the actual input files
first. Keep one working clone.

---

## E. Tooling and querying

### 14. Search by full IRI, not local name
`grep hasInputFile` matched both `gc:hasInputFile` and the retired
`ex:hasInputFile`. Search for the namespace-qualified IRI.

### 15. `robot` types every individual twice
Every instance also gets `owl:NamedIndividual`, so `?x a ?type`
returns duplicate rows. Filter it out, or ask for specific classes.

### 16. Test queries on more than one engine
The browser playground's engine (`rdflib.js`) silently ignores `FILTER`.
Results that looked right were wrong. Check against Jena `arq`.

---

## F. Documentation

### 17. The front door matters more than the completeness
The main README runs to over 1,500 lines, and a domain outsider found
the project hard to follow. **Instead,** open with one page: the
purpose, the three example datasets, a link to the playground, and the
list of competency questions. Put everything else behind links.
