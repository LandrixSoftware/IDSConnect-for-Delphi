// ************************************************************************ //
// Die in dieser Datei deklarierten Typen wurden aus Daten der unten
// beschriebenen WSDL-Datei generiert:

// WSDL     : https://shkgh20.shk-connect.de/services/Branchenliste?wsdl
//  >Import : https://shkgh20.shk-connect.de/services/Branchenliste?wsdl>0
// Codierung : UTF-8
// Version: 1.0
// (02.11.2020 22:45:08 - - $Rev: 101104 $)
// ************************************************************************ //

unit intf.SHKConnectBranchenliste;

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
  // !:string          - "http://www.w3.org/2001/XMLSchema"[Gbl]

  GetBranchenListe2    = class;                 { "http://service.shk-connect.de"[Lit][GblCplx] }
  GetBranchenListe     = class;                 { "http://service.shk-connect.de"[Lit][GblElm] }
  Branche              = class;                 { "http://service.shk-connect.de"[GblCplx] }
  GetBranchenListeResponse = class;             { "http://service.shk-connect.de"[Lit][GblCplx] }
  GetBranchenListeAntwort = class;              { "http://service.shk-connect.de"[Lit][GblElm] }
  Status               = class;                 { "http://service.shk-connect.de"[GblCplx] }

  Array_Of_Branche = array of Branche;          { "http://service.shk-connect.de"[GblUbnd] }


  // ************************************************************************ //
  // XML       : GetBranchenListe, global, <complexType>
  // Namespace : http://service.shk-connect.de
  // Serializtn: [xoLiteralParam]
  // Info      : Wrapper
  // ************************************************************************ //
  GetBranchenListe2 = class(TRemotable)
  private
    FSchnittstellenversion: string;
    FSchnittstellenversion_Specified: boolean;
    FSoftwarename: string;
    FSoftwarename_Specified: boolean;
    FSoftwarepasswort: string;
    FSoftwarepasswort_Specified: boolean;
    procedure SetSchnittstellenversion(Index: Integer; const Astring: string);
    function  Schnittstellenversion_Specified(Index: Integer): boolean;
    procedure SetSoftwarename(Index: Integer; const Astring: string);
    function  Softwarename_Specified(Index: Integer): boolean;
    procedure SetSoftwarepasswort(Index: Integer; const Astring: string);
    function  Softwarepasswort_Specified(Index: Integer): boolean;
  public
    constructor Create; override;
  published
    property Schnittstellenversion: string  Index (IS_OPTN or IS_UNQL) read FSchnittstellenversion write SetSchnittstellenversion stored Schnittstellenversion_Specified;
    property Softwarename:          string  Index (IS_OPTN or IS_UNQL) read FSoftwarename write SetSoftwarename stored Softwarename_Specified;
    property Softwarepasswort:      string  Index (IS_OPTN or IS_UNQL) read FSoftwarepasswort write SetSoftwarepasswort stored Softwarepasswort_Specified;
  end;



  // ************************************************************************ //
  // XML       : GetBranchenListe, global, <element>
  // Namespace : http://service.shk-connect.de
  // Info      : Wrapper
  // ************************************************************************ //
  GetBranchenListe = class(GetBranchenListe2)
  private
  published
  end;



  // ************************************************************************ //
  // XML       : Branche, global, <complexType>
  // Namespace : http://service.shk-connect.de
  // ************************************************************************ //
  Branche = class(TRemotable)
  private
    FID: Integer;
    FName_: string;
  published
    property ID:    Integer  Index (IS_UNQL) read FID write FID;
    property Name_: string   Index (IS_UNQL) read FName_ write FName_;
  end;



  // ************************************************************************ //
  // XML       : GetBranchenListeResponse, global, <complexType>
  // Namespace : http://service.shk-connect.de
  // Serializtn: [xoLiteralParam]
  // Info      : Wrapper
  // ************************************************************************ //
  GetBranchenListeResponse = class(TRemotable)
  private
    FSchnittstellenversion: string;
    FSchnittstellenversion_Specified: boolean;
    FServerkennung: string;
    FServerkennung_Specified: boolean;
    FStatus: Status;
    FStatus_Specified: boolean;
    FBranche: Array_Of_Branche;
    FBranche_Specified: boolean;
    procedure SetSchnittstellenversion(Index: Integer; const Astring: string);
    function  Schnittstellenversion_Specified(Index: Integer): boolean;
    procedure SetServerkennung(Index: Integer; const Astring: string);
    function  Serverkennung_Specified(Index: Integer): boolean;
    procedure SetStatus(Index: Integer; const AStatus: Status);
    function  Status_Specified(Index: Integer): boolean;
    procedure SetBranche(Index: Integer; const AArray_Of_Branche: Array_Of_Branche);
    function  Branche_Specified(Index: Integer): boolean;
  public
    constructor Create; override;
    destructor Destroy; override;
  published
    property Schnittstellenversion: string            Index (IS_OPTN or IS_UNQL) read FSchnittstellenversion write SetSchnittstellenversion stored Schnittstellenversion_Specified;
    property Serverkennung:         string            Index (IS_OPTN or IS_UNQL) read FServerkennung write SetServerkennung stored Serverkennung_Specified;
    property Status:                Status            Index (IS_OPTN or IS_UNQL) read FStatus write SetStatus stored Status_Specified;
    property Branche:               Array_Of_Branche  Index (IS_OPTN or IS_UNBD or IS_UNQL) read FBranche write SetBranche stored Branche_Specified;
  end;



  // ************************************************************************ //
  // XML       : GetBranchenListeAntwort, global, <element>
  // Namespace : http://service.shk-connect.de
  // Info      : Wrapper
  // ************************************************************************ //
  GetBranchenListeAntwort = class(GetBranchenListeResponse)
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
  // Bindung   : BranchenlisteBeanBinding
  // Service   : branchenListeService
  // Port      : branchenListeServicePort
  // URL       : https://shkgh20.shk-connect.de/services/Branchenliste
  // ************************************************************************ //
  BranchenlisteBean = interface(IInvokable)
  ['{C41F7F18-AE12-06EA-E359-E7B6598797DA}']

    // Entpacken nicht möglich: 
    //     - Mehrere strenge out-Elemente gefunden
    function  GetBranchenListe(const GetBranchenListe: GetBranchenListe): GetBranchenListeAntwort; stdcall;
  end;

function GetBranchenlisteBean(UseWSDL: Boolean=System.False; Addr: string=''; HTTPRIO: THTTPRIO = nil): BranchenlisteBean;


implementation
  uses System.SysUtils;

function GetBranchenlisteBean(UseWSDL: Boolean; Addr: string; HTTPRIO: THTTPRIO): BranchenlisteBean;
const
  defWSDL = 'https://shkgh20.shk-connect.de/services/Branchenliste?wsdl';
  defURL  = 'https://shkgh20.shk-connect.de/services/Branchenliste';
  defSvc  = 'branchenListeService';
  defPrt  = 'branchenListeServicePort';
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
    Result := (RIO as BranchenlisteBean);
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


constructor GetBranchenListe2.Create;
begin
  inherited Create;
  FSerializationOptions := [xoLiteralParam];
end;

procedure GetBranchenListe2.SetSchnittstellenversion(Index: Integer; const Astring: string);
begin
  FSchnittstellenversion := Astring;
  FSchnittstellenversion_Specified := True;
end;

function GetBranchenListe2.Schnittstellenversion_Specified(Index: Integer): boolean;
begin
  Result := FSchnittstellenversion_Specified;
end;

procedure GetBranchenListe2.SetSoftwarename(Index: Integer; const Astring: string);
begin
  FSoftwarename := Astring;
  FSoftwarename_Specified := True;
end;

function GetBranchenListe2.Softwarename_Specified(Index: Integer): boolean;
begin
  Result := FSoftwarename_Specified;
end;

procedure GetBranchenListe2.SetSoftwarepasswort(Index: Integer; const Astring: string);
begin
  FSoftwarepasswort := Astring;
  FSoftwarepasswort_Specified := True;
end;

function GetBranchenListe2.Softwarepasswort_Specified(Index: Integer): boolean;
begin
  Result := FSoftwarepasswort_Specified;
end;

constructor GetBranchenListeResponse.Create;
begin
  inherited Create;
  FSerializationOptions := [xoLiteralParam];
end;

destructor GetBranchenListeResponse.Destroy;
var
  I: Integer;
begin
  for I := 0 to System.Length(FBranche)-1 do
    System.SysUtils.FreeAndNil(FBranche[I]);
  System.SetLength(FBranche, 0);
  System.SysUtils.FreeAndNil(FStatus);
  inherited Destroy;
end;

procedure GetBranchenListeResponse.SetSchnittstellenversion(Index: Integer; const Astring: string);
begin
  FSchnittstellenversion := Astring;
  FSchnittstellenversion_Specified := True;
end;

function GetBranchenListeResponse.Schnittstellenversion_Specified(Index: Integer): boolean;
begin
  Result := FSchnittstellenversion_Specified;
end;

procedure GetBranchenListeResponse.SetServerkennung(Index: Integer; const Astring: string);
begin
  FServerkennung := Astring;
  FServerkennung_Specified := True;
end;

function GetBranchenListeResponse.Serverkennung_Specified(Index: Integer): boolean;
begin
  Result := FServerkennung_Specified;
end;

procedure GetBranchenListeResponse.SetStatus(Index: Integer; const AStatus: Status);
begin
  FStatus := AStatus;
  FStatus_Specified := True;
end;

function GetBranchenListeResponse.Status_Specified(Index: Integer): boolean;
begin
  Result := FStatus_Specified;
end;

procedure GetBranchenListeResponse.SetBranche(Index: Integer; const AArray_Of_Branche: Array_Of_Branche);
begin
  FBranche := AArray_Of_Branche;
  FBranche_Specified := True;
end;

function GetBranchenListeResponse.Branche_Specified(Index: Integer): boolean;
begin
  Result := FBranche_Specified;
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
  { BranchenlisteBean }
  InvRegistry.RegisterInterface(TypeInfo(BranchenlisteBean), 'http://service.shk-connect.de', 'UTF-8');
  InvRegistry.RegisterDefaultSOAPAction(TypeInfo(BranchenlisteBean), '');
  InvRegistry.RegisterInvokeOptions(TypeInfo(BranchenlisteBean), ioDocument);
  InvRegistry.RegisterInvokeOptions(TypeInfo(BranchenlisteBean), ioLiteral);
  RemClassRegistry.RegisterXSInfo(TypeInfo(Array_Of_Branche), 'http://service.shk-connect.de', 'Array_Of_Branche');
  RemClassRegistry.RegisterXSClass(GetBranchenListe2, 'http://service.shk-connect.de', 'GetBranchenListe2', 'GetBranchenListe');
  RemClassRegistry.RegisterSerializeOptions(GetBranchenListe2, [xoLiteralParam]);
  RemClassRegistry.RegisterXSClass(GetBranchenListe, 'http://service.shk-connect.de', 'GetBranchenListe');
  RemClassRegistry.RegisterXSClass(Branche, 'http://service.shk-connect.de', 'Branche');
  RemClassRegistry.RegisterExternalPropName(TypeInfo(Branche), 'Name_', '[ExtName="Name"]');
  RemClassRegistry.RegisterXSClass(GetBranchenListeResponse, 'http://service.shk-connect.de', 'GetBranchenListeResponse');
  RemClassRegistry.RegisterSerializeOptions(GetBranchenListeResponse, [xoLiteralParam]);
  RemClassRegistry.RegisterXSClass(GetBranchenListeAntwort, 'http://service.shk-connect.de', 'GetBranchenListeAntwort');
  RemClassRegistry.RegisterXSClass(Status, 'http://service.shk-connect.de', 'Status');

end.