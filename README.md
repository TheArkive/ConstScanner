# C++ Constants Scanner/Database

* This script is now functional again.
* Some incorrect constant values have been found. As always please do your own double-checking. I'll modify this README when i have reason to believe the full list is completely accurate.
* Parsing of constants has been significantly improved.
* eval() function has been updated and is more accurate with performing calculations within constants.
* In the `Other Dirs` button, you can specify additional individual files, and you can include wildcards to parse entire file patterns and directories (recursive).
* Save data now contains a list of INCLUDES and a sub-list for each INCLUDE contained in each file.

Pick the root header of the API you wish to scan.  This program will catalog all constants so they can be easily referenced with search filters.  You can save the current database in a file and load it up later, and also manage multiple databases of multiple APIs.

### Currently included API databases:

* Windows 10 API - as of 2020 Aug
* Win32 headers from mingw64 (msys2 repo) as of 2020 Dec
* scintilla API v4.4.3

### Sometimes there are duplicates after the scan.  Variations that can affect constant values:

* architecture (x86 vs x64)
* windows version
* and others...

This program will perform all simple calculations, including basic math, bit shifts, and bitwise operations.  Generally when there are duplicates, the first value found is used for calculations.

Planned changes:

* add a framework to allow user-defined values for duplicate constants

Please use the latest AutoHotkey v2 alpha (currently a122).

https://www.autohotkey.com/download/2.0/
