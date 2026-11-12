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
//
// Ablauf: Der Shop sendet den Warenkorb per POST (Feld "warenkorb") an
// ?sid=<uuid>. Die Handwerkssoftware ruft dieselbe Adresse per GET ab.
// Jede Uebertragung wird als eigene Datei in eine Warteschlange je sid
// gelegt; jeder Abruf liefert die aelteste und loescht sie. Damit gehen bei
// der Mehrfachrueckgabe (multipleResult, IDS 2.5.1) keine Rueckgaben
// verloren, und derselbe Warenkorb wird nie zweimal ausgeliefert.
// Frueher gab es nur eine Datei je sid: eine zweite Uebertragung vor dem
// naechsten Abruf ueberschrieb die erste.

const IDSCONNECT_DIR      = 'idsconnect';
const IDSCONNECT_MAX_SIZE = 4 * 1024 * 1024; // max. Groesse eines Warenkorbs
const IDSCONNECT_TTL      = 3600;            // Sekunden, danach gilt die Ablage als verfallen

// Die sid stammt aus TIDSConnect.GetUuid und ist immer eine UUID ohne
// geschweifte Klammern. Frueher wurde sie ungeprueft an den Dateipfad
// gehaengt - damit liessen sich ueber "../" beliebige Dateien lesen und
// ueberschreiben.
function idsconnect_sid()
{
  if (!isset($_REQUEST['sid']))
    return null;

  $sid = $_REQUEST['sid'];
  if (!is_string($sid))
    return null;
  if (!preg_match('/^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$/', $sid))
    return null;

  return strtolower($sid);
}

// Abgelaufene Ablagen entfernen, damit keine Warenkoerbe unbegrenzt liegen bleiben
function idsconnect_cleanup()
{
  if (!is_dir(IDSCONNECT_DIR))
    return;
  $limit = time() - IDSCONNECT_TTL;
  foreach (glob(IDSCONNECT_DIR . '/*') ?: [] as $file)
  {
    if (is_file($file) && filemtime($file) < $limit)
      @unlink($file);
  }
}

// Fertig geschriebene Rueckgaben einer sid, aelteste zuerst. Der Dateiname
// beginnt nach der sid mit einem Zeitstempel fester Breite, deshalb ergibt
// die Sortierung nach Namen die Eingangsreihenfolge.
function idsconnect_queue($sid)
{
  $files = glob(IDSCONNECT_DIR . '/' . $sid . '.*.xml') ?: [];
  sort($files, SORT_STRING);
  return $files;
}

$sid = idsconnect_sid();
if ($sid === null)
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

  // Erst unter einem Namen schreiben, den der Abruf nicht sieht, dann
  // umbenennen: rename ist atomar, ein paralleler Abruf findet also nie eine
  // halb geschriebene Datei.
  $name = IDSCONNECT_DIR . '/' . $sid . '.' . sprintf('%017.6f', microtime(true))
        . '-' . bin2hex(random_bytes(4)) . '.xml';
  $tmp = $name . '.tmp';
  if (file_put_contents($tmp, $warenkorb) === false)
  {
    http_response_code(500);
    exit;
  }
  @chmod($tmp, 0600);
  if (!@rename($tmp, $name))
  {
    @unlink($tmp);
    http_response_code(500);
    exit;
  }

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
  // Die aelteste Rueckgabe zuerst durch Umbenennen fuer diesen Abruf
  // beanspruchen. Gelingt das nicht, hat ein paralleler Abruf sie bereits
  // genommen - dann die naechste versuchen. So wird jede Rueckgabe genau
  // einmal ausgeliefert.
  foreach (idsconnect_queue($sid) as $file)
  {
    $claimed = $file . '.claimed-' . bin2hex(random_bytes(4));
    if (!@rename($file, $claimed))
      continue;
    $data = @file_get_contents($claimed);
    @unlink($claimed);
    if ($data === false)
      continue;
    header('Content-Type: text/xml; charset=utf-8');
    // Eindeutige Kennung der Uebertragung: Daran erkennt der Client eine
    // wiederholt ausgelieferte Rueckgabe, ohne zwei inhaltsgleiche, aber
    // eigenstaendige Uebertragungen zu verwechseln
    header('X-IDSConnect-Id: ' . basename($file, '.xml'));
    echo $data;
    exit;
  }

  // Noch nichts eingetroffen - fuer den Client der Normalfall waehrend des Wartens
  http_response_code(404);
}
?>
