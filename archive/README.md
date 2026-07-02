# Archived: gc_module.ttl

## What this file is

`gc_module_archived.ttl` is a manual extraction of terms from the Gainesville 
Core Ontology (GNVC v0.7) that were needed by ont_mm. It was created as a 
workaround because GNVC v0.7 could not be imported directly into ont_mm due 
to several structural defects in the original ontology file.

## Why the extraction workaround was necessary

GNVC v0.7 (`gc.owl`) had the following defects that prevented clean OWL import:

1. **Obsolete DAML periodic table import** — GNVC imported the DAML periodic 
   table (http://www.daml.org/2003/01/periodictable/PeriodicTable.owl), a 
   2003-era precursor to OWL that is no longer resolvable. This caused any 
   tool attempting to load GNVC to fail when resolving imports.

2. **Stale QUDT namespace** — GNVC referenced QUDT unit classes via the old 
   NASA namespace (http://data.nasa.gov/qudt/owl/qudt#) which is no longer 
   active. The current QUDT namespace is http://qudt.org/schema/qudt/.

3. **OWL modelling errors** — Several terms had class/individual collisions 
   (gc:Bond, gc:RHF), incorrect meta-level domain/range declarations 
   (gc:hasMolecularProperty using rdfs:Class as range), and a property/class 
   collision (gc:hasFloatValue).

4. **UTF-8 encoding errors** — String literals containing non-ASCII characters 
   (Schrödinger, Møller-Plesset) were corrupted due to double-encoding.

Rather than fix GNVC at the time, the approach taken was to extract only the 
terms needed by ont_mm into this standalone Turtle module.

## Why this workaround is now retired

All the above defects have been repaired in a maintained fork of GNVC, 
available at:

https://github.com/Darren01/GC-Ontology-Mirror

The repaired version is `gc07_without_imports.owl`, which is now imported 
directly by ont_mm via the catalog file (`source/catalog-v001.xml`).

## Transition date

June 2026

## What replaced this file

`source/gnvc_improved.owl` — a local copy of the repaired GNVC fork, 
imported via `source/catalog-v001.xml` which maps the canonical 
`http://purl.org/gc/` IRI to the local file.
