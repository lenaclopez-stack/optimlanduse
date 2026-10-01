#!/usr/bin/env python3
"""Extract the runnable R code from the lesson files into scripts/.

Every code block in lessons/*.md that is preceded by a line
    <!--run-->            -> goes to scripts/lessonNN.R
    <!--run:name.R-->     -> goes to scripts/name.R
is copied (in order) into the script, so the lessons and the scripts can never
disagree. Also writes scripts/run_all.R.
(You do NOT need Python to use the course - the scripts are already built.)
"""
import re, glob, os, collections

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
pat = re.compile(r"<!--run(?::([\w\.]+))?-->\s*\n```r\n(.*?)\n```", re.S)
files = collections.OrderedDict()
for path in sorted(glob.glob(os.path.join(root, "lessons", "lesson*.md"))):
    base = os.path.basename(path)
    nn = base[6:8]
    text = open(path, encoding="utf-8").read()
    for m in pat.finditer(text):
        target = m.group(1) or f"lesson{nn}.R"
        files.setdefault(target, {"lesson": int(nn), "src": base, "chunks": []})
        files[target]["chunks"].append(m.group(2))

os.makedirs(os.path.join(root, "scripts"), exist_ok=True)
for name, d in files.items():
    header = (f"# ------------------------------------------------------------------\n"
              f"# {name}  (code of lessons/{d['src']})\n"
              f"# Built automatically from the lesson text. Run it from the folder\n"
              f"# that contains surselva_course.Rproj (open the .Rproj in RStudio).\n"
              f"# ------------------------------------------------------------------\n\n")
    with open(os.path.join(root, "scripts", name), "w", encoding="utf-8") as f:
        f.write(header + "\n\n".join(d["chunks"]) + "\n")

# Files that make up the complete analysis, in order (lesson number = gate)
core = ["lesson01.R", "lesson04_theme.R", "lesson05.R", "lesson06_inputs.R",
        "lesson06.R", "lesson07.R", "lesson08.R", "lesson09.R", "lesson10.R"]
core = [c for c in core if c in files]
run_all = ['# ==================================================================',
 '#  run_all.R  -  runs the WHOLE analysis from start to finish',
 '# ==================================================================',
 '# 1. Open surselva_course.Rproj in RStudio (this sets the working folder).',
 '# 2. Click "Source" (top right of this editor) or type source("run_all.R").',
 '# Results appear in the folders output/figures and output/tables.',
 '#',
 '# UP_TO_LESSON lets you rebuild the state of your R session up to a lesson:',
 '# e.g. 7 runs everything needed for the end of lesson 7 and then stops.',
 '',
 'UP_TO_LESSON <- 10',
 '',
 'if (!file.exists("scripts/lesson05.R")) {',
 '  stop("Cannot find the scripts folder. Open surselva_course.Rproj first, ",',
 '       "or use setwd() to go to the surselva_course folder.")',
 '}',
 '',
 'steps <- data.frame(',
 '  lesson = c(' + ", ".join(str(files[c]["lesson"]) for c in core) + '),',
 '  file   = c(' + ", ".join(f'"{c}"' for c in core) + '),',
 '  stringsAsFactors = FALSE',
 ')',
 '',
 'for (i in seq_len(nrow(steps))) {',
 '  if (steps$lesson[i] <= UP_TO_LESSON) {',
 '    message("\\n>>> Running scripts/", steps$file[i])',
 '    source(file.path("scripts", steps$file[i]), echo = FALSE)',
 '  }',
 '}',
 'message("\\nDone. Look in the folder output/ for your figures and tables.")']
open(os.path.join(root, "scripts", "run_all.R"), "w", encoding="utf-8").write("\n".join(run_all) + "\n")
print("built:", ", ".join(files), "+ run_all.R")
