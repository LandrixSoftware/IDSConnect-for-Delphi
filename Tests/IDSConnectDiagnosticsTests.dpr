program IDSConnectDiagnosticsTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes, System.IOUtils, Winapi.ActiveX,
  intf.IDSConnect, intf.IDSConnectTypes, intf.IDSConnectDlgWebBrowser,
  LandrixXmlDom, LandrixXmlXsdSchema, LandrixXmlXsdSchemaLoader, LandrixXmlXsdValidator;

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

//Fills every field the given version knows, with values at their limits
procedure FillFullCart(Cart: TIDSConnect_Warenkorb; Version: TIDSConnect_Version);
var
  Addr: TIDSConnect_Address;
  Item: TIDSConnect_OrderItem;
begin
  Cart.Clear;
  Cart.WarenkorbInfo.Version := Version;
  Cart.WarenkorbInfo.Date := EncodeDate(2026,11,16);
  Cart.WarenkorbInfo.Time := EncodeTime(12,34,56,0);
  with Cart.Order.OrderInfo do
  begin
    if Version = idsConnectVersion_2_5 then
    begin
      InquiryNo := 'ANF-1';
      OfferNo := 'ANG-1';
      PartNo := 'BEST-1';
      OrderConfNo := 'AB-1';
    end else
      with Referenzen.AddItem do
      begin
        ReferenzNumber := 'BEST-1';
        ReferenzDate := EncodeDate(2026,11,1);
        ReferenzType := idsConnectRefType_220;
      end;
    DeliveryDate := EncodeDate(2026,12,1);
    ModeOfShipment := idsConnectMos_Lieferung;
    ZusatzText := 'Bitte klingeln & warten <hinten>';
    Kommission := 'Bad Müller';
    Cur := 'EUR';
  end;
  Addr := Cart.Order.CustomerInfo.Address;
  Cart.Order.CustomerInfo.IDNo := 'K-4711';
  Addr.Name1 := 'Muster GmbH';
  Addr.Name2 := 'Sanitär & Heizung';
  Addr.Name3 := 'z. Hd. Einkauf';
  if Version = idsConnectVersion_2_5 then
  begin
    Addr.Name4 := 'Abteilung';
    Addr.Street := 'Weg 1';
  end else
  begin
    Addr.Street1 := 'Weg 1';
    Addr.Street2 := 'Hinterhaus';
    Addr.Street3 := '3. OG';
  end;
  Addr.PCode := '12345';
  Addr.City := 'Musterstadt';
  Addr.Country := 'DE';
  Addr.ILN := '4012345000009';
  Addr.Contact := 'Max Muster';
  Addr.Phone := '+49 30 123';
  Addr.Fax := '+49 30 124';
  Addr.Email := 'einkauf@example.com';
  Cart.Order.SupplierInfo.IDNo := 'L-1';
  Cart.Order.SupplierInfo.Address.Assign(Addr);
  Cart.Order.DeliveryPlaceInfo.IDNo := 'LO-1';
  Cart.Order.DeliveryPlaceInfo.Address.Assign(Addr);
  if Version = idsConnectVersion_2_5_1 then
  begin
    Cart.Order.DeliveryPlaceInfo.HasGeoLocation := true;
    Cart.Order.DeliveryPlaceInfo.GeoLat := 52.5;
    Cart.Order.DeliveryPlaceInfo.GeoLang := -13.25;
  end;

  Item := Cart.Order.OrderItems.AddItem;
  Item.ItemChara := idsConnectIc_normal;
  Item.RefItems_Customer := '1';
  Item.RefItems_CustomerSubNo := '1.1';
  Item.RefItems_Supplier := '10';
  Item.RefItems_SupplierSubNo := '10.1';
  Item.EAN := '4012345678901';
  Item.ManufacturerID := 'GLN-1';
  Item.ManufacturerIDType := 'GLN';
  Item.ArtNo := 'ART-1';
  Item.Qty := 12.5;
  Item.QU := idsConnectQu_MTR;
  Item.Kurztext := 'Kupferrohr 15 mm';
  Item.Langtext := 'Langtext mit Umlauten äöü ß'+sLineBreak+'zweite Zeile';
  Item.OfferPrice := 123.4567;
  Item.NetPrice := 99.99;
  Item.PriceBasis := 100;
  Item.VAT := 19;
  Item.TechnClarification := idsConnectTc_No;
  Item.Hinweis := 'Hinweis';
  Item.Zuschlag := 1.5;
  Item.Divers := true;
  with Item.Rohstoffanteile.AddItem do
  begin
    Rohstoff := idsConnectR_CU;
    Gewichtsanteilswert := 0.35;
    Gewichtsanteilseinheit := idsConnectQu_KGM;
    Basiswert := 1;
    Basiseinheit := idsConnectQu_MTR;
    Basisnotierung := 150;
    NotierungAktuell := 812.34;
  end;
  if Version = idsConnectVersion_2_5_1 then
  begin
    Item.SumMaterialSurcharges := 4.56;
    Item.DiscountableAmount := 95.43;
    with Item.Referenzen.AddItem do
    begin
      ReferenzNumber := 'AB-1';
      ReferenzDate := EncodeDate(2026,11,2);
      ReferenzType := idsConnectRefType_231;
      ReferenzLine := '10';
    end;
  end;

  //Second item with only the mandatory fields
  Item := Cart.Order.OrderItems.AddItem;
  Item.ArtNo := 'ART-2';
  Item.Qty := 1;
  Item.QU := idsConnectQu_PCE;
  Item.Kurztext := 'Nur Pflichtfelder';
end;

//Validates own carts against the itek schemas. The XSDs are not part of the
//repository (licence); the check runs only where Documentation\ exists.
procedure CheckXsd(const DocRoot: String);
const
  Versions: array[0..1] of TIDSConnect_Version = (idsConnectVersion_2_5, idsConnectVersion_2_5_1);
  Folders: array[0..1] of String = ('IDSConnect 2.5', 'IDSConnect 2.5.1');
  Files: array[0..1] of String = ('warenkorb_senden_2_5.xsd', 'warenkorb_senden_2_5_1.xsd');
var
  i, k, Variant: Integer;
  XsdFile, Errors: String;
  Schema: TLandrixXmlXsdSchemaSet;
  Validator: TLandrixXmlXsdValidator;
  Doc: TLandrixXmlDocument;
  Cart: TIDSConnect_Warenkorb;
  Checked: Integer;
begin
  Checked := 0;
  for i := 0 to High(Versions) do
  begin
    XsdFile := TPath.Combine(TPath.Combine(DocRoot,Folders[i]),Files[i]);
    if (DocRoot = '') or not FileExists(XsdFile) then
    begin
      Writeln('SKIP: XSD validation '+Folders[i]+' (schema not present locally)');
      continue;
    end;
    Schema := LandrixXmlXsdLoadSchema(XsdFile);
    Validator := nil;
    Doc := nil;
    Cart := nil;
    try
      Doc := TLandrixXmlDocument.Create;
      Cart := TIDSConnect_Warenkorb.Create;
      Validator := TLandrixXmlXsdValidator.Create(Schema);
      //Variant 0: every field filled; variant 1: an almost empty cart;
      //variant 2: the alternatives - delivery week/year instead of a date,
      //error code and text, the raw materials MS/MK (2.5.1 only)
      for Variant := 0 to 2 do
      begin
        if Variant = 0 then
          FillFullCart(Cart,Versions[i])
        else if Variant = 2 then
        begin
          FillFullCart(Cart,Versions[i]);
          Cart.Order.OrderInfo.DeliveryDate := 0;
          Cart.Order.OrderInfo.DeliveryWeek := 48;
          Cart.Order.OrderInfo.DeliveryYear := 2026;
          Cart.Order.OrderInfo.ModeOfShipment := idsConnectMos_Abholung;
          Cart.Order.OrderItems[0].Fehlercode := idsConnectFc_1;
          Cart.Order.OrderItems[0].Fehlertext := 'Artikel nicht lieferbar';
          Cart.Order.OrderItems[0].ItemChara := idsConnectIc_alternate;
          Cart.Order.OrderItems[0].TechnClarification := idsConnectTc_Yes;
          with Cart.Order.OrderItems[0].Rohstoffanteile.AddItem do
          begin
            Rohstoff := idsConnectR_MS;
            Gewichtsanteilswert := 0.1;
            Gewichtsanteilseinheit := idsConnectQu_KGM;
          end;
          with Cart.Order.OrderItems[0].Rohstoffanteile.AddItem do
          begin
            Rohstoff := idsConnectR_MK;
            Gewichtsanteilswert := 0.2;
            Gewichtsanteilseinheit := idsConnectQu_KGM;
          end;
        end else
        begin
          Cart.Clear;
          Cart.WarenkorbInfo.Version := Versions[i];
          with Cart.Order.OrderItems.AddItem do
          begin
            ArtNo := 'X';
            Qty := 1;
            Kurztext := 'Minimal';
          end;
        end;
        Doc.LoadFromString(SaveCart(Cart));
        if not Validator.ValidateDocument(Doc) then
        begin
          Errors := '';
          for k := 0 to Validator.ErrorCount-1 do
            Errors := Errors+sLineBreak+'  '+IntToStr(Validator.Errors[k].Line)+': '+
                      Validator.Errors[k].Code+' '+Validator.Errors[k].Message;
          raise Exception.Create(Format('%s cart (variant %d) violates %s:%s',
                                        [Folders[i],Variant,Files[i],Errors]));
        end;
        Inc(Checked);
      end;
      //Counter-check: the validator must reject a wrong element name, or the
      //check above proves nothing
      Doc.LoadFromString(StringReplace(StringReplace(SaveCart(Cart),'<Kurztext>','<Kurztxt>',[]),
                         '</Kurztext>','</Kurztxt>',[]));
      Check(not Validator.ValidateDocument(Doc),Folders[i]+': validator accepted a wrong element');
    finally
      Cart.Free;
      Doc.Free;
      Validator.Free;
      Schema.Free;
    end;
  end;
  if Checked > 0 then
    Writeln(Format('PASS: %d own carts valid against the local itek XSDs',[Checked]));
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
  AllErrors, TmpA, TmpB, OldDir, QuXml: String;
  QuStream: TStringStream;
  Waited: Integer;
  Lock: TFileStream;
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
    CheckXsd(ParamStr(2));
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

    //Form file with credentials: deleted at once or after the delay
    TmpA := TPath.Combine(TPath.GetTempPath,'idsconnect-test-'+TGUID.NewGuid.ToString+'.html');
    TFile.WriteAllText(TmpA,'x');
    TIDSConnect.DeleteTmpFileLater(TmpA,0);
    Check(not TFile.Exists(TmpA),'tmp file not deleted immediately');
    TFile.WriteAllText(TmpA,'x');
    TIDSConnect.DeleteTmpFileLater(TmpA,1);
    Check(TFile.Exists(TmpA),'tmp file deleted before the delay');
    Waited := 0;
    while TFile.Exists(TmpA) and (Waited < 50) do
    begin
      Sleep(100);
      Inc(Waited);
    end;
    Check(not TFile.Exists(TmpA),'tmp file not deleted after the delay');
    //Same name scheduled twice: only the later deadline deletes it
    TFile.WriteAllText(TmpA,'x');
    TIDSConnect.DeleteTmpFileLater(TmpA,1);
    TIDSConnect.DeleteTmpFileLater(TmpA,3);
    Sleep(2000);
    Check(TFile.Exists(TmpA),'reused tmp file deleted by the earlier deadline');
    //Locked file: deletion is retried after the lock is released
    TmpB := TPath.Combine(TPath.GetTempPath,'idsconnect-test-'+TGUID.NewGuid.ToString+'.html');
    TFile.WriteAllText(TmpB,'x');
    Lock := TFileStream.Create(TmpB,fmOpenRead or fmShareDenyNone);
    try
      TIDSConnect.DeleteTmpFileLater(TmpB,1);
      Sleep(1800);
      Check(TFile.Exists(TmpB),'locked tmp file vanished - lock not effective, test meaningless');
    finally
      Lock.Free;
    end;
    //Windows: DeleteFile on a file opened with FILE_SHARE_DELETE missing fails
    Waited := 0;
    while TFile.Exists(TmpB) and (Waited < 100) do
    begin
      Sleep(100);
      Inc(Waited);
    end;
    Check(not TFile.Exists(TmpB),'locked tmp file not deleted after the lock was released');
    //Relative name: resolved when scheduled, not when deleted
    TmpB := 'idsconnect-test-'+TGUID.NewGuid.ToString+'.html';
    OldDir := GetCurrentDir;
    SetCurrentDir(TPath.GetTempPath);
    try
      TFile.WriteAllText(TmpB,'x');
      TIDSConnect.DeleteTmpFileLater(TmpB,1);
    finally
      SetCurrentDir(OldDir);
    end;
    Waited := 0;
    while TFile.Exists(TPath.Combine(TPath.GetTempPath,TmpB)) and (Waited < 50) do
    begin
      Sleep(100);
      Inc(Waited);
    end;
    Check(not TFile.Exists(TPath.Combine(TPath.GetTempPath,TmpB)),'relative tmp file not deleted');
    //Pending at program end: deleted in finalization (not checked here)
    Check(TIDSConnect.IDSCONNECT_TMPFILE_DELETE_DELAY = 60,'default delete delay');

    //WebView2 profile per Windows user, not next to the EXE
    Check(SameText(TIDSConnectDlgWebBrowser.DefaultCachePath,
            TPath.Combine(TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'),'IDSConnectDiagnosticsTests'),
                          'IDSConnect.WebView2')),
          'unexpected default WebView2 folder: '+TIDSConnectDlgWebBrowser.DefaultCachePath);
    Check(TIDSConnect.IDSCONNECT_WEBVIEW_USERDATAFOLDER = '','default user data folder not empty');

    Writeln('PASS: tmp form file deleted, WebView2 profile per user');
    //Units from real returns: common spellings are mapped silently, the
    //original stays in QUOriginal, unknown ones give one message per cart;
    //a delivery date in another format is reported instead of dropped silently
    AllErrors := '';
    QuXml := '<?xml version="1.0" encoding="UTF-8"?>'+
      '<Warenkorb xmlns="http://www.itek.de/Shop-Anbindung/Warenkorb/">'+
      '<WarenkorbInfo><Date>2026-11-16</Date><Time>12:00:00</Time>'+
      '<RueckgabeKZ>Warenkorbr'+#$00FC+'ckgabe</RueckgabeKZ><Version>2.5</Version></WarenkorbInfo>'+
      '<Order><OrderInfo><DeliveryDate>03/31/2026</DeliveryDate><ModeOfShipment>Lieferung</ModeOfShipment><Cur>EUR</Cur></OrderInfo>'+
      '<OrderItem><ArtNo>1</ArtNo><Qty>2</Qty><QU>STK</QU><Kurztext>a</Kurztext></OrderItem>'+
      '<OrderItem><ArtNo>2</ArtNo><Qty>2</Qty><QU>Stk.</QU><Kurztext>b</Kurztext></OrderItem>'+
      '<OrderItem><ArtNo>3</ArtNo><Qty>12</Qty><QU>qm</QU><Kurztext>c</Kurztext></OrderItem>'+
      '<OrderItem><ArtNo>4</ArtNo><Qty>1</Qty><QU>PK</QU><Kurztext>d</Kurztext></OrderItem>'+
      '<OrderItem><ArtNo>5</ArtNo><Qty>1</Qty><QU>PK</QU><Kurztext>e</Kurztext></OrderItem>'+
      '<OrderItem><ArtNo>6</ArtNo><Qty>1</Qty><QU></QU><Kurztext>f</Kurztext></OrderItem>'+
      '<OrderItem><ArtNo>7</ArtNo><Qty>1</Qty><QU>MTR</QU><Kurztext>g</Kurztext></OrderItem>'+
      '<OrderItem><ArtNo>8</ArtNo><Qty>1</Qty><QU>St'+#$00FC+'ck</QU><Kurztext>h</Kurztext>'+
      '<Rohstoffanteil><Rohstoff>CU</Rohstoff><Gewichtsanteilswert>1</Gewichtsanteilswert>'+
      '<Gewichtsanteilseinheit>Pfund</Gewichtsanteilseinheit></Rohstoffanteil></OrderItem>'+
      '</Order></Warenkorb>';
    QuStream := TStringStream.Create(QuXml,TEncoding.UTF8);
    try
      Check(Cart.LoadFromStream(QuStream),'cart with odd units not read');
    finally
      QuStream.Free;
    end;
    Check(Cart.Order.OrderItems[0].QU = idsConnectQu_PCE,'STK not PCE');
    Check(Cart.Order.OrderItems[1].QU = idsConnectQu_PCE,'Stk. not PCE');
    Check(Cart.Order.OrderItems[2].QU = idsConnectQu_MTK,'qm not MTK');
    Check(Cart.Order.OrderItems[3].QU = idsConnectQu_PCE,'PK not PCE');
    Check(Cart.Order.OrderItems[3].QUOriginal = 'PK','QUOriginal lost');
    Check(Cart.Order.OrderItems[1].QUOriginal = 'Stk.','QUOriginal of alias lost');
    Check(Cart.Order.OrderItems[6].QUOriginal = 'MTR','QUOriginal of standard code lost');
    Check(Pos('STK',AllErrors) + Pos('Stk.',AllErrors) + Pos('qm',AllErrors) = 0,
          'Alias reported as unknown: '+AllErrors);
    Check(Pos('"PK" (2'+#$00D7+')',AllErrors) > 0,'unknown unit not aggregated: '+AllErrors);
    Check(Pos('(leer) (1'+#$00D7+')',AllErrors) > 0,'empty unit not reported: '+AllErrors);
    Check(Length(AllErrors)-Length(StringReplace(AllErrors,'Mengeneinheit','',[rfReplaceAll])) =
          Length('Mengeneinheit'),'more than one unit message per cart: '+AllErrors);
    Check(Cart.Order.OrderItems[7].QU = idsConnectQu_PCE,'Stueck not PCE');
    Check(Pos('"St'+#$00FC+'ck"',AllErrors) = 0,'Stueck reported as unknown: '+AllErrors);
    Check(Pos('"Pfund" in Rohstoffanteilen (1'+#$00D7+')',AllErrors) > 0,
          'raw material unit not marked: '+AllErrors);
    Check(Cart.Order.OrderInfo.DeliveryDate = 0,'US date guessed');
    Check(Pos('03/31/2026',AllErrors) > 0,'odd delivery date not reported: '+AllErrors);
    //Strict date check: slashes and trailing garbage are reported, a time
    //zone or time part is fine, 1899-12-30 is a valid date
    for QuXml in TArray<String>.Create('2026/11/16','2026-11-16xyz','2026-02-30',
      '2026-11-16-garbage','2026-11-16+','2026-11-16Tinvalid','2026-11-16T10:00:00.','2026-11-16+99:99','2026-11-16T99:99:99','2026-11-16T24:00:01','2026-11-16T24:00:00.1') do
    begin
      AllErrors := '';
      QuStream := TStringStream.Create('<Warenkorb xmlns="http://www.itek.de/Shop-Anbindung/Warenkorb/">'+
        '<WarenkorbInfo><Date>'+QuXml+'</Date><Version>2.5</Version></WarenkorbInfo><Order/></Warenkorb>',TEncoding.UTF8);
      try
        Check(Cart.LoadFromStream(QuStream),'date cart not read');
      finally
        QuStream.Free;
      end;
      Check(Pos(QuXml,AllErrors) > 0,'bad date not reported: '+QuXml);
    end;
    for QuXml in TArray<String>.Create('2026-11-16','2026-11-16Z','2026-11-16+01:00','2026-11-16-05:00',
      '2026-11-16T10:00:00','2026-11-16T10:00:00.123Z','2026-11-16T10:00:00+01:00','2026-11-16T24:00:00','2026-11-16T24:00:00.000','2026-11-16+14:00','1899-12-30') do
    begin
      AllErrors := '';
      QuStream := TStringStream.Create('<Warenkorb xmlns="http://www.itek.de/Shop-Anbindung/Warenkorb/">'+
        '<WarenkorbInfo><Date>'+QuXml+'</Date><Version>2.5</Version></WarenkorbInfo><Order/></Warenkorb>',TEncoding.UTF8);
      try
        Check(Cart.LoadFromStream(QuStream),'date cart not read');
      finally
        QuStream.Free;
      end;
      Check(Pos('JJJJ',AllErrors) = 0,'good date reported: '+QuXml+' '+AllErrors);
      Check(FormatDateTime('yyyy-mm-dd',Cart.WarenkorbInfo.Date) = Copy(QuXml,1,10),'date wrong: '+QuXml);
    end;

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
