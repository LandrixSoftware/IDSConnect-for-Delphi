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

class function TIDSConnectDlgWebBrowser.ShowDialog(const _IDSHTMLValue,_CachePath : String;
  const _ReturnUrlPrefix : String): Boolean;
var
  lDlg : TIDSConnectDlgWebBrowser;
begin
  lDlg := TIDSConnectDlgWebBrowser.Create(Application.MainForm);
  try
    //Ein leerer UserDataFolder wuerde als leerer Pfad an die WebView2-Umgebung
    //durchgereicht; der Standard aus der DFM zeigt auf den IDE-Ordner.
    if _CachePath <> '' then
      lDlg.WebBrowser.UserDataFolder := _CachePath
    else
      lDlg.WebBrowser.UserDataFolder := TPath.Combine(TPath.GetCachePath,'IDSConnect.WebView2');
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
