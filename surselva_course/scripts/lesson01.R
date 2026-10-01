# ------------------------------------------------------------------
# lesson01.R  (code of lessons/lesson01_getting_started.md)
# Built automatically from the lesson text. Run it from the folder
# that contains surselva_course.Rproj (open the .Rproj in RStudio).
# ------------------------------------------------------------------

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
