set bin_path=c:\bin
@rem if exist %bin_path% rmdir /s /q %bin_path%
mklink /j %bin_path% .
