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
	Dim previousPos=0 As Int
	Dim sb As StringBuilder
	Dim id As Int
	id=1 '用于表格的id
	sb.Initialize
	sb.Append("<p>过程记录：</p><table>")
	sb.Append("<tr>")
	For Each head As String In Array As String("ID","Word","Position","Type","StartTime","EndTime","Duration","ActionTime","Pause","PauseLocation","DocLength","WhichPara","RevisionType","DeleteByPressing")
		sb.Append("<th>"&head&"</th>")
	Next
	sb.Append("</tr>")
	For Each item As Map In loglist
		
		Dim fullDoc As String=getFullDoc(id) '获得该时间点的文本
		Try
			Dim fullDocPlusOne As String=getFullDoc(id+1)
			If fullDocPlusOne.Length<fullDoc.Length Then '说明此后一步是删除
				fullDocPlusOne=fullDoc
			End If
		Catch
			Log(LastException)
			fullDocPlusOne=fullDoc
		End Try
		
		'以下一段分析各种时间
		Dim keyloglist As List
		keyloglist=item.Get("keylog")
		Dim firstKeylog As Map
		firstKeylog=keyloglist.Get(0)
		Dim startTime,duration,endTime,actionTime,pause As Long
		startTime=firstKeylog.Get("time")
		duration=item.Get("duration")
		endTime=item.Get("timestamp")
		actionTime=endTime-startTime
		If duration>actionTime Then
		    pause=duration-actionTime
		Else
			pause=duration
		End If
		
		'分析修改类型
		Dim revisionType,DeleteByPressing As String
		If item.Get("type")="revision_del" Or item.Get("type")="revision_new" Then
			If item.Get("pos")-previousPos>1 Or item.Get("pos")-previousPos<-1 Then
				revisionType="Long distance"
			Else
				revisionType="Nearby"
			End If
        End If
		
		If item.Get("type")="revision_del" Then
		    If item.Get("pos")=previousPos Then
				DeleteByPressing="delete"
			Else
				DeleteByPressing="backspace"
			End If
			Try
				Dim nextitem As Map
				nextitem=loglist.Get(id)
				If item.Get("pos")=nextitem.Get("pos") Then
					DeleteByPressing="delete"
				End If
			Catch
				Log(LastException)
			End Try
		End If
		
		'分析停顿位置，这里的代码比较复杂
		Dim pauselocation As String
		Dim pos As Int
		pos=item.Get("pos")
		Dim left,right As String
		If item.Get("type")="new" Or item.Get("type")="revision_new" Then
			If pos-2<0 Then
				left="不存在"
			Else
				left=fullDocPlusOne.CharAt(pos-2)
			End If
			If pos=fullDocPlusOne.Length Then
				right="不存在"
			Else
				Log(fullDocPlusOne.Length)
				Log(pos)
				If fullDocPlusOne.Length<pos Then
					right="不存在"
				Else
					right=fullDocPlusOne.CharAt(pos)
				End If
				
			End If
			Log("left: "&left)
			Log("right: "&right)
			Dim su As ApacheSU
			If item.Get("word")=CRLF Then
				pauselocation="BEFORE PARAGRAPHS"
			else if right=CRLF Then
				pauselocation="AFTER PARAGRAPHS"
			else If isPunctuation(left) Or left="不存在" Or left=CRLF Then '. M
				pauselocation="BEFORE SENTENCES"
			else if IsContent(left) And isPunctuation(item.Get("word")) Then 'you. I
				pauselocation="AFTER SENTENCES"
			else if IsContent(left) And item.Get("word")<>" " And item.Get("word")<>"," Then 'Middle
				pauselocation="WITHIN WORDS"
			else if left="'" And item.Get("word")<>" " And item.Get("word")<>"," Then 'Middle
				pauselocation="WITHIN WORDS"
			else if item.Get("word")=" " Or item.Get("word")="," Then 'love you
				If IsContent(left) Or left="," Then
					pauselocation="AFTER WORDS"
				End If
			else if left=" " And IsContent(right) Then 'love you
				pauselocation="BEFORE WORDS"
			else if left=" " And right=" " Then ' I 
				pauselocation="BEFORE WORDS"
			End If
			'pauselocation=left&pauselocation&right.Replace(CRLF,"Enter").Replace(" ","Space")
			Log(pauselocation)
		Else
			pauselocation="REVISION_DEL"
		End If

		'生成表格
		
		sb.Append("<tr>")
		Dim word As String
		word=item.Get("word")
		word=word.Replace(CRLF,"Enter")
		word=word.Replace(" ","Space")
		For Each col As String In Array As String(id,word,item.Get("pos"),item.Get("type"),startTime,endTime,duration,actionTime,pause,pauselocation,fullDoc.Length,getWhichParaBelongsTo(id),revisionType,DeleteByPressing)
			sb.Append("<th>"&col&"</th>")
		Next
		sb.Append("</tr>")
		id=id+1
		previousPos=item.Get("pos")
	Next
	sb.Append("</table>")
	summary.SetHtml(sb.ToString)
End Sub

Sub showparainfo_Click(Params As Map)
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
			paras=su.SplitWithSeparator(getFullDoc(id),CRLF)
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
			paras=su.SplitWithSeparator(getFullDoc(id),CRLF)
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

Sub getWhichParaBelongsTo(id As Int) As Int
	Dim item As Map
	item=loglist.Get(id-1)
    Dim fullText As String
	fullText=getFullDoc(id)
	Dim paras As List
	Dim su As ApacheSU
	paras=su.SplitWithSeparator(fullText,CRLF)
	
    For i=0 To paras.Size-1
		Dim paraCombined As String
		For j=0 To i
			paraCombined=paraCombined&CRLF&paras.Get(j)
		Next
		Log(item.Get("pos"))
		Log(paraCombined)
		If item.Get("pos")<paraCombined.Length Then
		    Return i+1
		End If
	Next
End Sub


Sub getWhichParaNowBelongsTo(id As Int) As Int
	Dim item As Map
	item=loglist.Get(id-1)
    Dim fullText As String
	fullText=getFullDoc(loglist.Size-1)
	Dim paras As List
	Dim su As ApacheSU
	paras=su.SplitWithSeparator(fullText,CRLF)
    For i=0 To paras.Size-1
		Dim paraCombined As String
		For j=0 To i
			paraCombined=paraCombined&CRLF&paras.Get(j)
		Next
		Log(item.Get("pos"))
		Log(paraCombined)
		If item.Get("pos")<paraCombined.Length Then
		    Return i+1
		End If
    Next
End Sub

Sub getFullDoc(id As Int) As String
	text=""
	Dim currentPos As Int=1 '因为id设的是以1起始，所以这里不是0
	For Each item As Map In loglist
		If currentPos>id Then
			Exit
		End If
		Dim word As String
		Dim before,after As String
		word=item.Get("word")
		Dim pos As Int
		pos=item.Get("pos")
		If item.Get("type")="new" Or item.Get("type")="revision_new" Then
			pos=pos-word.Length
			before=text.SubString2(0,pos)
			after=text.SubString2(pos,text.Length)
			text=before&item.Get("word")&after
		Else
			pos=pos+word.Length
			before=text.SubString2(0,pos)
			after=text.SubString2(pos,text.Length)
			text=before.SubString2(0,before.Length-word.Length)&after
		End If
		currentPos=currentPos+1
	Next
	Return text
End Sub

Sub isPunctuation(mark As String) As Boolean
	Select mark
		Case ".","!","?",";"
			Return True
		Case Else
			Return False
	End Select
End Sub

Sub IsContent(txt As String) As Boolean
	Dim su As ApacheSU
	If su.IsEmpty(txt)=False And isPunctuation(txt)=False And txt<>" " And txt<>CRLF Then
		Return True
	Else
		Return False
	End If
End Sub