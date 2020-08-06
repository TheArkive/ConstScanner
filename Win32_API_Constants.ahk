; AHK v2

; great win32 api constant sources:
; https://raw.githubusercontent.com/GroggyOtter/GroggyRepo/master/Files/List%20-%20Win32%20Constants
; https://www.autoitscript.com/forum/files/file/16-win32-api-constants/

; Thanks to GroggyOtter on GitHub and to GaryFrost on autoIt
; forums for posting thier lists of Win32 API constants.

Global g:="", doReset:=false, timerDelay := -500, unkFilter := false, dupeFilter := false
Global const_list:=Map(), Settings:=Map(), IncludesList := Map()

If (FileExist("settings.json")) {
    sText := FileRead("settings.json")
    Settings := jxon_load(sText)
}

load_gui()

; === use only one option =============================================================
; === option 1 ========================================================================
; scan_const() ; do this to re-calc values
; =====================================================================================
; === option 2 ========================================================================
If (FileExist("const_list.txt")) {
    saved_const := FileRead("const_list.txt") ; use these 2 lines to just load saved values
    const_list := jxon_load(saved_const)
    relist_const()
}
; =====================================================================================

OnMessage(0x0100,"WM_KEYDOWN") ; WM_KEYDOWN

return

#INCLUDE _JXON.ahk
#INCLUDE TheArkive_CliSAK.ahk
#INCLUDE TheArkive_Progress2.ahk
#INCLUDE win32_header_parser.ahk

#INCLUDE TheArkive_Debug.ahk

load_gui() {
    g := Gui.New("","Win32 API Constants")
    g.OnEvent("close","close_gui")
    g.SetFont("s10","Consolas")
    
    g.Add("Text","xm y10","Win32 Header Path:")
    g.Add("Edit","x+2 yp-4 w585 vApiPath","")
    g.Add("Button","x+0 h25 vPickApiPath","...").OnEvent("click","gui_events")
    g["ApiPath"].Value := (Settings.Has("ApiPath")) ? Settings["ApiPath"] : ""
    g.Add("Button","x+0 w50 h25 vScan","Scan").OnEvent("click","gui_events")
    
    g.Add("Text","xm y+5","Name:")
    g.Add("Edit","Section yp-4 x+2 w100 vNameFilter","").OnEvent("change","gui_events")
    g.Add("Button","x+0 hp vNameFilterClear","X").OnEvent("click","gui_events")
    g.Add("CheckBox","xs yp+30 vNameBW","Begins with").OnEvent("click","gui_events")
    
    g.Add("Text","x250 ys+4","Value:")
    g.Add("Edit","Section yp-4 x+2 w100 vValueFilter","").OnEvent("change","gui_events")
    g.Add("Button","x+0 hp vValueFilterClear","X").OnEvent("click","gui_events")
    g.Add("CheckBox","xs yp+30 vValueEQ","Exact").OnEvent("click","gui_events")
    
    g.Add("Text","x500 ys+4","Exp:")
    g.Add("Edit","Section yp-4 x+2 w100 vExpFilter","").OnEvent("change","gui_events")
    g.Add("Button","x+0 hp vExpFilterClear","X").OnEvent("click","gui_events")
    
    g.Add("Button","Section x680 ys h25 vDupe","Dupe").OnEvent("click","gui_events")
    g.Add("Button","x+0 h25 vUnk","UNK").OnEvent("click","gui_events")
    g.Add("Button","x+0 w50 h25 vReset","Reset").OnEvent("click","gui_events")
    g.Add("CheckBox","xs ys+30 vNoDupeUnk","Excl unk on dupe").OnEvent("click","gui_events")
    
    ctl := g.Add("ListView","xm w800 h400 vConstList",["Name","Value","Expression"])
    ctl.ModifyCol(1,385), ctl.ModifyCol(2,190), ctl.ModifyCol(3,195)
    ctl.OnEvent("click","gui_events")
    
    g.Add("Text","xm y+5","Press CTRL+D to copy selected constant details.")
    
    ctl := g.Add("Tab3","xm y+5 w800 h142 vTabs",["Details","Duplicates"])
    
    ctl.UseTab("Details")
    g.Add("Edit","xm y+5 w800 r7 vDetails ReadOnly","")
    
    ctl.UseTab("Duplicates")
    g.Add("Edit","xm y+5 w800 r7 vDuplicates ReadOnly","")
    
    ctl.UseTab()
    ctl := g.Add("Text","xm y+5 w800 vTotal","")
    
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

relist_const(nFilter:="",vFilter:="",eFilter:="") {
    ctl := g["ConstList"]
    ctl.Opt("-Redraw")
    ctl.Delete()
    t := 0, u := 0, i := 0, s := 0, m := 0
    
    nFilter := !nFilter ? "*" : nFilter
    nFilter := StrReplace(nFilter,"*",".*")
    nFilter := g["NameBW"].Value ? "^" nFilter : nFilter
    
    vFilter := !vFilter ? "*" : vFilter
    vFilter := StrReplace(vFilter,"*",".*")
    vFilter := g["ValueEQ"].Value ? "^" vFilter "$" : vFilter
    
    eFilter := !eFilter ? "*" : eFilter
    oopsStr := "(){}-+^$&%?.,<>" Chr(34)
    Loop Parse oopsStr
    {
        ch := A_LoopField
        If (InStr(eFilter,ch))
            eFilter := StrReplace(eFilter,ch,"\" ch)
    }
    eFilter := StrReplace(eFilter,"*",".*")
    
    If (unkFilter) {
        For const, obj in const_list {
            value := obj["value"], expr := obj["exp"]
            If (obj["type"] = "unknown")
                ctl.Add(,const,value,expr), t++, u++
        }
        unkFilter := false
    } Else If (dupeFilter) {
        For const, obj in const_list {
            value := obj["value"], expr := obj["exp"], cType := obj["type"]
            If (obj.Has("dupe")) {
                If cType = "integer" {
                    ctl.Add(,const,value,expr), i++, t++
                } Else If cType = "string"
                    ctl.Add(,const,value,expr), s++, t++
                Else If cType = "unknown" And !g["NoDupeUnk"].Value
                    ctl.Add(,const,value,expr), u++, t++
                Else If cType = "macro"
                    ctl.Add(,const,value,expr), m++, t++
            }
        }
        dupeFilter := false
    } Else {
        For const, obj in const_list {
            doList := false
            value := obj["value"]
            expr := obj["exp"]
            
            If (RegExMatch(const,"i)" nFilter) And RegExMatch(value,"i)" vFilter) And RegExMatch(expr,"i)" eFilter))
                doList := true
            
            If (doList) {
                ctl.Add(,const,value,expr), t++
                u := ((obj["type"] = "unknown") ? u+1 : u)
                i := ((obj["type"] = "integer") ? i+1 : i)
                s := ((obj["type"] = "string") ? s+1 : s)
                m := ((obj["type"] = "macro") ? m+1 : m)
            }
        }
    }
    
    ctl.Opt("+Redraw")
    g["Total"].Text := "Total: " t " / Unk: " u " / Known: " t-u " / Int: " i " / Str: " s " / Macros: " m
    
    If (doReset) {
        doReset:=false
        g["NameFilter"].Focus()
    }
}

gui_events(ctl,info) {
    If (ctl.Name = "NameFilter") Or (ctl.Name = "ValueFilter") Or (ctl.Name = "NameBW") Or (ctl.Name = "ValueEQ") Or (ctl.Name = "ExpFilter") {
        SetTimer "relist_timer", timerDelay
    } Else If (ctl.Name = "Reset") {
        g["NameFilter"].Value := ""
        g["ValueFilter"].Value := ""
        g["ExpFilter"].Value := ""
        g["Details"].Value := ""
        g["Duplicates"].Value := ""
        g["NameBW"].Value := 0
        g["ValueEQ"].Value := 0
        g["NoDupeUnk"].Value := 0
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
    } Else If (ctl.Name = "PickApiPath") {
        curFile := Settings.Has("ApiPath") ? Settings["ApiPath"] : ""
        selFile := DirSelect(curFile,,"Select Win32 header root directory:")
        If (selFile)
            Settings["ApiPath"] := selFile, g["ApiPath"].Value := selFile
    } Else If (ctl.Name = "Scan") {
        g["NameFilter"].Value := ""
        g["NameBW"].Value := 0
        g["ValueFilter"].Value := ""
        g["ValueEQ"].Value := 0
        g["Details"].Value := ""
        g["Duplicates"].Value := ""
        g["ExpFilter"].Value := ""
        g["Tabs"].Choose(1)
        
        g["ConstList"].Delete()
        g["Total"].Text := "Scanning Win32 API files..."
        
        win32_header_parser()
        relist_const()
    }
}

relist_timer() {
    relist_const(g["NameFilter"].value,g["ValueFilter"].value,g["ExpFilter"].Value)
}

scan_const() {
    const_list := Map(), const_exp := Map(), const_basic := Map(), delete_list := Map()
    
    arr := StrSplit(FileRead("constants.txt"),"`n","`r")
    
    For i, line in arr {
        If (line = "[CONSTANT]")
            Continue
        
        eq := InStr(line,"=")
        const := Trim(SubStr(line,1,eq-1))
        value := Trim(SubStr(line,eq+1)," =,")
        
        If (InStr(value,"(") = 1 And SubStr(value,-1) = ")")
            value := SubStr(value,2,-1)
        
        If (value = "NUL" Or value = "NULL" Or value = "false")
            value := 0
        
        If (value = "true")
            value := 1
        
        If (InStr(value,"|"))
            value := StrReplace(value,"|"," | ")
        
        curVal := ""
        Try curVal := Integer(value)
        
        If curVal = ""
            Try curVal := eval(value)
        
        If (IsInteger(curVal)) {
            const_list[const] := Map("const",const,"type","integer","value",curVal,"exp",value,"complete",true)
            Continue
        }
        
        If (SubStr(value,1,1) = Chr(34) And SubStr(value,-1) = Chr(34) And !InStr(value,"+")) {
            const_list[const] := Map("const",const,"type","string","value",value,"exp",value,"complete",true)
            Continue
        }
        
        If (InStr(value,Chr(34)) And InStr(value,"+")) {
            const_list[const] := Map("const",const,"type","unknown","value",value,"exp",value,"complete",false)
            Continue
        }
        
        const_list[const] := Map("const",const,"type","unknown","value",value,"exp",value,"complete",false)
    }
    
    If (const_list.Has(""))
        const_list.Delete("")
    
    
    ; msgbox "start reparse1()"
    ; passes := 2
    ; Loop passes
        ; reparse1(A_Index,passes)
    
    ; Loop 18 ; re-use until no replacements
        ; reparse2()
    
    ; Loop 3 ; re-use until no replacements
        ; reparse3()
    
    ; reparse4()
    
    ; msgbox "start reparse5()"
    ; Loop 3
        ; reparse5()
    
    ; reparse2()
}

WM_KEYDOWN(wParam, lParam, msg, hwnd) { ; up / down scrolling with keyboard
    If (g["ConstList"].hwnd = hwnd And (wParam = 38 Or wParam = 40))
        SetTimer "gui_timer", -100
}

gui_timer() {
    gui_events(g["ConstList"],g["ConstList"].GetNext())
}

; Name:  ADVISE_ALL
; Value: ADVISE_CLIPPING | ADVISE_PALETTE | ADVISE_COLORKEY | ADVISE_POSITION
; Expr:  ADVISE_CLIPPING | ADVISE_PALETTE | ADVISE_COLORKEY | ADVISE_POSITION
; Type:  unknown

; Name:  CERT_QUERY_FORMAT_FLAG_ALL
; Value: CERT_QUERY_FORMAT_FLAG_BINARY | CERT_QUERY_FORMAT_FLAG_BASE64_ENCODED
; Expr:  CERT_QUERY_FORMAT_FLAG_BINARY | CERT_QUERY_FORMAT_FLAG_BASE64_ENCODED
; Type:  unknown

reparse5() {
    t := 0, opers := "+-*/^|&"
    For const, obj in const_list {
        cValue := obj["value"], cType := obj["type"]
        cComp := obj["complete"], cExp := obj["exp"]
        newVal := 0, finalVal := "", success := true
        
        If (cType = "unknown" And InStr(cValue," ")) {
            ; If (const = "CERT_QUERY_FORMAT_FLAG_BASE64_ENCODED")
                ; MsgBox "CERT_QUERY_FORMAT_FLAG_BASE64_ENCODED"
            
            arr := StrSplit(cValue," ")
            
            If (arr[1] = "") 
                Continue
            
            For i, v in arr {
                v := Trim(v)
                If (const_list.Has(v) And const_list[v]["type"] = "integer") {
                    newVal := Integer(const_list[v]["value"])
                } Else If (IsInteger(v)) {
                    newVal := Integer(v)
                } Else If (InStr(opers,v)) {
                    newVal := v
                } Else {
                    newVal := 0, finalVal := "", success := false
                    Break ; MUST break / cancel changes to obj
                }
                
                finalVal .= newVal " "
            }
            finalVal := Trim(finalVal)
            
            If (success) {
                Try {
                    old := finalVal
                    finalVal := eval(finalVal)
                    ; Debug.Msg(const ": " old " / finalVal: " finalVal)
                    
                    If (!IsInteger(finalVal)) {
                        ; debug.msg("not working")
                        Continue
                    }
                    
                    
                } Catch e
                    Continue
                
                ; If (const = "CERT_QUERY_FORMAT_FLAG_BASE64_ENCODED")
                        ; MsgBox "CERT_QUERY_FORMAT_FLAG_BASE64_ENCODED / finalVal: " finalVal " / old: " old " / cValue: " cValue
                
                obj["value"] := finalVal, obj["complete"] := true, obj["type"] := "integer"
                const_list[const] := obj
                t++
            }
        }
        c := A_Index
    }
    
    ; msgbox "reparse5: " t
}

reparse4() {
    t := 0
    For const, obj in const_list {
        cValue := obj["value"], cType := obj["type"]
        cComp := obj["complete"], cExp := obj["exp"]
        newVal := 0, finalVal := 0, success := true
        
        If (cType = "unknown" And InStr(cValue,"-")) {
            arr := StrSplit(cValue,"-")
            
            If (arr.Length != 2 Or arr[1] = "") 
                Continue
            
            For i, v in arr {
                v := Trim(v)
                If (const_list.Has(v) And const_list[v]["type"] = "integer") {
                    newVal := Integer(const_list[v]["value"])
                } Else If (IsInteger(v)) {
                    newVal := Integer(v)
                } Else {
                    newVal := 0, finalVal := 0, success := false
                    Break ; MUST break / cancel changes to obj
                }
                
                finalVal -= newVal
            }
            
            If (success) {
                obj["value"] := finalVal, obj["complete"] := true, obj["type"] := "integer"
                const_list[const] := obj
                t++
            }
        }
        c := A_Index
    }
    
    ; msgbox "reparse4: " t " / " c
}

reparse3() { ; const integer with bitwise OR "|"
    t := 0
    For const, obj in const_list {
        cValue := obj["value"], cType := obj["type"]
        cComp := obj["complete"], cExp := obj["exp"]
        newVal := 0, finalVal := 0, success := true
        
        If (cType = "unknown" And InStr(cValue,"|")) {
            arr := StrSplit(cValue,"|")
            
            For i, v in arr {
                v := Trim(v)
                If (IsInteger(v))
                    newVal := Integer(v)
                Else If (const_list.Has(v) And const_list[v]["type"] = "integer") {
                    newVal := const_list[v]["value"]
                } Else {
                    success := false
                    Break
                }
                
                finalVal := finalVal | newVal
            }
            
            If (success) {
                obj["value"] := finalVal, obj["complete"] := true, obj["type"] := "integer"
                const_list[const] := obj
                t++
            }
        }
        c := A_Index
    }
    ; msgbox "reparse3: " t " / " c
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
    mathStr := StrReplace(StrReplace(StrReplace(mathStr,"^"," -bxor "),"&"," -band "),"|"," -bor ")
    c := cli.new("powershell " mathStr), output := c.stdout, c := ""
    
    return Trim(output,"`r`n`t ")
}

#HotIf WinActive("ahk_id " g.hwnd)

F2::{
    Msgbox "Starting save data."
    If (FileExist("const_list.txt"))
        FileDelete "const_list.txt"
    FileAppend jxon_dump(const_list,4), "const_list.txt"
    Msgbox "Data saved."
}

F3::{
    Msgbox "Starting re-scan."
    
    g["ConstList"].Delete()
    g["Total"].Value := "Please Wait ..."
    g["Details"].Value := ""
    
    scan_const()
    relist_const()
    
    Msgbox "Rescan complete."
}

^d::{
    A_Clipboard := g["Details"].Value
}
