Win32 API Constants for AHK

* Total:   135,279
* Unkonwn: 33,087
* Known:   102,192
* Integer: 78,335
* String:  4,896
* Macros:  18,862
* Dupes:   2,281

Stats DEFINITELY subject to change depending on my experiments.

With this script you can select your "includes" folder for ANY C++ source files and scan all files for constant and their values. Substitutions are automatically made, and calculations are done to resolve as many constants as possible. Generally speaking, macros won't be resolved, but if i find out how to properly calculate what the macros do, then I'll be able to resolve more constants.

PLEASE NOTE:  There are about 367 constants that are integers that also have duplicate values currently.  These 367 potential variances can mushroom into many other different values depending on which constants stem from other constants.

Please double check your math before you take the values in this app as gospel.

Variations that can affect constant values:

* architecture (x86 vs x64)
* windows version
* and others...

I haven't yet got around to fully checking the values of all duplicate constants.  I plan to first check the 367 integer constant duplicates.  It is a work in progress.

Please use the latest AutoHotkey v2 alpha (currently a119).
https://www.autohotkey.com/download/2.0/
