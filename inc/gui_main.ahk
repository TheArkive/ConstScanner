load_gui() {
    g := Gui("+OwnDialogs +Resize +MinSize1076x400","C/C++ Constants Scanner")
    g.OnEvent("close",close_gui), g.OnEvent("size",size_gui)
    g.SetFont("s10","Consolas")
    
    g.Menubar := load_menubar()
    
    g.SetFont("s10","Consolas")
    
    g.Add("Text","xm y+10","Name:")
    g.Add("Edit","Section yp-4 x+2 w100 vNameFilter","").OnEvent("change",gui_events)
    g.Add("Button","x+0 hp vNameFilterClear","X").OnEvent("click",gui_events)
    g.Add("CheckBox","x+4 yp+4 vNameBW","Begins with").OnEvent("click",gui_events)
    
    g.Add("Text","x+20 ys+4","Value:")
    g.Add("Edit","Section yp-4 x+2 w100 vValueFilter","").OnEvent("change",gui_events)
    g.Add("Button","x+0 hp vValueFilterClear","X").OnEvent("click",gui_events)
    g.Add("CheckBox","x+4 yp+4 vValueEQ","Exact").OnEvent("click",gui_events)
    
    g.Add("Text","x+20 ys+4","Expression:")
    g.Add("Edit","Section yp-4 x+2 w100 vExpFilter","").OnEvent("change",gui_events)
    g.Add("Button","x+0 hp vExpFilterClear","X").OnEvent("click",gui_events)
    
    ctl := g.Add("Button","x+15 h25 w65 vSearch","Search")
    ctl.OnEvent("click",gui_events)
    ctl.SetFont("s8","Verdana")
    
    ctl := g.Add("Button","x+5 hp w85 vMoreFilters","More Filters")
    ctl.OnEvent("click",gui_events)
    ctl.SetFont("s8","Verdana")
    
    ctl := g.Add("Button","x+0 hp w70 vReset","Reset All")
    ctl.OnEvent("click",gui_events)
    ctl.SetFont("s8","Verdana")
    
    ctl := g.Add("Button","x+5 hp w65 vTypes","Types")
    ctl.OnEvent("click",gui_events)
    ctl.SetFont("s8","Verdana")
    
    ctl := g.Add("ListView","xm y+5 w1051 h300 vConstList Checked +LV0x40",["Name","Value","Type","File","D","C"]) ; w1050
    ctl.OnEvent("ContextMenu",gui_context)
    
    If !Settings.Has("ColWidths")
        Settings["ColWidths"] := [435, 190, 135, 200, 30, 30]
    
    Loop Settings["ColWidths"].Length
        ctl.ModifyCol(A_Index, Settings["ColWidths"][A_Index])

    ctl.OnEvent("click",gui_events)
    ctl.OnEvent("doubleclick",details_display)
    
    ; g.Add("Text","xm y+5 vHelper","Press CTRL+D to copy selected constant details.")
    g.Add("Text","x500 y+5 w560 Right vFile","Data File:")
    
    tabCtl := g.Add("Tab3","Section xm y+5 w1050 h142 vTabs",["Details","Duplicates","Settings"]) ; Critical Dependencies
    
    tabCtl.UseTab("Details")
    g.Add("Edit","xm y+5 w1050 r7 vDetails ReadOnly","")
    
    tabCtl.UseTab("Duplicates")
    g.Add("Edit","xm y+5 w1050 r7 vDuplicates ReadOnly","")
    
    ; tabCtl.UseTab("Critical Dependencies")
    ; g.Add("Edit","xm y+5 w1050 r7 vCritDep ReadOnly","")
    
    width := 450, ColW := 525
    
    tabCtl.UseTab("Settings")
    ctl := g.Add("CheckBox","vAutoLoad Section","Auto-Load last session on start")
    ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["AutoLoad"]
    
    ctl := g.Add("CheckBox","ys xs+" ColW " vDisableTooltips","Disable Tooltips")
    ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["DisableTooltips"]
    
    ctl := g.Add("Text","xs y+10 Section","MSVC compiler environment command.")
    ctl.SetFont("s8","Verdana")
    ctl := g.Add("Text","ys xs+" ColW,"GCC compiler environment command.")
    ctl.SetFont("s8","Verdana")
    
    g.Add("Radio","xs ys+25 vx64_MSVC_Sel Group","x64:").OnEvent("click",gui_events)
    g.Add("Radio","xs y+10 vx86_MSVC_Sel","x86:").OnEvent("click",gui_events)
    g.Add("Radio","xs+" ColW " yp-25 vx64_GCC_Sel","x64:").OnEvent("click",gui_events)
    g.Add("Radio","xs+" CoLW " y+10 vx86_GCC_Sel","x86:").OnEvent("click",gui_events)
    
    g.Add("Edit","xs+45 ys+22 w" width " vx64_MSVC",Settings["x64_MSVC"]).OnEvent("change",gui_events)
    g.Add("Edit","xs+45 y+2 w" width " vx86_MSVC",Settings["x86_MSVC"]).OnEvent("change",gui_events)
    g.Add("Edit","xs+" (ColW+45) " ys+22 w" width " vx64_GCC",Settings["x64_GCC"]).OnEvent("change",gui_events)
    g.Add("Edit","xs+" (ColW+45) " y+2 w" width " vx86_GCC",Settings["x86_GCC"]).OnEvent("change",gui_events)
    
    tabCtl.UseTab()
    ctl := g.Add("Text","xm ys+90 w1050 vTotal","")
    ctl.SetFont("s8","Verdana")
    
    If (!FileExist("const_list.txt"))
        ctl.Text := "No list of constants."
    Else
        ctl.Text := "Please Wait ..."
    
        
    g["NameFilter"].Focus()
    
    g[Settings["CompilerType"]].Value := 1
    
    MinMax := Settings["MinMax"]
    w := Settings["WH"][1]
    h := Settings["WH"][2]
    
    g.Show()

    WinWait g.hwnd
    g.GetPos(&x,&y)
    
    ; dbg("wtf minmax: " MinMax)
    
    If !MinMax {
        ; dbg("restore ...")
        ; g.Show("w" w " h" h)
        WinMove x, y, Settings["WH"][1], Settings["WH"][2], g.hwnd
    } Else If MinMax = 1 {
        ; dbg("maximize ...")
        ; g.Show("Maximize")
        WinMaximize g.hwnd
    } Else If MinMax = -1 {
        ; dbg("minimize ...")
        ; g.Show("Minimize")
        WinMinimize g.hwnd
    }
    
    return g
}

delay_MinMax(g, MinMax) {
    Global Settings
    g.GetPos(&x,&y)
    
    WinWait g.hwnd
    
    ; dbg("wtf minmax: " MinMax)
    
    If !MinMax
        WinMove x, y, Settings["WH"][1], Settings["WH"][2], g.hwnd
    Else If MinMax = 1 {
        WinMaximize g.hwnd
    } Else If MinMax = -1
        WinMinimize g.hwnd
}

size_gui(o, MinMax, gW, gH) {
    ; dbg("MinMax: " minMax " / w: " gW " / h: " gH)
    
    Global Settings
    Settings["MinMax"] := MinMax
    Settings["WH"] := []
    Settings["WH"].Push(gW)
    Settings["WH"].Push(gH)
    
    o["ConstList"].Move(,,gW-25,gH-240)
    o["Tabs"].Move(,gH-170,gW-25)
    o["Tabs"].ReDraw()
    o["Details"].Move(,,gW-25)
    o["Duplicates"].Move(,,gW-25)
    ; o["CritDep"].Move(,,gW-25)
    
    o["File"].Move(,gH-190,gW-515)
    o["File"].ReDraw()
    o["Total"].Move(,gH-20,gW-25)
}

close_gui(*) {
    Global Settings
    
    LV := app.mainGUI["ConstList"]
    Settings["ColWidths"] := []
    Loop 6
        Settings["ColWidths"].Push(LV.GetColWidth(A_Index))
    
    (Settings.Has("BoundFunc")) ? Settings.Delete("BoundFunc") : ""
    
    sText := jxon_dump(Settings,4)
    If (FileExist("settings.json"))
        FileDelete "settings.json"
    FileAppend sText, "settings.json"
    ExitApp
}

gui_context(ctl, Item, rc, X, Y) {
    Global Settings
    
    m := Menu()
    m.Add("&Copy Selected Constants (group)",ListView_MenuEvent)
    m.Add("Copy Selected Constant Details (single - &Focused)",ListView_MenuEvent)
    
    If ((app.ApiPath && Settings["Recents"].Has(app.ApiPath))
    || DirExist(Settings["GlobBaseFolder"])) && Settings["TextEditorLine"] {
        m.Add()
        m.Add("&Go To #Include",ListView_MenuEvent)
    }
    
    m.Add()
    m.Add("Edit &Value",ListView_MenuEvent)
    m.Add("Edit &Expr",ListView_MenuEvent)
    
    m.Show()
}

ListView_MenuEvent(ItemName, ItemPos, Menu) {
    Global Settings, const_list
    g := app.MainGUI
    LV := g["ConstList"]
    
    If (ItemName = "&Copy Selected Constants (group)")
        copy_const_group()
    Else If (ItemName = "Copy Selected Constant Details (single - &Focused)")
        copy_const_details()
    Else If (ItemName = "&Go To #Include") {
        If DirExist(Settings["GlobBaseFolder"])
            baseFolder := Settings["GlobBaseFolder"]
        Else If app.ApiPath
            baseFolder := Settings["Recents"][app.ApiPath]["BaseFolder"][1]
        Else {
            Msgbox "Invalid Base Folder specified."
            return
        }
        
        obj := const_list[LV.GetText(LV.GetNext())]
        _file := baseFolder "\" obj["file"]
        cmd := StrReplace(Settings["TextEditorLine"]," -n#"," -n" obj["line"])
        cmd := StrReplace(cmd,"[file]",'"' _file '"')
        
        If Settings["TextEditorLine"]
            Run cmd
        
    } Else If (ItemName = "Edit &Value") {
        details_display(LV,LV.GetNext(),true,"value")
    } Else If (ItemName = "Edit &Expr") {
        details_display(LV,LV.GetNext(),true,"exp")
    }
}

gui_events(ctl,info) { ; i, f, s, u, m, st, d ; filters
    Global Settings, const_list
    n := ctl.Name
    g := ctl.gui
    
    If (n = "Types") {
        incl_report()
        
    } Else If (n = "MoreFilters") {
        load_filters()
        
    } Else If (n = "NameBW") {
        g["NameFilter"].Focus()
        
    } Else If (n = "ValueEQ") {
        g["ValueFilter"].Focus()
        
    } Else If (n = "Reset") {
        g["NameFilter"].Value := ""
        g["ValueFilter"].Value := ""
        g["ExpFilter"].Value := ""
        g["Details"].Value := ""
        g["Duplicates"].Value := ""
        ; g["CritDep"].Value := ""
        g["NameBW"].Value := 0
        g["ValueEQ"].Value := 0
        g["Tabs"].Choose(1)
        
        Settings["FileFilter"] := ""
        Settings["CheckInteger"] := 1
        Settings["CheckFloat"] := 1
        Settings["CheckString"] := 1
        Settings["CheckStruct"] := 1
        Settings["CheckUUID"] := 1
        ; Settings["CheckMIDL"] := 1
        Settings["CheckEnum"] := 1
        Settings["CheckMacro"] := 1
        ; Settings["CheckType"] := 1
        Settings["CheckUnknown"] := 1
        Settings["CheckOther"] := 1
        ; Settings["CheckExpr"] := 1
        Settings["CheckDupe"] := 1
        Settings["CheckCrit"] := 1
        
        Settings["doReset"] := true
        relist_const()
        
    } Else If (n = "ConstList") {
        If (!info)
            return
        
        constName  := ctl.GetText(info)
        constValue := const_list[constName]["value"]
        constType  := const_list[constName]["type"]
        constExp   := const_list[constName]["exp"]
        constLine  := const_list[constName]["line"]
        constFile  := const_list[constName]["file"]
        
        While const_list.Has(constValue)
            constValue := const_list[constValue]["value"]
        
        (!const_list[constName].Has("dupe")) ? const_list[constName]["dupe"] := [] : "" ; for compatibility with older lists
        (!const_list[constName].Has("critical")) ? const_list[constName]["critical"] := Map() : ""
        
        dupes := const_list[constName]["dupe"].Length
        ; critDep := const_list[constName]["critical"].Count
        
        If (constType = "Enum" || constType = "Struct") {
            entity_view_exp := (InStr(constExp,"`n") ? "`r`n`r`n" : "") . constExp "`r`n" . (InStr(constExp,"`n") ? "`r`n`r`n" : "")
            g["Details"].Value := (dupes ? "Duplicate Values Exist`r`n`r`n" : "")
                                . constValue "`r`n`r`n"
                                . ((constExp != constValue) ? ("Expr: " entity_view_exp) : "")
                                . "Type:  " constType "    /    File:  " constFile "    /    Line:  " constLine
        } Else {
            g["Details"].Value := (dupes ? "Duplicate Values Exist`r`n`r`n" : "")
                                . constName " := " constValue . (IsInteger(constValue) ? "    (" Format("0x{:X}",constValue) ")`r`n" : "`r`n") "`r`n"
                                . "Value: " constValue "`r`n"
                                . "Expr:  " constExp "`r`n"
                                . "Type:  " constType "    /    File:  " constFile "    /    Line:  " constLine
        }
        
        g["Duplicates"].Value := ""
        If (dupes) {
            dupeStr := "", dupeArr := const_list[constName]["dupe"]
            For i, obj in dupeArr {
                dValue := obj["value"], dExp := obj["exp"]
                dLine := obj["line"], dFile := obj["file"]
                sLine := "Value: " dValue "`r`n"
                       . "Expr:  " dExp "`r`n"
                       . "File:  " dFile "    /    Line: " dLine "`r`n`r`n"
                
                dupeStr .= sLine
            }
            dupeStr := Trim(dupeStr,"`r`n")
            g["Duplicates"].Value := dupeStr
        }
        
        ; g["CritDep"].Value := ""
        ; If (critDep) {
            ; crit := const_list[constName]["critical"], critList := "Entries: " crit.Count "`r`n`r`n"
            ; For const, o in crit {
                ; critList .= const " / Type: " o["type"] " / Value: " o["value"] " / Dupes: Yes`r`n`r`n"
            ; }
            ; g["CritDep"].Value := Trim(critList,"`r`n")
        ; }
        
    } Else If (n = "NameFilterClear") {
        g["NameFilter"].Value := ""
        g["NameBW"].Value := 0
        g["NameFilter"].Focus()
        
    } Else If (n = "ValueFilterClear") {
        g["ValueFilter"].Value := ""
        g["ValueEQ"].Value := 0
        g["ValueFilter"].Focus()
        
    } Else If (n = "ExpFilterClear") {
        g["ExpFilter"].Value := ""
        g["ExpFilter"].Focus()
        
    } Else If (n = "FileFilterClear") {
        ctl.gui["FileFilter"].Text := ""
        Settings["FileFilter"] := ""
        
    } Else If (n = "FileFilter") {
        Settings["FileFilter"] := ctl.gui["FileFilter"].Text
        
    } Else If (n = "AutoLoad") {
        Settings["AutoLoad"] := ctl.Value
        
    } Else If (n = "RemBaseFile") {
        curFile := g["ApiPath"].Text
        curBase := Settings["baseFiles"], newList := []
        For i, file_name in curBase {
            If (file_name != curFile)
                newList.Push(file_name)
        }
        g["ApiPath"].Delete()
        g["ApiPath"].Add(newList)
        Settings["baseFiles"] := newList
        g["ApiPath"].Text := curFile
        
    } Else If (n="x64_MSVC_Sel" Or n="x86_MSVC_Sel" Or n="x64_GCC_Sel" Or n="x86_GCC_Sel")
        Settings["CompilerType"] := n
        
    Else If (n="x64_MSVC") Or (n="x86_MSVC") Or (n="x64_GCC") Or (n="x86_GCC")
        Settings[n] := ctl.Value
        
    Else If (n="Search")
        relist_const()
        
    Else If (n="DisableTooltips")
        Settings["DisableTooltips"] := ctl.Value
}

recents_menu() {
    Global Settings
    mb_recent := menu(), app.recent_handle := mb_recent.handle
    mb_recent.Add("Clear &Recents",menu_events)
    mb_recent.Add("&Edit Recents",menu_events)
    mb_recent.Add()
    For file_name in Settings["Recents"] {
        mb_recent.Add(file_name,menu_events)
        If (file_name = app.ApiPath)
            mb_recent.Check(file_name)
    }
    
    return mb_recent
}

load_menubar() {
    Global Settings, includes_all
    ; mb_source := menu()
    ; mb_source.Add("Source &File",menu_events) ; "Source" > "Select C++ Source" submenu
    ; mb_source.Add("Source &Directory",menu_events)
    ; mb_source.Add("&Create Collection",menu_events)
    
    ; mb_scan := menu()                       ; "Source" > "Scanning" submenu
    ; mb_scan.Add("&Scan Now",menu_events)
    ; mb_scan.Add()
    ; mb_scan.Add("Select Scan Type:",menu_events)
    ; mb_scan.Disable("Select Scan Type:")
    ; mb_scan.Add("C&ollect",menu_events,"+Radio")
    ; mb_scan.Add("&Includes Only",menu_events,"+Radio")
    ; mb_scan.Check(Settings["ScanType"])
    
    mb_src := menu()                        ; "Source" root menu
    mb_src.Add("&New Profile",menu_events)
    mb_src.Add("&Load Recent", recents_menu())
    mb_src.Add("&Edit Profile",menu_events)
    mb_src.Add()
    mb_src.Add("&Global Settings",menu_events)
    mb_src.Add()
    ; mb_src.Add("S&canning", mb_scan)
    mb_src.Add("&Scan Now",menu_events)
    
    mb_data := menu()                       ; "Data" root menu
    mb_data.Add("&Load constants",menu_events)
    mb_data.Add("&Save constants",menu_events)
    mb_data.Add()
    mb_data.Add("&Overwrite Automatically",menu_events)
    mb_data.Add()
    mb_data.Add("Open &Data Folder",menu_events)
    Settings["OverwriteSave"] ? mb_data.Check("&Overwrite Automatically") : ""
    
    mb_copy := menu()                       ; "List" root menu
    mb_copy.Add("Copy &selected constant details (single - CTRL+SHIFT+D)",menu_events)
    mb_copy.Add("Copy selected constant &name only (single - CTRL+D)",menu_events)
    mb_copy.Add()
    mb_copy.Add("&Copy selected constants (group)",menu_events)
    mb_copy.Add()
    mb_copy.Add("View values as &Hex",menu_events,"+Radio")
    mb_copy.Add("View values as &Decimal",menu_events,"+Radio")
    mb_copy.Add()
    mb_copy.Add("&var := value",menu_events,"+Radio")
    mb_copy.Add("var &only",menu_events,"+Radio")
    mb_copy.Add()
    mb_copy.Add("&Prepend comment char on copy",menu_events)
    
    var_cpy := (Settings.Has("var_copy")) ? Settings["var_copy"] : "&var := value"
    mb_copy.Check(var_cpy)
    mb_copy.Check("View values as &" Settings["ViewBase"])
    
    If Settings["var_copy_comment"]
        mb_copy.Check("&Prepend comment char on copy")
    
    mb_compile := menu()                    ; "Compile" root menu
    mb_compile.Add("&Uncheck all constants (CTRL + SHIFT + U)",menu_events)
    mb_compile.Add("&Only Add #INCLUDES for checked constants",menu_events) ; Add #INCLUDES for checked constants
    mb_compile.Add()
    mb_compile.Add("&Compile and test checked constants (CTRL + SHIFT + C)",menu_events)
    If Settings["AddIncludes"]
        mb_compile.Check("&Only Add #INCLUDES for checked constants")
    
    If includes_all.Length { ; only attempt this if profile is saved
        mb_files := menu()
        
        for i, _file in includes_all
            mb_files.Add("-> " _file, menu_events)
        
        If (includes_all.Length > 1) {
            mb_files.Add()
            mb_Files.Add("-> All", menu_events)
        }
    }
    
    mb_settings := Menu()
    mb_settings.Add("Set &Text Editor: " Settings["TextEditor"], menu_events)
    mb_settings.Add("Set &Go-To Line command: " Settings["TextEditorLine"], menu_events)
    mb_settings.Add("Set Global &Base Folder: " Settings["GlobBaseFolder"], menu_events)
    
    mb := Menubar()
    mb.Add("&Source", mb_src)
    mb.Add("&Data", mb_data)
    mb.Add("&List", mb_copy)
    RegExMatch(ct := Settings["CompilerType"],"^(x86|x64)_(MSVC|GCC)",&m)
    If Settings[StrReplace(ct,"_Sel","")] ; only show compiler menu if options are defined
        mb.Add("&Compile", mb_compile)
    
    If includes_all.Length
        mb.Add("&Includes", mb_files)
    
    mb.Add("S&ettings", mb_settings)
    
    return mb
}

check_data_file(_in) {
    root := A_ScriptDir "\data\*.data"
    Loop Files root, "R"
    {
        If A_LoopFileName = _in
            return A_LoopFileFullPath
    }
    return false
}

menu_events(ItemName, ItemPos, _o) {
    Global Settings, const_list, includes_all, sizeof_list
    n := ItemName, g := app.mainGUI
    
    
    
    If (n = "&New Profile") {
        const_list := Map(), includes_all := [], sizeof_list := Map()
        app.mainGUI["ConstList"].Delete()
        app.mainGUI.Title := "C++ Constants Scanner"
        app.ApiPath := ""
        extra_dirs()
    } Else If (n="&Edit Recents") {
        recents_gui()
    } Else If (n = "Clear &Recents") {
        Settings["baseFiles"] := Map()
        Settings["dirs"] := Map()
        app.mainGUI.Menubar := load_menubar()
    } Else If (_o.Handle = app.recent_handle And Settings["Recents"].Has(n)) { ; selecting a recent profile
        app.ApiPath := Settings["Recents"][n]["Name"]
        app.mainGUI.Title := "C++ Constants Scanner - " Settings["Recents"][n]["Name"]
        app.mainGUI.Menubar := load_menubar()
        
        If (profile:=check_data_file(app.ApiPath ".data"))
            LoadFile([profile])
    } Else If (n = "C&ollect") Or (n = "&Includes Only") {
        Static scan_type := ["C&ollect","&Includes Only"] ; ,"x64 &MSVC","x86 M&SVC","x64 &GCC","x86 G&CC"]
        For typ in scan_type
            _o.Uncheck(typ)
        _o.Check(n)
        Settings["ScanType"] := n
    } Else If (n = "&Edit Profile") {
        If app.ApiPath {
            extra_dirs()
        } Else MsgBox("Load/Create a profile first.",,"Owner" app.mainGUI.hwnd)
    } Else if (n = "&Global Settings") {
        global_settings_gui()
    } Else If (n = "&Scan Now") {
        scan_now()
        
        
        
    } Else If (n = "&Load Constants") {
        LoadFile()
    } Else If (n = "&Save Constants") {
        SaveFile()
    } Else if (n = "&Overwrite Automatically") {
        Settings["OverwriteSave"] := !Settings["OverwriteSave"]
        app.MainGUI.Menubar := load_menubar()
    } Else if (n = "Open &Data Folder") {
        Run('explorer.exe "' A_ScriptDir '\data"')
    
        
        
    } Else if (n="Copy &selected constant details (single - CTRL+SHIFT+D)") {
        copy_const_details()
    } Else If (n="Copy selected constant &name only (single - CTRL+D)") {
        copy_const_only()
    } Else if (n="&Copy selected constants (group)") {
        copy_const_group()
    } Else If (n = "&var := value") Or (n = "var &only") {
        Settings["var_copy"] := n
        _o.Uncheck("&var := value"), _o.Uncheck("var &only")
        _o.Check(n)
    } Else If (n="&Prepend comment char on copy") {
        If Settings["var_copy_comment"] {
            Settings["var_copy_comment"] := false
            _o.UnCheck(n)
        } Else {
            Settings["var_copy_comment"] := true
            _o.Check(n)
        }
    } Else If InStr(n,"View values as") {
        If InStr(n,"Hex")
            Settings["ViewBase"] := "Hex"
        Else If InStr(n,"Decimal")
            Settings["ViewBase"] := "Decimal"
        _o.Uncheck("View values as &Hex"), _o.Uncheck("View values as &Decimal")
        _o.Check(n)
        HexDecToggle(StrReplace(n,"View values as &",""))
    } Else If (n="&Uncheck all constants (CTRL + SHIFT + U)") {
        g["ConstList"].Modify(0,"-Check")
    } Else If (n="&Only Add #INCLUDES for checked constants") {
        Settings["AddIncludes"] := !Settings["AddIncludes"]
        _o.ToggleCheck(n)
    } Else if (n="&Compile and test checked constants (CTRL + SHIFT + C)") {
        compile_constants()
    
    
    
    } Else if (n = "-> All") {
        ; _files := Settings["Recents"][app.ApiPath]["OtherDirList"]
        For i, _file in includes_all {
            If FileExist(_file)
                Run '"' Settings["TextEditor"] '" "' _file[3] '"'
            Else If FileExist(Settings["GlobBaseFolder"] "\" _file)
                Run Settings["TextEditor"] ' "' Settings["GlobBaseFolder"] "\" _file '"'
        }
    
    } Else If (InStr(n,"->") = 1) {
        _file := RegExReplace(n,"^\-> ","")
        If FileExist(_file)
            Run Settings["TextEditor"] ' "' _file '"'
        Else If FileExist(Settings["GlobBaseFolder"] "\" _file)
            Run Settings["TextEditor"] ' "' Settings["GlobBaseFolder"] "\" _file '"'
    
    
    
    } Else If (InStr(n,"Set &Text Editor:") = 1) {
        obj := InputBox("Enter command line for Text Editor:","Text Editor Command Line",,Settings["TextEditor"])
        If (obj.result != "OK")
            return 
        Settings["TextEditor"] := obj.value
        app.mainGUI.menubar := load_menubar()
    } Else if (InStr(n,"Set &Go-To Line command") = 1) {
        obj := InputBox("Enter command line for Go To Line:","Go To Line Command",,Settings["TextEditorLine"])
        If (obj.result != "OK")
            return
        Settings["TextEditorLine"] := obj.value
        app.mainGUI.menubar := load_menubar()
    } Else If (InStr(n,"Set Global &Base Folder") = 1) {
        obj := InputBox("Enter path to Global Base Folder:","Global Base Folder",,Settings["GlobBaseFolder"])
        If (obj.result != "OK")
            return
        Settings["GlobBaseFolder"] := obj.value
        app.mainGUI.menubar := load_menubar()
    }
}

compile_constants() {
    Global Settings
    
    If !app.ApiPath {
        Msgbox("Load or Create a profile first.",,"Owner" app.mainGUI.hwnd)
        return
    }
    
    If !(create_cpp_file()) {
        Msgbox "No valid constants selected.`n`n"
             . "Currntly supported types:`n`n"
             . "Integer, Float, String, Struct`n`n"
             . "Struct returns sizeof(struct_name)."
        Return
    }
    RegExMatch(ct := Settings["CompilerType"],"^(x86|x64)_(MSVC|GCC)",&m)
    
    If (IsObject(m) And m.Count = 2) {
        If (m[2] = "MSVC")
            error_check := CliData(Settings[StrReplace(ct,"_Sel","")] " & cl /EHsc test_const.cpp")
        Else If (m[2] = "GCC")
            error_check := CliData(Settings[StrReplace(ct,"_Sel","")] " & g++ -static -o test_const.exe test_const.cpp")
        
        If FileExist("test_const.exe") {
            r := CliData("test_const.exe"), final := ""
            
            Loop Parse r, "`n", "`r"
            {
                var := Trim(SubStr(A_LoopField,1,e:=InStr(A_LoopField,"=")-1))
                val := Trim(SubStr(A_LoopField,e+2))
                val_chk := const_list[var]["value"]
                
                If RegExMatch(val,"^[A-Fa-f0-9]+$") And RegExMatch(val,"[A-Fa-f]+")
                    val := Integer("0x" val)
                
                If (const_list[var]["type"]="Struct")
                    val := "size: " val " bytes"
                Else {
                    _chk := (val=val_chk) ? "  ( Good! )" : "  ( Wrong! )"
                    If (val >= -2147483648 And val <= 4294967295)
                        val := val " / " Format("0x{:08X}",val) _chk
                     Else
                        val := val " / " Format("0x{:016X}",val) _chk
                }
                
                final .= var " = " val "`r`n"
            }
            
            result_gui(Trim(final,"`r`n"))
        } Else
            result_gui( "The file did not compile.`r`n`r`n===================================`r`n`r`n" error_check )
    }
}

scan_now() {
    Global Settings, abort_parser, prog
    If !app.ApiPath {
        Msgbox("Select a profile first.",,"Owner" app.mainGUI.hwnd)
        return
    }
    
    res := MsgBox("Start scan now?`r`n`r`nThis will destroy the current list and scan the specified C++ Source Header and includes.","Confirm Scan","4 Owner" app.mainGUI.hwnd)
    If (res = "no")
        return
    
    g := app.mainGUI
    g["NameFilter"].Value := ""
    g["NameBW"].Value := 0
    g["ValueFilter"].Value := ""
    g["ValueEQ"].Value := 0
    g["ExpFilter"].Value := ""
    Settings["FileFilter"] := ""
    
    g["Details"].Value := ""
    g["Duplicates"].Value := ""
    ; g["CritDep"].Value := ""
    
    g["Tabs"].Choose(1)
    UnlockGui(false)
    
    g["ConstList"].Delete()
    g["Total"].Text := "Scanning header files..."
    
    ScanType := StrReplace(Settings["ScanType"],"&","")
    abort_parser := false
    
    If (ScanType = "Collect")
        header_parser()
    ; Else If (ScanType = "Includes Only")
        ; includes_report()
    Else if InStr(ScanType,"x86") Or InStr(ScanType,"x64")
        header_parser()
    
    (!abort_parser) ? relist_const() : (prog := "")
    
    UnlockGui(true)
    
    app.mainGUI.menubar := load_menubar()
    
    g.Flash()
}

copy_const_details() {
    comment := (Settings["var_copy_comment"]) ? "; " : ""
    final := ""
    Loop Parse app.mainGUI["Details"].Value, "`n", "`r"
        final .= ((A_Index=1)?"":"`r`n") comment A_LoopField
    A_Clipboard := final
}

copy_const_only() {
    comment := (Settings["var_copy_comment"]) ? "; " : ""
    If (n := app.mainGUI["ConstList"].GetNext())
        A_Clipboard := comment app.mainGUI["ConstList"].GetText(n)
}

copy_const_group() {
    list := "", n := 0, g := app.mainGUI
    comment := (Settings["var_copy_comment"]) ? "; " : ""
    While(n := g["ConstList"].GetNext(n)) {
        If StrReplace(Settings["var_copy"],"&","") = "var only"
            list .= ((A_Index=1)?"":"`r`n") comment g["ConstList"].GetText(n)
        Else If StrReplace(Settings["var_copy"],"&","") = "var := value"
            list .= ((A_Index=1)?"":"`r`n") comment g["ConstList"].GetText(n) " := " g["ConstList"].GetText(n,2)
    }
    A_Clipboard := list
}

result_gui(txt) {
    _gui := Gui("-MinimizeBox -MaximizeBox +AlwaysOnTop","Compiler Output")
    _gui.OnEvent("escape",result_close)
    
    _gui.Add("Edit","w500 r10 ReadOnly",txt)
    _gui.Add("Text","","Press ESC or close to exit.")
    _gui.Add("Button","w50 yp xp+450 vClose","Close").OnEvent("click",result_close2)
    _gui.Show("")
    _gui["Close"].Focus()
}

result_close2(ctl,info) {
    ctl.gui.Destroy()
}

result_close(_gui) {
    _gui.Destroy()
}

; ==================================================================
; ==================================================================
; Details display GUI
; ==================================================================
; ==================================================================

details_display(ctl, row, _edit:=false, _name:="") {
    Global Settings, const_list
    
    if !row
        return
    
    _main := app.mainGUI
    const := _main["ConstList"].GetText(row)
    
    g := Gui("+Resize +Owner" _main.hwnd, "Details Display")
    g.OnEvent("Escape",details_close)
    g.OnEvent("Close",details_close)
    g.OnEvent("Size",details_size)
    
    If !_edit {
        edit_ctl := g.Add("Edit","vDisp w750 h750 ReadOnly")
        edit_ctl.Value := _main["Details"].Value
    } Else {
        edit_ctl := g.Add("Edit","vDisp w750 h750")
        edit_ctl.Value := const_list[const][_name]
    }
    
    edit_ctl.SetFont("s12","Consolas")
    If !_edit {
        PostMessage 0xB1, 0, 0, edit_ctl.hwnd ; EM_SETSEL
        g.Add("Text","vTxtMsg y+10","Press ESC to exit.")
    } Else
        g.Add("Text","vTxtMsg y+10","Press ESC to exit / CTRL + S to save.")
    
    ctl := g.Add("CheckBox","vMaxDispOpen","Maximize on open")
    ctl.OnEvent("Click",details_event)
    ctl.value := Settings["MaxDispOpen"]
    
    app.edit_gui := g
    app.edit_const := const
    app.edit_row := row
    app.edit_prop := _name
    
    g.Show()
    WinWait g.hwnd
    
    If Settings["MaxDispOpen"]
        WinMaximize g.hwnd
    
    WinSetEnabled false, "ahk_id " _main.hwnd
}

details_event(ctl, info) {
    If (ctl.name = "MaxDispOpen")
        Settings["MaxDispOpen"] := ctl.value
}

details_close(_gui) {
    Global Settings
    _gui.Destroy()
    app.edit_gui := {hwnd:0}
    app.edit_const := ""
    app.edit_row := 0
    app.edit_prop := ""
    
    WinSetEnabled true, "ahk_id " app.mainGUI.hwnd
    WinActivate "ahk_id " app.mainGUI.hwnd 
}

details_size(g, MinMax, w, h) {
    Global Settings
    ; If Settings["MaxDispOpen"] && !MinMax
        ; return
    
    g["Disp"].Move(,,w-(g.MarginX * 2),h-(g.MarginY * 2)-20)
    g["TxtMsg"].Move(,h-(g.MarginY * 2)-7)
    
    g["MaxDispOpen"].GetPos(,,&_w)
    g["MaxDispOpen"].Move(w-(g.MarginX * 2)-_w,h-(g.MarginY * 2)-7)
}