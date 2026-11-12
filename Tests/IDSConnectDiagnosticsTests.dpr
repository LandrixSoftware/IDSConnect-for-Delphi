program IDSConnectDiagnosticsTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes, System.IOUtils, Winapi.ActiveX,
  intf.IDSConnect, intf.IDSConnectTypes;

procedure Check(Value: Boolean; const Message: String);
begin
  if not Value then
    raise Exception.Create(Message);
end;

procedure Run;
var
  Cart: TIDSConnect_Warenkorb;
  Error, Body, BaseUrl, RequestUrl, Parameters: String;
  Status, Calls: Integer;
  Bytes: TBytes;
  Versions: TStringList;
  Login: TIDSConnect_LoginInfo;
begin
  BaseUrl := ParamStr(1);
  Check(BaseUrl <> '', 'Missing local mock URL');
  Cart := TIDSConnect_Warenkorb.Create;
  try
    TIDSConnect.IDSCONNECT_ONERROR :=
      procedure(const Message: String; E: Exception)
      begin
        Writeln('Diagnostic: '+Message);
      end;
    Calls := 0;
    TIDSConnect.IDSCONNECT_ONRESPONSE :=
      procedure(const Url: String; Code: Integer; const Data: TBytes)
      begin
        Inc(Calls);
        Status := Code;
        Bytes := Copy(Data,0,Length(Data));
        Body := TEncoding.ASCII.GetString(Data);
      end;

    Check(TIDSConnect.TryFetchResult(BaseUrl+'/valid',Cart,Error),'Valid cart rejected: '+Error);
    Check((Status = 200) and (Calls = 1),'Missing response callback');
    Check(Pos('A&amp;B',Body) > 0,'Raw XML was changed');
    Check(Cart.Order.OrderItems.Count = 1,'Missing position');
    Check(Cart.Order.OrderItems[0].ArtNo = 'A&B','Decoded article differs');
    Check(Abs(Cart.Order.OrderItems[0].Qty-2.5) < 0.0001,'Quantity differs');

    Check(not TIDSConnect.TryFetchResult(BaseUrl+'/invalid',Cart,Error),'Invalid XML accepted');
    Check((Error <> '') and (Body = '<Warenkorb>'),'Invalid payload not retained');
    Check(not TIDSConnect.TryFetchResult(BaseUrl+'/html',Cart,Error),'HTML accepted as cart');
    Check((Error <> '') and (Pos('<html>',Body) = 1),'HTML response missing');
    Check(not TIDSConnect.TryFetchResult(BaseUrl+'/error',Cart,Error),'HTTP 500 accepted');
    Check((Status = 500) and (Pos('500',Error) > 0) and (Body = 'mock error'),
      'HTTP error diagnostics missing');
    Check(not TIDSConnect.TryFetchResult(BaseUrl+'/pending',Cart,Error),'HTTP 404 accepted');
    Check((Status = 404) and (Error = ''),'Pending response treated as error');
    Check(not TIDSConnect.TryFetchResult(BaseUrl+'/empty',Cart,Error),'Empty body accepted');
    Check((Status = 200) and (Length(Bytes) = 0),'Empty response not reported');
    Check(TIDSConnect.TryFetchResult(BaseUrl+'/latin1',Cart,Error),'Latin-1 cart rejected');
    Check(Pos('encoding="ISO-8859-1"',Body) > 0,'Encoding declaration changed');
    Check(Bytes[Length(Bytes)-4] = 233,'Raw Latin-1 byte changed');

    TIDSConnect.IDSCONNECT_ONRESPONSE := nil;
    Check(TIDSConnect.TryFetchResult(BaseUrl+'/valid',Cart,Error),'Fetch without callback failed');
    TIDSConnect.IDSCONNECT_HOOKURL := BaseUrl+'/callback';
    TIDSConnect.IDSCONNECT_ONREQUEST :=
      procedure(const Url, Fields: String)
      begin
        RequestUrl := Url;
        Parameters := Fields;
      end;
    //An existing directory cannot be written as a form file. This exercises
    //request preparation without opening a browser or contacting any shop.
    Check(not TIDSConnect.IDSConnectWKE('https://shop.invalid/ids','customer',
      'tester','secret-pw',TPath.GetTempPath,Cart),'Directory accepted as HTML file');
    Check(RequestUrl = 'https://shop.invalid/ids','Wrong request URL');
    Check(Pos('action=WKE',Parameters) > 0,'Missing WKE action');
    Check(Pos('hookurl='+BaseUrl+'/callback?sid=',Parameters) > 0,'Missing callback session');
    Check(Pos('secret-pw',Parameters) = 0,'Password leaked in diagnostics');
    Check(Pos('pw_kunde=(maskiert)',Parameters) > 0,'Password mask missing');
    Check(Pos('version=2.5.1'+sLineBreak,Parameters) > 0,'Default WKE version changed');
    TIDSConnect.IDSConnectWKE('https://shop.invalid/ids','customer',
      'tester','secret-pw',TPath.GetTempPath,Cart,idsConnectVersion_2_5);
    Check(Pos('version=2.5'+sLineBreak,Parameters) > 0,'WKE ignores selected version');
    TIDSConnect.IDSConnectWKE('https://shop.invalid/ids','customer',
      'tester','secret-pw',TPath.GetTempPath,Cart);
    Check(Pos('version=2.5.1'+sLineBreak,Parameters) > 0,'Version leaked between calls');
    Versions := TStringList.Create;
    try
      Check(TIDSConnect.IDSConnectSV(BaseUrl+'/post25',Versions,idsConnectVersion_2_5),
        'SV ignores selected version');
      Check(Versions.IndexOf('2.5') >= 0,'SV response missing');
      Check(TIDSConnect.IDSConnectLI(BaseUrl+'/post25',Login,idsConnectVersion_2_5),
        'LI ignores selected version');
      Check(TIDSConnect.IDSConnectSV(BaseUrl+'/post251',Versions),'Default SV version changed');
    finally
      Versions.Free;
    end;
    Writeln('PASS: response diagnostics, masked WKE request, selected and default versions for WKE/SV/LI');
  finally
    TIDSConnect.IDSCONNECT_ONREQUEST := nil;
    TIDSConnect.IDSCONNECT_ONERROR := nil;
    TIDSConnect.IDSCONNECT_ONRESPONSE := nil;
    Cart.Free;
  end;
end;

begin
  CoInitialize(nil);
  try
    try
      Run;
    except
      on E: Exception do
      begin
        Writeln('FAIL: '+E.Message);
        ExitCode := 1;
      end;
    end;
  finally
    CoUninitialize;
  end;
end.
