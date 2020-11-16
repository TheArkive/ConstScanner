includes_report() {

}

win32_header_parser() { ; total header files: 3,505
    root := g["ApiPath"].Text, calcListTotal := 0, calcListCount := 1
    
    If (!root Or !FileExist(root)) {
        Msgbox "Specify the path for the Win32 headers first."
        return
    }
    
    SplitPath root, fileName, rootDir
    Loop Files rootDir "\*.h", "R"
        fCount := A_Index
    
    IncludesList := Map(), const_list := Map()
    ; const_list := parse_includes([root])
    
    prog := progress2.New(0,fCount,"title:Scanning files...,mainText:0 of " fCount)
    Static q := Chr(34)
    rg1 := "i)^\#include[ `t]+(<|\" q ")([^>" q "]+)(>|\" q ")"
    rg2 := "i)^#define[ `t]+(\w+)[ `t]+(.+)"
    
    Loop Files rootDir "\*.h", "R"
    {
        fullPath := A_LoopFileFullPath, file := A_LoopFileName
        prog.Update(A_Index,A_Index " of " fCount,file)
        fText := FileRead(fullPath)
        fArr := StrSplit(fText,"`n","`r")
        
        cnt := 1
        For i, curLine in fArr {
            constValue := "" ; init value
            cnt := 1 ; counter for more lines
            If (RegExMatch(curLine,rg1,m)) { ; include line
                If (!IncludesList.Has(file))
                    IncludesList[file] := [m.Value(2)]
                Else
                    IncludesList[file].Push(m.Value(2))
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
                
                vConst := value_cleanup(constExp)
                
                item := Map("exp",constExp,"comment",comment,"file",file,"line",i,"value",vConst.value,"type",vConst.type)
                
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
    
    calcList := reparse2a() "`r`necho " Chr(34) "_quit_now_" Chr(34)
    c := cli.New("cmd /K powershell","mode:spr"), c.QuitString := "_quit_now_"
    c.write(calcList)
    
    Mprog := progress2.New(0,calcListTotal,"title:Calculating...")
    
    ; test ================================
    ; reparse6()
    ; relist_const()
    ; UnlockGui(true)

}

QuitCallback(quitString,ID,CLIobj) {
    Mprog.Close()
    relist_const()
    UnlockGui(true)
    g["Total"].Value := "Scan complete: " const_list.Count " constants recorded."
    
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

reparse2a() {
    Static q := Chr(34)
    t := 0, i := 0, bigChunk := ""
    
    For const, obj in const_list
        If (obj["type"] = "expr")
            i++
    
    prog := progress2.New(0,i,"title:Preparing Calculations List...")
    prog.Update(A_Index,"Reparse 3 - Pass #1")
    
    batchCmd := ""
    
    For const, obj in const_list {
        If (obj["type"] = "expr") {
            t++
            prog.Update(t,const,t " of " i)
            curConst := const
            curVal := obj["value"]
            mathExp := eval(curVal)
            
            If mathExp != ""
                bigChunk .= "echo " Chr(34) const ":" Chr(34) " " mathExp "`r`n", calcListTotal += 1
        }
    }
    
    prog.close()
    
    return Trim(bigChunk,"`r`n ")
}

reparse1a(pass) { ; constants that point to a single constant / any type
    t := 0, list := ""
    prog := progress2.New(0,const_list.Count,"title:Performing Substitutions")
    prog.Update(A_Index,"Pass #" pass)
    
    For const, obj in const_list {
        prog.Update(A_Index)
        
        
        
        If (obj["type"] = "unknown") {
            ; newPos := 1, prevMatch := "", cValue := obj["value"]
            
            ; r := RegExMatch(cValue,"([\w]+)",m), match := ""
            ; If (IsObject(m))
                ; match := m.Value(1)
            
            ; While (!isMathExpr(cValue)) {
                ; dupe_arr := [], prep := cValue ; searched := true
                
                ; If (!IsInteger(match) And !const_list.Has(match))
                    ; Break
                
                ; If IsInteger(match)
                    ; mValue := Integer(match)
                ; else
                    ; mValue := const_list[match]["exp"], newObj := const_list[match], (newObj.Has("dupe")) ? (dupe_arr := newObj["dupe"]) : ""
                ; (IsInteger(mValue)) ? mValue := Integer(mValue) : ""
                
                ; If (prevMatch = mValue And !IsInteger(prevMatch)) ; try to detect infinite loop with 2 constants referring to each other
                    ; Break
                
                ; cValue := StrReplace(cValue,match,mValue,false,,1)
                
                ; If InStr(cValue,"`t") Or InStr(cValue,"}") Or InStr(cValue,Chr(44)) Or InStr(cValue,Chr(34)) Or InStr(cValue,"#") Or InStr(cValue,"=") ; Or dot
                    ; Break
                
                ; If dupe_arr.Length > 0
                    ; obj["critical"] := Map()
                ; For i, item in dupe_arr ; indicates there may be an alternate value for const
                    ; obj["critical"][match] := item
                
                ; newPos := m.Pos(1) + StrLen(mValue)
                ; (newPos >= StrLen(cValue)) ? (newPos := 1) : ""
                
                ; prevMatch := match ; try to detect infinite loop with 2 constants referring to each other
                
                ; If isMathExpr(cValue)
                    ; Break
                
                ; r := RegExMatch(cValue,"([\w]+)",m,newPos), match := ""
                ; (IsObject(m)) ? match := m.Value(1) : ""
            ; }
            
            obj := do_subs(obj), cValue := obj["value"]
            
            If (cValue!="" And isMathExpr(cValue)) {
                obj["type"] := "expr", obj["value"] := cValue
                (obj.Has("critical") And obj["critical"].Count = 0) ? obj.Delete("critical") : ""
                const_list[const] := obj
                
                t++, list .= const "`r`n"
            }
        }
    }
    
    prog.Close()
    return list
}

do_subs(obj) {
    newPos := 1, cValue := obj["value"], prevMatch := ""
            
    r := RegExMatch(cValue,"([\w]+)",m), match := ""
    If (IsObject(m))
        match := m.Value(1)
    
    While (!isMathExpr(cValue)) {
        dupe_arr := [], prep := cValue ; searched := true
        
        If (!IsInteger(match) And !const_list.Has(match))
            Break
        
        If IsInteger(match)
            mValue := Integer(match)
        else
            mValue := const_list[match]["exp"], newObj := const_list[match], (newObj.Has("dupe")) ? (dupe_arr := newObj["dupe"]) : ""
        (IsInteger(mValue)) ? mValue := Integer(mValue) : ""
        
        If (prevMatch = mValue And !IsInteger(prevMatch)) ; try to detect infinite loop with 2 constants referring to each other
            Break
        
        cValue := StrReplace(cValue,match,mValue,false,,1)
        
        If InStr(cValue,"`t") Or InStr(cValue,"}") Or InStr(cValue,Chr(44)) Or InStr(cValue,Chr(34)) Or InStr(cValue,"#") Or InStr(cValue,"=") ; Or dot
            Break
        
        If dupe_arr.Length > 0
            obj["critical"] := Map()
        For i, item in dupe_arr ; indicates there may be an alternate value for const
            obj["critical"][match] := item
        
        newPos := m.Pos(1) + StrLen(mValue)
        (newPos >= StrLen(cValue)) ? (newPos := 1) : ""
        
        prevMatch := match ; try to detect infinite loop with 2 constants referring to each other
        
        If isMathExpr(cValue) {
            obj["value"] := cValue
            Break
        }
        
        r := RegExMatch(cValue,"([\w]+)",m,newPos), match := ""
        (IsObject(m)) ? match := m.Value(1) : ""
    }
    
    return obj
}

dupe_array_check(inArr,inValue) {
    For i, d in inArr
        If d = inValue
            return true
    return false
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
    
    prog.Close() ; msgbox "saved dupes: " t
}

checkDupeConst(main,dupe) {
     curExp := StrReplace(main["exp"]," ",""),  curVal := main["value"]
    dupeExp := StrReplace(dupe["exp"]," ",""), dupeVal := dupe["value"]
    
    If (curExp != dupeExp And curExp != "(" dupeExp ")") And (curVal != dupeVal And curVal != "(" dupeVal ")")
        return true
    Else
        return false
}

; 32-bit LONG max value = 2147483647
; 32-bit ULONG max value = 4294967296
;                          4294967295
; 32-bit convert LONG to ULONG >>> add 2147483648

; 64-bit LONG LONG max value = 9223372036854775807
; 64-bit ULONG LONG max vlue = 18446744073709551616
; 64-bit convert LONGLONG to ULONGLONG >>> add 9223372036854775808

value_cleanup(inValue) {
    Static q := Chr(34)
    cType := "unknown"
    
    ; If (RegExMatch(inValue,"^\w+\x28")) {       ; Macros likely won't be resolved, so identify them as such
        ; cType := "macro", cValue := inValue     ; so we don't continually recurse them.
        ; Goto Finish
    ; }
    
    inValue := Trim(RegExReplace(inValue,";$","")," `t")
    cValue := inValue ; init cValue
    
    If (IsInteger(inValue)) { ; type = integer / no conversion needed
        cType := "integer", cValue := Integer(inValue)
        Goto Finish
    }
    
    If (RegExMatch(inValue,"\x28?\d+U\-\d+U\x29?")) {
        newValue := StrReplace(inValue,"U","")
        cType := "expr", cValue := newValue
        Goto Finish
    }
    
    If RegExMatch(inValue,"i)\x28?__MSABI_LONG\x28[0-9A-Fx]+\x29\x29?") { ; (__MSABI_LONG())
        newValue := RegExReplace(inValue,"__MSABI_LONG|\x28|\x29","")
        (IsInteger(newValue)) ? newValue := Integer(newValue) : ""
        cType := "integer", cValue := newValue
        Goto Finish
    }
    
    If RegExMatch(inValue,"i)\x28?\x28(HRESULT|DWORD|NTSTATUS)\x29[0-9A-Fx]+\x29?") {
        newValue := RegExReplace(inValue,"i)HRESULT|NTSTATUS|DWORD|\x28|\x29","")
        (IsInteger(newValue)) ? newValue := Integer(newValue) : ""
        cType := "integer", cValue := newValue
        Goto Finish
    }
    
    If (RegExMatch(inValue,"^\x28?((0x)?[\-0-9A-Fa-f ]+)(L|l|LL)?\x29?$",m)) {
        If (IsInteger(m.Value(1))) {
            cType := "integer", cValue := Integer(m.Value(1))
            Goto Finish
        }
    }
    
    If (RegExMatch(inValue,"^\x28?\x28ULONG\x29 ?((0x)?[0-9A-Fa-f]+)\x29?$",m)) { ; simple ULONG conversion
        If (IsInteger(m.Value(1))) {
            cType := "integer", cValue := Integer(m.Value(1))
            Goto Finish
        }
    }
    
    newValue := RegExReplace(inValue,"^\x28? ?((0x)?\-?[a-fA-F0-9]+)(U|L|UL|ULL|LL|ui|ul|UI)(8|16|32|64)? ?\x29?$","$1")
    If (newValue != inValue And IsInteger(newValue)) { ; type = numeric literal
        cType := "integer", cValue := Integer(newValue)
        Goto Finish
    }
    
    If (RegExMatch(inValue,"^\x28? ?(\-?[0-9\.]+)(f)? ?\x29?$",m)) {
        cType := "float", cValue := m.Value(1)
        Goto Finish
    }
    
    If (RegExMatch(inValue,"^\{.*\}$")) {
        cType := "array", cValue := inValue
        Goto Finish
    }
    
    If (RegExMatch(inValue,"^\x28? ?L?\'.+?\' ?\x29?$")) {
        cType := "string", cValue := inValue
        Goto Finish
    }
    
    If (RegExMatch(inValue,"^\x28? ?L?\" q ".*\" q " ?\x29?$")) { ; wchar_t string
        cType := "string", cValue := inValue
        Goto Finish
    }
    
    Finish:
    inValue := RegExReplace(inValue,"[ ]{2,}"," ") ; attempt to remove consecutive spaces, hopefully won't break anything
    inValue := Trim(inValue," `t")
    return {value:cValue, type:cType}
}

isMathExpr(mathStr) {
    If mathStr = "" Or InStr(mathStr,Chr(34))
        return false
    Loop Parse mathStr
    {
        ch := Ord(A_LoopField) ; " # $ % , : ; = ? a-z A-Z { }
        If (ch>=34 And ch<=37) Or (ch=44) Or (ch=58) Or (ch=59) Or (ch=61) Or (ch=63) Or (ch>=65 And ch<=90) Or (ch>=97 And ch<=122) Or (ch=123) Or (ch=125) {
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

; get_full_path(inFile) {
    ; fullPath := ""
    ; root := Settings.Has("ApiPath") ? Settings["ApiPath"] : ""
    ; If (!root)
        ; return ""
    
    ; Loop Files root "\*", "R"
    ; {
        ; If (!fullPath And InStr(A_LoopFileFullPath,"\" inFile))
            ; fullPath := A_LoopFileFullPath
        ; Else If (fullPath And InStr(A_LoopFileFullPath,"\" inFile))
            ; Msgbox "Dupe file found:`r`n`r`n" fullPath "`r`n`r`n" A_LoopFileFullPath
    ; }
    
    ; return fullPath
; }