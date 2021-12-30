Global filter_gui

load_filters() {
    Global Settings, filter_gui
    filter_gui := Gui("-MinimizeBox -MaximizeBox +Owner" app.mainGUI.hwnd,"More Filter Options")
    filter_gui.OnEvent("escape",filter_escape)
    filter_gui.OnEvent("close",filter_close)
    
    filter_gui.Add("Text","xm y+5 Right w35","File:")
    filter_gui.Add("ComboBox","yp-4 x+2 w410 vFileFilter Sort").OnEvent("change",gui_events)
    
    fileList := listFiles()
    filter_gui["FileFilter"].Delete()
    filter_gui["FileFilter"].Add(fileList)
    filter_gui["FileFilter"].Opt("+Sort")
    filter_gui["FileFilter"].Text := Settings["FileFilter"]
    
    filter_gui.Add("Button","x+0 hp vFileFilterClear","X").OnEvent("click",gui_events)
    
    filter_gui.Add("Text","xm y+10","Types:")
    ctl := filter_gui.Add("Checkbox","y+5 vInteger Section","Integer"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckInteger"]
    ctl := filter_gui.Add("Checkbox","y+5 vFloat","Float"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckFloat"]
    ctl := filter_gui.Add("Checkbox","y+5 vString","String"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckString"]
    ; ctl := filter_gui.Add("Checkbox","y+5 vType","TypeDef"), ctl.OnEvent("click",gui_events)
    ; ctl.Value := Settings["CheckType"]
    ctl := filter_gui.Add("Checkbox","y+5 vUUID","UUID"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckUUID"]
    
    ctl := filter_gui.Add("Checkbox","xs+75 ys vStruct Section","Struct"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckStruct"]
    ctl := filter_gui.Add("Checkbox","xs y+5 vEnum","Enum"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckEnum"]
    ; ctl := filter_gui.Add("Checkbox","xs y+5 vExpr","Expr"), ctl.OnEvent("click",gui_events)
    ; ctl.Value := Settings["CheckExpr"]
    ctl := filter_gui.Add("Checkbox","xs y+5 vMacro","Macro"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckMacro"]
    ; ctl := filter_gui.Add("Checkbox","xs y+5 vMIDL","MIDL"), ctl.OnEvent("click",gui_events)
    ; ctl.Value := Settings["CheckMIDL"]
    
    ctl := filter_gui.Add("Checkbox","xs+75 ys vUnknown Section","Unknown"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckUnknown"]
    ctl := filter_gui.Add("Checkbox","xs y+5 vOther","Other"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckOther"]
    ctl := filter_gui.Add("Checkbox","xs y+5 vDupe","Dupe"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckDupe"]
    ctl := filter_gui.Add("Checkbox","xs y+5 vCrit","Critical"), ctl.OnEvent("click",gui_events)
    ctl.Value := Settings["CheckCrit"]
    
    filter_gui.Add("Button","ys xs+75 w85 vReset Section","Reset Filters").OnEvent("click",filter_events)
    filter_gui.Add("Button","y+0 xs wp vNoUnkOth","No Unknown").OnEvent("click",filter_events)
    filter_gui.Add("Button","y+0 xs wp vNoDupeCrit","No Dupe Crit").OnEvent("click",filter_events)
    
    filter_gui.Add("Button","ys x+0 wp vUnkOnly","Unknown").OnEvent("click",filter_events)
    filter_gui.Add("Button","y+0 xp wp vNumerics","Numerics").OnEvent("click",filter_events)
    filter_gui.Add("Button","y+0 xp wp vNonNumer","Non Numerics").OnEvent("click",filter_events)
    
    filter_gui.Add("Button","xm+428 vClose","Close").OnEvent("click",filter_events)
    
    filter_gui.Show()
    
    WinSetEnabled False, app.mainGUI.hwnd
}

filter_events(ctl,info) {
    Global Settings
    
    if (ctl.name = "Reset") {
        ctl.gui["FileFilter"].Text := ""
        ctl.gui["Integer"].value := 1
        ctl.gui["Float"].value := 1
        ctl.gui["String"].value := 1
        ctl.gui["UUID"].value := 1
        ; ctl.gui["MIDL"].value := 1
        ctl.gui["Struct"].value := 1
        ctl.gui["Enum"].value := 1
        ctl.gui["Macro"].value := 1
        ; ctl.gui["Type"].value := 1
        ; ctl.gui["Expr"].value := 1
        ctl.gui["Unknown"].value := 1
        ctl.gui["Other"].value := 1
        ctl.gui["Dupe"].value := 1
        ctl.gui["Crit"].value := 1
    } else if (ctl.name = "NoUnkOth") {
        ctl.gui["Unknown"].value := 0
        ctl.gui["Other"].value := 0
    } else if (ctl.name = "NoDupeCrit") {
        ctl.gui["Dupe"].value := 0
        ctl.gui["Crit"].value := 0
    } else if (ctl.name = "UnkOnly") {
        ctl.gui["Integer"].value := 0
        ctl.gui["Float"].value := 0
        ctl.gui["String"].value := 0
        ctl.gui["UUID"].value := 0
        ; ctl.gui["MIDL"].value := 0
        ctl.gui["Struct"].value := 0
        ctl.gui["Enum"].value := 0
        ctl.gui["Macro"].value := 0
        ; ctl.gui["Type"].value := 0
        ; ctl.gui["Expr"].value := 0
        ctl.gui["Unknown"].value := 1
        ctl.gui["Other"].value := 1
        ctl.gui["Dupe"].value := 1
        ctl.gui["Crit"].value := 1
    } else if (ctl.name = "Numerics") {
        ctl.gui["Integer"].value := 1
        ctl.gui["Float"].value := 1
        ctl.gui["String"].value := 0
        ctl.gui["UUID"].value := 0
        ; ctl.gui["MIDL"].value := 0
        ctl.gui["Struct"].value := 0
        ctl.gui["Enum"].value := 0
        ctl.gui["Macro"].value := 0
        ; ctl.gui["Type"].value := 0
        ; ctl.gui["Expr"].value := 0
        ctl.gui["Unknown"].value := 0
        ctl.gui["Other"].value := 0
        ctl.gui["Dupe"].value := 1
        ctl.gui["Crit"].value := 1
    } else if (ctl.name = "NonNumer") {
        ctl.gui["Integer"].value := 0
        ctl.gui["Float"].value := 0
        ctl.gui["String"].value := 1
        ctl.gui["UUID"].value := 1
        ; ctl.gui["MIDL"].value := 1
        ctl.gui["Struct"].value := 1
        ctl.gui["Enum"].value := 1
        ctl.gui["Macro"].value := 1
        ; ctl.gui["Type"].value := 1
        ; ctl.gui["Expr"].value := 1
        ctl.gui["Unknown"].value := 0
        ctl.gui["Other"].value := 0
        ctl.gui["Dupe"].value := 1
        ctl.gui["Crit"].value := 1
    } else if (ctl.name = "Close") {
        filter_close(ctl.gui)
    }
}

filter_close(_gui) {
    hwnd := _gui.hwnd
    
    Settings["CheckInteger"] := _gui["Integer"].value
    Settings["CheckFloat"] := _gui["Float"].value
    Settings["CheckString"] := _gui["String"].value
    Settings["CheckUUID"] := _gui["UUID"].value
    ; Settings["CheckMIDL"] := _gui["MIDL"].value
    Settings["CheckStruct"] := _gui["Struct"].value
    Settings["CheckEnum"] := _gui["Enum"].Value
    Settings["CheckMacro"] := _gui["Macro"].value
    ; Settings["CheckType"] := _gui["Type"].value
    ; Settings["CheckExpr"] := _gui["Expr"].value
    Settings["CheckUnknown"] := _gui["Unknown"].value
    Settings["CheckOther"] := _gui["Other"].value
    Settings["CheckDupe"] := _gui["Dupe"].value
    Settings["CheckCrit"] := _gui["Crit"].value
    
    Global Settings
    
    WinSetEnabled True, app.mainGUI.hwnd
    If !(WinActive("A") = app.mainGUI.hwnd)
        WinActivate "ahk_id " app.mainGUI.hwnd
    
    If WinExist("ahk_id " hwnd)
        _gui.Destroy()
    
    app.mainGUI["NameFilter"].Focus()
}

filter_escape(_gui) {
    Global filter_gui
    filter_close(_gui)
}