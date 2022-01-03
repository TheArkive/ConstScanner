; includes_report() {
    ; Global Settings, IncludesList, const_list
    
    ; prof := Settings["Recents"][app.ApiPath]
    ; baseFolders := prof["BaseFolder"] ; array
    
    ; includes_list := []
    ; For item in prof["OtherDirList"]
        ; if (item[2] != 2)
            ; includes_list.Push(item[3])
    
    ; const_list := Map()
    ; IncludesList := Map() ; for user reference after scan is complete
    
    ; Loop { ; try reading and populating the loop simultaneously
        ; do_continue := false
        ; If !includes_list.Has(A_Index)
            ; Break
        
        ; fullPath := includes_list[A_Index]
        
        ; If !FileExist(fullPath)
            ; msgbox("FILE DOES NOT EXIST:`r`n    " fullPath,,"Owner" app.mainGUI.hwnd)
        
        ; IncludesList[incl_short := StrReplace(fullPath,baseFolders[1] "\","")] := Map()
        
        ; fText := FileRead(fullPath)
        ; fArr := StrSplit(fText,"`n","`r")
        
        ; cnt := 1
        ; While (cnt <= fArr.Length) {
            ; curLine := fArr[cnt]
            
            ; If Trim(curLine,"`t ") = "" {
                ; cnt++
                ; Continue
            ; }
            
            ; constValue := "" ; init value
            ; If (RegExMatch(curLine,'i)^\#include[ \t]+(<|")?([^>"]+)(>|")?',&m)) { ; include line
                ; match := StrReplace(StrReplace(m[2],'"',""),"/","\")
                
                ; If !(cur_incl := get_full_path(match,baseFolders)) {
                    ; cur_incl := match
                ; } Else If (!dupe_item_check(includes_list,cur_incl) And Trim(cur_incl," `t") != "")
                    ; includes_list.Push(cur_incl)            ; file list for parsing
                
                ; If (Trim(cur_incl," `t") != "")
                    ; IncludesList[incl_short][match] := cur_incl   ; nested includes list
            ; }
            ; cnt++ ; increment line number
        ; }
        
        ; If (IncludesList[incl_short].Count = 0)
            ; IncludesList.Delete(incl_short)
    ; }
    
    ; incl_report()
; }

dupe_item_check(inArr,inValue) {
    For i, d in inArr
        If d = inValue
            return true
    return false
}

arr_item_exist(inArr,inValue,_case:=false) { ; better name for dupe_item_check() above
    For i, d in inArr {
        If d = inValue && !_case {
            return true
        } Else if d == inValue && _case
            return true
    }
    return false
}

arr_item_index(inArr,inValue) {
    For i, d in inArr
        If d = inValue
            return i
    return 0
}

prune_comments(inText) {
    result := RegExReplace(inText,'(?<!("|:))//.*',"")
    
    if result
        result := RegExReplace(result,'s)/\*.*?\*/',"")
    
    if result
        result := StrReplace(result,"`t"," ") ; replace all tabs with spaces
    
    return RTrim(result," `t")
}

init_macros() {
    list := Map()
    val := Map("value","predefined","params",["items"],"dupe",[],"file","")
    list["sizeof"] := val 
    list["defined"] :=  val
    list["DEFINE_GUID"] :=  val
    list["EXTERN_GUID"] :=  val
    list["DEFINE_GUIDSTRUCT"] :=  val
    list["DEFINE_PROPERTYKEY"] :=  val
    list["DECLARE_INTERFACE_IID"] :=  val
    list["DECLARE_INTERFACE_IID_"] :=  val
    ; list["DECLSPEC_UUID"] := Map("value","predefined","params",["item"],"dupe",[],"file","")
    return list
}

process_define(_in, file_name, lineNum, prof, other:=false) {
    Global Settings, MacroList, prog
         , includes_list, includes_processed, includes_all
         , const_list, const_other, sizeof_list
    
    If RegExMatch(_in, "[ \t]*#[ \t]*define[ \t]+([\w\$]+) *\x28([^\x28\x29]+)\x29[ \t]+(.+)", &m) { ; macro
        const_name := m[1]
        const_value := m[3]
        const_exp := m[0]
        const_type := "Macro"
        
        macro_obj := Map("value",const_value,"params",StrSplit(m[2],","," `t"),"file",file_name,"dupe",[])
        
        If !MacroList.Has(const_name)
            MacroList[const_name] := macro_obj
        Else If (const_value != MacroList[const_name]["value"])
            MacroList[const_name]["dupe"].Push(macro_obj)
        
    } Else If RegExMatch(_in, "[ \t]*#[ \t]*define[ \t]+([\w\$]+)[ \t]+(.+)", &m) { ; const = value
        const_name := m[1]
        const_value := number_cleanup(Trim(m[2]," `t"))
        const_type := "Unknown"
        
        If eval(const_value, true)
            const_value := eval(const_value)
        
        If IsInteger(const_value) {
            const_value := Integer(const_value)
            const_type := "Integer"
        } Else if IsFloat(const_value) {
            const_value := Float(const_value)
            const_type := "Float"
        } Else if RegExMatch(const_value,'^L?".*"$') {
            const_type := "String"
        }
        
        const_exp := m[0]
        
    } Else If RegExMatch(_in, "[ \t]*#[ \t]*define[ \t]+([\w\$]+)", &m) { ; const with no value
        const_name := m[1]
        const_value := ""
        const_type := "Other"
        const_exp := m[0]
        
    } else
        msgbox "Unable to categorize #define:`n`n" _in "`n`nfile: " file_name "`n`nline: " lineNum "`n`nThis should not happen."
    
    commit_item(const_name, make_obj(), other)
    
    expr_do_subs() {
        temp_obj := Map("value",const_value,"type","Unknown","exp",const_value,"dupe",[],"critical",Map())
        return (do_subs(temp_obj,""))["value"]
    }
    
    make_obj() {
        _file := StrReplace(file_name, prof["BaseFolder"][1] "\", "")
        return Map("exp" ,const_exp ,"comment",""
                  ,"file",_file ,"line",lineNum,"value",const_value
                  ,"type",const_type,"dupe",[],"critical",Map())
    }
}

check_braces(_in, exist:=false) {
    StrReplace(_in,"{","{",,&LB)
    StrReplace(_in,"}","}",,&RB)
    StrReplace(_in,"(","(",,&LP)
    StrReplace(_in,")",")",,&RP)
    StrReplace(_in,"[","[",,&LBR)
    StrReplace(_in,"]","]",,&RBR)
    if !exist
        return (LB=RB && LP=RP && LBR=RBR)
    else
        return (LB || RB || LP || RP || LBR || RBR)
}

header_parser() {
    Global Settings, MacroList, prog
         , includes_list, includes_processed, includes_all
         , const_list, const_other, const_cache, sizeof_list, abort_parser
    
    prof := Settings["Recents"][app.ApiPath]
    baseFolders := prof["BaseFolder"] ; array
    
    includes_all := []
    includes_list := []
    
    For item in prof["OtherDirList"] {
        includes_all.Push(item[3])
        if (item[2] != 2)
            includes_list.Push(item[3])
    }
    
    const_list := Map()
    const_other := Map()
    includes_processed := []
    MacroList := init_macros()
    init_sizeof_list() ; reset globals "basic_types" and "sizeof_list"
    
    If prof["CompType"] = "GCC"
        sizeof_list["wchar_t"] := 4
    
    prog := progress2(0, includes_list.Length, "title:Processing Global headers/constants...,parent:" app.mainGUI.hwnd) ; counter was fCount
    
    If prof["ProcGlobals"] {
        If prof["ProcGlobalCache"] { ; loading selected cache file
            cache_file := A_ScriptDir "\cache\" prof["GlobCacheFile"]
            
            If (prof["GlobCacheFile"]="") || !FileExist(cache_file) {
                Msgbox "Invalid cache file specified."
                return
            }
            
            prog.Update(,"Loading Cache","Please wait a moment ...","0-" const_other.Count)
            
            If const_cache["file"] != cache_file { ; reduce HDD usage on cache loading
                txt := FileRead(cache_file)
                _cache := jxon_load(&txt)
                const_cache["file"]  := cache_file
                const_cache["cache"] := _cache
            }
            
            const_other := const_cache["cache"]["__const_list"].Clone()
            sizeof_list := const_cache["cache"]["__sizeof_list"].Clone()
            MacroList   := const_cache["cache"]["__MacroList"].Clone()
            
            _cache := ""
            
            For _const, obj in const_other {                ; Transfer constants from const_other to const_list...
                For i, _file in includes_all {              ; ...if listed include files match.
                    If StrReplace(_file,baseFolders[1] "\","") = obj["file"] {
                        const_list[_const] := obj
                        If !arr_item_exist(includes_processed,_file)
                            includes_processed.Push(_file)
                        Continue
                    }
                }
            }
        } Else {
            If Settings.Has("GlobConst")        ; Global Constants / Macros
                const_other := parse_user_constants(Settings["GlobConst"])
            
            If Settings.Has("GlobMacro")
                parse_user_macros(Settings["GlobMacro"])
            
            If Settings.Has("GlobInclude") {
                For i, _incl in StrSplit(Settings["GlobInclude"],","," ")
                    process_include(get_full_path(_incl, baseFolders), prof) ; depth = 0
            }
        }
    }
    
    If prof.Has("UserConstants") {         ; User Constants / Macro
        user_const := parse_user_constants(prof["UserConstants"],const_other) ; populate const_other
        For _const, obj in user_const
            const_other[_const] := obj
    }
    
    If prof.Has("UserMacros")
        parse_user_macros(prof["UserMacros"])
    
    prog.Title := "Processing selected headers..."
    
    For i, curFile in includes_list {
        If !arr_item_exist(includes_processed,curFile) {
            includes_processed.Push(curFile)
            process_include(curFile, prof)
        }
        
        If abort_parser
            return ; return on abort
    }
    
    _list := (prof["MakeGlobalCache"]) ? const_other : const_list
    
    ; ==============================================
    ; Solve for basic type sizes
    ; ==============================================
    
    ; A_Clipboard := jxon_dump(sizeof_list,4)
    ; Msgbox "Check types BEFORE CLEAN"
    
    delete_list := []
    Loop {
        _match := 0
        
        For _name, _value in sizeof_list {
            If InStr(_value,";") || IsNumber(_value) ; || (sizeof_list.Has(_value) && (_value = sizeof_list[_value]))
                Continue
            Else If sizeof_list.Has(_value)
                sizeof_list[_name] := sizeof_list[_value], _match++
            Else If !IsNumber(_value) && !arr_item_exist(delete_list,_name,true)
                delete_list.Push(_name)
        }
    } Until (!_match)
    
    For i, _name in delete_list
        sizeof_list.Delete(_name)
    
    ; A_Clipboard := jxon_dump(sizeof_list,4)
    ; Msgbox "Check types"
    
    ; ==============================================
    ; look for "Unknown" types that are entities (struct/enum/union) and update the type
    ; ==============================================
    
    _match_list := []
    For i, _list_ in [const_list,const_other] {
        _match := -1
        While (_match != 0) {
            _match := 0
            For _const, obj in _list_ {
                If (obj["type"] != "Unknown")
                    Continue
                If (cValue:=get_const(obj["value"],"value")) {
                    _new_type := get_const(obj["value"],"type")
                    If (_new_type != "Unknown" && _new_type != "") { ;  && _new_type != "Macro")
                        _list_[_const]["type"] := _new_type, _match++, _match_list.Push(_const " / " _new_type)
                        If (_new_type = "Macro")
                            MacroList[_const] := MacroList[obj["value"]]
                        Else If (_new_type="Integer" || _new_type="Float" || _new_type="String")
                            _list_[_const]["value"] := cValue
                    }
                }
            }
        }
    }
    
    ; ==============================================
    ; solve constant values
    ; ==============================================
    
    prevList := ""  ; still need to actually parse constants (maybe)
    Loop {
        curList := reparse1a(A_Index,_list) ; const_list or const_other
        If (curList = prevList || curList = "")
            Break
        prevList := curList
    }
    
    ; ==============================================
    ; Identify Func/FuncA/FuncW instances
    ; ==============================================
    
    ; For _name, obj in const_list {
        ; If RegExMatch(obj["value"],_name "_?[WA]$")
            ; const_list[_name]["type"] := "Other"
    ; }
    
    ; A_Clipboard := jxon_dump(const_list,4)
    ; msgbox "check clipboard 2"
    
    ; A_Clipboard := jxon_dump(sizeof_list,4)
    
    ; ==============================================
    ; Fill in struct vars
    ; ==============================================
    
    For i, _list_ in [const_list,const_other] { ; test struct _MODEMSETTINGS
        prog.Update(,"Filling in struct array sizes",,"0-" _list_.Count)
        
        For _const, obj in _list_ {
            If obj["type"] != "Struct"
                Continue
            prog.Update(A_Index,"Filling in struct array sizes",_const)
            nextPos := 1
            While RegExMatch(_list_[_const]["value"],"\[ *(\w+) *\]",&s,nextPos) {
                If IsInteger(s[1]) {
                    nextPos := s.Pos[0] + s.Len[0]
                    Continue
                }
                If (get_const(s[1],"type") != "Integer") || (get_const(s[1],"value") = "")
                    Break
                
                _list_[_const]["value"] := RegExReplace(_list_[_const]["value"],"\[ *" s[1] " *\]","[" get_const(s[1],"value") "]")
                nextPos := 1
            }
        }
    }
    
    ; ==============================================
    ; Analyze Dupes
    ; ==============================================
    
    ; For _const, obj in _list {
        ; If (obj.Has("dupes") && obj["dupes"].Length && obj["type"] = "Struct") {
            ; del_list := []
            ; For i, d_obj in obj["dupes"] {
                ; val1 := RegExReplace(  obj["value"],"\[ *([\w]+) *\]","[$1]")
                ; val2 := RegExReplace(d_obj["value"],"\[ *([\w]+) *\]","[$1]")
                ; If (val1 = val2)
                    ; del_list.Push(i)
            ; }
            
            ; If del_list.Length
                ; msgbox "del dupe: " _const "`n`n" jxon_dump(del_list,4)
            
            ; Loop del_list.Length {
                
                ; msgbox "removing dupe:`n`n" 
                ; obj["dupes"].RemoveAt(del_list[ del_list.Length - (A_Index-1) ])
            ; }
        ; }
    ; }
    
    ; ==============================================
    ; If caching Global constants
    ; ==============================================
    
    If prof["MakeGlobalCache"] {
        _final := Map("__prof_name"  ,app.ApiPath
                     ,"__const_list" ,const_other.Clone()
                     ,"__sizeof_list",sizeof_list
                     ,"__MacroList"  ,MacroList
                     ,"__cache"      ,true)
        _final_txt := jxon_dump(_final,4)
        _file_name := A_ScriptDir "\cache\" prof["Name"] ".data"
        
        If FileExist(_file_name)
            FileDelete _file_name
        FileAppend _final_txt, _file_name
        
        ; Msgbox "Cache saved to file:`n`n" _file_name
        
        const_cache["file"] := _file_name
        const_cache["cache"] := _final
        
        const_list := const_other.Clone()
        const_other := Map()
    }
    
    ; msgbox "done: " _list.Count
}

process_include(file_name, prof, depth:=0) {
    
    Global Settings, basic_types, MacroList, prog
         , includes_list, includes_processed, includes_all
         , const_list, const_other, sizeof_list, abort_parser
    
    idx := arr_item_index(includes_list, file_name)
    SplitPath file_name, &_file
    
    if idx
        prog.Update(, idx " of " includes_list.Length " - " _file, _file)
    else
        prog.Update(,, _file)
    
    txt_arr := StrSplit(FileRead(file_name),"`n","`r")
    final_txt := []
    final_debug := ""
    
    i := 0
    preproc_nest := []
    prev_preproc := ""
    prev_expr := ""
    
    cur_preproc := ""
    cur_expr := ""
    take_else := false
    
    Static _rgx_types_basic := rgx_types("sizeof_list_basic")
    Static ptr_size := (Settings["GlobScanType"]="x64") ? 8 : 4
    
    While (++i <= txt_arr.Length) {
        
        if abort_parser
            return
        
        prog.Update(i,,_file " (Line " i " of " txt_arr.Length ")","0-" txt_arr.Length)
        
        curLine := prune_comments(txt_arr[i])
        
        _rgx_types := rgx_types()
        
        comment:=""
        lineNum := i ; save line num so it is properly reported when using line concatenation
        concat() ; concat lines ending in "\" or ","
        
        if InStr(curLine,"/*") {
            do_skip_2()
            curLine := Trim(RegExReplace(curLine,"[ \t]*/\*.*","")," `t")
        }
        
        ; dbg("process_include i: " i)
        
        If (curLine = "")
            Continue
        
        if RegExMatch(curLine, "^[ \t]*#[ \t]*(ifndef|ifdef|if|elif|else|endif)(?:[ \t]*(.*))?", &m) {
            
            ; dbg("file: " file_name " / line: " lineNum " / #preproc:   '" m[1] "'")
            
            cur_preproc := m[1]
            cur_expr := (m.Count=2) ? Trim(m[2]," `t") : ""
            
            if RegExMatch(cur_preproc, "^(ifdef|ifndef|if|elif)$") {
                
                if (cur_preproc="elif") && !take_else {
                    curDepth := preproc_nest.Length
                    do_skip()
                    Continue
                }
                
                if RegExMatch(cur_preproc, "^(ifdef|ifndef|if)$")
                    preproc_nest.Push(curLine)
                
                if RegExMatch(cur_preproc,"^ifn?def$")
                    cur_expr := ((cur_preproc="ifndef")?"!":"") "defined(" cur_expr ")"
                
                cur_expr := RegExReplace(cur_expr,"defined[ \t]+(\w+)","defined($1)")
                
                ; dbg("starting do_subs()")
                
                cur_expr := expr_do_subs()
                
                ; dbg("initial cur_expr: " cur_expr)
                
                If !eval(cur_expr, true) {
                    ; dbg("ugh... trying to fix: " cur_expr)
                    cur_expr := expr_do_subs()
                    ; dbg("fixed??:   " cur_expr)
                }
                
                ; dbg("checking cur_expr: " cur_expr)
                
                If eval(cur_expr, true) {
                    old_expr := cur_expr
                    
                    If !(cur_expr := eval(cur_expr)) { ; if expr result = FALSE
                    
                        ; dbg("cur_expr eval / old: " old_expr " / new: " cur_expr)
                        
                        curDepth := preproc_nest.Length
                        take_else := true
                        do_skip()
                        Continue
                    } Else
                        take_else := false
                    
                    ; dbg("whats next?")
                    
                } Else
                    msgbox "Can't parse expression:`n`n     " cur_expr "`n`nfile: " file_name "`nline: " lineNum
                
                ; msgbox "next line"
                Continue
                
            } else if (cur_preproc = "endif") {
                preproc_nest.RemoveAt(preproc_nest.Length)
                take_else := false
                Continue
                
            } else if (cur_preproc = "else") {
                If !take_else {
                    curDepth := preproc_nest.Length
                    do_skip()
                }
                Continue
            }
            
            prev_preproc := cur_preproc
            
        } Else if RegExMatch(curLine,'[ \t]*#[ \t]*include[ \t](?:"|<)([\w\.]+)(?:"|>)',&m) {
            if ( !prof["ProcIncludes"] || !(incl_path := get_full_path(m[1], prof["BaseFolder"])) )
                Continue
            
            If !arr_item_exist(includes_processed, incl_path) {
                includes_processed.Push(incl_path)
                process_include(incl_path, prof, depth+1)
                Continue
            }
                
        } Else if RegExMatch(curLine, '[ \t]*#[ \t]*define') {
            process_define(curLine, file_name, lineNum, prof, do_other())
        
        } Else if RegExMatch(curLine, "[ \t]*#[ \t]*error +(.+)", &m) { ; this shouldn't happen
            abort_parser := true
            msg := "ERROR:`n`n" m[1] "`n`nFile: " file_name "`nLine: " lineNum "`n`nOpen file and highlight line?"
            
            If (Msgbox(msg, "Compiler Error", 20) = "Yes")
                Run(StrReplace(Settings["TextEditorLine"] ' "' file_name '"',"#",lineNum))
            
            return
            
        } Else if RegExMatch(curLine, '[ \t]*#[ \t]*undef[ \t]+(\w+)', &m) { ; process undef lines
        
            if const_list.Has(m[1])
                const_list.Delete(m[1])
            Else If const_other.Has(m[1])
                const_other.Delete(m[1])
            
        }
        Else If (RegExMatch(curLine,"^[ \t]*(?:struct +)?(\w+)[ \t]*\x28", &m)
              && MacroList.Has(m[1]) && RegExMatch(m[1],"(?:UUID|GUID|_IID|PROPERTYKEY)"))
              || RegExMatch(curLine,"__declspec *\x28 *uuid *\x28") {
            
            concat_statement()
            
            ; dbg("GUID func: " curLine " / defined(D3DFMT_X8R8G8B8): " defined("D3DFMT_X8R8G8B8"))
            
            temp_obj := Map("exp" ,curLine,"value",curLine,"type","UUID")
            curLine2 := (do_subs(temp_obj,""))["value"]
            
            test := MacroList.Has("DEFINE_MEDIATYPE_GUID") ? jxon_dump(MacroList["DEFINE_MEDIATYPE_GUID"],4) : ""
            ; dbg("GUID after do_macro: " curLine2 " / has DEFINE_MEDIATYPE_GUID:`n`n" test)
            
            If RegExMatch(curLine,"__declspec *\x28 *uuid *\x28") {
                uuid := GET_UUID(Trim(curLine))
            
            } Else If RegExMatch(curLine2,"[ \t]*(\w+) *\x28(.+)\x29;?",&m) { ; in case the main fnc changes after do_macro()
                fnc := %m[1]%
                params := StrSplit(m[2],","," ")
                
                If !(Type(fnc) = "Func")
                    Msgbox "Unknown UUID/GUID func: " curLine2 "`n`nThis should not happen."
                
                uuid := fnc(params*)
                                
            } Else {
                msgbox "Malformed UUID expression:`n`n" curLine2 "`n`nThis should not happen."
                Continue ; skip malformed UUID expr
                
            }
            
            const_exp := Trim(curLine2,";")
            const_value := uuid[2]
            const_type := "UUID"
            
            commit_item(uuid[1], make_obj(), do_other())
            Continue ; don't record this line into final_txt
            
        }
        
        if RegExMatch(curLine,"^[ \t]*#")
            Continue
        
        final_debug .= (final_txt?"`r`n":"") curLine
        final_txt.Push([lineNum,curLine])               ; record for parse_entities()
        
    }
    
    ; A_Clipboard := final_debug
    
    process_entities(final_txt, prof, file_name)
    
    ; ======================================================
    ; Enclosures
    ; ======================================================
    
    make_obj() {
        _file_ := StrReplace(file_name, prof["BaseFolder"][1] "\", "")
        return Map("exp" ,const_exp ,"comment",""
                  ,"file",_file_ ,"line",lineNum,"value",const_value
                  ,"type",const_type,"dupe",[],"critical",Map())
    }
    
    concat_statement() {
        While (!check_braces(curLine) && !RegExMatch(curLine,";")) { ; concatenate lines
            
            ; dbg("doing concat_statement()")
            
            If check_braces(curLine) && RegExMatch(curLine,";$")
                Break
            
            nextLine := prune_comments(txt_arr[++i])
            curLine .= " " Trim(nextLine," `t")
        }
    }
    
    do_skip_2() {
        
        nextLine := ""
        While !RegExMatch(nextLine,"\*/[ \t]*") {
            ; dbg("doing SKIP 2!:" curLine)
            nextLine := txt_arr[++i]
        }
    }
    
    do_skip() {
        curLine := ""
        remove_depth := false
        rem_depth := ""
        
        While !RegExMatch(curLine,"^[ \t]*#(else|elif|endif)") || (curDepth != preproc_nest.Length) {
            
            if (remove_depth) {
                preproc_nest.RemoveAt(preproc_nest.Length)
                remove_depth := false
            }
            
            If !txt_arr.Has(i+1)
                Break
            
            curLine := prune_comments(txt_arr[++i])
            ; dbg("do_skip: " curLine "`r`n------> depth: " preproc_nest.Length " / file: " file_name " / line: " i)
            lineNum := i ; save line num so it is properly reported when using line concatenation
            
            If RegExMatch(curLine,'MIDL_INTERFACE\x28([\w\-"\{\}]+)\x29',&t) { ; get MIDL UUIDs during skip
                _name := RegExMatch(txt_arr[i+1],"[ \t]*(\w+)",&u)
                If IsObject(u) {
                    _name := u[1]
                    _uuid := "{" StrUpper(Trim(t[1],"{}'`" `t")) "}"
                    _exp := trim(curLine) . "`r`n" Trim(txt_arr[i+1])
                    
                    _file_name := StrReplace(file_name, prof["BaseFolder"][1] "\", "")
                    _obj := Map("exp" ,_exp ,"comment",""
                               ,"file",_file_name ,"line",lineNum,"value",_uuid
                               ,"type","UUID","dupe",[],"critical",Map())
                    commit_item(_name, _obj, do_other())
                }
            }
            
            concat() ; concat lines ending in "\" or ","
            
            if RegExMatch(curLine,"^[ \t]*(#[ \t]*if)")
                preproc_nest.Push(curLine)
            else if RegExMatch(curLine,"^[ \t]*#endif") {
                rem_depth := preproc_nest[preproc_nest.Length]
                remove_depth := true
            }
        }
        
        ; dbg("do_skip: END: " curLine "`r`n------> depth: " preproc_nest.Length " / file: " file_name " / line: " i)
        i := i-1 ; back up one line and process as usual
    }
    
    expr_do_subs() {
        temp_obj := Map("value",cur_expr,"type","Unknown","exp",cur_expr,"dupe",[],"critical",[])
        return (do_subs(temp_obj,"",true))["value"] ; true = allow replacing nonexistent constant with "0"
    }
    
    do_other() {
        If arr_item_exist(includes_all, file_name)
            return false
        Else
            return true
    }
    
    concat() {
        While (SubStr(curLine,-1) = "\" || SubStr(curLine,-1) = ",") { ; concatenate lines
            curLine := (SubStr(curLine,-1) = "\") ? RTrim(curLine,"\ `t") : curLine
            
            If txt_arr.Has(i+1) && RegExMatch(txt_arr[i+1],"^[ \t]*(#)")
                Break
            
            nextLine := prune_comments(txt_arr[++i])
            curLine .= " " Trim(nextLine," `t")
        }
    }
}

process_entities(_in, prof, file_name) { ; enums/structs/unions with and without "typedef"
    Global Settings, basic_types, MacroList, prog
         , includes_list, includes_processed, includes_all
         , const_list, const_other, sizeof_list, sizeof_list_basic
    
    Static ptr_size := (Settings["GlobScanType"]="x64") ? 8 : 4
    
    i := 0
    txt_arr := _in
    SplitPath file_name, &_file
    
    while (++i <= _in.Length) {
        
        if !(curLine := prune_comments(_in[i][2]))
            Continue
        lineNum := _in[i][1]
        concat()
        
        If RegExMatch(curLine,"^[ \t]*(\w+) *\x28([^\x28\x29]+)\x29;$",&r) && MacroList.Has(r[1]) {
            result := do_macro(curLine,"")
            If RegExMatch(result,"^typedef .+?;$")
                curLine := result
        }
        
        curLine2 := prune_entity_semantics(curLine) ; closure
        
        ; dbg("entities curLine2: ===================`r`n" curLine2 "`r`n===================")
        
        _p1 := "", _p2 := "", _p3 := "" ; reset _p#
        
        If !(_isEntity := RegExMatch(curLine2,"^[ \t]*(?:typedef +)?(struct|enum|union|interface)(?!\w)",&entity)) {
            entity := "" ; set entity type
        } Else
            entity := entity[1]
        
        If RegExMatch(curLine,"([^\{]+?)\{(.+)\}(.*);$",&m) {
            _p1 := m[1], _p2 := m[2], _p3 := m[3] ; split entity into 3 parts
            
            if (entity="")
                Continue
            
        } Else If RegExMatch(curLine2, "^[ \t]*(typedef|struct|enum|union|interface)[ \t].+;$") {
            entity_list := [], _p2 := ""
            curLine3 := RegExReplace(curLine2,"( struct| enum| union| interface)","")
            
            _rgx_types := rgx_types()
            ; dbg("entities types: " _rgx_types)
            
            If !RegExMatch(curLine3,"^[ \t]*(?:typedef)?( +unsigned| +signed)? +(" _rgx_types "|\w+)([\* \t][\w, \*\[\]]+);$", &m) {
                If RegExMatch(curLine3,"\(?.*\)?.*\(.*\) *;$") ; usually these are functions
                    Continue
                Else If RegExMatch(curLine2,"^(struct|enum|union|interface) +\w+") ; weird entities with one name
                    Continue
                
                ; msgbox("skipping typedef`n`n---> File: " file_name "`n`n" curLine) ; typedef size_t rsize_t; ?????
                Continue
            }
            
            _p1 := m[2], _p3 := Trim(m[3])
            
        } Else If RegExMatch(curLine2,"^(struct|union|enum|interface) +(\w+);$") {
            MsgBox "what is this?`n`n" curLine
            Continue
        
        } Else If RegExMatch(curLine2,"^[ \t]*(typedef|struct|union|enum|interface) +") {
            
            If !check_braces(curLine)
              || SubStr(curLine,-1) != ";"
                Continue
            
            Msgbox "Entity format problem:`n" ; this should never happen
                 . "File: " file_name "`n"
                 . "Line: " lineNum "`n`n"
                 . curLine "`n`nThis shouldn't happen."
                 
            Continue
        
        } Else {
            ; Msgbox "Not sure what to do here...`n`n" CurLine
            Continue ; go to next line/entity
        }
        
        If _p2 && entity { ; if entity has { body }
            curLine  := fix_indent(_p1,_p2,_p3,entity)
            
            _p2_temp := prune_entity_semantics(_p2)
            
            If (entity = "struct") { ; a struct with #define's that needs replacement
                ; temp_obj := Map("value",_p2_temp,"type","Struct","dupe",[],"critical",Map())
                ; _p2_temp := (do_subs(temp_obj,""))["value"]
            } Else If (entity = "enum") {
                _last_value := ""
                While RegExMatch(_p2,"(\w+) *\x28(.+?)\x29",&v) && MacroList.Has(v[1]) {
                    _p2 := RegExReplace(_p2,"\Q" v[0] "\E",do_macro(v[0],""))
                    If (_p2 = _last_value)
                        Break
                    _last_value := _p2
                }
            }
            
            curLine2 := fix_indent(prune_entity_semantics(_p1)
                                  ,_p2_temp
                                  ,prune_entity_semantics(_p3)
                                  ,entity,true) ; do a "deep fix" on curLine2
        } ; // end if entity has { body }
        Else If (_p2 && !entity)
            Msgbox "Another mangled entity:`n`n" curLine "`n`nThis should not happen."
        
        nameList := []
        _p1 := prune_entity_semantics(_p1)
        _p1 := Trim(RegExReplace(_p1,"(?<!\w)(?:typedef|enum|struct|union|interface)(?!\w)",""))
        
        If _p1
            nameList.Push(_p1)
        
        ; dbg( "silly test:`n`n" jxon_dump(nameList,4) )
        
        If Trim(_p3) {
            _p3 := prune_entity_semantics(_p3)
            For i, _name in StrSplit(_p3,","," `r`n`t")
                if !arr_item_exist(nameList,_name,true) ; case sensitive search
                    nameList.Push(_name)
        }
        
        ; dbg( "silly test 2:`n`n" jxon_dump(nameList,4) )
        
        const_value := curLine      ; value is entire enum { ... }
        
        If (entity = "enum") && InStr(curLine,"{") {    ; enum capture
            const_type := "Enum"                        ; set type
            
            For i, _name in nameList {  ; first enum gets full list, all others refer to first enum
                _name2 := Trim(_name," *")
                const_value := (i=1) ? curLine2 : nameList[1]
                const_exp := (i=1) ? curLine : "Original declaration: " nameList[1]
                obj := make_obj()
                If RegExMatch(_name,"^\*")
                    obj["size"] := ptr_size, obj["pointer"] := true
                commit_item(_name2, obj, do_other())
            }
            
            last_value := String("0"), last_name := ""
            const_type := "Unknown"
            largest := 0
            
            entity_list := StrSplit(_p2,',',"`r`n `t")
            For i, cur_expr in entity_list { ; solving for each enum value to add to list of constants
                If !cur_expr
                    Continue
                
                if (nameList.Length)
                    const_exp := "From Enumeration: " nameList[1]           ; reference where the enum value comes from
                else
                    const_exp := (i=1) ? curLine : "check:" entity_list[1]  ; if no enum name, full list stored in first value expr
                
                If (eq_sep:=InStr(cur_expr,"=")) {
                    const_name := Trim(SubStr(cur_expr,1,eq_sep-1))
                    const_value := Trim(SubStr(cur_expr,eq_sep+1))
                } Else {
                    const_name := Trim(cur_expr)
                    const_value := (i>1) ? (last_value . "+1") : last_value
                }
                
                If (i>1)
                    const_value := RegExReplace(const_value,"(?<!\w)(" last_name ")(?!\w)",last_value)
                If eval(const_value,true)
                    const_value := eval(const_value)
                
                commit_item(const_name, make_obj(), do_other())
                
                last_value := const_value
                last_name  := const_name
            }
            
        } Else If RegExMatch(entity,"^(struct|union|interface)$") && InStr(curLine,"{") {
            const_type := "Struct"      ; set type
            
            For i, _name in nameList {  ; first struct/union gets full list, all others refer to first enum
                _name2 := Trim(_name," *")
                const_value := (i=1) ? curLine2 : nameList[1]
                const_exp := (i=1) ? curLine : "Original declaration: " nameList[1]
                obj := make_obj()
                If RegExMatch(_name,"^\*")
                    obj["size"] := ptr_size, obj["pointer"] := true
                If !(entity="interface") && !(get_const(_name2,"type") = "UUID")
                    commit_item(_name2, obj, do_other())
            }
            
        } Else If (_p1 && _p3 && !_p2) {
            const_exp := curLine
            
            If nameList.Length <= 1 {
                ; msgbox "typedef with ONE or ZERO name(s):`n`n" curLine "`n`nThis should not be captured."
                Continue
            }
            
            entity := RegExReplace(entity,"^(union|interface)$","Struct")
            If (entity = "Struct" || entity = "Enum")
                const_type := StrTitle(entity)
            Else
                const_type := get_const(nameList[1],"type")
            _last_name := ""
            
            ; dbg("entities typedef: " nameList[1] " / type: " const_type " / name2: " nameList[2])
            
            For i, _name in nameList {
                _const := Trim(_name,"* ")
                If (i>1) {
                    If (const_type) {
                        If (const_type != "Struct" && const_type != "Enum") {
                            _const_check := _last_name
                            While (_const_check := get_const(_const_check,"value")) && get_const(_const_check,"type")
                                const_type := get_const(_const_check,"type")
                        }
                        
                        const_value := _last_name
                        obj := make_obj()
                        
                        ; dbg("entities typedef: " nameList[1] " / type: " const_type " / name2: " nameList[2])
                        
                        If RegExMatch(_name,"^\*") {
                            ; dbg("entities typedef: " nameList[1] " / type: " const_type " / name2: " nameList[2])
                            obj["size"] := ptr_size, obj["pointer"] := true
                        }
                        commit_item(_const, obj, do_other())
                    } Else {
                        If RegExMatch(_name,"^\*")
                            sizeof_list[_const] := ptr_size
                        Else
                            sizeof_list[_const] := _last_name
                    }
                }
                _last_name := _const
            }
        }
        Else
            Msgbox "Mangled enum/struct/union?  This shouldn't happen.`n`n" curLine ; this should never happen
    }
    
    make_obj() {
        _file_name := StrReplace(file_name, prof["BaseFolder"][1] "\", "")
        return Map("exp" ,const_exp ,"comment",""
                  ,"file",_file_name ,"line",lineNum,"value",const_value
                  ,"type",const_type,"dupe",[],"critical",Map())
    }
    
    do_other() {
        If arr_item_exist(includes_all, file_name)
            return false
        Else
            return true
    }
    
    concat() {
        ____count := 0
        
        curLine := LTrim(curLine," `t")
        
        If (RegExMatch(curLine,"^(?:\w+ *\x28.+?\x29 +)?(typedef|struct|enum|union|interface)") && check_braces(curLine) && SubStr(curLine,-1) = ";") {
            ; dbg("........ one-liner match: " curLine)
            return
        } Else If _in.Has(i+1) && _in.Has(i+2)
               && RegExMatch(curLine,"^(?:\w+ *\x28.+?\x29 +)?(typedef|struct|enum|union|interface)")
               && (!InStr(curLine,"{") && !InStr(_in[i+1][2],"{") && !InStr(_in[i+2][2],"{")) {
            ; dbg("........ not a match")
            return
        } Else If !RegExMatch(curLine,"^(?:\w+ *\x28.+?\x29 +)?(typedef|struct|enum|union|interface)")
            return
        
        
        Loop {
            ____count++
            ; dbg("entity count: " ____count)
            
            prog.Update(i,,_file " (Entities: Line " i " of " _in.Length ")","0-" _in.Length)
            
            if !(_in.Has(i+1))
                Break
            
            Else If (check_braces(curLine) && SubStr(curLine,-1) = ";")
                Break
            
            Else If RegExMatch(_in[i+1][2],"^[ \t]*typedef")
                Break
            
            if !(nextLine := prune_comments(_in[++i][2]))
                Continue
            curLine .= (curLine?" ":"") LTrim(nextLine," `t")
            
            If ____count > 800 {
                A_Clipboard := curLine
                msgbox "Excessive collection warning`n`nfile: " file_name "`nLine: " lineNum "`nCount: " ____count
            }
        }
        
        if RegExMatch(curLine,"typedef[\r\n \t]+")
            curLine := RegExReplace(curLine,"typedef[\r\n \t]+","typedef ")
    }
    
    prune_entity_semantics(_input,all:=true) {
        If (all) {
            rgx_remove_list := "\[(?:public|private)\]|_Null_terminated_|_NullNull_terminated_|UNALIGNED|_W64|"
            . "__RPC_FAR|far|near|FAR|NEAR|_CONST_RETURN|_WConst_return|RESTRICTED_POINTER|POINTER_64|"
            . "__RPC_string|__RPC__(?:in|out)(?:_opt)?|_COM_Outptr_|CONST|const|" ; not listed below
            . "__RPC_unique_pointer|DECLSPEC_ALIGN\(\d+\)|DECLSPEC_NOINITALL|_Field_z_|"
            . "(?:_Field_size_|_Field_size_opt_|_Field_range_|_Field_size_bytes_|_Field_size_bytes_opt_|_Return_type_success_|_Struct_size_bytes_|"
            . "__RPC__(?:in|out)_ecount_full|" ; not listed below
            . "_WINSOCK_DEPRECATED_BY) *\x28.+?\x29"
        } else {
            rgx_remove_list := "\[(?:public|private)\]|_Null_terminated_|_NullNull_terminated_|UNALIGNED|_W64|"
            . "__RPC_FAR|far|near|FAR|NEAR|_CONST_RETURN|_WConst_return|RESTRICTED_POINTER|POINTER_64|"
            . "__RPC_unique_pointer|DECLSPEC_ALIGN\(\d+\)|DECLSPEC_NOINITALL|_Field_z_|"
            . "(?:_Field_size_|_Field_size_opt_|_Field_range_|_Field_size_bytes_|_Field_size_bytes_opt_|_Return_type_success_|_Struct_size_bytes_|"
            . "_WINSOCK_DEPRECATED_BY) *\x28.+?\x29"
        }
        return RegExReplace(_input,"(?<!\w)(" rgx_remove_list ")(?!\w)","")
    }
}

rpt(str,reps) { ; repeat str
    final_str := ""
    Loop reps
        final_str .= str
    return final_str
}

fix_indent(_p1, _p2, _p3, entity, deep := false) {
    _d := 1, _idt := "    ", _t := " `r`n`t"
            
    curLine := Trim(RegExReplace(_p1,"[\r\n]","")) " {"
    
    If RegExMatch(entity,"^(struct|union|interface)$")
        sep := ";"
    Else If (entity = "enum")
        sep := ","
    Else
        msgbox "Fix Indentation - NO ENTITY:`n`nThis shouldn't happen."
    
    _p2 := RegExReplace(_p2,"\[ *(\w+) *\]","[$1]")
    entity_list := StrSplit(_p2,sep,"`r`n `t")
    
    For i, _line in entity_list { ; reconstruct entity with proper indentation
        _count := 0
        if Trim(_line,_t) {
            If !check_braces(_line) && StrReplace(_line,"{","{",,&_count) && _count {
                nextLine := ""
                For i, _sub_part in (_sub:=StrSplit(_line,"{"," `t")) {
                    if (i=1)
                        nextLine .= rpt(_idt,_d) Trim(_sub_part,_t) " {`r`n"
                    else if (i != _sub.Length)
                        nextLine .= rpt(_idt,++_d) Trim(_sub_part,_t) " {`r`n"
                    else
                        nextLine .= rpt(_idt,++_d) _sub_part sep ; Trim(_sub_part,_t) sep
                }
            } Else If !check_braces(_line) && (sep2:=InStr(_line,"}"))
                nextLine := rpt(_idt,--_d) "} " Trim(SubStr(_line,sep2+1),_t) sep
            Else {
                nextLine := rpt(_idt,_d) _line sep
                nextLine := StrReplace(nextLine,"BEGIN_INTERFACE ","BEGIN_INTERFACE`r`n" rpt(_idt,_d))
                If RegExMatch(nextLine,"(\x28.+?\x29) *\x28([\w \*,\x28\x29]+)\x29 *;",&m) && InStr(nextLine,",") {
                    newChunk := "", fnc_arr := StrSplit(m[2],","," ")
                    For i, _txt_ in fnc_arr
                        newChunk .= (newChunk?"`r`n":"") rpt(_idt,_d+1) _txt_ ((i<fnc_arr.Length)?",":"")
                    newChunk := "`r`n" newChunk
                    nextLine := StrReplace(nextLine,m[2],newChunk)
                }
            }
            
            curLine .= "`r`n" nextLine
        }
    }
    
    curLine := RTrim(curLine,",")
    curLine .= "`r`n} " Trim(RegExReplace(_p3," {2,}"," "),_t) ";"
    
    return curLine
}

commit_item(constName,obj,other:=false) {
    Global const_list, const_other
    
    const_obj := (other) ? const_other : const_list
    
    If (!const_obj.Has(constName)) {
        If (!other) && const_other.Has(constName)
            const_other.Delete(constName)
        const_obj[constName] := obj
        
    } Else If checkDupeConst(const_obj[constName],obj) {
        If (const_obj[constName]["type"] = "Unknown") && (obj["type"] != "Unknown") {   ; Prioritize known types...
            obj["dupe"] := const_obj[constName]["dupe"]                                 ; ...move "Unknown" types to dupes.
            const_obj[constName]["dupe"] := []
            obj["dupe"].Push(const_obj[constName])
            const_obj[constName] := obj
            
        } Else If (const_obj[constName]["value"] != obj["value"]) {
            (!const_obj[constName].Has("dupe")) ? const_obj[constName]["dupe"] := [] : ""
            const_obj[constName]["dupe"].Push(obj)
        }
    }
}

create_cpp_file(sizeof:=false,const_ovr:="") {
    Global Settings, const_list, sizeof_list
    
    prof := Settings["Recents"][app.ApiPath]
    cppFile := ""
    
    pre_const1 := (prof["ProcGlobals"]) ? parse_user_constants(Settings["GlobConstComp"]) : Map()
    pre_const2 := parse_user_constants(prof["UserConstants"]) ; process profile constants
    
    For const, obj in pre_const2 ; combine pre_const2 into pre_const1
        pre_const1[const] := obj
    
    For const, obj in pre_const1
        cppFile .= "#define " const " " obj["value"] "`r`n"
    
    inc_list := prof["OtherDirList"]
    
    If DirExist(Settings["GlobBaseFolder"]) ; ----- BaseFolder not use??? ... oops
        BaseFolder := Settings["GlobBaseFolder"]
    Else
        BaseFolder := prof["BaseFolder"][1]
    
    def_inc := []
    If prof["ProcGlobals"] ; process global includes?
        def_inc := StrSplit(Settings["GlobInclude"],","," ")
    
    If !Settings["AddIncludes"] { ; add ALL includes ONLY if ...
        For item in inc_list {
            If (item[2] != 2)
                def_inc.Push(item[3])
        }
    }
    
    row := 0, includes := [], constants := []
    While (row := app.mainGUI["ConstList"].GetNext(row,"C")) {  ; list constants
        constants.Push(_const:=app.mainGUI["ConstList"].GetText(row))
        SplitPath const_list[_const]["file"], &_new_file
        def_inc.Push(_new_file)
    }
    
    cppFile .= "`r`n#include <iostream>`r`n" ; basic cpp include
    
    For _file in def_inc {
        SplitPath _file, &file_Name
        cppFile .= "#include <" file_name ">`r`n" ; was rootFile
    }
    
    cppFile .= "`r`nint main() {`r`n"
    
    If (FileExist("test_const.cpp"))
        FileDelete "test_const.cpp"
    If (FileExist("test_const.exe"))
        FileDelete "test_const.exe"
    If (FileExist("test_const.obj"))
        FileDelete "test_const.obj"
    
    _count := 0, _num := 1
    For const in constants {
        obj := const_list[const]
        If !RegExMatch(obj["type"],"i)^(Integer|Float|String|Struct|Unknown)$")
            Continue
        Else _count++
        
        obj := const_list[const]
        _is_typedef := !!RegExMatch(obj["value"],"^[ \t]*typedef")
        
        If RegExMatch(obj["type"],"^(Integer|Float|Unknown)$") {
            cppFile .= '    std::cout << "' const ' = " << ' const ' << std::endl;`r`n'
        
        } Else If (obj["type"] = "String") {
            cppFile .= '    std::cout << "' const ' = " << sizeof(' const ') << std::endl;`r`n'
        
        } Else If (obj["type"] = "Struct") && InStr(obj["value"],"{") {
            cppFile .= '    struct ' const ' _test_const_' _num ';`r`n'
                     . '    std::cout << "' const ' = " << sizeof(_test_const_' _num ') << std::endl;`r`n'
            _num++
        } Else if (obj["type"] = "Struct") && !InStr(obj["value"],"{") {
            cppFile .= '    ' const ' _test_const_' _num ';`r`n'
                     . '    std::cout << "' const ' = " << sizeof(_test_const_' _num ') << std::endl;`r`n'
            _num++
        }
    }
    
    cppFile .= "`r`n    return 0;`r`n}"
    FileAppend cppFile, "test_const.cpp"
    
    return !!_count
}

; ============================================================================================
; ============================================================================================

reparse1a(pass,_list) { ; constants that point to a single constant / any type
    Global const_list, const_other, MacroList, prog
    t := 0, list := ""
    
    Static uuid_rgx := "i)^\{?[\da-f]{8}\-[\da-f]{4}\-[\da-f]{4}\-[\da-f]{4}\-[\da-f]{12}\}?$"
         , str_rgx  := '^(?:L?".*?"|\x28 *L?".+?" *\x29)$'
    
    prog.Title := "Calculating Constants..."
    prog.Range("0-" _list.Count)
    prog.Update(0,"Pass #" pass)
    
    For const, obj in _list {
        prog.Update(A_Index,,const)
        
        If (obj["type"] = "unknown") {
            If IsInteger(obj["value"])
                obj["type"] := "Integer"
            Else If IsFloat(obj["value"])
                obj["type"] := "Float"
            Else If RegExMatch(obj["value"],str_rgx) {
                obj["type"] := "String"
                obj["value"] := Trim(obj["value"],"() `t")
            } Else If RegExMatch(obj["value"],uuid_rgx)
                obj["type"] := "UUID"
            Else
                obj := do_subs(obj,const)
            
            _list[const] := obj
            
            t++, list .= const "`r`n"
        }
    }
    
    return list
}

parse_user_constants(uc, in_obj:="") { ; , other:=false <-- old last param
    const_obj := (in_obj) ? in_obj : Map()
    
    uc := RegExReplace(uc,"(\\r)?\\n","`r`n") ; shouldn't need this
    
    Loop Parse uc, "`n", "`r"
    {
        _line := prune_comments(A_LoopField)
        If !_line || RegExMatch(_line,"^[ \t]*;")
            Continue
        
        var := Trim(SubStr(_line,1,t:=InStr(_line,"=")-1)," `t`r`n")
        val := Trim(SubStr(_line,t+2)," `t`r`n")
        If RegExMatch(val,"i)^0x[a-f0-9]+$") || IsInteger(val)
            val := Integer(val)
        Else If IsFloat(val)
            val := Float(val)
        
        const_obj[var] := Map("value",val,"type",Type(val),"dupe",[],"critical",Map(),"exp",_line,"file","")
    }
    return const_obj
}

parse_user_macros(um) {
    Global MacroList
    usr_macros := StrSplit(um,"`n","`r")
    
    i := 0
    
    while (++i <= usr_macros.Length) {
        If !(c_line := Trim(usr_macros[i]," `t"))
            Continue
        
        While SubStr(c_line,-1) = "\"
            c_line := Trim(SubStr(c_line,1,-1)," `t") Trim(usr_macros[++i]," `t")
        
        RegExMatch(c_line,"(\w+)(\x28[^\x29]+\x29)[ \t]*(.+)",&m)
        
        If !IsObject(m) || (m.Count < 2) {
            Msgbox "Malformed macro:`n`n" c_line "`n`nExcluding this macro."
            Continue
        }
        
        MacroList[m[1]] := Map("value",m[3],"params",StrSplit(m[2],","," `t()"),"file","")
    }
    
    return MacroList
}

do_casting(_in) {
    Global sizeof_list, Settings
    result := _in
    pattern1 := "\x28 *(signed +|unsigned +)?(" (_rgx_types:=rgx_types()) "|\w+) *\x29 *(\-?[\d\.]+)"
    pattern2 := "\x28 *(signed +|unsigned +)?(" _rgx_types "|\w+) *\x29 *\x28 *(\-?[\d\.]+) *\x29"
    
    ; dbg("do_casting: " _in "`r`n ---> pattern: " _rgx_types)
    
    While RegExMatch(result,pattern1,&m) || RegExMatch(result,pattern2,&m) {
        orig_num := m[3]
        _type := m[2]
        _alt_type := get_const(_type,"type")
        _alt_size := get_const(_type,"size")
        
        If sizeof_list.Has(_type) || (_alt_type = "Enum") || (_alt_size) {
            _size := (_alt_type="Enum") ? 4 : (_alt_type="Struct" && _alt_size) ? _alt_size : sizeof_list[_type] ; assume enum is 4-bytes for now
            hex := "0x" rpt("FF",_size)
            new_val := orig_num & hex
            
            If (orig_num < 0 && _size=4 && Settings["GlobScanType"] = "x64")
                new_val := new_val << 32 >> 32 ; properly convert negative numbers
            
            result := RegExReplace(result,"\Q" m[0] "\E",new_val)
            
            ; dbg("type: " _type " / size: " _size " / orig val: " orig_num " / new val: " new_val)
        } Else
            Break
    }
    
    ; dbg("do_casting done: " result)
    
    return result
}

do_subs(obj,const,allow_zero:=false) {
    Global Settings, MacroList, sizeof_list
    
    Static rgx := "([\w\$]+(?:[ \t]*\x28)?)" ; match const or func
    Static special_words  := "__declspec|deprecated|defined"
    Static special_words2 := "BEGIN_INTERFACE|END_INTERFACE|STDMETHODCALLTYPE|REFIID"
    
    prof := Settings["Recents"][app.ApiPath]
    cValue := obj["value"]
    
    dbg("---------------------- do_subs: new const: " const " = " cValue)
    
    If const && RegExMatch(cValue,"(?<!\w)\Q" const "\E(?!\w)") { ; rare instances
        obj["type"] := "Other"
        return obj
    }
    
    const_check := const, entity_check_type := "", entity_check_value := ""
    While (const_check && (const_check := get_const(const_check,"value")) && get_const(const_check,"type")) {
        entity_check_type := get_const(const_check,"type") ; probe into const reference to const, find type
        entity_check_value := get_const(const_check,"value")
        
        ; if const
            ; dbg("const: " const " / entity_check: type: " entity_check_type " / value: " entity_check_value)
    }
    
    If (entity_check_type) {
        obj["type"] := entity_check_type
        If (entity_check_type="Integer" || entity_check_type="Float" || entity_check_type="String")
            obj["value"] := entity_check_value
        
        ; if const
            ; dbg("const: " const " / entity_check: type: " entity_check_type " / value: " entity_check_value)
        
        return obj
    }
    
    nextPos := 1
    Loop { ; const_type
        
        curPos := RegExMatch(cValue, "i)" rgx, &m, nextPos) ; the initial match
        ; dbg("curPos: " curPos)
        If (!curPos || nextPos >= StrLen(cValue)) {
            ; dbg("did we break?")
            Break
        }
        
        match := m[1]
        match_type := get_const(match,"type")
        match_value := get_const(match,"value")
        
        ; dbg("do_subs match: " match " / value: " match_value)
        
        If (match = "") {
            Msgbox "do_subs: Blank match: const: " const "`n`ncValue: " cValue "`n`nThis should not happen."
            ; dbg("do_sub cur const: " const)
            ; dbg("no match: cValue: " cValue " / nextPos: " nextPos " / curPos: " curPos)
            Break
        }
        
        If match_type && (match_value = "") && !allow_zero
            Break
        
        If const && match_type && (RegExMatch(match_value,"(?<!\w)\Q" match "\E(?!\w)")
                               ||  RegExMatch(match_value,"(?<!\w)\Q" const "\E(?!\w)"))
                               && !sizeof_list.Has(match) && (match_type != "Enum") && (match_type != "Struct") {
            
            obj["type"] := "Other"
            return obj ; match constains itself or const, making an infinite loop if parsed/replaced
        }
        
        If ((new_cValue := RegExReplace(cValue,"(!|~) +","$1")) != cValue) { ; remove spaces between ! or ~ and expression
            cValue := new_cValue
            nextPos := 1
            ; dbg("remove space in !|~[ ]+: " cvalue)
            Continue
        }
        
        If RegExMatch(cValue,"~\-?(0x[\da-f]+|\d+)",&o) && IsInteger(o[1]) { ; perform bitwise NOT math
            cValue := RegExReplace(cValue,o[0],~o[1])
            nextPos := 1
            ; dbg("do_subs bitwise not: " cValue)
            Continue
        }
        
        If (SubStr(match, -2) = " (") && MacroList.Has(m_match:=Trim(match," `t(")) { ; fix spaced func[ ](
            cValue := RegExReplace(cValue,"\Q" match "\E",m_match "(")
            nextPos := 1
            Continue
        }
        
        If RegExMatch(cValue,"(" special_words ")\x28.+?\x29",&n,m.Pos[0])
        || RegExMatch(cValue,"(" special_words2 ")",&n,m.Pos[0]) {    ; skip past certain functions entirely
            nextPos := n.Pos[0] + n.Len[0]
            ; dbg("const: " const " / special word skip: " n[0] " / nextPos: " nextPos)
            Continue
        } Else If (SubStr(match,-1) = "(") {                                    ; skip past macros(
            nextPos := m.Pos[0] + m.Len[0]
            Continue
        }
        
        ; if const
            ; dbg("cValue main Loop: " cValue " / match: " match " / defined: " defined(match))
        
        if (match_type = "Macro") || (match_type = "Enum") || (match_type = "Struct") || (match_type = "UUID")
          || sizeof_list.Has(match) || IsNumber(match) || !RegExMatch(match,"i)\w") { ; pass by elements not meant to be replaced
            ; dbg("do_sub cur const: " const)
            ; dbg("do_subs: Enum/Macro/Struct moving along...")
            
            nextPos := m.Pos[0] + m.Len[0]
            Continue
        }
        
        ; ================================================================================
        ; ================================================================================
        
        ; For i, item in obj["dupe"] { ; indicates there may be an alternate value for const
            ; if (obj["type"] != "Other" && obj["type"] != "Unknown")
                ; obj["critical"][match] := item ; link values based on const with dupe
        ; }
        
        If !defined(match) && allow_zero { ; replace undefined constant with "0" if allow_zero=true
            cValue := RegExReplace(cValue, "(?<!\w)" match "(?!\w)", "0")
            nextPos := 1
            
            ; dbg("do_sub cur const: " const)
            ; dbg("replace match with no value: " match " / nextPos: " nextPos " / cValue: " cValue)
        
        } Else If defined(match)            ; do sub with constant
               && !sizeof_list.Has(match) { ; make sure matched constant is not in sizeof_list
            
            If IsInteger(repl_value := get_const(match,"value"))
                repl_value := Integer(repl_value)
            Else If IsFloat(repl_value)
                repl_value := Float(repl_value)
            
            first_part := SubStr(cValue,1,m.Pos[0]-1)
            last_part  := SubStr(cValue,m.Pos[0]+m.Len[0])
            cValue := first_part . repl_value . last_part
            nextPos := 1
            
            ; dbg("do_sub cur const: " const)
            ; dbg("do const sub: " cValue " / match: " match " / value: " repl_value)
            
            Continue
        } Else if !allow_zero {
            nextPos := nextPos := m.Pos[0] + m.Len[0]
        }
        
        ; dbg("do_sub cur const: " const)
        ; dbg("infinite loop? nextPos: " nextPos " / cValue: " cValue " / match: " match " / match value: " get_const(match,"value"))
    }
    
    ; dbg("do_subs: after the break/loop")
    
    ; dbg("do_subs: first loop done: " cValue)
    
    temp_cValue := cValue
    
    Loop {
        
        Static macro_rgx := "([\w_]+)[ ]*\x28"
        If RegExMatch(cValue, macro_rgx) {
            dbg("do_subs: macro loop: " cValue)
            cValue := do_macro(cValue,const)
        }
        
        dbg("do_subs: after do_macro(): " cValue)
        
        cValue := number_cleanup(cValue)
        
        dbg("do_subs: after number_cleanup(): " cValue)
        
        While RegExMatch(cValue,"(L?'[\w \\]+')",&m) { ; replace 'text' with number
            cValue := RegExReplace(cValue,"\Q" m[0] "\E",str_to_num(m[1]))
            ; dbg("do_subs: replace 'txt': " cValue)
        }
        
        dbg("do_subs: after replace 'text' with number: " cValue)
        
        While RegExMatch(cValue,"i)(?<!\w)(\x28[^\x28\x29a-z]+\x29)",&q) && eval(q[1],true) ; process ( expr )
            cValue := StrReplace(cValue,q[1],eval(q[1]))
        
        dbg("do_subs: after eval(): " cValue)
        
        cValue := do_casting(cValue)
        
        dbg("do_subs: after casting: " cValue)
        
        If (temp_cValue = cValue)
            Break
        
        temp_cValue := cValue
    }
    
    obj["value"] := cValue ; record the furthest progress of substitutions, prior to final eval()
    
    dbg("const final value: " cValue)
    
    If (obj["type"] = "Unknown") {
        uuid := StrSplit(cValue,","," ")
        If (uuid.Length = 11) {
            uuid := DEFINE_GUID(const,uuid*)
            obj["value"] := uuid[2]
            obj["type"] := "UUID"
            return obj
        }
    }
    
    ; =================================
    ; =================================
    
    If (eval(cValue,true)) { ; attempt to do numerical evaluation
        cValue := eval(cValue)
        cValue := do_casting(cValue)
        
        If IsInteger(cValue) {
            obj["type"]  := "Integer"
            obj["value"] := Integer(cValue)
        } Else If IsFloat(cValue) {
            obj["type"]  := "Float"
            obj["value"] := Float(cValue)
        }
    }
    
    ; dbg("do_subs: complete: " obj["value"])
    
    return obj
}

str_to_num(_in) {
    result := 0
    ; dbg("str_to_num: begin: " _in)
    If RegExMatch(_in,"i)^'\\x([\da-f]+)'$",&a)
        result := Integer("0x" a[1])
    Else If RegExMatch(_in,"^'\\(\d+)'$",&a)
        result := Integer(a[1])
    Else {
        result := 0
        transpose := (StrLen(_in:=Trim(_in,"'")) - 1)
        
        Loop Parse _in
        {
            ; dbg("str_to_num: Len: " transpose " / char: " A_LoopField)
            result := result | (Ord(A_LoopField) << (8 * transpose--))
        }
    }
    ; dbg("str_to_num: result: " result)
    return result
}

get_const(_in,cat) {
    Global const_list, const_other
    
    If const_list.Has(_in) && const_list[_in].Has(cat)
        return const_list[_in][cat]
    Else If const_other.Has(_in) && const_other[_in].Has(cat)
        return const_other[_in][cat]
    Else
        return ""
}

do_macro(fnc,const) {
    Global sizeof_list, MacroList
    Static macro_rgx := "([\w_]+)[ \t]*\x28([^\x28\x29]+)\x29"
    Static spec_mac := "__declspec|deprecated"
    
    ; dbg("---------------------- begin macro: " fnc " /// const: " const)
    
    casting := "\x28 *(" rgx_types() ") *\x29"
    
    solve_expressions()
    
    startPos := 1
    temp_fnc := blank_out_str(fnc)
    
    While (pos := RegExMatch(temp_fnc, macro_rgx, &m, startPos)) { ; inner-most macros - no embedded functions?
        
        ; dbg("do_macro 1: " fnc " / macro_name: " m[1])
        macro_name := m[1]
        
        If !MacroList.Has(macro_name) {
            ; dbg("missing macro: " macro_name " / StartPos: " startPos " / fnc: " fnc)
            return fnc
            
        } Else If RegExMatch(macro_name,"^(" spec_mac ")$") { ; list of "special macros" to skip
            startPos += m.Len[0] + 1
            Continue
            
        } 
        
        ; dbg("made it through: " m[0])
        ; dbg("do_macro: file: " MacroList[macro_name]["file"])
        
        param_range := SubStr(fnc,m.Pos[2],m.Len[2])    ; extract param range from fnc
        
        dbg("param_range: " param_range " / macro name: " macro_name " / fnc: " fnc)
        
        params := StrSplit(param_range,","," `t()")
        param_names := MacroList[macro_name]["params"]
        
        macro_value := MacroList[macro_name]["value"]
        
        dbg("macro_value 1: '" macro_value "' / macro name: " macro_name " / value: " MacroList[macro_name]["value"])
        
        if (params.Length != param_names.Length) && (macro_value != "predefined") { ; param count mismatch
            ; dbg("params don't match...")
            return
        }
        
        ; dbg("param count good")
        
        If !(macro_value = "predefined") {
            ; dbg("do_macro: start param subs: " macro_value)
            for i, pname in param_names { ; replace params with values
                _typ := get_const(params[i],"type")
                if (_typ = "Struct" || _typ = "Enum") ; skip macros that accept struct/enum as a parameter for now
                    return fnc
                macro_value := rpl_param(pname,params[i],macro_value)
            }
            ; dbg("do_macro: end param subs: " macro_value)
        } else {
            macro_value := %macro_name%(params*)
            
            if (Type(macro_value) = "Array") || (macro_value="") {
                dbg("macro: return predef value: " fnc)
                return fnc
            }
            Else
                dbg("macro_value predefined: '" macro_value "'")
            
        }
        
        if (macro_value!="") {
            if eval(macro_value,true)
                macro_value := eval(macro_value)
            
            first_part  := SubStr(fnc,1,m.Pos[0]-1)         ; 3-step process, more precise replacement
            second_part := SubStr(fnc,m.Pos[0]+m.Len[0])
            fnc := first_part . macro_value . second_part
            
            dbg("final fnc in loop: " fnc)
            
            startPos := 1
        } else
            startPos += m.Len[0]
        
        solve_expressions()
        temp_fnc := blank_out_str(fnc)
    }
    
    ; dbg("do_macro: " const ": " fnc)
    
    return (eval(fnc,true)) ? eval(fnc) : fnc
    
    ; ==========================================================
    ; Enclosures
    ; ==========================================================
    
    solve_expressions() {
        prev_fnc := fnc
        
        While RegExMatch(fnc,"(?<!\w)(\x28[^\x28\x29]+\x29)",&m) {
            
            if m[1] && eval(m[1],true) {
                prev_fnc := fnc
                fnc := RegExReplace(fnc, "\Q" m[1] "\E", eval(m[1]))
                startPos := 1
            } Else Break
            
            If (prev_fnc = fnc) ; don't infinite loop
                Break
        }
    }
    
    get_macro(macro,&predef:=0) {
        For _const, obj in MacroList {
            If RegExMatch(_const,"^" macro "[ \t]*\(.+?\)") {
                If (obj["value"] = "predefined")
                    predef := true
                return _const
            }
        }
    }
    
    rpl_param(x,y,_in_value) { ; x = param name, y = value
        ; dbg("do_macro: end param subs INTERNAL: " _in_value)

        While RegExMatch(_in_value," *## *\Q" x "\E(?!\w)")
            _in_value := RegExReplace(_in_value," *## *\Q" x "\E(?!\w)",y)
        
        While RegExMatch(_in_value,"(?<![\w#])\Q" x "\E *## *")
            _in_value := RegExReplace(_in_value,"(?<![\w#])\Q" x "\E *## *",y)
        
        While RegExMatch(_in_value,"#\Q" x "\E(?!\w)")
            _in_value := RegExReplace(_in_value,"#\Q" x "\E(?!\w)",y)
        
        While RegExMatch(_in_value,"(?<!\w)\Q" x "\E(?!\w)")
            _in_value := RegExReplace(_in_value,"(?<!\w)\Q" x "\E(?!\w)",y)
        
        return _in_value
    }
}

blank_out_str(_in) {
    _in := StrReplace(_in,"\\","**") ; prevent confusion with \\" or \\'
    _in := StrReplace(_in,'\"',"**") ; prevent premature string end \"
    _in := StrReplace(_in,"\'","**") ; prevent premature string end \'
    
    While RegExMatch(_in,"('.+?')",&m) || RegExMatch(_in,'(".+?")',&m) {
        If m[1]
            _in := RegExReplace(_in,'\Q' m[1] '\E',rpt("*",StrLen(m[1])))
    }
    
    return _in
}

; ===========================================================
; Pre-Defined macros
; ===========================================================

defined(_in) {
    Global const_list, const_other
    return (const_list.Has(_in)) ? true : (const_other.Has(_in)) ? true : false
}

GUID_CLEAN(const,p*) {
    for i, val in p {
        
        if Type(val) = "Array"
            msgbox "GUID_CLEAN:`n`n" const "`n`n" jxon_dump(p,4)
        
        If !IsNumber(val := RegExReplace(val,"[\{\}\;]",""))
            val := expr_do_subs(val)
        
        If !IsNumber(val)
            msgbox "Invalid parameter:`n`nconst: " const "`n`nval: " val "`n`nvalues:`n`n" jxon_dump(p,4)
        
        If (i=1)
            p[i] := Format("{:08X}",Trim(val,"()"))
        Else If (i=2 || i=3)
            p[i] := Format("{:04X}",Trim(val,"()"))
        Else If (i>=4)
            p[i] := Format("{:02X}",Trim(val,"()"))
    }
    return p
    
    expr_do_subs(_in) {
        temp_obj := Map("value",_in,"type","Unknown","exp",_in,"dupe",[],"critical",Map())
        return (do_subs(temp_obj,""))["value"]
    }
}

GUID_STR(u*) {
    return "{" u[1] "-" u[2] "-" u[3]  "-" u[4] u[5] "-" u[6] u[7] u[8] u[9] u[10] u[11] "}"
}

DEFINE_GUID(const, p*) {
    p := GUID_CLEAN(const, p*)
    return [const,GUID_STR(p*)]
}

EXTERN_GUID(const, p*) {
    return DEFINE_GUID(const, p*)
}

DEFINE_GUIDSTRUCT(uuid, const) {
    return [const,"{" Trim(uuid,'"') "}"]
}

DEFINE_PROPERTYKEY(const, p*) {
    idx := p[p.Length]
    p.RemoveAt(p.Length)
    p := GUID_CLEAN(const, p*)
    return [const,GUID_STR(p*) "," idx]
}

DECLSPEC_UUID(uuid) {
    return "{" Trim(uuid,'"') "}"
}

DECLARE_INTERFACE_IID(p*) {
    iid := "{" Trim(p[2],'"{}') "}"
    return [ p[1] , iid ]
}

DECLARE_INTERFACE_IID_(p*) {
    return DECLARE_INTERFACE_IID(p[1],p[3])
}

GET_UUID(str) { ; try to sort through more obscure declarations of UUIDs
    If RegExMatch(str,"^(?:class|interface) +__declspec *\x28 *uuid *\x28 *(.+?) *\x29 *\x29 +(\w+);$",&m)
        return [ m[2] , "{" Trim(m[1],'"{}') "}" ]
}

sizeof(item) {
    Global sizeof_list, const_list
    
    If get_const(item,"type") = "String"
        item := get_const(item,"value")
    
    dbg("sizeof_list: " item)
    
    If RegExMatch(item,'^L?".*?"$') {
        wide := (InStr(item,"L") = 1)
        item := Trim(LTrim(item,"L"),'"')
        If StrLen(item) > 1
            item := RegExReplace(item,"\\(.)","$1")
        return (StrLen(item)+1) * (wide?2:1)
        
    } Else If sizeof_list.Has(item)
        return sizeof_list[item]
    Else If (_size := get_const(item,"size"))
        return _size
    Else If RegExMatch(item,"^\w+ *\*")
        return sizeof_list["__int3264"]
    Else
        return ""
}




; ===========================================================
; end Pre-Defined macros
; ===========================================================

checkDupeConst(main,dupe) {
     curExp := StrReplace(main["exp"]," ",""),  curVal := main["value"]
    dupeExp := StrReplace(dupe["exp"]," ",""), dupeVal := dupe["value"]
    
    If (curExp != dupeExp && curExp != "(" dupeExp ")") && (curVal != dupeVal && curVal != "(" dupeVal ")")
        return true
    Else
        return false
}

number_cleanup(inValue) { ; TRANSACTION_OBJECT_PATH
    Static typs    := "U?I8|U?I16|U?I32|U?I64|ULL|UI|LL|UL|U|L|I"
    Static flt     := "(\d+\.\d+(?:e\+\d+|e\-\d+|e\d+)?)f?"
    Static hex     := "(0x[\dA-F]+)(?:" typs ")?"
    Static int     := "(\d+)(?:" typs ")"
    
    result := inValue, last_result := ""
    
    While RegExMatch(result,"i)" flt, &x)
       || RegExMatch(result,"i)" hex, &y)
       || RegExMatch(result,"i)" int, &z) {
       
        If IsObject(x) && x.Count       ; float
            result := RegExReplace(result,"(?<!\w)\Q" x[0] "\E(?!\w)",Float(x[1]))      ; Prevent accidental replacement of unsought types...
        Else If IsObject(y) && y.Count  ; hex
            result := RegExReplace(result,"(?<!\w)\Q" y[0] "\E(?!\w)",Integer(y[1]))    ; ... ie ui128
        Else If IsObject(z) && z.Count  ; int
            result := RegExReplace(result,"(?<!\w)\Q" z[0] "\E(?!\w)",Integer(z[1]))
        
        If (last_result = result)
            Break
        
        last_result := result
    }
    
    return result
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


