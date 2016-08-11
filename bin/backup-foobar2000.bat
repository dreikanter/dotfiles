@echo off
rem Saves foobar2000 installation from Program Files to dropbox

set foobar_path=%programfiles(x86)%/foobar2000
set conf_path=%AppData%\foobar2000\
set archive_path=c:/bin/foobar2000.zip
7za a -tzip -r -xr!.svn* %archive_path% %foobar_path%/*
rem database.dat wavecache.db
