# Surselva land-use optimisation with *optimLanduse* – a 10-lesson course for R beginners

Goal: produce the Results section of your PhD article – a **Pareto frontier** for six land-use types (timber forest, protection forest, alpine pasture, biodiversity meadows, proforestation, natural regeneration of abandoned land) in Surselva, with three indicator bundles (economic: NPV + soil rent; ecological: deadwood + carbon sequestration + species richness; social: four stakeholder values from a 6-expert AHP survey).

**All numbers in this course are invented placeholders.** When your data arrive you replace the means and standard deviations in **one file** (`scripts/lesson06_inputs.R`) and re-run one command.

## Start here

1. Read `lessons/lesson01_getting_started.md` (install R + RStudio, open `surselva_course.Rproj`).
2. Work through the lessons in order. Each lesson has explanations and code with a line-by-line description. The code of each lesson is also in `scripts/` so you can run it directly.
3. At any time, `source("scripts/run_all.R")` runs the **entire analysis** and writes figures and tables to `output/`. (`example_output/` shows what it produces with the placeholder data.)

| # | Lesson | You learn |
|---|---|---|
| 1 | [Getting started](lessons/lesson01_getting_started.md) | install, RStudio, the big picture, glossary, **note on the missing Pareto function** |
| 2 | [R basics](lessons/lesson02_r_basics.md) | objects, vectors, functions, errors |
| 3 | [Tables and dplyr](lessons/lesson03_tables_and_dplyr.md) | matrices, data frames, mean/SD, wide → long format |
| 4 | [Figures with ggplot2](lessons/lesson04_ggplot2.md) | plots, colours, saving for journals |
| 5 | [The package: init → solve → performance](lessons/lesson05_optimlanduse_basics.md) | every argument, reproducing the package example |
| 6 | [Your data](lessons/lesson06_your_data.md) | **where to put your means and SDs**, automatic checks, AHP → mean/SD |
| 7 | [Robust optimisation](lessons/lesson07_robust_optimisation.md) | compromise and bundle optima, Figures R1–R2 |
| 8 | [Pareto frontier – engine](lessons/lesson08_pareto_engine.md) | dominance, grid of all mixes, validation, pay-off matrix |
| 9 | [Pareto frontier – figures](lessons/lesson09_pareto_figures.md) | Figures R3–R4, Table R2 |
| 10 | [Uncertainty and writing](lessons/lesson10_uncertainty_and_results.md) | Figures R5–R6, auto-written sentences, checklist, Methods wording |

Also read [`PACKAGE_NOTES.md`](PACKAGE_NOTES.md): what I found when reading every file of the package (including that the package has **no** Pareto-frontier function).

## Folder map

```
surselva_course/
├── surselva_course.Rproj      double-click to start
├── lessons/                   the 10 lessons
├── scripts/
│   ├── lesson06_inputs.R      <<< THE ONLY FILE YOU EDIT WITH YOUR DATA
│   ├── run_all.R              runs everything
│   └── lesson01.R … lesson10.R, lesson04_theme.R, lesson06_ahp_demo.R
├── example_output/            figures/tables made with the placeholder data
├── tools/build_course.py      (maintainers only) rebuilds scripts/ from the lessons
└── PACKAGE_NOTES.md
```

## Assumptions I made – please confirm

1. **"Pareto frontier"** = the non-dominated set of land-use compositions with respect to the *guaranteed performance* of the three bundles (worst indicator, worst uncertainty scenario). The package does not provide this; it is built on top of the package and checked against it (Lessons 1.1, 8).
2. **Social indicators**: AHP gives, per expert, a priority score for each land use under each of the four stakeholder values; mean and SD are taken across the 6 experts. If your AHP produced *weights of the four values* instead, the data structure needs to be discussed.
3. **Uncertainty = standard deviation** (as you said), with a switch to use the standard error (SD/√n).
4. All indicators are "more is better". "Proforestatio" is read as *proforestation*.
5. Main setting `u = 1`, `optimisticRule = "expectation"`, `fixDistance = NA`, 5 % grid (use 2.5 % for the final run).
6. The placeholder numbers are plausible-looking inventions, **not** Surselva data.

## Tested with

R 4.3.3, optimLanduse 1.1.0 (repository commit `0bbaa84`), dplyr 1.1.4, ggplot2 3.4.4, patchwork. The complete pipeline runs in about 35 seconds on the placeholder data.
