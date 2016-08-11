set st_home="%appdata%\Desktop\Sublime Text 2"
set backup_path=D:\private\dropbox\backup\sublime

rem TODO: Add parameters for backup and restore

rem @echo off
rem Backups Sublime Text configuration and packages to Dropbox (or any other location)

call sublime-env.bat
if not exist %backup_path% mkdir %backup_path%
rem 7za a -tzip -r %backup_path%/sublime-profile.zip %st_home%
