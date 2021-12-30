incl_report() {
    Global Settings, sizeof_list
    g3 := Gui("-MinimizeBox -MaximizeBox +Owner" app.mainGUI.hwnd,"Types List")
    g3.OnEvent("close",g3_close)
    g3.OnEvent("escape",g3_escape)
    
    g3.Add("Edit","xm w370 vFilter").OnEvent("change",gui_events3)
    g3.Add("Button","x+0 w30 vClearFilter","X").OnEvent("click",gui_events3)
    ctl := g3.Add("Edit","xm w400 h400 ReadOnly y+2 vReport")
    ctl.SetFont(,"Consolas")
    ctl.value := jxon_dump(sizeof_list,4)
    
    g3.Add("Button","xm y+0 w400 vCopy","Copy").OnEvent("click",gui_events3)
    
    g3.Show()
    
    incl_report_filter(g3)
    ; Static bf := incl_report_filter.Bind(g3)
    ; app.BoundFunc := bf
    
    WinSetEnabled False, app.mainGUI.hwnd
}

g3_close(_gui) {
    Global Settings
    WinActivate "ahk_id " app.mainGUI.hwnd
    WinSetEnabled True, app.mainGUI.hwnd
}

g3_escape(_gui) {
    g3_close(_gui)
    _gui.Destroy()
}

gui_events3(ctl,info) {
    Global Settings
    If (ctl.Name = "Filter") {
        ; SetTimer Settings["BoundFunc"], -500
        incl_report_filter(ctl.gui)
    } Else If (ctl.Name = "ClearFilter") {
        ctl.gui["Filter"].Value := ""
        ; SetTimer Settings["BoundFunc"], -500
        incl_report_filter(ctl.gui)
    } Else If (ctl.Name = "Copy")
        A_Clipboard := ctl.gui["Report"].Value
}

incl_report_filter(g3) {
    Global IncludesList
    filter_txt := g3["Filter"].Value
    final_list := Map()
    rData := ""
    longest := 10
    
    For _type, _size in sizeof_list {
        If StrLen(_type) > longest
            longest := StrLen(_type)
    }
    
    rData := Format("{1:-" longest "}  Size","Type") "`r`n"
    rData .= rpt("=",longest + 6) "`r`n"
    
    If (filter_txt != "") {
        For _type, _size in sizeof_list {
            If InStr(_type,filter_txt)
                rData .= (rData?"`r`n":"") Format("{:-" longest "} {2: 4}",_type,_size)
        }
    } Else {
        For _type, _size in sizeof_list
            rData .= (rData?"`r`n":"") Format("{:-" longest "} {2: 4}",_type,_size)
    }
    
    g3["Report"].Value := rData
    
    rpt(str,reps) { ; closure
        final_str := ""
        Loop reps
            final_str .= str
        return final_str
    }
}
