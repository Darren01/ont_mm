# DGEMM "parameter number 13 had an illegal value" — reproducible crash with reduced-size custom BASNAM basis sets, GAMESS 15 Jul 2024 (R2 Patch 1)

## Environment

- GAMESS version: 15 Jul 2024 (R2 Patch 1), 64-bit Linux
- System: ARCHER2 (HPE Cray EX, AMD EPYC "Rome")
- Built with: `PrgEnv-gnu` (gfortran 11.2.0), target `linux64`, DDI comm `sockets`
- Math library: Cray LibSci 23.09.1.1 (GNU variant), linked manually via
  `GMS_LAPACK_LINK_LINE = "-L/opt/cray/pe/libsci/23.09.1.1/GNU/10.3/x86_64/lib -lsci_gnu_82 -ldl"`
  in `install.info` — this GAMESS release's `hpe-cray-ex` config target only
  auto-wires Cray LibSci for `GMS_HPC_SYSTEM_TARGET=perlmutter` specifically, so
  a generic ARCHER2 build required this manual linkage.
- Two small `lked` patches were also required to stop it falling back to a
  bundled (never-built) Netlib BLAS/LAPACK; happy to share full build notes if
  useful context.

## Summary

Custom `BASNAM`-defined basis sets that are smaller than the one we have
successfully run (33 total shells, def2-TZVPP-derived) consistently crash at
the very start of the SCF step with:

```
DDI Process N: error code 6
** On entry to DGEMM  parameter number 13 had an illegal value
```

This happens immediately after `END OF ONE-ELECTRON INTEGRALS`, before any SCF
iteration or DFT/PCM-specific code runs. Parameter 13 of `DGEMM` is `LDC`
(leading dimension of the output matrix), consistent with an array being
allocated with a dimension too small for the actual problem size.

## Reproducibility

The crash is **fully reproducible** and **independent of**:
- **Basis identity**: occurs both with a def2-SVP basis (22 shells, freshly
  sourced from Basis Set Exchange and verified byte-for-byte against the
  source — see attached `caa005bIRC-def2svp-test.inp`) and with a basis built
  by directly *removing* shells from our known-working def2-TZVPP basis (also
  22 shells, every remaining primitive/coefficient byte-identical to the
  working file — see attached `caa005bIRC-trimmedTZVPP-test.inp`).
- **Core count**: identical crash with 8 DDI processes and with a single (1)
  process — rules out any DDI work-distribution/chunking explanation.
- **Compute node**: identical crash reproduced on three different physical
  nodes across separate job submissions (`nid001026`, `nid003554`,
  `nid003972`).

## What works

The full, untrimmed def2-TZVPP basis (33 shells across H/C/O/Cl, same
molecule, same `$CONTRL`/`$SCF`/`$STATPT` settings, same PCM(water) setup) has
run successfully across many separate job submissions on the same build/system
(geometry optimizations, Hessian evaluations, single points) — see attached
`caa005bIRCCML1stdef2TZVPPe.inp` for a representative working input.

Additionally, the full bundled GAMESS example test suite (`runall`, all 49
`examNN` tests, all using GAMESS's own **built-in** `GBASIS=...` basis
mechanism rather than custom `BASNAM`) was run to completion on this same
build: 46/49 passed exactly or within ordinary floating-point tolerance; the
remaining 3 failures are explained by 2 tests simply not finishing inside our
job's time limit (comparing incomplete output against the reference) and 1
test missing its reference value by 1.1e-07 (smaller than several *passing*
tests' discrepancies — ordinary platform/compiler noise, not a real problem).
Several of these 49 tests use genuinely small systems, and **none** hit the
`DGEMM` crash. This narrows the likely cause specifically to how custom
`BASNAM`-defined basis sets are processed, rather than small problem size in
general — GAMESS's internal `GBASIS`-driven basis construction is evidently a
separate, unaffected code path.

We also tested GAMESS's **other** user-supplied-basis mechanism, `EXTFIL`
(reading a named basis from an external file via the `EXTBAS` environment
variable, keyed by chemical symbol, rather than `BASNAM`'s inline
per-atom-position blocks). Using the identical isolated-Cl-atom test case,
with the same basis data (byte-identical, this time supplied via an external
file instead of inline), the run got further (successfully located and read
the basis from the external file, reached `END OF ONE-ELECTRON INTEGRALS`)
but hit the **exact same `DGEMM` parameter-13 crash at the exact same stage**.
This rules out `BASNAM` specifically as the cause: both of GAMESS's
user-supplied-basis input mechanisms fail identically, while the built-in
`GBASIS` mechanism does not. This points at something in how GAMESS
constructs its internal basis-set data structures for any non-built-in basis
below some size threshold, independent of which input syntax supplied it.

## Minimal example of the failure

Molecule: chloroacetaldehyde hydrate + water (13 atoms, C1, neutral singlet).
`$CONTRL SCFTYP=RHF RUNTYP=OPTIMIZE DFTTYP=wB97X-D COORD=UNIQUE MAXIT=200 NOSYM=1`,
PCM(water), custom `BASNAM` basis referencing 4 named blocks (one per element).

Relevant log excerpt from an isolated single chlorine atom (13 total
electrons removed vs. the 13-atom molecule — the smallest possible test case,
UHF, no PCM, ~40 basis functions total, custom `$clbas` block copied
verbatim/byte-for-byte from a working larger input):

```
 ...... END OF ONE-ELECTRON INTEGRALS ......
 DDI Process 0: error code 6
 ** On entry to DGEMM  parameter number 13 had an illegal value
 ddikick.x: application process 0 quit unexpectedly.
```

Relevant log excerpt from the earlier 13-atom molecule tests (identical
pattern for both failing basis sets, all core counts, and all nodes tested):

```
 ...... END OF ONE-ELECTRON INTEGRALS ......
 CPU     0: STEP CPU TIME=     0.00 TOTAL CPU TIME=          0.0 (      0.0 MIN)
 TOTAL WALL CLOCK TIME=          0.1 SECONDS, CPU UTILIZATION IS    79.42%
 DDI Process 3: error code 6
 DDI Process 7: error code 6
 ** On entry to DGEMM  parameter number 13 had an illegal value
 [... one such line per DDI process ...]
 ddikick.x: application process 2 quit unexpectedly.
 ddikick.x: Fatal error detected.
          -------------
          GUESS OPTIONS
          -------------
          GUESS =HUCKEL            NORB  =       0          NORDER=       0
 INITIAL GUESS ORBITALS GENERATED BY HUCKEL   ROUTINE.
 HUCKEL GUESS REQUIRES     18686 WORDS.
 ddikick.x: Sending kill signal to DDI processes.
 ddikick.x: Execution terminated due to error(s).
```

(Note: the `HUCKEL GUESS REQUIRES...` line printing *after* the crash messages
in the log is just interleaved/buffered output from different DDI processes
during the crash, not necessarily true chronological order.)

1-process version of the same crash (rules out DDI distribution entirely):

```
 ...... END OF ONE-ELECTRON INTEGRALS ......
 STEP CPU TIME =     0.00 TOTAL CPU TIME =          0.0 (      0.0 MIN)
 TOTAL WALL CLOCK TIME=          0.9 SECONDS, CPU UTILIZATION IS     5.05%
 DDI Process 0: error code 6
 ** On entry to DGEMM  parameter number 13 had an illegal value
 ddikick.x: application process 0 quit unexpectedly.
```

## Community suggestions received (for reference / future follow-up)

**Forum response (different thread, but point 2 directly actionable and tested):**
1. Increase the XC integration grid
2. Increase the accuracy of the integrals (ITOL and ICUT)
3. Adjust/remove PCM (PCMCAV, TESCAV options) to isolate whether PCM is a factor
4. Check Susi Lehtola's analysis of numerically sensitive XC functionals for wB97X-D

**On point 4** (checked directly against Lehtola & Marques, "Many recent
density functionals are numerically ill-behaved," arXiv:2206.14062): wB97X-D
is NOT examined in this paper. The authors explicitly state that
range-separated hybrids with dispersion corrections (their own example:
"the ωB97X-D3 functional") are "not thought to present major issues with
numerical behavior" and are excluded from the study, which focuses on base
GGA/meta-GGA functionals (heavily the SCAN family). This doesn't rule out
wB97X-D having some other numerical issue, but this specific, often-cited
analysis doesn't implicate it.

**Separately, PCseg-2 (see below) gave a strong, independent line of
evidence pointing away from a genuine functional/PES instability and toward
our custom-basis implementation being the actual culprit all along** --
worth keeping points 1-3 in reserve if a genuine wB97X-D-specific numerical
issue ever needs isolating in future work, but not the immediate priority
given the PCseg-2 result.

## Follow-up: understand and fix the root cause, report back to the community

**Update:** switching to GAMESS's native `PCseg-2` basis (same functional,
same geometry, same PCM setup) resolved the instability completely --
converged cleanly to a chemically sensible energy (`-766.37` Hartree,
matching a rough atomic-sum estimate of `~-763`, vs. the custom
`def2-TZVPP` basis's `-491.67` at the identical geometry) with **zero
imaginary frequencies** in the final Hessian. This strongly suggests the
16-negative-eigenvalue "instability" documented above was never a real
feature of the potential energy surface -- it was the optimizer correctly
reacting to a badly wrong energy surface produced by a broken custom-basis
implementation on this build, not evidence of a genuine chemical/physical
effect. Full write-up posted back to the original thread.

Once time allows, worth digging into GAMESS's actual Fortran source (full
source tree available at /work/e283/e283/darren01/gamess/source/ on
ARCHER2) for the basis-set-construction routines specifically handling
BASNAM/EXTFIL input, to identify the actual root cause of both the DGEMM
crash AND the wrong total energy on the full molecule under custom
def2-TZVPP. A genuine fix (not just a bug report) would be a valuable
thing to contribute back to the GAMESS Google Group.

### Update: likely root cause identified via source inspection

Traced the crash directly through GAMESS's Fortran source. Starting point:
the crash occurs immediately after `END OF ONE-ELECTRON INTEGRALS`, right
around the printing of `INITIAL GUESS ORBITALS GENERATED BY HUCKEL
ROUTINE.` -- pointing at `guess.src`, which contains exactly that format
string (line 986).

`guess.src` contains three `DGEMM` calls, all inside/around the subroutine
`COPROJ` ("corresponding orbital projection" -- H.F. King et al.,
J. Chem. Phys. 47, 1936-1941 (1967)), which projects orbitals from GAMESS's
own internal minimal ("MBS") reference basis onto the actual requested
basis for the Huckel guess.

The second `DGEMM` call inside `COPROJ` (source line 674) is:

```fortran
CALL DGEMM('N','N',NMO,NREST,L1,ONE,WRK(MINMO,1),L1,
     *               VA(1,MINMO),L1,ZERO,D,NPROJ)
```

Parameter 13 (`LDC`) here is `NPROJ`. `D` is declared `DIMENSION
D(NPROJ,L0)`, and `NPROJ` is computed just before the call (in the calling
routine, around line 1944):

```fortran
C                  DO AT MOST 5 VIRTUALS FROM THE HUCKEL
      NPROJ=MIN(L0CO-NCORE,NDOC+NACT+5)
```

Note that `NPROJ` is derived entirely from the internal minimal-basis size
(`L0CO`) and the electron count (`NDOC+NACT+5`, i.e. occupied orbitals plus
up to 5 extra virtuals) -- it never references `L1`, the size of the actual
target basis. `DGEMM` requires `LDC >= M` (here `M = NMO`, a subset count
of `NPROJ`). If the requested basis is small enough that it does not
actually provide `NDOC+NACT+5` orbitals (i.e. effectively `L1 < NPROJ` for
some code path), this call would produce exactly the "parameter 13 had an
illegal value" crash we observed.

In plain terms: the Huckel guess unconditionally tries to build occupied
orbitals plus up to 5 additional virtuals from its internal projection
scheme, regardless of how small the actual target basis is. For a small
enough custom basis (our isolated Cl atom case, ~40 basis functions total),
there may not be room for that many projected orbitals relative to how the
array is dimensioned, while GAMESS's own built-in `GBASIS` bases either
avoid this code path differently or are never exercised at a small enough
size in normal use for this to surface.

**This is our leading hypothesis, not yet fully proven** -- confirming it
properly would need instrumenting the actual runtime values of `L0CO`,
`NCORE`, `NDOC`, `NACT`, and `L1` for one of our failing cases (e.g.
temporarily adding a `WRITE` statement before the `NPROJ=MIN(...)` line and
rebuilding), which we have not yet done. If confirmed, the fix would likely
be as simple as also bounding `NPROJ` by `L1`, e.g.:

```fortran
NPROJ=MIN(L0CO-NCORE,NDOC+NACT+5,L1)
```

Posting this as a follow-up on the original thread in case anyone with
deeper familiarity with `guess.src`/`COPROJ` can confirm or correct this
reading, or knows of an existing fix in a newer release.

## Questions for the list

1. Is this a known issue with custom user-supplied basis sets (either
   `BASNAM` or `EXTFIL`) below some size threshold? The fact that GAMESS's
   own 49-test example suite (all using `GBASIS=...`) passes cleanly on this
   same build, while even a single isolated atom crashes identically via
   *both* `BASNAM` and `EXTFIL`, points at how non-built-in basis sets are
   internally constructed/dimensioned, rather than problem size or input
   syntax specifically.
2. Given our build required manual `GMS_LAPACK_LINK_LINE` linkage (see
   Environment above, since this release's `hpe-cray-ex` LibSci
   auto-configuration is gated on `GMS_HPC_SYSTEM_TARGET=perlmutter`
   specifically) — is there a known array-sizing assumption specific to the
   non-built-in-basis code path that could misfire under this kind of custom
   LibSci linkage, that the standard `GBASIS` path doesn't exercise?
3. Is there a recommended minimum basis size, or a workaround, for smaller
   custom bases (BASNAM or EXTFIL) on this kind of build?

Happy to provide full, unedited log files (currently several hundred KB to a
few MB each) on request.

## Files to attach when posting

- `caa005bIRC-def2svp-test.inp` (fails)
- `caa005bIRC-trimmedTZVPP-test.inp` (fails, built from proven-working text)
- `caa005bIRCCML1stdef2TZVPPe.inp` (works, for comparison)
- Full logs: `caa005bIRC-def2svp-test.log`, `caa005bIRC-trimmedTZVPP-test.log`,
  `caa005bIRC-trimmedTZVPP-test-1core.log` (from ARCHER2 — copy these over
  before posting)
