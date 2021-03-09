includes_report() {
    Global Settings, IncludesList, const_list
    Static q := Chr(34)
    
    prof := Settings["Recents"][Settings["ApiPath"]]
    baseFolders := prof["BaseFolder"] ; array
    other_dirs := []
    For item in prof["OtherDirList"]
        if (item[2] != 2)
            other_dirs.Push(item[3])
    
    const_list := Map()
    IncludesList := Map() ; for user reference after scan is complete
    includes_list := []
    
    For oDir in other_dirs { ; maybe include error handling here, and allow relative paths in Other Dirs window
        If !InStr(oDir,"*") {         ; Add full-path file to includes_list
            If !dupe_item_check(includes_list,oDir)
                includes_list.Push(oDir)
        } Else If (SubStr(oDir,-4) = "\*.h") { ; Add all files defined in wildcard expression... recursive.
            Loop Files oDir, "R"
            {
                If !dupe_item_check(includes_list,A_LoopFileFullPath)
                    includes_list.Push(A_LoopFileFullPath)
            }
        } Else If (RegExMatch(oDir,"i)\\(?:[a-z0-9\-_]+)?\*(?:[a-z0-9\-_]+)?\.h$")) { ; All files matching pattern in folder only.
            Loop Files oDir
            {
                If !dupe_item_check(includes_list,A_LoopFileFullPath)
                    includes_list.Push(A_LoopFileFullPath)
            }
        }
    }
    
    Loop { ; try reading and populating the loop simultaneously
        do_continue := false
        If !includes_list.Has(A_Index)
            Break
        
        fullPath := includes_list[A_Index]
        
        If !FileExist(fullPath)
            msgbox "FILE DOES NOT EXIST:`r`n    " fullPath
        
        IncludesList[StrReplace(fullPath,"\","|")] := []
        ; SplitPath fullPath, file_name
        
        fText := FileRead(fullPath)
        fArr := StrSplit(fText,"`n","`r")
        
        cnt := 1
        While (cnt <= fArr.Length) {
            curLine := fArr[cnt]
            
            If Trim(curLine,"`t ") = "" {
                cnt++
                Continue
            }
            
            constValue := "" ; init value
            If (RegExMatch(curLine,"i)^\#include[ `t]+(<|\" q ")?([^>" q "]+)(>|\" q ")?",&m)) { ; include line
                match := StrReplace(StrReplace(m.Value(2),q,""),"/","\")
                
                If !(cur_incl := get_full_path(match,baseFolders)) {
                    cur_incl := match
                } Else If (!dupe_item_check(includes_list,cur_incl) And Trim(cur_incl," `t") != "")
                    includes_list.Push(cur_incl)            ; file list for parsing
                
                If (Trim(cur_incl," `t") != "")
                    IncludesList[StrReplace(fullPath,"\","|")].Push([match,cur_incl])   ; nested includes list
            }
            cnt++ ; increment line number
        }
        
        If (IncludesList[StrReplace(fullPath,"\","|")].Length = 0)
            IncludesList.Delete(StrReplace(fullPath,"\","|"))
    }
    
    incl_report()
}

dupe_item_check(inArr,inValue) {
    For i, d in inArr
        If d = inValue
            return true
    return false
}

prune_comments(inText) {
    result := RegExReplace(inText,"([ `t]*//.*|[ `t]*/\*.*?\*/)","")
    result := RegExReplace(result,"[ `t]*/\*.*","")
    return RTrim(result," `t")
}

header_parser() {
    Global Settings, IncludesList, const_list, prog
    Static q := Chr(34)
    
    prof := Settings["Recents"][Settings["ApiPath"]]
    baseFolders := prof["BaseFolder"] ; array
    other_dirs := []
    For item in prof["OtherDirList"]
        if (item[2] != 2)
            other_dirs.Push(item[3])
    
    const_list := Map()
    IncludesList := Map() ; for user reference after scan is complete
    includes_list := []
    
    For oDir in other_dirs { ; maybe include error handling here, and allow relative paths in Other Dirs window
        If !InStr(oDir,"*") {         ; Add full-path file to includes_list
            If !dupe_item_check(includes_list,oDir)
                includes_list.Push(oDir)
        } Else If (SubStr(oDir,-4) = "\*.h") { ; Add all files defined in wildcard expression... recursive.
            Loop Files oDir, "R"
            {
                If !dupe_item_check(includes_list,A_LoopFileFullPath)
                    includes_list.Push(A_LoopFileFullPath)
            }
        } Else If (RegExMatch(oDir,"i)\\(?:[a-z0-9\-_]+)?\*(?:[a-z0-9\-_]+)?\.h$")) { ; All files matching pattern in folder only.
            Loop Files oDir
            {
                If !dupe_item_check(includes_list,A_LoopFileFullPath)
                    includes_list.Push(A_LoopFileFullPath)
            }
        }
    }
    
    prog := progress2(0,includes_list.Length,"title:Scanning files...,parent:" Settings["gui"].hwnd) ; counter was fCount
    Static rg1 := "i)^\#include[ `t]+(<|\" q ")([^>" q "]+)(>|\" q ")"
    Static rg2 := "i)^#define[ `t]+(\w+)[ `t]+(.+)"
    Static rg3 := "i)^[ `t]*(?:(typedef|enum|struct))"
    
    prevLine := ""
    Loop { ; try reading and populating the loop simultaneously
        do_continue := false
        If !includes_list.Has(A_Index)
            Break
        
        fullPath := includes_list[A_Index]
        
        If !FileExist(fullPath)
            msgbox "FILE DOES NOT EXIST:`r`n    " fullPath
        
        IncludesList[StrReplace(fullPath,"\","|")] := []
        SplitPath fullPath, &file_name
        
        prog.Update(A_Index,A_Index " of " includes_list.Length,file_name,"0-" includes_list.Length)
        
        fText := FileRead(fullPath)
        fArr := StrSplit(fText,"`n","`r")
        
        cnt := 1
        While (cnt <= fArr.Length) {
            curLine := fArr[cnt]
            
            If Trim(curLine,"`t ") = "" {
                cnt++
                Continue
            }
            
            constValue := "" ; init value
            If (RegExMatch(curLine,rg1,&m)) { ; include line
                match := StrReplace(StrReplace(m.Value(2),q,""),"/","\")
                
                If !(cur_incl := get_full_path(match,baseFolders)) {
                    cur_incl := match
                } Else If (!dupe_item_check(includes_list,cur_incl) And Trim(cur_incl," `t") != "")
                    includes_list.Push(cur_incl)            ; file list for parsing
                
                If (Trim(cur_incl," `t") != "")
                    IncludesList[StrReplace(fullPath,"\","|")].Push([match,cur_incl])   ; Main IncludesList
                
            } Else If (RegExMatch(curLine,rg2,&m)) { ; match constants
                constName := m.Value(1), constExp := m.Value(2)
                lineNum := cnt
                
                comment := ""
                If (RegExMatch(constExp,"([ `t]*//.*|[ `t]*/\*.*)",&m2)) {
                    comment := Trim(m2.Value(0)," `t")
                    constExp := prune_comments(constExp)
                }
                
                While (SubStr(constExp,-1) = "\") {
                    cnt++ ; inc next line
                    nextLine := prune_comments(fArr[cnt])
                    constExp := Trim(SubStr(constExp,1,-1),"`t ") . nextLine
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
                                       Or (constExp = "(&" constName ")")
                    cType := "Other"
                Else If InStr(constExp,Chr(34)) Or InStr(constExp,"'")
                    cType := "String"
                
                commit_item(constName,Map("exp",constExp,"comment",comment,"file",file_name,"line",lineNum,"value",constExp,"type",cType))
            } Else If (RegExMatch(curLine,rg3,&m)) {
                lineNum := cnt, full := "" ; full = full body text of ENUM or STRUCT
                cL := prune_comments(curLine)
                
                If RegExMatch(cL,"i)^[ `t]*(?:typedef[ `t]+)?(enum|struct)[ `t]+[a-z0-9_\*]+[ `t]+[a-z0-9_\*]+;$") {
                    cnt++
                    Continue
                } Else If RegExMatch(cL,"i)^[ `t]*(?:typedef[ `t]+)?(enum|struct)[ `t]+([a-z0-9_]+)[ `t]*\x7B.*?\x7D;$",&m) {
                    full := m.Value(0), constType := StrUpper(m.Value(1),"T"), constName := m.Value(2)
                } Else If ( RegExMatch(cL,"i)^[ `t]*(?:typedef[ `t]+)?(enum|struct)[ `t]+([a-z0-9_]+)(?:[ `t]*\x7B)?$",&m)
                         Or RegExMatch(td:=cL,"i)^[ `t]*(?:typedef|enum|struct)[ `t]*$") ) {
                    
                    If (td) {
                        RegExMatch(fArr[cnt+1],"i)^[ `t]*(enum|struct)[ `t]+([a-z0-9_]+)",&m)
                        full := "typedef"
                        If (!IsObject(m) Or m.Count() = 0) {
                            cnt++
                            Continue ; main while loop
                        }
                    } Else
                        full := m.Value(0)
                    
                    constType := m.Value(1), constName := m.Value(2)
                    If (constType != "struct" And constType != "enum") {
                        cnt++
                        Continue ; main while loop
                    }
                    
                    full_no_comment := full, nextLine := "", full_no_comment := prune_comments(full)
                    
                    Loop {
                        cnt++ ; inc next line
                        If (!fArr.Has(cnt))
                            Break
                        nextLine := Trim(fArr[cnt],"`r`n")
                        nextLine_no_comment := prune_comments(nextLine)
                        If !nextLine
                            Continue
                        
                        full .= "`r`n" nextLine
                        full_no_comment .= "`r`n" nextLine_no_comment
                        
                        StrReplace(full_no_comment,"{","{",,&encL), StrReplace(full_no_comment,"}","}",,&encR)
                        
                        If RegExMatch(full_no_comment,"i)[ `t]*\x7D([`r`n `ta-z0-9_\,\*/]+)?;$") And (encL = encR) ; ender for enum|struct
                            Break
                    }
                }
                
                If (full)
                    commit_item(constName,Map("exp","","comment","","file",file_name,"line",lineNum
                               ,"value",Trim(full," `t"),"type",StrUpper(constType,"T"))) ; commit item to main array
            }
            
            prevLine := curLine, td := ""
            cnt++ ; increment line number
        }
        
        If (IncludesList[StrReplace(fullPath,"\","|")].Length = 0)
            IncludesList.Delete(StrReplace(fullPath,"\","|"))
    }
    
    prevList := ""
    Loop {
        curList := reparse1a(A_Index)
        If (curList = prevList or curList = "")
            Break
        prevList := curList
    }
    
    reparse6()
    ; prog.Close(), prog := ""
    prog.SetTitle("Preparing to reload list...")
    prog.Update(0," "," ","0-100")
    
    ; A_Clipboard := jxon_dump(IncludesList,4)
    ; msgbox A_Clipboard
}

commit_item(constName,item) {
    Global const_list
    If (!const_list.Has(constName))
        const_list[constName] := item
    Else If checkDupeConst(const_list[constName],item) {
        (!const_list[constName].Has("dupe")) ? const_list[constName]["dupe"] := [] : ""
        const_list[constName]["dupe"].Push(item)
    }
}

create_cpp_file() {
    Global Settings
    Static q := Chr(34)
    
    inc_list := Settings["Recents"][Settings["ApiPath"]]["OtherDirList"]
    BaseFolders := Settings["Recents"][Settings["ApiPath"]]["BaseFolder"]
    def_inc := []
    For item in inc_list {
        If (item[1])
            def_inc.Push(item[3])
    }
    
    For _file in def_inc {
        SplitPath _file, &file_Name
        ; For bFolder in BaseFolders {
            ; If InStr(file_name,bFolder) {
                ; file_name := StrReplace(file_name,bFolder "\","")
                ; Break
            ; }
        ; }
        cppFile := "#include <iostream>`r`n#include <" file_name ">`r`n" ; was rootFile
    }
    
    row := 0, includes := [], constants := []
    While (row := Settings["gui"]["ConstList"].GetNext(row,"C")) {
        If (Settings["AddIncludes"]) {
            _include := Settings["gui"]["ConstList"].GetText(row,4)
            If (_include And !dupe_item_check(includes,_include))
                includes.Push(_include)
        }
        constants.Push(Settings["gui"]["ConstList"].GetText(row))
    }
    
    For file_name in includes                     ; for user specified files ONLY
        cppFile .= "#include <" file_name ">`r`n"
    
    cppFile .= "`r`nint main() {`r`n"
    
    If (FileExist("test_const.cpp"))
        FileDelete "test_const.cpp"
    If (FileExist("test_const.exe"))
        FileDelete "test_const.exe"
    If (FileExist("test_const.obj"))
        FileDelete "test_const.obj"
    
    For const in constants
        cppFile .= "    std::cout << " q const " = " q " << " const " << std::endl;`r`n"
    
    cppFile .= "`r`n    return 0;`r`n}"
    FileAppend cppFile, "test_const.cpp"
}

; ============================================================================================
; ============================================================================================

reparse1a(pass) { ; constants that point to a single constant / any type
    Global const_list, prog
    t := 0, list := ""
    ; prog := progress2.New(0, const_list.Count, "title:Calculating Constants...,parent:" g.hwnd)
    prog.SetTitle("Calculating Constants..."), prog.Range("0-" const_list.Count)
    prog.Update(0,"Pass #" pass)
    
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
    
    ; prog.Close()
    return list
}

do_subs(obj,const:="") {
    Global const_list
    Static casting := "HRESULT|NTSTATUS|BCRYPT_ALG_HANDLE|ULONGLONG|LONGLONG|ULONG64|ULONG|LONG64|LONG32|LONG|long|float|LHANDLE|HANDLE|BYTE|ARGB|DISPID|HBITMAP|u_long|" ; long
                    . "BOOKMARK|DWORD64|DWORD32|DWORD|WORD|USHORT|SHORT|UINT64|UINT32|UINT16|UINT8|UINT|INT64|INT32|INT16|INT8|INT|int|CHAR|LPTSTR|LPSTR|LPCSTR|LPCTSTR|HWND|"
                    . "D3DRENDERSTATETYPE|D3DTRANSFORMSTATETYPE|D3DTEXTURESTAGESTATETYPE|D3DVERTEXBLENDFLAGS|HFILE|HCERTCHAINENGINE|HINSTANCE|unsigned long|"
                    . "DELTA_FILE_TYPE|DELTA_FLAG_TYPE|LPDATAOBJECT|DPI_AWARENESS_CONTEXT|MCIDEVICEID|PROPID"
    
    Static typs := "(?:UI8|UI16|UI32|UI64|I64|I32|I16|I8|ULL|UI|LL|UL|U|L|I)"
    
    Static win32_typ_fnc := "_ASF_HRESULT_TYPEDEF_|_HRESULT_TYPEDEF_|AUDCLNT_ERR|AUDCLNT_SUCCESS|MAKE_AVIERR|MAKE_DDHRESULT|MAKE_D3DHRESULT|D3DTS_WORLDMATRIX|"
                          . "MAKE_DMHRESULTERROR|MAKE_DSHRESULT|_NDIS_ERROR_TYPEDEF_|DBDAOERR|__MSABI_LONG"
    
    cValue := obj["value"]
    
    ; cValue := RegExReplace(cValue,"(?:" win32_typ_fnc ") ?\x28 ?(.*?) ?\x29","$1") ; func type conversion
    ; While RegExMatch(cValue,"\x28 ?(" casting ")(?:_PTR)? ?\x29",_m) ; remove initial type casting
        ; cValue := StrReplace(cValue,_m.Value(0),"")
    
    cValue := number_cleanup(cValue) ; try to clean up number formats, and convert hex to base-10
    
    newPos := 1
    
    Static rgx := "([_A-Z][\w_]+\x28?)" ; "((?<!\d)[A-Z_][\w]+)"
    r := RegExMatch(cValue,"i)" rgx,&m), match := ""
    (IsObject(m) And m.Count()) ? match := m.Value(1) : "" ; attempt to capture first match
    
    ; =============================================
    ; If InStr(const,"API_SET_CHPE_GUEST") = 1
        ; Debug.Msg(const ": " const_list[const]["value"] "`r`nmatch: " match "`r`ncValue: " cValue)
    ; =============================================
    
    While (!eval(cValue,true) And IsObject(m)) { ; require a match for looping
        dupe_arr := [], prep := cValue, mValue := "" ; searched := true
        
        If (SubStr(match,-1) = "(") Or (!IsInteger(match) And !const_list.Has(match))
            Break
        
        If IsInteger(match)
            mValue := Integer(match), newObj := Map("type","")
        else {
            mValue := const_list[match]["exp"]
            ; If (commit)
                newObj := const_list[match], (newObj.Has("dupe")) ? (dupe_arr := newObj["dupe"]) : "" ; lay off critical for now
            ; Else newObj := Map("type","")
            
            ; mValue := RegExReplace(mValue,"(?:" win32_typ_fnc ") ?\x28 ?(.*?) ?\x29","$1")   ; func type conversion
            ; While RegExMatch(mValue,"\x28 ?(" casting ") ?\x29",_m)                         ; remove type casting
                ; mValue := StrReplace(mValue,_m.Value(0),"")
            
            mValue := number_cleanup(mValue)
        }
        
        If (newObj["type"] = "Other") Or (newObj["type"] = "String") { ; don't do substitutions with "Other" type
            obj["type"] := newObj["type"]
            return obj
        }
        
        If (const_list[const]["value"] = mValue) { ; infinite loop, 2 vars reference themselves
            obj["type"] := "Other"
            return obj
        }
        
        (IsInteger(mValue)) ? mValue := Integer(mValue) : ""
        cValue := StrReplace(cValue,match,mValue,false,,1) ; the actual substitution within the expression
        
        ; =================================
        ; If InStr(const,"API_SET_CHPE_GUEST") = 1
            ; Debug.Msg(const ": " const_list[const]["value"] "`r`n    match: " match "`r`n    mValue: " mValue "`r`ncValue: " cValue "`r`n")
        ; =================================
        
        ; If (commit) {
            If dupe_arr.Length > 0            ; lay off "critical" for now
                obj["critical"] := Map()
            For i, item in dupe_arr ; indicates there may be an alternate value for const
                obj["critical"][match] := item
        ; }
        
        r := RegExMatch(cValue,"i)" rgx,&m), match := "", newPos := 1 ; prep for next iteration
        If IsObject(m)
            match := m.Value(1)
        Else Break ; no match, break and move on
        
        ; =================================
        ; If const = "_Reserved_"
            ; debug.msg(const " wtf match: " match)
        ; =================================
    }
    
    obj["value"] := cValue ; record the furthest progress of substitutions
    
    ; =================================
    ; If InStr(const,"API_SET_CHPE_GUEST") = 1
        ; Debug.Msg(const ": " const_list[const]["value"] "`r`ncValue: " cValue "`r`n")
    ; =================================
    
    If (eval(cValue,true)) {
        cValue := RegExReplace(cValue,"(!|~) +","$1") ; remove spaces between ! or ~ and expression
        ; obj["subs"] := cValue
        cValue := eval(cValue)
        
        If IsInteger(cValue)
            obj["value"] := Integer(cValue)
        Else If IsFloat(cValue)
            obj["value"] := Float(cValue)
        Else obj["value"] := cValue
        obj["type"] := "Expr"
    }
    
    return obj
}

reparse6() {
    Global const_list, prog
    t := 0
    ; prog := progress2.New(0,const_list.Count,"title:Reparse 6,parent:" g.hwnd)
    prog.SetTitle("Removing Duplicates"), prog.Range("0-" const_list.Count)
    prog.Update(0,"Reparse 6 - removing duplicates with same value")
    
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
    
    ; prog.Close()
}

checkDupeConst(main,dupe) {
     curExp := StrReplace(main["exp"]," ",""),  curVal := main["value"]
    dupeExp := StrReplace(dupe["exp"]," ",""), dupeVal := dupe["value"]
    
    If (curExp != dupeExp And curExp != "(" dupeExp ")") And (curVal != dupeVal And curVal != "(" dupeVal ")")
        return true
    Else
        return false
}

number_cleanup(inValue) {
    Static q := Chr(34)
    Static typs    := "(?:UI8|UI16|UI32|UI64|I64|I32|I16|I8|ULL|UI|LL|UL|U|L|I)"
    Static num     := "\-?(?:\d+\.\d+(?:e\+\d+|e\-\d+|e\d+)?f?|0x[\dA-F]+|\d+)"
    Static hex     := "\-?0x[\dA-F]+"
    
    inValue := Trim(RegExReplace(inValue,";$","")," ")
    inValue := StrReplace(inValue,"`t","")
    cValue := inValue ; init cValue
    
    test := false
    If InStr(cValue,"(0U-700U)")
        test := true
    
    While RegExMatch(cValue,"i)(" num ")(" typs ")",&m) {
        If !IsObject(m) Or (m.Count() < 2)
            Break
        
        cValue := StrReplace(cValue,m.Value(0),m.Value(1),,,1) ; replace hex with decimal
    }
    
    While RegExMatch(cValue,"i)(" hex ")",&n) {
        If !IsObject(n) Or (!n.Count())
            Break
        
        match := n.Value(1)
        _num :=  (IsInteger(match)) ? Integer(match) : (IsFloat(match)) ? Float(match) : match
        cValue := StrReplace(cValue,match,_num,,,1) ; replace hex with decimal
    }
    return cValue
}

get_full_path(inFile, BaseFolderArr:="") {
    fullPath := ""
    For BaseFolder in BaseFolderArr {
        If FileExist(inFile)
            return inFile
        Else {
            SplitPath inFile, &file_name, &rootDir, &ext
            If (!DirExist(BaseFolder) Or BaseFolder="")
                return ""
        }
        
        Loop Files BaseFolder "\*", "R"
        {
            If (!fullPath And InStr(A_LoopFileFullPath,"\" inFile)) {
                fullPath := A_LoopFileFullPath
                Break
            }
        }
        
        ; If (!fullPath) {
            ; SplitPath BaseFolder,, _rootDir ; search up one level for the file_name, recursively
            ; Loop Files _rootDir "\*", "R"
            ; {
                ; If (!fullPath And InStr(A_LoopFileFullPath,"\" inFile)) {
                    ; fullPath := A_LoopFileFullPath
                    ; Break
                ; }
            ; }
        ; }
    }
    
    return fullPath
}