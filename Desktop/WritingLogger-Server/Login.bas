Type=Class
Version=5.9
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
'WebSocket class
Sub Class_Globals
	Private ws As WebSocket
End Sub

Public Sub Initialize
	
End Sub

Private Sub WebSocket_Connected (WebSocket1 As WebSocket)
	ws = WebSocket1
End Sub

Private Sub WebSocket_Disconnected

End Sub

Sub user_login(map1 As Map)
	Dim username As String
	username = map1.GetValueAt(0)
	If UsersShared.connections.ContainsKey(username) Then
		ws.RunFunction("duplicate",Null)
	Else
		ws.RunFunction("refresh",Null)
	End If
End Sub