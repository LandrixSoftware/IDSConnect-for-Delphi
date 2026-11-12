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
  State: TIDSConnect.TCollectState;
  Merged: TIDSConnect_Warenkorb;
  LastError: String;
begin
  BaseUrl := ParamStr(1);
  Check(BaseUrl <> '', 'Missing local mock URL');
  Cart := TIDSConnect_Warenkorb.Create;
  try
    TIDSConnect.IDSCONNECT_ONERROR :=
      procedure(const Message: String; E: Exception)
      begin
        Writeln('Diagnostic: '+Message);
        LastError := Message;
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
    Check(Cart.Order.OrderItems[0].ArtNo = 'Caf'#$E9,'Latin-1 text decoded wrong: '+
          Cart.Order.OrderItems[0].ArtNo);

    Check(TIDSConnect.TryFetchResult(BaseUrl+'/utf8-1252',Cart,Error),'UTF-8 with 1252 rejected: '+Error);
    Check(Cart.Order.OrderItems[0].ArtNo = 'B-1252 M'#$FC'ller','UTF-8 decoded as ANSI: '+
          Cart.Order.OrderItems[0].ArtNo);
    Check(TIDSConnect.TryFetchResult(BaseUrl+'/latin1-decl-utf8',Cart,Error),
          'UTF-8 with Latin-1 declaration rejected: '+Error);
    Check(Cart.Order.OrderItems[0].ArtNo = 'Gr'#$FC'n','UTF-8 bytes with Latin-1 declaration: '+
          Cart.Order.OrderItems[0].ArtNo);
    Check(TIDSConnect.TryFetchResult(BaseUrl+'/decl-tab',Cart,Error),'Tab in declaration rejected: '+Error);
    Check(Cart.Order.OrderItems[0].ArtNo = #$0141,'Tab in declaration ignored: '+
          Cart.Order.OrderItems[0].ArtNo);
    Check(TIDSConnect.TryFetchResult(BaseUrl+'/cp1252-nodecl',Cart,Error),'CP1252 without declaration rejected: '+Error);
    Check(Cart.Order.OrderItems[0].ArtNo = 'Ma'#$DF'band '#$20AC,'CP1252 without declaration: '+
          Cart.Order.OrderItems[0].ArtNo);
    Check(TIDSConnect.TryFetchResult(BaseUrl+'/ns',Cart,Error),'Namespace prefix rejected: '+Error);
    Check((Cart.Order.OrderItems.Count = 1) and (Cart.Order.OrderItems[0].ArtNo = 'NS1') and
          (Cart.Order.OrderInfo.Cur = 'CHF'),'Namespace prefix content lost');
    Check(TIDSConnect.TryFetchResult(BaseUrl+'/mixed-text',Cart,Error),'Mixed content rejected: '+Error);
    Check(Cart.Order.OrderItems[0].ArtNo = 'abc&de','Mixed content text: '+Cart.Order.OrderItems[0].ArtNo);

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
    //Multiple returns: queue is drained, header comes from the first return
    Merged := TIDSConnect_Warenkorb.Create;
    try
      State := Default(TIDSConnect.TCollectState);
      Check(TIDSConnect.CollectResults(BaseUrl+'/queue',Merged,State),'Queue not collected');
      Check(State.Received = 2,'Queued returns missing: '+IntToStr(State.Received));
      Check(Merged.Order.OrderItems.Count = 2,'Merged positions missing');
      Check((Merged.Order.OrderItems[0].ArtNo = 'Q1') and
            (Merged.Order.OrderItems[1].ArtNo = 'Q2'),'Merged order differs');
      Check(Merged.Order.OrderInfo.Cur = 'CHF','Currency of first return lost');
      Check(Merged.Order.OrderInfo.Kommission = 'K-1','Kommission of first return lost');
      Check(Merged.Order.SupplierInfo.Address.Name1 = 'Lieferant','Supplier of first return lost');
      Check(not TIDSConnect.CollectResults(BaseUrl+'/queue',Merged,State),'Empty queue reported data');
      Check(Merged.Order.OrderItems.Count = 2,'Empty queue changed cart');

      //A hook server that does not consume returns must not loop or duplicate
      State := Default(TIDSConnect.TCollectState);
      LastError := '';
      Check(TIDSConnect.CollectResults(BaseUrl+'/sticky',Merged,State),'Sticky return rejected');
      Check(State.Received = 1,'Sticky return duplicated: '+IntToStr(State.Received));
      Check(Merged.Order.OrderItems.Count = 1,'Sticky positions duplicated');
      Check(State.DuplicateReported and (LastError <> ''),'Duplicate not reported');
      Check(not TIDSConnect.CollectResults(BaseUrl+'/sticky',Merged,State),'Sticky return collected again');
      Check(Merged.Order.OrderItems.Count = 1,'Sticky positions duplicated on next poll');

      //With transfer ids: identical content in separate transfers is kept
      State := Default(TIDSConnect.TCollectState);
      Check(TIDSConnect.CollectResults(BaseUrl+'/id-queue',Merged,State),'Id queue not collected');
      Check(State.Received = 3,'Identical separate transfers dropped: '+IntToStr(State.Received));
      Check((Merged.Order.OrderItems[0].ArtNo = 'S') and (Merged.Order.OrderItems[1].ArtNo = 'S') and
            (Merged.Order.OrderItems[2].ArtNo = 'T'),'Id queue order differs');
      Check(not State.DuplicateReported,'Separate transfers reported as duplicate');

      //Same id again: repeated delivery of one transfer
      State := Default(TIDSConnect.TCollectState);
      Check(TIDSConnect.CollectResults(BaseUrl+'/sticky-id',Merged,State),'Sticky id rejected');
      Check((State.Received = 1) and State.DuplicateReported,'Repeated id not detected');

      //Cyclic delivery A, B, A: the repeated A is detected
      State := Default(TIDSConnect.TCollectState);
      Check(TIDSConnect.CollectResults(BaseUrl+'/cycle',Merged,State),'Cycle not collected');
      Check((State.Received = 2) and State.DuplicateReported,
            'Cyclic repeat not detected: '+IntToStr(State.Received));

      //Mixed: A with id, then B twice without id - the repeated B is detected
      State := Default(TIDSConnect.TCollectState);
      Check(TIDSConnect.CollectResults(BaseUrl+'/mixed',Merged,State),'Mixed not collected');
      Check((State.Received = 2) and State.DuplicateReported,
            'Repeat without id after id not detected: '+IntToStr(State.Received));

      //Limit per call is not a silent overall limit
      State := Default(TIDSConnect.TCollectState);
      Check(TIDSConnect.CollectResults(BaseUrl+'/many',Merged,State),'Many not collected');
      Check((State.Received = TIDSConnect.IDSCONNECT_MAX_COLLECT) and State.LimitReached,
            'Limit not signalled');
      while State.LimitReached do
        TIDSConnect.CollectResults(BaseUrl+'/many',Merged,State);
      Check(State.Received = 120,'Transfers lost after limit: '+IntToStr(State.Received));
      Check(Merged.Order.OrderItems[119].ArtNo = 'M119','Last transfer missing');

      //Self assignment must not wipe lists
      Merged.Order.OrderInfo.Referenzen.AddItem.ReferenzNumber := 'R1';
      Merged.Assign(Merged);
      Check(Merged.Order.OrderItems.Count = 120,'Self assign lost positions');
      Check(Merged.Order.OrderInfo.Referenzen.Count = 1,'Self assign lost references');
      Merged.Order.Assign(Merged.Order);
      Check(Merged.Order.OrderItems.Count = 120,'Order self assign lost positions');
      Merged.Order.OrderInfo.Assign(Merged.Order.OrderInfo);
      Check(Merged.Order.OrderInfo.Referenzen.Count = 1,'OrderInfo self assign lost references');
      Merged.Order.OrderItems[0].Referenzen.AddItem.ReferenzNumber := 'P1';
      Merged.Order.OrderItems[0].Assign(Merged.Order.OrderItems[0]);
      Check(Merged.Order.OrderItems[0].Referenzen.Count = 1,'OrderItem self assign lost references');
    finally
      Merged.Free;
    end;

    Writeln('PASS: response diagnostics, masked WKE request, selected and default versions for WKE/SV/LI, multiple-return queue/header/duplicates');
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
