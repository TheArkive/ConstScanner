; ==================================================================
; GuiControl_Ex
; ==================================================================

__w(ctl) {                  ; A short wrapper function, use in place of gCtl.New() when manually wrapping the control.
    return gCtl.New(ctl)    ; All this does is allow the user to be a bit more lazy.
}

Global __current_gui_control ; change this var to whatever you want, and change it throughout this script.
class gui2 extends gui2._gui_important_stuff {  ; Gui - place custom methods() and properties[] in main class.
    class _gui_important_stuff extends gui { ; put the important stuff out of the way
        __New(opt:="", title:="", EventObj:="") {
            super.__New(opt, title, (EventObj="this")?this:EventObj) ; Specifying Gui2.New(..., ..., "this") will use the Gui2 class as the "event sink"
        }
        __Item[key] { ; Wrap/pass on GuiControl obj when using gui["control"]
            get => gCtl.New(super[key])
        }
        Add(p*) { ; type, options:="", value:="" ; p* ; GuiObj.Add(...)
            return gCtl.New(super.Add(p*)) ; type, options, value
        }
    }
}

class gCtl extends gCtl.GuiControl { ; GuiControls - place custom methods() and properties[] in main class.

    Checked(row) { ; ListView
        ctl := __current_gui_control
        If (ctl.Type = "ListView") ; This was taken directly from the AutoHotkey help files.
            return (SendMessage(4140,row-1,0xF000,, "ahk_id " ctl.hwnd) >> 12) - 1 ; VM_GETITEMSTATE = 4140 / LVIS_STATEIMAGEMASK = 0xF000
    }
    
    GetCount(p*) { ; ListView, TreeView, ListBox, ComboBox
        ctl := __current_gui_control
        If (ctl.Type = "ListView" Or ctl.Type = "TreeView") ; original functionality for TreeView / ListView
            return ctl.GetCount(p*)
        Else If (ctl.Type = "ListBox")
            return SendMessage(0x018B, 0, 0, ctl.hwnd) ; LB_GETCOUNT
        Else If (ctl.Type = "ComboBox")
            return SendMessage(0x146, 0, 0, ctl.hwnd) ; CB_GETCOUNT
    }
    
    IconIndex(row,col:=1) { ; ListView
        ctl := __current_gui_control
        If (ctl.Type = "ListView") { ; from "just me" LV_EX ; Link: https://www.autohotkey.com/boards/viewtopic.php?f=76&t=69262&p=298308#p299057
            LVITEM := BufferAlloc((A_PtrSize=8)?56:40, 0)                   ; create variable/structure
            NumPut("UInt", 0x2, "Int", row-1, "Int", col-1, LVITEM.ptr, 0)  ; LVIF_IMAGE := 0x2 / iItem (row) / column num
            NumPut("Int", 0, LVITEM.ptr, (A_PtrSize=8)?36:28)               ; iImage
            SendMessage(StrLen(Chr(0xFFFF))?0x104B:0x1005, 0, LVITEM.ptr,, "ahk_id " ctl.hwnd) ; LVM_GETITEMA/W := 0x1005 / 0x104B
            return NumGet(LVITEM.ptr, (A_PtrSize=8)?36:28, "Int")+1 ;iImage
        }
    }
    
    GetItems() { ; ListBox, ComboBox
        ctl := __current_gui_control, result := []
        If (ctl.Type = "ListBox" Or ctl.Type = "ComboBox") {
            Loop this.GetCount()
                result.Push(this.GetText(A_Index))
            return result
        }
    }
    
    GetText(p*) { ; ListView, TreeView, ListBox, ComboBox
        ctl := __current_gui_control
        If (ctl.Type = "TreeView" Or ctl.Type = "ListView")
            return ctl.GetText(p*)
        Else If (ctl.Type = "ListBox")
            return this._GetString(0x18A,0x189,p*) ; 0x18A > LB_GETTEXTLEN // 0x189 > LB_GETTEXT
        Else if (ctl.Type = "ComboBox")
            return this._GetString(0x149,0x148,p*) ; 0x149 > CB_GETLBTEXTLEN // 0x148 > CB_GETLBTEXT
    }
    
    _GetString(getLen_msg,get_msg,p*) {
        ctl := __current_gui_control, n := StrLen(Chr(0xFFFF))?2:1
        size := SendMessage(getLen_msg, p[1]-1, 0, ctl.hwnd) ; LB_GETTEXTLEN
        buf := BufferAlloc( (size+1) * n, 0 )
        SendMessage(get_msg, p[1]-1, buf.ptr, ctl.hwnd) ; LB_GETTEXT
        return StrGet(buf)
    }
    
    class GuiControl {
        __New(ctl) {
            __current_gui_control := ctl
        }
        __Get(key,p) {
            return __current_gui_control.%key%
        }
        __Set(key,p,value) {
            __current_gui_control.%key% := value
        }
        __Call(key,p) {
            If key = "__Init" { ; This is only for preventing an error when __Init fires.
                return
            } Else If key = "GetPos" {                      ; ByRef treatment doesn't wrap well.
                __current_gui_control.GetPos(x, y, w, h)    ; Switching back to returning an obj.
                return {x:x, y:y, w:w, h:h}
            } Else If key {
                return __current_gui_control.%key%(p*)
            }
        }
        gui[item := ""] { ; need this to properly handle .gui member of GuiControl
            get => (item="") ? __current_gui_control.gui : __current_gui_control.gui[item]
        }
    }
}