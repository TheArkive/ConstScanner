# C++ Constants Scanner/Database

This script is for making the process of exploring API functions easier.

You can define profiles (groups of headers) and any user-defined constants needed prior to scanning for values.

Global constant/macro values are generally compiler specific (ie. MSVC or GCC).

## Recent Updates

2022/01/03
+ Cleaned up some dialogs to be more consistent with the rest of the UI changes.
+ Added a *"Global Base Folder"* option for users who just browse `.data` files.\
This enables the *"Go to #Include"* and *"Include"* menu functionality.
+ The Compile menu is now hidden unless you define your CLI compiler enviornment settings in the Settings tab.
+ Added the ability to edit values.\
This is mostly used for selectively cleaning up struct indentation.
+ Re-dumped all x64 `.data` files because most were missing some includes (re-download please!).
+ Finised dumping values into `.data` files for the remaining Win32 API references on the [Microsoft site](https://docs.microsoft.com/en-us/windows/win32/api/).

Also, due to recent updates:
+ "Dupes" and "Critical" constants used to be "a thing" in this script.  Now, "Critical" doesn't exist (no data files have "Critical" constants anymore) and the few existing "Dupes" are usually obscure structs, or redeclarations of UUIDs/GUIDs.
+ The old `.data` files will not work with this update.  Please download all the `.data` files (that you use) again.  For now only x64 `.data` files exist.  I'll dump the x86 ones later.

## API .data Files

I have already scanned and posted several Win32 API `.data` files.

You can get the `.data` files here: [ConstScannerDataFiles Repo](https://github.com/TheArkive/ConstScannerDataFiles)

I'll post more `.data` files as I scan more headers.

Place these files in the *data* folder within the script directory.

Load them up from the menubar:  `Data > Load Constants`

## Highlights
+ Inspired by [Constants.ahk](https://autohotkey.com/board/topic/18177-crazy-scripting-list-of-win32-constants/) (written by SKAN)
+ Scans and catalogs Integers, Floats, Strings, Structs, Enums, Macros, and UUIDs.
+ Automatically perform calculations and variable substitutions defined in macros to resolve constant values.
+ Set user-defined constants so you can keep your `.data` files lean with only the constants you want to list in a given API.
+ Create profiles of user-defined groups of headers.
+ All `#preprocessors` are now parsed to get a more accurate set of constants.
+ Flexible UI for searching and referencing API constants/structs/unions/enums/macros.
+ All listed Win32 API groups have been dumped to the [Data File Repo](https://github.com/TheArkive/ConstScannerDataFiles).
+ Jump to where a value is defined in headers from the main list (right-click).\
(Define text editor settings in the Settings menu.)
+ Setup this script with a compiler of your choice for checking constants (recommended MSVC BuildTools or GCC variant, like MinGW32/64 or TDGCC).\
It sometimes doesn't work, this is a work-in-progress.
+ Double-click a constant in the list (or press `F3`) to get a larger display window (handy for browsing large structs and enums).
+ Toggle `Value` column between Hex and Decimal format with `CTRL + Space`, or from the List menu.
+ Each `.data` file now contains a sub-catalog of data types and their sizes that pertain to that API.
+ Drastically reduced number of duplicate constants.
+ No more "critical" constants.\
"Critical" used to mean that a value of a numeric constant was based on one or more duplicate constants.  Now with the proper pre-defined constants, and `#preprocessors` being processed during scanning, there are no more "Critical" constants, and significantly fewer dupes.

## Simple Setup

If you only plan to use this script to load `.data` files and browse constants, then there is no setup to be done.  Just grab the `.data` files you want to use from the repo mentioned above, and load them up.

If you have downloaded the Windows SDK and want to be able to use the UI to open up headers in your preffered text editor AND jump to the line where the value is defined, keep reading below. 

### Define Text Editor Settings

From the *Settings* menu, define the following values.
+ Text Editor\
Example: `C:\Program Files\Notepad++\notepad++.exe`
+ Go-To-Line Command\
Example: `C:\Program Files\Notepad++\notepad++.exe -n# [file]`

It is important to note the following elements when defining the *"Go-To-Line Command"*:
+ The `#` is replaced by the recorded value's line number (stored in the `.data` file).
+ The `[file]` is replaced by the header file name.

Of course different text editors will likely require different syntax.

Just make sure to place the `#` and `[file]` in the proper syntax for your text editor.

After you define these settings, and restart the script, then you will see an *"Includes"* menu, and when you right-click on a value in the main list, you will see a *"Go to #Include"* entry in the context menu.

The *"Includes"* menu shows a list of headers referenced in this API and allows you to open up any one, or all of them in your text editor.

The *"Go to #Include"* context menu entry will open the required header file and automatically jump to that line where the value is defined.

## Using the compiler settings

In general you should have your compiler setup in your system or user `%PATH%` environment setting.  This will allow the most flexibility when trying to compile very small "programs" in order to just display constant values.

In the *"Settings"* tab, you will see the required compiler settings.  Enter the command used to load the compiler environment for each compiler you intend to use.

```
Example for MSVC CLI environment:

x64:  vcvarsall x86_x64
x86:  vcvarsall x64_x86

Eample for a GCC environment:

x64:  msystem mingw64
x86:  msystem mingw32
```

Use the radio buttons to select the active compiling setting.  You can change between MSVC/GCC/x86/x64 any time as you browse and compile to test constant values.

## Making your own .data files

A detailed tutorial is needed for this, and i have yet to write one.  Hopefully this will at least get you started.

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

When setting the `Base Folder` for the profile, make sure to only list a single folder (the deepest folder that contains everything).  Adding more than one `Base Folder` in a profile might generate unusual results.  This will be revisited in the future and only one entry will be enforced, or multiple include directories will be supported again.

### Recommended Global Settings - for scanning headers

Just copy/paste the following into the Global Settings window.  Please note these constants are required for MSVC (I happen to use BuildTools - CLI only).  I have not yet figured out what the pre-defined constants are for GCC compilers.  I do not recommend using all of the following global constants when scanning headers meant for a GCC compiler.

To load global/pre-defined constants for MSVC, click the *"Source"* menu > *"Global Settings"* option.  Copy/paste the following into the *"Global Settings"* dialog.

Global Constants (Scanning)
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

Define the architecture you want from the DropDown menu for pulling data.  This is required, since the architecture determines many of the constant values and struct/enum layouts.  The purpose of this DropDown menu is to define simply 64-bit or 32-bit.

When defining/changing the architecture, also make sure to also edit the Global Constants as needed prior to scanning.  I know this is a bit redundant, but in theory you can also pull constants for mobile ARM/ARM64 architecture as well, not just PC x86 and x64.  More work will be done on this in the future to try and make this a bit less crazy.

## Planned changes:

+ Dump x86 constants for Win10.
+ Include global/pre-defined constants for GCC compilers.
+ Calculate struct sizes and field offsets (aligned and unaligned) without the compiler (I still will spot check with the compiler though).

Please use the latest AutoHotkey v2-beta.3

https://www.autohotkey.com/download/2.0/
