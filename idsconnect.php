<?
  if (!isset($_REQUEST["sid"]))
    exit;

  //Callback-Warenkorb vom Onlineshop im Ordner idsconnect unter der SID abspeichern
  //der Unterordner idsconnect sollte die Berechtigung 700 haben, damit er oeffentlich nicht lesbar ist
  //die Callback-URL muss per https erreichbar sein
  if (isset($_REQUEST["warenkorb"]))
  {
    $fp = fopen("idsconnect/".$_REQUEST["sid"], "w");
    fputs($fp, ( get_magic_quotes_gpc() ) ? stripslashes($_REQUEST["warenkorb"]) : $_REQUEST["warenkorb"]);
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