set dest=d:\private\dropbox\backup\h2.zip
set backup=h2.old.zip
if exist %dest% move /y %dest% %backup%
7za a -tzip -mx9 -x!*.pyc -xr!hydrogen\test-* %dest% hydrogen
