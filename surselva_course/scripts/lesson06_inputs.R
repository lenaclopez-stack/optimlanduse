# ------------------------------------------------------------------
# lesson06_inputs.R  (code of lessons/lesson06_your_data.md)
# Built automatically from the lesson text. Run it from the folder
# that contains surselva_course.Rproj (open the .Rproj in RStudio).
# ------------------------------------------------------------------

# ==============================================================================
#  >>>  THE ONLY FILE YOU HAVE TO EDIT WHEN YOUR REAL DATA ARRIVE  <<<
#  All numbers below are INVENTED PLACEHOLDERS for testing the workflow.
# ==============================================================================

# ---- A. Is this still placeholder data? ---------------------------------------
# While TRUE, every figure carries a red warning caption. Set to FALSE once the
# means and SDs below are your REAL values.
DATA_ARE_PLACEHOLDERS <- TRUE

# ---- B. The six land uses -------------------------------------------------------
# ids: short, no spaces, no special characters (used inside the code)
land_use_ids    <- c("TimberForest", "ProtectionForest", "AlpinePasture",
                     "BiodivMeadow", "ProForestation",   "NatRegeneration")
# labels: nice names for figures and tables (same ORDER as the ids!)
land_use_labels <- c("Timber forest", "Protection forest", "Alpine pasture",
                     "Biodiversity meadows", "Proforestation", "Natural regeneration")

# ---- C. The nine indicators and their bundles -----------------------------------
indicator_info <- data.frame(
  id        = c("NPV", "SoilRent",
                "Deadwood", "CarbonSeq", "SpeciesRichness",
                "LocalEconomy", "CulturalLandscape", "BiodiversityValue", "WildlifeCoexistence"),
  label     = c("NPV", "Soil rent",
                "Deadwood", "Carbon sequestration", "Species richness",
                "Local economy", "Cultural landscape", "Biodiversity (value)", "Living with wildlife"),
  bundle    = c("Economic", "Economic",
                "Ecological", "Ecological", "Ecological",
                "Social", "Social", "Social", "Social"),
  direction = rep("more is better", 9),    # use "less is better" for costs etc.
  stringsAsFactors = FALSE
)

# ---- D. THE MEANS (one row per indicator, one column per land use) ---------------
#                       Timber  Protect  Pasture  Meadow  ProFor  NatReg
means <- matrix(c(
  # --- Economic ---
                        4500,   1500,    2800,    900,    -300,   200,     # NPV (CHF/ha)
                          60,     15,      95,     35,       0,    10,     # SoilRent (CHF/ha/yr)
  # --- Ecological ---
                           8,     20,       1,      2,      45,    25,     # Deadwood (m3/ha)
                         6.0,    5.0,     0.5,    0.8,     7.5,   4.0,     # CarbonSeq (t CO2/ha/yr)
                          35,     42,      48,     68,      55,    60,     # SpeciesRichness (species/plot)
  # --- Social (AHP priorities from the 6 experts; each row sums to 1) ---
                        0.30,   0.12,    0.30,   0.12,    0.06,  0.10,     # LocalEconomy
                        0.12,   0.10,    0.35,   0.28,    0.05,  0.10,     # CulturalLandscape
                        0.06,   0.16,    0.10,   0.28,    0.22,  0.18,     # BiodiversityValue
                        0.20,   0.20,    0.25,   0.15,    0.08,  0.12      # WildlifeCoexistence
  ), nrow = 9, byrow = TRUE,
  dimnames = list(indicator_info$id, land_use_ids))

# ---- E. THE STANDARD DEVIATIONS (same layout as the means!) ----------------------
#                       Timber  Protect  Pasture  Meadow  ProFor  NatReg
sds <- matrix(c(
  # --- Economic ---
                         600,    300,     500,     250,    150,    150,     # NPV
                          12,      5,      15,       8,      3,      4,     # SoilRent
  # --- Ecological ---
                           2,      4,     0.5,     0.8,      8,      6,     # Deadwood
                         0.8,    0.7,     0.2,     0.3,    1.2,    0.9,     # CarbonSeq
                           4,      5,       5,       7,      6,      7,     # SpeciesRichness
  # --- Social ---
                        0.04,   0.03,    0.05,    0.03,   0.02,   0.03,     # LocalEconomy
                        0.03,   0.03,    0.05,    0.05,   0.02,   0.03,     # CulturalLandscape
                        0.02,   0.04,    0.03,    0.06,   0.05,   0.04,     # BiodiversityValue
                        0.05,   0.05,    0.06,    0.04,   0.03,   0.04      # WildlifeCoexistence
  ), nrow = 9, byrow = TRUE,
  dimnames = list(indicator_info$id, land_use_ids))

# ---- F. Is your uncertainty a standard deviation or a standard error? ------------
# FALSE = the numbers in "sds" are used as they are (standard deviations).
# TRUE  = "sds" are divided by sqrt(n) first (turning SDs into standard errors).
USE_STANDARD_ERROR <- FALSE
# Number of observations behind each indicator (same order as indicator_info).
# Only used when USE_STANDARD_ERROR <- TRUE. Social indicators: 6 experts.
N_OBS <- c(NA, NA, NA, NA, NA, 6, 6, 6, 6)

# ---- G. Model settings (see Lesson 5.3 and 7.1) ---------------------------------
U_VALUE         <- 1                  # caution dial for the main analysis
OPTIMISTIC_RULE <- "expectation"      # or "uncertaintyAdjustedExpectation"
FIX_DISTANCE    <- NA                 # NA = off (recommended, see Lesson 5.3)
DIGITS          <- 6                  # precision of the optimisation (decimals of beta)

# ---- H. Settings for the Pareto frontier and sensitivity (Lessons 8-10) --------
GRID_STEP <- 0.05                     # 0.05 = test every mix in 5 % steps (53,130 mixes)
U_SWEEP   <- seq(0, 3, by = 0.5)      # u-values for the sensitivity figure (Lesson 10)
U_COMPARE <- c(0, 1, 2)               # u-values for the frontier comparison (Lesson 10)
