; ==================================================================
; GuiControl_Ex
; ==================================================================


class gui_control_ex extends Gui.Control {
    Static __New() {
        super.prototype.GetCount := ObjBindMethod(this,"GetCount")
        super.prototype.GetText  := ObjBindMethod(this,"GetText")
        super.prototype.GetItems := ObjBindMethod(this,"GetItems")
        super.prototype.Checked := ObjBindMethod(this,"Checked")
        super.prototype.IconIndex := ObjBindMethod(this,"IconIndex")
    }
    
    Static Checked(ctl,row) { ; ListView
        If (ctl.Type = "ListView") ; This was taken directly from the AutoHotkey help files.
            return (SendMessage(4140,row-1,0xF000,, "ahk_id " ctl.hwnd) >> 12) - 1 ; VM_GETITEMSTATE = 4140 / LVIS_STATEIMAGEMASK = 0xF000
    }
    
    Static GetCount(ctl,p*) { ; p* compensates for additional params when used with ListView
        If (ctl.Type = "ListBox")
            return SendMessage(0x018B, 0, 0, ctl.hwnd) ; LB_GETCOUNT
        Else If (ctl.Type = "ComboBox")
            return SendMessage(0x146, 0, 0, ctl.hwnd) ; CB_GETCOUNT
    }
    
    Static GetText(ctl,row,p*) { ; p* compensates for additional params when used with ListView/TreeView
        If (ctl.Type = "ListBox")
            return this._GetString(ctl,0x18A,0x189,row) ; 0x18A > LB_GETTEXTLEN // 0x189 > LB_GETTEXT
        Else if (ctl.Type = "ComboBox")
            return this._GetString(ctl,0x149,0x148,row) ; 0x149 > CB_GETLBTEXTLEN // 0x148 > CB_GETLBTEXT
    }
    
    Static GetItems(ctl,p*) { ; ListBox, ComboBox
        If (ctl.Type = "ListBox" Or ctl.Type = "ComboBox") {
            result := []
            Loop ctl.GetCount()
                result.Push(ctl.GetText(A_Index))
            return result
        }
    }
    
    Static IconIndex(ctl,row,col:=1) { ; ListView
        If (ctl.Type = "ListView") { ; from "just me" LV_EX ; Link: https://www.autohotkey.com/boards/viewtopic.php?f=76&t=69262&p=298308#p299057
            LVITEM := BufferAlloc((A_PtrSize=8)?56:40, 0)                   ; create variable/structure
            NumPut("UInt", 0x2, "Int", row-1, "Int", col-1, LVITEM.ptr, 0)  ; LVIF_IMAGE := 0x2 / iItem (row) / column num
            NumPut("Int", 0, LVITEM.ptr, (A_PtrSize=8)?36:28)               ; iImage
            SendMessage(StrLen(Chr(0xFFFF))?0x104B:0x1005, 0, LVITEM.ptr,, "ahk_id " ctl.hwnd) ; LVM_GETITEMA/W := 0x1005 / 0x104B
            return NumGet(LVITEM.ptr, (A_PtrSize=8)?36:28, "Int")+1 ;iImage
        }
    }
    
    Static _GetString(ctl,getLen_msg,get_msg,row) {
        size := SendMessage(getLen_msg, row-1, 0, ctl.hwnd) ; GETTEXTLEN
        buf := BufferAlloc( (size+1) * (StrLen(Chr(0xFFFF))?2:1), 0 )
        SendMessage(get_msg, row-1, buf.ptr, ctl.hwnd) ; GETTEXT
        return StrGet(buf)
    }
}

