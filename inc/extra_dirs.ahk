extra_dirs() {
    If (!Settings.Has("dirs"))
        Settings["dirs"] := Map()
    
    root := g["ApiPath"].Text
    SplitPath root, file
    other_dirs := Settings["dirs"].Has(file) ? Settings["dirs"][file] : []
    
    g2 := Gui.New("-DPIScale +OwnDialogs +AlwaysOnTop","Other Directories")
    g2.OnEvent("close","g2_close")
    
    g2.Add("Edit","xm w560 vOtherDir")
    g2.Add("Button","x+0 w20 vAddOtherDir","+").OnEvent("click","gui_events2")
    g2.Add("Button","x+0 w20 vRemOtherDir","-").OnEvent("click","gui_events2")
    g2.Add("Listbox","xm y+5 w600 r10 vOtherDirList",other_dirs).OnEvent("doubleclick","gui_events2")
    
    g2.Show()
}

gui_events2(ctl,info) {
    root := g["ApiPath"].Text
    SplitPath root, file
    other_dirs := Settings["dirs"].Has(file) ? Settings["dirs"][file] : []
    If (ctl.Name = "AddOtherDir" And ctl.gui["OtherDir"].Value) {
        v := ctl.gui["OtherDir"].Value
        ctl.gui["OtherDirList"].Add([v]), other_dirs.Push(v)
        ctl.gui["OtherDir"].Value := ""
    } Else If (ctl.Name = "RemOtherDir" And ctl.gui["OtherDirList"].Value) {
        v := ctl.gui["OtherDirList"].Value
        ctl.gui["OtherDirList"].Delete(v), other_dirs.RemoveAt(v)
    } Else If (ctl.Name = "OtherDirList" And ctl.Value) {
        v := ctl.Value
        ctl.Delete(v), other_dirs.RemoveAt(v)
    }
    Settings["dirs"][file] := other_dirs
}

g2_close(g2) {
    If (!Settings.Has("dirs"))
        Settings["dirs"] := Map()
    
    root := g["ApiPath"].Text
    SplitPath root, file
    other_dirs := Settings["dirs"].Has(file) ? Settings["dirs"][file] : []
    Settings["dirs"][file] := other_dirs
    
    ; msgbox jxon_dump(other_dirs,4)
}