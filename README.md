# C++ Constants Scanner/Database

## API Database Files

Get them here: [ConstScannerDataFiles Repo](https://github.com/TheArkive/ConstScannerDataFiles)

Place these files in the data folder within the script directory.

Load them up from the menubar:  Data > Load Constants

NOTE:  "Dupes" and "Critical" constants used to be "a thing" in this script.  Now, "Critical" doesn't exist (no data files have "Critical" constants anymore) and the few existing "Dupes" are usually obscure structs, or redeclarations of UUIDs/GUIDs.

ANOTHER NOTE:  The old `.data` files will not work with this update.  Please download all the `.data` files (that you use) again.  For now only x64 `.data` files exist.  I'll dump the x86 ones later.

## Highlights
* Inspired by [Constants.ahk](https://autohotkey.com/board/topic/18177-crazy-scripting-list-of-win32-constants/) (written by SKAN)
* Flexible and searchable database for referencing API constants.
* Scans and catalogs structs, enums, macros, UUIDs, and all #define entries.
* All `#preprocessors` are now parsed to get a more accurate set of constants.\
Architecture must be defined
* Create profiles of user-defined groups of headers.
* Set user-defined constants so you can keep your database files lean with only the constants you want to list in a given API.
* Setup this script with a compiler of your choice for checking constants (recommended MSVC BuildTools or GCC variant, like MinGW32/64 or TDGCC).\
It sometimes doesn't work, this is a work-in-progress.
* Automatically perform calculations and variable substitutions defined in macros to resolve constant values.
* Double-click a constant in the list (or press `F3`) to get a larger display window (handy for browsing large structs and enums).
* Toggle `Value` column between Hex and Decimal format with `CTRL + Space`, or from the List menu.
* Each `.data` file now contains a sub-catalog of data types and their sizes that pertain to that API.

## Details

This script is for making the process of exploring API functions easier.

Most users of this script will only use the `.data` files that I generate and post on [this repo](https://github.com/TheArkive/ConstScannerDataFiles).

Load a `.data` file by clicking:
* Data menu > Load constants

## Making your own .data files

A detailed tutorial is needed, and I don't have one yet, so here goes my best attempt to at least get you started.

----------------

You can create your own profile from the menu.  A "profile" is simply a list of headers with a title and a few options set for scanning.

Predefined Constant format:
```
const_name1 = value
const_name2 = value
```

Predefined Macro format:
```
#define Macro_Name(param1,param2) ((what) << the | macro << does)
```

When setting the `Base Folder` for the profile, make sure to only list a single folder (the top most that contains everything).  Adding more than 1 might generate unusual results.  This will be revisited in the future and only one entry will be enforced, or multiple include directories will be supported again.

### Recommended Global Settings - for scanning headers

Just copy/paste the following into the Global Settings window.  Please note these constants are required for MSVC (I happen to use BuildTools - cli only).  I have not yet dove into the specifics of the MinGW (32 & 64) GCC compilers, this is planned for the future.  However, compiling and checking constant values does still work for the most part in MinGW.

(Source menu > Global Settings.)

Global Constants
```
// https://docs.microsoft.com/en-us/cpp/preprocessor/predefined-macros
_MSC_VER = 1920         // required
_MSC_FULL_VER = 0       // required
WIN32_LEAN_AND_MEAN = 1 // recommended for lean data files
UNICODE = 1             // optional - comment out for ANSI

_WIN64 = 1              // uncomment this when pulling x64 constants

// ------------------------- CHOOSE AN ARCHITECTURE -------------------------

_M_AMD64 = 100          // PC x64 - also needs next line
_M_X64 = 100

//_M_ARM64 = 1          // mobile ARM x64 architecture

//_M_IX86 = 600         // PC x86 - also needs next line
//_M_IX86_FP = 2

//_M_ARM = 7            // mobile ARM

// ------------------------- Other Global Constants -------------------------

// _CHAR_UNSIGNED = 1   // optional

__COUNTER__ = 0         // these should always be defined
_INTEGRAL_MAX_BITS = 64
_WIN32 = 1
NO_STRICT = 1
_MSC_EXTENSIONS = 1
UINT_MAX = 0xFFFFFFFF
```

Global Constants (Compiling):
```
WIN32_LEAN_AND_MEAN = 1 // recommended for lean data files
NO_STRICT = 1
_MSC_EXTENSIONS = 1
```

Global Macros:
```
#define HRESULT_FROM_WIN32(x) __HRESULT_FROM_WIN32(x)
```

Global Includes:
```
Windows.h
```

Define the architecture you want from the DropDown menu for pulling data.  This is required, since the architecture determines many of the constant values and struct/enum layouts.

Make sure to also edit the Global Constants as needed prior to scanning (this also sets the architecture).  I know this is a bit redundant, but in theory you can also pull constants for ARM/ARM64 architecture as well, not just x86 and x64 (PC).  More work will be done on this in the future to try and make this a bit less crazy.

NOTE:  "Dupes" and "Critical" constants used to be "a thing" in this script.  Now, "Critical" doesn't exist (no data files have "Critical" constants anymore) and the few existing "Dupes" are usually obscure structs, or redeclarations of UUIDs/GUIDs.

## Planned changes:

* Dig into GCC MinGW compiler and its WIN32 source files.\
This will likely yield a different set of global constants for the GCC compiler.  I plan to include these default global settings in the future.
* Calculate struct sizes and field offsets (aligned and unaligned) without the compiler (I still will spot check with the compiler though).

Please use the latest AutoHotkey v2-beta.3

https://www.autohotkey.com/download/2.0/
