# Lesson 6 – Your Surselva data: the ONE place where you type your numbers

**Time:** about 2 hours  **You will learn:** how your study is encoded (6 land uses, 9 indicators, 3 bundles), where to replace the placeholder means and standard deviations, how AHP expert scores become a mean and SD, how the code automatically checks your data, and how it builds the table the package needs.

> **The single most important rule of this course:** when your data arrive, you edit **only** the file `scripts/lesson06_inputs.R` (the block shown in 6.2) and then run `source("scripts/run_all.R")`. Everything else – optimisation, Pareto frontier, figures, tables, sentences – updates automatically.

---

## 6.1 How your study maps onto the package

| Your study | Package word | Our code name |
|---|---|---|
| 6 land uses | `landUse` | `land_use_ids` (short names without spaces) + `land_use_labels` (nice names for figures) |
| 9 indicators | `indicator` | `indicator_info$id` |
| 3 bundles | `indicatorGroup` | `indicator_info$bundle` |
| mean per land use & indicator | `indicatorValue` | matrix `means` |
| SD per land use & indicator | `indicatorUncertainty` | matrix `sds` |
| all indicators: "more is better" | `direction` | `indicator_info$direction` |

**Land uses** (the `land_use_ids`): `TimberForest`, `ProtectionForest`, `AlpinePasture`, `BiodivMeadow`, `ProForestation`, `NatRegeneration`.
(You wrote "proforestatio" – I assumed you mean *proforestation*: letting existing forests develop undisturbed. Change the label if I guessed wrong.)

**Why short names without spaces?** The package builds column names by gluing text together (e.g. `"adjSem"` + land-use name) and looks columns up by name. Names with spaces, or names that start with words the package uses internally (`mean`, `sem`, `adj`, `outcome`), can cause confusing errors. So the code uses safe IDs and translates them to readable labels (`land_use_labels`) only for figures and tables.

**Indicators and units** (placeholders – please replace/confirm):

| Bundle | Indicator ID | Meaning | Unit |
|---|---|---|---|
| Economic | `NPV` | net present value | CHF/ha |
| Economic | `SoilRent` | soil rent (soil expectation value) | CHF/ha/yr |
| Ecological | `Deadwood` | deadwood volume | m³/ha |
| Ecological | `CarbonSeq` | carbon sequestration | t CO₂/ha/yr |
| Ecological | `SpeciesRichness` | species richness | species per plot |
| Social | `LocalEconomy` | stakeholder value "local economy" | AHP priority (0–1) |
| Social | `CulturalLandscape` | "cultural landscape" | AHP priority (0–1) |
| Social | `BiodiversityValue` | "biodiversity" (the *stakeholder value*, not the measured species richness) | AHP priority (0–1) |
| Social | `WildlifeCoexistence` | "living with wildlife" | AHP priority (0–1) |

**Units do not have to match.** The package rescales every indicator to 0–100 % (Lesson 5), so CHF, m³ and AHP scores can sit in the same analysis. What matters is the *direction* and the *differences between land uses*.

---

## 6.2 THE FILE YOU EDIT: `scripts/lesson06_inputs.R`

Below is the complete file. Open it in RStudio, and when your real data arrive, replace the numbers in the two matrices `means` and `sds`. Each line is **one indicator**, in the order listed in `indicator_info`; each column is **one land use**, in the order of `land_use_ids`.

<!--run:lesson06_inputs.R-->
```r
# ==============================================================================
#  >>>  THE ONLY FILE YOU HAVE TO EDIT WHEN YOUR REAL DATA ARRIVE  <<<
#  All numbers below are INVENTED PLACEHOLDERS for testing the workflow.
# ==============================================================================

# ---- A. Is this still placeholder data? ---------------------------------------
# While TRUE, every figure carries a red warning caption. Set to FALSE once the
# means and SDs below are your REAL values.
DATA_ARE_PLACEHOLDERS <- TRUE

# ---- B. The six land uses -------------------------------------------------------
# ids: short, no spaces, no special characters (used inside the code)
land_use_ids    <- c("TimberForest", "ProtectionForest", "AlpinePasture",
                     "BiodivMeadow", "ProForestation",   "NatRegeneration")
# labels: nice names for figures and tables (same ORDER as the ids!)
land_use_labels <- c("Timber forest", "Protection forest", "Alpine pasture",
                     "Biodiversity meadows", "Proforestation", "Natural regeneration")

# ---- C. The nine indicators and their bundles -----------------------------------
indicator_info <- data.frame(
  id        = c("NPV", "SoilRent",
                "Deadwood", "CarbonSeq", "SpeciesRichness",
                "LocalEconomy", "CulturalLandscape", "BiodiversityValue", "WildlifeCoexistence"),
  label     = c("NPV", "Soil rent",
                "Deadwood", "Carbon sequestration", "Species richness",
                "Local economy", "Cultural landscape", "Biodiversity (value)", "Living with wildlife"),
  bundle    = c("Economic", "Economic",
                "Ecological", "Ecological", "Ecological",
                "Social", "Social", "Social", "Social"),
  direction = rep("more is better", 9),    # use "less is better" for costs etc.
  stringsAsFactors = FALSE
)

# ---- D. THE MEANS (one row per indicator, one column per land use) ---------------
#                       Timber  Protect  Pasture  Meadow  ProFor  NatReg
means <- matrix(c(
  # --- Economic ---
                        4500,   1500,    2800,    900,    -300,   200,     # NPV (CHF/ha)
                          60,     15,      95,     35,       0,    10,     # SoilRent (CHF/ha/yr)
  # --- Ecological ---
                           8,     20,       1,      2,      45,    25,     # Deadwood (m3/ha)
                         6.0,    5.0,     0.5,    0.8,     7.5,   4.0,     # CarbonSeq (t CO2/ha/yr)
                          35,     42,      48,     68,      55,    60,     # SpeciesRichness (species/plot)
  # --- Social (AHP priorities from the 6 experts; each row sums to 1) ---
                        0.30,   0.12,    0.30,   0.12,    0.06,  0.10,     # LocalEconomy
                        0.12,   0.10,    0.35,   0.28,    0.05,  0.10,     # CulturalLandscape
                        0.06,   0.16,    0.10,   0.28,    0.22,  0.18,     # BiodiversityValue
                        0.20,   0.20,    0.25,   0.15,    0.08,  0.12      # WildlifeCoexistence
  ), nrow = 9, byrow = TRUE,
  dimnames = list(indicator_info$id, land_use_ids))

# ---- E. THE STANDARD DEVIATIONS (same layout as the means!) ----------------------
#                       Timber  Protect  Pasture  Meadow  ProFor  NatReg
sds <- matrix(c(
  # --- Economic ---
                         600,    300,     500,     250,    150,    150,     # NPV
                          12,      5,      15,       8,      3,      4,     # SoilRent
  # --- Ecological ---
                           2,      4,     0.5,     0.8,      8,      6,     # Deadwood
                         0.8,    0.7,     0.2,     0.3,    1.2,    0.9,     # CarbonSeq
                           4,      5,       5,       7,      6,      7,     # SpeciesRichness
  # --- Social ---
                        0.04,   0.03,    0.05,    0.03,   0.02,   0.03,     # LocalEconomy
                        0.03,   0.03,    0.05,    0.05,   0.02,   0.03,     # CulturalLandscape
                        0.02,   0.04,    0.03,    0.06,   0.05,   0.04,     # BiodiversityValue
                        0.05,   0.05,    0.06,    0.04,   0.03,   0.04      # WildlifeCoexistence
  ), nrow = 9, byrow = TRUE,
  dimnames = list(indicator_info$id, land_use_ids))

# ---- F. Is your uncertainty a standard deviation or a standard error? ------------
# FALSE = the numbers in "sds" are used as they are (standard deviations).
# TRUE  = "sds" are divided by sqrt(n) first (turning SDs into standard errors).
USE_STANDARD_ERROR <- FALSE
# Number of observations behind each indicator (same order as indicator_info).
# Only used when USE_STANDARD_ERROR <- TRUE. Social indicators: 6 experts.
N_OBS <- c(NA, NA, NA, NA, NA, 6, 6, 6, 6)

# ---- G. Model settings (see Lesson 5.3 and 7.1) ---------------------------------
U_VALUE         <- 1                  # caution dial for the main analysis
OPTIMISTIC_RULE <- "expectation"      # or "uncertaintyAdjustedExpectation"
FIX_DISTANCE    <- NA                 # NA = off (recommended, see Lesson 5.3)
DIGITS          <- 6                  # precision of the optimisation (decimals of beta)

# ---- H. Settings for the Pareto frontier and sensitivity (Lessons 8-10) --------
GRID_STEP <- 0.05                     # 0.05 = test every mix in 5 % steps (53,130 mixes)
U_SWEEP   <- seq(0, 3, by = 0.5)      # u-values for the sensitivity figure (Lesson 10)
U_COMPARE <- c(0, 1, 2)               # u-values for the frontier comparison (Lesson 10)
```

### How to edit

* **Only change the numbers.** Keep the commas, keep the line order, keep one row per indicator.
* **Do not** add or delete rows/columns unless your design changes. (If you do change the indicators or land uses, update `land_use_ids`, `land_use_labels` and `indicator_info`, and make sure the matrices have the right number of rows/columns – the checks in 6.3 will tell you if not.)
* Nothing else in the course folder contains your data.
* The matrix is filled `byrow = TRUE`, so the numbers are read in reading order: left to right, line by line. That is why 9 lines × 6 numbers = 54 numbers.
* When done, set `DATA_ARE_PLACEHOLDERS <- FALSE`.

**What the settings mean**

| Setting | Meaning |
|---|---|
| `U_VALUE` | the caution dial for the *main* results (1 = one SD below the mean for the pessimistic outcome). |
| `GRID_STEP` | fineness of the search for the Pareto frontier. `0.05` is quick (≈ 1–3 min). `0.025` gives a smoother frontier (1.2 million mixes, 20–60 min; only for the final version). It must divide 1 exactly (0.1, 0.05, 0.025, 0.02, 0.01…). |
| `DIGITS` | decimals of β in `solveScenario(digitsPrecision = …)`. 6 is more precise than the default 4 and still fast. |

### Standard deviation or standard error? (decide with your supervisor)

The package multiplies "uncertainty" by `u`. With **SD**, `u = 1` means "one standard deviation below the mean" – a statement about the spread between individual observations/experts. With **SE** (SD ÷ √n) the uncertainty is the precision of the *mean*, typically much smaller. The package's own example (Gosling et al. 2020) used the SE across survey respondents. Both are legitimate; they just describe different uncertainty. Set `USE_STANDARD_ERROR` accordingly, and report it.

---

## 6.3 Checks that protect you from silly mistakes

Now `scripts/lesson06.R`. It does not change your numbers; it only **stops with a clear message** if something is wrong.

<!--run-->
```r
library(dplyr)
library(tidyr)

# ---- 1. Do the dimensions and names fit together? ---------------------------
stopifnot(
  "`land_use_ids` and `land_use_labels` must have the same length" =
    length(land_use_ids) == length(land_use_labels),
  "`means` must have one row per indicator and one column per land use" =
    identical(dim(means), c(nrow(indicator_info), length(land_use_ids))),
  "`sds` must have the same size as `means`" =
    identical(dim(sds), dim(means)),
  "Row names of `means` must equal indicator_info$id (same order)" =
    identical(rownames(means), indicator_info$id),
  "Column names of `means` must equal land_use_ids (same order)" =
    identical(colnames(means), land_use_ids),
  "Row/column names of `sds` must equal those of `means`" =
    identical(dimnames(sds), dimnames(means))
)

# ---- 2. Are the numbers valid? ---------------------------------------------------
if (anyNA(means) || anyNA(sds))
  stop("There are missing values (NA) in `means` or `sds`. The package needs a value for every indicator x land use.")
if (any(sds < 0))
  stop("Uncertainties (`sds`) cannot be negative.")
if (!all(indicator_info$direction %in% c("more is better", "less is better")))
  stop('`direction` must be exactly "more is better" or "less is better".')

# An indicator that is identical in all land uses cannot be normalised (0 / 0)
no_variation <- apply(means, 1, function(x) max(x) - min(x) == 0)
if (any(no_variation))
  stop("These indicators have identical means in all land uses: ",
       paste(rownames(means)[no_variation], collapse = ", "))

# ---- 2b. Are the model settings valid? (the package itself only prints a message for typos!) ----
if (!OPTIMISTIC_RULE %in% c("expectation", "uncertaintyAdjustedExpectation"))
  stop('OPTIMISTIC_RULE must be exactly "expectation" or "uncertaintyAdjustedExpectation".')
if (!is.na(FIX_DISTANCE) && (FIX_DISTANCE < 0 || FIX_DISTANCE > 10))
  stop("FIX_DISTANCE must be NA or a number between 0 and 10.")
if (U_VALUE < 0) stop("U_VALUE cannot be negative.")
if (1 / GRID_STEP != round(1 / GRID_STEP)) stop("GRID_STEP must divide 1 exactly (e.g. 0.1, 0.05, 0.025).")

# ---- 3. Standard error instead of standard deviation? ------------------------------
if (USE_STANDARD_ERROR) {
  if (anyNA(N_OBS)) stop("USE_STANDARD_ERROR is TRUE, so N_OBS needs a number for every indicator.")
  sds_used <- sds / sqrt(N_OBS)      # divides each ROW by the square root of its n
} else {
  sds_used <- sds
}

# ---- 4. Soft check for AHP indicators: do priorities sum to ~1 per indicator? -----
social_ids <- indicator_info$id[indicator_info$bundle == "Social"]
row_sums <- rowSums(means[social_ids, , drop = FALSE])
if (any(abs(row_sums - 1) > 0.05))
  message("Note: the social (AHP) means of these indicators do not sum to 1 across land uses: ",
          paste(names(row_sums)[abs(row_sums - 1) > 0.05], collapse = ", "),
          ". That is fine if your AHP scores are scaled differently.")

message("Data checks passed: ", nrow(means), " indicators x ", ncol(means), " land uses.")
```

**Explanation**

* `stopifnot("message" = condition, ...)` stops the script with *your message* if a condition is `FALSE`. (R 4.0 or newer.)
* `identical(a, b)` is `TRUE` only if `a` and `b` are exactly the same.
* `anyNA(x)` – any missing values? `any(sds < 0)` – any negative SD?
* `apply(means, 1, function(x) ...)` applies a function to every **row** (`1` = rows, `2` = columns). Here: `max(x) - min(x) == 0` means "all land uses have the same mean". Such an indicator would produce 0/0 inside the package, so we stop early.
* `sds / sqrt(N_OBS)` – a matrix divided by a vector of length 9 divides each **row** by its own value.
* The settings check (2b) exists because *optimLanduse* does not stop on a misspelled `optimisticRule`: it only prints a message and carries on with missing values (we tested this).
* The AHP check is only a *message* (not an error) because your AHP scaling may differ.

---

## 6.4 Build the table in the package's format

<!--run-->
```r
# Wide -> long, for the means
means_long <- as.data.frame(means) %>%
  mutate(indicator = rownames(means)) %>%
  pivot_longer(cols = -indicator, names_to = "landUse", values_to = "indicatorValue")

# Wide -> long, for the uncertainties
sds_long <- as.data.frame(sds_used) %>%
  mutate(indicator = rownames(sds_used)) %>%
  pivot_longer(cols = -indicator, names_to = "landUse", values_to = "indicatorUncertainty")

# Join: means + uncertainties + direction + bundle
coef_table <- means_long %>%
  left_join(sds_long, by = c("indicator", "landUse")) %>%
  left_join(indicator_info[, c("id", "direction", "bundle")],
            by = c("indicator" = "id")) %>%
  rename(indicatorGroup = bundle) %>%                         # the package's name for "bundle"
  select(indicatorGroup, indicator, direction, landUse,
         indicatorValue, indicatorUncertainty) %>%
  as.data.frame()

# Final safety checks
stopifnot(nrow(coef_table) == nrow(means) * ncol(means),
          !anyNA(coef_table))

# A note that is added to every figure as long as the data are placeholders
data_note <- if (DATA_ARE_PLACEHOLDERS) "PLACEHOLDER DATA - not real results" else NULL
if (DATA_ARE_PLACEHOLDERS) message("REMINDER: DATA_ARE_PLACEHOLDERS is TRUE - figures are for testing only.")

# The course code is written for exactly these three bundles
stopifnot("indicator_info$bundle must only contain Economic, Ecological and Social" =
            setequal(unique(indicator_info$bundle), c("Economic", "Ecological", "Social")))
bundle_names <- c("Economic", "Ecological", "Social")

print(head(coef_table, 10))
```

**Explanation**

* `as.data.frame(means)` turns the matrix into a table; `mutate(indicator = rownames(means))` adds the row names as a proper column; `pivot_longer()` makes it long (Lesson 3).
* `left_join(indicator_info[, c("id", "direction", "bundle")], by = c("indicator" = "id"))` attaches `direction` and `bundle`; the join links the column `indicator` (left table) to `id` (right table).
* `rename(indicatorGroup = bundle)` – the package accepts an optional column named `indicatorGroup`.
* `select(...)` puts columns in the same order as the package's example file.
* `nrow(coef_table)` must be 9 × 6 = **54**.
* `data_note` is the red warning text for the figures.
* `bundle_names` fixes the order of the three bundles used everywhere later. The check makes sure every indicator is assigned to one of them.

The result, `coef_table`, is the object that you hand to `initScenario()`.

---

## 6.5 From 6 experts' raw AHP answers to a mean and SD (optional but useful)

Your social data come from 6 experts. This section shows how to get from the **raw** expert numbers to the means and SDs that go into the matrices. It uses **simulated** expert answers (invented!), so you can see the mechanics now and re-use the function with your real survey file later.

**What you need from AHP:** for each expert *e*, each stakeholder value *v* (local economy, …) and each land use *l*, a **priority score** (a number between 0 and 1; for one expert and one value, the scores of the six land uses add up to 1). Many AHP tools (e.g. Excel templates, `ahpsurvey`, Expert Choice, BPMSG) output exactly this. Check the **consistency ratio** of each expert's comparisons (a common rule: CR < 0.1) before using the scores, and report how you handled inconsistent experts.

If your AHP produced *weights of the four values* instead (a single set of four weights per expert) and land-use scores come from elsewhere, tell your supervisor – the data structure here would then be different. This course assumes the former.

<!--run:lesson06_ahp_demo.R-->
```r
library(dplyr)

# A function that turns raw expert scores into the `means` and `sds` matrices
# raw must have the columns: expert, indicator, landUse, score
scores_to_matrices <- function(raw, indicator_ids, land_use_ids) {
  summary_tab <- raw %>%
    group_by(indicator, landUse) %>%
    summarise(m = mean(score), s = sd(score), n = n(), .groups = "drop")

  to_matrix <- function(column) {
    mat <- tapply(summary_tab[[column]],
                  list(summary_tab$indicator, summary_tab$landUse), identity)
    mat[indicator_ids, land_use_ids, drop = FALSE]     # put rows/columns in OUR order
  }
  list(means = to_matrix("m"), sds = to_matrix("s"), n = to_matrix("n"))
}

# ---- DEMO with simulated experts (replace `expert_scores` by your survey data) ---
set.seed(2024)                                     # makes the "random" numbers reproducible
demo_ids <- c("LocalEconomy", "CulturalLandscape", "BiodiversityValue", "WildlifeCoexistence")

expert_scores <- expand.grid(expert    = paste0("Expert", 1:6),
                             indicator = demo_ids,
                             landUse   = land_use_ids,
                             stringsAsFactors = FALSE)

# Simulate: placeholder mean + random noise, never below 0.001
true_mean <- means[cbind(expert_scores$indicator, expert_scores$landUse)]
expert_scores$score <- pmax(0.001, rnorm(nrow(expert_scores), mean = true_mean, sd = 0.04))

demo <- scores_to_matrices(expert_scores, demo_ids, land_use_ids)
print(round(demo$means, 3))      # would go into `means[demo_ids, ]`
print(round(demo$sds, 3))        # would go into `sds[demo_ids, ]`
stopifnot(identical(dim(demo$means), c(4L, 6L)))
```

**Explanation**

* `expand.grid(...)` creates every combination of experts × indicators × land uses (6 × 4 × 6 = 144 rows) – the shape of a raw survey table in long format.
* `means[cbind(rows, cols)]` picks cells by pairs of names (a "coordinate list").
* `rnorm(n, mean, sd)` draws random numbers; `set.seed()` fixes them so the demo always gives the same numbers. **Your real analysis contains no random numbers.**
* `group_by(indicator, landUse) %>% summarise(...)` computes mean and SD over the 6 experts for each indicator × land-use cell.
* `tapply(values, list(rows, cols), identity)` re-arranges those summaries into a matrix; the last line puts rows and columns in the order the course needs.
* **To use with real data:** read your survey (`raw <- read.csv("my_ahp_scores.csv")`, with columns `expert, indicator, landUse, score` and the same ids), call `scores_to_matrices(raw, demo_ids, land_use_ids)`, then copy the printed numbers into the social rows of `means` and `sds` in `lesson06_inputs.R`.

---

## 6.6 Practice

1. In `lesson06_inputs.R`, change the NPV of timber forest to 6000, run Lessons 6.3 and 6.4 again and check `coef_table`.
2. Deliberately set one standard deviation to `-1` and see the error message. Then undo it.
3. Delete one number from a row and run the check – R complains that the matrix size does not fit.

**Next:** Lesson 7 – the robust optimisation with your data, bundle by bundle.
