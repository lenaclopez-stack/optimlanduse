# Lesson 7 – The robust optimisation: compromise, bundle optima, indicator performance

**Time:** about 2 hours  **You will learn:** to run *optimLanduse* on your Surselva data, to optimise for all indicators and for each bundle separately, to draw the land-use composition figure (Figure R1) and the indicator-performance figure (Figure R2).

Requirements: Lessons 4–6 must have been run in this R session. If you restarted R, run `source("scripts/run_all.R")` after setting `UP_TO_LESSON <- 6` at the top of `run_all.R` (then set it back to 10 later).

---

## 7.1 Initialise and solve with *all nine* indicators

<!--run-->
```r
library(optimLanduse)
library(dplyr)
library(tidyr)
library(ggplot2)

# Step 1: set up the problem
init_all <- initScenario(coefTable      = coef_table,
                         uValue         = U_VALUE,
                         optimisticRule = OPTIMISTIC_RULE,
                         fixDistance    = FIX_DISTANCE)

# Safety check: the package divides by the "range" of each scenario.
# A range of 0 would give NaN. (Cannot happen with sensible data, but we check.)
stopifnot(!anyNA(init_all$scenarioTable),
          !any(init_all$scenarioTable$diffAdjSem == 0))
cat("Number of scenarios:", nrow(init_all$scenarioTable), "\n")   # 9 indicators x 2^6 = 576

# Step 2: solve
result_all <- solveScenario(x = init_all, digitsPrecision = DIGITS)

stopifnot(result_all$status == "optimized")
stopifnot(identical(names(result_all$landUse), land_use_ids))   # same order as our ids

cat("Guaranteed performance (1 - beta):", round(1 - result_all$beta, 3), "\n")
print(round(result_all$landUse * 100, 1))      # shares in percent
```

**Explanation**

* The arguments come from the settings in `lesson06_inputs.R`; you do not need to retype numbers here.
* `init_all$scenarioTable` has `9 × 2⁶ = 576` rows. `nrow()` counts rows.
* `stopifnot(...)` verifies that the scenario table has no missing values and that no scenario has a zero range.
* `result_all$status` should be `"optimized"`. If the solver fails, the package prints "No optimum found" and the status says so; our `stopifnot` would then stop the script.
* `1 - result_all$beta` is the **guaranteed performance**: in the worst-case scenario of the worst-served indicator, the portfolio still achieves this share of the best achievable level.
* `result_all$landUse * 100` converts shares to percent.

---

## 7.2 Optimise bundle by bundle

To see what each *group* of goals would ask for on its own, we run the optimisation three more times, each time on a subset of the indicators. This is the same idea as the "socio-economic / ecological / immediate economic" bundles in the package README.

<!--run-->
```r
solve_for_bundle <- function(bundle_name) {
  # keep only the rows of this bundle in the long table
  sub_table <- coef_table[coef_table$indicatorGroup == bundle_name, ]

  init_b   <- initScenario(coefTable      = sub_table,
                           uValue         = U_VALUE,
                           optimisticRule = OPTIMISTIC_RULE,
                           fixDistance    = FIX_DISTANCE)
  result_b <- solveScenario(x = init_b, digitsPrecision = DIGITS)
  stopifnot(result_b$status == "optimized")
  result_b
}

# Run it for "Economic", "Ecological", "Social" and keep the results in a named list
results_bundle <- lapply(setNames(bundle_names, bundle_names), solve_for_bundle)

for (b in bundle_names) {
  cat(b, "bundle alone: guaranteed performance =",
      round(1 - results_bundle[[b]]$beta, 3), "\n")
}
```

**Explanation**

* `function(bundle_name) { ... }` is our own function (Lesson 2). It takes a bundle name and returns the solved object for that bundle.
* `coef_table[coef_table$indicatorGroup == bundle_name, ]` – "keep the rows where the bundle equals `bundle_name`". The comma with nothing after it means "all columns".
* `lapply(list, function)` applies the function to every element and returns a list. `setNames(bundle_names, bundle_names)` gives the list element names ("Economic", …).
* `results_bundle[["Economic"]]` (or `results_bundle$Economic`) gets one result.
* The guaranteed performance of a bundle alone is usually **higher** than that of all nine indicators together (fewer goals are easier to satisfy). The difference shows the "price" of balancing all goals.

---

## 7.3 Collect the four portfolios in one table

<!--run-->
```r
selected <- data.frame(
  portfolio = c("Economic optimum", "Ecological optimum", "Social optimum",
                "Compromise (all indicators)"),
  rbind(results_bundle[["Economic"]]$landUse,
        results_bundle[["Ecological"]]$landUse,
        results_bundle[["Social"]]$landUse,
        result_all$landUse),
  stringsAsFactors = FALSE
)
rownames(selected) <- NULL

# Print as percentages with the nice labels
selected_print <- selected
selected_print[, land_use_ids] <- round(selected[, land_use_ids] * 100, 1)
names(selected_print)[match(land_use_ids, names(selected_print))] <- land_use_labels
print(selected_print)

# Each portfolio's shares must add up to 1 (100 %)
stopifnot(all(abs(rowSums(selected[, land_use_ids]) - 1) < 1e-6))

dir.create(file.path("output", "tables"), recursive = TRUE, showWarnings = FALSE)
write.csv(selected_print, file.path("output", "tables", "table_selected_portfolios.csv"),
          row.names = FALSE)
```

**Explanation**

* `rbind()` stacks the four one-row tables under each other. `data.frame(portfolio = ..., rbind(...))` puts the names in front.
* `selected[, land_use_ids]` selects the six share columns by name.
* `names(selected_print)[match(land_use_ids, names(selected_print))] <- land_use_labels` renames the columns from ids to nice labels (for the printout and the CSV only; the `selected` table itself keeps the ids, which the later code needs).
* `write.csv()` saves the table; you can open it in Excel and paste it into the manuscript.

---

## 7.4 Figure R1 – land-use composition of the four portfolios

<!--run-->
```r
fig_data <- selected %>%
  pivot_longer(cols = all_of(land_use_ids), names_to = "landUse", values_to = "share") %>%
  mutate(share     = share * 100,
         landUse   = factor(landUse, levels = land_use_ids, labels = land_use_labels),
         portfolio = factor(portfolio, levels = selected$portfolio))

fig_r1 <- ggplot(fig_data, aes(x = portfolio, y = share, fill = landUse)) +
  geom_col(colour = "white", linewidth = 0.4, width = 0.7) +
  scale_fill_manual(values = setNames(land_use_palette, land_use_labels)) +
  scale_y_continuous(breaks = seq(0, 100, 20), expand = c(0, 0)) +
  coord_cartesian(ylim = c(0, 100)) +
  labs(x = NULL, y = "Share of land (%)", fill = NULL, caption = data_note) +
  guides(fill = guide_legend(nrow = 2)) +
  theme_article() +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))

print(fig_r1)
save_figure(fig_r1, "fig_R1_portfolio_composition", width = 16, height = 11)
```

**Explanation**

* `pivot_longer(cols = all_of(land_use_ids), ...)` – ggplot needs one row per bar segment (portfolio × land use).
* `factor(x, levels = ..., labels = ...)` turns text into a *factor* with a fixed order and nicer names. That fixes the stacking order and the legend order.
* `setNames(land_use_palette, land_use_labels)` links each colour to a land use **by name**, so a land use keeps its colour in every figure.
* `geom_col(colour = "white", linewidth = 0.4)` gives a thin white gap between segments.
* `scale_y_continuous(..., expand = c(0, 0))` lets the bars start exactly at 0. `coord_cartesian(ylim = c(0, 100))` sets the visible range. (We use `coord_cartesian` rather than `limits =` on purpose: with `limits`, a bar whose shares add up to 100.0000001 because of rounding would lose a segment.)
* `caption = data_note` shows the red placeholder warning (it is `NULL`, i.e. invisible, once you set `DATA_ARE_PLACEHOLDERS <- FALSE`).
* `save_figure()` (from Lesson 4) writes PNG + PDF to `output/figures/`.

**How to read Figure R1 for your Results section:** the *Economic optimum* shows which land uses carry the monetary indicators, the *Ecological optimum* what nature-oriented indicators want, the *Social optimum* what the stakeholders want, and the *Compromise* how the robust balance looks. Differences between bars are the land-use conflicts of Surselva.

---

## 7.5 Figure R2 – how well is every indicator served by the compromise?

<!--run-->
```r
perf_all <- calcPerformance(result_all)       # call only ONCE per object
scen_all <- perf_all$scenarioTable
scen_all$performance_pct <- scen_all$performance * 100

# attach labels and bundle names to every scenario row
scen_all <- scen_all %>%
  left_join(indicator_info[, c("id", "label", "bundle")], by = c("indicator" = "id"))

guaranteed_pct <- min(scen_all$performance_pct)
cat("Guaranteed performance:", round(guaranteed_pct, 1), "%\n")

# Order of the y axis: bundles in the given order, indicators in table order
scen_all$label <- factor(scen_all$label, levels = rev(indicator_info$label))

fig_r2 <- ggplot(scen_all, aes(x = performance_pct, y = label, colour = bundle)) +
  geom_vline(xintercept = guaranteed_pct, linetype = "dashed", colour = "#52514e") +
  geom_point(size = 1.8, alpha = 0.55) +
  scale_colour_manual(values = bundle_cols) +
  scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, 20)) +
  labs(x = "Performance (% of the best achievable level)", y = NULL, colour = NULL,
       caption = data_note) +
  theme_article()

print(fig_r2)
save_figure(fig_r2, "fig_R2_indicator_performance", width = 16, height = 11)

# Which indicators define the compromise? (their lowest dot touches the dashed line)
bottleneck <- scen_all %>%
  group_by(indicator = label) %>%
  summarise(lowest_pct = min(performance_pct), .groups = "drop") %>%
  arrange(lowest_pct)
print(as.data.frame(bottleneck))
write.csv(bottleneck, file.path("output", "tables", "table_indicator_lowest_performance.csv"),
          row.names = FALSE)
```

**How to read Figure R2.** Each dot is one of the 64 uncertainty scenarios of an indicator. The dashed line is the guaranteed performance. Indicators with a dot **on** the dashed line are the *bottlenecks*: they determine the compromise. Indicators whose dots are all far to the right are well served; a wide spread of dots means the indicator is sensitive to uncertainty (large SD relative to the differences between land uses).

**Explanation of the code.** `left_join(...)` attaches nice labels and the bundle. `group_by(indicator = label) %>% summarise(min(...))` finds the lowest performance per indicator; `arrange()` sorts from the lowest. In Results you can write: *"The compromise is limited by X and Y (lowest performance …%)."*

---

## 7.6 What the `u` value does (read this before choosing `U_VALUE`)

* `U_VALUE = 0`: uncertainty ignored; the model is an ordinary reference-point optimisation.
* `U_VALUE = 1`: the pessimistic outcome is *mean − 1 × uncertainty*.
* Larger values: more risk-averse. In Lesson 10 you will see how portfolios and the Pareto frontier change from `u = 0` to `u = 3`.

There is no "correct" u – it expresses how cautious the decision-maker is. Many studies show a range of u. Choose a main value (we use 1) and show the sensitivity (Lesson 10).

---

## 7.7 Practice

1. Change `U_VALUE` in `lesson06_inputs.R` to `2`, re-run Lessons 6–7, and see how the compromise changes.
2. Which land use gets the largest share in the compromise? Which gets none? Why? (Look at the means: is that land use always beaten by another?)
3. In `results_bundle`, check `results_bundle$Social$landUse`.

**Next:** Lesson 8 – building the Pareto frontier.
