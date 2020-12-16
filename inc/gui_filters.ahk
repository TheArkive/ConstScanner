Global filter_gui

load_filters() {
    filter_gui := Gui.New("-MinimizeBox -MaximizeBox +Owner" g.hwnd,"More Filter Options")
    
    filter_gui.Add("Text","xm y+5 Right w35","File:")
    filter_gui.Add("ComboBox","yp-4 x+2 w410 vFileFilter").OnEvent("change","gui_events")
    
    fileList := listFiles()
    filter_gui["FileFilter"].Delete()
    filter_gui["FileFilter"].Add(fileList)
    filter_gui["FileFilter"].Opt("+Sort")
    
    filter_gui.Add("Button","x+0 hp vFileFilterClear","X").OnEvent("click","gui_events")
    
    filter_gui.Add("Text","xm y+10","Types:")
    ctl := filter_gui.Add("Checkbox","y+5 vInteger Section","Integer"), ctl.OnEvent("click","gui_events")
    ctl.Value := Settings["CheckInteger"]
    ctl := filter_gui.Add("Checkbox","y+5 vFloat","Float"), ctl.OnEvent("click","gui_events")
    ctl.Value := Settings["CheckFloat"]
    ctl := filter_gui.Add("Checkbox","y+5 vString","String"), ctl.OnEvent("click","gui_events")
    ctl.Value := Settings["CheckString"]
    ctl := filter_gui.Add("Checkbox","xs+100 ys vUnknown Section","Unknown"), ctl.OnEvent("click","gui_events")
    ctl.Value := Settings["CheckUnknown"]
    ctl := filter_gui.Add("Checkbox","xs y+5 vOther","Other"), ctl.OnEvent("click","gui_events")
    ctl.Value := Settings["CheckOther"]
    ctl := filter_gui.Add("Checkbox","xs y+5 vExpr","Expr"), ctl.OnEvent("click","gui_events")
    ctl.Value := Settings["CheckExpr"]
    ctl := filter_gui.Add("Checkbox","xs y+5 vDupe","Dupe"), ctl.OnEvent("click","gui_events")
    ctl.Value := Settings["CheckDupe"]
    
    filter_gui.Show()
}