; AHK v2

; great win32 api constant sources:
; https://raw.githubusercontent.com/GroggyOtter/GroggyRepo/master/Files/List%20-%20Win32%20Constants
; https://www.autoitscript.com/forum/files/file/16-win32-api-constants/

; Thanks to GroggyOtter on GitHub and to GaryFrost on autoIt
; forums for posting thier lists of Win32 API constants.

Global g:="" ; Gui obj
Global c:="" ; console obj
Global calcListCount := 1, calcListTotal := 0, calcErrorList := "", Mprog := "", errMsg := "" ; for progress bar during calculations
Global doReset:=false, timerDelay := -500, unkFilter := false, dupeFilter := false, critFilter := false
Global const_list:=Map(), dupe_list:=[], Settings:=Map(), IncludesList := Map(), filteredList := Map(), already_scanned := Map() ; , other_dirs := []
; Global test_discard:=Map()

If (FileExist("settings.json")) {
    sText := FileRead("settings.json")
    Settings := jxon_load(sText)
    
    (!Settings.Has("LastFile")) ? Settings["LastFile"] := "" : ""
    (!Settings.Has("AutoLoad")) ? Settings["AutoLoad"] := false : ""
    (!Settings.Has("baseFiles")) ? Settings["baseFiles"] := [] : ""
    (!Settings.Has("ApiPath")) ? Settings["ApiPath"] := "" : ""
    (!Settings.Has("x64compiler")) ? Settings["x64compiler"] := "" : ""
    (!Settings.Has("x86compiler")) ? Settings["x86compiler"] := "" : ""
}

load_gui()

If (Settings["AutoLoad"] And FileExist(Settings["LastFile"])) { ; load data if Auto-Load enabled
    UnlockGui(false)
    selFile := Settings["LastFile"]
    SplitPath selFile, fileName
    g["Total"].Value := "Loading data file.  Please Wait ..."
    fileData := FileRead(selFile)
    const_list := jxon_load(fileData)
    relist_const()
    UnlockGui(true)
    g["File"].Value := "File: " fileName
}

OnMessage(0x0100,"WM_KEYDOWN") ; WM_KEYDOWN

return

#INCLUDE libs\_JXON.ahk
#INCLUDE libs\TheArkive_CliSAK.ahk
#INCLUDE libs\TheArkive_Progress2.ahk

#INCLUDE libs\TheArkive_Debug.ahk

#INCLUDE inc\parser_compiler.ahk
#INCLUDE inc\win32_header_parser.ahk
#INCLUDE inc\extra_dirs.ahk



listFiles() {
    list_of_files := Map(), fileList := []
    
    For const, obj in const_list {
        file := obj["file"]
        list_of_files[file] := ""
    }
    
    For file in list_of_files
        fileList.Push(file)
    
    return fileList
}

LoadFile(selFile) {
    g["Details"].Value := "", g["Duplicates"].Value := ""
    UnlockGui(false)
    SplitPath selFile, fileName
    g["Total"].Value := "Loading data file.  Please Wait ..."
    fileData := FileRead(selFile)
    const_list := jxon_load(fileData)
    relist_const()
    g["File"].Value := "File: " fileName
    Settings["LastFile"] := selFile
    
    fileList := listFiles()
    g["FileFilter"].Delete()
    g["FileFilter"].Add(fileList)
    UnlockGui(true)
}

UnlockGui(bool) {
    g["ApiPath"].Enabled := bool, g["PickApiPath"].Enabled := bool, g["Scan"].Enabled := bool
    g["Save"].Enabled := bool, g["Load"].Enabled := bool, g["AutoLoad"].Enabled := bool
    g["NameFilter"].Enabled := bool, g["NameFilterClear"].Enabled := bool, g["NameBW"].Enabled := bool
    g["ValueFilter"].Enabled := bool, g["ValueFilterClear"].Enabled := bool, g["ValueEQ"].Enabled := bool
    g["ExpFilter"].Enabled := bool, g["ExpFilterClear"].Enabled := bool
    g["FileFilter"].Enabled := bool, g["FileFilterClear"].Enabled := bool
    g["Reset"].Enabled := bool
    ; g["Unk"].Enabled := bool, g["Dupe"].Enabled := bool, g["DupeIntOnly"].Enabled := bool
    g["ConstList"].Enabled := bool, g["Tabs"].Enabled := bool
    g["Copy"].Enabled := bool, g["CopyType"].Enabled := bool
}

load_gui() {
    g := Gui.New("-DPIScale +OwnDialogs","C++ Constants Scanner")
    g.OnEvent("close","close_gui")
    g.SetFont("s10","Consolas")
    
    g.Add("Text","xm y10","C++ Source File:")
    g.SetFont("s8","Verdana")
    ctl := g.Add("ComboBox","x+2 yp-2 w485 vApiPath",Settings["baseFiles"]) ; GuiControl
    ctl.OnEvent("change","gui_events")
    g.SetFont("s10","Consolas")
    
    g.Add("Button","x+0 yp-2 h25 w20 vAddBaseFile","+").OnEvent("click","gui_events")
    g.Add("Button","x+0 h25 w20 vRemBaseFile","-").OnEvent("click","gui_events")
    g.Add("Button","x+0 h25 vPickApiPath","...").OnEvent("click","gui_events")
    g.Add("Button","x+0 h25 vOtherDirs","Other Dirs").OnEvent("click","gui_events")
    g["ApiPath"].Text := (Settings.Has("ApiPath")) ? Settings["ApiPath"] : ""
    g.Add("Button","x+0 w50 h25 vScan","Scan").OnEvent("click","gui_events")
    g.Add("Text","x+5 yp+4","Type:")
    ctl := g.Add("DropDownList","x+2 w75 yp-4 vArch",["Collect","x64","x86"])
    ctl.Value := 2
    
    g.Add("Button","x973 yp h25 vSave","Save").OnEvent("click","gui_events")
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
    g.Add("Button","x+20 w85 hp vReset","Reset All").OnEvent("click","gui_events")
    
    g.Add("Button","x+0 yp h23 vCopy","Copy List").OnEvent("click","gui_events")
    ctl := g.Add("DropDownList","x+0 w114 vCopyType",["var := value","var only"])
    ctl.Value := 1
    
    g.Add("Text","xm y+5 Right w35","File:")
    g.Add("ComboBox","yp-4 x+2 w410 vFileFilter").OnEvent("change","gui_events")
    g.Add("Button","x+0 hp vFileFilterClear","X").OnEvent("click","gui_events")
    
    g.Add("Text","x509 yp+4","Types:")
    ctl := g.Add("Checkbox","x+5 vInteger","Integer"), ctl.OnEvent("click","gui_events")
    ctl.Value := 1
    ctl := g.Add("Checkbox","x+5 vFloat","Float"), ctl.OnEvent("click","gui_events")
    ctl.Value := 1
    ctl := g.Add("Checkbox","x+5 vString","String"), ctl.OnEvent("click","gui_events")
    ctl.Value := 1
    ctl := g.Add("Checkbox","x+5 vUnknown","Unknown"), ctl.OnEvent("click","gui_events")
    ctl.Value := 1
    ctl := g.Add("Checkbox","x+5 vMacro","Macro"), ctl.OnEvent("click","gui_events")
    ctl.Value := 1
    ctl := g.Add("Checkbox","x+5 vStruct","Struct"), ctl.OnEvent("click","gui_events")
    ctl.Value := 1
    ctl := g.Add("Checkbox","x+5 vDupe","Dupe"), ctl.OnEvent("click","gui_events")
    ctl.Value := 0
    
    ; ctl := g.Add("DropDownList","x+2 yp-4 w100 vFilterType",["All","Integer","Unknown","Dupe","Critical"])
    ; ctl.OnEvent("change","gui_events")
    ; ctl.Value := 1
    
    
    ; g.Add("Button","x+0 hp vUnk","Unknown").OnEvent("click","gui_events")
    ; g.Add("Button","x+0 hp vDupe","Dupe").OnEvent("click","gui_events")
    ; g.Add("CheckBox","x+5 yp hp vDupeIntOnly","Dupe int only").OnEvent("click","gui_events")
    
    
    
    ctl := g.Add("ListView","xm y+5 w1050 h300 vConstList",["Name","Value","Expression","File"])
    ctl.ModifyCol(1,435), ctl.ModifyCol(2,190), ctl.ModifyCol(3,195), ctl.ModifyCol(4,200)
    ctl.OnEvent("click","gui_events")
    
    g.Add("Text","xm y+5","Press CTRL+D to copy selected constant details.")
    g.Add("Text","x+370 w350 Right vFile","Data File:")
    
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
    g.Add("Text","Section y+10","x64 Compiler:")
    g.Add("Edit","x+2 w800 yp-4 vx64compiler",Settings["x64compiler"]).OnEvent("change","gui_events")
    g.Add("Text","xs y+10","x86 Compiler:")
    g.Add("Edit","x+2 w800 yp-4 vx86compiler",Settings["x86compiler"]).OnEvent("change","gui_events")
    
    tabCtl.UseTab()
    ctl := g.Add("Text","xm ys+70 w1050 vTotal","")
    
    If (!FileExist("const_list.txt"))
        ctl.Text := "No list of constants."
    Else
        ctl.Text := "Please Wait ..."
    
    g.Show("w1076")
    g["NameFilter"].Focus()
}

close_gui(*) {
    ; Settings["ApiPath"] := g["ApiPath"].Value
    sText := jxon_dump(Settings,4)
    If (FileExist("settings.json"))
        FileDelete "settings.json"
    FileAppend sText, "settings.json"
    ExitApp
}

relist_const(nFilter:="",vFilter:="",eFilter:="",fFilter:="") {
    filteredList := Map()
    ctl := g["ConstList"]
    ctl.Opt("-Redraw")
    ctl.Delete()
    tot := 0
    ; u := 0, i := 0, s := 0, m := 0, r := 0, d := 0, f := 0
    
    i:=0, f:=0, s:=0, u:=0, m:=0, st:=0, d:=0 ; i, f, s, u, m, st, d
    i_f := g["integer"].value, f_f := g["float"].Value, s_f := g["string"], u_f := g["unknown"].Value
    m_f := g["macro"].value, st_f := g["struct"].Value, d_f := g["dupe"].Value
    
    nFilter := !nFilter ? "*" : nFilter
    nFilter := StrReplace(nFilter,"*",".*")
    nFilter := g["NameBW"].Value ? "^" nFilter : nFilter
    
    vFilter := !vFilter ? "*" : vFilter
    vFilter := StrReplace(vFilter,"*",".*")
    vFilter := g["ValueEQ"].Value ? "^" vFilter "$" : vFilter
    
    eFilter := !eFilter ? "*" : eFilter
    oopsStr := "(){}[]-+^$&%?.,<>" Chr(34)
    Loop Parse oopsStr
    {
        ch := A_LoopField
        If (InStr(eFilter,ch))
            eFilter := StrReplace(eFilter,ch,"\" ch)
    }
    eFilter := StrReplace(eFilter,"*",".*")
    
    fFilter := !fFilter ? "*" : fFilter
    fFilter := StrReplace(fFilter,".","\.")
    fFilter := StrReplace(fFilter,"*",".*")
    
    prog := progress2.New(0,const_list.Count,"title:Loading...")
    ; If (unkFilter) {
        ; For const, obj in const_list {
            ; value := obj["value"], expr := obj["exp"], file := obj["file"]
            ; If (obj["type"] = "unknown") {
                ; dupe := (obj.Has("dupe")) ? true : false, d := dupe ? d+1 : d
                ; ctl.Add(,const,value,expr,file), tot++, u++, filteredList[const] := obj
            ; }
        ; }
        ; unkFilter := false
    ; } Else If (critFilter) {
        ; For const, obj in const_list {
            ; value := obj["value"], expr := obj["exp"], file := obj["file"], cType := obj["type"]
            ; If (obj.Has("critical")) {
                ; dupe := (obj.Has("dupe")) ? true : false
                
                ; If (cType = "integer")
                    ; ctl.Add(,const,value,expr,file), tot++, u++, d := dupe ? d+1 : d, filteredList[const] := obj
                ; If (!g["DupeIntOnly"].Value) {
                    ; If cType = "string"
                        ; ctl.Add(,const,value,expr,file), s++, tot++, filteredList[const] := obj
                    ; Else If cType = "unknown"
                        ; ctl.Add(,const,value,expr,file), u++, tot++, filteredList[const] := obj
                    ; Else If cType = "macro"
                        ; ctl.Add(,const,value,expr,file), m++, tot++, filteredList[const] := obj
                    ; Else If cType = "struct"
                        ; ctl.Add(,const,value,expr), st++, tot++
                ; }
            ; }
        ; }
        ; critFilter := false
    ; } Else If (dupeFilter) {
        ; For const, obj in const_list {
            ; prog.Update(A_Index)
            ; value := obj["value"], expr := obj["exp"], cType := obj["type"], file := obj["file"]
            ; If (obj.Has("dupe")) {
                ; d++
                ; If cType = "integer"
                    ; ctl.Add(,const,value,expr,file), i++, tot++, filteredList[const] := obj
                ; If (!g["DupeIntOnly"].Value) {
                    ; If cType = "string"
                        ; ctl.Add(,const,value,expr,file), s++, tot++, filteredList[const] := obj
                    ; Else If cType = "unknown"
                        ; ctl.Add(,const,value,expr,file), u++, tot++, filteredList[const] := obj
                    ; Else If cType = "macro"
                        ; ctl.Add(,const,value,expr,file), m++, tot++, filteredList[const] := obj
                    ; Else If cType = "struct"
                        ; ctl.Add(,const,value,expr), st++, tot++
                ; }
            ; }
        ; }
        ; dupeFilter := false
    ; } Else {
    For const, obj in const_list {
        prog.Update(A_Index)
        doList := false
        value := obj["value"], expr := obj["exp"], file := obj["file"], t := obj["type"]
        dupe := (obj.Has("dupe")) ? true : false
        
        If (RegExMatch(const,"i)" nFilter) And RegExMatch(value,"i)" vFilter) And RegExMatch(expr,"i)" eFilter) And RegExMatch(file,"i)" fFilter))
            doList := true
        
        If (doList) And ((t="integer" And i_f) Or (t="float" And f_f) Or (t="string" And s_f) Or (t="unknown" And u_f) Or (t="macro" And m_f) Or (t="struct" And st_f)) {
            If (d_f And dupe) Or (!d_f And !dupe) {
                filteredList[const] := obj
                ctl.Add(,const,value,expr,file), tot++ ; i, f, s, u, m, st, d
            
                i := ((obj["type"] = "integer") ? i+1 : i)
                f := ((obj["type"] = "float") ? f+1 : f)
                s := ((obj["type"] = "string") ? s+1 : s)
                u := ((obj["type"] = "unknown") ? u+1 : u)
                m := ((obj["type"] = "macro") ? m+1 : m)
               st := ((obj["type"] = "struct") ? st+1 : st)
                
                d := dupe ? d+1 : d
            }
        }
    }
    ; }
    prog.close()
    
    ctl.Opt("+Redraw")
    g["Total"].Text := "Total: " tot " / Unk: " u " / Known: " tot-u " / Int: " i " / Float: " f " / Str: " s " / Struct: " st " / Macro: " m " / Dupes: " d
    
    If (doReset) {
        doReset:=false
        g["NameFilter"].Focus()
    }
}

gui_events(ctl,info) { ; i, f, s, u, m, st, d
    n := ctl.Name
    If (n = "NameFilter") Or (n = "ValueFilter") Or (n = "ExpFilter") Or (n = "FileFilter") {
        SetTimer "relist_timer", timerDelay
    } Else If (n = "NameBW" And g["NameFilter"].Value) {
        SetTimer "relist_timer", timerDelay
    } Else If (n = "ValueEQ" And g["ValueFilter"].Value) {
        SetTimer "relist_timer", timerDelay
    } Else If (n="integer" Or n="float" Or n="string" Or n="unknown" Or n="macro" Or n="struct" Or n="dupe") {
        SetTimer "relist_timer", timerDelay
    } Else If (n = "Reset") {
        g["NameFilter"].Value := ""
        g["ValueFilter"].Value := ""
        g["ExpFilter"].Value := ""
        g["Details"].Value := ""
        g["Duplicates"].Value := ""
        g["CritDep"].Value := ""
        g["NameBW"].Value := 0
        g["ValueEQ"].Value := 0
        g["DupeIntOnly"].Value := 0
        g["FileFilter"].Text := ""
        g["Tabs"].Choose(1)
        
        g["Integer"].Value := 1
        g["Float"].Value := 1
        g["String"].Value := 1
        g["Unknown"].Value := 1
        g["Macro"].Value := 1
        g["Structure"].Value := 1
        g["Dupe"].Value := 0
        
        doReset := true
        SetTimer "relist_timer", timerDelay
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
                            . constName " := " constValue
                            . (IsInteger(constValue) ? "    (" Format("0x{:X}",constValue) ")`r`n" : "`r`n")
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
            For i, o in crit {
                const := i
                typ := o["type"]
                val := o["value"]
                dupe := (o.Has("dupe")) ? "Yes" : "No"
                critList .= const " / Type: " typ " / Value: " val " / Dupes: " dupe "`r`n`r`n"
            }
            g["CritDep"].Value := Trim(critList,"`r`n")
        }
    } Else If (n = "NameFilterClear") {
        g["NameFilter"].Value := ""
        g["NameBW"].Value := 0
        SetTimer "relist_timer", timerDelay
    } Else If (n = "ValueFilterClear") {
        g["ValueFilter"].Value := ""
        g["ValueEQ"].Value := 0
        SetTimer "relist_timer", timerDelay
    } Else If (n = "ExpFilterClear") {
        g["ExpFilter"].Value := ""
        SetTimer "relist_timer", timerDelay
    } Else If (n = "FileFilterClear") {
        g["FileFilter"].Text := ""
        SetTimer "relist_timer", timerDelay
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
        g["Details"].Value := ""
        g["Duplicates"].Value := ""
        g["CritDep"].Value := ""
        g["ExpFilter"].Value := ""
        g["FileFilter"].Text := ""
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
        
        If (g["Arch"].Text != "Collect")
            parser_by_compiler()
        Else
            win32_header_parser()
        
        fileList := listFiles()
        g["FileFilter"].Delete()
        g["FileFilter"].Add(fileList)
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
        lastFile := Settings["LastFile"]
        SplitPath lastFile, lastName
        saveFile := FileSelect("S 18",A_ScriptDir "\data\" lastName,"Save Data File:")
        If (saveFile) {
            UnlockGui(false)
            FileExist(saveFile) ? FileDelete(saveFile) : ""
            fileData := Jxon_dump(const_list)
            saveFile := (SubStr(saveFile,-5) != ".data") ? saveFile ".data" : saveFile
            FileAppend fileData, saveFile
            Settings["LastFile"] := saveFile
            MsgBox "Data file successfully saved."
            UnlockGui(true)
        }
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
    } Else If (n = "Critical") {
        critFilter := true
        g["NameFilter"].Value := ""
        g["NameBW"].Value := 0
        g["ValueFilter"].Value := ""
        g["ValueEQ"].Value := 0
        g["ExpFilter"].Value := ""
        g["Details"].Value := ""
        g["Duplicates"].Value := ""
        g["CritDep"].Value := ""
        g["FileFilter"].Text := ""
        SetTimer "relist_timer", timerDelay
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

buildDepnList(inMap) {
    newMap := Map()
    For d in inMap {
        Debug.Msg(d)
        
        curObj := const_list[d]
        If (curObj.Has("depn")) {
            
        }
        newMap[d] := ""
    }
    
    return
}

relist_timer() {
    relist_const(g["NameFilter"].value,g["ValueFilter"].value,g["ExpFilter"].Value,g["FileFilter"].Text)
}

WM_KEYDOWN(wParam, lParam, msg, hwnd) { ; up / down scrolling with keyboard
    If (g["ConstList"].hwnd = hwnd And (wParam = 38 Or wParam = 40)) {
        up_down_nav(wParam)
    }
}

up_down_nav(key) {
    ctl := g["ConstList"]
    rMax := ctl.GetCount()
    curRow := ctl.GetNext()
    nextRow := (key=40) ? curRow+1 : (key=38) ? curRow-1 : curRow
    nextRow := (nextRow > rMax) ? 0 : nextRow
    gui_events(ctl,nextRow)
}

eval(mathStr) { ; chr 65-90 or 97-122
    If IsInteger(mathStr)
        return Integer(mathStr)
    Else If mathStr = "" Or InStr(mathStr,Chr(34))
        return ""

    mathStr := StrReplace(StrReplace(mathStr,"< <","<<"),"> >",">>")
    mathStr := StrReplace(StrReplace(StrReplace(mathStr,"^"," -bxor "),"&"," -band "),"|"," -bor ")
    mathStr := StrReplace(StrReplace(StrReplace(mathStr,"<<"," -shl "),">>"," -shr "),"~"," -bnot ")

    return "(" mathStr ")"
}

#HotIf WinActive("ahk_id " g.hwnd)

^d::{ ; copy full deatils
    A_Clipboard := g["Details"].Value
}

^+d::{ ; copy selected constant name only
    n := g["ConstList"].GetNext()
    If (n) {
        t := g["ConstList"].GetText(n)
        A_Clipboard := t
    }
}

F2::{
    critList := ""
    For const, obj in const_list {
        If obj.has("critical") And obj["critical"].Count > 0 {
            critList .= const "`r`n"
            For crit, obj2 in obj["critical"] {
                critList .= "    - " crit "`r`n"
            }
            critList .= "`r`n"
        }
    }
    critList := Trim(critList)
    Msgbox "Critical constants.`r`nFull list is copied to clipboard.`r`n`r`n" (!critList ? "* None *" : critList)
    A_Clipboard := critList
}
