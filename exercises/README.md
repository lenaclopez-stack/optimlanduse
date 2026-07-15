# Beginner Exercise: Rerunning the optimLanduse Analysis

This folder contains a self-contained, heavily-commented exercise for
someone who has never used R or GitHub before, but wants to rerun the
land-use optimization in this repository from scratch, using the real
dataset from Gosling et al. (2020) that ships with the package.

The exercise script is: [`01_beginner_optimization_walkthrough.R`](01_beginner_optimization_walkthrough.R)

You do **not** need to understand linear programming or the math behind the
method to complete this exercise. You just need to follow the steps below
in order.

## 1. Install the tools

You need three pieces of free software on your computer:

1. **R** — the programming language itself. Download it from
   [cran.r-project.org](https://cran.r-project.org/) (choose your operating
   system, then the recommended/base installer).
2. **RStudio Desktop** — a friendly editor for writing and running R code.
   Download the free version from
   [posit.co/download/rstudio-desktop](https://posit.co/download/rstudio-desktop/).
   Install R first, then RStudio.
3. **Git** — the version-control tool GitHub is built on. Download it from
   [git-scm.com](https://git-scm.com/downloads). During installation, the
   default options are fine.

You can check everything installed correctly by opening RStudio and typing
`R.version.string` into the Console (bottom-left pane), then pressing Enter.

## 2. Get a copy of this repository onto your computer

In RStudio:

1. Go to **File > New Project > Version Control > Git**.
2. In the "Repository URL" box, paste:
   `https://github.com/lenaclopez-stack/optimlanduse.git`
3. Choose a folder on your computer where you'd like the project saved, then
   click **Create Project**.
4. RStudio will download ("clone") the repository and automatically open it
   as a Project. You'll know it worked because you'll see the files of this
   repository (including this `exercises/` folder) in the "Files" pane
   (bottom-right).

If you'd rather not use Git yet, you can instead click the green **Code**
button on the repository's GitHub page and choose **Download ZIP**, then
unzip it and double-click `optimLanduse.Rproj` to open the project in
RStudio. You just won't be able to easily save/sync your changes back to
GitHub this way.

## 3. Switch to this exercise's branch (only if needed)

This exercise lives on a branch called
`claude/optimlanduse-beginner-exercise-ao1vgy`. If you cloned the repository
and don't see an `exercises/` folder, open the RStudio **Terminal** tab
(next to Console) and run:

```
git fetch origin
git checkout claude/optimlanduse-beginner-exercise-ao1vgy
```

## 4. Open and run the exercise script

1. In the Files pane, click into the `exercises` folder, then click
   `01_beginner_optimization_walkthrough.R` to open it.
2. Confirm you're inside the right RStudio Project: the top-right corner of
   RStudio should say **optimLanduse**. If it doesn't, open
   `optimLanduse.Rproj` first (File > Open Project).
3. Read the script from the top. Every section is explained in plain
   English in the comments (lines starting with `#`).
4. Run the code one line/chunk at a time: click on a line and press
   **Ctrl+Enter** (Windows/Linux) or **Cmd+Enter** (Mac). Watch the Console
   (bottom-left) and Plots (bottom-right) panes after each step.
5. The first time you run it, uncomment and run the `install.packages(...)`
   lines in "STEP 0" — after that you can leave them commented out.

## 5. What you should see

Working through the script reproduces the worked example from this
repository's main [README.md](../README.md) ("3 Example Application"),
using the real survey data of Panamanian smallholder farmers from:

> Gosling, E., Reith, E., Knoke, T., Paul, C. (2020). A goal programming
> approach to evaluate agroforestry systems in Eastern Panama. *Journal of
> Environmental Management*, 261, 110248.

By the end you will have:

- Loaded the built-in `exampleGosling.xlsx` dataset.
- Run the full `initScenario()` → `solveScenario()` → `calcPerformance()`
  workflow.
- Produced a bar chart of the optimal farm land-cover composition (expect
  it to be dominated by Silvopasture and Forest).
- Produced a plot showing how well each of the 10 farmer indicators is
  satisfied by that optimal composition.
- Tried four small "Try it yourself" modifications (STEP 10 of the script)
  to build intuition for how the model responds to different assumptions.

## 6. If something goes wrong

- **Red error mentioning "could not find function"**: you likely skipped
  `devtools::load_all(".")` in STEP 2, or your RStudio Project isn't open
  at the repository root.
- **Red error mentioning "there is no package called ..."**: go back to
  STEP 0 and install the missing package with `install.packages("name")`.
- **A function's behavior is unclear**: type `?functionName` in the
  Console (e.g. `?initScenario`) to open its help page.
- Still stuck? Open an
  [Issue on this repository's GitHub page](https://github.com/lenaclopez-stack/optimlanduse/issues)
  describing what you ran and the exact error message you saw.
