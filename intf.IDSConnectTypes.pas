{* Licensed to the Apache Software Foundation (ASF) under one
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
 * under the License.}

unit intf.IDSConnectTypes;

interface

uses
  System.SysUtils,System.Classes,System.Contnrs,System.DateUtils
  ,System.StrUtils,System.Types,System.Generics.Collections
  ;

//Die Bezeichnungen der Klassen wurden an die XSD-Datei der Schnittstellenbeschreibung
//angelehnt, sind also eine Mischung aus Englisch und Deutsch
type
  TIDSConnect_Version = (idsConnectVersion_Unkown,
                         idsConnectVersion_1_3,
                         idsConnectVersion_2_0,
                         idsConnectVersion_2_3,
                         idsConnectVersion_2_5,
                         idsConnectVersion_2_5_1);

  //Rueckgabekennzeichen, pflicht bei Warenkorbempfang
  TIDSConnect_RueckgabeKZ = (idsConnectRKZ_None,
                             idsConnectRKZ_Warenkorbrueckgabe,              //value="Warenkorbrueckgabe"
                             idsConnectRKZ_WarenkorbrueckgabeMitBestellung);//value="Warenkorbrueckgabe mit Bestellung"

  //Informationen zum Warenkorb
  TIDSConnect_WarenkorbInfo = class(TObject)
  public
    Date        : TDate; //Muss tgDate Erstellungsdatum der Datenaustauschdatei
    Time        : TTime; //Muss tgTime Erstellungszeit der Datenaustauschdatei
    RueckgabeKZ : TIDSConnect_RueckgabeKZ;    //Muss bei Empfang
    Version     : TIDSConnect_Version;//Muss Angabe der Schnittstellenversion max 2.5
    constructor Create;
    procedure Clear;
    procedure Assign(_From : TIDSConnect_WarenkorbInfo);
  end;

  //Lieferung / Abholung
  TIDSConnect_ModeOfShipment = (idsConnectMos_Lieferung, //value="Lieferung"
                                idsConnectMos_Abholung); //value="Abholung"

  //Antwort auf die Aktion "LI" (Logininformationen): welche Anmeldedaten das
  //Shop-System benoetigt
  TIDSConnect_LoginInfo = record
    CustomerNoRequired : Boolean; //Kundennummer_erforderlich
    UsernameRequired : Boolean;   //Benutzername_erforderlich
    PasswordRequired : Boolean;   //Passwort_erforderlich
    procedure Clear;
  end;

  //Belegart, ab IDS 2.5.1 - Codeliste tgCodelisteReferenzType
  TIDSConnect_ReferenzType = (idsConnectRefType_None,
                              idsConnectRefType_220,  //Bestellung
                              idsConnectRefType_231,  //Bestaetigung (Auftrag)
                              idsConnectRefType_310,  //Angebot
                              idsConnectRefType_315); //Vertrag

  //Referenz auf einen Beleg in den Kopfdaten, ab IDS 2.5.1
  TIDSConnect_Referenz = class(TObject)
  public
    ReferenzNumber : String;                  //Muss String 15 Belegnummer
    ReferenzDate : TDate;                     //Muss Belegdatum
    ReferenzType : TIDSConnect_ReferenzType;  //Muss Belegart
    constructor Create;
    procedure Clear; virtual;
    procedure Assign(_From : TIDSConnect_Referenz); virtual;
  end;

  TIDSConnect_ReferenzList = class(TObjectList<TIDSConnect_Referenz>)
  public
    function AddItem : TIDSConnect_Referenz;
  end;

  //Referenz auf einen Beleg in den Positionsdaten, ab IDS 2.5.1
  TIDSConnect_ReferenzPos = class(TIDSConnect_Referenz)
  public
    ReferenzLine : String; //Muss String 10 Belegposition
    procedure Clear; override;
    procedure Assign(_From : TIDSConnect_Referenz); override;
  end;

  TIDSConnect_ReferenzPosList = class(TObjectList<TIDSConnect_ReferenzPos>)
  public
    function AddItem : TIDSConnect_ReferenzPos;
  end;

  TIDSConnect_OrderInfo = class(TObject)
  public
    //Die folgenden vier Felder entfallen ab IDS 2.5.1 und werden dort durch
    //Referenzen ersetzt. Sie werden nur noch fuer Version <= 2.5 serialisiert.
    InquiryNo : String; //Kann String 15 Anfragenummer aus der Handwerkssoftware
    OfferNo : String;  //Kann String 15 Angebotsnummer aus dem Grosshandels-System
    PartNo : String; //Kann String 15 Bestellnummer aus der Handwerkssoftware
    OrderConfNo : String; //Kann String 15 Auftragsbestaetigungsnummer Bestellnummer aus dem Grosshandels-System
    Referenzen : TIDSConnect_ReferenzList; //Kann 0..n, ab IDS 2.5.1
    //Entweder
    DeliveryWeek : Integer; //Kann Lieferwoche Maximaler Wert: 53
    DeliveryYear : Integer; //Kann Angabe des Lieferjahres zur Lieferwoche. Maximal vier Ziffern zwischen 2000 und 2100
    //Oder
    DeliveryDate : TDate; //Kann Lieferdatum
    //End
    ModeOfShipment : TIDSConnect_ModeOfShipment; //Muss Versandart
    ZusatzText : String; //Kann String 100 Reiner Hinweistext z.B. fuer den Fahrer
    Kommission : String; //Kann String 80
    Cur : String; //Muss String 3 Verwendet werden die Waehrungen entsprechend der Codeliste der ISO 4217
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Assign(_From : TIDSConnect_OrderInfo);
  end;

  TIDSConnect_Address = class(TObject)
  public
    Name1 : String;   //String 40
    Name2 : String;   //String 40
    Name3 : String;   //String 40
    Name4 : String;   //String 40 - entfaellt ab IDS 2.5.1
    Street : String;  //String 40 - ab IDS 2.5.1 durch Street1 ersetzt
    Street1 : String; //String 40 - ab IDS 2.5.1
    Street2 : String; //String 40 - ab IDS 2.5.1
    Street3 : String; //String 40 - ab IDS 2.5.1
    PCode : String;   //String 20, ab IDS 2.5.1 nur noch String 9
    City : String;    //String 40
    Country : String; //String 40
    ILN : String;     //String 20
    Contact : String; //String 40
    Phone : String;   //String 20
    Fax : String;     //String 20
    Email : String;   //String 256
    constructor Create;
    procedure Clear;
    procedure Assign(_From : TIDSConnect_Address);
  end;

  //Informationen zum Lieferanten
  TIDSConnect_SupplierInfo = class(TObject)
  public
    IDNo : String; //Kann String 40 Lieferantennummer beim Handwerker
    Address : TIDSConnect_Address; //Informationen zur Adresse des Lieferanten
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Assign(_From : TIDSConnect_SupplierInfo);
  end;

  //Informationen zum Besteller (Kunden)
  TIDSConnect_CustomerInfo = class(TObject)
  public
    IDNo : String; //Kann String 40 Kundennummer beim Lieferanten
    Address : TIDSConnect_Address; //Informationen zur Adresse des Kunden
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Assign(_From : TIDSConnect_CustomerInfo);
  end;

  //Struktur zur Abbildung der Lieferadresse bzw.Abholadresse abh�ngig von der Versandart
  TIDSConnect_DeliveryPlaceInfo = class(TObject)
  public
    IDNo : String; //Kann String 40 ID-Nummer fuer Lieferort
    Address : TIDSConnect_Address; //Kann
    //Geo-Daten ab IDS 2.5.1; nur wenn HasGeoLocation gesetzt ist werden sie ausgegeben
    HasGeoLocation : Boolean;
    GeoLat : double;  //Kann Breitengrad -90.0 bis 90.0 Grad
    GeoLang : double; //Kann Laengengrad -180.0 bis 180.0 Grad (Elementname laut XSD "GeoLang")
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Assign(_From : TIDSConnect_DeliveryPlaceInfo);
  end;

  TIDSConnect_ItemChara = (idsConnectIc_normal,   //String value="normal"
                           idsConnectIc_alternate,//String value="alternate"
                           idsConnectIc_provis);  //String value="provis"

  TIDSConnect_QU = (idsConnectQu_CMQ,// Kubik-Zentimeter
                 idsConnectQu_CMK,// Quadrat-Zentimeter
                 idsConnectQu_CMT,// Zentimeter
                 idsConnectQu_DZN,// Dutzend
                 idsConnectQu_GRM,// Gramm
                 idsConnectQu_HLT,// Hekto-Liter
                 idsConnectQu_KGM,// Kilogramm
                 idsConnectQu_KTM,// Kilometer
                 idsConnectQu_LTR,// Liter
                 idsConnectQu_MMT,// Millimeter
                 idsConnectQu_MTK,// Quadrat-Meter
                 idsConnectQu_MTQ,// Kubik-Meter
                 idsConnectQu_MTR,// Meter
                 idsConnectQu_PR, // Paar
                 idsConnectQu_PCE,// Stueck
                 idsConnectQu_SET,// Satz
                 idsConnectQu_TNE // Tonne
                 );

  TIDSConnect_Fehlercode = (idsConnectFc_None,
                            idsConnectFc_1); //1 Allgemeiner Fehler

  TIDSConnect_Rohstoff = (idsConnectR_AL,// Aluminium
                   idsConnectR_PB,// Blei
                   idsConnectR_CR,// Chrom
                   idsConnectR_AU,// Gold
                   idsConnectR_CD,// Kadmium
                   idsConnectR_CU,// Kupfer
                   idsConnectR_MG,// Magnesium
                   idsConnectR_NI,// Nickel
                   idsConnectR_PL,// Platin
                   idsConnectR_AG,// Silber
                   idsConnectR_W, // Wolfram
                   idsConnectR_ZN,// Zink
                   idsConnectR_SN,// Zinn
                   idsConnectR_MS,// Messing   - ab IDS 2.5.1
                   idsConnectR_MK // MK Kupfer - ab IDS 2.5.1
                   );

  //Struktur zur Abbildung der Rohstoffanteile f�r NE-Metalle
  TIDSConnect_Rohstoffanteil = class(TObject)
  public
    Rohstoff : TIDSConnect_Rohstoff;//Kann Angabe des Rohstoffs zu dem Daten uebertragen werden sollen (siehe Anhang).Erlaubt sind die Werte der Codeliste Rohstoffe (siehe Anhang) K Einfach STRING 3 Order/OrderItem/Rohstoffanteil/Rohstoff
    Gewichtsanteilswert : double;//Kann Angabe des Gewichtsanteils (siehe Anhang) K Einfach DEZIMAL10,4 Order/OrderItem/Rohstoffanteil/
    Gewichtsanteilseinheit : TIDSConnect_QU;//Kann Angabe der Gewichtsanteilseinheit (siehe Anhang). Erlaubt sind die Werte der Codeliste Mengeneinheiten (siehe Anhang) K Einfach STRING 3 Order/OrderItem/Rohstoffanteil/
    Basiswert : double; //Kann Angabe des Basiswerts auf den sich der Gewichtsanteil bezieht (siehe Anhang)K Einfach DEZIMAL10,4Order/OrderItem/Rohstoffanteil/Basiswert
    Basiseinheit  : TIDSConnect_QU;//Kann Angabe der Basiseinheit auf die sich der Gewichtsanteil bezieht (siehe Anhang).Erlaubt sind die Werte der Codeliste Mengeneinheiten(siehe Anhang) K Einfach STRING 3 Order/OrderItem/Rohstoffanteil/Basiseinheit
    Basisnotierung : double;//Kann Basis DEL-Notierung K Einfach DEZIMAL10,4Order/OrderItem/Rohstoffanteil/
    NotierungAktuell : double;//Kann Aktuelle DEL-Notierung Beinhaltet die DEL-Notierung, mit der der Nettopreisberechnet wurde; muss nicht der aktuellen DEL-Notierungentsprechen, da ggf. f�r Kontingente fixiert.K Einfach DEZIMAL10,4Order/OrderItem/Rohstoffanteil/
    constructor Create;
    procedure Clear;
    procedure Assign(_From : TIDSConnect_Rohstoffanteil);
  end;

  TIDSConnect_RohstoffanteilList = class(TObjectList<TIDSConnect_Rohstoffanteil>)
  public
    function AddItem : TIDSConnect_Rohstoffanteil;
  end;

  TIDSConnect_TechnClarification = (idsConnectTc_None,
                        idsConnectTc_Yes, //value="Yes"
                        idsConnectTc_No); //value="No"


  //Warenkorbposition
  TIDSConnect_OrderItem = class(TObject)
  public
    ItemChara : TIDSConnect_ItemChara; //Kann Positionskennzeichen
    RefItems_Customer : String;        //Kann String 35 Positionsnummer des Handwerkers
    RefItems_CustomerSubNo : String;   //Kann String 35 Unterpositionsnummer des Handwerkers
    RefItems_Supplier : String;        //Kann String 35 Positionsnummer des Grosshaendlers
    RefItems_SupplierSubNo : String;   //Kann String 35 Unterpositionsnummer des Grosshaendlers
    EAN : String; //Kann Decimal 13,0 EAN-Nummer der Position
    ManufacturerID : String; //Kann String 40 Identifikation des Herstellers
    ManufacturerIDType : String; //Kann String 40 Typ der Identifikation des Herstellers (z. B. DUNS, GLN, ...)
    ArtNo : String; //Kann String 15 Artikelnummer des Lieferanten oder Herstellers
    Qty : double; //Decimal 13,2ArtMenge, Anfrage-, Angebots- oder Bestellmenge (je nach Datenaustauschphase)
    QU : TIDSConnect_QU; //String 4 Anfrage- / Angebots-Mengeneinheit
    //Mengeneinheit, wie der Shop sie geliefert hat (z. B. "PK" oder "Stk.").
    //QU ist daraus abgeleitet; Einheiten ausserhalb der IDS-Codeliste werden
    //dort zu PCE. Nur beim Einlesen gesetzt, beim Senden zaehlt QU.
    QUOriginal : String;
    Kurztext : String; //String 100
    Langtext : String; //Kann String
    OfferPrice : double; //Kann Decimal 10,4 Brutto-, Listenpreis
    NetPrice : double; //Kann Decimal 10,4 Einkaufspreis des Kunden
    PriceBasis : double; //Kann Decimal 10,2 Preis bezieht sich auf "n" Einheiten der Anfrage- / Angebots-Mengeneinheit
    VAT : double; //Kann Decimal 5.2 MwSt in %
    TechnClarification : TIDSConnect_TechnClarification; //Kann Technische Klaerung erforderlich Yes / No
    Hinweis : String; //Kann String 256 Wichtiger Hinweis muss dem Benutzer angezeigt werden
    Fehlercode : TIDSConnect_Fehlercode; //Kann
    Fehlertext : String; //Kann String 256
    Zuschlag : double; //Kann Decimal 10,4
    Rohstoffanteile : TIDSConnect_RohstoffanteilList; //Kann
    Divers : Boolean; //Kann
    //ab IDS 2.5.1
    SumMaterialSurcharges : double; //Kann Decimal 10,4 Summe aller Rohstoffzuschlaege bezogen auf die angefragte Menge und die aktuelle Notierung
    DiscountableAmount : double;    //Kann Decimal 10,4 skontofaehiger Betrag bezogen auf die angefragte Menge inkl. aller Zuschlaege und Rabatte
    Referenzen : TIDSConnect_ReferenzPosList; //Kann 0..n
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    //Uebernimmt alle Felder inklusive Rohstoffanteilen und Referenzen.
    //Wird gebraucht, um mehrere Rueckuebertragungen (multipleResult, ab
    //IDS 2.5.1) in einem Warenkorb zu sammeln.
    procedure Assign(_From : TIDSConnect_OrderItem);
  end;

  TIDSConnect_OrderItemList = class(TObjectList<TIDSConnect_OrderItem>)
  public
    function AddItem : TIDSConnect_OrderItem;
  end;

  //Bestellung
  TIDSConnect_Order = class(TObject)
  public
    OrderInfo : TIDSConnect_OrderInfo;
    SupplierInfo : TIDSConnect_SupplierInfo;
    CustomerInfo : TIDSConnect_CustomerInfo;
    DeliveryPlaceInfo : TIDSConnect_DeliveryPlaceInfo;
    OrderItems : TIDSConnect_OrderItemList; //0 bis x
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    //Uebernimmt OrderInfo, SupplierInfo, CustomerInfo und DeliveryPlaceInfo,
    //aber keine Positionen
    procedure AssignHeader(_From : TIDSConnect_Order);
    //Uebernimmt Kopfdaten und Positionen
    procedure Assign(_From : TIDSConnect_Order);
  end;

  TIDSConnect_Warenkorb = class(TObject)
  public
    WarenkorbInfo : TIDSConnect_WarenkorbInfo;
    Order : TIDSConnect_Order;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Assign(_From : TIDSConnect_Warenkorb);
  end;

  //########## Heatinglabel (Aktion HLS, ab IDS 2.3)
  //Die Handwerkssoftware sendet die Artikelliste einer Heizungsanlage an eine
  //Plattform, die das ErP-Label der Verbundanlage berechnet; zurueck kommen
  //die Liste mit Status je Position und die Label als PDF.
  //Schemas: heatinglabel_senden_2-5.xsd und heatinglabel_empfangen_2-5.xsd,
  //Namensraum http://www.itek.de/Shop-Anbindung/Heatinglabel/.
  //Bei allen Codelisten bedeutet der erste Wert "nicht angegeben".

  //Anlagenfunktion
  TIDSConnect_HLPackageFunction = (idsHlPf_None,
                                   idsHlPf_Warmwater,   //warmwater   Warmwasser
                                   idsHlPf_Heating,     //heating     Heizung
                                   idsHlPf_Combination);//combination Kombi

  //Anlagentyp
  TIDSConnect_HLPackageType = (idsHlPt_None,
                               idsHlPt_HeatingBoiler,                   //heating-boiler
                               idsHlPt_HeatingCogeneration,             //heating-cogeneration
                               idsHlPt_HeatingHeatpump,                 //heating-heatpump
                               idsHlPt_HeatingLowtempHeatpump,          //heating-lowtemp-heatpump
                               idsHlPt_HeatingSolidfuelBoiler,          //heating-solidfuel-boiler
                               idsHlPt_HeatingSolidfuelCogeneration,    //heating-solidfuel-cogeneration
                               idsHlPt_CombinationBoiler,               //combination-boiler
                               idsHlPt_CombinationHeatpump,             //combination-heatpump
                               idsHlPt_CombinationSolidfuelBoiler,      //combination-solidfuel-boiler
                               idsHlPt_CombinationSolidfuelCogeneration,//combination-solidfuel-cogeneration
                               idsHlPt_WarmwaterConventional,           //warmwater-conventional
                               idsHlPt_WarmwaterHeatpump);              //warmwater-heatpump

  //Lastprofil
  TIDSConnect_HLLoadProfile = (idsHlLp_None, idsHlLp_M, idsHlLp_L, idsHlLp_XL, idsHlLp_XXL);

  //Einbausituation des Speichers
  TIDSConnect_HLModeOfUse = (idsHlMu_None,
                             idsHlMu_Indoor,   //Indoor  innen
                             idsHlMu_Outdoor); //Outdoor aussen

  //Solarverwendung
  TIDSConnect_HLSolarDeviceUsage = (idsHlSu_None,
                                    idsHlSu_Both,    //both    Warmwasser und Heizung
                                    idsHlSu_Water,   //water   Warmwasser
                                    idsHlSu_Heating);//heating Heizung

  //Produkttyp einer Position (nur in der Rueckgabe)
  TIDSConnect_HLProducttype = (idsHlProd_None,
                               idsHlProd_RHG_HK,      //Raumheizgeraete mit Heizkessel
                               idsHlProd_RHG_KWK,     //Raumheizgeraete mit Kraft-Waerme-Kopplung
                               idsHlProd_RHG_WP,      //Raumheizgeraete mit Waermepumpe
                               idsHlProd_N_WP,        //Niedertemperatur-Waermepumpen
                               idsHlProd_KHG_HK,      //Kombiheizgeraete mit Heizkessel
                               idsHlProd_KHG_WP,      //Kombiheizgeraete mit Waermepumpe
                               idsHlProd_K_WWB,       //Konventionelle Warmwasserbereiter
                               idsHlProd_S_WWB,       //Solarbetriebene Warmwasserbereiter
                               idsHlProd_WWB_WP,      //Warmwasserbereiter mit Waermepumpe
                               idsHlProd_WWS,         //Warmwasserspeicher
                               idsHlProd_TR,          //Temperaturregler
                               idsHlProd_SR,          //Solarregler
                               idsHlProd_TSR,         //Temperaturregler und Solarregler
                               idsHlProd_SE,          //Solareinrichtung
                               idsHlProd_KO,          //Kollektor
                               idsHlProd_PSO,         //Pumpe Solar
                               idsHlProd_SOLG,        //Solargruppe
                               idsHlProd_VBA_RHG_TR_S,//Verbundanlage Raumheizgeraet, Temperaturregelung und Solareinrichtung
                               idsHlProd_VBA_KHG_TR_S,//Verbundanlage Kombiheizgeraet, Temperaturregelung und Solareinrichtung
                               idsHlProd_VBA_WWB_S,   //Verbundanlage Warmwasserbereiter mit Solareinrichtung
                               idsHlProd_WRL,         //nur im Schema, ohne Beschreibung
                               idsHlProd_FBS_HK);     //nur im Schema, ohne Beschreibung

  //Status einer Position (nur in der Rueckgabe)
  TIDSConnect_HLStatus = (idsHlSt_None,
                          idsHlSt_NotUsed,  //Position nicht verwendet
                          idsHlSt_NotFound, //Position nicht im Datenpool vorhanden
                          idsHlSt_Used,     //Position in der Verbundanlage verwendet
                          idsHlSt_New);     //verwendet und in der Plattform hinzugefuegt

  //Art eines PDF-Dokuments (nur in der Rueckgabe)
  TIDSConnect_HLPDFType = (idsHlPdf_None,
                           idsHlPdf_PackageLabelAndFiche,  //Datenblatt und ErP-Label der Verbundanlage
                           idsHlPdf_Articlelist,           //Liste der verwendeten Artikel
                           idsHlPdf_PrimaryProductLabel,   //ErP-Label des Primaergeraets
                           idsHlPdf_PositionProductLabel); //Produktlabel einer Position

const
  //Codes laut Schema, Index = Aufzaehlungswert
  IDS_HL_PACKAGEFUNCTION_CODES : array[TIDSConnect_HLPackageFunction] of String =
    ('','warmwater','heating','combination');
  IDS_HL_PACKAGETYPE_CODES : array[TIDSConnect_HLPackageType] of String =
    ('','heating-boiler','heating-cogeneration','heating-heatpump',
     'heating-lowtemp-heatpump','heating-solidfuel-boiler',
     'heating-solidfuel-cogeneration','combination-boiler','combination-heatpump',
     'combination-solidfuel-boiler','combination-solidfuel-cogeneration',
     'warmwater-conventional','warmwater-heatpump');
  IDS_HL_LOADPROFILE_CODES : array[TIDSConnect_HLLoadProfile] of String =
    ('','M','L','XL','XXL');
  IDS_HL_MODEOFUSE_CODES : array[TIDSConnect_HLModeOfUse] of String =
    ('','Indoor','Outdoor');
  IDS_HL_SOLARDEVICEUSAGE_CODES : array[TIDSConnect_HLSolarDeviceUsage] of String =
    ('','both','water','heating');
  IDS_HL_PRODUCTTYPE_CODES : array[TIDSConnect_HLProducttype] of String =
    ('','RHG-HK','RHG-KWK','RHG-WP','N-WP','KHG-HK','KHG-WP','K-WWB','S-WWB',
     'WWB-WP','WWS','TR','SR','TSR','SE','KO','PSO','SOLG','VBA-RHG-TR-S',
     'VBA-KHG-TR-S','VBA-WWB-S','WRL','FBS-HK');
  IDS_HL_STATUS_CODES : array[TIDSConnect_HLStatus] of String =
    ('','NotUsed','NotFound','Used','New');
  IDS_HL_PDFTYPE_CODES : array[TIDSConnect_HLPDFType] of String =
    ('','PackageLabelAndFiche','Articlelist','PrimaryProductLabel','PositionProductLabel');

type
  //Ein PDF-Dokument der Rueckgabe; Data enthaelt die dekodierte Datei
  TIDSConnect_HeatinglabelPDF = class(TObject)
  public
    PDFName : String;   //Muss String 80 Dateiname
    Data : TBytes;      //Muss Datei (im XML base64)
    PDFType : TIDSConnect_HLPDFType; //Muss
    constructor Create;
    procedure Clear;
    procedure Assign(_From : TIDSConnect_HeatinglabelPDF);
    function IsEmpty : Boolean;
    //Schreibt Data in eine Datei
    procedure SaveToFile(const _Filename : String);
  end;

  TIDSConnect_HeatinglabelPDFList = class(TObjectList<TIDSConnect_HeatinglabelPDF>)
  public
    function AddItem : TIDSConnect_HeatinglabelPDF;
  end;

  //Kopfdaten der Verbundanlage
  TIDSConnect_HeatinglabelHeader = class(TObject)
  public
    PackageFunction : TIDSConnect_HLPackageFunction;   //Senden Kann, Rueckgabe Muss
    PackageType : TIDSConnect_HLPackageType;           //Senden Kann, Rueckgabe Muss
    LoadProfile : TIDSConnect_HLLoadProfile;           //Kann
    ModeOfUse : TIDSConnect_HLModeOfUse;               //Kann
    PackageSupplier : String;                          //String 35, wer die Anlage zusammenstellt (erscheint auf dem Label); Senden Kann, Rueckgabe Muss
    SolarDeviceUsage : TIDSConnect_HLSolarDeviceUsage; //Kann
    IncludeProductLabels : Boolean;                    //Nur Senden: auch die Produktlabel der Positionen anfordern (nur true wird gesendet)
    PDFs : TIDSConnect_HeatinglabelPDFList;            //Nur Rueckgabe, 1 bis 3
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Assign(_From : TIDSConnect_HeatinglabelHeader);
  end;

  //Position der Artikelliste. Zum Senden wird jede Position entweder ueber
  //SupplierID und Productnumber (Kennungen der Plattform) oder ueber die
  //GTIN (EAN) identifiziert - das Schema laesst nur eines von beiden zu; sind
  //beide angegeben, werden SupplierID und Productnumber gesendet.
  TIDSConnect_HeatinglabelPosition = class(TObject)
  public
    SupplierID : String;       //String 80 Lieferant in der Plattform; Rueckgabe Muss
    Productnumber : String;    //String 80 Produkt in der Plattform; Rueckgabe Muss
    GTIN : String;             //String 13
    ConstructionFrom : TDate;  //Kann, hergestellt ab (0 = nicht angegeben)
    ConstructionTo : TDate;    //Kann, hergestellt bis (0 = nicht angegeben)
    Shorttext : String;        //Kann String 81
    Qty : Integer;             //Kann, Menge in der Anlage; groesser 1 nur bei Kollektoren (0 = nicht angegeben)
    RefItems_Customer : String;      //Kann String 35 Positionsnummer des Handwerkers
    RefItems_CustomerSubNo : String; //Kann String 35 Unterpositionsnummer des Handwerkers
    RefItems_Supplier : String;      //Kann String 35 Positionsnummer der Plattform
    RefItems_SupplierSubNo : String; //Kann String 35 Unterpositionsnummer der Plattform
    Producttype : TIDSConnect_HLProducttype; //Nur Rueckgabe
    Status : TIDSConnect_HLStatus;           //Nur Rueckgabe, dort Muss
    PDF : TIDSConnect_HeatinglabelPDF;       //Nur Rueckgabe: Produktlabel der Position (leer, wenn keines)
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Assign(_From : TIDSConnect_HeatinglabelPosition);
  end;

  TIDSConnect_HeatinglabelPositionList = class(TObjectList<TIDSConnect_HeatinglabelPosition>)
  public
    function AddItem : TIDSConnect_HeatinglabelPosition;
  end;

  TIDSConnect_Heatinglabel = class(TObject)
  public
    Header : TIDSConnect_HeatinglabelHeader;
    Positions : TIDSConnect_HeatinglabelPositionList;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Assign(_From : TIDSConnect_Heatinglabel);
  end;

implementation

{ TIDSConnect_LoginInfo }

procedure TIDSConnect_LoginInfo.Clear;
begin
  //Ohne Antwort des Shops wird angenommen, dass alle drei Angaben noetig
  //sind - das ist die Voreinstellung der bisherigen Aufrufe
  CustomerNoRequired := true;
  UsernameRequired := true;
  PasswordRequired := true;
end;

{ TIDSConnect_WarenkorbInfo }

constructor TIDSConnect_WarenkorbInfo.Create;
begin
  Clear;
end;

procedure TIDSConnect_WarenkorbInfo.Clear;
begin
  Date        := 0;
  Time        := 0;
  RueckgabeKZ := idsConnectRKZ_None;
  //Standard ist die aktuelle Schnittstellenversion. Wer weiterhin nach 2.5
  //serialisieren will, setzt Version explizit auf idsConnectVersion_2_5.
  Version     := idsConnectVersion_2_5_1;
end;

procedure TIDSConnect_WarenkorbInfo.Assign(_From: TIDSConnect_WarenkorbInfo);
begin
  if (_From = nil) or (_From = Self) then
    exit;
  Date        := _From.Date;
  Time        := _From.Time;
  RueckgabeKZ := _From.RueckgabeKZ;
  Version     := _From.Version;
end;

{ TIDSConnect_Referenz }

constructor TIDSConnect_Referenz.Create;
begin
  Clear;
end;

procedure TIDSConnect_Referenz.Clear;
begin
  ReferenzNumber := '';
  ReferenzDate := 0;
  ReferenzType := idsConnectRefType_None;
end;

procedure TIDSConnect_Referenz.Assign(_From: TIDSConnect_Referenz);
begin
  if (_From = nil) or (_From = Self) then
    exit;
  ReferenzNumber := _From.ReferenzNumber;
  ReferenzDate := _From.ReferenzDate;
  ReferenzType := _From.ReferenzType;
end;

{ TIDSConnect_ReferenzList }

function TIDSConnect_ReferenzList.AddItem: TIDSConnect_Referenz;
begin
  Result := TIDSConnect_Referenz.Create;
  Add(Result);
end;

{ TIDSConnect_ReferenzPos }

procedure TIDSConnect_ReferenzPos.Clear;
begin
  inherited;
  ReferenzLine := '';
end;

procedure TIDSConnect_ReferenzPos.Assign(_From: TIDSConnect_Referenz);
begin
  inherited;
  if _From is TIDSConnect_ReferenzPos then
    ReferenzLine := TIDSConnect_ReferenzPos(_From).ReferenzLine;
end;

{ TIDSConnect_ReferenzPosList }

function TIDSConnect_ReferenzPosList.AddItem: TIDSConnect_ReferenzPos;
begin
  Result := TIDSConnect_ReferenzPos.Create;
  Add(Result);
end;

{ TIDSConnect_OrderInfo }

constructor TIDSConnect_OrderInfo.Create;
begin
  Referenzen := TIDSConnect_ReferenzList.Create;
  Clear;
end;

destructor TIDSConnect_OrderInfo.Destroy;
begin
  if Assigned(Referenzen) then begin Referenzen.Free; Referenzen := nil; end;
  inherited;
end;

procedure TIDSConnect_OrderInfo.Clear;
begin
  InquiryNo := '';
  OfferNo := '';
  PartNo := '';
  OrderConfNo := '';
  Referenzen.Clear;
  DeliveryWeek := 0;
  DeliveryYear := 0;
  DeliveryDate := 0;
  ModeOfShipment := idsConnectMos_Lieferung;
  ZusatzText := '';
  Kommission := '';
  Cur := 'EUR';
end;

procedure TIDSConnect_OrderInfo.Assign(_From: TIDSConnect_OrderInfo);
var
  i : Integer;
begin
  if (_From = nil) or (_From = Self) then
    exit;
  InquiryNo := _From.InquiryNo;
  OfferNo := _From.OfferNo;
  PartNo := _From.PartNo;
  OrderConfNo := _From.OrderConfNo;
  Referenzen.Clear;
  for i := 0 to _From.Referenzen.Count-1 do
    Referenzen.AddItem.Assign(_From.Referenzen[i]);
  DeliveryWeek := _From.DeliveryWeek;
  DeliveryYear := _From.DeliveryYear;
  DeliveryDate := _From.DeliveryDate;
  ModeOfShipment := _From.ModeOfShipment;
  ZusatzText := _From.ZusatzText;
  Kommission := _From.Kommission;
  Cur := _From.Cur;
end;

{ TIDSConnect_Address }

constructor TIDSConnect_Address.Create;
begin
  Clear;
end;

procedure TIDSConnect_Address.Clear;
begin
  Name1 := '';
  Name2 := '';
  Name3 := '';
  Name4 := '';
  Street := '';
  Street1 := '';
  Street2 := '';
  Street3 := '';
  PCode := '';
  City := '';
  Country := '';
  ILN := '';
  Contact := '';
  Phone := '';
  Fax := '';
  Email := '';
end;

procedure TIDSConnect_Address.Assign(_From: TIDSConnect_Address);
begin
  if (_From = nil) or (_From = Self) then
    exit;
  Name1 := _From.Name1;
  Name2 := _From.Name2;
  Name3 := _From.Name3;
  Name4 := _From.Name4;
  Street := _From.Street;
  Street1 := _From.Street1;
  Street2 := _From.Street2;
  Street3 := _From.Street3;
  PCode := _From.PCode;
  City := _From.City;
  Country := _From.Country;
  ILN := _From.ILN;
  Contact := _From.Contact;
  Phone := _From.Phone;
  Fax := _From.Fax;
  Email := _From.Email;
end;

{ TIDSConnect_SupplierInfo }

constructor TIDSConnect_SupplierInfo.Create;
begin
  Address := TIDSConnect_Address.Create;
  Clear;
end;

destructor TIDSConnect_SupplierInfo.Destroy;
begin
  if Assigned(Address) then begin Address.Free; Address := nil; end;
  inherited;
end;

procedure TIDSConnect_SupplierInfo.Clear;
begin
  IDNo := '';
  Address.Clear;
end;

procedure TIDSConnect_SupplierInfo.Assign(_From: TIDSConnect_SupplierInfo);
begin
  if (_From = nil) or (_From = Self) then
    exit;
  IDNo := _From.IDNo;
  Address.Assign(_From.Address);
end;

{ TIDSConnect_CustomerInfo }

constructor TIDSConnect_CustomerInfo.Create;
begin
  Address := TIDSConnect_Address.Create;
  Clear;
end;

destructor TIDSConnect_CustomerInfo.Destroy;
begin
  if Assigned(Address) then begin Address.Free; Address := nil; end;
  inherited;
end;

procedure TIDSConnect_CustomerInfo.Clear;
begin
  IDNo := '';
  Address.Clear;
end;

procedure TIDSConnect_CustomerInfo.Assign(_From: TIDSConnect_CustomerInfo);
begin
  if (_From = nil) or (_From = Self) then
    exit;
  IDNo := _From.IDNo;
  Address.Assign(_From.Address);
end;

{ TIDSConnect_DeliveryPlaceInfo }

constructor TIDSConnect_DeliveryPlaceInfo.Create;
begin
  Address := TIDSConnect_Address.Create;
  Clear;
end;

destructor TIDSConnect_DeliveryPlaceInfo.Destroy;
begin
  if Assigned(Address) then begin Address.Free; Address := nil; end;
  inherited;
end;

procedure TIDSConnect_DeliveryPlaceInfo.Clear;
begin
  IDNo := '';
  Address.Clear;
  HasGeoLocation := false;
  GeoLat := 0;
  GeoLang := 0;
end;

procedure TIDSConnect_DeliveryPlaceInfo.Assign(_From: TIDSConnect_DeliveryPlaceInfo);
begin
  if (_From = nil) or (_From = Self) then
    exit;
  IDNo := _From.IDNo;
  Address.Assign(_From.Address);
  HasGeoLocation := _From.HasGeoLocation;
  GeoLat := _From.GeoLat;
  GeoLang := _From.GeoLang;
end;

{ TIDSConnect_Rohstoffanteil }

constructor TIDSConnect_Rohstoffanteil.Create;
begin
  Clear;
end;

procedure TIDSConnect_Rohstoffanteil.Clear;
begin
  Rohstoff := idsConnectR_CU;
  Gewichtsanteilswert := 0;
  Gewichtsanteilseinheit := idsConnectQu_PCE;
  Basiswert := 0;
  Basiseinheit  := idsConnectQu_PCE;
  Basisnotierung := 0;
  NotierungAktuell := 0;
end;

procedure TIDSConnect_Rohstoffanteil.Assign(_From: TIDSConnect_Rohstoffanteil);
begin
  if (_From = nil) or (_From = Self) then
    exit;
  Rohstoff := _From.Rohstoff;
  Gewichtsanteilswert := _From.Gewichtsanteilswert;
  Gewichtsanteilseinheit := _From.Gewichtsanteilseinheit;
  Basiswert := _From.Basiswert;
  Basiseinheit := _From.Basiseinheit;
  Basisnotierung := _From.Basisnotierung;
  NotierungAktuell := _From.NotierungAktuell;
end;

{ TIDSConnect_RohstoffanteilList }

function TIDSConnect_RohstoffanteilList.AddItem: TIDSConnect_Rohstoffanteil;
begin
  Result := TIDSConnect_Rohstoffanteil.Create;
  Add(Result);
end;

{ TIDSConnect_OrderItem }

constructor TIDSConnect_OrderItem.Create;
begin
  Rohstoffanteile := TIDSConnect_RohstoffanteilList.Create;
  Referenzen := TIDSConnect_ReferenzPosList.Create;
  Clear;
end;

destructor TIDSConnect_OrderItem.Destroy;
begin
  if Assigned(Rohstoffanteile) then begin  Rohstoffanteile.Free; Rohstoffanteile := nil; end;
  if Assigned(Referenzen) then begin Referenzen.Free; Referenzen := nil; end;
  inherited;
end;

procedure TIDSConnect_OrderItem.Clear;
begin
  ItemChara := idsConnectIc_normal;
  RefItems_Customer := '';
  RefItems_CustomerSubNo := '';
  RefItems_Supplier := '';
  RefItems_SupplierSubNo := '';
  EAN := '';
  ManufacturerID := '';
  ManufacturerIDType := '';
  ArtNo := '';
  Qty := 0;
  QU := idsConnectQu_PCE;
  QUOriginal := '';
  Kurztext := '';
  Langtext := '';
  OfferPrice := 0;
  NetPrice := 0;
  PriceBasis := 1;
  VAT := 0;
  TechnClarification := idsConnectTc_None;
  Hinweis := '';
  Fehlercode := idsConnectFc_None;
  Fehlertext := '';
  Zuschlag := 0;
  Rohstoffanteile.Clear;
  Divers := false;
  SumMaterialSurcharges := 0;
  DiscountableAmount := 0;
  Referenzen.Clear;
end;

procedure TIDSConnect_OrderItem.Assign(_From: TIDSConnect_OrderItem);
var
  i : Integer;
begin
  if (_From = nil) or (_From = Self) then
    exit;
  ItemChara := _From.ItemChara;
  RefItems_Customer := _From.RefItems_Customer;
  RefItems_CustomerSubNo := _From.RefItems_CustomerSubNo;
  RefItems_Supplier := _From.RefItems_Supplier;
  RefItems_SupplierSubNo := _From.RefItems_SupplierSubNo;
  EAN := _From.EAN;
  ManufacturerID := _From.ManufacturerID;
  ManufacturerIDType := _From.ManufacturerIDType;
  ArtNo := _From.ArtNo;
  Qty := _From.Qty;
  QU := _From.QU;
  QUOriginal := _From.QUOriginal;
  Kurztext := _From.Kurztext;
  Langtext := _From.Langtext;
  OfferPrice := _From.OfferPrice;
  NetPrice := _From.NetPrice;
  PriceBasis := _From.PriceBasis;
  VAT := _From.VAT;
  TechnClarification := _From.TechnClarification;
  Hinweis := _From.Hinweis;
  Fehlercode := _From.Fehlercode;
  Fehlertext := _From.Fehlertext;
  Zuschlag := _From.Zuschlag;
  Divers := _From.Divers;
  SumMaterialSurcharges := _From.SumMaterialSurcharges;
  DiscountableAmount := _From.DiscountableAmount;

  Rohstoffanteile.Clear;
  for i := 0 to _From.Rohstoffanteile.Count-1 do
    Rohstoffanteile.AddItem.Assign(_From.Rohstoffanteile[i]);

  Referenzen.Clear;
  for i := 0 to _From.Referenzen.Count-1 do
    Referenzen.AddItem.Assign(_From.Referenzen[i]);
end;

{ TIDSConnect_OrderItemList }

function TIDSConnect_OrderItemList.AddItem: TIDSConnect_OrderItem;
begin
  Result := TIDSConnect_OrderItem.Create;
  Add(Result);
end;

{ TIDSConnect_Order }

constructor TIDSConnect_Order.Create;
begin
  OrderInfo := TIDSConnect_OrderInfo.Create;
  SupplierInfo := TIDSConnect_SupplierInfo.Create;
  CustomerInfo := TIDSConnect_CustomerInfo.Create;
  DeliveryPlaceInfo := TIDSConnect_DeliveryPlaceInfo.Create;
  OrderItems := TIDSConnect_OrderItemList.Create;
  Clear;
end;

destructor TIDSConnect_Order.Destroy;
begin
  if Assigned(OrderInfo) then begin OrderInfo.Free; OrderInfo := nil; end;
  if Assigned(SupplierInfo) then begin SupplierInfo.Free; SupplierInfo := nil; end;
  if Assigned(CustomerInfo) then begin CustomerInfo.Free; CustomerInfo := nil; end;
  if Assigned(DeliveryPlaceInfo) then begin DeliveryPlaceInfo.Free; DeliveryPlaceInfo := nil; end;
  if Assigned(OrderItems) then begin OrderItems.Free; OrderItems := nil; end;
  inherited;
end;

procedure TIDSConnect_Order.Clear;
begin
  OrderInfo.Clear;
  SupplierInfo.Clear;
  CustomerInfo.Clear;
  DeliveryPlaceInfo.Clear;
  OrderItems.Clear;
end;

procedure TIDSConnect_Order.AssignHeader(_From: TIDSConnect_Order);
begin
  if (_From = nil) or (_From = Self) then
    exit;
  OrderInfo.Assign(_From.OrderInfo);
  SupplierInfo.Assign(_From.SupplierInfo);
  CustomerInfo.Assign(_From.CustomerInfo);
  DeliveryPlaceInfo.Assign(_From.DeliveryPlaceInfo);
end;

procedure TIDSConnect_Order.Assign(_From: TIDSConnect_Order);
var
  i : Integer;
begin
  if (_From = nil) or (_From = Self) then
    exit;
  AssignHeader(_From);
  OrderItems.Clear;
  for i := 0 to _From.OrderItems.Count-1 do
    OrderItems.AddItem.Assign(_From.OrderItems[i]);
end;

{ TIDSConnect_Warenkorb }

procedure TIDSConnect_Warenkorb.Clear;
begin
  WarenkorbInfo.Clear;
  Order.Clear;
end;

procedure TIDSConnect_Warenkorb.Assign(_From: TIDSConnect_Warenkorb);
begin
  if (_From = nil) or (_From = Self) then
    exit;
  WarenkorbInfo.Assign(_From.WarenkorbInfo);
  Order.Assign(_From.Order);
end;

constructor TIDSConnect_Warenkorb.Create;
begin
  WarenkorbInfo := TIDSConnect_WarenkorbInfo.Create;
  Order := TIDSConnect_Order.Create;
  Clear;
end;

destructor TIDSConnect_Warenkorb.Destroy;
begin
  if Assigned(WarenkorbInfo) then begin WarenkorbInfo.Free; WarenkorbInfo := nil; end;
  if Assigned(Order) then begin Order.Free; Order := nil; end;
  inherited;
end;

{ TIDSConnect_HeatinglabelPDF }

constructor TIDSConnect_HeatinglabelPDF.Create;
begin
  Clear;
end;

procedure TIDSConnect_HeatinglabelPDF.Clear;
begin
  PDFName := '';
  Data := nil;
  PDFType := idsHlPdf_None;
end;

procedure TIDSConnect_HeatinglabelPDF.Assign(_From: TIDSConnect_HeatinglabelPDF);
begin
  if (_From = nil) or (_From = Self) then
    exit;
  PDFName := _From.PDFName;
  Data := Copy(_From.Data);
  PDFType := _From.PDFType;
end;

function TIDSConnect_HeatinglabelPDF.IsEmpty: Boolean;
begin
  Result := Length(Data) = 0;
end;

procedure TIDSConnect_HeatinglabelPDF.SaveToFile(const _Filename: String);
var
  lStream : TFileStream;
begin
  lStream := TFileStream.Create(_Filename,fmCreate);
  try
    if Length(Data) > 0 then
      lStream.WriteBuffer(Data[0],Length(Data));
  finally
    lStream.Free;
  end;
end;

{ TIDSConnect_HeatinglabelPDFList }

function TIDSConnect_HeatinglabelPDFList.AddItem: TIDSConnect_HeatinglabelPDF;
begin
  Result := TIDSConnect_HeatinglabelPDF.Create;
  Add(Result);
end;

{ TIDSConnect_HeatinglabelHeader }

constructor TIDSConnect_HeatinglabelHeader.Create;
begin
  PDFs := TIDSConnect_HeatinglabelPDFList.Create;
  Clear;
end;

destructor TIDSConnect_HeatinglabelHeader.Destroy;
begin
  PDFs.Free;
  inherited;
end;

procedure TIDSConnect_HeatinglabelHeader.Clear;
begin
  PackageFunction := idsHlPf_None;
  PackageType := idsHlPt_None;
  LoadProfile := idsHlLp_None;
  ModeOfUse := idsHlMu_None;
  PackageSupplier := '';
  SolarDeviceUsage := idsHlSu_None;
  IncludeProductLabels := false;
  PDFs.Clear;
end;

procedure TIDSConnect_HeatinglabelHeader.Assign(_From: TIDSConnect_HeatinglabelHeader);
var
  i : Integer;
begin
  if (_From = nil) or (_From = Self) then
    exit;
  PackageFunction := _From.PackageFunction;
  PackageType := _From.PackageType;
  LoadProfile := _From.LoadProfile;
  ModeOfUse := _From.ModeOfUse;
  PackageSupplier := _From.PackageSupplier;
  SolarDeviceUsage := _From.SolarDeviceUsage;
  IncludeProductLabels := _From.IncludeProductLabels;
  PDFs.Clear;
  for i := 0 to _From.PDFs.Count-1 do
    PDFs.AddItem.Assign(_From.PDFs[i]);
end;

{ TIDSConnect_HeatinglabelPosition }

constructor TIDSConnect_HeatinglabelPosition.Create;
begin
  PDF := TIDSConnect_HeatinglabelPDF.Create;
  Clear;
end;

destructor TIDSConnect_HeatinglabelPosition.Destroy;
begin
  PDF.Free;
  inherited;
end;

procedure TIDSConnect_HeatinglabelPosition.Clear;
begin
  SupplierID := '';
  Productnumber := '';
  GTIN := '';
  ConstructionFrom := 0;
  ConstructionTo := 0;
  Shorttext := '';
  Qty := 0;
  RefItems_Customer := '';
  RefItems_CustomerSubNo := '';
  RefItems_Supplier := '';
  RefItems_SupplierSubNo := '';
  Producttype := idsHlProd_None;
  Status := idsHlSt_None;
  PDF.Clear;
end;

procedure TIDSConnect_HeatinglabelPosition.Assign(_From: TIDSConnect_HeatinglabelPosition);
begin
  if (_From = nil) or (_From = Self) then
    exit;
  SupplierID := _From.SupplierID;
  Productnumber := _From.Productnumber;
  GTIN := _From.GTIN;
  ConstructionFrom := _From.ConstructionFrom;
  ConstructionTo := _From.ConstructionTo;
  Shorttext := _From.Shorttext;
  Qty := _From.Qty;
  RefItems_Customer := _From.RefItems_Customer;
  RefItems_CustomerSubNo := _From.RefItems_CustomerSubNo;
  RefItems_Supplier := _From.RefItems_Supplier;
  RefItems_SupplierSubNo := _From.RefItems_SupplierSubNo;
  Producttype := _From.Producttype;
  Status := _From.Status;
  PDF.Assign(_From.PDF);
end;

{ TIDSConnect_HeatinglabelPositionList }

function TIDSConnect_HeatinglabelPositionList.AddItem: TIDSConnect_HeatinglabelPosition;
begin
  Result := TIDSConnect_HeatinglabelPosition.Create;
  Add(Result);
end;

{ TIDSConnect_Heatinglabel }

constructor TIDSConnect_Heatinglabel.Create;
begin
  Header := TIDSConnect_HeatinglabelHeader.Create;
  Positions := TIDSConnect_HeatinglabelPositionList.Create;
end;

destructor TIDSConnect_Heatinglabel.Destroy;
begin
  Positions.Free;
  Header.Free;
  inherited;
end;

procedure TIDSConnect_Heatinglabel.Clear;
begin
  Header.Clear;
  Positions.Clear;
end;

procedure TIDSConnect_Heatinglabel.Assign(_From: TIDSConnect_Heatinglabel);
var
  i : Integer;
begin
  if (_From = nil) or (_From = Self) then
    exit;
  Header.Assign(_From.Header);
  Positions.Clear;
  for i := 0 to _From.Positions.Count-1 do
    Positions.AddItem.Assign(_From.Positions[i]);
end;

end.
