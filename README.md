# C++ Constants Scanner/Database

## API Database Files
Get them here: https://github.com/TheArkive/ConstScannerDataFiles

Place these data files in the script .\data directory.

Load them up with the menu:  Data > Load Constants

## Highlights
* Flexible and searchable database for referencing API constants.
* Select source C++ header and optionally define additioinal #INCLUDES, or entire directories to scan for more headers/constants.
* Setup this script with a compiler of your choice for checking constants (recommended MSVC BuildTools or GCC variant, like MinGW32/64 or TDGCC).
* Easily compile constants into a small test program to check constant value from the compiler of your choice.
* After scanning, a searchable Includes List is generated, showing child includes for each listed include.
* Catalogs structs, enums, and #define entries.

## Details

This script is for making the process of exploring API functions easier.  You can simply load up one the lists (above) that I've already made and start searching for values of constants.

You can also use this script to generate a list of constants for a selected API from the headers you specify.  Each constant is logged with lots of data, like src file and line number, so you can easily track down where that constant is in the source code.  You can also optionally do a quick check of the constant value through a compiler (but only if you have the headers available to check).

Currently this script attempts to resolve constant values without the compiler, but only does so for simple math expressions.  Since this script allows you to check the constant value through the compiler, I will be updating this script over time as I learn the various ways numbers are expressed in C++ (ie. type casting) so that more correct values can be returned without the need for using the compiler.

Constant values that can be resolved, or types that can be determined, are categorized to assist with searching.  The rest are left as "Unknown".  The "Other" type usually describes constants that are arrays or an alias for a macro or function.

It is important to note that the "scanner" portion of this script is not "hyper intelligent".  Generally it's not unheard of to come up with multiple values for a single constant, even within the same header, because that constant's value changes depending on other constants, that are often defined by the user.  I'm not sure if I'll get around to parsing all of the `#ifdef` and similar statements to weed out the duplicates, but I am looking for ways to try and achieve this.  No ETA on when/if this will be done.

Constant values with multiple definitions are referred to as "Dupes" in the GUI of the script.  "Critical" constants are defined as those whose value depends on one or more "Dupes".  You can filter out critical and dupe constants if desired.  You can also see all the dupe and critical info for each constant that has this type of info.

## Planned changes:

* Add a framework to allow user-defined values for constants before testing/compiling.

Please use the latest AutoHotkey v2 alpha (as of 2021/03/09 -> a128).

https://www.autohotkey.com/download/2.0/
