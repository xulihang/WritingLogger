Type=StaticCode
Version=5.9
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@

Sub Process_Globals
	
End Sub

Public Sub EscapeHtml(Raw As String) As String
   Dim sb As StringBuilder
   sb.Initialize
   For i = 0 To Raw.Length - 1
     Dim C As Char = Raw.CharAt(i)
     Select C
       Case QUOTE
         sb.Append("&quot;")
       Case "'"
         sb.Append("&#39;")
       Case "<"
         sb.Append("&lt;")
       Case ">"
         sb.Append("&gt;")
       Case "&"
         sb.Append("&amp;")
       Case Else
         sb.Append(C)
     End Select
   Next
   Return sb.ToString
End Sub

Public Sub ReplaceMap(Base As String, Replacements As Map) As String
	For i = 0 To Replacements.Size - 1
		Base = Base.Replace("$" & Replacements.GetKeyAt(i) & "$", Replacements.GetValueAt(i))
	Next
	Return Base
End Sub

Public Sub RedirectTo(ws As WebSocket, TargetUrl As String)
	ws.Eval("window.location = arguments[0]", Array As Object(TargetUrl))
End Sub

Public Sub PopUpWindows(ws As WebSocket, TargetUrl As String)
	ws.Eval("window.open("&TargetUrl&")",Null)
End Sub