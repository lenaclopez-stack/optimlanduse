# Lesson 8 – The Pareto frontier, part 1: scoring thousands of land-use mixes

**Time:** about 2.5 hours  **You will learn:** what "Pareto-efficient" means, how to turn the package's scenario table into a fast scoring tool (and prove that it agrees with the package), how to generate every land-use mix on a grid, how to filter out the dominated ones, and how to build the pay-off matrix of bundles (Table R1).

---

## 8.1 The concept, step by step

You have three goals (bundles): **Economic**, **Ecological**, **Social**. For *any* land-use mix (portfolio) we can compute how well each bundle is served. We measure it as the bundle's **guaranteed performance**: the performance of the worst-served indicator of that bundle in its worst uncertainty scenario (0 = as bad as the worst land use, 1 = as good as the best land use). This is the same quantity the package reports as `1 − β` – but now computed **per bundle**.

So every portfolio becomes a point with three coordinates:

```
portfolio  →  (Economic score, Ecological score, Social score)
```

Portfolio **A dominates** portfolio **B** if A is at least as good on all three scores and strictly better on at least one. B is then pointless: A is better for everyone. A portfolio that nobody dominates is **Pareto-efficient**. The set of all Pareto-efficient portfolios is the **Pareto frontier**.

*Example with two goals:* A = (0.8, 0.4), B = (0.6, 0.4), C = (0.5, 0.7). A dominates B (better economy, same ecology). A and C do not dominate each other (A is better economically, C is better ecologically) → both are on the frontier. Moving along the frontier means **trading** one goal for another – this trade-off is what your paper shows.

**How we find it – two complementary routes**

1. **The package's own Pareto option (exact, two bundles at a time).** `solveScenario(paretoY = …, paretoX = …, paretoMaxDistance = …)` (new in optimLanduse 2.0.0) maximises the guaranteed performance of the Y indicators while the X indicators must reach at least the level `paretoMaxDistance`. Repeating it for levels from 0 to the maximum traces the exact trade-off curve between two bundles.
2. **A grid search over all land-use mixes (approximate, all three bundles together).** We (a) generate every mix in 5 % steps, (b) score each on the three bundles, (c) throw away every dominated mix. The package can only constrain one set of X indicators, so it cannot give the full three-bundle surface; the grid can.

The two routes are **used to check each other**: no grid mix may ever be better than the package's exact curve, and the exact optimum of each bundle (also computed by the package) must be at least as high as the grid's best.

---

## 8.2 Step 1 – A fast scoring tool built on the package's scenario table

`calcPerformance()` from the package scores **one** portfolio in about 0.1 s. For the grid we need ~53,000 portfolios (and for the exact curves we need the three bundle scores of each point), so we use the same arithmetic in a vectorised form. For each scenario row, the package defines (see `defineConstraintCoefficients` and `calcPerformance` in the package source):

* "more is better": performance = (value − min) / range,
* "less is better": performance = (max − value) / range,

where the *value* of a portfolio is the share-weighted sum of the land-use values, and `min`, `max`, `range` are stored in the scenario table (`minAdjSem`, `maxAdjSem`, `diffAdjSem`). Because the value is linear in the shares, the performance of a portfolio in a scenario is simply

```
performance(portfolio, scenario) = Σ over land uses  share × A[scenario, land use]
```

where `A` is a fixed table ("scoring matrix"). We build `A` once.

<!--run-->
```r
library(optimLanduse)

# ---- Build the scoring matrix A from an initialised object -----------------
# Rows = scenarios, columns = land uses.
build_scoring_matrix <- function(init) {
  st   <- init$scenarioTable
  adj  <- as.matrix(st[, paste0("adjSem", names(init$landUse))])  # uncertainty-adjusted values
  more <- st$direction == "more is better"

  A <- adj                                              # same shape; we overwrite it below
  A[more, ]  <- (adj[more, , drop = FALSE]  - st$minAdjSem[more])  / st$diffAdjSem[more]
  A[!more, ] <- (st$maxAdjSem[!more] - adj[!more, , drop = FALSE]) / st$diffAdjSem[!more]
  colnames(A) <- names(init$landUse)
  A
}

score_matrix       <- build_scoring_matrix(init_all)
scenario_indicator <- init_all$scenarioTable$indicator
scenario_bundle    <- indicator_info$bundle[match(scenario_indicator, indicator_info$id)]

cat("Scoring matrix:", nrow(score_matrix), "scenarios x", ncol(score_matrix), "land uses\n")
```

**Explanation**

* `paste0("adjSem", names(init$landUse))` builds the column names `adjSemTimberForest`, … These columns hold the uncertainty-adjusted indicator values of each land use in each scenario (low or high outcome).
* `more` is `TRUE` for "more is better" rows.
* `A[more, ] <- (adj[more, ] - min) / range` – rows of "more is better" scenarios.
* `A[!more, ]` – the same for "less is better" (not used in your data, but the code is general). `!` means "not".
* `match(scenario_indicator, indicator_info$id)` finds, for each scenario row, which indicator it belongs to; then `indicator_info$bundle[...]` gives its bundle. So `scenario_bundle` says for each of the 576 scenario rows whether it is economic, ecological or social.

## 8.3 Step 2 – The function that scores portfolios on the three bundles

<!--run-->
```r
# W: a table of portfolios (one row per portfolio, one column per land use, rows sum to 1)
# Result: for each portfolio, the guaranteed performance of each bundle
score_bundles <- function(W, A, scen_bundle, bundles, chunk_size = 5000) {
  W   <- as.matrix(W)
  out <- matrix(NA_real_, nrow = nrow(W), ncol = length(bundles),
                dimnames = list(NULL, bundles))
  starts <- seq(1, nrow(W), by = chunk_size)          # work in chunks to save memory
  for (s in starts) {
    idx <- s:min(s + chunk_size - 1, nrow(W))
    P   <- W[idx, , drop = FALSE] %*% t(A)             # performance in every scenario
    for (b in bundles) {
      out[idx, b] <- apply(P[, scen_bundle == b, drop = FALSE], 1, min)   # worst scenario of bundle b
    }
  }
  out
}

# Scores of single indicators (worst scenario of each indicator) for ONE portfolio
score_indicators <- function(w, A, scen_indicator) {
  p <- as.numeric(A %*% as.numeric(w))
  tapply(p, scen_indicator, min)
}
```

**Explanation**

* `W %*% t(A)` is matrix multiplication: each portfolio (row of `W`) times each scenario (row of `A`) = a table of 5,000 × 576 performances.
* `apply(P[, scen_bundle == b], 1, min)` – for each portfolio take the **minimum** across the scenarios of bundle `b` = the guaranteed performance of that bundle.
* Working in chunks keeps memory use small on an ordinary laptop.
* `NA_real_` is a missing number used to pre-fill the result.

## 8.4 Step 3 – PROVE that the fast tool agrees with the package

This is the "no errors" safeguard. We take 5 random portfolios, score them with (a) our fast function, (b) the package's `calcPerformance()`, and (c) the package's solver with the portfolio fixed through `lowerBound = upperBound` (the method the package README uses for the pay-off matrix). The script **stops** if they disagree.

<!--run-->
```r
n_lu <- length(land_use_ids)

set.seed(1)                                   # the test portfolios are random but reproducible
test_w <- matrix(rexp(5 * n_lu), nrow = 5)    # random positive numbers ...
test_w <- test_w / rowSums(test_w)            # ... scaled so that each row sums to 1
colnames(test_w) <- land_use_ids

fast <- score_bundles(test_w, score_matrix, scenario_bundle, bundle_names)

for (i in 1:5) {
  # (b) package: put the portfolio into the object and let calcPerformance score it
  tmp <- init_all
  tmp$landUse[1, ] <- test_w[i, ]
  tmp$status <- "optimized"
  official <- calcPerformance(tmp)$scenarioTable
  official_bundle <- tapply(official$performance, scenario_bundle, min)[bundle_names]

  if (!isTRUE(all.equal(as.numeric(official_bundle), as.numeric(fast[i, ]), tolerance = 1e-8)))
    stop("Check failed: the fast scoring differs from calcPerformance(). ",
         "The installed optimLanduse version may differ from the tested one (2.0.0).")
}

# (c) package solver with the portfolio fixed: 1 - beta must equal the lowest bundle score
fixed <- solveScenario(init_all, digitsPrecision = DIGITS,
                       lowerBound = test_w[1, ], upperBound = test_w[1, ])
if (abs((1 - fixed$beta) - min(fast[1, ])) > 1e-4)
  stop("Check failed: solveScenario() with fixed bounds disagrees with the fast scoring.")

message("Check passed: the fast scoring agrees with calcPerformance() and solveScenario().")
```

**Explanation**

* `rexp(n)` draws positive random numbers; dividing each row by its sum gives random portfolios that add up to 1.
* `tmp$landUse[1, ] <- test_w[i, ]` writes the test portfolio into a copy of the object. `calcPerformance()` only needs the portfolio and the status.
* `tapply(values, groups, min)` takes the minimum of `values` within each group (here: each bundle).
* `all.equal(a, b, tolerance = 1e-8)` – "equal within tiny rounding differences".
* `lowerBound = upperBound = portfolio` forces the solver to use exactly this portfolio, and `1 − β` is then the lowest performance across all scenarios = the lowest bundle score.

If this ever stops with an error after you changed something, **do not continue** – tell your supervisor; it means the scoring does not match the package.

---

## 8.5 Step 4 – Generate every land-use mix on a grid

If we use 5 % steps, a portfolio is 20 "blocks" of 5 % distributed over 6 land uses. The number of ways is "20 blocks into 6 boxes" = 53,130.

Classic trick ("stars and bars"): line up 20 blocks and 5 dividers (25 positions); choose which 5 positions are dividers; the numbers of blocks between the dividers are the six shares.

<!--run-->
```r
make_grid <- function(n_options, step) {
  n_units <- round(1 / step)                          # e.g. 20 blocks of 5 %
  if (abs(n_units * step - 1) > 1e-9) stop("GRID_STEP must divide 1 exactly (e.g. 0.1, 0.05, 0.025, 0.01).")
  n_slots <- n_units + n_options - 1                  # blocks + dividers
  bars    <- t(combn(n_slots, n_options - 1))         # every way to place the dividers
  edges   <- cbind(0, bars, n_slots + 1)              # add the two outer edges
  parts   <- edges[, -1, drop = FALSE] - edges[, -ncol(edges), drop = FALSE] - 1
  parts / n_units                                     # shares between 0 and 1
}

grid_w <- make_grid(n_lu, GRID_STEP)
colnames(grid_w) <- land_use_ids

cat("Number of land-use mixes on the grid:", nrow(grid_w), "\n")
stopifnot(nrow(grid_w) == choose(round(1 / GRID_STEP) + n_lu - 1, n_lu - 1),
          all(abs(rowSums(grid_w) - 1) < 1e-9),
          all(grid_w >= 0))
print(head(round(grid_w * 100), 4))       # first few mixes in percent
```

**Explanation**

* `combn(25, 5)` lists all ways of choosing 5 positions out of 25 (as columns); `t()` turns them into rows.
* The differences between neighbouring divider positions (minus 1) are the numbers of blocks in each box.
* `choose(n, k)` is the mathematical "n choose k" – we use it to verify the number of mixes.
* With `GRID_STEP = 0.05` you get **53,130** mixes. The check confirms each mix adds to 100 % and has no negative shares.
* The grid contains all "pure" portfolios (100 % of one land use) and all two-way, three-way … mixes.

## 8.6 Step 5 – Score the whole grid

<!--run-->
```r
grid_perf <- score_bundles(grid_w, score_matrix, scenario_bundle, bundle_names)
print(summary(grid_perf))
```

(This takes some seconds. `grid_perf` has one row per mix and one column per bundle.)

---

## 8.7 Step 6 – Keep only the Pareto-efficient mixes

<!--run-->
```r
# P: matrix with one row per portfolio, one column per goal. Larger = better.
# Returns TRUE for rows that no other row dominates.
is_pareto_efficient <- function(P, tol = 1e-9) {
  P <- as.matrix(P)
  n <- nrow(P); k <- ncol(P)

  # Sort so that any portfolio that could dominate another comes BEFORE it:
  # best first on goal 1, ties broken by goal 2, then goal 3, ...
  ord <- do.call(order, lapply(seq_len(k), function(j) -P[, j]))
  Ps  <- P[ord, , drop = FALSE]

  front   <- matrix(NA_real_, nrow = n, ncol = k)   # the efficient points found so far
  n_front <- 0
  keep    <- logical(n)

  for (i in seq_len(n)) {
    p <- Ps[i, ]
    dominated <- FALSE
    if (n_front > 0) {
      D <- front[seq_len(n_front), , drop = FALSE] -
           matrix(p, nrow = n_front, ncol = k, byrow = TRUE)
      # a front point dominates p if it is >= p everywhere and > p somewhere
      dominated <- any(rowSums(D >= -tol) == k & rowSums(D > tol) > 0)
    }
    if (!dominated) {
      n_front <- n_front + 1
      front[n_front, ] <- p
      keep[i] <- TRUE
    }
  }

  result <- logical(n)
  result[ord] <- keep            # put the answers back into the ORIGINAL order
  result
}

# Tiny test with the example from 8.1: A = (0.8, 0.4), B = (0.6, 0.4), C = (0.5, 0.7)
test_points <- rbind(A = c(0.8, 0.4), B = c(0.6, 0.4), C = c(0.5, 0.7))
stopifnot(identical(unname(is_pareto_efficient(test_points)), c(TRUE, FALSE, TRUE)))

# Now the real thing: all three bundles at once
on_front <- is_pareto_efficient(grid_perf)
cat("Pareto-efficient mixes:", sum(on_front), "of", length(on_front), "\n")
```

**Explanation**

* A point can only be dominated by a point that is *at least as good on the first goal*. After sorting by goal 1 (then goal 2, then goal 3), all possible dominators come earlier in the list. So each point only needs to be compared with the efficient points found so far. That makes the search fast.
* `D` holds the differences "front point − this point". If all differences are ≥ 0 and at least one is > 0, the point is dominated. `tol` ignores differences of 1e-9 (computer rounding noise).
* `result[ord] <- keep` restores the original order.
* The little test with A, B, C checks the function: the expected answer is `TRUE FALSE TRUE`.

Assemble the frontier table:

<!--run-->
```r
frontier <- cbind(as.data.frame(grid_w), as.data.frame(grid_perf))[on_front, ]
rownames(frontier) <- NULL
print(summary(frontier[, bundle_names]))
```

`frontier` now contains, for each efficient portfolio, its six land-use shares and its three bundle scores.

---

## 8.8 Step 7 – Validate against the package's exact single-bundle optima

For each bundle, `solveScenario()` finds the *exact* best portfolio for that bundle alone (Lesson 7). We score those portfolios on **all three** bundles – this is the **pay-off matrix** (Table R1). Then we compare the best bundle scores found on the grid with the exact ones.

<!--run-->
```r
anchor_w    <- as.matrix(selected[, land_use_ids])           # the four portfolios from Lesson 7
anchor_perf <- score_bundles(anchor_w, score_matrix, scenario_bundle, bundle_names)

payoff <- data.frame(`Optimised for` = selected$portfolio, round(anchor_perf, 3),
                     check.names = FALSE)
print(payoff)
write.csv(payoff, file.path("output", "tables", "table_R1_payoff_matrix.csv"), row.names = FALSE)

# Validation: the best score of each bundle on the grid vs the exact package optimum
exact_best <- sapply(bundle_names, function(b) 1 - results_bundle[[b]]$beta)
grid_best  <- apply(grid_perf, 2, max)[bundle_names]
validation <- data.frame(bundle = bundle_names,
                         exact_package_optimum = round(exact_best, 4),
                         best_on_grid          = round(grid_best, 4),
                         difference            = round(exact_best - grid_best, 4))
print(validation)

if (any(grid_best > exact_best + 1e-3))
  warning("A grid portfolio beats the package optimum - please check the settings.")
```

**Explanation**

* `anchor_perf` rows: the portfolio optimised for Economic / Ecological / Social / all; columns: the guaranteed performance of each bundle for that portfolio. The **diagonal** (portfolio optimised for a bundle, scored on that bundle) is the highest value in each column. Off-diagonal entries show the **cost to the other bundles** of focusing on one goal – the heart of the trade-off. (This is the bundle-level version of the pay-off matrix in the package README.)
* `data.frame(`Optimised for` = ...)` – backticks allow a column name with a space; `check.names = FALSE` keeps it.
* `sapply(bundle_names, function(b) ...)` runs the function over the bundles and returns a vector.
* In the validation table, `difference` should be **small and not negative** (≥ 0): the grid cannot be better than the exact optimum; with a 5 % grid it is typically slightly worse (a few percentage points at most). If the difference is large, use a finer `GRID_STEP`.

---

## 8.9 Step 8 – Exact two-bundle frontiers with the package's Pareto option

For a pair of bundles (e.g. Economic on the x axis, Ecological on the y axis, the third bundle ignored) we call `solveScenario()` with the Pareto arguments for 41 levels of the x bundle. Each call returns one exact frontier point.

<!--run-->
```r
# The Pareto arguments exist only in optimLanduse >= 2.0.0
stopifnot("Please install optimLanduse 2.0.0 or newer (see Lesson 1.4)" =
            all(c("paretoY", "paretoX", "paretoMaxDistance") %in% names(formals(solveScenario))))

bundle_ids <- function(b) indicator_info$id[indicator_info$bundle == b]

# init : an initialised optimLanduse object (any u-value)
# x_bundle, y_bundle : the two bundles on the axes; third_bundle : the remaining one
native_pair_frontier <- function(init, x_bundle, y_bundle, third_bundle, n_points = 41) {
  A_i <- build_scoring_matrix(init)
  sb  <- indicator_info$bundle[match(init$scenarioTable$indicator, indicator_info$id)]

  # Highest possible x performance: maximise the x bundle with no condition on y
  top   <- solveScenario(init, digitsPrecision = DIGITS,
                         paretoY = bundle_ids(x_bundle), paretoX = bundle_ids(y_bundle),
                         paretoMaxDistance = 0)
  x_max <- 1 - top$beta

  # Required x levels from 0 up to (just below) the maximum
  levels <- seq(0, x_max - 1e-5, length.out = n_points)

  rows <- lapply(levels, function(level) {
    r <- solveScenario(init, digitsPrecision = DIGITS,
                       paretoY = bundle_ids(y_bundle),      # maximise this ...
                       paretoX = bundle_ids(x_bundle),      # ... while this stays >= level
                       paretoMaxDistance = level)
    if (r$status != "optimized") return(NULL)
    as.numeric(r$landUse[1, ])
  })
  W <- do.call(rbind, rows)
  colnames(W) <- names(init$landUse)

  perf <- score_bundles(W, A_i, sb, bundle_names)            # score all three bundles
  keep <- is_pareto_efficient(perf[, c(x_bundle, y_bundle)])  # drop weakly dominated points
  out  <- cbind(as.data.frame(W[keep, , drop = FALSE]),
                x = perf[keep, x_bundle], y = perf[keep, y_bundle],
                third = perf[keep, third_bundle])
  out <- out[order(-out$y), ]                            # best y first ...
  out <- out[!duplicated(round(out$x, 5)), ]             # ... so only one point per x value stays
  out <- out[order(out$x), ]
  rownames(out) <- NULL
  out
}

pair_defs   <- combn(bundle_names, 2, simplify = FALSE)   # (Economic, Ecological), (Economic, Social), (Ecological, Social)
pair_fronts <- lapply(pair_defs, function(p)
  native_pair_frontier(init_all, p[1], p[2], setdiff(bundle_names, p)))
names(pair_fronts) <- sapply(pair_defs, paste, collapse = " vs ")
print(sapply(pair_fronts, nrow))     # number of frontier points per pair
```

**Explanation**

* `names(formals(solveScenario))` lists the argument names of the function; we stop with a clear message if the Pareto arguments are missing (old package version).
* `bundle_ids("Economic")` returns the indicator ids of a bundle, e.g. `"NPV"`, `"SoilRent"`. The package takes indicator **names**, so giving it all indicators of a bundle treats the bundle as one objective (its worst indicator in its worst scenario).
* First call: we *swap* the roles (maximise the x bundle, no condition on y: `paretoMaxDistance = 0`) to find the highest performance the x bundle can reach at all, `x_max`.
* `seq(0, x_max - 1e-5, length.out = 41)` – 41 required levels from 0 up to just below `x_max` (the tiny margin avoids a rounding-induced "no solution").
* `lapply(levels, function(level) {...})` – for each level one `solveScenario()` call; `r$landUse[1, ]` is the resulting land-use mix.
* `do.call(rbind, rows)` stacks the mixes into a table; `score_bundles()` (Lesson 8.3) computes the performance of all three bundles for each; `is_pareto_efficient()` removes any point that is not strictly on the two-bundle frontier.
* `duplicated(round(out$x, 5))` keeps a single point per x value (the one with the highest y); the area chart in Lesson 9 needs unique x values.
* The result has the six shares plus `x`, `y` (the two bundle performances) and `third` (the performance of the bundle that was not used). Each row is a **real optimum** found by the package's linear-programming solver, not an approximation.

## 8.10 Cross-check: grid versus the package's exact curve

First we build the grid version of the same curves (best portfolio for the third bundle among ties), then compare.

<!--run-->
```r
pair_frontier_grid <- function(perf, W, a, b, third) {
  eff <- is_pareto_efficient(perf[, c(a, b)])
  out <- cbind(as.data.frame(W[eff, , drop = FALSE]),
               x = perf[eff, a], y = perf[eff, b], third = perf[eff, third])
  out <- out[order(-out$third), ]
  out <- out[!duplicated(round(cbind(out$x, out$y), 6)), ]
  out <- out[order(out$x), ]
  rownames(out) <- NULL
  out
}

compare_tab <- do.call(rbind, lapply(pair_defs, function(p) {
  g <- pair_frontier_grid(grid_perf, grid_w, p[1], p[2], setdiff(bundle_names, p))
  n <- pair_fronts[[paste(p, collapse = " vs ")]]
  # for every exact point: best y reached by ANY grid mix with at least the same x
  grid_y <- sapply(n$x, function(x0) max(c(-Inf, g$y[g$x >= x0 - 1e-9])))
  data.frame(pair = paste(p, collapse = " vs "),
             grid_beats_exact = sum(grid_y > n$y + 1e-4),        # must be 0
             max_gap = round(max((n$y - grid_y)[is.finite(grid_y)]), 3))  # how far the grid falls short
}))
print(compare_tab)

if (any(compare_tab$grid_beats_exact > 0))
  stop("Check failed: a grid mix is better than the package's exact Pareto point.")
message("Check passed: the grid frontier never beats the package's exact frontier.")
```

**Explanation**

* `pair_frontier_grid()` is the grid version of the two-bundle frontier (the same code as in the first version of the course).
* `(n$y - grid_y)[is.finite(grid_y)]` ignores exact points whose x level no grid mix reaches.
* For every exact point `n` we ask: what is the highest `y` that any grid mix achieves with `x` at least as large? If the package's solver is right, the grid can **never** be better (`grid_beats_exact` must be 0) – the script stops otherwise.
* `max_gap` shows how much lower the grid frontier is: it is the price of the 5 % resolution (a few hundredths in guaranteed performance). This is why the black lines in the figures come from the package's exact method, whereas the 3-bundle dots come from the grid.

## 8.11 Save the tables

<!--run-->
```r
frontier_out <- frontier
names(frontier_out)[match(land_use_ids, names(frontier_out))] <- land_use_labels
write.csv(round(frontier_out, 4), file.path("output", "tables", "table_pareto_frontier_all_portfolios.csv"),
          row.names = FALSE)
cat("Saved", nrow(frontier_out), "Pareto-efficient portfolios.\n")
```

**Next:** Lesson 9 – turning this into the figures of your Results section.
