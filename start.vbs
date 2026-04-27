Dim sh, fso, scriptPath, gadgetPath, startupKey, existing

Set sh  = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

scriptPath = WScript.ScriptFullName
gadgetPath = fso.GetParentFolderName(scriptPath) & "\coins_gadget.ps1"

' Register in startup on first run
startupKey = "HKCU\Software\Microsoft\Windows\CurrentVersion\Run\CoinsGadget"
On Error Resume Next
existing = sh.RegRead(startupKey)
If Err.Number <> 0 Or existing = "" Then
    sh.RegWrite startupKey, "wscript.exe """ & scriptPath & """", "REG_SZ"
End If
On Error GoTo 0

' Launch silently
sh.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & gadgetPath & """", 0, False
