Type=StaticCode
Version=5.9
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
    Public LoginForm As Form
	Private Button1 As Button
	Private TextField1 As TextField
End Sub

Public Sub Show
	LoginForm.Initialize("LoginForm",300,300)
	LoginForm.RootPane.LoadLayout("login") 'Load the layout file.
	LoginForm.Show
End Sub

Sub Button1_MouseClicked (EventData As MouseEvent)
	If TextField1.Text<>"" Then
		Main.username=TextField1.Text
		Main.wsh.SendEventToServer("user_login",CreateMap("username":Main.username))
	Else
		fx.Msgbox(LoginForm,"请输入你的名字","")
	End If
End Sub