object IDSConnectDlgWebBrowser: TIDSConnectDlgWebBrowser
  Left = 266
  Top = 123
  Caption = 'IDS-Connect'
  ClientHeight = 596
  ClientWidth = 484
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnShow = FormShow
  object WebBrowser: TEdgeBrowser
    Left = 0
    Top = 0
    Width = 484
    Height = 596
    Align = alClient
    TabOrder = 0
    AllowSingleSignOnUsingOSPrimaryAccount = False
    TargetCompatibleBrowserVersion = '117.0.2045.28'
    UserDataFolder = '%LOCALAPPDATA%\bds.exe.WebView2'
    OnCreateWebViewCompleted = WebBrowserCreateWebViewCompleted
    OnNavigationCompleted = WebBrowserNavigationCompleted
  end
end
