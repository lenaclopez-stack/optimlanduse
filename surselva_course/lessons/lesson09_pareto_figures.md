# Lesson 9 – The Pareto frontier, part 2: the figures for your Results section

**Time:** about 2 hours  **You will learn:** how to draw the Pareto frontier for the three bundles (Figure R3), how the land-use composition changes along the frontier (Figure R4), how to summarise the frontier in a table (Table R2), and how to read all of it.

Requirements: Lesson 8 must have been run (`run_all.R` with `UP_TO_LESSON <- 8` rebuilds everything).

---

## 9.1 What the figure shows

Each **dot** is one land-use mix on the grid, scored on two bundles. Three layers:

* **Grey cloud** – a random sample of 8,000 of all mixes (so the file stays small). Shows what is *possible*.
* **Coloured dots** – the mixes on the full three-bundle Pareto frontier. Their colour shows the **third** bundle (the one not on the axes). A dot can look "inside" the cloud in a 2-D view because it is only efficient when you also look at the third bundle.
* **Black line** – the two-bundle frontier (ignoring the third bundle): the upper-right edge of the cloud. This is the classic "trade-off curve": moving along it improves one bundle and worsens the other.
* **Large symbols** – the four portfolios from Lesson 7: the three single-bundle optima and the robust compromise (black diamond).

## 9.2 Figure R3 – the Pareto frontier for all three pairs of bundles

<!--run-->
```r
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
```

**Explanation**

* `sample(n, size)` draws random row numbers; `set.seed(42)` makes the draw repeatable.
* `.data[[a]]` lets ggplot use a column whose *name* is stored in the variable `a` (so one function can draw all three pairs).
* The four `geom_*` layers are drawn in order: cloud (bottom), frontier dots, black line, big symbols (top).
* `scale_colour_gradient(low, high)` – a one-hue light→dark scale for the third bundle (dark = high performance). `limits = c(0, 1)` keeps the colours comparable between panels.
* `shape` values 21–25 are filled symbols: circle, square, diamond, triangle… `colour = "white"` gives them a white ring.
* The axis titles say "performance" for short; it always means the bundle's *guaranteed performance* (0–1). `guide_colourbar(...)` makes the colour legends small so that three of them fit in one row.
* `coord_cartesian(xlim, ylim)` fixes both axes to 0–1 without removing points; `aspect.ratio = 1` makes the panel square.
* `wrap_plots(panels, nrow = 1)` (package *patchwork*) puts the three plots in a row; `plot_layout(guides = "collect")` merges identical legends.

**How to read the figure in your Results**

* The **distance of the black line from the top-right corner** tells you how strong the conflict between two bundles is. A line that bends sharply near the corner means you can improve both goals together up to a point (synergy); a long diagonal means that one is gained only at the other's expense (trade-off).
* The **position of the compromise diamond** relative to the line shows how much is sacrificed for balance.
* The **colour** of the frontier dots shows whether the third bundle suffers when you favour two.

## 9.3 Figure R4 – how the land-use mix changes along the frontier

<!--run-->
```r
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
```

**Explanation**

* For every pair-frontier we take its table, add a label, and `pivot_longer()` the six share columns into one column (the long format ggplot needs).
* `bind_rows(lapply(...))` glues the three long tables together.
* `geom_area(position = "stack")` draws stacked areas; the x position is the performance of the first bundle of the pair, so we see how the **recipe of land uses changes as one bundle is favoured over the other**.
* `facet_wrap(~ pair, scales = "free_x")` makes one panel per pair, each with its own x range.
* Remember: among portfolios with identical scores, the one that is best for the third bundle was kept (Lesson 8.9). Otherwise the areas would jump around arbitrarily.

**Reading it:** Wide bands that grow on one side show which land uses "win" when the corresponding goal gets priority. A land use whose band appears only in the middle is a *compromise land use*. A land use that never appears is dominated by others in those two goals.

## 9.4 Table R2 – summary of the frontier

<!--run-->
```r
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
```

**Explanation**

* For each land use we describe the distribution of its share across all frontier portfolios: smallest, median, largest, and in what percentage of the frontier portfolios it is used at all.
* `sweep(grid_perf, 2, compromise_scores)` subtracts the compromise scores from every row of the grid scores.
* The package compromise maximises the *weakest* indicator across **all** nine indicators. It is therefore a "balanced" point on or near the frontier. The count of "better everywhere" grid mixes is usually 0 or very small: if it is larger than 0, the compromise could be marginally improved for the non-limiting bundles without losing on the limiting one (this can happen because of ties; it is not an error).
* `best_balanced` is the mix on the frontier whose weakest bundle is the strongest; it should have almost the same weakest-bundle score as the package compromise (the small gap is the 5 % grid resolution).

## 9.5 Choosing the right resolution (and the word "frontier")

* The frontier is **approximated** by a grid. With `GRID_STEP = 0.05` the points are spaced at least 5 percentage points apart in the land-use shares; the frontier can look slightly stepped. For the final version of the paper, set `GRID_STEP <- 0.025` in `lesson06_inputs.R` and run `run_all.R` while you do something else (expect 20–60 minutes on a laptop). Report the step size in the Methods.
* The validation table of Lesson 8 (exact package optimum vs best on grid) is the quantitative evidence that the grid is fine enough; quote it, e.g. "the grid optimum deviated from the exact optimum by less than 0.0X guaranteed-performance units".

## 9.6 Practice

1. Which pair of bundles has the sharpest trade-off? Look at how far the black line is from the top-right corner.
2. Which land use dominates the *Economic* end of Figure R4? Which is typical for the *Ecological* end?
3. Change one placeholder mean substantially (e.g. raise the NPV of `ProForestation` to 5000), re-run, and see how the frontier changes.

**Next:** Lesson 10 – uncertainty (the u-value), the final outputs, and writing the Results section.
