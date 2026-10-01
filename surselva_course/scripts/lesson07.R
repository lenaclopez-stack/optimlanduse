# ------------------------------------------------------------------
# lesson07.R  (code of lessons/lesson07_robust_optimisation.md)
# Built automatically from the lesson text. Run it from the folder
# that contains surselva_course.Rproj (open the .Rproj in RStudio).
# ------------------------------------------------------------------

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
