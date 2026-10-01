# ------------------------------------------------------------------
# lesson05.R  (code of lessons/lesson05_optimlanduse_basics.md)
# Built automatically from the lesson text. Run it from the folder
# that contains surselva_course.Rproj (open the .Rproj in RStudio).
# ------------------------------------------------------------------

library(optimLanduse)
library(readxl)
library(dplyr)
library(tidyr)
library(ggplot2)

# Where is the example file stored on your computer?
path_example <- exampleData("exampleGosling.xlsx")

# Read the Excel file into a table
example_data <- read_excel(path_example)

# Look at the first rows
print(head(as.data.frame(example_data), 8))

example_init <- initScenario(coefTable      = example_data,
                             uValue         = 2,
                             optimisticRule = "expectation",
                             fixDistance    = NA)

print(names(example_init))
print(dim(example_init$scenarioTable))   # rows x columns of the scenario table

example_result <- solveScenario(x = example_init)

print(example_result$status)           # "optimized"
print(example_result$beta)             # beta
print(round(example_result$landUse, 3))  # the land-use shares (they add up to 1)

example_perf <- calcPerformance(example_result)

scen <- example_perf$scenarioTable
scen$performance_pct <- scen$performance * 100

# The guaranteed performance = the lowest performance of any scenario
print(round(min(scen$performance_pct), 1))      # 38.7
print(names(scen)[1:8])

source("scripts/lesson04_theme.R")     # our colours and theme (from Lesson 4)

p_example <- ggplot(scen,
                    aes(x = performance_pct,
                        y = reorder(indicator, performance_pct, FUN = min))) +
  geom_point(alpha = 0.5, colour = "#2a78d6") +
  geom_vline(xintercept = min(scen$performance_pct),
             linetype = "dashed", colour = "#52514e") +
  scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, 20)) +
  labs(x = "Performance (% of best achievable level)", y = NULL,
       caption = "Package example data (Gosling et al. 2020), u = 2. Dashed line = guaranteed performance (1 - beta).") +
  theme_article()
print(p_example)

for (u in c(0, 1, 2)) {
  r <- solveScenario(initScenario(example_data, uValue = u,
                                  optimisticRule = "expectation", fixDistance = NA))
  cat("u =", u, " guaranteed performance =", round(1 - r$beta, 3), "\n")
}
