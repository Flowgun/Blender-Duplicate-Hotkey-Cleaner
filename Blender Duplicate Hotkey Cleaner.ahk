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
	Exit

FileRead, content, % HotkeyFile
arr:=SplitByCondition(content, Func("SplitCondition"))
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

			value:= RemoveDuplicateBlocks(value, HotkeyBlock, allRemovedText)
		}
	}
	arr[key]:= value
	if (!isObject(AllRemovedArray))
		AllRemovedArray:={}
	else
		AllRemovedArray.push(allRemovedText)
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
		exit
	}
}
run, % OutDir
exit

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
RemoveDuplicateBlocks(haystackText, needleText, ByRef allRemovedText) {
    temp := haystackText
    allRemoved := StrReplace(temp, needleText)
    Loop {
        pos := InStr(haystackText, needleText)
        if (!pos)
            break
        if (!found) {
            endPos := pos + StrLen(needleText) - 1
            cleaned := SubStr(haystackText, 1, endPos)
            haystackText := SubStr(haystackText, endPos + 1)
            found := true
        } else {
            haystackText := StrReplace(haystackText, needleText,,, 1)
        }
    }
    cleaned .= haystackText
    allRemovedText := allRemoved
    return cleaned
}
;;;-------------
SaveArrayToFile(arr, filePath, Addedseparator:="") {
    fileContent := ""
    for index, block in arr {
        fileContent .= block "`r`n"
    }
    FileDelete, %filePath%
    FileAppend, %fileContent%, %filePath%
}
;;;-------------
ExtractBracketedBlock(text, startMatchText := "", openChar := "(", ByRef startLine := "", ByRef endLine := "") {
    pairs := { "(": ")", "{": "}", "[": "]" }
    closeChar := pairs[openChar]
    if (!closeChar) {
        startLine := endLine := 0
        return ""  ; Invalid bracket
    }

    depth := 0
    currentLine := 0
    matchFound := (startMatchText = "")  ; If no match text required, start immediately

    Loop, Parse, text, `n, `r
    {
        line := A_LoopField
        currentLine++

        ; Wait until the line contains the required starting text
        if (!matchFound && InStr(line, startMatchText)) {
            matchFound := true
        }

        if (!matchFound)
            continue

        ; Only begin once we detect the opening character
        if (!foundStart && InStr(line, openChar)) {
            foundStart := true
            startLine := currentLine
        }

        ; Count depth of brackets
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