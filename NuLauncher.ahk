#NoEnv
#SingleInstance, Force
#Persistent
#NoTrayIcon
Process, Priority,, High
SetBatchLines, -1
ListLines, Off
SetWinDelay, -1
SendMode Input
SetWorkingDir, %A_ScriptDir%

NuPath := A_AppData "\NuLauncher"

GitNu := "https://raw.githubusercontent.com/oli-lap/NuLauncher/main/NuLauncher/Nu.ahk"
GitVer := "https://raw.githubusercontent.com/oli-lap/NuLauncher/main/NuLauncher/version.txt"
GitIco := "https://raw.githubusercontent.com/oli-lap/NuLauncher/main/NuLauncher/ico/Nu.ico"

MakeUpdate := 0

if !(FileExist(NuPath) = "D") {
	FileCreateDir, % NuPath
	MakeUpdate := 1
}
else {
	if !FileExist(NuPath "\version.txt") {
		MakeUpdate := 1
	}
	else {
		FileRead, CurrentVersion, % NuPath "\version.txt"

		whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		whr.Open("GET", GitVer, true)
		whr.Send()
		whr.WaitForResponse()
		LastVersion := whr.ResponseText

		if (CurrentVersion != LastVersion) {
			MsgBox, 4,, A new version of NuLauncher was found.`nDo you want to update now ?
			IfMsgBox Yes
				MakeUpdate := 1
		}
	}
	if !FileExist(NuPath "\Nu.ahk")
		MakeUpdate := 1
}

if MakeUpdate {
	Gui, Add, Text,, Updating, please wait...
	Gui, Show, Center, Updating

	UrlDownloadToFile, % GitVer, %  NuPath "\version.txt"
	if ErrorLevel
		MsgBox, There was a problem downloading a file...
	UrlDownloadToFile, % GitNu, %  NuPath "\Nu.ahk"
	if ErrorLevel
		MsgBox, There was a problem downloading a file...

	if !FileExist(NuPath "\Nu.ico")
		UrlDownloadToFile, % GitIco, %  NuPath "\Nu.ico"
		if ErrorLevel
			MsgBox, There was a problem downloading a file...
}

if FileExist(NuPath "\Nu.ahk")
	Run, % NuPath "\Nu.ahk"
else
	MsgBox, There was a problem launching the program...
ExitApp