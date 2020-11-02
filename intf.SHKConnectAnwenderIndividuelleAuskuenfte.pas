// ************************************************************************ //
// Die in dieser Datei deklarierten Typen wurden aus Daten der unten
// beschriebenen WSDL-Datei generiert:

// WSDL     : https://shkgh20.shk-connect.de/services/AnwenderIndividuelleAuskuenfte?wsdl
//  >Import : https://shkgh20.shk-connect.de/services/AnwenderIndividuelleAuskuenfte?wsdl>0
// Codierung : UTF-8
// Version: 1.0
// (02.11.2020 22:45:08 - - $Rev: 101104 $)
// ************************************************************************ //

unit intf_SHKConnectAnwenderIndividuelleAuskuenfte;

interface

uses Soap.InvokeRegistry, Soap.SOAPHTTPClient, System.Types, Soap.XSBuiltIns;

const
  IS_OPTN = $0001;
  IS_UNBD = $0002;
  IS_NLBL = $0004;
  IS_UNQL = $0008;


type

  // ************************************************************************ //
  // Die folgenden Typen, auf die im WSDL-Dokument Bezug genommen wird, sind in dieser Datei
  // nicht repräsentiert. Sie sind entweder Aliase[@] anderer repräsentierter Typen oder auf sie wurde Bezug genommen,
  // aber sie sind in diesem Dokument nicht[!] deklariert. Die Typen aus letzterer Kategorie
  // sind in der Regel vordefinierten/bekannten XML- oder Embarcadero-Typen zugeordnet; sie könnten aber auf 
  // ein inkorrektes WSDL-Dokument hinweisen, das einen Schematyp nicht deklariert oder importiert hat.
  // ************************************************************************ //
  // !:long            - "http://www.w3.org/2001/XMLSchema"[Gbl]
  // !:int             - "http://www.w3.org/2001/XMLSchema"[Gbl]
  // !:string          - "http://www.w3.org/2001/XMLSchema"[Gbl]

  Link                 = class;                 { "http://service.shk-connect.de"[GblCplx] }
  GetIndividuelleAuskunft2 = class;             { "http://service.shk-connect.de"[Lit][GblCplx] }
  GetIndividuelleAuskunft = class;              { "http://service.shk-connect.de"[Lit][GblElm] }
  Prozess              = class;                 { "http://service.shk-connect.de"[GblCplx] }
  GetIndividuelleAuskunftResponse = class;      { "http://service.shk-connect.de"[Lit][GblCplx] }
  GetIndividuelleAuskunftAntwort = class;       { "http://service.shk-connect.de"[Lit][GblElm] }
  Status               = class;                 { "http://service.shk-connect.de"[GblCplx] }

  {$SCOPEDENUMS ON}
  { "http://service.shk-connect.de"[GblSmpl] }
  Authentifizierungsmethode = (URL, HTTPAUTH, KEINE, COOKIE);

  {$SCOPEDENUMS OFF}

  Array_Of_Link = array of Link;                { "http://service.shk-connect.de"[GblUbnd] }
  Teilprozesse = array of string;               { "http://service.shk-connect.de"[Cplx] }
  CookieList = array of string;                 { "http://service.shk-connect.de"[Cplx] }


  // ************************************************************************ //
  // XML       : Link, global, <complexType>
  // Namespace : http://service.shk-connect.de
  // ************************************************************************ //
  Link = class(TRemotable)
  private
    FBeschreibung: string;
    FURL: string;
    FDatum: string;
    FDatum_Specified: boolean;
    FGroesse: Int64;
    FAuthentifizierungsmethode: Authentifizierungsmethode;
    FDatenDatum: string;
    FAenderungsInfo: string;
    FAenderungsInfo_Specified: boolean;
    FCookieList: CookieList;
    FCookieList_Specified: boolean;
    FDateityp: string;
    FDateityp_Specified: boolean;
    FDateiname_org: string;
    FDateiname_org_Specified: boolean;
    procedure SetDatum(Index: Integer; const Astring: string);
    function  Datum_Specified(Index: Integer): boolean;
    procedure SetAenderungsInfo(Index: Integer; const Astring: string);
    function  AenderungsInfo_Specified(Index: Integer): boolean;
    procedure SetCookieList(Index: Integer; const ACookieList: CookieList);
    function  CookieList_Specified(Index: Integer): boolean;
    procedure SetDateityp(Index: Integer; const Astring: string);
    function  Dateityp_Specified(Index: Integer): boolean;
    procedure SetDateiname_org(Index: Integer; const Astring: string);
    function  Dateiname_org_Specified(Index: Integer): boolean;
  published
    property Beschreibung:              string                     Index (IS_UNQL) read FBeschreibung write FBeschreibung;
    property URL:                       string                     Index (IS_UNQL) read FURL write FURL;
    property Datum:                     string                     Index (IS_OPTN or IS_UNQL) read FDatum write SetDatum stored Datum_Specified;
    property Groesse:                   Int64                      Index (IS_NLBL or IS_UNQL) read FGroesse write FGroesse;
    property Authentifizierungsmethode: Authentifizierungsmethode  Index (IS_UNQL) read FAuthentifizierungsmethode write FAuthentifizierungsmethode;
    property DatenDatum:                string                     Index (IS_UNQL) read FDatenDatum write FDatenDatum;
    property AenderungsInfo:            string                     Index (IS_OPTN or IS_UNQL) read FAenderungsInfo write SetAenderungsInfo stored AenderungsInfo_Specified;
    property CookieList:                CookieList                 Index (IS_OPTN or IS_UNQL) read FCookieList write SetCookieList stored CookieList_Specified;
    property Dateityp:                  string                     Index (IS_OPTN or IS_UNQL) read FDateityp write SetDateityp stored Dateityp_Specified;
    property Dateiname_org:             string                     Index (IS_OPTN or IS_UNQL) read FDateiname_org write SetDateiname_org stored Dateiname_org_Specified;
  end;



  // ************************************************************************ //
  // XML       : GetIndividuelleAuskunft, global, <complexType>
  // Namespace : http://service.shk-connect.de
  // Serializtn: [xoLiteralParam]
  // Info      : Wrapper
  // ************************************************************************ //
  GetIndividuelleAuskunft2 = class(TRemotable)
  private
    FSchnittstellenversion: string;
    FSchnittstellenversion_Specified: boolean;
    FSoftwarename: string;
    FSoftwarename_Specified: boolean;
    FSoftwarepasswort: string;
    FSoftwarepasswort_Specified: boolean;
    FUnternehmensID: Integer;
    FKundennummer: string;
    FKundennummer_Specified: boolean;
    FBenutzername: string;
    FBenutzername_Specified: boolean;
    FPasswort: string;
    FPasswort_Specified: boolean;
    FProzesscode: string;
    FProzesscode_Specified: boolean;
    FVersion: string;
    FVersion_Specified: boolean;
    procedure SetSchnittstellenversion(Index: Integer; const Astring: string);
    function  Schnittstellenversion_Specified(Index: Integer): boolean;
    procedure SetSoftwarename(Index: Integer; const Astring: string);
    function  Softwarename_Specified(Index: Integer): boolean;
    procedure SetSoftwarepasswort(Index: Integer; const Astring: string);
    function  Softwarepasswort_Specified(Index: Integer): boolean;
    procedure SetKundennummer(Index: Integer; const Astring: string);
    function  Kundennummer_Specified(Index: Integer): boolean;
    procedure SetBenutzername(Index: Integer; const Astring: string);
    function  Benutzername_Specified(Index: Integer): boolean;
    procedure SetPasswort(Index: Integer; const Astring: string);
    function  Passwort_Specified(Index: Integer): boolean;
    procedure SetProzesscode(Index: Integer; const Astring: string);
    function  Prozesscode_Specified(Index: Integer): boolean;
    procedure SetVersion(Index: Integer; const Astring: string);
    function  Version_Specified(Index: Integer): boolean;
  public
    constructor Create; override;
  published
    property Schnittstellenversion: string   Index (IS_OPTN or IS_UNQL) read FSchnittstellenversion write SetSchnittstellenversion stored Schnittstellenversion_Specified;
    property Softwarename:          string   Index (IS_OPTN or IS_UNQL) read FSoftwarename write SetSoftwarename stored Softwarename_Specified;
    property Softwarepasswort:      string   Index (IS_OPTN or IS_UNQL) read FSoftwarepasswort write SetSoftwarepasswort stored Softwarepasswort_Specified;
    property UnternehmensID:        Integer  Index (IS_UNQL) read FUnternehmensID write FUnternehmensID;
    property Kundennummer:          string   Index (IS_OPTN or IS_UNQL) read FKundennummer write SetKundennummer stored Kundennummer_Specified;
    property Benutzername:          string   Index (IS_OPTN or IS_UNQL) read FBenutzername write SetBenutzername stored Benutzername_Specified;
    property Passwort:              string   Index (IS_OPTN or IS_UNQL) read FPasswort write SetPasswort stored Passwort_Specified;
    property Prozesscode:           string   Index (IS_OPTN or IS_UNQL) read FProzesscode write SetProzesscode stored Prozesscode_Specified;
    property Version:               string   Index (IS_OPTN or IS_UNQL) read FVersion write SetVersion stored Version_Specified;
  end;



  // ************************************************************************ //
  // XML       : GetIndividuelleAuskunft, global, <element>
  // Namespace : http://service.shk-connect.de
  // Info      : Wrapper
  // ************************************************************************ //
  GetIndividuelleAuskunft = class(GetIndividuelleAuskunft2)
  private
  published
  end;



  // ************************************************************************ //
  // XML       : Prozess, global, <complexType>
  // Namespace : http://service.shk-connect.de
  // ************************************************************************ //
  Prozess = class(TRemotable)
  private
    FProzesscode: string;
    FVersion: string;
    FVersion_Specified: boolean;
    FTeilprozesse: Teilprozesse;
    FTeilprozesse_Specified: boolean;
    FURL: string;
    FURL_Specified: boolean;
    FLink: Array_Of_Link;
    FLink_Specified: boolean;
    procedure SetVersion(Index: Integer; const Astring: string);
    function  Version_Specified(Index: Integer): boolean;
    procedure SetTeilprozesse(Index: Integer; const ATeilprozesse: Teilprozesse);
    function  Teilprozesse_Specified(Index: Integer): boolean;
    procedure SetURL(Index: Integer; const Astring: string);
    function  URL_Specified(Index: Integer): boolean;
    procedure SetLink(Index: Integer; const AArray_Of_Link: Array_Of_Link);
    function  Link_Specified(Index: Integer): boolean;
  public
    destructor Destroy; override;
  published
    property Prozesscode:  string         Index (IS_UNQL) read FProzesscode write FProzesscode;
    property Version:      string         Index (IS_OPTN or IS_UNQL) read FVersion write SetVersion stored Version_Specified;
    property Teilprozesse: Teilprozesse   Index (IS_OPTN or IS_UNQL) read FTeilprozesse write SetTeilprozesse stored Teilprozesse_Specified;
    property URL:          string         Index (IS_OPTN or IS_UNQL) read FURL write SetURL stored URL_Specified;
    property Link:         Array_Of_Link  Index (IS_OPTN or IS_UNBD or IS_UNQL) read FLink write SetLink stored Link_Specified;
  end;

  Prozessliste = array of Prozess;              { "http://service.shk-connect.de"[GblCplx] }


  // ************************************************************************ //
  // XML       : GetIndividuelleAuskunftResponse, global, <complexType>
  // Namespace : http://service.shk-connect.de
  // Serializtn: [xoLiteralParam]
  // Info      : Wrapper
  // ************************************************************************ //
  GetIndividuelleAuskunftResponse = class(TRemotable)
  private
    FSchnittstellenversion: string;
    FSchnittstellenversion_Specified: boolean;
    FServerkennung: string;
    FServerkennung_Specified: boolean;
    FStatus: Status;
    FStatus_Specified: boolean;
    FProzessliste: Prozessliste;
    FProzessliste_Specified: boolean;
    procedure SetSchnittstellenversion(Index: Integer; const Astring: string);
    function  Schnittstellenversion_Specified(Index: Integer): boolean;
    procedure SetServerkennung(Index: Integer; const Astring: string);
    function  Serverkennung_Specified(Index: Integer): boolean;
    procedure SetStatus(Index: Integer; const AStatus: Status);
    function  Status_Specified(Index: Integer): boolean;
    procedure SetProzessliste(Index: Integer; const AProzessliste: Prozessliste);
    function  Prozessliste_Specified(Index: Integer): boolean;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    property Schnittstellenversion: string        Index (IS_OPTN or IS_UNQL) read FSchnittstellenversion write SetSchnittstellenversion stored Schnittstellenversion_Specified;
    property Serverkennung:         string        Index (IS_OPTN or IS_UNQL) read FServerkennung write SetServerkennung stored Serverkennung_Specified;
    property Status:                Status        Index (IS_OPTN or IS_UNQL) read FStatus write SetStatus stored Status_Specified;
    property Prozessliste:          Prozessliste  Index (IS_OPTN or IS_UNQL) read FProzessliste write SetProzessliste stored Prozessliste_Specified;
  end;



  // ************************************************************************ //
  // XML       : GetIndividuelleAuskunftAntwort, global, <element>
  // Namespace : http://service.shk-connect.de
  // Info      : Wrapper
  // ************************************************************************ //
  GetIndividuelleAuskunftAntwort = class(GetIndividuelleAuskunftResponse)
  private
  published
  end;



  // ************************************************************************ //
  // XML       : Status, global, <complexType>
  // Namespace : http://service.shk-connect.de
  // ************************************************************************ //
  Status = class(TRemotable)
  private
    FCode: string;
    FMeldung: string;
    FMeldung_Specified: boolean;
    procedure SetMeldung(Index: Integer; const Astring: string);
    function  Meldung_Specified(Index: Integer): boolean;
  published
    property Code:    string  Index (IS_UNQL) read FCode write FCode;
    property Meldung: string  Index (IS_OPTN or IS_UNQL) read FMeldung write SetMeldung stored Meldung_Specified;
  end;


  // ************************************************************************ //
  // Namespace : http://service.shk-connect.de
  // Transport : http://schemas.xmlsoap.org/soap/http
  // Stil     : document
  // Verwenden von       : literal
  // Bindung   : AnwenderIndividuelleAuskuenfteBeanBinding
  // Service   : anwenderIndividuelleAuskuenfteService
  // Port      : anwenderIndividuelleAuskuenftePort
  // URL       : https://shkgh20.shk-connect.de/services/AnwenderIndividuelleAuskuenfte
  // ************************************************************************ //
  AnwenderIndividuelleAuskuenfteBean = interface(IInvokable)
  ['{5072BA2C-0784-556C-4EC2-A2BD8D629A22}']

    // Entpacken nicht möglich: 
    //     - Mehrere strenge out-Elemente gefunden
    function  GetIndividuelleAuskunft(const GetIndividuelleAuskunft: GetIndividuelleAuskunft): GetIndividuelleAuskunftAntwort; stdcall;
  end;

function GetAnwenderIndividuelleAuskuenfteBean(UseWSDL: Boolean=System.False; Addr: string=''; HTTPRIO: THTTPRIO = nil): AnwenderIndividuelleAuskuenfteBean;


implementation
  uses System.SysUtils;

function GetAnwenderIndividuelleAuskuenfteBean(UseWSDL: Boolean; Addr: string; HTTPRIO: THTTPRIO): AnwenderIndividuelleAuskuenfteBean;
const
  defWSDL = 'https://shkgh20.shk-connect.de/services/AnwenderIndividuelleAuskuenfte?wsdl';
  defURL  = 'https://shkgh20.shk-connect.de/services/AnwenderIndividuelleAuskuenfte';
  defSvc  = 'anwenderIndividuelleAuskuenfteService';
  defPrt  = 'anwenderIndividuelleAuskuenftePort';
var
  RIO: THTTPRIO;
begin
  Result := nil;
  if (Addr = '') then
  begin
    if UseWSDL then
      Addr := defWSDL
    else
      Addr := defURL;
  end;
  if HTTPRIO = nil then
    RIO := THTTPRIO.Create(nil)
  else
    RIO := HTTPRIO;
  try
    Result := (RIO as AnwenderIndividuelleAuskuenfteBean);
    if UseWSDL then
    begin
      RIO.WSDLLocation := Addr;
      RIO.Service := defSvc;
      RIO.Port := defPrt;
    end else
      RIO.URL := Addr;
  finally
    if (Result = nil) and (HTTPRIO = nil) then
      RIO.Free;
  end;
end;


procedure Link.SetDatum(Index: Integer; const Astring: string);
begin
  FDatum := Astring;
  FDatum_Specified := True;
end;

function Link.Datum_Specified(Index: Integer): boolean;
begin
  Result := FDatum_Specified;
end;

procedure Link.SetAenderungsInfo(Index: Integer; const Astring: string);
begin
  FAenderungsInfo := Astring;
  FAenderungsInfo_Specified := True;
end;

function Link.AenderungsInfo_Specified(Index: Integer): boolean;
begin
  Result := FAenderungsInfo_Specified;
end;

procedure Link.SetCookieList(Index: Integer; const ACookieList: CookieList);
begin
  FCookieList := ACookieList;
  FCookieList_Specified := True;
end;

function Link.CookieList_Specified(Index: Integer): boolean;
begin
  Result := FCookieList_Specified;
end;

procedure Link.SetDateityp(Index: Integer; const Astring: string);
begin
  FDateityp := Astring;
  FDateityp_Specified := True;
end;

function Link.Dateityp_Specified(Index: Integer): boolean;
begin
  Result := FDateityp_Specified;
end;

procedure Link.SetDateiname_org(Index: Integer; const Astring: string);
begin
  FDateiname_org := Astring;
  FDateiname_org_Specified := True;
end;

function Link.Dateiname_org_Specified(Index: Integer): boolean;
begin
  Result := FDateiname_org_Specified;
end;

constructor GetIndividuelleAuskunft2.Create;
begin
  inherited Create;
  FSerializationOptions := [xoLiteralParam];
end;

procedure GetIndividuelleAuskunft2.SetSchnittstellenversion(Index: Integer; const Astring: string);
begin
  FSchnittstellenversion := Astring;
  FSchnittstellenversion_Specified := True;
end;

function GetIndividuelleAuskunft2.Schnittstellenversion_Specified(Index: Integer): boolean;
begin
  Result := FSchnittstellenversion_Specified;
end;

procedure GetIndividuelleAuskunft2.SetSoftwarename(Index: Integer; const Astring: string);
begin
  FSoftwarename := Astring;
  FSoftwarename_Specified := True;
end;

function GetIndividuelleAuskunft2.Softwarename_Specified(Index: Integer): boolean;
begin
  Result := FSoftwarename_Specified;
end;

procedure GetIndividuelleAuskunft2.SetSoftwarepasswort(Index: Integer; const Astring: string);
begin
  FSoftwarepasswort := Astring;
  FSoftwarepasswort_Specified := True;
end;

function GetIndividuelleAuskunft2.Softwarepasswort_Specified(Index: Integer): boolean;
begin
  Result := FSoftwarepasswort_Specified;
end;

procedure GetIndividuelleAuskunft2.SetKundennummer(Index: Integer; const Astring: string);
begin
  FKundennummer := Astring;
  FKundennummer_Specified := True;
end;

function GetIndividuelleAuskunft2.Kundennummer_Specified(Index: Integer): boolean;
begin
  Result := FKundennummer_Specified;
end;

procedure GetIndividuelleAuskunft2.SetBenutzername(Index: Integer; const Astring: string);
begin
  FBenutzername := Astring;
  FBenutzername_Specified := True;
end;

function GetIndividuelleAuskunft2.Benutzername_Specified(Index: Integer): boolean;
begin
  Result := FBenutzername_Specified;
end;

procedure GetIndividuelleAuskunft2.SetPasswort(Index: Integer; const Astring: string);
begin
  FPasswort := Astring;
  FPasswort_Specified := True;
end;

function GetIndividuelleAuskunft2.Passwort_Specified(Index: Integer): boolean;
begin
  Result := FPasswort_Specified;
end;

procedure GetIndividuelleAuskunft2.SetProzesscode(Index: Integer; const Astring: string);
begin
  FProzesscode := Astring;
  FProzesscode_Specified := True;
end;

function GetIndividuelleAuskunft2.Prozesscode_Specified(Index: Integer): boolean;
begin
  Result := FProzesscode_Specified;
end;

procedure GetIndividuelleAuskunft2.SetVersion(Index: Integer; const Astring: string);
begin
  FVersion := Astring;
  FVersion_Specified := True;
end;

function GetIndividuelleAuskunft2.Version_Specified(Index: Integer): boolean;
begin
  Result := FVersion_Specified;
end;

destructor Prozess.Destroy;
var
  I: Integer;
begin
  for I := 0 to System.Length(FLink)-1 do
    System.SysUtils.FreeAndNil(FLink[I]);
  System.SetLength(FLink, 0);
  inherited Destroy;
end;

procedure Prozess.SetVersion(Index: Integer; const Astring: string);
begin
  FVersion := Astring;
  FVersion_Specified := True;
end;

function Prozess.Version_Specified(Index: Integer): boolean;
begin
  Result := FVersion_Specified;
end;

procedure Prozess.SetTeilprozesse(Index: Integer; const ATeilprozesse: Teilprozesse);
begin
  FTeilprozesse := ATeilprozesse;
  FTeilprozesse_Specified := True;
end;

function Prozess.Teilprozesse_Specified(Index: Integer): boolean;
begin
  Result := FTeilprozesse_Specified;
end;

procedure Prozess.SetURL(Index: Integer; const Astring: string);
begin
  FURL := Astring;
  FURL_Specified := True;
end;

function Prozess.URL_Specified(Index: Integer): boolean;
begin
  Result := FURL_Specified;
end;

procedure Prozess.SetLink(Index: Integer; const AArray_Of_Link: Array_Of_Link);
begin
  FLink := AArray_Of_Link;
  FLink_Specified := True;
end;

function Prozess.Link_Specified(Index: Integer): boolean;
begin
  Result := FLink_Specified;
end;

constructor GetIndividuelleAuskunftResponse.Create;
begin
  inherited Create;
  FSerializationOptions := [xoLiteralParam];
end;

destructor GetIndividuelleAuskunftResponse.Destroy;
var
  I: Integer;
begin
  for I := 0 to System.Length(FProzessliste)-1 do
    System.SysUtils.FreeAndNil(FProzessliste[I]);
  System.SetLength(FProzessliste, 0);
  System.SysUtils.FreeAndNil(FStatus);
  inherited Destroy;
end;

procedure GetIndividuelleAuskunftResponse.SetSchnittstellenversion(Index: Integer; const Astring: string);
begin
  FSchnittstellenversion := Astring;
  FSchnittstellenversion_Specified := True;
end;

function GetIndividuelleAuskunftResponse.Schnittstellenversion_Specified(Index: Integer): boolean;
begin
  Result := FSchnittstellenversion_Specified;
end;

procedure GetIndividuelleAuskunftResponse.SetServerkennung(Index: Integer; const Astring: string);
begin
  FServerkennung := Astring;
  FServerkennung_Specified := True;
end;

function GetIndividuelleAuskunftResponse.Serverkennung_Specified(Index: Integer): boolean;
begin
  Result := FServerkennung_Specified;
end;

procedure GetIndividuelleAuskunftResponse.SetStatus(Index: Integer; const AStatus: Status);
begin
  FStatus := AStatus;
  FStatus_Specified := True;
end;

function GetIndividuelleAuskunftResponse.Status_Specified(Index: Integer): boolean;
begin
  Result := FStatus_Specified;
end;

procedure GetIndividuelleAuskunftResponse.SetProzessliste(Index: Integer; const AProzessliste: Prozessliste);
begin
  FProzessliste := AProzessliste;
  FProzessliste_Specified := True;
end;

function GetIndividuelleAuskunftResponse.Prozessliste_Specified(Index: Integer): boolean;
begin
  Result := FProzessliste_Specified;
end;

procedure Status.SetMeldung(Index: Integer; const Astring: string);
begin
  FMeldung := Astring;
  FMeldung_Specified := True;
end;

function Status.Meldung_Specified(Index: Integer): boolean;
begin
  Result := FMeldung_Specified;
end;

initialization
  { AnwenderIndividuelleAuskuenfteBean }
  InvRegistry.RegisterInterface(TypeInfo(AnwenderIndividuelleAuskuenfteBean), 'http://service.shk-connect.de', 'UTF-8');
  InvRegistry.RegisterDefaultSOAPAction(TypeInfo(AnwenderIndividuelleAuskuenfteBean), '');
  InvRegistry.RegisterInvokeOptions(TypeInfo(AnwenderIndividuelleAuskuenfteBean), ioDocument);
  InvRegistry.RegisterInvokeOptions(TypeInfo(AnwenderIndividuelleAuskuenfteBean), ioLiteral);
  RemClassRegistry.RegisterXSInfo(TypeInfo(Authentifizierungsmethode), 'http://service.shk-connect.de', 'Authentifizierungsmethode');
  RemClassRegistry.RegisterXSInfo(TypeInfo(Array_Of_Link), 'http://service.shk-connect.de', 'Array_Of_Link');
  RemClassRegistry.RegisterXSInfo(TypeInfo(Teilprozesse), 'http://service.shk-connect.de', 'Teilprozesse');
  RemClassRegistry.RegisterXSInfo(TypeInfo(CookieList), 'http://service.shk-connect.de', 'CookieList');
  RemClassRegistry.RegisterXSClass(Link, 'http://service.shk-connect.de', 'Link');
  RemClassRegistry.RegisterExternalPropName(TypeInfo(Link), 'CookieList', '[ArrayItemName="Cookie"]');
  RemClassRegistry.RegisterXSClass(GetIndividuelleAuskunft2, 'http://service.shk-connect.de', 'GetIndividuelleAuskunft2', 'GetIndividuelleAuskunft');
  RemClassRegistry.RegisterSerializeOptions(GetIndividuelleAuskunft2, [xoLiteralParam]);
  RemClassRegistry.RegisterXSClass(GetIndividuelleAuskunft, 'http://service.shk-connect.de', 'GetIndividuelleAuskunft');
  RemClassRegistry.RegisterXSClass(Prozess, 'http://service.shk-connect.de', 'Prozess');
  RemClassRegistry.RegisterExternalPropName(TypeInfo(Prozess), 'Teilprozesse', '[ArrayItemName="Teilprozess"]');
  RemClassRegistry.RegisterXSInfo(TypeInfo(Prozessliste), 'http://service.shk-connect.de', 'Prozessliste');
  RemClassRegistry.RegisterXSClass(GetIndividuelleAuskunftResponse, 'http://service.shk-connect.de', 'GetIndividuelleAuskunftResponse');
  RemClassRegistry.RegisterExternalPropName(TypeInfo(GetIndividuelleAuskunftResponse), 'Prozessliste', '[ArrayItemName="Prozess"]');
  RemClassRegistry.RegisterSerializeOptions(GetIndividuelleAuskunftResponse, [xoLiteralParam]);
  RemClassRegistry.RegisterXSClass(GetIndividuelleAuskunftAntwort, 'http://service.shk-connect.de', 'GetIndividuelleAuskunftAntwort');
  RemClassRegistry.RegisterXSClass(Status, 'http://service.shk-connect.de', 'Status');

end.