recents_gui() {
    recents_list := []
    For rec in Settings["Recents"]
        recents_list.Push(StrReplace(rec,"|","\"))
    
    g4 := Gui.New("-MinimizeBox -MaximizeBox +Owner" Settings["gui"].hwnd,"Edit Recents")
    g4.OnEvent("close","g4_close")
    g4.OnEvent("escape","g4_escape")
    
    g4.Add("Listbox","xm y+5 w500 r10 vRecentsList",recents_list).OnEvent("doubleclick","gui_events4")
    g4.Add("Button","xm+450 y+0 w50 vRemove","Remove").OnEvent("click","gui_events4")
    
    g4.Show()
    
    WinSetEnabled False, Settings["gui"].hwnd
}

gui_events4(ctl,info) {
    If (ctl.Name = "RecentsList" Or ctl.Name = "Remove") {
        If (row := ctl.gui["RecentsList"].Value) {
            txt := ctl.gui["RecentsList"].Text
            ; msgbox "row: " row
            ctl.gui["RecentsList"].Delete(row)
            Settings["Recents"].Delete(txt)
            Settings["gui"].Menubar := load_menubar()
        }
    }
}

g4_close(g4) {
    g := Settings["gui"]
    WinActivate "ahk_id " g.hwnd
    WinSetEnabled True, g.hwnd
    g["NameFilter"].Focus()
}

g4_escape(g4) {
    g4_close(g4)
    g4.Destroy()
}