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
	Try
		If req.ContentType.StartsWith("multipart/form-data") Then
			Dim parts As Map = req.GetMultipartData(File.DirApp & "/www/uploaded", 10000000)
			Dim filepart As Part = parts.Get("file1")
			If filepart.SubmittedFilename.EndsWith("json")=False Then
				resp.ContentType="text/html"
				resp.Write("请上传下载的json文件")
				Return
			End If
			req.GetSession.SetAttribute("filename",filepart.SubmittedFilename)
			Log(filepart.IsFile)
			File.Copy(filepart.TempFile,"",File.DirApp,"/www/uploaded/"&filepart.SubmittedFilename)
			File.Delete(filepart.TempFile,"")
		End If
		resp.SendRedirect("/analyser.html")
	Catch
		resp.SendError(500, LastException)
	End Try
	
End Sub