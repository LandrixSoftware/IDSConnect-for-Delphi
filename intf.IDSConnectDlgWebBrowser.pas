unit intf.IDSConnectDlgWebBrowser;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.IOUtils, System.StrUtils, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Vcl.Menus,Vcl.ExtDlgs,
  Vcl.OleCtrls, Winapi.WebView2, Winapi.ActiveX,
  Vcl.Edge, Vcl.ExtCtrls;

const
  //Abholen nach einer Uebertragung, ausserhalb des WebView2-Ereignisses
  WM_IDSCONNECT_COLLECT = WM_APP + 1;

type
  TIDSConnectDlgWebBrowser = class(TForm)
    WebBrowser: TEdgeBrowser;
    procedure FormShow(Sender: TObject);
    procedure WebBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser;
      AResult: HRESULT);
    procedure WebBrowserNavigationCompleted(Sender: TCustomEdgeBrowser;
      IsSuccess: Boolean; WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
  private
    isInitialized : Boolean;
    content : String;
    //Temporaere Datei fuer Inhalte jenseits der Grenze von NavigateToString;
    //wird beim Freigeben des Dialogs geloescht
    contentFile : String;
    //Praefix der Ruecksprungadresse. Sobald der Browser dorthin navigiert,
    //gilt die Rueck-Kommunikation als abgeschlossen. Frueher war hier
    //"https://www.landrix.de" fest verdrahtet - bei jeder anderen Hook-URL
    //konnte der Dialog sich nie selbst schliessen.
    returnUrlPrefix : String;
    //Mehrfachrueckgabe (multipleResult, ab IDS 2.5.1): der Dialog schliesst
    //sich nach einer Uebertragung nicht, sondern kehrt in den Shop zurueck.
    //Frueher endete der Vorgang nach der ersten Rueckgabe, obwohl dem Shop
    //weitere zugesagt waren.
    multipleResult : Boolean;
    received : Integer;
    returning : Boolean;
    captionBase : String;
    //Holt die Rueckgaben ab und liefert deren Gesamtzahl; wird nach jeder
    //Uebertragung und regelmaessig ueber collectTimer aufgerufen
    onTransfer : TFunc<Integer>;
    collectTimer : TTimer;
    //Ein Abruf laeuft im Hintergrund
    collecting : Boolean;
    //Waehrend eines laufenden Abrufs wurde ein weiterer angefordert
    collectPending : Boolean;
    //Der Dialog wird geschlossen: keinen neuen Abruf mehr starten
    closing : Boolean;
    function LoadContent : Boolean;
    procedure ReturnToShop;
    procedure Collect;
    procedure CollectDone(_Count : Integer);
    procedure UpdateCaption;
    procedure DoCollectTimer(Sender : TObject);
    procedure WMIDSConnectCollect(var Msg : TMessage); message WM_IDSCONNECT_COLLECT;
  public
    //Voreinstellung fuer Profil, Cookies und Cache:
    //%LOCALAPPDATA%\<EXE-Name>\IDSConnect.WebView2. Frueher lag das Profil
    //neben der EXE - unter Program Files nicht beschreibbar, und auf einem
    //Terminalserver teilten sich alle Benutzer dieselbe Shop-Sitzung.
    class function DefaultCachePath : String;
    //Liefert den Ordner, in dem WebView2 Profil, Cookies und Cache ablegt.
    //Ist _CachePath leer, wird DefaultCachePath verwendet; der Ordner wird
    //bei Bedarf angelegt.
    class function ResolveCachePath(const _CachePath : String) : String;
    //Wie ShowDialog, liefert aber das ModalResult: mrAbort, wenn der Browser
    //nicht starten oder den Inhalt nicht laden konnte (dann wurde nichts
    //gesendet), mrOK nach der Rueckuebertragung bzw. bei Mehrfachrueckgabe
    //nach mindestens einer, sonst mrCancel (Fenster geschlossen).
    class function Execute(const _IDSHTMLValue,_CachePath : String;
                           const _ReturnUrlPrefix : String = '';
                           _MultipleResult : Boolean = false;
                           _OnTransfer : TFunc<Integer> = nil) : TModalResult;
    //_MultipleResult: nach einer Navigation zur Ruecksprungadresse offen
    //bleiben; der Anwender schliesst das Fenster selbst, wenn er fertig ist.
    //_OnTransfer (nur mit _MultipleResult): holt die Rueckgaben schon
    //waehrend der Sitzung ab und liefert deren Gesamtzahl.
    class function ShowDialog(const _IDSHTMLValue,_CachePath : String;
                              const _ReturnUrlPrefix : String = '';
                              _MultipleResult : Boolean = false;
                              _OnTransfer : TFunc<Integer> = nil) : Boolean;
  end;

implementation

uses
  System.Threading;

{$R *.dfm}

{ TIDSConnectDlgWebBrowser }

procedure TIDSConnectDlgWebBrowser.FormShow(Sender: TObject);
begin
  //NavigateToString ist wirkungslos, solange die WebView nicht erzeugt wurde -
  //deshalb wird die Erzeugung hier einmalig angestossen und der Inhalt erst
  //in OnCreateWebViewCompleted geladen.
  if isInitialized then
    exit;
  isInitialized := true;
  WebBrowser.CreateWebView;
end;

procedure TIDSConnectDlgWebBrowser.WebBrowserCreateWebViewCompleted(
  Sender: TCustomEdgeBrowser; AResult: HRESULT);
begin
  //Vcl.Edge wirft keine Exceptions, sondern meldet Fehler nur ueber AResult.
  //Ohne diese Pruefung blieb bei fehlender WebView2-Runtime oder nicht
  //beschreibbarem UserDataFolder einfach ein weisses Fenster stehen.
  if not Succeeded(AResult) then
  begin
    MessageDlg('Der integrierte Browser konnte nicht gestartet werden.'+sLineBreak+
               'Ist die WebView2-Runtime installiert? (Fehler '+IntToHex(AResult,8)+')',
               mtError,[mbOk],0);
    ModalResult := mrAbort;
    exit;
  end;

  if not LoadContent then
  begin
    MessageDlg('Der Inhalt konnte nicht angezeigt werden.',mtError,[mbOk],0);
    ModalResult := mrAbort;
  end;
end;

procedure TIDSConnectDlgWebBrowser.WebBrowserNavigationCompleted(
  Sender: TCustomEdgeBrowser; IsSuccess: Boolean;
  WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
begin
  if returnUrlPrefix = '' then
    exit;
  if not IsSuccess then
  begin
    //Der Schritt zurueck kann scheitern, wenn die vorherige Shopseite selbst
    //das Ergebnis eines POST war und nicht erneut gesendet werden darf -
    //dann den Shop ueber das urspruengliche Formular neu oeffnen
    if returning then
    begin
      returning := false;
      LoadContent;
    end;
    exit;
  end;
  returning := false;
  //Der frueher hier verdrahtete Handler hatte die Signatur des alten
  //TWebBrowser und war in der DFM gar nicht zugewiesen - ModalResult wurde
  //deshalb nie gesetzt und ShowDialog lieferte immer false.
  if not StartsText(returnUrlPrefix,WebBrowser.LocationURL) then
    exit;
  if not multipleResult then
  begin
    ModalResult := mrOK;
    exit;
  end;
  //Nicht direkt hier abholen: der Abruf kann IDSCONNECT_ONERROR ausloesen,
  //und ein modaler Dialog darin waere eine verschachtelte Nachrichtenschleife
  //innerhalb eines WebView2-Ereignisses - laut Microsoft nicht unterstuetzt.
  //Die Meldung wird erst nach Rueckkehr aus dem Ereignis verarbeitet; ist
  //das Fenster bis dahin zerstoert, verfaellt sie.
  if Assigned(onTransfer) then
    PostMessage(Handle,WM_IDSCONNECT_COLLECT,0,0)
  else
    Inc(received);
  ReturnToShop;
end;

procedure TIDSConnectDlgWebBrowser.WMIDSConnectCollect(var Msg: TMessage);
begin
  Collect;
end;

procedure TIDSConnectDlgWebBrowser.Collect;
var
  lTransfer : TFunc<Integer>;
begin
  if closing or (not Assigned(onTransfer)) then
    exit;
  //Laeuft schon ein Abruf, kann die neue Uebertragung nach dessen Anfrage
  //eingetroffen sein - deshalb im Anschluss noch einmal abholen
  if collecting then
  begin
    collectPending := true;
    exit;
  end;
  //Frueher lief der Abruf synchron im Hauptthread: bei einem langsamen oder
  //nicht erreichbaren Hook-Server stand der Browser bis zum HTTP-Timeout
  collecting := true;
  collectPending := false;
  lTransfer := onTransfer;
  TTask.Run(
    procedure
    var
      lCount : Integer;
    begin
      try
        lCount := lTransfer();
      except
        //Die Abruffunktionen fangen ihre Fehler selbst ab; eine dennoch
        //durchgereichte Exception darf den Dialog nicht blockieren
        lCount := -1;
      end;
      TThread.Queue(nil,
        procedure
        begin
          CollectDone(lCount);
        end);
    end);
end;

procedure TIDSConnectDlgWebBrowser.CollectDone(_Count: Integer);
begin
  collecting := false;
  if _Count >= 0 then
  begin
    received := _Count;
    UpdateCaption;
  end;
  if collectPending and (not closing) then
    Collect;
end;

procedure TIDSConnectDlgWebBrowser.DoCollectTimer(Sender: TObject);
begin
  //Shops, die per Skript im Hintergrund an die Hook-URL senden, loesen keine
  //Navigation aus - deshalb zusaetzlich regelmaessig abholen
  Collect;
end;

procedure TIDSConnectDlgWebBrowser.UpdateCaption;
begin
  if received = 0 then
    exit;
  if received = 1 then
    Caption := captionBase+' - 1 Rückgabe übernommen, Fenster schließen, wenn Sie fertig sind'
  else
    Caption := Format('%s - %d Rückgaben übernommen, Fenster schließen, wenn Sie fertig sind',
                      [captionBase,received]);
end;

procedure TIDSConnectDlgWebBrowser.ReturnToShop;
begin
  UpdateCaption;
  returning := true;
  if WebBrowser.CanGoBack then
    WebBrowser.GoBack
  else
    LoadContent;
end;

//Wandelt einen Dateipfad in eine file-URL. Zeichen ausserhalb der
//unreservierten Menge (auch #, %, ?, Leerzeichen, Umlaute) werden als UTF-8
//prozentkodiert; ein UNC-Pfad \\server\freigabe wird zu file://server/freigabe.
function FileToUrl(const _Path : String) : String;
var
  lPath, lPrefix : String;
  lBytes : TBytes;
  i : Integer;
  b : Byte;
begin
  lPath := StringReplace(_Path,'\','/',[rfReplaceAll]);
  if StartsStr('//',lPath) then
  begin
    lPrefix := 'file:';
    //der Rest beginnt mit //server/...
  end else
  begin
    lPrefix := 'file:///';
  end;
  lBytes := TEncoding.UTF8.GetBytes(lPath);
  Result := lPrefix;
  for i := 0 to Length(lBytes)-1 do
  begin
    b := lBytes[i];
    if (AnsiChar(b) in ['A'..'Z','a'..'z','0'..'9','-','.','_','~','/']) or
       ((AnsiChar(b) = ':') and (i = 1) and (lPrefix = 'file:///')) then
      Result := Result+Char(b)
    else
      Result := Result+'%'+IntToHex(b,2);
  end;
end;

function TIDSConnectDlgWebBrowser.LoadContent: Boolean;
const
  //NavigateToString nimmt laut WebView2-Dokumentation hoechstens 2 MB an;
  //ein sehr grosser WKS-Warenkorb scheiterte daran mit "Inhalt konnte nicht
  //angezeigt werden". Mit Abstand zur Grenze, gemessen in UTF-16-Bytes.
  MaxInlineBytes = 1500000;
begin
  if Length(content)*SizeOf(Char) <= MaxInlineBytes then
  begin
    Result := WebBrowser.NavigateToString(content);
    exit;
  end;
  //Der Inhalt enthaelt die Zugangsdaten: eindeutiger Name und Loeschen beim
  //Schliessen des Dialogs
  Result := false;
  try
    if contentFile = '' then
    begin
      contentFile := TPath.Combine(TPath.GetTempPath,
                       'idsconnect-'+TGUID.NewGuid.ToString.Trim(['{','}'])+'.html');
      TFile.WriteAllText(contentFile,content,TEncoding.UTF8);
    end;
    //Der Pfad kann Leerzeichen, # oder % enthalten (Benutzername) - frueher
    //wurden nur Leerzeichen kodiert, ein # schnitt die URL als Fragment ab
    Result := WebBrowser.Navigate(FileToUrl(contentFile));
  except
    on E:Exception do
      MessageDlg('Die temporäre Datei für den Browser konnte nicht angelegt werden:'+sLineBreak+
                 E.Message,mtError,[mbOk],0);
  end;
end;

class function TIDSConnectDlgWebBrowser.DefaultCachePath: String;
var
  lBase : String;
begin
  lBase := GetEnvironmentVariable('LOCALAPPDATA');
  if lBase = '' then
    lBase := TPath.GetHomePath;
  Result := TPath.Combine(TPath.Combine(lBase,ChangeFileExt(ExtractFileName(ParamStr(0)),'')),
                          'IDSConnect.WebView2');
end;

class function TIDSConnectDlgWebBrowser.ResolveCachePath(const _CachePath: String): String;
begin
  Result := _CachePath;

  //Profil, Cookies und Cache dauerhaft ablegen - unabhaengig vom aktuellen
  //Arbeitsverzeichnis und pro Windows-Benutzer
  if Result = '' then
    Result := DefaultCachePath;

  if not TDirectory.Exists(Result) then
  try
    TDirectory.CreateDirectory(Result);
  except
    on E:Exception do
      //Kein Abbruch: WebView2 meldet das Problem sonst ueber AResult
      MessageDlg('Der Ordner für den integrierten Browser konnte nicht angelegt werden:'+sLineBreak+
                 Result+sLineBreak+E.Message,mtWarning,[mbOk],0);
  end;
end;

class function TIDSConnectDlgWebBrowser.ShowDialog(const _IDSHTMLValue,_CachePath : String;
  const _ReturnUrlPrefix : String; _MultipleResult : Boolean;
  _OnTransfer : TFunc<Integer>): Boolean;
begin
  Result := Execute(_IDSHTMLValue,_CachePath,_ReturnUrlPrefix,_MultipleResult,_OnTransfer) = mrOK;
end;

class function TIDSConnectDlgWebBrowser.Execute(const _IDSHTMLValue,_CachePath : String;
  const _ReturnUrlPrefix : String; _MultipleResult : Boolean;
  _OnTransfer : TFunc<Integer>): TModalResult;
var
  lDlg : TIDSConnectDlgWebBrowser;
  lContentFile : String;
  lBounds, lWorkArea : TRect;
  lWidth, lHeight : Integer;
begin
  lDlg := TIDSConnectDlgWebBrowser.Create(Application.MainForm);
  try
    //Position kann das Fensterhandle neu erzeugen. Deshalb unbedingt vor
    //ShowModal setzen, niemals in OnShow (EInvalidOperation / Visible).
    lDlg.Position := poDesigned;
    if Assigned(Application.MainForm) then
    begin
      lDlg.ScaleForPPI(Application.MainForm.CurrentPPI);
      lWorkArea := Application.MainForm.Monitor.WorkareaRect;
      if not IntersectRect(lBounds,Application.MainForm.BoundsRect,lWorkArea) then
        lBounds := lWorkArea;
    end else
    begin
      lDlg.ScaleForPPI(lDlg.Monitor.PixelsPerInch);
      lBounds := lDlg.Monitor.WorkareaRect;
    end;
    //90 % des sichtbaren Hauptfensters, mittig und innerhalb der Arbeitsflaeche.
    lWidth := MulDiv(lBounds.Right-lBounds.Left,90,100);
    lHeight := MulDiv(lBounds.Bottom-lBounds.Top,90,100);
    lDlg.SetBounds(lBounds.Left+(lBounds.Right-lBounds.Left-lWidth) div 2,
                   lBounds.Top+(lBounds.Bottom-lBounds.Top-lHeight) div 2,
                   lWidth,lHeight);
    lDlg.WebBrowser.UserDataFolder := ResolveCachePath(_CachePath);
    lDlg.content := _IDSHTMLValue;
    lDlg.returnUrlPrefix := _ReturnUrlPrefix;
    lDlg.multipleResult := _MultipleResult;
    lDlg.captionBase := lDlg.Caption;
    if _MultipleResult and Assigned(_OnTransfer) then
    begin
      lDlg.onTransfer := _OnTransfer;
      //Der Timer gehoert dem Dialog und wird mit ihm freigegeben
      lDlg.collectTimer := TTimer.Create(lDlg);
      lDlg.collectTimer.Interval := 60000;
      lDlg.collectTimer.OnTimer := lDlg.DoCollectTimer;
      lDlg.collectTimer.Enabled := true;
    end;
    try
      Result := lDlg.ShowModal;
    finally
      //Ein laufender Abruf greift noch auf den Dialog und den Warenkorb zu -
      //auf sein Ende warten (auch bei Application.Terminate) und dabei seine
      //Synchronize-/Queue-Aufrufe abarbeiten
      lDlg.closing := true;
      if Assigned(lDlg.collectTimer) then
        lDlg.collectTimer.Enabled := false;
      while lDlg.collecting do
        CheckSynchronize(50);
    end;
    //Bei Mehrfachrueckgabe schliesst der Anwender das Fenster selbst; der
    //Vorgang war erfolgreich, sobald mindestens eine Uebertragung erfolgte
    if _MultipleResult and (lDlg.received > 0) and (Result <> mrAbort) then
      Result := mrOK;
  finally
    //Die Lebensdauer gehoert eindeutig hierher. Das fruehere Action := caFree
    //im OnClose hat zusaetzlich Release gepostet - zusammen mit diesem Free
    //war das ein latenter Double-Free.
    lContentFile := lDlg.contentFile;
    lDlg.Free;
    //Erst nach dem Freigeben loeschen, wenn der Browser die Datei nicht
    //mehr offen hat
    if lContentFile <> '' then
      System.SysUtils.DeleteFile(lContentFile);
  end;
end;

end.
