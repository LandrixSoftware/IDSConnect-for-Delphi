unit intf.IDSConnectDlgWebBrowser;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.IOUtils, System.StrUtils, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Vcl.Menus,Vcl.ExtDlgs,
  Vcl.OleCtrls, Winapi.WebView2, Winapi.ActiveX,
  Vcl.Edge;

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
    //Praefix der Ruecksprungadresse. Sobald der Browser dorthin navigiert,
    //gilt die Rueck-Kommunikation als abgeschlossen. Frueher war hier
    //"https://www.landrix.de" fest verdrahtet - bei jeder anderen Hook-URL
    //konnte der Dialog sich nie selbst schliessen.
    returnUrlPrefix : String;
  public
    //Liefert den Ordner, in dem WebView2 Profil, Cookies und Cache ablegt.
    //Ist _CachePath leer, wird ein anwendungseigener Ordner unterhalb von
    //%LOCALAPPDATA% verwendet und bei Bedarf angelegt.
    class function ResolveCachePath(const _CachePath : String) : String;
    class function ShowDialog(const _IDSHTMLValue,_CachePath : String;
                              const _ReturnUrlPrefix : String = '') : Boolean;
  end;

implementation

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

  if not WebBrowser.NavigateToString(content) then
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
    exit;
  //Der frueher hier verdrahtete Handler hatte die Signatur des alten
  //TWebBrowser und war in der DFM gar nicht zugewiesen - ModalResult wurde
  //deshalb nie gesetzt und ShowDialog lieferte immer false.
  if StartsText(returnUrlPrefix,WebBrowser.LocationURL) then
    ModalResult := mrOK;
end;

class function TIDSConnectDlgWebBrowser.ResolveCachePath(const _CachePath: String): String;
begin
  Result := _CachePath;

  //Bleibt der Ordner leer, legt WebView2 sein Profil im Verzeichnis der
  //ausfuehrbaren Datei an - unter C:\Program Files schlaegt die
  //Initialisierung damit fehl. Der Standard aus der DFM zeigte ausserdem auf
  //den Ordner der Entwicklungsumgebung (bds.exe.WebView2).
  //Deshalb ein anwendungseigener, beschreibbarer Ordner unter %LOCALAPPDATA%.
  //Er ist bewusst dauerhaft: WebView2 legt dort Cookies und Anmeldesitzung
  //ab, sonst muesste sich der Anwender bei jedem Aufruf neu anmelden.
  if Result = '' then
    Result := TPath.Combine(TPath.GetCachePath,
                ChangeFileExt(ExtractFileName(Application.ExeName),'')+'.IDSConnect.WebView2');

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
  const _ReturnUrlPrefix : String): Boolean;
var
  lDlg : TIDSConnectDlgWebBrowser;
begin
  lDlg := TIDSConnectDlgWebBrowser.Create(Application.MainForm);
  try
    lDlg.WebBrowser.UserDataFolder := ResolveCachePath(_CachePath);
    lDlg.content := _IDSHTMLValue;
    lDlg.returnUrlPrefix := _ReturnUrlPrefix;
    Result := lDlg.ShowModal = mrOK;
  finally
    //Die Lebensdauer gehoert eindeutig hierher. Das fruehere Action := caFree
    //im OnClose hat zusaetzlich Release gepostet - zusammen mit diesem Free
    //war das ein latenter Double-Free.
    lDlg.Free;
  end;
end;

end.
