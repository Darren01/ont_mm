# SPARQL tutorial: finding your way around a graph

## Chapter 1 - What is in my graph?

You've built a graph. You know roughly what's in it, but "roughly" doesn't get you far when you want to ask a real question. This chapter shows how to ask the graph itself: what kinds of things it contains, what those things *are*, and what properties they have.

Each step introduces one idea, then stops to look at what just happened before moving on. Every example runs against the published `aa` graph (`examples/aa/ont/aa_graph_20260909.ttl`), so your output should match what's printed here. Once it does, point the same queries at your own graph.

**What you need:** a built graph (a `.ttl` file), and either `arq` - Apache Jena's command-line SPARQL tool, which comes in the same download as `shacl` (see Step 5 of the [README](./README.md)) - or `robot`, which you already have. If `arq` won't start, the Jena setup notes in the README (Java version, and `JENAROOT` on Windows) are the first thing to check. Where robot does the same job differently, you'll find a note saying how.

Every result table below is real output from running that query on that graph. Apart from the deliberately sloppy first query in Step 0, every query on our graph has an `ORDER BY`, so your rows should arrive in the same order.

---

## Step 0 - Running a query from the command line

`arq` needs two things: the graph to ask, and a *file* containing your question. Here is the whole routine, with a deliberately lazy first question:

```bash
mkdir -p /tmp/sparql && cd /tmp/sparql               # a scratch folder for today's questions

G=~/ont_mm/examples/aa/ont/aa_graph_20260909.ttl     # adjust to wherever you cloned it

cat > q1.rq <<'EOF'
SELECT * WHERE { ?s ?p ?o } LIMIT 3
EOF

arq --data $G --query q1.rq
```

```text
----------------------------------------------------------------------------------------------------------------------------------------
| s                                        | p                                                 | o                                     |
========================================================================================================================================
| <http://qudt.org/schema/qudt/LengthUnit> | <http://www.w3.org/2000/01/rdf-schema#label>      | "Length Unit"@en                      |
| <http://qudt.org/schema/qudt/LengthUnit> | <http://www.w3.org/2000/01/rdf-schema#subClassOf> | <http://purl.org/gc/AuxiliaryConcept> |
| <http://qudt.org/schema/qudt/LengthUnit> | <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> | <http://www.w3.org/2002/07/owl#Class> |
----------------------------------------------------------------------------------------------------------------------------------------
```

Four commands, so let's take them one at a time.

**`mkdir -p /tmp/sparql && cd /tmp/sparql`** makes a folder for today's experiments and moves into it. `-p` means "no complaint if it already exists", and `&&` means "only do the second part if the first one worked". More on why `/tmp` in a moment.

**`G=...`** stores the path to your graph in a shell variable called `G`, so you type it once and write `$G` afterwards. (No spaces around the `=`. If your path contains spaces, write `"$G"` with the quotes.)

**`cat > q1.rq <<'EOF'` ... `EOF`** writes the lines in between into a file called `q1.rq`. It's the quickest way to make a query file from the terminal, and worth understanding, because it's how you'll ask questions on the fly:

- `cat` normally prints a file. `>` redirects its output into a file instead, so `cat > q1.rq` means "put whatever I give you into `q1.rq`". If `q1.rq` already exists it is **overwritten**.
- `<<'EOF'` is a *here-document*: instead of typing at the keyboard, you supply the text right there, on the lines that follow, up to a line containing nothing but `EOF`.
- `EOF` is just an agreed marker. Any word works (`END`, `QUERY`), as long as the closing line matches exactly and stands alone at the start of the line.
- The quotes around `'EOF'` matter. They tell the shell to copy your text exactly as typed, without treating `$` or backticks as shell commands. SPARQL variables can be written `$x` as well as `?x`, so without the quotes the shell could quietly rewrite your query.
- Nothing runs at this point. You have only made a text file. `cat q1.rq` shows it back to you.

Comment freely while you're at it. `#` starts a comment in bash, exactly as it does in SPARQL (Step 3 says more about that), so a line like `# adjust to wherever you cloned it` inside a here-document costs nothing and saves you working out, next month, what a command was for. You'll see this done throughout the rest of the tutorial.

To change a query, either run the `cat` block again with the new text (it overwrites the old file) or open `q1.rq` in an editor. If you don't have a bash shell (Windows), write the query in Notepad and save it as `q1.rq` - choose "All files" as the type, or it becomes `q1.rq.txt`.

**`arq --data $G --query q1.rq`** runs it: `--data` is the graph to ask, `--query` is the file with the question. Each run re-reads the graph, so it takes a few seconds, mostly Java starting up.

### What that first query told you

Each row is one **triple**: a subject, a predicate and an object. `LengthUnit` *has the label* "Length Unit"; `LengthUnit` *is a subclass of* `AuxiliaryConcept`; `LengthUnit` *is a* `Class`. The whole graph is nothing but rows like these - 7801 of them in this one - and every query you'll write is a way of asking for some of them.

It's also a poor question. We asked for "anything" and got three arbitrary triples. With no `ORDER BY` the engine returns whatever it happens to find first, so your three may differ from these, and none of them says much about what the graph is *about*. That's fine: poor questions are how you find good ones. What's worth doing is making them cheap, and keeping the good ones.

### Two habits: scratch and kept

**Scratch.** Do your exploring in `/tmp/sparql`, as above, and number your files as you go - `q1.rq`, `q2.rq`, `q3.rq` - rather than reusing a name. Nothing is overwritten when you improve a query, so the numbered files are a free log of how your questions got better. `/tmp` is usually cleared when the machine restarts, which is exactly what you want for throw-away work. (On a shared machine, other users can often read what's in `/tmp`, so if you ever save *results* from confidential data, keep them somewhere private.)

**Kept.** When a query has earned its place, promote it to a folder that survives restarts, with a short header saying what it answers and what you learned. Lines starting with `#` are comments, so the header can live inside the query file itself. Make the folder once:

```bash
mkdir -p ~/queries
```

You'll do the promoting for real at the end of Step 3. It looks like this:

```bash
cat - q3.rq > ~/queries/types-in-graph.rq <<'EOF'
# Question: what kinds of things are in the graph, and how many of each?
# Graph:    aa_graph_20260909.ttl
# Learned:  owl:NamedIndividual is a tag on every item - ignore it; units come from QUDT (declare a qudt: prefix)
# Replaces: q1 (SELECT * ... LIMIT 3) - three arbitrary triples, told me nothing
EOF
```

(`cat -` prints what you typed in the here-document - the header - and then `q3.rq`, so the new file is the header followed by the query.) The `Replaces:` line is the one people skip, and the one that matters: it records the poor question you started from, so that in six months the file tells you not only what the query does but why you ended up with it.

### A few extras

- `arq ... --results=CSV` prints comma-separated values instead of the text table (`arq --help` lists the other formats).
- The output is plain text, so ordinary tools work on it: `arq ... | grep 'gc:'` keeps only the lines containing `gc:`, and `| less` lets you scroll.
- **No `arq`?** `robot query --input $G --query q1.rq out.tsv` runs the same engine, and `cat out.tsv` shows the result. The query file is identical for both tools. (Robot prints full addresses rather than shortening them - you'll see why in Step 2.)

### A skill worth noticing

`arq --help` says `--data` accepts a URL as well as a file, so you can point it straight at a published graph without cloning anything:

```bash
arq --data https://raw.githubusercontent.com/Darren01/ont_mm/main/examples/aa/ont/aa_graph_20260909.ttl --query q1.rq
```

(Robot can do it too: `robot query --input-iri <the same URL> --query q1.rq out.tsv`.)

You don't have to build that URL by hand. Browse to the file on GitHub and click the "Raw" button; the address bar then shows something like `.../ont_mm/raw/refs/heads/main/examples/aa/ont/aa_graph_20260909.ttl`, which works exactly the same way - it just redirects to the form above.

Stop and notice what that is. You've asked a question of a graph that lives on someone else's server, using a text file you wrote in a minute and one command. You didn't clone anything, load a database or write a program. Anything published as RDF can be asked this way, and the rest of this tutorial is about asking it well.

**Same skill, different graph.** How hard would it be to ask something you didn't build at all? Wikidata - the large public knowledge graph run by the Wikimedia Foundation - answers SPARQL over the web. Acetone is item `Q49546` in Wikidata, and density is property `P2054`. (How anyone finds those two codes in the first place, for a substance and property they didn't already know, is a fair question, and a real one - Wikidata is a graph like any other, and asking it "what's your code for acetone?" is itself a query. We'll come back to it.) So: what is the density of acetone?

```bash
cat > wd1.rq <<'EOF'
PREFIX wd:  <http://www.wikidata.org/entity/>
PREFIX wdt: <http://www.wikidata.org/prop/direct/>

SELECT ?density
WHERE { wd:Q49546 wdt:P2054 ?density }
EOF

curl -s -G https://query.wikidata.org/sparql \
     -H 'Accept: text/csv' \
     -A 'sparql-tutorial/0.1 (your-email-or-project-url)' \
     --data-urlencode query@wd1.rq
```

```text
density
0.7902
```

That's the same shape as every query so far: a pattern with a fixed subject (acetone), a fixed property (density) and a variable for the answer. Wikidata replies in CSV: a header line, then the value. A few details:

- **`curl` rather than `arq`**, because Wikidata isn't a file to load; it's a live *endpoint* - a service you send questions to. `-G` sends the query in the address, `--data-urlencode query@wd1.rq` reads it from your file and encodes it, and `-H 'Accept: text/csv'` asks for CSV. Jena's `rsparql` does the same job for endpoints (`rsparql --help`). **Robot can't:** `robot query` loads a graph from a file or an IRI, not a live endpoint. (On Windows PowerShell, type `curl.exe`, because plain `curl` is an alias for something else, and put the command on one line.)
- **`-A` sets a User-Agent.** Wikimedia asks clients to identify themselves and can reject requests that don't, so put your own project name and a contact there.
- **You may get more than one row.** Wikidata can hold several densities for a substance, for example at different temperatures. And if you get only the header line, that's the "nothing back" case at the end of this chapter: Wikidata may simply not hold a density for that item.

Typing that `cat` and `curl` pair every time gets tedious quickly. Step 2 wraps it in a one-word shortcut, the same way it wraps `arq` in `ask`.

That's genuinely close to the reference value: Wikipedia lists acetone at 0.7845 g/cm³ at 25 °C, and Wikidata's own figure here is near enough that the small difference is just two sources measuring under slightly different conditions, not an error in the query. If your own number instead looked out by a factor of 1000, that would be the real clue - a missing unit, not a wrong value - and we'll come back to exactly that. The simple `wdt:` form used here gives you the value on its own; Wikidata records the unit on a separate value node, one step away. That is the same shape as `gc:FloatValue` in our own graph, which the graph defines as "containing value and unit". Once you've seen how our graph does it (Chapter 2), you'll be able to follow Wikidata's unit the same way, and we'll finish Chapter 2 by doing exactly that.

---

## Step 1 - What kinds of things exist?

Time for a better question. Instead of asking for triples, ask which *types* the things in the graph have, and how many of each. Save it as `q2.rq` and run it:

```bash
cat > q2.rq <<'EOF'
SELECT ?type (COUNT(?thing) AS ?howMany)
WHERE { ?thing a ?type }
GROUP BY ?type
ORDER BY DESC(?howMany) ?type
LIMIT 5
EOF

arq --data $G --query q2.rq
```

```text
-------------------------------------------------------------
| type                                            | howMany |
=============================================================
| <http://www.w3.org/2002/07/owl#NamedIndividual> | 1102    |
| <http://www.w3.org/2002/07/owl#Class>           | 328     |
| <http://purl.org/gc/ReactionPathPoint>          | 268     |
| <http://purl.org/gc/FloatValue>                 | 192     |
| <http://www.w3.org/2002/07/owl#ObjectProperty>  | 154     |
-------------------------------------------------------------
```

> **With robot:** `robot query --input $G --query q2.rq out.tsv && cat out.tsv` runs the same query and prints tab-separated text:
>
> ```text
> ?type	?howMany
> <http://www.w3.org/2002/07/owl#NamedIndividual>	1102
> <http://www.w3.org/2002/07/owl#Class>	328
> <http://purl.org/gc/ReactionPathPoint>	268
> <http://purl.org/gc/FloatValue>	192
> <http://www.w3.org/2002/07/owl#ObjectProperty>	154
> ```

Each row is a *type* and how many things in the graph have that type. Two things to notice, and we'll take them in turn:

1. The names are long addresses in angle brackets. That's Step 2.
2. We only asked for five rows. To see what the query actually said, and why it produced this, is Step 3.

---

## Step 2 - Prefixes: nicknames for those long addresses

Look at one of those rows: `<http://purl.org/gc/FloatValue>`. An address like this has two parts: a **namespace** (the start it shares with many others, `http://purl.org/gc/`) and a **local name** (`FloatValue`). Because hundreds of terms share the same namespace, SPARQL lets you give it a nickname - a **prefix** - once, at the top of the query:

```sparql
PREFIX gc: <http://purl.org/gc/>
```

From then on `gc:FloatValue` means exactly `<http://purl.org/gc/FloatValue>`. Two things worth knowing straight away.

**Prefixes are optional.** Step 1 worked without any. They exist for readability, and they change how `arq` *prints* results (you'll see that in a moment).

**The nickname is your choice.** Only the address between the `< >` matters. Declare it as `chem:` instead and the same query prints:

```sparql
PREFIX chem: <http://purl.org/gc/>
```

```text
-------------------------------------------------------------
| type                                            | howMany |
=============================================================
| <http://www.w3.org/2002/07/owl#NamedIndividual> | 1102    |
| <http://www.w3.org/2002/07/owl#Class>           | 328     |
| chem:ReactionPathPoint                          | 268     |
| chem:FloatValue                                 | 192     |
| <http://www.w3.org/2002/07/owl#ObjectProperty>  | 154     |
-------------------------------------------------------------
```

(That is Step 1's query with only that `PREFIX` line added above it.) Same things, different nickname. We'll use the project's usual nicknames so queries look the same everywhere.

### How do you know which prefixes to use?

Three places, in the order you'll probably need them:

1. **Read them off the results.** Take any address from Step 1 and cut off the last word: `<http://purl.org/gc/FloatValue>` becomes `PREFIX gc: <http://purl.org/gc/>`. Keep the trailing `/` (or `#`, in addresses like `.../rdf-schema#`).
2. **The top of your graph file.** Here is what this one declares:

   ```text
   @prefix : <http://purl.org/gc/core#> .
   @prefix owl: <http://www.w3.org/2002/07/owl#> .
   @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
   @prefix xml: <http://www.w3.org/XML/1998/namespace> .
   @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
   @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
   ```

   Only a handful of standard ones - not `gc:` and not `ex:`. That's normal: the body of the file writes full addresses, and the nicknames are left to whoever queries it.
3. **The project's usual set**, below. Put the whole block at the top of every query. Declaring a prefix you don't use costs nothing, so start with all of them.

Save the block once, in the `~/queries` folder from Step 0, and give its path a nickname the same way you did for the graph:

```bash
P=~/queries/prefixes.txt
cat > $P <<'EOF'
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX prov: <http://www.w3.org/ns/prov#>
PREFIX schema: <http://schema.org/>
PREFIX gc: <http://purl.org/gc/>
PREFIX ex: <http://example.org/>
EOF
```

Now every new query is that block plus your question, and you can build the file in one go:

```bash
cat $P - > q3.rq <<'EOF'
SELECT ?type (COUNT(?thing) AS ?howMany)
WHERE { ?thing a ?type }
GROUP BY ?type
ORDER BY DESC(?howMany) ?type
EOF
```

(`cat` reads the prefixes file first, then `-`, which means "whatever comes next on the input" - here, your here-document.) That is Step 1's query without the `LIMIT`, so we get the whole list this time. Run it:

```bash
arq --data $G --query q3.rq
```

```text
--------------------------------------------------------------------
| type                                                   | howMany |
====================================================================
| owl:NamedIndividual                                    | 1102    |
| owl:Class                                              | 328     |
| gc:ReactionPathPoint                                   | 268     |
| gc:FloatValue                                          | 192     |
| owl:ObjectProperty                                     | 154     |
| gc:FrequencyPeak                                       | 96      |
| owl:DatatypeProperty                                   | 65      |
| owl:AnnotationProperty                                 | 37      |
| ex:DataFile                                            | 30      |
| ex:InputFile                                           | 30      |
| ex:LogFile                                             | 30      |
| gc:MolecularComputation                                | 27      |
```

That's the first 12 of 37 rows; the full list is here if you want it.

<details>
<summary>All 37 rows</summary>

```text
--------------------------------------------------------------------
| type                                                   | howMany |
====================================================================
| owl:NamedIndividual                                    | 1102    |
| owl:Class                                              | 328     |
| gc:ReactionPathPoint                                   | 268     |
| gc:FloatValue                                          | 192     |
| owl:ObjectProperty                                     | 154     |
| gc:FrequencyPeak                                       | 96      |
| owl:DatatypeProperty                                   | 65      |
| owl:AnnotationProperty                                 | 37      |
| ex:DataFile                                            | 30      |
| ex:InputFile                                           | 30      |
| ex:LogFile                                             | 30      |
| gc:MolecularComputation                                | 27      |
| gc:SystemEnergies                                      | 25      |
| owl:FunctionalProperty                                 | 19      |
| gc:VibrationalAnalysis                                 | 16      |
| gc:VibrationalSpectra                                  | 15      |
| gc:SinglePoint                                         | 10      |
| ex:DistanceConstraint                                  | 6       |
| <http://qudt.org/schema/qudt/DerivedUnit>              | 6       |
| gc:ForceField                                          | 4       |
| gc:ParameterSet                                        | 4       |
| <http://qudt.org/schema/qudt/EnergyAndWorkUnit>        | 4       |
| gc:IRC                                                 | 2       |
| gc:SaddlePoint                                         | 2       |
| <http://qudt.org/schema/qudt/LengthUnit>               | 2       |
| gc:Methodology                                         | 1       |
| gc:ReactionPath                                        | 1       |
| <http://qudt.org/schema/qudt/ChemistryUnit>            | 1       |
| <http://qudt.org/schema/qudt/ElectricDipoleMomentUnit> | 1       |
| <http://qudt.org/schema/qudt/FrequencyUnit>            | 1       |
| <http://qudt.org/schema/qudt/PlaneAngleUnit>           | 1       |
| <http://qudt.org/schema/qudt/TemperatureUnit>          | 1       |
| <http://qudt.org/schema/qudt/Unit>                     | 1       |
| owl:Axiom                                              | 1       |
| owl:Ontology                                           | 1       |
| owl:Restriction                                        | 1       |
| prov:Activity                                          | 1       |
--------------------------------------------------------------------
```

</details>

Compare that with Step 1: `gc:FloatValue` where there was `<http://purl.org/gc/FloatValue>`. `arq` shortens every address it has a prefix for. But scroll down the full list and you'll find rows that are still long: the `<http://qudt.org/schema/qudt/...>` ones, because we never declared a prefix for that namespace. That's your cue to add one, using the rule above:

```sparql
PREFIX qudt: <http://qudt.org/schema/qudt/>
```

With that line added, the same rows print as:

```text
| qudt:DerivedUnit              | 6       |
| qudt:EnergyAndWorkUnit        | 4       |
| qudt:LengthUnit               | 2       |
| qudt:ChemistryUnit            | 1       |
| qudt:ElectricDipoleMomentUnit | 1       |
| qudt:FrequencyUnit            | 1       |
| qudt:PlaneAngleUnit           | 1       |
| qudt:TemperatureUnit          | 1       |
| qudt:Unit                     | 1       |
```

> **With robot:** the query file is identical, but even with the `PREFIX` lines in it, robot prints the full addresses. The prefixes still matter for *writing* the query; they just don't change how robot *displays* the answer:
>
> ```text
> ?type	?howMany
> <http://www.w3.org/2002/07/owl#NamedIndividual>	1102
> <http://www.w3.org/2002/07/owl#Class>	328
> <http://purl.org/gc/ReactionPathPoint>	268
> ```

### A shortcut for quick questions

If you're firing off lots of quick questions, wrap the routine in a function. It puts the prefix block on top of whatever you type, saves it as a scratch file, and runs it:

```bash
ask() {
  mkdir -p /tmp/sparql
  cat ~/queries/prefixes.txt - > /tmp/sparql/ask.rq
  arq --data "$G" --query /tmp/sparql/ask.rq
}
```

(Paste that into your shell once - or into `~/.bashrc` if you want it every time.) Then a question is just:

```bash
ask <<'EOF'
SELECT ?type (COUNT(?thing) AS ?n)
WHERE { ?thing a ?type }
GROUP BY ?type
ORDER BY DESC(?n) ?type
LIMIT 3
EOF
```

```text
-------------------------------
| type                 | n    |
===============================
| owl:NamedIndividual  | 1102 |
| owl:Class            | 328  |
| gc:ReactionPathPoint | 268  |
-------------------------------
```

It reuses one scratch file, `ask.rq`, so it's for the throw-away questions: when one turns out to matter, save it as a numbered file and promote it, as in Step 0. Using robot instead of arq? Swap the last line of the function for `robot query --input "$G" --query /tmp/sparql/ask.rq /tmp/sparql/ask.tsv && cat /tmp/sparql/ask.tsv`.

**A variant, if you work with more than one graph:** `ask` always asks the graph in `$G`. `ask2` takes the graph as its first argument instead, so you can point the same question at a different graph without redefining anything. Run the exact question from a moment ago again, first as a reminder:

```bash
ask <<'EOF'
SELECT ?type (COUNT(?thing) AS ?n)
WHERE { ?thing a ?type }
GROUP BY ?type
ORDER BY DESC(?n) ?type
LIMIT 3
EOF
```

```text
-------------------------------
| type                 | n    |
===============================
| owl:NamedIndividual  | 1102 |
| owl:Class            | 328  |
| gc:ReactionPathPoint | 268  |
-------------------------------
```

then define `ask2` and point it at a different, published graph - `caa` this time:

```bash
ask2() {
  local d="$1"
  mkdir -p /tmp/sparql
  cat ~/queries/prefixes.txt - > /tmp/sparql/ask.rq
  arq --data "$d" --query /tmp/sparql/ask.rq
}
```

```bash
G2=https://raw.githubusercontent.com/Darren01/ont_mm/main/examples/caa/ont/caa_graph_20260905.ttl   # the caa graph, loaded straight from its own URL

ask2 "$G2" <<'EOF'
SELECT ?type (COUNT(?thing) AS ?n)
WHERE { ?thing a ?type }
GROUP BY ?type
ORDER BY DESC(?n) ?type
LIMIT 3
EOF
```

```text
------------------------------
| type                | n    |
==============================
| owl:NamedIndividual | 1759 |
| gc:FloatValue       | 416  |
| owl:Class           | 328  |
------------------------------
```

Same question, same shape, one argument changed - and third place is genuinely different: `gc:ReactionPathPoint` in `aa`, `gc:FloatValue` in `caa`. That's a real, quick way to sanity-check that two datasets built by the same pipeline aren't identical underneath. Worth trying for a while to see whether it earns a permanent place next to `ask`, rather than assuming it will.

**Piping `ask`'s own output somewhere else** works too, though the heredoc makes it look backwards the first time you write it: the pipe goes right after the opening `<<'EOF'`, on the same line as the call itself, not after the closing `EOF`:

```bash
ask <<'EOF' | grep 'gc:'
SELECT ?type (COUNT(?thing) AS ?n) WHERE { ?thing a ?type } GROUP BY ?type ORDER BY DESC(?n) ?type
EOF
```

It only looks odd because the pipe appears before you've even typed the query - but it still only fires once `ask` actually produces output, same as any other command. `| less` works the same way, and so does `ask2`: `ask2 "$G2" <<'EOF' | grep 'gc:'`.

**The same idea for Wikidata.** Step 0 asked Wikidata a question with a `cat` and a long `curl`. That pair is worth wrapping the way `arq` was: `wiki` takes a query on standard input and sends it to Wikidata's endpoint instead of loading a file.

```bash
wiki() {
  mkdir -p /tmp/sparql
  cat - > /tmp/sparql/wiki.rq
  curl -s -G https://query.wikidata.org/sparql -H 'Accept: text/csv' -A 'sparql-tutorial/0.1 (your-contact-here)' --data-urlencode query@/tmp/sparql/wiki.rq
}
```

Step 0's question then becomes:

```bash
wiki <<'EOF'
PREFIX wd:  <http://www.wikidata.org/entity/>
PREFIX wdt: <http://www.wikidata.org/prop/direct/>

SELECT ?density
WHERE { wd:Q49546 wdt:P2054 ?density }
EOF
```

```text
density
0.7902
```

Same number as before. Two differences from `ask` are worth knowing. It doesn't prepend your prefix file, because Wikidata needs its own prefixes (`wd:`, `wdt:` and others), which is why they're written out in the query. And the answer comes back as CSV rather than `arq`'s table, because that's what the `Accept` header asks for. Piping works exactly as it does for `ask`: `| grep` or `| less` goes right after the opening `<<'EOF'`. The name is only a label - call it something shorter if you like.

---

## Step 3 - What just happened?

Now that you have a list, here is the query that produced it, one line at a time:

```sparql
SELECT ?type (COUNT(?thing) AS ?howMany)   # what to show: each type, and how many things have it
WHERE { ?thing a ?type }                   # the pattern: any thing, whose type is any type
GROUP BY ?type                             # one row per type, instead of one per thing
ORDER BY DESC(?howMany) ?type              # biggest count first; ties in alphabetical order
LIMIT 5                                    # stop after 5 rows
```

(Everything after a `#` on a line is a comment: SPARQL ignores it, and you can use it to leave yourself notes. This commented version gives exactly the same result as the one in Step 1.)

- **[`SELECT`](https://www.w3.org/TR/sparql11-query/#select)** names the variables to return - here, `?type` and the new `?howMany`.
- **[`WHERE`](https://www.w3.org/TR/sparql11-query/#GraphPattern)** introduces the pattern to match against the graph. `?type`, `?thing` and `?howMany` are *variables*: names you invent, each starting with `?`, standing for "whatever fits here".
- **`?thing a ?type`** is the heart of it. It has three slots - subject, predicate, object - and `a` in the middle is short for "is a" (the graph stores it as `rdf:type`). Read it aloud: "some thing, which is a some type". The engine finds every place in the graph where that pattern fits, and each fit becomes a row.
- **[`COUNT`](https://www.w3.org/TR/sparql11-query/#aggregates), [`GROUP BY`](https://www.w3.org/TR/sparql11-query/#groupby)** turn "one row per thing" into "one row per type, with a count". Without `GROUP BY` you would get more than a thousand rows.
- **[`ORDER BY`](https://www.w3.org/TR/sparql11-query/#modOrderBy) `DESC(?howMany) ?type`** sorts biggest first, and breaks ties alphabetically so the order is the same every time.
- **[`LIMIT`](https://www.w3.org/TR/sparql11-query/#modResultLimit) `5`** stops after five rows.

Each of those links goes to the official W3C specification - the authoritative source for exactly what a keyword means and how it behaves in every case, including ones this tutorial doesn't cover. [`DISTINCT`](https://www.w3.org/TR/sparql11-query/#modDuplicates), used in Step 5, is there too.

### Reading the full list

The list in Step 2 mixes three kinds of row, and it helps to be able to tell them apart:

- **OWL bookkeeping** - `owl:NamedIndividual`, `owl:Class`, `owl:ObjectProperty` and so on. Every item of data carries an `owl:NamedIndividual` tag on top of its real type (that's the biggest count), and `owl:Class` counts the kinds that the ontology *defines*. The graph is one pot holding both the vocabulary and your data.
- **Your data**, typed with the project's own terms - `gc:ReactionPathPoint`, `gc:FloatValue`, `gc:FrequencyPeak`, `ex:DataFile`, `ex:InputFile`, `ex:LogFile`, and the experiment types such as `gc:SinglePoint` and `gc:VibrationalAnalysis`.
- **Units**, from the QUDT vocabulary - the ones you just gave a prefix to.

### Keep this one

That last query, with its prefix block, is worth keeping. Promote it, as described in Step 0 (`q3.rq` is the file to promote):

```bash
cat - q3.rq > ~/queries/types-in-graph.rq <<'EOF'
# Question: what kinds of things are in the graph, and how many of each?
# Graph:    aa_graph_20260909.ttl
# Learned:  owl:NamedIndividual is a tag on every item - ignore it; units come from QUDT (declare a qudt: prefix)
# Replaces: q1 (SELECT * ... LIMIT 3) - three arbitrary triples, told me nothing
EOF
```

From now on `arq --data $G --query ~/queries/types-in-graph.rq` runs it from anywhere, and the header says what it's for.

Which raises the obvious question about the list itself.

---

## Step 4 - But what *are* these things?

From here on the queries are shown without the prefix block. Put each one in a file with the `cat $P - > q4.rq <<'EOF'` pattern from Step 2, using the next number each time, and run it as before.

`gc:FrequencyPeak` is on the list. What is one, exactly? The definition should be in the graph, since the graph contains the vocabulary as well as your data. To find it, ask the graph for **everything it says about that one thing**:

```sparql
SELECT ?property ?value
WHERE { gc:FrequencyPeak ?property ?value }
ORDER BY ?property ?value
```

```text
--------------------------------------------------------------------------------
| property         | value                                                     |
================================================================================
| rdf:type         | owl:Class                                                 |
| rdfs:comment     | "A class for FrequencyPeak."@en                           |
| rdfs:comment     | "A class representing frequency peak of the spectrum."@en |
| rdfs:isDefinedBy | <http://chemicalsemantics.com/>                           |
| rdfs:label       | "Frequency Peak"@en                                       |
| rdfs:subClassOf  | gc:GainesvilleCoreTerm                                    |
| rdfs:subClassOf  | gc:SpectralFeatures                                       |
--------------------------------------------------------------------------------
```

Look at what came back. This time the *subject* slot holds one fixed thing, and the property and value slots are variables, so you get every fact recorded about it:

- `rdf:type owl:Class` - it's a kind of thing (a class), not an individual item.
- `rdfs:label` - its short human name.
- `rdfs:comment` - **its definition.** (There are two here; some terms have more than one.)
- `rdfs:subClassOf` - the broader kinds it belongs to.
- `rdfs:isDefinedBy` - a pointer to who defines it.

**If the query itself looks odd** - no `a` anywhere, unlike every query so far - that's worth pausing on. `a` is just a stand-in for one specific predicate, `rdf:type`, in the middle slot of a triple pattern. Step 1 fixed that slot to `a` and left the other two (`?thing`, `?type`) as variables, which is why it could only ever answer "what type is this?". Here the middle slot is a variable too (`?property`), so nothing is fixed except the subject: the pattern reads "`gc:FrequencyPeak`, connected by any property, to any value" - every fact about that one thing, whichever predicates happen to hold it. `a` will come back the moment you fix the type again, as it does in Step 5's `?thing a gc:FrequencyPeak ; ?property ?value`.

**Try it on something else.** Go back to Step 2's list (or run `arq --data $G --query ~/queries/types-in-graph.rq` again) and pick a different name from it - `gc:SinglePoint`, say, or `ex:LogFile`. This is exactly the quick, one-off question the `ask()` shortcut from Step 2 was built for, so use it rather than editing a saved file:

```bash
ask <<'EOF'
SELECT ?property ?value WHERE { gc:SinglePoint ?property ?value }
EOF
```

```text
-------------------------------------------------------------------------------------------------------------------------------------
| property         | value                                                                                                          |
=====================================================================================================================================
| rdfs:label       | "Single Point"@en                                                                                              |
| rdfs:isDefinedBy | <http://chemicalsemantics.com/>                                                                                |
| rdfs:comment     | "A class for Single Point calculations - computation of the energy of molecular system for given geometry."@en |
| rdfs:subClassOf  | gc:MolecularComputation                                                                                        |
| rdf:type         | owl:Class                                                                                                      |
-------------------------------------------------------------------------------------------------------------------------------------
```

Only the one fixed term changed; the query's shape didn't. Flipping between the two files like this - the list, then a detail, then back to the list - is the fastest way to get a feel for what's actually in a graph you didn't build yourself.

Other ontologies sometimes keep definitions in other properties, so this "everything about X" question is the way to find out which one a given term uses. It works for any name on any list.

### Not everything is defined

Try it on a term from this project's own `ex:` namespace instead:

```sparql
SELECT ?property ?value
WHERE { ex:InputFile ?property ?value }
ORDER BY ?property ?value
```

```text
------------------------
| property | value     |
========================
| rdf:type | owl:Class |
------------------------
```

Just its type - no label, no definition. The `ex:` terms are this project's own, and the graph doesn't document them. The [glossary](./GLOSSARY.md) is the first place to look for those; if a term isn't there, how it's used in the graph (Chapter 2) is the next. Either way, a missing definition is itself information about where a term comes from.

### All the labels at once

You can ask about every type in use, rather than one at a time:

```sparql
SELECT DISTINCT ?type ?label
WHERE { ?thing a ?type .
        ?type rdfs:label ?label . }
ORDER BY ?type
```

That returns 22 rows - fewer than the 37 types in Step 2, because the ones with no label (the OWL bookkeeping and the `ex:` terms) drop out. The first few:

```text
---------------------------------------------------------------------------------------------
| type                                                   | label                            |
=============================================================================================
| gc:FloatValue                                          | "Float Value"@en                 |
| gc:ForceField                                          | "Force Field"@en                 |
| gc:FrequencyPeak                                       | "Frequency Peak"@en              |
| gc:IRC                                                 | "IRC"@en                         |
| gc:Methodology                                         | "Methodology"@en                 |
| gc:MolecularComputation                                | "Molecular Computation"@en       |
```

**Your turn:** definitions are `rdfs:comment`, not `rdfs:label`. Change those two words in the query and run it. You should get **17 rows**, and that is fewer again than the labels: some types have a name but no definition.

---

## Step 5 - What properties do they have?

Types tell you what kinds of things exist. **Properties** are what connect and describe them. The same trick as Step 1 finds every property in use, this time with the variable in the middle slot. Save it as `props.rq`:

```sparql
SELECT DISTINCT ?property
WHERE { ?s ?property ?o }
ORDER BY ?property
```

`DISTINCT` means "each property once, however often it's used". That's 82 properties in this graph; here are the first rows.

```text
-------------------------------------------------
| property                                      |
=================================================
| <http://creativecommons.org/ns#license>       |
| ex:fileURL                                    |
| ex:hasConstraint                              |
| ex:hasHssend                                  |
| ex:hasRuntyp                                  |
| ex:hasSolvationModel                          |
| ex:hasSolvent                                 |
| ex:involvesAtom1                              |
| ex:involvesAtom2                              |
| ex:targetValue                                |
| <http://purl.obolibrary.org/obo/IAO_0000115>  |
| <http://purl.org/dc/elements/1.1/created>     |
```

A long list, and much of it is OWL and PROV machinery from the ontologies. Because the output is plain text, you can narrow it with ordinary shell tools rather than more SPARQL. To see only this project's `gc:` properties:

```bash
arq --data $G --query props.rq | grep 'gc:'
```

```text
| gc:constraintMode                             |
| gc:hasBasisSet                                |
| gc:hasElectronicEnergy                        |
| gc:hasEnthalpy                                |
| gc:hasEntropy                                 |
| gc:hasFloatValue                              |
| gc:hasFrequency                               |
| gc:hasFrequencyPeak                           |
| gc:hasGibbsFreeEnergy                         |
| gc:hasIndex                                   |
| gc:hasIntensity                               |
| gc:hasMethod                                  |
| gc:hasPathEnergy                              |
| gc:hasReactionPathPoint                       |
| gc:hasResult                                  |
| gc:hasUnit                                    |
| gc:hasZeroPointEnergy                         |
| gc:isAbstract                                 |
```

(A few properties print in full, such as the Creative Commons `license` one - same reason as QUDT in Step 2, no prefix declared.)

> **With robot:** its output has full addresses, so match on the address rather than the nickname: `robot query --input $G --query props.rq props.tsv && grep 'purl.org/gc/' props.tsv` prints the same properties:
>
> ```text
> <http://purl.org/gc/constraintMode>
> <http://purl.org/gc/hasBasisSet>
> <http://purl.org/gc/hasElectronicEnergy>
> <http://purl.org/gc/hasEnthalpy>
> <http://purl.org/gc/hasEntropy>
> <http://purl.org/gc/hasFloatValue>
> <http://purl.org/gc/hasFrequency>
> <http://purl.org/gc/hasFrequencyPeak>
> <http://purl.org/gc/hasGibbsFreeEnergy>
> <http://purl.org/gc/hasIndex>
> <http://purl.org/gc/hasIntensity>
> <http://purl.org/gc/hasMethod>
> <http://purl.org/gc/hasPathEnergy>
> <http://purl.org/gc/hasReactionPathPoint>
> <http://purl.org/gc/hasResult>
> <http://purl.org/gc/hasUnit>
> <http://purl.org/gc/hasZeroPointEnergy>
> <http://purl.org/gc/isAbstract>
> ```

### What properties does *one kind* of thing have?

The list above is every property in the graph. What you usually want is the properties of a particular kind of thing, say a frequency peak:

```sparql
SELECT DISTINCT ?property
WHERE { ?thing a gc:FrequencyPeak ;
               ?property ?value . }
ORDER BY ?property
```

```text
-------------------
| property        |
===================
| gc:hasFrequency |
| gc:hasIntensity |
| rdf:type        |
| rdfs:label      |
-------------------
```

That is the real answer to "what properties do they have": a `gc:FrequencyPeak` has a frequency and an intensity, plus its type and a label. Note the `;` in the query: it means "same subject again", so `?thing a gc:FrequencyPeak ; ?property ?value` says "some thing which is a frequency peak, and which has some property with some value". It saves repeating `?thing`.

### And what do the properties *mean*?

Same question as Step 4, asked about a property this time:

```sparql
SELECT ?property ?value
WHERE { gc:hasFrequency ?property ?value }
ORDER BY ?property ?value
```

```text
-------------------------------------------------------------------------------------------------------------
| property           | value                                                                                |
=============================================================================================================
| rdf:type           | owl:ObjectProperty                                                                   |
| rdfs:comment       | "A property that describes the value of a frequency at the peak of the spectrum."@en |
| rdfs:domain        | gc:FrequencyPeak                                                                     |
| rdfs:isDefinedBy   | <http://chemicalsemantics.com/>                                                      |
| rdfs:label         | "has frequency"@en                                                                   |
| rdfs:range         | gc:FloatValue                                                                        |
| rdfs:subPropertyOf | gc:hasResult                                                                         |
-------------------------------------------------------------------------------------------------------------
```

The label and comment define it, as before. Two new lines are worth reading closely: `rdfs:domain` is the kind of thing the property starts from (`gc:FrequencyPeak`), and `rdfs:range` is the kind of thing it points to. It points to `gc:FloatValue`. So a frequency here is **not a number**: it's a `FloatValue` thing, which in turn holds the number. That's where Chapter 2 starts - and where the unit on acetone's density, back in Step 0, will turn up again.

---

## If you get nothing back

An empty table is a *valid answer* ("nothing matches"), not an error, which makes it easy to misread. The usual causes:

**A namespace that's slightly wrong.** Leave the trailing `/` off the prefix and every name built from it points at an address that doesn't exist:

```sparql
PREFIX gc: <http://purl.org/gc>
SELECT ?property ?value
WHERE { gc:FrequencyPeak ?property ?value }
```

```text
--------------------
| property | value |
====================
--------------------
```

**A name with the wrong capitalisation.** Names are case-sensitive. `gc:frequencypeak` is not `gc:FrequencyPeak`:

```text
--------------------
| property | value |
====================
--------------------
```

Both return an empty table with no complaint. When you get one, check the names against a list you know is right (Step 2's list is a good one) before suspecting anything else.

**A prefix you forgot to declare.** This one does complain, and the message names the culprit - Jena reports something like `Unresolved prefixed name: gc:FrequencyPeak`, with the line and column.

## If you get something back, but not what you expected

The harder case: no error, a plausible-looking table, and it's still the wrong answer - because the query asked a different question from the one you meant. The most common way this happens is swapping subject and object in a triple pattern. Step 1's own query:

```sparql
SELECT ?type (COUNT(?thing) AS ?howMany) WHERE { ?thing a ?type } GROUP BY ?type ORDER BY DESC(?howMany) ?type LIMIT 3
```

```text
----------------------------------
| type                 | howMany |
==================================
| owl:NamedIndividual  | 1102    |
| owl:Class            | 328     |
| gc:ReactionPathPoint | 268     |
----------------------------------
```

Swap the two variables in the pattern - `?type a ?thing` instead of `?thing a ?type` - and nothing about the query looks obviously broken:

```sparql
SELECT ?type (COUNT(?thing) AS ?howMany) WHERE { ?type a ?thing } GROUP BY ?type ORDER BY DESC(?howMany) ?type LIMIT 3
```

```text
------------------------------------
| type                   | howMany |
====================================
| ex:exp_aa001-ts-pcseg2 | 3       |
| ex:exp_aa001a          | 3       |
| ex:exp_aa001b          | 3       |
------------------------------------
```

Real output, no error - and a completely different question. The first asks "for each type, how many things have it". The second asks "for each thing that has at least one type, how many types does it have" - and these three experiments each genuinely have three (`owl:NamedIndividual` plus two more specific ones). `?a` and `?b` in a pattern are never interchangeable just because they're both variables: which one is the subject and which is the object is the entire meaning of the line. When a result looks plausible but doesn't match your own sense of the data, re-reading the pattern itself - which variable sits where - is worth doing before anything else.

---

## What you've learned

| To find out... | Ask... |
|---|---|
| what kinds of things exist | `SELECT ?type (COUNT(?thing) AS ?howMany) WHERE { ?thing a ?type } GROUP BY ?type` |
| everything the graph says about one thing | `SELECT ?property ?value WHERE { gc:FrequencyPeak ?property ?value }` |
| every property in use | `SELECT DISTINCT ?property WHERE { ?s ?property ?o }` |
| the properties of one kind of thing | `SELECT DISTINCT ?property WHERE { ?thing a gc:FrequencyPeak ; ?property ?value }` |

Four habits carry over to everything else: explore in scratch and keep only what earns its place, put the prefix block at the top, look at what came back before writing the next query, and when a name is unfamiliar, ask the graph what it is.

## Chapter 2 - Following links, and finding what's missing

Chapter 1 ended on a discovery: a frequency isn't a number, it's a `FloatValue` thing, one hop away. This chapter follows that hop, and several more like it - from a single value, up to an experiment's own results, up again to the files behind them, and finally out to a value in a completely different graph on the other side of the web.

Same tools as before: `arq` (or `robot query`), the `~/queries/prefixes.txt` file from Chapter 1, and the `ask`/`ask2` shortcuts if you kept them. Every query below ran against the same published `aa` graph, and every result shown is real.

---

## Step 1 - Follow one link

*How was `ex:peak_aa001a_1` chosen in the first place? The same way you'd choose any starting point when you don't already have a specific name in mind: ask the graph for any example of what you want, and use whatever comes back. `SELECT ?peak WHERE { ?peak a gc:FrequencyPeak } LIMIT 1` - by type - or `SELECT ?a ?fv WHERE { ?a gc:hasFrequency ?fv }` - by property - both work equally well; either approach would have handed you a real, working name to start from.*

Take one real peak, `ex:peak_aa001a_1`, and its frequency property:

```sparql
SELECT ?fv WHERE { ex:peak_aa001a_1 gc:hasFrequency ?fv }
```

```text
-----------------------
| fv                  |
=======================
| ex:freqval_aa001a_1 |
-----------------------
```

That's not the frequency itself - it's the address of a `FloatValue` node. Ask *that* node what it holds:

```sparql
SELECT ?p ?v WHERE { ex:freqval_aa001a_1 ?p ?v }
```

```text
------------------------------------------------
| p                | v                         |
================================================
| rdfs:label       | "Frequency mode 1 aa001a" |
| gc:hasFloatValue | "-1314.49"^^xsd:float     |
| gc:hasUnit       | gc:cm-1                   |
| rdf:type         | gc:FloatValue             |
| rdf:type         | owl:NamedIndividual       |
------------------------------------------------
```

There it is: `-1314.49`, in `gc:cm-1`. Two queries, one plain, unglamorous idea: the object of one triple can be the subject of the next, because in RDF an object is never just a value sitting in a cell - it's a real, addressable thing, exactly like the subject was.

**This is worth pausing on**, because it isn't a quirk of this particular ontology. A traditional, flat database would store `-1314.49` as a number in a column, full stop - asking for its unit would mean going and finding the column's own documentation, somewhere else entirely, hoping it hadn't changed since. Here the unit is *in the graph*, one hop from the number itself, because that's what "linked" means in linked data: a value can be a real thing in its own right, with its own further facts attached, addressable the same way anything else is. That's also the entire reason chaining works at all. You're not learning a clever trick - you're just following the data where it already points.

---

## Step 2 - Chain it into one query

Same question, one query. `;` means "same subject again", so a chain of properties can share one variable without repeating it:

```sparql
SELECT ?freq ?unit WHERE {
  ex:peak_aa001a_1 gc:hasFrequency ?fv .
  ?fv gc:hasFloatValue ?freq ;
      gc:hasUnit ?unit .
}
```

```text
-----------------------------------
| freq                  | unit    |
===================================
| "-1314.49"^^xsd:float | gc:cm-1 |
-----------------------------------
```

Read the middle line as "some `?fv`, reached via `gc:hasFrequency`, which itself has a `gc:hasFloatValue` and a `gc:hasUnit`". Nothing new happened here that didn't already happen in Step 1 - the two queries are the same journey, just written as one hop instead of two.

---

## Step 3 - From an experiment down to its results

Peaks don't float free in the graph; an experiment has results, and results have peaks. Follow the whole thing from the top:

```sparql
SELECT ?p ?v WHERE { ex:exp_aa001a ?p ?v } ORDER BY ?p
```

Among the answers (Chapter 1's "everything about one thing" question, still the right first move on anything unfamiliar) is `gc:hasResult ex:spectrum_aa001a`. Ask what *that* holds:

```sparql
SELECT ?p ?v WHERE { ex:spectrum_aa001a ?p ?v } ORDER BY ?p
```

```text
-------------------------------------------------------
| p                   | v                             |
=======================================================
| gc:hasFrequencyPeak | ex:peak_aa001a_1              |
| gc:hasFrequencyPeak | ex:peak_aa001a_2              |
| gc:hasFrequencyPeak | ex:peak_aa001a_3              |
| gc:hasFrequencyPeak | ex:peak_aa001a_4              |
| gc:hasFrequencyPeak | ex:peak_aa001a_5              |
| gc:hasFrequencyPeak | ex:peak_aa001a_6              |
| gc:hasFrequencyPeak | ex:peak_aa001a_7              |
| rdf:type            | gc:VibrationalSpectra         |
| rdf:type            | owl:NamedIndividual           |
| rdfs:label          | "Vibrational spectrum aa001a" |
-------------------------------------------------------
```

Seven peaks. Chain the whole route - experiment, to spectrum, to peak, to frequency value - in one query, and ask a real question of it: which mode has the lowest frequency?

```sparql
SELECT ?peak ?freq ?unit WHERE {
  ex:exp_aa001a gc:hasResult ?spec .
  ?spec gc:hasFrequencyPeak ?peak .
  ?peak gc:hasFrequency ?fv .
  ?fv gc:hasFloatValue ?freq ;
      gc:hasUnit ?unit .
}
ORDER BY ?freq
LIMIT 5
```

```text
------------------------------------------------------
| peak             | freq                  | unit    |
======================================================
| ex:peak_aa001a_1 | "-1314.49"^^xsd:float | gc:cm-1 |
| ex:peak_aa001a_6 | "0.12"^^xsd:float     | gc:cm-1 |
| ex:peak_aa001a_5 | "0.3"^^xsd:float      | gc:cm-1 |
| ex:peak_aa001a_7 | "1.29"^^xsd:float     | gc:cm-1 |
| ex:peak_aa001a_4 | "42.77"^^xsd:float    | gc:cm-1 |
------------------------------------------------------
```

Same idea as Step 2, just more hops - nothing new to learn, only more to follow. And the answer is a real one: this experiment has a genuine imaginary frequency, `-1314.49 cm-1`, the negative sign meaning exactly what it means in the vibrational-analysis output this graph was built from.

**With robot:** the same query works unchanged; only the printed addresses are full-length rather than shortened:

```text
?peak	?freq	?unit
<http://example.org/peak_aa001a_1>	"-1314.49"^^<http://www.w3.org/2001/XMLSchema#float>	<http://purl.org/gc/cm-1>
<http://example.org/peak_aa001a_6>	"0.12"^^<http://www.w3.org/2001/XMLSchema#float>	<http://purl.org/gc/cm-1>
<http://example.org/peak_aa001a_5>	"0.3"^^<http://www.w3.org/2001/XMLSchema#float>	<http://purl.org/gc/cm-1>
<http://example.org/peak_aa001a_7>	"1.29"^^<http://www.w3.org/2001/XMLSchema#float>	<http://purl.org/gc/cm-1>
<http://example.org/peak_aa001a_4>	"42.77"^^<http://www.w3.org/2001/XMLSchema#float>	<http://purl.org/gc/cm-1>
```

---

## Step 4 - From an experiment up to its files

Results trace down into the chemistry. Provenance traces up into the files that produced it. Two properties do this project's own version of that job, and Chapter 1 already met them by name: `prov:used` for what an experiment started from, `prov:generated` for what it produced.

```sparql
SELECT ?input WHERE { ex:exp_aa001a prov:used ?input }
```

```text
----------------------
| input              |
======================
| ex:file_aa001a_inp |
----------------------
```

```sparql
SELECT ?output WHERE { ex:exp_aa001a prov:generated ?output }
ORDER BY ?output
```

```text
----------------------
| output             |
======================
| ex:file_aa001a_dat |
| ex:file_aa001a_log |
----------------------
```

One input, two outputs - a `.dat` and a `.log`, both real files on someone's disk, both now addressable, nameable things in the graph, exactly like the peaks and results above.

---

## Step 5 - What's missing

The [checksum work](./GLOSSARY.md) recorded a `schema:sha256` on files like these, so you can confirm a file's real content hasn't silently changed. Ask for it the way Chapter 1 first asked for an optional label:

```sparql
SELECT ?output ?hash WHERE {
  ex:exp_aa001a prov:generated ?output .
  OPTIONAL { ?output schema:sha256 ?hash . }
}
ORDER BY ?output
```

```text
-------------------------------------------------------------------------------------------
| output             | hash                                                               |
===========================================================================================
| ex:file_aa001a_dat |                                                                    |
| ex:file_aa001a_log | "ca9cf795626c1c861c4bb82b1c19c9cfa247ad01202666a558e7c475669ff930" |
-------------------------------------------------------------------------------------------
```

The `.log` file has one. The `.dat` file doesn't - `OPTIONAL` means the row survives anyway, with that one column simply empty, rather than the whole file vanishing from the answer. That's a real, honest gap in this published graph, not a manufactured one: every `.dat` file here is missing a checksum, project-wide, for a genuine, traceable reason ([the README says why](./README.md)).

Which raises the natural next question: not "does this one file have a checksum", but "which files don't". `OPTIONAL` plus `FILTER(!BOUND(...))` answers exactly that - get the value if there is one, then keep only the rows where there wasn't:

```sparql
SELECT ?file WHERE {
  ?file a ex:DataFile .
  OPTIONAL { ?file schema:sha256 ?h . }
  FILTER(!BOUND(?h))
}
```

```text
----------------------------------------------
| file                                       |
==============================================
| ex:file_aa002-aldehyde-pcseg2_dat          |
| ex:file_aa001f_dat                         |
| ex:file_aa002-hydrate-bare-smd_dat         |
| ex:file_aa001d-smd-pcseg2_dat              |
| ex:file_aa001e_dat                         |
| ex:file_aa001b_dat                         |
| ex:file_aa001d_dat                         |
| ex:file_aa001g-smd-pcseg2_dat              |
| ex:file_aa001c_dat                         |
| ex:file_aa001a_dat                         |
| ex:file_aa001g-smd_dat                     |
| ex:file_aa002-aldehyde-bare_dat            |
| ex:file_aa001h_dat                         |
| ex:file_aa002-water-bare_dat               |
| ex:file_aa001h-smd_dat                     |
| ex:file_aa001g_dat                         |
| ex:file_aa002-aldehyde-bare-smd-check_dat  |
| ex:file_aa001h-pcseg2_dat                  |
| ex:file_aa001-ts-pcseg2_dat                |
| ex:file_aa001g-pcseg2_dat                  |
| ex:file_aa002-aldehyde-bare-smd_dat        |
| ex:file_aa002-aldehyde-bare-smd-hcore_dat  |
| ex:file_aa002-aldehyde-bare-smd-energy_dat |
| ex:file_aa002-hydrate-bare_dat             |
| ex:file_aa001h-smd-pcseg2_dat              |
| ex:file_aa002-water-bare-smd_dat           |
| ex:file_aa002-hydrate-pcseg2_dat           |
| ex:file_aa001d-smd_dat                     |
| ex:file_aa002-water-pcseg2_dat             |
| ex:file_aa001d-smd-hess_dat                |
----------------------------------------------
```

> **With robot:** the same query, same result - 30 rows, one per `.dat` file, full addresses as always:
>
> ```text
> ?file
> <http://example.org/file_aa002-aldehyde-pcseg2_dat>
> <http://example.org/file_aa001f_dat>
> <http://example.org/file_aa002-hydrate-bare-smd_dat>
> <http://example.org/file_aa001d-smd-pcseg2_dat>
> <http://example.org/file_aa001e_dat>
> <http://example.org/file_aa001b_dat>
> <http://example.org/file_aa001d_dat>
> <http://example.org/file_aa001g-smd-pcseg2_dat>
> <http://example.org/file_aa001c_dat>
> <http://example.org/file_aa001a_dat>
> <http://example.org/file_aa001g-smd_dat>
> <http://example.org/file_aa002-aldehyde-bare_dat>
> <http://example.org/file_aa001h_dat>
> <http://example.org/file_aa002-water-bare_dat>
> <http://example.org/file_aa001h-smd_dat>
> <http://example.org/file_aa001g_dat>
> <http://example.org/file_aa002-aldehyde-bare-smd-check_dat>
> <http://example.org/file_aa001h-pcseg2_dat>
> <http://example.org/file_aa001-ts-pcseg2_dat>
> <http://example.org/file_aa001g-pcseg2_dat>
> <http://example.org/file_aa002-aldehyde-bare-smd_dat>
> <http://example.org/file_aa002-aldehyde-bare-smd-hcore_dat>
> <http://example.org/file_aa002-aldehyde-bare-smd-energy_dat>
> <http://example.org/file_aa002-hydrate-bare_dat>
> <http://example.org/file_aa001h-smd-pcseg2_dat>
> <http://example.org/file_aa002-water-bare-smd_dat>
> <http://example.org/file_aa002-hydrate-pcseg2_dat>
> <http://example.org/file_aa001d-smd_dat>
> <http://example.org/file_aa002-water-pcseg2_dat>
> <http://example.org/file_aa001d-smd-hess_dat>
> ```

Thirty files, every `.dat` in this dataset. **Worth reading carefully, though: an empty result here is not automatically a problem.** This graph deliberately doesn't hold everything a `.log` file contains - `filter_vibrational_modes()`, used to build it, keeps only the imaginary frequencies and the six translation/rotation modes, not the full vibrational spectrum. That's not lost data; it's a map drawn at a scale that stays usable, with the full, unabridged territory still one hop away in the `.log` file itself, via `prov:generated`. Finding something absent from the graph tells you the graph doesn't index it - it doesn't yet tell you whether that's a genuine gap or a deliberate choice. The only way to tell them apart is the same principle either way: check whether the source file it points to still has it.

---

## Step 6 - The Wikidata payoff

Chapter 1 asked Wikidata for acetone's density with the simple, direct form:

```sparql
SELECT ?density WHERE { wd:Q49546 wdt:P2054 ?density }
```

That's genuinely the `wdt:` ("truthy") shortcut - the single best-ranked value, with nothing else attached. The real statement behind it holds more, the same way `gc:hasFrequency` led somewhere rather than being a number itself. Wikidata's own version of that indirection uses different names - `p:` for the full statement, `psv:` for its value node, `wikibase:quantityAmount` and `wikibase:quantityUnit` for what that node holds - but it's the identical shape:

```sparql
PREFIX wd:  <http://www.wikidata.org/entity/>
PREFIX p:   <http://www.wikidata.org/prop/>
PREFIX psv: <http://www.wikidata.org/prop/statement/value/>
PREFIX wikibase: <http://wikiba.se/ontology#>

SELECT ?amount ?unit WHERE {
  wd:Q49546 p:P2054 ?statement .
  ?statement psv:P2054 ?value .
  ?value wikibase:quantityAmount ?amount ;
         wikibase:quantityUnit ?unit .
}
```

```bash
cat > /tmp/wd2.rq <<'EOF'
PREFIX wd:  <http://www.wikidata.org/entity/>
PREFIX p:   <http://www.wikidata.org/prop/>
PREFIX psv: <http://www.wikidata.org/prop/statement/value/>
PREFIX wikibase: <http://wikiba.se/ontology#>

SELECT ?amount ?unit
WHERE {
  wd:Q49546 p:P2054 ?statement .
  ?statement psv:P2054 ?value .
  ?value wikibase:quantityAmount ?amount ;
         wikibase:quantityUnit ?unit .
}
EOF

curl -s -G https://query.wikidata.org/sparql -H 'Accept: text/csv' -A 'sparql-tutorial/0.1 (your-contact-here)' --data-urlencode query@/tmp/wd2.rq
```

```text
amount,unit
0.7902,http://www.wikidata.org/entity/Q13147228
```

`?unit` comes back as another Wikidata item address, `wd:Q13147228`, not a readable word - which is Step 4 of Chapter 1 again: ask that address what it is.

```sparql
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT ?label WHERE { wd:Q13147228 rdfs:label ?label FILTER(LANG(?label) = "en") }
```

That returns "gram per cubic centimetre" - confirmed directly, the genuine SI unit for density, not a label to take on trust. **Worth being careful here, and not just skimming past it:** Wikidata's own page for that item describes it as the "SI unit of density", which is easy to misread on a first pass as the page being *about* density itself, rather than being the unit density happens to be measured in. The address is the only thing that's actually reliable; the description next to it is written for people, and people-language is exactly the kind of thing worth double-checking against the query rather than assuming.

The same one habit, the same shape of query, answering the same kind of question, on a graph you didn't build and have never seen the inside of. That's the whole chapter in one sentence: once you can follow a link, it doesn't matter whose graph it is.

---

## What's still open

Not everything a `.log` file contains belongs in the graph - Step 5 already touched on why. A full geometry trajectory, per-cycle SCF convergence, timing data: all real, all currently living only in the file, none of it indexed here. Whether more of it should be is a genuinely open, unresolved question, and probably doesn't have one right answer - it depends what a given user actually needs, which this project can't guess on their behalf. What `ont_mm` can promise is the map: a graph that tells you which file to open. What you do once you've opened it is a different tool's job.

## Chapter 3 - Finding things when you don't know their name

Every query so far started from a name already in hand - `ex:peak_aa001a_1`, `gc:FrequencyPeak`, `ex:exp_aa001a`. Real questions rarely start that way. This chapter is about the other direction: you know roughly what you're looking for, not its exact name, and the graph has to help you find it.

Same tools, same graph, same real output throughout.

---

## Step 1 - Search by label

You remember an experiment involved an aldehyde, but not its exact name. `CONTAINS` searches inside a string rather than matching it exactly:

```sparql
SELECT ?thing ?label WHERE {
  ?thing rdfs:label ?label .
  FILTER(CONTAINS(?label, "aldehyde"))
}
```

That's a wide net - 46 rows in this graph, and worth seeing why:

```text
-----------------------------------------------------------------------------------------------------
| thing                                      | label                                                |
=====================================================================================================
| ex:peak_aa002-aldehyde-bare_4              | "Mode 4 aa002-aldehyde-bare"                         |
| ex:intval_aa002-aldehyde-bare_6            | "IR intensity mode 6 aa002-aldehyde-bare"            |
| ex:exp_aa002-aldehyde-bare-smd             | "Vibrational analysis aa002-aldehyde-bare-smd"       |
| ex:file_aa002-aldehyde-bare-smd-energy_dat | "Output data aa002-aldehyde-bare-smd-energy"         |
| ex:freqval_aa002-aldehyde-bare_4           | "Frequency mode 4 aa002-aldehyde-bare"               |
| ex:file_aa002-aldehyde-bare-smd-check_dat  | "Output data aa002-aldehyde-bare-smd-check"          |
| ex:exp_aa002-aldehyde-bare-smd-energy      | "Single point aa002-aldehyde-bare-smd-energy"        |
| ex:file_aa002-aldehyde-bare-smd-energy_inp | "Input file aa002-aldehyde-bare-smd-energy"          |
| ex:file_aa002-aldehyde-bare_dat            | "Output data aa002-aldehyde-bare"                    |
... (38 more rows)
-----------------------------------------------------------------------------------------------------
```

Peaks, files, energies, spectra, experiments - everything with a matching label, not just the experiments you probably had in mind. A label search finds every *kind* of thing at once, because `rdfs:label` doesn't care what it's attached to. Narrow it to experiments specifically - `prov:used` is a reliable test for that, since only something that actually ran has an input file (Chapter 4 shows why this beats the more obvious class):

```sparql
SELECT ?exp ?label WHERE {
  ?exp prov:used ?f ;
       rdfs:label ?label .
  FILTER(CONTAINS(?label, "aldehyde"))
}
```

```text
------------------------------------------------------------------------------------------------
| exp                                   | label                                                |
================================================================================================
| ex:exp_aa002-aldehyde-pcseg2          | "Single point aa002-aldehyde-pcseg2"                 |
| ex:exp_aa002-aldehyde-bare-smd        | "Vibrational analysis aa002-aldehyde-bare-smd"       |
| ex:exp_aa002-aldehyde-bare-smd-hcore  | "Vibrational analysis aa002-aldehyde-bare-smd-hcore" |
| ex:exp_aa002-aldehyde-bare-smd-check  | "Vibrational analysis aa002-aldehyde-bare-smd-check" |
| ex:exp_aa002-aldehyde-bare-smd-energy | "Single point aa002-aldehyde-bare-smd-energy"        |
| ex:exp_aa002-aldehyde-bare            | "Vibrational analysis aa002-aldehyde-bare"           |
------------------------------------------------------------------------------------------------
```

Six experiments, not forty-five. The wide search isn't a mistake to avoid - it's often the right first move precisely because it doesn't assume you already know what kind of thing you're after. Narrowing comes after, once you can see what's actually there.

---

## Step 2 - Case sensitivity

`CONTAINS` is case-sensitive. Search for the wrong case and nothing warns you:

```sparql
SELECT ?exp WHERE {
  ?exp prov:used ?f ; rdfs:label ?label .
  FILTER(CONTAINS(?label, "ALDEHYDE"))
}
```

```text
-------
| exp |
=======
-------
```

An empty table again - Chapter 1's own lesson, showing up in a new place. `LCASE` fixes it by lowering both sides before comparing:

```sparql
SELECT (COUNT(?exp) AS ?n) WHERE {
  ?exp prov:used ?f ; rdfs:label ?label .
  FILTER(CONTAINS(LCASE(?label), "aldehyde"))
}
```

```text
-----
| n |
=====
| 6 |
-----
```

Worth making a habit of `LCASE` on both sides of any label search, rather than trusting you'll always remember how something was capitalised when it was written.

---

## Step 3 - See your options before you filter

Before writing `FILTER(?method = "...")`, it's worth asking what values are even possible - this graph's own `aa` dataset only ever used one method, which would make a filter example here pointless. `caa` didn't:

```sparql
SELECT DISTINCT ?method WHERE { ?exp gc:hasMethod ?method }
```

```text
-------------
| method    |
=============
| "wB97X-D" |
| "CCSD(T)" |
| "UHF"     |
| "RHF"     |
-------------
```

Four real methods, including `CCSD(T)` - worth a note of its own, since its parentheses need no special treatment inside a SPARQL string (`FILTER(?method = "CCSD(T)")` works exactly as written; the parentheses only mean something to the *query syntax* outside the quotes). `DISTINCT` here does the same job it did back in Chapter 1: it turns "one row per experiment" into "one row per value actually used" - the options worth filtering by, before you commit to one.

---

## Step 4 - Search the human-written notes, and change them with SPARQL

Not everything worth finding is a structured property. `skos:editorialNote` holds real, free-text notes - the kind you'd write while troubleshooting a run. Search them the same way as any other label:

```sparql
SELECT ?exp ?note WHERE {
  ?exp skos:editorialNote ?note .
  FILTER(CONTAINS(?note, "PURIFY"))
}
```

```text
------------------------------------------------------------------------------------------
| exp           | note                                                                   |
==========================================================================================
| ex:exp_aa001c | "used PURIFY=.t. in $FORCE which gave rotations/translations as 0cm-1" |
| ex:exp_aa001a | "prepared without PURIFY=.t. and hence lost accuracy."                 |
------------------------------------------------------------------------------------------
```

Two experiments - but a third, `ex:exp_aa001b`, hit the same real issue and typed `PURFIFY` in its own note. Text search only finds what's actually spelled the way you searched for; that typo is invisible to this query and would need its own line (`|| CONTAINS(?note, "PURFIFY")`) to catch. Structured properties don't have this problem - `gc:hasMethod` can't be misspelled once it's written - which is exactly the trade-off between free text and structured data: notes are cheap to write and can say anything, but they can't be searched with the confidence a real property gives you.

### Adding a note with SPARQL, to see the result on the fly

SPARQL isn't only for asking questions. `INSERT DATA` adds a triple directly. It can't go through `ask`, though: `arq` only understands queries, and given an update it stops at the parser with an error like `Was expecting one of: "select" ... "describe" ... "ask"`. Save it in a file instead and hand the file to `robot`. (`.ru` is the usual extension for a SPARQL Update, as `.rq` is for a query - a convention only. The file carries its own `PREFIX` lines because `robot` doesn't prepend your prefix file the way `ask` does.)

```bash
cat > add_note.ru <<'EOF'
PREFIX ex: <http://example.org/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

INSERT DATA {
  ex:exp_aa001a skos:editorialNote "A second, added note - just to see what this looks like." .
}
EOF
```

With `robot`, this is `-u`/`--update` instead of `-q`/`--query`, writing the result to a new file with `-o`:

```bash
robot query --input aa_graph_20260909.ttl --update add_note.ru --output aa_graph_20260909_updated.ttl
```

**The `--output` filename has to genuinely differ from `--input`, and this is worth testing rather than assuming.** Point both at the same path and `robot` reads the whole file first, applies the update in memory, then writes the result back out to whatever `--output` says - including, if it's the same name, straight over the original. Confirmed directly: doing exactly that leaves the "original" holding the update, with nothing to undo it. The two-file version above isn't just a teaching convenience for showing the before/after side by side - it's the only thing standing between "preview" and "permanent, irreversible change", so always give `--output` a name that isn't `--input`.

```text
--------------------------------------------------------------
| note                                                       |
==============================================================
| "prepared without PURIFY=.t. and hence lost accuracy."     |
| "A second, added note - just to see what this looks like." |
--------------------------------------------------------------
```

`ex:exp_aa001a` now has two notes, side by side - genuinely useful for trying out a change before committing to it. But notice what `--output` actually did: it wrote a *new file*. Query the original `aa_graph_20260909.ttl` again and the second note simply isn't there:

```text
----------------------------------------------------------
| note                                                   |
==========================================================
| "prepared without PURIFY=.t. and hence lost accuracy." |
----------------------------------------------------------
```

That's not a bug to work around - it's the entire point, and worth sitting with rather than rushing past. This graph is a generated file, rebuilt from `run_notes.tsv` every time. A note added straight into a `.ttl` file lives only in that one output, until the next real rebuild quietly regenerates the graph from `run_notes.tsv` and doesn't know the SPARQL-added note ever existed. If you're happy with a note after seeing it this way, the durable version of "add it" is the same as it's always been in this project: write it into `run_notes.tsv`, then rebuild properly - not because SPARQL Update doesn't work, but because `run_notes.tsv` is this project's actual source of truth, and the graph is only ever a faithful copy of it.

### One update, many triples: fixing something at scale

`INSERT DATA` adds one specific triple. `DELETE`/`WHERE` finds every triple matching a pattern and removes all of them in a single operation - genuinely more powerful, and worth seeing on something real. Recall from Chapter 1: `gc:FrequencyPeak` carries two `rdfs:comment` values, one a real definition and the other a generic placeholder ("A class for FrequencyPeak.") left over from when the upstream ontology was first scaffolded. It isn't the only one - 51 classes across the release carry that same placeholder pattern. One update removes every one of them, wherever it appears:

Save it as `remove_placeholders.ru`, run it the same way - to a new file, never over the original - and count the placeholder lines before and after, plus the real comment on `gc:FrequencyPeak` to check it survived:

```bash
cat > remove_placeholders.ru <<'EOF'
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

DELETE {
  ?class rdfs:comment ?placeholder .
}
WHERE {
  ?class rdfs:comment ?placeholder .
  FILTER(STRSTARTS(STR(?placeholder), "A class for "))
}
EOF

robot query --input aa_graph_20260909.ttl --update remove_placeholders.ru --output aa_graph_noplaceholders.ttl

grep -c '"A class for [A-Za-z]*\."@en' aa_graph_20260909.ttl
grep -c '"A class for [A-Za-z]*\."@en' aa_graph_noplaceholders.ttl
grep -c 'A class representing frequency peak' aa_graph_noplaceholders.ttl
```

```text
51
0
1
```

All 51, gone in one pass (the counts above are before, after, and the surviving real comment) - and the real, useful comment on `gc:FrequencyPeak` survives untouched, because the pattern only matches the generic placeholder shape, not genuine documentation. This is the same searching skill as the rest of the chapter, just aimed at *changing* the graph instead of reading it: describe the pattern of what's wrong, and SPARQL finds every instance of it for you, rather than you finding and fixing each one by hand.

### What "permanent and logged" would actually need

Seeing a change on the fly like this is genuinely useful - it's a fast way to try something before committing to it. But the moment a change should stick, the question becomes: stick *where*, and how would anyone later know it happened? For this project, the honest answer already exists in how it's built, rather than needing anything new:

- **The source of truth stays a file.** For notes, that's `run_notes.tsv`; the ontology's own upstream text is `gc_core.ttl`. A SPARQL Update to the built graph is a preview of a change, not the change itself, for exactly the reason shown above - it evaporates on the next real rebuild.
- **Git is the audit trail.** Every edit to `run_notes.tsv` (or, for something like the placeholder-comment fix, an upstream correction) is a real commit, with a real message saying what changed and why - which is a genuine, working audit trail already, not something this project is missing.
- **Does the graph itself need a checksum, the way `.log` and `.dat` files already have one?** A fair question, and there's a real, published answer to it - [Trusty URIs](https://arxiv.org/abs/1401.5775) (Kuhn & Dumontier, 2014), built for precisely this: making RDF content verifiable even when a hash of it needs to appear *inside* the content itself. Their own paper discusses Git directly, and makes the relevant point plainly: Git's commit hashes already give exactly this guarantee - verifiable, immutable, checkable - just scoped to this one repository rather than the open web. Since nothing outside this repository currently cites this graph independently of it, that scope is the one that actually matters here. If it ever needed to be checked without the repository - the same way an `.inp` file's checksum lives in the graph, not inside the `.inp` file itself - the honest version would be a plain hash of the built `.ttl`, kept in a small file *next to* it rather than a triple *inside* it, for the same reason a checksum never describes itself: an RDF graph can be written out in more than one byte-for-byte-different way while meaning exactly the same thing, so a hash of the graph's bytes is a real answer to "does this exact file match", not to "does this graph still say the same thing" - a subtler question this project hasn't needed to answer yet.

---

## Step 5 - The same question, back where we started

Chapter 1 opened by simply handing you `wd:Q49546` and `wdt:P2054` - acetone, and density - without saying how anyone would find them without already knowing them. This chapter's whole subject has been exactly that gap, just aimed at this project's own graph. The same technique closes it on Wikidata too:

```bash
cat > /tmp/wd3.rq <<'EOF'
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT ?item
WHERE {
  ?item rdfs:label "Acetone"@en
}
EOF

curl -s -G https://query.wikidata.org/sparql -H 'Accept: text/csv' -A 'sparql-tutorial/0.1 (your-contact-here)' --data-urlencode query@/tmp/wd3.rq
```

```text
item
http://www.wikidata.org/entity/Q639124
http://www.wikidata.org/entity/Q4673275
http://www.wikidata.org/entity/Q4673276
http://www.wikidata.org/entity/Q63986955
http://www.wikidata.org/entity/Q108541377
```

Real output, genuinely run - and not `wd:Q49546` anywhere in it. `Q639124` turns out to be Acetone the Los Angeles musical group; `Q4673276` is a separate "chemical data page" item that also carries the label "Acetone". Wikidata's real world is exactly as full of same-named, different things as this chapter has been showing all along on `caa` and `aa` - a wide label search finds everything that matches, not just what you had in mind, and Wikidata is no exception.

But that's not the only thing going on here, and it's worth checking before assuming a type filter is the whole fix. Wikidata's own page for the compound is titled, in full: **acetone (Q49546)** - lowercase. `=` in SPARQL is exactly as case-sensitive as `CONTAINS` was in Step 2, and this query asked for `"Acetone"@en`, capital A. The real chemical compound was never in the running at all - it was filtered out by a difference in case before a type filter would even get the chance to matter. The corrected query:

```sparql
SELECT ?item WHERE {
  ?item rdfs:label "acetone"@en
}
```

```text
item
http://www.wikidata.org/entity/Q49546
```

Confirmed directly, and cleanly - one result, `Q49546` itself, nothing else to narrow down. The case fix alone was the whole story here; the wide-net problem from earlier in this section never actually needed its own separate fix once the label matched.

The same two lessons this chapter taught on a graph you built yourself turned out to matter, unedited, on a graph you'd never seen the inside of - which is the whole point of a shared query language: the skill doesn't know which graph it's pointed at, and neither do its gotchas.

## Chapter 4 - A field guide to a graph you didn't build

Chapters 1 to 3 each taught a move. This chapter puts them in order, using a question that sounds trivial and isn't: **which experiments are in this graph, and how many?** There is almost no new syntax (`IN` and `FILTER NOT EXISTS`, both small). What's new is a habit - checking an answer a second way before trusting it - and the example is a real one, where the obvious first answer comes back short with no sign that anything is wrong.

Every query below runs against the published `aa` graph unless it says otherwise.

---

## Step 1 - Take the plausible answer, then count something else

Chapter 1's type list is where an unknown graph begins. Scanning it for something experiment-like, `gc:MolecularComputation` looks exactly right. Count it - and, beside it, the three kinds of file the pipeline records for every run (an input, a data file and a log, one of each per experiment, as Chapter 2 showed). `IN` keeps the rows whose value is in the list:

```sparql
SELECT ?type (COUNT(?thing) AS ?n) WHERE {
  ?thing a ?type .
  FILTER(?type IN (gc:MolecularComputation, ex:InputFile, ex:DataFile, ex:LogFile))
}
GROUP BY ?type ORDER BY ?type
```

```text
--------------------------------
| type                    | n  |
================================
| ex:DataFile             | 30 |
| ex:InputFile            | 30 |
| ex:LogFile              | 30 |
| gc:MolecularComputation | 27 |
--------------------------------
```

Three counts of 30 and one of 27. Nothing errored, and 27 looks like a perfectly reasonable answer on its own. It is only visibly wrong because a second, independent count disagrees with it - which is the whole reason to take one.

---

## Step 2 - When two counts disagree, find the difference

Which experiments - things with an input file, the test Chapter 3 used - are missing the class? `FILTER NOT EXISTS { ... }` keeps a row only if the pattern inside matches nothing, which is the direct way to say "without". (Chapter 2 spelled the same idea with `OPTIONAL` plus `FILTER(!BOUND(...))`. That form also works in the playground, whose simpler engine silently ignores `FILTER NOT EXISTS`; on a full engine like `arq`, this one says it more directly.)

```sparql
SELECT ?exp WHERE {
  ?exp prov:used ?f .
  FILTER NOT EXISTS { ?exp a gc:MolecularComputation }
}
ORDER BY ?exp
```

```text
----------------------------------------
| exp                                  |
========================================
| ex:exp_aa002-aldehyde-bare-smd       |
| ex:exp_aa002-aldehyde-bare-smd-check |
| ex:exp_aa002-aldehyde-bare-smd-hcore |
----------------------------------------
```

Three runs of one calculation, the SMD aldehyde: the plain run and two diagnostic variants of it. What do they lack that the others have? Ask one of them for everything it has (Chapter 1's question), and compare with `ex:exp_aa001a` from Chapter 2:

```sparql
SELECT ?p ?v WHERE { ex:exp_aa002-aldehyde-bare-smd-hcore ?p ?v } ORDER BY ?p ?v
```

```text
-------------------------------------------------------------------------------
| p                    | v                                                    |
===============================================================================
| ex:hasHssend         | true                                                 |
| ex:hasRuntyp         | "OPTIMIZE"                                           |
| ex:hasSolvationModel | "SMD"                                                |
| ex:hasSolvent        | "water"                                              |
| gc:hasBasisSet       | "6-21G+(d,p)"                                        |
| gc:hasMethod         | "wB97X-D"                                            |
| rdf:type             | gc:VibrationalAnalysis                               |
| rdf:type             | owl:NamedIndividual                                  |
| rdfs:label           | "Vibrational analysis aa002-aldehyde-bare-smd-hcore" |
| prov:generated       | ex:file_aa002-aldehyde-bare-smd-hcore_dat            |
| prov:generated       | ex:file_aa002-aldehyde-bare-smd-hcore_log            |
| prov:used            | ex:file_aa002-aldehyde-bare-smd-hcore_inp            |
-------------------------------------------------------------------------------
```

Label, method, basis set, input and output files are all there. What's missing is `gc:hasResult`. Check that this is the whole story: how many experiments have a result, and does any experiment carry the class without one?

```sparql
SELECT (COUNT(DISTINCT ?exp) AS ?withResults) WHERE { ?exp gc:hasResult ?r }
```

```text
---------------
| withResults |
===============
| 27          |
---------------
```

```sparql
SELECT ?exp WHERE {
  ?exp a gc:MolecularComputation .
  FILTER NOT EXISTS { ?exp gc:hasResult ?r }
}
```

```text
-------
| exp |
=======
-------
```

27 with a result, and nothing has the class without one - so every experiment with the class has a result, and the counts match: the same 27 experiments, not merely the same number.

`gc:MolecularComputation` is not a label the pipeline puts on every experiment. It arrives as a by-product: the scripts that attach results, constraints and notes to an experiment each write that class on it, so an experiment that nothing was attached to never gets it. These three produced no results, so they never did - and a note added to one of them would give it the class, whether or not there are results. The class wasn't wrong about anything it said. It was answering a different question - "which experiments have had something attached?" - from the one that was asked.

---

## Step 3 - Pick something every one of them has, and check it

A relationship can do what the class couldn't. Everything that ran has an input file and, as Chapter 2 showed, generated output files. Count each:

```sparql
SELECT (COUNT(DISTINCT ?exp) AS ?n) WHERE { ?exp prov:used ?f }
```

```text
------
| n  |
======
| 30 |
------
```

```sparql
SELECT (COUNT(DISTINCT ?exp) AS ?n) WHERE { ?exp prov:generated ?o }
```

```text
------
| n  |
======
| 30 |
------
```

And the kinds of experiment - Chapter 1's breakdown, restricted to things that ran:

```sparql
SELECT ?type (COUNT(DISTINCT ?exp) AS ?n) WHERE { ?exp prov:used ?f ; a ?type }
GROUP BY ?type ORDER BY DESC(?n) ?type
```

```text
--------------------------------
| type                    | n  |
================================
| owl:NamedIndividual     | 30 |
| gc:MolecularComputation | 27 |
| gc:VibrationalAnalysis  | 16 |
| gc:SinglePoint          | 10 |
| gc:IRC                  | 2  |
| gc:SaddlePoint          | 2  |
--------------------------------
```

The four specific kinds - 16, 10, 2 and 2 - add up to 30, so every experiment has exactly one of them (the other rows are broader tags: `owl:NamedIndividual` on everything, and the unreliable class). Now input files, output files, the file counts from Step 1 and the sum of the kinds all say 30. The class said 27.

If you want the list rather than the count, the playground's "basic inventory" example is exactly that, with the kinds spelled out.

---

## Step 4 - Does the answer travel?

A test that works on one graph might only have been fitted to it. Run Step 3's count, and then its breakdown, again on `caa`, with `ask2 "$G2"` from Chapter 1:

```text
------
| n  |
======
| 61 |
------
```

```text
--------------------------------
| type                    | n  |
================================
| owl:NamedIndividual     | 61 |
| gc:MolecularComputation | 60 |
| gc:VibrationalAnalysis  | 43 |
| gc:SinglePoint          | 13 |
| gc:IRC                  | 2  |
| gc:SaddlePoint          | 2  |
| gc:GeometryOptimization | 1  |
--------------------------------
```

Five specific kinds this time - `gc:GeometryOptimization` has one experiment - and 43 + 13 + 2 + 2 + 1 is 61, matching the `prov:used` count. A list of kinds written for `aa` would have missed that one; the relationship didn't care. That's also why the playground's inventory lists all five. The class is short again, 60 of 61, and the missing experiment is `ex:exp_caa001` - the lone geometry optimisation, which has no results attached: no results, no class, the same pattern as in `aa`.

One more trap, if you use the reasoned graph (README Step 6): inference can make a loose class looser. The same class on `aa`'s published reasoned graph - `ask2` takes a URL as well as a file:

```bash
ask2 https://raw.githubusercontent.com/Darren01/ont_mm/main/examples/aa/ont/aa_graph_reasoned.ttl <<'EOF'
SELECT (COUNT(DISTINCT ?x) AS ?n) WHERE { ?x a gc:MolecularComputation }
EOF
```

```text
-------
| n   |
=======
| 426 |
-------
```

Not 30, and not 27: reaction path points, frequency peaks, atoms and other things now count as "a computation" too. The relationship holds up where the class doesn't - Step 3's `prov:used` count, on the same reasoned graph:

```text
------
| n  |
======
| 30 |
------
```

Whatever you decide counts as "an experiment" in the asserted graph, re-check it on the reasoned one before relying on it.

---

## The recipe, in one place

Facing a graph you know nothing about:

1. **What kinds of thing are here, and how many of each?** (Chapter 1, Steps 1 to 3)
2. **What do the interesting ones mean?** Ask for their labels and definitions. (Chapter 1, Step 4)
3. **Is there one class for "all of them"?** If the obvious class exists, treat it as a candidate, not the answer. If none fits, look for something every one of them has - usually a relationship. (Steps 1 and 3 above)
4. **Count it a second way, from a different part of the model** - files, results, outputs - **and when counts disagree, find out why.** (Steps 1 and 2 above)
5. **Look at one in full, then ask what that kind of thing has.** (Chapter 1, Steps 4 and 5; Chapter 2, Step 1)
6. **See the real values before you filter on them, and follow the links to what they point at.** (Chapter 2; Chapter 3, Step 3)
7. **Look for what's missing, and check whether it's deliberate.** (Chapter 2, Step 5)
8. **Check that the answer travels** - to another graph, and to the reasoned version of the same one. (Step 4 above)

Steps 3, 4 and 8 are this chapter's. The rest were already in Chapters 1 to 3, but nowhere as one sequence.

## What this chapter showed

The class was never wrong about anything it said. It answered a different question - "which experiments have had something attached?" - from the one that was asked, and the only thing that revealed it was a second count. That is the habit to take to any graph you didn't build: before you trust a number, ask something else that has to agree with it. Chapter 5 is the first time this is tried on a graph nobody here built.

## Chapter 5 - Out in the wild

Everything so far has worked on a graph you either built yourself or watched get built. This chapter uses the same skills, unmodified, on a graph nobody in this project built: Wikidata, a real, public, billions-of-facts knowledge graph that anyone can query the same way `caa` and `aa` have been queried all along. Chapter 4 ended with a recipe for approaching a graph you know nothing about; this chapter is its first test on one nobody here built.

It's worth asking honestly, before going any further: why do this at all, rather than just look a number up on Wikipedia? For a single fact, Wikipedia is often genuinely faster, and this chapter won't pretend otherwise. The real answer is that the value shows up exactly where "one fact" stops being enough:

- **More than one item stops being one lookup per item.** The density of acetone is one Wikipedia visit. The density *and* pKa of four solvents is, on Wikipedia, four visits and eight numbers copied out by hand. On Wikidata it's the same one query either way.
- **The numbers aren't laid out for a program to read.** An infobox is built for a human eye; pulling "just the density" out of it means reading it yourself or writing something fragile that breaks the next time the page's formatting changes. Wikidata's version of the same number is a real, structured `wikibase:quantityAmount` - the same shape on every item, which is exactly what let Chapter 2 write one query that works on any experiment in this project's own graphs, not one query per experiment.
- **A genuinely combined question is one more line, not several pages read by hand.** "Which of these solvents has a density under 1 g/cm³ *and* a recorded pKa above 15" is a real filter in SPARQL. No single Wikipedia infobox is built to answer it at all.
- **Nothing here is a new tool.** The query shape that found real values in `caa`'s own `hasMethod` column, and the `p:`/`psv:` pattern Chapter 2 built for a `FloatValue`, are unchanged. Same skill, a graph with billions of facts instead of thousands.

That last point is the honest test this chapter has to pass: everything in it should already be familiar, just pointed somewhere new.

---

## Step 1 - Finding the property you need, without being handed it

Chapters 1 through 3 handed you `wd:Q49546` and `wdt:P2054` before you'd found either yourself. That's a real gap for an item (Chapter 3 closed it), and the same gap exists for a *property* - `P2054` is exactly as arbitrary a code as `Q49546` was, and just as unfindable by guessing.

Wikidata properties are real entities with their own `rdfs:label`, the same as items - the difference is a property also has a `wikibase:directClaim` link to its own predicate, and only properties do, which makes it a reliable way to search *just* properties rather than every entity that happens to share a word:

```sparql
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX wikibase: <http://wikiba.se/ontology#>

SELECT ?property ?label WHERE {
  ?property wikibase:directClaim ?p ;
            rdfs:label ?label .
  FILTER(CONTAINS(LCASE(?label), "density"))
}
```

```text
property,label
http://www.wikidata.org/entity/P2054,density
http://www.wikidata.org/entity/P14392,energy density
```

Two results, both genuinely about density, no noise. `P2054` is the one used throughout this tutorial; `P14392` is a real, different property (energy density) that happens to share the word - worth noticing, since it's the same "wide net, then look at what came back" habit from Chapter 3, now finding a property instead of an item.

## Step 2 - Finding several items at once

A single item's density or pKa is one query. Several solvents' worth of both is where Wikidata starts to genuinely pay for itself - but that means finding several items in one go, not one at a time.

`VALUES` binds a variable to a fixed list before the rest of the query runs - here, a list of labels rather than addresses, since the addresses are exactly what this step is trying to find:

```bash
wiki <<'EOF'
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT ?solvent ?wantedLabel WHERE {
  VALUES ?wantedLabel { "water"@en "ethanol"@en "methanol"@en "acetone"@en }
  ?solvent rdfs:label ?wantedLabel .
}
EOF
```

(`wiki` is the shortcut from Chapter 1, Step 2 - the same idea as `ask`, but sending the query to Wikidata's own endpoint. If you skipped it, here it is again:

```bash
wiki() {
  mkdir -p /tmp/sparql
  cat - > /tmp/sparql/wiki.rq
  curl -s -G https://query.wikidata.org/sparql -H 'Accept: text/csv' -A 'sparql-tutorial/0.1 (your-contact-here)' --data-urlencode query@/tmp/sparql/wiki.rq
}
```

Paste that into your shell once, same as `ask`.)

Real output:

```text
solvent,wantedLabel
http://www.wikidata.org/entity/Q14982,methanol
http://www.wikidata.org/entity/Q153,ethanol
http://www.wikidata.org/entity/Q283,water
http://www.wikidata.org/entity/Q2637515,water
http://www.wikidata.org/entity/Q5474065,water
http://www.wikidata.org/entity/Q16035863,water
http://www.wikidata.org/entity/Q25588649,water
http://www.wikidata.org/entity/Q56877699,water
http://www.wikidata.org/entity/Q68834339,water
http://www.wikidata.org/entity/Q140424798,water
http://www.wikidata.org/entity/Q140443055,water
http://www.wikidata.org/entity/Q140445549,water
http://www.wikidata.org/entity/Q49546,acetone
```

Methanol, ethanol and acetone: one result each. `water` alone comes back nine times - Chapter 3's own lesson (a label search finds everything that matches, not just what you had in mind) landing harder here, on a much more ordinary word than "acetone" ever was.

The fix is the same one Chapter 3 used on this project's own graph: narrow by type, not just by label. Wikidata's version of `rdf:type` is `wdt:P31` ("instance of"), and the value to narrow by is worth getting straight from the item itself rather than trusted from a search - a first attempt here, using the commonly-cited class "chemical compound" (`Q11173`), came back completely empty:

```bash
wiki <<'EOF'
PREFIX wd: <http://www.wikidata.org/entity/>
PREFIX wdt: <http://www.wikidata.org/prop/direct/>

SELECT ?type WHERE { wd:Q283 wdt:P31 ?type }
EOF
```

```text
type
http://www.wikidata.org/entity/Q113145171
```

`Q283`'s own, real, current type is `Q113145171` - "type of chemical entity", a deliberate marker Wikidata's own Chemistry WikiProject adds to pure chemical substances specifically so they can all be found with one query, rather than the more general "chemical compound" a search had suggested. Asking the item what it actually is settled it, the same principle as Chapter 1's very first lesson - a name's real meaning is worth confirming from the graph, not assumed from what looked right. With the correct type:

```bash
wiki <<'EOF'
PREFIX wd: <http://www.wikidata.org/entity/>
PREFIX wdt: <http://www.wikidata.org/prop/direct/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT ?solvent ?wantedLabel WHERE {
  VALUES ?wantedLabel { "water"@en "ethanol"@en "methanol"@en "acetone"@en }
  ?solvent rdfs:label ?wantedLabel ;
           wdt:P31 wd:Q113145171 .
}
EOF
```

```text
solvent,wantedLabel
http://www.wikidata.org/entity/Q153,ethanol
http://www.wikidata.org/entity/Q283,water
http://www.wikidata.org/entity/Q14982,methanol
http://www.wikidata.org/entity/Q49546,acetone
```

Four solvents, four rows, `water` finally down to the one real item. Worth keeping the four addresses this found - `Q283`, `Q153`, `Q14982`, `Q49546` - since the rest of this chapter uses them directly, the same way Chapter 2 moved from finding a peak to working with it.

## Step 3 - Density, for all four at once

Chapter 2 found acetone's own density through its real statement node, not the plain `wdt:` shortcut, because the statement holds more than the number - a unit alongside it. The same query, run across all four solvents with `VALUES`:

```bash
wiki <<'EOF'
PREFIX wd: <http://www.wikidata.org/entity/>
PREFIX p: <http://www.wikidata.org/prop/>
PREFIX psv: <http://www.wikidata.org/prop/statement/value/>
PREFIX wikibase: <http://wikiba.se/ontology#>

SELECT ?solvent ?amount ?unit WHERE {
  VALUES ?solvent { wd:Q283 wd:Q153 wd:Q14982 wd:Q49546 }
  ?solvent p:P2054 ?statement .
  ?statement psv:P2054 ?value .
  ?value wikibase:quantityAmount ?amount ;
          wikibase:quantityUnit ?unit .
}
EOF
```

29 rows, not 4 - and worth reading closely rather than skimming past, because it holds two real, separate lessons.

**Water alone accounts for 25 of them.** That's not noise: density genuinely depends on temperature, and Wikidata is honestly recording separate measurements at different temperatures as separate statements, none marked as the one "preferred" value. Worth a direct correction here to something Chapter 2 said too simply: the `wdt:` shortcut is described there as "the single best-ranked value" - true only when one statement actually is marked preferred. Where none are, as with water's own density, `wdt:` hands back every one of them, exactly like the full statement form does. Confirmed directly:

```sparql
SELECT ?solvent ?density WHERE {
  VALUES ?solvent { wd:Q283 wd:Q153 wd:Q14982 wd:Q49546 }
  ?solvent wdt:P2054 ?density .
}
```

still returns water's own 26 values, not one.

**Ethanol's own row is `790.0`, in a different unit** (`Q844211`, not `Q13147228` like the other three) - not a value roughly a thousand times too high, but the same number in kilograms per cubic metre rather than grams per cubic centimetre (790 kg/m³ is exactly 0.79 g/cm³, matching methanol almost exactly). Different contributors recorded the same real quantity in different, equally valid units. Comparing the raw numbers without checking `?unit` first would have been a genuine, silent error here - the kind a person skimming a Wikipedia infobox by eye would likely catch, and an automated query absolutely will not, unless it's written to check.

Picking one temperature to compare at needs the same qualifier-reading skill pKa needs later, so it's worth building it here first, on something already familiar. `pq:` reads a qualifier off the same statement node already found:

```sparql
PREFIX pq: <http://www.wikidata.org/prop/qualifier/>

SELECT ?solvent ?amount ?unit ?temp WHERE {
  VALUES ?solvent { wd:Q283 wd:Q153 wd:Q14982 wd:Q49546 }
  ?solvent p:P2054 ?statement .
  ?statement psv:P2054 ?value ;
             pq:P2076 ?temp .
  ?value wikibase:quantityAmount ?amount ;
          wikibase:quantityUnit ?unit .
}
```

Real output shows water recorded across more than twenty different temperatures, from -30°C to 100°C - and, checked directly rather than assumed, neither the modern IUPAC standard (0°C) nor the older, common one (25°C) has a recorded value for all four solvents; only water has either. **20°C** does - the honest answer here isn't "the standard reference condition", it's "the one temperature this dataset actually, consistently recorded for every solvent being compared." Filtering on it directly:

```bash
wiki <<'EOF'
PREFIX wd: <http://www.wikidata.org/entity/>
PREFIX p: <http://www.wikidata.org/prop/>
PREFIX psv: <http://www.wikidata.org/prop/statement/value/>
PREFIX pq: <http://www.wikidata.org/prop/qualifier/>
PREFIX wikibase: <http://wikiba.se/ontology#>

SELECT ?solvent ?amount ?unit WHERE {
  VALUES ?solvent { wd:Q283 wd:Q153 wd:Q14982 wd:Q49546 }
  ?solvent p:P2054 ?statement .
  ?statement psv:P2054 ?value ;
             pq:P2076 20.0 .
  ?value wikibase:quantityAmount ?amount ;
          wikibase:quantityUnit ?unit .
}
EOF
```

```text
solvent,amount,unit
http://www.wikidata.org/entity/Q49546,0.7902,http://www.wikidata.org/entity/Q13147228
http://www.wikidata.org/entity/Q14982,0.79,http://www.wikidata.org/entity/Q13147228
http://www.wikidata.org/entity/Q153,790.0,http://www.wikidata.org/entity/Q844211
http://www.wikidata.org/entity/Q283,0.9982071,http://www.wikidata.org/entity/Q13147228
```

Four rows, one per solvent, genuinely comparable now that temperature is matched - except ethanol's unit is still the odd one out, confirming this wasn't a fluke of the earlier, mixed-temperature result. Converted by hand (790 kg/m³ = 0.79 g/cm³), all four solvents sit within a narrow, unsurprising range at 20°C - acetone 0.790, methanol 0.790, ethanol 0.790, water 0.998. A real SPARQL query could normalize the unit automatically with `BIND`/`IF` rather than by hand; left as a genuine next step rather than built out here, since this chapter still has pKa ahead of it and one new construct at a time is enough.

## Step 4 - pKa, where it exists

Same shape of query as density - `p:`/`psv:` for the statement and its value, `pq:` for the temperature it was measured at - now on `P1117`, the property Step 1 found by searching, not being handed:

```bash
wiki <<'EOF'
PREFIX wd: <http://www.wikidata.org/entity/>
PREFIX p: <http://www.wikidata.org/prop/>
PREFIX psv: <http://www.wikidata.org/prop/statement/value/>
PREFIX pq: <http://www.wikidata.org/prop/qualifier/>
PREFIX wikibase: <http://wikiba.se/ontology#>

SELECT ?solvent ?amount ?temp WHERE {
  VALUES ?solvent { wd:Q283 wd:Q153 wd:Q14982 wd:Q49546 }
  ?solvent p:P1117 ?statement .
  ?statement psv:P1117 ?value .
  ?value wikibase:quantityAmount ?amount .
  OPTIONAL { ?statement pq:P2076 ?temp . }
}
EOF
```

```text
solvent,amount,temp
http://www.wikidata.org/entity/Q14982,15.5,
http://www.wikidata.org/entity/Q153,16.0,
http://www.wikidata.org/entity/Q49546,19.16,25.0
```

Three rows, not four - **water has no recorded pKa here at all.** That's a real, honest result, not a missing step: Chapter 1's own lesson about absence again, on a dataset this tutorial had no hand in building. Methanol (15.5) and ethanol (16.0) genuinely are weak acids of a similar, unremarkable strength; acetone, at 19.16, is markedly weaker - a real, meaningful difference between these solvents, not an artefact of the query.

Worth noticing too: only acetone's own row carries a temperature. `P1117`'s own property page states temperature as a *required* qualifier - but "required" on Wikidata is a documented expectation, not something SPARQL enforces the way an OWL range restriction does in this project's own graphs. Methanol and ethanol's values are real, genuinely present, just recorded without it. Real, open data is written by many different people over time, and not every statement lives up to its own property's stated intent - a difference worth remembering before assuming a `pq:` qualifier will always be there just because a property's documentation says it should be.

## What this chapter actually showed

Two `VALUES` queries and two `pq:` qualifier reads is the whole new syntax this chapter introduced - genuinely small, exactly as promised at the start. Everything harder than the syntax was the data itself being real: water's density recorded at more than twenty different temperatures with none marked preferred, the same quantity written in two different, equally valid units, a "required" qualifier that wasn't always there, and a property with no value at all for one of the four items asked about. None of that needed a new tool. Every one of those was handled with a habit already built on this project's own graphs - search wide then narrow, check what's actually there before assuming, treat an empty or partial result as information rather than failure.

That was always the real test this chapter set for itself, back in its own opening: not "is Wikidata interesting", but "does everything already learned still hold up, unmodified, somewhere this project had no hand in building." It did.

## Where next

- **Finding solvents by class, not by hand:** this chapter searched four solvents chosen and named in advance. Wikidata's own "type of chemical entity" (`Q113145171`) - the class this chapter's own Step 2 had to go and verify directly - is a real, natural way to find solvents rather than list them, and was deliberately left for later rather than folded in here.
- **Normalizing units automatically:** Step 3's ethanol/kilogram-per-cubic-metre mismatch was converted by hand. A real query could do this with `BIND`/`IF`, checking `?unit` and adjusting the value accordingly - a genuine next construct, not built out here so this chapter could stay focused on one new thing at a time.
- [COMPETENCY_QUESTIONS.md](./COMPETENCY_QUESTIONS.md) - worked questions about experiments, energies and frequencies.
- The [SPARQL playground](./tools/sparql_playground.html) - the same searches from this chapter, in a browser, with nothing to install.
