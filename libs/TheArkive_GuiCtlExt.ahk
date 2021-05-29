; ==================================================================
; GuiControl_Ex
; ==================================================================

class ListComboBox_Ext {
    Static __New() {
        For prop in this.Prototype.OwnProps() {
            Gui.ListBox.Prototype.%prop% := this.prototype.%prop%
            Gui.ComboBox.Prototype.%prop% := this.prototype.%prop%
        }
    }
    
    GetCount(p*) { ; p* compensates for additional params when used with ListView
        If (this.Type = "ListBox")
            return SendMessage(0x018B, 0, 0, this.hwnd) ; LB_GETCOUNT
        Else If (this.Type = "ComboBox")
            return SendMessage(0x146, 0, 0, this.hwnd)  ; CB_GETCOUNT
    }
    
    GetText(row,p*) { ; p* compensates for additional params when used with ListView/TreeView
        If (this.Type = "ListBox")
            return this._GetString(0x18A,0x189,row) ; 0x18A > LB_GETTEXTLEN // 0x189 > LB_GETTEXT
        Else if (this.Type = "ComboBox")
            return this._GetString(0x149,0x148,row) ; 0x149 > CB_GETLBTEXTLEN // 0x148 > CB_GETLBTEXT
    }
    
    GetItems(p*) { ; ListBox, ComboBox
        If (this.Type = "ListBox" Or this.Type = "ComboBox") {
            result := []
            Loop this.GetCount()
                result.Push(this.GetText(A_Index))
            return result
        }
    }
    
    _GetString(getLen_msg,get_msg,row) {
        size := SendMessage(getLen_msg, row-1, 0, this.hwnd) ; GETTEXTLEN
        buf := Buffer( (size+1) * (StrLen(Chr(0xFFFF))?2:1), 0 )
        SendMessage(get_msg, row-1, buf.ptr, this.hwnd) ; GETTEXT
        return StrGet(buf)
    }
}

class ListView_Ext extends Gui.ListView { ; Technically no need to extend classes unless
    Static __New() { ; you are attaching new base on control creation.
        For prop in this.Prototype.OwnProps()
            super.Prototype.%prop% := this.Prototype.%prop%
    }
    Checked(row) { ; This was taken directly from the AutoHotkey help files.
        return (SendMessage(4140,row-1,0xF000,, "ahk_id " this.hwnd) >> 12) - 1 ; VM_GETITEMSTATE = 4140 / LVIS_STATEIMAGEMASK = 0xF000
    }
    IconIndex(row,col:=1) { ; from "just me" LV_EX ; Link: https://www.autohotkey.com/boards/viewtopic.php?f=76&t=69262&p=298308#p299057
        LVITEM := Buffer((A_PtrSize=8)?56:40, 0)                   ; create variable/structure
        NumPut("UInt", 0x2, "Int", row-1, "Int", col-1, LVITEM.ptr, 0)  ; LVIF_IMAGE := 0x2 / iItem (row) / column num
        NumPut("Int", 0, LVITEM.ptr, (A_PtrSize=8)?36:28)               ; iImage
        SendMessage(StrLen(Chr(0xFFFF))?0x104B:0x1005, 0, LVITEM.ptr,, "ahk_id " this.hwnd) ; LVM_GETITEMA/W := 0x1005 / 0x104B
        return NumGet(LVITEM.ptr, (A_PtrSize=8)?36:28, "Int")+1 ;iImage
    }
    GetColWidth(n) {
        return SendMessage(0x101D, n-1, 0, this.hwnd)
    }
}

class PicButton extends Gui.Button {
    Static __New() {
        For prop in this.Prototype.OwnProps()
            super.Prototype.%prop% := this.Prototype.%prop%
    }
    SetImg(sFile, sOptions:="") { ; input params exact same as first 2 params of LoadPicture()
        curStyle := ControlGetStyle(this.hwnd)
        ControlSetStyle (curStyle | 0x40), this.hwnd
        hIco := LoadPicture(sFile, sOptions, &type)
        return SendMessage(0xF7, 1, hIco, this.hwnd) ; BM_SETIMAGE
    }
}