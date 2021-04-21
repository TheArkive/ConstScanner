# C++ Constants Scanner/Database

## API Database Files
Get them here: https://github.com/TheArkive/ConstScannerDataFiles

Place these files in the data directory.

Load them up with the menu:  Data > Load Constants

## Highlights
* Inspired by [Constants.ahk](https://autohotkey.com/board/topic/18177-crazy-scripting-list-of-win32-constants/) (written by SKAN)
* Flexible and searchable database for referencing API constants.
* Scan for constants in user-defined groups of headers.
* Set user-defined constants so you can keep your database files lean with only the constants you want to list in a given API.
* Setup this script with a compiler of your choice for checking constants (recommended MSVC BuildTools or GCC variant, like MinGW32/64 or TDGCC).
* After scanning, a searchable Includes List is generated, showing child includes for each listed include.
* Catalogs structs, enums, and all #define entries.
* Double-click a constant in the list (or press `F3`) to get a larger display window (handy for large structs and enums).
* Toggle `Value` column between Hex and Decimal with `CTRL + Space`, or from the List menu.

## Details

This script is for making the process of exploring API functions easier.  You can generate and search lists that contain constants for a selected API.  Each constant is logged with lots of data, like src file and line number, so you can easily track down where that constant is in the source code.  You can also optionally do a quick check of the constant value through a compiler if you setup a profile to specify the headers.

Currently this script attempts to resolve constant values without the compiler, but only does so for simple math expressions, and a few functions: `MAKE_HRESULT()`, `MAKE_SCODE()`, `HRESULT_FROM_WIN32()`, `CTL_CODE()`, `USB_CTL()`.  Since I can check values through the compiler, I will be updating this script over time as I learn how to properly calculate these constants.

Constant values that can be resolved, or types that can be determined, are categorized to assist with searching.  The rest are left as "Unknown".  The "Other" type usually describes constants that are arrays, macros, and other expressions that aren't so easily resolved.

Constant values with multiple definitions are referred to as "Dupes" in the GUI of the script.  "Critical" constants are defined as those whose value depends on one or more "Dupes".  You can filter out critical and dupe constants if desired.  You can also see all the dupe and critical info for each constant that has this type of info.

## Planned changes:

* append user-defined constants to database files, and make this list visible

Please use the latest AutoHotkey v2 alpha (currently a131).

https://www.autohotkey.com/download/2.0/
