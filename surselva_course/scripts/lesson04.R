# ------------------------------------------------------------------
# lesson04.R  (code of lessons/lesson04_ggplot2.md)
# Built automatically from the lesson text. Run it from the folder
# that contains surselva_course.Rproj (open the .Rproj in RStudio).
# ------------------------------------------------------------------

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

p2 <- p1 +
  geom_text(aes(label = landUse), vjust = -0.8, size = 3) +   # label every dot
  expand_limits(y = 9, x = 5500) +                            # a bit of free space
  theme_classic(base_size = 11)                               # clean look: no grey background
print(p2)

p3 <- ggplot(practice, aes(x = landUse, y = npv)) +
  geom_col(fill = "#2a78d6") +
  coord_flip() +                       # turn the plot sideways so long names fit
  labs(x = NULL, y = "NPV (CHF/ha)") +
  theme_classic(base_size = 11)
print(p3)

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

source("scripts/lesson04_theme.R")      # load the colours, theme and save_figure()

p5 <- ggplot(shares, aes(x = portfolio, y = share, fill = landUse)) +
  geom_col(colour = "white", linewidth = 0.4) +
  scale_fill_manual(values = land_use_palette[1:3]) +
  labs(x = NULL, y = "Share of land (%)", fill = NULL) +
  theme_article()

save_figure(p5, "practice_stacked_bars", width = 10, height = 8)
