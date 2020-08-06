win32_header_parser() { ; total header files: 3,505
    root := Settings.Has("ApiPath") ? Settings["ApiPath"] : ""
    If (!root) {
        Msgbox "Specify the path for the Win32 headers first."
        return
    }
    
    rootFile := ""
    Loop Files root "\*.h", "R"
    {
        If (A_LoopFileName = "Windows.h") {
            rootFile := A_LoopFileFullPath
            Break
        }
    }
    
    If (!rootFile) {
        Msgbox "Can't find Windows.h`r`n`r`nHalting."
        return
    }
    
    ; msgbox rootFile
    
    startFile := get_full_path("Windows.h")
    fileList := parse_file(startFile)
    
    msgbox "file count: " fileList.Count
    A_Clipboard := jxon_dump(fileList,4)
}

parse_file(file) {
    Static q := Chr(34), outList := Map()
    
    If (outList.Count = 0)
        outList.CaseSense := 0
    
    If (file = "")
        return outList
    
    SplitPath file, curFile
    fText := FileRead(file)
    fArr := StrSplit(fText,"`n","`r")
    
    fileList := ""
    Loop fArr.Length {
        curLine := fArr[A_Index]
        
        rg := "^\#include[ ]+(<|\" q ")([^>" q "]+)(>|\" q ")"
        If (RegExMatch(curLine,rg,m)) {
            fileName := StrReplace(Trim(m.Value(2),"<>" q),"/","\")
            fullPath := get_full_path(fileName)
            
            If (!outList.Has(fileName))
                outList := parse_file(fullPath)
            
            If (outList.Has(curFile)) {
                outList[curFile].Push(fileName)
            } Else {
                outList[curFile] := [fileName]
            }
        }
    }
    
    return outList
}

get_full_path(inFile) {
    fullPath := ""
    root := Settings.Has("ApiPath") ? Settings["ApiPath"] : ""
    If (!root)
        return ""
    
    Loop Files root "\*", "R"
    {
        If (!fullPath And InStr(A_LoopFileFullPath,"\" inFile))
            fullPath := A_LoopFileFullPath
        Else If (fullPath And InStr(A_LoopFileFullPath,"\" inFile))
            Msgbox "Dupe file found:`r`n`r`n" fullPath "`r`n`r`n" A_LoopFileFullPath
    }
    
    return fullPath
}