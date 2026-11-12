[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=5V8N3XFTU495G)

# IDSConnect-for-Delphi

Umsetzung der IDS-Connect-Schnittstelle für Delphi. Unterstützt werden die
Schnittstellenversionen **2.5** und **2.5.1**.

Weitere Informationen unter https://www.itek.de/beratung/ids-connect

## Einbinden

XML wird mit [LandrixXML for Pascal](https://github.com/landrix/LandrixXML-for-Pascal)
gelesen (MIT-Lizenz, ohne weitere Abhängigkeiten); MSXML wird nicht mehr
benötigt. Die Bibliothek ist als Git-Submodul unter `Lib/LandrixXML`
eingebunden und auf ein Release festgelegt (derzeit `v0.3.0`):

```
git clone --recurse-submodules https://github.com/LandrixSoftware/IDSConnect-for-Delphi.git
# oder in einem bestehenden Klon:
git submodule update --init
```

In eigenen Projekten zusätzlich zum Repo-Ordner `Lib\LandrixXML\source` in den
Suchpfad aufnehmen. Ein neueres Release wird so übernommen:

```
cd Lib/LandrixXML
git fetch --tags
git checkout v<neue Version>
cd ../..
git add Lib/LandrixXML
```

## Unterstützte Aktionen

| Aktion | Code | Methode |
|--------|------|---------|
| Warenkorb senden | WKS | `TIDSConnect.IDSConnectWKS` |
| Warenkorb empfangen | WKE | `TIDSConnect.IDSConnectWKE` |
| Artikeldeeplink | ADL | `TIDSConnect.IDSConnectADT` |
| Artikelsuche | AS | `TIDSConnect.IDSConnectAS` |
| Logininformationen | LI | `TIDSConnect.IDSConnectLI` |
| Schnittstellenversion | SV | `TIDSConnect.IDSConnectSV` |

`LI` und `SV` laufen als direkter POST ohne Browser und ohne Hook-URL:

```pascal
//Welche Anmeldedaten braucht der Shop?
var lLogin : TIDSConnect_LoginInfo;
if TIDSConnect.IDSConnectLI(URL,lLogin) then
  if lLogin.PasswordRequired then ...

//Welche Version sprechen wir?
case TIDSConnect.IDSConnectSVBestVersion(URL) of
  idsConnectVersion_2_5_1 : lWarenkorb.WarenkorbInfo.Version := idsConnectVersion_2_5_1;
  idsConnectVersion_2_5   : lWarenkorb.WarenkorbInfo.Version := idsConnectVersion_2_5;
end;
```

Antwortet der Shop nicht, liefert `IDSConnectLI` `False` und lässt alle drei
Angaben auf „erforderlich"; `IDSConnectSVBestVersion` liefert dann
`idsConnectVersion_Unkown` – ebenso, wenn der Shop nur Versionen vor 2.5
nennt, denn nur 2.5 und 2.5.1 kann die Unit senden. Wer die Liste ohnehin
mit `IDSConnectSV` abgefragt hat, wertet sie mit
`TIDSConnect.BestSupportedVersion(Liste)` aus, ohne zweite Abfrage.

## Version 2.5 oder 2.5.1

Die erzeugte Schnittstellenversion steuert `WarenkorbInfo.Version`. Voreingestellt
ist `idsConnectVersion_2_5_1`; für die alte Fassung genügt

```pascal
lWarenkorb.WarenkorbInfo.Version := idsConnectVersion_2_5;
```

Beim Einlesen werden beide Fassungen erkannt, ebenso ältere Antworten mit
Version 1.3, 2.0 und 2.3.

Gesendet wird immer als 2.5 oder 2.5.1 (`TIDSConnectHelper.SendVersion`):
Ein Warenkorb mit unbekannter Version geht als 2.5.1 hinaus, einer mit 1.3,
2.0 oder 2.3 – etwa ein empfangener Warenkorb eines älteren Shops – als 2.5,
der nächstliegenden Struktur. Die Umstellung wird über `IDSCONNECT_ONERROR`
gemeldet. Versionsangabe im XML, Schema und Struktur sowie das `version`-Feld
des WKS-Formulars stimmen dabei immer überein.

### Was 2.5.1 gegenüber 2.5 ändert

* `InquiryNo`, `OfferNo`, `PartNo` und `OrderConfNo` in den Kopfdaten entfallen
  und werden durch beliebig viele `Referenz`-Einträge ersetzt
  (`OrderInfo.Referenzen`, je mit Belegnummer, Belegdatum und Belegart).
  Sind die alten Felder bei 2.5.1 gefüllt, werden sie nicht gesendet und über
  `IDSCONNECT_ONERROR` gemeldet. Eine automatische Umsetzung in Referenzen
  gibt es bewusst nicht: Eine Referenz verlangt ein Belegdatum, das die alten
  Felder nicht haben. Wer bisher ohne gesetzte Version gearbeitet hat (früher
  war 2.5 voreingestellt), trägt die Bestellnummer jetzt so ein:

```pascal
with lWarenkorb.Order.OrderInfo.Referenzen.AddItem do
begin
  ReferenzNumber := 'B-4711';
  ReferenzDate := Bestelldatum;
  ReferenzType := idsConnectRefType_220;   //Bestellung
end;
```

* Belegarten: `220` Bestellung, `231` Bestätigung (Auftrag), `310` Angebot,
  `315` Vertrag.
* Positionen kennen zusätzlich `SumMaterialSurcharges` (Summe der
  Rohstoffzuschläge), `DiscountableAmount` (skontofähiger Betrag) und eigene
  `Referenz`-Einträge mit Belegposition.
* Adressen: `Name4` entfällt (bei 2.5.1 gemeldet, nicht gesendet), `Street`
  wird zu `Street1` bis `Street3`, die Postleitzahl ist auf 9 Stellen begrenzt.
* Der Lieferort kann Geokoordinaten tragen (`GeoLat`, `GeoLang`).
* Rohstoff-Codeliste um `MS` (Messing) und `MK` (MK Kupfer) erweitert.
* Für die Artikelsuche gibt es die Parameter `multipleResult` und
  `hookURLTimeout`:

```pascal
TIDSConnect.IDSConnectAS(URL,Kundennr,Benutzer,Passwort,TempDatei,Suchbegriff,
                         lWarenkorb,
                         True,   //Mehrfachrückgabe an die HookUrl unterstützt
                         300);   //HookUrl bleibt 300 Sekunden aktiv
```

### Mehrfachrückgabe

Mit `multipleResult = True` darf der Shop mehrfach an die Hook-URL senden. Der
Warte-Dialog bleibt dann offen und übernimmt jede eintreffende Rückgabe: deren
Positionen werden an `lWarenkorb` **angehängt**, die Kopfdaten (Währung,
Kommission, Referenzen, Lieferanten-, Kunden- und Lieferortdaten) stammen aus
der ersten Rückgabe. Der Dialog zeigt laufend die Anzahl der übernommenen
Rückgaben; beendet wird der Vorgang über „Fertig" oder durch Ablauf der Frist.
Was bis zum Schließen noch eingetroffen ist, wird danach ein letztes Mal
abgeholt.

Im integrierten Browser schließt sich das Fenster bei Mehrfachrückgabe nicht
nach der ersten Übertragung: Es kehrt in den Shop zurück, die Titelzeile zählt
die übernommenen Rückgaben mit, und der Anwender schließt das Fenster, wenn er
fertig ist. Abgeholt wird schon während der Sitzung — nach jeder Übertragung
und zusätzlich jede Minute —, damit bei langen Sitzungen nichts auf dem Server
verfällt.

Der Hook-Server muss jede Rückgabe **beim Abruf verbrauchen** und mehrere
Rückgaben derselben Sitzung in einer Warteschlange halten — so arbeitet das
beiliegende [idsconnect.php](idsconnect.php). Es schickt außerdem je Rückgabe
eine eindeutige Kennung im Header `X-IDSConnect-Id`. Liefert ein Server
dieselbe Rückgabe erneut (gleiche Kennung), wird sie verworfen und einmalig
über `IDSCONNECT_ONERROR` gemeldet. Inhaltsgleiche, aber eigenständige
Übertragungen bleiben erhalten. Ein Server ohne diese Kennung wird über
gleiche Rohdaten erkannt — dort fällt eine unmittelbar wiederholte,
bytegleiche Übertragung weg.

`hookURLTimeout` bemisst sich dabei — wie in der Spezifikation vorgesehen — ab
der **letzten** Übertragung.

**Ob ein Shop die Mehrfachrückgabe beherrscht, lässt sich nicht abfragen.** Der
Parameter ist eine Zusage der Handwerkssoftware an den Shop („ich kann mehrere
Rückgaben verarbeiten"), keine Anfrage; die Spezifikation kennt dafür weder in
`SV` noch in `LI` ein Merkmal. Praktisch bleibt nur, es je Großhändler einmal
auszuprobieren und zu hinterlegen — im Beispielprojekt über den Schlüssel
`MultipleResult` in der `config.ini`.

Standardmäßig wartet der Dialog nach jeder Rückgabe die volle zugesagte Frist
auf weitere. Sendet ein Shop nur einmal, beendet der Anwender den Vorgang mit
„Fertig". Wer den Dialog früher schließen will, kann eine kürzere Nachlauffrist
setzen — Rückgaben, die der Shop danach noch innerhalb von `hookURLTimeout`
sendet, gehen dann allerdings verloren:

```pascal
//Sekunden; 0 (Voreinstellung) = die volle Frist abwarten
TIDSConnect.IDSCONNECT_MULTIPLERESULT_FOLLOWUP := 0;
```

Wer den Ablauf selbst steuern will, holt die aufgelaufenen Rückgaben mit
`TIDSConnect.CollectResults` ab oder führt sie mit
`TIDSConnect.MergeOrderItems(_Quelle,_Ziel,_MitKopfdaten)` zusammen — nötig,
weil `LoadFromStream` den Zielwarenkorb ersetzt.

## Rücksprungadresse (Hook-URL)

Die Rück-Kommunikation läuft über eine eigene, per HTTPS erreichbare Adresse:

```pascal
TIDSConnect.IDSCONNECT_HOOKURL := 'https://<eigener-server>/idsconnect.php';
```

Ein passendes Server-Skript liegt als [idsconnect.php](idsconnect.php) bei. Über
diese Adresse laufen Warenkorb-, Preis- und Kundendaten — sie gehört auf einen
Server, den man selbst kontrolliert. Das Skript legt jede Übertragung als eigene
Datei in eine Warteschlange je Sitzung; jeder Abruf liefert die älteste und
löscht sie. Ein eigener Hook-Server muss sich genauso verhalten.

Nach dem Absenden zeigt die Unit einen Warte-Dialog und fragt die Hook-URL im
Abstand von zwei Sekunden ab, bis die Rückübertragung eintrifft, der Anwender
abbricht oder das Zeitlimit abläuft. Der Abruf läuft im Hintergrund, der
Dialog bleibt auch bei einem nicht erreichbaren Server bedienbar;
`IDSCONNECT_ONERROR` und `IDSCONNECT_ONRESPONSE` werden trotzdem im
Hauptthread aufgerufen:

```pascal
//Sekunden; 0 = ohne Zeitbegrenzung warten, bis der Anwender abbricht
TIDSConnect.IDSCONNECT_HOOKURL_TIMEOUT := 300;
```

Für die Artikelsuche gilt stattdessen der an `IDSConnectAS` übergebene
`hookURLTimeout`.

## Was serialisiert wird

`SaveToString` gibt jeden Block aus, sobald er gefüllt ist — eine reine Anfrage
ohne Preise erzeugt also dieselben Elemente wie bisher:

* `SupplierInfo`, `CustomerInfo` und `DeliveryPlaceInfo`, sobald `IDNo` oder ein
  Adressfeld gesetzt ist (beim Lieferort ab 2.5.1 auch bei gesetzten Geodaten)
* je Position `Kurztext`, `Langtext`, `OfferPrice`, `NetPrice`, `PriceBasis`,
  `VAT`, `TechnClarification`, `Hinweis`, `Fehlercode`, `Fehlertext`,
  `Zuschlag`, `Rohstoffanteil` und `Divers`, sofern belegt

Alle Textinhalte werden XML-maskiert; beim Einbetten in das HTML-Formular kommt
die HTML-Maskierung hinzu.
Zeichen, die XML 1.0 verbietet (Steuerzeichen außer Tab, LF und CR, z. B. ein
vertikaler Tab aus Word-Texten, sowie `U+FFFE`, `U+FFFF` und einzelne
Surrogate), werden entfernt; beim Kürzen auf die Feldlänge wird kein
Surrogatpaar getrennt.

## Fehlerbehandlung

Parser- und Netzwerkfehler werden über einen optionalen Callback gemeldet:

```pascal
TIDSConnect.IDSCONNECT_ONERROR :=
  procedure (const _Message : String; _E : Exception)
  begin
    //protokollieren oder anzeigen
  end;
```

Gemeldet werden außerdem:

* fehlende Angaben, bevor ein Aufruf abbricht (Shop-Adresse, Hook-URL,
  Suchbegriff, Artikelnummer, Warenkorb). Fehlende Anmeldedaten sind kein
  Abbruchgrund: Welche ein Shop braucht, liefert `IDSConnectLI`, und der Shop
  lehnt fehlende Daten selbst ab;
* unbekannte Mengeneinheiten und Rohstoffe in einer Rückgabe, mit dem
  Originalwert. Übernommen werden sie als `PCE` bzw. `CU` – wer den Fall
  fachlich behandeln will, wertet die Meldung aus;
* Referenzen ohne Belegdatum (Muss-Feld); sie werden nicht gesendet;
* eine Shop- oder Hook-Adresse mit `http://` statt `https://` (außer
  `localhost`). Mit `TIDSConnect.IDSCONNECT_REQUIRE_HTTPS_HOOK := True` bricht
  ein Aufruf mit unverschlüsselter Hook-URL zusätzlich ab;
* beim Senden als 2.5.1 Felder, die es dort nicht mehr gibt (siehe oben).

Scheitert das Einlesen einer Rückgabe, bleibt der übergebene Warenkorb
unverändert – bei WKS also der gesendete Warenkorb.

`IDSConnectWKS` sendet die Hook-URL immer mit, wie die Spezifikation es
verlangt; mit `_DontWait = True` wird nur nicht auf die Rückübertragung
gewartet.

Für Testumgebungen mit selbstsignierten Zertifikaten lässt sich die
Zertifikatsprüfung gezielt abschalten — im Normalbetrieb bleibt die Prüfung des
Betriebssystems aktiv:

```pascal
TIDSConnect.IDSCONNECT_ALLOW_INVALID_CERT := True;
```

## Integrierter Browser

Alle vier Aktionen laufen wahlweise im Standardbrowser oder im integrierten
Browser (`TEdgeBrowser`, benötigt die WebView2-Runtime). Gesteuert wird das über
den Parameter `_TmpFilename`:

* **gesetzt** — das Formular wird in diese Datei geschrieben und im
  Standardbrowser geöffnet
* **leer** — das Formular wird direkt im integrierten Browser angezeigt; es
  entsteht keine Datei mit Zugangsdaten auf der Platte. Ausnahme: Ein
  Formular über rund 1,5 MB (sehr großer WKS-Warenkorb) überschreitet die
  Grenze von `NavigateToString` und wird aus einer eindeutig benannten
  Temp-Datei geladen, die beim Schließen des Dialogs gelöscht wird

Im integrierten Browser erkennt der Dialog den Sprung auf die Hook-URL selbst
und schließt sich; der Warenkorb wird danach abgeholt. Beim Standardbrowser
übernimmt das der Warte-Dialog mit Polling.

### Profil- und Cache-Ordner

Wenn beim `ShowDialog` kein Pfad übergeben wird, verwendet `TEdgeBrowser`
für Profil, Cookies und Cache den Unterordner **WebView2 neben der EXE**:

```
<EXE-Verzeichnis>\WebView2
```

Der Ordner wird bei Bedarf angelegt und muss beschreibbar sein. Er ist dauerhaft und kein
Temp-Verzeichnis: WebView2 legt dort die Anmeldesitzung ab, sonst müsste sich
der Anwender bei jedem Aufruf neu am Shop anmelden. Ein eigener Pfad lässt sich
weiterhin übergeben.

## Beispielprojekt

Das Projekt unter [Samples](Samples/) liest eine `config.ini` neben der EXE
oder im Projektverzeichnis. Der bisherige Name `configuration.ini` wird
weiterhin unterstützt. Beispiel:

```ini
[Settings]
HookUrl=https://<eigener-server>/idsconnect.php

[Name Lieferant]
Username=...
Password=...
Customernumber=...
IDSConnectUrl=https://...
Version=2.5.1
; optional, füllt das Feld Artikelnummer
DemoArticle=...
; optional, Shop beherrscht die Mehrfachrückgabe
MultipleResult=1
```

Kommentare gehören auf eigene Zeilen: `TMemIniFile` liest einen Kommentar
hinter dem Wert mit, aus `MultipleResult=1 ;optional` würde so `false`.

Der Schalter „Shop-Infos (SV / LI)" fragt beim ausgewählten Anbieter die
unterstützten Schnittstellenversionen und die benötigten Anmeldedaten ab.
Die Abfrage ändert die konfigurierte Version nicht.

`Version` wird **je Anbieter** eingetragen: erlaubt sind `2.5` und `2.5.1`.
Ohne Schlüssel gilt weiterhin `2.5.1`; ein leerer oder ungültiger Wert wird
als Konfigurationsfehler angezeigt und verhindert den Aufruf. Die Einstellung
gilt für WKE, WKS, ADL, AS, SV und LI. Bei WKS stimmen Formularversion und
Warenkorb-XML überein. Bei AS werden die Parameter `multipleResult` und
`hookURLTimeout` nur für 2.5.1 übertragen; das lokale Zeitlimit bleibt aktiv.

In eigenen Anwendungen lässt sich die Version als letzter optionaler Parameter
an `IDSConnectWKE`, `IDSConnectADT`, `IDSConnectAS`, `IDSConnectSV`,
`IDSConnectLI` und `IDSConnectSVBestVersion` übergeben. Bestehende Aufrufe
verwenden weiterhin 2.5.1. Für WKS bestimmt `WarenkorbInfo.Version` sowohl
die XML- als auch die Formularversion.

Die Datei enthält Zugangsdaten und ist deshalb von der Versionsverwaltung
ausgenommen.

### Einen Shop mit „Warenkorb empfangen“ prüfen

Die Konfiguration direkt neben der EXE hat Vorrang vor dem Projektverzeichnis.
Je Verzeichnis wird zuerst `config.ini`, dann `configuration.ini` gesucht.
Anbieter auswählen und
„Warenkorb empfangen“ starten. Im geöffneten Shop den gewünschten Warenkorb
an die Handwerkssoftware zurückgeben.

Für diesen WKE-Aufruf zeigt das Beispiel drei Ansichten:

* **Aufruf / Protokoll:** vorbereitete POST-Parameter mit maskiertem Passwort,
  Hook-URL inklusive Sitzungskennung, HTTP-Status und Größe der Hook-Antworten,
  Fehler sowie Gesamtdauer einschließlich der Bedienung im Shop.
* **XML / Rückgabe:** XML wird für die Anzeige mit Zeilenumbrüchen und zwei
  Leerzeichen je Ebene eingerückt (Pretty Print). Lässt sich die Antwort
  nicht formatieren, bleibt der ursprüngliche Text sichtbar, auch bei
  ungültigem XML oder HTTP-Fehlern. „Rückgabe speichern“ speichert die
  ursprünglichen Bytes ohne Umkodierung. Leere Antworten und HTTP 404
  überschreiben die letzte angezeigte Nutzlast nicht.
* **Eingelesener Warenkorb:** Version, Kundennummer, Kommission und Positionen
  mit Artikelnummer, Texten, Menge, Einheit, Nettopreis, Preisbasis, MwSt.,
  Hinweisen und Fehlern des Shops.

### Einlesen der Rückgabe

* **Kodierung:** Maßgeblich ist ein BOM, sonst die Angabe `encoding` in der
  XML-Deklaration (ISO-8859-1/-15/-2, Windows-1250/1252 über feste
  Codepages, unabhängig von der Systemcodepage). Ohne Deklaration gilt
  UTF-8; ist der Inhalt kein gültiges UTF-8, wird Windows-1252 angenommen.
  Deklariert ein Shop eine Byte-Kodierung, sendet aber gültiges UTF-8 mit
  Umlauten, wird UTF-8 gelesen.
* **Namensräume:** Elemente werden über ihren lokalen Namen erkannt;
  `<ids:Warenkorb xmlns:ids="…">` wird wie `<Warenkorb>` gelesen.
* **Gemischter Inhalt:** Text und CDATA-Abschnitte eines Elements werden
  zusammengesetzt, Kommentare übersprungen.
* **Parser:** LandrixXML prüft streng auf Wohlgeformtheit, verarbeitet keine
  DTD und lädt nichts nach. Fehlermeldungen nennen Zeile und Spalte. Die
  Antworten auf LI und SV werden genauso dekodiert wie die Hook-Rückgabe.
* Scheitert das Einlesen trotzdem, ist die Rückgabe beim mitgelieferten
  PHP-Skript bereits verbraucht. Die rohen Bytes liefert
  `IDSCONNECT_ONRESPONSE` — wer sie dort sichert, verliert nichts.

Die Browserformulare (ADL, AS, WKE, WKS) senden wie von der Spezifikation
verlangt `multipart/form-data`, ebenso die direkten Abfragen LI und SV.

Die HTTP-Statuswerte stammen vom **Abruf der Hook-URL**. Der eigentliche
Shop-Aufruf läuft im Browser; dessen HTTP-Antworten werden hier nicht
mitgeschnitten. „Eingelesen“ bestätigt die Verarbeitung durch den Parser,
keine Schema-Konformität oder fachliche Vollständigkeit. Fehlende Zahlenfelder
können im Datenmodell als 0 erscheinen; zum Vergleich dient die rohe Rückgabe.

Für eigene Diagnoseoberflächen stehen optional `IDSCONNECT_ONREQUEST`
(vorbereiteter WKE-Aufruf) und `IDSCONNECT_ONRESPONSE` (HTTP-Status und rohe
Bytes jedes Hook-Abrufs) bereit. `TryFetchResult(URL,Warenkorb,Fehlertext)`
ermöglicht einen einzelnen Abruf ohne Browser oder Wartedialog. Dazu muss die
vollständige Hook-URL einschließlich `sid` übergeben werden. Der Abruf kann
die serverseitige Rückgabe verbrauchen; beim mitgelieferten PHP-Skript wird
sie anschließend gelöscht.

Lokale Regressionstests mit einem simulierten HTTP-Endpunkt lassen sich mit
`python Tests/run_diagnostics.py` starten (Python 3 und `dcc32` im PATH).
Sie prüfen Rückgaben, Fehlerfälle, unveränderte Bytes und die Passwortmaskierung
ohne einen echten Shop aufzurufen, dazu das Sammeln mehrerer Rückgaben samt
Kopfdaten und den Schutz vor doppelt gelieferten Rückgaben sowie die
Kodierungserkennung, Namensraum-Präfixe und gemischten Inhalt.
`python Tests/test_hook_php.py` (PHP im PATH) prüft die Warteschlange von
`idsconnect.php` auf dem eingebauten PHP-Server.

# Lieferanten mit IDS-Connect-Unterstützung

| Lieferant | ja | geplant | nein | Version |
|----------|----------|----------|----------|----------
| Pfeiffer & May | x | - | - | 2.5 |
| GC-Gruppe | x | - | - | |
| Pietsch | x | - | - | |
| Pürsch | - | - | x | |
| Sanitär-Heinze | x | - | - | |
| ZVSHK | x | - | - | |

# Lizenz / License IDSConnect-for-Delphi

Copyright (C) 2026 Landrix Software GmbH & Co. KG
Sven Harazim, info@landrix.de

Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
