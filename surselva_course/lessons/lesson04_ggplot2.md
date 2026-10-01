# Lesson 4 – Figures with ggplot2 (and our shared colours and theme)

**Time:** about 2 hours  **You will learn:** the "grammar of graphics" in `ggplot2`, how to make scatter plots, bar charts and stacked bars, how to set colours, and how to save journal-quality files. At the end we define the colours and plot style used by every later figure.

---

## 4.1 The idea: build a plot in layers

A ggplot is built from:

1. **data** – a data frame,
2. **aesthetics `aes()`** – which column goes on x, y, colour, fill, shape …,
3. **geoms** – the drawn shapes (`geom_point` = dots, `geom_col` = bars, `geom_line`, …),
4. **extras** – labels (`labs`), scales (`scale_*`), theme (`theme_*`).

Layers are joined with `+`.

<!--run:lesson04.R-->
```r
library(ggplot2)
library(dplyr)
library(tidyr)

practice <- data.frame(
  landUse = c("Timber forest", "Protection forest", "Alpine pasture",
              "Biodiversity meadows", "Proforestation", "Natural regeneration"),
  npv     = c(4500, 1500, 2800, 900, -300, 200),      # placeholder numbers
  carbon  = c(6.0, 5.0, 0.5, 0.8, 7.5, 4.0)           # placeholder numbers
)

# Scatter plot: NPV (x) against carbon sequestration (y)
p1 <- ggplot(data = practice, mapping = aes(x = npv, y = carbon)) +
  geom_point(size = 3) +
  labs(x = "NPV (CHF/ha)", y = "Carbon sequestration (t CO2/ha/yr)")
print(p1)
```

**Line by line**

* `ggplot(data = practice, mapping = aes(x = npv, y = carbon))` – "start a plot from the table `practice`; put `npv` on the x axis and `carbon` on the y axis". Nothing is drawn yet.
* `+ geom_point(size = 3)` – draw one dot per row, size 3.
* `+ labs(x = ..., y = ...)` – axis titles.
* `print(p1)` – show the plot (in a script, a plot is only shown if you `print` it; typing `p1` in the Console also works). It appears in the **Plots** pane.

Add text labels and a theme:

<!--run:lesson04.R-->
```r
p2 <- p1 +
  geom_text(aes(label = landUse), vjust = -0.8, size = 3) +   # label every dot
  expand_limits(y = 9, x = 5500) +                            # a bit of free space
  theme_classic(base_size = 11)                               # clean look: no grey background
print(p2)
```

---

## 4.2 Bar charts and the difference between `geom_col` and `geom_bar`

`geom_col()` draws bars whose height is *a number you already have*. (Use it for land-use shares.)

<!--run:lesson04.R-->
```r
p3 <- ggplot(practice, aes(x = landUse, y = npv)) +
  geom_col(fill = "#2a78d6") +
  coord_flip() +                       # turn the plot sideways so long names fit
  labs(x = NULL, y = "NPV (CHF/ha)") +
  theme_classic(base_size = 11)
print(p3)
```

`fill` colours the inside of a bar, `colour` colours its outline. `coord_flip()` swaps the axes. `x = NULL` removes an axis title.

---

## 4.3 Stacked bars: the land-use composition plot

This is the plot type you will use the most: one bar per portfolio, split into coloured segments for the land-use shares.

<!--run:lesson04.R-->
```r
shares <- data.frame(
  portfolio = rep(c("Portfolio A", "Portfolio B"), each = 3),
  landUse   = rep(c("Timber", "Pasture", "Meadow"), times = 2),
  share     = c(50, 30, 20,   10, 40, 50)    # percent; each portfolio sums to 100
)

p4 <- ggplot(shares, aes(x = portfolio, y = share, fill = landUse)) +
  geom_col(colour = "white", linewidth = 0.4) +      # thin white outline separates the segments
  labs(x = NULL, y = "Share of land (%)", fill = "Land use") +
  theme_classic(base_size = 11)
print(p4)
```

Because we mapped `fill = landUse` inside `aes()`, ggplot automatically makes one colour per land use and a legend. To choose the colours ourselves we add `scale_fill_manual(values = c(Timber = "#2a78d6", ...))`.

**Rule of thumb:** things that depend on a column go **inside** `aes()`; fixed things (e.g. "all bars blue") go **outside**.

---

## 4.4 Our fixed colours and theme (used by all later figures)

In a paper, the same land use should always have the same colour in every figure. We therefore define the colours once. They are colour-blind-friendly (checked with a CVD distance test) and each segment has a thin white gap so neighbours are always distinguishable.

The block below is saved as `scripts/lesson04_theme.R` and is loaded automatically by `run_all.R`.

<!--run:lesson04_theme.R-->
```r
library(ggplot2)

# --- Colours -----------------------------------------------------------------
# Bundles (3 colours, picked to stay distinguishable for colour-blind readers)
bundle_cols <- c(Economic = "#2a78d6", Ecological = "#1baf7a", Social = "#eb6834")

# Land uses (6 colours, in the fixed order of land_use_ids from Lesson 6)
land_use_palette <- c("#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4", "#008300")

# --- Theme (the "look" of all figures) ------------------------------------------
theme_article <- function(base_size = 11) {
  theme_classic(base_size = base_size) +
    theme(
      panel.grid.major = element_line(colour = "#e6e6e3", linewidth = 0.3),
      legend.position  = "bottom",
      strip.background = element_blank(),
      strip.text       = element_text(face = "bold"),
      plot.caption     = element_text(colour = "#b3261e", face = "bold")
    )
}

# --- Saving ------------------------------------------------------------------------
# Saves a figure twice: PNG (300 dpi, for Word) and PDF (vector, for journals).
# width/height are in centimetres.
save_figure <- function(plot, name, width = 16, height = 10) {
  dir.create(file.path("output", "figures"), recursive = TRUE, showWarnings = FALSE)
  ggsave(file.path("output", "figures", paste0(name, ".png")),
         plot = plot, width = width, height = height, units = "cm", dpi = 300)
  ggsave(file.path("output", "figures", paste0(name, ".pdf")),
         plot = plot, width = width, height = height, units = "cm")
  invisible(plot)
}
```

**Explanation**

* `bundle_cols` is a *named vector*: names (`Economic`, …) on the left, colour codes on the right. Colours are written as hex codes (`#RRGGBB`).
* `theme_article()` is **our own function** that returns a theme. Adding `+ theme_article()` to any plot gives it the same style: classic axes, light grid, legend at the bottom. The red caption is used for a **placeholder-data warning** (Lesson 6) so that you never accidentally publish figures made with invented numbers.
* `save_figure()` calls `ggsave()` twice. `units = "cm"` and `dpi = 300` give print quality (most journals ask for ≥ 300 dpi, or vector PDF). A single-column figure is usually 8–9 cm wide, a double-column figure 16–18 cm. Check your journal's guidelines.

Now use them in the practice example and save:

<!--run:lesson04.R-->
```r
source("scripts/lesson04_theme.R")      # load the colours, theme and save_figure()

p5 <- ggplot(shares, aes(x = portfolio, y = share, fill = landUse)) +
  geom_col(colour = "white", linewidth = 0.4) +
  scale_fill_manual(values = land_use_palette[1:3]) +
  labs(x = NULL, y = "Share of land (%)", fill = NULL) +
  theme_article()

save_figure(p5, "practice_stacked_bars", width = 10, height = 8)
```

Look in the folder `output/figures/` – you should find `practice_stacked_bars.png` and `.pdf`.

> **If `source("scripts/lesson04_theme.R")` says "cannot open file"**, you are not in the project folder. Open `surselva_course.Rproj` (Lesson 1.3) and check `getwd()`.

---

## 4.5 Useful ggplot cheat-sheet

| I want to… | Add this |
|---|---|
| change axis limits | `+ scale_x_continuous(limits = c(0, 1))` |
| show percentages | `+ scale_y_continuous(labels = scales::percent)` |
| split into panels | `+ facet_wrap(~ variable)` |
| rotate the legend text / move legend | `+ theme(legend.position = "right")` |
| draw a horizontal reference line | `+ geom_hline(yintercept = 0.4, linetype = "dashed")` |
| use my own colours | `+ scale_fill_manual(values = c(...))` (bars) or `scale_colour_manual` (dots/lines) |
| title / caption | `+ labs(title = "…", caption = "…")` |

**Next:** Lesson 5 – meeting the *optimLanduse* package with its built-in example.
