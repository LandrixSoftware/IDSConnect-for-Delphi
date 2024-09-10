<?
/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
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