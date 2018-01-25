Type=Class
Version=5.9
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
'WebSocket class
Sub Class_Globals
	Private ws As WebSocket
	Private username,userlist,textarea As JQueryElement
	Private loginedUsername="" As String
	Private previousTimestamp=0 As Long
	Private old="" As String
	Private logList As List
End Sub

Public Sub Initialize
	If logList.IsInitialized=False Then
		logList.Initialize
	End If
End Sub

Private Sub WebSocket_Connected (WebSocket1 As WebSocket)
	ws = WebSocket1
	For Each key In UsersShared.connections.Keys
		addUser(key)
	Next
End Sub

Private Sub WebSocket_Disconnected
	If loginedUsername<> "" Then CallSubDelayed3(UsersShared, "removeConnection", Me,loginedUsername)
End Sub

Sub Enter_Click (Params As Map)
	Dim nf As Future = username.GetVal
	Dim name As String = nf.Value
	name = WebUtils.EscapeHtml(name.Trim)
    Log(name)
	If name="" Then
		ws.Alert("请输入用户名")
		Return
	End If
	If UsersShared.connections.ContainsKey(name) Then
		ws.Eval("alert('用户名已存在')",Null)
		ws.Flush
	Else
		Log(File.Exists(File.DirApp,"www/tmp/"&name&".txt"))
		If File.Exists(File.DirApp,"www/tmp/"&name&".txt") Then
			Dim confirm As Future
			confirm=ws.RunFunctionWithResult("show_confirm",Array as Object("检测到此前保存的记录，是否使用？"))
			Dim result As String=confirm.Value
			If result="true" Then
				loadRecord(name)
			End If
		End If
		loginedUsername=name
		CallSubDelayed3(UsersShared,"addConnection",Me,name)
	End If
End Sub

Sub Logout_Click (Params As Map)
	Dim nf As Future = username.GetVal
	Dim name As String = nf.Value
	name = WebUtils.EscapeHtml(name.Trim)
    Log(name)
	CallSubDelayed3(UsersShared,"removeConnection",Me,name)
End Sub

Sub Download_Click (Params As Map)
	save_Record(False)
	WebUtils.RedirectTo(ws,"/records")
	ws.Alert("请根据文件名找到并下载您的文件")
	ws.Flush
End Sub


Sub addUser(name As String)
	Log("ddd")
	userlist.RunMethod("append",Array As Object("<span id="&Chr(34)&name&Chr(34)&">"&name&"</span>"))
	ws.Flush
End Sub

Sub loadRecord(name As String)
	old=File.ReadString(File.DirApp,"www/tmp/"&name&".txt")
	textarea.SetVal(old)
	Dim json As JSONParser
	json.Initialize(File.ReadString(File.DirApp,"www/tmp/"&name&".json"))
	logList=json.NextArray
	Dim lastmap As Map
	lastmap=logList.Get(logList.Size-1)
	previousTimestamp=lastmap.Get("timestamp")
End Sub

Sub Logout(name As String)
	Log("ddd2")
	ws.Eval("$('span').remove('#"&name&"')",Null)
	ws.Flush
End Sub

Sub upload_Text(params As Map)
	If loginedUsername="" Then
		ws.Alert("请先登录！")
		ws.Flush
		Return
	End If
	If logList.Size=0 Then
		previousTimestamp=DateTime.Now
	End If
    Dim new As String
	Dim position As Int
	new=params.Get("text")
	position=params.Get("position")
	Dim map1 As Map
	map1.Initialize
	If new.Length>old.Length Then
        map1.Put("word",new.SubString2(position-new.Length+old.Length,position))
		map1.Put("type","new")
        map1.Put("pos",position)
		Dim time As Long
		time=DateTime.Now
		Log(time)
		Log(previousTimestamp)
		map1.Put("timestamp",time)
		map1.Put("duration",time-previousTimestamp)
		previousTimestamp=time
		logList.Add(map1)
		Log(map1)
		old=new
	Else if new.Length<old.Length Then
		Log(position)
		Log(old.Length)
		Log(new.Length)
		map1.Put("word",old.SubString2(position,position+old.Length-new.Length))
		map1.Put("type","revision")
		map1.Put("pos",position)
		Dim time As Long
		time=DateTime.Now
		map1.Put("timestamp",time)
		map1.Put("duration",time-previousTimestamp)
		previousTimestamp=time
		logList.Add(map1)
		Log(map1)
		old=new
	End If
	save_Record(True)
End Sub

Sub save_Record(istmp As Boolean)
	Dim json As JSONGenerator
	json.Initialize2(logList)
	DateTime.DateFormat="yyyy-MM-dd"
	DateTime.TimeFormat="-HH-mm-ss"
	Dim filename As String
	If istmp=True Then '判断是临时保存还是永久保存
		filename="www/tmp/"&loginedUsername
	Else
		filename="www/records/"&DateTime.Date(DateTime.Now)&DateTime.Time(DateTime.Now)&"-"&loginedUsername
        saveToCSV(filename)
	End If
	Log(filename)
	File.WriteString(File.DirApp,filename&".json",json.ToPrettyString(4))
	File.WriteString(File.DirApp,filename&".txt",old)
	ws.RunFunction("Saved",Null)
End Sub

Sub saveToCSV(filename As String)
	Dim csv As String
	For Each item As Map In logList
		For Each key As String In item.Keys
			csv=csv&"	"&key
		Next
		csv=csv&CRLF
		Exit'添加表头
	Next
	For Each item As Map In logList
		For Each key As String In item.Keys
			csv=csv&"	"&item.Get(key)
		Next
		csv=csv&CRLF
	Next
	File.WriteString(File.DirApp,filename&".csv",csv)
End Sub