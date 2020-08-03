#NoTrayIcon
#Region Compiler directives section
;** This is a list of compiler directives used by CompileAU3.exe.
;** comment the lines you don't need or else it will override the default settings
;#Compiler_Prompt=y              					;y=show compile menu
;** AUT2EXE settings
;#Compiler_AUT2EXE=
#Compiler_Icon=API.ico                  			;Filename of the Ico file to use
;#Compiler_OutFile=              					;Target exe filename.
#Compiler_Compression=4         					;Compression parameter 0-4  0=Low 2=normal 4=High
#Compiler_Allow_Decompile=n      					;y= allow decompile
;#Compiler_PassPhrase=           					;Password to use for compilation
;** Target program Resource info
#Compiler_Res_Comment=Tool to Aid Admins.
#Compiler_Res_Description=Software tool to aid Admins
#Compiler_Res_FileVersion_AutoIncrement=n
#Compiler_Res_Fileversion=1.0.0.1
#Compiler_Res_LegalCopyright=Gary Frost
; free form resource fields ... max 15
#Compiler_Res_Field=Email|custompcs@charter.net 	;Free format fieldname|fieldvalue
#Compiler_Res_Field=Release Date|09/13/2006  		;Free format fieldname|fieldvalue
#Compiler_Res_Field=Update Date|09/15/2006			;Free format fieldname|fieldvalue
#Compiler_Res_Field=Internal Name|APIConstants.exe 	;Free format fieldname|fieldvalue
#Compiler_Res_Field=Status|Release 					;Free format fieldname|fieldvalue
#Compiler_Run_AU3Check=n        					;Run au3check before compilation
; The following directives can contain:
;   %in% , %out%, %icon% which will be replaced by the fullpath\filename.
;   %scriptdir% same as @ScriptDir and %scriptfile% = filename without extension.
#Compiler_Run_Before=           					;process to run before compilation - you can have multiple records that will be processed in sequence
#Compiler_Run_After=move "%out%" "%scriptdir%"  	;process to run After compilation - you can have multiple records that will be processed in sequence
#EndRegion
#include <GUIConstants.au3>
#include <GuiList.au3>
#include <GuiListView.au3>

Opt("MustDeclareVars", 1)

Global $g_szVersion = "        API Constants for AutoIt"
Global $lv_Constants, $lb_Selected, $origHWND, $GUI_APIConstants
Global Const $DebugIt = 0
Global $hMainGUI

If WinExists($g_szVersion) Then Exit ; It's already running
AutoItWinSetTitle($g_szVersion)




Global Const $WM_NOTIFY = 0x004E
Global Const $WM_DRAWCLIPBOARD = 0x0308
Global Const $WM_CHANGECBCHAIN = 0x030D
Global $White = 0xFFFFFF
Global $Black = 0x000000

Global $Constants_Dir = @ScriptDir & "\Constants\"

_Main()

Func _Main()
	Local $cmb_Files, $radio_Local, $radio_Global, $btn_Copy, $btn_Delete, $btn_SelAll, $btn_Exit, $nMsg, $ret
	$hMainGUI = GUICreate($g_szVersion, 643, 270)
	; remember last clip viewer in queue and set our GUI as first in queue
	$origHWND = DllCall("user32.dll", "hwnd", "SetClipboardViewer", "hwnd", $hMainGUI)
	$origHWND = $origHWND[0]

	$cmb_Files = GUICtrlCreateCombo("", 8, 0, 305, 25, BitOR($CBS_SORT, $CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL, $WS_VSCROLL))
	_LoadFileList($cmb_Files)

	$lv_Constants = GUICtrlCreateListView("Constant Name|Value", 8, 24, 305, 238, BitOR($LVS_NOCOLUMNHEADER, $LVS_SHOWSELALWAYS, $LVS_SINGLESEL))
	GUICtrlSendMsg($lv_Constants, $LVM_SETEXTENDEDLISTVIEWSTYLE, $LVS_EX_GRIDLINES, $LVS_EX_GRIDLINES)
	GUICtrlSendMsg($lv_Constants, $LVM_SETEXTENDEDLISTVIEWSTYLE, $LVS_EX_FULLROWSELECT, $LVS_EX_FULLROWSELECT)
	GUICtrlSetBkColor($lv_Constants, $White)
	GUICtrlSetColor($lv_Constants, $Black)

	GUICtrlCreateGroup("", 320, 0, 313, 263)
	$lb_Selected = GUICtrlCreateList("", 328, 16, 297, 188, BitOR($LBS_SORT, $WS_BORDER, $WS_VSCROLL, $WS_HSCROLL, $LBS_NOTIFY, $LBS_MULTIPLESEL))
	_GUICtrlListSetHorizontalExtent($lb_Selected, 600)

	$radio_Local = GUICtrlCreateRadio("Local", 336, 207, 105, 17)
	$radio_Global = GUICtrlCreateRadio("Global", 336, 233, 105, 17)
	GUICtrlSetState($radio_Global, $GUI_CHECKED)

	$btn_Copy = GUICtrlCreateButton("Copy", 465, 215, 50, 20)
	$btn_Delete = GUICtrlCreateButton("Delete", 520, 215, 50, 20)
	$btn_SelAll = GUICtrlCreateButton("Select All", 575, 215, 50, 20)
	$btn_Exit = GUICtrlCreateButton("Exit", 575, 235, 50, 20)
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	GUISetState(@SW_SHOW)

	;Register WM_NOTIFY  events
	GUIRegisterMsg($WM_NOTIFY, "WM_Notify_Events")
	;Register clipboard  events
	GUIRegisterMsg($WM_DRAWCLIPBOARD, "OnClipBoardChange")
	GUIRegisterMsg($WM_CHANGECBCHAIN, "OnClipBoardViewerChange")

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE, $btn_Exit
				Exit
			Case $cmb_Files
				GUISetCursor(15)
				GUICtrlSetCursor($lv_Constants, 15)
				GUICtrlSetCursor($lb_Selected, 15)
				GUICtrlSetCursor($radio_Global, 15)
				GUICtrlSetCursor($radio_Local, 15)
				GUISetState(@SW_LOCK)
				_GUICtrlListViewDeleteAllItems($lv_Constants)
				Local $Constant
				Local $Constants = StringSplit(FileRead($Constants_Dir & GUICtrlRead($cmb_Files) & ".au3"), @CRLF, 1)
				For $x = 1 To $Constants[0]
					$Constant = StringReplace(StringStripWS(StringReplace($Constants[$x], "Const ", "",1), 8), "=", "|")
					GUICtrlCreateListViewItem(StringTrimLeft($Constant, 1), $lv_Constants)
				Next
				_GUICtrlListViewSetColumnWidth($lv_Constants, 0, 285)
				_GUICtrlListViewHideColumn($lv_Constants, 1)
				GUISetState(@SW_UNLOCK)
				GUISetCursor(2)
				GUICtrlSetCursor($lv_Constants, 2)
				GUICtrlSetCursor($lb_Selected, 2)
				GUICtrlSetCursor($radio_Global, 2)
				GUICtrlSetCursor($radio_Local, 2)
			Case $btn_Copy
				$ret = _GUICtrlListGetSelItems($lb_Selected)
				If (Not IsArray($ret)) Then ContinueLoop
				Local $clipboard_string = "", $type = "Global "
				If BitAND(GUICtrlRead($radio_Local), $GUI_CHECKED) = $GUI_CHECKED Then $type = "Local "
				For $x = 1 To $ret[0]
					$clipboard_string &= $type & _GUICtrlListGetText($lb_Selected, $ret[$x]) & @CRLF
				Next
				ClipPut($clipboard_string)
			Case $btn_Delete
				$ret = _GUICtrlListGetSelItems($lb_Selected)
				If (Not IsArray($ret)) Then ContinueLoop
				For $x = $ret[0] To 1 Step - 1
					_GUICtrlListDeleteItem($lb_Selected, $ret[$x])
				Next
			Case $btn_SelAll
				_GUICtrlListSelItemRange($lb_Selected, 1, 0, _GUICtrlListCount($lb_Selected) - 1)
		EndSwitch
	WEnd
EndFunc   ;==>_Main

Func _LoadFileList(ByRef $cmb_Files)
	Local $file, $files = ""
	Local $search = FileFindFirstFile($Constants_Dir & "*.au3")

	; Check if the search was successful
	If $search = -1 Then Return SetError(-1, -1, 0)

	While 1
		$file = FileFindNextFile($search)
		If @error Then ExitLoop
		$files &= StringReplace($file, ".au3", "") & "|"
	WEnd

	; Close the search handle
	FileClose($search)
	GUICtrlSetData($cmb_Files, StringTrimRight($files, 1))
EndFunc   ;==>_LoadFileList

Func ListView_Click()
	;----------------------------------------------------------------------------------------------
	If $DebugIt Then _DebugPrint("$NM_CLICK")
	;----------------------------------------------------------------------------------------------
EndFunc   ;==>ListView_Click

Func ListView_DoubleClick()
	;----------------------------------------------------------------------------------------------
	If $DebugIt Then _DebugPrint("$NM_DBLCLK")
	;----------------------------------------------------------------------------------------------
	If _GUICtrlListViewGetItemCount($lv_Constants) > 0 Then _
	GUICtrlSetData($lb_Selected, "Const $" & _
			StringReplace(_GUICtrlListViewGetItemText($lv_Constants, _GUICtrlListViewGetSelectedIndices($lv_Constants)), "|", " = "), "|")
EndFunc   ;==>ListView_DoubleClick

;
; WM_NOTIFY event handler
Func WM_Notify_Events($hWndGUI, $MsgID, $wParam, $lParam)
	Local Const $NM_FIRST = 0
	Local Const $NM_CLICK = ($NM_FIRST - 2)
	Local Const $NM_DBLCLK = ($NM_FIRST - 3)
	#forceref $hWndGUI, $MsgID, $wParam
	Local $tagNMHDR, $event
	$tagNMHDR = DllStructCreate("int;int;int", $lParam) ;NMHDR (hwndFrom, idFrom, code)
	If @error Then Return
	$event = DllStructGetData($tagNMHDR, 3)
	Select
		Case $wParam = $lv_Constants
			Select
				Case $event = $NM_CLICK
					ListView_Click()
				Case $event = $NM_DBLCLK
					ListView_DoubleClick()
			EndSelect
	EndSelect
	$tagNMHDR = 0
	$event = 0
	$lParam = 0
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_Notify_Events

Func OnClipBoardChange($hWnd, $nMsg, $wParam, $lParam)
	#forceref $hWnd, $nMsg
	; send notification about clipboard change to next clipviewer
	DllCall("user32.dll", "int", "SendMessage", "hWnd", $origHWND, "int", $WM_DRAWCLIPBOARD, "int", $wParam, "int", $lParam)
EndFunc   ;==>OnClipBoardChange

Func OnClipBoardViewerChange($hWnd, $nMsg, $wParam, $lParam)
	#forceref $hWnd, $nMsg
	; if our remembered previous clipviewer is removed then we must remember new next clipviewer
	; else send notification about clipviewr change to next clipviewer
	If $wParam = $origHWND Then
		$origHWND = $lParam
	Else
		DllCall("user32.dll", "int", "SendMessage", "hWnd", $origHWND, "int", $WM_CHANGECBCHAIN, "hwnd", $wParam, "hwnd", $lParam)
	EndIf
EndFunc   ;==>OnClipBoardViewerChange

Func OnAutoItExit()
	;----------------------------------------------------------------------------------------------
	If $DebugIt Then _DebugPrint("OnAutoItExit")
	;----------------------------------------------------------------------------------------------
	; send notification that we no longer will be in clipboard hook queue
	If $origHWND <> "" Then DllCall("user32.dll", "int", "ChangeClipboardChain", "hwnd", $hMainGUI, "hwnd", $origHWND)
EndFunc   ;==>OnAutoItExit

Func _DebugPrint($s_text)
	ConsoleWrite( _
			"!===========================================================" & @LF & _
			"+===========================================================" & @LF & _
			"-->" & $s_text & @LF & _
			"+===========================================================" & @LF)
EndFunc   ;==>_DebugPrint