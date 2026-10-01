# ==================================================================
#  run_all.R  -  runs the WHOLE analysis from start to finish
# ==================================================================
# 1. Open surselva_course.Rproj in RStudio (this sets the working folder).
# 2. Click "Source" (top right of this editor) or type source("run_all.R").
# Results appear in the folders output/figures and output/tables.
#
# UP_TO_LESSON lets you rebuild the state of your R session up to a lesson:
# e.g. 7 runs everything needed for the end of lesson 7 and then stops.

UP_TO_LESSON <- 10

if (!file.exists("scripts/lesson05.R")) {
  stop("Cannot find the scripts folder. Open surselva_course.Rproj first, ",
       "or use setwd() to go to the surselva_course folder.")
}

steps <- data.frame(
  lesson = c(1, 4, 5, 6, 6, 7, 8, 9, 10),
  file   = c("lesson01.R", "lesson04_theme.R", "lesson05.R", "lesson06_inputs.R", "lesson06.R", "lesson07.R", "lesson08.R", "lesson09.R", "lesson10.R"),
  stringsAsFactors = FALSE
)

for (i in seq_len(nrow(steps))) {
  if (steps$lesson[i] <= UP_TO_LESSON) {
    message("\n>>> Running scripts/", steps$file[i])
    source(file.path("scripts", steps$file[i]), echo = FALSE)
  }
}
message("\nDone. Look in the folder output/ for your figures and tables.")
