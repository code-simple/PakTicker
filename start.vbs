Dim sh, fso, scriptPath, gadgetPath

Set sh  = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

scriptPath = WScript.ScriptFullName
gadgetPath = fso.GetParentFolderName(scriptPath) & "\coins_gadget.ps1"

' Launch silently
sh.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & gadgetPath & """", 0, False
