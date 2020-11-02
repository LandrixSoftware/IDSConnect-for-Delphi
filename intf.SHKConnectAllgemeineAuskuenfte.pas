// ************************************************************************ //
// Die in dieser Datei deklarierten Typen wurden aus Daten der unten
// beschriebenen WSDL-Datei generiert:

// WSDL     : https://shkgh20.shk-connect.de/services/AllgemeineAuskuenfte?wsdl
//  >Import : https://shkgh20.shk-connect.de/services/AllgemeineAuskuenfte?wsdl>0
// Codierung : UTF-8
// Version: 1.0
// (02.11.2020 22:45:08 - - $Rev: 101104 $)
// ************************************************************************ //

unit intf_SHKConnectAllgemeineAuskuenfte;

interface

uses Soap.InvokeRegistry, Soap.SOAPHTTPClient, System.Types, Soap.XSBuiltIns;

const
  IS_OPTN = $0001;
  IS_UNBD = $0002;
  IS_UNQL = $0008;


type

  // ************************************************************************ //
  // Die folgenden Typen, auf die im WSDL-Dokument Bezug genommen wird, sind in dieser Datei
  // nicht repräsentiert. Sie sind entweder Aliase[@] anderer repräsentierter Typen oder auf sie wurde Bezug genommen,
  // aber sie sind in diesem Dokument nicht[!] deklariert. Die Typen aus letzterer Kategorie
  // sind in der Regel vordefinierten/bekannten XML- oder Embarcadero-Typen zugeordnet; sie könnten aber auf 
  // ein inkorrektes WSDL-Dokument hinweisen, das einen Schematyp nicht deklariert oder importiert hat.
  // ************************************************************************ //
  // !:int             - "http://www.w3.org/2001/XMLSchema"[Gbl]
  // !:boolean         - "http://www.w3.org/2001/XMLSchema"[Gbl]
  // !:string          - "http://www.w3.org/2001/XMLSchema"[Gbl]

  GetAllgemeineAuskunft2 = class;               { "http://service.shk-connect.de"[Lit][GblCplx] }
  GetAllgemeineAuskunft = class;                { "http://service.shk-connect.de"[Lit][GblElm] }
  Unternehmen          = class;                 { "http://service.shk-connect.de"[GblCplx] }
  Umkreis              = class;                 { "http://service.shk-connect.de"[GblCplx] }
  GetAllgemeineAuskunftResponse = class;        { "http://service.shk-connect.de"[Lit][GblCplx] }
  GetAllgemeineAuskunftAntwort = class;         { "http://service.shk-connect.de"[Lit][GblElm] }
  Status               = class;                 { "http://service.shk-connect.de"[GblCplx] }

  Array_Of_Unternehmen = array of Unternehmen;   { "http://service.shk-connect.de"[GblUbnd] }


  // ************************************************************************ //
  // XML       : GetAllgemeineAuskunft, global, <complexType>
  // Namespace : http://service.shk-connect.de
  // Serializtn: [xoLiteralParam]
  // Info      : Wrapper
  // ************************************************************************ //
  GetAllgemeineAuskunft2 = class(TRemotable)
  private
    FSchnittstellenversion: string;
    FSchnittstellenversion_Specified: boolean;
    FSoftwarename: string;
    FSoftwarename_Specified: boolean;
    FSoftwarepasswort: string;
    FSoftwarepasswort_Specified: boolean;
    FProzess: string;
    FProzess_Specified: boolean;
    FVersion: string;
    FVersion_Specified: boolean;
    FBrancheID: string;
    FBrancheID_Specified: boolean;
    FUmkreis: Umkreis;
    FUmkreis_Specified: boolean;
    procedure SetSchnittstellenversion(Index: Integer; const Astring: string);
    function  Schnittstellenversion_Specified(Index: Integer): boolean;
    procedure SetSoftwarename(Index: Integer; const Astring: string);
    function  Softwarename_Specified(Index: Integer): boolean;
    procedure SetSoftwarepasswort(Index: Integer; const Astring: string);
    function  Softwarepasswort_Specified(Index: Integer): boolean;
    procedure SetProzess(Index: Integer; const Astring: string);
    function  Prozess_Specified(Index: Integer): boolean;
    procedure SetVersion(Index: Integer; const Astring: string);
    function  Version_Specified(Index: Integer): boolean;
    procedure SetBrancheID(Index: Integer; const Astring: string);
    function  BrancheID_Specified(Index: Integer): boolean;
    procedure SetUmkreis(Index: Integer; const AUmkreis: Umkreis);
    function  Umkreis_Specified(Index: Integer): boolean;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    property Schnittstellenversion: string   Index (IS_OPTN or IS_UNQL) read FSchnittstellenversion write SetSchnittstellenversion stored Schnittstellenversion_Specified;
    property Softwarename:          string   Index (IS_OPTN or IS_UNQL) read FSoftwarename write SetSoftwarename stored Softwarename_Specified;
    property Softwarepasswort:      string   Index (IS_OPTN or IS_UNQL) read FSoftwarepasswort write SetSoftwarepasswort stored Softwarepasswort_Specified;
    property Prozess:               string   Index (IS_OPTN or IS_UNQL) read FProzess write SetProzess stored Prozess_Specified;
    property Version:               string   Index (IS_OPTN or IS_UNQL) read FVersion write SetVersion stored Version_Specified;
    property BrancheID:             string   Index (IS_OPTN or IS_UNQL) read FBrancheID write SetBrancheID stored BrancheID_Specified;
    property Umkreis:               Umkreis  Index (IS_OPTN or IS_UNQL) read FUmkreis write SetUmkreis stored Umkreis_Specified;
  end;



  // ************************************************************************ //
  // XML       : GetAllgemeineAuskunft, global, <element>
  // Namespace : http://service.shk-connect.de
  // Info      : Wrapper
  // ************************************************************************ //
  GetAllgemeineAuskunft = class(GetAllgemeineAuskunft2)
  private
  published
  end;



  // ************************************************************************ //
  // XML       : Unternehmen, global, <complexType>
  // Namespace : http://service.shk-connect.de
  // ************************************************************************ //
  Unternehmen = class(TRemotable)
  private
    FID: Integer;
    FName_: string;
    FStrasse: string;
    FStrasse_Specified: boolean;
    FPLZ: string;
    FPLZ_Specified: boolean;
    FOrt: string;
    FOrt_Specified: boolean;
    FLand: string;
    FLand_Specified: boolean;
    FKundennummer_erforderlich: Boolean;
    FKundennummer_erforderlich_Specified: boolean;
    FBenutzername_erforderlich: Boolean;
    FBenutzername_erforderlich_Specified: boolean;
    FPasswort_erforderlich: Boolean;
    FPasswort_erforderlich_Specified: boolean;
    procedure SetStrasse(Index: Integer; const Astring: string);
    function  Strasse_Specified(Index: Integer): boolean;
    procedure SetPLZ(Index: Integer; const Astring: string);
    function  PLZ_Specified(Index: Integer): boolean;
    procedure SetOrt(Index: Integer; const Astring: string);
    function  Ort_Specified(Index: Integer): boolean;
    procedure SetLand(Index: Integer; const Astring: string);
    function  Land_Specified(Index: Integer): boolean;
    procedure SetKundennummer_erforderlich(Index: Integer; const ABoolean: Boolean);
    function  Kundennummer_erforderlich_Specified(Index: Integer): boolean;
    procedure SetBenutzername_erforderlich(Index: Integer; const ABoolean: Boolean);
    function  Benutzername_erforderlich_Specified(Index: Integer): boolean;
    procedure SetPasswort_erforderlich(Index: Integer; const ABoolean: Boolean);
    function  Passwort_erforderlich_Specified(Index: Integer): boolean;
  published
    property ID:                        Integer  Index (IS_UNQL) read FID write FID;
    property Name_:                     string   Index (IS_UNQL) read FName_ write FName_;
    property Strasse:                   string   Index (IS_OPTN or IS_UNQL) read FStrasse write SetStrasse stored Strasse_Specified;
    property PLZ:                       string   Index (IS_OPTN or IS_UNQL) read FPLZ write SetPLZ stored PLZ_Specified;
    property Ort:                       string   Index (IS_OPTN or IS_UNQL) read FOrt write SetOrt stored Ort_Specified;
    property Land:                      string   Index (IS_OPTN or IS_UNQL) read FLand write SetLand stored Land_Specified;
    property Kundennummer_erforderlich: Boolean  Index (IS_OPTN or IS_UNQL) read FKundennummer_erforderlich write SetKundennummer_erforderlich stored Kundennummer_erforderlich_Specified;
    property Benutzername_erforderlich: Boolean  Index (IS_OPTN or IS_UNQL) read FBenutzername_erforderlich write SetBenutzername_erforderlich stored Benutzername_erforderlich_Specified;
    property Passwort_erforderlich:     Boolean  Index (IS_OPTN or IS_UNQL) read FPasswort_erforderlich write SetPasswort_erforderlich stored Passwort_erforderlich_Specified;
  end;



  // ************************************************************************ //
  // XML       : Umkreis, global, <complexType>
  // Namespace : http://service.shk-connect.de
  // ************************************************************************ //
  Umkreis = class(TRemotable)
  private
    FPostleitzahl: string;
    FEntfernung: string;
  published
    property Postleitzahl: string  Index (IS_UNQL) read FPostleitzahl write FPostleitzahl;
    property Entfernung:   string  Index (IS_UNQL) read FEntfernung write FEntfernung;
  end;



  // ************************************************************************ //
  // XML       : GetAllgemeineAuskunftResponse, global, <complexType>
  // Namespace : http://service.shk-connect.de
  // Serializtn: [xoLiteralParam]
  // Info      : Wrapper
  // ************************************************************************ //
  GetAllgemeineAuskunftResponse = class(TRemotable)
  private
    FSchnittstellenversion: string;
    FSchnittstellenversion_Specified: boolean;
    FServerkennung: string;
    FServerkennung_Specified: boolean;
    FStatus: Status;
    FStatus_Specified: boolean;
    FUnternehmen: Array_Of_Unternehmen;
    FUnternehmen_Specified: boolean;
    procedure SetSchnittstellenversion(Index: Integer; const Astring: string);
    function  Schnittstellenversion_Specified(Index: Integer): boolean;
    procedure SetServerkennung(Index: Integer; const Astring: string);
    function  Serverkennung_Specified(Index: Integer): boolean;
    procedure SetStatus(Index: Integer; const AStatus: Status);
    function  Status_Specified(Index: Integer): boolean;
    procedure SetUnternehmen(Index: Integer; const AArray_Of_Unternehmen: Array_Of_Unternehmen);
    function  Unternehmen_Specified(Index: Integer): boolean;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    property Schnittstellenversion: string                Index (IS_OPTN or IS_UNQL) read FSchnittstellenversion write SetSchnittstellenversion stored Schnittstellenversion_Specified;
    property Serverkennung:         string                Index (IS_OPTN or IS_UNQL) read FServerkennung write SetServerkennung stored Serverkennung_Specified;
    property Status:                Status                Index (IS_OPTN or IS_UNQL) read FStatus write SetStatus stored Status_Specified;
    property Unternehmen:           Array_Of_Unternehmen  Index (IS_OPTN or IS_UNBD or IS_UNQL) read FUnternehmen write SetUnternehmen stored Unternehmen_Specified;
  end;



  // ************************************************************************ //
  // XML       : GetAllgemeineAuskunftAntwort, global, <element>
  // Namespace : http://service.shk-connect.de
  // Info      : Wrapper
  // ************************************************************************ //
  GetAllgemeineAuskunftAntwort = class(GetAllgemeineAuskunftResponse)
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
  // Bindung   : AllgemeineAuskuenfteBeanBinding
  // Service   : allgemeineAuskuenfteService
  // Port      : allgemeineAuskuenftePort
  // URL       : https://shkgh20.shk-connect.de/services/AllgemeineAuskuenfte
  // ************************************************************************ //
  AllgemeineAuskuenfteBean = interface(IInvokable)
  ['{CBE248A0-C3D0-960A-D598-C329A3636445}']

    // Entpacken nicht möglich: 
    //     - Mehrere strenge out-Elemente gefunden
    function  GetAllgemeineAuskunft(const GetAllgemeineAuskunft: GetAllgemeineAuskunft): GetAllgemeineAuskunftAntwort; stdcall;
  end;

function GetAllgemeineAuskuenfteBean(UseWSDL: Boolean=System.False; Addr: string=''; HTTPRIO: THTTPRIO = nil): AllgemeineAuskuenfteBean;


implementation
  uses System.SysUtils;

function GetAllgemeineAuskuenfteBean(UseWSDL: Boolean; Addr: string; HTTPRIO: THTTPRIO): AllgemeineAuskuenfteBean;
const
  defWSDL = 'https://shkgh20.shk-connect.de/services/AllgemeineAuskuenfte?wsdl';
  defURL  = 'https://shkgh20.shk-connect.de/services/AllgemeineAuskuenfte';
  defSvc  = 'allgemeineAuskuenfteService';
  defPrt  = 'allgemeineAuskuenftePort';
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
    Result := (RIO as AllgemeineAuskuenfteBean);
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


constructor GetAllgemeineAuskunft2.Create;
begin
  inherited Create;
  FSerializationOptions := [xoLiteralParam];
end;

destructor GetAllgemeineAuskunft2.Destroy;
begin
  System.SysUtils.FreeAndNil(FUmkreis);
  inherited Destroy;
end;

procedure GetAllgemeineAuskunft2.SetSchnittstellenversion(Index: Integer; const Astring: string);
begin
  FSchnittstellenversion := Astring;
  FSchnittstellenversion_Specified := True;
end;

function GetAllgemeineAuskunft2.Schnittstellenversion_Specified(Index: Integer): boolean;
begin
  Result := FSchnittstellenversion_Specified;
end;

procedure GetAllgemeineAuskunft2.SetSoftwarename(Index: Integer; const Astring: string);
begin
  FSoftwarename := Astring;
  FSoftwarename_Specified := True;
end;

function GetAllgemeineAuskunft2.Softwarename_Specified(Index: Integer): boolean;
begin
  Result := FSoftwarename_Specified;
end;

procedure GetAllgemeineAuskunft2.SetSoftwarepasswort(Index: Integer; const Astring: string);
begin
  FSoftwarepasswort := Astring;
  FSoftwarepasswort_Specified := True;
end;

function GetAllgemeineAuskunft2.Softwarepasswort_Specified(Index: Integer): boolean;
begin
  Result := FSoftwarepasswort_Specified;
end;

procedure GetAllgemeineAuskunft2.SetProzess(Index: Integer; const Astring: string);
begin
  FProzess := Astring;
  FProzess_Specified := True;
end;

function GetAllgemeineAuskunft2.Prozess_Specified(Index: Integer): boolean;
begin
  Result := FProzess_Specified;
end;

procedure GetAllgemeineAuskunft2.SetVersion(Index: Integer; const Astring: string);
begin
  FVersion := Astring;
  FVersion_Specified := True;
end;

function GetAllgemeineAuskunft2.Version_Specified(Index: Integer): boolean;
begin
  Result := FVersion_Specified;
end;

procedure GetAllgemeineAuskunft2.SetBrancheID(Index: Integer; const Astring: string);
begin
  FBrancheID := Astring;
  FBrancheID_Specified := True;
end;

function GetAllgemeineAuskunft2.BrancheID_Specified(Index: Integer): boolean;
begin
  Result := FBrancheID_Specified;
end;

procedure GetAllgemeineAuskunft2.SetUmkreis(Index: Integer; const AUmkreis: Umkreis);
begin
  FUmkreis := AUmkreis;
  FUmkreis_Specified := True;
end;

function GetAllgemeineAuskunft2.Umkreis_Specified(Index: Integer): boolean;
begin
  Result := FUmkreis_Specified;
end;

procedure Unternehmen.SetStrasse(Index: Integer; const Astring: string);
begin
  FStrasse := Astring;
  FStrasse_Specified := True;
end;

function Unternehmen.Strasse_Specified(Index: Integer): boolean;
begin
  Result := FStrasse_Specified;
end;

procedure Unternehmen.SetPLZ(Index: Integer; const Astring: string);
begin
  FPLZ := Astring;
  FPLZ_Specified := True;
end;

function Unternehmen.PLZ_Specified(Index: Integer): boolean;
begin
  Result := FPLZ_Specified;
end;

procedure Unternehmen.SetOrt(Index: Integer; const Astring: string);
begin
  FOrt := Astring;
  FOrt_Specified := True;
end;

function Unternehmen.Ort_Specified(Index: Integer): boolean;
begin
  Result := FOrt_Specified;
end;

procedure Unternehmen.SetLand(Index: Integer; const Astring: string);
begin
  FLand := Astring;
  FLand_Specified := True;
end;

function Unternehmen.Land_Specified(Index: Integer): boolean;
begin
  Result := FLand_Specified;
end;

procedure Unternehmen.SetKundennummer_erforderlich(Index: Integer; const ABoolean: Boolean);
begin
  FKundennummer_erforderlich := ABoolean;
  FKundennummer_erforderlich_Specified := True;
end;

function Unternehmen.Kundennummer_erforderlich_Specified(Index: Integer): boolean;
begin
  Result := FKundennummer_erforderlich_Specified;
end;

procedure Unternehmen.SetBenutzername_erforderlich(Index: Integer; const ABoolean: Boolean);
begin
  FBenutzername_erforderlich := ABoolean;
  FBenutzername_erforderlich_Specified := True;
end;

function Unternehmen.Benutzername_erforderlich_Specified(Index: Integer): boolean;
begin
  Result := FBenutzername_erforderlich_Specified;
end;

procedure Unternehmen.SetPasswort_erforderlich(Index: Integer; const ABoolean: Boolean);
begin
  FPasswort_erforderlich := ABoolean;
  FPasswort_erforderlich_Specified := True;
end;

function Unternehmen.Passwort_erforderlich_Specified(Index: Integer): boolean;
begin
  Result := FPasswort_erforderlich_Specified;
end;

constructor GetAllgemeineAuskunftResponse.Create;
begin
  inherited Create;
  FSerializationOptions := [xoLiteralParam];
end;

destructor GetAllgemeineAuskunftResponse.Destroy;
var
  I: Integer;
begin
  for I := 0 to System.Length(FUnternehmen)-1 do
    System.SysUtils.FreeAndNil(FUnternehmen[I]);
  System.SetLength(FUnternehmen, 0);
  System.SysUtils.FreeAndNil(FStatus);
  inherited Destroy;
end;

procedure GetAllgemeineAuskunftResponse.SetSchnittstellenversion(Index: Integer; const Astring: string);
begin
  FSchnittstellenversion := Astring;
  FSchnittstellenversion_Specified := True;
end;

function GetAllgemeineAuskunftResponse.Schnittstellenversion_Specified(Index: Integer): boolean;
begin
  Result := FSchnittstellenversion_Specified;
end;

procedure GetAllgemeineAuskunftResponse.SetServerkennung(Index: Integer; const Astring: string);
begin
  FServerkennung := Astring;
  FServerkennung_Specified := True;
end;

function GetAllgemeineAuskunftResponse.Serverkennung_Specified(Index: Integer): boolean;
begin
  Result := FServerkennung_Specified;
end;

procedure GetAllgemeineAuskunftResponse.SetStatus(Index: Integer; const AStatus: Status);
begin
  FStatus := AStatus;
  FStatus_Specified := True;
end;

function GetAllgemeineAuskunftResponse.Status_Specified(Index: Integer): boolean;
begin
  Result := FStatus_Specified;
end;

procedure GetAllgemeineAuskunftResponse.SetUnternehmen(Index: Integer; const AArray_Of_Unternehmen: Array_Of_Unternehmen);
begin
  FUnternehmen := AArray_Of_Unternehmen;
  FUnternehmen_Specified := True;
end;

function GetAllgemeineAuskunftResponse.Unternehmen_Specified(Index: Integer): boolean;
begin
  Result := FUnternehmen_Specified;
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
  { AllgemeineAuskuenfteBean }
  InvRegistry.RegisterInterface(TypeInfo(AllgemeineAuskuenfteBean), 'http://service.shk-connect.de', 'UTF-8');
  InvRegistry.RegisterDefaultSOAPAction(TypeInfo(AllgemeineAuskuenfteBean), '');
  InvRegistry.RegisterInvokeOptions(TypeInfo(AllgemeineAuskuenfteBean), ioDocument);
  InvRegistry.RegisterInvokeOptions(TypeInfo(AllgemeineAuskuenfteBean), ioLiteral);
  RemClassRegistry.RegisterXSInfo(TypeInfo(Array_Of_Unternehmen), 'http://service.shk-connect.de', 'Array_Of_Unternehmen');
  RemClassRegistry.RegisterXSClass(GetAllgemeineAuskunft2, 'http://service.shk-connect.de', 'GetAllgemeineAuskunft2', 'GetAllgemeineAuskunft');
  RemClassRegistry.RegisterSerializeOptions(GetAllgemeineAuskunft2, [xoLiteralParam]);
  RemClassRegistry.RegisterXSClass(GetAllgemeineAuskunft, 'http://service.shk-connect.de', 'GetAllgemeineAuskunft');
  RemClassRegistry.RegisterXSClass(Unternehmen, 'http://service.shk-connect.de', 'Unternehmen');
  RemClassRegistry.RegisterExternalPropName(TypeInfo(Unternehmen), 'Name_', '[ExtName="Name"]');
  RemClassRegistry.RegisterXSClass(Umkreis, 'http://service.shk-connect.de', 'Umkreis');
  RemClassRegistry.RegisterXSClass(GetAllgemeineAuskunftResponse, 'http://service.shk-connect.de', 'GetAllgemeineAuskunftResponse');
  RemClassRegistry.RegisterSerializeOptions(GetAllgemeineAuskunftResponse, [xoLiteralParam]);
  RemClassRegistry.RegisterXSClass(GetAllgemeineAuskunftAntwort, 'http://service.shk-connect.de', 'GetAllgemeineAuskunftAntwort');
  RemClassRegistry.RegisterXSClass(Status, 'http://service.shk-connect.de', 'Status');

end.