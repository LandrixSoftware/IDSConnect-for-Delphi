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
// Ablage: Die Warenkoerbe (mit Preisen und Kundendaten) liegen in
// "idsconnect-data" NEBEN dem Ordner dieses Skripts. Liegt das Skript direkt
// im Webroot, ist das ausserhalb; liegt es tiefer (z. B. /var/www/html/hooks/),
// ist es noch im Webroot - dann IDSCONNECT_DIR setzen. Ein anderer Ordner
// laesst sich ueber die Umgebungsvariable IDSCONNECT_DIR setzen (Apache:
// SetEnv). Ist der Ordner nicht anlegbar (z. B. open_basedir), wird
// "idsconnect" im Skriptordner verwendet.
// In jeden Ablageordner werden eine .htaccess (Zugriff verboten) und eine
// leere index.html (kein Verzeichnislisting) gelegt; lassen sie sich nicht
// anlegen, nimmt das Skript nichts an. Die .htaccess wirkt nur bei Apache
// mit AllowOverride (mindestens AuthConfig bzw. All); bei nginx oder
// AllowOverride None den Ordner in der Serverkonfiguration sperren.
// Frueher stand hier, die Berechtigung 700 schuetze den Ordner im Webroot -
// das gilt nicht, wenn PHP und Webserver derselbe Benutzer sind.
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

const IDSCONNECT_MAX_SIZE  = 4 * 1024 * 1024;  // max. Groesse eines Warenkorbs
const IDSCONNECT_MAX_TOTAL = 64 * 1024 * 1024; // max. Gesamtgroesse der Ablage (Umgebungsvariable IDSCONNECT_MAX_TOTAL)
const IDSCONNECT_MIN_FILE  = 4096;             // so viel zaehlt jede Datei mindestens (auch eine leere)
const IDSCONNECT_TTL       = 3600;             // Sekunden, danach gilt die Ablage als verfallen

// Dateinamen der Ablage: <sid>.<Zeitstempel>-<Zufall>.dat, beim Schreiben mit
// .tmp, beim Abruf mit .claimed-<Zufall>. Die Endung .dat statt frueher .xml:
// Wird eine Datei doch direkt abgerufen, liefert der Webserver sie nicht als
// XML aus, in dem ein Skript laufen koennte.
const IDSCONNECT_OWN_FILE  = '/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.[0-9]+\.[0-9]+-[0-9a-f]{8}\.dat(\.tmp|\.claimed-[0-9a-f]{8})?$/D';

// Legt .htaccess und index.html an bzw. prueft sie; false, wenn der Ordner
// nicht geschuetzt werden konnte
function idsconnect_protect($dir)
{
  $htaccess = $dir . '/.htaccess';
  $current = @file_get_contents($htaccess);
  if ($current === false || strpos($current, 'Require all denied') === false
      || strpos($current, 'Deny from all') === false)
  {
    $content = "<IfModule mod_authz_core.c>\nRequire all denied\n</IfModule>\n"
             . "<IfModule !mod_authz_core.c>\nDeny from all\n</IfModule>\n";
    if (@file_put_contents($htaccess, $content) === false)
      return false;
  }
  if (!@is_file($dir . '/index.html') && @file_put_contents($dir . '/index.html', '') === false)
    return false;
  return true;
}

// Ablageordner, siehe oben. Leer, wenn kein geschuetzter Ordner verfuegbar ist.
function idsconnect_dir()
{
  static $dir = null;
  if ($dir !== null)
    return $dir;

  $env = getenv('IDSCONNECT_DIR');
  if (is_string($env) && $env !== '')
    $candidates = [rtrim($env, '/' . chr(92))];
  else
    $candidates = [dirname(__DIR__) . '/idsconnect-data', __DIR__ . '/idsconnect'];

  foreach ($candidates as $candidate)
  {
    if (!@is_dir($candidate) && !@mkdir($candidate, 0700, true))
      continue;
    if (idsconnect_protect($candidate))
      return $dir = $candidate;
  }
  return $dir = '';
}

function idsconnect_max_total()
{
  $env = getenv('IDSCONNECT_MAX_TOTAL');
  if (is_string($env) && ctype_digit($env))
    return (int)$env;
  return IDSCONNECT_MAX_TOTAL;
}

// Auslieferung gespeicherter Inhalte: Der Inhalt stammt von einem nicht
// authentifizierten Absender. Ohne diese Header liefe ein als XHTML getarntes
// Skript beim Aufruf im Browser im Origin dieses Servers (Stored XSS).
function idsconnect_safe_headers()
{
  header('X-Content-Type-Options: nosniff');
  header("Content-Security-Policy: sandbox; default-src 'none'");
  header('Cache-Control: no-store');
}

// Die sid stammt aus TIDSConnect.GetUuid und ist immer eine UUID ohne
// geschweifte Klammern. Frueher wurde sie ungeprueft an den Dateipfad
// gehaengt - damit liessen sich ueber "../" beliebige Dateien lesen und
// ueberschreiben. Der Modifikator D: Ohne ihn liesse $ einen abschliessenden
// Zeilenumbruch zu - die Datei mit Umbruch im Namen wuerde weder gezaehlt
// noch ausgeliefert noch aufgeraeumt.
function idsconnect_sid()
{
  if (!isset($_REQUEST['sid']))
    return null;

  $sid = $_REQUEST['sid'];
  if (!is_string($sid))
    return null;
  if (!preg_match('/^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$/D', $sid))
    return null;

  return strtolower($sid);
}

// Eigene Dateien der Ablage (Name => Pfad). Das Verzeichnis wird gelesen und
// gefiltert statt per glob(): Zeichen wie [ ] im Ablagepfad waeren sonst ein
// Muster, und Abruf, Aufraeumen und Quote faenden nichts.
function idsconnect_files()
{
  $dir = idsconnect_dir();
  $result = [];
  foreach (@scandir($dir) ?: [] as $name)
  {
    if (preg_match(IDSCONNECT_OWN_FILE, $name))
      $result[$name] = $dir . '/' . $name;
  }
  return $result;
}

// Abgelaufene Ablagen entfernen, damit keine Warenkoerbe unbegrenzt liegen bleiben
function idsconnect_cleanup()
{
  $limit = time() - IDSCONNECT_TTL;
  foreach (idsconnect_files() as $file)
  {
    $mtime = @filemtime($file);
    if ($mtime !== false && $mtime < $limit)
      @unlink($file);
  }
}

// Belegter Platz aller Rueckgaben; jede Datei zaehlt mindestens
// IDSCONNECT_MIN_FILE, sonst liessen sich unbegrenzt leere Dateien ablegen
function idsconnect_used()
{
  $sum = 0;
  foreach (idsconnect_files() as $file)
  {
    $size = @filesize($file);
    $sum += max($size === false ? 0 : $size, IDSCONNECT_MIN_FILE);
  }
  return $sum;
}

// Fertig geschriebene Rueckgaben einer sid, aelteste zuerst. Der Dateiname
// beginnt nach der sid mit einem Zeitstempel fester Breite, deshalb ergibt
// die Sortierung nach Namen die Eingangsreihenfolge.
function idsconnect_queue($sid)
{
  $files = [];
  foreach (idsconnect_files() as $name => $file)
  {
    if (strpos($name, $sid . '.') === 0 && substr($name, -4) === '.dat')
      $files[$name] = $file;
  }
  ksort($files, SORT_STRING);
  return array_values($files);
}

$sid = idsconnect_sid();
if ($sid === null)
{
  http_response_code(400);
  exit;
}

if (idsconnect_dir() === '')
{
  // Kein geschuetzter Ablageordner - lieber nichts annehmen
  http_response_code(500);
  exit;
}

idsconnect_cleanup();

// Nur POST legt ab. Frueher genuegte wegen $_REQUEST ein GET-Link mit
// ?warenkorb=..., um Inhalte unterzuschieben.
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['warenkorb']))
{
  $warenkorb = $_POST['warenkorb'];
  if (!is_string($warenkorb) || strlen($warenkorb) > IDSCONNECT_MAX_SIZE)
  {
    http_response_code(413);
    exit;
  }

  $dir = idsconnect_dir();

  // Pruefen und Schreiben unter einer Sperre: sonst saehen zwei parallele
  // Uploads denselben belegten Platz und ueberschritten die Quote gemeinsam
  $lock = @fopen($dir . '/.lock', 'c');
  if ($lock === false || !flock($lock, LOCK_EX))
  {
    http_response_code(500);
    exit;
  }

  // Gesamtgroesse begrenzen: sonst liesse sich die Platte mit beliebig vielen
  // 4-MB-Ablagen fuellen (abgelaufene sind oben schon entfernt)
  if (idsconnect_used() + max(strlen($warenkorb), IDSCONNECT_MIN_FILE) > idsconnect_max_total())
  {
    flock($lock, LOCK_UN);
    http_response_code(507);
    exit;
  }

  // Erst unter einem Namen schreiben, den der Abruf nicht sieht, dann
  // umbenennen: rename ist atomar, ein paralleler Abruf findet also nie eine
  // halb geschriebene Datei.
  $name = $dir . '/' . $sid . '.' . sprintf('%017.6f', microtime(true))
        . '-' . bin2hex(random_bytes(4)) . '.dat';
  $tmp = $name . '.tmp';
  $ok = @file_put_contents($tmp, $warenkorb) !== false;
  if ($ok)
  {
    @chmod($tmp, 0600);
    $ok = @rename($tmp, $name);
  }
  if (!$ok)
    @unlink($tmp);
  flock($lock, LOCK_UN);
  fclose($lock);
  if (!$ok)
  {
    http_response_code(500);
    exit;
  }

  header('Content-Type: text/html; charset=utf-8');
  header('X-Content-Type-Options: nosniff');
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
    idsconnect_safe_headers();
    // Eindeutige Kennung der Uebertragung: Daran erkennt der Client eine
    // wiederholt ausgelieferte Rueckgabe, ohne zwei inhaltsgleiche, aber
    // eigenstaendige Uebertragungen zu verwechseln
    header('X-IDSConnect-Id: ' . basename($file, '.dat'));
    echo $data;
    exit;
  }

  // Noch nichts eingetroffen - fuer den Client der Normalfall waehrend des Wartens
  http_response_code(404);
}
?>
