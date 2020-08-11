# C++ Constants Scanner/Database

Pick the folder of your API (where the headers are) and scan.  This program will catalog all constants so they can be easily referenced with search filters.  You can save the current database in a file and load it up later, and also manage multiple databases of multiple APIs.

### Currently included API databases:

* Windoes 10 API - as of 2020 Aug
* scintilla API v4.4.3

### Sometimes there are duplicates after the scan.  Variations that can affect constant values:

* architecture (x86 vs x64)
* windows version
* and others...

This program will perform all simple calculations, including basic math, bit shifts, and bitwise operations.  Generally when there are duplicates, the first value found is used for calculations.

Planned changes:

* add a framework to allow user-defined values for duplicate constants

Please use the latest AutoHotkey v2 alpha (currently a121).

https://www.autohotkey.com/download/2.0/
