# Glossary of Terms

Following [SAMOD](https://essepuntato.it/samod/) (Peroni, 2016), a
proper ontology development process produces a glossary "collected
from the scenario and the competency questions" - tied to the model
itself, not to any one dataset's actual contents. That's deliberately
how this glossary is scoped: every term below is one that
[`COMPETENCY_QUESTIONS.md`](./COMPETENCY_QUESTIONS.md) actually
references, whether or not the `caa` example happens to populate it.
Some terms here (`hasMethod`, `hasBasisSet`) are things the questions
need but the graph doesn't yet provide - included anyway, since the
glossary describes the model the competency questions are written
against, not just what one example dataset currently contains.

Where a definition comes directly from the ontology's own schema
(`gc_core.ttl`), it's quoted as such. Where a term is this project's
own (`ex:`), it has never actually had a formal definition anywhere in
the project until now - noted honestly below, not disguised as
something inherited.

## Experiment types

These classify what kind of GAMESS (US) calculation an experiment
actually was - see `classify_gamess_jobs()` in `gamess_functions` for
exactly how a raw `RUNTYP` value gets mapped to one of these.

**`gc:MolecularComputation`** - *"A class for MolecularComputation."*
(Gainesville Core's own definition - genuinely this brief.) The
general parent class every experiment type below belongs to.

**`gc:GeometryOptimization`** - *"A class for calculations in
computational chemistry that aim to find molecular geometry of lowest
energy."* (Gainesville Core)

**`gc:VibrationalAnalysis`** - *"A class for the computations of
vibrational spectrum of molecules."* (Gainesville Core - a second,
near-duplicate comment, *"A class for VibrationalAnalysis,"* also
exists in the schema but adds nothing; the one above is the real
definition.)

**This project's own usage note, not part of the Gainesville Core
definition above:** a run whose raw `RUNTYP=OPTIMIZE` also has
`HSSEND=.TRUE.` set gets classified as `VibrationalAnalysis`, not
`GeometryOptimization` - the frequency calculation appended to confirm
a genuine stationary point is judged the more scientifically
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

## Files and provenance

**`ex:hasInputFile`**, **`ex:hasOutputFile`** - this project's own
properties, linking an experiment to its real `.inp`/`.log` files.
Never formally defined anywhere until now: **`ex:hasInputFile`**
relates an experiment to the GAMESS (US) input deck it was run from;
**`ex:hasOutputFile`** relates it to the log file(s) it produced.

**`prov:wasGeneratedBy`** - from
[W3C PROV-O](https://www.w3.org/TR/prov-o/), a real, external,
widely-used standard for describing where something came from. Used
here to link a generated file to the experiment that produced it -
the mechanism behind tracing "what output came from this input."

## Constraints

**`ex:DistanceConstraint`**, **`ex:AngleConstraint`**,
**`ex:DihedralConstraint`** - this project's own classes, never
formally defined until now: a geometric restriction applied during a
calculation, fixing a bond distance, bond angle, or dihedral angle to
a specific target value rather than letting it optimize freely.

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

**`gc:hasFloatValue`** - *"A property that describes floating point
value."* The actual number at the end of a reification chain - e.g.
`experiment -> hasResult -> energies -> hasEnthalpy -> [an entity] ->
hasFloatValue -> the real number`. Every energetic quantity below
follows this same pattern: the named property (`hasEnthalpy`, etc.)
points to a separate entity, not the number directly, and that
entity's own `hasFloatValue` holds the real value.

**`gc:hasElectronicEnergy`** - *"A property that describes the
electronic energy."*

**`gc:hasZeroPointEnergy`** - *"A property that describes the
zero-point energy."*

**`gc:hasEnthalpy`** - *"A property that describes the enthalpy."*

**`gc:hasEntropy`** - *"A property that describes the entropy."*

**`gc:hasGibbsFreeEnergy`** - *"A property that describes the Gibbs
free energy."*

## Vibrational data

**`gc:hasFrequencyPeak`** - *"A property that describes the value of a
frequency peak of the vibrational spectrum."* Links a spectrum to one
of its individual peaks.

**`gc:hasFrequency`** - *"A property that describes the value of a
frequency at the peak of the spectrum."* A negative value here means
an imaginary frequency - the standard, real signal used throughout
this project to flag whether a geometry is a genuine stationary point
(zero expected for a minimum, exactly one for a confirmed transition
state).

## Reaction paths

**`gc:hasReactionPathPoint`** - *"A property linking a reaction path
to one of its constituent points."*

**`gc:hasIndex`** - *"A property that defines a sequential arrangement
of material in numerical order, i.e. Frequency Peak, Orbital or a
sequence number in residue."* Used here to give reaction path points
their real, intended order.

**`gc:hasPathEnergy`** - *"A property that describes the relative
energy at a point along a reaction path."*

## Literature and review

**`dcterms:relation`** - from
[Dublin Core Terms](https://www.dublincore.org/specifications/dublin-core/dcmi-terms/),
a real, external, widely-used standard meaning, plainly: a related
resource. Used here to link an experiment to a published paper's DOI.

**`skos:editorialNote`** - from
[SKOS](https://www.w3.org/TR/skos-reference/), a real, external,
widely-used standard for exactly this purpose: an administrative or
editorial note, not part of the thing itself. Used here for a
researcher's own, contemporaneous review comments on an experiment -
the mechanism behind `run_notes.tsv`.

## Not yet populated, but part of the model

**`gc:hasMethod`** - *"A property that defines the calculation method
for given technology."* Defined in the schema; not yet written by any
extraction code into any experiment in any built graph.

**`gc:hasBasisSet`** - *"A property that allows Basis Sets to be
assigned to a given quantum methodology."* Same real status as
`hasMethod` above - defined, unused. Together these are the level of
theory gap noted throughout `COMPETENCY_QUESTIONS.md`.
