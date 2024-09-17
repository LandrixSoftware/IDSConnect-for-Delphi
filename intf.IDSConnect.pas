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
  ,System.StrUtils,System.Types,System.Generics.Collections
  ,Vcl.Dialogs, WinApi.ShellAPI, WinApi.Windows,Vcl.Controls
  ,System.Net.HttpClient,System.Net.URLClient,System.Net.Mime
  ,Xml.XMLIntf, Xml.XMLDoc, Xml.xmldom
  ,intf.IDSConnectTypes
  ;

type
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

  TIDSConnectOnException = reference to procedure (const _Message : String; _E : Exception);

  TIDSConnect = class(TObject)
  public class var
    IDSCONNECT_HOOKURL : String;
  private type
    TValidateCertificatHelper = class(TObject)
      procedure DoValidateCertificateEvent(const Sender: TObject;
                   const ARequest: TURLRequest; const Certificate: TCertificate;
                   var Accepted: Boolean);
    end;
  private
    class function GetUuid : String;
    class function GetStreamFromUrl(const _URL : String; _Result : TStream; _OnReceiveData: TReceiveDataEvent; _OnError : TIDSConnectOnException) : Boolean;
  public
    class procedure IDSConnectADT(const _ServiceURL,_Cst,_UN,_Pwd,_ArtNr,_TmpFilename : String);
    class function  IDSConnectWKE(const _ServiceURL,_Cst,_UN,_Pwd,_TmpFilename : String;_Warenkorb : TIDSConnect_Warenkorb) : Boolean;
    class function  IDSConnectWKS(_ServiceURL,_Cst,_UN,_Pwd,_TmpFilename : String;_Warenkorb : TIDSConnect_Warenkorb;_DontWait : Boolean = false) : Boolean;
    class function  IDSConnectAS(_ServiceURL,_Cst,_UN,_Pwd,_TmpFilename,_SearchString : String;_Warenkorb : TIDSConnect_Warenkorb) : Boolean;
  end;

implementation

const
  TIDSConnect_XMLNameSpace = 'http://www.itek.de/Shop-Anbindung/Warenkorb/';
  TIDSConnect_XMLSchemaLocationSendShoppingCart = 'http://www.itek.de/Shop-Anbindung/Warenkorb/warenkorb_senden_2_5.xsd';
  TIDSConnect_XMLSchemaLocationReceiveShoppingCart = 'http://www.itek.de/Shop-Anbindung/Warenkorb/warenkorb_empfangen_2_5.xsd';

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
  end;
end;

class function TIDSConnectHelper.StrMaxLength(const _Str: String;
  const _MaxLength: integer): String;
begin
  Result := _Str;
  if (Length(_Str)>_MaxLength) then
    SetLength(Result,_MaxLength);
end;

class function TIDSConnectHelper.StrToFloat(_Val: String; _Default: double): double;
begin
  _Val := ReplaceText(_Val,'.',',');
  Result := StrToFloatDef(_Val,_Default);
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
  case _Val of
    idsConnectTc_Yes: Result := 'Yes';
    else Result := 'No' ;//idsConnectTc_No: ;
  end;
end;

class function TIDSConnectHelper.TimeStrToTime(const _Val: String): TTime;
begin
  Result := StrToTimeDef(_Val,0);
end;

class function TIDSConnectHelper.TimeToTimeStr(const _Val: TTime): String;
begin
  Result := TimeToStr(_Val);
end;

class function TIDSConnectHelper.VersionFromStr(
  const _Val: String): TIDSConnect_Version;
begin
  if SameText(_Val,'2.5') then
    Result := TIDSConnect_Version.idsConnectVersion_2_5
  else
    Result := TIDSConnect_Version.idsConnectVersion_Unkown;
end;

class function TIDSConnectHelper.VersionToStr(
  const _Val: TIDSConnect_Version): String;
begin
  case _val of
    idsConnectVersion_2_5: Result := '2.5';
    else Result := '';
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
    TIDSConnect_QU.idsConnectQu_MTK : Result := 'cm';        // Quadrat-Meter
    TIDSConnect_QU.idsConnectQu_MTQ : Result := 'qm';        // Kubik-Meter
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
  if Length(_Val) <> 10 then
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
  Result := Format('%.'+IntToStr(_Decimals)+'f',[_Val]);
  Result := ReplaceText(Result,',','.');
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
  Result := true;
end;

function TIDSConnect_WarenkorbHelper.idsCustomerInfo(_Node: IXMLNode;
  _Obj: TIDSConnect_CustomerInfo): Boolean;
var
  i : Integer;
begin
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
  Result := true;
end;

function TIDSConnect_WarenkorbHelper.idsDeliveryPlaceInfo(_Node: IXMLNode;
  _Obj: TIDSConnect_DeliveryPlaceInfo): Boolean;
var
  i : Integer;
begin
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
  Result := true;
end;

function TIDSConnect_WarenkorbHelper.idsOrder(_Node: IXMLNode; _Obj : TIDSConnect_Order): Boolean;
var
  i : Integer;
begin
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
  Result := true;
end;

function TIDSConnect_WarenkorbHelper.idsOrderInfo(_Node: IXMLNode;
  _Obj: TIDSConnect_OrderInfo): Boolean;
var
  i : Integer;
begin
  for i := 0 to _Node.ChildNodes.Count -1 do
  begin
    if UnusedObj(_Node.ChildNodes[i]) then continue;

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
  Result := true;
end;

function TIDSConnect_WarenkorbHelper.idsOrderItem(_Node: IXMLNode;
  _Obj: TIDSConnect_OrderItemList): Boolean;
var
  i : Integer;
  itm : TIDSConnect_OrderItem;
begin
  itm := TIDSConnect_OrderItem.Create;
  _Obj.Add(itm);

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

    //ProtocolUnknownObj(_Node.ChildNodes[i]);
  end;
  Result := true;
end;

function TIDSConnect_WarenkorbHelper.idsRefItems(_Node: IXMLNode;
  _Obj: TIDSConnect_OrderItem): Boolean;
var
  i : Integer;
begin
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
  Result := true;
end;

function TIDSConnect_WarenkorbHelper.idsRohstoffanteil(_Node: IXMLNode;
  _Obj: TIDSConnect_RohstoffanteilList): Boolean;
var
  i : Integer;
  itm : TIDSConnect_Rohstoffanteil;
begin
  itm := TIDSConnect_Rohstoffanteil.Create;
  _Obj.Add(itm);

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
  Result := true;
end;

function TIDSConnect_WarenkorbHelper.idsSupplierInfo(_Node: IXMLNode;
  _Obj: TIDSConnect_SupplierInfo): Boolean;
var
  i : Integer;
begin
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
  Result := true;
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
  Result := true;
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
    LoadFromStream(str);
  finally
    str.Free;
  end;
end;

function TIDSConnect_WarenkorbHelper.LoadFromStream(_Stream: TStream): Boolean;
var
  lBuffer : IXMLDocument;
  lStringList : TStringList;
  lStringStream : TStringStream;
begin
  Result := false;
  Clear;

  lBuffer := TXMLDocument.Create(nil);

  try
    lStringList := TStringList.Create;
    lStringStream := TStringStream.Create;
    try
      try
        _Stream.Position := 0;
        lStringStream.LoadFromStream(_Stream);
        _Stream.Position := 0;

        if Pos('encoding="ISO-8859-1"',lStringStream.DataString)>0 then
          lStringList.LoadFromStream(_Stream)
        else
          lStringList.LoadFromStream(_Stream,TEncoding.UTF8);
      except
        on E:Exception do ;//TODO ShowMessage(E.ClassName+ ' '+e.Message);
      end;
      if Pos('<head/>',lStringList.Text) > 0 then
        lStringList.Text := ReplaceText(lStringList.Text,'<head/>','');
      lBuffer.LoadFromXML(lStringList.Text);
    finally
      lStringStream.Free;
      lStringList.Free;
    end;

    if lBuffer.DocumentElement = nil then
      exit;

    if SameText(lBuffer.DocumentElement.NodeName,'Warenkorb') then
      Result := idsWarenkorb(lBuffer.DocumentElement)
  except
    on E:Exception do ; //TODO begin Protocol(E.Message,pet_FATAL); end;
  end;
end;

function TIDSConnect_WarenkorbHelper.SaveToString(
  _Val: TStringBuilder): Boolean;
var
  i,j : Integer;

  procedure OutAddress(_Obj : TIDSConnect_Address);
  begin
    if (_Obj.Name1 <> '') then _Val.AppendFormat('  '+'<Name1>%s</Name1>'+#13#10,[TIDSConnectHelper.StrMaxLength(_Obj.Name1,40)]);
    if (_Obj.Name2 <> '') then _Val.AppendFormat('  '+'<Name2>%s</Name2>'+#13#10,[TIDSConnectHelper.StrMaxLength(_Obj.Name2,40)]);
    if (_Obj.Name3 <> '') then _Val.AppendFormat('  '+'<Name3>%s</Name3>'+#13#10,[TIDSConnectHelper.StrMaxLength(_Obj.Name3,40)]);
    if (_Obj.Name4 <> '') then _Val.AppendFormat('  '+'<Name4>%s</Name4>'+#13#10,[TIDSConnectHelper.StrMaxLength(_Obj.Name4,40)]);
    if (_Obj.Street <> '') then _Val.AppendFormat('  '+'<Street>%s</Street>'+#13#10,[TIDSConnectHelper.StrMaxLength(_Obj.Street,40)]);
    if (_Obj.PCode <> '') then _Val.AppendFormat('  '+'<PCode>%s</PCode>'+#13#10,[TIDSConnectHelper.StrMaxLength(_Obj.PCode,20)]);
    if (_Obj.City <> '') then _Val.AppendFormat('  '+'<City>%s</City>'+#13#10,[TIDSConnectHelper.StrMaxLength(_Obj.City,40)]);
    if (_Obj.Country <> '') then _Val.AppendFormat('  '+'<Country>%s</Country>'+#13#10,[TIDSConnectHelper.StrMaxLength(_Obj.Country,40)]);
    if (_Obj.ILN <> '') then _Val.AppendFormat('  '+'<ILN>%s</ILN>'+#13#10,[TIDSConnectHelper.StrMaxLength(_Obj.ILN,20)]);
    if (_Obj.Contact <> '') then _Val.AppendFormat('  '+'<Contact>%s</Contact>'+#13#10,[TIDSConnectHelper.StrMaxLength(_Obj.Contact,40)]);
    if (_Obj.Phone <> '') then _Val.AppendFormat('  '+'<Phone>%s</Phone>'+#13#10,[TIDSConnectHelper.StrMaxLength(_Obj.Phone,20)]);
    if (_Obj.Fax <> '') then _Val.AppendFormat('  '+'<Fax>%s</Fax>'+#13#10,[TIDSConnectHelper.StrMaxLength(_Obj.Fax,20)]);
    if (_Obj.Email <> '') then _Val.AppendFormat('  '+'<Email>%s</Email>'+#13#10,[TIDSConnectHelper.StrMaxLength(_Obj.Email,256)]);
  end;

begin
  _Val.Append('<?xml version="1.0" encoding="UTF-8"?>'+#13#10);
  _Val.Append('<Warenkorb xmlns="http://www.itek.de/Shop-Anbindung/Warenkorb/" ');
  _Val.Append('xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+#13#10);
  //_Val.Append('xsi:schemaLocation="http://www.itek.de/Shop-Anbindung/Warenkorb/warenkorb_senden.xsd">'+#13#10);

  _Val.Append(' '+'<WarenkorbInfo>'+#13#10);
  _Val.AppendFormat('  '+'<Date>%s</Date>'+#13#10,[TIDSConnectHelper.DateToDateStr(WarenkorbInfo.Date)]);
  _Val.AppendFormat('  '+'<Time>%s</Time>'+#13#10,[TIDSConnectHelper.TimeToTimeStr(WarenkorbInfo.Time)]);
  //<RueckgabeKZ>Warenkorbrückgabe</RueckgabeKZ> für Client nicht erforderlich
  _Val.Append('  '+'<Version>'+TIDSConnectHelper.VersionToStr(WarenkorbInfo.Version)+'</Version>'+#13#10);
  _Val.Append(' '+'</WarenkorbInfo>'+#13#10);

  _Val.Append(' '+'<Order>'+#13#10);

  //########## OderInfo
  _Val.Append('  '+'<OrderInfo>'+#13#10);
  if (Order.OrderInfo.InquiryNo <> '') then _Val.AppendFormat('  '+'<InquiryNo>%s</InquiryNo>'+#13#10,[TIDSConnectHelper.StrMaxLength(Order.OrderInfo.InquiryNo,15)]);
  if (Order.OrderInfo.OfferNo <> '') then _Val.AppendFormat('  '+'<OfferNo>%s</OfferNo>'+#13#10,[TIDSConnectHelper.StrMaxLength(Order.OrderInfo.OfferNo,15)]);
  if (Order.OrderInfo.PartNo <> '') then _Val.AppendFormat('  '+'<PartNo>%s</PartNo>'+#13#10,[TIDSConnectHelper.StrMaxLength(Order.OrderInfo.PartNo,15)]);
  if (Order.OrderInfo.OrderConfNo <> '') then _Val.AppendFormat('  '+'<OrderConfNo>%s</OrderConfNo>'+#13#10,[TIDSConnectHelper.StrMaxLength(Order.OrderInfo.OrderConfNo,15)]);
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
  if (Order.OrderInfo.ZusatzText <> '') then _Val.AppendFormat('  '+'<ZusatzText>%s</ZusatzText>'+#13#10,[TIDSConnectHelper.StrMaxLength(Order.OrderInfo.ZusatzText,100)]);
  if (Order.OrderInfo.Kommission <> '') then _Val.AppendFormat('  '+'<Kommission>%s</Kommission>'+#13#10,[TIDSConnectHelper.StrMaxLength(Order.OrderInfo.Kommission,80)]);
  _Val.Append('  '+'<Cur>EUR</Cur>'+#13#10);
  _Val.Append('  '+'</OrderInfo>'+#13#10);
  //########## OderInfo
//  if (_Options.OutSupplierInfo) then
//  begin
//    _Val.Append('  '+'<SupplierInfo>'+#13#10);
//    if (SupplierInfo.IDNo <> '') then _Val.AppendFormat('  '+'<IDNo>%s</IDNo>'+#13#10,[TIDSConnectHelper.StrMaxLength(SupplierInfo.IDNo,40)]);
//    OutAddress(SupplierInfo.Address);
//    _Val.Append('  '+'</SupplierInfo>'+#13#10);
//  end;
//  if (_Options.OutCustomerInfo) then
//  begin
//    _Val.Append('  '+'<CustomerInfo>'+#13#10);
//    if (CustomerInfo.IDNo <> '') then _Val.AppendFormat('  '+'<IDNo>%s</IDNo>'+#13#10,[TIDSConnectHelper.StrMaxLength(CustomerInfo.IDNo,40)]);
//    OutAddress(CustomerInfo.Address);
//    _Val.Append('  '+'</CustomerInfo>'+#13#10);
//  end;
//  if (_Options.OutDeliveryPlaceInfo) then
//  begin
//    _Val.Append('  '+'<DeliveryPlaceInfo>'+#13#10);
//    OutAddress(DeliveryPlaceInfo.Address);
//    _Val.Append('  '+'</DeliveryPlaceInfo>'+#13#10);
//  end;
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
      _Val.Append('  '+'<RefItems>'+#13#10);
      if (Order.OrderItems[i].RefItems_Customer <> '') or
         (Order.OrderItems[i].RefItems_CustomerSubNo <> '') then
      begin
        _Val.AppendFormat('  '+'<Customer>%s</Customer>'+#13#10,[TIDSConnectHelper.StrMaxLength(Order.OrderItems[i].RefItems_Customer,35)]);
        _Val.AppendFormat('  '+'<CustomerSubNo>%s</CustomerSubNo>'+#13#10,[TIDSConnectHelper.StrMaxLength(Order.OrderItems[i].RefItems_CustomerSubNo,35)]);
      end;
      if (Order.OrderItems[i].RefItems_Supplier <> '') or
         (Order.OrderItems[i].RefItems_SupplierSubNo <> '') then
      begin
        _Val.AppendFormat('  '+'<Supplier>%s</Supplier>'+#13#10,[TIDSConnectHelper.StrMaxLength(Order.OrderItems[i].RefItems_Supplier,35)]);
        _Val.AppendFormat('  '+'<SupplierSubNo>%s</SupplierSubNo>'+#13#10,[TIDSConnectHelper.StrMaxLength(Order.OrderItems[i].RefItems_SupplierSubNo,35)]);
      end;
      _Val.Append('  '+'</RefItems>'+#13#10);
    end;
    if Order.OrderItems[i].EAN <> '' then _Val.AppendFormat('  '+'<EAN>%s</EAN>'+#13#10,[TIDSConnectHelper.StrMaxLength(Order.OrderItems[i].EAN,13)]);
    if Order.OrderItems[i].ArtNo <> '' then _Val.AppendFormat('  '+'<ArtNo>%s</ArtNo>'+#13#10,[TIDSConnectHelper.StrMaxLength(Order.OrderItems[i].ArtNo,15)]);
    _Val.AppendFormat('  '+'<Qty>%s</Qty>'+#13#10,[TIDSConnectHelper.FloatToStr(Order.OrderItems[i].Qty,2)]);
    _Val.AppendFormat('  '+'<QU>%s</QU>'+#13#10,[TIDSConnectHelper.QuToQuStr(Order.OrderItems[i].QU)]);
//    if (not _Options.OutHWPMode) then
//    begin
//      if OrderItems[i].Kurztext <> '' then _Val.AppendFormat('  '+'<Kurztext>%s</Kurztext>'+#13#10,[TIDSConnectHelper.StrMaxLength(OrderItems[i].Kurztext,100)]);
//      if OrderItems[i].Langtext <> '' then _Val.AppendFormat('  '+'<Langtext>%s</Langtext>'+#13#10,[OrderItems[i].Langtext]);
//      if OrderItems[i].OfferPrice <> 0 then _Val.AppendFormat('  '+'<OfferPrice>%s</OfferPrice>'+#13#10,[IDSFloatToStr(OrderItems[i].OfferPrice,4)]);
//      if OrderItems[i].NetPrice <> 0 then _Val.AppendFormat('  '+'<NetPrice>%s</NetPrice>'+#13#10,[IDSFloatToStr(OrderItems[i].NetPrice,4)]);
//      if OrderItems[i].PriceBasis <> 0 then _Val.AppendFormat('  '+'<PriceBasis>%s</PriceBasis>'+#13#10,[IDSFloatToStr(OrderItems[i].PriceBasis,2)]);
//      if OrderItems[i].VAT <> 0 then _Val.AppendFormat('  '+'<VAT>%s</VAT>'+#13#10,[IDSFloatToStr(OrderItems[i].VAT,2)]);
//      if OrderItems[i].TechnClarification <> '' then _Val.AppendFormat('  '+'<TechnClarification>%s</TechnClarification>'+#13#10,[TIDSConnectHelper.StrMaxLength(OrderItems[i].TechnClarification,3)]);
//      if OrderItems[i].Hinweis <> '' then _Val.AppendFormat('  '+'<Hinweis>%s</Hinweis>'+#13#10,[OrderItems[i].Hinweis]);
//      //Fehlercode : TIDS_Fehlercode;
//      //Fehlertext : String;
//      if OrderItems[i].Zuschlag <> 0 then _Val.AppendFormat('  '+'<Zuschlag>%s</Zuschlag>'+#13#10,[IDSFloatToStr(OrderItems[i].Zuschlag,4)]);
//      if (OrderItems[i].Rohstoffanteil.Count > 0) then
//      begin
//      _Val.Append('  '+'<Rohstoffanteil>'+#13#10);
//      for j := 0 to OrderItems[i].Rohstoffanteil.Count - 1 do
//      begin
//        _Val.AppendFormat('  '+'<Rohstoff>%s</Rohstoff>'+#13#10,[IDSRohstoffToRohstoffStr(OrderItems[i].Rohstoffanteil[j].Rohstoff)]);
//        _Val.AppendFormat('  '+'<Gewichtsanteilswert>%s</Gewichtsanteilswert>'+#13#10,[IDSFloatToStr(OrderItems[i].Rohstoffanteil[j].Gewichtsanteilswert,4)]);
//        _Val.AppendFormat('  '+'<Gewichtsanteilseinheit>%s</Gewichtsanteilseinheit>'+#13#10,[IDSQuToQuStr(OrderItems[i].Rohstoffanteil[j].Gewichtsanteilseinheit)]);
//        _Val.AppendFormat('  '+'<Basiswert>%s</Basiswert>'+#13#10,[IDSFloatToStr(OrderItems[i].Rohstoffanteil[j].Basiswert,4)]);
//        _Val.AppendFormat('  '+'<Basiseinheit>%s</Basiseinheit>'+#13#10,[IDSQuToQuStr(OrderItems[i].Rohstoffanteil[j].Basiseinheit)]);
//        _Val.AppendFormat('  '+'<Basisnotierung>%s</Basisnotierung>'+#13#10,[IDSFloatToStr(OrderItems[i].Rohstoffanteil[j].Basisnotierung,4)]);
//        _Val.AppendFormat('  '+'<NotierungAktuell>%s</NotierungAktuell>'+#13#10,[IDSFloatToStr(OrderItems[i].Rohstoffanteil[j].NotierungAktuell,4)]);
//      end;
//       _Val.Append('  '+'</Rohstoffanteil>'+#13#10);
//      end;
//    end;
    _Val.Append('  '+'</OrderItem>'+#13#10);
  end;
  _Val.Append(' '+'</Order>'+#13#10);
  _Val.Append('</Warenkorb>');
  Result := true;
end;

function TIDSConnect_WarenkorbHelper.UnusedObj(_Node: IXMLNode): Boolean;
begin
  Result := SameText(_Node.NodeName,'#text');
end;

{ TIDSConnect }

class function TIDSConnect.GetStreamFromUrl(const _URL: String;
  _Result: TStream; _OnReceiveData: TReceiveDataEvent;
  _OnError: TIDSConnectOnException): Boolean;
var
  http : THTTPClient;
  vcHelper : TIDSConnect.TValidateCertificatHelper;
begin
  result := false;
  if _Result = nil then
    exit;
  http := THTTPClient.Create;
  vcHelper := TIDSConnect.TValidateCertificatHelper.Create;
  try
    http.OnValidateServerCertificate := vcHelper.DoValidateCertificateEvent;
    http.OnReceiveData := _OnReceiveData;
    try
      with http.Get(_URL,_Result) do
        result := StatusCode = 200;
    except
      on E:Exception do if Assigned(_OnError) then _OnError('',E);
    end;
  finally
    vcHelper.Free;
    http.Free;
  end;
end;

class function TIDSConnect.GetUuid: String;
begin
  Result := TGUID.NewGuid.ToString;
  System.Delete(Result,1,1);
  System.Delete(Result,Length(Result),1);
end;

class procedure TIDSConnect.IDSConnectADT(const _ServiceURL, _Cst, _UN, _Pwd,
  _ArtNr, _TmpFilename: String);
var
  hstrl : TStringList;
begin
  if _Cst.IsEmpty and _UN.IsEmpty and _Pwd.IsEmpty then
    exit;
  if _ArtNr = '' then
    exit;
  if _TmpFilename = '' then
    exit;
  hstrl := TStringList.Create;
  try
    hstrl.Add('<!doctype html public "-//W3C//DTD HTML 3.2 //EN">');
    hstrl.Add('<html><head><title>IDS-Connect Schnittstelle ADT</title></head>');
    hstrl.Add('<body onload="document.forms[''adt''].submit();">');
    hstrl.Add('<form id="adt" name="adt" action="'+_ServiceURL+'" method="post">');
    hstrl.Add('<input type="hidden" name="kndnr" value="'+_Cst+'" size="50" maxlength="50">');
    hstrl.Add('<input type="hidden" name="name_kunde" value="'+_UN+'" size="50" maxlength="50">');
    hstrl.Add('<input type="hidden" name="pw_kunde" value="'+_Pwd+'" size="50" maxlength="50">');
    hstrl.Add('<input type="hidden" name="version" value="2.5" size="5" maxlength="5">');
    hstrl.Add('<input type="hidden" name="action" value="ADL" size="3" maxlength="3">');
    //hstrl.Add('<td><input type="Text" name="hookurl" value="die URL an die die Antwort gesendet wird" size="256" maxlength="256">');
    hstrl.Add('<input type="hidden" name="ghnummer" value="'+_ArtNr+'" size="35" maxlength="35">');
    //hstrl.Add('<input type="Submit" name="Abschicken3" value="Abschicken Artikeldeeplink">');
    hstrl.Add('</form></body></html>');

    hstrl.SaveToFile(_TmpFilename,TEncoding.GetEncoding(1252));
    ShellExecuteW(0,'open',PChar(_TmpFilename),'','',SW_SHOWNORMAL);
  finally
    hstrl.Free;
  end;
end;

class function TIDSConnect.IDSConnectAS(_ServiceURL, _Cst, _UN, _Pwd,
  _TmpFilename, _SearchString: String; _Warenkorb: TIDSConnect_Warenkorb): Boolean;
var
  hstrl : TStringList;
  sid : String;
  str : TMemoryStream;
begin
  Result := false;
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
  hstrl.Add('<!doctype html public "-//W3C//DTD HTML 3.2 //EN">');
  hstrl.Add('<html><head><title>IDS-Connect Schnittstelle AS</title></head>');
  hstrl.Add('<body onload="document.forms[''search''].submit();">');
  hstrl.Add('<form id="search" name="search" action="'+_ServiceURL+'" method="post">');
  hstrl.Add('<input type="hidden" name="kndnr" value="'+_Cst+'" size="50" maxlength="50">');
  hstrl.Add('<input type="hidden" name="name_kunde" value="'+_UN+'" size="50" maxlength="50">');
  hstrl.Add('<input type="hidden" name="pw_kunde" value="'+_Pwd+'" size="50" maxlength="50">');
  hstrl.Add('<input type="hidden" name="version" value="2.5" size="5" maxlength="5">');
  hstrl.Add('<input type="hidden" name="searchterm" value="'+_SearchString+'">');
  hstrl.Add('<input type="hidden" name="action" value="AS" size="3" maxlength="3">');
  hstrl.Add('<input type="hidden" name="hookurl" value="'+IDSCONNECT_HOOKURL+'?sid='+sid +'" size="256" maxlength="256">');
  hstrl.Add('</form></body></html>');
  hstrl.SaveToFile(_TmpFilename,TEncoding.GetEncoding(1252));
  hstrl.Free;
  ShellExecuteW(0,'open',PChar(_TmpFilename),'','',SW_SHOWNORMAL);


  if TaskMessageDlg('Warte auf Abschluss...', 'Warenkorb einlesen', mtConfirmation, mbYesNoCancel, 0) = mrYes then
  begin
    str := TMemoryStream.Create;
    try
      if TIDSConnect.GetStreamFromUrl(TIDSConnect.IDSCONNECT_HOOKURL+'?sid='+sid,str,nil,nil) then
        Result := _Warenkorb.LoadFromStream(str);
    finally
      str.Free;
    end;
  end;
end;

class function TIDSConnect.IDSConnectWKE(const _ServiceURL, _Cst, _UN, _Pwd,
  _TmpFilename: String; _Warenkorb: TIDSConnect_Warenkorb): Boolean;
var
  hstrl : TStringList;
  sid : String;
  str : TMemoryStream;
  TaskDialog: TTaskDialog;
  Button: TTaskDialogBaseButtonItem;
begin
  Result := false;
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
  hstrl.Add('<!doctype html public "-//W3C//DTD HTML 3.2 //EN">');
  hstrl.Add('<html><head><title>IDS-Connect Schnittstelle WKE</title></head>');
  hstrl.Add('<body onload="document.forms[''wke''].submit();">');
  hstrl.Add('<form id="wke" name="wke" action="'+_ServiceURL+'" method="post">');
  hstrl.Add('<input type="hidden" name="kndnr" value="'+_Cst+'" size="50" maxlength="50">');
  hstrl.Add('<input type="hidden" name="name_kunde" value="'+_UN+'" size="50" maxlength="50">');
  hstrl.Add('<input type="hidden" name="pw_kunde" value="'+_Pwd+'" size="50" maxlength="50">');
  hstrl.Add('<input type="hidden" name="version" value="1.3" size="5" maxlength="5">');
  hstrl.Add('<input type="hidden" name="action" value="WKE" size="3" maxlength="3">');
  hstrl.Add('<input type="hidden" name="hookurl" value="'+TIDSConnect.IDSCONNECT_HOOKURL+'?sid='+sid +'" size="256" maxlength="256">');
  hstrl.Add('</form></body></html>');
  hstrl.SaveToFile(_TmpFilename,TEncoding.GetEncoding(1252));
  hstrl.Free;
  ShellExecuteW(0,'open',PChar(_TmpFilename),'','',SW_SHOWNORMAL);


  if TaskMessageDlg('Warte auf Abschluss...', 'Warenkorb einlesen', mtConfirmation, mbYesNoCancel, 0) = mrYes then
  begin
    str := TMemoryStream.Create;
    try
      if TIDSConnect.GetStreamFromUrl(TIDSConnect.IDSCONNECT_HOOKURL+'?sid='+sid,str,nil,nil) then
        Result := _Warenkorb.LoadFromStream(str);
    finally
      str.Free;
    end;
  end;
end;

class function TIDSConnect.IDSConnectWKS(_ServiceURL, _Cst, _UN, _Pwd,
  _TmpFilename: String; _Warenkorb: TIDSConnect_Warenkorb;
  _DontWait: Boolean): Boolean;
var
  hstrl : TStringList;
  sid : String;
  str : TMemoryStream;
  hstr : TStringBuilder;
begin
  Result := false;
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
    _Warenkorb.SaveToString(hstr);
    hstrl.Add('<!doctype html public "-//W3C//DTD HTML 3.2 //EN">');
    hstrl.Add('<html><head><title>IDS-Connect Schnittstelle WKS</title></head>');
    hstrl.Add('<body onload="document.forms[''wks''].submit();">');
    hstrl.Add('<form id="wks" name="wks" action="'+_ServiceURL+'" method="post">');
    hstrl.Add('<input type="hidden" name="kndnr" value="'+_Cst+'" size="50" maxlength="50">');
    hstrl.Add('<input type="hidden" name="name_kunde" value="'+_UN+'" size="50" maxlength="50">');
    hstrl.Add('<input type="hidden" name="pw_kunde" value="'+_Pwd+'" size="50" maxlength="50">');
    hstrl.Add('<input type="hidden" name="version" value="1.3" size="5" maxlength="5">');
    hstrl.Add('<textarea cols="1" rows="1" name="warenkorb">'+#13#10+hstr.ToString+#13#10+'</textarea>');
    hstrl.Add('<input type="hidden" name="action" value="WKS" size="3" maxlength="3">');
    if not _DontWait then
      hstrl.Add('<input type="hidden" name="hookurl" value="'+IDSCONNECT_HOOKURL+'?sid='+sid +'" size="256" maxlength="256">');
    hstrl.Add('</form></body></html>');
    hstrl.SaveToFile(_TmpFilename,TEncoding.GetEncoding(1252));
  finally
    hstrl.Free;
    hstr.Free;
  end;
  ShellExecuteW(0,'open',PChar(_TmpFilename),'','',SW_SHOWNORMAL);

  if _DontWait then
  begin
    Result := true;
    exit;
  end;

  if TaskMessageDlg('Warte auf Abschluss...', 'Warenkorb einlesen', mtConfirmation, mbYesNoCancel, 0) = mrYes then
  begin
    str := TMemoryStream.Create;
    try
      if TIDSConnect.GetStreamFromUrl(TIDSConnect.IDSCONNECT_HOOKURL+'?sid='+sid,str,nil,nil) then
        Result := _Warenkorb.LoadFromStream(str);
    finally
      str.Free;
    end;
  end;
end;

{ TIDSConnect.TValidateCertificatHelper }

procedure TIDSConnect.TValidateCertificatHelper.DoValidateCertificateEvent(
  const Sender: TObject; const ARequest: TURLRequest;
  const Certificate: TCertificate; var Accepted: Boolean);
begin
  Accepted := true;
end;

end.
