# Glossary of Terms

Following [SAMOD](https://essepuntato.it/samod/) (Peroni, 2016), a
proper ontology development process produces a glossary "collected
from the scenario and the competency questions" - tied to the model
itself, not to any one dataset's actual contents. That's deliberately
how this glossary is scoped: every term below is one that
[`COMPETENCY_QUESTIONS.md`](./COMPETENCY_QUESTIONS.md) actually
references, whether or not the `caa` example happens to populate it.
One deliberate exception: the file classes (`ex:InputFile`,
`ex:DataFile`, `ex:LogFile`), `ex:fileURL`, `ex:involvesAtom1` to
`ex:involvesAtom4`, the two defined classes (`ex:Experiment`,
`ex:ImaginaryFrequencyPeak`) and, from Gainesville Core, six classes
(`gc:SystemEnergies`, `gc:FloatValue`, `gc:VibrationalSpectra`,
`gc:FrequencyPeak`, `gc:ReactionPath`, `gc:ReactionPathPoint`) and one
property (`gc:hasIntensity`) are not referenced by any competency
question by name - the questions reach those classes only through the
properties that link to them - but they turn up in the
[SPARQL tutorial](./SPARQL_TUTORIAL.md)'s own examples, in README
Step 6, and in anyone's first queries of these graphs, so they are
defined here too rather than left to be guessed.

Where a definition comes directly from the ontology's own schema
(`gc_core.ttl`), it's quoted as such. Where a term is this project's
own (`ex:`), it has never actually had a formal definition anywhere in
the project until now - noted below, not disguised as
something inherited.

## Experiment types

These classify what kind of GAMESS (US) calculation an experiment
actually was - see `classify_gamess_jobs()` in `gamess_functions` for
exactly how a raw `RUNTYP` value gets mapped to one of these.

**`gc:MolecularComputation`** - *"A class for MolecularComputation."*
(Gainesville Core's own definition - this brief.) The
general parent class every experiment type below belongs to. It is
not a reliable way to list experiments, though - see `ex:Experiment`,
below.

**`ex:Experiment`** - this project's own class, never formally defined
until now: a calculation run, meaning anything that used an input file
(`prov:used` some `ex:InputFile`). It is *derived*, not asserted: the
reasoner works it out from [`dl_axioms.ttl`](./dl_axioms.ttl)
(section 3), so it appears only in a reasoned graph (README Step 6);
in the asserted graph, `prov:used` is the test instead. Each experiment
keeps its specific kind from the list below, and the structure-building
step (`ex:avogadro_build`), which used nothing, is correctly not one.
Its parent is `prov:Activity`, and because it is more specific than
that, a reasoned graph no longer returns experiments for
`?x a prov:Activity` - ask for `ex:Experiment` instead. It exists
because no upstream class means "an experiment": `gc:MolecularComputation`
is only attached as a by-product of writing results, constraints or
notes for one, so it misses experiments with none of those, and once
reasoned it matches far more than experiments. Nearest concepts
elsewhere, none imported: OBI's `data transformation` (`OBI_0200000`),
EXPO's `ComputationalExperiment` and ASMO's `Simulation`.

**`gc:GeometryOptimization`** - *"A class for calculations in
computational chemistry that aim to find molecular geometry of lowest
energy."* (Gainesville Core)

**`gc:VibrationalAnalysis`** - *"A class for the computations of
vibrational spectrum of molecules."* (Gainesville Core - a second,
near-duplicate comment, *"A class for VibrationalAnalysis,"* also
exists in the schema but adds nothing; the one above is the
definition.)

**This project's own usage note, not part of the Gainesville Core
definition above:** a run whose raw `RUNTYP=OPTIMIZE` also has
`HSSEND=.TRUE.` set gets classified as `VibrationalAnalysis`, not
`GeometryOptimization` - the frequency calculation appended to confirm
a stationary point is judged the more scientifically
significant outcome. Only a "bare" optimization with no frequency
check stays `GeometryOptimization`. A standalone `RUNTYP=HESSIAN` is
always `VibrationalAnalysis` too. This is a deliberate design decision
in this project's own extraction code - not something the base
ontology itself says or requires.

**`gc:SaddlePoint`** - *"A class for calculations that locate a
stationary point on the potential energy surface with exactly one
direction of negative curvature (a first-order saddle point),
corresponding to a transition state."*

**`gc:SinglePoint`** - *"A class for Single Point calculations -
computation of the energy of molecular system for given geometry."*

**`gc:IRC`** - *"A class for calculations that follow the intrinsic
reaction coordinate away from a saddle point, in either the forward or
backward direction."*

## Level of theory

**`gc:hasMethod`** - *"A property that defines the calculation method
for given technology."* Written into every experiment by
`extract_level_of_theory_parts()` - the correlated or DFT method
used (e.g. `wB97X-D`, `CCSD(T)`), or, when no such method was set, the
raw `SCFTYP` keyword (`RHF`/`UHF`/`ROHF`) instead of leaving this
blank - a deliberate choice, so a competency question like "which
experiments used RHF" stays answerable.

**`gc:hasBasisSet`** - *"A property that allows Basis Sets to be
assigned to a given quantum methodology."* Same extraction path as
`hasMethod` above. Finding this queryable for the first time
surfaced a previously-unnoticed extraction bug (`GBASIS=N21` was
hardcoded to `3-21G` regardless of the `NGAUSS` value used) - see
`examples/aa/README.md`'s own "A second real bug" section.

**`ex:hasSolvent`**, **`ex:hasSolvationModel`** - this project's own
properties, never formally defined until now: **`ex:hasSolvent`** is
the actual solvent named in a `$PCM` group (e.g. `water`);
**`ex:hasSolvationModel`** is which implicit solvation model was used
(`PCM` or `SMD` - a different setting `$PCM`'s own
`SMD` keyword controls, kept as a separate property rather than folded
into one string, since this project's own `aa` data shows the
distinction is scientifically meaningful, not cosmetic).

**`ex:hasRuntyp`**, **`ex:hasHssend`** - this project's own
properties, never formally defined until now: the raw GAMESS
`RUNTYP`/`HSSEND` keyword values `classify_gamess_job()` already
computes for its own type classification, written into the graph
alongside it rather than only ever existing internally. Useful on their own, not just as classification inputs - e.g.
distinguishing a `SaddlePoint` search that itself computed a
confirming Hessian (`HSSEND=.t.`) from one that read it from a
separate companion file instead (like `caa005bTSb`, see
`examples/caa`'s own data).

## Files and provenance

**`prov:used`**, **`prov:generated`**, **`prov:wasGeneratedBy`** -
all from [W3C PROV-O](https://www.w3.org/TR/prov-o/), an external, widely-used standard for describing where something came
from - already declared in this project's own `gc_core.ttl`, since
Gainesville Core itself already imports the vocabulary, so no new
import was ever needed. **`prov:used`** relates an experiment to the
GAMESS (US) input deck it was run from; **`prov:generated`** relates
it to the log/data file(s) it directly produced;
**`prov:wasGeneratedBy`** is used the other way round, linking a file
to the experiment that produced it - the mechanism behind tracing
"what output came from this input."

These three replaced this project's own, locally-invented
`ex:hasInputFile`/`ex:hasOutputFile`, once an audit turned up
that exact, already-available PROV-O equivalents had existed the
whole time. An example of preferring an external standard
over a project's own invented term once one turns out to exist -
worth knowing if you're wondering whether an older copy of a graph or
a saved query still using the old names will keep working: it won't,
without a rebuild.

**`schema:sha256`** - from [Schema.org](https://schema.org/sha256),
recorded directly on each input/data/log file individual (the same
ones `prov:used`/`prov:generated` already point at) as a content
fingerprint - the SHA-256 hash of the file's own, actual bytes at
build time, not just its filename or path. Considered against
[SPDX's own checksum model](https://spdx.org/rdf/terms#checksum)
first, which is the more commonly-cited standard for this - rejected
only because it requires a separate `Checksum` node plus an
`algorithm` value for every hash, overhead this project doesn't
need since it only ever uses SHA-256. Not declared in `gc_core.ttl`
itself (unlike the `prov:` terms above): a small, separate file,
[`schema_terms.ttl`](./schema_terms.ttl), carries just this one
property's declaration, kept apart from that versioned release
for the same reason [`dl_axioms.ttl`](./dl_axioms.ttl) is.

**`ex:InputFile`**, **`ex:DataFile`**, **`ex:LogFile`** - this
project's own classes, never formally defined until now, for the
three files recorded for every experiment: the GAMESS (US) input deck
it was run from (`.inp`), the `.dat` (PUNCH) file it wrote, and its
`.log` - the printed output its results are read from. There is
always one of each per experiment, and the individual exists even if
the real file wasn't found on disk when the graph was built: the
published `aa` and `caa` graphs have a `DataFile` for every experiment
and not one `ex:fileURL` or `schema:sha256` among them. An experiment
reaches its input through `prov:used` and its data and log files
through `prov:generated`, above.

**`ex:fileURL`** - this project's own property, never formally defined
until now: where the real file is, as a `file:` URL for its absolute
path on the machine the graph was built on. It is a plain string, not
a link a query can follow, and it is not portable - it names the
builder's own folders, so it won't resolve on anyone else's machine.
It is only written where the file was actually found at build time;
otherwise the property is absent altogether, and so is the file's
`schema:sha256`, since both come from the same lookup of the real
file.

## Constraints

**`ex:DistanceConstraint`**, **`ex:AngleConstraint`**,
**`ex:DihedralConstraint`** - this project's own classes, never
formally defined until now: a geometric restriction applied during a
calculation, fixing a bond distance, bond angle, or dihedral angle to
a specific target value rather than letting it optimize freely.

**`ex:hasConstraint`** - this project's own property, never formally
defined until now: links an experiment to each geometric constraint
applied during it, one link per constraint. The constraint is a node
of one of the classes above, carrying its own `ex:targetValue`,
`gc:hasUnit` and `gc:constraintMode`, and naming the atoms it fixes
with **`ex:involvesAtom1`** to **`ex:involvesAtom4`** - up to four:
two for a distance, three for an angle, four for a dihedral (the
published `aa` and `caa` graphs contain only distance constraints).
Worth knowing before following one of those links: an atom is named
`ex:atom_<n>`, where `<n>` is the atom's number in the GAMESS input,
and that is all the graph knows about it. The node is declared and
nothing more - no element, no coordinates, no label - and the same
`ex:atom_10` is reused by every experiment that mentions atom 10 (19
different experiments in `caa`), whichever molecule's numbering that
is. It identifies a position in an input file, not an atom in the
world.

**`ex:targetValue`** - this project's own property, never formally
defined until now: the specific numeric value (with `gc:hasUnit`,
below) a constraint was fixed to.

**`gc:hasUnit`** - *"A property that describes a unit of the value."*
(Gainesville Core)

## Results and energetics

**`gc:hasResult`** - *"A property that describes generic results of
the computations."* The general link from an experiment to whatever it
produced - energies, spectra, or a reaction path, depending on the
experiment type.

**`gc:SystemEnergies`** - *"A class for various types of energies
associated with molecular system."* One per experiment that produced
energies, linked from the experiment by `gc:hasResult`. It holds no
numbers itself: each energy hangs off it through its own property -
`gc:hasZeroPointEnergy`, `gc:hasEnthalpy`, `gc:hasEntropy`,
`gc:hasGibbsFreeEnergy` or `gc:hasElectronicEnergy` - pointing at a
`gc:FloatValue`. Which experiments carry which: a frequency analysis
(and a saddle-point run that also computed a Hessian) carries the four
thermochemical quantities, and a single point carries only its
electronic energy.

**`gc:hasFloatValue`** - *"A property that describes floating point
value."* The actual number at the end of a reification chain - e.g.
`experiment -> hasResult -> energies -> hasEnthalpy -> [an entity] ->
hasFloatValue -> the number`. Every energetic quantity below
follows this same pattern: the named property (`hasEnthalpy`, etc.)
points to a separate entity, not the number directly, and that
entity's own `hasFloatValue` holds the value.

**`gc:FloatValue`** - *"A class for float value, containing value and
unit."* A number with its unit, as a node of its own: `gc:hasFloatValue`
holds the number (an `xsd:float`) and `gc:hasUnit` the unit, itself an
individual. In these graphs exactly eight properties point at one:
`gc:hasFrequency` (unit "cm-1"), `gc:hasIntensity` (unit
"Debye^2/amu-Angstrom^2"), `gc:hasElectronicEnergy`,
`gc:hasZeroPointEnergy` and `gc:hasPathEnergy` (unit "hartree"),
`gc:hasEnthalpy` and `gc:hasGibbsFreeEnergy` (unit `gc:kiloJoulePerMole`,
label "kJ/mol") and `gc:hasEntropy` (unit "J/(mol K)"). The
enthalpy and Gibbs values are read from the log as kJ/mol. From gc
v0.8.9 the ontology has `gc:kiloJoulePerMole` (kJ/mol, the same unit as
QUDT's `KiloJ-PER-MOL`), and `gc:kiloJoules` is deprecated but kept so
that older graphs stay valid. The extraction
(`thermochemistry_to_templates()` in gamess_functions) writes
`gc:kiloJoulePerMole`, and the current `aa` and `caa` examples have been
rebuilt with it. A graph built before that still uses `gc:kiloJoules`
until it is rebuilt.

In a reasoned graph every `gc:FloatValue` is also typed
`gc:CalculationResult` and `rdfs:Class`, and every unit `rdfs:Class`.
Neither type says anything about the data. The first follows because
the properties pointing at a value are all sub-properties of
`gc:hasResult`, whose range is `gc:CalculationResult`; the second
because `gc:hasUnit` sat under `gc:hasAuxiliaryProperty`, whose domain
and range are both `rdfs:Class` (upstream describes that as an upper
property for publication-related properties, so it was a misplacement).
From gc v0.8.9 `gc:hasUnit` no longer sits there, so a graph reasoned
over that release does not get the `rdfs:Class` types; graphs reasoned
over earlier releases still show them.

**`gc:hasElectronicEnergy`** - *"A property that describes the
electronic energy."*

**`gc:hasZeroPointEnergy`** - *"A property that describes the
zero-point energy."*

**`gc:hasEnthalpy`** - *"A property that describes the enthalpy."*

**`gc:hasEntropy`** - *"A property that describes the entropy."*

**`gc:hasGibbsFreeEnergy`** - *"A property that describes the Gibbs
free energy."*

## Vibrational data

**`gc:VibrationalSpectra`** - *"A class for spectra resulting from the
molecular vibrations."* One per experiment whose log yielded a
frequency result, linked from the experiment by `gc:hasResult`; an
experiment with no parsed frequency result simply has none. The class
name is plural but each individual is a single spectrum (the labels
read "Vibrational spectrum ..."). It reaches its peaks through
`gc:hasFrequencyPeak`.

**`gc:hasFrequencyPeak`** - *"A property that describes the value of a
frequency peak of the vibrational spectrum."* Links a spectrum to one
of its individual peaks.

**`gc:FrequencyPeak`** - *"A class representing frequency peak of the
spectrum."* (Upstream also carries a placeholder second comment, *"A
class for FrequencyPeak."*) One vibrational mode, with its frequency
(`gc:hasFrequency`) and intensity (`gc:hasIntensity`), each a
`gc:FloatValue`. A spectrum here does not hold every mode: the
imaginary ones and GAMESS's six translation/rotation modes are kept,
typically six to eight per spectrum, and the rest are filtered out by
`filter_vibrational_modes()` (the full list stays in the `.log`). The
six near-zero modes are therefore not vibrations of the molecule, and a
negative frequency marks an imaginary one - typed
`ex:ImaginaryFrequencyPeak` in a reasoned graph (below).

**`gc:hasFrequency`** - *"A property that describes the value of a
frequency at the peak of the spectrum."* A negative value here means
an imaginary frequency - the standard signal used throughout
this project to flag whether a geometry is a stationary point
(zero expected for a minimum, exactly one for a confirmed transition
state).

**`gc:hasIntensity`** - *"A property that describes the value of the
intensity of a peak of a spectrum."* Links a peak to its intensity, a
`gc:FloatValue` with the unit "Debye^2/amu-Angstrom^2". Its domain is
`gc:FrequencyPeak`, and like `gc:hasFrequency` it is a sub-property of
`gc:hasResult`.

**`ex:ImaginaryFrequencyPeak`** - this project's own class, never
formally defined until now: a `gc:FrequencyPeak` whose `gc:hasFrequency`
value is strictly negative, which is GAMESS's convention for an
imaginary vibrational mode. A confirmed transition state has exactly one
and a minimum has none; a vibrational analysis that shows one where
none is expected flags an unconverged geometry. It is *derived*, not
asserted: the reasoner classifies each peak from
[`dl_axioms.ttl`](./dl_axioms.ttl) (section 1), purely from the sign of
the value, so it appears only in a reasoned graph (README Step 6), and
"which results show an imaginary frequency?" becomes
`?peak a ex:ImaginaryFrequencyPeak` instead of a numeric filter. Exactly
zero does not count - tested deliberately, not assumed - which matters
because the six translation and rotation modes sit near zero without
being imaginary. Counted both ways on the published `aa` and `caa`
graphs, the class and the numeric test agree.

## Reaction paths

**`gc:ReactionPath`** - *"A minimum-energy reaction path on a
potential energy surface in mass-weighted coordinates, connecting
reactants to products via the transition state."* The release also
carries a longer comment: *"A class for the combined reaction path
connecting reactants to products via a transition state, typically
assembled from a forward and a backward IRC run sharing the same saddle
point."* In these graphs there is one per IRC pair: the forward and the
backward IRC experiment both link to the same path through
`gc:hasResult`, and the path reaches its points through
`gc:hasReactionPathPoint`.

**`gc:hasReactionPathPoint`** - *"A property linking a reaction path
to one of its constituent points."*

**`gc:ReactionPathPoint`** - *"A class representing a single point
along a reaction path, with an index (position along the path) and an
energy value (the absolute total energy from the IRC log, not relative
to the starting point). May originate from an individual forward or
backward IRC log, or from a combined reaction-path file assembled from
both."* (The definition said "relative to the starting point" before
gc v0.8.9; the quoted text is the current wording.) In these graphs `gc:hasIndex`
runs continuously along the whole combined path (1 to N, each used
once); the direction appears only in the label, "(forward)" or
"(backward)"; and `gc:hasPathEnergy` points at a `gc:FloatValue`. The
stored energy is the absolute total energy from the IRC log, in hartree
(about -306 for the first point of the `aa` path). Subtract a reference
point - the first point, or the transition state - to get relative
energies.

**`gc:hasIndex`** - *"A property that defines a sequential arrangement
of material in numerical order, i.e. Frequency Peak, Orbital or a
sequence number in residue."* Used here to give reaction path points
their intended order.

**`gc:hasPathEnergy`** - *"A property that describes the energy at a
point along a reaction path. As produced by the ont_mm pipeline this is
the absolute total energy from the IRC log, in the unit of its
FloatValue (hartree); subtract a reference point, such as the first
point or the transition state, to get a relative energy."* (Before gc
v0.8.9 the definition said "relative energy"; see `gc:ReactionPathPoint`.)

## Species and atoms

A calculation is a *system* (the thing the input file describes); what
is in it are *species*. They are separate nodes so that the same
compound can be recognised across systems.

- **System**: `ex:molecule_<experiment>` (a `gc:Molecule`), linked from
  the experiment by `gc:hasMolecule`. It is the whole geometry.
- **Species**: `ex:species_<experiment>_<k>` (also a `gc:Molecule`),
  linked from the system by `gc:hasMolecule`. It carries
  `gc:hasInChIString` and `gc:hasInChIKey`, and `gc:hasAtom` for its
  atoms. A system with a water and a hydrate has two.
- **Atom**: `ex:atom_<experiment>_<n>` (a `gc:Atom`) with
  `gc:hasElementSymbol` and `gc:hasIndex`. The index is the position of
  the atom in the `$DATA` block of the input file, counted from 1. It is
  **not** an IUPAC number, and it differs from one experiment to the
  next. The coordinates are not in the graph; they stay in the files the
  graph points to.

A species gets an InChI only when the identity can be established
without guessing. The geometry is checked for connectivity, charge and
stereochemistry; where a stereocentre or double bond is undefined, or a
supplied InChI/InChIKey does not match the geometry, the species is
**refused** and gets no node at all, and the reason is written to
`species_report.tsv` beside the other instance files. Only minima
(`OPTIMIZE` runs that report "EQUILIBRIUM GEOMETRY LOCATED") are
considered. Competency question 16 shows how to ask for a species.

## Literature and review

**`dcterms:relation`** - from
[Dublin Core Terms](https://www.dublincore.org/specifications/dublin-core/dcmi-terms/),
an external, widely-used standard meaning, plainly: a related
resource. Used here to link an experiment to a published paper's DOI.

**`skos:editorialNote`** - from
[SKOS](https://www.w3.org/TR/skos-reference/), an external,
widely-used standard for exactly this purpose: an administrative or
editorial note, not part of the thing itself. Used here for a
researcher's own, contemporaneous review comments on an experiment -
the mechanism behind `run_notes.tsv`.

