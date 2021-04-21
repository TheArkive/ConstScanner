load_gui() {
    g := Gui("+OwnDialogs +Resize +MinSize1076x488","C++ Constants Scanner")
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
    
    ctl := g.Add("Button","x+5 hp w65 vIncludes","Includes")
    ctl.OnEvent("click",gui_events)
    ctl.SetFont("s8","Verdana")
    
    ctl := g.Add("ListView","xm y+5 w1051 h300 vConstList Checked",["Name","Value","Type","File","D","C"]) ; w1050
    ctl.OnEvent("ContextMenu",gui_context)
    
    If !Settings.Has("ColWidths")
        Settings["ColWidths"] := [435, 190, 135, 200, 30, 30]
    
    Loop Settings["ColWidths"].Length
        ctl.ModifyCol(A_Index, Settings["ColWidths"][A_Index])
    ; ctl.ModifyCol(1,435), ctl.ModifyCol(2,190), ctl.ModifyCol(3,135), ctl.ModifyCol(4,200), ctl.ModifyCol(5,30), ctl.ModifyCol(6,30)
    ctl.OnEvent("click",gui_events)
    ctl.OnEvent("doubleclick",details_display)
    
    ; g.Add("Text","xm y+5 vHelper","Press CTRL+D to copy selected constant details.")
    g.Add("Text","x500 y+5 w560 Right vFile","Data File:")
    
    tabCtl := g.Add("Tab3","Section xm y+5 w1050 h142 vTabs",["Details","Duplicates","Critical Dependencies","Settings"]) ; Critical Dependencies
    
    tabCtl.UseTab("Details")
    g.Add("Edit","xm y+5 w1050 r7 vDetails ReadOnly","")
    
    tabCtl.UseTab("Duplicates")
    g.Add("Edit","xm y+5 w1050 r7 vDuplicates ReadOnly","")
    
    tabCtl.UseTab("Critical Dependencies")
    g.Add("Edit","xm y+5 w1050 r7 vCritDep ReadOnly","")
    
    width := 450, ColW := 525
    
    tabCtl.UseTab("Settings")
    ctl := g.Add("CheckBox","vAutoLoad Section","Auto-Load most recent file on start")
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
    
    If !Settings["MinMax"]
        g.Show("w" Settings["WH"][1] " h" Settings["WH"][2])
    Else If Settings["MinMax"] = 1
        g.Show("Maximize")
    Else If Settings["MinMax"] = -1
        g.Show("Minimize")
        
    g["NameFilter"].Focus()
    
    g[Settings["CompilerType"]].Value := 1
    
    return g
}

size_gui(o, MinMax, gW, gH) {
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
    o["CritDep"].Move(,,gW-25)
    
    o["File"].Move(,gH-190,gW-515)
    o["File"].ReDraw()
    o["Total"].Move(,gH-20,gW-25)
}

close_gui(*) {
    Global Settings
    
    LV := Settings["gui"]["ConstList"]
    Settings["ColWidths"] := []
    Loop 6
        Settings["ColWidths"].Push(LV.GetColWidth(A_Index))
    
    Settings["ApiPath"] := "" ; these values are meant to be temporary, but need to be accessed globally
    Settings["BaseSearchDir"] := ""
    Settings["DefaultIncludes"] := Map()
    Settings["recent_handle"] := 0
    Settings.Has("temp_gui") ? Settings.Delete("temp_gui") : ""
    Settings.Delete("gui")
    (Settings.Has("BoundFunc")) ? Settings.Delete("BoundFunc") : ""
    
    sText := jxon_dump(Settings,4)
    If (FileExist("settings.json"))
        FileDelete "settings.json"
    FileAppend sText, "settings.json"
    ExitApp
}

gui_context(ctl, Item, rc, X, Y) {
    m := Menu()
    m.Add("&Copy Constants (group)",ListView_MenuEvent)
    m.Add("Copy Constant Details (single - &Focused)",ListView_MenuEvent)
    m.Show()
}

ListView_MenuEvent(ItemName, ItemPos, Menu) {
    If (ItemName = "&Copy Constants (group)")
        copy_const_group()
    Else If (ItemName = "Copy Constant Details (single - &Focused)")
        copy_const_details()
}

gui_events(ctl,info) { ; i, f, s, u, m, st, d ; filters
    Global Settings, const_list
    n := ctl.Name
    ; g := Settings["gui"]
    g := ctl.gui
    
    If (n = "Includes") {
        incl_report()
    } Else If (n = "MoreFilters") {
        load_filters()
    } Else If (n="integer" Or n="float" Or n="string" Or n="unknown" Or n="other" Or n="expr" Or n="dupe" Or n="crit" Or n="struct" Or n="enum") {
        Settings["Check" n] := ctl.Value
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
        g["CritDep"].Value := ""
        g["NameBW"].Value := 0
        g["ValueEQ"].Value := 0
        g["Tabs"].Choose(1)
        
        Settings["FileFilter"] := ""
        Settings["CheckInteger"] := 1
        Settings["CheckFloat"] := 1
        Settings["CheckString"] := 1
        Settings["CheckStruct"] := 1
        Settings["CheckEnum"] := 1
        Settings["CheckUnknown"] := 1
        Settings["CheckOther"] := 1
        Settings["CheckExpr"] := 1
        Settings["CheckDupe"] := 1
        Settings["CheckOther"] := 1
        Settings["CheckCrit"] := 1
        
        Settings["doReset"] := true
        relist_const()
    } Else If (n = "ConstList") {
        If (!info)
            return
        
        constName := ctl.GetText(info)
        constValue := StrReplace(StrReplace(const_list[constName]["value"],"\r","`r"),"\n","`n")
        constType := const_list[constName]["type"]
        constExp := const_list[constName]["exp"]
        constLine := const_list[constName]["line"]
        constFile := const_list[constName]["file"]
        dupes := const_list[constName].Has("dupe")
        critDep := const_list[constName].Has("critical")
        
        If (constType = "Struct" Or constType = "Enum") {
            g["Details"].Value := (dupes ? "Duplicate Values Exist`r`n`r`n" : "")
                                . StrReplace(constValue,"\t"," ") "`r`n"
                                . "`r`nType:  " constType "    /    File:  " constFile "    /    Line:  " constLine
        } Else {
            g["Details"].Value := (dupes ? "Duplicate Values Exist`r`n`r`n" : "")
                                . constName " := " constValue . (IsInteger(constValue) ? "    (" Format("0x{:X}",constValue) ")`r`n" : "`r`n")
                                . "`r`nValue: " constValue "`r`nExpr:  " constExp "`r`nType:  " constType "    /    File:  " constFile "    /    Line:  " constLine
        }
        
        g["Duplicates"].Value := ""
        If (dupes) {
            dupeStr := "", dupeArr := const_list[constName]["dupe"]
            For i, obj in dupeArr {
                dValue := obj["value"], dExp := obj["exp"]
                dLine := obj["line"], dFile := obj["file"]
                sLine := "Value: " dValue "`r`nExpr:  " dExp "`r`nFile:  " dFile "    /    Line: " dLine "`r`n`r`n"
                
                dupeStr .= sLine
            }
            dupeStr := Trim(dupeStr,"`r`n")
            g["Duplicates"].Value := dupeStr
        }
        
        g["CritDep"].Value := ""
        If (critDep) { ; item := Map("exp",constExp,"comment",comment,"file",file,"line",i,"value",vConst.value,"type",vConst.type)
            crit := const_list[constName]["critical"], critList := "Entries: " crit.Count "`r`n`r`n"
            For const, o in crit {
                critList .= const " / Type: " o["type"] " / Value: " o["value"] " / Dupes: Yes`r`n`r`n"
            }
            g["CritDep"].Value := Trim(critList,"`r`n")
        }
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
    mb_recent := menu(), Settings["recent_handle"] := mb_recent.handle
    mb_recent.Add("Clear &Recents",menu_events)
    mb_recent.Add("&Edit Recents",menu_events)
    mb_recent.Add()
    For file_name in Settings["Recents"] {
        mb_recent.Add(file_name,menu_events)
        If (file_name = Settings["ApiPath"])
            mb_recent.Check(file_name)
    }
    
    return mb_recent
}

load_menubar() {
    Global Settings
    mb_source := menu()
    mb_source.Add("Source &File",menu_events) ; "Source" > "Select C++ Source" submenu
    mb_source.Add("Source &Directory",menu_events)
    mb_source.Add("&Create Collection",menu_events)
    
    mb_scan := menu()                       ; "Source" > "Scanning" submenu
    mb_scan.Add("&Scan Now",menu_events)
    mb_scan.Add()
    mb_scan.Add("Select Scan Type:",menu_events)
    mb_scan.Disable("Select Scan Type:")
    mb_scan.Add("C&ollect",menu_events,"+Radio")
    mb_scan.Add("&Includes Only",menu_events,"+Radio")
    mb_scan.Check(Settings["ScanType"])
    
    mb_src := menu()                        ; "Source" root menu
    mb_src.Add("&New Profile",menu_events)
    mb_src.Add("&Load Recent", recents_menu())
    mb_src.Add("&Edit Profile",menu_events)
    mb_src.Add()
    mb_src.Add("S&canning", mb_scan)
    
    mb_data := menu()                       ; "Data" root menu
    mb_data.Add("&Load constants",menu_events)
    mb_data.Add("&Save constants",menu_events)
    
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
    
    var_cpy := (Settings.Has("var_copy")) ? Settings["var_copy"] : "&var := value"
    mb_copy.Check(var_cpy)
    mb_copy.Check("View values as &" Settings["ViewBase"])
    
    mb_compile := menu()                    ; "Compile" root menu
    mb_compile.Add("&Uncheck all constants",menu_events)
    mb_compile.Add("&Add #INCLUDES for checked constants",menu_events)
    mb_compile.Add()
    mb_compile.Add("&Compile and test checked constants",menu_events)
    If Settings["AddIncludes"]
        mb_compile.Check("&Add #INCLUDES for checked constants")
    
    mb := Menubar()
    mb.Add("&Source", mb_src)
    mb.Add("&Data", mb_data)
    mb.Add("&List", mb_copy)
    mb.Add("&Compile",mb_compile)
    
    return mb
}

menu_events(ItemName, ItemPos, _o) {
    Global Settings
    n := ItemName, g := Settings["gui"]
    
    
    
    If (n = "&New Profile") {
        const_list := "", IncludesList := ""
        Settings["gui"]["ConstList"].Delete()
        Settings["gui"].Title := "C++ Constants Scanner"
        Settings["ApiPath"] := ""
        extra_dirs()
    } Else If (n="&Edit Recents") {
        recents_gui()
    } Else If (n = "Clear &Recents") {
        Settings["baseFiles"] := Map()
        Settings["dirs"] := Map()
        Settings["gui"].Menubar := load_menubar()
    } Else If (_o.Handle = Settings["recent_handle"] And Settings["Recents"].Has(n)) { ; selecting a recent profile
        Settings["ApiPath"] := Settings["Recents"][n]["Name"]
        Settings["gui"].Title := "C++ Constants Scanner - " Settings["Recents"][n]["Name"]
        Settings["gui"].Menubar := load_menubar()
    } Else If (n = "C&ollect") Or (n = "&Includes Only") {
        Static scan_type := ["C&ollect","&Includes Only"] ; ,"x64 &MSVC","x86 M&SVC","x64 &GCC","x86 G&CC"]
        For typ in scan_type
            _o.Uncheck(typ)
        _o.Check(n)
        Settings["ScanType"] := n
    } Else If (n = "&Edit Profile") {
        If Settings["ApiPath"] {
            extra_dirs()
        } Else MsgBox("Load/Create a profile first.")
    } Else If (n = "&Scan Now") {
        scan_now()
        
        
        
    } Else If (n = "&Load Constants") {
        LoadFile()
    } Else If (n = "&Save Constants") {
        SaveFile()
        
        
        
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
    } Else If InStr(n,"View values as") {
        If InStr(n,"Hex")
            Settings["ViewBase"] := "Hex"
        Else If InStr(n,"Decimal")
            Settings["ViewBase"] := "Decimal"
        _o.Uncheck("View values as &Hex"), _o.Uncheck("View values as &Decimal")
        _o.Check(n)
        HexDecToggle()
    } Else If (n="&Uncheck all constants") {
        g["ConstList"].Modify(0,"-Check")
    } Else If (n="&Add #INCLUDES for checked constants") {
        Settings["AddIncludes"] := !Settings["AddIncludes"]
        _o.ToggleCheck(n)
    } Else if (n="&Compile and test checked constants") {
        If !Settings["ApiPath"] {
            Msgbox "Load or Create a profile first."
            return
        }
        
        create_cpp_file()
        RegExMatch(Settings["CompilerType"],"^(x86|x64)_(MSVC|GCC)",&m)
        
        If (IsObject(m) And m.Count() = 2) {
            If (m.Value(2) = "MSVC")
                error_check := CliData("vcvars " m.Value(1) " & cl /EHsc test_const.cpp")
            Else If (m.Value(2) = "GCC")
                error_check := CliData("msystem mingw" StrReplace(m.Value(1),"x","") " & g++ -o test_const.exe test_const.cpp")
            
            If FileExist("test_const.exe") {
                r := CliData("test_const.exe"), final := ""
                
                Loop Parse r, "`n", "`r"
                {
                    var := Trim(SubStr(A_LoopField,1,e:=InStr(A_LoopField,"=")-1))
                    val := Trim(SubStr(A_LoopField,e+2))
                    
                    If RegExMatch(val,"^[A-Fa-f0-9]+$") And RegExMatch(val,"[A-Fa-f]+")
                        val := Integer("0x" val)
                    
                    If (val >= -2147483648 And val <= 4294967295) {
                        final .= var " = " val " / " Format("0x{:08X}",val) "`r`n"    ; 32-bit
                    } Else {
                        final .= var " = " val " / " Format("0x{:016X}",val) "`r`n"   ; 64-bit
                    }
                }
                
                result_gui(Trim(final,"`r`n"))
            } Else
                result_gui( "The file did not compile.`r`n`r`n===================================`r`n`r`n" error_check )
        }
    }
}

scan_now() {
    Global Settings
    If !Settings["ApiPath"] {
        Msgbox "Select a C++ Source Header file first."
        return
    }
    
    res := MsgBox("Start scan now?`r`n`r`nThis will destroy the current list and scan the specified C++ Source Header and includes.","Confirm Scan",4)
    If (res = "no")
        return
    
    g := Settings["gui"]
    g["NameFilter"].Value := ""
    g["NameBW"].Value := 0
    g["ValueFilter"].Value := ""
    g["ValueEQ"].Value := 0
    g["ExpFilter"].Value := ""
    Settings["FileFilter"] := ""
    
    g["Details"].Value := ""
    g["Duplicates"].Value := ""
    g["CritDep"].Value := ""
    
    g["Tabs"].Choose(1)
    UnlockGui(false)
    
    g["ConstList"].Delete()
    g["Total"].Text := "Scanning header files..."
    
    ScanType := StrReplace(Settings["ScanType"],"&","")
    
    If (ScanType = "Collect")
        header_parser()
    Else If (ScanType = "Includes Only")
        includes_report()
    Else if InStr(ScanType,"x86") Or InStr(ScanType,"x64")
        header_parser()
    
    relist_const()
    UnlockGui(true)
    
    g.Flash()
}

copy_const_details() {
    A_Clipboard := Settings["gui"]["Details"].Value
}

copy_const_only() {
    n := Settings["gui"]["ConstList"].GetNext()
    If (n) {
        t := Settings["gui"]["ConstList"].GetText(n)
        A_Clipboard := t
    }
}

copy_const_group() {
    list := "", n := 0, g := Settings["gui"]
    While(n := g["ConstList"].GetNext(n)) {
        If StrReplace(Settings["var_copy"],"&","") = "var only"
            list .= g["ConstList"].GetText(n) "`r`n"
        Else If StrReplace(Settings["var_copy"],"&","") = "var := value" {
            value := (IsInteger(value:=g["ConstList"].GetText(n,2))) ? Format("0x{:X}",value) : value
            list .= g["ConstList"].GetText(n) " := " value "`r`n"
        }
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

details_display(*) {
    Global Settings
    _main := Settings["gui"]
    g := Gui("+Resize +Owner" _main.hwnd, "Details Display")
    g.OnEvent("Escape",details_close)
    g.OnEvent("Close",details_close)
    g.OnEvent("Size",details_size)
    
    ctl := g.Add("Edit","vDisp w750 h750 ReadOnly")
    ctl.Value := _main["Details"].Value
    ctl.SetFont("s12","Consolas")
    PostMessage 0xB1, 0, 0, ctl.hwnd
    
    g.Add("Text","vTxtMsg y+10","Press ESC to exit.")
    ctl := g.Add("CheckBox","vMaxDispOpen","Maximize on open")
    ctl.OnEvent("Click",details_event)
    ctl.value := Settings["MaxDispOpen"]
    
    Settings["MaxDispOpen"] ? g.Show("Maximize") : g.Show()
    
    WinSetEnabled false, "ahk_id " _main.hwnd
}

details_event(ctl, info) {
    If (ctl.name = "MaxDispOpen")
        Settings["MaxDispOpen"] := true
}

details_close(_gui) {
    Global Settings
    _main := Settings["gui"]
    _gui.Destroy()
    
    WinSetEnabled true, "ahk_id " _main.hwnd
    WinActivate "ahk_id " _main.hwnd 
}

details_size(g, MinMax, w, h) {
    g["Disp"].Move(,,w-(g.MarginX * 2),h-(g.MarginY * 2)-20)
    g["TxtMsg"].Move(,h-(g.MarginY * 2)-7)
    
    g["MaxDispOpen"].GetPos(,,&_w)
    g["MaxDispOpen"].Move(w-(g.MarginX * 2)-_w,h-(g.MarginY * 2)-7)
}