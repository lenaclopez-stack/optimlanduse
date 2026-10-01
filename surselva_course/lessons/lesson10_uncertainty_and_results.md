# Lesson 10 – Uncertainty, final outputs, and writing the Results section

**Time:** about 2.5 hours  **You will learn:** how the caution level `u` changes the compromise (Figure R5) and the Pareto frontier (Figure R6), how to let R write the number-filled sentences for your text, how to export everything, and exactly what to do on the day your real data arrive.

Requirements: Lessons 6–9 run in this session (`run_all.R` with `UP_TO_LESSON <- 9`).

---

## 10.1 Figure R5 – the compromise under rising uncertainty

We repeat the optimisation for several `u` values (`U_SWEEP` in `lesson06_inputs.R`, default 0, 0.5, … 3). This is the sensitivity analysis used in the package README (Fig. 5 there).

<!--run-->
```r
sweep_df <- bind_rows(lapply(U_SWEEP, function(u) {
  init_u <- initScenario(coefTable = coef_table, uValue = u,
                         optimisticRule = OPTIMISTIC_RULE, fixDistance = FIX_DISTANCE)
  res_u  <- solveScenario(x = init_u, digitsPrecision = DIGITS)
  stopifnot(res_u$status == "optimized")
  data.frame(u = u, guaranteed = 1 - res_u$beta, res_u$landUse)
}))
print(round(sweep_df, 3))

sweep_long <- sweep_df %>%
  pivot_longer(cols = all_of(land_use_ids), names_to = "landUse", values_to = "share") %>%
  mutate(landUse = factor(landUse, levels = land_use_ids, labels = land_use_labels),
         share   = share * 100)

fig_r5 <- ggplot(sweep_long, aes(x = u, y = share, fill = landUse)) +
  geom_area(colour = "white", linewidth = 0.3) +
  scale_fill_manual(values = setNames(land_use_palette, land_use_labels)) +
  scale_x_continuous(breaks = U_SWEEP, expand = c(0, 0)) +
  scale_y_continuous(breaks = seq(0, 100, 20), expand = c(0, 0)) +
  labs(x = "Uncertainty level u (higher = more risk-averse)",
       y = "Share of land in the compromise portfolio (%)", fill = NULL, caption = data_note) +
  guides(fill = guide_legend(nrow = 2)) +
  theme_article()

print(fig_r5)
save_figure(fig_r5, "fig_R5_compromise_vs_uncertainty", width = 16, height = 10)

write.csv(round(sweep_df, 4), file.path("output", "tables", "table_R3_compromise_vs_u.csv"),
          row.names = FALSE)
```

**Explanation**

* `lapply(U_SWEEP, function(u) {...})` runs the full init → solve cycle for every `u` and returns a list of one-row tables; `bind_rows()` stacks them.
* `data.frame(u = u, guaranteed = 1 - res_u$beta, res_u$landUse)` – one row: the u-value, the guaranteed performance, and the six shares.
* `geom_area()` – a stacked area chart; the x axis is `u`.
* **How to read it:** at `u = 0` the optimiser ignores uncertainty. As `u` grows, land uses with **large SDs relative to their advantage** lose share, while land uses with reliable (low-SD) contributions gain. If the mix hardly changes, your result is robust to the choice of `u`. Note the column `guaranteed` in the table: it falls as `u` rises.

## 10.2 Figure R6 – how the Pareto frontier moves with uncertainty

<!--run-->
```r
pair_cmp <- bundle_names[1:2]            # which two bundles to show (default: Economic vs Ecological)
third_cmp <- setdiff(bundle_names, pair_cmp)

compare_fronts <- bind_rows(lapply(U_COMPARE, function(u) {
  init_u <- initScenario(coefTable = coef_table, uValue = u,
                         optimisticRule = OPTIMISTIC_RULE, fixDistance = FIX_DISTANCE)
  f <- native_pair_frontier(init_u, pair_cmp[1], pair_cmp[2], third_cmp)   # exact, package Pareto option
  data.frame(u = u, x = f$x, y = f$y)
}))

u_cols <- colorRampPalette(c("#7fb0ea", "#123f78"))(length(U_COMPARE))

fig_r6 <- ggplot(compare_fronts, aes(x = x, y = y, colour = factor(u), group = u)) +
  geom_line(linewidth = 0.8) +
  scale_colour_manual(values = u_cols, name = "Uncertainty level u") +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1)) +
  labs(x = paste(pair_cmp[1], "bundle: guaranteed performance"),
       y = paste(pair_cmp[2], "bundle: guaranteed performance"), caption = data_note) +
  theme_article() +
  theme(aspect.ratio = 1)

print(fig_r6)
save_figure(fig_r6, "fig_R6_frontier_vs_uncertainty", width = 12, height = 12)
```

**Explanation**

* For each `u` we initialise a *new* object (the uncertainty-adjusted values change with `u`) and trace the exact two-bundle frontier with `native_pair_frontier()` from Lesson 8.9, i.e. with the package's Pareto option.
* `colorRampPalette(c(light, dark))(n)` makes `n` shades between two colours (one-hue light→dark = more uncertainty).
* **Important for interpretation:** the performance at each `u` is relative to the best and worst achievable *at that u*. Frontiers therefore show how the *trade-off shape* changes, not that "everything gets worse in absolute terms". With larger `u`, frontiers typically move towards the lower left (guaranteed performances fall) and portfolios become more diversified.
* To compare another pair, change `pair_cmp <- bundle_names[c(1, 3)]` (Economic vs Social) or `[2:3]` (Ecological vs Social).

---

## 10.3 Let R write your Results sentences

The next block turns the numbers into ready-to-edit sentences saved in `output/results_sentences.txt`. The numbers update automatically when the data change. **Always read and adapt the sentences – they are a starting point, not a final text.**

<!--run-->
```r
pct <- function(x, digits = 0) paste0(formatC(100 * x, format = "f", digits = digits), "%")

# --- ingredients -------------------------------------------------------------------
comp <- unlist(selected[selected$portfolio == "Compromise (all indicators)", land_use_ids])
comp <- sort(comp, decreasing = TRUE)
comp_lab <- land_use_labels[match(names(comp), land_use_ids)]
used <- comp > 0.005                          # land uses with at least 0.5 %
comp_text <- paste0(comp_lab[used], " (", pct(comp[used]), ")", collapse = ", ")
unused_text <- if (any(!used)) paste(comp_lab[!used], collapse = ", ") else "none"

guaranteed <- 1 - result_all$beta
bottleneck_names <- as.character(bottleneck$indicator[bottleneck$lowest_pct <=
                                                        min(bottleneck$lowest_pct) + 0.5])

own <- diag(as.matrix(payoff[1:3, bundle_names]))       # each bundle's own optimum
comp_vs_own <- as.numeric(anchor_perf[4, ]) / own        # compromise as share of own optimum
names(comp_vs_own) <- bundle_names

n_front <- nrow(frontier)

sentences <- c(
  if (DATA_ARE_PLACEHOLDERS) "*** WARNING: these numbers come from PLACEHOLDER data and must not be used in the manuscript. ***" else NULL,
  "",
  "-- Robust compromise portfolio --",
  sprintf("The robust compromise portfolio (u = %s) allocated land to: %s. No land was allocated to: %s.",
          U_VALUE, comp_text, unused_text),
  sprintf("Its guaranteed performance was %s: even in the worst uncertainty scenario, every indicator reached at least %s of its best achievable level.",
          pct(guaranteed, 1), pct(guaranteed, 1)),
  sprintf("The compromise was limited by: %s.", paste(bottleneck_names, collapse = ", ")),
  "",
  "-- Single-bundle optima and trade-offs --",
  sprintf("Optimising for the %s bundle alone gave that bundle a guaranteed performance of %s; the compromise reached %s of this value (%s).",
          bundle_names, pct(own, 1), pct(comp_vs_own), pct(anchor_perf[4, ], 1)),
  "",
  "-- Pareto frontier --",
  sprintf("Of %s land-use mixes evaluated on a %s%% grid, %s were Pareto-efficient with respect to the %s, %s and %s bundles.",
          format(nrow(grid_w), big.mark = ","), GRID_STEP * 100, format(n_front, big.mark = ","),
          bundle_names[1], bundle_names[2], bundle_names[3]),
  sprintf("Along the frontier the share of %s ranged from %s to %s.",
          frontier_summary$`Land use`, paste0(frontier_summary$`Min share (%)`, "%"),
          paste0(frontier_summary$`Max share (%)`, "%")),
  "",
  "-- Sensitivity to uncertainty --",
  sprintf("Raising u from %s to %s reduced the guaranteed performance of the compromise from %s to %s.",
          min(sweep_df$u), max(sweep_df$u),
          pct(sweep_df$guaranteed[which.min(sweep_df$u)], 1),
          pct(sweep_df$guaranteed[which.max(sweep_df$u)], 1))
)

writeLines(sentences, file.path("output", "results_sentences.txt"))
cat(sentences, sep = "\n")
```

**Explanation**

* `sprintf("... %s ...", value)` fills the `%s` spots with values (a *template*). `sprintf` is vectorised: if `value` has six elements you get six sentences.
* `formatC(100 * x, format = "f", digits = 0)` formats a number with a fixed number of decimals.
* `sort(comp, decreasing = TRUE)` orders the shares from largest to smallest.
* `diag(...)` takes the diagonal of the pay-off matrix = each bundle's own optimum.
* `writeLines(text, file)` saves the sentences into a text file.

## 10.4 Save the record of what you did (for reproducibility)

<!--run-->
```r
writeLines(capture.output(sessionInfo()), file.path("output", "session_info.txt"))

cat("\nFiles created:\n")
print(list.files("output", recursive = TRUE))
```

`sessionInfo()` lists your R version and all package versions. Keep this file with the results and mention the versions of R and *optimLanduse* in the Methods.

---

## 10.5 The day your real data arrive – checklist

1. Open `scripts/lesson06_inputs.R`.
2. Check (and edit if needed) the **names** of land uses and indicators and the **bundle** assignment.
3. Replace the numbers in `means` and `sds`, line by line. Keep the same order of indicators and land uses.
4. Decide SD vs SE (`USE_STANDARD_ERROR`) and set `N_OBS` if needed.
5. For the social indicators: if you have the raw expert scores, use `scores_to_matrices()` (Lesson 6.5).
6. Set `DATA_ARE_PLACEHOLDERS <- FALSE`.
7. Choose `U_VALUE` (main) and `U_SWEEP` / `U_COMPARE` (sensitivity).
8. Run `source("scripts/run_all.R")`. Fix anything the checks complain about.
9. For the final version set `GRID_STEP <- 0.025` (slower), run again, and keep the `output` folder.
10. Delete or move the old `example_output/` so placeholder figures cannot be mixed up with real ones.

## 10.6 Suggested structure of your Results section

| Sub-section | Figure / Table | What to say |
|---|---|---|
| 3.1 Indicator values | a table of your means ± SD (from the `means`/`sds` matrices) | which land use is best/worst per indicator; where uncertainty is large |
| 3.2 Robust compromise | Fig. R1 (the "Compromise" bar), Fig. R2 | composition, guaranteed performance, bottleneck indicators |
| 3.3 Bundle optima & trade-offs | Fig. R1 (all bars), Table R1 (pay-off matrix) | what each bundle wants alone, and the cost to the others |
| 3.4 Pareto frontier | Fig. R3, Fig. R4, Table R2 | shape of the trade-off, synergies, which land uses are "frontier land uses" |
| 3.5 Sensitivity to uncertainty | Fig. R5, Fig. R6, Table R3 | stability of the results to `u` |

**Methods wording (adapt!).**
*"Land-use compositions were optimised with the R package optimLanduse (Husmann et al. 2022; version 2.0.0), which implements the robust multi-objective approach of Knoke et al. (2016). For each land use and indicator, the mean and the standard deviation were entered; uncertainty-adjusted outcomes were calculated as mean ∓ u × SD, with u = … The performance of a composition is the share of the best achievable level of an indicator (min–max scaled); the guaranteed performance of a bundle is the lowest performance of any of its indicators in any uncertainty scenario. Pairwise Pareto frontiers between bundles were computed with the Pareto option of solveScenario() (epsilon-constraint method: maximising the guaranteed performance of one bundle while the guaranteed performance of another bundle is held at or above a given level, in … steps). The three-bundle frontier was derived by evaluating all land-use compositions on a …% grid (n = …) with the package's scenario table and retaining all non-dominated compositions; this evaluation was verified against calcPerformance() and solveScenario(), and the grid frontier was checked against the exact pairwise frontiers. Social indicator values were derived from AHP priorities of six experts (mean and SD across experts)."*

**References to check and cite** (always verify the final published version yourself):

* Knoke, T., Paul, C., Hildebrandt, P. et al. (2016). Compositional diversity of rehabilitated tropical lands supports multiple ecosystem services and buffers uncertainties. *Nature Communications* 7, 11877. https://doi.org/10.1038/ncomms11877
* Husmann, K., von Groß, V., Bödeker, K., Fuchs, J. M., Paul, C., & Knoke, T. (2022). optimLanduse: A package for multiobjective land-cover composition optimization under uncertainty. *Methods in Ecology and Evolution*. https://doi.org/10.1111/2041-210X.14000 (as given in the package documentation of version 2.0.0). Also cite the package version you used: run `citation("optimLanduse")` in R.
* Gosling, E., Reith, E., Knoke, T., Paul, C. (2020). A goal programming approach to evaluate agroforestry systems in Eastern Panama. *Journal of Environmental Management* 261, 110248. https://doi.org/10.1016/j.jenvman.2020.110248 (the package documentation also lists a second Gosling et al. 2020 paper in *Agroforestry Systems*; see `PACKAGE_NOTES.md`).

## 10.7 Troubleshooting

| Message / symptom | Cause and fix |
|---|---|
| `Cannot find the scripts folder` | You are not in the project folder. Open `surselva_course.Rproj`. |
| `object 'coef_table' not found` | Lesson 6 was not run in this session. Run `source("scripts/run_all.R")` with `UP_TO_LESSON` set to the lesson you are at. |
| `there is no package called …` | Install it: `install.packages("name")`. |
| `At least one indicator is not available for at least one land-use option.` | Your long table has a missing indicator × land-use combination. The checks in 6.3 normally catch it earlier. |
| `The indicator names are not unique.` | An indicator–land-use pair appears twice. |
| `No optimum found` printed by the solver | Very rare; usually caused by bounds that cannot be met or NaN values. Check for identical means or zero ranges. |
| Warning *"Non-necessary columns detected and neglected"* | Your table has extra columns. Harmless (only `indicatorGroup` is allowed to stay without a warning). |
| `Check failed: the fast scoring differs…` | The installed package version differs from the tested one (2.0.0). Install the GitHub version (see Lesson 1.4) and re-run; if it persists, do not use the Pareto results and ask for help. |
| `Please install optimLanduse 2.0.0 or newer` | The Pareto arguments are missing in your version. See Lesson 1.4. |
| Plot is empty or colours missing | A name in `land_use_labels` differs from the one in `land_use_palette` mapping. Re-check the labels. |
| Very slow | Use `GRID_STEP <- 0.1` for quick tests (3,003 mixes). |
| `optimisticRule` typo, e.g. "expectaton" | The package only *prints* an error message and then carries on with invalid values! Always spell it exactly: `"expectation"` or `"uncertaintyAdjustedExpectation"`. |

Congratulations – you now have a complete, reproducible analysis pipeline. Re-run it any time with `source("scripts/run_all.R")`.
