# Making the reaction animation

[`make_animation.spt`](./make_animation.spt) is the real Jmol script
used to generate the looping GIF shown in the main
[`aa` README](../README.md) - the same approach used for
[`caa`'s own animation](../../caa/animation/README.md), reused here
almost unchanged. See that README for the fuller explanation of
`getProperty`, `frame 1.N`, `animation fps`, and `capture`/`gifsicle` -
this one only covers what was actually different or went wrong for
`aa` specifically.

## Prerequisites

Same as `caa`'s: [Jmol](https://jmol.sourceforge.net/) (the desktop
application, not JSmol) and [gifsicle](http://www.lcdf.org/gifsicle/)
for the final looping step.

## Getting `aa001_IRC.cml` in the first place

Unlike `caa`, which had a single, already-combined IRC trajectory file,
`aa`'s two IRC directions (`aa001e.log`, `aa001f.log`) needed combining
first. This was done with
[wxMacMolPlt](https://brettbode.github.io/wxmacmolplt/) - **File → Open**
one direction, **File → Append** the other (its own built-in feature
for exactly this: combining multiple GAMESS files into one animation),
then **File → Save As** → `.cml` (the sole supported save format since
wxMacMolPlt 5.6).

## A real mistake, worth documenting honestly

The first attempt at the `moveto` line looked like this:

```
moveto 0.0 { moveto /* time, axisAngle */ 1.0 { 81 -962 262 82.2} ... }
```

This doesn't work, and Jmol failed on it silently - no visible error,
the script just did nothing when run. The real cause: `show
orientation`'s own console output is already a complete, valid
`moveto` command on its own - it was pasted *inside* a second, generic
`moveto 0.0 { ... }` wrapper by mistake, producing a doubled, invalid
structure. The fix is simply to use the real, copied line directly,
with nothing wrapping it:

```
moveto 0.0 { 81 -962 262 82.2} 49.72 0.0 0.0 {3.0622349 1.3389854 -2.6526475} 4.7753077 {0 0 0} 0 0 0 3.0 0.0 0.0;
```

(The leading `1.0` from the real `show orientation` output - the
transition *time* in seconds - is deliberately changed to `0.0` here
too, same reasoning as `caa`: an instant snap into position each
frame, not a second-long pan repeated 30+ times.)

## What this GIF is, and isn't

Same as `caa`: a fixed-angle illustration, not the real data. To
rotate, zoom, measure distances, or inspect any individual frame
yourself, open [`aa001_IRC.cml`](../outputs/aa001_IRC.cml) directly in
Jmol.
