[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=5V8N3XFTU495G)

# IDSConnect-for-Delphi

Umsetzung der IDS-Connect-Schnittstelle für Delphi. Unterstützt werden die
Schnittstellenversionen **2.5** und **2.5.1**.

Weitere Informationen unter https://www.itek.de/beratung/ids-connect

## Unterstützte Aktionen

| Aktion | Code | Methode |
|--------|------|---------|
| Warenkorb senden | WKS | `TIDSConnect.IDSConnectWKS` |
| Warenkorb empfangen | WKE | `TIDSConnect.IDSConnectWKE` |
| Artikeldeeplink | ADL | `TIDSConnect.IDSConnectADT` |
| Artikelsuche | AS | `TIDSConnect.IDSConnectAS` |

## Version 2.5 oder 2.5.1

Die erzeugte Schnittstellenversion steuert `WarenkorbInfo.Version`. Voreingestellt
ist `idsConnectVersion_2_5_1`; für die alte Fassung genügt

```pascal
lWarenkorb.WarenkorbInfo.Version := idsConnectVersion_2_5;
```

Beim Einlesen werden beide Fassungen erkannt, ebenso ältere Antworten mit
Version 1.3, 2.0 und 2.3.

### Was 2.5.1 gegenüber 2.5 ändert

* `InquiryNo`, `OfferNo`, `PartNo` und `OrderConfNo` in den Kopfdaten entfallen
  und werden durch beliebig viele `Referenz`-Einträge ersetzt
  (`OrderInfo.Referenzen`, je mit Belegnummer, Belegdatum und Belegart).
* Belegarten: `220` Bestellung, `231` Bestätigung (Auftrag), `310` Angebot,
  `315` Vertrag.
* Positionen kennen zusätzlich `SumMaterialSurcharges` (Summe der
  Rohstoffzuschläge), `DiscountableAmount` (skontofähiger Betrag) und eigene
  `Referenz`-Einträge mit Belegposition.
* Adressen: `Name4` entfällt, `Street` wird zu `Street1` bis `Street3`, die
  Postleitzahl ist auf 9 Stellen begrenzt.
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

## Rücksprungadresse (Hook-URL)

Die Rück-Kommunikation läuft über eine eigene, per HTTPS erreichbare Adresse:

```pascal
TIDSConnect.IDSCONNECT_HOOKURL := 'https://<eigener-server>/idsconnect.php';
```

Ein passendes Server-Skript liegt als [idsconnect.php](idsconnect.php) bei. Über
diese Adresse laufen Warenkorb-, Preis- und Kundendaten — sie gehört auf einen
Server, den man selbst kontrolliert.

Nach dem Absenden zeigt die Unit einen Warte-Dialog und fragt die Hook-URL im
Abstand von zwei Sekunden ab, bis die Rückübertragung eintrifft, der Anwender
abbricht oder das Zeitlimit abläuft:

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

## Fehlerbehandlung

Parser- und Netzwerkfehler werden über einen optionalen Callback gemeldet:

```pascal
TIDSConnect.IDSCONNECT_ONERROR :=
  procedure (const _Message : String; _E : Exception)
  begin
    //protokollieren oder anzeigen
  end;
```

Für Testumgebungen mit selbstsignierten Zertifikaten lässt sich die
Zertifikatsprüfung gezielt abschalten — im Normalbetrieb bleibt sie aktiv:

```pascal
TIDSConnect.IDSCONNECT_ALLOW_INVALID_CERT := True;
```

## Beispielprojekt

Das Projekt unter [Samples](Samples/) erwartet neben der Projektdatei eine
`configuration.ini`:

```ini
[Settings]
HookUrl=https://<eigener-server>/idsconnect.php

[Name Lieferant]
Username=...
Password=...
Customernumber=...
IDSConnectUrl=https://...
```

Die Datei enthält Zugangsdaten und ist deshalb von der Versionsverwaltung
ausgenommen.

# Lieferanten mit IDS-Connect-Unterstützung

| Lieferant | ja | geplant | nein | Version |
|----------|----------|----------|----------|----------
| Pfeiffer & May | x | - | - | 2.5 |

| GC-Gruppe | x | - | - |
| Pietsch | x | - | - |
| Pürsch | - | - | x |
| Sanitär-Heinze | x | - | - |
| ZVSHK | x | - | - |

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
