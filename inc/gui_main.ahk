load_gui() {
    g := Gui.New("+OwnDialogs +Resize +MinSize1176x588","C++ Constants Scanner")
    g.OnEvent("close","close_gui"), g.OnEvent("size","size_gui")
    g.SetFont("s10","Consolas")
    
    g.Add("Text","xm y10","C++ Source File:")
    g.SetFont("s8","Verdana")
    ctl := g.Add("ComboBox","x+2 yp-2 w485 +Sort vApiPath",Settings["baseFiles"]) ; GuiControl
    ctl.OnEvent("change","gui_events")
    g.SetFont("s10","Consolas")
    
    g.Add("Button","x+0 yp-2 h25 w20 vAddBaseFile","+").OnEvent("click","gui_events")
    g.Add("Button","x+0 h25 w20 vRemBaseFile","-").OnEvent("click","gui_events")
    g.Add("Button","x+0 h25 vPickApiPath","...").OnEvent("click","gui_events")
    g.Add("Button","x+0 h25 vOtherDirs","Other Dirs").OnEvent("click","gui_events")
    g["ApiPath"].Text := (Settings.Has("ApiPath")) ? Settings["ApiPath"] : ""
    
    g.Add("Text","x+15 yp+4","Type:")
    ctl := g.Add("DropDownList","x+2 w85 yp-4 vArch",["Collect","Includes","x64","x86"])
    ctl.OnEvent("change","gui_events")
    If Settings.Has("Arch")
        ctl.Value := Settings["Arch"]
    Else ctl.Value := 2
    g.Add("Button","x+0 w50 h25 vScan","Scan").OnEvent("click","gui_events")
    g.Add("Button","x+15 h25 vIncludes","Includes").OnEvent("click","gui_events")
    
    g.Add("Button","x1073 yp h25 vSave","Save").OnEvent("click","gui_events")
    g.Add("Button","x+0 h25 vLoad","Load").OnEvent("click","gui_events")
    
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
    g.Add("Button","x+15 yp h23 vCopy","Copy List").OnEvent("click","gui_events")
    ctl := g.Add("DropDownList","x+0 w114 vCopyType",["var := value","var only"])
    ctl.Value := 1
    
    ctl := g.Add("ListView","xm y+5 w1151 h300 vConstList",["Name","Value","Expression","File"]) ; w1050
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
    
    msg := "MSVC or GCC compilers:  Enter the commands x64 and x86 compilers.  Include full path, " Chr(34) "quotes" Chr(34) ", and switches as desired.  Output file (-o) syntax is automatically handled.`r`n"
    ctl := g.Add("Text","y+10",msg)
    ctl.SetFont("s8","Verdana")
    g.Add("Text","Section y+0","x64 Compiler:")
    g.Add("Edit","x+2 w800 yp-4 vx64compiler",Settings["x64compiler"]).OnEvent("change","gui_events")
    g.Add("Text","xs y+10","x86 Compiler:")
    g.Add("Edit","x+2 w800 yp-4 vx86compiler",Settings["x86compiler"]).OnEvent("change","gui_events")
    
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
    g["ConstList"].Move(,,gW-25,gH-280)
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
    } Else If (n = "PickApiPath") {
        curFile := Settings.Has("ApiPath") ? Settings["ApiPath"] : ""
        selFile := FileSelect("1",,"Select C++ source directory:")
        If (selFile)
            Settings["ApiPath"] := selFile, g["ApiPath"].Text := selFile
    } Else If (n = "Scan") {
        res := MsgBox("Start scan now?`r`n`r`nThis will destroy the current list and scan the specified C++ Source Path.","Confirm Scan",4)
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
        
        root := g["ApiPath"].Text
        
        fexist := FileExist(root)
        If (!fexist) {
            Msgbox "Specify the path for the Win32 headers first."
            UnlockGui(true)
            return
        }
        
        arch := g["Arch"].Text
        If (arch != "Collect" And arch != "Includes")
            parser_by_compiler()
        Else If arch = "Collect"
            header_parser()
        Else If arch = "Includes"
            includes_report()
        
        If arch != "Includes" {
            ; fileList := listFiles()
            ; g["FileFilter"].Delete()
            ; g["FileFilter"].Add(fileList)
            ; g["FileFilter"].Opt("+Sort")
        } Else {
            UnlockGui(true)
        }
        
        ; relist_const()
        ; UnlockGui(true)
        ; g["Total"].Value := "Scan complete: " const_list.Count " constants recorded."
    } Else If (n = "AutoLoad")
        Settings["AutoLoad"] := ctl.Value
    Else If (n = "Load") {
        selFile := FileSelect("1",A_ScriptDir "\data\","Load Constant File:","Data file (*.data)")
        If (selFile)
            LoadFile(selFile)
    } Else If (n = "Save") {
        SaveFile()
    } Else If (n = "Copy") {
        If (filteredList.Count) {
            txt := "", ct := g["CopyType"].text
            For const, obj in filteredList {
                txt .= "`r`n" const
                If (ct = "var := value")
                    txt .= " := " obj["value"]
            }
            A_Clipboard := Trim(txt,"`r`n")
            
            msgbox "List copied to clipboard."
        }
    } Else If (n = "ApiPath") {
        Settings["ApiPath"] := g["ApiPath"].Text
    } Else If (n = "Arch") {
        Settings["Arch"] := g["Arch"].Value
    } Else If (n = "x64compiler")
        Settings["x64compiler"] := ctl.Value
    Else If (n = "x86compiler")
        Settings["x86compiler"] := ctl.Value
    Else If (n = "OtherDirs")
        extra_dirs()
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