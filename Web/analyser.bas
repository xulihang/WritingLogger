Type=Class
Version=5.9
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
'WebSocket class
Sub Class_Globals
	Private ws As WebSocket
	Private textarea As JQueryElement
	Private text As String
	Private filename As String
	Private username As String
End Sub

Public Sub Initialize
	
End Sub

Private Sub WebSocket_Connected (WebSocket1 As WebSocket)
	ws = WebSocket1
	Log("connected")
	If ws.Session.HasAttribute("filename") Then
		Log(ws.Session.GetAttribute("filename"))
		filename=ws.Session.GetAttribute("filename")
		ws.Session.RemoveAttribute("filename")
	Else If ws.Session.HasAttribute("username") Then
		username=ws.Session.GetAttribute("username")
	Else
		ws.Alert("并未上传文件")
		ws.Flush
		ws.Close
		
	End If
End Sub

Private Sub WebSocket_Disconnected

End Sub

Sub replayRecord
	Dim loglist As List
	Dim path As String
	If filename<>"" Then
	    path=File.Combine(File.DirApp,"/www/uploaded/"&filename)
	else if username<>"" Then
		path=File.Combine(File.DirApp,"/www/tmp/"&username&".json")
	End If
	Dim json As JSONParser
	json.Initialize(File.Readstring(path,""))
	loglist=json.NextArray
	Log(loglist)
	text=""
	For Each item As Map In loglist
		Dim word As String
		Dim before,after As String
		word=item.Get("word")
		Dim pos As Int
		pos=item.Get("pos")
		If item.Get("type")="new" Then
			Sleep(item.Get("duration"))
			pos=pos-word.Length
			before=text.SubString2(0,pos)
			after=text.SubString2(pos,text.Length)
			text=before&item.Get("word")&after
			ws.Eval("textarea.textContent=arguments[0]", Array As Object(text))
			ws.Eval("textarea.selectionStart=arguments[0]", Array As Object(pos+word.Length))
			ws.Flush
		Else
			Sleep(item.Get("duration"))
			pos=pos+word.Length
			before=text.SubString2(0,pos)
			after=text.SubString2(pos,text.Length)
			text=before.SubString2(0,before.Length-word.Length)&after
			ws.Eval("textarea.textContent=arguments[0]", Array As Object(text))
			ws.Eval("textarea.selectionStart=arguments[0]", Array As Object(pos-word.Length))
			ws.Flush
		End If
	Next
End Sub

Sub replay_Click(Params As Map)
	replayRecord
End Sub