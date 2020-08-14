; AHK v2

; great win32 api constant sources:
; https://raw.githubusercontent.com/GroggyOtter/GroggyRepo/master/Files/List%20-%20Win32%20Constants
; https://www.autoitscript.com/forum/files/file/16-win32-api-constants/

; Thanks to GroggyOtter on GitHub and to GaryFrost on autoIt
; forums for posting thier lists of Win32 API constants.

Global g:="", c:="", prog:=""
Global doReset:=false, timerDelay := -500, unkFilter := false, dupeFilter := false, constCalcs := ""
Global const_list:=Map(), Settings:=Map(), IncludesList := Map(), curList := Map()

If (FileExist("settings.json")) {
    sText := FileRead("settings.json")
    Settings := jxon_load(sText)
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

#INCLUDE _JXON.ahk
#INCLUDE TheArkive_CliSAK.ahk
#INCLUDE TheArkive_Progress2.ahk
#INCLUDE win32_header_parser.ahk

#INCLUDE TheArkive_Debug.ahk

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
    g["Reset"].Enabled := bool, g["Unk"].Enabled := bool, g["Dupe"].Enabled := bool, g["DupeIntOnly"].Enabled := bool
    g["ConstList"].Enabled := bool, g["Tabs"].Enabled := bool
    g["Copy"].Enabled := bool, g["CopyType"].Enabled := bool
}

load_gui() {
    g := Gui.New("-DPIScale +OwnDialogs","C++ Constants Scanner")
    g.OnEvent("close","close_gui")
    g.SetFont("s10","Consolas")
    
    g.Add("Text","xm y10","C++ Source Path:")
    g.Add("Edit","x+2 yp-4 w585 vApiPath","")
    g.Add("Button","x+0 h25 vPickApiPath","...").OnEvent("click","gui_events")
    g["ApiPath"].Value := (Settings.Has("ApiPath")) ? Settings["ApiPath"] : ""
    g.Add("Button","x+0 w50 h25 vScan","Scan").OnEvent("click","gui_events")
    
    g.Add("Button","x+0 h25 vSave","Save").OnEvent("click","gui_events")
    g.Add("Button","x+0 h25 vLoad","Load").OnEvent("click","gui_events")
    ctl := g.Add("CheckBox","x+5 yp+4 vAutoLoad","Auto-Load on Start")
    ctl.OnEvent("click","gui_events")
    ctl.Value := Settings["AutoLoad"]
    
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
    
    g.Add("Text","xm y+5 Right w35","File:")
    g.Add("ComboBox","yp-4 x+2 w450 vFileFilter").OnEvent("change","gui_events")
    g.Add("Button","x+0 hp vFileFilterClear","X").OnEvent("click","gui_events")
    
    g.Add("Button","Section x+54 w50 hp vReset","Reset").OnEvent("click","gui_events")
    g.Add("Button","x+0 hp vUnk","Unknown").OnEvent("click","gui_events")
    g.Add("Button","x+0 hp vDupe","Dupe").OnEvent("click","gui_events")
    g.Add("CheckBox","x+5 yp hp vDupeIntOnly","Dupe int only").OnEvent("click","gui_events")
    
    g.Add("Button","x+10 h23 vCopy","Copy List").OnEvent("click","gui_events")
    ctl := g.Add("DropDownList","x+0 w114 vCopyType",["var := value","var only"])
    ctl.Value := 1
    
    ctl := g.Add("ListView","xm y+5 w1050 h300 vConstList",["Name","Value","Expression","File"])
    ctl.ModifyCol(1,435), ctl.ModifyCol(2,190), ctl.ModifyCol(3,195), ctl.ModifyCol(4,200)
    ctl.OnEvent("click","gui_events")
    
    g.Add("Text","xm y+5","Press CTRL+D to copy selected constant details.")
    g.Add("Text","x+370 w350 Right vFile","Data File:")
    
    ctl := g.Add("Tab3","xm y+5 w1050 h142 vTabs",["Details","Duplicates"])
    
    ctl.UseTab("Details")
    g.Add("Edit","xm y+5 w1050 r7 vDetails ReadOnly","")
    
    ctl.UseTab("Duplicates")
    g.Add("Edit","xm y+5 w1050 r7 vDuplicates ReadOnly","")
    
    ctl.UseTab()
    ctl := g.Add("Text","xm y+5 w1050 vTotal","")
    
    If (!FileExist("const_list.txt"))
        ctl.Text := "No list of constants."
    Else
        ctl.Text := "Please Wait ..."
    
    g.Show()
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
    curList := Map()
    ctl := g["ConstList"]
    ctl.Opt("-Redraw")
    ctl.Delete()
    t := 0, u := 0, i := 0, s := 0, m := 0, r := 0, d := 0, f := 0
    
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
    If (unkFilter) {
        For const, obj in const_list {
            value := obj["value"], expr := obj["exp"], file := obj["file"]
            If (obj["type"] = "unknown") {
                dupe := (obj.Has("dupe")) ? true : false
                d := dupe ? d+1 : d
                ctl.Add(,const,value,expr,file), t++, u++, curList[const] := obj
            }
        }
        unkFilter := false
    } Else If (dupeFilter) {
        For const, obj in const_list {
            prog.Update(A_Index)
            value := obj["value"], expr := obj["exp"], cType := obj["type"], file := obj["file"]
            If (obj.Has("dupe")) {
                d++
                If cType = "integer" ; {
                    ctl.Add(,const,value,expr,file), i++, t++, curList[const] := obj
                If (!g["DupeIntOnly"].Value) {
                    If cType = "string"
                        ctl.Add(,const,value,expr,file), s++, t++, curList[const] := obj
                    Else If cType = "unknown"
                        ctl.Add(,const,value,expr,file), u++, t++, curList[const] := obj
                    Else If cType = "macro"
                        ctl.Add(,const,value,expr,file), m++, t++, curList[const] := obj
                    ; Else If cType = "struct"
                        ; ctl.Add(,const,value,expr), r++, t++
                }
            }
        }
        dupeFilter := false
    } Else {
        For const, obj in const_list {
            prog.Update(A_Index)
            doList := false
            value := obj["value"], expr := obj["exp"], file := obj["file"]
            dupe := (obj.Has("dupe")) ? true : false
            
            If (RegExMatch(const,"i)" nFilter) And RegExMatch(value,"i)" vFilter) And RegExMatch(expr,"i)" eFilter) And RegExMatch(file,"i)" fFilter))
                doList := true
            
            If (doList) {
                curList[const] := obj
                ctl.Add(,const,value,expr,file), t++
                u := ((obj["type"] = "unknown") ? u+1 : u)
                i := ((obj["type"] = "integer") ? i+1 : i)
                s := ((obj["type"] = "string") ? s+1 : s)
                m := ((obj["type"] = "macro") ? m+1 : m)
                f := ((obj["type"] = "float") ? f+1 : f)
                
                d := dupe ? d+1 : d
            }
        }
    }
    prog.close()
    
    ctl.Opt("+Redraw")
    g["Total"].Text := "Total: " t " / Unk: " u " / Known: " t-u " / Int: " i " / Float: " f " / Str: " s " / Macros: " m " / Dupes: " d
    
    If (doReset) {
        doReset:=false
        g["NameFilter"].Focus()
    }
}

gui_events(ctl,info) {
    If (ctl.Name = "NameFilter") Or (ctl.Name = "ValueFilter") Or (ctl.Name = "NameBW") Or (ctl.Name = "ValueEQ") Or (ctl.Name = "ExpFilter") Or (ctl.Name = "FileFilter") {
        SetTimer "relist_timer", timerDelay
    } Else If (ctl.Name = "Reset") {
        g["NameFilter"].Value := ""
        g["ValueFilter"].Value := ""
        g["ExpFilter"].Value := ""
        g["Details"].Value := ""
        g["Duplicates"].Value := ""
        g["NameBW"].Value := 0
        g["ValueEQ"].Value := 0
        g["DupeIntOnly"].Value := 0
        g["FileFilter"].Text := ""
        g["Tabs"].Choose(1)
        
        doReset := true
        SetTimer "relist_timer", timerDelay
    } Else If (ctl.Name = "ConstList") {
        If (!info)
            return
        
        constName := ctl.GetText(info)
        constValue := const_list[constName]["value"]
        constType := const_list[constName]["type"]
        constExp := const_list[constName]["exp"]
        constLine := const_list[constName]["line"]
        constFile := const_list[constName]["file"]
        dupes := const_list[constName].Has("dupe")
        
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
    } Else If (ctl.Name = "Unk") {
        unkFilter := true
        g["NameFilter"].Value := ""
        g["NameBW"].Value := 0
        g["ValueFilter"].Value := ""
        g["ValueEQ"].Value := 0
        g["ExpFilter"].Value := ""
        g["Details"].Value := ""
        g["Duplicates"].Value := ""
        g["FileFilter"].Text := ""
        SetTimer "relist_timer", timerDelay
    } Else If (ctl.Name = "Dupe") {
        dupeFilter := true
        g["NameFilter"].Value := ""
        g["NameBW"].Value := 0
        g["ValueFilter"].Value := ""
        g["ValueEQ"].Value := 0
        g["ExpFilter"].Value := ""
        g["Details"].Value := ""
        g["Duplicates"].Value := ""
        g["FileFilter"].Text := ""
        SetTimer "relist_timer", timerDelay
    } Else If (ctl.Name = "NameFilterClear") {
        g["NameFilter"].Value := ""
        g["NameBW"].Value := 0
        SetTimer "relist_timer", timerDelay
    } Else If (ctl.Name = "ValueFilterClear") {
        g["ValueFilter"].Value := ""
        g["ValueEQ"].Value := 0
        SetTimer "relist_timer", timerDelay
    } Else If (ctl.Name = "ExpFilterClear") {
        g["ExpFilter"].Value := ""
        SetTimer "relist_timer", timerDelay
    } Else If (ctl.Name = "FileFilterClear") {
        g["FileFilter"].Text := ""
        SetTimer "relist_timer", timerDelay
    } Else If (ctl.Name = "PickApiPath") {
        curFile := Settings.Has("ApiPath") ? Settings["ApiPath"] : ""
        selFile := FileSelect("D 2",,"Select C++ source directory:")
        If (selFile)
            Settings["ApiPath"] := selFile, g["ApiPath"].Value := selFile
    } Else If (ctl.Name = "Scan") {
        res := MsgBox("Start scan now?`r`n`r`nThis will destroy the current list and scan the specified C++ Source Path.","Confirm Scan",4)
        If (res = "no")
            return
        
        g["NameFilter"].Value := ""
        g["NameBW"].Value := 0
        g["ValueFilter"].Value := ""
        g["ValueEQ"].Value := 0
        g["Details"].Value := ""
        g["Duplicates"].Value := ""
        g["ExpFilter"].Value := ""
        g["FileFilter"].Text := ""
        g["Tabs"].Choose(1)
        UnlockGui(false)
        
        g["ConstList"].Delete()
        g["Total"].Text := "Scanning Win32 API files..."
        
        win32_header_parser()
        fileList := listFiles()
        g["FileFilter"].Delete()
        g["FileFilter"].Add(fileList)
        relist_const()
        UnlockGui(true)
    } Else If (ctl.Name = "AutoLoad")
        Settings["AutoLoad"] := ctl.Value
    Else If (ctl.Name = "Load") {
        selFile := FileSelect("1",A_ScriptDir "\data\","Load Constant File:","Data file (*.data)")
        If (selFile)
            LoadFile(selFile)
    } Else If (ctl.Name = "Save") {
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
    } Else If (ctl.Name = "Copy") {
        If (curList.Count) {
            txt := "", ct := g["CopyType"].text
            For const, obj in curList {
                txt .= "`r`n" const
                If (ct = "var := value")
                    txt .= " := " obj["value"]
            }
            A_Clipboard := Trim(txt,"`r`n")
            
            msgbox "List copied to clipboard."
        }
    }
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
    If mathStr = "" Or InStr(mathStr,Chr(34)) Or SubStr(mathStr,1,1) = "-"
        return ""
    Loop Parse mathStr
    {
        c := Ord(A_LoopField)
        If (c >= 65 And c <= 90) Or (c >= 97 And c <= 122)
            return "" ; actual string evaluated MUST be purely numerical with operators
    }
    mathStr := StrReplace(StrReplace(mathStr,"< <","<<"),"> >",">>")
    mathStr := StrReplace(StrReplace(StrReplace(mathStr,"^"," -bxor "),"&"," -band "),"|"," -bor ")
    mathStr := StrReplace(StrReplace(StrReplace(mathStr,"<<"," -shl "),">>"," -shr "),"~"," -bnot ")
    c := cli.new("powershell " mathStr), output := c.stdout, c := ""
    
    return Trim(output,"`r`n`t ")
}

#HotIf WinActive("ahk_id " g.hwnd)

^d::{
    A_Clipboard := g["Details"].Value
}

^+d::{
    n := g["ConstList"].GetNext()
    If (n) {
        t := g["ConstList"].GetText(n)
        A_Clipboard := t
    }
}