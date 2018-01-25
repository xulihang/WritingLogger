Type=StaticCode
Version=5.9
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
	
Sub Process_Globals
	Public connections As Map
End Sub

Public Sub Init
	'this map is accessed from other threads so it needs to be a thread safe map
	connections.Initialize
End Sub


Public Sub addConnection(w As Writing,name As String)
	connections.Put(name, w)
	Log("connection added"&w)
	Log(connections)
End Sub



Public Sub removeConnection(w As Writing, name As String)
	If connections.ContainsKey(name) = False Or connections.Get(name) <> w Then Return
	connections.Remove(name)
	Log(name&" exited")
End Sub