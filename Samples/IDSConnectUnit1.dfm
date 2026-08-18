object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'IDSConnect-Schnittstelle 2.5.1'
  ClientHeight = 895
  ClientWidth = 1279
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 41
    Height = 13
    Caption = 'Anbieter'
  end
  object Label2: TLabel
    Left = 607
    Top = 163
    Width = 43
    Height = 13
    Caption = 'Suchtext'
  end
  object Label3: TLabel
    Left = 607
    Top = 125
    Width = 68
    Height = 13
    Caption = 'Artikelnummer'
  end
  object ListBox1: TListBox
    Left = 8
    Top = 27
    Width = 449
    Height = 829
    ItemHeight = 13
    TabOrder = 0
    OnClick = ListBox1Click
  end
  object Button1: TButton
    Left = 8
    Top = 862
    Width = 145
    Height = 25
    Caption = 'Anbieterliste aktualisieren'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 462
    Top = 51
    Width = 130
    Height = 25
    Caption = 'Warenkorb empfangen'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Edit1: TEdit
    Left = 687
    Top = 122
    Width = 121
    Height = 21
    TabOrder = 3
    Text = 'AXPP2RM100200'
  end
  object Button3: TButton
    Left = 462
    Top = 120
    Width = 130
    Height = 25
    Caption = 'Artikel Deeplink'
    TabOrder = 4
    OnClick = Button3Click
  end
  object Button4: TButton
    Left = 462
    Top = 82
    Width = 130
    Height = 25
    Caption = 'Warenkorb senden'
    TabOrder = 5
    OnClick = Button4Click
  end
  object Button5: TButton
    Left = 462
    Top = 159
    Width = 130
    Height = 25
    Caption = 'Artikel suchen'
    TabOrder = 6
    OnClick = Button5Click
  end
  object Edit2: TEdit
    Left = 687
    Top = 160
    Width = 121
    Height = 21
    TabOrder = 7
    Text = 'Wanne'
  end
  object Memo1: TMemo
    Left = 463
    Top = 200
    Width = 345
    Height = 289
    ScrollBars = ssBoth
    TabOrder = 8
  end
  object CheckBox1: TCheckBox
    Left = 463
    Top = 28
    Width = 187
    Height = 17
    Caption = 'InApp-Browser'
    Checked = True
    State = cbChecked
    TabOrder = 9
  end
end
