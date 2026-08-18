<?php
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

// Callback-Endpunkt fuer die IDS-Connect-Rueckuebertragung.
//
// Der Unterordner "idsconnect" muss ausserhalb des oeffentlich lesbaren
// Bereichs liegen bzw. die Berechtigung 700 haben.
// Die Callback-URL muss per https erreichbar sein.

const IDSCONNECT_DIR      = 'idsconnect';
const IDSCONNECT_MAX_SIZE = 4 * 1024 * 1024; // max. Groesse eines Warenkorbs
const IDSCONNECT_TTL      = 3600;            // Sekunden, danach gilt die Ablage als verfallen

// Die sid stammt aus TIDSConnect.GetUuid und ist immer eine UUID ohne
// geschweifte Klammern. Frueher wurde sie ungeprueft an den Dateipfad
// gehaengt - damit liessen sich ueber "../" beliebige Dateien lesen und
// ueberschreiben.
function idsconnect_sid_path()
{
  if (!isset($_REQUEST['sid']))
    return null;

  $sid = $_REQUEST['sid'];
  if (!is_string($sid))
    return null;
  if (!preg_match('/^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$/', $sid))
    return null;

  return IDSCONNECT_DIR . '/' . strtolower($sid);
}

// Abgelaufene Ablagen entfernen, damit keine Warenkoerbe unbegrenzt liegen bleiben
function idsconnect_cleanup()
{
  if (!is_dir(IDSCONNECT_DIR))
    return;
  $limit = time() - IDSCONNECT_TTL;
  foreach (glob(IDSCONNECT_DIR . '/*') as $file)
  {
    if (is_file($file) && filemtime($file) < $limit)
      @unlink($file);
  }
}

$path = idsconnect_sid_path();
if ($path === null)
{
  http_response_code(400);
  exit;
}

idsconnect_cleanup();

if (isset($_REQUEST['warenkorb']))
{
  $warenkorb = $_REQUEST['warenkorb'];
  if (!is_string($warenkorb) || strlen($warenkorb) > IDSCONNECT_MAX_SIZE)
  {
    http_response_code(413);
    exit;
  }

  if (!is_dir(IDSCONNECT_DIR))
    @mkdir(IDSCONNECT_DIR, 0700, true);

  // LOCK_EX, damit ein paralleler Abruf keine halb geschriebene Datei liest
  if (file_put_contents($path, $warenkorb, LOCK_EX) === false)
  {
    http_response_code(500);
    exit;
  }
  @chmod($path, 0600);

  header('Content-Type: text/html; charset=utf-8');
?>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>IDS-SCHNITTSTELLE</title>
</head>
<body>
<h1>Schlie&szlig;en Sie nun den Browser und setzen Sie die Bearbeitung in der Software fort!</h1>
</body>
</html>
<?php
}
else
{
  if (!is_file($path))
  {
    http_response_code(404);
    exit;
  }

  header('Content-Type: text/xml; charset=utf-8');
  readfile($path);

  // Einmalabruf: nach der Uebergabe an die Handwerkssoftware wird die
  // Ablage geloescht, damit der Warenkorb nicht abrufbar liegen bleibt.
  // Fuer die Mehrfachrueckgabe nach IDS 2.5.1 (multipleResult) muss diese
  // Zeile entfallen und stattdessen auf die TTL oben vertraut werden.
  @unlink($path);
}
?>
