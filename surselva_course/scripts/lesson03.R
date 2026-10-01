# ------------------------------------------------------------------
# lesson03.R  (code of lessons/lesson03_tables_and_dplyr.md)
# Built automatically from the lesson text. Run it from the folder
# that contains surselva_course.Rproj (open the .Rproj in RStudio).
# ------------------------------------------------------------------

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

m["NPV", "TimberForest"]      # one cell
m["NPV", ]                    # the whole NPV row
m[, "AlpinePasture"]          # the whole AlpinePasture column
dim(m)                        # 3 rows, 3 columns

df <- as.data.frame(m)                 # matrix -> data frame
df$indicator <- rownames(m)            # $ picks / creates a column; here we create "indicator"
df

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

expert_scores <- c(0.28, 0.33, 0.30, 0.25, 0.35, 0.29)   # 6 experts, one land use, one value

mean(expert_scores)                      # the mean  -> goes into the "mean" table
sd(expert_scores)                        # the standard deviation -> goes into the "SD" table
sd(expert_scores) / sqrt(length(expert_scores))   # the standard ERROR (SE) = SD / sqrt(n)

means_wide <- as.data.frame(m)
means_wide$indicator <- rownames(m)

means_long <- means_wide %>%
  pivot_longer(cols = -indicator,            # all columns EXCEPT indicator
               names_to  = "landUse",        # the old column names become a column "landUse"
               values_to = "indicatorValue") # the numbers go into "indicatorValue"

means_long

sd_matrix <- m * 0.10                        # fake SDs: 10 % of the mean (just for practice)

sd_long <- as.data.frame(sd_matrix) %>%
  mutate(indicator = rownames(sd_matrix)) %>%
  pivot_longer(cols = -indicator, names_to = "landUse", values_to = "indicatorUncertainty")

both <- left_join(means_long, sd_long, by = c("indicator", "landUse"))
both$direction <- "more is better"           # a constant column: same text in every row
both

dir.create("output", showWarnings = FALSE)
write.csv(both, "output/practice_table.csv", row.names = FALSE)
back <- read.csv("output/practice_table.csv")
stopifnot(nrow(back) == 9)          # stopifnot() stops with an error if the statement is not TRUE
