; AHK v2

; Inspired by Constants.ahk (written by SKAN)
; Link: https://autohotkey.com/board/topic/18177-crazy-scripting-list-of-win32-constants/

; great win32 api constant sources:
; https://raw.githubusercontent.com/GroggyOtter/GroggyRepo/master/Files/List%20-%20Win32%20Constants
; https://www.autoitscript.com/forum/files/file/16-win32-api-constants/

; Thanks to GroggyOtter on GitHub and to GaryFrost on autoIt
; forums for posting thier lists of Win32 API constants.

; For a list of win32 headers by category / technology:
; https://docs.microsoft.com/en-us/windows/win32/api/

#NoTrayIcon

#INCLUDE libs\_JXON.ahk
#INCLUDE libs\TheArkive_CliSAK.ahk
#INCLUDE libs\TheArkive_Progress2.ahk
#INCLUDE libs\_eval.ahk
#INCLUDE libs\_GuiCtlExt.ahk

#INCLUDE inc\gui_edit_recents.ahk
#INCLUDE inc\gui_extra_dirs.ahk
#INCLUDE inc\gui_filters.ahk
#INCLUDE inc\gui_incl_report.ahk
#INCLUDE inc\gui_main.ahk
#INCLUDE inc\gui_global_settings.ahk
#INCLUDE inc\header_parser.ahk

Global Settings:=Map()
Global c:="" ; console obj
Global prog:="" ; progress bar
Global includes_list := [], includes_processed := [], includes_all:=[]
Global const_list:=Map(), const_other:=Map(), typedef_list:=Map(), MacroList:=Map()
Global const_cache:=Map("file","","cache","")
Global filteredList := Map()
Global sizeof_list := Map(), sizeof_list_basic := Map()
Global basic_types := "" ; not used?
Global abort_parser := false
Global already_scanned := Map(), dupe_list:=[]

Global _basic_types := FileRead("basic_types.txt")

If (FileExist("settings.json")) {
    sText := FileRead("settings.json")
    Settings := jxon_load(&sText)
}

(!Settings.Has("AutoLoad"))         ? Settings["AutoLoad"]          := false : ""
(!Settings.Has("DisableTooltips"))  ? Settings["DisableTooltips"]   := 1  : 0       ; init default values
(!Settings.Has("LastFile"))         ? Settings["LastFile"]          := "" : ""
(!Settings.Has("LastSession"))      ? Settings["LastSession"]       := [] : ""
(!Settings.Has("lastDir"))          ? Settings["lastDir"]           := "" : ""
(!Settings.Has("Recents"))          ? Settings["Recents"]           := Map() : ""
(!Settings.Has("doReset"))          ? Settings["doReset"]           := false : ""
(!Settings.Has("temp_gui"))         ? app.temp_gui                  := {hwnd:0} : ""
(!Settings.Has("ViewBase"))         ? Settings["ViewBase"]          := "Decimal" : ""
(!Settings.Has("MaxDispOpen"))      ? Settings["MaxDispOpen"]       := false : ""
(!Settings.Has("MinMax"))           ? Settings["MinMax"]            := 0 : "" ; 1076, 529
(!Settings.Has("WH"))               ? Settings["WH"]                := [1076,529] : ""

(!Settings.Has("ApiPath"))          ? app.ApiPath                   := "" : ""
(!Settings.Has("ScanType"))         ? Settings["ScanType"]          := "C&ollect" : ""
(!Settings.Has("x64_MSVC"))         ? Settings["x64_MSVC"]          := "" : ""
(!Settings.Has("x86_MSVC"))         ? Settings["x86_MSVC"]          := "" : ""
(!Settings.Has("x64_GCC"))          ? Settings["x64_GCC"]           := "" : ""
(!Settings.Has("x86_GCC"))          ? Settings["x86_GCC"]           := "" : ""
(!Settings.Has("CompilerType"))     ? Settings["CompilerType"]      := "x64_MSVC_Sel" : ""
(!Settings.Has("AddIncludes"))      ? Settings["AddIncludes"]       := true : ""
(!Settings.Has("var_copy"))         ? Settings["var_copy"]          := "&var := value" : ""
(!Settings.Has("var_copy_comment")) ? Settings["var_copy_comment"]  := false : ""

(!Settings.Has("FileFilter"))       ? Settings["FileFilter"]        := "" : ""
(!Settings.Has("CheckInteger"))     ? Settings["CheckInteger"]      := 1 : ""
(!Settings.Has("CheckFloat"))       ? Settings["CheckFloat"]        := 1 : ""
(!Settings.Has("CheckString"))      ? Settings["CheckString"]       := 1 : ""
(!Settings.Has("CheckUUID"))        ? Settings["CheckUUID"]         := 1 : ""
(!Settings.Has("CheckMIDL"))        ? Settings["CheckMIDL"]         := 1 : ""
(!Settings.Has("CheckUnknown"))     ? Settings["CheckUnknown"]      := 1 : ""
(!Settings.Has("CheckOther"))       ? Settings["CheckOther"]        := 1 : ""
(!Settings.Has("CheckExpr"))        ? Settings["CheckExpr"]         := 1 : ""
(!Settings.Has("CheckDupe"))        ? Settings["CheckDupe"]         := 1 : ""
(!Settings.Has("CheckCrit"))        ? Settings["CheckCrit"]         := 1 : ""
(!Settings.Has("CheckStruct"))      ? Settings["CheckStruct"]       := 1 : ""
(!Settings.Has("CheckEnum"))        ? Settings["CheckEnum"]         := 1 : ""
(!Settings.Has("CheckMacro"))       ? Settings["CheckMacro"]        := 1 : ""
(!Settings.Has("CheckType"))        ? Settings["CheckType"]         := 1 : ""

(!Settings.Has("TextEditor"))       ? Settings["TextEditor"]        := "" : ""
(!Settings.Has("TextEditorLine"))   ? Settings["TextEditorLine"]    := "" : ""

(!Settings.Has("GlobConst"))        ? Settings["GlobConst"]         := "" : ""
(!Settings.Has("GlobConstComp"))    ? Settings["GlobConstComp"]     := "" : ""
(!Settings.Has("GlobMacro"))        ? Settings["GlobMacro"]         := "" : ""
(!Settings.Has("GlobInclude"))      ? Settings["GlobInclude"]       := "" : ""
(!Settings.Has("GlobScanType"))     ? Settings["GlobScanType"]      := "x64" : ""
(!Settings.Has("OverwriteSave"))    ? Settings["OverwriteSave"]     := false : ""
(!Settings.Has("GlobBaseFolder"))   ? Settings["GlobBaseFolder"]    := "" : ""

init_sizeof_list()

init_sizeof_list() {
    Global Settings, _basic_types, basic_types, sizeof_list, sizeof_list_basic
    
    basic_types := "", sizeof_list := Map(), scan_type := Settings["GlobScanType"]
    
    Loop Parse _basic_types, "`n", "`r" ; populate basic_types && sizeof_list
    {
        _types_arr := StrSplit(A_LoopField,"="," ")
        basic_types .= (basic_types?"`r`n":"") _types_arr[1]
        _size := StrSplit(_types_arr[2],";")
        
        if _types_arr.Has(2)
            If _size.Has(2)
                sizeof_list[_types_arr[1]] := (scan_type="x86") ? _size[1] : _size[2]
            Else
                sizeof_list[_types_arr[1]] := _size[1]
    }
    
    sizeof_list_basic := sizeof_list.Clone()
}

rgx_types(list_obj:="sizeof_list") {
    Global sizeof_list, sizeof_list_basic
    
    mainList := %list_obj%, result := "", list_sort := []
    Loop 200
        list_sort.Push([]) ; assuming we never have a str longer than 200 chars
        
    For _type, info in mainList
        list_sort[StrLen(_type)].Push(_type)
    
    Loop 200 {
        For i2, _type in list_sort[200 - (A_Index - 1)] {
            if !_type
                Continue
            Else
                result .= (result?"|":"") _type
        }
    }
    
    return result
}

rgx_types_basic() {
    Global sizeof_list_basic
    result := ""
    For _type, info in sizeof_list_basic
        result .= (result?"|":"") _type
    return result
}

class app {
    Static mainGUI := ""
         , temp_gui := ""
         , recent_handle := ""
         , ApiPath := ""
         , edit_gui := {hwnd:0}
         , edit_const := ""
         , edit_row := 0
         , edit_prop := ""
         ; , GlobConst := Map()
         ; , GlobMacro := Map()
         ; , BoundFunc := ""
}



Settings["SearchControlList"] := ["NameFilter","ValueFilter","ExpFilter"]
app.mainGUI := load_gui()

If !DirExist(A_ScriptDir "\data")
    DirCreate A_ScriptDir "\data"
If !DirExist(A_ScriptDir "\cache")
    DirCreate A_ScriptDir "\cache"

If (Settings["AutoLoad"] And FileExist(Settings["LastFile"])) { ; load data if Auto-Load enabled
    UnlockGui(false)
    LoadFile(Settings["LastSession"]) ; reworking for LastSession
    UnlockGui(true)
    app.mainGUI["File"].Value := "File: " Settings["LastFile"]
}

OnMessage(0x0100,WM_KEYDOWN) ; WM_KEYDOWN
OnMessage(0x0200,WM_MOUSEMOVE) ; WM_MOUSEMOVE



WM_KEYDOWN(wParam, lParam, msg, hwnd) { ; up / down scrolling with keyboard
    Static g := app.mainGUI
          LV := app.mainGUI["ConstList"]
    If (filter_check(hwnd) And wParam = 13) ; pressing enter for filters
        relist_const()
    Else If (LV.hwnd = hwnd && (wParam = 38 Or wParam = 40))
        up_down_nav(wParam)
    Else If (LV.hwnd = hwnd && (wParam = 13) && LV.GetNext())
        details_display(LV,LV.GetNext())
}

WM_MOUSEMOVE(wParam, lParam, Msg, hwnd) {
    If (!Settings["DisableTooltips"]) {
        If (app.temp_gui.hwnd) {    ; not the main GUI
            If (hwnd = app.temp_gui["OtherDirList"].hwnd)
                ToolTip "Indicate which includes should always be included when checking`r`n"
                      . "constant values through the compiler with a check (the first status).`r`n`r`n"
                      . "The second status (green check or red X) determines if that file`r`n"
                      . "is listed as an include during the scan.  If not, none of the`r`n"
                      . "constants or includes contained in files marked with a red X will`r`n"
                      . "be recorded during the scan.`r`n`r`n"
                      . "Toggle second status with right-click."
            Else If (hwnd = app.temp_gui["BaseFolder"].hwnd)
                ToolTip "BaseFolder"
            Else If (hwnd = app.temp_gui["OtherDir"].hwnd)
                ToolTip "Add one include per line.`r`n`r`n"
                      . "Includes can be full path, or just the file name.`r`n`r`n"
                      . "If using file name only, Base Folders defined above will be searched,`r`n"
                      . "and then the full path will automatically be added below."
            Else
                ToolTip
        } Else {                            ; main GUI
            Tooltip
        }
    }
}

listFiles() {
    list_of_files := Map(), fileList := []
    
    For const, obj in const_list {
        file_name := obj["file"]
        list_of_files[file_name] := ""
    }
    
    For file_name in list_of_files
        fileList.Push(file_name)
    
    return fileList
}

LoadFile(fileArr:="") { ; input is file list array
    Global Settings, const_list, includes_all, sizeof_list
    Global const_other, const_cache, MacroList
    fileArr := (fileArr="") ? [] : fileArr
    
    If !fileArr.Length {
        If !(fileArr := FileSelect("M1",A_ScriptDir "\data\","Load Constant File:","Data file (*.data)")).Length {
            app.MainGUI.menubar := load_menubar()
            return ; user cancelled
        }
    }
    
    For i, _selFile in fileArr { ; make sure all files are valid
        SplitPath _selFile,,,&_ext
        If !FileExist(_selFile) || (_ext != "data") {
            msg := "Invalid file specified:`r`n`r`n" _selFile "`r`n`r`n"
                 . "Load session cancelled."
            Msgbox(msg,,"Owner" app.mainGUI.hwnd)
            return
        }
    }
    
    app.mainGUI["Details"].Value := "", app.mainGUI["Duplicates"].Value := ""
    app.mainGUI["Total"].Value := "Loading files/session.  Please Wait ..."
    
    UnlockGui(false)
    
    app.ApiPath := ""
    app.mainGUI.Title := "C++ Constants Scanner"
    
    const_list := Map()
    sizeof_list := Map()
    includes_all := []
    MacroList := Map()
    prog := progress2(0,fileArr.Length,"title:Loading Files...")
    
    For i, _selFile in fileArr {
        fileData := FileRead(_selFile)
        SplitPath _selFile,&fileName
        _data    := jxon_load(&fileData)
        profName := _data["__prof_name"]
        prog.Update(i,,fileName)
        
        If (fileArr.Length = 1) && Settings["Recents"].Has(profName) { ; if loading a single file
            app.mainGUI.Title := "C++ Constants Scanner - " (app.ApiPath := profName)
            If _data["__cache"] { ; only bother with loading cache on single file load
                const_cache["cache"] := _data.Clone()
                const_cache["file"]  := _selFile
                MacroList := _data["__MacroList"]
            }
        }
        
        If Settings["Recents"].Has(profName) {
            baseFolder := Settings["Recents"][profName]["BaseFolder"][1] "\"
        } Else
            baseFolder := ""
        
        For _const, obj in _data["__const_list"] {
            If const_list.Has(_const) && (const_list[_const]["value"] != obj["value"]) {
                ; msgbox "Constant overlap and mismatch:`r`n`r`n"
                     ; . _const "`r`n`r`n"
                     ; . "Value: Src: " const_list[_const]["value"] " / New: " obj["value"] "`r`n`r`n"
                     ; . "File: " const_list[_const]["file"] " / " obj["file"] "`r`n`r`n"
                
                If obj["dupe"].Length { ; move obj dupes to existing const list
                    For i, _obj2 in obj["dupe"]
                        const_list[_const]["dupe"].Push(_obj2)
                }
                obj["dupe"] := []
                const_list[_const]["dupe"].Push(obj) ; push obj to dupes
            }
            const_list[_const] := obj
        }
        
        If !_data["__cache"] {
            For i, include in _data["__includes_list"]
                includes_all.Push(baseFolder include)
        }
        For _type, _size in _data["__sizeof_list"]
            sizeof_list[_type] := _size
    }
    
    prog := "" ; close progress window
    relist_const()
    
    If (fileArr.Length = 1)
        app.mainGUI["File"].Value := "Data File: " fileName
    Else
        app.mainGUI["File"].Value := "Session: " fileArr.Length " files"
    
    Settings["LastSession"] := fileArr
    app.MainGui.menubar := load_menubar()
    
    UnlockGui(true)
}

SaveFile(saveFile:="") {
    Global Settings, const_list, includes_all, sizeof_list
    
    if !Settings["OverwriteSave"] || (Settings["LastSession"].Length > 1) {
        saveFile := FileSelect("S 18",saveFile,"Save Data File:")
        If !saveFile
            return ; cancel save operation
    
    } Else If !app.ApiPath || !Settings["Recents"].Has(app.ApiPath) {
        Msgbox("Load / Create a profile first, then perform a scan.",,"Owner" app.mainGUI.hwnd)
        return
    
    } Else
        saveFile := (!saveFile) ? (A_ScriptDir "\data\" app.ApiPath ".data") : saveFile
    
    prof := Settings["Recents"][app.ApiPath]
    
    short_includes := []
    For i, _path in includes_all
        short_includes.Push(StrReplace(_path,prof["BaseFolder"][1] "\",""))
    
    save_data := Map("__prof_name",app.ApiPath
                   , "__const_list",const_list
                   , "__includes_list",short_includes
                   , "__user_constants",((prof.Has("UserConstants")) ? prof["UserConstants"] : "")
                   , "__user_macros",   ((prof.Has("UserMacros"))    ? prof["UserMacros"]    : "")
                   , "__sizeof_list",sizeof_list
                   , "__cache",false)
    
    UnlockGui(false)
    
    FileExist(saveFile) ? FileDelete(saveFile) : ""
    fileData := Jxon_dump(save_data)
    saveFile := (SubStr(saveFile,-5) != ".data") ? saveFile ".data" : saveFile
    
    FileAppend fileData, saveFile
    
    Settings["LastFile"] := saveFile
    MsgBox("Data file successfully saved.",,"Owner" app.mainGUI.hwnd)
    UnlockGui(true)
    
    SplitPath saveFile, &fileName
    app.mainGUI["File"].Value := "Data File: " fileName
}

UnlockGui(bool) {
    Global Settings
    g := app.mainGUI
    g["NameFilter"].Enabled := bool
    g["NameFilterClear"].Enabled := bool
    g["NameBW"].Enabled := bool
    g["ValueFilter"].Enabled := bool
    g["ValueFilterClear"].Enabled := bool
    g["ValueEQ"].Enabled := bool
    g["ExpFilter"].Enabled := bool
    g["ExpFilterClear"].Enabled := bool
    
    g["Search"].Enabled := bool
    g["MoreFilters"].Enabled := bool
    g["Reset"].Enabled := bool
    g["Types"].Enabled := bool
    g["ConstList"].Enabled := bool
    g["Tabs"].Enabled := bool
    
    If (bool) {
        g.menubar := load_menubar()
        ; g.menubar.Enable("&Source")
        ; g.menubar.Enable("&Data")
        ; g.menubar.Enable("&List")
        ; g.menubar.Enable("&Compile")
    } Else {
        g.menubar := ""
        ; g.menubar.Disable("&Source")
        ; g.menubar.Disable("&Data")
        ; g.menubar.Disable("&List")
        ; g.menubar.Enable("&Compile")
    }
}

relist_const() {
    Global Settings, filteredList, prog, const_list
    Static q := Chr(34)
    Static oopsStr := "\|(){}[]-+^$&%?.,<>" q
    
    g := app.mainGUI
    n_fil := g["NameFilter"].value
    v_fil := g["ValueFilter"].value
    v_fil := IsInteger(v_fil) ? Format("{:d}",v_fil) : v_fil
    e_fil := g["ExpFilter"].Value
    f_fil := Settings["FileFilter"]
    
    If RegExMatch(n_fil,"[\\\|\(\)\{\}\[\]\-\+\^\$\&\%\?\.\,\<\>\" q "]") Or RegExMatch(f_fil,"\\\?\|<>:/" q) ; invalid chars in name and file filters
        return
    
    filteredList := Map()
    ctl := g["ConstList"]
    ctl.Opt("-Redraw")
    ctl.Delete()
    tot := 0
    
    i:=0, f:=0, s:=0, u:=0, o:=0, e:=0, d:=0, c:=0, en:=0, st:=0, m:=0, ty:=0, uu:=0, mi:=0 ; i, f, s, u, o, e, d, c, en, st, m ; tallies for each type
    i_f  := Settings["CheckInteger"], f_f := Settings["CheckFloat"],  s_f  := Settings["CheckString"] ; checkbox type filters
    u_f  := Settings["CheckUnknown"], o_f := Settings["CheckOther"],  m_f  := Settings["CheckMacro"]
    d_f  := Settings["CheckDupe"],    c_f := Settings["CheckCrit"]
    en_f := Settings["CheckEnum"],   st_f := Settings["CheckStruct"]
    uu_f := Settings["CheckUUID"]
    
    nFilter := !n_fil ? "*" : n_fil
    nFilter := StrReplace(nFilter,"*",".*")
    nFilter := g["NameBW"].Value ? "^" nFilter : nFilter
    
    vFilter := ""
    Loop Parse v_fil
    {
        If (InStr(oopsStr,ch := A_LoopField))
            vFilter .= "\" ch
        Else vFilter .= ch
    }
    vFilter := StrReplace(vFilter,"*",".*")
    vFilter := g["ValueEQ"].Value ? "^" vFilter "$" : vFilter
    
    eFilter := ""
    Loop Parse e_fil
    {
        If (InStr(oopsStr,ch := A_LoopField))
            eFilter .= "\" ch
        Else eFilter .= ch
    }
    eFilter := StrReplace(eFilter,"*",".*")
    
    fFilter := !f_fil ? "*" : f_fil
    fFilter := StrReplace(fFilter,"\","\\")
    fFilter := StrReplace(fFilter,".","\.")
    fFilter := StrReplace(fFilter,"*",".*")
    
    If (prog != "") And IsObject(prog) {
        prog.Range("0-" const_list.Count)
        prog.Title := "Loading..."
        prog.Update(0," "," ")
    } Else prog := progress2(0,const_list.Count,"title:Loading...,parent:" g.hwnd)
    
    do_all := (!n_fil And !v_fil And !e_fil And !f_fil) ? true : false
    
    For const, obj in const_list {
        prog.Update(A_Index)
        do_filter := false
        
        if !obj.Has("value")
            msgbox jxon_dump(obj,4)
        
        value := obj["value"], expr := obj["exp"], file_name := obj["file"], t := obj["type"]
        
        if !obj.Has("dupe")
            obj["dupe"] := []           ; compatibility with old lists
        if !obj.Has("critical")
            obj["critical"] := Map()    ; compatibility with old lists
        
        unk := (obj["type"] = "Unknown" || obj["type"] = "Other") ? true : false
        dupe := (obj["dupe"].Length) ? true : false
        crit := (obj["critical"].Count) ? true : false
        
        If (RegExMatch(const,"i)" nFilter) And RegExMatch(value,"i)" vFilter) And RegExMatch(expr,"i)" eFilter) And RegExMatch(file_name,"i)" fFilter))
            do_filter := true
        
        If (dupe And !d_f) Or (crit And !c_f) ; skip dupes and crits if check filter is unchecked
            Continue
        
        If ((t="integer" And !i_f) || (t="float" And !f_f)   || (t="string" And !s_f) || (t="unknown" And !u_f) || (t="other" And !o_f)
         || (t="enum" And !en_f)   || (t="struct" And !st_f) || (t="macro" And !m_f)  || (t="uuid" And !uu_f))
            Continue  ; skip if unchecked
        
        If do_filter {
            filteredList[const] := obj
            c_disp := (crit)?"X":""
            d_disp := (dupe)?"X":""
            
            ; While const_list.Has(value)
                ; value := const_list[value]["value"]
            
            If (Settings["ViewBase"] = "Hex") And IsInteger(value)
                disp_val := Format("0x{:X}",value)
            ELse
                disp_val := value
            
            ctl.Add(,const,disp_val,obj["type"],file_name,d_disp,c_disp)
            tot++ ; i, f, s, u, o, e, d    ; type filters
            
            Switch obj["type"] {
                Case "Integer": i+=1
                Case "Float"  : f+=1
                Case "String" : s+=1
                Case "UUID"   : uu+=1
                Case "Unknown": u+=1
                Case "Other"  : o+=1
                Case "Struct" : st+=1
                Case "Enum"   : en+=1
                Case "Macro"  : m+=1
            }
            
            (dupe) ? d+=1 : ""
            (crit) ? c+=1 : ""
        }
    }
    
    ctl.ModifyCol(1,"Sort")
    ctl.Opt("+Redraw")
    g["Total"].Text := "Total: " tot " / Unk: " u " / Known: " tot-u " / Int: " i " / Float: " f " / String: " s " / UUID: " uu
                     . " / Struct: " st " / Enum: " en " / Macro: " m " / Other: " o " / Dupes: " d " / Crit: " c
    
    If Settings["doReset"] {
        Settings["doReset"]:=false
        g["NameFilter"].Focus()
    }
    prog := ""
}

filter_check(hwnd) {
    For ctl in Settings["SearchControlList"] ; global defined above
        If (hwnd = app.mainGUI[ctl].hwnd)
            return true
    return false
}

up_down_nav(key) {
    ctl := app.mainGUI["ConstList"]
    rMax := ctl.GetCount()
    curRow := ctl.GetNext()
    nextRow := (key=40) ? curRow+1 : (key=38) ? curRow-1 : curRow
    nextRow := (nextRow > rMax) ? 0 : nextRow
    gui_events(ctl,nextRow)
}

HexDecToggle(_type:="") {
    Global Settings
    
    if (_type)
        Settings["ViewBase"] := _type
    else {
        If (Settings["ViewBase"] = "Hex")
            _type := Settings["ViewBase"] := "Decimal"
        ELse
            _type := Settings["ViewBase"] := "Hex"
    }
    
    LV := app.mainGUI["ConstList"]
    Loop LV.GetCount() {
        const := LV.GetText(A_Index,1)
        value := const_list[const]["value"]
        
        If IsInteger(value) {
            If (_type = "Hex")
                LV.Modify(A_Index,"Col2",Format("0x{:X}",value))
            Else
                LV.Modify(A_Index,"Col2",value)
        }
    }
}

uncheck_all() {
    app.mainGUI["ConstList"].Modify(0,"-Check")
}

dbg(_in) {
    Loop Parse _in, "`n", "`r"
        OutputDebug "AHK: " A_LoopField
}

#HotIf WinActive("ahk_id " app.mainGUI.hwnd)

^+u::uncheck_all()
^+c::compile_constants()

XButton1::uncheck_all()
XButton2::compile_constants()

^+d::copy_const_details()
^d::copy_const_only()
^space::HexDecToggle()

F2::{
    Global const_list
    critList := "", i := 0
    For const, obj in const_list {
        If obj.has("critical") And obj["critical"].Count > 0 {
            critList .= const "`r`n"
            For crit, obj2 in obj["critical"] {
                critList .= "    - " crit "`r`n"
                i++
            }
            critList .= "`r`n"
        }
    }
    critList := Trim(critList)
    Msgbox("Critical constants.`r`nFull list is copied to clipboard.`r`n`r`nCount: " i "`r`n`r`n" (!critList ? "* None *" : critList),,"Owner" app.mainGUI.hwnd)
    A_Clipboard := critList
}

F3::{
    ctl := app.MainGUI["ConstList"]
    details_display(ctl,ctl.GetNext())
}
F6::{
    Global const_list
    row := app.MainGUI["ConstList"].GetNext()
    txt := app.MainGUI["ConstList"].GetText(row)
    MsgBox jxon_dump(const_list[txt],4)
}
^s::SaveFile()
^e::details_display(app.mainGUI["ConstList"],app.mainGUI["ConstList"].GetNext(),true)

#HotIf WinActive("ahk_id " app.edit_gui.hwnd)

^s::{
    Global const_list
    const_list[app.edit_const][app.edit_prop] := (new_val := app.edit_gui["Disp"].Value)
    If (app.edit_prop = "value")
        app.mainGUI["ConstList"].Modify(app.edit_row,"Col2",new_val)
    gui_events(app.mainGUI["ConstList"],app.edit_row)
    details_close(app.edit_gui)
}
TAB::SendInput("    ")