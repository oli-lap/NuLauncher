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

if FileExist(A_ScriptDir "\Nu.ico")
	Menu, Tray, Icon, A_ScriptDir "\Nu.ico"

NuLauncher := new NuLauncher()
Return

NuLauncherGuiClose:
ExitApp

class NuLauncher {
	__New() {
		this.Version := [1,1,1]
		this.LoadInfo()
		this.ReadData()
		;this.CheckVer()

		this.CreateLU()
		this.GetMon()
		this.CreateLists()

		this.LoadGui()
		this.UpdateToons()
		this.LVLoadData()
		this.LoadSettings()

		this.CheckGame()

		this.SetInfoText(this.PersistMsg)
	}
	CheckVer() {
		Return
	}
	DataChange(refresh) {
		this.WriteData()
		this.CreateLU()
		this.CreateLists()
		if (refresh = 1) {
			this.LVLoadData()

			this.LoadSettings()
			this.Gui.Elements.ToonForm.Elements.ToonAccount.ChangeList(this.Lists.Accounts)
			this.Gui.Elements.TeamForm.Elements.Team1.ChangeList(this.Lists.Toons)
			this.Gui.Elements.TeamForm.Elements.Team2.ChangeList(this.Lists.Toons)
		}
	}
	LoadSettings() {
		GuiControl, choose, DDServers, % this.data.DefaultServer
		GuiControl,, DaocPath, % this.data.DaocPath
		GuiControl,, FavOnly, % this.data.FavOnly
		GuiControl, choose, RealmOnly, % this.data.RealmOnly + 1
	}
	LVLoadData() {
		this.LVLoadAccountsData()
		this.LVLoadToonsData()
		this.LVLoadTeamsData()
	}
	LVLoadAccountsData() {
		data := []
		for i, d in this.data.Accounts {
			if !this.data.FavOnly OR d.Favorite
				data.Push([i, d.Name, d.WindowName, (d.Favorite=1 ? "v" :"")])
		}
		this.Gui.Elements.LVAccounts.PushData(this.Gui.Name, data)
		this.Gui.Elements.LVAccounts.SetCreating()
		this.Gui.Elements.AccountForm.SetCreating()
	}
	LVLoadToonsData() {
		data := []
		for i, d in this.data.Toons {
				if (!this.data.FavOnly OR d.Favorite) AND ((this.data.RealmOnly = 0) OR (this.data.RealmOnly = this.LU.Realms[d.Realm].Pos)) {
					data.Push([i, d.Name, d.Realm, d.Class, d.Level, d.RR, d.BP, this.data.Accounts[d.Account].Name, d.Server, StrSplit(d.Note, "`n")[1], (d.Favorite=1 ? "v" :"")])
				}
		}
		this.Gui.Elements.LVToons.PushData(this.Gui.Name, data)
		this.Gui.Elements.LVToons.SetCreating()
		this.Gui.Elements.AToonForm.SetCreating()
		LV_ModifyCol(6, "SortDesc")
		LV_ModifyCol(5, "SortDesc")
	}
	LVLoadTeamsData() {
		data := []
		for i, d in this.data.Teams {
			if (!this.data.FavOnly OR d.Favorite) AND ((this.data.RealmOnly = 0) OR (this.data.RealmOnly = this.LU.Realms[d.Realm].Pos))
				data.Push([i, this.data.Toons[d[1]].Name, this.data.Toons[d[2]].Name, (d.Favorite=1 ? "v" :"")])
		}
		this.Gui.Elements.LVTeams.PushData(this.Gui.Name, data)
		this.Gui.Elements.LVTeams.SetCreating()
		this.Gui.Elements.TeamForm.SetCreating()
	}
	CheckGame() {
		this.GameFound := 0
		this.PersistMsg := ""
		if !this.data.DaocPath
			this.PersistMsg := "Select the DAoC installation folder"
		else if !FileExist(this.data.DaocPath "/game.dll")
			this.PersistMsg := "game.dll was not found in the selected folder."
		else
			this.GameFound := 1
	}
	
	;Gui
	LoadGui() {
		Global
		this.Gui := {}
		this.Gui.Name := "NuLauncher"
		GuiName := this.Gui.Name
		this.Gui.w := 717
		this.Gui.h := 860

		this.Gui.Elements := {}

		x := this.Gui.w - 110
		y := this.Gui.w - 20

		;Accounts
		LVName := "LVAccounts"
		lvAc := New cListView(LVName, "Accounts", 10, 25, 11, {single: "", double: ""})
		lvAc.AddCol("id", 0, "Integer")
		lvAc.AddCol("Name", 125, "Text")
		lvAc.AddCol("Window name", 125, "Text")
		lvAc.AddCol("Fav", 30, "Text")
		this.Gui.Elements[LVName] := lvAc

		DDName := "DDServers"
		ddServ := New cDropDownList("", DDName, 0, this.Lists.Servers, 191, 19)
		this.Gui.Elements[DDName] := ddServ

		FormName := "AccountForm"
		AccForm := New cForm(name, "Account", 330, 40)
		AccForm.AddElement(Type:="Edit", Name:="Name", ToSave:=1, Text:="Account name", r:=1, Password:=0, DisableEdit:=1)
		AccForm.AddElement(Type:="Edit", Name:="WindowName", ToSave:=1, Text:="Window Name (opt)", r:=1, Password:=0, DisableEdit:=0)
		AccForm.AddElement(Type:="Edit", Name:="Password", ToSave:=1, Text:="Password (opt)", r:=1, Password:=1, DisableEdit:=0)
		AccForm.AddElement(Type:="Checkbox", Name:="DispPassword", ToSave:=0, Text:="Display password")
		AccForm.AddElement(Type:="Checkbox", Name:="Favorite", ToSave:=1, Text:="Favorite")
		AccForm.AddElement(Type:="Button", Name:="SaveAccount", ToSave:=0, Text:="Save new|Save changes")
		AccForm.AddElement(Type:="Button", Name:="DeleteAccount", ToSave:=0, Text:="|Delete account")
		AccForm.AddElement(Type:="Button", Name:="NewAccount", ToSave:=0, Text:="|New account")
		this.Gui.Elements[FormName] := AccForm

		;Toons
		LVName := "LVToons"
		lvToon := New cListView(LVName, "Toons", 10, 270, 12, {single: "", double: ""})
		lvToon.AddCol("id", 0, "Integer")
		lvToon.AddCol("Name", 90, "Text")
		lvToon.AddCol("Realm", 51, "Text")
		lvToon.AddCol("Class", 71, "Text")
		lvToon.AddCol("Lvl", 27, "Integer Desc")
		lvToon.AddCol("RR", 36, "Float Desc")
		lvToon.AddCol("BPs", 48, "Integer Desc")
		lvToon.AddCol("Account", 60, "Text")
		lvToon.AddCol("Server", 53, "Text Logical")
		lvToon.AddCol("Note", 63, "Text")
		lvToon.AddCol("Fav", 30, "Text")
		this.Gui.Elements[LVName] := lvToon

		FormName := "ToonForm"
		ToonForm := New cForm(name, "Toon", 587, 285)
		ToonForm.AddElement(Type:="Edit", Name:="Name", ToSave:=1, Text:="Toon name", r:=1, Password:=0, DisableEdit:=1)
		ToonForm.AddElement(Type:="DropDownList", Name:="Account", ToSave:=1, List:=this.Lists.Accounts)
		ToonForm.AddElement(Type:="Edit", Name:="Note", ToSave:=1, Text:="Note", r:=5, Password:=0, DisableEdit:=0)
		ToonForm.AddElement(Type:="Checkbox", Name:="Favorite", ToSave:=1, Text:="Favorite")
		ToonForm.AddElement(Type:="Button", Name:="SaveToon", ToSave:=0, Text:="Save new|Save changes")
		ToonForm.AddElement(Type:="Button", Name:="DeleteToon", ToSave:=0, Text:="|Delete toon")
		ToonForm.AddElement(Type:="Button", Name:="NewToon", ToSave:=0, Text:="|New toon")
		this.Gui.Elements[FormName] := ToonForm

		;Teams
		LVName := "LVTeams"
		lvTeams := New cListView(LVName, "Teams", 10, 530, 7, {single: "", double: ""})
		lvTeams.AddCol("id", 0, "Integer")
		lvTeams.AddCol("Toon 1", 125, "Text")
		lvTeams.AddCol("Toon 2", 125, "Text")
		lvTeams.AddCol("Fav", 30, "Text")
		this.Gui.Elements[LVName] := lvTeams

		FormName := "TeamForm"
		TeamForm := New cForm(name, "Team", 342, 545)
		TeamForm.AddElement(Type:="DropDownList", Name:="1", ToSave:=1, List:=this.Lists.Toons)
		TeamForm.AddElement(Type:="DropDownList", Name:="2", ToSave:=1, List:=this.Lists.Toons)
		TeamForm.AddElement(Type:="Checkbox", Name:="Favorite", ToSave:=1, Text:="Favorite")
		TeamForm.AddElement(Type:="Button", Name:="SaveTeam", ToSave:=0, Text:="Save new|Save changes")
		TeamForm.AddElement(Type:="Button", Name:="DeleteTeam", ToSave:=0, Text:="|Delete team")
		TeamForm.AddElement(Type:="Button", Name:="NewTeam", ToSave:=0, Text:="|New team")
		this.Gui.Elements[FormName] := TeamForm

		y := 715
		Gui %GuiName%: Add, Text, % "x10 y" y, % "Settings"

		y += 19
		Gui %GuiName%: Add, Button, % "x10 y" y " vChangeDaocPath", Change DAoC Path
		y += 5
		Gui %GuiName%: Add, Text, % "x120 y" y " w700 vDaocPath",

		y += 20
		Gui %GuiName%: Add, Button, % "x10 y" y " vMoveBtn", Move
		str := ""
		for i, e in this.Lists.Accounts {
			str .= e "|"
			str .= i=1 ? "|" :
		}
		Gui %GuiName%: Add, DropDownList, % "x55 y" y+1 " vMoveAcc +AltSubmit", % str
		Gui %GuiName%: Add, Text, % "x180 y" y+4, to
		str := ""
		for i, e in this.Lists.Mon {
			str .= e "|"
			str .= i=1 ? "|" :
		}
		Gui %GuiName%: Add, DropDownList, % "x192 y" y+1 " vMoveMon +AltSubmit", % str
		

		y += 26
		Gui %GuiName%: Add, CheckBox, % "x10 y" y " vFavOnly" , Favorites only

		y += 20
		str := "All realms||"
		for i, e in this.Lists.Realms {
			str .= e " only|"
		}
		Gui %GuiName%: Add, DropDownList, % "x10 y" y " vRealmOnly +AltSubmit", % str

		y += 26
		Gui %GuiName%: Font, cAA0000
		Gui %GuiName%: Add, Text, % "x10 y" y " w717 vInfoText",
		Gui %GuiName%: Font, c000000
		
		for i, e in this.Gui.Elements {
			e.Show(this.Gui.Name)
		}

		this.Bind("DDServers", "DDServers", "")
		this.Bind("LVAccounts", "LVClick", {Normal: "LVAccountsSingle", DoubleClick: "LVAccountsDouble", LVName: "LVAccounts", NoSelect: "NewAccount"})
		this.Bind("LVToons", "LVClick", {Normal: "LVToonsSingle", DoubleClick: "LVToonsDouble", LVName: "LVToons", NoSelect: "NewToon"})
		this.Bind("LVTeams", "LVClick", {Normal: "LVTeamsSingle", DoubleClick: "LVTeamsDouble", LVName: "LVTeams", NoSelect: "NewTeam"})

		this.Bind("AccountDispPassword", "SwitchDispPassword", "")

		this.Bind("NewAccount", "NewAccount", "")
		this.Bind("NewToon", "NewToon", "")
		this.Bind("NewTeam", "NewTeam", "")

		this.Bind("SaveAccount", "SaveAccount", "")
		this.Bind("SaveToon", "SaveToon", "")
		this.Bind("SaveTeam", "SaveTeam", "")

		this.Bind("DeleteAccount", "DeleteAccount", "")
		this.Bind("DeleteToon", "DeleteToon", "")
		this.Bind("DeleteTeam", "DeleteTeam", "")

		this.Bind("ChangeDaocPath", "ChangeDaocPath", 0)
		
		this.Bind("MoveBtn", "WinMove", "")

		this.Bind("FavOnly", "FavOnly", "")

		this.Bind("RealmOnly", "RealmOnly", "")

		Gui %GuiName%: Show, % "w" this.Gui.w " h" this.Gui.h, % this.Gui.Name
	}
	RealmOnly() {
		GuiName := this.Gui.Name
		Gui %GuiName%: Default
		GuiControlGet, Realm,, RealmOnly
		this.Data.RealmOnly := Realm - 1
		this.DataChange(1)
	}
	WinMove() {
		GuiName := this.Gui.Name
		Gui %GuiName%: Default
		GuiControlGet, Account,, MoveAcc
		GuiControlGet, Mon,, MoveMon
		xPos := this.Mon[Mon].Left
		yPos := this.Mon[Mon].Top
		hPos := this.Mon[Mon].h
		wPos := this.Mon[Mon].w

		if (StrLen(this.data.Accounts[Account].WindowName) > 0)
			WinName := this.data.Accounts[Account].WindowName
		else
			WinName := "DAoC - " this.data.Accounts[Account].Name
		if WinExist(WinName)
			WinMove, % WinName,, % xPos, % yPos, % wPos, % hPos
		else
			this.TempMessage("The window was not found.")
	}
	RunAccount(id, server) {
		if !this.GameFound
			Return
		path := this.data.DaocPath

		ip := this.ip
		server := this.serversL["Ywain" server]

		account := this.data.Accounts[id].Name
		password := this.data.Accounts[id].Password
		WindowName := this.data.Accounts[id].WindowName

		if (StrLen(password) < 1)
			InputBox, password, Password, Password for the account %account%, HIDE
		if ErrorLevel
			Return

		command := % ip " " server " " account " " password
		Run, %ComSpec% /c cd /d %path% && game.dll %command%,, hide
		
		WinWaitActive, Dark Age of Camelot

		if (StrLen(WindowName) > 0)
			WinSetTitle, Dark Age of Camelot, , % WindowName
		else
			WinSetTitle, Dark Age of Camelot, , % "DAoC - " account
	}
	RunToon(id) {
		if !this.GameFound
			Return
		
		path := this.data.DaocPath

		ip := this.ip
		server := this.serversL[this.data.Toons[id].Server]

		account := this.data.Accounts[this.data.Toons[id].Account].Name
		password := this.data.Accounts[this.data.Toons[id].Account].Password
		WindowName := this.data.Accounts[this.data.Toons[id].Account].WindowName
		

		if (StrLen(password) < 1)
			InputBox, password, Password, Password for the account %account%, HIDE
		if ErrorLevel
			Return
		ToonName := this.data.Toons[id].Name
		realm := this.LU.Realms[this.data.Toons[id].Realm].Pos

		command := % ip " " server " " account " " password " " ToonName " " realm
		Run, %ComSpec% /c cd /d %path% && game.dll %command%,, hide
		
		WinWaitActive, Dark Age of Camelot

		if (StrLen(WindowName) > 0)
			WinSetTitle, Dark Age of Camelot, , % WindowName
		else
			WinSetTitle, Dark Age of Camelot, , % "DAoC - " account
	}
	RunTeam(id) {
		this.RunToon(this.data.Teams[id][1])
		Sleep, 5000
		this.RunToon(this.data.Teams[id][2])
	}
	SetInfoText(text) {
		GuiName := this.Gui.Name
		Gui %GuiName%: Default
		GuiControl,, InfoText, % text
	}
	SetInfoTextPersist() {
		this.SetInfoText(this.PersistMsg)
	}
	FavOnly() {
		GuiName := this.Gui.Name
		Gui %GuiName%: Default
		GuiControlGet, checked,, FavOnly
		if (checked != this.data.FavOnly) {
			this.data.FavOnly := checked
			this.DataChange(1)
		}
	}
	DDServers() {
		GuiControlGet, server,, DDServers
		this.data.DefaultServer := server
		this.DataChange(0)
	}
	DeleteAccount() {
		id := this.Gui.Elements.AccountForm.Selected
		name := this.data.Accounts[id].Name
		MsgBox,	8244, Delete account %name%, Do you want to delete account %name% ?`nAssociated toons and teams will also be deleted.
		IfMsgBox, No
			Return
		this.DeleteToons(id)
		this.data.Accounts.RemoveAt(id)
		this.DataChange(1)
	}
	DeleteToons(AccountID) {
		pos := this.data.Toons.MaxIndex()

		Loop, % this.data.Toons.MaxIndex()
			{
			if (this.data.Toons[pos].Account = AccountID)
				this.DeleteToon(pos)
			pos -= 1
		}

		for i, d in this.data.Toons {
			if (d.Account > AccountID)
				this.data.Toons[i]["Account"] -= 1
		}
	}
	DeleteToon(id:=0) {
		if !id {
			refresh := 1
			id := this.Gui.Elements.ToonForm.Selected
			name := this.data.Toons[id].Name
			MsgBox,	8244, Delete toon %name%, Do you want to delete toon %name% ?`nAssociated teams will also be deleted.
			IfMsgBox, No
				Return
		}
		else {
			refresh := 0
		}
		
		this.DeleteTeams(id)
		this.data.Toons.RemoveAt(id)
		this.DataChange(refresh)
	}
	DeleteTeams(ToonID) {
		pos := this.data.Teams.MaxIndex()

		Loop, % this.data.Teams.MaxIndex()
			{
			if (this.data.Teams[pos][1] = ToonID) OR (this.data.Teams[pos][2] = ToonID)
				this.DeleteTeam(pos)
			pos -= 1
		}

		for i, d in this.data.Teams {
			if (d[1] > ToonID)
				this.data.Teams[i][1] -= 1
			if (d[2] > ToonID)
				this.data.Teams[i][2] -= 1
		}
	}
	DeleteTeam(id) {
		if !id {
			refresh := 1
			id := this.Gui.Elements.TeamForm.Selected
			MsgBox,	8244, Delete team, Do you want to delete selected team ?
			IfMsgBox, No
				Return
		}
		else {
			refresh := 0
		}
		this.data.Teams.RemoveAt(id)
		this.DataChange(refresh)
	}
	TempMessage(msg) {
		this.SetInfoText(msg)
		p := this.PersistMsg
		f := ObjBindMethod(this, "SetInfoText", p)
		SetTimer, %f%, -5000
	}
	SaveAccount() {
		data := this.Gui.Elements.AccountForm.GetData()
		if (StrLen(data.Name) < 1) {
			this.TempMessage("The account name shouldn't be empty.")
			Return
		}
		else if (this.LU.Accounts[data.Name]) AND (this.Gui.Elements.AccountForm.CreatingNew) {
			this.TempMessage("The account " data.Name " already exists.")
			Return
		}

		if this.Gui.Elements.AccountForm.CreatingNew {
			this.data.Accounts.Push(data)
		}
		else {
			id := this.Gui.Elements.AccountForm.Selected
			this.data.Accounts[id] := data
		}
		this.DataChange(1)
	}
	SaveToon() {
		data := this.Gui.Elements.ToonForm.GetData()
		if (this.data.Accounts.MaxIndex() < 1) {
			this.TempMessage("An account should be created first.")
			Return
		}
		else if (StrLen(data.Account) < 1) {
			this.TempMessage("An account should be selected.")
			Return
		}
		else if (StrLen(data.Name) < 1) {
			this.TempMessage("The toon name shouldn't be empty.")
			Return
		}
		else if (this.LU.Toons[data.Name]) AND (this.Gui.Elements.ToonForm.CreatingNew) {
			this.TempMessage("The toon " data.Name " already exists.")
			Return
		}
		if this.GetToonID(data) {
			data := this.GetToonData(data)
			if this.Gui.Elements.ToonForm.CreatingNew {
				this.data.Toons.Push(data)
			}
			else {
				id := this.Gui.Elements.ToonForm.Selected
				this.data.Toons[id] := data
			}
			this.DataChange(1)
		}
	}
	GetToonId(data) {
		Try {
			WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
			WebRequest.Open("GET", "https://api.camelotherald.com/character/search?name=" data.Name "&cluster=Ywain")
			WebRequest.Send()
			CharID := JSON.Load(WebRequest.ResponseText).results[1].character_web_id
			if !CharID {
				this.TempMessage("The toon " data.Name " was not found.")
				Return 0
			}
			else {
				data["CharID"] := CharID
			}
			Return data
		}
		Catch {
			this.TempMessage("Could not connect to the Herald.")
			Return 0
		}
	}
	UpdateToons() {
		this.TempMessage("Updating toon infos...")
		oneUpdate := 0
		for i, toon in this.data.Toons {
			if ((A_NowUTC - toon.LastUpdate) > 600) {
				this.UpdateToon(i)
				oneUpdate := 1
			}
		}
		if oneUpdate
			this.DataChange(1)
		this.TempMessage("Toon infos updated !")
	}
	UpdateToon(id) {
		Try {
			WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
			WebRequest.Open("GET", "https://api.camelotherald.com/character/info/" this.data.Toons[id].CharID)
			WebRequest.Send()
			CharInfo := JSON.Load(WebRequest.ResponseText)
		}
		Catch {
			this.TempMessage("Could not connect to the Herald.")
			Return
		}

		this.data.Toons[id]["Level"] := CharInfo.level
		this.data.Toons[id]["BP"] := CharInfo.realm_war_stats.current.bounty_points
		this.data.Toons[id]["RR"] := this.GetRR(CharInfo.realm_war_stats.current.realm_points)
		this.data.Toons[id]["LastUpdate"] := A_NowUTC
	}
	GetToonData(data) {
		WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		WebRequest.Open("GET", "https://api.camelotherald.com/character/info/" data.CharID)
		WebRequest.Send()
		CharInfo := JSON.Load(WebRequest.ResponseText)

		data["Name"] := StrSplit(CharInfo.name, " ")[1]
		data["Class"] := CharInfo.class_name
		data["Realm"] := this.realms[CharInfo.realm].Name
		data["Server"] := CharInfo.server_name
		data["Level"] := CharInfo.level
		data["BP"] := CharInfo.realm_war_stats.current.bounty_points
		data["RR"] := this.GetRR(CharInfo.realm_war_stats.current.realm_points)
		data["LastUpdate"] := A_NowUTC

		Return data
	}
	GetRR(RP) {
		if (RP = 0) {
			TRank := "0.0"
		}
		else if (RP >= this.ranks[this.ranks.MaxIndex()].min_rp) {
			TRank := this.ranks.MaxIndex() ".0"
		}
		else {
			TRank := "1.1"
			stoploop := 0
			prevRP := 0
			nextRP := 0
			for i, rank in this.ranks {
				if stoploop
					Break
				if (rank.rank != 0) and (rank.rank < this.ranks[this.ranks.MaxIndex()].rank) {
					RR := rank.rank
					RL = 0
					if (RR = 1) {
						RL := 1
					}
					for j, level in rank.levels {
						nextRP := level
						if (rp < level) {
							stoploop := 1
							Break
						}
					TRank := RR "." RL
					RL += 1
					prevRP := level
					}
				}
			}
		}
		Return TRank
	}
	SaveTeam() {
		data := this.Gui.Elements.TeamForm.GetData()
		data["Realm"] := this.data.Toons[data[1]].Realm
		if (this.data.Accounts.MaxIndex() < 2) {
			this.TempMessage("At least two accounts are needed to create a team.")
			Return
		}
		else if (this.data.Toons.MaxIndex() < 2) {
			this.TempMessage("At least two toons are needed to create a team.")
			Return
		}
		else if (data[1] < 1) or (data[2] < 1) {
			this.TempMessage("Two toons should be selected to create a team.")
			Return
		}
		else if (data[1] = data[2]) {
			this.TempMessage("A team should be made of two different toons.")
			Return
		}
		else if (this.data.Toons[data[1]].Account = this.data.Toons[data[2]].Account) {
			this.TempMessage("The selected toons should belong to different accounts.")
			Return
		}
		else if (this.data.Toons[data[1]].Realm != this.data.Toons[data[2]].Realm) {
			this.TempMessage("Both toons should belong to the same realm.")
			Return
		}
		if this.Gui.Elements.TeamForm.CreatingNew {
			this.data.Teams.Push(data)
		}
		else {
			id := this.Gui.Elements.TeamForm.Selected
			this.data.Teams[id] := data
		}
		this.DataChange(1)
	}
	NewAccount() {
		GuiName := this.Gui.Name
		Gui %GuiName%: Default
		Gui, ListView, LVAccounts
		LV_GetNext(RowNumber)
		LV_Modify(RowNumber, "-Select")
		this.Gui.Elements.LVAccounts.SetCreating()
		this.Gui.Elements.AccountForm.SetCreating()
	}
	NewToon() {
		GuiName := this.Gui.Name
		Gui %GuiName%: Default
		Gui, ListView, LVToons
		LV_GetNext(RowNumber)
		LV_Modify(RowNumber, "-Select")
		this.Gui.Elements.LVToons.SetCreating()
		this.Gui.Elements.ToonForm.SetCreating()
	}
	NewTeam() {
		GuiName := this.Gui.Name
		Gui %GuiName%: Default
		Gui, ListView, LVTeams
		LV_GetNext(RowNumber)
		LV_Modify(RowNumber, "-Select")
		this.Gui.Elements.LVTeams.SetCreating()
		this.Gui.Elements.TeamForm.SetCreating()
	}
	SwitchDispPassword() {
		GuiName := this.Gui.Name
		Gui %GuiName%: Default
		GuiControlGet, checked,, AccountDispPassword
		this.Gui.Elements.AccountForm.Elements.AccountPassword.SetPassword(checked)
	}
	LVClick(data) {
		id := 0
		GuiName := this.Gui.Name
		Gui %GuiName%: Default
		Gui, ListView, % data.LVName
		LV_GetText(id, A_EventInfo, 1)
		ItemsSelected := LV_GetCount("S")
        if (ItemsSelected=0) {
			id := 0
			ObjBindMethod(this, data["NoSelect"], "").Call()
		}

		if (A_EventInfo > 0) AND (id > 0) AND (LV_GetNext() > 0) {
			ObjBindMethod(this, data[A_GuiEvent], id).Call()
		}
	}
	LVAccountsSingle(id) {
		this.Gui.Elements.LVAccounts.SetEditing()
		this.Gui.Elements.AccountForm.SetEditing()
		this.Gui.Elements.AccountForm.SetValues(this.data.Accounts[id], id)
	}
	LVAccountsDouble(id) {
		this.RunAccount(id, this.data.DefaultServer)
	}

	LVToonsSingle(id) {
		this.Gui.Elements.LVToons.SetEditing()
		this.Gui.Elements.ToonForm.SetEditing()
		this.Gui.Elements.ToonForm.SetValues(this.data.Toons[id], id)

	}
	LVToonsDouble(id) {
		this.RunToon(id)
	}

	LVTeamsSingle(id) {
		this.Gui.Elements.LVTeams.SetEditing()
		this.Gui.Elements.TeamForm.SetEditing()
		this.Gui.Elements.TeamForm.SetValues(this.data.Teams[id], id)

	}
	LVTeamsDouble(id) {
		this.RunTeam(id)
	}
	
	;Data file
	ReadData() {
		if !FileExist(this.DataFilePath)
			this.CreateDataFile()
		FileRead, data, % this.DataFilePath
		this.data := JSON.Load(data)
	}
	CreateLU() {
		this.LU := {}

		this.LU["Accounts"] := {}
		for i, d in this.data.Accounts {
			this.LU.Accounts[d.Name] := this.ObjFullyClone(d)
			this.LU.Accounts[d.Name]["Pos"] := i
		}

		this.LU["Toons"] := {}
		for i, d in this.data.Toons {
			this.LU.Toons[d.Name] := this.ObjFullyClone(d)
			this.LU.Toons[d.Name]["Pos"] := i
		}

		this.LU["Realms"] := {}
		for i, d in this.realms {
			this.LU.Realms[d.Name] := this.ObjFullyClone(d)
			this.LU.Realms[d.Name]["Pos"] := i
		}
	}
	CreateLists() {
		this.Lists := {}

		listServ := []
		for i, d in this.servers {
			listServ.Push(d.Name)
		}
		this.Lists["Servers"] := listServ

		listRealms := []
		for i, d in this.Realms {
			listRealms.Push(d.Name)
		}
		this.Lists["Realms"] := listRealms

		listAcc := []
		for i, d in this.data.Accounts {
			listAcc.Push(d.Name)
		}
		this.Lists["Accounts"] := listAcc

		listToon := []
		for i, d in this.data.Toons {
			listToon.Push(d.Name)
		}
		this.Lists["Toons"] := listToon

		listMon := []
		for i, d in this.Mon {
			listMon.Push("Screen " i)
		}
		this.Lists["Mon"] := listMon
	}
	WriteData() {
		DataFile := FileOpen(this.DataFilePath, "w")
		DataFile.Write(JSON.Dump(this.data,, " "))
		DataFile.Close()
	}
	CreateDataFile() {
		this.data := {}
		this.data["Version"] := this.Version
		this.data["Accounts"] := []
		this.data["Toons"] := []
		this.data["Teams"] := []
		this.data["DefaultServer"] := ""
		this.data["DaocPath"] := ""
		this.data["RealmOnly"] := 0
		this.WriteData()
	}
	ChangeDaocPath() {
		FileSelectFolder, DAoCFolder,::{20d04fe0-3aea-1069-a2d8-08002b30309d},0,Select DAoC folder
		if ErrorLevel
			Return
		this.Data.DaocPath := DAoCFolder
		this.DataChange(1)
		this.CheckGame()
		this.SetInfoText(this.PersistMsg)
	}
	;Load Info
	LoadInfo() {
		this.DataFilePath := A_ScriptDir "\NuData.json"

		this.DefaultServer := 1

		this.ip := "107.23.173.143 10622"
		
		this.servers := []
		this.servers.Push({Name:"Ywain1",id:"41"})
		this.servers.Push({Name:"Ywain2",id:"49"})
		this.servers.Push({Name:"Ywain3",id:"50"})
		this.servers.Push({Name:"Ywain4",id:"51"})
		this.servers.Push({Name:"Ywain5",id:"52"})
		this.servers.Push({Name:"Ywain6",id:"53"})
		this.servers.Push({Name:"Ywain7",id:"54"})
		this.servers.Push({Name:"Ywain8",id:"55"})
		this.servers.Push({Name:"Ywain9",id:"56"})
		this.servers.Push({Name:"Ywain10",id:"57"})
		
		this.serversL := {}
		this.serversL["Ywain1"] := 41
		this.serversL["Ywain2"] := 49
		this.serversL["Ywain3"] := 50
		this.serversL["Ywain4"] := 51
		this.serversL["Ywain5"] := 52
		this.serversL["Ywain6"] := 53
		this.serversL["Ywain7"] := 54
		this.serversL["Ywain8"] := 55
		this.serversL["Ywain9"] := 56
		this.serversL["Ywain10"] := 57

		this.realms := []
		realm := {}
		realm["Name"] := "Albion"
		this.realms.Push(realm)
		realm := {}
		realm["Name"] := "Midgard"
		this.realms.Push(realm)
		realm := {}
		realm["Name"] := "Hibernia"
		this.realms.Push(realm)

		this.ranks := {}
		this.ranks[0] := {"rank": 0, "min_rp": 0, "max_rp": 1, "titles": [{"realm": 1, "male": "Protector", "female": "Protector"}, {"realm": 2, "male": "Vakten", "female": "Vakten"}, {"realm": 3, "male": "Wayfarer", "female": "Wayfarer"}]}
		this.ranks[1] := {"rank": 1, "min_rp": 1, "max_rp": 9625, "minor_rank_start": 1, "levels": [1, 25, 125, 350, 750, 1375, 2275, 3500, 5100], "titles": [{"realm": 1, "male": "Guardian", "female": "Guardian"}, {"realm": 2, "male": "Skiltvakten", "female": "Skiltvakten"}, {"realm": 3, "male": "Savant", "female": "Savant"}]}
		this.ranks[2] := {"rank": 2, "min_rp": 7125, "max_rp": 61750, "levels": [7125, 9625, 12650, 16250, 20475, 25375, 31000, 37400, 44625, 52725], "titles": [{"realm": 1, "male": "Warder", "female": "Warder"}, {"realm": 2, "male": "Isen Vakten", "female": "Isen Vakten"}, {"realm": 3, "male": "Cosantoir", "female": "Cosantoir"}]}
		this.ranks[3] := {"rank": 3, "min_rp": 61750, "max_rp": 213875, "levels": [61750, 71750, 82775, 94875, 108100, 122500, 138125, 155025, 173250, 192850], "titles": [{"realm": 1, "male": "Myrmidon", "female": "Myrmidon"}, {"realm": 2, "male": "Flammen Vakten", "female": "Flammen Vakten"}, {"realm": 3, "male": "Brehon", "female": "Brehon"}]}
		this.ranks[4] := {"rank": 4, "min_rp": 213875, "max_rp": 513500, "levels": [213875, 236375, 260400, 286000, 313225, 342125, 372750, 405150, 439375, 475475], "titles": [{"realm": 1, "male": "Gryphon Knight", "female": "Gryphon Knight"}, {"realm": 2, "male": "Elding Vakten", "female": "Elding Vakten"}, {"realm": 3, "male": "Grove Protector", "female": "Grove Protector"}]}
		this.ranks[5] := {"rank": 5, "min_rp": 513500, "max_rp": 1010625, "levels": [513500, 553500, 595525, 639625, 685850, 734250, 784875, 837775, 893000, 950600], "titles": [{"realm": 1, "male": "Eagle Knight", "female": "Eagle Knight"}, {"realm": 2, "male": "Stormur Vakten", "female": "Stormur Vakten"}, {"realm": 3, "male": "Raven Ardent", "female": "Raven Ardent"}]}
		this.ranks[6] := {"rank": 6, "min_rp": 1010625, "max_rp": 1755250, "levels": [1010625, 1073125, 1138150, 1205750, 1275975, 1348875, 1424500, 1502900, 1584125, 1668225], "titles": [{"realm": 1, "male": "Phoenix Knight", "female": "Phoenix Knight"}, {"realm": 2, "male": "Isen Herra", "female": "Isen Fru"}, {"realm": 3, "male": "Silver Hand", "female": "Silver Hand"}]}
		this.ranks[7] := {"rank": 7, "min_rp": 1755250, "max_rp": 2797375, "levels": [1755250, 1845250, 1938275, 2034375, 2133600, 2236000, 2341625, 2450525, 2562750, 2678350], "titles": [{"realm": 1, "male": "Alerion Knight", "female": "Alerion Knight"}, {"realm": 2, "male": "Flammen Herra", "female": "Flammen Fru"}, {"realm": 3, "male": "Thunderer", "female": "Thunderer"}]}
		this.ranks[8] := {"rank": 8, "min_rp": 2797375, "max_rp": 4187000, "levels": [2797375, 2919875, 3045900, 3175500, 3308725, 3445625, 3586250, 3730650, 3878875, 4030975], "titles": [{"realm": 1, "male": "Unicorn Knight", "female": "Unicorn Knight"}, {"realm": 2, "male": "Elding Herra", "female": "Elding Fru"}, {"realm": 3, "male": "Gilded Spear", "female": "Gilded Spear"}]}
		this.ranks[9] := {"rank": 9, "min_rp": 4187000, "max_rp": 5974125, "levels": [4187000, 4347000, 4511025, 4679125, 4851350, 5027750, 5208375, 5393275, 5582500, 5776100], "titles": [{"realm": 1, "male": "Lion Knight", "female": "Lion Knight"}, {"realm": 2, "male": "Stormur Herra", "female": "Stormur Fru"}, {"realm": 3, "male": "Tiarna", "female": "Bantiarna"}]}
		this.ranks[10] := {"rank": 10, "min_rp": 5974125, "max_rp": 8208750, "levels": [5974125, 6176625, 6383650, 6595250, 6811475, 7032375, 7258000, 7488400, 7723625, 7963725], "titles": [{"realm": 1, "male": "Dragon Knight", "female": "Dragon Knight"}, {"realm": 2, "male": "Einherjar", "female": "Einherjar"}, {"realm": 3, "male": "Emerald Ridere", "female": "Emerald Ridere"}]}
		this.ranks[11] := {"rank": 11, "min_rp": 8208750, "max_rp": 23308097, "levels": [8208750, 9111713, 10114001, 11226541, 12461460, 13832221, 15353765, 17042680, 18917374, 20998286], "titles": [{"realm": 1, "male": "Lord", "female": "Lady"}, {"realm": 2, "male": "Herra", "female": "Fru"}, {"realm": 3, "male": "Barun", "female": "Banbharun"}]}
		this.ranks[12] := {"rank": 12, "min_rp": 23308097, "max_rp": 66181501, "levels": [23308097, 25871988, 28717906, 31876876, 35383333, 39275499, 43595804, 48391343, 53714390, 59622973], "titles": [{"realm": 1, "male": "Baronet", "female": "Baronetess"}, {"realm": 2, "male": "Hersir", "female": "Baronsfru"}, {"realm": 3, "male": "Ard Tiarna", "female": "Ard Bantiarna"}]}
		this.ranks[13] := {"rank": 13, "min_rp": 66181501, "max_rp": 187917143, "levels": [66181501, 73461466, 81542227, 90511872, 100468178, 111519678, 123786843, 137403395, 152517769, 169294723], "titles": [{"realm": 1, "male": "Baron", "female": "Baroness"}, {"realm": 2, "male": "Vicomte", "female": "Vicomtessa"}, {"realm": 3, "male": "Ciann Cath", "female": "Ciann Cath"}]}
		this.ranks[14] := {"rank": 14, "min_rp": 187917143, "titles": [{"realm": 1, "male": "Arch Duke", "female": "Arch Duchess"}, {"realm": 2, "male": "Stor Jarl", "female": "Stor Hurfru"}, {"realm": 3, "male": "Ard Diuc", "female": "Ard Bandiuc"}]}

		this.LotMPath := A_AppData "\Electronic Arts\Dark Age of Camelot\LotM"
	}
	;Misc
	Bind(v, m, p) {
		GuiName := this.Gui.Name
		b := ObjBindMethod(this, m, p)
		GuiControl %GuiName%: +g, % v, % b
	}
	ObjFullyClone(obj) {
		nobj := obj.Clone()
		for k,v in nobj
			if IsObject(v)
				nobj[k] := this.ObjFullyClone(v)
		return nobj
	}
	GetMon() {
		this.Mon := []
		SysGet, MonCount, MonitorCount
		SysGet, PrimMon, MonitorPrimary
		SysGet, Mon, Monitor, % PrimMon
		this.Mon[1] := {Left: MonLeft, Top: MonTop, Right: MonRight, Bottom: MonBottom, h: (MonBottom - MonTop), w: (MonRight - MonLeft)}
		Loop, % MonCount
		{
			if (A_Index = PrimMon)
				Continue
			SysGet, Mon, Monitor, % A_Index
			this.Mon.Push({Left: MonLeft, Top: MonTop, Right: MonRight, Bottom: MonBottom, h: (MonBottom - MonTop), w: (MonRight - MonLeft)})
		}
	}
}

class cListView {
	__New(Name, Title, x, y, rows, methods) {
		this.Type := "ListView"
		this.Title := Title
		this.Name := Name
		this.x := x
		this.y := y
		this.r := rows
		this.w := 21
		this.Cols := []
	}
	PushData(GuiName, data) {
		Global
		Gui %GuiName%: Default
		Gui, ListView, % this.Name
		LV_Delete()
		for i, d in data {
			Gui, ListView, % this.Name
			LV_Add("", d*)
		}
	}
	AddCol(Name, w, Type) {
		col := new this.Col(Name, w, Type)
		this.Cols.Push(col)
		this.w += w
	}
	Show(GuiName) {
		Global
		this.GuiName := GuiName
		Gui %GuiName%: Default
		
		Gui %GuiName%: Add, Text, % "x" this.x " y" this.y, % this.Title
		Gui %GuiName%: Add, ListView, % "x" this.x " y" this.y + 15 " w" this.w " R" this.r " v" this.Name " hwndHWND +AltSubmit -Multi -LV0x10", % this.GetColsStr()

		this.hwnd := HWND

		Gui, ListView, % this.Name
		for i, Col in this.Cols {
			LV_ModifyCol(i, Col.w " " Col.Type)
		}
		this.SetCreating()
	}
	SetCreating() {
		GuiName := this.GuiName
		Gui %GuiName%: Default
	}
	SetEditing() {
		GuiName := this.GuiName
		Gui %GuiName%: Default
		Gui, ListView, % this.Name
	}
	GetColsStr() {
		str := ""
		
		for i, Col in this.Cols {
			str .= i>1 ? "|" :
			str .= Col.Name
		}
		Return str
	}

	class Col {
		__New(Name, w, Type) {
			this.Name := Name
			this.w := w
			this.Type := Type
		}
	}
}
class cForm {
	__New(Name, NameS, x, y) {
		this.CreatingNew := 1
		this.Type := "Form"
		this.Name := Name
		this.NameS := NameS
		this.x := x
		this.y := y
		this.d := 25
		this.Elements := {}
		this.ElementsO := []
		this.ECount := 0
	}
	AddElement(Type, Name, ToSave, Text:=0, r:=0, Password:=0, List:=0) {
		tv := c%Type%
		e := New tv(Form:=this.NameS, Name:=Name, ToSave:=ToSave, Text:=Text, r:=r, Password:=Password, List:=List)
		e.SetPos(this.x, (this.y + (this.ECount * this.d)))
		this.Elements[e.vName] := e
		this.ElementsO.Push(e.vName)
		this.ECount += 1
		if (r>1)
			this.ECount += Round((r-1)/2)
	}
	Show(GuiName) {
		this.GuiName := GuiName
		for i, e in this.ElementsO {
			this.Elements[e].Show(GuiName)
		}
	}
	SetValues(data, id) {
		this.Selected := id
		for form, d in data {
			if this.Elements[this.NameS form] {
				this.Elements[this.NameS form].SetValue(d)
			}
		}
	}
	SetEditing() {
		if this.CreatingNew {
			this.CreatingNew := 0
			for i, e in this.Elements {
				e.SetEditing()
			}
		}
	}
	SetCreating() {
		if !this.CreatingNew {
			this.Selected := 0
			this.CreatingNew := 1
			for i, e in this.Elements {
				e.SetCreating()
			}
			GuiName := this.GuiName
			Gui %GuiName%: Default
		}
	}
	GetData() {
		d := {}
		for name, e in this.Elements {
			if e.ToSave
				d[e.Name] := e.GetData()
		}
		Return d
	}
}
class cEdit {
	__New(Form, Name, ToSave, Text, r, Password, DisableEdit) {
		this.Type := "Edit"
		this.Form := Form
		this.Name := Name
		this.ToSave := ToSave
		this.vName := this.Form this.Name
		this.Text := Text
		this.r := r
		this.Password := Password
		this.DisableEdit := DisableEdit
	}
	SetPos(x, y) {
		this.x := x
		this.y := y
	}
	Show(GuiName) {
		Global
		this.GuiName := GuiName
		Gui %GuiName%: Default
		PW := this.Password=1 ? " Password" : ""
		Gui %GuiName%: Add, Edit, % "v" this.vName " hwndhwnd" " x" this.x " y" this.y " r" this.r PW
		this.SetCueBanner(hwnd, this.Text)
	}
	SetCueBanner(handle, string, option := true) {
		static ECM_FIRST := 0x1500 
		static EM_SETCUEBANNER := ECM_FIRST + 1
		if (DllCall("user32\SendMessage", "ptr", handle, "uint", EM_SETCUEBANNER, "int", option, "str", string, "int"))
			return true
		return false
	}
	SetPassword(state) {
		GuiName := this.GuiName
		Gui %GuiName%: Default
		if state
			GuiControl -Password, % this.vName
		else
			GuiControl +Password, % this.vName
	}
	SetValue(d) {
		GuiControl,, % this.vName, % d
	}
	SetCreating() {
		this.SetValue("")
		if (this.DisableEdit)
			GuiControl, Enable, % this.vName
	}
	SetEditing() {
		if (this.DisableEdit)
			GuiControl, Disable, % this.vName
	}
	GetData() {
		GuiControlGet, d,, % this.vName
		Return d
	}
}
class cButton {
	__New(Form, Name, ToSave, Text) {
		this.Type := "Button"
		this.Form := Form
		this.Name := Name
		this.ToSave := ToSave
		this.vName := this.Form this.Name
		this.Text := Text
		this.NewText := StrSplit(Text, "|")[1]
		this.EditText := StrSplit(Text, "|")[2]
	}
	SetPos(x, y) {
		this.x := x
		this.y := y
	}
	Show(GuiName) {
		Global
		Gui %GuiName%: Default
		Gui %GuiName%: Add, Button, % "v" this.Name " x" this.x " y" this.y " w120", % this.EditText
		this.SetCreating()
	}
	SetCreating() {
		if this.NewText {
			GuiControl,, % this.Name, % this.NewText
			GuiControl, Enable, % this.Name
		}
		else {
			GuiControl, Disable, % this.Name
		}
	}
	SetEditing() {
		if this.EditText {
			GuiControl,, % this.Name, % this.EditText
			GuiControl, Enable, % this.Name
		}
		else {
			GuiControl, Disable, % this.Name
		}
	}
}
class cCheckbox {
	__New(Form, Name, ToSave, Text) {
		this.Type := "Checkbox"
		this.Form := Form
		this.Name := Name
		this.ToSave := ToSave
		this.vName := this.Form this.Name
		this.Text := Text
	}
	SetPos(x, y) {
		this.x := x
		this.y := y + 4
	}
	Show(GuiName) {
		Global
		Gui %GuiName%: Default
		Gui %GuiName%: Add, CheckBox, % "v" this.vName " x" this.x " y" this.y, % this.Text
	}
	SetValue(d) {
		GuiControl,, % this.vName, % d
	}
	SetCreating() {
		this.SetValue(0)
	}
	GetData() {
		GuiControlGet, d,, % this.vName
		Return d
	}
}
class cDropDownList {
	__New(Form, Name, ToSave, list, x:=0, y:=0) {
		this.Type := "DropDownList"
		this.Form := Form
		this.Name := Name
		this.ToSave := ToSave
		this.vName := this.Form this.Name
		this.x := x
		this.y := y
		this.list := list
	}
	SetPos(x, y) {
		this.x := x
		this.y := y
	}
	Show(GuiName) {
		Global
		this.GuiName := GuiName
		Gui %GuiName%: Default

		Gui %GuiName%: Add, DropDownList, % "+AltSubmit x" this.x " y" this.y " v" this.vName, % this.GetList()
	}
	GetList() {
		str := ""
		for i, e in this.list {
			str .= e "|"
			str .= i=1 ? "|" :
		}
		Return str
	}
	SetValue(d:=1) {
		GuiControl, Choose, % this.vName, % d
	}
	ChangeList(list) {
		if (this.list = list)
			Return
		this.list := list
		GuiControl,, % this.vName, % "|" this.GetList()
	}
	SetCreating() {
		this.SetValue(1)
	}
	GetData() {
		GuiControlGet, d,, % this.vName
		Return d
	}
}




/**
 * Lib: JSON.ahk
 *     JSON lib for AutoHotkey.
 * Version:
 *     v2.1.3 [updated 04/18/2016 (MM/DD/YYYY)]
 * License:
 *     WTFPL [http://wtfpl.net/]
 * Requirements:
 *     Latest version of AutoHotkey (v1.1+ or v2.0-a+)
 * Installation:
 *     Use #Include JSON.ahk or copy into a function library folder and then
 *     use #Include <JSON>
 * Links:
 *     GitHub:     - https://github.com/cocobelgica/AutoHotkey-JSON
 *     Forum Topic - http://goo.gl/r0zI8t
 *     Email:      - cocobelgica <at> gmail <dot> com
 */


/**
 * Class: JSON
 *     The JSON object contains methods for parsing JSON and converting values
 *     to JSON. Callable - NO; Instantiable - YES; Subclassable - YES;
 *     Nestable(via #Include) - NO.
 * Methods:
 *     Load() - see relevant documentation before method definition header
 *     Dump() - see relevant documentation before method definition header
 */
class JSON
{
	/**
	 * Method: Load
	 *     Parses a JSON string into an AHK value
	 * Syntax:
	 *     value := JSON.Load( text [, reviver ] )
	 * Parameter(s):
	 *     value      [retval] - parsed value
	 *     text    [in, ByRef] - JSON formatted string
	 *     reviver   [in, opt] - function object, similar to JavaScript's
	 *                           JSON.parse() 'reviver' parameter
	 */
	class Load extends JSON.Functor
	{
		Call(self, ByRef text, reviver:="")
		{
			this.rev := IsObject(reviver) ? reviver : false
		; Object keys(and array indices) are temporarily stored in arrays so that
		; we can enumerate them in the order they appear in the document/text instead
		; of alphabetically. Skip if no reviver function is specified.
			this.keys := this.rev ? {} : false

			static quot := Chr(34), bashq := "\" . quot
			     , json_value := quot . "{[01234567890-tfn"
			     , json_value_or_array_closing := quot . "{[]01234567890-tfn"
			     , object_key_or_object_closing := quot . "}"

			key := ""
			is_key := false
			root := {}
			stack := [root]
			next := json_value
			pos := 0

			while ((ch := SubStr(text, ++pos, 1)) != "") {
				if InStr(" `t`r`n", ch)
					continue
				if !InStr(next, ch, 1)
					this.ParseError(next, text, pos)

				holder := stack[1]
				is_array := holder.IsArray

				if InStr(",:", ch) {
					next := (is_key := !is_array && ch == ",") ? quot : json_value

				} else if InStr("}]", ch) {
					ObjRemoveAt(stack, 1)
					next := stack[1]==root ? "" : stack[1].IsArray ? ",]" : ",}"

				} else {
					if InStr("{[", ch) {
					; Check if Array() is overridden and if its return value has
					; the 'IsArray' property. If so, Array() will be called normally,
					; otherwise, use a custom base object for arrays
						static json_array := Func("Array").IsBuiltIn || ![].IsArray ? {IsArray: true} : 0
					
					; sacrifice readability for minor(actually negligible) performance gain
						(ch == "{")
							? ( is_key := true
							  , value := {}
							  , next := object_key_or_object_closing )
						; ch == "["
							: ( value := json_array ? new json_array : []
							  , next := json_value_or_array_closing )
						
						ObjInsertAt(stack, 1, value)

						if (this.keys)
							this.keys[value] := []
					
					} else {
						if (ch == quot) {
							i := pos
							while (i := InStr(text, quot,, i+1)) {
								value := StrReplace(SubStr(text, pos+1, i-pos-1), "\\", "\u005c")

								static tail := A_AhkVersion<"2" ? 0 : -1
								if (SubStr(value, tail) != "\")
									break
							}

							if (!i)
								this.ParseError("'", text, pos)

							  value := StrReplace(value,  "\/",  "/")
							, value := StrReplace(value, bashq, quot)
							, value := StrReplace(value,  "\b", "`b")
							, value := StrReplace(value,  "\f", "`f")
							, value := StrReplace(value,  "\n", "`n")
							, value := StrReplace(value,  "\r", "`r")
							, value := StrReplace(value,  "\t", "`t")

							pos := i ; update pos
							
							i := 0
							while (i := InStr(value, "\",, i+1)) {
								if !(SubStr(value, i+1, 1) == "u")
									this.ParseError("\", text, pos - StrLen(SubStr(value, i+1)))

								uffff := Abs("0x" . SubStr(value, i+2, 4))
								if (A_IsUnicode || uffff < 0x100)
									value := SubStr(value, 1, i-1) . Chr(uffff) . SubStr(value, i+6)
							}

							if (is_key) {
								key := value, next := ":"
								continue
							}
						
						} else {
							value := SubStr(text, pos, i := RegExMatch(text, "[\]\},\s]|$",, pos)-pos)

							static number := "number", integer :="integer"
							if value is %number%
							{
								if value is %integer%
									value += 0
							}
							else if (value == "true" || value == "false")
								value := %value% + 0
							else if (value == "null")
								value := ""
							else
							; we can do more here to pinpoint the actual culprit
							; but that's just too much extra work.
								this.ParseError(next, text, pos, i)

							pos += i-1
						}

						next := holder==root ? "" : is_array ? ",]" : ",}"
					} ; If InStr("{[", ch) { ... } else

					is_array? key := ObjPush(holder, value) : holder[key] := value

					if (this.keys && this.keys.HasKey(holder))
						this.keys[holder].Push(key)
				}
			
			} ; while ( ... )

			return this.rev ? this.Walk(root, "") : root[""]
		}

		ParseError(expect, ByRef text, pos, len:=1)
		{
			static quot := Chr(34), qurly := quot . "}"
			
			line := StrSplit(SubStr(text, 1, pos), "`n", "`r").Length()
			col := pos - InStr(text, "`n",, -(StrLen(text)-pos+1))
			msg := Format("{1}`n`nLine:`t{2}`nCol:`t{3}`nChar:`t{4}"
			,     (expect == "")     ? "Extra data"
			    : (expect == "'")    ? "Unterminated string starting at"
			    : (expect == "\")    ? "Invalid \escape"
			    : (expect == ":")    ? "Expecting ':' delimiter"
			    : (expect == quot)   ? "Expecting object key enclosed in double quotes"
			    : (expect == qurly)  ? "Expecting object key enclosed in double quotes or object closing '}'"
			    : (expect == ",}")   ? "Expecting ',' delimiter or object closing '}'"
			    : (expect == ",]")   ? "Expecting ',' delimiter or array closing ']'"
			    : InStr(expect, "]") ? "Expecting JSON value or array closing ']'"
			    :                      "Expecting JSON value(string, number, true, false, null, object or array)"
			, line, col, pos)

			static offset := A_AhkVersion<"2" ? -3 : -4
			throw Exception(msg, offset, SubStr(text, pos, len))
		}

		Walk(holder, key)
		{
			value := holder[key]
			if IsObject(value) {
				for i, k in this.keys[value] {
					; check if ObjHasKey(value, k) ??
					v := this.Walk(value, k)
					if (v != JSON.Undefined)
						value[k] := v
					else
						ObjDelete(value, k)
				}
			}
			
			return this.rev.Call(holder, key, value)
		}
	}

	/**
	 * Method: Dump
	 *     Converts an AHK value into a JSON string
	 * Syntax:
	 *     str := JSON.Dump( value [, replacer, space ] )
	 * Parameter(s):
	 *     str        [retval] - JSON representation of an AHK value
	 *     value          [in] - any value(object, string, number)
	 *     replacer  [in, opt] - function object, similar to JavaScript's
	 *                           JSON.stringify() 'replacer' parameter
	 *     space     [in, opt] - similar to JavaScript's JSON.stringify()
	 *                           'space' parameter
	 */
	class Dump extends JSON.Functor
	{
		Call(self, value, replacer:="", space:="")
		{
			this.rep := IsObject(replacer) ? replacer : ""

			this.gap := ""
			if (space) {
				static integer := "integer"
				if space is %integer%
					Loop, % ((n := Abs(space))>10 ? 10 : n)
						this.gap .= " "
				else
					this.gap := SubStr(space, 1, 10)

				this.indent := "`n"
			}

			return this.Str({"": value}, "")
		}

		Str(holder, key)
		{
			value := holder[key]

			if (this.rep)
				value := this.rep.Call(holder, key, ObjHasKey(holder, key) ? value : JSON.Undefined)

			if IsObject(value) {
			; Check object type, skip serialization for other object types such as
			; ComObject, Func, BoundFunc, FileObject, RegExMatchObject, Property, etc.
				static type := A_AhkVersion<"2" ? "" : Func("Type")
				if (type ? type.Call(value) == "Object" : ObjGetCapacity(value) != "") {
					if (this.gap) {
						stepback := this.indent
						this.indent .= this.gap
					}

					is_array := value.IsArray
				; Array() is not overridden, rollback to old method of
				; identifying array-like objects. Due to the use of a for-loop
				; sparse arrays such as '[1,,3]' are detected as objects({}). 
					if (!is_array) {
						for i in value
							is_array := i == A_Index
						until !is_array
					}

					str := ""
					if (is_array) {
						Loop, % value.Length() {
							if (this.gap)
								str .= this.indent
							
							v := this.Str(value, A_Index)
							str .= (v != "") ? v . "," : "null,"
						}
					} else {
						colon := this.gap ? ": " : ":"
						for k in value {
							v := this.Str(value, k)
							if (v != "") {
								if (this.gap)
									str .= this.indent

								str .= this.Quote(k) . colon . v . ","
							}
						}
					}

					if (str != "") {
						str := RTrim(str, ",")
						if (this.gap)
							str .= stepback
					}

					if (this.gap)
						this.indent := stepback

					return is_array ? "[" . str . "]" : "{" . str . "}"
				}
			
			} else ; is_number ? value : "value"
				return ObjGetCapacity([value], 1)=="" ? value : this.Quote(value)
		}

		Quote(string)
		{
			static quot := Chr(34), bashq := "\" . quot

			if (string != "") {
				  string := StrReplace(string,  "\",  "\\")
				; , string := StrReplace(string,  "/",  "\/") ; optional in ECMAScript
				, string := StrReplace(string, quot, bashq)
				, string := StrReplace(string, "`b",  "\b")
				, string := StrReplace(string, "`f",  "\f")
				, string := StrReplace(string, "`n",  "\n")
				, string := StrReplace(string, "`r",  "\r")
				, string := StrReplace(string, "`t",  "\t")

				static rx_escapable := A_AhkVersion<"2" ? "O)[^\x20-\x7e]" : "[^\x20-\x7e]"
				while RegExMatch(string, rx_escapable, m)
					string := StrReplace(string, m.Value, Format("\u{1:04x}", Ord(m.Value)))
			}

			return quot . string . quot
		}
	}

	/**
	 * Property: Undefined
	 *     Proxy for 'undefined' type
	 * Syntax:
	 *     undefined := JSON.Undefined
	 * Remarks:
	 *     For use with reviver and replacer functions since AutoHotkey does not
	 *     have an 'undefined' type. Returning blank("") or 0 won't work since these
	 *     can't be distnguished from actual JSON values. This leaves us with objects.
	 *     Replacer() - the caller may return a non-serializable AHK objects such as
	 *     ComObject, Func, BoundFunc, FileObject, RegExMatchObject, and Property to
	 *     mimic the behavior of returning 'undefined' in JavaScript but for the sake
	 *     of code readability and convenience, it's better to do 'return JSON.Undefined'.
	 *     Internally, the property returns a ComObject with the variant type of VT_EMPTY.
	 */
	Undefined[]
	{
		get {
			static empty := {}, vt_empty := ComObject(0, &empty, 1)
			return vt_empty
		}
	}

	class Functor
	{
		__Call(method, ByRef arg, args*)
		{
		; When casting to Call(), use a new instance of the "function object"
		; so as to avoid directly storing the properties(used across sub-methods)
		; into the "function object" itself.
			if IsObject(method)
				return (new this).Call(method, arg, args*)
			else if (method == "")
				return (new this).Call(arg, args*)
		}
	}
}