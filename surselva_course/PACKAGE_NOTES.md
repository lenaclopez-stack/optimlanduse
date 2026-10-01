# Notes from a careful read of the *optimLanduse* repository

**Correction (important).** The first version of this course was written from a copy of the repository at version **1.1.0** (a fork snapshot, commit `0bbaa84`), which has no Pareto function, and I wrongly concluded the package had none. The upstream repository `Forest-Economics-Goettingen/optimLanduse` is at **version 2.0.0** (commit `f93e055`, "Submission 2.0.0"), and its `NEWS.md` says: *"solveScenario: added Pareto optimisation (paretoY, paretoX, paretoMaxDistance) and land-use restrictions (landUseRestriction)"*. The course has been rebuilt on 2.0.0 and uses that feature.

Everything below comes from reading the R files of both versions (`initScenario.R`, `solveScenario.R`, `calcPerformance.R`, `dataPreparation.R`, `helper.R`, `examples.R`, `autoSearch.R` in 2.0.0), `NEWS.md`, `DESCRIPTION`, `NAMESPACE`, `README.Rmd`, the help pages, and from running the package (R 4.3.3, version 2.0.0). Items marked ✔ were reproduced by running code on 2.0.0.

## 1. How the Pareto option works (version 2.0.0)

`solveScenario(x, paretoY, paretoX, paretoMaxDistance)` implements the **epsilon-constraint method** as one linear program:

* it **maximises** the guaranteed performance (beta in the code) of the indicators named in `paretoY`;
* subject to: every `paretoX` indicator has performance ≥ `paretoMaxDistance` in **every** uncertainty scenario (a number between 0 and 1, despite the name "distance");
* then fixes that optimum and maximises a tie-breaking objective to return one unique portfolio.

Consequences for your study:

* One call = one point of the frontier. The course loops over 41 levels to trace a curve (Lesson 8.9).
* Only **one** X set with **one** threshold exists, so the package yields exact **two-bundle** frontiers. The course gets the **three-bundle** frontier from a 5 % grid and checks the grid against the exact curves (Lesson 8.10: the grid never beats the exact curve; it falls short by ≈ 0.04–0.05 guaranteed-performance units on the placeholder data).
* Passing a bundle = passing all its indicator names as a vector. The bundle's performance is then that of its worst indicator in its worst scenario.
* `landUseRestriction` (new in 2.0.0) sets maximum shares per land use; not needed in the course.
* The Pareto feature is documented only in the help page and `NEWS.md`; there is no README example. The course code is therefore tested rather than copied from an example.

## 2. Things that can silently go wrong (and how the course guards against them)

| # | Finding | Evidence | Guard in the course |
|---|---|---|---|
| 1 | A misspelled `optimisticRule` (e.g. `"expectaton"`) does **not** stop `initScenario()`. It prints a message via `cat()`, leaves NA values in the scenario table, and `solveScenario()` still reports `status = "optimized"`. | ✔ tested | Lesson 6 check 2b + `anyNA` check in Lesson 7 |
| 2 | The default of `initScenario(fixDistance = )` is **3**, whereas the README examples use `NA`. With `3` the distances/performances are no longer interpretable as "% of the best achievable level" (README, section *The Use of fixDistance*). | ✔ `formals()` | We always pass `fixDistance` explicitly (default `NA` in `lesson06_inputs.R`) |
| 3 | `fixDistance` outside 0–10 is silently replaced by `NA` (only a warning). | source | Lesson 6 check 2b |
| 4 | Calling `calcPerformance()` on an object that already went through it prints "Error: No optimim found. Did you call solveScenario?" (misleading message) but still returns the object. | ✔ tested | Called once per object |
| 5 | Several internal consistency problems are only `cat("Error: …")` messages, not real errors (missing direction, failed attachment of values, NA in adjusted values). | source | Own `stopifnot()` checks |
| 6 | `solveScenario(lowerBound, upperBound)`: no explicit checks on the number/order of bounds. The order must equal the order of the land uses in the object. Impossible bounds (e.g. lower bounds summing to 3) or an unreachable `paretoMaxDistance` do not stop with an error: the function prints "No optimum found. Status code 2" and returns `status = "no optimum found"`. | ✔ tested | Fixed portfolios in the course are always built from `names(init$landUse)` |
| 7 | `initScenario()` builds column names such as `outcome<LandUse>`, `mean<LandUse>`, `sem<LandUse>`, `adjSem<LandUse>` and finds them with `startsWith()`/`contains("sem")` (case-insensitive). Unusual land-use names (spaces, names starting with `adj`, containing "sem") are a risk. The package's own example data work with spaces, but we use safe ids. | source | Short ids without spaces; labels only for figures |
| 8 | An indicator that is identical in all land uses gives a zero range (`diffAdjSem = 0`) and 0/0 = NaN. | source | Lesson 6 check + Lesson 7 check |

## 3. Documentation inconsistencies

* The package cites two different Gosling et al. (2020) papers: `DESCRIPTION` and the README literature list give *J. Environ. Manage.* 261:110248 ("A goal programming approach to evaluate agroforestry systems in Eastern Panama"), whereas the help pages of `calcPerformance()`, `dataPreparation()` and `exampleData()` give *Agroforestry Systems* 94 (doi 10.1007/s10457-020-00519-0, "Exploring farmer perceptions of agroforestry via multi-objective optimisation …"). Check which one you actually need to cite.
* Version 1.1.0 lists the method paper as "under review"; version 2.0.0 gives the published reference: Husmann et al. (2022), *Methods in Ecology and Evolution*, https://doi.org/10.1111/2041-210X.14000. Use `citation("optimLanduse")` for the package itself.
* The README code uses `geom_hline(size = 1)`, which newer ggplot2 versions flag as deprecated (`linewidth`). The course code uses `linewidth`.
* README Fig. 5 code selects columns `3:8` by position (works for 6 land uses; the course never does this).

## 4. What was tested (R 4.3.3, optimLanduse 2.0.0, dplyr 1.1.4, ggplot2 3.4.4, patchwork)

* The package reproduces the README result for the Gosling example (`u = 2`, `fixDistance = NA`): guaranteed performance 0.3868 (README: 0.387), silvopasture 59.8 %, forest 38.7 %.
* The complete course (`scripts/run_all.R`) runs without errors or warnings in about a minute with the placeholder data; also with `USE_STANDARD_ERROR = TRUE`, `GRID_STEP = 0.1`, `FIX_DISTANCE = 3`, `U_VALUE = 2`.
* Fast scoring = `calcPerformance()` to within 1e-8; fixed-bound `solveScenario()` agrees to within 1e-4 (checked every run).
* The grid frontier never beats the package's exact Pareto curve (checked every run).
* Not tested: other R / package versions (1.1.0 lacks the Pareto option; the course stops with a clear message), macOS/Windows.
