# rebuild_examples.R - rebuild the aa and caa example graphs from scratch, with species InChI nodes.
#
# Run from a terminal where `python3 -c "import rdkit"` works and `robot` is on the PATH:
#     Rscript scripts/rebuild_examples.R   (from the ont_mm folder)
#
# What it does, per dataset (aa, then caa):
#   1. deletes every GENERATED file in examples/<ds>/ont (instance tables, template .ttl, graphs)
#      - keeps run_notes.tsv, which is hand-written. Nothing is deleted outside that folder.
#   2. process_gamess_directory(..., species = TRUE)   -> instance tables incl. molecule rows
#   3. notes -> annotations, then filter_vibrational_modes()
#   4. build_ontology_graph()  -> <ds>_graph_20261007.ttl   (same file name as before, so links keep working)
#   5. build_reasoned_graph()  -> <ds>_graph_reasoned.ttl
#   6. prints a short check (species counts) and the species refusals.
# Git is your undo: commit your other changes first, and `git checkout examples/` restores the old graphs.

code_dir <- path.expand(Sys.getenv("REBUILD_CODE_DIR", unset = "~/Projects/active"))
datasets <- strsplit(Sys.getenv("REBUILD_DATASETS", unset = "aa,caa"), ",")[[1]]
robot    <- Sys.getenv("REBUILD_ROBOT", unset = "robot")

gf <- file.path(code_dir, "gamess_functions")
om <- file.path(code_dir, "ont_mm")
stopifnot(dir.exists(gf), dir.exists(om))

# ---- prerequisites -------------------------------------------------------------------------
if (system2("python3", c("-c", shQuote("import rdkit")), stdout = FALSE, stderr = FALSE) != 0) {
  stop("Python cannot import rdkit - install it first (python3 -m pip install rdkit).")
}
if (suppressWarnings(system2(robot, "--version", stdout = FALSE, stderr = FALSE)) != 0) {
  stop("robot was not found on the PATH (see README Step 1c / check_robot_setup()).")
}

# ---- load the code (README Step 3's list, plus the species files) --------------------------
paths <- c(
  "gamess_functions/R/gamess_input_utils.R", "gamess_functions/R/classify_gamess_jobs.R",
  "gamess_functions/R/extract_basis.R", "gamess_functions/R/extract_level_of_theory.R",
  "gamess_functions/R/extract_ir_spectrum.R", "gamess_functions/R/extract_ir_diagnostics.R",
  "gamess_functions/R/identify_diagnostic_modes.R", "gamess_functions/R/extract_thermochemistry.R",
  "gamess_functions/R/extract_electronic_energy.R", "gamess_functions/R/extract_irc_trajectory.R",
  "gamess_functions/R/combine_irc_trajectories.R", "gamess_functions/R/extract_constraints.R",
  "gamess_functions/R/extract_geometry_trajectory.R", "gamess_functions/R/check_vibrational_quality.R",
  "gamess_functions/R/geometry_to_atoms.R", "gamess_functions/R/ir_spectrum_to_templates.R",
  "gamess_functions/R/thermochemistry_to_templates.R", "gamess_functions/R/electronic_energy_to_templates.R",
  "gamess_functions/R/reaction_path_to_templates.R", "gamess_functions/R/constraints_to_templates.R",
  "gamess_functions/R/species_inchi_to_templates.R", "gamess_functions/R/build_species_table.R",
  "gamess_functions/R/notes_to_annotations.R", "gamess_functions/R/build_reasoned_graph.R",
  "ont_mm/scripts/build_provenance.R", "ont_mm/scripts/process_experiments.R",
  "ont_mm/scripts/process_results.R", "ont_mm/scripts/process_thermo_results.R",
  "ont_mm/scripts/process_electronic_energy_results.R", "ont_mm/scripts/process_reaction_path_results.R",
  "ont_mm/scripts/process_contraints.R", "ont_mm/scripts/process_gamess_directory.R",
  "ont_mm/scripts/filter_vibrational_modes.R", "ont_mm/scripts/build_ontology_graph.R"
)
for (p in file.path(code_dir, paths)) source(p)

helper    <- file.path(gf, "python/inchi_species.py")
release   <- file.path(om, "releases/2026-10-11/gc_core.ttl")
extension <- file.path(om, "schema_terms.ttl")
dl_axioms <- file.path(om, "dl_axioms.ttl")
template  <- file.path(om, "templates/experiment_template.tsv")
for (f in c(helper, release, extension, dl_axioms, template)) if (!file.exists(f)) stop("missing: ", f)

for (ds in datasets) {
  cat("\n################ ", ds, " ################\n", sep = "")
  base <- file.path(om, "examples", ds)
  ont  <- file.path(base, "ont")
  graph    <- file.path(ont, paste0(ds, "_graph_20261007.ttl"))
  reasoned <- file.path(ont, paste0(ds, "_graph_reasoned.ttl"))

  # 1. delete generated files only
  gen <- c(list.files(ont, "_template_instances\\.tsv$", full.names = TRUE),
           list.files(ont, "_template\\.ttl$", full.names = TRUE),
           list.files(ont, "_graph.*\\.ttl$", full.names = TRUE),
           file.path(ont, "release_with_extensions.ttl"),
           file.path(ont, "species_report.tsv"))
  gen <- unique(gen[file.exists(gen)])
  cat("Deleting", length(gen), "generated files in", ont, "\n")
  file.remove(gen)

  # 2. instance data, with species
  process_gamess_directory(
    input_dir = file.path(base, "inputs"), output_dir = file.path(base, "outputs"),
    data_dir = file.path(base, "dat"), ontology_dir = ont,
    experiment_template_file = template, species = TRUE, species_helper = helper)

  # 3. notes, then filter modes
  notes <- file.path(ont, "run_notes.tsv")
  if (file.exists(notes)) {
    write_annotations(notes_to_annotations(notes), file.path(ont, "annotation_template_instances.tsv"))
  }
  filter_vibrational_modes(ontology_dir = ont, output_dir = file.path(base, "outputs"))

  # 4. graph
  build_ontology_graph(ontology_dir = ont, release_file = release, output_file = graph,
                       extensions_file = extension, robot_cmd = robot)

  # 5. reasoned graph (several minutes, longest for caa)
  build_reasoned_graph(asserted_graph_file = graph, extensions_file = dl_axioms,
                       output_file = reasoned, robot_cmd = robot)

  # 6. quick check
  q <- tempfile(fileext = ".rq"); o <- tempfile(fileext = ".tsv")
  writeLines(c("PREFIX gc: <http://purl.org/gc/>",
               "SELECT ?inchikey (COUNT(DISTINCT ?system) AS ?systems) WHERE {",
               "  ?system gc:hasMolecule ?species . ?species gc:hasInChIKey ?inchikey .",
               "} GROUP BY ?inchikey ORDER BY DESC(?systems)"), q)
  system2(robot, c("query", "--input", shQuote(graph), "--query", shQuote(q), shQuote(o)), stdout = FALSE, stderr = FALSE)
  cat("\nSpecies in", basename(graph), "(InChIKey, number of systems):\n")
  print(utils::read.delim(o, check.names = FALSE), row.names = FALSE)
  rep <- utils::read.delim(file.path(ont, "species_report.tsv"), stringsAsFactors = FALSE)
  ref <- rep[rep$status == "refused", c("experiment", "formula", "message")]
  cat("\nRefused (no node written):", nrow(ref), "species\n")
  if (nrow(ref)) print(ref, row.names = FALSE)
}
cat("\nDone. Review with `git status` and `git diff --stat` in ont_mm before committing.\n")
