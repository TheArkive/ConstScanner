load_gui() {
    g := Gui.New("+OwnDialogs +Resize +MinSize1076x488","C++ Constants Scanner")
    g.OnEvent("close","close_gui"), g.OnEvent("size","size_gui")
    g.SetFont("s10","Consolas")
    
    load_menubar(g)
    
    ; g.Add("Text","xm y10","C++ Source File:")
    ; g.SetFont("s8","Verdana")
    ; ctl := g.Add("ComboBox","x+2 yp-2 w485 +Sort vApiPath",Settings["baseFiles"]) ; GuiControl
    ; ctl.OnEvent("change","gui_events")
    g.SetFont("s10","Consolas")
    
    ; g.Add("Button","x+0 yp-2 h25 w20 vAddBaseFile","+").OnEvent("click","gui_events")
    ; g.Add("Button","x+0 h25 w20 vRemBaseFile","-").OnEvent("click","gui_events")
    ; g.Add("Button","x+0 h25 vPickApiPath","...").OnEvent("click","gui_events")
    ; g.Add("Button","x+0 h25 vOtherDirs","Other Dirs").OnEvent("click","gui_events")
    ; g["ApiPath"].Text := (Settings.Has("ApiPath")) ? Settings["ApiPath"] : ""
    
    ; g.Add("Text","x+15 yp+4","Type:")
    ; ctl := g.Add("DropDownList","x+2 w85 yp-4 vArch",["Collect","Includes","x64","x86"])
    ; ctl.OnEvent("change","gui_events")
    ; If Settings.Has("Arch")
        ; ctl.Value := Settings["Arch"]
    ; Else ctl.Value := 2
    ; g.Add("Button","x+0 w50 h25 vScan","Scan").OnEvent("click","gui_events")
    
    
    ; g.Add("Button","x1073 yp h25 vSave","Save").OnEvent("click","gui_events")
    ; g.Add("Button","x+0 h25 vLoad","Load").OnEvent("click","gui_events")
    
    g.Add("Text","xm y+10","Name:")
    g.Add("Edit","Section yp-4 x+2 w100 vNameFilter","").OnEvent("change","gui_events")
    g.Add("Button","x+0 hp vNameFilterClear","X").OnEvent("click","gui_events")
    g.Add("CheckBox","x+4 yp+4 vNameBW","Begins with").OnEvent("click","gui_events")
    
    g.Add("Text","x+20 ys+4","Value:")
    g.Add("Edit","Section yp-4 x+2 w100 vValueFilter","").OnEvent("change","gui_events")
    g.Add("Button","x+0 hp vValueFilterClear","X").OnEvent("click","gui_events")
    g.Add("CheckBox","x+4 yp+4 vValueEQ","Exact").OnEvent("click","gui_events")
    
    g.Add("Text","x+20 ys+4","Expression:")
    g.Add("Edit","Section yp-4 x+2 w100 vExpFilter","").OnEvent("change","gui_events")
    g.Add("Button","x+0 hp vExpFilterClear","X").OnEvent("click","gui_events")
    
    g.Add("Button","x+15 hp vMoreFilters","More Filters").OnEvent("click","gui_events")
    g.Add("Button","x+0 w85 hp vReset","Reset All").OnEvent("click","gui_events")
    g.Add("Button","x+15 h25 vIncludes","Includes").OnEvent("click","gui_events")
    ; g.Add("Button","x+15 yp h23 vCopy","Copy List").OnEvent("click","gui_events")
    ; ctl := g.Add("DropDownList","x+0 w114 vCopyType",["var := value","var only"])
    ; ctl.Value := 1
    
    ctl := g.Add("ListView","xm y+5 w1051 h300 vConstList",["Name","Value","Expression","File"]) ; w1050
    ctl.ModifyCol(1,435), ctl.ModifyCol(2,190), ctl.ModifyCol(3,195), ctl.ModifyCol(4,200)
    ctl.OnEvent("click","gui_events")
    
    g.Add("Text","xm y+5 vHelper","Press CTRL+D to copy selected constant details.")
    g.Add("Text","x500 yp w560 Right vFile","Data File:")
    
    tabCtl := g.Add("Tab3","Section xm y+5 w1050 h142 vTabs",["Details","Duplicates","Critical Dependencies","Settings"])
    
    tabCtl.UseTab("Details")
    g.Add("Edit","xm y+5 w1050 r7 vDetails ReadOnly","")
    
    tabCtl.UseTab("Duplicates")
    g.Add("Edit","xm y+5 w1050 r7 vDuplicates ReadOnly","")
    
    tabCtl.UseTab("Critical Dependencies")
    g.Add("Edit","xm y+5 w1050 r7 vCritDep ReadOnly","")
    
    tabCtl.UseTab("Settings")
    ctl := g.Add("CheckBox","vAutoLoad","Auto-Load most recent file on start")
    ctl.OnEvent("click","gui_events")
    ctl.Value := Settings["AutoLoad"]
    
    ctl := g.Add("Text","y+10 Section","MSVC compiler environment command.")
    ctl.SetFont("s8","Verdana")
    g.Add("Text","y+10","x64 Compiler:")
    g.Add("Edit","x+2 w300 yp-4 vx64_MSVC",Settings["x64_MSVC"]).OnEvent("change","gui_events")
    g.Add("Text","xs y+10","x86 Compiler:")
    g.Add("Edit","x+2 w300 yp-4 vx86_MSVC",Settings["x86_MSVC"]).OnEvent("change","gui_events")
    
    ctl := g.Add("Text","ys xs+500 Section","GCC compiler environment command.")
    ctl.SetFont("s8","Verdana")
    g.Add("Text","y+10","x64 Compiler:")
    g.Add("Edit","x+2 w300 yp-4 vx64_GCC",Settings["x64_GCC"]).OnEvent("change","gui_events")
    g.Add("Text","xs y+10","x86 Compiler:")
    g.Add("Edit","x+2 w300 yp-4 vx86_GCC",Settings["x86_GCC"]).OnEvent("change","gui_events")
    
    tabCtl.UseTab()
    ctl := g.Add("Text","xm ys+70 w1050 vTotal","")
    
    If (!FileExist("const_list.txt"))
        ctl.Text := "No list of constants."
    Else
        ctl.Text := "Please Wait ..."
    
    g.Show("")
    g["NameFilter"].Focus()
}

size_gui(o, MinMax, gW, gH) {
    g["ConstList"].Move(,,gW-25,gH-240)
    g["Tabs"].Move(,gH-170,gW-25)
    g["Tabs"].ReDraw()
    g["Details"].Move(,,gW-25)
    g["Duplicates"].Move(,,gW-25)
    g["CritDep"].Move(,,gW-25)
    
    g["Helper"].Move(,gH-190)
    g["File"].Move(,gH-190,gW-515)
    g["File"].ReDraw()
    g["Total"].Move(,gH-20,gW-25)
}

close_gui(*) {
    Settings["ApiPath"] := ""
    sText := jxon_dump(Settings,4)
    If (FileExist("settings.json"))
        FileDelete "settings.json"
    FileAppend sText, "settings.json"
    ExitApp
}

gui_events(ctl,info) { ; i, f, s, u, m, st, d ; filters
    n := ctl.Name
    If (n = "Includes") {
        incl_report()
    } Else If (n = "MoreFilters") {
        load_filters()
    } Else If (n="integer" Or n="float" Or n="string" Or n="unknown" Or n="other" Or n="expr" Or n="dupe") {
        Settings["Check" n] := ctl.Value
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
        Settings["CheckUnknown"] := 1
        Settings["CheckOther"] := 1
        Settings["CheckExpr"] := 1
        Settings["CheckDupe"] := 0
        
        doReset := true
        relist_const()
    } Else If (n = "ConstList") {
        If (!info)
            return
        
        constName := ctl.GetText(info)
        constValue := const_list[constName]["value"]
        constType := const_list[constName]["type"]
        constExp := const_list[constName]["exp"]
        constLine := const_list[constName]["line"]
        constFile := const_list[constName]["file"]
        dupes := const_list[constName].Has("dupe")
        critDep := const_list[constName].Has("critical")
        
        g["Details"].Value := (dupes ? "Duplicate Values Exist`r`n`r`n" : "")
                            . constName " := " constValue . (IsInteger(constValue) ? "    (" Format("0x{:X}",constValue) ")`r`n" : "`r`n")
                            . (const_list[constName].Has("subs") ? const_list[constName]["subs"] : "") "`r`n"
                            . "`r`nValue: " constValue "`r`nExpr:  " constExp "`r`nType:  " constType "    /    File:  " constFile "    /    Line:  " constLine
        
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
                ; dupe := (const_list[const].Has("dupe")) ? "Yes" : "No" ; this is redundant
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
        g["FileFilter"].Text := ""
    ; } Else If (n = "PickApiPath") {
        ; curFile := Settings.Has("ApiPath") ? Settings["ApiPath"] : ""
        ; selFile := FileSelect("1",,"Select C++ source directory:")
        ; If (selFile)
            ; Settings["ApiPath"] := selFile, g["ApiPath"].Text := selFile
    ; } Else If (n = "Scan") {
        ; res := MsgBox("Start scan now?`r`n`r`nThis will destroy the current list and scan the specified C++ Source Path.","Confirm Scan",4)
        ; If (res = "no")
            ; return
        
        ; g["NameFilter"].Value := ""
        ; g["NameBW"].Value := 0
        ; g["ValueFilter"].Value := ""
        ; g["ValueEQ"].Value := 0
        ; g["ExpFilter"].Value := ""
        ; Settings["FileFilter"] := ""
        
        ; g["Details"].Value := ""
        ; g["Duplicates"].Value := ""
        ; g["CritDep"].Value := ""
        
        ; g["Tabs"].Choose(1)
        ; UnlockGui(false)
        
        ; g["ConstList"].Delete()
        ; g["Total"].Text := "Scanning header files..."
        
        ; root := g["ApiPath"].Text
        
        ; fexist := FileExist(root)
        ; If (!fexist) {
            ; Msgbox "Specify the path for the Win32 headers first."
            ; UnlockGui(true)
            ; return
        ; }
        
        ; arch := g["Arch"].Text
        ; If (arch != "Collect" And arch != "Includes")
            ; parser_by_compiler()
        ; Else If arch = "Collect"
            ; header_parser()
        ; Else If arch = "Includes"
            ; includes_report()
        
        ; If (arch = "Includes")
            ; UnlockGui(true)
        
        ; relist_const()
        ; UnlockGui(true)
        ; g["Total"].Value := "Scan complete: " const_list.Count " constants recorded."
    } Else If (n = "AutoLoad")
        Settings["AutoLoad"] := ctl.Value
    ; Else If (n = "Load") {
        ; selFile := FileSelect("1",A_ScriptDir "\data\","Load Constant File:","Data file (*.data)")
        ; If (selFile)
            ; LoadFile(selFile)
    ; } Else If (n = "Save") {
        ; SaveFile()
    ; } Else If (n = "Copy") {
        ; If (filteredList.Count) {
            ; txt := "", ct := g["CopyType"].text
            ; For const, obj in filteredList {
                ; txt .= "`r`n" const
                ; If (ct = "var := value")
                    ; txt .= " := " obj["value"]
            ; }
            ; A_Clipboard := Trim(txt,"`r`n")
            
            ; msgbox "List copied to clipboard."
        ; }
    ; } Else If (n = "ApiPath") {
        ; Settings["ApiPath"] := g["ApiPath"].Text
    ; } Else If (n = "Arch") {
        ; Settings["Arch"] := g["Arch"].Value
    ; } Else If InStr(n,"_MSVC") Or InStr(n,"_GCC")
        ; Settings[ctl.Name] := ctl.Value
    ; Else If (n = "OtherDirs")
        ; extra_dirs()
    Else If (n = "AddBaseFile") {
        If (!Settings.Has("baseFiles"))
            Settings["baseFiles"] := []
        curFile := g["ApiPath"].Text
        If (!curFile)
            return
        curList := Settings["baseFiles"], success := true
        For i, file in curList {
            If (file = curFile) {
                success := false
                Break
            }
        }
        
        If (success) {
            Settings["baseFiles"].Push(curFile)
            g["ApiPath"].Delete()
            g["ApiPath"].Add(Settings["baseFiles"])
            g["ApiPath"].Text := curFile
        }
    } Else If (n = "RemBaseFile") {
        curFile := g["ApiPath"].Text
        curBase := Settings["baseFiles"], newList := []
        For i, file in curBase {
            If (file != curFile)
                newList.Push(file)
        }
        g["ApiPath"].Delete()
        g["ApiPath"].Add(newList)
        Settings["baseFiles"] := newList
        g["ApiPath"].Text := curFile
    }
}

recents_menu() {
    mb_recent := menu.new(), recent_handle := mb_recent.handle
    mb_recent.Add("Clear &Recents","menu_events")
    mb_recent.Add()
    For file in Settings["baseFiles"]
        mb_recent.Add(file,"menu_events")
    
    return mb_recent
}

load_menubar(_gui) {
    mb_scan := menu.new()
    mb_scan.Add("&Scan Now","menu_events")
    mb_scan.Add()
    mb_scan.Add("Select Scan Type:","menu_events")
    mb_scan.Disable("Select Scan Type:")
    mb_scan.Add("C&ollect","menu_events","+Radio")
    mb_scan.Add("&Includes Only","menu_events","+Radio")
    mb_scan.Add("x64 &MSVC","menu_events","+Radio")
    mb_scan.Add("x86 M&SVC","menu_events","+Radio")
    mb_scan.Add("x64 &GCC","menu_events","+Radio")
    mb_scan.Add("x86 G&CC","menu_events","+Radio")
    mb_scan.Check(Settings["ScanType"])
    
    mb_src := menu.new()
    mb_src.Add("&Select C++ Source Header","menu_events")
    mb_src.Add("&Recent",recents_menu())
    mb_src.Add("&Other Files/Folders","menu_events")
    ; mb_src.Disable("&Other Files/Folders")
    mb_src.Add()
    mb_src.Add("S&canning",mb_scan)
    ;============================
    ; mb_src.Add("S&c","menu_events")
    ; mb_src.Add()
    ; mb_src.Add("Scan Type","menu_events")
    ; mb_src.Disable("Scan Type")
    ; mb_src.Add("Collect","menu_events","+Radio")
    ; mb_src.Add("Includes Only","menu_events","+Radio")
    ; mb_src.Add("x64 MSVC","menu_events","+Radio")
    ; mb_src.Add("x86 MSVC","menu_events","+Radio")
    ; mb_src.Add("x64 GCC","menu_events","+Radio")
    ; mb_src.Add("x86 GCC","menu_events","+Radio")
    ; mb_src.Check(Settings["ScanType"])
    
    mb_data := menu.new()
    mb_data.Add("&Load Constants","menu_events")
    mb_data.Add("&Save Constants","menu_events")
    
    mb_copy := menu.new()
    mb_copy.Add("&Copy Constants","menu_events")
    mb_copy.Add()
    mb_copy.Add("&var := value","menu_events","+Radio")
    mb_copy.Add("var &only","menu_events","+Radio")
    
    var_cpy := (Settings.Has("var_copy")) ? Settings["var_copy"] : "&var := value"
    mb_copy.Check(var_cpy)
    
    mb := menubar.new()
    mb.Add("&Source", mb_src)
    mb.Add("&Data", mb_data)
    mb.Add("&List", mb_copy)
    
    _gui.menubar := mb
    
}

menu_events(ItemName, ItemPos, _o) {
    n := ItemName
    If (n = "&Select C++ Source Header") {
        select_header(_o,n)
    } Else If (n = "C&ollect") Or (n = "&Includes Only") Or InStr(n,"x86") Or InStr(n,"x64") {
        Static scan_type := ["C&ollect","&Includes Only","x64 &MSVC","x86 M&SVC","x64 &GCC","x86 G&CC"]
        For typ in scan_type
            _o.Uncheck(typ)
        _o.Check(n)
        Settings["ScanType"] := n
    } Else If (n = "&Other Files/Folders") {
        If Settings["ApiPath"]
            extra_dirs()
    } Else If (n = "&Scan Now") {
        scan_now()
    } Else If (n = "&Load Constants") {
        LoadFile()
    } Else If (n = "&Save Constants") {
        SaveFile()
    } Else If (n = "&Copy Constants") {
        txt := "", ct := Settings["var_copy"]
        For const, obj in filteredList {
            txt .= "`r`n" const
            If (ct = "var := value")
                txt .= " := " obj["value"]
        }
        A_Clipboard := Trim(txt,"`r`n")
        
        msgbox "List copied to clipboard."
    } Else If (n = "&var := value") Or (n = "var &only") {
        Settings["var_copy"] := n
        _o.Uncheck("&var := value"), _o.Uncheck("var &only")
        _o.Check(n)
    } Else If (n = "Clear &Recents") {
        Loop Settings["baseFiles"].Length {
            num := 2 + Settings["baseFiles"].Length - (A_Index - 1)
            _o.Delete(num "&")
        }
        Settings["baseFiles"] := []
    } Else If (_o.Handle = recent_handle) {
        select_header(_o,n)
    }
}

scan_now() {
    If !Settings["ApiPath"] {
        Msgbox "Select a C++ Source Header file first."
        return
    }
    
    res := MsgBox("Start scan now?`r`n`r`nThis will destroy the current list and scan the specified C++ Source Header and includes.","Confirm Scan",4)
    If (res = "no")
        return
    
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
    
    root := Settings["ApiPath"]
    
    fexist := FileExist(root)
    If (!fexist) {
        Msgbox "Specify the path for the Win32 headers first."
        UnlockGui(true)
        return
    }
    
    ScanType := StrReplace(Settings["ScanType"],"&","")
    
    If (ScanType = "Collect")
        header_parser()
    Else If (ScanType = "Includes Only")
        includes_report()
    Else if InStr(ScanType,"x86") Or InStr(ScanType,"x64") {
        
    }
    
    If (ScanType = "Includes")
        UnlockGui(true)
    
    ; relist_const()
    ; UnlockGui(true)
    ; g["Total"].Value := "Scan complete: " const_list.Count " constants recorded."
}

select_header(_o,n) {
    If (n = "&Select C++ Source Header")
        selFile := FileSelect("1",,"Select C++ source header file:")
    Else selFile := n ; use recent
    
    If !selFile ; user cancels
        return
    
    SplitPath selFile,,,ext
    If (selFile) And (ext="h") {
        Settings["ApiPath"] := selFile
        If !dupe_item_check(Settings["baseFiles"],selFile)
            Settings["baseFiles"].Push(selFile)
        _o.Add("2&",recents_menu())
        g.title := "C++ Constants Scanner - " selFile
    } Else If (ext!="h")
        MsgBox "You must select a header file."
}