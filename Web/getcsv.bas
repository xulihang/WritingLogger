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
	buildzip(resp)
	StartMessageLoop
End Sub

Sub buildzip(resp As ServletResponse)
	
	Dim fileNum=0 As Int
	For Each filename As String In File.ListFiles(File.Combine(File.DirApp,"www/records"))
		If filename.EndsWith(".csv") Then
            fileNum=fileNum+1
		End If
	Next
	Dim filenames(fileNum) As String
	fileNum=0
	For Each filename As String In File.ListFiles(File.Combine(File.DirApp,"www/records"))
		If filename.EndsWith(".csv") Then
			filenames(fileNum)=filename
			fileNum=fileNum+1
		End If
	Next
	Dim archiver As Archiver

	archiver.AsyncZipFiles(File.Combine(File.DirApp,"www/records/"),filenames,File.DirApp,"www/records/all.zip","zip")
	wait for zip_zipDone(CompletedWithoutError As Boolean, NbOfFiles As Int)
	resp.SendRedirect("/records/all.zip")
	StopMessageLoop
End Sub