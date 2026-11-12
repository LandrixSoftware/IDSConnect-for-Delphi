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

function SaveCart(Cart: TIDSConnect_Warenkorb): String;
var
  sb: TStringBuilder;
begin
  sb := TStringBuilder.Create;
  try
    Check(Cart.SaveToString(sb),'SaveToString failed');
    Result := sb.ToString;
  finally
    sb.Free;
  end;
end;

procedure CheckSerializer(var LastError: String);
var
  Cart, Back: TIDSConnect_Warenkorb;
  Xml: String;
  Stream: TStringStream;
  List: TStringList;
begin
  Check(TIDSConnectHelper.VersionFromStr(' 2.5 ') = idsConnectVersion_2_5,'Version not trimmed');
  List := TStringList.Create;
  try
    List.CommaText := '1.3,2.0,2.3';
    Check(TIDSConnect.BestSupportedVersion(List) = idsConnectVersion_Unkown,'Version < 2.5 offered as best');
    List.CommaText := '2.3,2.5';
    Check(TIDSConnect.BestSupportedVersion(List) = idsConnectVersion_2_5,'Best version 2.5 missed');
    List.CommaText := '2.5.1,2.5';
    Check(TIDSConnect.BestSupportedVersion(List) = idsConnectVersion_2_5_1,'Best version 2.5.1 missed');
  finally
    List.Free;
  end;
  Check(TIDSConnectHelper.StrMaxLength('ab'+#$D83D#$DE00,3) = 'ab','Surrogate pair split');
  Check(TIDSConnectHelper.StrMaxLength('ab'+#$D83D#$DE00,4) = 'ab'+#$D83D#$DE00,'Complete pair cut');

  Cart := TIDSConnect_Warenkorb.Create;
  Back := TIDSConnect_Warenkorb.Create;
  try
    with Cart.Order.OrderItems.AddItem do
    begin
      ArtNo := 'X1';
      Qty := 1;
      Kurztext := 'Kurz';
      //vertical tab, form feed, U+FFFE, lone surrogates; a valid pair stays
      Langtext := 'a'#11'b'#12'c'#$FFFE'd'#$D800'e'#$DC00'f'#$D83D#$DE00'g'#9'h';
    end;

    //Received from an old shop: 1.3 is sent with the 2.5 structure
    Cart.WarenkorbInfo.Version := idsConnectVersion_1_3;
    Cart.Order.CustomerInfo.Address.Street := 'Weg 1';
    LastError := '';
    Xml := SaveCart(Cart);
    Check(Pos('<Version>2.5</Version>',Xml) > 0,'1.3 not sent as 2.5');
    Check(Pos('warenkorb_senden_2_5.xsd',Xml) > 0,'1.3: wrong schema');
    Check(Pos('<Street>Weg 1</Street>',Xml) > 0,'1.3: not 2.5 structure');
    Check(Pos('1.3',LastError) > 0,'Version change not reported');

    //Unknown version is sent as 2.5.1 throughout
    Cart.WarenkorbInfo.Version := idsConnectVersion_Unkown;
    Xml := SaveCart(Cart);
    Check(Pos('<Version>2.5.1</Version>',Xml) > 0,'Unknown not sent as 2.5.1');
    Check(Pos('warenkorb_senden_2_5_1.xsd',Xml) > 0,'Unknown: wrong schema');
    Check(Pos('<Street1>Weg 1</Street1>',Xml) > 0,'Unknown: not 2.5.1 structure');

    //Fields that 2.5.1 no longer has are reported, not dropped silently
    Cart.WarenkorbInfo.Version := idsConnectVersion_2_5_1;
    Cart.Order.OrderInfo.PartNo := 'B-4711';
    LastError := '';
    Xml := SaveCart(Cart);
    Check(Pos('B-4711',Xml) = 0,'PartNo written in 2.5.1');
    Check((Pos('PartNo',LastError) > 0) and (Pos('220',LastError) > 0),'Dropped PartNo not reported');
    Cart.Order.OrderInfo.PartNo := '';
    Cart.Order.CustomerInfo.Address.Name4 := 'Abteilung';
    LastError := '';
    Xml := SaveCart(Cart);
    Check(Pos('Name4',LastError) > 0,'Dropped Name4 not reported');
    Check(Pos('Abteilung',Xml) = 0,'Name4 written in 2.5.1');

    //A reference without date is not sent with 1899-12-30
    Cart.Order.CustomerInfo.Address.Name4 := '';
    with Cart.Order.OrderInfo.Referenzen.AddItem do
    begin
      ReferenzNumber := 'R-OHNE';
      ReferenzType := idsConnectRefType_220;
    end;
    LastError := '';
    Xml := SaveCart(Cart);
    Check(Pos('R-OHNE',Xml) = 0,'Reference without date sent');
    Check(Pos('1899',Xml) = 0,'1899-12-30 sent');
    Check(Pos('R-OHNE',LastError) > 0,'Reference without date not reported');
    Cart.Order.OrderInfo.Referenzen.Clear;

    //Forbidden characters are removed and the document can be read again
    Check(Pos('<Langtext>abcdef'+#$D83D#$DE00+'g'#9'h</Langtext>',Xml) > 0,
          'Forbidden characters not removed');
    Stream := TStringStream.Create(Xml,TEncoding.UTF8);
    try
      Check(Back.LoadFromStream(Stream),'Own XML is not well-formed');
    finally
      Stream.Free;
    end;
    Check(Back.Order.OrderItems[0].Langtext = 'abcdef'+#$D83D#$DE00+'g'#9'h','Langtext round trip');
  finally
    Back.Free;
    Cart.Free;
  end;
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
  RolReports: Integer;
  OffMainThread, Done: Boolean;
  AllErrors: String;
  Worker: TThread;
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
        AllErrors := AllErrors+Message+'|';
        if TThread.CurrentThread.ThreadID <> MainThreadID then
          OffMainThread := true;
        if Pos('ROL',Message) > 0 then
          Inc(RolReports);
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
    //A failed fetch keeps the caller's cart (WKS: the cart that was sent)
    Check(Cart.Order.OrderItems.Count = 1,'Precondition: cart filled');
    Check(not TIDSConnect.TryFetchResult(BaseUrl+'/invalid',Cart,Error),'Invalid XML accepted');
    Check((Cart.Order.OrderItems.Count = 1) and (Cart.Order.OrderItems[0].ArtNo = 'A&B'),
          'Failed fetch cleared the cart');
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
    LastError := '';
    Check(TIDSConnect.TryFetchResult(BaseUrl+'/unknown-codes',Cart,Error),'Unknown codes rejected: '+Error);
    Check(Cart.Order.OrderItems[0].QU = idsConnectQu_PCE,'Unknown unit: fallback changed');
    Check(Pos('ROL',LastError) + Pos('XX',LastError) > 0,'Unknown code not reported: '+LastError);
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
      Check(TIDSConnect.IDSConnectSV(BaseUrl+'/post-utf16',Versions) and
            (Versions.IndexOf('2.5') >= 0),'SV ignores HTTP charset (UTF-16 without BOM)');
      Check(TIDSConnect.IDSConnectSV(BaseUrl+'/post-gzip',Versions) and
            (Versions.IndexOf('2.5') >= 0),'SV fails on gzip response');
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

      //A repeated return with an unknown code is reported once, not per poll
      State := Default(TIDSConnect.TCollectState);
      RolReports := 0;
      TIDSConnect.CollectResults(BaseUrl+'/sticky-unknown',Merged,State);
      TIDSConnect.CollectResults(BaseUrl+'/sticky-unknown',Merged,State);
      Check(RolReports = 1,'Unknown code reported per poll: '+IntToStr(RolReports));

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

    CheckSerializer(LastError);
    Writeln('PASS: serializer versions, dropped 2.5.1 fields, forbidden characters');
    LastError := '';
    TIDSConnect.IDSConnectADT('','c','u','p','x',TPath.GetTempPath);
    Check(Pos('ADL',LastError) > 0,'ADT without URL silent');
    LastError := '';
    Check(not TIDSConnect.IDSConnectAS('https://shop.invalid/ids','c','u','p',TPath.GetTempPath,'',Cart),
          'AS without search term accepted');
    Check(Pos('Suchbegriff',LastError) > 0,'AS without search term silent');
    LastError := '';
    Check(not TIDSConnect.IDSConnectWKS('','c','u','p',TPath.GetTempPath,Cart),'WKS without URL accepted');
    Check(Pos('WKS',LastError) > 0,'WKS without URL silent');
    //Without credentials the request is prepared; here it fails only at the
    //temp file (a directory), not at a credentials check
    LastError := '';
    TIDSConnect.IDSConnectWKE('https://shop.invalid/ids','','','',TPath.GetTempPath,Cart);
    Check(Pos('temporaere Datei',LastError) > 0,'Empty credentials still block WKE: '+LastError);

    //The wait dialog polls in a background task: callbacks must still arrive
    //on the main thread
    OffMainThread := false;
    Done := false;
    RolReports := 0;
    LastError := '';
    TIDSConnect.IDSCONNECT_ONRESPONSE :=
      procedure(const Url: String; Code: Integer; const Data: TBytes)
      begin
        if TThread.CurrentThread.ThreadID <> MainThreadID then
          OffMainThread := true;
      end;
    Worker := TThread.CreateAnonymousThread(
      procedure
      var
        WorkerState: TIDSConnect.TCollectState;
        WorkerCart: TIDSConnect_Warenkorb;
      begin
        WorkerCart := TIDSConnect_Warenkorb.Create;
        try
          WorkerState := Default(TIDSConnect.TCollectState);
          TIDSConnect.CollectResults(BaseUrl+'/sticky-unknown',WorkerCart,WorkerState);
        finally
          WorkerCart.Free;
          Done := true;
        end;
      end);
    Worker.Start;
    while not Done do
      CheckSynchronize(10);
    Check(RolReports = 1,'Background report missing: '+IntToStr(RolReports));
    Check(not OffMainThread,'Callback ran outside the main thread');
    TIDSConnect.IDSCONNECT_ONRESPONSE := nil;

    //http instead of https is reported (not for localhost), the hook can be enforced
    AllErrors := '';
    TIDSConnect.IDSConnectWKE('http://shop.example/ids','c','u','p',TPath.GetTempPath,Cart);
    Check(Pos('http statt https',AllErrors) > 0,'http shop URL not reported');
    AllErrors := '';
    TIDSConnect.IDSConnectWKE('https://shop.example/ids','c','u','p',TPath.GetTempPath,Cart);
    Check(Pos('http statt https',AllErrors) = 0,'localhost hook reported: '+AllErrors);
    TIDSConnect.IDSCONNECT_HOOKURL := 'http://hook.example/idsconnect.php';
    TIDSConnect.IDSCONNECT_REQUIRE_HTTPS_HOOK := true;
    AllErrors := '';
    Check(not TIDSConnect.IDSConnectWKE('https://shop.example/ids','c','u','p',TPath.GetTempPath,Cart),
          'http hook accepted although enforced');
    Check((Pos('REQUIRE_HTTPS_HOOK',AllErrors) > 0) and (Pos('temporaere Datei',AllErrors) = 0),
          'Enforced http hook did not abort early: '+AllErrors);
    TIDSConnect.IDSCONNECT_REQUIRE_HTTPS_HOOK := false;
    TIDSConnect.IDSCONNECT_HOOKURL := BaseUrl+'/callback';

    Writeln('PASS: kept cart on failed fetch, unknown codes, missing input reported, empty credentials allowed');
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
