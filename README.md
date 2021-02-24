# C++ Constants Scanner/Database

## API Database Files
Get them here: https://github.com/TheArkive/ConstScannerDataFiles

Place these files in the data directory.

Load them up with the menu:  Data > Load Constants

## Highlights
* Flexible and searchable database for referencing API constants.
* Select source C++ header and optionally define additioinal #INCLUDES, or entire directories to scan for more headers/constants.
* Setup this script with a compiler of your choice for checking constants (recommended MSVC BuildTools or GCC variant, like MinGW32/64 or TDGCC).
* Easily compile constants into a small test program to check constant value from the compiler of your choice.
* After scanning, a searchable Includes List is generated, showing child includes for each listed include.
* Catalogs structs, enums, and #define entries.

## Details

This script is for making the process of exploring API functions easier.  You can generate and search lists that contain constants for a selected API.  Each constant is logged with lots of data, like src file and line number, so you can easily track down where that constant is in the source code.  You can also optionally do a quick check of the constant value through a compiler.

Currently this script attempts to resolve constant values without the compiler, but only does so for simple math expressions.  Since this script allows you to check the constant value through the compiler, I will be updating this script over time as I learn the various ways numbers are expressed in C++ (ie. type casting) so that more correct values can be returned without the need for using the compiler.

Constant values that can be resolved, or types that can be determined, are categorized to assist with searching.  The rest are left as "Unknown".  The "Other" type usually describes constants that are structs, enums, arrays, or an alias for a macro or function.

It is important to note that the "scanner" portion of this script is not "hyper intelligent".  A single constant can have multiple values if overlapping versions of headers are parsed, or depending on how certain user-defined constant values are set.  Some constants rely on user-defined values in order to be properly populated/exposed (see the documentation of the API you want to scan to find out what those constants might be).  So generally, programatically resolving all constants in a large API, like the Windows 10 API, isn't completely feasible, especially if trying to collect all the constants in such a large set of headers.  Because of this, it is also not feasible to be able to test/compile all constants unless the proper user-defined constants are entered into the source code before compiling.  Providing the ability to define constants prior to compiling/testing is planned, but is currently not supported.


Constant values with multiple definitions are referred to as "Dupes" in the GUI of the script.  "Critical" constants are defined as those whose value depends on one or more "Dupes".  You can filter out critical and dupe constants if desired.  You can also see all the dupe and critical info for each constant that has this type of info.

## Planned changes:

* Add a framework to allow user-defined values for constants before testing/compiling.

Please use the latest AutoHotkey v2 alpha (currently a125).

https://www.autohotkey.com/download/2.0/
