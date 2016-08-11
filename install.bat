if exist %userprofile%\.gitconfig move /y %userprofile%\.gitconfig %userprofile%\.gitconfig.bak
mklink "%userprofile%\.gitconfig" "d:\src\dotfiles\win\.gitconfig"
setx home %userprofile%
