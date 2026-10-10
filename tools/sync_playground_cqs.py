#!/usr/bin/env python3
"""Keep the SPARQL playground aligned with COMPETENCY_QUESTIONS.md.

The competency questions file is the single source of truth. This script
reads every numbered question ("## 7. Find a ...") and its first ```sparql
block, then writes them into tools/sparql_playground.html between the
markers

    // BEGIN GENERATED: competency questions
    // END GENERATED: competency questions

so the playground's "Competency questions" buttons always carry exactly the
text the document shows, and each button links back to its section.

It can also add (or refresh) a "Try it in the playground" link under each
question heading in the document itself.

Usage (from the repo root; standard-library Python 3 only):

    python3 tools/sync_playground_cqs.py            # update playground + doc links
    python3 tools/sync_playground_cqs.py --check    # change nothing; exit 1 if out of date
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOC = ROOT / "COMPETENCY_QUESTIONS.md"
PLAYGROUND = ROOT / "tools" / "sparql_playground.html"
GLOSSARY = ROOT / "GLOSSARY.md"

DOC_URL = "https://github.com/Darren01/ont_mm/blob/main/COMPETENCY_QUESTIONS.md"
PLAYGROUND_URL = "https://darren01.github.io/ont_mm/tools/sparql_playground.html"

BEGIN = "// BEGIN GENERATED: competency questions"
END = "// END GENERATED: competency questions"
LINK_MARK = "<!-- playground-link -->"

# Facts the playground needs that cannot be read from the document.
# Edit these when a question changes; --check does not know them.
#   dataset: the example graph the question's IDs belong to (the buttons
#            say so, and link to the right one). Omit if it works on both.
#   skip:    why the playground cannot run it (shown instead of a button
#            that would fail). The question is still listed, with its link.
PLAYGROUND_NOTES = {
    1: {"label": "Experiments by type",
        "blurb": "The basic inventory - every experiment, grouped by what kind of calculation it was."},
    2: {"label": "Review notes",
        "blurb": "Every experiment with a recorded annotation - the real, contemporaneous debugging trail."},
    3: {"label": "Trace a file", "dataset": "caa",
        "blurb": "Where did these output files come from? Swap the input file for any other experiment's own."},
    4: {"label": "Constraints",
        "blurb": "The geometric constraints applied in each experiment, with their target values and units."},
    5: {"label": "Linked to a paper",
        "blurb": "Which experiment is linked to a specific DOI. An honest \"no results\" is a real finding for a graph with no link recorded."},
    6: {"label": "Find the exact geometry",
        "blurb": "Which experiment used a specific, known constraint value."},
    7: {"label": "Runs at a level of theory",
        "skip": "it has an OPTIONAL inside an OPTIONAL, which the playground's query engine "
                "(rdflib.js) leaves unbound, so the file columns come back empty. Run it with ask/arq instead."},
    8: {"label": "Imaginary frequencies",
        "blurb": "A data-quality check - flags any result whose geometry may not be a genuine minimum."},
    9: {"label": "One imaginary frequency?",
        "blurb": "Counts imaginary frequencies per spectrum: a transition state should show exactly one, a minimum none."},
    10: {"label": "Annotated + imaginary",
         "blurb": "Annotated experiments that also show a data-quality issue."},
    11: {"label": "Energetics",
         "blurb": "The actual computed numbers: electronic energy, ZPE, enthalpy, entropy, Gibbs free energy."},
    12: {"label": "File chain", "dataset": "aa",
         "skip": "it uses VALUES, which the playground's query engine (rdflib.js) cannot parse. Run it with ask/arq instead."},
    13: {"label": "Path energies", "dataset": "aa",
         "blurb": "Energies are absolute hartree. For the plot and the barriers, use the R steps in the document."},
    14: {"label": "Method + basis set", "dataset": "caa",
         "blurb": "Which experiments used a given method and basis set."},
    15: {"label": "Barriers",
         "skip": "it is answered by a short R step after question 13's query, not by one query."},
}


def github_anchor(heading):
    """GitHub's heading id: lowercase, drop punctuation, spaces -> hyphens."""
    h = heading.strip().lower().replace("`", "")
    h = re.sub(r"[^\w\s-]", "", h, flags=re.UNICODE)
    return h.replace(" ", "-")


def parse_questions(text):
    parts = re.split(r"(?m)^## (\d+)\. (.*)$", text)
    out = []
    for i in range(1, len(parts), 3):
        n, title, body = int(parts[i]), parts[i + 1].strip(), parts[i + 2]
        body = body.split("\n## ")[0]
        blocks = re.findall(r"```sparql\n(.*?)```", body, re.S)
        status = re.search(r"\*\*Status: ?(\S+)", body)
        query = None
        if blocks:
            # The playground adds its own PREFIX block, so drop ours.
            lines = [l for l in blocks[0].splitlines()
                     if not re.match(r"\s*PREFIX\s", l, re.I)]
            query = "\n".join(lines).strip()
        note = PLAYGROUND_NOTES.get(n, {})
        out.append({
            "n": n,
            "title": title,
            "anchor": github_anchor(f"{n}. {title}"),
            "status": status.group(1) if status else "",
            "query": query,
            "label": note.get("label"),
            "blurb": note.get("blurb"),
            "dataset": note.get("dataset"),
            "skip": note.get("skip") or (None if query else "it has no single query."),
        })
    return out


def render_block(questions):
    payload = json.dumps(questions, indent=2, ensure_ascii=False)
    return (f"{BEGIN}\n"
            f"// Generated by tools/sync_playground_cqs.py from COMPETENCY_QUESTIONS.md.\n"
            f"// Do not edit by hand - edit the document and re-run the script.\n"
            f"const CQ_DOC_URL = {json.dumps(DOC_URL)};\n"
            f"const CQS = {payload};\n"
            f"{END}")


def update_playground(text, questions):
    pattern = re.compile(re.escape(BEGIN) + r".*?" + re.escape(END), re.S)
    if not pattern.search(text):
        sys.exit(f"Markers not found in {PLAYGROUND.name}: add the "
                 f"'{BEGIN}' / '{END}' lines first.")
    return pattern.sub(lambda m: render_block(questions), text)


def update_doc_links(text, questions):
    """Put one 'Try it in the playground' line under each question heading."""
    for q in questions:
        if q["skip"] or not q["query"]:
            # No link for a question the playground cannot run; remove a stale one.
            stale = re.compile(r"(?m)^(## %d\. .*)\n\n?%s.*\n" % (q["n"], re.escape(LINK_MARK)))
            text = stale.sub(lambda m: m.group(1) + "\n", text, count=1)
            continue
        ds = q["dataset"] or "caa"
        link = (f"{LINK_MARK} [Try this in the playground]"
                f"({PLAYGROUND_URL}?dataset={ds}&cq={q['n']})")
        head = re.compile(r"(?m)^(## %d\. .*)\n(?:\n?%s.*\n)?" % (q["n"], re.escape(LINK_MARK)))
        text = head.sub(lambda m: m.group(1) + "\n\n" + link + "\n", text, count=1)
    return text


def glossary_gaps(questions):
    """Prefixed terms used by the questions' queries that GLOSSARY.md never mentions."""
    if not GLOSSARY.exists():
        return []
    gloss = GLOSSARY.read_text()
    used = set()
    for q in questions:
        if q["query"]:
            used.update(re.findall(r"\b((?:gc|ex):[A-Za-z][A-Za-z0-9_]*)", q["query"]))
    # Instance IDs (ex:exp_..., ex:file_..., ex:reactionpath_...) are data, not vocabulary.
    used = {t for t in used if not re.match(r"ex:(exp|file|reactionpath|pathpoint)_", t)}
    return sorted(t for t in used if t not in gloss and t.split(":", 1)[1] not in gloss)


def main():
    check = "--check" in sys.argv
    doc_text = DOC.read_text()
    qs = parse_questions(doc_text)

    new_doc = update_doc_links(doc_text, qs)
    pg_text = PLAYGROUND.read_text()
    new_pg = update_playground(pg_text, qs)

    stale = []
    if new_doc != doc_text:
        stale.append(DOC.name)
    if new_pg != pg_text:
        stale.append(PLAYGROUND.name)

    gaps = glossary_gaps(qs)
    if gaps:
        print("Terms used in competency questions but not found in GLOSSARY.md:")
        for t in gaps:
            print("  ", t)

    runnable = [q for q in qs if q["query"] and not q["skip"]]
    print(f"{len(qs)} questions; {len(runnable)} runnable in the playground.")

    if check:
        if stale:
            print("OUT OF SYNC:", ", ".join(stale), "- run: python3 tools/sync_playground_cqs.py")
            sys.exit(1)
        print("In sync." if not gaps else "In sync (glossary gaps above).")
        sys.exit(1 if gaps else 0)

    if new_doc != doc_text:
        DOC.write_text(new_doc)
        print("Updated", DOC.name)
    if new_pg != pg_text:
        PLAYGROUND.write_text(new_pg)
        print("Updated", PLAYGROUND.name)
    if not stale:
        print("Nothing to change.")


if __name__ == "__main__":
    main()
