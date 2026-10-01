# Lesson 3 – Tables: matrices, data frames, dplyr and "long" format

**Time:** about 2 hours  **You will learn:** how R stores tables, how to select/filter/summarise them with `dplyr`, how to compute mean and standard deviation of expert answers, and – most importantly – how to turn a "wide" table into the **long** table format that *optimLanduse* requires.

Open `scripts/lesson03.R` or type along.

---

## 3.1 Matrices and data frames

A **matrix** is a rectangular table where *everything has the same type* (all numbers). A **data frame** is a table whose columns can have different types (some text, some numbers). Your input data will be a matrix (numbers only); the package wants a data frame.

<!--run:lesson03.R-->
```r
library(dplyr)
library(tidyr)

# A small matrix: 3 indicators (rows) x 3 land uses (columns). Placeholder numbers!
m <- matrix(c(4500, 1500, 2800,     # row 1: NPV
              120,   40,   90,      # row 2: soil rent
              8,     20,   1),      # row 3: deadwood
            nrow = 3, byrow = TRUE,
            dimnames = list(c("NPV", "SoilRent", "Deadwood"),           # row names
                            c("TimberForest", "ProtectionForest", "AlpinePasture")))  # column names
m
```

* `matrix(values, nrow = 3, byrow = TRUE)` fills the table **row by row** (`byrow = TRUE`). That lets you type the numbers exactly as they will look on the page – one line per indicator. We use this layout for your real data.
* `dimnames = list(rows, columns)` gives names to the rows and columns.

Picking from a matrix: `m[row, column]`.

<!--run:lesson03.R-->
```r
m["NPV", "TimberForest"]      # one cell
m["NPV", ]                    # the whole NPV row
m[, "AlpinePasture"]          # the whole AlpinePasture column
dim(m)                        # 3 rows, 3 columns
```

Turning it into a data frame (and putting the row names into a proper column):

<!--run:lesson03.R-->
```r
df <- as.data.frame(m)                 # matrix -> data frame
df$indicator <- rownames(m)            # $ picks / creates a column; here we create "indicator"
df
```

* `df$indicator` means "the column called indicator of the table df".
* `rownames(m)` returns the row names of the matrix.

---

## 3.2 The pipe `%>%` and the five dplyr verbs

`dplyr` has simple "verbs". The **pipe** `%>%` (say "then") hands the result of one step to the next, so code reads like a recipe: *take the table, then filter, then summarise*.

| Verb | What it does |
|---|---|
| `filter()` | keep rows that satisfy a condition |
| `select()` | keep/drop columns |
| `mutate()` | create or change a column |
| `group_by()` + `summarise()` | calculate something per group |
| `arrange()` | sort rows |

<!--run:lesson03.R-->
```r
indicators <- data.frame(
  id     = c("NPV", "SoilRent", "Deadwood", "CarbonSeq", "SpeciesRichness"),
  bundle = c("Economic", "Economic", "Ecological", "Ecological", "Ecological"),
  stringsAsFactors = FALSE
)

indicators %>% filter(bundle == "Ecological")          # rows of the ecological bundle
indicators %>% select(id)                              # only the id column
indicators %>% mutate(n_letters = nchar(id))           # new column: length of the name
indicators %>% group_by(bundle) %>% summarise(n = n()) # how many indicators per bundle
indicators %>% arrange(desc(id))                       # sort Z -> A
```

* `==` means "is equal to" (two equal signs).
* `n()` counts rows within each group.
* None of these *change* `indicators`; they show a result. To keep a result, store it: `eco <- indicators %>% filter(bundle == "Ecological")`.

---

## 3.3 Mean and standard deviation from experts' answers

Your social indicators come from **6 experts**. Suppose each gave a score for one land use. R's `mean()` and `sd()` give the average and the standard deviation (the usual measure of how much the experts disagree).

<!--run:lesson03.R-->
```r
expert_scores <- c(0.28, 0.33, 0.30, 0.25, 0.35, 0.29)   # 6 experts, one land use, one value

mean(expert_scores)                      # the mean  -> goes into the "mean" table
sd(expert_scores)                        # the standard deviation -> goes into the "SD" table
sd(expert_scores) / sqrt(length(expert_scores))   # the standard ERROR (SE) = SD / sqrt(n)
```

**SD or SE?** The SD describes how much the *individual* answers differ. The SE (= SD ÷ √n) describes how precisely the *mean* is known; with only 6 experts it is about 2.4 times smaller than the SD. The package accepts either as "uncertainty" (its documentation says "typically SE or SD"). You said you will provide the standard deviation, so the course uses the **SD** by default – and it contains a switch (`USE_STANDARD_ERROR`, Lesson 6) in case your supervisor prefers the SE. Whichever you choose, **state it in the Methods and use it consistently**.

---

## 3.4 Wide versus long tables (the key step for the package)

You will naturally *type* your data in **wide** form (one row per indicator, one column per land use). The package needs **long** form: **one row for every combination of indicator × land use**, with columns named exactly:

| indicator | direction | landUse | indicatorValue | indicatorUncertainty |
|---|---|---|---|---|
| NPV | more is better | TimberForest | 4500 | 600 |
| NPV | more is better | ProtectionForest | 1500 | 300 |
| … | … | … | … | … |

`tidyr::pivot_longer()` converts wide → long:

<!--run:lesson03.R-->
```r
means_wide <- as.data.frame(m)
means_wide$indicator <- rownames(m)

means_long <- means_wide %>%
  pivot_longer(cols = -indicator,            # all columns EXCEPT indicator
               names_to  = "landUse",        # the old column names become a column "landUse"
               values_to = "indicatorValue") # the numbers go into "indicatorValue"

means_long
```

Check it: 3 indicators × 3 land uses = **9 rows**.

Now we do the same for a second table (uncertainties) and **join** the two by their shared columns:

<!--run:lesson03.R-->
```r
sd_matrix <- m * 0.10                        # fake SDs: 10 % of the mean (just for practice)

sd_long <- as.data.frame(sd_matrix) %>%
  mutate(indicator = rownames(sd_matrix)) %>%
  pivot_longer(cols = -indicator, names_to = "landUse", values_to = "indicatorUncertainty")

both <- left_join(means_long, sd_long, by = c("indicator", "landUse"))
both$direction <- "more is better"           # a constant column: same text in every row
both
```

* `left_join(a, b, by = ...)` attaches the columns of `b` to `a`, matching rows where `indicator` and `landUse` agree.
* This is exactly the structure of the real analysis in Lesson 6.

**`direction`** tells the package whether a larger value is good (`"more is better"`) or bad (`"less is better"`, e.g. costs). In your study all 9 indicators are "more is better". The text must be written *exactly* like that.

---

## 3.5 Reading and writing files

```r
# Write a table to a CSV file (opens in Excel)
write.csv(both, "output/practice_table.csv", row.names = FALSE)

# Read it back
back <- read.csv("output/practice_table.csv")
```

* `"output/practice_table.csv"` is a *relative path*: from the project folder, into the `output` folder. The folder must exist first: `dir.create("output", showWarnings = FALSE)`.
* `row.names = FALSE` avoids an extra numbered column.
* For Excel files use `readxl::read_excel("file.xlsx")` (Lesson 5 uses it).

A small runnable version:

<!--run:lesson03.R-->
```r
dir.create("output", showWarnings = FALSE)
write.csv(both, "output/practice_table.csv", row.names = FALSE)
back <- read.csv("output/practice_table.csv")
stopifnot(nrow(back) == 9)          # stopifnot() stops with an error if the statement is not TRUE
```

---

## 3.6 Practice

1. In `means_long`, keep only the rows of `TimberForest` (use `filter`).
2. Add a column `bundle` to `both` that says `"Economic"` for NPV and SoilRent and `"Ecological"` for Deadwood (hint: `left_join` with a small table like `indicators`).
3. How many rows would the long table have for **9 indicators × 6 land uses**? (54.)

**Next:** Lesson 4 – making publication-quality figures with `ggplot2`.
