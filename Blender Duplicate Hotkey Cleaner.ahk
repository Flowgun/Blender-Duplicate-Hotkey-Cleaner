#NoEnv
#Requires AutoHotkey v1
SetBatchLines -1
#SingleInstance Force
#Persistent 
#WinActivateForce

if (!A_IsAdmin) {
	Run % "*RunAs " A_ScriptFullPath,, UseErrorlevel
	ExitApp
}

FileSelectFile, HotkeyFile, 3, % A_appdata "\Blender Foundation\Blender", Choose your Hotkey file to clean, *.py
if (!HotkeyFile)
	ExitApp

FileRead, content, % HotkeyFile
arr:=SplitByCondition(content, Func("SplitCondition"))
DuplicateArray:={}
AllRemovedArray:={}
for key, value in arr
{
	loop, parse, value, `n, `r
	{
		if (instr(A_loopfield, "(""")){	;; if we have a hotkey
			;;; one-line hotkeys
			if (instr(A_loopfield, """type"":"))
				HotkeyBlock:= trim(A_loopfield," `t[")
			else{ ; multi-line hotkey
				HotkeyBlock:= ExtractBracketedBlock(value, A_loopfield)
				if !instr(HotkeyBlock,"""type"":") or instr(HotkeyBlock,"""type"":",,,2)
					continue
			}

			value:= RemoveDuplicateBlocks(value, HotkeyBlock, Duplicate)
			if (Duplicate)
				DuplicateArray.push(Duplicate)
		}
	}
	arr[key]:= value
	for x,Duplicate in DuplicateArray
		value:= strReplace(value,Duplicate "`n","")
	AllRemovedArray.push(value)
}
SplitPath, HotkeyFile,, OutDir, OutExtension, OutNameNoExt
CleanedFile:= OutDir "\" OutNameNoExt "_Cleaned." OutExtension
RemovedFile:= OutDir "\" OutNameNoExt "_AllDuplicateRemoved." OutExtension
FileDelete, % CleanedFile
FileDelete, % RemovedFile

SaveArrayToFile(arr, CleanedFile, Addedseparator:="")
SaveArrayToFile(AllRemovedArray, RemovedFile, Addedseparator:="")
msgbox,4096,Complete, % "Complete!"

for window in ComObjCreate("Shell.Application").Windows
{
	folder := window.Document.Folder
	if (folder.Self.Path = OutDir){
		WinActivate, % "ahk_id " window.HWND
		ExitApp
	}
}
run, % OutDir
ExitApp

;;;-------------
SplitCondition(line) {
    return InStr(line, " (") = 1
}
;;;-------------
SplitByCondition(text, conditionFunc) {
    arr := []
    Loop, Parse, text, `n, `r
    {
		line := A_LoopField
        if (conditionFunc.Call(line)) {
            if (block) {
                arr.Push(RTrim(block, "`r`n"))
                block := ""
            }
        }
        block .= line "`n"
    }
    if (block != "") {
        arr.Push(RTrim(block, "`r`n"))
    }
    return arr
}
;;;-------------
RemoveDuplicateBlocks(haystackText, needleText, ByRef allRemovedText := "") {
    CleanNeedle := Func("TrimNeedleBlock")
    allText := haystackText
    count := 0
    Loop {
        block := CleanNeedle.Call(allText, needleText, countFound := false)
        if (block = "")
            break
        allText := StrReplace(allText, block, "",, 1)
        count++
    }
    allRemovedText := (count > 1) ? needleText : ""
    cleaned := ""
    found := false
    Loop {
        block := CleanNeedle.Call(haystackText, needleText, countFound := false)
        if (block = "")
            break
        if (!found) {
            pos := InStr(haystackText, block)
            cleaned := SubStr(haystackText, 1, pos + StrLen(block) - 1)
            haystackText := SubStr(haystackText, pos + StrLen(block))
            found := true
        } else {
            haystackText := StrReplace(haystackText, block, "",, 1)
        }
    }
    cleaned .= haystackText
    return cleaned
}
TrimNeedleBlock(fullText, needleText, ByRef found) {
    found := false
    pos := InStr(fullText, needleText)
    if (!pos)
        return
    start := pos
    while (start > 1) {
        char := SubStr(fullText, start - 1, 1)
        if (char ~= "[ \t]") {
            start--
        } else if (char = "`n" || char = "`r") {
            start--
            ; Remove only one newline before block
            if (start > 1 && SubStr(fullText, start - 1, 1) ~= "[\r\n]")
                start--
            break
        } else
            break
    }
    end := pos + StrLen(needleText) - 1
    while (end < StrLen(fullText)) {
        char := SubStr(fullText, end + 1, 1)
        if (char ~= "[ \t]") {
            end++
        } else if (char = "`n" || char = "`r") {
            end++
            break
        } else
            break
    }
    found := true
    return SubStr(fullText, start, end - start + 1)
}
;;;-------------
SaveArrayToFile(arr, filePath, Addedseparator:="") {
    for index, block in arr 
        fileContent .= block "`r`n"
    FileDelete, %filePath%
    FileAppend, %fileContent%, %filePath%
}
;;;-------------
ExtractBracketedBlock(text, startMatchText := "", openChar := "(", ByRef startLine := "", ByRef endLine := "") {
    pairs := { "(": ")", "{": "}", "[": "]" }
    closeChar := pairs[openChar]
    if (!closeChar) {
        startLine := endLine := 0
        return
    }
    depth := 0
    currentLine := 0
    matchFound := (startMatchText = "")
    Loop, Parse, text, `n, `r
    {
        line := A_LoopField
        currentLine++
        if (!matchFound && InStr(line, startMatchText)) {
            matchFound := true
        }

        if (!matchFound)
            continue
        if (!foundStart && InStr(line, openChar)) {
            foundStart := true
            startLine := currentLine
        }
        Loop, Parse, line
        {
            char := A_LoopField
            if (char = openChar) {
                depth++
                if (!foundStart) {
                    foundStart := true
                    startLine := currentLine
                }
            } else if (char = closeChar) {
                depth--
            }
        }
        if (foundStart)
            block .= line "`n"

        if (foundStart && depth = 0) {
            endLine := currentLine
            break
        }
    }
    if (depth != 0)
        endLine := 0

    return block
}
;;;-------------
