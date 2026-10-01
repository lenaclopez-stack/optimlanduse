# ------------------------------------------------------------------
# lesson06.R  (code of lessons/lesson06_your_data.md)
# Built automatically from the lesson text. Run it from the folder
# that contains surselva_course.Rproj (open the .Rproj in RStudio).
# ------------------------------------------------------------------

library(dplyr)
library(tidyr)

# ---- 1. Do the dimensions and names fit together? ---------------------------
stopifnot(
  "`land_use_ids` and `land_use_labels` must have the same length" =
    length(land_use_ids) == length(land_use_labels),
  "`means` must have one row per indicator and one column per land use" =
    identical(dim(means), c(nrow(indicator_info), length(land_use_ids))),
  "`sds` must have the same size as `means`" =
    identical(dim(sds), dim(means)),
  "Row names of `means` must equal indicator_info$id (same order)" =
    identical(rownames(means), indicator_info$id),
  "Column names of `means` must equal land_use_ids (same order)" =
    identical(colnames(means), land_use_ids),
  "Row/column names of `sds` must equal those of `means`" =
    identical(dimnames(sds), dimnames(means))
)

# ---- 2. Are the numbers valid? ---------------------------------------------------
if (anyNA(means) || anyNA(sds))
  stop("There are missing values (NA) in `means` or `sds`. The package needs a value for every indicator x land use.")
if (any(sds < 0))
  stop("Uncertainties (`sds`) cannot be negative.")
if (!all(indicator_info$direction %in% c("more is better", "less is better")))
  stop('`direction` must be exactly "more is better" or "less is better".')

# An indicator that is identical in all land uses cannot be normalised (0 / 0)
no_variation <- apply(means, 1, function(x) max(x) - min(x) == 0)
if (any(no_variation))
  stop("These indicators have identical means in all land uses: ",
       paste(rownames(means)[no_variation], collapse = ", "))

# ---- 2b. Are the model settings valid? (the package itself only prints a message for typos!) ----
if (!OPTIMISTIC_RULE %in% c("expectation", "uncertaintyAdjustedExpectation"))
  stop('OPTIMISTIC_RULE must be exactly "expectation" or "uncertaintyAdjustedExpectation".')
if (!is.na(FIX_DISTANCE) && (FIX_DISTANCE < 0 || FIX_DISTANCE > 10))
  stop("FIX_DISTANCE must be NA or a number between 0 and 10.")
if (U_VALUE < 0) stop("U_VALUE cannot be negative.")
if (1 / GRID_STEP != round(1 / GRID_STEP)) stop("GRID_STEP must divide 1 exactly (e.g. 0.1, 0.05, 0.025).")

# ---- 3. Standard error instead of standard deviation? ------------------------------
if (USE_STANDARD_ERROR) {
  if (anyNA(N_OBS)) stop("USE_STANDARD_ERROR is TRUE, so N_OBS needs a number for every indicator.")
  sds_used <- sds / sqrt(N_OBS)      # divides each ROW by the square root of its n
} else {
  sds_used <- sds
}

# ---- 4. Soft check for AHP indicators: do priorities sum to ~1 per indicator? -----
social_ids <- indicator_info$id[indicator_info$bundle == "Social"]
row_sums <- rowSums(means[social_ids, , drop = FALSE])
if (any(abs(row_sums - 1) > 0.05))
  message("Note: the social (AHP) means of these indicators do not sum to 1 across land uses: ",
          paste(names(row_sums)[abs(row_sums - 1) > 0.05], collapse = ", "),
          ". That is fine if your AHP scores are scaled differently.")

message("Data checks passed: ", nrow(means), " indicators x ", ncol(means), " land uses.")

# Wide -> long, for the means
means_long <- as.data.frame(means) %>%
  mutate(indicator = rownames(means)) %>%
  pivot_longer(cols = -indicator, names_to = "landUse", values_to = "indicatorValue")

# Wide -> long, for the uncertainties
sds_long <- as.data.frame(sds_used) %>%
  mutate(indicator = rownames(sds_used)) %>%
  pivot_longer(cols = -indicator, names_to = "landUse", values_to = "indicatorUncertainty")

# Join: means + uncertainties + direction + bundle
coef_table <- means_long %>%
  left_join(sds_long, by = c("indicator", "landUse")) %>%
  left_join(indicator_info[, c("id", "direction", "bundle")],
            by = c("indicator" = "id")) %>%
  rename(indicatorGroup = bundle) %>%                         # the package's name for "bundle"
  select(indicatorGroup, indicator, direction, landUse,
         indicatorValue, indicatorUncertainty) %>%
  as.data.frame()

# Final safety checks
stopifnot(nrow(coef_table) == nrow(means) * ncol(means),
          !anyNA(coef_table))

# A note that is added to every figure as long as the data are placeholders
data_note <- if (DATA_ARE_PLACEHOLDERS) "PLACEHOLDER DATA - not real results" else NULL
if (DATA_ARE_PLACEHOLDERS) message("REMINDER: DATA_ARE_PLACEHOLDERS is TRUE - figures are for testing only.")

# The course code is written for exactly these three bundles
stopifnot("indicator_info$bundle must only contain Economic, Ecological and Social" =
            setequal(unique(indicator_info$bundle), c("Economic", "Ecological", "Social")))
bundle_names <- c("Economic", "Ecological", "Social")

print(head(coef_table, 10))
