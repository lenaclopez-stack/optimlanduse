# ------------------------------------------------------------------
# lesson08.R  (code of lessons/lesson08_pareto_engine.md)
# Built automatically from the lesson text. Run it from the folder
# that contains surselva_course.Rproj (open the .Rproj in RStudio).
# ------------------------------------------------------------------

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

grid_perf <- score_bundles(grid_w, score_matrix, scenario_bundle, bundle_names)
print(summary(grid_perf))

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

frontier <- cbind(as.data.frame(grid_w), as.data.frame(grid_perf))[on_front, ]
rownames(frontier) <- NULL
print(summary(frontier[, bundle_names]))

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

frontier_out <- frontier
names(frontier_out)[match(land_use_ids, names(frontier_out))] <- land_use_labels
write.csv(round(frontier_out, 4), file.path("output", "tables", "table_pareto_frontier_all_portfolios.csv"),
          row.names = FALSE)
cat("Saved", nrow(frontier_out), "Pareto-efficient portfolios.\n")
