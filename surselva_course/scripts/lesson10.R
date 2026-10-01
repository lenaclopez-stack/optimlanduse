# ------------------------------------------------------------------
# lesson10.R  (code of lessons/lesson10_uncertainty_and_results.md)
# Built automatically from the lesson text. Run it from the folder
# that contains surselva_course.Rproj (open the .Rproj in RStudio).
# ------------------------------------------------------------------

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

writeLines(capture.output(sessionInfo()), file.path("output", "session_info.txt"))

cat("\nFiles created:\n")
print(list.files("output", recursive = TRUE))
