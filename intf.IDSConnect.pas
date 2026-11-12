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

unit intf.IDSConnect;

interface

uses
  System.SysUtils, System.Classes, System.Net.URLClient, LandrixXmlDom,
  intf.IDSConnectTypes;

type
  TIDSConnectOnException = reference to procedure (const _Message : String; _E : Exception);
  TIDSConnectOnRequest = reference to procedure (const _Url,_Parameters : String);
  TIDSConnectOnResponse = reference to procedure (const _Url : String;
    _StatusCode : Integer; const _Body : TBytes);

  TIDSConnect = class(TObject)
  public class var
    IDSCONNECT_HOOKURL : String;
    //Nur fuer Testumgebungen mit selbstsignierten Zertifikaten auf true setzen.
    //Im Normalbetrieb bleibt die Zertifikatspruefung des Betriebssystems aktiv.
    IDSCONNECT_ALLOW_INVALID_CERT : Boolean;
    //Optionaler Fehler-Callback. Fruehere Versionen haben Parser- und
    //Netzwerkfehler in leeren except-Bloecken verschluckt.
    IDSCONNECT_ONERROR : TIDSConnectOnException;
    //Optional: vorbereiteter WKE-Aufruf (Passwort maskiert) und rohe
    //HTTP-Antworten der Hook-URL, auch bei HTTP- oder XML-Fehlern.
    IDSCONNECT_ONREQUEST : TIDSConnectOnRequest;
    IDSCONNECT_ONRESPONSE : TIDSConnectOnResponse;
    //Wie lange (in Sekunden) beim Warenkorb senden/empfangen auf die
    //Rueckuebertragung gewartet wird. 0 = ohne Zeitbegrenzung warten, bis der
    //Anwender abbricht. Fuer die Artikelsuche gibt es ab IDS 2.5.1 den
    //eigenen Parameter hookURLTimeout an IDSConnectAS.
    IDSCONNECT_HOOKURL_TIMEOUT : Integer;
    //Nur bei Mehrfachrueckgabe: wie lange (in Sekunden) nach einer
    //eingetroffenen Rueckgabe noch auf weitere gewartet wird.
    //0 (Voreinstellung) = die volle Frist hookURLTimeout ab der letzten
    //Uebertragung, wie sie dem Shop zugesagt wurde; der Anwender beendet den
    //Vorgang mit "Fertig". Ein kleinerer Wert schliesst den Dialog frueher,
    //verwirft dann aber Rueckgaben, die der Shop innerhalb der zugesagten
    //Frist noch sendet.
    IDSCONNECT_MULTIPLERESULT_FOLLOWUP : Integer;
  public const
    //Hoechstzahl der Abrufe in einem Durchgang von CollectResults - schuetzt
    //vor einer Endlosschleife, falls ein Hook-Server die Rueckgabe beim Abruf
    //nicht verbraucht
    IDSCONNECT_MAX_COLLECT = 50;
  public type
    //Zustand beim Sammeln mehrerer Rueckgaben (Mehrfachrueckgabe). Vor dem
    //ersten Aufruf von CollectResults mit Default() initialisieren.
    TCollectState = record
      Received : Integer;          //Anzahl der uebernommenen Rueckgaben
      SeenIds : TArray<String>;    //Kennungen (X-IDSConnect-Id) aller
                                   //uebernommenen Rueckgaben
      LastRaw : TBytes;            //Rohdaten der letzten Rueckgabe, falls der
                                   //Server keine Kennung liefert
      LastHadId : Boolean;         //Die letzte Rueckgabe hatte eine Kennung
      ErrorReported : Boolean;     //Abruffehler wurde bereits gemeldet
      DuplicateReported : Boolean; //Wiederholte Rueckgabe wurde bereits gemeldet
      LimitReached : Boolean;      //Der letzte Durchgang endete an
                                   //IDSCONNECT_MAX_COLLECT, es kann mehr vorliegen
    end;
  private type
    TValidateCertificatHelper = class(TObject)
      procedure DoValidateCertificateEvent(const Sender: TObject;
                   const ARequest: TURLRequest; const Certificate: TCertificate;
                   var Accepted: Boolean);
    end;
  private
    class procedure ReportError(const _Message : String; _E : Exception);
    class function GetUuid : String;
    class function HookUrlWithSid(const _Sid : String) : String;
    class function TryFetchResult(const _Url : String;_Warenkorb : TIDSConnect_Warenkorb) : Boolean; overload;
    //Wie TryFetchResult, liefert zusaetzlich die Rohdaten der Antwort und die
    //Kennung der Uebertragung (Header X-IDSConnect-Id, leer, wenn der Server
    //keine sendet). Mit _Warenkorb = nil wird nur heruntergeladen: true, wenn
    //eine nicht leere Antwort mit HTTP 200 vorliegt.
    class function FetchResult(const _Url : String;_Warenkorb : TIDSConnect_Warenkorb;
                               out _Error : String; out _Raw : TBytes;
                               out _Id : String) : Boolean;
    //Ruft CollectResults so oft auf, bis die Warteschlange leer ist (begrenzt
    //auf 20 Durchgaenge); bleibt danach noch etwas liegen, wird es gemeldet
    class procedure CollectAll(const _Url : String; _Warenkorb : TIDSConnect_Warenkorb;
                               var _State : TCollectState);
    //Basisadresse der Hook-URL ohne Query - daran erkennt der integrierte
    //Browser, dass die Rueck-Kommunikation abgeschlossen ist
    class function HookUrlBase : String;
    //Direkter POST einer Aktion ohne Browser; fuer die Abfragen LI und SV
    class function PostAction(const _ServiceURL,_Action : String; out _Response : String;
      _Version : TIDSConnect_Version) : Boolean;
    //Wurzelknoten der Antwort einer Abfrage; nil bei Fehler
    class function ParseResponse(const _Response,_RootName : String; out _Doc : TLandrixXmlDocument) : TLandrixXmlNode;
    //Wartet mit Fortschrittsdialog, bis die Rueckuebertragung eingetroffen
    //ist, der Anwender abbricht oder das Timeout ablaeuft.
    class function WaitForResult(const _Url : String;_Warenkorb : TIDSConnect_Warenkorb;
                                 _TimeoutSec : Integer;_MultipleResult : Boolean = false) : Boolean;
    class function BuildFormHeader(const _Title : String) : String;
    class function HiddenField(const _Name,_Value : String; _MaxLength : Integer = 0) : String;
    class function SaveFormToFile(_Form : TStrings; const _TmpFilename : String) : Boolean;
    class function OpenInBrowser(const _TmpFilename : String) : Boolean;
    //Zeigt das Formular an und holt anschliessend das Ergebnis ab.
    //_TmpFilename = '' -> integrierter Browser, sonst externer Browser ueber
    //eine temporaere Datei. _ResultUrl = '' -> es wird kein Ergebnis erwartet.
    class function ShowFormAndFetch(_Form : TStrings; const _TmpFilename,_ResultUrl : String;
                                    _Warenkorb : TIDSConnect_Warenkorb; _TimeoutSec : Integer;
                                    _MultipleResult : Boolean = false) : Boolean;
  public
    //Ein einzelner Abruf der vollstaendigen Hook-URL inklusive sid, auch fuer
    //eigene Diagnose-/Polling-Oberflaechen. 404 oder leer: false, kein Fehler.
    //HTTP-/Parserfehler: false und Fehlertext. Rohe Antwort ueber ONRESPONSE.
    class function TryFetchResult(const _Url : String;_Warenkorb : TIDSConnect_Warenkorb;
                                  out _Error : String) : Boolean; overload;
    //Haengt die Positionen einer Rueckgabe an den Zielwarenkorb an. Wird bei
    //der Mehrfachrueckgabe (multipleResult, ab IDS 2.5.1) gebraucht und steht
    //auch fuer eine eigene Ablaufsteuerung zur Verfuegung.
    //Mit _TakeHeader werden zusaetzlich alle Kopfdaten (WarenkorbInfo,
    //OrderInfo inkl. Waehrung und Referenzen, Lieferanten-, Kunden- und
    //Lieferortdaten) uebernommen - das gehoert zur ersten Rueckgabe.
    class procedure MergeOrderItems(_From,_To : TIDSConnect_Warenkorb;
                                    _TakeHeader : Boolean); overload;
    //Uebernimmt die Kopfdaten, solange der Zielwarenkorb noch keine
    //Positionen hat
    class procedure MergeOrderItems(_From,_To : TIDSConnect_Warenkorb); overload;
    //Holt die an der Hook-URL aufgelaufenen Rueckgaben ab (hoechstens
    //IDSCONNECT_MAX_COLLECT je Aufruf, dann ist _State.LimitReached gesetzt)
    //und haengt sie an _Warenkorb an; die erste liefert auch die Kopfdaten.
    //Der Hook-Server muss jede Rueckgabe beim Abruf verbrauchen
    //(Warteschlange, siehe idsconnect.php). Wiederholt er eine Rueckgabe,
    //wird sie verworfen und einmalig gemeldet - erkannt an der Kennung
    //X-IDSConnect-Id, bei Servern ohne Kennung an gleichen Rohdaten.
    //Ergebnis: true, wenn in diesem Aufruf mindestens eine neue Rueckgabe
    //uebernommen wurde.
    class function CollectResults(const _Url : String; _Warenkorb : TIDSConnect_Warenkorb;
                                  var _State : TCollectState) : Boolean;

    //Aktion "LI": fragt ab, welche Anmeldedaten das Shop-System benoetigt.
    //Laeuft als direkter POST, ohne Browser und ohne Hook-URL.
    class function IDSConnectLI(const _ServiceURL : String; out _LoginInfo : TIDSConnect_LoginInfo;
      _Version : TIDSConnect_Version = idsConnectVersion_2_5_1) : Boolean;
    //Aktion "SV": fragt die vom Shop unterstuetzten Schnittstellenversionen ab.
    //_Versions erhaelt die Angaben in der Reihenfolge der Antwort.
    class function IDSConnectSV(const _ServiceURL : String; _Versions : TStrings;
      _Version : TIDSConnect_Version = idsConnectVersion_2_5_1) : Boolean;
    //Liefert die hoechste Version, die sowohl der Shop als auch diese Unit
    //beherrscht - oder idsConnectVersion_Unkown, wenn die Abfrage scheitert.
    class function IDSConnectSVBestVersion(const _ServiceURL : String;
      _Version : TIDSConnect_Version = idsConnectVersion_2_5_1) : TIDSConnect_Version;
    class procedure IDSConnectADT(const _ServiceURL,_Cst,_UN,_Pwd,_ArtNr,_TmpFilename : String;
      _Version : TIDSConnect_Version = idsConnectVersion_2_5_1);
    class function  IDSConnectWKE(const _ServiceURL,_Cst,_UN,_Pwd,_TmpFilename : String;_Warenkorb : TIDSConnect_Warenkorb;
      _Version : TIDSConnect_Version = idsConnectVersion_2_5_1) : Boolean;
    class function  IDSConnectWKS(_ServiceURL,_Cst,_UN,_Pwd,_TmpFilename : String;_Warenkorb : TIDSConnect_Warenkorb;_DontWait : Boolean = false) : Boolean;
    //_MultipleResult und _HookUrlTimeout sind ab IDS 2.5.1 definiert:
    //_MultipleResult = true  -> die Handwerkssoftware unterstuetzt mehrfache Uebertragungen an die HookUrl
    //_HookUrlTimeout > 0     -> Angabe in Sekunden, wie lange die HookUrl aktiv bleibt
    class function  IDSConnectAS(_ServiceURL,_Cst,_UN,_Pwd,_TmpFilename,_SearchString : String;_Warenkorb : TIDSConnect_Warenkorb;
                                 _MultipleResult : Boolean = false;_HookUrlTimeout : Integer = 0;
                                 _Version : TIDSConnect_Version = idsConnectVersion_2_5_1) : Boolean;
  end;

  TIDSConnectHelper = class(TObject)
  public
    class function RohstoffStrToRohstoff(const _Val: String): TIDSConnect_Rohstoff;
    //false bei unbekanntem Code; _Rohstoff ist dann CU
    class function TryRohstoffStrToRohstoff(const _Val: String; out _Rohstoff: TIDSConnect_Rohstoff): Boolean;
    class function RohstoffToRohstoffStr(const _Val: TIDSConnect_Rohstoff): String;
    class function StrToFloat(_Val: String; _Default: double): double;
    class function FloatToStr(const _Val: double; _Decimals: Integer): String;
    class function QuToQuStrInternal(const _Val: TIDSConnect_QU): String;
    class function QuToQuStr(const _Val: TIDSConnect_QU): String;
    class function QuStrToQu(const _Val: String): TIDSConnect_QU;
    //false bei unbekanntem Code; _Qu ist dann PCE
    class function TryQuStrToQu(const _Val: String; out _Qu: TIDSConnect_QU): Boolean;
    class function DateStrToDate(const _Val : String) : TDate;
    class function TimeStrToTime(const _Val : String) : TTime;
    class function DateToDateStr(const _Val : TDate) : String;
    class function TimeToTimeStr(const _Val : TTime) : String;
    class function VersionFromStr(const _Val: String): TIDSConnect_Version;
    class function VersionToStr(const _Val: TIDSConnect_Version): String;
    //Version, mit der ein Warenkorb gesendet wird: 2.5 und 2.5.1 bleiben,
    //unbekannt wird 2.5.1, aeltere Versionen (1.3 bis 2.3) werden 2.5 - die
    //Unit erzeugt nur diese beiden Strukturen. XML-Element, Schema und das
    //WKS-Formularfeld muessen dieselbe Version melden.
    class function SendVersion(const _Val: TIDSConnect_Version): TIDSConnect_Version;
    class function StrToTechnClarification(const _Val: String) : TIDSConnect_TechnClarification;
    class function TechnClarificationToStr(_Val: TIDSConnect_TechnClarification) : String;
    class function StrMaxLength(const _Str: String; const _MaxLength: integer): String;
    class function ReferenzTypeFromStr(const _Val: String): TIDSConnect_ReferenzType;
    class function ReferenzTypeToStr(const _Val: TIDSConnect_ReferenzType): String;
    //Maskiert die fuer XML-Textinhalte und Attributwerte kritischen Zeichen
    class function XmlEscape(const _Val : String) : String;
    //Maskiert HTML-Sonderzeichen; noetig, weil das erzeugte XML in ein
    //<textarea> bzw. in value="..." eines HTML-Formulars eingebettet wird
    class function HtmlEscape(const _Val : String) : String;
    //Kuerzt auf _MaxLength und maskiert anschliessend fuer XML
    class function XmlText(const _Str: String; const _MaxLength: integer): String;
  end;

  TIDSConnect_WarenkorbHelper = class helper for TIDSConnect_Warenkorb
  private
    function  UnusedObj(_Node: TLandrixXmlNode): Boolean;
//    procedure ProtocolErrorObj(_Node: TLandrixXmlNode);
//    //procedure Protocol (const _Msg : String;_Type : TProtocolEventType);
//    procedure ProtocolUnknownObj(_Node : TLandrixXmlNode);
  private
    function  idsWarenkorb(_Node : TLandrixXmlNode) : Boolean;
    function  idsWarenkorbInfo(_Node : TLandrixXmlNode;_obj : TIDSConnect_WarenkorbInfo) : Boolean;
    function  idsOrder(_Node : TLandrixXmlNode; _Obj : TIDSConnect_Order) : Boolean;
    function  idsOrderInfo(_Node : TLandrixXmlNode;_Obj : TIDSConnect_OrderInfo) : Boolean;
    function  idsOrderItem(_Node : TLandrixXmlNode;_Obj : TIDSConnect_OrderItemList) : Boolean;
    function  idsReferenz(_Node : TLandrixXmlNode;_Obj : TIDSConnect_Referenz) : Boolean;
    function  idsRohstoffanteil(_Node : TLandrixXmlNode;_Obj : TIDSConnect_RohstoffanteilList) : Boolean;
    function  idsRefItems(_Node : TLandrixXmlNode;_Obj : TIDSConnect_OrderItem) : Boolean;
    function  idsSupplierInfo(_Node : TLandrixXmlNode;_Obj : TIDSConnect_SupplierInfo) : Boolean;
    function  idsCustomerInfo(_Node : TLandrixXmlNode;_Obj : TIDSConnect_CustomerInfo) : Boolean;
    function  idsDeliveryPlaceInfo(_Node : TLandrixXmlNode;_Obj : TIDSConnect_DeliveryPlaceInfo) : Boolean;
    function  idsAddress(_Node : TLandrixXmlNode;_Obj : TIDSConnect_Address) : Boolean;
  public
    function LoadFromFile(const _Filename : String) : Boolean;
    function LoadFromStream(_Stream : TStream) : Boolean;
    function SaveToString(_Val : TStringBuilder) : Boolean;
    //function SaveToFile(_Options : TIDS_Warenkorb_GenerateOptions;_Filename : String) : Boolean;
  end;

implementation

uses
  System.Math, System.DateUtils, System.StrUtils, Winapi.ShellAPI,
  Winapi.Windows, System.Net.HttpClient, System.Net.Mime,
  intf.IDSConnectDlgWebBrowser, intf.IDSConnectDlgWait;

const
  TIDSConnect_XMLNameSpace = 'http://www.itek.de/Shop-Anbindung/Warenkorb/';
  TIDSConnect_XMLSchemaSendShoppingCart_2_5      = TIDSConnect_XMLNameSpace+'warenkorb_senden_2_5.xsd';
  TIDSConnect_XMLSchemaSendShoppingCart_2_5_1    = TIDSConnect_XMLNameSpace+'warenkorb_senden_2_5_1.xsd';
  TIDSConnect_XMLSchemaReceiveShoppingCart_2_5   = TIDSConnect_XMLNameSpace+'warenkorb_empfangen_2_5.xsd';
  TIDSConnect_XMLSchemaReceiveShoppingCart_2_5_1 = TIDSConnect_XMLNameSpace+'warenkorb_empfangen_2_5_1.xsd';
  //Aktuelle Schnittstellenversion, die diese Unit erzeugt
  TIDSConnect_CurrentVersionStr = '2.5.1';

//Textinhalt eines Elements: alle Text- und CDATA-Teile, auch in
//untergeordneten Elementen, ohne Kommentare (TLandrixXmlNode.Text). Das
//fruehere IXMLNode.Text von MSXML warf dagegen eine Exception, sobald ein
//Element mehr als einen Textknoten hatte.
function NodeText(_Node : TLandrixXmlNode) : String;
begin
  if _Node = nil then
    Result := ''
  else
    Result := _Node.Text;
end;

//true, wenn die Bytes gueltiges UTF-8 sind und mindestens ein Nicht-ASCII-
//Zeichen enthalten
function IsNonAsciiUtf8(const _Bytes : TBytes; _Offset : Integer) : Boolean;
var
  i : Integer;
  lHasHigh : Boolean;
begin
  Result := false;
  lHasHigh := false;
  for i := _Offset to Length(_Bytes)-1 do
    if _Bytes[i] >= $80 then
    begin
      lHasHigh := true;
      break;
    end;
  if not lHasHigh then
    exit;
  Result := MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,
              PAnsiChar(@_Bytes[_Offset]),Length(_Bytes)-_Offset,nil,0) > 0;
end;

//Liest die in der XML-Deklaration angegebene Kodierung (nur innerhalb von
//<?xml ... ?>); '' wenn keine angegeben ist
function XmlDeclEncoding(const _Bytes : TBytes; _Offset : Integer;
  out _DeclStart, _DeclEnd : Integer) : String;
var
  lHead : String;
  p, lEnd, q : Integer;
  lQuote : Char;
begin
  Result := '';
  _DeclStart := 0;
  _DeclEnd := 0;
  //Die Deklaration besteht nur aus ASCII-Zeichen
  lHead := TEncoding.ASCII.GetString(_Bytes,_Offset,Min(Length(_Bytes)-_Offset,512));
  p := Pos('<?xml',lHead);
  if (p = 0) or (Trim(Copy(lHead,1,p-1)) <> '') then
    exit;
  lEnd := PosEx('?>',lHead,p);
  if lEnd = 0 then
    exit;
  _DeclStart := p;
  _DeclEnd := lEnd+1;
  q := PosEx('encoding',lHead,p);
  if (q = 0) or (q > lEnd) then
    exit;
  q := PosEx('=',lHead,q);
  if (q = 0) or (q > lEnd) then
    exit;
  Inc(q);
  //XML erlaubt um das Gleichheitszeichen beliebigen Leerraum, auch Tab und
  //Zeilenumbruch
  while (q < lEnd) and CharInSet(lHead[q],[' ',#9,#10,#13]) do
    Inc(q);
  lQuote := lHead[q];
  if not CharInSet(lQuote,['"','''']) then
    exit;
  p := PosEx(lQuote,lHead,q+1);
  if (p = 0) or (p > lEnd) then
    exit;
  Result := Trim(Copy(lHead,q+1,p-q-1));
end;

//Codepage zu einem Kodierungsnamen; 0 = UTF-8 oder unbekannt
function SingleByteCodePage(const _Name : String) : Integer;
var
  lName : String;
begin
  lName := LowerCase(_Name);
  if (lName = 'iso-8859-1') or (lName = 'latin1') or (lName = 'iso_8859-1') then
    Result := 28591
  else if lName = 'iso-8859-15' then
    Result := 28605
  else if (lName = 'windows-1252') or (lName = 'cp1252') then
    Result := 1252
  else if lName = 'windows-1250' then
    Result := 1250
  else if lName = 'iso-8859-2' then
    Result := 28592
  else
    Result := 0;
end;

//Liest eine Mengeneinheit. Ein unbekannter Code wurde frueher still zu PCE -
//aus 100 Rollen ("ROL") wurden so 100 Stueck. Der Ersatzwert bleibt, damit
//das Datenmodell gefuellt ist, aber der Aufrufer erfaehrt davon.
function ReadQu(const _Text, _Where : String) : TIDSConnect_QU;
var
  lText : String;
begin
  lText := Trim(_Text);
  if (not TIDSConnectHelper.TryQuStrToQu(lText,Result)) and (lText <> '') then
    TIDSConnect.ReportError(Format('Unbekannte Mengeneinheit "%s" (%s); als PCE (Stück) übernommen.',
                            [lText,_Where]),nil);
end;

//Stellt die XML-Deklaration eines bereits dekodierten Strings auf UTF-8 um
function XmlDeclToUtf8(const _Xml : String) : String;
var
  lDeclStart, lDeclEnd : Integer;
begin
  Result := _Xml;
  lDeclStart := Pos('<?xml',Result);
  if (lDeclStart > 0) and (Trim(Copy(Result,1,lDeclStart-1)) = '') then
  begin
    lDeclEnd := PosEx('?>',Result,lDeclStart);
    if lDeclEnd > 0 then
      Result := '<?xml version="1.0" encoding="UTF-8"?>'+
                Copy(Result,lDeclEnd+2,MaxInt);
  end;
end;

//Dekodiert eine Warenkorb-Rueckgabe zu einem String und gleicht die
//Deklaration auf UTF-8 an: TLandrixXmlDocument.LoadFromString liest den
//String als UTF-8, eine Deklaration mit Byte-Kodierung passte nicht dazu.
//Die eigene Erkennung bleibt, weil sie nachsichtiger ist als die Bibliothek
//(Windows-1250/ISO-8859-2, falsch deklariertes UTF-8). Frueher wurde nach "8859" oder "1252" irgendwo
//in den ersten 200 Zeichen gesucht und dann mit der Systemcodepage
//(TEncoding.ANSI) gelesen: eine Artikelnummer "B-1252" machte aus UTF-8
//Mojibake, und auf Systemen mit anderer Codepage wurde Latin-1 falsch gelesen.
function DecodeXmlBytes(const _Bytes : TBytes) : String;
var
  lEncoding : TEncoding;
  lBom, lCodePage, lDeclStart, lDeclEnd : Integer;
  lDeclared : String;
  lOwned : Boolean;
begin
  //Ein BOM hat Vorrang vor der Deklaration
  lEncoding := nil;
  lBom := TEncoding.GetBufferEncoding(_Bytes,lEncoding);
  if lBom > 0 then
  begin
    Result := lEncoding.GetString(_Bytes,lBom,Length(_Bytes)-lBom);
    lDeclared := '';
  end else
  begin
    lDeclared := XmlDeclEncoding(_Bytes,0,lDeclStart,lDeclEnd);
    lCodePage := SingleByteCodePage(lDeclared);
    //Deklariert eine Byte-Kodierung, gesendet wurde aber gueltiges UTF-8 mit
    //Umlauten: das kommt bei Shops vor und ist bei echtem Latin-1 praktisch
    //ausgeschlossen
    if (lCodePage <> 0) and IsNonAsciiUtf8(_Bytes,0) then
      lCodePage := 0;
    //Ohne Deklaration ist UTF-8 Standard; ungueltiges UTF-8 ist dann am
    //ehesten Windows-1252
    if (lCodePage = 0) and (lDeclared = '') and (Length(_Bytes) > 0) and
       (MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,PAnsiChar(@_Bytes[0]),
                            Length(_Bytes),nil,0) = 0) then
      lCodePage := 1252;
    lOwned := lCodePage <> 0;
    if lOwned then
      lEncoding := TEncoding.GetEncoding(lCodePage)
    else
      lEncoding := TEncoding.UTF8;
    try
      Result := lEncoding.GetString(_Bytes);
    finally
      if lOwned then
        lEncoding.Free;
    end;
  end;
  Result := XmlDeclToUtf8(Result);
end;

{ TIDSConnectHelper }

class function TIDSConnectHelper.RohstoffStrToRohstoff(const _Val: String): TIDSConnect_Rohstoff;
begin
  TryRohstoffStrToRohstoff(_Val,Result);
end;

class function TIDSConnectHelper.TryRohstoffStrToRohstoff(const _Val: String;
  out _Rohstoff: TIDSConnect_Rohstoff): Boolean;
var
  lVal : String;
  lRes : TIDSConnect_Rohstoff;
begin
  lVal := Trim(_Val);
  Result := true;
  if SameText('AL',lVal) then
    lRes := TIDSConnect_Rohstoff.idsConnectR_AL else
  if SameText('PB',lVal) then
    lRes := TIDSConnect_Rohstoff.idsConnectR_PB else
  if SameText('CR',lVal) then
    lRes := TIDSConnect_Rohstoff.idsConnectR_CR else
  if SameText('AU',lVal) then
    lRes := TIDSConnect_Rohstoff.idsConnectR_AU else
  if SameText('CD',lVal) then
    lRes := TIDSConnect_Rohstoff.idsConnectR_CD else
  if SameText('CU',lVal) then
    lRes := TIDSConnect_Rohstoff.idsConnectR_CU else
  if SameText('MG',lVal) then
    lRes := TIDSConnect_Rohstoff.idsConnectR_MG else
  if SameText('NI',lVal) then
    lRes := TIDSConnect_Rohstoff.idsConnectR_NI else
  if SameText('PL',lVal) then
    lRes := TIDSConnect_Rohstoff.idsConnectR_PL else
  if SameText('AG',lVal) then
    lRes := TIDSConnect_Rohstoff.idsConnectR_AG else
  if SameText('W',lVal) then
    lRes := TIDSConnect_Rohstoff.idsConnectR_W else
  if SameText('ZN',lVal) then
    lRes := TIDSConnect_Rohstoff.idsConnectR_ZN else
  if SameText('SN',lVal) then
    lRes := TIDSConnect_Rohstoff.idsConnectR_SN else
  if SameText('MS',lVal) then
    lRes := TIDSConnect_Rohstoff.idsConnectR_MS else
  if SameText('MK',lVal) then
    lRes := TIDSConnect_Rohstoff.idsConnectR_MK else
  begin
    lRes := TIDSConnect_Rohstoff.idsConnectR_CU;
    Result := false;
  end;
  _Rohstoff := lRes;
end;

class function TIDSConnectHelper.RohstoffToRohstoffStr(const _Val: TIDSConnect_Rohstoff): String;
begin
  Result := '';
  case _Val of
    TIDSConnect_Rohstoff.idsConnectR_AL : Result := 'AL';
    TIDSConnect_Rohstoff.idsConnectR_PB : Result := 'PB';
    TIDSConnect_Rohstoff.idsConnectR_CR : Result := 'CR';
    TIDSConnect_Rohstoff.idsConnectR_AU : Result := 'AU';
    TIDSConnect_Rohstoff.idsConnectR_CD : Result := 'CD';
    TIDSConnect_Rohstoff.idsConnectR_CU : Result := 'CU';
    TIDSConnect_Rohstoff.idsConnectR_MG : Result := 'MG';
    TIDSConnect_Rohstoff.idsConnectR_NI : Result := 'NI';
    TIDSConnect_Rohstoff.idsConnectR_PL : Result := 'PL';
    TIDSConnect_Rohstoff.idsConnectR_AG : Result := 'AG';
    TIDSConnect_Rohstoff.idsConnectR_W  : Result := 'W';
    TIDSConnect_Rohstoff.idsConnectR_ZN : Result := 'ZN';
    TIDSConnect_Rohstoff.idsConnectR_SN : Result := 'SN';
    TIDSConnect_Rohstoff.idsConnectR_MS : Result := 'MS';
    TIDSConnect_Rohstoff.idsConnectR_MK : Result := 'MK';
  end;
end;

class function TIDSConnectHelper.ReferenzTypeFromStr(const _Val: String): TIDSConnect_ReferenzType;
begin
  if _Val = '220' then
    Result := TIDSConnect_ReferenzType.idsConnectRefType_220 else
  if _Val = '231' then
    Result := TIDSConnect_ReferenzType.idsConnectRefType_231 else
  if _Val = '310' then
    Result := TIDSConnect_ReferenzType.idsConnectRefType_310 else
  if _Val = '315' then
    Result := TIDSConnect_ReferenzType.idsConnectRefType_315 else
    Result := TIDSConnect_ReferenzType.idsConnectRefType_None;
end;

class function TIDSConnectHelper.ReferenzTypeToStr(const _Val: TIDSConnect_ReferenzType): String;
begin
  Result := '';
  case _Val of
    TIDSConnect_ReferenzType.idsConnectRefType_220 : Result := '220';
    TIDSConnect_ReferenzType.idsConnectRefType_231 : Result := '231';
    TIDSConnect_ReferenzType.idsConnectRefType_310 : Result := '310';
    TIDSConnect_ReferenzType.idsConnectRefType_315 : Result := '315';
  end;
end;

class function TIDSConnectHelper.XmlEscape(const _Val: String): String;
var
  lClean : TStringBuilder;
  i : Integer;
  c : Char;
begin
  //Zeichen, die XML 1.0 nicht erlaubt, werden entfernt: Steuerzeichen ausser
  //Tab/LF/CR, #$FFFE/#$FFFF und einzelne Surrogate. Ein vertikaler Tab oder
  //Seitenvorschub aus Word-/RTF-Langtexten machte das gesendete XML frueher
  //nicht wohlgeformt, der Shop lehnte den ganzen Warenkorb ab.
  lClean := TStringBuilder.Create(Length(_Val));
  try
    i := 1;
    while i <= Length(_Val) do
    begin
      c := _Val[i];
      if (c >= #$D800) and (c <= #$DBFF) then
      begin
        //Nur ein vollstaendiges Surrogatpaar ist ein gueltiges Zeichen
        if (i < Length(_Val)) and (_Val[i+1] >= #$DC00) and (_Val[i+1] <= #$DFFF) then
        begin
          lClean.Append(c).Append(_Val[i+1]);
          Inc(i);
        end;
      end else
      if (c >= #$DC00) and (c <= #$DFFF) then
        //einzelnes niedriges Surrogat
      else
      if ((c < #32) and not CharInSet(c,[#9,#10,#13])) or (c = #$FFFE) or (c = #$FFFF) then
        //nicht erlaubt
      else
        lClean.Append(c);
      Inc(i);
    end;
    Result := lClean.ToString;
  finally
    lClean.Free;
  end;
  //Reihenfolge ist wichtig: & muss zuerst ersetzt werden
  Result := Result.Replace('&','&amp;',[rfReplaceAll])
                .Replace('<','&lt;',[rfReplaceAll])
                .Replace('>','&gt;',[rfReplaceAll])
                .Replace('"','&quot;',[rfReplaceAll])
                .Replace(#39,'&apos;',[rfReplaceAll]);
end;

class function TIDSConnectHelper.HtmlEscape(const _Val: String): String;
begin
  Result := _Val.Replace('&','&amp;',[rfReplaceAll])
                .Replace('<','&lt;',[rfReplaceAll])
                .Replace('>','&gt;',[rfReplaceAll])
                .Replace('"','&quot;',[rfReplaceAll]);
end;

class function TIDSConnectHelper.XmlText(const _Str: String; const _MaxLength: integer): String;
begin
  //Erst kuerzen (die Laengenbegrenzung der XSD gilt fuer den Klartext),
  //dann maskieren - sonst koennte eine Entity mittendrin abgeschnitten werden
  Result := XmlEscape(StrMaxLength(_Str,_MaxLength));
end;

class function TIDSConnectHelper.StrMaxLength(const _Str: String;
  const _MaxLength: integer): String;
begin
  Result := _Str;
  if (Length(_Str)>_MaxLength) then
  begin
    SetLength(Result,_MaxLength);
    //Ein abgeschnittenes Surrogatpaar wuerde ein ungueltiges Zeichen ergeben
    if (_MaxLength > 0) and (Result[_MaxLength] >= #$D800) and (Result[_MaxLength] <= #$DBFF) then
      SetLength(Result,_MaxLength-1);
  end;
end;

class function TIDSConnectHelper.StrToFloat(_Val: String; _Default: double): double;
var
  fs : TFormatSettings;
begin
  //Die XSD schreibt den Punkt als Dezimaltrenner vor. Frueher wurde hier auf
  //Komma umgestellt und mit den globalen FormatSettings geparst - auf Systemen
  //mit '.' als Dezimaltrenner (en-US) wurden dadurch alle Preise und Mengen 0.
  fs := TFormatSettings.Invariant;
  //Ein eingestreutes Komma wird der Toleranz halber weiterhin akzeptiert
  Result := StrToFloatDef(_Val.Replace(',','.',[rfReplaceAll]),_Default,fs);
end;

class function TIDSConnectHelper.StrToTechnClarification(
  const _Val: String): TIDSConnect_TechnClarification;
begin
  if SameText(_Val,'Yes') then
    Result := TIDSConnect_TechnClarification.idsConnectTc_Yes
  else
  if SameText(_Val,'No') then
    Result := TIDSConnect_TechnClarification.idsConnectTc_No
  else
    Result := TIDSConnect_TechnClarification.idsConnectTc_None;
end;

class function TIDSConnectHelper.TechnClarificationToStr(
  _Val: TIDSConnect_TechnClarification): String;
begin
  //idsConnectTc_None bedeutet "nicht angegeben" und darf nicht als aktives
  //"No" ausgegeben werden - der Serializer laesst das Element dann weg
  case _Val of
    idsConnectTc_Yes: Result := 'Yes';
    idsConnectTc_No:  Result := 'No';
    else Result := '';
  end;
end;

class function TIDSConnectHelper.TimeStrToTime(const _Val: String): TTime;
var
  h,m,s : Word;
  lVal : String;
  i : Integer;
begin
  //xs:time kann als 06:54:35, 06:54:35.123, 06:54:35Z oder 06:54:35+01:00
  //ankommen. StrToTimeDef scheiterte an allem ausser dem einfachsten Fall und
  //lieferte dann still 00:00:00 zurueck.
  Result := 0;
  lVal := Trim(_Val);
  if Length(lVal) < 8 then
    exit;
  //Zeitzone bzw. Millisekunden abschneiden
  i := 1;
  while (i <= Length(lVal)) and (CharInSet(lVal[i],['0'..'9',':'])) do
    Inc(i);
  lVal := Copy(lVal,1,i-1);
  if Length(lVal) < 8 then
    exit;
  h := StrToIntDef(Copy(lVal,1,2),99);
  m := StrToIntDef(Copy(lVal,4,2),99);
  s := StrToIntDef(Copy(lVal,7,2),99);
  if (h > 23) or (m > 59) or (s > 59) then
    exit;
  Result := EncodeTime(h,m,s,0);
end;

class function TIDSConnectHelper.TimeToTimeStr(const _Val: TTime): String;
begin
  //TimeToStr war locale-abhaengig und lieferte auf en-US z.B. "6:54:35 AM",
  //was gegen xs:time verstoesst
  Result := FormatDateTime('hh:nn:ss',_Val,TFormatSettings.Invariant);
end;

class function TIDSConnectHelper.VersionFromStr(
  const _Val: String): TIDSConnect_Version;
var
  lVal : String;
begin
  //Auch aeltere Versionen werden erkannt - fruehere Antworten mit
  //<Version>1.3</Version> liefen sonst auf Unkown und erzeugten beim
  //erneuten Senden ein leeres <Version>-Element.
  //Leerraum um den Wert ist in XML zulaessig (" 2.5 " ergab frueher Unkown)
  lVal := Trim(_Val);
  if SameText(lVal,'2.5.1') then
    Result := TIDSConnect_Version.idsConnectVersion_2_5_1 else
  if SameText(lVal,'2.5') then
    Result := TIDSConnect_Version.idsConnectVersion_2_5 else
  if SameText(lVal,'2.3') then
    Result := TIDSConnect_Version.idsConnectVersion_2_3 else
  if SameText(lVal,'2.0') then
    Result := TIDSConnect_Version.idsConnectVersion_2_0 else
  if SameText(lVal,'1.3') then
    Result := TIDSConnect_Version.idsConnectVersion_1_3 else
    Result := TIDSConnect_Version.idsConnectVersion_Unkown;
end;

class function TIDSConnectHelper.SendVersion(
  const _Val: TIDSConnect_Version): TIDSConnect_Version;
begin
  case _Val of
    idsConnectVersion_2_5,
    idsConnectVersion_2_5_1 : Result := _Val;
    idsConnectVersion_1_3,
    idsConnectVersion_2_0,
    idsConnectVersion_2_3   : Result := idsConnectVersion_2_5;
    else                      Result := idsConnectVersion_2_5_1;
  end;
end;

class function TIDSConnectHelper.VersionToStr(
  const _Val: TIDSConnect_Version): String;
begin
  case _val of
    idsConnectVersion_1_3:   Result := '1.3';
    idsConnectVersion_2_0:   Result := '2.0';
    idsConnectVersion_2_3:   Result := '2.3';
    idsConnectVersion_2_5:   Result := '2.5';
    idsConnectVersion_2_5_1: Result := '2.5.1';
    //Unbekannte Version: die aktuelle Version ausgeben, damit kein leeres
    //Element entsteht, das die XSD-Enumeration verletzen wuerde
    else Result := '2.5.1';
  end;
end;

class function TIDSConnectHelper.QuToQuStrInternal(const _Val: TIDSConnect_QU): String;
begin
  Result := '';
  case _Val of
    TIDSConnect_QU.idsConnectQu_CMQ : Result := 'ccm';         // Kubik-Zentimeter
    TIDSConnect_QU.idsConnectQu_CMK : Result := 'qcm';        // Quadrat-Zentimeter
    TIDSConnect_QU.idsConnectQu_CMT : Result := 'cm';        // Zentimeter
    TIDSConnect_QU.idsConnectQu_DZN : Result := 'dtzd';        // Dutzend
    TIDSConnect_QU.idsConnectQu_GRM : Result := 'g';        // Gramm
    TIDSConnect_QU.idsConnectQu_HLT : Result := 'hl';        // Hekto-Liter
    TIDSConnect_QU.idsConnectQu_KGM : Result := 'kg';        // Kilogramm
    TIDSConnect_QU.idsConnectQu_KTM : Result := 'km';        // Kilometer
    TIDSConnect_QU.idsConnectQu_LTR : Result := 'l';        // Liter
    TIDSConnect_QU.idsConnectQu_MMT : Result := 'mm';        // Millimeter
    TIDSConnect_QU.idsConnectQu_MTK : Result := 'qm';        // Quadrat-Meter
    TIDSConnect_QU.idsConnectQu_MTQ : Result := 'cbm';        // Kubik-Meter
    TIDSConnect_QU.idsConnectQu_MTR : Result := 'm';        // Meter
    TIDSConnect_QU.idsConnectQu_PCE : Result := 'Stck';        // Stueck
    TIDSConnect_QU.idsConnectQu_PR  : Result := 'Paar' ;        // Paar
    TIDSConnect_QU.idsConnectQu_SET : Result := 'Set';        // Satz
    TIDSConnect_QU.idsConnectQu_TNE : Result := 't';        // Tonne
  end;
end;

class function TIDSConnectHelper.QuToQuStr(const _Val: TIDSConnect_QU): String;
begin
  Result := '';
  case _Val of
    TIDSConnect_QU.idsConnectQu_CMQ : Result := 'CMQ';
    TIDSConnect_QU.idsConnectQu_CMK : Result := 'CMK';
    TIDSConnect_QU.idsConnectQu_CMT : Result := 'CMT';
    TIDSConnect_QU.idsConnectQu_DZN : Result := 'DZN';
    TIDSConnect_QU.idsConnectQu_GRM : Result := 'GRM';
    TIDSConnect_QU.idsConnectQu_HLT : Result := 'HLT';
    TIDSConnect_QU.idsConnectQu_KGM : Result := 'KGM';
    TIDSConnect_QU.idsConnectQu_KTM : Result := 'KTM';
    TIDSConnect_QU.idsConnectQu_LTR : Result := 'LTR';
    TIDSConnect_QU.idsConnectQu_MMT : Result := 'MMT';
    TIDSConnect_QU.idsConnectQu_MTK : Result := 'MTK';
    TIDSConnect_QU.idsConnectQu_MTQ : Result := 'MTQ';
    TIDSConnect_QU.idsConnectQu_MTR : Result := 'MTR';
    TIDSConnect_QU.idsConnectQu_PCE : Result := 'PCE';
    TIDSConnect_QU.idsConnectQu_PR  : Result := 'PR' ;
    TIDSConnect_QU.idsConnectQu_SET : Result := 'SET';
    TIDSConnect_QU.idsConnectQu_TNE : Result := 'TNE';
  end;
end;

class function TIDSConnectHelper.DateStrToDate(const _Val: String): TDate;
begin
  Result := 0;
  //xs:date erlaubt einen Zeitzonen-Zusatz (2022-11-18Z, 2022-11-18+01:00),
  //deshalb wird nur der Datumsteil ausgewertet
  if Length(_Val) < 10 then
    exit;
  try
    Result := EncodeDate(StrToIntDef(Copy(_Val,1,4),0),StrToIntDef(Copy(_Val,6,2),0),StrToIntDef(Copy(_Val,9,2),0));
  except
    Result := 0;
  end;
end;

class function TIDSConnectHelper.DateToDateStr(const _Val: TDate): String;
begin
  Result := IntToStr(YearOf(_Val))+'-'+
            IfThen(MonthOf(_Val)<10,'0','')+ IntToStr(MonthOf(_Val))+'-'+
            IfThen(DayOf(_Val)<10,'0','')+ IntToStr(DayOf(_Val));
end;

class function TIDSConnectHelper.FloatToStr(const _Val: double;
  _Decimals: Integer): String;
begin
  //Invariante FormatSettings statt globaler - die XSD verlangt den Punkt
  Result := Format('%.*f',[_Decimals,_Val],TFormatSettings.Invariant);
end;

class function TIDSConnectHelper.QuStrToQu(const _Val: String): TIDSConnect_QU;
begin
  TryQuStrToQu(_Val,Result);
end;

class function TIDSConnectHelper.TryQuStrToQu(const _Val: String;
  out _Qu: TIDSConnect_QU): Boolean;
var
  lVal : String;
  lRes : TIDSConnect_QU;
begin
  lVal := Trim(_Val);
  Result := true;
  if SameText('CMQ',lVal) then
    lRes := TIDSConnect_QU.idsConnectQu_CMQ else
  if SameText('CMK',lVal) then
    lRes := TIDSConnect_QU.idsConnectQu_CMK else
  if SameText('CMT',lVal) then
    lRes := TIDSConnect_QU.idsConnectQu_CMT else
  if SameText('DZN',lVal) then
    lRes := TIDSConnect_QU.idsConnectQu_DZN else
  if SameText('GRM',lVal) then
    lRes := TIDSConnect_QU.idsConnectQu_GRM else
  if SameText('HLT',lVal) then
    lRes := TIDSConnect_QU.idsConnectQu_HLT else
  if SameText('KGM',lVal) then
    lRes := TIDSConnect_QU.idsConnectQu_KGM else
  if SameText('KTM',lVal) then
    lRes := TIDSConnect_QU.idsConnectQu_KTM else
  if SameText('LTR',lVal) then
    lRes := TIDSConnect_QU.idsConnectQu_LTR else
  if SameText('MMT',lVal) then
    lRes := TIDSConnect_QU.idsConnectQu_MMT else
  if SameText('MTK',lVal) then
    lRes := TIDSConnect_QU.idsConnectQu_MTK else
  if SameText('MTQ',lVal) then
    lRes := TIDSConnect_QU.idsConnectQu_MTQ else
  if SameText('MTR',lVal) then
    lRes := TIDSConnect_QU.idsConnectQu_MTR else
  if SameText('PCE',lVal) then
    lRes := TIDSConnect_QU.idsConnectQu_PCE else
  if SameText('PR',lVal) then
    lRes := TIDSConnect_QU.idsConnectQu_PR else
  if SameText('SET',lVal) then
    lRes := TIDSConnect_QU.idsConnectQu_SET else
  if SameText('TNE',lVal) then
    lRes := TIDSConnect_QU.idsConnectQu_TNE else
  begin
    lRes := TIDSConnect_QU.idsConnectQu_PCE;
    Result := false;
  end;
  _Qu := lRes;
end;

{ TIDSConnect_WarenkorbHelper }

function TIDSConnect_WarenkorbHelper.idsAddress(_Node: TLandrixXmlNode;
  _Obj: TIDSConnect_Address): Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to _Node.ChildCount -1 do
  begin
    if UnusedObj(_Node.Children[i]) then continue;

    if SameText(_Node.Children[i].LocalName,'Name1') then
    begin
      _Obj.Name1 := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Name2') then
    begin
      _Obj.Name2 := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Name3') then
    begin
      _Obj.Name3 := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Name4') then
    begin
      _Obj.Name4 := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Street') then
    begin
      _Obj.Street := NodeText(_Node.Children[i]);
      //Damit Aufrufer, die nur Street1 auswerten, auch 2.5-Daten sehen
      if _Obj.Street1 = '' then
        _Obj.Street1 := _Obj.Street;
      continue;
    end;
    //Street1..Street3 ersetzen ab IDS 2.5.1 das einzelne Street-Element
    if SameText(_Node.Children[i].LocalName,'Street1') then
    begin
      _Obj.Street1 := NodeText(_Node.Children[i]);
      if _Obj.Street = '' then
        _Obj.Street := _Obj.Street1;
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Street2') then
    begin
      _Obj.Street2 := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Street3') then
    begin
      _Obj.Street3 := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'PCode') then
    begin
      _Obj.PCode := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'City') then
    begin
      _Obj.City := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Country') then
    begin
      _Obj.Country := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'ILN') then
    begin
      _Obj.ILN := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Contact') then
    begin
      _Obj.Contact := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Phone') then
    begin
      _Obj.Phone := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Fax') then
    begin
      _Obj.Fax := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Email') then
    begin
      _Obj.Email := NodeText(_Node.Children[i]);
      continue;
    end;
    //ProtocolUnknownObj(_Node.Children[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsCustomerInfo(_Node: TLandrixXmlNode;
  _Obj: TIDSConnect_CustomerInfo): Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to _Node.ChildCount -1 do
  begin
    if UnusedObj(_Node.Children[i]) then continue;

    if SameText(_Node.Children[i].LocalName,'IDNo') then
    begin
      _Obj.IDNo := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Address') then
    begin
      Result := idsAddress(_Node.Children[i],_Obj.Address);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.Children[i]);
        break;
      end else
        continue;
    end;

    //ProtocolUnknownObj(_Node.Children[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsDeliveryPlaceInfo(_Node: TLandrixXmlNode;
  _Obj: TIDSConnect_DeliveryPlaceInfo): Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to _Node.ChildCount -1 do
  begin
    if UnusedObj(_Node.Children[i]) then continue;

    if SameText(_Node.Children[i].LocalName,'IDNo') then
    begin
      _Obj.IDNo := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Address') then
    begin
      Result := idsAddress(_Node.Children[i],_Obj.Address);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.Children[i]);
        break;
      end else
        continue;
    end;
    //Geo-Daten ab IDS 2.5.1
    if SameText(_Node.Children[i].LocalName,'GeoLat') then
    begin
      _Obj.GeoLat := TIDSConnectHelper.StrToFloat(NodeText(_Node.Children[i]),0);
      _Obj.HasGeoLocation := true;
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'GeoLang') then
    begin
      _Obj.GeoLang := TIDSConnectHelper.StrToFloat(NodeText(_Node.Children[i]),0);
      _Obj.HasGeoLocation := true;
      continue;
    end;

    //ProtocolUnknownObj(_Node.Children[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsOrder(_Node: TLandrixXmlNode; _Obj : TIDSConnect_Order): Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to _Node.ChildCount -1 do
  begin
    if UnusedObj(_Node.Children[i]) then continue;

    if SameText(_Node.Children[i].LocalName,'OrderInfo') then
    begin
      Result := idsOrderInfo(_Node.Children[i],_Obj.OrderInfo);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.Children[i]);
        break;
      end else
        continue;
     end;

    if SameText(_Node.Children[i].LocalName,'SupplierInfo') then
    begin
      Result := idsSupplierInfo(_Node.Children[i],_Obj.SupplierInfo);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.Children[i]);
        break;
      end else
        continue;
     end;

    if SameText(_Node.Children[i].LocalName,'CustomerInfo') then
    begin
      Result := idsCustomerInfo(_Node.Children[i],_Obj.CustomerInfo);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.Children[i]);
        break;
      end else
        continue;
     end;

    if SameText(_Node.Children[i].LocalName,'DeliveryPlaceInfo') then
    begin
      Result := idsDeliveryPlaceInfo(_Node.Children[i],_Obj.DeliveryPlaceInfo);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.Children[i]);
        break;
      end else
        continue;
     end;

    if SameText(_Node.Children[i].LocalName,'OrderItem') then
    begin
      Result := idsOrderItem(_Node.Children[i],_Obj.OrderItems);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.Children[i]);
        break;
      end else
        continue;
    end;

    //ProtocolUnknownObj(_Node.Children[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsReferenz(_Node: TLandrixXmlNode;
  _Obj: TIDSConnect_Referenz): Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to _Node.ChildCount -1 do
  begin
    if UnusedObj(_Node.Children[i]) then continue;

    if SameText(_Node.Children[i].LocalName,'ReferenzNumber') then
    begin
      _Obj.ReferenzNumber := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'ReferenzDate') then
    begin
      _Obj.ReferenzDate := TIDSConnectHelper.DateStrToDate(NodeText(_Node.Children[i]));
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'ReferenzType') then
    begin
      _Obj.ReferenzType := TIDSConnectHelper.ReferenzTypeFromStr(NodeText(_Node.Children[i]));
      continue;
    end;
    //ReferenzLine gibt es nur in den Positionsdaten
    if SameText(_Node.Children[i].LocalName,'ReferenzLine') and (_Obj is TIDSConnect_ReferenzPos) then
    begin
      TIDSConnect_ReferenzPos(_Obj).ReferenzLine := NodeText(_Node.Children[i]);
      continue;
    end;

    //ProtocolUnknownObj(_Node.Children[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsOrderInfo(_Node: TLandrixXmlNode;
  _Obj: TIDSConnect_OrderInfo): Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to _Node.ChildCount -1 do
  begin
    if UnusedObj(_Node.Children[i]) then continue;

    //Referenzen ersetzen ab IDS 2.5.1 InquiryNo/OfferNo/PartNo/OrderConfNo
    if SameText(_Node.Children[i].LocalName,'Referenz') then
    begin
      Result := idsReferenz(_Node.Children[i],_Obj.Referenzen.AddItem);
      if not Result then
        break
      else
        continue;
    end;
    if SameText(_Node.Children[i].LocalName,'InquiryNo') then
    begin
      _Obj.InquiryNo := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'OfferNo') then
    begin
      _Obj.OfferNo := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'PartNo') then
    begin
      _Obj.PartNo := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'OrderConfNo') then
    begin
      _Obj.OrderConfNo := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'DeliveryWeek') then
    begin
      _Obj.DeliveryWeek := StrToIntDef(NodeText(_Node.Children[i]),0);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'DeliveryYear') then
    begin
      _Obj.DeliveryYear := StrToIntDef(NodeText(_Node.Children[i]),0);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'DeliveryDate') then
    begin
      _Obj.DeliveryDate := TIDSConnectHelper.DateStrToDate(NodeText(_Node.Children[i]));
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'ModeOfShipment') then
    begin
      if (Pos('LIEFERUNG',UpperCase(NodeText(_Node.Children[i])))>0) then
        _Obj.ModeOfShipment := idsConnectMos_Lieferung
      else
        _Obj.ModeOfShipment := idsConnectMos_Abholung;
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'ZusatzText') then
    begin
      _Obj.ZusatzText := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Kommission') then
    begin
      _Obj.Kommission := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Cur') then
    begin
      _Obj.Cur := NodeText(_Node.Children[i]);
      continue;
    end;

    //ProtocolUnknownObj(_Node.Children[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsOrderItem(_Node: TLandrixXmlNode;
  _Obj: TIDSConnect_OrderItemList): Boolean;
var
  i : Integer;
  itm : TIDSConnect_OrderItem;
begin
  Result := true;
  itm := _Obj.AddItem;

  for i := 0 to _Node.ChildCount -1 do
  begin
    if UnusedObj(_Node.Children[i]) then continue;

    if SameText(_Node.Children[i].LocalName,'ItemChara') then
    begin
      if SameText('alternate',NodeText(_Node.Children[i])) then
        itm.ItemChara := idsConnectIc_alternate
      else
      if SameText('provis',NodeText(_Node.Children[i])) then
        itm.ItemChara := idsConnectIc_provis
      else
        itm.ItemChara := idsConnectIc_normal;
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'RefItems') then
    begin
      Result := idsRefItems(_Node.Children[i],itm);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.Children[i]);
        break;
      end else
        continue;
    end;
    if SameText(_Node.Children[i].LocalName,'EAN') then
    begin
      itm.EAN := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'ManufacturerID') then
    begin
      itm.ManufacturerID := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'ManufacturerIDType') then
    begin
      itm.ManufacturerIDType := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'ArtNo') then
    begin
      itm.ArtNo := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Qty') then
    begin
      itm.Qty := TIDSConnectHelper.StrToFloat(NodeText(_Node.Children[i]),0);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'QU') then
    begin
      itm.QU := ReadQu(NodeText(_Node.Children[i]),Format('Position %d',[_Obj.Count]));
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Kurztext') then
    begin
      itm.Kurztext := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Langtext') then
    begin
      itm.Langtext := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'OfferPrice') then
    begin
      itm.OfferPrice := TIDSConnectHelper.StrToFloat(NodeText(_Node.Children[i]),0);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'NetPrice') then
    begin
      itm.NetPrice := TIDSConnectHelper.StrToFloat(NodeText(_Node.Children[i]),0);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'PriceBasis') then
    begin
      itm.PriceBasis := TIDSConnectHelper.StrToFloat(NodeText(_Node.Children[i]),0);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'VAT') then
    begin
      itm.VAT := TIDSConnectHelper.StrToFloat(NodeText(_Node.Children[i]),0);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'TechnClarification') then
    begin
      itm.TechnClarification := TIDSConnectHelper.StrToTechnClarification(NodeText(_Node.Children[i]));
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Hinweis') then
    begin
      itm.Hinweis := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Fehlercode') then
    begin
      if SameTExt(NodeText(_Node.Children[i]),'1') then
        itm.Fehlercode := idsConnectFc_1;
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Fehlertext') then
    begin
      itm.Fehlertext := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Zuschlag') then
    begin
      itm.Zuschlag := TIDSConnectHelper.StrToFloat(NodeText(_Node.Children[i]),0);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Rohstoffanteil') then
    begin
      Result := idsRohstoffanteil(_Node.Children[i],itm.Rohstoffanteile);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.Children[i]);
        break;
      end else
        continue;
    end;
    //Divers wurde bisher nie eingelesen
    if SameText(_Node.Children[i].LocalName,'Divers') then
    begin
      itm.Divers := SameText(NodeText(_Node.Children[i]),'true') or (NodeText(_Node.Children[i]) = '1');
      continue;
    end;
    //ab IDS 2.5.1
    if SameText(_Node.Children[i].LocalName,'SumMaterialSurcharges') then
    begin
      itm.SumMaterialSurcharges := TIDSConnectHelper.StrToFloat(NodeText(_Node.Children[i]),0);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'DiscountableAmount') then
    begin
      itm.DiscountableAmount := TIDSConnectHelper.StrToFloat(NodeText(_Node.Children[i]),0);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Referenz') then
    begin
      Result := idsReferenz(_Node.Children[i],itm.Referenzen.AddItem);
      if not Result then
        break
      else
        continue;
    end;

    //ProtocolUnknownObj(_Node.Children[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsRefItems(_Node: TLandrixXmlNode;
  _Obj: TIDSConnect_OrderItem): Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to _Node.ChildCount -1 do
  begin
    if UnusedObj(_Node.Children[i]) then continue;

    if SameText(_Node.Children[i].LocalName,'Customer') then
    begin
      _Obj.RefItems_Customer := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'CustomerSubNo') then
    begin
      _Obj.RefItems_CustomerSubNo := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Supplier') then
    begin
      _Obj.RefItems_Supplier := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'SupplierSubNo') then
    begin
      _Obj.RefItems_SupplierSubNo := NodeText(_Node.Children[i]);
      continue;
    end;

    //ProtocolUnknownObj(_Node.Children[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsRohstoffanteil(_Node: TLandrixXmlNode;
  _Obj: TIDSConnect_RohstoffanteilList): Boolean;
var
  i : Integer;
  itm : TIDSConnect_Rohstoffanteil;
  lText : String;
begin
  Result := true;
  itm := _Obj.AddItem;

  for i := 0 to _Node.ChildCount -1 do
  begin
    if UnusedObj(_Node.Children[i]) then continue;

    if SameText(_Node.Children[i].LocalName,'Rohstoff') then
    begin
      lText := Trim(NodeText(_Node.Children[i]));
      if (not TIDSConnectHelper.TryRohstoffStrToRohstoff(lText,itm.Rohstoff)) and (lText <> '') then
        TIDSConnect.ReportError(Format('Unbekannter Rohstoff "%s" in einem Rohstoffanteil; als CU (Kupfer) übernommen.',
                                [lText]),nil);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Gewichtsanteilswert') then
    begin
      itm.Gewichtsanteilswert := TIDSConnectHelper.StrToFloat(NodeText(_Node.Children[i]),0);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Gewichtsanteilseinheit') then
    begin
      itm.Gewichtsanteilseinheit := ReadQu(NodeText(_Node.Children[i]),'Gewichtsanteilseinheit eines Rohstoffanteils');
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Basiswert') then
    begin
      itm.Basiswert := TIDSConnectHelper.StrToFloat(NodeText(_Node.Children[i]),0);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Basiseinheit') then
    begin
      itm.Basiseinheit := ReadQu(NodeText(_Node.Children[i]),'Basiseinheit eines Rohstoffanteils');
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Basisnotierung') then
    begin
      itm.Basisnotierung := TIDSConnectHelper.StrToFloat(NodeText(_Node.Children[i]),0);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'NotierungAktuell') then
    begin
      itm.NotierungAktuell := TIDSConnectHelper.StrToFloat(NodeText(_Node.Children[i]),0);
      continue;
    end;

    //ProtocolUnknownObj(_Node.Children[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsSupplierInfo(_Node: TLandrixXmlNode;
  _Obj: TIDSConnect_SupplierInfo): Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to _Node.ChildCount -1 do
  begin
    if UnusedObj(_Node.Children[i]) then continue;

    if SameText(_Node.Children[i].LocalName,'IDNo') then
    begin
      _Obj.IDNo := NodeText(_Node.Children[i]);
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Address') then
    begin
      Result := idsAddress(_Node.Children[i],_Obj.Address);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.Children[i]);
        break;
      end else
        continue;
    end;

    //ProtocolUnknownObj(_Node.Children[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsWarenkorb(_Node: TLandrixXmlNode): Boolean;
var
  i : Integer;
begin
  Result := false;

  for i := 0 to _Node.ChildCount -1 do
  begin
    if UnusedObj(_Node.Children[i]) then continue;
    if SameText(_Node.Children[i].LocalName,'WarenkorbInfo') then
    begin
      Result := idsWarenkorbInfo(_Node.Children[i],WarenkorbInfo);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.Children[i]);
        break;
      end else
        continue;
     end;

    if SameText(_Node.Children[i].LocalName,'Order') then
    begin
      Result := idsOrder(_Node.Children[i],Order);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.Children[i]);
        break;
      end else
        continue;
     end;

     //ProtocolUnknownObj(_Node.Children[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsWarenkorbInfo(_Node: TLandrixXmlNode;
  _obj: TIDSConnect_WarenkorbInfo): Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to _Node.ChildCount -1 do
  begin
    if UnusedObj(_Node.Children[i]) then continue;
    if SameText(_Node.Children[i].LocalName,'Date') then
    begin
      _Obj.Date := TIDSConnectHelper.DateStrToDate(NodeText(_Node.Children[i]));
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Time') then
    begin
      _Obj.Time := TIDSConnectHelper.TimeStrToTime(NodeText(_Node.Children[i]));
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'RueckgabeKZ') then
    begin
      if (Pos('BESTELLUNG',UpperCase(NodeText(_Node.Children[i])))>0) then
        _Obj.RueckgabeKZ := idsConnectRKZ_WarenkorbrueckgabeMitBestellung
      else
        _Obj.RueckgabeKZ := idsConnectRKZ_Warenkorbrueckgabe;
      continue;
    end;
    if SameText(_Node.Children[i].LocalName,'Version') then
    begin
      _Obj.Version := TIDSConnectHelper.VersionFromStr(NodeText(_Node.Children[i]));
      continue;
    end;
    //ProtocolUnknownObj(_Node.Children[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.LoadFromFile(
  const _Filename: String): Boolean;
begin
  Result := false;
  if not FileExists(_Filename) then
    exit;
  var str : TMemoryStream := TMemoryStream.Create;
  try
    str.LoadFromFile(_Filename);
    //Der Rueckgabewert wurde hier frueher verworfen - LoadFromFile lieferte
    //dadurch selbst bei erfolgreichem Einlesen immer false
    Result := LoadFromStream(str);
  finally
    str.Free;
  end;
end;

function TIDSConnect_WarenkorbHelper.LoadFromStream(_Stream: TStream): Boolean;
var
  lBuffer : TLandrixXmlDocument;
  lBytes : TBytes;
  lXml : String;
  lCart : TIDSConnect_Warenkorb;
begin
  Result := false;
  //Frueher wurde hier zuerst Clear aufgerufen: scheiterte das Einlesen, war
  //der Warenkorb des Aufrufers leer - bei WKS also der gesendete Warenkorb.
  //Jetzt wird in einen eigenen Warenkorb gelesen und nur bei Erfolg
  //uebernommen.
  lCart := nil;
  lBuffer := TLandrixXmlDocument.Create;
  try
  try
    _Stream.Position := 0;
    SetLength(lBytes,_Stream.Size);
    if Length(lBytes) > 0 then
      _Stream.ReadBuffer(lBytes[0],Length(lBytes));
    _Stream.Position := 0;

    lXml := DecodeXmlBytes(lBytes);
    if ContainsText(lXml,'<head/>') then
      lXml := ReplaceText(lXml,'<head/>','');
    lBuffer.LoadFromString(lXml);

    if lBuffer.Root = nil then
      exit;

    if SameText(lBuffer.Root.LocalName,'Warenkorb') then
    begin
      lCart := TIDSConnect_Warenkorb.Create;
      Result := lCart.idsWarenkorb(lBuffer.Root);
      if Result then
        Assign(lCart);
    end;
  except
    on E:Exception do
    begin
      //Parserfehler wurden hier frueher spurlos verschluckt
      Result := false;
      TIDSConnect.ReportError('Der Warenkorb konnte nicht gelesen werden: '+E.Message,E);
    end;
  end;
  finally
    lCart.Free;
    lBuffer.Free;
  end;
end;

function TIDSConnect_WarenkorbHelper.SaveToString(
  _Val: TStringBuilder): Boolean;
var
  i : Integer;

  lIs251 : Boolean;

  procedure OutAddress(_Obj : TIDSConnect_Address);
  var
    lStreet1 : String;
    lPCodeLen : Integer;
  begin
    if (_Obj.Name1 <> '') then _Val.AppendFormat('  '+'<Name1>%s</Name1>'+#13#10,[TIDSConnectHelper.XmlText(_Obj.Name1,40)]);
    if (_Obj.Name2 <> '') then _Val.AppendFormat('  '+'<Name2>%s</Name2>'+#13#10,[TIDSConnectHelper.XmlText(_Obj.Name2,40)]);
    if (_Obj.Name3 <> '') then _Val.AppendFormat('  '+'<Name3>%s</Name3>'+#13#10,[TIDSConnectHelper.XmlText(_Obj.Name3,40)]);
    //Name4 gibt es ab IDS 2.5.1 nicht mehr
    if _Obj.Name4 <> '' then
    begin
      if lIs251 then
        TIDSConnect.ReportError('Name4 gibt es ab IDS 2.5.1 nicht mehr und wurde nicht gesendet ("'+
                                _Obj.Name4+'").',nil)
      else
        _Val.AppendFormat('  '+'<Name4>%s</Name4>'+#13#10,[TIDSConnectHelper.XmlText(_Obj.Name4,40)]);
    end;

    //Street1 hat Vorrang; wer nur das alte Street-Feld befuellt hat, wird
    //trotzdem korrekt serialisiert
    lStreet1 := _Obj.Street1;
    if lStreet1 = '' then
      lStreet1 := _Obj.Street;
    if lIs251 then
    begin
      if (lStreet1 <> '') then _Val.AppendFormat('  '+'<Street1>%s</Street1>'+#13#10,[TIDSConnectHelper.XmlText(lStreet1,40)]);
      if (_Obj.Street2 <> '') then _Val.AppendFormat('  '+'<Street2>%s</Street2>'+#13#10,[TIDSConnectHelper.XmlText(_Obj.Street2,40)]);
      if (_Obj.Street3 <> '') then _Val.AppendFormat('  '+'<Street3>%s</Street3>'+#13#10,[TIDSConnectHelper.XmlText(_Obj.Street3,40)]);
    end else
      if (lStreet1 <> '') then _Val.AppendFormat('  '+'<Street>%s</Street>'+#13#10,[TIDSConnectHelper.XmlText(lStreet1,40)]);

    //Die PLZ ist ab IDS 2.5.1 auf 9 Stellen begrenzt
    if lIs251 then
      lPCodeLen := 9
    else
      lPCodeLen := 20;
    if (_Obj.PCode <> '') then _Val.AppendFormat('  '+'<PCode>%s</PCode>'+#13#10,[TIDSConnectHelper.XmlText(_Obj.PCode,lPCodeLen)]);
    if (_Obj.City <> '') then _Val.AppendFormat('  '+'<City>%s</City>'+#13#10,[TIDSConnectHelper.XmlText(_Obj.City,40)]);
    if (_Obj.Country <> '') then _Val.AppendFormat('  '+'<Country>%s</Country>'+#13#10,[TIDSConnectHelper.XmlText(_Obj.Country,40)]);
    if (_Obj.ILN <> '') then _Val.AppendFormat('  '+'<ILN>%s</ILN>'+#13#10,[TIDSConnectHelper.XmlText(_Obj.ILN,20)]);
    if (_Obj.Contact <> '') then _Val.AppendFormat('  '+'<Contact>%s</Contact>'+#13#10,[TIDSConnectHelper.XmlText(_Obj.Contact,40)]);
    if (_Obj.Phone <> '') then _Val.AppendFormat('  '+'<Phone>%s</Phone>'+#13#10,[TIDSConnectHelper.XmlText(_Obj.Phone,20)]);
    if (_Obj.Fax <> '') then _Val.AppendFormat('  '+'<Fax>%s</Fax>'+#13#10,[TIDSConnectHelper.XmlText(_Obj.Fax,20)]);
    if (_Obj.Email <> '') then _Val.AppendFormat('  '+'<Email>%s</Email>'+#13#10,[TIDSConnectHelper.XmlText(_Obj.Email,256)]);
  end;

  //Adressbloecke werden ausgegeben, sobald irgendein Feld gefuellt ist
  function AddressIsFilled(_Obj : TIDSConnect_Address) : Boolean;
  begin
    Result := (_Obj.Name1 <> '') or (_Obj.Name2 <> '') or (_Obj.Name3 <> '') or
              (_Obj.Name4 <> '') or (_Obj.Street <> '') or (_Obj.Street1 <> '') or
              (_Obj.Street2 <> '') or (_Obj.Street3 <> '') or (_Obj.PCode <> '') or
              (_Obj.City <> '') or (_Obj.Country <> '') or (_Obj.ILN <> '') or
              (_Obj.Contact <> '') or (_Obj.Phone <> '') or (_Obj.Fax <> '') or
              (_Obj.Email <> '');
  end;

  //Referenzen gibt es erst ab IDS 2.5.1
  procedure OutReferenz(const _Indent : String;_Obj : TIDSConnect_Referenz);
  begin
    if (_Obj.ReferenzNumber = '') or (_Obj.ReferenzType = idsConnectRefType_None) then
      exit;
    //Das Belegdatum ist ein Muss-Feld; ohne Datum entstand frueher 1899-12-30
    if _Obj.ReferenzDate = 0 then
    begin
      TIDSConnect.ReportError(Format('Die Referenz %s (Belegart %s) hat kein Belegdatum und wurde nicht gesendet.',
                              [_Obj.ReferenzNumber,TIDSConnectHelper.ReferenzTypeToStr(_Obj.ReferenzType)]),nil);
      exit;
    end;
    _Val.Append(_Indent+'<Referenz>'+#13#10);
    _Val.AppendFormat(_Indent+' <ReferenzNumber>%s</ReferenzNumber>'+#13#10,[TIDSConnectHelper.XmlText(_Obj.ReferenzNumber,15)]);
    _Val.AppendFormat(_Indent+' <ReferenzDate>%s</ReferenzDate>'+#13#10,[TIDSConnectHelper.DateToDateStr(_Obj.ReferenzDate)]);
    _Val.AppendFormat(_Indent+' <ReferenzType>%s</ReferenzType>'+#13#10,[TIDSConnectHelper.ReferenzTypeToStr(_Obj.ReferenzType)]);
    if (_Obj is TIDSConnect_ReferenzPos) then
      _Val.AppendFormat(_Indent+' <ReferenzLine>%s</ReferenzLine>'+#13#10,[TIDSConnectHelper.XmlText(TIDSConnect_ReferenzPos(_Obj).ReferenzLine,10)]);
    _Val.Append(_Indent+'</Referenz>'+#13#10);
  end;

var
  lDate : TDate;
  lTime : TTime;
  lCur : String;
  j : Integer;
  lVersion : TIDSConnect_Version;

  //Ab IDS 2.5.1 gibt es ein Feld nicht mehr - nicht still verwerfen
  procedure ReportDropped(const _Field, _Hint : String);
  begin
    TIDSConnect.ReportError(Format('%s gibt es ab IDS 2.5.1 nicht mehr und wurde nicht gesendet.%s',
                            [_Field,_Hint]),nil);
  end;

begin
  Result := false;
  if _Val = nil then
    exit;

  //Frueher wurde lIs251 aus der rohen Version abgeleitet, das Element aber
  //ueber VersionToStr geschrieben: aus "Unbekannt" wurde so ein Dokument mit
  //<Version>2.5.1</Version>, 2.5-Schema und 2.5-Struktur, aus 1.3 eines mit
  //<Version>1.3</Version> und 2.5-Struktur
  lVersion := TIDSConnectHelper.SendVersion(WarenkorbInfo.Version);
  if lVersion <> WarenkorbInfo.Version then
    TIDSConnect.ReportError(Format('Der Warenkorb hat die Version "%s"; gesendet wird er als %s.',
      [IfThen(WarenkorbInfo.Version = idsConnectVersion_Unkown,'unbekannt',
              TIDSConnectHelper.VersionToStr(WarenkorbInfo.Version)),
       TIDSConnectHelper.VersionToStr(lVersion)]),nil);
  lIs251 := lVersion >= idsConnectVersion_2_5_1;

  _Val.Append('<?xml version="1.0" encoding="UTF-8"?>'+#13#10);
  _Val.Append('<Warenkorb xmlns="'+TIDSConnect_XMLNameSpace+'" ');
  _Val.Append('xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ');
  _Val.AppendFormat('xsi:schemaLocation="%s %s">'+#13#10,
                    [TIDSConnect_XMLNameSpace,
                     IfThen(lIs251,TIDSConnect_XMLSchemaSendShoppingCart_2_5_1,TIDSConnect_XMLSchemaSendShoppingCart_2_5)]);

  //Ohne gesetztes Datum entstand hier frueher 1899-12-30 / 00:00:00
  lDate := WarenkorbInfo.Date;
  if lDate = 0 then
    lDate := Date;
  lTime := WarenkorbInfo.Time;
  if lTime = 0 then
    lTime := Time;

  _Val.Append(' '+'<WarenkorbInfo>'+#13#10);
  _Val.AppendFormat('  '+'<Date>%s</Date>'+#13#10,[TIDSConnectHelper.DateToDateStr(lDate)]);
  _Val.AppendFormat('  '+'<Time>%s</Time>'+#13#10,[TIDSConnectHelper.TimeToTimeStr(lTime)]);
  //<RueckgabeKZ>Warenkorbrueckgabe</RueckgabeKZ> fuer Client nicht erforderlich
  _Val.Append('  '+'<Version>'+TIDSConnectHelper.VersionToStr(lVersion)+'</Version>'+#13#10);
  _Val.Append(' '+'</WarenkorbInfo>'+#13#10);

  _Val.Append(' '+'<Order>'+#13#10);

  //########## OrderInfo
  //Die Reihenfolge folgt der XSD: Referenz*, (DeliveryWeek+Year | DeliveryDate),
  //ModeOfShipment, Cur, ZusatzText, Kommission. Frueher wurde Cur nach
  //ZusatzText/Kommission ausgegeben - damit war jeder Warenkorb mit
  //Kommission oder Zusatztext schemaungueltig.
  _Val.Append('  '+'<OrderInfo>'+#13#10);
  if lIs251 then
  begin
    //Die alten Belegnummern werden nicht automatisch zu Referenzen: eine
    //Referenz verlangt ein Belegdatum, das diese Felder nicht haben
    if Order.OrderInfo.InquiryNo <> '' then
      ReportDropped('InquiryNo (Anfragenummer)',' Die Codeliste der Referenzen kennt keine Anfrage.');
    if Order.OrderInfo.OfferNo <> '' then
      ReportDropped('OfferNo (Angebotsnummer)',' Stattdessen OrderInfo.Referenzen mit Belegart 310 verwenden.');
    if Order.OrderInfo.PartNo <> '' then
      ReportDropped('PartNo (Bestellnummer)',' Stattdessen OrderInfo.Referenzen mit Belegart 220 verwenden.');
    if Order.OrderInfo.OrderConfNo <> '' then
      ReportDropped('OrderConfNo (Auftragsbestätigung)',' Stattdessen OrderInfo.Referenzen mit Belegart 231 verwenden.');
    for j := 0 to Order.OrderInfo.Referenzen.Count-1 do
      OutReferenz('   ',Order.OrderInfo.Referenzen[j]);
  end else
  begin
    if (Order.OrderInfo.InquiryNo <> '') then _Val.AppendFormat('  '+'<InquiryNo>%s</InquiryNo>'+#13#10,[TIDSConnectHelper.XmlText(Order.OrderInfo.InquiryNo,15)]);
    if (Order.OrderInfo.OfferNo <> '') then _Val.AppendFormat('  '+'<OfferNo>%s</OfferNo>'+#13#10,[TIDSConnectHelper.XmlText(Order.OrderInfo.OfferNo,15)]);
    if (Order.OrderInfo.PartNo <> '') then _Val.AppendFormat('  '+'<PartNo>%s</PartNo>'+#13#10,[TIDSConnectHelper.XmlText(Order.OrderInfo.PartNo,15)]);
    if (Order.OrderInfo.OrderConfNo <> '') then _Val.AppendFormat('  '+'<OrderConfNo>%s</OrderConfNo>'+#13#10,[TIDSConnectHelper.XmlText(Order.OrderInfo.OrderConfNo,15)]);
  end;
  if (Order.OrderInfo.DeliveryWeek<>0) and (Order.OrderInfo.DeliveryYear<>0) then
  begin
    _Val.AppendFormat('  '+'<DeliveryWeek>%s</DeliveryWeek>'+#13#10,[IntToStr(Order.OrderInfo.DeliveryWeek)]);
    _Val.AppendFormat('  '+'<DeliveryYear>%s</DeliveryYear>'+#13#10,[IntToStr(Order.OrderInfo.DeliveryYear)]);
  end else
  if (Order.OrderInfo.DeliveryDate<>0) then
    _Val.AppendFormat('  '+'<DeliveryDate>%s</DeliveryDate>'+#13#10,[TIDSConnectHelper.DateToDateStr(Order.OrderInfo.DeliveryDate)]);
  case Order.OrderInfo.ModeOfShipment of
    idsConnectMos_Lieferung: _Val.Append('  '+'<ModeOfShipment>Lieferung</ModeOfShipment>'+#13#10);
    idsConnectMos_Abholung: _Val.Append('  '+'<ModeOfShipment>Abholung</ModeOfShipment>'+#13#10);
  end;
  //Cur wurde bisher fest auf EUR gesetzt und das gepflegte Feld ignoriert
  lCur := Trim(Order.OrderInfo.Cur);
  if lCur = '' then
    lCur := 'EUR';
  _Val.AppendFormat('  '+'<Cur>%s</Cur>'+#13#10,[TIDSConnectHelper.XmlText(lCur,3)]);
  if (Order.OrderInfo.ZusatzText <> '') then _Val.AppendFormat('  '+'<ZusatzText>%s</ZusatzText>'+#13#10,[TIDSConnectHelper.XmlText(Order.OrderInfo.ZusatzText,100)]);
  if (Order.OrderInfo.Kommission <> '') then _Val.AppendFormat('  '+'<Kommission>%s</Kommission>'+#13#10,[TIDSConnectHelper.XmlText(Order.OrderInfo.Kommission,80)]);
  _Val.Append('  '+'</OrderInfo>'+#13#10);
  //########## OrderInfo

  //Die folgenden Bloecke waren frueher ueber einen Options-Record gesteuert
  //und komplett auskommentiert - gepflegte Lieferanten-, Kunden- und
  //Lieferortdaten sind dadurch beim Senden verloren gegangen. Sie werden
  //jetzt ausgegeben, sobald sie gefuellt sind.
  if (Order.SupplierInfo.IDNo <> '') or AddressIsFilled(Order.SupplierInfo.Address) then
  begin
    _Val.Append('  '+'<SupplierInfo>'+#13#10);
    if (Order.SupplierInfo.IDNo <> '') then _Val.AppendFormat('  '+'<IDNo>%s</IDNo>'+#13#10,[TIDSConnectHelper.XmlText(Order.SupplierInfo.IDNo,40)]);
    if AddressIsFilled(Order.SupplierInfo.Address) then
    begin
      _Val.Append('  '+'<Address>'+#13#10);
      OutAddress(Order.SupplierInfo.Address);
      _Val.Append('  '+'</Address>'+#13#10);
    end;
    _Val.Append('  '+'</SupplierInfo>'+#13#10);
  end;

  if (Order.CustomerInfo.IDNo <> '') or AddressIsFilled(Order.CustomerInfo.Address) then
  begin
    _Val.Append('  '+'<CustomerInfo>'+#13#10);
    if (Order.CustomerInfo.IDNo <> '') then _Val.AppendFormat('  '+'<IDNo>%s</IDNo>'+#13#10,[TIDSConnectHelper.XmlText(Order.CustomerInfo.IDNo,40)]);
    if AddressIsFilled(Order.CustomerInfo.Address) then
    begin
      _Val.Append('  '+'<Address>'+#13#10);
      OutAddress(Order.CustomerInfo.Address);
      _Val.Append('  '+'</Address>'+#13#10);
    end;
    _Val.Append('  '+'</CustomerInfo>'+#13#10);
  end;

  if (Order.DeliveryPlaceInfo.IDNo <> '') or
     AddressIsFilled(Order.DeliveryPlaceInfo.Address) or
     (lIs251 and Order.DeliveryPlaceInfo.HasGeoLocation) then
  begin
    _Val.Append('  '+'<DeliveryPlaceInfo>'+#13#10);
    if (Order.DeliveryPlaceInfo.IDNo <> '') then _Val.AppendFormat('  '+'<IDNo>%s</IDNo>'+#13#10,[TIDSConnectHelper.XmlText(Order.DeliveryPlaceInfo.IDNo,40)]);
    if AddressIsFilled(Order.DeliveryPlaceInfo.Address) then
    begin
      _Val.Append('  '+'<Address>'+#13#10);
      OutAddress(Order.DeliveryPlaceInfo.Address);
      _Val.Append('  '+'</Address>'+#13#10);
    end;
    //Geo-Daten gibt es erst ab IDS 2.5.1
    if lIs251 and Order.DeliveryPlaceInfo.HasGeoLocation then
    begin
      _Val.AppendFormat('  '+'<GeoLat>%s</GeoLat>'+#13#10,[TIDSConnectHelper.FloatToStr(Order.DeliveryPlaceInfo.GeoLat,8)]);
      _Val.AppendFormat('  '+'<GeoLang>%s</GeoLang>'+#13#10,[TIDSConnectHelper.FloatToStr(Order.DeliveryPlaceInfo.GeoLang,8)]);
    end;
    _Val.Append('  '+'</DeliveryPlaceInfo>'+#13#10);
  end;
  for i := 0 to Order.OrderItems.Count-1 do
  begin
    _Val.Append('  '+'<OrderItem>'+#13#10);
    case Order.OrderItems[i].ItemChara of
      idsConnectIc_normal : _Val.Append('  '+'<ItemChara>normal</ItemChara>'+#13#10);
      idsConnectIc_alternate : _Val.Append('  '+'<ItemChara>alternate</ItemChara>'+#13#10);
      idsConnectIc_provis : _Val.Append('  '+'<ItemChara>provis</ItemChara>'+#13#10);
    end;
    if (Order.OrderItems[i].RefItems_Customer <> '') or
       (Order.OrderItems[i].RefItems_CustomerSubNo <> '') or
       (Order.OrderItems[i].RefItems_Supplier <> '') or
       (Order.OrderItems[i].RefItems_SupplierSubNo <> '') then
    begin
      //Customer und Supplier sind laut XSD innerhalb von RefItems Pflicht,
      //deshalb werden sie immer geschrieben, sobald RefItems ausgegeben wird
      _Val.Append('  '+'<RefItems>'+#13#10);
      _Val.AppendFormat('  '+'<Customer>%s</Customer>'+#13#10,[TIDSConnectHelper.XmlText(Order.OrderItems[i].RefItems_Customer,35)]);
      if (Order.OrderItems[i].RefItems_CustomerSubNo <> '') then
        _Val.AppendFormat('  '+'<CustomerSubNo>%s</CustomerSubNo>'+#13#10,[TIDSConnectHelper.XmlText(Order.OrderItems[i].RefItems_CustomerSubNo,35)]);
      _Val.AppendFormat('  '+'<Supplier>%s</Supplier>'+#13#10,[TIDSConnectHelper.XmlText(Order.OrderItems[i].RefItems_Supplier,35)]);
      if (Order.OrderItems[i].RefItems_SupplierSubNo <> '') then
        _Val.AppendFormat('  '+'<SupplierSubNo>%s</SupplierSubNo>'+#13#10,[TIDSConnectHelper.XmlText(Order.OrderItems[i].RefItems_SupplierSubNo,35)]);
      _Val.Append('  '+'</RefItems>'+#13#10);
    end;
    if Order.OrderItems[i].EAN <> '' then _Val.AppendFormat('  '+'<EAN>%s</EAN>'+#13#10,[TIDSConnectHelper.XmlText(Order.OrderItems[i].EAN,13)]);
    if Order.OrderItems[i].ManufacturerID <> '' then _Val.AppendFormat('  '+'<ManufacturerID>%s</ManufacturerID>'+#13#10,[TIDSConnectHelper.XmlText(Order.OrderItems[i].ManufacturerID,40)]);
    if Order.OrderItems[i].ManufacturerIDType <> '' then _Val.AppendFormat('  '+'<ManufacturerIDType>%s</ManufacturerIDType>'+#13#10,[TIDSConnectHelper.XmlText(Order.OrderItems[i].ManufacturerIDType,40)]);
    //ArtNo ist laut XSD Pflicht und wird deshalb auch leer ausgegeben
    _Val.AppendFormat('  '+'<ArtNo>%s</ArtNo>'+#13#10,[TIDSConnectHelper.XmlText(Order.OrderItems[i].ArtNo,15)]);
    _Val.AppendFormat('  '+'<Qty>%s</Qty>'+#13#10,[TIDSConnectHelper.FloatToStr(Order.OrderItems[i].Qty,2)]);
    _Val.AppendFormat('  '+'<QU>%s</QU>'+#13#10,[TIDSConnectHelper.QuToQuStr(Order.OrderItems[i].QU)]);
    //Texte, Preise und Rohstoffanteile waren bisher komplett auskommentiert.
    //Sie werden ausgegeben, sobald sie gefuellt sind - eine reine Anfrage ohne
    //Preise erzeugt also weiterhin genau dieselben Elemente wie zuvor.
    if Order.OrderItems[i].Kurztext <> '' then _Val.AppendFormat('  '+'<Kurztext>%s</Kurztext>'+#13#10,[TIDSConnectHelper.XmlText(Order.OrderItems[i].Kurztext,100)]);
    if Order.OrderItems[i].Langtext <> '' then _Val.AppendFormat('  '+'<Langtext>%s</Langtext>'+#13#10,[TIDSConnectHelper.XmlEscape(Order.OrderItems[i].Langtext)]);
    if Order.OrderItems[i].OfferPrice <> 0 then _Val.AppendFormat('  '+'<OfferPrice>%s</OfferPrice>'+#13#10,[TIDSConnectHelper.FloatToStr(Order.OrderItems[i].OfferPrice,4)]);
    if Order.OrderItems[i].NetPrice <> 0 then _Val.AppendFormat('  '+'<NetPrice>%s</NetPrice>'+#13#10,[TIDSConnectHelper.FloatToStr(Order.OrderItems[i].NetPrice,4)]);
    //PriceBasis wird mit 1 vorbelegt; die 1 ist der Standardfall und muss
    //nicht uebertragen werden
    if (Order.OrderItems[i].PriceBasis <> 0) and (Order.OrderItems[i].PriceBasis <> 1) then
      _Val.AppendFormat('  '+'<PriceBasis>%s</PriceBasis>'+#13#10,[TIDSConnectHelper.FloatToStr(Order.OrderItems[i].PriceBasis,2)]);
    if Order.OrderItems[i].VAT <> 0 then _Val.AppendFormat('  '+'<VAT>%s</VAT>'+#13#10,[TIDSConnectHelper.FloatToStr(Order.OrderItems[i].VAT,2)]);
    //idsConnectTc_None liefert einen Leerstring und wird weggelassen
    if TIDSConnectHelper.TechnClarificationToStr(Order.OrderItems[i].TechnClarification) <> '' then
      _Val.AppendFormat('  '+'<TechnClarification>%s</TechnClarification>'+#13#10,[TIDSConnectHelper.TechnClarificationToStr(Order.OrderItems[i].TechnClarification)]);
    if Order.OrderItems[i].Hinweis <> '' then _Val.AppendFormat('  '+'<Hinweis>%s</Hinweis>'+#13#10,[TIDSConnectHelper.XmlText(Order.OrderItems[i].Hinweis,256)]);
    if Order.OrderItems[i].Fehlercode <> idsConnectFc_None then
      _Val.Append('  '+'<Fehlercode>1</Fehlercode>'+#13#10);
    if Order.OrderItems[i].Fehlertext <> '' then _Val.AppendFormat('  '+'<Fehlertext>%s</Fehlertext>'+#13#10,[TIDSConnectHelper.XmlText(Order.OrderItems[i].Fehlertext,256)]);
    if Order.OrderItems[i].Zuschlag <> 0 then _Val.AppendFormat('  '+'<Zuschlag>%s</Zuschlag>'+#13#10,[TIDSConnectHelper.FloatToStr(Order.OrderItems[i].Zuschlag,4)]);
    //Rohstoffanteil ist ein wiederholbares Element, kein Sammelknoten
    for j := 0 to Order.OrderItems[i].Rohstoffanteile.Count-1 do
    begin
      //MS und MK kennt erst die Codeliste von 2.5.1. Wuerde man sie in ein
      //2.5-Dokument schreiben, verletzte das die Enumeration der XSD.
      if (not lIs251) and
         (Order.OrderItems[i].Rohstoffanteile[j].Rohstoff in [idsConnectR_MS,idsConnectR_MK]) then
      begin
        TIDSConnect.ReportError(Format('Der Rohstoff %s ist erst ab IDS 2.5.1 definiert und wurde in Position %d ausgelassen.',
                                [TIDSConnectHelper.RohstoffToRohstoffStr(Order.OrderItems[i].Rohstoffanteile[j].Rohstoff),i+1]),nil);
        continue;
      end;
      _Val.Append('   '+'<Rohstoffanteil>'+#13#10);
      _Val.AppendFormat('    '+'<Rohstoff>%s</Rohstoff>'+#13#10,[TIDSConnectHelper.RohstoffToRohstoffStr(Order.OrderItems[i].Rohstoffanteile[j].Rohstoff)]);
      _Val.AppendFormat('    '+'<Gewichtsanteilswert>%s</Gewichtsanteilswert>'+#13#10,[TIDSConnectHelper.FloatToStr(Order.OrderItems[i].Rohstoffanteile[j].Gewichtsanteilswert,4)]);
      _Val.AppendFormat('    '+'<Gewichtsanteilseinheit>%s</Gewichtsanteilseinheit>'+#13#10,[TIDSConnectHelper.QuToQuStr(Order.OrderItems[i].Rohstoffanteile[j].Gewichtsanteilseinheit)]);
      _Val.AppendFormat('    '+'<Basiswert>%s</Basiswert>'+#13#10,[TIDSConnectHelper.FloatToStr(Order.OrderItems[i].Rohstoffanteile[j].Basiswert,4)]);
      _Val.AppendFormat('    '+'<Basiseinheit>%s</Basiseinheit>'+#13#10,[TIDSConnectHelper.QuToQuStr(Order.OrderItems[i].Rohstoffanteile[j].Basiseinheit)]);
      _Val.AppendFormat('    '+'<Basisnotierung>%s</Basisnotierung>'+#13#10,[TIDSConnectHelper.FloatToStr(Order.OrderItems[i].Rohstoffanteile[j].Basisnotierung,4)]);
      _Val.AppendFormat('    '+'<NotierungAktuell>%s</NotierungAktuell>'+#13#10,[TIDSConnectHelper.FloatToStr(Order.OrderItems[i].Rohstoffanteile[j].NotierungAktuell,4)]);
      _Val.Append('   '+'</Rohstoffanteil>'+#13#10);
    end;
    //Divers wurde bisher weder gelesen noch geschrieben
    if Order.OrderItems[i].Divers then
      _Val.Append('  '+'<Divers>true</Divers>'+#13#10);
    //ab IDS 2.5.1: Summe der Rohstoffzuschlaege, skontofaehiger Betrag und
    //Belegreferenzen auf Positionsebene
    if lIs251 then
    begin
      if Order.OrderItems[i].SumMaterialSurcharges <> 0 then
        _Val.AppendFormat('  '+'<SumMaterialSurcharges>%s</SumMaterialSurcharges>'+#13#10,[TIDSConnectHelper.FloatToStr(Order.OrderItems[i].SumMaterialSurcharges,4)]);
      if Order.OrderItems[i].DiscountableAmount <> 0 then
        _Val.AppendFormat('  '+'<DiscountableAmount>%s</DiscountableAmount>'+#13#10,[TIDSConnectHelper.FloatToStr(Order.OrderItems[i].DiscountableAmount,4)]);
      for j := 0 to Order.OrderItems[i].Referenzen.Count-1 do
        OutReferenz('   ',Order.OrderItems[i].Referenzen[j]);
    end;
    _Val.Append('  '+'</OrderItem>'+#13#10);
  end;
  _Val.Append(' '+'</Order>'+#13#10);
  _Val.Append('</Warenkorb>');
  Result := true;
end;

function TIDSConnect_WarenkorbHelper.UnusedObj(_Node: TLandrixXmlNode): Boolean;
begin
  //Nur Elemente werden ausgewertet; Text, Kommentare, CDATA-Abschnitte und
  //Verarbeitungsanweisungen zwischen den Elementen werden uebersprungen
  Result := _Node.NodeType <> xntElement;
end;

{ TIDSConnect }

class procedure TIDSConnect.ReportError(const _Message: String; _E: Exception);
begin
  if Assigned(TIDSConnect.IDSCONNECT_ONERROR) then
    TIDSConnect.IDSCONNECT_ONERROR(_Message,_E);
end;

class function TIDSConnect.GetUuid: String;
begin
  Result := TGUID.NewGuid.ToString;
  System.Delete(Result,1,1);
  System.Delete(Result,Length(Result),1);
end;


class function TIDSConnect.HookUrlWithSid(const _Sid: String): String;
begin
  Result := IDSCONNECT_HOOKURL;
  if Result = '' then
    exit;
  //Enthaelt die Hook-URL bereits einen Query-String, darf kein zweites '?' folgen
  if Pos('?',Result) > 0 then
    Result := Result+'&sid='+_Sid
  else
    Result := Result+'?sid='+_Sid;
end;

class function TIDSConnect.PostAction(const _ServiceURL, _Action: String;
  out _Response: String; _Version : TIDSConnect_Version): Boolean;
var
  http : THTTPClient;
  vcHelper : TIDSConnect.TValidateCertificatHelper;
  data : TMultipartFormData;
  res : IHTTPResponse;
  lBytes : TBytes;
begin
  Result := false;
  _Response := '';
  if _ServiceURL = '' then
    exit;

  http := THTTPClient.Create;
  vcHelper := TIDSConnect.TValidateCertificatHelper.Create;
  //Die Doku schreibt fuer die Formulardaten multipart/form-data vor
  data := TMultipartFormData.Create;
  try
    if TIDSConnect.IDSCONNECT_ALLOW_INVALID_CERT then
      http.OnValidateServerCertificate := vcHelper.DoValidateCertificateEvent;
    http.ConnectionTimeout := 15000;
    http.ResponseTimeout := 30000;
    //Komprimierte Antworten entpackt dann das Betriebssystem; ContentStream
    //enthaelt so immer die unkomprimierten Bytes
    http.AutomaticDecompression := [THTTPCompressionMethod.Any];

    data.AddField('action',_Action);
    data.AddField('version',TIDSConnectHelper.VersionToStr(_Version));
    try
      res := http.Post(_ServiceURL,data);
      if res.StatusCode <> 200 then
      begin
        ReportError(Format('Die Abfrage "%s" wurde mit HTTP %d beantwortet.',[_Action,res.StatusCode]),nil);
        exit;
      end;
      //Nennt der Server einen Zeichensatz, gilt der (z. B. UTF-16 ohne BOM).
      //Ohne Angabe wie bei der Hook-Rueckgabe ueber Deklaration bzw. BOM
      //dekodieren - ContentAsString las Latin-1 ohne charset-Header falsch.
      if res.ContentCharSet <> '' then
        _Response := XmlDeclToUtf8(res.ContentAsString)
      else
      begin
        res.ContentStream.Position := 0;
        SetLength(lBytes,res.ContentStream.Size);
        if Length(lBytes) > 0 then
          res.ContentStream.ReadBuffer(lBytes[0],Length(lBytes));
        _Response := DecodeXmlBytes(lBytes);
      end;
      Result := _Response <> '';
    except
      on E:Exception do
        ReportError(Format('Die Abfrage "%s" ist fehlgeschlagen: %s',[_Action,E.Message]),E);
    end;
  finally
    data.Free;
    vcHelper.Free;
    http.Free;
  end;
end;

class function TIDSConnect.ParseResponse(const _Response, _RootName: String;
  out _Doc: TLandrixXmlDocument): TLandrixXmlNode;
begin
  Result := nil;
  //Der Aufrufer gibt _Doc frei, auch wenn das Ergebnis nil ist
  _Doc := TLandrixXmlDocument.Create;
  try
    _Doc.LoadFromString(_Response);
    if _Doc.Root = nil then
      exit;
    if not SameText(_Doc.Root.LocalName,_RootName) then
    begin
      ReportError(Format('Unerwartete Antwort: <%s> statt <%s>.',
                  [_Doc.Root.Name,_RootName]),nil);
      exit;
    end;
    Result := _Doc.Root;
  except
    on E:Exception do
      ReportError('Die Antwort konnte nicht gelesen werden: '+E.Message,E);
  end;
end;

class function TIDSConnect.IDSConnectLI(const _ServiceURL: String;
  out _LoginInfo: TIDSConnect_LoginInfo; _Version : TIDSConnect_Version): Boolean;
var
  lResponse : String;
  lDoc : TLandrixXmlDocument;
  lRoot,lNode : TLandrixXmlNode;

  function NodeIsTrue(const _Name : String; _Default : Boolean) : Boolean;
  var
    i : Integer;
  begin
    Result := _Default;
    //Ueber den lokalen Namen suchen, damit ein Namensraum-Praefix nicht stoert
    for i := 0 to lRoot.ChildCount-1 do
    begin
      lNode := lRoot.Children[i];
      if (lNode.NodeType = xntElement) and SameText(lNode.LocalName,_Name) then
      begin
        Result := SameText(Trim(NodeText(lNode)),'true') or (Trim(NodeText(lNode)) = '1');
        exit;
      end;
    end;
  end;

begin
  _LoginInfo.Clear;
  Result := false;
  if not PostAction(_ServiceURL,'LI',lResponse,_Version) then
    exit;

  lDoc := nil;
  try
    lRoot := ParseResponse(lResponse,'Logininformationen',lDoc);
    if lRoot = nil then
      exit;

    //Fehlt eine Angabe, bleibt es bei "erforderlich" aus Clear
    _LoginInfo.CustomerNoRequired := NodeIsTrue('Kundennummer_erforderlich',true);
    _LoginInfo.UsernameRequired   := NodeIsTrue('Benutzername_erforderlich',true);
    _LoginInfo.PasswordRequired   := NodeIsTrue('Passwort_erforderlich',true);
    Result := true;
  finally
    lDoc.Free;
  end;
end;

class function TIDSConnect.IDSConnectSV(const _ServiceURL: String;
  _Versions: TStrings; _Version : TIDSConnect_Version): Boolean;
var
  lResponse : String;
  lDoc : TLandrixXmlDocument;
  lRoot : TLandrixXmlNode;
  i : Integer;
begin
  Result := false;
  if _Versions = nil then
    exit;
  _Versions.Clear;
  if not PostAction(_ServiceURL,'SV',lResponse,_Version) then
    exit;

  lDoc := nil;
  try
    lRoot := ParseResponse(lResponse,'Schnittstellenversionen',lDoc);
    if lRoot = nil then
      exit;

    for i := 0 to lRoot.ChildCount-1 do
      if (lRoot.Children[i].NodeType = xntElement) and
         SameText(lRoot.Children[i].LocalName,'Version') then
        _Versions.Add(Trim(NodeText(lRoot.Children[i])));
    Result := true;
  finally
    lDoc.Free;
  end;
end;

class function TIDSConnect.IDSConnectSVBestVersion(
  const _ServiceURL: String; _Version : TIDSConnect_Version): TIDSConnect_Version;
var
  lVersions : TStringList;
  i : Integer;
  lVer : TIDSConnect_Version;
begin
  Result := idsConnectVersion_Unkown;
  lVersions := TStringList.Create;
  try
    if not IDSConnectSV(_ServiceURL,lVersions,_Version) then
      exit;
    //Hinweis: Die Beispielantwort der Spezifikation listet nur 1.3 bis 2.3
    //auf; Shops, die 2.5 oder 2.5.1 koennen, melden das entsprechend.
    //Unbekannte Angaben werden uebergangen.
    for i := 0 to lVersions.Count-1 do
    begin
      lVer := TIDSConnectHelper.VersionFromStr(lVersions[i]);
      if (lVer <> idsConnectVersion_Unkown) and (lVer > Result) then
        Result := lVer;
    end;
  finally
    lVersions.Free;
  end;
end;

class function TIDSConnect.HookUrlBase: String;
var
  p : Integer;
begin
  Result := IDSCONNECT_HOOKURL;
  p := Pos('?',Result);
  if p > 0 then
    Result := Copy(Result,1,p-1);
end;

class function TIDSConnect.TryFetchResult(const _Url: String;
  _Warenkorb: TIDSConnect_Warenkorb; out _Error : String): Boolean;
var
  lRaw : TBytes;
  lId : String;
begin
  //FetchResult laedt ohne Warenkorb nur herunter - hier gibt es ohne
  //Warenkorb nichts einzulesen
  Result := false;
  _Error := '';
  if _Warenkorb = nil then
    exit;
  Result := FetchResult(_Url,_Warenkorb,_Error,lRaw,lId);
end;

class function TIDSConnect.FetchResult(const _Url: String;
  _Warenkorb: TIDSConnect_Warenkorb; out _Error : String; out _Raw : TBytes;
  out _Id : String): Boolean;
var
  str : TMemoryStream;
  http : THTTPClient;
  vcHelper : TIDSConnect.TValidateCertificatHelper;
  res : IHTTPResponse;
begin
  Result := false;
  _Error := '';
  _Raw := nil;
  _Id := '';
  if _Url = '' then
    exit;

  str := TMemoryStream.Create;
  http := THTTPClient.Create;
  vcHelper := TIDSConnect.TValidateCertificatHelper.Create;
  try
    //Nur zuweisen, wenn beanstandete Zertifikate akzeptiert werden sollen -
    //siehe die Erlaeuterung bei DoValidateCertificateEvent. Ohne Zuweisung
    //prueft Windows das Zertifikat wie gewohnt.
    if TIDSConnect.IDSCONNECT_ALLOW_INVALID_CERT then
      http.OnValidateServerCertificate := vcHelper.DoValidateCertificateEvent;
    //Kurze Timeouts, damit der Warte-Dialog zwischen zwei Versuchen bedienbar
    //bleibt - ein einzelner Versuch darf das Warten nicht blockieren
    http.ConnectionTimeout := 5000;
    http.ResponseTimeout := 10000;
    try
      //Solange noch nichts vorliegt, antwortet der Callback-Endpunkt mit 404
      //bzw. mit einem leeren Rumpf. Das ist kein Fehler, sondern der
      //Normalfall waehrend des Wartens - deshalb wird hier nichts gemeldet.
      res := http.Get(_Url,str);
      SetLength(_Raw,str.Size);
      str.Position := 0;
      if Length(_Raw) > 0 then
        str.ReadBuffer(_Raw[0],Length(_Raw));
      if Assigned(IDSCONNECT_ONRESPONSE) then
        IDSCONNECT_ONRESPONSE(_Url,res.StatusCode,_Raw);
      if res.StatusCode <> 200 then
      begin
        if res.StatusCode <> 404 then
          _Error := Format('Hook-URL antwortet mit HTTP %d.',[res.StatusCode]);
        exit;
      end;
      if str.Size = 0 then
        exit;
      _Id := Trim(res.HeaderValue['X-IDSConnect-Id']);
      if _Warenkorb = nil then
      begin
        Result := true;
        exit;
      end;
      Result := _Warenkorb.LoadFromStream(str);
      if not Result then
        _Error := 'Die Rückgabe konnte nicht als Warenkorb eingelesen werden.';
    except
      //Netzwerkaussetzer beenden das Warten nicht, der naechste Versuch folgt.
      //Der Aufrufer bekommt die Meldung aber einmalig zu sehen, damit ein
      //dauerhaftes Problem (falsche Adresse, abgelehntes Zertifikat) nicht
      //als endloses Warten erscheint.
      on E:Exception do
      begin
        Result := false;
        _Error := E.Message;
      end;
    end;
  finally
    vcHelper.Free;
    http.Free;
    str.Free;
  end;
end;

class function TIDSConnect.TryFetchResult(const _Url: String;
  _Warenkorb: TIDSConnect_Warenkorb): Boolean;
var
  lError : String;
begin
  Result := TryFetchResult(_Url,_Warenkorb,lError);
  if (not Result) and (lError <> '') then
    ReportError(lError,nil);
end;

class procedure TIDSConnect.MergeOrderItems(_From, _To: TIDSConnect_Warenkorb;
  _TakeHeader: Boolean);
var
  i : Integer;
begin
  if (_From = nil) or (_To = nil) then
    exit;
  //Die erste Rueckgabe liefert die Kopfdaten. Frueher wurden dabei nur Datum,
  //Uhrzeit, RueckgabeKZ und Version uebernommen - Waehrung, Kommission,
  //Referenzen und die Adressen fielen weg, ein CHF-Warenkorb wurde so zu EUR.
  if _TakeHeader then
  begin
    _To.WarenkorbInfo.Assign(_From.WarenkorbInfo);
    _To.Order.AssignHeader(_From.Order);
  end;
  for i := 0 to _From.Order.OrderItems.Count-1 do
    _To.Order.OrderItems.AddItem.Assign(_From.Order.OrderItems[i]);
end;

class procedure TIDSConnect.MergeOrderItems(_From, _To: TIDSConnect_Warenkorb);
begin
  if _To = nil then
    exit;
  MergeOrderItems(_From,_To,_To.Order.OrderItems.Count = 0);
end;

class function TIDSConnect.CollectResults(const _Url: String;
  _Warenkorb: TIDSConnect_Warenkorb; var _State: TCollectState): Boolean;
var
  lBuffer : TIDSConnect_Warenkorb;
  lError, lId, lSeen : String;
  lRaw : TBytes;
  i : Integer;
  lDuplicate, lParsed : Boolean;
  lStream : TBytesStream;

  //Kennung bzw. Rohdaten merken - auch bei einer Rueckgabe, die nicht
  //eingelesen werden konnte, damit ihre Wiederholung als Dublette gilt
  procedure Remember;
  begin
    if lId <> '' then
      _State.SeenIds := _State.SeenIds + [lId];
    _State.LastHadId := lId <> '';
    _State.LastRaw := lRaw;
  end;

begin
  Result := false;
  _State.LimitReached := false;
  if (_Url = '') or (_Warenkorb = nil) then
    exit;
  if _State.Received = 0 then
    _Warenkorb.Clear;
  //LoadFromStream ersetzt den Zielwarenkorb, deshalb wird ueber einen
  //Zwischenpuffer gelesen und anschliessend zusammengefuehrt.
  lBuffer := TIDSConnect_Warenkorb.Create;
  try
    //Die Obergrenze schuetzt vor einer Endlosschleife, falls ein Hook-Server
    //die Rueckgabe beim Abruf nicht verbraucht
    for i := 1 to IDSCONNECT_MAX_COLLECT do
    begin
      //Erst nur herunterladen und auf Dublette pruefen, dann einlesen: sonst
      //kaemen Meldungen des Parsers (z. B. unbekannte Mengeneinheit) bei einem
      //Server, der dieselbe Rueckgabe wiederholt, bei jedem Abruf neu
      if not FetchResult(_Url,nil,lError,lRaw,lId) then
      begin
        if (lError <> '') and (not _State.ErrorReported) then
        begin
          _State.ErrorReported := true;
          ReportError('Der Abruf von '+_Url+' ist fehlgeschlagen: '+lError,nil);
        end;
        exit;
      end;
      //Ein Hook-Server, der beim Abruf nicht loescht, liefert dieselbe
      //Rueckgabe immer wieder - sie wuerde sonst bei jedem Abruf erneut
      //angehaengt und die Frist liefe nie ab. Mit Kennung ist das eindeutig;
      //inhaltsgleiche, aber eigenstaendige Uebertragungen haben verschiedene
      //Kennungen. Ohne Kennung bleibt nur der Vergleich der Rohdaten.
      lDuplicate := false;
      if lId <> '' then
      begin
        //Mit Kennung gegen alle bereits gesehenen pruefen - ein Server, der
        //zyklisch ausliefert (A, B, A), wird so ebenfalls erkannt
        for lSeen in _State.SeenIds do
          if lSeen = lId then
          begin
            lDuplicate := true;
            break;
          end;
      end else
      //Ohne Kennung: mit der letzten Rueckgabe vergleichen, sofern auch diese
      //keine Kennung hatte
      if (_State.LastRaw <> nil) and (not _State.LastHadId) then
        lDuplicate := (Length(lRaw) = Length(_State.LastRaw)) and
                      CompareMem(PByte(lRaw),PByte(_State.LastRaw),Length(lRaw));
      if lDuplicate then
      begin
        if not _State.DuplicateReported then
        begin
          _State.DuplicateReported := true;
          ReportError('Die Hook-URL liefert dieselbe Rückgabe erneut; sie wurde verworfen. '+
                      'Der Hook-Server muss jede Rückgabe beim Abruf löschen (siehe idsconnect.php).',nil);
        end;
        exit;
      end;

      lStream := TBytesStream.Create(lRaw);
      try
        lParsed := lBuffer.LoadFromStream(lStream);
      finally
        lStream.Free;
      end;
      Remember;
      if not lParsed then
      begin
        //Die Einzelheiten hat LoadFromStream bereits gemeldet
        if not _State.ErrorReported then
        begin
          _State.ErrorReported := true;
          ReportError('Die Rückgabe von '+_Url+' konnte nicht als Warenkorb eingelesen werden.',nil);
        end;
        exit;
      end;
      MergeOrderItems(lBuffer,_Warenkorb,_State.Received = 0);
      Inc(_State.Received);
      Result := true;
    end;
    //Schleife ohne leere Warteschlange beendet: es kann noch mehr vorliegen
    _State.LimitReached := true;
  finally
    lBuffer.Free;
  end;
end;

class procedure TIDSConnect.CollectAll(const _Url: String;
  _Warenkorb: TIDSConnect_Warenkorb; var _State: TCollectState);
var
  i : Integer;
begin
  for i := 1 to 20 do
  begin
    CollectResults(_Url,_Warenkorb,_State);
    if not _State.LimitReached then
      exit;
  end;
  ReportError(Format('An der Hook-URL liegen nach %d Rückgaben noch weitere vor; '+
                     'sie wurden nicht mehr abgeholt.',[_State.Received]),nil);
end;

class function TIDSConnect.WaitForResult(const _Url: String;
  _Warenkorb: TIDSConnect_Warenkorb; _TimeoutSec: Integer;
  _MultipleResult: Boolean): Boolean;
var
  lReported : Boolean;
  lState : TCollectState;
begin
  //Frueher stand hier ein TaskMessageDlg mit genau einem Abrufversuch
  //danach: war der Warenkorb noch nicht angekommen, scheiterte der Vorgang
  //ohne Wiederholung und ohne Diagnose.
  lReported := false;

  if not _MultipleResult then
  begin
    Result := TIDSConnectDlgWait.Execute(
                'Warte auf Abschluss',
                'Bitte schliessen Sie den Vorgang im Browser ab.'+sLineBreak+
                'Der Warenkorb wird danach automatisch uebernommen.',
                _TimeoutSec,
                function : TIDSConnectPollResult
                var
                  lError : String;
                begin
                  if TryFetchResult(_Url,_Warenkorb,lError) then
                    Result := idsPollFinished
                  else
                  begin
                    Result := idsPollNothing;
                    //Eine dauerhafte Stoerung nur einmal melden, nicht bei
                    //jedem Abrufversuch
                    if (lError <> '') and (not lReported) then
                    begin
                      lReported := true;
                      ReportError('Der Abruf von '+_Url+' ist fehlgeschlagen: '+lError,nil);
                    end;
                  end;
                end);
    exit;
  end;

  //Mehrfachrueckgabe (ab IDS 2.5.1): Der Shop darf mehrfach an die Hook-URL
  //senden. Jede Rueckgabe wird eingelesen und an den Warenkorb angehaengt,
  //bis der Anwender den Vorgang beendet oder die Frist abgelaufen ist.
  lState := Default(TCollectState);
  _Warenkorb.Clear;
  TIDSConnectDlgWait.Execute(
                'Warte auf Abschluss',
                'Sie koennen nacheinander mehrere Artikel uebernehmen.'+sLineBreak+
                'Schliessen Sie den Vorgang mit "Fertig" ab.',
                _TimeoutSec,
                function : TIDSConnectPollResult
                begin
                  if CollectResults(_Url,_Warenkorb,lState) then
                    //Weiter warten - es koennen noch Rueckgaben folgen
                    Result := idsPollReceived
                  else
                    Result := idsPollNothing;
                end,
                2000,
                IDSCONNECT_MULTIPLERESULT_FOLLOWUP,
                //Ein Abruf kann mehrere Rueckgaben uebernehmen - der Dialog
                //zeigt deshalb die tatsaechliche Anzahl
                function : Integer
                begin
                  Result := lState.Received;
                end);
  //Was zwischen dem letzten Abruf und dem Schliessen des Dialogs eingetroffen
  //ist, wuerde sonst ungelesen auf dem Server verfallen
  CollectAll(_Url,_Warenkorb,lState);
  Result := lState.Received > 0;
end;

class function TIDSConnect.BuildFormHeader(const _Title: String): String;
begin
  //Der Zeichensatz muss im HTML deklariert werden, sonst raet der Browser die
  //Kodierung der Formulardaten. Zusammen mit accept-charset stellt das sicher,
  //dass Umlaute als UTF-8 beim Grosshaendler ankommen - passend zur
  //UTF-8-Deklaration des eingebetteten Warenkorb-XML.
  Result := '<html><head>'+
            '<meta http-equiv="Content-Type" content="text/html; charset=utf-8">'+
            '<title>IDS-Connect Schnittstelle '+TIDSConnectHelper.HtmlEscape(_Title)+'</title>'+
            '</head>';
end;

class function TIDSConnect.HiddenField(const _Name, _Value: String;
  _MaxLength: Integer): String;
begin
  //Die Werte wurden frueher unmaskiert in value="..." eingesetzt - ein
  //Anfuehrungszeichen im Passwort oder Suchbegriff zerlegte das Formular
  Result := '<input type="hidden" name="'+_Name+'" value="'+TIDSConnectHelper.HtmlEscape(_Value)+'"';
  if _MaxLength > 0 then
    Result := Result+' size="'+IntToStr(_MaxLength)+'" maxlength="'+IntToStr(_MaxLength)+'"';
  Result := Result+'>';
end;

class function TIDSConnect.SaveFormToFile(_Form: TStrings;
  const _TmpFilename: String): Boolean;
begin
  Result := false;
  try
    //Frueher wurde als Codepage 1252 gespeichert, waehrend das eingebettete
    //XML UTF-8 deklarierte. TEncoding.UTF8 ist ausserdem ein RTL-Singleton und
    //muss - anders als TEncoding.GetEncoding(1252) - nicht freigegeben werden.
    _Form.SaveToFile(_TmpFilename,TEncoding.UTF8);
    Result := true;
  except
    on E:Exception do
      ReportError('Die temporaere Datei '+_TmpFilename+' konnte nicht geschrieben werden: '+E.Message,E);
  end;
end;

class function TIDSConnect.OpenInBrowser(const _TmpFilename: String): Boolean;
begin
  //ShellExecute meldet Fehler ueber einen Rueckgabewert <= 32; das wurde
  //bisher ignoriert und der Anwender bekam trotzdem den Warte-Dialog
  Result := ShellExecuteW(0,'open',PChar(_TmpFilename),'','',SW_SHOWNORMAL) > 32;
  if not Result then
    ReportError('Der Browser konnte nicht gestartet werden ('+_TmpFilename+').',nil);
end;

class function TIDSConnect.ShowFormAndFetch(_Form: TStrings; const _TmpFilename,
  _ResultUrl: String; _Warenkorb: TIDSConnect_Warenkorb;
  _TimeoutSec: Integer; _MultipleResult: Boolean): Boolean;
var
  lState : TCollectState;
begin
  Result := false;

  if _TmpFilename = '' then
  begin
    //Integrierter Browser. Der Dialog schliesst sich selbst, sobald der Shop
    //zur Hook-URL navigiert - deshalb ist hier kein zusaetzlicher
    //Warte-Dialog noetig.
    //Bei Mehrfachrueckgabe bleibt der Dialog nach einer Uebertragung offen,
    //damit der Anwender im Shop weitere Artikel uebernehmen kann. Die
    //Rueckgaben werden schon waehrend der Sitzung abgeholt (nach jeder
    //Uebertragung und regelmaessig) - sonst verfielen sie bei einer langen
    //Sitzung nach der TTL des Hook-Servers.
    lState := Default(TCollectState);
    if _MultipleResult and (_ResultUrl <> '') then
    begin
      _Warenkorb.Clear;
      TIDSConnectDlgWebBrowser.ShowDialog(_Form.Text,'',HookUrlBase,true,
        function : Integer
        begin
          CollectAll(_ResultUrl,_Warenkorb,lState);
          Result := lState.Received;
        end);
    end else
      TIDSConnectDlgWebBrowser.ShowDialog(_Form.Text,'',HookUrlBase);
    if _ResultUrl = '' then
    begin
      Result := true;
      exit;
    end;
    //Auch wenn der Anwender das Fenster von Hand geschlossen hat, kann der
    //Warenkorb bereits uebertragen worden sein
    if not _MultipleResult then
    begin
      Result := TryFetchResult(_ResultUrl,_Warenkorb);
      exit;
    end;
    //Was seit dem letzten Abruf noch eingetroffen ist
    CollectAll(_ResultUrl,_Warenkorb,lState);
    Result := lState.Received > 0;
    exit;
  end;

  //Externer Browser ueber eine temporaere Datei
  if not SaveFormToFile(_Form,_TmpFilename) then
    exit;
  if not OpenInBrowser(_TmpFilename) then
    exit;
  if _ResultUrl = '' then
    Result := true
  else
    Result := WaitForResult(_ResultUrl,_Warenkorb,_TimeoutSec,_MultipleResult);
end;

class procedure TIDSConnect.IDSConnectADT(const _ServiceURL, _Cst, _UN, _Pwd,
  _ArtNr, _TmpFilename: String; _Version : TIDSConnect_Version);
var
  hstrl : TStringList;
begin
  //Frueher brachen ADT, AS und WKS hier ohne jede Meldung ab
  if _ServiceURL.IsEmpty then
  begin
    ReportError('ADL: Die Shop-Adresse fehlt.',nil);
    exit;
  end;
  //Fehlende Anmeldedaten sind kein Abbruchgrund mehr: welche ein Shop
  //braucht, sagt die Abfrage LI, und manche Shops (z. B. eine offene
  //Artikelsuche) brauchen keine. Der Shop lehnt fehlende Daten selbst ab.
  if _ArtNr = '' then
  begin
    ReportError('ADL: Die Artikelnummer fehlt.',nil);
    exit;
  end;
  hstrl := TStringList.Create;
  try
    hstrl.Add('<!doctype html>');
    hstrl.Add(BuildFormHeader('ADT'));
    hstrl.Add('<body onload="document.forms[''adt''].submit();">');
    hstrl.Add('<form id="adt" name="adt" action="'+TIDSConnectHelper.HtmlEscape(_ServiceURL)+'" method="post" enctype="multipart/form-data" accept-charset="utf-8">');
    hstrl.Add(HiddenField('kndnr',_Cst,50));
    hstrl.Add(HiddenField('name_kunde',_UN,50));
    hstrl.Add(HiddenField('pw_kunde',_Pwd,50));
    hstrl.Add(HiddenField('version',TIDSConnectHelper.VersionToStr(_Version),5));
    hstrl.Add(HiddenField('action','ADL',3));
    hstrl.Add(HiddenField('ghnummer',_ArtNr,35));
    hstrl.Add('</form></body></html>');
    //Der Artikeldeeplink hat keine Rueckuebertragung, deshalb ohne Ergebnis-URL
    ShowFormAndFetch(hstrl,_TmpFilename,'',nil,0);
  finally
    hstrl.Free;
  end;
end;

class function TIDSConnect.IDSConnectAS(_ServiceURL, _Cst, _UN, _Pwd,
  _TmpFilename, _SearchString: String; _Warenkorb: TIDSConnect_Warenkorb;
  _MultipleResult : Boolean; _HookUrlTimeout : Integer; _Version : TIDSConnect_Version): Boolean;
var
  hstrl : TStringList;
  sid : String;
begin
  Result := false;
  if _ServiceURL.IsEmpty then
  begin
    ReportError('AS: Die Shop-Adresse fehlt.',nil);
    exit;
  end;
  //Fehlende Anmeldedaten sind kein Abbruchgrund mehr: welche ein Shop
  //braucht, sagt die Abfrage LI, und manche Shops (z. B. eine offene
  //Artikelsuche) brauchen keine. Der Shop lehnt fehlende Daten selbst ab.
  if TIDSConnect.IDSCONNECT_HOOKURL = '' then
  begin
    ReportError('AS: Die Hook-URL fehlt.',nil);
    exit;
  end;
  if _SearchString = '' then
  begin
    ReportError('AS: Der Suchbegriff fehlt.',nil);
    exit;
  end;
  if _Warenkorb = nil then
  begin
    ReportError('AS: Es ist kein Warenkorb für das Ergebnis übergeben.',nil);
    exit;
  end;

  if _Version < idsConnectVersion_2_5_1 then
    _MultipleResult := false;
  sid := TIDSConnect.GetUuid;
  hstrl := TStringList.Create;
  try
    hstrl.Add('<!doctype html>');
    hstrl.Add(BuildFormHeader('AS'));
    hstrl.Add('<body onload="document.forms[''search''].submit();">');
    hstrl.Add('<form id="search" name="search" action="'+TIDSConnectHelper.HtmlEscape(_ServiceURL)+'" method="post" enctype="multipart/form-data" accept-charset="utf-8">');
    hstrl.Add(HiddenField('kndnr',_Cst,50));
    hstrl.Add(HiddenField('name_kunde',_UN,50));
    hstrl.Add(HiddenField('pw_kunde',_Pwd,50));
    hstrl.Add(HiddenField('version',TIDSConnectHelper.VersionToStr(_Version),5));
    hstrl.Add(HiddenField('searchterm',_SearchString));
    hstrl.Add(HiddenField('action','AS',3));
    hstrl.Add(HiddenField('hookurl',HookUrlWithSid(sid),256));
    //Beide Parameter sind ab IDS 2.5.1 fuer die Artikelsuche definiert
    if _MultipleResult then
      hstrl.Add(HiddenField('multipleResult','true'));
    if (_Version >= idsConnectVersion_2_5_1) and (_HookUrlTimeout > 0) then
      hstrl.Add(HiddenField('hookURLTimeout',IntToStr(_HookUrlTimeout)));
    hstrl.Add('</form></body></html>');
    //Leerer Dateiname bedeutet: im integrierten Browser anzeigen.
    //Beim externen Browser wird mit Fortschrittsdialog gewartet;
    //_HookUrlTimeout ist der IDS-2.5.1-Parameter hookURLTimeout.
    Result := ShowFormAndFetch(hstrl,_TmpFilename,HookUrlWithSid(sid),_Warenkorb,_HookUrlTimeout,_MultipleResult);
  finally
    hstrl.Free;
  end;
end;

class function TIDSConnect.IDSConnectWKE(const _ServiceURL, _Cst, _UN, _Pwd,
  _TmpFilename: String; _Warenkorb: TIDSConnect_Warenkorb; _Version : TIDSConnect_Version): Boolean;
var
  hstrl : TStringList;
  sid : String;
begin
  Result := false;
  if _ServiceURL.IsEmpty then
  begin
    ReportError('WKE: Die Shop-Adresse fehlt.',nil);
    exit;
  end;
  //Fehlende Anmeldedaten sind kein Abbruchgrund mehr: welche ein Shop
  //braucht, sagt die Abfrage LI, und manche Shops (z. B. eine offene
  //Artikelsuche) brauchen keine. Der Shop lehnt fehlende Daten selbst ab.
  if TIDSConnect.IDSCONNECT_HOOKURL = '' then
  begin
    ReportError('WKE: Die Hook-URL fehlt.',nil);
    exit;
  end;
  if _Warenkorb = nil then
  begin
    ReportError('WKE: Es ist kein Warenkorb für das Ergebnis übergeben.',nil);
    exit;
  end;

  sid := TIDSConnect.GetUuid;
  hstrl := TStringList.Create;
  try
    hstrl.Add('<!doctype html>');
    hstrl.Add(BuildFormHeader('WKE'));
    hstrl.Add('<body onload="document.forms[''wke''].submit();">');
    hstrl.Add('<form id="wke" name="wke" action="'+TIDSConnectHelper.HtmlEscape(_ServiceURL)+'" method="post" enctype="multipart/form-data" accept-charset="utf-8">');
    hstrl.Add(HiddenField('kndnr',_Cst,50));
    hstrl.Add(HiddenField('name_kunde',_UN,50));
    hstrl.Add(HiddenField('pw_kunde',_Pwd,50));
    hstrl.Add(HiddenField('version',TIDSConnectHelper.VersionToStr(_Version),5));
    hstrl.Add(HiddenField('action','WKE',3));
    hstrl.Add(HiddenField('hookurl',HookUrlWithSid(sid),256));
    hstrl.Add('</form></body></html>');
    if Assigned(IDSCONNECT_ONREQUEST) then
      IDSCONNECT_ONREQUEST(_ServiceURL,
        'action=WKE'+sLineBreak+
        'version='+TIDSConnectHelper.VersionToStr(_Version)+sLineBreak+
        'kndnr='+_Cst+sLineBreak+
        'name_kunde='+_UN+sLineBreak+
        'pw_kunde='+IfThen(_Pwd = '','(leer)','(maskiert)')+sLineBreak+
        'hookurl='+HookUrlWithSid(sid));
    //Leerer Dateiname bedeutet: im integrierten Browser anzeigen
    Result := ShowFormAndFetch(hstrl,_TmpFilename,HookUrlWithSid(sid),_Warenkorb,IDSCONNECT_HOOKURL_TIMEOUT);
  finally
    hstrl.Free;
  end;
end;

class function TIDSConnect.IDSConnectWKS(_ServiceURL, _Cst, _UN, _Pwd,
  _TmpFilename: String; _Warenkorb: TIDSConnect_Warenkorb;
  _DontWait: Boolean): Boolean;
var
  hstrl : TStringList;
  sid : String;
  hstr : TStringBuilder;
begin
  Result := false;
  if _ServiceURL.IsEmpty then
  begin
    ReportError('WKS: Die Shop-Adresse fehlt.',nil);
    exit;
  end;
  //Fehlende Anmeldedaten sind kein Abbruchgrund mehr: welche ein Shop
  //braucht, sagt die Abfrage LI, und manche Shops (z. B. eine offene
  //Artikelsuche) brauchen keine. Der Shop lehnt fehlende Daten selbst ab.
  if TIDSConnect.IDSCONNECT_HOOKURL = '' then
  begin
    ReportError('WKS: Die Hook-URL fehlt.',nil);
    exit;
  end;
  if _Warenkorb = nil then
  begin
    ReportError('WKS: Es ist kein Warenkorb übergeben.',nil);
    exit;
  end;

  sid := TIDSConnect.GetUuid;
  hstr := TStringBuilder.Create;
  hstrl := TStringList.Create;
  try
    if not _Warenkorb.SaveToString(hstr) then
    begin
      ReportError('WKS: Der Warenkorb konnte nicht als XML erzeugt werden.',nil);
      exit;
    end;
    hstrl.Add('<!doctype html>');
    hstrl.Add(BuildFormHeader('WKS'));
    hstrl.Add('<body onload="document.forms[''wks''].submit();">');
    hstrl.Add('<form id="wks" name="wks" action="'+TIDSConnectHelper.HtmlEscape(_ServiceURL)+'" method="post" enctype="multipart/form-data" accept-charset="utf-8">');
    hstrl.Add(HiddenField('kndnr',_Cst,50));
    hstrl.Add(HiddenField('name_kunde',_UN,50));
    hstrl.Add(HiddenField('pw_kunde',_Pwd,50));
    //Formular und Warenkorb-XML muessen dieselbe Version melden.
    hstrl.Add(HiddenField('version',TIDSConnectHelper.VersionToStr(
      TIDSConnectHelper.SendVersion(_Warenkorb.WarenkorbInfo.Version)),5));
    //Der Browser dekodiert Entities im textarea-Inhalt vor dem Absenden.
    //Das XML muss deshalb ein zweites Mal - diesmal HTML - maskiert werden,
    //sonst kommt ein im XML korrektes &amp; als nacktes & beim Shop an und
    //ein </textarea> im Langtext wuerde aus dem Formular ausbrechen.
    hstrl.Add('<textarea cols="1" rows="1" name="warenkorb">'+#13#10+
              TIDSConnectHelper.HtmlEscape(hstr.ToString)+#13#10+'</textarea>');
    hstrl.Add(HiddenField('action','WKS',3));
    //Laut Spezifikation muss die Hook-URL "in jedem Fall mitgesendet werden" -
    //frueher fehlte sie bei _DontWait. Dann wird nur nicht auf die
    //Rueckuebertragung gewartet.
    hstrl.Add(HiddenField('hookurl',HookUrlWithSid(sid),256));
    hstrl.Add('</form></body></html>');
    //Leerer Dateiname bedeutet: im integrierten Browser anzeigen.
    if _DontWait then
      Result := ShowFormAndFetch(hstrl,_TmpFilename,'',nil,0)
    else
      Result := ShowFormAndFetch(hstrl,_TmpFilename,HookUrlWithSid(sid),_Warenkorb,IDSCONNECT_HOOKURL_TIMEOUT);
  finally
    hstrl.Free;
    hstr.Free;
  end;
end;

{ TIDSConnect.TValidateCertificatHelper }

procedure TIDSConnect.TValidateCertificatHelper.DoValidateCertificateEvent(
  const Sender: TObject; const ARequest: TURLRequest;
  const Certificate: TCertificate; var Accepted: Boolean);
begin
  //Wichtig: Dieses Ereignis ist keine Zertifikatspruefung.
  //System.Net.HttpClient.Win ruft es bei JEDER HTTPS-Anfrage auf, solange
  //keine Beanstandung vorliegt (FSecureFailureReasons = []), und gibt
  //Accepted mit True vorbelegt herein - gedacht ist es fuer Certificate
  //Pinning, also fuer das nachtraegliche Ablehnen an sich gueltiger
  //Zertifikate.
  //Der Handler wird deshalb nur noch dann zugewiesen, wenn beanstandete
  //Zertifikate ausdruecklich akzeptiert werden sollen (Testumgebungen mit
  //selbstsignierten Zertifikaten). Ohne Zuweisung greift die normale
  //Pruefung des Betriebssystems.
  Accepted := true;
end;

initialization
  //Voreinstellung: nach jeder Rueckgabe die volle zugesagte Frist
  //(hookURLTimeout) auf weitere warten. Die fruehere Voreinstellung von
  //30 Sekunden verwarf Rueckgaben, die der Shop innerhalb der zugesagten
  //Frist noch sandte.
  TIDSConnect.IDSCONNECT_MULTIPLERESULT_FOLLOWUP := 0;

end.
