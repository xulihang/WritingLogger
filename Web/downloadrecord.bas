Type=Class
Version=5.9
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
'Handler class
Sub Class_Globals

End Sub

Public Sub Initialize
	
End Sub

Sub Handle(req As ServletRequest, resp As ServletResponse)
	Dim username As String
	username=req.RequestURI.SubString(req.RequestURI.LastIndexOf("/")+1)
	If File.Exists(File.Combine(File.DirApp,"www/tmp/"),username&".json")=False Then
		resp.SendError(500,"no record")
		Return
	End If
	buildzip(resp,username)
	StartMessageLoop 'see the thread in b4x forum: Resumable Subs (wait for / sleep) in server handlers
End Sub

Sub buildzip(resp As ServletResponse,username As String)
	Dim archiver As Archiver
	Dim filenames() As String
	filenames=Array As String(username&".json",username&".txt")
	archiver.AsyncZipFiles(File.Combine(File.DirApp,"www/tmp/"),filenames,File.DirApp,"www/tmp/zip/"&username&".zip","zip")
	wait for zip_zipDone(CompletedWithoutError As Boolean, NbOfFiles As Int)
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("/tmp/zip/").Append(username).Append(".zip")
	Log(sb.ToString)
	resp.SendRedirect(sb.ToString)
	StopMessageLoop
End Sub
