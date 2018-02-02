Type=Class
Version=5.9
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
'WebSocket class
Sub Class_Globals
	Private ws As WebSocket
	Private textarea,summary,parainfo As JQueryElement
	Private text As String
	Private filename As String
	Private username As String
	Private loglist As List
	
End Sub

Public Sub Initialize
	
End Sub

Private Sub WebSocket_Connected (WebSocket1 As WebSocket)
	ws = WebSocket1
	Log("connected")
	If ws.Session.HasAttribute("filename") Then '用于分析用户上传的文件
		Log(ws.Session.GetAttribute("filename"))
		filename=ws.Session.GetAttribute("filename")
		ws.Session.RemoveAttribute("filename")
	Else If ws.Session.HasAttribute("username") Then '用于写完后直接进行分析
		username=ws.Session.GetAttribute("username")
	Else
		ws.Alert("并未上传文件")
		ws.Flush
		ws.Close
		Return
	End If
	init
End Sub

Private Sub WebSocket_Disconnected

End Sub

Sub init
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
End Sub

Sub replayRecord
	text=""
	For Each item As Map In loglist
		Dim word As String
		Dim before,after As String
		word=item.Get("word")
		Dim pos As Int
		pos=item.Get("pos")
		If item.Get("type")="new" Or item.Get("type")="revision_new" Then
			Sleep(item.Get("duration")) '回放的时候反映停顿时间
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

Sub showsummary_Click(Params As Map)
	Dim sb As StringBuilder
	Dim au As analysingUtils
	au.Initialize
	Dim resultList As List
	resultList=au.summaryList(loglist)
	sb.Initialize
	sb.Append("<p>过程记录：</p><table>")
	'生成表格
	For Each itemList As List In resultList
		sb.Append("<tr>")
		For Each item As String In itemList
			sb.Append("<th>"&item&"</th>")
		Next
		sb.Append("</tr>")
	Next
	sb.Append("</table>")
	summary.SetHtml(sb.ToString)
End Sub

Sub showparainfo_Click(Params As Map)
	Dim au As analysingUtils
	au.Initialize
	Dim startTime As Long
	Dim paras As List
	paras.Initialize
	Dim parasInfo As List
	parasInfo.Initialize
	Dim id As Int
	id=1
	For Each item As Map In loglist
		If id=1 Then
			startTime=item.Get("timestamp")
		End If
		Dim su As ApacheSU
		If item.Get("word")=CRLF And item.Get("type")="new" Then
			paras=su.SplitWithSeparator(au.getFullDoc(id,loglist),CRLF)
			Log(parasInfo.Size)
			Dim fullText As String
			fullText=paras.Get(parasInfo.Size)
			Dim oneparainfo As Map
			oneparainfo.Initialize
			oneparainfo.Put("writingTime",item.Get("timestamp")-startTime)
			oneparainfo.Put("length",fullText.Length)
			parasInfo.Add(oneparainfo)
		'else if If item.Get("word")=CRLF And item.Get("type")="revision" Then '目前不处理删除段落的情况
		End If
		If id=loglist.Size Then '避免最后一段被忽略，但是遇到在删除情况就不好使了，说明这里段落的分析方式不合理
			paras=su.SplitWithSeparator(au.getFullDoc(id,loglist),CRLF)
			Log(parasInfo.Size)
			Dim fullText As String
			fullText=paras.Get(parasInfo.Size)
			Dim oneparainfo As Map
			oneparainfo.Initialize
			oneparainfo.Put("writingTime",item.Get("timestamp")-startTime)
			oneparainfo.Put("length",fullText.Length)
			parasInfo.Add(oneparainfo)
		End If
		id=id+1
	Next
	Dim sb As StringBuilder
	sb.Initialize
	For i=1 To parasInfo.Size
		Dim oneparainfo As Map
		oneparainfo=parasInfo.Get(i-1)
		sb.Append("<p>第"&i&"段用时："&oneparainfo.Get("writingTime")&"ms ")
		sb.Append("第"&i&"段长度："&oneparainfo.Get("length")&"</p>")
	Next
	parainfo.SetHtml(sb.ToString)
	Log(paras)
	Log(parasInfo)
End Sub