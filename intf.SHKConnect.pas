{
License IDSConnect-for-Delphi

Copyright (C) 2020 Landrix Software GmbH & Co. KG
Sven Harazim, info@landrix.de

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
}

unit intf.SHKConnect;

interface

uses
  System.SysUtils, System.Classes,System.StrUtils,Vcl.Controls,
  System.Contnrs,Vcl.Dialogs,Vcl.Forms,System.IOUTils, System.Generics.Collections
  ;

type
  TSHKConnectSupplier = class
  public
    ID:      Integer;
    Name :   string ;
    Street: string ;
    Zip:     string ;
    City:     string ;
    Country:    string ;
    ServiceURL : String;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
	  procedure AssignTo(_Dest : TSHKConnectSupplier);
  	function  Duplicate : TSHKConnectSupplier;
  end;

  TSHKConnectSupplierList = class(TObjectList<TSHKConnectSupplier>)
	  procedure AssignTo(_Dest : TSHKConnectSupplierList);
  	function  Duplicate : TSHKConnectSupplierList;
    function  GetItemBySupplierID(const _ID : Integer) : TSHKConnectSupplier;
  end;

  TSHKConnectBusiness = class
  public
    ID : Integer;
    Description : String;
    Supplier : TSHKConnectSupplierList;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
	  procedure AssignTo(_Dest : TSHKConnectBusiness);
  	function  Duplicate : TSHKConnectBusiness;
  end;

  TSHKConnectBusinessList = class(TObjectList<TSHKConnectBusiness>)
	  procedure AssignTo(_Dest : TSHKConnectBusinessList);
  	function  Duplicate : TSHKConnectBusinessList;
    function  GetItemByBusiness(const _ID : Integer;_CreateIfNotExists : Boolean = false) : TSHKConnectBusiness;
  end;

  TSHKConnectHelper = class(TObject)
  public const
    SHKCONNECT_SERVICE_ARGE  = 'https://arge20.shk-connect.de';
    SHKCONNECT_SERVICE_SHKGH = 'https://shkgh20.shk-connect.de';
    SHKCONNECT_SERVICE_OC    = 'https://o-connect.de';

    SHKCONNECT_SERVICE_BL  = '/services/Branchenliste';
    SHKCONNECT_SERVICE_AA  = '/services/AllgemeineAuskuenfte';
    SHKCONNECT_SERVICE_AIA = '/services/AnwenderIndividuelleAuskuenfte';
  public
    class function GetSupplierList(_ResultList : TSHKConnectBusinessList) : Boolean;
  end;

implementation

uses
  intf.SHKConnectAllgemeineAuskuenfte
  ,intf.SHKConnectAnwenderIndividuelleAuskuenfte
  ,intf.SHKConnectBranchenliste;

{$I intf.SHKCONNECT.inc}

{ TSHKConnectSupplier }

procedure TSHKConnectSupplier.AssignTo(_Dest: TSHKConnectSupplier);
begin
  _Dest.ID := ID;
  _Dest.Name := Name;
  _Dest.Street := Street;
  _Dest.Zip :=  Zip;
  _Dest.City :=  City;
  _Dest.Country :=  Country;
  _Dest.ServiceURL := ServiceURL;
end;

procedure TSHKConnectSupplier.Clear;
begin
  ID := -1;
  Name := '';
  Street := '';
  Zip := '';
  City := '';
  Country := '';
  ServiceURL := '';
end;

function TSHKConnectSupplier.Duplicate: TSHKConnectSupplier;
begin
  Result := TSHKConnectSupplier.Create;
  AssignTo(Result);
end;

constructor TSHKConnectSupplier.Create;
begin
  Clear;
end;

destructor TSHKConnectSupplier.Destroy;
begin
  inherited;
end;

{ TSHKConnectSupplierList }

function TSHKConnectSupplierList.GetItemBySupplierID(
  const _ID: Integer): TSHKConnectSupplier;
begin
  Result := TSHKConnectSupplier.Create;
  Result.ID := _ID;
  Add(Result);
end;

procedure TSHKConnectSupplierList.AssignTo(_Dest: TSHKConnectSupplierList);
var
  i : Integer;
begin
  _Dest.Clear;
  for i := 0 to Count-1 do
    _Dest.Add(Items[i].Duplicate);
end;

function TSHKConnectSupplierList.Duplicate : TSHKConnectSupplierList;
begin
  Result := TSHKConnectSupplierList.Create;
  AssignTo(Result);
end;

{ TSHKConnectBusiness }

constructor TSHKConnectBusiness.Create;
begin
  Supplier := TSHKConnectSupplierList.Create;
  Clear;
end;

destructor TSHKConnectBusiness.Destroy;
begin
  if Assigned(Supplier) then begin Supplier.Free; Supplier := nil; end;
  inherited;
end;

procedure TSHKConnectBusiness.AssignTo(_Dest: TSHKConnectBusiness);
begin
  _Dest.ID := ID;
  _Dest.Description := Description;
  Supplier.AssignTo(_Dest.Supplier);
end;

procedure TSHKConnectBusiness.Clear;
begin
  ID := -1;
  Description := '';
  Supplier.Clear;
end;

function TSHKConnectBusiness.Duplicate: TSHKConnectBusiness;
begin
  Result := TSHKConnectBusiness.Create;
  AssignTo(Result);
end;

{ TSHKConnectBusinessList }

function TSHKConnectBusinessList.GetItemByBusiness(const _ID: Integer;
  _CreateIfNotExists: Boolean): TSHKConnectBusiness;
var
  i : Integer;
begin
  REsult := nil;
  for I := 0 to Count - 1 do
  if Items[i].ID = _ID then
  begin
    Result := Items[i];
    break;
  end;
  if (Result = nil) and (_CreateIfNotExists) then
  begin
    Result := TSHKConnectBusiness.Create;
    Result.ID := _ID;
    Add(Result);
  end;
end;

procedure TSHKConnectBusinessList.AssignTo(_Dest: TSHKConnectBusinessList);
var
  i : Integer;
begin
  _Dest.Clear;
  for i := 0 to Count-1 do
    _Dest.Add(Items[i].Duplicate);
end;

function TSHKConnectBusinessList.Duplicate : TSHKConnectBusinessList;
begin
  Result := TSHKConnectBusinessList.Create;
  AssignTo(Result);
end;

{ TSHKConnectHelper }

class function TSHKConnectHelper.GetSupplierList(_ResultList: TSHKConnectBusinessList): Boolean;
var
  bl_gb : GetBranchenListe;
  bl_b : BranchenlisteBean;
  bl_resp : GetBranchenListeAntwort;
  bl_br : Branche;

  aa_gb : GetAllgemeineAuskunft;
  aa_b : AllgemeineAuskuenfteBean;
  aa_resp : GetAllgemeineAuskunftAntwort;
  aa_u : Unternehmen;

  i : Integer;

  businessItm : TSHKConnectBusiness;
  supplierItm : TSHKConnectSupplier;
begin
  Result := false;

  if _ResultList = nil then
    exit;

  try
    bl_gb := GetBranchenListe.Create;
    bl_gb.Schnittstellenversion := '2.0';
    bl_gb.Softwarename := SHKCONNECT_LOGIN;
    bl_gb.Softwarepasswort := SHKCONNECT_PWD;

    bl_b := GetBranchenlisteBean(false,SHKCONNECT_SERVICE_ARGE+SHKCONNECT_SERVICE_BL);
    bl_resp := bl_b.GetBranchenListe(bl_gb);

    if bl_resp.Status.Code = '0' then
    begin
      for bl_br in bl_resp.Branche do
      begin
        businessItm := _ResultList.GetItemByBusiness(bl_br.ID,true);
        businessItm.Description := bl_br.Name_;
      end;
    end;// else
      //WideMessageDialog(SHKCONNECT_SERVICE_ARGE+SHKCONNECT_SERVICE_BL+#10+bl_resp.Status.Meldung, mtError, [mbOK], 0);

    bl_resp.Free;
    bl_b := nil;

    bl_gb.Free;
  except
//    On E:Exception do begin TLog.Log(true,P_ERROR,'GetBranchenlisteBean '+SHKCONNECT_SERVICE_ARGE,e);  end;
  end;

  try
    bl_gb := GetBranchenListe.Create;
    bl_gb.Schnittstellenversion := '2.0';
    bl_gb.Softwarename := SHKCONNECT_LOGIN;
    bl_gb.Softwarepasswort := SHKCONNECT_PWD;

    bl_b := GetBranchenlisteBean(false,SHKCONNECT_SERVICE_SHKGH+SHKCONNECT_SERVICE_BL);
    bl_resp := bl_b.GetBranchenListe(bl_gb);

    if bl_resp.Status.Code = '0' then
    begin
      for bl_br in bl_resp.Branche do
      begin
        businessItm := _ResultList.GetItemByBusiness(bl_br.ID,true);
        businessItm.Description := bl_br.Name_;
      end;
    end;// else
      //WideMessageDialog(SHKCONNECT_SERVICE_SHKGH+SHKCONNECT_SERVICE_BL+#10+bl_resp.Status.Meldung, mtError, [mbOK], 0);

    bl_resp.Free;
    bl_b := nil;

    bl_gb.Free;
  except
//    On E:Exception do begin TLog.Log(true,P_ERROR,'GetBranchenlisteBean '+SHKCONNECT_SERVICE_SHKGH,e);  end;
  end;

  try
    bl_gb := GetBranchenListe.Create;
    bl_gb.Schnittstellenversion := '2.0';
    bl_gb.Softwarename := SHKCONNECT_LOGIN;
    bl_gb.Softwarepasswort := SHKCONNECT_PWD;

    bl_b := GetBranchenlisteBean(false,SHKCONNECT_SERVICE_OC+SHKCONNECT_SERVICE_BL);
    bl_resp := bl_b.GetBranchenListe(bl_gb);

    if bl_resp.Status.Code = '0' then
    begin
      for bl_br in bl_resp.Branche do
      begin
        businessItm := _ResultList.GetItemByBusiness(bl_br.ID,true);
        businessItm.Description := bl_br.Name_;
      end;
    end;// else
      //WideMessageDialog(SHKCONNECT_SERVICE_SHKGH+SHKCONNECT_SERVICE_BL+#10+bl_resp.Status.Meldung, mtError, [mbOK], 0);

    bl_resp.Free;
    bl_b := nil;

    bl_gb.Free;
  except
//    On E:Exception do begin TLog.Log(true,P_ERROR,'GetBranchenlisteBean '+SHKCONNECT_SERVICE_OC,e);  end;
  end;

  try
    aa_gb := GetAllgemeineAuskunft.Create;
    aa_gb.Schnittstellenversion := '2.0';

    aa_gb.Softwarename := SHKCONNECT_LOGIN;
    aa_gb.Softwarepasswort := SHKCONNECT_PWD;

    for i := 0 to _ResultList.Count - 1 do
    begin
      aa_gb.BrancheID := IntToStr(_ResultList[i].ID);

      try
      aa_b := GetAllgemeineAuskuenfteBean(false,SHKCONNECT_SERVICE_ARGE+SHKCONNECT_SERVICE_AA);
      aa_resp := aa_b.GetAllgemeineAuskunft(aa_gb);

      if aa_resp.Status.Code = '0' then
      begin
        for aa_u in aa_resp.Unternehmen do
        begin
          supplierItm := _ResultList[i].Supplier.GetItemBySupplierID(aa_u.ID);
          supplierItm.Name := aa_u.Name_;
          supplierItm.Street := aa_u.Strasse;
          supplierItm.zip := aa_u.PLZ;
          supplierItm.City := aa_u.Ort;
          supplierItm.Country := aa_u.Land;
          supplierItm.ServiceURL := SHKCONNECT_SERVICE_ARGE;
        end;
      end;// else
        //WideMessageDialog(SHKCONNECT_SERVICE_ARGE+SHKCONNECT_SERVICE_AA+#10+bl_resp.Status.Meldung, mtError, [mbOK], 0);

      aa_resp.Free;
      aa_b := nil;
      except
        //On E:Exception do begin TLog.Log(true,P_ERROR,'GetAllgemeineAuskuenfteBean '+SHKCONNECT_SERVICE_ARGE,e); exit; end;
      end;

      try
      aa_b := GetAllgemeineAuskuenfteBean(false,SHKCONNECT_SERVICE_SHKGH+SHKCONNECT_SERVICE_AA);
      aa_resp := aa_b.GetAllgemeineAuskunft(aa_gb);

      if aa_resp.Status.Code = '0' then
      begin
        for aa_u in aa_resp.Unternehmen do
        begin
          supplierItm := _ResultList[i].Supplier.GetItemBySupplierID(aa_u.ID);
          supplierItm.Name := aa_u.Name_;
          supplierItm.Street := aa_u.Strasse;
          supplierItm.zip := aa_u.PLZ;
          supplierItm.City := aa_u.Ort;
          supplierItm.Country := aa_u.Land;
          supplierItm.ServiceURL := SHKCONNECT_SERVICE_SHKGH;
        end;
      end;// else
        //WideMessageDialog(SHKCONNECT_SERVICE_SHKGH+SHKCONNECT_SERVICE_AA+#10+bl_resp.Status.Meldung, mtError, [mbOK], 0);

      aa_resp.Free;
      aa_b := nil;
      except
//        On E:Exception do begin TLog.Log(true,P_ERROR,'GetAllgemeineAuskuenfteBean '+SHKCONNECT_SERVICE_SHKGH,e); exit; end;
      end;

      try
      aa_b := GetAllgemeineAuskuenfteBean(false,SHKCONNECT_SERVICE_OC+SHKCONNECT_SERVICE_AA);
      aa_resp := aa_b.GetAllgemeineAuskunft(aa_gb);

      if aa_resp.Status.Code = '0' then
      begin
        for aa_u in aa_resp.Unternehmen do
        begin
          supplierItm := _ResultList[i].Supplier.GetItemBySupplierID(aa_u.ID);
          supplierItm.Name := aa_u.Name_;
          supplierItm.Street := aa_u.Strasse;
          supplierItm.zip := aa_u.PLZ;
          supplierItm.City := aa_u.Ort;
          supplierItm.Country := aa_u.Land;
          supplierItm.ServiceURL := SHKCONNECT_SERVICE_OC;
        end;
      end;// else
        //WideMessageDialog(SHKCONNECT_SERVICE_SHKGH+SHKCONNECT_SERVICE_AA+#10+bl_resp.Status.Meldung, mtError, [mbOK], 0);

      aa_resp.Free;
      aa_b := nil;
      except
//        On E:Exception do begin TLog.Log(true,P_ERROR,'GetAllgemeineAuskuenfteBean '+SHKCONNECT_SERVICE_OC,e); exit; end;
      end;
    end;

    aa_gb.Free;
  except
//    On E:Exception do begin TLog.Log(true,P_ERROR,'GetAllgemeineAuskuenfteBean',e); exit; end;
  end;
end;

end.

