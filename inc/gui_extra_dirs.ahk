extra_dirs() {
    Global Settings
    g2 := Gui("-MinimizeBox -MaximizeBox +Owner" Settings["gui"].hwnd,"Other Files (grouped with primary C++ Source File)")
    g2.OnEvent("close",g2_close)
    g2.OnEvent("escape",g2_escape)
    
    ctl := g2.Add("Text","xm Section","Profile Name:")
    g2.Add("Edit","x80 yp-4 w400 vProfileName")
    
    g2.Add("Text","xs y+10","Base Folders:")
    ctl := g2.Add("ListBox","x+6 yp-4 w495 r3 vBaseFolder")
    ctl.OnEvent("ContextMenu",gui_events2b)
    ctl.OnEvent("DoubleClick",gui_events2)
    
    g2.Add("Button","x+0 w30 h20 vBaseFolderAdd","...").OnEvent("click",gui_events2)
    g2.Add("Button","xp y+0 wp h23 vBaseFolderRemove","X").OnEvent("click",gui_events2)
    
    g2.Add("Text","xs y+10","Constants:")
    g2.Add("Edit","x+20 yp-4 w495 r3 vUserConstants")
    
    g2.Add("Text","xs y+10","Add Includes/Folders (paste list here - * wildcard * patterns optional)")
    g2.Add("Edit","xs y+5 r3 w560 vOtherDir")
    g2.Add("Button","x+0 w40 h47 vAddOtherDir","Add").OnEvent("click",gui_events2)
    
    g2.Add("Text","xs y+20","Includes List")
    g2.Add("Text","x+140 w100 Right","Search:")
    g2.Add("Edit","x+5 yp-4 w265 vSearch").OnEvent("change",gui_events2)
    g2.Add("Button","x+0 w30 vClearSearch","X").OnEvent("click",gui_events2)
    
    IL := IL_Create(2), IL_Add(IL, "icons\check.ico"), IL_Add(IL, "icons\X.ico") ; check, X
    
    Settings["MakeProfile"] := []
    ctl := g2.Add("ListView","xs y+0 w600 r10 Checked Count20 vOtherDirList Multi Sort",["WildPath"])
    ctl.OnEvent("ContextMenu",gui_events2b), ctl.SetImageList(IL)
    ctl.OnEvent("ItemCheck",g2_check_event)
    ctl.ModifyCol(1,570)
    
    g2.Add("Button","xm+450 y+10 w75 vOK","OK").OnEvent("click",gui_events2)
    g2.Add("Button","x+0 w75 vCancel","Cancel").OnEvent("click",gui_events2)
    
    g2.Show()
    
    Settings["temp_gui"] := g2
    
    WinSetEnabled False, Settings["gui"].hwnd
    
    If Settings["Recents"].Has(Settings["ApiPath"]) {
        rec := Settings["Recents"][Settings["ApiPath"]]
        g2["ProfileName"].Value := rec["Name"]
        g2["BaseFolder"].Add(rec["BaseFolder"])
        (rec.Has("UserConstants")) ? g2["UserConstants"].value := StrReplace(rec["UserConstants"],"\n","`n") : ""
        
        For row in rec["OtherDirList"]
            g2["OtherDirList"].Add((row[1]?"Check ":"") "Icon" row[2],row[3])
        Settings["MakeProfile"] := rec["OtherDirList"]
    }
}

g2_menu(ctl,row) {
    m := Menu()
    m.Add("Include during scan",g2_menu_events)
    m.SetIcon("Include during scan","icons\check.ico")
    m.Add("Exclude during scan",g2_menu_events)
    m.SetIcon("Exclude during scan","icons\X.ico")
    m.Add()
    m.Add("Delete",g2_menu_events)
    m.ctl := ctl, m.row := row
    m.Add()
    m.Add("Copy",g2_menu_events)
    m.Add("Select All",g2_menu_events)
    m.Show()
}

g2_menub(ctl,row) {
    m := Menu()
    m.Add("Move Up",g2_menu_events)
    m.Add("Move Down",g2_menu_events)
    m.SetIcon("Move Up","icons\up.ico")
    m.SetIcon("Move Down","icons\down.ico")
    m.ctl := ctl
    m.row := row
    m.Show()
}

g2_menu_events(n, p, m) { ; ItemName, ItemPos, MenuObj
    Global Settings
    row:=0
    If (n="Include during scan") {
        While (row:=m.ctl.GetNext(row)) {
            file_name := m.ctl.GetText(row)
            m.ctl.Modify(row,"Icon1")
            For curItem in Settings["MakeProfile"] {
                If (file_name = curItem[3]) {
                    Settings["MakeProfile"][A_Index][2] := 1
                    Break
                }
            }
        }
    } Else If (n="Exclude during scan") {
        While (row:=m.ctl.GetNext(row)) {
            file_name := m.ctl.GetText(row)
            m.ctl.Modify(row,"Icon2")
            For curItem in Settings["MakeProfile"] { ; array loop
                If (file_name = curItem[3]) {
                    Settings["MakeProfile"][A_Index][2] := 2
                    Break
                }
            }
        }
    } Else If (n="Delete") {
        While (row:=m.ctl.GetNext(0)) {
            file_name := m.ctl.GetText(row)
            m.ctl.Delete(row) ; delete in GUI
            For curItem in Settings["MakeProfile"] {
                If (file_name = curItem[3]) {
                    Settings["MakeProfile"].RemoveAt(A_Index) ; delete in backup array
                    Break
                }
            }
        }
    } Else If (n="Copy") {
        fileList := ""
        While (row:=m.ctl.GetNext(row))
            fileList .= m.ctl.GetText(row) "`r`n"
        A_Clipboard := fileList
    } Else If (n="Select All") {
        m.ctl.Modify(0,"Select")
    } Else If (n="Move Up") Or (n="Move Down") {
        list := m.ctl.GetItems(), txt := list[m.row], len := list.Length
        new_row := (n="Move Up") ? m.row - 1 : (n="Move Down") ? m.row + 1 : m.row
        (new_row>len) ? new_row := len : (new_row=0) ? new_row := 1 : "" ; clip ends
        list.RemoveAt(m.row), list.InsertAt(new_row, txt)
        m.ctl.Delete(), m.ctl.Add(list)
    }
}

gui_events2b(ctl, Item, IsRightClick, X, Y) { ; context menu event
    If (ctl.Name = "OtherDirList") ; ListView
        g2_menu(ctl,item) ; item=row
    Else If (ctl.Name = "BaseFolder") { ; ListBox
        Click x ", " y ; messy but effective - select on right-click
        g2_menub(ctl,ctl.Value)
    }
}

g2_check_event(ctl, row, c) {
    Global Settings
    file_name := ctl.GetText(row)
    For item in Settings["MakeProfile"] {
        If item[3] = file_name {
            Settings["MakeProfile"][A_Index][1] := c
            Break
        }
    }
}

gui_events2(ctl,info) {
    Global Settings
    other_dirs := []
    
    If (ctl.Name = "AddOtherDir") {
        If !ctl.gui["OtherDir"].Value {
            Msgbox "Nothing to add!"
            return
        } Else If !ctl.gui["BaseFolder"].GetItems() {
            Msgbox "Select Base Folder first."
            return
        }
        
        v := Trim(StrReplace(ctl.gui["OtherDir"].Value,Chr(34),""),"`r`n`t ")
        a := StrSplit(v,"`n","`r")
        
        ctl.gui["OtherDirList"].Opt("-Redraw")
        For path in a {
            path := Trim(path,"`t ")
            (!FileExist(path)) ? path := get_full_path(path,ctl.gui["BaseFolder"].GetItems()) : ""
            If (path) {
                ctl.gui["OtherDirList"].Add("Icon1",path)
                Settings["MakeProfile"].Push(0,1,path)
            }
        }
        
        ctl.gui["OtherDirList"].Opt("Sort")
        ctl.gui["OtherDirList"].Opt("+Redraw")
        ctl.gui["OtherDir"].Value := ""
        ctl.gui["OtherDir"].Focus()
        Settings["MakeProfile"] := SaveOtherDirList(ctl.gui["OtherDirList"])
        ctl.Gui["Search"].Value := ""
        
    } Else If (ctl.Name = "Search") {
        ctl.gui["OtherDirList"].Opt("-Redraw")
        ctl.gui["OtherDirList"].Delete()
        For item in Settings["MakeProfile"]
            If ((ctl.Value != "") And InStr(item[3],ctl.Value)) Or (ctl.Value = "")
                ctl.gui["OtherDirList"].Add((item[1]?"Check ":"") "Icon" item[2],item[3])
        ctl.gui["OtherDirList"].Opt("+Redraw")
        
    } Else If (ctl.Name = "ClearSearch") {
        ctl.gui["Search"].Value := ""
        ctl.gui["OtherDirList"].Opt("-Redraw")
        ctl.gui["OtherDirList"].Delete()
        For item in Settings["MakeProfile"]
            If ((ctl.Value != "") And InStr(item[3],ctl.Value)) Or (ctl.Value = "")
                ctl.gui["OtherDirList"].Add((item[1]?"Check ":"") "Icon" item[2],item[3])
        ctl.gui["OtherDirList"].Opt("+Redraw")
    
    } Else If (ctl.Name = "BaseFolder") {
        ctl.Delete(ctl.Value)
    
    } Else If (ctl.Name = "BaseFolderAdd") {
        SplitPath Settings["lastDir"],, &dir
        sel_dir := FileSelect("D2", dir, "Select Base Folder")
        If !sel_dir
            return
        Settings["lastDir"] := sel_dir
        ctl.gui["BaseFolder"].Add([sel_dir])
        
    } Else If (ctl.Name = "BaseFolderRemove") {
        If (row := ctl.gui["BaseFolder"].Value)
            ctl.Gui["BaseFolder"].Delete(row)
        
    } Else If (ctl.Name = "Cancel") {
        g2_close(ctl.gui), ctl.gui.Destroy()
    } Else If (ctl.Name = "OK") {
        If (!ctl.gui["ProfileName"].Value Or InStr(ctl.Gui["ProfileName"].Value,"\")) {
            Msgbox "Enter a Profile Name.  It must not contain a backslash (\)."
            return
        } Else If !ctl.gui["BaseFolder"].GetCount() {
            Msgbox "Enter at least one Base Folder."
            return
        } Else If !ctl.gui["OtherDirList"].GetCount() {
            Msgbox "Enter at least one header."
            return
        }
        
        prof := Map(), prof.CaseSense := false ; save settings
        prof["Name"] := ctl.gui["ProfileName"].Value
        prof["BaseFolder"] := ctl.gui["BaseFolder"].GetItems()
        prof["UserConstants"] := ctl.gui["UserConstants"].value
        prof["OtherDirList"] := Settings["MakeProfile"]
        Settings["Recents"][prof["Name"]] := prof
        
        Settings["ApiPath"] := prof["Name"]
        Settings["gui"].Title := "C++ Constants Scanner - " prof["Name"]
        
        Settings["gui"].Menubar := load_menubar()
        
        g2_close(ctl.gui)
        ctl.gui.Destroy()
    }
}

SaveOtherDirList(ctl) {
    SaveArr := []
    Loop ctl.GetCount()
        SaveArr.Push([ctl.Checked(A_Index), ctl.IconIndex(A_Index), ctl.GetText(A_Index)])
    return SaveArr
}

g2_close(g2) {
    Global Settings
    g := Settings["gui"]
    WinActivate "ahk_id " g.hwnd
    WinSetEnabled True, g.hwnd
    Settings["temp_gui"] := {hwnd:0}
    g["NameFilter"].Focus()
    Settings.Delete("MakeProfile")
}

g2_escape(g2) {
    g2_close(g2), g2.Destroy()
}

 