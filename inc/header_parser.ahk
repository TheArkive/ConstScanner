includes_report() {
    root := g["ApiPath"].Text
    SplitPath root, file, dir
    IncludesList := Map()
    Static q := Chr(34)
    
    Loop Files dir "\*.h", "R"
    {
        fileTxt := FileRead(A_LoopFileFullPath)
        a := StrSplit(fileTxt,"`n","`r")
        IncludesList[A_LoopFileName] := []
        
        For i, line in a {
            rg1 := "i)^\#include[ `t]+(<|\" q ")([^>" q "]+)(>|\" q ")"
            
            If RegExMatch(line,rg1,m) {
                cur_incl := StrReplace(m.Value(2),"/","\")
                IncludesList[A_LoopFileName].Push(cur_incl)
            }
        }
        
        If (IncludesList[A_LoopFileName].Length = 0)
            IncludesList.Delete(A_LoopFileName)
    }
    
    incl_report()
}

dupe_item_check(inArr,inValue) {
    For i, d in inArr
        If d = inValue
            return true
    return false
}

header_parser() {
    Static q := Chr(34)
    
    root := g["ApiPath"].Text, calcListTotal := 0, calcListCount := 1, d := StrReplace(root,"\","|")
    If Settings.Has("dirs") And Settings["dirs"].Has(d) {
        all_files := Settings["dirs"][d]["all"]
        other_dirs := Settings["dirs"][d]["files"]
    } Else all_files := false
    
    If (!root Or !FileExist(root)) {
        Msgbox "Specify the C++ Source File first."
        return
    }
    
    If all_files
        MsgBox "*** WARNING ***`r`n`r`nScanning ALL headers in the source folder has a likelyhood of creating duplicate values."
    
    SplitPath root, fileName, rootDir
    Loop Files rootDir "\*.h", "R"
        fCount := A_Index
    
    const_list := Map()
    IncludesList := []
    
    If !all_files
        IncludesList := [root]
    Else {
        Loop Files rootDir "\*.h", "R"
            IncludesList.Push(A_LoopFileFullPath)
    }
    
    For oDir in other_dirs ; maybe include error handling here, and allow relative paths in Other Dirs window
        IncludesList.Push(oDir)
    
    prog := progress2.New(0,fCount,"title:Scanning files...,mainText:0 of " fCount)
    rg1 := "i)^\#include[ `t]+(<|\" q ")([^>" q "]+)(>|\" q ")"
    rg2 := "i)^#define[ `t]+(\w+)[ `t]+(.+)"
    
    Loop { ; try reading and populating the loop simultaneously
        do_continue := false
        If !IncludesList.Has(A_Index)
            Break
        
        fullPath := IncludesList[A_Index]
        SplitPath fullPath, file
        
        prog.Update(A_Index,A_Index " of " fCount,file)
        
        fText := FileRead(fullPath)
        fArr := StrSplit(fText,"`n","`r")
        
        cnt := 1
        For i, curLine in fArr {
            constValue := "" ; init value
            cnt := 1 ; counter for more lines
            If (RegExMatch(curLine,rg1,m)) { ; include line
                If !FileExist(m.Value(2))
                    cur_incl := get_full_path(StrReplace(m.Value(2),"/","\"))
                else cur_incl := m.Value(2)
                If (!dupe_item_check(IncludesList,cur_incl) And cur_incl != "")
                    IncludesList.Push(cur_incl)
            } Else If (RegExMatch(curLine,rg2,m)) {
                constName := m.Value(1), constExp := m.Value(2)
                
                comment := ""
                If (RegExMatch(constExp,"([ `t]*//.*|[ `t]*/\*.*)",m2)) {
                    comment := Trim(m2.Value(0)," `t")
                    constExp := RegExReplace(constExp,"([ `t]*//.*|[ `t]*/\*.*?\*/)","")
                    constExp := RegExReplace(constExp,"[ `t]*/\*.*","")
                }
                
                nextLine := fArr[i+cnt]
                While (SubStr(constExp,-1) = "\") {
                    nextLine := RegExReplace(nextLine,"([ `t]*//.*|[ `t]*/\*.*?\*/)","")
                    nextLine := RegExReplace(nextLine,"[ `t]*/\*.*","")
                    
                    constExp := SubStr(constExp,1,-1) . nextLine
                    cnt++, nextLine := fArr[i+cnt]
                }
                
                constExp := RegExReplace(Trim(constExp," `t"),"[ ]{2,}"," ")
                If (InStr(constExp,"//") = 1) ; this is a comment, not a value/expression!
                    constExp := ""
                 
                cType := "Unknown"
                If RegExMatch(constExp,"^TEXT\x28.*([\" q "|']+).*\x29$") Or RegExMatch(constExp,"^\x28? ?L\" q)
                    cType := "String"
                Else If InStr(constExp,"#") Or (InStr(constExp,"{") And InStr(constExp,"}")) Or InStr(constExp,"=") Or InStr(constExp,";")  ; chars indicating NOT an expr
                                       Or InStr(constExp,",") Or (constExp = "")
                                       Or ("_" constName = constExp)                                                                        ; constExpr = _ + constName
                                       Or RegExMatch(constExp,"\x28 *" constName " *\x29")
                                       Or (constName "A" = constExp Or constName "W" = constExp Or constName "0" = constExp) ; Or constName "_W" = constExp Or constName "_A" = constExp)
                                       Or (SubStr(constExp,-1) = "*")
                                       Or (InStr(constExp,"enum ") = 1 Or InStr(constExp,"struct ") = 1)
                                       Or RegExMatch(constExp,"i)^[A-F0-9]{8}\-[A-F0-9]{4}\-[A-F0-9]{4}\-[A-F0-9]{4}\-[A-F0-9]{12}$")       ; 47065EDC-D7FE-4B03-919C-C4A50B749605
                                       Or RegExMatch(constExp,"^[a-zA-Z_]+\x28.*([\" q "|#|\,]+).*\x29$")                                   ; function-like with invalid chars / NOT expr
                    cType := "Other"
                Else If InStr(constExp,Chr(34)) Or InStr(constExp,"'")
                    cType := "String"
                
                item := Map("exp",constExp,"comment",comment,"file",file,"line",i,"value",constExp,"type",cType)
                
                If (!const_list.Has(constName))
                    const_list[constName] := item
                Else {
                    If checkDupeConst(const_list[constName],item) {
                        (!const_list[constName].Has("dupe")) ? const_list[constName]["dupe"] := [] : ""
                        const_list[constName]["dupe"].Push(item)
                    }
                }
            }

        }
    }
    prog.Close()
    
    
    
    
    
    prevList := ""
    Loop {
        curList := reparse1a(A_Index)
        If (curList = prevList or curList = "")
            Break
        prevList := curList
    }
    
    
    
    
    
    
    ; calcList := reparse2a() "`r`necho " Chr(34) "_quit_now_" Chr(34)
    ; c := cli.New("cmd /K powershell","mode:spr"), c.QuitString := "_quit_now_"
    ; c.write(calcList)
    
    ; Mprog := progress2.New(0,calcListTotal,"title:Calculating...")
    ; test ================================
    
    
    
    
    
    
    reparse6()
    relist_const()
    UnlockGui(true)
}

QuitCallback(quitString,ID,CLIobj) {
    Mprog.Close()
    relist_const()
    UnlockGui(true)
    
    If (calcErrorList)
        MsgBox "The following constants had errors during calculation:`r`n`r`n" calcErrorList "`r`n`r`n"
             . "Please look up these constants, find them in the source code, and inspect for errors."
    calcErrorList := ""
}

PromptCallback(prompt,ID,o) {
    If !o.ready
        o.stdout := ""
    Else {
        d := StrReplace(o.stdout,"`r`n",""), errMsg := d
        cmd := StrSplit(o.command,Chr(34))
        const := Trim(cmd[2],":")
        
        s := InStr(d,":"), const2 := SubStr(d,1,s-1), value := SubStr(d,s+1)
        Mprog.Update(calcListCount,const,calcListCount " of " calcListTotal), calcListCount++
        
        If !const_list.Has(const2)
            calcErrorList .= const "`r`n"
        Else
            const_list[const]["value"] := value, const_list[const]["type"] := "integer"
        o.stdout := ""
    }
}

; reparse2a() { ; prepare batch of commands for calculating constants in PowerShell
    ; Static q := Chr(34)
    ; t := 0, i := 0, bigChunk := ""
    
    ; For const, obj in const_list
        ; If (obj["type"] = "expr")
            ; i++
    
    ; prog := progress2.New(0,i,"title:Preparing Calculations List...")
    ; prog.Update(A_Index,"Reparse 3 - Pass #1")
    
    ; batchCmd := ""
    
    ; For const, obj in const_list {
        ; If (obj["type"] = "expr") {
            ; t++
            ; prog.Update(t,const,t " of " i)
            ; curConst := const
            ; curVal := obj["value"]
            
            ; If IsInteger(curVal) {
                ; const_list[const]["value"] := Integer(curVal)
                ; Continue
            ; } Else If (curval = "")
                ; Continue
            
            ; res := eval(curVal)
            ; const_list[const]["value"] := res
            
            ; mathExp := eval_simple(curVal)
            
            ; If mathExp != ""
                ; bigChunk .= "echo " Chr(34) const ":" Chr(34) " " mathExp "`r`n", calcListTotal += 1
        ; }
    ; }
    
    ; prog.close()
    
    ; return Trim(bigChunk,"`r`n ")
; }

; eval_simple(mathStr) { ; chr 65-90 or 97-122
    ; If IsInteger(mathStr)
        ; return Integer(mathStr)
    ; Else If mathStr = "" Or InStr(mathStr,Chr(34))
        ; return ""
    
    ; calc_test := eval(mathStr)
    
    ; mathStr := StrReplace(StrReplace(calc_test,"< <","<<"),"> >",">>")
    ; mathStr := StrReplace(StrReplace(StrReplace(mathStr,"^"," -bxor "),"&"," -band "),"|"," -bor ")
    ; mathStr := StrReplace(StrReplace(StrReplace(mathStr,"<<"," -shl "),">>"," -shr "),"~"," -bnot ")

    ; return "(" mathStr ")"
; }

reparse1a(pass) { ; constants that point to a single constant / any type
    t := 0, list := ""
    prog := progress2.New(0,const_list.Count,"title:Calculating Constants...")
    prog.Update(A_Index,"Pass #" pass)
    
    For const, obj in const_list {
        prog.Update(A_Index,,const)
        
        If (obj["type"] = "unknown") {
            obj := do_subs(obj,const)
            cValue := obj["value"]
            
            If IsInteger(cValue)
                obj["type"] := "Integer"
            Else If IsFloat(cValue)
                obj["type"] := "Float"
            
            (obj.Has("critical") And obj["critical"].Count = 0) ? obj.Delete("critical") : ""
            const_list[const] := obj
            
            t++, list .= const "`r`n"
        }
    }
    
    prog.Close()
    return list
}

do_subs(obj,const:="") {
    Static casting := "HRESULT|NTSTATUS|BCRYPT_ALG_HANDLE|ULONGLONG|LONGLONG|ULONG64|ULONG|LONG64|LONG32|LONG|long|float|LHANDLE|HANDLE|BYTE|ARGB|DISPID|HBITMAP|" ; long
                    . "BOOKMARK|DWORD64|DWORD32|DWORD|WORD|USHORT|SHORT|UINT64|UINT32|UINT16|UINT8|UINT|INT64|INT32|INT16|INT8|INT|int|CHAR|LPTSTR|LPSTR|LPCSTR|LPCTSTR|HWND|"
                    . "D3DRENDERSTATETYPE|D3DTRANSFORMSTATETYPE|D3DTEXTURESTAGESTATETYPE|D3DVERTEXBLENDFLAGS|"
                    . "DELTA_FILE_TYPE|DELTA_FLAG_TYPE|LPDATAOBJECT|DPI_AWARENESS_CONTEXT|MCIDEVICEID|PROPID"
    
    Static typs := "(?:UI8|UI16|UI32|UI64|I64|I32|I16|I8|ULL|UI|LL|UL|U|L|I)"
    
    Static win32_typ_fnc := "_ASF_HRESULT_TYPEDEF_|_HRESULT_TYPEDEF_|AUDCLNT_ERR|AUDCLNT_SUCCESS|MAKE_AVIERR|MAKE_DDHRESULT|MAKE_D3DHRESULT|D3DTS_WORLDMATRIX|"
                          . "MAKE_DMHRESULTERROR|MAKE_DSHRESULT|_NDIS_ERROR_TYPEDEF_|DBDAOERR"
    cValue := obj["value"]
    
    While RegExMatch(cValue,"\x28 ?(" casting ")(?:_PTR)? ?\x29",_m) ; remove initial type casting
        cValue := StrReplace(cValue,_m.Value(0),"")
    cValue := RegExReplace(cValue,"^(?:" win32_typ_fnc ")\x28 ?(.*?) ?\x29$","$1")
    newPos := 1
    
    Static rgx := "((?<!\d)[A-Z_][\w]+)"
    r := RegExMatch(cValue,"i)" rgx,m), match := ""
    If (IsObject(m) And m.Count())
        match := m.Value(1)
    else
        cValue := value_cleanup(cValue)
    
    While (!eval(cValue,true) And IsObject(m)) { ; require a match for looping
        dupe_arr := [], prep := cValue, mValue := "" ; searched := true
        
        ; If const = "DELTA_CLI4_FLAGS_I386"
            ; debug.msg(const ": " cValue)
        
        If (!IsInteger(match) And !const_list.Has(match)) {
            newPos := m.Pos(1) + m.Len(1)
            r := RegExMatch(cValue,"i)" rgx,m,newPos), match := ""
            If (IsObject(m) And m.Count())
                match := m.Value(1)
            Else Break ; no more matches?
            
            If (newPos >= StrLen(cValue)) ; searched entire value
                Break
            
            Continue
        }
        
        If IsInteger(match)
            mValue := Integer(match)
        else
            mValue := const_list[match]["exp"], newObj := const_list[match], (newObj.Has("dupe")) ? (dupe_arr := newObj["dupe"]) : ""
        
        While RegExMatch(mValue,"\x28 ?(" casting ") ?\x29",_m) ; remove subsequent type casting after substitutions
            mValue := StrReplace(mValue,_m.Value(0),"")
        
        If RegExMatch(mValue,typs "$")
            mValue := value_cleanup(mValue) ; clean up numerical types
        
        If (newObj["type"] = "Other") Or (newObj["type"] = "String") { ; don't do substitutions with "Other" type
            obj["type"] := newObj["type"]
            return obj
        }
        
        If const_list.Has(mValue) And (const_list[mValue]["value"]=const) { ; infinite loop, 2 vars reference themselves
            obj["type"] := "Other"
            return obj
        }
        
        (IsInteger(mValue)) ? mValue := Integer(mValue) : ""
        cValue := StrReplace(cValue,match,mValue,false,,1)
        
        ; If const = "AF_SETTABLE_BITS"
            ; Debug.Msg(const ": " cValue)
        
        If dupe_arr.Length > 0
            obj["critical"] := Map()
        For i, item in dupe_arr ; indicates there may be an alternate value for const
            obj["critical"][match] := item
        
        r := RegExMatch(cValue,"i)" rgx,m), match := "", newPos := 1
        If IsObject(m)
            match := m.Value(1) ; , newPos := 1
        Else {
            Break ; no match, break and move on
        }
    }
    
    obj["subs"] := cValue ; record the furthest progress of substitutions
    
    If !RegExMatch(cValue,"i)[g-km-tv-wy-z_]")
        cValue := value_cleanup(cValue)
    
    If RegExMatch(cValue,"ui64$")
        cValue := value_cleanup(cValue), debug.msg(const ": " cValue " / " obj["value"])
    
    If eval(cValue,true) {
        cValue := RegExReplace(cValue,"(!|~) +","$1") ; remove spaces between ! or ~ and expression
        obj["subs"] := cValue
        obj["value"] := eval(cValue)
        obj["type"] := "Expr"
    }
    
    return obj
}

reparse6() {
    t := 0
    prog := progress2.New(0,const_list.Count,"title:Reparse 6")
    prog.Update(A_Index,"Reparse 6 - removing duplicates with same value")
    
    For const, obj in const_list {
        prog.Update(A_Index)
        
        dupe := obj.Has("dupe") ? obj["dupe"] : ""
        If (dupe) {
            curExp := StrReplace(obj["exp"]," ",""), curVal := obj["value"]
            newDupes := []
            For i, obj2 in dupe {
                dupeExp := StrReplace(obj2["exp"]," ",""), dupeVal := obj2["value"]
                
                If (curExp != dupeExp And curExp != "(" dupeExp ")") And (curVal != dupeVal And curVal != "(" dupeVal ")")
                    newDupes.push(obj2)
            }
            
            If (newDupes.Length)
                const_list[const]["dupe"] := newDupes, t++
            Else
                const_list[const].Delete("dupe")
        }
    }
    
    prog.Close()
}

checkDupeConst(main,dupe) {
     curExp := StrReplace(main["exp"]," ",""),  curVal := main["value"]
    dupeExp := StrReplace(dupe["exp"]," ",""), dupeVal := dupe["value"]
    
    If (curExp != dupeExp And curExp != "(" dupeExp ")") And (curVal != dupeVal And curVal != "(" dupeVal ")")
        return true
    Else
        return false
}

value_cleanup(inValue) {
    Static q := Chr(34)
    ; Static casting := "HRESULT|NTSTATUS|BCRYPT_ALG_HANDLE|ULONGLONG|ULONG|LHANDLE|BYTE|ARGB|BOOKMARK|DWORD|WORD|USHORT|SHORT|UINT64|UINT32|UINT16|UINT8|UINT|INT64|INT64|INT32|INT16|INT8|INT"
    Static macro   := "__MSABI_LONG|_HRESULT_TYPEDEF_|_ASF_HRESULT_TYPEDEF_|AUDCLNT_ERR|MAKE_AVIERR|AUDCLNT_SUCCESS"
    Static typs    := "(?:UI8|UI16|UI32|UI64|I64|I32|I16|I8|ULL|UI|LL|UL|U|L|I)"
    ; Static num     := "\-?(?:0x)?[0-9A-F]+"
    Static num     := "\-?(?:\d+\.\d+(?:e\+\d+|e\-\d+|e\d+)?f?|0x[\dA-F]+|\d+)"
    
    inValue := Trim(RegExReplace(inValue,";$","")," ")
    inValue := StrReplace(inValue,"`t","")
    cValue := inValue ; init cValue
    
    ; If RegExMatch(cValue,"i)" macro " ?\x28 ?(" num ")" typs " ?\x29",m) { ; macros?
        ; cValue := StrReplace(cValue,m.Value(0),m.Value(1))
        
    ; } Else If RegExMatch(cValue,"i)\x28 ?(?:" casting ") ?\x29 ?(" num ")" typs,m) { ; type casting
        ; cValue := StrReplace(cValue,m.Value(0),m.Value(1))
        
    ; } Else If (RegExMatch(cValue,"^\x28? ?\d+U?\ *- *\d+U? ?\x29?")) {
        ; cValue := StrReplace(cValue,"U","")
    ; }
    
    ; If (RegExMatch(inValue,"^\x28?((0x)?[\-0-9A-Fa-f ]+)(L|l|LL)?\x29?$",m)) {
        ; If (IsInteger(m.Value(1)))
            ; cValue := Integer(m.Value(1))
    ; }
    
    ; If (RegExMatch(inValue,"^\x28?\x28ULONG\x29 ?((0x)?[0-9A-Fa-f]+)\x29?$",m)) { ; simple ULONG conversion
        ; If (IsInteger(m.Value(1)))
            ; cValue := Integer(m.Value(1))
    ; }
    
    ; testValue := RegExReplace(cValue,"(\-?(0x)?[a-fA-F0-9]+)(U|L|UL|ULL|LL|u|l|ui|ul|UI)(8|16|32|64)?","$1")
    ; If (testValue != cValue And IsInteger(testValue)) ; type = numeric literal
    
    If RegExMatch(inValue,"ui64$")
        debug.msg("cValue: " cValue " / inValue: " inValue " .... WWTTFF!!!")
    
    While RegExMatch(cValue,"i)" "(" num ")" typs,m) {
        cValue := StrReplace(cValue,m.Value(0),m.Value(1)) ; replace hex with decimal
        If RegExMatch(inValue,"ui64$")
            debug.msg("in the shit: " cValue)
    }
    
    cValue := RegExReplace(cValue,"i)(" num ")" typs,"$1")
    
    ; a := m.Value(0), b := m.Value(1)
    
    If RegExMatch(inValue,"ui64$")
        debug.msg("cValue: " cValue " / inValue: " inValue " ... darn it")
        
    return cValue
}

isMathExpr(mathStr) {
    If RegExMatch(mathStr,"i)[a-wyz]")
    If mathStr = "" Or InStr(mathStr,Chr(34))
        return false
    Loop Parse mathStr
    {
        ch := Ord(A_LoopField) ; " # $ % , : ; = ? a-z A-Z { }
        If (ch>=34 And ch<=37) Or (ch=44) Or (ch=58) Or (ch=59) Or (ch=61) Or (ch=63) Or (ch>=65 And ch<=90) Or (ch>=97 And ch<=122) Or (ch=123) Or (ch=125) {
            ; If RegExMatch(mathStr,"(?<!0)x")
                return false ; actual string evaluated MUST be purely numerical with operators
        }
    }
    return true
}

isMathExprDebug(mathStr) {
    If mathStr = "" Or InStr(mathStr,Chr(34))
        return false
    Loop Parse mathStr
    {
        ch := Ord(A_LoopField)
        If (ch>=34 And ch<=37) Or (ch=44) Or (ch=58) Or (ch=59) Or (ch=61) Or (ch=63) Or (ch>=65 And ch<=90) Or (ch>=97 And ch<=122) Or (ch=123) Or (ch=125) {
            return ch ; actual string evaluated MUST be purely numerical with operators
        }
    }
    return true
}
