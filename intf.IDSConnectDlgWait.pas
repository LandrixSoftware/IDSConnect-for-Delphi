{* Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.}

unit intf.IDSConnectDlgWait;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls;

type
  //Ergebnis eines Abrufversuchs
  TIDSConnectPollResult = (
    idsPollNothing,   //noch nichts eingetroffen, weiter warten
    idsPollReceived,  //etwas eingetroffen, aber es koennen weitere Rueckgaben
                      //folgen (Mehrfachrueckgabe ab IDS 2.5.1). Die Frist
                      //beginnt dabei von vorn - der Parameter hookURLTimeout
                      //bezieht sich laut Doku auf die letzte Uebertragung.
    idsPollFinished); //fertig, der Dialog wird geschlossen

  //Wird im Polling-Intervall aufgerufen
  TIDSConnectPollEvent = reference to function : TIDSConnectPollResult;

  //Warte-Dialog fuer die Rueck-Kommunikation ueber die Hook-URL.
  //Ersetzt den frueheren TaskMessageDlg, nach dem genau ein einziger
  //Abrufversuch unternommen wurde: war der Warenkorb zu diesem Zeitpunkt
  //noch nicht angekommen, schlug der Vorgang ohne Wiederholung fehl.
  TIDSConnectDlgWait = class(TForm)
  private
    FLabel : TLabel;
    FProgress : TProgressBar;
    FCancelBtn : TButton;
    FTimer : TTimer;
    FOnPoll : TIDSConnectPollEvent;
    FDeadline : TDateTime;
    FTimeoutSec : Integer;
    FBusy : Boolean;
    FCaptionBase : String;
    FReceived : Integer;
    FBaseText : String;
    FFollowUpSec : Integer;
    FGetReceived : TFunc<Integer>;
    FCancelRequested : Boolean;
    procedure DoTimer(Sender : TObject);
    procedure DoCancel(Sender : TObject);
    procedure DoCloseQuery(Sender : TObject; var CanClose : Boolean);
    procedure PollDone(_Result : TIDSConnectPollResult);
    procedure Finish(_Result : TModalResult);
    function CheckTimeout : Boolean;
    procedure UpdateCaption;
  public
    //Anzahl der bereits uebernommenen Rueckgaben
    property Received : Integer read FReceived;
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
    //_TimeoutSec entspricht dem IDS-2.5.1-Parameter hookURLTimeout.
    //_IntervalMS bestimmt, wie oft die Hook-URL abgefragt wird.
    //Liefert true, wenn mindestens eine Rueckgabe uebernommen wurde - auch
    //dann, wenn der Anwender anschliessend abgebrochen hat oder die Frist
    //abgelaufen ist.
    //_FollowUpSec bestimmt, wie lange nach einer eingetroffenen Rueckgabe noch
    //auf weitere gewartet wird. Viele Shops kennen die Mehrfachrueckgabe
    //nicht - ohne diese Verkuerzung stuende der Dialog nach der einzigen
    //Rueckgabe die volle Frist offen. 0 = die volle Frist verwenden.
    //_GetReceived liefert die tatsaechliche Anzahl uebernommener Rueckgaben,
    //wenn ein Abruf mehrere auf einmal uebernehmen kann; ohne wird je
    //idsPollReceived/idsPollFinished um eins gezaehlt.
    //_OnPoll laeuft in einem Hintergrund-Task, damit der Dialog bedienbar
    //bleibt, auch wenn ein Abruf haengt. Es laeuft hoechstens ein Abruf
    //zugleich, und der Dialog schliesst erst, wenn er beendet ist.
    //_GetReceived wird im Hauptthread aufgerufen.
    class function Execute(const _Caption,_Text : String; _TimeoutSec : Integer;
                           _OnPoll : TIDSConnectPollEvent;
                           _IntervalMS : Integer = 2000;
                           _FollowUpSec : Integer = 0;
                           _GetReceived : TFunc<Integer> = nil) : Boolean;
  end;

implementation

uses
  System.DateUtils, System.Threading;

{ TIDSConnectDlgWait }

constructor TIDSConnectDlgWait.CreateNew(AOwner: TComponent; Dummy: Integer);
begin
  inherited CreateNew(AOwner,Dummy);
  //Der Dialog wird zur Laufzeit aufgebaut, damit keine weitere DFM noetig ist
  BorderStyle := bsDialog;
  Position := poMainFormCenter;
  ClientWidth := 380;
  ClientHeight := 130;

  FLabel := TLabel.Create(Self);
  FLabel.Parent := Self;
  FLabel.SetBounds(16,16,348,32);
  FLabel.WordWrap := true;
  FLabel.AutoSize := false;

  FProgress := TProgressBar.Create(Self);
  FProgress.Parent := Self;
  FProgress.SetBounds(16,56,348,16);
  FProgress.Min := 0;
  FProgress.Max := 100;

  FCancelBtn := TButton.Create(Self);
  FCancelBtn.Parent := Self;
  FCancelBtn.SetBounds(268,88,96,26);
  FCancelBtn.Caption := 'Abbrechen';
  FCancelBtn.Cancel := true;
  FCancelBtn.OnClick := DoCancel;

  FTimer := TTimer.Create(Self);
  FTimer.Enabled := false;
  FTimer.OnTimer := DoTimer;

  OnCloseQuery := DoCloseQuery;
end;

procedure TIDSConnectDlgWait.Finish(_Result: TModalResult);
begin
  FTimer.Enabled := false;
  ModalResult := _Result;
end;

procedure TIDSConnectDlgWait.DoCancel(Sender: TObject);
begin
  //Laeuft gerade ein Abruf, wird erst nach dessen Ende geschlossen - er
  //greift noch auf den Warenkorb des Aufrufers zu
  if FBusy then
  begin
    FCancelRequested := true;
    FCancelBtn.Enabled := false;
    FCancelBtn.Caption := 'Wird beendet ...';
    exit;
  end;
  //Wurde bereits etwas uebernommen, ist der Abbruch trotzdem ein Erfolg -
  //bei der Mehrfachrueckgabe beendet der Anwender den Vorgang selbst
  if FReceived > 0 then
    Finish(mrOk)
  else
    Finish(mrCancel);
end;

procedure TIDSConnectDlgWait.DoCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  //Schliessen ueber das Fensterkreuz wie Abbrechen behandeln
  if FBusy then
  begin
    CanClose := false;
    DoCancel(nil);
  end;
end;

function TIDSConnectDlgWait.CheckTimeout: Boolean;
begin
  Result := (FTimeoutSec > 0) and (Now > FDeadline);
  if not Result then
    exit;
  //Bereits uebernommene Rueckgaben zaehlen als Erfolg
  if FReceived > 0 then
    Finish(mrOk)
  else
    Finish(mrAbort);
end;

procedure TIDSConnectDlgWait.UpdateCaption;
var
  lRest : Integer;
begin
  lRest := SecondsBetween(Now,FDeadline);
  if Now > FDeadline then
    lRest := 0;
  if FTimeoutSec > 0 then
  begin
    FProgress.Position := 100 - Round(lRest / FTimeoutSec * 100);
    Caption := Format('%s (noch %d s)',[FCaptionBase,lRest]);
  end;
  if FReceived > 0 then
  begin
    FCancelBtn.Caption := 'Fertig';
    if FReceived = 1 then
      FLabel.Caption := FBaseText+sLineBreak+sLineBreak+'1 Rückgabe übernommen.'
    else
      FLabel.Caption := FBaseText+sLineBreak+sLineBreak+
                        Format('%d Rückgaben übernommen.',[FReceived]);
  end;
end;

procedure TIDSConnectDlgWait.DoTimer(Sender: TObject);
var
  lPoll : TIDSConnectPollEvent;
begin
  //Ein noch laufender Abruf darf nicht erneut angestossen werden
  if FBusy then
    exit;
  if FCancelRequested then
  begin
    DoCancel(nil);
    exit;
  end;
  if CheckTimeout then
    exit;
  if not Assigned(FOnPoll) then
    exit;
  //Frueher lief der Abruf hier synchron im Timer: war der Server nicht
  //erreichbar, fror der Dialog bei jedem Versuch 5 bis 15 Sekunden ein und
  //"Abbrechen" reagierte kaum
  FBusy := true;
  UpdateCaption;
  lPoll := FOnPoll;
  TTask.Run(
    procedure
    var
      lResult : TIDSConnectPollResult;
    begin
      try
        lResult := lPoll();
      except
        //Die Abruffunktionen fangen ihre Fehler selbst ab; eine dennoch
        //durchgereichte Exception darf den Dialog nicht blockieren
        lResult := idsPollNothing;
      end;
      TThread.Queue(nil,
        procedure
        begin
          PollDone(lResult);
        end);
    end);
end;

procedure TIDSConnectDlgWait.PollDone(_Result: TIDSConnectPollResult);
begin
  FBusy := false;
  case _Result of
    idsPollFinished:
      begin
        Inc(FReceived);
        Finish(mrOk);
        exit;
      end;
    idsPollReceived:
      begin
        //Weitere Rueckgaben moeglich: die Frist beginnt von vorn.
        //Ist eine Nachlauffrist gesetzt, wird nur noch diese gewartet.
        if Assigned(FGetReceived) then
          FReceived := FGetReceived()
        else
          Inc(FReceived);
        if FFollowUpSec > 0 then
        begin
          FTimeoutSec := FFollowUpSec;
          FDeadline := IncSecond(Now,FFollowUpSec);
          FProgress.Style := pbstNormal;
        end else
        if FTimeoutSec > 0 then
          FDeadline := IncSecond(Now,FTimeoutSec);
      end;
  end;
  if FCancelRequested then
  begin
    DoCancel(nil);
    exit;
  end;
  if CheckTimeout then
    exit;
  UpdateCaption;
end;

class function TIDSConnectDlgWait.Execute(const _Caption, _Text: String;
  _TimeoutSec: Integer; _OnPoll: TIDSConnectPollEvent;
  _IntervalMS: Integer; _FollowUpSec : Integer;
  _GetReceived : TFunc<Integer>): Boolean;
var
  lDlg : TIDSConnectDlgWait;
begin
  Result := false;
  if not Assigned(_OnPoll) then
    exit;
  if _IntervalMS < 250 then
    _IntervalMS := 250;

  lDlg := TIDSConnectDlgWait.CreateNew(Application);
  try
    lDlg.Caption := _Caption;
    lDlg.FCaptionBase := _Caption;
    lDlg.FLabel.Caption := _Text;
    lDlg.FBaseText := _Text;
    lDlg.FOnPoll := _OnPoll;
    lDlg.FTimeoutSec := _TimeoutSec;
    lDlg.FFollowUpSec := _FollowUpSec;
    lDlg.FGetReceived := _GetReceived;
    if _TimeoutSec > 0 then
      lDlg.FDeadline := IncSecond(Now,_TimeoutSec)
    else
    begin
      //Ohne Timeout laeuft der Dialog, bis der Anwender abbricht
      lDlg.FDeadline := IncSecond(Now,24*60*60);
      lDlg.FProgress.Style := pbstMarquee;
    end;
    lDlg.FTimer.Interval := _IntervalMS;
    lDlg.FTimer.Enabled := true;
    lDlg.UpdateCaption;
    try
      lDlg.ShowModal;
    finally
      //Normalerweise endet ShowModal erst nach dem laufenden Abruf. Beim
      //Beenden der Anwendung (Application.Terminate) verlaesst die VCL
      //ShowModal aber ohne OnCloseQuery - der Task greift dann noch auf den
      //Dialog und den Warenkorb zu. Deshalb hier auf sein Ende warten und
      //dabei seine Synchronize-/Queue-Aufrufe weiter abarbeiten.
      lDlg.FTimer.Enabled := false;
      while lDlg.FBusy do
        CheckSynchronize(50);
    end;
    Result := lDlg.FReceived > 0;
  finally
    lDlg.Free;
  end;
end;

end.
