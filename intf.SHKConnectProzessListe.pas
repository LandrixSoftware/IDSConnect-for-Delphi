// ************************************************************************ //
// Die in dieser Datei deklarierten Typen wurden aus Daten der unten
// beschriebenen WSDL-Datei generiert:

// WSDL     : https://shkgh20.shk-connect.de/services/ProzessListe?wsdl
//  >Import : https://shkgh20.shk-connect.de/services/ProzessListe?wsdl>0
// Codierung : UTF-8
// Version: 1.0
// (02.11.2020 22:45:08 - - $Rev: 101104 $)
// ************************************************************************ //

unit intf_SHKConnectProzessListe;

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
  // !:string          - "http://www.w3.org/2001/XMLSchema"[Gbl]

  GetProzessListe2     = class;                 { "http://service.shk-connect.de"[Lit][GblCplx] }
  GetProzessListe      = class;                 { "http://service.shk-connect.de"[Lit][GblElm] }
  Teilprozess          = class;                 { "http://service.shk-connect.de"[GblCplx] }
  GetProzessListeResponse = class;              { "http://service.shk-connect.de"[Lit][GblCplx] }
  GetProzessListeAntwort = class;               { "http://service.shk-connect.de"[Lit][GblElm] }
  Status               = class;                 { "http://service.shk-connect.de"[GblCplx] }
  Prozess              = class;                 { "http://service.shk-connect.de"[GblCplx] }

  Array_Of_Prozess = array of Prozess;          { "http://service.shk-connect.de"[GblUbnd] }
  Array_Of_Teilprozess = array of Teilprozess;   { "http://service.shk-connect.de"[GblUbnd] }


  // ************************************************************************ //
  // XML       : GetProzessListe, global, <complexType>
  // Namespace : http://service.shk-connect.de
  // Serializtn: [xoLiteralParam]
  // Info      : Wrapper
  // ************************************************************************ //
  GetProzessListe2 = class(TRemotable)
  private
    FSchnittstellenversion: string;
    FSoftwarename: string;
    FSoftwarepasswort: string;
  public
    constructor Create; override;
  published
    property Schnittstellenversion: string  Index (IS_UNQL) read FSchnittstellenversion write FSchnittstellenversion;
    property Softwarename:          string  Index (IS_UNQL) read FSoftwarename write FSoftwarename;
    property Softwarepasswort:      string  Index (IS_UNQL) read FSoftwarepasswort write FSoftwarepasswort;
  end;



  // ************************************************************************ //
  // XML       : GetProzessListe, global, <element>
  // Namespace : http://service.shk-connect.de
  // Info      : Wrapper
  // ************************************************************************ //
  GetProzessListe = class(GetProzessListe2)
  private
  published
  end;



  // ************************************************************************ //
  // XML       : Teilprozess, global, <complexType>
  // Namespace : http://service.shk-connect.de
  // ************************************************************************ //
  Teilprozess = class(TRemotable)
  private
    FTeilprozesscode: string;
    FVersion: string;
    FName_: string;
  published
    property Teilprozesscode: string  Index (IS_UNQL) read FTeilprozesscode write FTeilprozesscode;
    property Version:         string  Index (IS_UNQL) read FVersion write FVersion;
    property Name_:           string  Index (IS_UNQL) read FName_ write FName_;
  end;



  // ************************************************************************ //
  // XML       : GetProzessListeResponse, global, <complexType>
  // Namespace : http://service.shk-connect.de
  // Serializtn: [xoLiteralParam]
  // Info      : Wrapper
  // ************************************************************************ //
  GetProzessListeResponse = class(TRemotable)
  private
    FSchnittstellenversion: string;
    FServerkennung: string;
    FStatus: Status;
    FProzess: Array_Of_Prozess;
    FProzess_Specified: boolean;
    procedure SetProzess(Index: Integer; const AArray_Of_Prozess: Array_Of_Prozess);
    function  Prozess_Specified(Index: Integer): boolean;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    property Schnittstellenversion: string            Index (IS_UNQL) read FSchnittstellenversion write FSchnittstellenversion;
    property Serverkennung:         string            Index (IS_UNQL) read FServerkennung write FServerkennung;
    property Status:                Status            Index (IS_UNQL) read FStatus write FStatus;
    property Prozess:               Array_Of_Prozess  Index (IS_OPTN or IS_UNBD or IS_UNQL) read FProzess write SetProzess stored Prozess_Specified;
  end;



  // ************************************************************************ //
  // XML       : GetProzessListeAntwort, global, <element>
  // Namespace : http://service.shk-connect.de
  // Info      : Wrapper
  // ************************************************************************ //
  GetProzessListeAntwort = class(GetProzessListeResponse)
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
  // XML       : Prozess, global, <complexType>
  // Namespace : http://service.shk-connect.de
  // ************************************************************************ //
  Prozess = class(TRemotable)
  private
    FProzesscode: string;
    FVersion: string;
    FName_: string;
    FTeilprozess: Array_Of_Teilprozess;
    FTeilprozess_Specified: boolean;
    procedure SetTeilprozess(Index: Integer; const AArray_Of_Teilprozess: Array_Of_Teilprozess);
    function  Teilprozess_Specified(Index: Integer): boolean;
  public
    destructor Destroy; override;
  published
    property Prozesscode: string                Index (IS_UNQL) read FProzesscode write FProzesscode;
    property Version:     string                Index (IS_UNQL) read FVersion write FVersion;
    property Name_:       string                Index (IS_UNQL) read FName_ write FName_;
    property Teilprozess: Array_Of_Teilprozess  Index (IS_OPTN or IS_UNBD or IS_UNQL) read FTeilprozess write SetTeilprozess stored Teilprozess_Specified;
  end;


  // ************************************************************************ //
  // Namespace : http://service.shk-connect.de
  // Transport : http://schemas.xmlsoap.org/soap/http
  // Stil     : document
  // Verwenden von       : literal
  // Bindung   : ProzessListeBeanImplBinding
  // Service   : ProzessListeService
  // Port      : ProzessListeServicePort
  // URL       : https://shkgh20.shk-connect.de/services/ProzessListe
  // ************************************************************************ //
  ProzessListeBeanImpl = interface(IInvokable)
  ['{AAF152AB-CA65-FB96-817F-55666D242D44}']

    // Entpacken nicht möglich: 
    //     - Mehrere strenge out-Elemente gefunden
    function  GetProzessListe(const GetProzessListe: GetProzessListe): GetProzessListeAntwort; stdcall;
  end;

function GetProzessListeBeanImpl(UseWSDL: Boolean=System.False; Addr: string=''; HTTPRIO: THTTPRIO = nil): ProzessListeBeanImpl;


implementation
  uses System.SysUtils;

function GetProzessListeBeanImpl(UseWSDL: Boolean; Addr: string; HTTPRIO: THTTPRIO): ProzessListeBeanImpl;
const
  defWSDL = 'https://shkgh20.shk-connect.de/services/ProzessListe?wsdl';
  defURL  = 'https://shkgh20.shk-connect.de/services/ProzessListe';
  defSvc  = 'ProzessListeService';
  defPrt  = 'ProzessListeServicePort';
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
    Result := (RIO as ProzessListeBeanImpl);
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


constructor GetProzessListe2.Create;
begin
  inherited Create;
  FSerializationOptions := [xoLiteralParam];
end;

constructor GetProzessListeResponse.Create;
begin
  inherited Create;
  FSerializationOptions := [xoLiteralParam];
end;

destructor GetProzessListeResponse.Destroy;
var
  I: Integer;
begin
  for I := 0 to System.Length(FProzess)-1 do
    System.SysUtils.FreeAndNil(FProzess[I]);
  System.SetLength(FProzess, 0);
  System.SysUtils.FreeAndNil(FStatus);
  inherited Destroy;
end;

procedure GetProzessListeResponse.SetProzess(Index: Integer; const AArray_Of_Prozess: Array_Of_Prozess);
begin
  FProzess := AArray_Of_Prozess;
  FProzess_Specified := True;
end;

function GetProzessListeResponse.Prozess_Specified(Index: Integer): boolean;
begin
  Result := FProzess_Specified;
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

destructor Prozess.Destroy;
var
  I: Integer;
begin
  for I := 0 to System.Length(FTeilprozess)-1 do
    System.SysUtils.FreeAndNil(FTeilprozess[I]);
  System.SetLength(FTeilprozess, 0);
  inherited Destroy;
end;

procedure Prozess.SetTeilprozess(Index: Integer; const AArray_Of_Teilprozess: Array_Of_Teilprozess);
begin
  FTeilprozess := AArray_Of_Teilprozess;
  FTeilprozess_Specified := True;
end;

function Prozess.Teilprozess_Specified(Index: Integer): boolean;
begin
  Result := FTeilprozess_Specified;
end;

initialization
  { ProzessListeBeanImpl }
  InvRegistry.RegisterInterface(TypeInfo(ProzessListeBeanImpl), 'http://service.shk-connect.de', 'UTF-8');
  InvRegistry.RegisterDefaultSOAPAction(TypeInfo(ProzessListeBeanImpl), '');
  InvRegistry.RegisterInvokeOptions(TypeInfo(ProzessListeBeanImpl), ioDocument);
  InvRegistry.RegisterInvokeOptions(TypeInfo(ProzessListeBeanImpl), ioLiteral);
  RemClassRegistry.RegisterXSInfo(TypeInfo(Array_Of_Prozess), 'http://service.shk-connect.de', 'Array_Of_Prozess');
  RemClassRegistry.RegisterXSInfo(TypeInfo(Array_Of_Teilprozess), 'http://service.shk-connect.de', 'Array_Of_Teilprozess');
  RemClassRegistry.RegisterXSClass(GetProzessListe2, 'http://service.shk-connect.de', 'GetProzessListe2', 'GetProzessListe');
  RemClassRegistry.RegisterSerializeOptions(GetProzessListe2, [xoLiteralParam]);
  RemClassRegistry.RegisterXSClass(GetProzessListe, 'http://service.shk-connect.de', 'GetProzessListe');
  RemClassRegistry.RegisterXSClass(Teilprozess, 'http://service.shk-connect.de', 'Teilprozess');
  RemClassRegistry.RegisterExternalPropName(TypeInfo(Teilprozess), 'Name_', '[ExtName="Name"]');
  RemClassRegistry.RegisterXSClass(GetProzessListeResponse, 'http://service.shk-connect.de', 'GetProzessListeResponse');
  RemClassRegistry.RegisterSerializeOptions(GetProzessListeResponse, [xoLiteralParam]);
  RemClassRegistry.RegisterXSClass(GetProzessListeAntwort, 'http://service.shk-connect.de', 'GetProzessListeAntwort');
  RemClassRegistry.RegisterXSClass(Status, 'http://service.shk-connect.de', 'Status');
  RemClassRegistry.RegisterXSClass(Prozess, 'http://service.shk-connect.de', 'Prozess');
  RemClassRegistry.RegisterExternalPropName(TypeInfo(Prozess), 'Name_', '[ExtName="Name"]');

end.