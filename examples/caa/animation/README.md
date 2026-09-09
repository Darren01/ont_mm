# Making the reaction animation

[`make_animation.spt`](./make_animation.spt) is the real Jmol script
used to generate the looping GIF shown in the main
[`caa` README](../README.md) - kept here so the process is
reproducible, both for re-running it on this same trajectory and for
adapting it to a different one later (e.g. once the `aa` dataset
exists).

This took a few real, genuine attempts to get right - documented
honestly below, since the mistakes are as useful as the final result.

## Prerequisites

- [Jmol](https://jmol.sourceforge.net/) - the desktop application,
  not JSmol (the in-browser version). This matters: JSmol has real,
  documented trouble loading files over `file://`, which is exactly
  how this script works.
- [gifsicle](http://www.lcdf.org/gifsicle/) - `sudo apt install
  gifsicle` on Ubuntu. Used only for the final looping step (see
  below) - Jmol's own GIF output doesn't loop by default.

## Running it

Open Jmol → **File → Script Editor**, paste in the contents of
`make_animation.spt`, adjust the two `file:///` paths near the top and
bottom to your own machine, and run it. It will take a while - one
snapshot per frame, 200+ frames for this trajectory.

## What each part does, and the real bugs hit along the way

**`n = getProperty("modelInfo.modelCount")`** - gets the real number
of frames in the loaded file. The first attempt used `_modelCount`,
which isn't a real Jmol variable - it silently evaluated to nothing,
so the loop below it never ran a single iteration, and the "finished"
GIF was a 14-byte, completely empty file. `getProperty(...)` is the
correct, documented way to ask for this.

**`frame @{"1." + i}`** - jumps to a specific frame within the loaded
file. The first working attempt used `frame next`, which ran the
correct number of times but never actually advanced - it produced 200+
identical snapshots of the same geometry. The right syntax is
`frame <file>.<frame>` (`1.1`, `1.50`, `1.200`, ...) - the `1.` prefix
means "file #1" (there's only one file loaded here). Building this
string with `@{"1." + i}` lets the loop count normally with `i`
while still producing the correct `frame 1.N` command each time.

**`moveto 0.0 { ... }`** - sets a specific, fixed viewing angle before
each snapshot, rather than leaving it to whatever Jmol's default
orientation happens to be (which, left alone, gave a genuinely
unhelpful angle here). To get your own numbers for a different
trajectory: manually rotate/zoom the model with the mouse until it
looks right, right-click the model → **Console**, type
`show orientation`, and copy the resulting `moveto ...` line directly -
it already contains everything after the first number. That first
number is the animation *time* (in seconds) for Jmol to move into that
orientation - set it to `0` here, since we want each of 200+ frames to
snap into position instantly, not spend a second animating into it
every single time.

**`animation fps 10`** - controls playback speed once assembled into
the GIF. Higher = faster, not slower - a real, easy mix-up given "fps"
sounds like it should work the other way round. `fps 4` felt sluggish;
`fps 10` was the number that actually looked right here.

**`capture transparent "..."` / `capture end`** - starts and finishes
the GIF recording; each `write` call inside the loop adds one frame to
it.

## Looping

Jmol's own GIF output plays once and stops - it does not loop by
default, and no reliable, documented Jmol scripting option to control
this was found. The fix is a separate step afterwards:

```bash
gifsicle --loopcount=0 caa_IRC_animation.gif -o caa_IRC_animation_looped.gif
```

`--loopcount=0` is the standard convention for "loop forever."

## What this GIF is, and isn't

This is a fixed-angle, illustrative rendering - useful for a quick
look, not a substitute for the real data. To rotate, zoom, measure
distances, or inspect any individual frame properly, load
[`../outputs/caa005bIRC.cml`](../outputs/caa005bIRC.cml) directly into
Jmol yourself.
