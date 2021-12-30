global_settings_gui() {
    Global Settings
    
    g := Gui("-MinimizeBox -MaximizeBox +Owner" app.mainGUI.hwnd,"Global Settings")
    g.OnEvent("close",global_settings_close)
    g.OnEvent("escape",global_settings_escape)
    
    g.Add("Text","xm y+10 Section","Global Constants (Scanning)")
    ctl := g.Add("Edit","xs y+5 r11 w560 vGlobConst")
    ctl.Value := Settings["GlobConst"]
    ctl.SetFont(,"Consolas")
    
    g.Add("Text","xm y+10 Section","Global Constants (Compiling)")
    ctl := g.Add("Edit","xs y+5 r5 w560 vGlobConstComp")
    ctl.Value := Settings["GlobConstComp"]
    ctl.SetFont(,"Consolas")
    
    g.Add("Text","xm y+10 Section","Global Macros")
    ctl := g.Add("Edit","xs y+5 r5 w560 vGlobMacro")
    ctl.Value := Settings["GlobMacro"]
    ctl.SetFont(,"Consolas")
    
    g.Add("Text","xm y+10 Section","Global Includes (comma separated)")
    ctl := g.Add("Edit","xs y+5 r5 w560 vGlobInclude")
    ctl.Value := Settings["GlobInclude"]
    ctl.SetFont(,"Consolas")
    
    g.Add("Text","y+14 xm","Scan Type:")
    ctl := g.Add("DropDownList","x+5 yp-4 w50 vGlobScanType",["x64","x86"])
    ctl.OnEvent("Change",global_settings_events)
    ctl.Text := Settings["GlobScanType"]
    
    ; ctl := g.Add("Checkbox","yp+4 x+10 vGlobalCache","Cache global constants")
    ; ctl.OnEvent("Click",global_settings_events)
    ; ctl.Value := Settings["GlobalCache"]
    
    ; ctl := g.Add("Checkbox","x+10 vGlobalCachePrompt","Prompt to load global cache")
    ; ctl.OnEvent("Click",global_settings_events)
    ; ctl.Value := Settings["GlobalCachePrompt"]
    
    g.Add("Button","xm+420 y+20 w70 vOK","OK").OnEvent("Click",global_settings_events)
    g.Add("Button","x+0 w70 vCancel","Cancel").OnEvent("Click",global_settings_events)
    
    g["OK"].Focus()
    g.Show()
    
    WinSetEnabled False, app.mainGUI.hwnd
}

global_settings_close(g) {
    WinActivate app.mainGUI.hwnd
    WinSetEnabled True, app.mainGUI.hwnd
    app.mainGUI["NameFilter"].Focus()
}

global_settings_escape(g) {
    global_settings_close(g), g.Destroy()
}

global_settings_events(ctl, info) {
    Global Settings
    
    If (ctl.Name = "OK") {
        Settings["GlobConst"] := ctl.gui["GlobConst"].Value
        Settings["GlobConstComp"] := ctl.gui["GlobConstComp"].Value
        Settings["GlobMacro"] := ctl.gui["GlobMacro"].Value
        Settings["GlobInclude"] := ctl.gui["GlobInclude"].Value
        global_settings_escape(ctl.gui)
    } Else If (ctl.Name = "Cancel")
        global_settings_escape(ctl.gui)
    Else If (ctl.Name = "GlobScanType")
        Settings["GlobScanType"] := ctl.Text
    ; Else If RegExMatch(ctl.Name,"^GlobalCache")
        ; Settings[ctl.Name] := ctl.Value
}