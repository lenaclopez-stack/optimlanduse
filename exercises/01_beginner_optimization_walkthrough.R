##----------------------------------------------------------------------------##
## optimLanduse — A COMPLETE BEGINNER'S EXERCISE                              ##
##----------------------------------------------------------------------------##
#
# Who this is for:
#   You have never really used R before and this is your first time running
#   code from a GitHub repository. This script will not assume you know
#   anything. Read every comment (the lines starting with #) before running
#   the code beneath it.
#
# How to run this script:
#   1. Open this file inside the optimLanduse.Rproj project in RStudio.
#   2. Put your cursor on a line of CODE (not a comment) and press
#      Ctrl+Enter (Windows/Linux) or Cmd+Enter (Mac) to run just that line.
#   3. Work through the script from top to bottom, one chunk at a time.
#      Look at what appears in the "Console" and "Plots" panes after each
#      step before moving to the next one.
#   4. If something errors, read the red error message - it usually tells
#      you exactly what went wrong (e.g. a missing package).
#
# What this script does:
#   It reruns the full optimLanduse example analysis using the real,
#   published dataset that ships with this package: a smallholder
#   agroforestry survey from Eastern Panama (Gosling et al., 2020). You will
#   load the data, run the optimization, and plot the results - the same
#   workflow described in this repository's README ("3 Example Application").
#
# For full background, see README.md in the root of this repository.

## ---------------------------------------------------------------------------
## STEP 0: Install the R packages this script needs (only run this ONCE,
##         the first time you ever run this script on your computer)
## ---------------------------------------------------------------------------

# In R, code you have "commented out" with a # is not run. Remove the #
# from the lines below and run them if you have not installed these
# packages before. If you're not sure, run them anyway - reinstalling an
# already-installed package does no harm, it just takes a minute.

# install.packages("devtools")  # lets us load this package's code directly
# install.packages("readxl")    # lets us read .xlsx (Excel) files
# install.packages("ggplot2")   # lets us make plots
# install.packages("dplyr")     # helps reshape/summarize data
# install.packages("tidyr")     # helps reshape data ("long" vs "wide" format)

## ---------------------------------------------------------------------------
## STEP 1: Load the packages you just installed
## ---------------------------------------------------------------------------

# "Loading" a package with library() makes its functions available in your
# current R session. You need to do this every time you (re)start R -
# unlike install.packages(), which you only need once per computer.

library(readxl)
library(ggplot2)
library(dplyr)
library(tidyr)

## ---------------------------------------------------------------------------
## STEP 2: Load the optimLanduse code itself
## ---------------------------------------------------------------------------

# Because you are working directly inside the source code of the optimLanduse
# package (this GitHub repository), rather than a version installed from
# CRAN, we use devtools::load_all() to load all of its functions
# (initScenario, solveScenario, calcPerformance, exampleData, ...) into your
# session. Make sure your RStudio "Project" is optimLanduse.Rproj (check the
# top-right corner of RStudio) before running this - load_all() loads
# whatever project/folder you currently have open.

devtools::load_all(".")

## ---------------------------------------------------------------------------
## STEP 3: Load the example dataset that ships with this package
## ---------------------------------------------------------------------------

# exampleData() is a helper function from this package. It returns the file
# path to a dataset that is bundled inside the package. Here we ask for
# "exampleGosling.xlsx", the real dataset from:
#
#   Gosling, E., Reith, E., Knoke, T., Paul, C. (2020). A goal programming
#   approach to evaluate agroforestry systems in Eastern Panama. Journal of
#   Environmental Management, 261, 110248.
#
# It contains smallholder farmers' survey-based expectations (and
# uncertainties) about 10 indicators (e.g. financial stability, labour
# demand, water protection) for 6 land-cover options (e.g. Crops, Pasture,
# Forest, Silvopasture).

path <- exampleData("exampleGosling.xlsx")
dat <- read_excel(path)

# Look at the raw data. Click on "dat" in the Environment pane (top-right),
# or run the line below, to open it in a spreadsheet-like viewer.
View(dat)

# Print the column names so you know what you're working with.
names(dat)

# Print how many rows there are: one row per land-cover x indicator
# combination.
nrow(dat)

## ---------------------------------------------------------------------------
## STEP 4: Understand the data structure (just reading - nothing to run)
## ---------------------------------------------------------------------------

# Every row of `dat` describes ONE combination of a land-cover option (e.g.
# "Forest") and ONE indicator (e.g. "Liquidity"), giving:
#   - indicator:  name of the indicator being measured
#   - landUse:    name of the land-cover option
#   - expectation: the average expected value for that combination
#   - uncertainty: how uncertain that expectation is (e.g. standard error)
#   - direction:  whether "more is better" or "less is better" for this
#                 indicator
#
# The optimization looks across ALL these rows at once to find the mix of
# land-cover shares (how much % Crops, % Pasture, % Forest, etc.) that best
# balances ALL 10 indicators simultaneously, while being robust to the
# uncertainty in the underlying survey data.

## ---------------------------------------------------------------------------
## STEP 5: Initialize ("set up") the optimization scenario
## ---------------------------------------------------------------------------

# initScenario() combines your data with a few settings that control HOW the
# optimization behaves:
#
#   - uValue: how risk-averse the "decision maker" is. A HIGHER number means
#     the optimizer is more cautious about uncertainty. uValue = 2 is the
#     value used in the published Gosling et al. (2020) analysis.
#   - optimisticRule: "expectation" means we use each indicator's average
#     survey value as the optimistic (best-case) outcome. This matches most
#     published applications of this method.
#   - fixDistance: leave this as NA for now - it disables an advanced option
#     you don't need for this first exercise.

init <- initScenario(
  coefTable      = dat,
  uValue         = 2,
  optimisticRule = "expectation",
  fixDistance    = NA
)

# init is now an "optimLanduse object" - a structured list that is ready to
# be solved. You don't need to understand its internals yet; just pass it on
# to solveScenario() in the next step.

## ---------------------------------------------------------------------------
## STEP 6: Solve the optimization
## ---------------------------------------------------------------------------

# solveScenario() runs the actual linear-programming solver and returns the
# optimal land-cover composition, i.e. the mix of land-cover shares that
# best balances all 10 indicators under uncertainty.

result <- solveScenario(x = init)

# "beta" is the guaranteed worst-case distance to the ideal outcome across
# all indicators - lower is better. Compare it to (1 - beta), the
# "guaranteed performance" of the resulting land-cover composition (see
# README section 3 for the full interpretation).
result$beta

## ---------------------------------------------------------------------------
## STEP 7: Look at the resulting land-cover composition
## ---------------------------------------------------------------------------

# result$landUse is a one-row table with the optimal share (0 to 1, i.e. a
# proportion) of each land-cover option. Multiply by 100 to read it as a
# percentage of the farm.

result$landUse
result$landUse * 100

## ---------------------------------------------------------------------------
## STEP 8: Visualize the optimal farm composition
## ---------------------------------------------------------------------------

# pivot_longer() reshapes the one-row landUse table into a "long" format
# (one row per land-cover option) that ggplot2 needs for a stacked bar chart.

landUse_long <- result$landUse %>%
  pivot_longer(cols = everything(),
               names_to  = "landCoverOption",
               values_to = "landCoverShare") %>%
  mutate(landCoverShare = landCoverShare * 100,
         portfolio = "Optimal farm composition")

ggplot(landUse_long, aes(x = portfolio, y = landCoverShare, fill = landCoverOption)) +
  geom_bar(position = "stack", stat = "identity") +
  theme_classic() +
  labs(y = "Allocated share (%)", x = NULL, fill = "Land-cover option") +
  scale_y_continuous(breaks = seq(0, 100, 10), limits = c(0, 100))

# You should see a single stacked bar showing what % of the farm should
# ideally be Crops, Pasture, Alley Cropping, Silvopasture, Plantation and
# Forest. In the published analysis, this portfolio is dominated by
# Silvopasture and Forest.

## ---------------------------------------------------------------------------
## STEP 9: Check how well each indicator is satisfied ("performance")
## ---------------------------------------------------------------------------

# calcPerformance() tells you, for each of the 10 indicators, how close the
# optimized farm gets to that indicator's own best-possible (100%) level.

performance <- calcPerformance(result)
performance$scenarioTable$performance <- performance$scenarioTable$performance * 100

ggplot(performance$scenarioTable, aes(x = indicator, y = performance, color = indicator)) +
  geom_point() +
  geom_hline(yintercept = min(performance$scenarioTable$performance),
             linetype = "dashed", color = "red") +
  theme_classic() +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank()) +
  labs(y = "Min-max normalized indicator value (%)", x = "Indicators", color = NULL) +
  scale_y_continuous(breaks = seq(0, 100, 10), limits = c(0, 101))

# The dashed red line marks the worst-performing indicator - this is the one
# that "limits" how good the compromise portfolio can be for everyone.

## ---------------------------------------------------------------------------
## STEP 10: Try it yourself - beginner exercises
## ---------------------------------------------------------------------------

# Now that you've reproduced the published result, try modifying the code
# above (or copy the relevant lines down here) to answer these questions.
# There's no need to overthink it - just change one thing at a time, rerun
# STEP 5-9, and see what happens.

# Exercise A: What happens to the farm composition if decision-makers are
# LESS cautious about uncertainty? Try uValue = 0 in STEP 5, rerun steps
# 6-8, and compare the resulting bar chart to the original (uValue = 2).

# Exercise B: What happens if they are MORE cautious? Try uValue = 3.

# Exercise C: The dataset contains only ecological indicators
# ("Protecting soil resources", "Protecting water supply"). What farm
# composition do you get if you optimize using ONLY those two indicators?
# Hint:
#
#   dat_ecologic <- dat[dat$indicator %in% c("Protecting soil resources",
#                                             "Protecting water supply"), ]
#
#   Then repeat STEP 5-8 using dat_ecologic instead of dat.

# Exercise D: Look up the help page for initScenario() by running:
#
#   ?initScenario
#
#   What does the fixDistance argument do? Try setting fixDistance = 3 in
#   STEP 5 (with uValue = 2) and see whether the resulting land-cover shares
#   change.

# When you're ready for more, see "4 Batch Application and Sensitivity
# Analysis" in this repository's README.md, which shows how to solve the
# optimization across a whole range of uValues at once and compare the
# optimized farm to the currently observed one.
