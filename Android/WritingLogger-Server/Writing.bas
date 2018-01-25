Type=Class
Version=5.9
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
'WebSocket class
Sub Class_Globals
	Private ws As WebSocket
	Private logList As List
	Private username As String
End Sub

Public Sub Initialize
	logList.Initialize
End Sub

Private Sub WebSocket_Connected (WebSocket1 As WebSocket)
	ws = WebSocket1
End Sub

Private Sub WebSocket_Disconnected
	If username<> "" Then CallSubDelayed3(UsersShared, "removeConnection", Me,username)
End Sub

Sub user_login(map1 As Map)
	username = map1.GetValueAt(0)
	Log(username)
	If UsersShared.connections.ContainsKey(username) Then
		ws.RunFunction("duplicate",Null)
	Else
		CallSubDelayed3(UsersShared,"addConnection",Me,map1.GetValueAt(0))
		ws.RunFunction("loggedin",Null)
	End If
End Sub

Sub upload_Text(map1 As Map)
	logList.Add(map1)
	Log(logList)
End Sub

Sub stop_Recording(map1 As Map)
	Dim json As JSONGenerator
	json.Initialize2(logList)
	DateTime.DateFormat="yyyy-MM-dd"
	DateTime.TimeFormat="-HH-mm-ss"
	Dim filename As String
	filename=DateTime.Date(DateTime.Now)&DateTime.Time(DateTime.Now)&"-"&username
	Log(filename)
	File.WriteString(File.DirApp,filename&".json",json.ToPrettyString(4))
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
	ws.RunFunction("Saved",Null)
	logList.Clear
End Sub