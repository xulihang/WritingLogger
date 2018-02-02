Type=Class
Version=5.9
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
'Class module
Sub Class_Globals
	Private text As String
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize()

End Sub

Sub summaryList(loglist As List) As List
	Dim resultList As List
	resultList.Initialize
	'表头
	Dim innerList As List
	innerList.Initialize
	innerList.AddAll(Array As String("ID","Word","Position","Type","StartTime","EndTime","Duration","ActionTime","Pause","PauseLocation","DocLength","WhichPara","RevisionType","DeleteByPressing"))
	resultList.Add(innerList)
	
	Dim previousPos=0 As Int

	Dim id As Int
	id=1 '用于表格的id
	
	

	For Each item As Map In loglist
		
		Dim fullDoc As String=getFullDoc(id,loglist) '获得该时间点的文本
		Try
			Dim fullDocPlusOne As String=getFullDoc(id+1,loglist)
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

		'生成列表

		Dim word As String
		word=item.Get("word")
		word=word.Replace(CRLF,"Enter")
		word=word.Replace(" ","Space")
		Dim innerList2 As List
		innerList2.Initialize
		innerList2.AddAll(Array As String(id,word,item.Get("pos"),item.Get("type"),startTime,endTime,duration,actionTime,pause,pauselocation,fullDoc.Length,getWhichParaBelongsTo(id,loglist),revisionType,DeleteByPressing))
		resultList.Add(innerList2)
		id=id+1
		previousPos=item.Get("pos")
	Next
	Return resultList
End Sub

Sub getFullDoc(id As Int,loglist As List) As String
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

Sub getWhichParaBelongsTo(id As Int,loglist As List) As Int
	Dim item As Map
	item=loglist.Get(id-1)
	Dim fullText As String
	fullText=getFullDoc(id,loglist)
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

Sub getWhichParaNowBelongsTo(id As Int,loglist As List) As Int
	Dim item As Map
	item=loglist.Get(id-1)
	Dim fullText As String
	fullText=getFullDoc(loglist.Size-1,loglist)
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