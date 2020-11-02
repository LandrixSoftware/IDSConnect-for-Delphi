del intf.SHKConnectProzessListe.pas
del intf.SHKConnectBranchenliste.pas
del intf.SHKConnectAllgemeineAuskuenfte.pas
del intf.SHKConnectAnwenderIndividuelleAuskuenfte.pas

"C:\Program Files (x86)\Embarcadero\Studio\21.0\bin\WSDLIMP.exe" -P -D. -=+ @intf.SHKConnectWSDL.txt

ren intf_SHKConnectProzessListe.pas intf.SHKConnectProzessListe.pas
ren intf_SHKConnectBranchenliste.pas intf.SHKConnectBranchenliste.pas
ren intf_SHKConnectAllgemeineAuskuenfte.pas intf.SHKConnectAllgemeineAuskuenfte.pas
ren intf_SHKConnectAnwenderIndividuelleAuskuenfte.pas intf.SHKConnectAnwenderIndividuelleAuskuenfte.pas

pause