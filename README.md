## About this fork

This is a maintained fork of the Gainesville Core Ontology (GNVC v0.7), 
originally developed by Chemical Semantics, Inc. and mirrored by NFDI4Chem.

GNVC is a valuable ontology for publishing computational chemistry results, 
but v0.7 contains several structural defects that prevent clean import and 
use with current OWL tooling. This fork aims to repair those defects while 
preserving the original term IRIs and conceptual structure, and to extend 
coverage where gaps have been identified.

If you are the original author or a stakeholder in GNVC, we would welcome 
contact. The goal is to bring this ontology back into active maintenance, 
not to replace or compete with any future official release.

---

## Repairs in v0.8.0

The working file is `gc07_without_imports.owl`. The following structural 
defects from GNVC v0.7 have been repaired:

### Fix 1 — DAML periodic table import removed
GNVC v0.7 imported the DAML periodic table 
(http://www.daml.org/2003/01/periodictable/PeriodicTable.owl), a 2003-era 
precursor to OWL that is no longer resolvable. This import was removed and 
replaced with a local `gc:Element` stub class with a `rdfs:seeAlso` reference 
to ChEBI (http://purl.obolibrary.org/obo/CHEBI_33250).

### Fix 2 — QUDT namespace updated
GNVC referenced QUDT unit classes via the old NASA namespace 
(http://data.nasa.gov/qudt/owl/qudt#) which is no longer active. All 
references have been updated to the current QUDT namespace 
(http://qudt.org/schema/qudt/).

### Fix 3 — gc:Bond class/individual collision resolved
A cardinality restriction was incorrectly applied to gc:Bond as a named 
individual rather than as a class axiom. This has been corrected by moving 
the restriction to a proper owl:subClassOf axiom on the class.

### Fix 4 — gc:RHF/UHF/ROHF modelling corrected
gc:RHF was simultaneously declared as a class and a named individual. 
gc:RHF, gc:UHF, and gc:ROHF are now consistently modelled as subclasses 
of gc:SpinType, consistent with the dominant pattern used for methodology 
classes elsewhere in GNVC.

### Fix 5 — gc:hasFloatValue class/property collision resolved
gc:hasFloatValue was declared as both a datatype property and a class. 
The spurious class declaration was removed. The range of gc:hasMass was 
corrected from gc:hasFloatValue (a property) to gc:FloatValue (the 
correct class).

### Fix 6 — Meta-level domain/range declarations removed
gc:hasMolecularProperty and gc:hasAtomProperty had rdfs:Class and 
owl:ObjectProperty as domain/range values respectively. These meta-level 
constructs have been removed. The stray owl:ObjectProperty and rdfs:Class 
class declarations have also been removed.

### Fix 7 — UTF-8 encoding errors corrected
String literals containing non-ASCII characters were corrupted due to 
double-encoding. Affected terms: Schrödinger, Møller-Plesset.

### Fix 8 — gc:hasSystemMultiplicity consolidated
gc:hasSystemMultiplicity existed as both an object property and a datatype 
property with conflicting axioms. These have been consolidated into a single 
datatype property with correct domain (gc:MolecularSystem), range 
(xsd:positiveInteger), and complete annotations.

### Fix 9 — Ontology metadata updated
The ontology version has been bumped to 0.8.0 with a proper owl:versionIRI. 
dc:modified and dcterms:contributor annotations have been added. Stale 
commented-out import statements and encoding errors in the description have 
been removed.

---

## Quality improvements in v0.8.0

Beyond structural repairs, the following quality improvements have been made:

- Duplicate rdfs:label values resolved across 15 terms
- Missing rdfs:label annotations added to 13 terms
- QUDT unit class declarations given proper labels
- Multiple label conflicts resolved
- dcterms:license added in ROBOT-compatible form
- UTF-8 encoding errors fixed throughout

---

## Formal definitions (IAO:0000115) — work in progress

Formal OBO Foundry definitions have been added for the following terms, 
sourced from the IUPAC Gold Book (https://goldbook.iupac.org) and IUPAC 
PAC recommendations:

- gc:BasisSet — Gold Book BT06999
- gc:Atom — Gold Book A00493
- gc:Molecule — Gold Book M03986
- gc:Orbital — Gold Book O04317
- gc:WaveFunction — Gold Book W06659
- gc:DensityFunctional — PAC 1999, 71, 1919

Definitions for remaining terms are in progress. Contributions welcome — 
see open issues labelled `good first issue`.

The following review informed the design decisions in this fork:
https://doi.org/10.26434/chemrxiv-2024-fvzpq

---

## Original NFDI4Chem mirror note

This repository contains a copy of the Gainesville Core Ontology that was 
developed by Chemical Semantics in 2015. The NFDI4Chem terminology service 
created the original mirror because the original IRI no longer resolves.
The ontology was taken from this snapshot of the internet archive:
https://web.archive.org/web/20221005233201fw_/http://ontologies.makolab.com/gc/gc07.owl
Since this archived version imports outdated and unresolvable versions of 
BFO and QUDT, the associated import statements were commented out in the 
original mirror (see gc07_without_imports.owl).

---

## Contributing

If you would like to contribute definitions, bug fixes, or extensions:

1. Open an issue describing what you want to add or fix
2. Fork this repository
3. Make your changes to `gc07_without_imports.owl`
4. Verify with `xmllint --noout gc07_without_imports.owl` and 
   `robot convert --input gc07_without_imports.owl --output test.ttl`
5. Open a pull request

Issues labelled `good first issue` are suitable for new contributors and 
typically involve adding a formal IAO:0000115 definition to an existing term.

---

## Additions in v0.8.1

### gc:debyeSquaredPerAmuAngstromSquared added
GAMESS (US) reports IR intensity in Debye**2/amu-Angstrom**2, which had no 
corresponding unit individual in the ontology (`gc:cm-1` existed for 
frequency, but nothing for intensity). Added as a properly QUDT-typed 
individual (`qudt:DerivedUnit`), consistent with the existing `gc:cm-1` 
pattern. Distinct from the km/mol convention used by some other packages 
(e.g. Gaussian) - the two require a conversion factor (1 Debye**2/amu-Angstrom**2 
= 42.2561 km/mol), not a direct equivalence.

Contributed via the ont_mm project (github.com/Darren01/ont_mm), which 
consumes this ontology for a GAMESS output extraction and SPARQL-driven 
data pipeline.

## Additions in v0.8.2

### Thermochemistry classes and properties added
GAMESS (US) (and other quantum chemistry packages) reports thermochemical
state functions - zero-point energy, enthalpy, entropy, and Gibbs free
energy - computed from a vibrational/frequency analysis. These had no
corresponding classes in the ontology; SystemEnergies previously only
covered ElectronicEnergy, CoreEnergy, and TotalBOPotentialEnergy.

Added four new classes (all subClassOf SystemEnergies) and four
corresponding properties (all subPropertyOf hasSystemEnergiesResult,
domain SystemEnergies, range FloatValue), each with a Gold-Book-sourced
IAO:0000115 definition:

- gc:ZeroPointEnergy / gc:hasZeroPointEnergy (Gold Book 08215)
- gc:Enthalpy / gc:hasEnthalpy (Gold Book E02141)
- gc:Entropy / gc:hasEntropy (Gold Book E02149)
- gc:GibbsFreeEnergy / gc:hasGibbsFreeEnergy (Gold Book G02629)

Also added gc:joulePerMoleKelvin, a QUDT-typed unit individual for
entropy's native unit (J/(mol K)) - distinct from the kJ/mol unit used
for enthalpy and Gibbs free energy in the same GAMESS output table.

Contributed via the ont_mm project (github.com/Darren01/ont_mm), which
consumes this ontology for a GAMESS output extraction and SPARQL-driven
data pipeline.

## Additions in v0.8.3

### gc:degree added
Bond angle and dihedral angle constraint values had no corresponding
unit individual in the ontology - only gc:angstrom existed, for
distance constraints.

Added gc:degree as a properly QUDT-typed individual (qudt:PlaneAngleUnit).

Contributed via the ont_mm project (github.com/Darren01/ont_mm), which
consumes this ontology for a GAMESS output extraction and SPARQL-driven
data pipeline.

## Additions in v0.8.4

### SaddlePoint, IRC, ReactionPath, ReactionPathPoint added
A transition-state/reaction-pathway workflow - locating a saddle point,
then following the intrinsic reaction coordinate away from it in both
directions to connect reactants and products - had no corresponding
vocabulary anywhere in the ontology. A review of related ontologies in
the same ecosystem (OntoCompChem, OntoPESScan) confirmed neither covers
this either - both are limited to single point/geometry optimization/
frequency calculations and potential energy surface scans respectively;
transition-state search and IRC following appear to be a genuine gap
in the existing landscape, not something reused from elsewhere.

Added four new classes:

- gc:SaddlePoint (subClassOf MolecularComputation) - a calculation
  that locates a stationary point with exactly one direction of
  negative curvature (a first-order saddle point), corresponding to a
  transition state.
- gc:IRC (subClassOf MolecularComputation) - a calculation that
  follows the intrinsic reaction coordinate away from a saddle point,
  in either the forward or backward direction.
- gc:ReactionPath - the combined reaction path connecting reactants to
  products via a transition state, typically assembled from a forward
  and a backward IRC run sharing the same saddle point.
- gc:ReactionPathPoint - a single point along a reaction path, with an
  index (position along the path) and an energy value relative to the
  starting point.

Contributed via the ont_mm project (github.com/Darren01/ont_mm), which
consumes this ontology for a GAMESS output extraction and SPARQL-driven
data pipeline.

## Additions in v0.8.5

### InfraRedSpectrum merged into InfraRedSpectra; UVVisSpectrum re-parented
Two disconnected duplicate/orphaned terms found and fixed:

InfraRedSpectrum and InfraRedSpectra were accidental duplicates for the
same concept - the plural was already correctly subClassOf
VibrationalSpectra, properly wired into the CalculationResult chain;
the singular was disconnected (subClassOf GainesvilleCoreTerm only) but
carried the real Gold Book citation (IUPAC 08618). Moved the citation
onto the properly-wired class, deleted the duplicate. No pipeline
impact - neither class was referenced by any built writer at the time.

UVVisSpectrum was similarly disconnected. Re-parented from
GainesvilleCoreTerm to ElectronicSpectra (properly wired, same sibling
pattern as InfraRedSpectra/RamanSpectra under VibrationalSpectra) - now
automatically eligible for the existing hasFrequencyPeak property
(domain already includes ElectronicSpectra), no new properties needed.

Contributed via the ont_mm project (github.com/Darren01/ont_mm), which
consumes this ontology for a GAMESS output extraction and SPARQL-driven
data pipeline.

## Fixes in v0.8.6

### Dangling domain references corrected
Three properties (xAxis, yAxis, yAxisUnit) still had rdfs:domain
pointing at InfraRedSpectrum, the class deleted in v0.8.5's merge -
left dangling by that change rather than caught at the time. Corrected
to point at InfraRedSpectra, the class InfraRedSpectrum was merged
into.

Contributed via the ont_mm project (github.com/Darren01/ont_mm), which
consumes this ontology for a GAMESS output extraction and SPARQL-driven
data pipeline.

## Additions in v0.8.7

### gc:ppm added
NMR shielding and chemical shift values (isotropic and anisotropy
components) had no corresponding unit individual in the ontology -
nothing in gc: represented parts per million, the standard unit both
quantities are conventionally reported in.

Added gc:ppm as a properly QUDT-typed individual (qudt:Unit), with an
owl:sameAs link to the real, current QUDT PPM unit
(http://qudt.org/vocab/unit/PPM, itself typed qudt:Unit under
quantitykind:DimensionlessRatio, alongside PERCENT/PPB/PPT) - the same
verify-before-reuse discipline as gc:degree and gc:angstrom.

(Originally added in the commit before this one, but without its own
version bump - v0.8.7 corrects that, rather than leaving gc:ppm
permanently unversioned.)

Contributed via the ont_mm project (github.com/Darren01/ont_mm), which
consumes this ontology for a GAMESS output extraction and SPARQL-driven
data pipeline.

## Fixes in v0.8.8

### Multiple rdfs:domain declarations now read as "any of", not "all of"
Six properties - hasBasisSet, hasForceField, hasFrequencyPeak, hasMass,
hasParameterSet and hasPeakCount - each listed two or three rdfs:domain
classes as separate statements. In OWL separate domain statements are
conjunctive: a subject must belong to *all* of the listed classes. The
intent was plainly "any of". Reasoned over real data this produced
false conclusions: every experiment typed as a gc:Atom, and every
infrared spectrum also typed as an NMR spectrum and an electronic
spectrum.

Each of the six now has a single rdfs:domain, the owl:unionOf the
classes it listed - the same form three other properties already used.
Verified by rebuilding two real datasets from the ont_mm project and
reasoning over them: the reasoner stays consistent, exactly the false
types disappear (30 gc:Atom, 15 NMR and 15 electronic spectrum
assertions in one dataset; 61, 32 and 32 in the other), and nothing
else changes.

Deliberately not changed: hasBasisSet is still declared as both an
object property and a datatype property (illegal punning in OWL 2 DL),
with ranges BasisSet and Literal. And as a sub-property of hasFeature,
whose domain is MolecularMethodology, it still implies that whatever
carries a basis set is a methodology - which matches its own definition
("assigned to a given quantum methodology"), so that is a modelling
question for data producers rather than a defect to patch here.

Contributed via the ont_mm project (github.com/Darren01/ont_mm), which
consumes this ontology for a GAMESS output extraction and SPARQL-driven
data pipeline.

## Acknowledgements
The repair and documentation work in this fork was carried out by Darren Rhodes
using Claude (Anthropic) as a technical assistant for XML editing, ROBOT tooling, and OWL pattern guidance.
