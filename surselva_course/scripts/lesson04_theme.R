# ------------------------------------------------------------------
# lesson04_theme.R  (code of lessons/lesson04_ggplot2.md)
# Built automatically from the lesson text. Run it from the folder
# that contains surselva_course.Rproj (open the .Rproj in RStudio).
# ------------------------------------------------------------------

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
