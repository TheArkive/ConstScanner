extra_dirs() {
    Global Settings
    g2 := Gui("-MinimizeBox -MaximizeBox +Owner" app.mainGUI.hwnd,"Other Files (grouped with primary C++ Source File)")
    g2.OnEvent("close",g2_close)
    g2.OnEvent("escape",g2_escape)
    
    ctl := g2.Add("Text","xm Section","Profile Name:")
    g2.Add("Edit","x80 yp-4 w400 vProfileName")
    ctl := g2.Add("DropDownList","x+0 w60 vCompType",["WIN32","GCC"])
    ctl.Text := "WIN32"
    
    g2.Add("Text","xs y+10","Base Folders:")
    ctl := g2.Add("ListBox","x+6 yp-4 w495 r3 vBaseFolder")
    ctl.OnEvent("ContextMenu",gui_events2b)
    ctl.OnEvent("DoubleClick",gui_events2)
    
    g2.Add("Button","x+0 w30 h20 vBaseFolderAdd","...").OnEvent("click",gui_events2)
    g2.Add("Button","xp y+0 wp h23 vBaseFolderRemove","X").OnEvent("click",gui_events2)
    
    g2.Add("Text","xs y+10","Constants:")
    ctl := g2.Add("Edit","x+20 yp-4 w495 r3 vUserConstants")
    ctl.SetFont(,"Consolas")
    
    g2.Add("Text","xs y+10","Macros:")
    ctl := g2.Add("Edit","x+32 yp-4 w495 r3 vUserMacros")
    ctl.SetFont(,"Consolas")
    
    g2.Add("Text","xs y+10","Add Includes/Folders (paste list here - * wildcard * patterns optional)")
    ctl := g2.Add("Edit","xs y+5 r3 w560 vOtherDir")
    ctl.SetFont(,"Consolas")
    
    g2.Add("Button","x+0 w40 h23 vAddOtherDir","Add").OnEvent("click",gui_events2)
    g2.Add("Button","xp y+0 w40 h24 vListFiles","List").OnEvent("click",gui_events2)
    
    g2.Add("Text","xs y+20","Includes List")
    g2.Add("Text","x+140 w100 Right","Search:")
    g2.Add("Edit","x+5 yp-4 w265 vSearch").OnEvent("change",gui_events2)
    g2.Add("Button","x+0 w30 vClearSearch","X").OnEvent("click",gui_events2)
    
    IL := IL_Create(2), IL_Add(IL, "icons\check.ico"), IL_Add(IL, "icons\X.ico") ; check, X
    
    Settings["MakeProfile"] := []
    ctl := g2.Add("ListView","xs y+0 w600 r10 Checked Count20 vOtherDirList Multi",["WildPath"])
    ctl.SetFont(,"Consolas")
    ctl.OnEvent("ContextMenu",gui_events2b), ctl.SetImageList(IL)
    ctl.OnEvent("ItemCheck",g2_check_event)
    ctl.ModifyCol(1,570)
    
    g2.AddPicButton("xm y+10 w24 h24 vMoveUp","icons\up.ico","w16 h16").OnEvent("click",gui_events2)
    g2.AddPicButton("x+0 w24 h24 vMoveDown","icons\down.ico","w16 h16").OnEvent("click",gui_events2)
    g2.Add("Button","x+10 yp h24 vCleanIncludes","Clean Includes List").OnEvent("click",gui_events2)
    
    g2.Add("Checkbox","xm y+10 vProcIncludes","Process #INCLUDEs").OnEvent("click",gui_events2)
    g2.Add("Checkbox","x+10 yp vProcGlobals","Process Globals").OnEvent("click",gui_events2)
    g2.Add("Checkbox","x+10 yp vProcGlobalCache Section","Load Global cache:").OnEvent("click",gui_events2)
    ctl := g2.Add("Edit","x+5 yp-4 w215 vGlobCacheFile")
    ctl.SetFont(,"Consolas")
    ctl.OnEvent("change",gui_events2)
    g2.Add("Button","x+0 yp vGlobCacheFilePick","...").OnEvent("click",gui_events2) ; GlobCacheFile
    g2.Add("Checkbox","xs y+10 vMakeGlobalCache","Create Global cache").OnEvent("click",gui_events2)
    
    g2.Add("Button","x460 y+20 w75 h24 vOK","OK").OnEvent("click",gui_events2)
    g2.Add("Button","x+0 w75 hp vCancel","Cancel").OnEvent("click",gui_events2)
    
    g2.Show()
    
    app.temp_gui := g2
    
    WinSetEnabled False, app.mainGUI.hwnd
    
    If Settings["Recents"].Has(app.ApiPath) {
        rec := Settings["Recents"][app.ApiPath]
        
        g2["ProfileName"].Value := rec["Name"]
        g2.old_name := rec["Name"]
        g2["BaseFolder"].Add(rec["BaseFolder"])
        
        (rec.Has("UserConstants"))   ? g2["UserConstants"].value   := rec["UserConstants"] : ""
        (rec.Has("UserMacros"))      ? g2["UserMacros"].value      := rec["UserMacros"] : ""
        (rec.Has("ProcIncludes"))    ? g2["ProcIncludes"].value    := rec["ProcIncludes"] : ""
        (rec.Has("ProcGlobals"))     ? g2["ProcGlobals"].Value     := rec["ProcGlobals"] : ""
        (rec.Has("ProcGlobalCache")) ? g2["ProcGlobalCache"].Value := rec["ProcGlobalCache"] : ""
        (rec.Has("GlobCacheFile"))   ? g2["GlobCacheFile"].Value   := rec["GlobCacheFile"] : ""
        (rec.Has("MakeGlobalCache")) ? g2["MakeGlobalCache"].Value := rec["MakeGlobalCache"] : ""
        (rec.Has("CompType"))        ? g2["CompType"].Text         := rec["CompType"] : ""
        
        If !g2["ProcGlobalCache"].Value {
            g2["GlobCacheFile"].Enabled := g2["GlobCacheFilePick"].Enabled := false
            g2["MakeGlobalCache"].Enabled := true
        }
        
        If !g2["ProcGlobals"].Value {
            g2["ProcGlobalCache"].Enabled := g2["GlobCacheFile"].Enabled := false
            g2["GlobCacheFilePick"].Enabled := g2["MakeGlobalCache"].Enabled := false
        }
        
        Settings["MakeProfile"] := rec["OtherDirList"].Clone()
        populate_OtherDirList(g2)
    }
}

populate_OtherDirList(g) {
    Global Settings
    
    LV := g["OtherDirList"]
    LV.Delete()
    LV.Opt("-Redraw")
    
    list := Settings["MakeProfile"]
    For row in list
        LV.Add((row[1]?"Check ":"") "Icon" row[2],row[3])
    
    LV.Opt("+Redraw")
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
    Settings["MakeProfile"][row][1] := c
}

gui_events2(ctl,info) {
    Global Settings
    other_dirs := []
    g := ctl.gui
    LV := g["OtherDirList"]
    
    If (ctl.Name = "AddOtherDir") {
        If !g["OtherDir"].Value {
            Msgbox "Nothing to add!"
            return
        } Else If !g["BaseFolder"].GetItems() {
            Msgbox "Select Base Folder first."
            return
        }
        
        v := Trim(StrReplace(g["OtherDir"].Value,Chr(34),""),"`r`n`t ")
        a := StrSplit(v,"`n","`r")
        
        LV.Opt("-Redraw")
        For path in a {
            path := Trim(path,"`t ")
            (!FileExist(path)) ? path := get_full_path(path,g["BaseFolder"].GetItems()) : ""
            If (path) {
                go := true
                Loop LV.GetCount() { ; check for dupes
                    If (LV.GetText(A_Index) = path) {
                        go := false
                        Break
                    }
                }
                
                go ? LV.Add("Icon1",path) : ""
            }
        }
        
        LV.Opt("+Redraw")
        g["OtherDir"].Value := ""
        g["OtherDir"].Focus()
        Settings["MakeProfile"] := SaveOtherDirList(LV)
        g["Search"].Value := ""
        
    } Else If (ctl.Name = "Search") {
        LV.Opt("-Redraw")
        LV.Delete()
        For item in Settings["MakeProfile"]
            If ((ctl.Value != "") And InStr(item[3],ctl.Value)) Or (ctl.Value = "")
                LV.Add((item[1]?"Check ":"") "Icon" item[2],item[3])
        LV.Opt("+Redraw")
        
    } Else If (ctl.Name = "ClearSearch") {
        g["Search"].Value := ""
        LV.Opt("-Redraw")
        LV.Delete()
        For item in Settings["MakeProfile"]
            If ((ctl.Value != "") And InStr(item[3],ctl.Value)) Or (ctl.Value = "")
                LV.Add((item[1]?"Check ":"") "Icon" item[2],item[3])
        LV.Opt("+Redraw")
    
    } Else If (ctl.Name = "BaseFolder") {
        ctl.Delete(ctl.Value)
    
    } Else If (ctl.Name = "BaseFolderAdd") {
        SplitPath Settings["lastDir"],, &dir
        sel_dir := FileSelect("D2", dir, "Select Base Folder")
        If !sel_dir
            return
        Settings["lastDir"] := sel_dir
        g["BaseFolder"].Add([sel_dir])
        
    } Else If (ctl.Name = "BaseFolderRemove") {
        If (row := g["BaseFolder"].Value)
            g["BaseFolder"].Delete(row)
        
    } Else If (ctl.Name = "Cancel") {
        g2_close(g), g.Destroy()
        
    } Else If (ctl.Name = "OK") {
        If (!g["ProfileName"].Value Or InStr(g["ProfileName"].Value,"\")) {
            Msgbox "Enter a Profile Name.  It must not contain a backslash (\)."
            return
        } Else If !g["BaseFolder"].GetCount() {
            Msgbox "Enter at least one Base Folder."
            return
        }
        
        prof := Map(), prof.CaseSense := false ; save settings
        prof["Name"] := g["ProfileName"].Value
        prof["BaseFolder"] := g["BaseFolder"].GetItems()
        prof["UserConstants"] := g["UserConstants"].value
        prof["UserMacros"] := g["UserMacros"].value
        prof["OtherDirList"] := Settings["MakeProfile"]
        prof["ProcIncludes"] := g["ProcIncludes"].Value
        prof["ProcGlobals"] := g["ProcGlobals"].Value
        prof["ProcGlobalCache"] := g["ProcGlobalCache"].Value
        prof["GlobCacheFile"] := g["GlobCacheFile"].Value
        prof["MakeGlobalCache"] := g["MakeGlobalCache"].Value
        prof["CompType"] := g["CompType"].Text
        
        Settings["Recents"].Delete(g.old_name)
        Settings["Recents"][prof["Name"]] := prof
        
        app.ApiPath := prof["Name"]
        app.mainGUI.Title := "C++ Constants Scanner - " prof["Name"]
        
        app.mainGUI.Menubar := load_menubar()
        
        g2_close(g)
        g.Destroy()
        
    } Else if (ctl.Name = "ListFiles") {
        start := (g["BaseFolder"].GetItems())[1]
        If !(dir := FileSelect("D2",start,"Select folder to scan:"))
            return
        
        obj := Inputbox("Input wildcard file pattern:","List Files",,"*.h")
        If (obj.result = "OK") {
            list := ""
            Loop Files dir "\" obj.value, "R"
                list .= (list?"`r`n":"") dir "\" A_LoopFileName
            g["OtherDir"].Value .= "`r`n" list
        }
        
    } Else If (ctl.Name = "MoveUp") || (ctl.Name = "MoveDown") {
        If (row := LV.GetNext()) && (LV.GetCount("S") == 1) {
            mv := SubStr(ctl.Name,5)
            item := Settings["MakeProfile"][row]
            total := Settings["MakeProfile"].Length
            
            new_row := (mv = "Up") ? row-1 : row+1
            
            If (new_row=0 || new_row>total)
                return
            
            Settings["MakeProfile"].RemoveAt(row)
            Settings["MakeProfile"].InsertAt(new_row,item)
            LV.Delete(row)
            LV.Insert(new_row,(item[1]?"Check ":"") "Icon" item[2],item[3])
            LV.Modify(new_row,"Vis")
            ; populate_OtherDirList(g)
            LV.Modify(new_row,"Select")
            
        } Else {
            Msgbox "Select one item to move."
            return
        }
        
    } Else If (ctl.Name = "CleanIncludes") {
        msg := "Prevent double-scanning of #INCLUDEs in listed files?`n`n"
             . "Any file that is declared in an #INCLUDE statement will have the status icon changed to a 'red X'.  "
             . "This will prevent the file from being scanned twice.  All files with a green check icon will be scanned.`n`n"
             . "NOTE:  This 'cleaning' process does not do a deep scan, and will not scan into Global #INCLUDEs."
        If (MsgBox(msg,"Clean #includes",4) != "Yes")
            return
        
        file_list := [], rem_list := []
        For i, obj in Settings["MakeProfile"] {
            Loop Parse FileRead(obj[3]), "`n", "`r"
                If (obj[2]==1 && RegExMatch(A_LoopField,'#include[ \t]+"?<?([\w\.]+)>?"?',&m))
                    If !dupe_item_check(file_list,m[1])
                        file_list.Push(m[1])
        }
        
        For i, _file in file_list {
            For i, obj in Settings["MakeProfile"] {
                SplitPath obj[3], &outFile
                if (_file = outFile) {
                    Settings["MakeProfile"][i][2] := 2
                    Break
                }
            }
        }
        
        new_prof := []
        For i, obj in Settings["MakeProfile"]
            If obj[2] != 2
                new_prof.Push(obj)
        
        For i, obj in Settings["MakeProfile"]
            If (obj[2] = 2)
                new_prof.Push(obj)
        
        Settings["MakeProfile"] := new_prof
        
        populate_OtherDirList(g)
        
    } Else if (ctl.Name = "GlobCacheFilePick") {
        If (sFile := FileSelect("1",A_ScriptDir "\cache"),"Select cache file:") {
            SplitPath sFile, &cache_file
            g["GlobCacheFile"].Value := cache_file
        }
    
    } Else If (ctl.Name = "ProcGlobalCache") {
        g["GlobCacheFile"].Enabled := g["GlobCacheFilePick"].Enabled := ctl.Value
        
        If g["ProcGlobalCache"].Value
            g["MakeGlobalCache"].Value := false
        
    } Else If (ctl.Name = "MakeGlobalCache") {
        g["ProcGlobalCache"].Value := false
        g["GlobCacheFile"].Enabled := g["GlobCacheFilePick"].Enabled := false
        
    } Else If (ctl.Name = "ProcGlobals") {
        g["ProcGlobalCache"].Enabled := g["MakeGlobalCache"].Enabled := ctl.Value
        If g["ProcGlobalCache"].Value
            g["GlobCacheFile"].Enabled := g["GlobCacheFilePick"].Enabled := ctl.Value
        
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
    WinActivate "ahk_id " app.mainGUI.hwnd
    WinSetEnabled True, app.mainGUI.hwnd
    app.temp_gui := {hwnd:0}
    app.mainGUI["NameFilter"].Focus()
    Settings.Delete("MakeProfile")
}

g2_escape(g2) {
    g2_close(g2), g2.Destroy()
}

 