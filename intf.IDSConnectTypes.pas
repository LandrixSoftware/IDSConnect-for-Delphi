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
  TIDSConnect_Version = (idsConnectVersion_Unkown,idsConnectVersion_2_5);

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
  end;

  //Lieferung / Abholung
  TIDSConnect_ModeOfShipment = (idsConnectMos_Lieferung, //value="Lieferung"
                                idsConnectMos_Abholung); //value="Abholung"

  TIDSConnect_OrderInfo = class(TObject)
  public
    InquiryNo : String; //Kann String 15 Anfragenummer aus der Handwerkssoftware
    OfferNo : String;  //Kann String 15 Angebotsnummer aus dem Grosshandels-System
    PartNo : String; //Kann String 15 Bestellnummer aus der Handwerkssoftware
    OrderConfNo : String; //Kann String 15 Auftragsbestaetigungsnummer Bestellnummer aus dem Grosshandels-System
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
    procedure Clear;
  end;

  TIDSConnect_Address = class(TObject)
  public
    Name1 : String;   //String 40
    Name2 : String;   //String 40
    Name3 : String;   //String 40
    Name4 : String;   //String 40
    Street : String;  //String 40
    PCode : String;   //String 20
    City : String;    //String 40
    Country : String; //String 40
    ILN : String;     //String 20
    Contact : String; //String 40
    Phone : String;   //String 20
    Fax : String;     //String 20
    Email : String;   //String 256
    constructor Create;
    procedure Clear;
  end;

  //Informationen zum Lieferanten
  TIDSConnect_SupplierInfo = class(TObject)
  public
    IDNo : String; //Kann String 40 Lieferantennummer beim Handwerker
    Address : TIDSConnect_Address; //Informationen zur Adresse des Lieferanten
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  end;

  //Informationen zum Besteller (Kunden)
  TIDSConnect_CustomerInfo = class(TObject)
  public
    IDNo : String; //Kann String 40 Kundennummer beim Lieferanten
    Address : TIDSConnect_Address; //Informationen zur Adresse des Kunden
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  end;

  //Struktur zur Abbildung der Lieferadresse bzw.Abholadresse abh�ngig von der Versandart
  TIDSConnect_DeliveryPlaceInfo = class(TObject)
  public
    IDNo : String; //Kann String 40 ID-Nummer fuer Lieferort
    Address : TIDSConnect_Address; //Kann
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
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
                   idsConnectR_SN // Zinn
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
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
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
  end;

  TIDSConnect_Warenkorb = class(TObject)
  public
    WarenkorbInfo : TIDSConnect_WarenkorbInfo;
    Order : TIDSConnect_Order;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  end;

implementation

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
  Version     := idsConnectVersion_2_5;
end;

{ TIDSConnect_OrderInfo }

constructor TIDSConnect_OrderInfo.Create;
begin
  Clear;
end;

procedure TIDSConnect_OrderInfo.Clear;
begin
  InquiryNo := '';
  OfferNo := '';
  PartNo := '';
  OrderConfNo := '';
  DeliveryWeek := 0;
  DeliveryYear := 0;
  DeliveryDate := 0;
  ModeOfShipment := idsConnectMos_Lieferung;
  ZusatzText := '';
  Kommission := '';
  Cur := 'EUR';
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
  PCode := '';
  City := '';
  Country := '';
  ILN := '';
  Contact := '';
  Phone := '';
  Fax := '';
  Email := '';
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
  Clear;
end;

destructor TIDSConnect_OrderItem.Destroy;
begin
  if Assigned(Rohstoffanteile) then begin  Rohstoffanteile.Free; Rohstoffanteile := nil; end;
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

{ TIDSConnect_Warenkorb }

procedure TIDSConnect_Warenkorb.Clear;
begin
  WarenkorbInfo.Clear;
  Order.Clear;
end;

constructor TIDSConnect_Warenkorb.Create;
begin
  WarenkorbInfo := TIDSConnect_WarenkorbInfo.Create;
  Order := TIDSConnect_Order.Create;
end;

destructor TIDSConnect_Warenkorb.Destroy;
begin
  if Assigned(WarenkorbInfo) then begin WarenkorbInfo.Free; WarenkorbInfo := nil; end;
  if Assigned(Order) then begin Order.Free; Order := nil; end;
  inherited;
end;

end.
