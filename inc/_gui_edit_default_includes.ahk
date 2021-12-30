default_includes_gui() {
    Global Settings
    g := app.mainGUI
    If !app.ApiPath {
        Msgbox "Select C++ source first."
        return
    }
    root := StrReplace(app.ApiPath,"\","|")
    default_includes := Settings["baseFiles"].Has(root) ? Settings["baseFiles"][root] : []
    
    For incl in default_includes
        default_includes.Push(StrReplace(incl,"|","\"))
    
    g4 := Gui("-MinimizeBox -MaximizeBox +Owner" g.hwnd,"Default Includes")
    g4.OnEvent("close",g5_close)
    g4.OnEvent("escape",g5_escape)
    
    g4.Add("Listbox","xm y+5 w500 r10 vDefaultIncludes",recents_list).OnEvent("doubleclick",gui_events5)
    g4.Add("Button","xm+400 y+0 w50 vAdd","Add").OnEvent("click",gui_events5)
    g4.Add("Button","x+0 y+0 w50 vRemove","Remove").OnEvent("click",gui_events5)
    
    g4.Show()
    
    WinSetEnabled False, g.hwnd
}

gui_events5(ctl,info) {
    Global Settings
    g := app.mainGUI
    recents_list := []
    For rec in Settings["baseFiles"]
        recents_list.Push(rec)
    
    If (ctl.Name = "RecentsList" Or ctl.Name = "Remove") {
        If (row := ctl.gui["RecentsList"].Value) {
            txt := StrReplace(recents_list[row],"\","|")
            ctl.Delete(row)
            recents_list.RemoveAt(row)
            Settings["baseFiles"].Delete(txt)
            load_menubar(g)
        }
    }
}

g5_close(g5) {
    Global Settings
    g := app.mainGUI
    WinActivate "ahk_id " g.hwnd
    WinSetEnabled True, g.hwnd
    g["NameFilter"].Focus()
}

g5_escape(g5) {
    g5_close(g5)
    g5.Destroy()
}