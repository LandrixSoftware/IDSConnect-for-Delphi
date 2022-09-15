<?
/*
License
Copyright (C) 2022 Landrix Software GmbH & Co. KG
Sven Harazim, info@landrix.de

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

  if (!isset($_REQUEST["sid"]))
    exit;

  //Callback-Warenkorb vom Onlineshop im Ordner idsconnect unter der SID abspeichern
  //der Unterordner idsconnect sollte die Berechtigung 700 haben, damit er oeffentlich nicht lesbar ist
  //die Callback-URL muss per https erreichbar sein
  if (isset($_REQUEST["warenkorb"]))
  {
    $fp = fopen("idsconnect/".$_REQUEST["sid"], "w");
    fputs($fp, $_REQUEST["warenkorb"]);
    fclose($fp);
?>
<html>
<head>
<title>IDS-SCHNITTSTELLE</title>
</head>
<body>
<h1>Schlie&szlig;en Sie nun den Browser und setzen Sie die Bearbeitung in der Software fort!</h1>    
</body>
</html>
<?
  }
  else
  {
    if (file_exists("idsconnect/".$_REQUEST["sid"])) 
    {
      $datei = file("idsconnect/".$_REQUEST["sid"]);
      foreach($datei as $meine_datei)
      {
        echo $meine_datei;
      }
    }
  }
?>