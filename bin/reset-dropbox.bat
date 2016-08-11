echo %date% %time%
"%programfiles(x86)%\Forefront TMG Client\FwcTool.exe" enable
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" ^ /v ProxyEnable /t REG_DWORD /d 1 /f
taskkill /IM dropbox.exe /F
start %appdata%\dropbox\bin\dropbox /home
exit