# Lesson 5 – Meeting *optimLanduse*: how the package thinks, with its own example

**Time:** about 2 hours  **You will learn:** the three package functions (`initScenario`, `solveScenario`, `calcPerformance`), what each argument means, how to read the results – by reproducing the published example (Gosling et al. 2020 farm data from Eastern Panama), whose answer is printed in the package README so you can check that your installation is correct.

---

## 5.1 The idea in plain words

You have several land uses and several indicators. Every land use is good at some indicators and bad at others. How should you split the land?

The package uses the **robust reference-point approach** (Knoke et al. 2016; Husmann et al.):

1. **Uncertainty.** Each mean has an uncertainty. For every indicator and every land use the package considers a "low" outcome (mean − u × uncertainty, for "more is better" indicators) and a "high" outcome (by default just the mean – `optimisticRule = "expectation"`).
2. **Scenarios.** It builds *every combination* of low/high outcomes across land uses. With 6 land uses that is 2⁶ = 64 scenarios **per indicator**; with 9 indicators, 9 × 64 = **576 scenarios**. This is the `scenarioTable`.
3. **Normalise.** Within each scenario, each land use's value is rescaled from 0 % (the worst land use in that scenario) to 100 % (the best). This puts NPV in francs and species richness in species on the same 0–100 % scale ("min–max normalisation"). The performance of a portfolio is the share-weighted average of these percentages.
4. **Max–min.** The optimiser finds the land-use split that makes the **worst** of all 576 scenario performances as good as possible. That worst value is called the **guaranteed performance** (1 − β). So *every* indicator, even in its worst-case scenario, reaches at least that percentage of its best possible level.

The result is a **robust compromise**: not the best for any single indicator, but the best "weakest link".

---

## 5.2 Load the packages and the example data

<!--run-->
```r
library(optimLanduse)
library(readxl)
library(dplyr)
library(tidyr)
library(ggplot2)

# Where is the example file stored on your computer?
path_example <- exampleData("exampleGosling.xlsx")

# Read the Excel file into a table
example_data <- read_excel(path_example)

# Look at the first rows
print(head(as.data.frame(example_data), 8))
```

**Explanation**

* `library(...)` loads a package for this session (do it at the start of every session).
* `exampleData("exampleGosling.xlsx")` is a function of the package: it returns the file path of the example file that ships with the package. (`exampleData("exampleEmpty.xlsx")` gives an empty template.)
* `read_excel(path)` reads an Excel sheet into a table (a *tibble*, a modern data frame).
* `head(x, 8)` shows the first 8 rows.

You see the **required format** – exactly the long table from Lesson 3:

| Column | Meaning |
|---|---|
| `indicatorGroup` | *(optional)* which bundle the indicator belongs to |
| `indicator` | name of the indicator |
| `direction` | `"more is better"` or `"less is better"` |
| `landUse` | name of the land-use option |
| `indicatorValue` | the mean |
| `indicatorUncertainty` | the uncertainty (SE or SD) |

Rules from the package's code (`initScenario`): the columns `indicator`, `direction`, `landUse`, `indicatorValue`, `indicatorUncertainty` **must** exist with exactly these spellings; **every indicator must be present for every land use**; each indicator–land-use combination must appear **once**. Other columns are dropped (with a warning), except `indicatorGroup`, which is allowed.

---

## 5.3 Step 1: `initScenario()` – set up the problem

<!--run-->
```r
example_init <- initScenario(coefTable      = example_data,
                             uValue         = 2,
                             optimisticRule = "expectation",
                             fixDistance    = NA)
```

| Argument | Meaning | Our choice |
|---|---|---|
| `coefTable` | The long table above. | `example_data` |
| `uValue` | The "caution dial": uncertainty is multiplied by this value. `0` = ignore uncertainty, `1` = one SD/SE, `2` = two, … Higher = more risk-averse. | `2` (as in the published example) |
| `optimisticRule` | How the *good* outcome of an indicator is defined. `"expectation"` = the mean itself (only downside risk is considered, the usual choice). `"uncertaintyAdjustedExpectation"` = mean **plus** u × uncertainty for "more is better". | `"expectation"` |
| `fixDistance` | Optional: use a *separate*, fixed u-value (0–10) for the normalisation. Default in the function is `3`. `NA` switches it off, so the same u is used everywhere. | `NA` |

**Why `fixDistance = NA`?** With `NA` the performance can be read as a straightforward *"percentage of the best achievable level"*. The package README states that with a separate `fixDistance` "the distances can no longer be straightforwardly interpreted as a degree of fulfilment". Because we want to report performances as percentages, we use `NA`. (If you prefer smoother transitions when varying u, you can set `FIX_DISTANCE <- 3` in Lesson 6; just do not interpret performances as percentages then.)

> Careful: the function's *default* is `fixDistance = 3`. If you forget to write `fixDistance = NA`, you silently get the default 3! We always write it out.

`initScenario()` returns an *object* (a list) with several parts. Peek inside:

<!--run-->
```r
print(names(example_init))
print(dim(example_init$scenarioTable))   # rows x columns of the scenario table
```

The most important parts: `scenarioTable` (all scenarios and the uncertainty-adjusted values `adjSem…`), `coefObjective` and `coefConstraint` (the maths passed to the solver), `landUse` (empty until solved) and `status`.

---

## 5.4 Step 2: `solveScenario()` – find the best compromise

<!--run-->
```r
example_result <- solveScenario(x = example_init)

print(example_result$status)           # "optimized"
print(example_result$beta)             # beta
print(round(example_result$landUse, 3))  # the land-use shares (they add up to 1)
```

* `solveScenario(x = ...)` takes the initialised object and runs the linear-programming solver `lpSolveAPI` repeatedly, narrowing down β step by step (a bisection search).
* `$beta` is β. The **guaranteed performance** is `1 - beta`.
* `$landUse` is the answer: shares between 0 and 1.

**Check against the README.** The package README reports a guaranteed performance of **0.387** (38.7 %) for these data with u = 2 and the farm composition dominated by silvopasture (≈ 60 %) and forest (≈ 39 %). You should see `beta` = 0.6132 and `1 - beta` = 0.3868. If so, your installation works exactly as the developers' does.

Optional arguments of `solveScenario()` (used later):

| Argument | Meaning |
|---|---|
| `digitsPrecision` | Number of decimals of β (default 4). More digits = more accurate, slightly slower. We use 6. |
| `lowerBound`, `upperBound` | Force minimum / maximum shares. Giving the **same** vector to both fixes a portfolio exactly (used in the README for the "current land use" and the pay-off matrix). |

---

## 5.5 Step 3: `calcPerformance()` – how well is each indicator served?

<!--run-->
```r
example_perf <- calcPerformance(example_result)

scen <- example_perf$scenarioTable
scen$performance_pct <- scen$performance * 100

# The guaranteed performance = the lowest performance of any scenario
print(round(min(scen$performance_pct), 1))      # 38.7
print(names(scen)[1:8])
```

`calcPerformance()` adds two columns to the scenario table: `portfolioPerformance` (the share-weighted value of the indicator in that scenario) and `performance` (0–1, the min–max normalised value = "percentage of the best achievable level").

> Run `calcPerformance()` **only once** per solved object. Running it a second time on the result prints an error message, because the object is already "updated".

Now the plot (the same idea as Fig. 3 in the package README): one row per indicator, one dot per scenario.

<!--run-->
```r
source("scripts/lesson04_theme.R")     # our colours and theme (from Lesson 4)

p_example <- ggplot(scen,
                    aes(x = performance_pct,
                        y = reorder(indicator, performance_pct, FUN = min))) +
  geom_point(alpha = 0.5, colour = "#2a78d6") +
  geom_vline(xintercept = min(scen$performance_pct),
             linetype = "dashed", colour = "#52514e") +
  scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, 20)) +
  labs(x = "Performance (% of best achievable level)", y = NULL,
       caption = "Package example data (Gosling et al. 2020), u = 2. Dashed line = guaranteed performance (1 - beta).") +
  theme_article()
print(p_example)
```

**How to read it.** Every dot is one scenario of one indicator. The dashed line is the guaranteed performance: the *lowest* dot. Indicators whose lowest dot sits exactly on the line (here: financial stability, investment costs, meeting household needs) are the ones that **define** the solution – the "bottleneck" indicators. The README discusses exactly this. In your own analysis, this plot tells you *which of your indicators drive the compromise*.

`reorder(indicator, performance_pct, FUN = min)` sorts the indicators on the y axis by their lowest performance; `geom_vline` draws the dashed line.

---

## 5.6 Step 4 (optional): a quick look at uncertainty

<!--run-->
```r
for (u in c(0, 1, 2)) {
  r <- solveScenario(initScenario(example_data, uValue = u,
                                  optimisticRule = "expectation", fixDistance = NA))
  cat("u =", u, " guaranteed performance =", round(1 - r$beta, 3), "\n")
}
```

* `for (u in c(0, 1, 2)) { ... }` repeats the code inside for each value of `u`.
* `cat(...)` prints text and numbers. `"\n"` starts a new line.

Higher `u` → more caution → the guaranteed performance falls (the worst case is worse).

---

## 5.7 Recap

| Function | Does | Returns |
|---|---|---|
| `initScenario()` | builds all scenarios from your table | an object (`status = "initialized"`) |
| `solveScenario()` | finds the best compromise | the same object with `$landUse` and `$beta` filled in |
| `calcPerformance()` | computes performance of every indicator in every scenario | the object with `performance` in `$scenarioTable` |

**What is missing for your paper?** (1) your own data, (2) bundles, and (3) the Pareto frontier. Lesson 6 prepares the data; Lessons 7–9 do the rest.
