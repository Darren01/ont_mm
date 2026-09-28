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

**Same skill, different graph.** How hard would it be to ask something you didn't build at all? Wikidata - the large public knowledge graph run by the Wikimedia Foundation - answers SPARQL over the web. Acetone is item `Q49546` in Wikidata, and density is property `P2054`. So: what is the density of acetone?

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

**Try it on something else.** Go back to Step 2's list (or run `arq --data $G --query ~/queries/types-in-graph.rq` again) and pick a different name from it - `gc:SinglePoint`, say, or `ex:LogFile` - then put it in place of `gc:FrequencyPeak` above. The query doesn't change shape at all; only the one fixed term does. Flipping between the two files like this, list then detail then back to the list, is the fastest way to get a feel for what's actually in a graph you didn't build yourself.

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

---

## What you've learned

| To find out... | Ask... |
|---|---|
| what kinds of things exist | `SELECT ?type (COUNT(?thing) AS ?howMany) WHERE { ?thing a ?type } GROUP BY ?type` |
| everything the graph says about one thing | `SELECT ?property ?value WHERE { gc:FrequencyPeak ?property ?value }` |
| every property in use | `SELECT DISTINCT ?property WHERE { ?s ?property ?o }` |
| the properties of one kind of thing | `SELECT DISTINCT ?property WHERE { ?thing a gc:FrequencyPeak ; ?property ?value }` |

Four habits carry over to everything else: explore in scratch and keep only what earns its place, put the prefix block at the top, look at what came back before writing the next query, and when a name is unfamiliar, ask the graph what it is.

## Where next

- **Chapter 2 (to come):** following links from an experiment to its files, values that live inside their own nodes - ending with the unit on acetone's density in Wikidata - and finding what's *missing*.
- [COMPETENCY_QUESTIONS.md](./COMPETENCY_QUESTIONS.md) - worked questions about experiments, energies and frequencies.
- The [SPARQL playground](./tools/sparql_playground.html) - runs in a browser with nothing to install. It is a quick way to try queries, with limits: it runs on a simpler engine that ignores some standard SPARQL, which is one reason to graduate to `arq` for real work.
- The [W3C SPARQL 1.1 Query Language](https://www.w3.org/TR/sparql11-query/) specification, and Jena's [command-line documentation](https://jena.apache.org/documentation/query/cmds.html). Because `arq` is a complete SPARQL engine, queries from any SPARQL tutorial should run on your graph as written.
