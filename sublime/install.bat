@echo on
set user_path="%appdata%\Sublime Text 3\Packages\User"
set backup_dir=User.backup
set backup_path="%appdata%\Sublime Text 3\Packages\%backup_dir%"
if exist %backup_path% rmdir /s /q %backup_path%
if exist %user_path% ren %user_path% %backup_dir%
mklink /j %user_path% User
