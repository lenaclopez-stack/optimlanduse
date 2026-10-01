# ------------------------------------------------------------------
# lesson02.R  (code of lessons/lesson02_r_basics.md)
# Built automatically from the lesson text. Run it from the folder
# that contains surselva_course.Rproj (open the .Rproj in RStudio).
# ------------------------------------------------------------------

2 + 3
10 / 4
2 ^ 3          # power: 2 to the power of 3
(5 + 3) * 2    # brackets work as in maths

npv_timber <- 4500      # store the number 4500 in a box called npv_timber
npv_timber              # typing the name shows what is inside
npv_timber * 2          # use it in a calculation

land_use <- "Timber forest"   # text must be in quotes
land_use

npv <- c(4500, 1500, 2800, 900, -300, 200)    # NPV of 6 land uses (placeholder numbers)
names(npv) <- c("Timber", "Protection", "Pasture", "Meadow", "ProFor", "NatReg")
npv

npv * 2                 # operations work on every element
sum(npv)                # add them up
mean(npv)               # average
sd(npv)                 # standard deviation
max(npv); min(npv)      # biggest / smallest (the ; lets you put two commands on one line)
length(npv)             # how many elements
round(mean(npv), 1)     # round to 1 decimal

npv[1]                  # the first element
npv[c(1, 3)]            # elements 1 and 3
npv["Pasture"]          # by name
npv[npv > 1000]         # only elements that are bigger than 1000

round(3.14159, digits = 2)   # round() has an argument called digits
seq(from = 0, to = 1, by = 0.25)   # a sequence: 0, 0.25, 0.5, 0.75, 1
rep(1, times = 6)            # repeat the value 1 six times

# A function that turns a standard deviation into a standard error
# sd = standard deviation, n = number of observations
sd_to_se <- function(sd, n) {
  sd / sqrt(n)
}

sd_to_se(sd = 0.05, n = 6)    # SE if 6 experts gave the answers

bundle <- c("Economic", "Economic", "Ecological", "Ecological", "Ecological")
bundle == "Economic"                 # TRUE TRUE FALSE FALSE FALSE
unique(bundle)                       # the distinct values
table(bundle)                        # how often each occurs

x <- c(1, 2, NA, 4)                  # NA = missing value
mean(x)                              # NA! one missing value poisons the result
mean(x, na.rm = TRUE)                # na.rm = TRUE means "ignore the NAs"
anyNA(x)                             # TRUE: is there any missing value?
