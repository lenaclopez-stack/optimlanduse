# ------------------------------------------------------------------
# lesson09.R  (code of lessons/lesson09_pareto_figures.md)
# Built automatically from the lesson text. Run it from the folder
# that contains surselva_course.Rproj (open the .Rproj in RStudio).
# ------------------------------------------------------------------

library(patchwork)

# Random sample of the grid, only for drawing the grey cloud (reproducible)
set.seed(42)
cloud_rows <- sample(nrow(grid_perf), min(8000, nrow(grid_perf)))
cloud      <- as.data.frame(grid_perf)[cloud_rows, ]

# The four special portfolios and their bundle scores
anchors <- data.frame(portfolio = selected$portfolio, as.data.frame(anchor_perf))
anchor_fill  <- c("Economic optimum"   = unname(bundle_cols["Economic"]),
                  "Ecological optimum" = unname(bundle_cols["Ecological"]),
                  "Social optimum"     = unname(bundle_cols["Social"]),
                  "Compromise (all indicators)" = "#0b0b0b")
anchor_shape <- c("Economic optimum" = 21, "Ecological optimum" = 22,
                  "Social optimum" = 24, "Compromise (all indicators)" = 23)

plot_pair <- function(a, b, third) {
  f2 <- pair_fronts[[paste(a, "vs", b)]]

  ggplot() +
    geom_point(data = cloud,    aes(x = .data[[a]], y = .data[[b]]),
               colour = "#d4d4d0", size = 0.5) +
    geom_point(data = frontier, aes(x = .data[[a]], y = .data[[b]], colour = .data[[third]]),
               size = 1.1) +
    geom_line(data = f2, aes(x = x, y = y), colour = "#0b0b0b", linewidth = 0.6) +
    geom_point(data = anchors,
               aes(x = .data[[a]], y = .data[[b]], shape = portfolio, fill = portfolio),
               size = 3.6, colour = "white", stroke = 0.9) +
    scale_colour_gradient(low = "#cfe0f7", high = "#123f78", limits = c(0, 1), breaks = c(0, 0.5, 1),
                          name = paste("Colour:", third, "performance"),
                          guide = guide_colourbar(title.position = "top",
                                                  barwidth = unit(2.6, "cm"),
                                                  barheight = unit(0.25, "cm"))) +
    scale_fill_manual(values = anchor_fill, name = NULL) +
    scale_shape_manual(values = anchor_shape, name = NULL) +
    guides(shape = guide_legend(nrow = 4), fill = guide_legend(nrow = 4)) +
    coord_cartesian(xlim = c(0, 1), ylim = c(0, 1)) +
    labs(x = paste(a, "performance"), y = paste(b, "performance")) +
    theme_article(base_size = 10) +
    theme(aspect.ratio = 1, legend.title = element_text(size = 8),
          legend.text = element_text(size = 8))
}

panels <- lapply(pair_defs, function(p) plot_pair(p[1], p[2], setdiff(bundle_names, p)))

fig_r3 <- wrap_plots(panels, nrow = 1) +
  plot_layout(guides = "collect") +
  plot_annotation(caption = data_note,
                  theme = theme(plot.caption = element_text(colour = "#b3261e", face = "bold"))) &
  theme(legend.position = "bottom", legend.box = "horizontal")

print(fig_r3)
save_figure(fig_r3, "fig_R3_pareto_frontier", width = 26, height = 11.5)

along <- bind_rows(lapply(names(pair_fronts), function(nm) {
  pair_fronts[[nm]] %>%
    mutate(pair = nm, position = x) %>%
    pivot_longer(cols = all_of(land_use_ids), names_to = "landUse", values_to = "share") %>%
    select(pair, position, landUse, share)
})) %>%
  mutate(landUse = factor(landUse, levels = land_use_ids, labels = land_use_labels),
         share   = share * 100,
         pair    = factor(pair, levels = names(pair_fronts)))

fig_r4 <- ggplot(along, aes(x = position, y = share, fill = landUse)) +
  geom_area(colour = "white", linewidth = 0.2, position = "stack") +
  facet_wrap(~ pair, nrow = 1, scales = "free_x") +
  scale_fill_manual(values = setNames(land_use_palette, land_use_labels)) +
  scale_y_continuous(breaks = seq(0, 100, 20), expand = c(0, 0)) +
  scale_x_continuous(expand = c(0, 0)) +
  labs(x = "Guaranteed performance of the FIRST bundle named in the panel title (moving right = favouring the first bundle)",
       y = "Share of land (%)", fill = NULL, caption = data_note) +
  guides(fill = guide_legend(nrow = 1)) +
  theme_article(base_size = 10) +
  theme(axis.title.x = element_text(size = 8))

print(fig_r4)
save_figure(fig_r4, "fig_R4_composition_along_frontier", width = 26, height = 11)

frontier_summary <- bind_rows(lapply(seq_along(land_use_ids), function(i) {
  s <- frontier[[land_use_ids[i]]] * 100
  data.frame(`Land use`                     = land_use_labels[i],
             `Min share (%)`                = round(min(s), 1),
             `Median share (%)`             = round(median(s), 1),
             `Max share (%)`                = round(max(s), 1),
             `Present in portfolios (%)`    = round(mean(s > 0.001) * 100, 1),
             check.names = FALSE)
}))
print(frontier_summary)
write.csv(frontier_summary, file.path("output", "tables", "table_R2_frontier_summary.csv"),
          row.names = FALSE)

# How does the frontier relate to the package's compromise?
compromise_scores <- anchor_perf[4, ]
better_everywhere <- rowSums(sweep(grid_perf, 2, compromise_scores) >= -1e-9) == length(bundle_names) &
                     rowSums(sweep(grid_perf, 2, compromise_scores) >  1e-6) > 0
cat("Package compromise (all indicators): scores =",
    paste(bundle_names, round(compromise_scores, 3), collapse = ", "), "\n")
cat("Grid mixes that are better or equal on all bundles and clearly better on one:",
    sum(better_everywhere), "\n")

frontier$weakest_bundle_score <- apply(frontier[, bundle_names], 1, min)
best_balanced <- frontier[which.max(frontier$weakest_bundle_score), ]
cat("Best-balanced mix found on the grid: weakest bundle =", round(best_balanced$weakest_bundle_score, 3),
    " | package compromise: weakest bundle =", round(min(compromise_scores), 3), "\n")
