# Lesson 1 – Getting started: R, RStudio, the big picture

**Time:** about 1–1.5 hours  **You will learn:** how to install everything, how R and RStudio work, what the *optimLanduse* package does, and exactly what we are going to build for your Results section.

---

## 1.1 What are we building? (the big picture)

Your paper asks: *"How should land in Surselva be split between six land-use types so that economic, ecological and social goals are all served – and what are the trade-offs between these goals?"*

| Piece of your study | In plain words |
|---|---|
| **6 land-use options** | Timber forest, protection forest, alpine pasture, biodiversity meadows, proforestation, natural regeneration of abandoned land. The model decides what **share (%) of the land** each one gets. The six shares always add up to 100 %. |
| **9 indicators** | The things you measure for every land use. |
| **3 bundles** | *Economic* = NPV + soil rent. *Ecological* = deadwood + carbon sequestration + species richness. *Social* = four stakeholder values (local economy, cultural landscape, biodiversity, living with wildlife) from your 6-expert AHP survey. |
| **mean + standard deviation** | For every land use × indicator you have an average value (the *mean*) and a measure of how unsure we are (*standard deviation*). **These are the only numbers you will have to replace later.** |

By the end of the course you will produce, with one click:

1. **Figure R1** – the *robust compromise* land-use mix (best balance of all 9 indicators).
2. **Figure R2** – how well each indicator is served by that mix.
3. **Table R1** – a *pay-off matrix*: what each bundle gets when you optimise for only one bundle.
4. **Figure R3** – the **Pareto frontier** (the set of best possible trade-offs between economic, ecological and social bundles).
5. **Figure R4** – how the land-use mix changes along the frontier.
6. **Figure R5/R6** – what happens when you are more cautious about uncertainty.
7. Ready-made sentences with the numbers filled in, for your Results text.

### Important honesty note about "the Pareto frontier in the NEWS.md"

You asked for the Pareto frontier "created in the code under NEWS.md". I read **every file** of the repository (all R code, `NEWS.md`, `README.Rmd`, `DESCRIPTION`, help pages). The word "Pareto" does not appear anywhere. `NEWS.md` only lists version changes (0.0.4 → 1.0.0 → 1.1.0) and contains no code.

What the package really does: it finds **one** best-compromise land-use mix (it maximises the performance of the *worst-served* indicator under uncertainty, a so-called *robust max-min* or *reference-point* approach – Knoke et al. 2016). It does **not** draw a Pareto frontier by itself.

So in this course we build the Pareto frontier **ourselves, on top of the package**, in a way that is transparent and checkable:

* we use the package to define the problem and to compute the uncertainty-adjusted performance of any land-use mix;
* we score a very large number of possible land-use mixes (every mix in 5 % steps = 53,130 mixes);
* we keep only the mixes that **nobody beats** on all three bundles at once = the Pareto frontier;
* we **check** our fast calculation against the package's own functions (Lesson 8), so you can say in the paper that it is consistent with *optimLanduse*.

In your Methods you can write this as: *"The Pareto frontier of the three bundles was derived by evaluating the uncertainty-adjusted guaranteed performance (Husmann et al.) of all land-use compositions on a 5 % grid and retaining the non-dominated compositions."* Please let your supervisor confirm this matches how you want to define the frontier.

---

## 1.2 Install R and RStudio

R is the *engine* (the language that does the maths). RStudio is the *dashboard* (a friendly window to use R). You need both.

1. Install **R** from <https://cran.r-project.org/> (choose your operating system, download, install with default settings).
2. Install **RStudio Desktop** (free) from <https://posit.co/download/rstudio-desktop/>.
3. Open RStudio. You will see four areas:

```
+-----------------------+-----------------------+
|  1. SCRIPT EDITOR     |  3. ENVIRONMENT       |
|  (where you write and |  (the "objects" R     |
|   save your code)     |   remembers)          |
+-----------------------+-----------------------+
|  2. CONSOLE           |  4. FILES / PLOTS /   |
|  (where R answers)    |     PACKAGES / HELP   |
+-----------------------+-----------------------+
```

* **Script editor** – your notebook. Code written here can be saved (`.R` files).
* **Console** – R's "answer window". You can type there too, but it is not saved.
* **Plots tab** – where your figures appear.

**The one shortcut you need:** put the cursor on a line of code in the script and press **Ctrl + Enter** (Mac: **Cmd + Enter**). RStudio sends that line to the console and runs it. If you select several lines first, it runs all of them.

---

## 1.3 Open the course as an RStudio *project*

R always works "inside a folder" (called the *working directory*). If R is in the wrong folder, it cannot find your files – the most common beginner problem.

The easy fix: **double-click `surselva_course.Rproj`** (or in RStudio: *File → Open Project…*). RStudio now automatically sets the correct folder. You can check:

```r
getwd()
```

`getwd()` means "get working directory". The answer must end in `surselva_course`.

Folder map:

```
surselva_course/
├── surselva_course.Rproj   <- double-click this
├── lessons/                <- the 10 lessons (what you are reading)
├── scripts/                <- the runnable code of each lesson
│   ├── lesson06_inputs.R   <- THE FILE WHERE YOU PUT YOUR REAL MEANS AND SDs
│   └── run_all.R           <- runs the whole analysis
├── output/                 <- appears when you run: figures + tables
└── example_output/         <- what the figures look like with the placeholder data
```

---

## 1.4 Install the packages

A *package* is an add-on for R written by other people. You install it **once** per computer (`install.packages`), and you load it **every time** you start R (`library`).

Run this **once**, in the Console (it needs internet and may take a few minutes):

```r
install.packages(c("dplyr", "tidyr", "ggplot2", "readxl", "patchwork", "optimLanduse"))
```

If R asks *"Do you want to restore a previous session / use a personal library?"* answer **yes**.

What each package is for:

| Package | Purpose in our analysis |
|---|---|
| `optimLanduse` | **The main package** – the robust land-use optimisation. |
| `lpSolveAPI` | Installed automatically with optimLanduse; it is the linear-programming solver inside it. |
| `dplyr`, `tidyr` | Tidying and reshaping tables (lesson 3). |
| `ggplot2` | Making figures (lesson 4). |
| `readxl` | Reading Excel files (needed for the package's example data). |
| `patchwork` | Putting several figures side by side. |

> **Version note.** The code in this course was tested with *optimLanduse* version **1.1.0** (the version in the GitHub repository you sent, `Forest-Economics-Goettingen/optimLanduse`) together with dplyr 1.1.4 and ggplot2 3.4.4. If `install.packages("optimLanduse")` gives you a different version, the course contains an automatic check (Lesson 8) that stops with a clear message if anything behaves differently. To install exactly the GitHub version: `install.packages("remotes")` and then `remotes::install_github("Forest-Economics-Goettingen/optimLanduse")`.

---

## 1.5 Check that everything works

Open the file `scripts/lesson01.R` (File → Open File…) and run it line by line with Ctrl + Enter. Here is the code with explanations:

<!--run-->
```r
# Which packages do we need?
needed <- c("optimLanduse", "lpSolveAPI", "dplyr", "tidyr",
            "ggplot2", "readxl", "patchwork")

# Which of them are NOT installed on this computer yet?
missing_packages <- needed[!needed %in% rownames(installed.packages())]

# If any are missing, stop with a helpful message. Otherwise say "all good".
if (length(missing_packages) > 0) {
  stop("Please install these packages first: ",
       paste(missing_packages, collapse = ", "),
       "\n  e.g. install.packages(c(",
       paste0('"', missing_packages, '"', collapse = ", "), "))")
} else {
  message("All packages are installed. You are ready for Lesson 2.")
}

# Show the version of the main package
print(packageVersion("optimLanduse"))
```

**Line by line**

* `needed <- c(...)` – `c()` means "combine". We make a list of package names (text goes in quotes). `<-` is R's arrow: it *stores* the thing on the right under the name on the left.
* `installed.packages()` lists all installed packages; `rownames(...)` takes their names.
* `needed %in% rownames(...)` asks, for each needed package, "is it in that list?" → `TRUE`/`FALSE`. The `!` flips it, so we keep the ones that are **not** there.
* `if (...) { ... } else { ... }` – "if this is true, do A, otherwise do B".
* `stop("text")` – ends the script and prints the text as an error. `message("text")` just prints information.
* `paste(x, collapse = ", ")` glues several texts together into one, separated by commas.
* `print(packageVersion("optimLanduse"))` – shows the installed version (we tested `1.1.0`).

If you see *"All packages are installed"* you are ready.

---

## 1.6 Mini-glossary (come back to this whenever you are lost)

| Word | Meaning |
|---|---|
| **Land-use option** | One of the six land-use types. The package calls it `landUse`. |
| **Indicator** | Something you measure per land use (NPV, deadwood, …). |
| **Bundle** | A group of indicators (economic / ecological / social). The package calls it `indicatorGroup`. |
| **Mean / "indicatorValue"** | The average value of an indicator for a land use. |
| **Uncertainty / "indicatorUncertainty"** | Your standard deviation (or standard error) – how unsure we are about the mean. |
| **u-value** | A "caution dial". The uncertainty is multiplied by `u`. `u = 0` ignores uncertainty; larger `u` means a more risk-averse decision-maker. |
| **Scenario** | One combination of "each indicator turns out low or high". The package works through all of them and protects against the worst. |
| **Performance** | How close an indicator gets to the *best it could possibly get* (0 % = worst case, 100 % = best case). |
| **β (beta) and "guaranteed performance" (1 − β)** | β = the distance of the worst-served indicator from its best. 1 − β is the performance that **every** indicator reaches at least. |
| **Portfolio / composition** | A specific split of land, e.g. 30 % timber forest, 20 % pasture … |
| **Pareto-efficient (non-dominated)** | A portfolio is Pareto-efficient if you cannot improve any bundle without making another bundle worse. |
| **Pareto frontier** | The set of all Pareto-efficient portfolios – "the best possible trade-offs". |

---

## 1.7 Self-check (answer in your head, no code)

1. What is the difference between the Console and the Script editor?
2. What does `<-` do?
3. Why do we open the `.Rproj` file?
4. Does the package draw the Pareto frontier for you? (No – we build it on top of the package, and check it against the package.)

**Next:** Lesson 2 – your first R commands.
