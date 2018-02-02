Type=Class
Version=5.9
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
'WebSocket class
Sub Class_Globals
	Private ws As WebSocket
	Private username,userlist,textarea,taskbar,login,downrecord As JQueryElement
	Private loginedUsername="" As String
	Private previousTimestamp=0 As Long
	'Private old="" As String
	Private logList As List
	Private keyLogList As List
End Sub

Public Sub Initialize
	If logList.IsInitialized=False Then
		logList.Initialize
	End If
	If keyLogList.IsInitialized=False Then
		keyLogList.Initialize
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
			confirm=ws.RunFunctionWithResult("show_confirm",Array As Object("检测到此前保存的记录，是否使用？"))
			Dim result As String=confirm.Value
			If result="true" Then
				loadRecord(name)
			End If
		End If
		loginedUsername=name
		ws.Session.SetAttribute("username",loginedUsername)
		login.SetHtml("<p>"&name&"已登录</p>")
		downrecord.SetProp("href","/downloadrecord/"&name)
		taskbar.SetCSS("display","inherit")
		CallSubDelayed3(UsersShared,"addConnection",Me,name)
	End If
End Sub

Sub Logout_Click (Params As Map)
	save_Record(False)
	CallSubDelayed3(UsersShared,"removeConnection",Me,loginedUsername)
End Sub

Sub addUser(name As String) '更新已登录用户列表
	userlist.RunMethod("append",Array As Object("<span id="&Chr(34)&name&Chr(34)&">"&name&"</span>"))
	ws.Flush
End Sub

Sub loadRecord(name As String)
	Dim old As String
	old=File.ReadString(File.DirApp,"www/tmp/"&name&".txt")
	ws.Eval("old=arguments[0]",Array As Object(old)) '需要给客户端也重新加载
	ws.Flush
	textarea.SetVal(old)
	Dim json As JSONParser
	json.Initialize(File.ReadString(File.DirApp,"www/tmp/"&name&".json"))
	logList=json.NextArray
	Dim lastmap As Map
	lastmap=logList.Get(logList.Size-1)
	previousTimestamp=lastmap.Get("timestamp")
End Sub

Sub UsersExited(name As String)
	ws.Eval("$('span').remove('#"&name&"')",Null)
	ws.Flush
End Sub

Sub Logout(name As String)
	ws.Eval("$('span').remove('#"&name&"')",Null)
	login.SetText("未连接")
	taskbar.SetHtml("<a href="&Chr(34)&"/analyser.html"&Chr(34)&">分析记录</a>")
	ws.Alert("您已登出")
	ws.Flush
	ws.Close
End Sub

Sub onchange(params As Map) '用于响应oninput事件
	If logList.Size=0 Then
		previousTimestamp=DateTime.Now
	End If
	Dim time As Long
	time=DateTime.Now
	Dim list1 As List
	list1.Initialize
	list1.AddAll(keyLogList)
	'list1=keyLogList 不能用这行代码，会变成实参
	params.Put("timestamp",time)
	params.Put("duration",time-previousTimestamp)
	params.Put("keylog",list1)
	previousTimestamp=time
	logList.Add(params)
	Log(params)
	save_Record(True)
	keyLogList.Clear
End Sub

Sub up_load(params As Map)
	If loginedUsername="" Then
		ws.Alert("请先登录！")
		ws.Flush
		Return
	End If
	onchange(params)
	Log("oninput")
End Sub

Sub key_down(params As Map)
    Log("key_down")
    Dim map1 As Map
	map1.Initialize
    map1.Put("key",params.Get("key"))
	map1.Put("time",DateTime.Now)
	map1.Put("type","keydown")
    keyLogList.Add(map1)
	Log(keyLogList)
End Sub

Sub key_press(params As Map)
	Log("key_press"&DateTime.Now)
	Dim map1 As Map
	map1.Initialize
	map1.Put("key",params.Get("key"))
	map1.Put("time",DateTime.Now)
	map1.Put("type","keypress")
	keyLogList.Add(map1)
	Log(keyLogList)
End Sub

Sub save_Record(istmp As Boolean) As String
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
	Dim tf As Future
	tf=textarea.GetVal
	Dim old As String
	old=tf.Value
	File.WriteString(File.DirApp,filename&".txt",old)
	Return filename
End Sub

Sub saveToCSV(filename As String)
	Dim au As analysingUtils
	au.Initialize
	Dim resultList As List
	resultList=au.summaryList(logList)
	Dim csv As String
	For Each itemList As List In resultList
		Dim line As String
		For Each item As String In itemList
			If line="" Then
				line=item
			Else
				line=line&"	"&item
		    End If
		Next
		csv=csv&line&CRLF
	Next
	File.WriteString(File.DirApp,filename&".csv",csv)
End Sub

Sub saveToCSVOld(filename As String)
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