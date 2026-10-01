# Notes from a careful read of the *optimLanduse* repository

Everything below comes from reading all R files (`initScenario.R`, `solveScenario.R`, `calcPerformance.R`, `dataPreparation.R`, `helper.R`, `examples.R`), `NEWS.md`, `DESCRIPTION`, `NAMESPACE`, `README.Rmd` and the help pages, and from running the package (R 4.3.3, package version 1.1.0, repository commit `0bbaa84`). Items marked ✔ were reproduced by running code; the others are read from the source.

## 1. Where is the Pareto frontier?

* The word "Pareto" does not occur anywhere in the repository. `NEWS.md` contains only the version history (0.0.4 → 1.0.0 → 1.1.0) and no code.
* The package computes **one** robust compromise portfolio (maximin of the normalised performance over all uncertainty scenarios). Related analyses in the README: sensitivity to `u`, indicator bundles, a pay-off matrix, and "current vs optimal" comparison via equal lower/upper bounds.
* The Pareto frontier in this course is therefore **our own extension** (Lessons 8–9): grid of all compositions → scores from the package's scenario table → non-dominated filter. Its scoring was verified against `calcPerformance()` and `solveScenario()` inside the course code, and the grid optimum is compared with the package's exact single-bundle optimum.

## 2. Things that can silently go wrong (and how the course guards against them)

| # | Finding | Evidence | Guard in the course |
|---|---|---|---|
| 1 | A misspelled `optimisticRule` (e.g. `"expectaton"`) does **not** stop `initScenario()`. It prints a message via `cat()`, leaves NA values in the scenario table, and `solveScenario()` still reports `status = "optimized"`. | ✔ tested | Lesson 6 check 2b + `anyNA` check in Lesson 7 |
| 2 | The default of `initScenario(fixDistance = )` is **3**, whereas the README examples use `NA`. With `3` the distances/performances are no longer interpretable as "% of the best achievable level" (README, section *The Use of fixDistance*). | ✔ `formals()` | We always pass `fixDistance` explicitly (default `NA` in `lesson06_inputs.R`) |
| 3 | `fixDistance` outside 0–10 is silently replaced by `NA` (only a warning). | source | Lesson 6 check 2b |
| 4 | Calling `calcPerformance()` on an object that already went through it prints "Error: No optimim found. Did you call solveScenario?" (misleading message) but still returns the object. | ✔ tested | Called once per object |
| 5 | Several internal consistency problems are only `cat("Error: …")` messages, not real errors (missing direction, failed attachment of values, NA in adjusted values). | source | Own `stopifnot()` checks |
| 6 | `solveScenario(lowerBound, upperBound)`: the code has `tbd` comments – no checks on the number/order of bounds or on whether lower bounds sum to > 1. The order must equal the order of the land uses in the object. | source | Fixed portfolios in the course are always built from `names(init$landUse)` |
| 7 | `initScenario()` builds column names such as `outcome<LandUse>`, `mean<LandUse>`, `sem<LandUse>`, `adjSem<LandUse>` and finds them with `startsWith()`/`contains("sem")` (case-insensitive). Unusual land-use names (spaces, names starting with `adj`, containing "sem") are a risk. The package's own example data work with spaces, but we use safe ids. | source | Short ids without spaces; labels only for figures |
| 8 | An indicator that is identical in all land uses gives a zero range (`diffAdjSem = 0`) and 0/0 = NaN. | source | Lesson 6 check + Lesson 7 check |

## 3. Documentation inconsistencies

* The package cites two different Gosling et al. (2020) papers: `DESCRIPTION` and the README literature list give *J. Environ. Manage.* 261:110248 ("A goal programming approach to evaluate agroforestry systems in Eastern Panama"), whereas the help pages of `calcPerformance()`, `dataPreparation()` and `exampleData()` give *Agroforestry Systems* 94 (doi 10.1007/s10457-020-00519-0, "Exploring farmer perceptions of agroforestry via multi-objective optimisation …"). Check which one you actually need to cite.
* The method paper is listed as "under review" (*Methods in Ecology and Evolution*); look up the published reference and use `citation("optimLanduse")`.
* The README code uses `geom_hline(size = 1)`, which newer ggplot2 versions flag as deprecated (`linewidth`). The course code uses `linewidth`.
* README Fig. 5 code selects columns `3:8` by position (works for 6 land uses; the course never does this).

## 4. What was tested (R 4.3.3, dplyr 1.1.4, tidyr, ggplot2 3.4.4, patchwork)

* The package reproduces the README result for the Gosling example (`u = 2`, `fixDistance = NA`): guaranteed performance 0.3868 (README: 0.387), silvopasture 59.8 %, forest 38.7 %.
* The complete course (`scripts/run_all.R`) runs without errors or warnings in ≈ 35 s with the placeholder data; also with `USE_STANDARD_ERROR = TRUE`, `GRID_STEP = 0.1`, `FIX_DISTANCE = 3`, `U_VALUE = 2`.
* Fast scoring = `calcPerformance()` to within 1e-8; fixed-bound `solveScenario()` agrees to within 1e-4 (checked every run).
* Not tested: other R / package versions, macOS/Windows (the code uses only portable functions and `file.path()`).
