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
  System.SysUtils,System.Classes,System.Contnrs,System.DateUtils
  ,System.StrUtils,System.Types,System.Generics.Collections,System.UITypes
  ,Vcl.Dialogs, WinApi.ShellAPI, WinApi.Windows,Vcl.Controls
  ,System.Net.HttpClient,System.Net.URLClient,System.Net.Mime
  ,Xml.XMLIntf, Xml.XMLDoc, Xml.xmldom
  ,intf.IDSConnectTypes,intf.IDSConnectDlgWebBrowser,intf.IDSConnectDlgWait
  ;

type
  TIDSConnectOnException = reference to procedure (const _Message : String; _E : Exception);

  TIDSConnect = class(TObject)
  public class var
    IDSCONNECT_HOOKURL : String;
    //Nur fuer Testumgebungen mit selbstsignierten Zertifikaten auf true setzen.
    //Im Normalbetrieb bleibt die Zertifikatspruefung des Betriebssystems aktiv.
    IDSCONNECT_ALLOW_INVALID_CERT : Boolean;
    //Optionaler Fehler-Callback. Fruehere Versionen haben Parser- und
    //Netzwerkfehler in leeren except-Bloecken verschluckt.
    IDSCONNECT_ONERROR : TIDSConnectOnException;
    //Wie lange (in Sekunden) beim Warenkorb senden/empfangen auf die
    //Rueckuebertragung gewartet wird. 0 = ohne Zeitbegrenzung warten, bis der
    //Anwender abbricht. Fuer die Artikelsuche gibt es ab IDS 2.5.1 den
    //eigenen Parameter hookURLTimeout an IDSConnectAS.
    IDSCONNECT_HOOKURL_TIMEOUT : Integer;
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
    //Ein einzelner, stiller Abrufversuch. Liefert nur dann true, wenn
    //tatsaechlich ein Warenkorb angekommen ist und gelesen werden konnte.
    class function TryFetchResult(const _Url : String;_Warenkorb : TIDSConnect_Warenkorb) : Boolean;
    //Wartet mit Fortschrittsdialog, bis die Rueckuebertragung eingetroffen
    //ist, der Anwender abbricht oder das Timeout ablaeuft.
    class function WaitForResult(const _Url : String;_Warenkorb : TIDSConnect_Warenkorb;
                                 _TimeoutSec : Integer) : Boolean;
    class function BuildFormHeader(const _Title : String) : String;
    class function HiddenField(const _Name,_Value : String; _MaxLength : Integer = 0) : String;
    class function SaveFormToFile(_Form : TStrings; const _TmpFilename : String) : Boolean;
    class function OpenInBrowser(const _TmpFilename : String) : Boolean;
  public
    class procedure IDSConnectADT(const _ServiceURL,_Cst,_UN,_Pwd,_ArtNr,_TmpFilename : String);
    class function  IDSConnectWKE(const _ServiceURL,_Cst,_UN,_Pwd,_TmpFilename : String;_Warenkorb : TIDSConnect_Warenkorb) : Boolean;
    class function  IDSConnectWKS(_ServiceURL,_Cst,_UN,_Pwd,_TmpFilename : String;_Warenkorb : TIDSConnect_Warenkorb;_DontWait : Boolean = false) : Boolean;
    //_MultipleResult und _HookUrlTimeout sind ab IDS 2.5.1 definiert:
    //_MultipleResult = true  -> die Handwerkssoftware unterstuetzt mehrfache Uebertragungen an die HookUrl
    //_HookUrlTimeout > 0     -> Angabe in Sekunden, wie lange die HookUrl aktiv bleibt
    class function  IDSConnectAS(_ServiceURL,_Cst,_UN,_Pwd,_TmpFilename,_SearchString : String;_Warenkorb : TIDSConnect_Warenkorb;
                                 _MultipleResult : Boolean = false;_HookUrlTimeout : Integer = 0) : Boolean;
  end;

  TIDSConnectHelper = class(TObject)
  public
    class function RohstoffStrToRohstoff(const _Val: String): TIDSConnect_Rohstoff;
    class function RohstoffToRohstoffStr(const _Val: TIDSConnect_Rohstoff): String;
    class function StrToFloat(_Val: String; _Default: double): double;
    class function FloatToStr(const _Val: double; _Decimals: Integer): String;
    class function QuToQuStrInternal(const _Val: TIDSConnect_QU): String;
    class function QuToQuStr(const _Val: TIDSConnect_QU): String;
    class function QuStrToQu(const _Val: String): TIDSConnect_QU;
    class function DateStrToDate(const _Val : String) : TDate;
    class function TimeStrToTime(const _Val : String) : TTime;
    class function DateToDateStr(const _Val : TDate) : String;
    class function TimeToTimeStr(const _Val : TTime) : String;
    class function VersionFromStr(const _Val: String): TIDSConnect_Version;
    class function VersionToStr(const _Val: TIDSConnect_Version): String;
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
    function  UnusedObj(_Node: IXMLNode): Boolean;
//    procedure ProtocolErrorObj(_Node: IXMLNode);
//    //procedure Protocol (const _Msg : String;_Type : TProtocolEventType);
//    procedure ProtocolUnknownObj(_Node : IXMLNode);
  private
    function  idsWarenkorb(_Node : IXMLNode) : Boolean;
    function  idsWarenkorbInfo(_Node : IXMLNode;_obj : TIDSConnect_WarenkorbInfo) : Boolean;
    function  idsOrder(_Node : IXMLNode; _Obj : TIDSConnect_Order) : Boolean;
    function  idsOrderInfo(_Node : IXMLNode;_Obj : TIDSConnect_OrderInfo) : Boolean;
    function  idsOrderItem(_Node : IXMLNode;_Obj : TIDSConnect_OrderItemList) : Boolean;
    function  idsReferenz(_Node : IXMLNode;_Obj : TIDSConnect_Referenz) : Boolean;
    function  idsRohstoffanteil(_Node : IXMLNode;_Obj : TIDSConnect_RohstoffanteilList) : Boolean;
    function  idsRefItems(_Node : IXMLNode;_Obj : TIDSConnect_OrderItem) : Boolean;
    function  idsSupplierInfo(_Node : IXMLNode;_Obj : TIDSConnect_SupplierInfo) : Boolean;
    function  idsCustomerInfo(_Node : IXMLNode;_Obj : TIDSConnect_CustomerInfo) : Boolean;
    function  idsDeliveryPlaceInfo(_Node : IXMLNode;_Obj : TIDSConnect_DeliveryPlaceInfo) : Boolean;
    function  idsAddress(_Node : IXMLNode;_Obj : TIDSConnect_Address) : Boolean;
  public
    function LoadFromFile(const _Filename : String) : Boolean;
    function LoadFromStream(_Stream : TStream) : Boolean;
    function SaveToString(_Val : TStringBuilder) : Boolean;
    //function SaveToFile(_Options : TIDS_Warenkorb_GenerateOptions;_Filename : String) : Boolean;
  end;

implementation

const
  TIDSConnect_XMLNameSpace = 'http://www.itek.de/Shop-Anbindung/Warenkorb/';
  TIDSConnect_XMLSchemaSendShoppingCart_2_5      = TIDSConnect_XMLNameSpace+'warenkorb_senden_2_5.xsd';
  TIDSConnect_XMLSchemaSendShoppingCart_2_5_1    = TIDSConnect_XMLNameSpace+'warenkorb_senden_2_5_1.xsd';
  TIDSConnect_XMLSchemaReceiveShoppingCart_2_5   = TIDSConnect_XMLNameSpace+'warenkorb_empfangen_2_5.xsd';
  TIDSConnect_XMLSchemaReceiveShoppingCart_2_5_1 = TIDSConnect_XMLNameSpace+'warenkorb_empfangen_2_5_1.xsd';
  //Aktuelle Schnittstellenversion, die diese Unit erzeugt
  TIDSConnect_CurrentVersionStr = '2.5.1';

{ TIDSConnectHelper }

class function TIDSConnectHelper.RohstoffStrToRohstoff(const _Val: String): TIDSConnect_Rohstoff;
begin
  if SameText('AL',_Val) then
    Result := TIDSConnect_Rohstoff.idsConnectR_AL else
  if SameText('PB',_Val) then
    Result := TIDSConnect_Rohstoff.idsConnectR_PB else
  if SameText('CR',_Val) then
    Result := TIDSConnect_Rohstoff.idsConnectR_CR else
  if SameText('AU',_Val) then
    Result := TIDSConnect_Rohstoff.idsConnectR_AU else
  if SameText('CD',_Val) then
    Result := TIDSConnect_Rohstoff.idsConnectR_CD else
  if SameText('CU',_Val) then
    Result := TIDSConnect_Rohstoff.idsConnectR_CU else
  if SameText('MG',_Val) then
    Result := TIDSConnect_Rohstoff.idsConnectR_MG else
  if SameText('NI',_Val) then
    Result := TIDSConnect_Rohstoff.idsConnectR_NI else
  if SameText('PL',_Val) then
    Result := TIDSConnect_Rohstoff.idsConnectR_PL else
  if SameText('AG',_Val) then
    Result := TIDSConnect_Rohstoff.idsConnectR_AG else
  if SameText('W',_Val) then
    Result := TIDSConnect_Rohstoff.idsConnectR_W else
  if SameText('ZN',_Val) then
    Result := TIDSConnect_Rohstoff.idsConnectR_ZN else
  if SameText('SN',_Val) then
    Result := TIDSConnect_Rohstoff.idsConnectR_SN else
  if SameText('MS',_Val) then
    Result := TIDSConnect_Rohstoff.idsConnectR_MS else
  if SameText('MK',_Val) then
    Result := TIDSConnect_Rohstoff.idsConnectR_MK else
    Result := TIDSConnect_Rohstoff.idsConnectR_CU;
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
begin
  //Reihenfolge ist wichtig: & muss zuerst ersetzt werden
  Result := _Val.Replace('&','&amp;',[rfReplaceAll])
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
    SetLength(Result,_MaxLength);
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
begin
  //Auch aeltere Versionen werden erkannt - fruehere Antworten mit
  //<Version>1.3</Version> liefen sonst auf Unkown und erzeugten beim
  //erneuten Senden ein leeres <Version>-Element
  if SameText(_Val,'2.5.1') then
    Result := TIDSConnect_Version.idsConnectVersion_2_5_1 else
  if SameText(_Val,'2.5') then
    Result := TIDSConnect_Version.idsConnectVersion_2_5 else
  if SameText(_Val,'2.3') then
    Result := TIDSConnect_Version.idsConnectVersion_2_3 else
  if SameText(_Val,'2.0') then
    Result := TIDSConnect_Version.idsConnectVersion_2_0 else
  if SameText(_Val,'1.3') then
    Result := TIDSConnect_Version.idsConnectVersion_1_3 else
    Result := TIDSConnect_Version.idsConnectVersion_Unkown;
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
  if SameText('CMQ',_Val) then
    Result := TIDSConnect_QU.idsConnectQu_CMQ else
  if SameText('CMK',_Val) then
    Result := TIDSConnect_QU.idsConnectQu_CMK else
  if SameText('CMT',_Val) then
    Result := TIDSConnect_QU.idsConnectQu_CMT else
  if SameText('DZN',_Val) then
    Result := TIDSConnect_QU.idsConnectQu_DZN else
  if SameText('GRM',_Val) then
    Result := TIDSConnect_QU.idsConnectQu_GRM else
  if SameText('HLT',_Val) then
    Result := TIDSConnect_QU.idsConnectQu_HLT else
  if SameText('KGM',_Val) then
    Result := TIDSConnect_QU.idsConnectQu_KGM else
  if SameText('KTM',_Val) then
    Result := TIDSConnect_QU.idsConnectQu_KTM else
  if SameText('LTR',_Val) then
    Result := TIDSConnect_QU.idsConnectQu_LTR else
  if SameText('MMT',_Val) then
    Result := TIDSConnect_QU.idsConnectQu_MMT else
  if SameText('MTK',_Val) then
    Result := TIDSConnect_QU.idsConnectQu_MTK else
  if SameText('MTQ',_Val) then
    Result := TIDSConnect_QU.idsConnectQu_MTQ else
  if SameText('MTR',_Val) then
    Result := TIDSConnect_QU.idsConnectQu_MTR else
  if SameText('PCE',_Val) then
    Result := TIDSConnect_QU.idsConnectQu_PCE else
  if SameText('PR',_Val) then
    Result := TIDSConnect_QU.idsConnectQu_PR else
  if SameText('SET',_Val) then
    Result := TIDSConnect_QU.idsConnectQu_SET else
  if SameText('TNE',_Val) then
    Result := TIDSConnect_QU.idsConnectQu_TNE else
    Result := TIDSConnect_QU.idsConnectQu_PCE;
end;

{ TIDSConnect_WarenkorbHelper }

function TIDSConnect_WarenkorbHelper.idsAddress(_Node: IXMLNode;
  _Obj: TIDSConnect_Address): Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to _Node.ChildNodes.Count -1 do
  begin
    if UnusedObj(_Node.ChildNodes[i]) then continue;

    if SameText(_Node.ChildNodes[i].NodeName,'Name1') then
    begin
      _Obj.Name1 := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Name2') then
    begin
      _Obj.Name2 := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Name3') then
    begin
      _Obj.Name3 := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Name4') then
    begin
      _Obj.Name4 := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Street') then
    begin
      _Obj.Street := _Node.ChildNodes[i].Text;
      //Damit Aufrufer, die nur Street1 auswerten, auch 2.5-Daten sehen
      if _Obj.Street1 = '' then
        _Obj.Street1 := _Obj.Street;
      continue;
    end;
    //Street1..Street3 ersetzen ab IDS 2.5.1 das einzelne Street-Element
    if SameText(_Node.ChildNodes[i].NodeName,'Street1') then
    begin
      _Obj.Street1 := _Node.ChildNodes[i].Text;
      if _Obj.Street = '' then
        _Obj.Street := _Obj.Street1;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Street2') then
    begin
      _Obj.Street2 := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Street3') then
    begin
      _Obj.Street3 := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'PCode') then
    begin
      _Obj.PCode := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'City') then
    begin
      _Obj.City := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Country') then
    begin
      _Obj.Country := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'ILN') then
    begin
      _Obj.ILN := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Contact') then
    begin
      _Obj.Contact := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Phone') then
    begin
      _Obj.Phone := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Fax') then
    begin
      _Obj.Fax := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Email') then
    begin
      _Obj.Email := _Node.ChildNodes[i].Text;
      continue;
    end;
    //ProtocolUnknownObj(_Node.ChildNodes[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsCustomerInfo(_Node: IXMLNode;
  _Obj: TIDSConnect_CustomerInfo): Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to _Node.ChildNodes.Count -1 do
  begin
    if UnusedObj(_Node.ChildNodes[i]) then continue;

    if SameText(_Node.ChildNodes[i].NodeName,'IDNo') then
    begin
      _Obj.IDNo := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Address') then
    begin
      Result := idsAddress(_Node.ChildNodes[i],_Obj.Address);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.ChildNodes[i]);
        break;
      end else
        continue;
    end;

    //ProtocolUnknownObj(_Node.ChildNodes[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsDeliveryPlaceInfo(_Node: IXMLNode;
  _Obj: TIDSConnect_DeliveryPlaceInfo): Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to _Node.ChildNodes.Count -1 do
  begin
    if UnusedObj(_Node.ChildNodes[i]) then continue;

    if SameText(_Node.ChildNodes[i].NodeName,'IDNo') then
    begin
      _Obj.IDNo := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Address') then
    begin
      Result := idsAddress(_Node.ChildNodes[i],_Obj.Address);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.ChildNodes[i]);
        break;
      end else
        continue;
    end;
    //Geo-Daten ab IDS 2.5.1
    if SameText(_Node.ChildNodes[i].NodeName,'GeoLat') then
    begin
      _Obj.GeoLat := TIDSConnectHelper.StrToFloat(_Node.ChildNodes[i].Text,0);
      _Obj.HasGeoLocation := true;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'GeoLang') then
    begin
      _Obj.GeoLang := TIDSConnectHelper.StrToFloat(_Node.ChildNodes[i].Text,0);
      _Obj.HasGeoLocation := true;
      continue;
    end;

    //ProtocolUnknownObj(_Node.ChildNodes[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsOrder(_Node: IXMLNode; _Obj : TIDSConnect_Order): Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to _Node.ChildNodes.Count -1 do
  begin
    if UnusedObj(_Node.ChildNodes[i]) then continue;

    if SameText(_Node.ChildNodes[i].NodeName,'OrderInfo') then
    begin
      Result := idsOrderInfo(_Node.ChildNodes[i],_Obj.OrderInfo);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.ChildNodes[i]);
        break;
      end else
        continue;
     end;

    if SameText(_Node.ChildNodes[i].NodeName,'SupplierInfo') then
    begin
      Result := idsSupplierInfo(_Node.ChildNodes[i],_Obj.SupplierInfo);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.ChildNodes[i]);
        break;
      end else
        continue;
     end;

    if SameText(_Node.ChildNodes[i].NodeName,'CustomerInfo') then
    begin
      Result := idsCustomerInfo(_Node.ChildNodes[i],_Obj.CustomerInfo);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.ChildNodes[i]);
        break;
      end else
        continue;
     end;

    if SameText(_Node.ChildNodes[i].NodeName,'DeliveryPlaceInfo') then
    begin
      Result := idsDeliveryPlaceInfo(_Node.ChildNodes[i],_Obj.DeliveryPlaceInfo);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.ChildNodes[i]);
        break;
      end else
        continue;
     end;

    if SameText(_Node.ChildNodes[i].NodeName,'OrderItem') then
    begin
      Result := idsOrderItem(_Node.ChildNodes[i],_Obj.OrderItems);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.ChildNodes[i]);
        break;
      end else
        continue;
    end;

    //ProtocolUnknownObj(_Node.ChildNodes[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsReferenz(_Node: IXMLNode;
  _Obj: TIDSConnect_Referenz): Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to _Node.ChildNodes.Count -1 do
  begin
    if UnusedObj(_Node.ChildNodes[i]) then continue;

    if SameText(_Node.ChildNodes[i].NodeName,'ReferenzNumber') then
    begin
      _Obj.ReferenzNumber := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'ReferenzDate') then
    begin
      _Obj.ReferenzDate := TIDSConnectHelper.DateStrToDate(_Node.ChildNodes[i].Text);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'ReferenzType') then
    begin
      _Obj.ReferenzType := TIDSConnectHelper.ReferenzTypeFromStr(_Node.ChildNodes[i].Text);
      continue;
    end;
    //ReferenzLine gibt es nur in den Positionsdaten
    if SameText(_Node.ChildNodes[i].NodeName,'ReferenzLine') and (_Obj is TIDSConnect_ReferenzPos) then
    begin
      TIDSConnect_ReferenzPos(_Obj).ReferenzLine := _Node.ChildNodes[i].Text;
      continue;
    end;

    //ProtocolUnknownObj(_Node.ChildNodes[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsOrderInfo(_Node: IXMLNode;
  _Obj: TIDSConnect_OrderInfo): Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to _Node.ChildNodes.Count -1 do
  begin
    if UnusedObj(_Node.ChildNodes[i]) then continue;

    //Referenzen ersetzen ab IDS 2.5.1 InquiryNo/OfferNo/PartNo/OrderConfNo
    if SameText(_Node.ChildNodes[i].NodeName,'Referenz') then
    begin
      Result := idsReferenz(_Node.ChildNodes[i],_Obj.Referenzen.AddItem);
      if not Result then
        break
      else
        continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'InquiryNo') then
    begin
      _Obj.InquiryNo := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'OfferNo') then
    begin
      _Obj.OfferNo := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'PartNo') then
    begin
      _Obj.PartNo := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'OrderConfNo') then
    begin
      _Obj.OrderConfNo := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'DeliveryWeek') then
    begin
      _Obj.DeliveryWeek := StrToIntDef(_Node.ChildNodes[i].Text,0);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'DeliveryYear') then
    begin
      _Obj.DeliveryYear := StrToIntDef(_Node.ChildNodes[i].Text,0);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'DeliveryDate') then
    begin
      _Obj.DeliveryDate := TIDSConnectHelper.DateStrToDate(_Node.ChildNodes[i].Text);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'ModeOfShipment') then
    begin
      if (Pos('LIEFERUNG',UpperCase(_Node.ChildNodes[i].Text))>0) then
        _Obj.ModeOfShipment := idsConnectMos_Lieferung
      else
        _Obj.ModeOfShipment := idsConnectMos_Abholung;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'ZusatzText') then
    begin
      _Obj.ZusatzText := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Kommission') then
    begin
      _Obj.Kommission := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Cur') then
    begin
      _Obj.Cur := _Node.ChildNodes[i].Text;
      continue;
    end;

    //ProtocolUnknownObj(_Node.ChildNodes[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsOrderItem(_Node: IXMLNode;
  _Obj: TIDSConnect_OrderItemList): Boolean;
var
  i : Integer;
  itm : TIDSConnect_OrderItem;
begin
  Result := true;
  itm := _Obj.AddItem;

  for i := 0 to _Node.ChildNodes.Count -1 do
  begin
    if UnusedObj(_Node.ChildNodes[i]) then continue;

    if SameText(_Node.ChildNodes[i].NodeName,'ItemChara') then
    begin
      if SameText('alternate',_Node.ChildNodes[i].Text) then
        itm.ItemChara := idsConnectIc_alternate
      else
      if SameText('provis',_Node.ChildNodes[i].Text) then
        itm.ItemChara := idsConnectIc_provis
      else
        itm.ItemChara := idsConnectIc_normal;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'RefItems') then
    begin
      Result := idsRefItems(_Node.ChildNodes[i],itm);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.ChildNodes[i]);
        break;
      end else
        continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'EAN') then
    begin
      itm.EAN := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'ManufacturerID') then
    begin
      itm.ManufacturerID := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'ManufacturerIDType') then
    begin
      itm.ManufacturerIDType := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'ArtNo') then
    begin
      itm.ArtNo := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Qty') then
    begin
      itm.Qty := TIDSConnectHelper.StrToFloat(_Node.ChildNodes[i].Text,0);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'QU') then
    begin
      itm.QU := TIDSConnectHelper.QuStrToQu(_Node.ChildNodes[i].Text);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Kurztext') then
    begin
      itm.Kurztext := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Langtext') then
    begin
      itm.Langtext := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'OfferPrice') then
    begin
      itm.OfferPrice := TIDSConnectHelper.StrToFloat(_Node.ChildNodes[i].Text,0);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'NetPrice') then
    begin
      itm.NetPrice := TIDSConnectHelper.StrToFloat(_Node.ChildNodes[i].Text,0);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'PriceBasis') then
    begin
      itm.PriceBasis := TIDSConnectHelper.StrToFloat(_Node.ChildNodes[i].Text,0);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'VAT') then
    begin
      itm.VAT := TIDSConnectHelper.StrToFloat(_Node.ChildNodes[i].Text,0);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'TechnClarification') then
    begin
      itm.TechnClarification := TIDSConnectHelper.StrToTechnClarification(_Node.ChildNodes[i].Text);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Hinweis') then
    begin
      itm.Hinweis := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Fehlercode') then
    begin
      if SameTExt(_Node.ChildNodes[i].Text,'1') then
        itm.Fehlercode := idsConnectFc_1;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Fehlertext') then
    begin
      itm.Fehlertext := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Zuschlag') then
    begin
      itm.Zuschlag := TIDSConnectHelper.StrToFloat(_Node.ChildNodes[i].Text,0);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Rohstoffanteil') then
    begin
      Result := idsRohstoffanteil(_Node.ChildNodes[i],itm.Rohstoffanteile);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.ChildNodes[i]);
        break;
      end else
        continue;
    end;
    //Divers wurde bisher nie eingelesen
    if SameText(_Node.ChildNodes[i].NodeName,'Divers') then
    begin
      itm.Divers := SameText(_Node.ChildNodes[i].Text,'true') or (_Node.ChildNodes[i].Text = '1');
      continue;
    end;
    //ab IDS 2.5.1
    if SameText(_Node.ChildNodes[i].NodeName,'SumMaterialSurcharges') then
    begin
      itm.SumMaterialSurcharges := TIDSConnectHelper.StrToFloat(_Node.ChildNodes[i].Text,0);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'DiscountableAmount') then
    begin
      itm.DiscountableAmount := TIDSConnectHelper.StrToFloat(_Node.ChildNodes[i].Text,0);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Referenz') then
    begin
      Result := idsReferenz(_Node.ChildNodes[i],itm.Referenzen.AddItem);
      if not Result then
        break
      else
        continue;
    end;

    //ProtocolUnknownObj(_Node.ChildNodes[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsRefItems(_Node: IXMLNode;
  _Obj: TIDSConnect_OrderItem): Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to _Node.ChildNodes.Count -1 do
  begin
    if UnusedObj(_Node.ChildNodes[i]) then continue;

    if SameText(_Node.ChildNodes[i].NodeName,'Customer') then
    begin
      _Obj.RefItems_Customer := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'CustomerSubNo') then
    begin
      _Obj.RefItems_CustomerSubNo := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Supplier') then
    begin
      _Obj.RefItems_Supplier := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'SupplierSubNo') then
    begin
      _Obj.RefItems_SupplierSubNo := _Node.ChildNodes[i].Text;
      continue;
    end;

    //ProtocolUnknownObj(_Node.ChildNodes[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsRohstoffanteil(_Node: IXMLNode;
  _Obj: TIDSConnect_RohstoffanteilList): Boolean;
var
  i : Integer;
  itm : TIDSConnect_Rohstoffanteil;
begin
  Result := true;
  itm := _Obj.AddItem;

  for i := 0 to _Node.ChildNodes.Count -1 do
  begin
    if UnusedObj(_Node.ChildNodes[i]) then continue;

    if SameText(_Node.ChildNodes[i].NodeName,'Rohstoff') then
    begin
      itm.Rohstoff := TIDSConnectHelper.RohstoffStrToRohstoff(_Node.ChildNodes[i].Text);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Gewichtsanteilswert') then
    begin
      itm.Gewichtsanteilswert := TIDSConnectHelper.StrToFloat(_Node.ChildNodes[i].Text,0);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Gewichtsanteilseinheit') then
    begin
      itm.Gewichtsanteilseinheit := TIDSConnectHelper.QuStrToQu(_Node.ChildNodes[i].Text);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Basiswert') then
    begin
      itm.Basiswert := TIDSConnectHelper.StrToFloat(_Node.ChildNodes[i].Text,0);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Basiseinheit') then
    begin
      itm.Basiseinheit := TIDSConnectHelper.QuStrToQu(_Node.ChildNodes[i].Text);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Basisnotierung') then
    begin
      itm.Basisnotierung := TIDSConnectHelper.StrToFloat(_Node.ChildNodes[i].Text,0);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'NotierungAktuell') then
    begin
      itm.NotierungAktuell := TIDSConnectHelper.StrToFloat(_Node.ChildNodes[i].Text,0);
      continue;
    end;

    //ProtocolUnknownObj(_Node.ChildNodes[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsSupplierInfo(_Node: IXMLNode;
  _Obj: TIDSConnect_SupplierInfo): Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to _Node.ChildNodes.Count -1 do
  begin
    if UnusedObj(_Node.ChildNodes[i]) then continue;

    if SameText(_Node.ChildNodes[i].NodeName,'IDNo') then
    begin
      _Obj.IDNo := _Node.ChildNodes[i].Text;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Address') then
    begin
      Result := idsAddress(_Node.ChildNodes[i],_Obj.Address);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.ChildNodes[i]);
        break;
      end else
        continue;
    end;

    //ProtocolUnknownObj(_Node.ChildNodes[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsWarenkorb(_Node: IXMLNode): Boolean;
var
  i : Integer;
begin
  Result := false;

  for i := 0 to _Node.ChildNodes.Count -1 do
  begin
    if UnusedObj(_Node.ChildNodes[i]) then continue;
    if SameText(_Node.ChildNodes[i].NodeName,'WarenkorbInfo') then
    begin
      Result := idsWarenkorbInfo(_Node.ChildNodes[i],WarenkorbInfo);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.ChildNodes[i]);
        break;
      end else
        continue;
     end;

    if SameText(_Node.ChildNodes[i].NodeName,'Order') then
    begin
      Result := idsOrder(_Node.ChildNodes[i],Order);
      if not Result then
      begin
        //ProtocolErrorObj(_Node.ChildNodes[i]);
        break;
      end else
        continue;
     end;

     //ProtocolUnknownObj(_Node.ChildNodes[i]);
  end;
end;

function TIDSConnect_WarenkorbHelper.idsWarenkorbInfo(_Node: IXMLNode;
  _obj: TIDSConnect_WarenkorbInfo): Boolean;
var
  i : Integer;
begin
  Result := true;
  for i := 0 to _Node.ChildNodes.Count -1 do
  begin
    if UnusedObj(_Node.ChildNodes[i]) then continue;
    if SameText(_Node.ChildNodes[i].NodeName,'Date') then
    begin
      _Obj.Date := TIDSConnectHelper.DateStrToDate(_Node.ChildNodes[i].Text);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Time') then
    begin
      _Obj.Time := TIDSConnectHelper.TimeStrToTime(_Node.ChildNodes[i].Text);
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'RueckgabeKZ') then
    begin
      if (Pos('BESTELLUNG',UpperCase(_Node.ChildNodes[i].Text))>0) then
        _Obj.RueckgabeKZ := idsConnectRKZ_WarenkorbrueckgabeMitBestellung
      else
        _Obj.RueckgabeKZ := idsConnectRKZ_Warenkorbrueckgabe;
      continue;
    end;
    if SameText(_Node.ChildNodes[i].NodeName,'Version') then
    begin
      _Obj.Version := TIDSConnectHelper.VersionFromStr(_Node.ChildNodes[i].Text);
      continue;
    end;
    //ProtocolUnknownObj(_Node.ChildNodes[i]);
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
  lBuffer : IXMLDocument;
  lStringList : TStringList;
  lStringStream : TStringStream;
  lDecl : String;
  lXml : String;
begin
  Result := false;
  Clear;

  lBuffer := TXMLDocument.Create(nil);

  try
    lStringList := nil;
    lStringStream := nil;
    try
      //Beide Objekte innerhalb des try anlegen, sonst leckt das erste,
      //wenn das zweite Create fehlschlaegt
      lStringList := TStringList.Create;
      lStringStream := TStringStream.Create;

      _Stream.Position := 0;
      lStringStream.LoadFromStream(_Stream);
      _Stream.Position := 0;

      //Die Encoding-Erkennung war frueher exakt auf encoding="ISO-8859-1"
      //festgelegt; einfache Anfuehrungszeichen oder Kleinschreibung fielen
      //dadurch faelschlich in den UTF-8-Zweig
      lDecl := Copy(lStringStream.DataString,1,200);
      if ContainsText(lDecl,'8859') or ContainsText(lDecl,'1252') or ContainsText(lDecl,'windows-125') then
        lStringList.LoadFromStream(_Stream,TEncoding.ANSI)
      else
        lStringList.LoadFromStream(_Stream,TEncoding.UTF8);

      lXml := lStringList.Text;
      if ContainsText(lXml,'<head/>') then
        lXml := ReplaceText(lXml,'<head/>','');
      //MSXML lehnt einen Unicode-String ab, dessen Deklaration eine
      //Byte-Kodierung nennt ("Switch from current encoding to specified
      //encoding not supported") - deshalb wird die Deklaration angeglichen
      if ContainsText(Copy(lXml,1,200),'encoding=') then
      begin
        lXml := ReplaceText(lXml,'encoding="ISO-8859-1"','encoding="UTF-8"');
        lXml := ReplaceText(lXml,'encoding=''ISO-8859-1''','encoding="UTF-8"');
        lXml := ReplaceText(lXml,'encoding="windows-1252"','encoding="UTF-8"');
        lXml := ReplaceText(lXml,'encoding=''windows-1252''','encoding="UTF-8"');
      end;
      lBuffer.LoadFromXML(lXml);
    finally
      lStringStream.Free;
      lStringList.Free;
    end;

    if lBuffer.DocumentElement = nil then
      exit;

    if SameText(lBuffer.DocumentElement.NodeName,'Warenkorb') then
      Result := idsWarenkorb(lBuffer.DocumentElement)
  except
    on E:Exception do
    begin
      //Parserfehler wurden hier frueher spurlos verschluckt
      Result := false;
      TIDSConnect.ReportError('Der Warenkorb konnte nicht gelesen werden: '+E.Message,E);
    end;
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
    if (not lIs251) and (_Obj.Name4 <> '') then
      _Val.AppendFormat('  '+'<Name4>%s</Name4>'+#13#10,[TIDSConnectHelper.XmlText(_Obj.Name4,40)]);

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
begin
  Result := false;
  if _Val = nil then
    exit;

  lIs251 := WarenkorbInfo.Version >= idsConnectVersion_2_5_1;

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
  _Val.Append('  '+'<Version>'+TIDSConnectHelper.VersionToStr(WarenkorbInfo.Version)+'</Version>'+#13#10);
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

function TIDSConnect_WarenkorbHelper.UnusedObj(_Node: IXMLNode): Boolean;
begin
  //Neben Textknoten muessen auch Kommentare und CDATA-Abschnitte uebersprungen
  //werden, sonst laufen sie in die Elementnamen-Vergleiche
  Result := SameText(_Node.NodeName,'#text') or
            SameText(_Node.NodeName,'#comment') or
            SameText(_Node.NodeName,'#cdata-section');
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

class function TIDSConnect.TryFetchResult(const _Url: String;
  _Warenkorb: TIDSConnect_Warenkorb): Boolean;
var
  str : TMemoryStream;
  http : THTTPClient;
  vcHelper : TIDSConnect.TValidateCertificatHelper;
begin
  Result := false;
  if (_Url = '') or (_Warenkorb = nil) then
    exit;

  str := TMemoryStream.Create;
  http := THTTPClient.Create;
  vcHelper := TIDSConnect.TValidateCertificatHelper.Create;
  try
    http.OnValidateServerCertificate := vcHelper.DoValidateCertificateEvent;
    //Kurze Timeouts, damit der Warte-Dialog zwischen zwei Versuchen bedienbar
    //bleibt - ein einzelner Versuch darf das Warten nicht blockieren
    http.ConnectionTimeout := 5000;
    http.ResponseTimeout := 10000;
    try
      //Solange noch nichts vorliegt, antwortet der Callback-Endpunkt mit 404
      //bzw. mit einem leeren Rumpf. Das ist kein Fehler, sondern der
      //Normalfall waehrend des Wartens - deshalb wird hier nichts gemeldet.
      if http.Get(_Url,str).StatusCode <> 200 then
        exit;
      if str.Size = 0 then
        exit;
      Result := _Warenkorb.LoadFromStream(str);
    except
      //Netzwerkaussetzer beenden das Warten nicht, der naechste Versuch folgt
      on E:Exception do
        Result := false;
    end;
  finally
    vcHelper.Free;
    http.Free;
    str.Free;
  end;
end;

class function TIDSConnect.WaitForResult(const _Url: String;
  _Warenkorb: TIDSConnect_Warenkorb; _TimeoutSec: Integer): Boolean;
begin
  //Frueher stand hier ein TaskMessageDlg mit genau einem Abrufversuch
  //danach: war der Warenkorb noch nicht angekommen, scheiterte der Vorgang
  //ohne Wiederholung und ohne Diagnose.
  Result := TIDSConnectDlgWait.Execute(
              'Warte auf Abschluss',
              'Bitte schliessen Sie den Vorgang im Browser ab.'+sLineBreak+
              'Der Warenkorb wird danach automatisch uebernommen.',
              _TimeoutSec,
              function : Boolean
              begin
                Result := TryFetchResult(_Url,_Warenkorb);
              end);
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

class procedure TIDSConnect.IDSConnectADT(const _ServiceURL, _Cst, _UN, _Pwd,
  _ArtNr, _TmpFilename: String);
var
  hstrl : TStringList;
begin
  if _ServiceURL.IsEmpty then
    exit;
  if _Cst.IsEmpty and _UN.IsEmpty and _Pwd.IsEmpty then
    exit;
  if _ArtNr = '' then
    exit;
  hstrl := TStringList.Create;
  try
    hstrl.Add('<!doctype html>');
    hstrl.Add(BuildFormHeader('ADT'));
    hstrl.Add('<body onload="document.forms[''adt''].submit();">');
    hstrl.Add('<form id="adt" name="adt" action="'+TIDSConnectHelper.HtmlEscape(_ServiceURL)+'" method="post" accept-charset="utf-8">');
    hstrl.Add(HiddenField('kndnr',_Cst,50));
    hstrl.Add(HiddenField('name_kunde',_UN,50));
    hstrl.Add(HiddenField('pw_kunde',_Pwd,50));
    hstrl.Add(HiddenField('version',TIDSConnect_CurrentVersionStr,5));
    hstrl.Add(HiddenField('action','ADL',3));
    hstrl.Add(HiddenField('ghnummer',_ArtNr,35));
    hstrl.Add('</form></body></html>');

    if _TmpFilename <> '' then
    begin
      if SaveFormToFile(hstrl,_TmpFilename) then
        OpenInBrowser(_TmpFilename);
    end else
      TIDSConnectDlgWebBrowser.ShowDialog(hstrl.Text,'');
  finally
    hstrl.Free;
  end;
end;

class function TIDSConnect.IDSConnectAS(_ServiceURL, _Cst, _UN, _Pwd,
  _TmpFilename, _SearchString: String; _Warenkorb: TIDSConnect_Warenkorb;
  _MultipleResult : Boolean; _HookUrlTimeout : Integer): Boolean;
var
  hstrl : TStringList;
  sid : String;
begin
  Result := false;
  if _ServiceURL.IsEmpty then
    exit;
  if _Cst.IsEmpty and _UN.IsEmpty and _Pwd.IsEmpty then
    exit;
  if TIDSConnect.IDSCONNECT_HOOKURL = '' then
    exit;
  if _TmpFilename = '' then
    exit;
  if _SearchString = '' then
    exit;
  if _Warenkorb = nil then
    exit;

  sid := TIDSConnect.GetUuid;
  hstrl := TStringList.Create;
  try
    hstrl.Add('<!doctype html>');
    hstrl.Add(BuildFormHeader('AS'));
    hstrl.Add('<body onload="document.forms[''search''].submit();">');
    hstrl.Add('<form id="search" name="search" action="'+TIDSConnectHelper.HtmlEscape(_ServiceURL)+'" method="post" accept-charset="utf-8">');
    hstrl.Add(HiddenField('kndnr',_Cst,50));
    hstrl.Add(HiddenField('name_kunde',_UN,50));
    hstrl.Add(HiddenField('pw_kunde',_Pwd,50));
    hstrl.Add(HiddenField('version',TIDSConnect_CurrentVersionStr,5));
    hstrl.Add(HiddenField('searchterm',_SearchString));
    hstrl.Add(HiddenField('action','AS',3));
    hstrl.Add(HiddenField('hookurl',HookUrlWithSid(sid),256));
    //Beide Parameter sind ab IDS 2.5.1 fuer die Artikelsuche definiert
    if _MultipleResult then
      hstrl.Add(HiddenField('multipleResult','true'));
    if _HookUrlTimeout > 0 then
      hstrl.Add(HiddenField('hookURLTimeout',IntToStr(_HookUrlTimeout)));
    hstrl.Add('</form></body></html>');
    if not SaveFormToFile(hstrl,_TmpFilename) then
      exit;
  finally
    hstrl.Free;
  end;

  if not OpenInBrowser(_TmpFilename) then
    exit;

  //Wartet mit Fortschrittsdialog und fragt die Hook-URL im Intervall ab.
  //_HookUrlTimeout ist der IDS-2.5.1-Parameter hookURLTimeout; ohne Angabe
  //wird bis zum Abbruch durch den Anwender gewartet.
  Result := WaitForResult(HookUrlWithSid(sid),_Warenkorb,_HookUrlTimeout);
end;

class function TIDSConnect.IDSConnectWKE(const _ServiceURL, _Cst, _UN, _Pwd,
  _TmpFilename: String; _Warenkorb: TIDSConnect_Warenkorb): Boolean;
var
  hstrl : TStringList;
  sid : String;
begin
  Result := false;
  if _ServiceURL.IsEmpty then
    exit;
  if _Cst.IsEmpty and _UN.IsEmpty and _Pwd.IsEmpty then
    exit;
  if TIDSConnect.IDSCONNECT_HOOKURL = '' then
    exit;
  if _TmpFilename = '' then
    exit;
  if _Warenkorb = nil then
    exit;

  sid := TIDSConnect.GetUuid;
  hstrl := TStringList.Create;
  try
    hstrl.Add('<!doctype html>');
    hstrl.Add(BuildFormHeader('WKE'));
    hstrl.Add('<body onload="document.forms[''wke''].submit();">');
    hstrl.Add('<form id="wke" name="wke" action="'+TIDSConnectHelper.HtmlEscape(_ServiceURL)+'" method="post" accept-charset="utf-8">');
    hstrl.Add(HiddenField('kndnr',_Cst,50));
    hstrl.Add(HiddenField('name_kunde',_UN,50));
    hstrl.Add(HiddenField('pw_kunde',_Pwd,50));
    //Hier stand bisher 1.3, waehrend ADT und AS 2.5 meldeten
    hstrl.Add(HiddenField('version',TIDSConnect_CurrentVersionStr,5));
    hstrl.Add(HiddenField('action','WKE',3));
    hstrl.Add(HiddenField('hookurl',HookUrlWithSid(sid),256));
    hstrl.Add('</form></body></html>');
    if not SaveFormToFile(hstrl,_TmpFilename) then
      exit;
  finally
    hstrl.Free;
  end;

  if not OpenInBrowser(_TmpFilename) then
    exit;

  //Wartet mit Fortschrittsdialog und fragt die Hook-URL im Intervall ab
  Result := WaitForResult(HookUrlWithSid(sid),_Warenkorb,IDSCONNECT_HOOKURL_TIMEOUT);
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
    exit;
  if _Cst.IsEmpty and _UN.IsEmpty and _Pwd.IsEmpty then
    exit;
  if TIDSConnect.IDSCONNECT_HOOKURL = '' then
    exit;
  if _TmpFilename = '' then
    exit;
  if _Warenkorb = nil then
    exit;

  sid := TIDSConnect.GetUuid;
  hstr := TStringBuilder.Create;
  hstrl := TStringList.Create;
  try
    if not _Warenkorb.SaveToString(hstr) then
      exit;
    hstrl.Add('<!doctype html>');
    hstrl.Add(BuildFormHeader('WKS'));
    hstrl.Add('<body onload="document.forms[''wks''].submit();">');
    hstrl.Add('<form id="wks" name="wks" action="'+TIDSConnectHelper.HtmlEscape(_ServiceURL)+'" method="post" accept-charset="utf-8">');
    hstrl.Add(HiddenField('kndnr',_Cst,50));
    hstrl.Add(HiddenField('name_kunde',_UN,50));
    hstrl.Add(HiddenField('pw_kunde',_Pwd,50));
    //Hier stand bisher 1.3, waehrend das erzeugte XML 2.5 bzw. 2.5.1 meldet
    hstrl.Add(HiddenField('version',TIDSConnect_CurrentVersionStr,5));
    //Der Browser dekodiert Entities im textarea-Inhalt vor dem Absenden.
    //Das XML muss deshalb ein zweites Mal - diesmal HTML - maskiert werden,
    //sonst kommt ein im XML korrektes &amp; als nacktes & beim Shop an und
    //ein </textarea> im Langtext wuerde aus dem Formular ausbrechen.
    hstrl.Add('<textarea cols="1" rows="1" name="warenkorb">'+#13#10+
              TIDSConnectHelper.HtmlEscape(hstr.ToString)+#13#10+'</textarea>');
    hstrl.Add(HiddenField('action','WKS',3));
    if not _DontWait then
      hstrl.Add(HiddenField('hookurl',HookUrlWithSid(sid),256));
    hstrl.Add('</form></body></html>');
    if not SaveFormToFile(hstrl,_TmpFilename) then
      exit;
  finally
    hstrl.Free;
    hstr.Free;
  end;

  if not OpenInBrowser(_TmpFilename) then
    exit;

  if _DontWait then
  begin
    Result := true;
    exit;
  end;

  //Wartet mit Fortschrittsdialog und fragt die Hook-URL im Intervall ab
  Result := WaitForResult(HookUrlWithSid(sid),_Warenkorb,IDSCONNECT_HOOKURL_TIMEOUT);
end;

{ TIDSConnect.TValidateCertificatHelper }

procedure TIDSConnect.TValidateCertificatHelper.DoValidateCertificateEvent(
  const Sender: TObject; const ARequest: TURLRequest;
  const Certificate: TCertificate; var Accepted: Boolean);
begin
  //Hier stand bedingungslos Accepted := true - damit war die
  //Serverauthentifizierung fuer einen Kanal abgeschaltet, ueber den
  //Zugangsdaten, Preise und Bestelldaten laufen.
  //Nur wenn der Anwender das ausdruecklich fuer eine Testumgebung freischaltet,
  //wird ein nicht vertrauenswuerdiges Zertifikat akzeptiert.
  Accepted := TIDSConnect.IDSCONNECT_ALLOW_INVALID_CERT;
  if not Accepted then
    TIDSConnect.ReportError('Das Serverzertifikat wurde abgelehnt: '+Certificate.Subject,nil);
end;

end.
