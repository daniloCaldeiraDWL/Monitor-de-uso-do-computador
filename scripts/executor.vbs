' executor.vbs
' Lanca o RegistrarEvento.ps1 completamente sem janela visivel.
' Chamado pelo Agendador de Tarefas com o argumento ATIVACAO ou INATIVACAO.
' O uso de wscript.exe + CreateObject("WScript.Shell").Run com intHide=0
' garante que absolutamente nenhuma janela apareça na tela do usuario.

Dim tipo, scriptPath, psArgs, shell

tipo       = WScript.Arguments(0)
scriptPath = Replace(WScript.ScriptFullName, WScript.ScriptName, "") & "RegistrarEvento.ps1"
psArgs     = "-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass" & _
             " -File """ & scriptPath & """" & _
             " -Tipo " & tipo

Set shell = CreateObject("WScript.Shell")
' 0 = janela oculta, False = nao aguarda termino
shell.Run "powershell.exe " & psArgs, 0, False

Set shell = Nothing
