# Lesson 2 – R basics: objects, vectors, functions and errors

**Time:** about 1.5 hours  **You will learn:** to store values in *objects*, work with *vectors*, call *functions*, use comparisons, read the help, and understand error messages. Everything here is used later in the real analysis.

Type each code block into a new script (File → New File → R Script) or open `scripts/lesson02.R`, and run it with Ctrl + Enter. **Typing it yourself teaches you more than copy-pasting.**

---

## 2.1 R as a calculator

<!--run:lesson02.R-->
```r
2 + 3
10 / 4
2 ^ 3          # power: 2 to the power of 3
(5 + 3) * 2    # brackets work as in maths
```

* Text after a `#` is a **comment**. R ignores it. Use comments to explain your code to your future self.
* In the Console you will see `[1] 5`, `[1] 2.5` … The `[1]` just means "first element of the answer".

---

## 2.2 Objects: giving values a name

An *object* is a named box that holds a value. You make one with the arrow `<-`.

<!--run:lesson02.R-->
```r
npv_timber <- 4500      # store the number 4500 in a box called npv_timber
npv_timber              # typing the name shows what is inside
npv_timber * 2          # use it in a calculation

land_use <- "Timber forest"   # text must be in quotes
land_use
```

* Object names are case-sensitive: `npv_timber` and `NPV_timber` are different.
* Use letters, numbers, `_` and `.`; start with a letter; **no spaces**. (This matters for our land-use names later: we call them `TimberForest`, not `Timber forest`, inside the code, because some package functions break with awkward names.)
* Overwriting: `npv_timber <- 5000` replaces the old value.
* Look at the **Environment** pane: it lists every object R currently remembers.

---

## 2.3 Vectors: several values in one object

`c()` ("combine") puts several values in one object. That is a **vector**.

<!--run:lesson02.R-->
```r
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
```

**Picking elements** with square brackets `[ ]`:

<!--run:lesson02.R-->
```r
npv[1]                  # the first element
npv[c(1, 3)]            # elements 1 and 3
npv["Pasture"]          # by name
npv[npv > 1000]         # only elements that are bigger than 1000
```

`npv > 1000` is a **comparison**. It gives `TRUE`/`FALSE` for each element, and `[ ]` keeps the `TRUE` ones. Other comparisons: `<`, `>=`, `<=`, `==` (equal – two equal signs!), `!=` (not equal).

---

## 2.4 Functions: the verbs of R

A **function** does something. It has a name, then brackets with *arguments* (the inputs):

```
function_name(argument1 = value, argument2 = value)
```

<!--run:lesson02.R-->
```r
round(3.14159, digits = 2)   # round() has an argument called digits
seq(from = 0, to = 1, by = 0.25)   # a sequence: 0, 0.25, 0.5, 0.75, 1
rep(1, times = 6)            # repeat the value 1 six times
```

* Arguments have **names**. You can leave the names out if you keep the usual order (`round(3.14159, 2)`), but names make code easier to read. The package functions we use later have many arguments (e.g. `initScenario(coefTable = ..., uValue = ..., ...)`), so naming them is wise.
* **Help:** type `?round` in the Console and press Enter. The Help pane shows the description, arguments and examples. For the package: `?initScenario`, `?solveScenario`, `?calcPerformance`.

You can write your own function:

<!--run:lesson02.R-->
```r
# A function that turns a standard deviation into a standard error
# sd = standard deviation, n = number of observations
sd_to_se <- function(sd, n) {
  sd / sqrt(n)
}

sd_to_se(sd = 0.05, n = 6)    # SE if 6 experts gave the answers
```

`function(sd, n) { ... }` defines the inputs; the last line inside `{ }` is what comes out. We will write a few such functions in the Pareto lessons – they just package a calculation so you can reuse it.

---

## 2.5 Text, logical values, and "missing" values

<!--run:lesson02.R-->
```r
bundle <- c("Economic", "Economic", "Ecological", "Ecological", "Ecological")
bundle == "Economic"                 # TRUE TRUE FALSE FALSE FALSE
unique(bundle)                       # the distinct values
table(bundle)                        # how often each occurs

x <- c(1, 2, NA, 4)                  # NA = missing value
mean(x)                              # NA! one missing value poisons the result
mean(x, na.rm = TRUE)                # na.rm = TRUE means "ignore the NAs"
anyNA(x)                             # TRUE: is there any missing value?
```

`NA` is R's "not available". The package refuses data that contain `NA`, so later we check for it.

---

## 2.6 Reading error messages (a survival skill)

Errors are normal. Even experts see them all day. An error message tells you **what** went wrong and usually **where**.

The following examples are NOT run automatically (they would stop a script). Type them into the Console to see what errors look like:

```r
npv_timbr * 2
# Error: object 'npv_timbr' not found      -> typo in the name (it is npv_timber)

mean(c(1, 2, 3)
# (R waits with a "+" prompt)                -> a closing bracket is missing. Press Esc.

library(notapackage)
# Error: there is no package called 'notapackage'  -> not installed, or misspelled

round("abc")
# Error: non-numeric argument to mathematical function -> you gave text where a number is needed
```

**Troubleshooting checklist**

1. Read the error text. Which object or function does it name?
2. Check spelling, capital letters, quotes, brackets and commas.
3. Did you run all previous lines? (Objects only exist after you ran the line that creates them.)
4. Is the package loaded with `library(...)`?
5. Copy the first line of the error and search for it online – someone else has had it.

**Warnings** (yellow/orange) are different from errors: the code still ran, but R wants you to look. Read them; do not ignore them.

---

## 2.7 Practice (5 minutes)

1. Create a vector `carbon <- c(6, 5, 0.5, 0.8, 7.5, 4)` (t CO2/ha/yr).
2. Find its mean and the position of its largest value (`which.max(carbon)`).
3. Which land uses (positions) have carbon above the mean? (`carbon > mean(carbon)`)

**Next:** Lesson 3 – tables (data frames), `dplyr`, and reshaping data.
