# ------------------------------------------------------------------
# lesson06_ahp_demo.R  (code of lessons/lesson06_your_data.md)
# Built automatically from the lesson text. Run it from the folder
# that contains surselva_course.Rproj (open the .Rproj in RStudio).
# ------------------------------------------------------------------

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
