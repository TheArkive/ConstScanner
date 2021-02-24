; AHK v2

; great win32 api constant sources:
; https://raw.githubusercontent.com/GroggyOtter/GroggyRepo/master/Files/List%20-%20Win32%20Constants
; https://www.autoitscript.com/forum/files/file/16-win32-api-constants/

; Thanks to GroggyOtter on GitHub and to GaryFrost on autoIt
; forums for posting thier lists of Win32 API constants.

; For a list of win32 headers by category / technology:
; https://docs.microsoft.com/en-us/windows/win32/api/

#NoTrayIcon

Global Settings:=Map()
; Global g:="", g3:="" ; Gui obj
Global c:="" ; console obj
Global prog:="" ; progress bar
Global IncludesList := Map(), const_list:=Map(), filteredList := Map()
Global already_scanned := Map(), dupe_list:=[]

; Global mb := menubar.new()
; Global calcListCount := 1, calcListTotal := 0, calcErrorList := "", Mprog := "", timerDelay := -500

If (FileExist("settings.json")) {
    sText := FileRead("settings.json")
    Settings := jxon_load(sText)
}

; (!Settings.Has("DefaultIncludes"))  ? Settings["DefaultIncludes"]   := Map() : ""
; (!Settings.Has("BaseSearchDir"))    ? Settings["BaseSearchDir"]     := "" : ""
; (!Settings.Has("baseFiles"))        ? Settings["baseFiles"]         := Map() : ""
; (!Settings.Has("dirs"))             ? Settings["dirs"]              := Map() : ""

(!Settings.Has("AutoLoad"))         ? Settings["AutoLoad"]          := false : ""
(!Settings.Has("DisableTooltips"))  ? Settings["DisableTooltips"]   := 1  : 0       ; init default values
(!Settings.Has("LastFile"))         ? Settings["LastFile"]          := "" : ""
(!Settings.Has("lastDir"))          ? Settings["lastDir"]           := "" : ""
(!Settings.Has("Recents"))          ? Settings["Recents"]           := Map() : ""
(!Settings.Has("doReset"))          ? Settings["doReset"]           := false : ""
(!Settings.Has("temp_gui"))         ? Settings["temp_gui"]          := {hwnd:0} : ""

(!Settings.Has("ApiPath"))          ? Settings["ApiPath"]           := "" : ""
(!Settings.Has("ScanType"))         ? Settings["ScanType"]          := "C&ollect" : ""
(!Settings.Has("x64_MSVC"))         ? Settings["x64_MSVC"]          := "" : ""
(!Settings.Has("x86_MSVC"))         ? Settings["x86_MSVC"]          := "" : ""
(!Settings.Has("x64_GCC"))          ? Settings["x64_GCC"]           := "" : ""
(!Settings.Has("x86_GCC"))          ? Settings["x86_GCC"]           := "" : ""
(!Settings.Has("CompilerType"))     ? Settings["CompilerType"]      := "x64_MSVC_Sel" : ""
(!Settings.Has("AddIncludes"))      ? Settings["AddIncludes"]       := true : ""
(!Settings.Has("var_copy"))         ? Settings["var_copy"]          := "&var := value" : ""

(!Settings.Has("FileFilter"))       ? Settings["FileFilter"]        := "" : ""
(!Settings.Has("CheckInteger"))     ? Settings["CheckInteger"]      := 1 : ""
(!Settings.Has("CheckFloat"))       ? Settings["CheckFloat"]        := 1 : ""
(!Settings.Has("CheckString"))      ? Settings["CheckString"]       := 1 : ""
(!Settings.Has("CheckUnknown"))     ? Settings["CheckUnknown"]      := 1 : ""
(!Settings.Has("CheckOther"))       ? Settings["CheckOther"]        := 1 : ""
(!Settings.Has("CheckExpr"))        ? Settings["CheckExpr"]         := 1 : ""
(!Settings.Has("CheckDupe"))        ? Settings["CheckDupe"]         := 1 : ""
(!Settings.Has("CheckCrit"))        ? Settings["CheckCrit"]         := 1 : ""
(!Settings.Has("CheckStruct"))      ? Settings["CheckStruct"]       := 1 : ""
(!Settings.Has("CheckEnum"))        ? Settings["CheckEnum"]         := 1 : ""

Settings["SearchControlList"] := ["NameFilter","ValueFilter","ExpFilter"]
Settings["gui"] := load_gui()

; IncludesList := Map("incl1",[["abc","def","ghi"]]
                   ; ,"incl2",[["def","ghi","jkl"]]
                   ; ,"incl3",[["ghi","jkl","mno"]])
; incl_report()

If (Settings["AutoLoad"] And FileExist(Settings["LastFile"])) { ; load data if Auto-Load enabled
    UnlockGui(false)
    LoadFile(Settings["LastFile"])
    UnlockGui(true)
    Settings["gui"]["File"].Value := "File: " Settings["LastFile"]
}

OnMessage(0x0100,"WM_KEYDOWN") ; WM_KEYDOWN
OnMessage(0x0200,"WM_MOUSEMOVE") ; WM_MOUSEMOVE

return ; end auto-exec section

#INCLUDE libs\_JXON.ahk
#INCLUDE libs\TheArkive_CliSAK.ahk
#INCLUDE libs\TheArkive_Progress2.ahk
#INCLUDE libs\TheArkive_eval.ahk
#INCLUDE libs\TheArkive_GuiExt.ahk

#INCLUDE "*i libs\TheArkive_Debug.ahk"

; #INCLUDE inc\gui_edit_default_includes.ahk
#INCLUDE inc\gui_edit_recents.ahk
#INCLUDE inc\gui_extra_dirs.ahk
#INCLUDE inc\gui_filters.ahk
#INCLUDE inc\gui_incl_report.ahk
#INCLUDE inc\gui_main.ahk
#INCLUDE inc\header_parser.ahk
; #INCLUDE inc\parser_compiler.ahk

WM_KEYDOWN(wParam, lParam, msg, hwnd) { ; up / down scrolling with keyboard
    If (filter_check(hwnd) And wParam = 13) ; pressing enter for filters
        relist_const()
    Else If (Settings["gui"]["ConstList"].hwnd = hwnd And (wParam = 38 Or wParam = 40))
        up_down_nav(wParam)
}

WM_MOUSEMOVE(wParam, lParam, Msg, hwnd) {
    If (!Settings["DisableTooltips"]) {
        If (Settings["temp_gui"].hwnd) {    ; not the main GUI
            If (hwnd = Settings["temp_gui"]["OtherDirList"].hwnd)
                ToolTip "Indicate which includes should always be included when checking`r`n"
                      . "constant values through the compiler with a check (the first status).`r`n`r`n"
                      . "The second status (green check or red X) determines if that file`r`n"
                      . "is listed as an include during the scan.  If not, none of the`r`n"
                      . "constants or includes contained in files marked with a red X will`r`n"
                      . "be recorded during the scan.`r`n`r`n"
                      . "Toggle second status with right-click."
            Else If (hwnd = Settings["temp_gui"]["BaseFolder"].hwnd)
                ToolTip "BaseFolder"
            Else If (hwnd = Settings["temp_gui"]["OtherDir"].hwnd)
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

LoadFile(selFile:="") {
    If (selFile != "" And !FileExist(selFile)) {
        msgbox "Previous loaded file no longer exist.`r`n`r`nLoad failed."
        return
    } Else If (selFile="") {
        selFile := FileSelect("1",A_ScriptDir "\data\","Load Constant File:","Data file (*.data)")
        If (!selFile) ; user cancelled
            return
        SplitPath selFile,,,ext
        If (ext != "data") Or (!FileExist(selFile)) {
            Msgbox "You must select a *.data file."
            return
        }
    }
    
    Settings["gui"]["Details"].Value := "", Settings["gui"]["Duplicates"].Value := ""
    UnlockGui(false)
    SplitPath selFile, fileName,,,profName
    Settings["gui"]["Total"].Value := "Loading data file.  Please Wait ..."
    
    fileData := FileRead(selFile)
    
    in_load_data := jxon_load(fileData)
    If (in_load_data.Count = 2 And in_load_data.Has("__const_list")) {
        const_list := in_load_data["__const_list"]
        IncludesList := in_load_data["__includes_list"]
        in_load_data := "" ; free input array
    } Else
        const_list := in_load_data
    
    relist_const()
    Settings["gui"]["File"].Value := "Data File: " fileName
    Settings["LastFile"] := selFile
    If Settings["Recents"].Has(profName) {
        Settings["ApiPath"] := profName
        Settings["gui"].Title := "C++ Constants Scanner - " profName
    }
    
    UnlockGui(true)
}

SaveFile() {
    If !Settings["ApiPath"] {
        Msgbox "Load / Create a profile first, then perform a scan."
        return
    }
    
    lastFile := Settings["LastFile"]
    SplitPath lastFile, lastName
    saveFile := FileSelect("S 18",A_ScriptDir "\data\" Settings["ApiPath"] ".data","Save Data File:")
    
    If (saveFile) {
        save_data := Map("__const_list",const_list, "__includes_list",IncludesList)
        
        UnlockGui(false)
        
        FileExist(saveFile) ? FileDelete(saveFile) : ""
        fileData := Jxon_dump(save_data)
        saveFile := (SubStr(saveFile,-5) != ".data") ? saveFile ".data" : saveFile
        
        FileAppend fileData, saveFile
        
        Settings["LastFile"] := saveFile
        MsgBox "Data file successfully saved."
        UnlockGui(true)
        
        SplitPath saveFile, fileName
        Settings["gui"]["File"].Value := "Data File: " fileName
    }
}

UnlockGui(bool) {
    g := Settings["gui"]
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
    g["Includes"].Enabled := bool
    g["ConstList"].Enabled := bool
    g["Tabs"].Enabled := bool
    
    If (bool) {
        g.menubar.Enable("&Source"), g.menubar.Enable("&Data")
        g.menubar.Enable("&List"), g.menubar.Enable("&Compile")
    } Else {
        g.menubar.Disable("&Source"), g.menubar.Disable("&Data")
        g.menubar.Disable("&List"), g.menubar.Enable("&Compile")
    }
}

relist_const() {
    Static q := Chr(34)
    Static oopsStr := "\|(){}[]-+^$&%?.,<>" q
    
    g := Settings["gui"]
    n_fil := g["NameFilter"].value
    v_fil := g["ValueFilter"].value
    e_fil := g["ExpFilter"].Value
    f_fil := Settings["FileFilter"]
    
    If RegExMatch(n_fil,"[\\\|\(\)\{\}\[\]\-\+\^\$\&\%\?\.\,\<\>\" q "]") Or RegExMatch(f_fil,"\\\?\|<>:/" q) ; invalid chars in name and file filters
        return
    
    filteredList := Map()
    ctl := g["ConstList"]
    ctl.Opt("-Redraw")
    ctl.Delete()
    tot := 0
    
    i:=0, f:=0, s:=0, u:=0, o:=0, e:=0, d:=0, c:=0, en:=0, st:=0 ; i, f, s, u, o, e, d, c, en, st ; tallies for each type
    i_f  := Settings["CheckInteger"], f_f := Settings["CheckFloat"], s_f := Settings["CheckString"] ; checkbox type filters
    u_f  := Settings["CheckUnknown"], o_f := Settings["CheckOther"], e_f := Settings["CheckExpr"]
    d_f  := Settings["CheckDupe"],    c_f := Settings["CheckCrit"]
    en_f := Settings["CheckEnum"],   st_f := Settings["CheckStruct"]
    
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
    fFilter := StrReplace(fFilter,".","\.")
    fFilter := StrReplace(fFilter,"*",".*")
    
    If (prog != "") And IsObject(prog)
        prog.Range("0-" const_list.Count), prog.Title("Loading..."), prog.Update(0," "," ")
    Else prog := progress2.New(0,const_list.Count,"title:Loading...,parent:" g.hwnd)
    
    do_all := (!n_fil And !v_fil And !e_fil And !f_fil) ? true : false
    
    For const, obj in const_list {
        prog.Update(A_Index)
        do_filter := false
        value := obj["value"], expr := obj["exp"], file_name := obj["file"], t := obj["type"]
        dupe := (obj.Has("dupe")) ? true : false
        crit := (obj.Has("critical")) ? true : false
        
        If (RegExMatch(const,"i)" nFilter) And RegExMatch(value,"i)" vFilter) And RegExMatch(expr,"i)" eFilter) And RegExMatch(file_name,"i)" fFilter))
            do_filter := true
        
        If (dupe And !d_f) Or (crit And !c_f) ; skip dupes and crits if check filter is unchecked
            Continue
        
        If ((t="integer" And !i_f) Or (t="float" And !f_f) Or (t="string" And !s_f) Or (t="unknown" And !u_f) Or (t="other" And !o_f)
         Or (t="expr" And !e_f) Or (t="enum" And !en_f) Or (t="struct" And !st_f))
            Continue  ; skip if unchecked
        
        If do_filter {
            filteredList[const] := obj
            c_disp := (crit)?"X":""
            d_disp := (dupe)?"X":""
            ctl.Add(,const,value,obj["type"],file_name,d_disp,c_disp), tot++ ; i, f, s, u, o, e, d    ; type filters
            
            Switch obj["type"] {
                Case "Integer": i+=1
                Case "Float"  : f+=1
                Case "String" : s+=1
                Case "Unknown": u+=1
                Case "Expr"   : e+=1
                Case "Other"  : o+=1
                Case "Struct" : st+=1
                Case "Enum"   : en+=1
            }
            
            (dupe) ? d+=1 : ""
            (crit) ? c+=1 : ""
        }
    }
    
    ctl.ModifyCol(1,"Sort")
    ctl.Opt("+Redraw")
    g["Total"].Text := "Total: " tot " / Unk: " u " / Known: " tot-u " / Int: " i " / Float: " f " / Str: " s " / Struct: " st " / Enum: " en " / Other: " o " / Expr: " e " / Dupes: " d " / Crit: " c
    
    If Settings["doReset"] {
        Settings["doReset"]:=false
        g["NameFilter"].Focus()
    }
    prog.close(), prog := ""
}

filter_check(hwnd) {
    For ctl in Settings["SearchControlList"] ; global defined above
        If (hwnd = Settings["gui"][ctl].hwnd)
            return true
    return false
}

up_down_nav(key) {
    ctl := Settings["gui"]["ConstList"]
    rMax := ctl.GetCount()
    curRow := ctl.GetNext()
    nextRow := (key=40) ? curRow+1 : (key=38) ? curRow-1 : curRow
    nextRow := (nextRow > rMax) ? 0 : nextRow
    gui_events(ctl,nextRow)
}

#HotIf WinActive("ahk_id " Settings["gui"].hwnd)

^+d::copy_const_details()
^d::copy_const_only()

F2::{
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
    Msgbox "Critical constants.`r`nFull list is copied to clipboard.`r`n`r`nCount: " i "`r`n`r`n" (!critList ? "* None *" : critList)
    A_Clipboard := critList
}

; F3::{
    ; SendMessage(0x018B)
; }