{*******************************************************}
{                                                       }
{ TEntity is the parent class responsible for being the }
{   persistence layer like the DB. Each inherited class }
{   represents a single entity in the DB.               }
{                                                       }
{*******************************************************}

{*******************************************************}
{         Created by Thiago R. Morini - 10/2018         }
{*******************************************************}

unit Morini.Entity;

interface

uses
  System.SysUtils, System.Rtti, System.TypInfo, Morini.Attributes, Morini.Exception, Morini.DBField, Morini.DB,

  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.VCLUI.Wait, FireDAC.Comp.Client, FireDAC.Phys.MSSQL,
  FireDAC.Phys.MSSQLDef, FireDAC.Comp.UI, FireDAC.DApt;

resourcestring
  SFieldNotInformed = 'The field ''%s'' must be informed';
  SRequiredField = 'The field ''%s'' must be filled';

type
  TAction = (acInsert, acUpdate, acDelete);
  TInvokedMethods = (imCreate, imDestroy, imSearch);

  TEntity = class
  private
    procedure FillAttributes;
    procedure DestroyForeignEntities;
    procedure ConfigFields(ListOfFields: TDBFields);
    function GetFields: TDBFields;
    function GetPrimaryKeyField: TDBFields;
    function GetForeignKeyField: TDBFields;
    function GetRequiredFields: TDBFields;
    function InvokeMethod(const InvokedMethod: TInvokedMethods; RttiType: TRttiType; Instance: TValue; const Args: array of TValue): TValue;
  protected
    procedure SetFieldValues(Database: TDatabase; BringForeignEntity: Boolean = False);
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Search(Connection: TFDConnection; BringForeignEntity: Boolean = False);
    procedure Insert(Connection: TFDConnection);
    procedure Update(Connection: TFDConnection);
    procedure Delete(Connection: TFDConnection);
    procedure Save(Connection: TFDConnection; Action: TAction);
    procedure CheckFilling(Action: TAction; ListOfFields: TDBFields); overload;
    function GetTableName: string;
    class function IsEntity(Value: TValue): Boolean;
  end;

implementation

uses
  Morini.SQL;

{ TEntity }

constructor TEntity.Create;
begin
  FillAttributes;
end;

destructor TEntity.Destroy;
begin
  DestroyForeignEntities;
  inherited;
end;

procedure TEntity.Search(Connection: TFDConnection; BringForeignEntity: Boolean = False);
var
  SQL: TSQL;
  Aux: TDatabase;

  Conditions: array of TCondition;
  ListOfFields: TDBFields;
  Value: TValue;
  DBField: TDBField;
begin
  ListOfFields := GetPrimaryKeyField;

  SetLength(Conditions, 0);

  for Value in ListOfFields do
  begin
    Value.ExtractRawData(@DBField);
    SetLength(Conditions, Length(Conditions)+1);
    Conditions[Length(Conditions)-1] := DBField.Equal(TValue.From<Variant>(DBField.Value));
  end;

  SQL := TSQL.Create;
  Aux := TDatabase.Create(nil, Connection);

  try
    (* SELECT * FROM <TABLE> WHERE <PK> = KEY *)
    Aux.OpenTable(SQL.Select.From(Self).Where(Conditions).ToText);

    (* Populate the properties with data from the DB. *)
    SetFieldValues(Aux, BringForeignEntity);
  finally
    FreeAndNil(Aux);
    FreeAndNil(SQL);
  end;
end;

procedure TEntity.Insert(Connection: TFDConnection);
var
  SQL: TSQL;
  Aux: TDatabase;
begin
  SQL := TSQL.Create;
  Aux := TDatabase.Create(nil, Connection);

  try
    (* INSERT INTO <TABLE> VALUES(<FIELDS>) *)
    Aux.ExecuteSQL(SQL.Insert(Self).ToText);
  finally
    FreeAndNil(Aux);
    FreeAndNil(SQL);
  end;
end;

procedure TEntity.Update(Connection: TFDConnection);
var
  SQL: TSQL;
  Aux: TDatabase;
begin
  SQL := TSQL.Create;
  Aux := TDatabase.Create(nil, Connection);

  try
    (* UPDATE <TABLE> SET <FIELDS> WHERE <PK> = KEY *)
    Aux.ExecuteSQL(SQL.Update(Self).ToText);
  finally
    FreeAndNil(Aux);
    FreeAndNil(SQL);
  end;
end;

procedure TEntity.Delete(Connection: TFDConnection);
var
  SQL: TSQL;
  Aux: TDatabase;
begin
  SQL := TSQL.Create;
  Aux := TDatabase.Create(nil, Connection);

  try
    (* DELETE FROM <TABLE> WHERE <PK> = KEY *)
    Aux.ExecuteSQL(SQL.Delete(Self).ToText);
  finally
    FreeAndNil(Aux);
    FreeAndNil(SQL);
  end;
end;

procedure TEntity.Save(Connection: TFDConnection; Action: TAction);
begin
  case Action of
    acInsert: Self.Insert(Connection);
    acUpdate: Self.Update(Connection);
  end;
end;

procedure TEntity.CheckFilling(Action: TAction; ListOfFields: TDBFields);
var
  RequiredFields: TDBFields;
  Required, Value: TValue;
  RequiredField, DBField: TDBField;
  ExistRequired: Boolean;
begin
  case Action of
    acInsert:
    begin
      if Length(ListOfFields) > 0 then
      begin
        (* For the inclusion of informed fields, it is necessary that all required fields are within the list of informed fields.
             If they are, it is checked if the values of these fields are filled. *)
        RequiredFields := GetRequiredFields;
        for Required in RequiredFields do
        begin
          Required.ExtractRawData(@RequiredField);
          ExistRequired := False;

          for Value in ListOfFields do
          begin
            if not TDBField.IsField(Value) then Continue;
            Value.ExtractRawData(@DBField);

            if SameText(RequiredField.FieldName, DBField.FieldName) then
            begin
              ExistRequired := True;
              Break;
            end;
          end;

          if not ExistRequired then
            raise EMoriniException.CreateFmt(SFieldNotInformed, [RequiredField.Display]);
        end;

        ConfigFields(ListOfFields);
      end
      else
        (* If no fields were informed, it means that the system must take all fields. *)
        ConfigFields(GetFields);
    end;

    acUpdate:
    begin
      if Length(ListOfFields) > 0 then
      begin
        (* To change the informed fields, it is necessary to check the completion of all the fields informed,
             but it is also necessary to see if the primary key is filled in, as it may not be in the list of fields informed. *)
        ConfigFields(GetPrimaryKeyField);
        ConfigFields(ListOfFields);
      end
      else
        (* If no fields were informed, it means that the system must pick up all fields. *)
        ConfigFields(GetFields);
    end;

    acDelete:
    begin
      (* For the deletion, I just need to see if the primary key is populated. *)
      ConfigFields(GetPrimaryKeyField);
    end;
  end;
end;

function TEntity.GetTableName: string;
var
  Context: TRttiContext;
  Obj: TRttiType;
  Attribute: TCustomAttribute;
begin
  (* Get the name of the table registered in the entity attribute. *)

  Context := TRttiContext.Create;

  try
    Obj := Context.GetType(Self.ClassInfo);

    for Attribute in Obj.GetAttributes do
    begin
      if Attribute is Table then
      begin
        Result := (Attribute as Table).Name;
      end;
    end;
  finally
    Context.Free;
  end;
end;

class function TEntity.IsEntity(Value: TValue): Boolean;
begin
  if Value.TypeInfo = nil then
  begin
    Result := False;
    Exit;
  end;

  Result := (Value.TypeInfo.Kind = tkClass) and (Value.TypeInfo.TypeData.ClassType.ClassParent = TEntity);
end;

procedure TEntity.ConfigFields(ListOfFields: TDBFields);
var
  RequiredNotFilled: Boolean;
  Display: string;

  Value: TValue;
  DBField: TDBField;
begin
  (* Here you read all the properties of the entity to know if it is required,
       if it has no value and if it is not auto-increment. If yes, set a raise. *)

  RequiredNotFilled := False;
  Display := '';

  for Value in ListOfFields do
  begin
    if not TDBField.IsField(Value) then Continue;
    Value.ExtractRawData(@DBField);

    (* I look for if it is required, if it has no value and if it is not auto-increment.
         If yes, it triggers a raise stating that the field is mandatory (The Display registered in the attribute). *)
    if (DBField.Required) and not (DBField.HasValue) and not (DBField.PK.AutoIncrement) then
    begin
      RequiredNotFilled := True;
      Display := DBField.Display;
      Break;
    end;
  end;

  (* Set the raise *)
  if RequiredNotFilled then
    raise EMoriniException.CreateFmt(SRequiredField, [Display]);
end;

function TEntity.GetFields: TDBFields;
var
  Context: TRttiContext;
  Obj: TRttiType;
  Prop: TRttiProperty;

  Value: TValue;
begin
  SetLength(Result, 0);

  Context := TRttiContext.Create;

  try
    Obj := Context.GetType(Self.ClassInfo);

    for Prop in Obj.GetProperties do
    begin
      Value := Prop.GetValue(Self);
      if not TDBField.IsField(Value) then Continue;

      SetLength(Result, Length(Result)+1);
      Result[Length(Result)-1] := Value;
    end;
  finally
    Context.Free;
  end;
end;

function TEntity.GetPrimaryKeyField: TDBFields;
var
  Value: TValue;
begin
  SetLength(Result, 0);

  for Value in GetFields do
  begin
    if not TDBField.IsPK(Value) then Continue;

    SetLength(Result, Length(Result)+1);
    Result[Length(Result)-1] := Value;
  end;
end;

function TEntity.GetForeignKeyField: TDBFields;
var
  Value: TValue;
begin
  SetLength(Result, 0);

  for Value in GetFields do
  begin
    if not TDBField.IsFK(Value) then Continue;

    SetLength(Result, Length(Result)+1);
    Result[Length(Result)-1] := Value;
  end;
end;

function TEntity.GetRequiredFields: TDBFields;
var
  Value: TValue;
begin
  SetLength(Result, 0);

  for Value in GetFields do
  begin
    if not TDBField.IsRequired(Value) then Continue;

    SetLength(Result, Length(Result)+1);
    Result[Length(Result)-1] := Value;
  end;
end;

procedure TEntity.FillAttributes;
var
  Context: TRttiContext;
  Obj: TRttiType;
  Prop: TRttiProperty;
  Attribute: TCustomAttribute;

  Value: TValue;
  DBField: TDBField;
begin
  (* When creating the entity, all attributes of the properties are stored in the respective types of each child of the TDBField. *)

  Context := TRttiContext.Create;

  try
    Obj := Context.GetType(Self.ClassInfo);

    for Prop in Obj.GetProperties do
    begin

      (* For each specific type, all attributes are read and stored in a TValue. *)
      if Prop.PropertyType.Handle.TypeData.ClassType = TVariantField then
        DBField := TVariantField.Create(System.TypeInfo(Variant))
      else
      if Prop.PropertyType.Handle.TypeData.ClassType = TIntegerField then
        DBField := TIntegerField.Create(System.TypeInfo(Integer))
      else
      if Prop.PropertyType.Handle.TypeData.ClassType = TStringField then
        DBField := TStringField.Create(System.TypeInfo(string))
      else
      if Prop.PropertyType.Handle.TypeData.ClassType = TDateTimeField then
        DBField := TDateTimeField.Create(System.TypeInfo(TDateTime))
      else
      if Prop.PropertyType.Handle.TypeData.ClassType = TFloatField then
        DBField := TFloatField.Create(System.TypeInfo(Double))
      else
      if Prop.PropertyType.Handle.TypeData.ClassType = TCurrencyField then
        DBField := TCurrencyField.Create(System.TypeInfo(Double))
      else
      if Prop.PropertyType.Handle.TypeData.ClassType = TBooleanField then
        DBField := TBooleanField.Create(System.TypeInfo(Boolean))
      else
      if Prop.PropertyType.Handle.TypeData.ClassType = TBlobField then
        DBField := TBlobField.Create(System.TypeInfo(Variant))
      else
      if Prop.PropertyType.Handle.TypeData.ClassType = TMemoField then
        DBField := TMemoField.Create(System.TypeInfo(Variant))
      else
        (* If the property is not to be inherited from TDBField, do nothing. *)
        Continue;

      case Prop.PropertyType.TypeKind of
        tkClass:
        begin
          DBField.Parent := Self;
          DBField.Prop := Prop.Name;

          for Attribute in Prop.GetAttributes do
          begin

            (* PK *)
            if Attribute is PK then
            begin
              DBField.PK := True;
              DBField.PK.AutoIncrement := (Attribute as PK).AutoIncrement;
              Continue;
            end;

            (* FK *)
            if Attribute is FK then
            begin
              DBField.FK := True;
              DBField.FK.Entity := (Attribute as FK).Entity;
              Continue;
            end;

            (* Required *)
            if Attribute is Required then
            begin
              DBField.Required := True;
              Continue;
            end;

            (* FieldName *)
            if Attribute is FieldName then
            begin
              DBField.FieldName := (Attribute as FieldName).Name;
              Continue;
            end;

            (* Display *)
            if Attribute is Display then
            begin
              DBField.Display := (Attribute as Display).Value;
              Continue;
            end;

            (* Size *)
            if Attribute is Size then
            begin
              if Prop.PropertyType.Handle.TypeData.ClassType = TFloatField then
              begin
                TFloatField(DBField).Precision := (Attribute as Size).Value;
                TFloatField(DBField).Decimal := (Attribute as Size).Decimal;
              end
              else
              if Prop.PropertyType.Handle.TypeData.ClassType = TCurrencyField then
              begin
                TCurrencyField(DBField).Precision := (Attribute as Size).Value;
                TCurrencyField(DBField).Decimal := (Attribute as Size).Decimal;
              end
              else
              if Prop.PropertyType.Handle.TypeData.ClassType = TStringField then
                TStringField(DBField).Size := (Attribute as Size).Value;

              Continue;
            end;

          end;
        end;
        (* If the property is not of type TClass, do nothing. *)
        else Continue;
      end;

      (* The property of type TDBField receives the value of TValue containing all attributes registered in the entity. *)
      TValue.Make(@DBField, Prop.PropertyType.Handle, Value);
      Prop.SetValue(Self, Value);
    end;
  finally
    Context.Free;
  end;
end;

procedure TEntity.DestroyForeignEntities;
var
  Value: TValue;
  Context: TRttiContext;
  Obj, O: TRttiType;
  Prop: TRttiProperty;
  Entity: TEntity;
begin
  Context := TRttiContext.Create;

  try
    Obj := Context.GetType(Self.ClassInfo);

    (* Reading all entity properties where they are inherited from TDBField. *)
    for Prop in Obj.GetProperties do
    begin
      Value := Prop.GetValue(Self);
      if not TEntity.IsEntity(Value) then Continue;

      (* This is to check if the entity has already been created via Search. *)
      Value.ExtractRawData(@Entity);
      if Entity = nil then Continue;

      (* Destroy FK object. *)
      O := Context.GetType(Value.TypeInfo);
      InvokeMethod(imDestroy, O, Value, []);
    end;
  finally
    Context.Free;
  end;
end;

function TEntity.InvokeMethod(const InvokedMethod: TInvokedMethods; RttiType: TRttiType; Instance: TValue; const Args: array of TValue): TValue;
var
  Found: Boolean;
  Method: TRttiMethod;
  MethodName: string;
  I: Integer;
  Parameters: TArray<TRttiParameter>;
begin
  Result := nil;
  Method := nil;
  Found := False;

  case InvokedMethod of
    imCreate: MethodName := 'Create';
    imDestroy: MethodName := 'Destroy';
    imSearch: MethodName := 'Search';
  end;

  (* It is necessary to read each method because there may be methods with the same name (overload) but that is not exactly what we are trying to execute.
       Therefore, it is also necessary to compare all the parameters informed with the parameters of the localized method. *)
  for Method in RttiType.GetMethods do
    if SameText(Method.Name, MethodName) then
    begin
      Parameters := Method.GetParameters;

      if Length(Args) = Length(Parameters) then
      begin
        Found := True;

        (* Here I compare the parameters informed with the parameters of the localized method. *)
        for I := 0 to Length(Parameters)-1 do
          if Parameters[I].ParamType.Handle <> Args[I].TypeInfo then
          begin
            Found := False;
            Break;
          end;
      end;

      if Found then Break;
    end;

  if (Method <> nil) and Found then
    Result := Method.Invoke(Instance, Args);
end;

procedure TEntity.SetFieldValues(Database: TDatabase; BringForeignEntity: Boolean = False);
var
  Value, FKValue, ValueInstance, V: TValue;
  Context: TRttiContext;
  Obj, O, FKObject: TRttiType;
  Prop, FKProperty: TRttiProperty;
  Instance: TRttiInstanceType;

  PKFields: TDBFields;

  DBField, FKField: TDBField;
  Entity: TEntity;

  Atributo: TCustomAttribute;
  AtributoCampoFK: string;
begin
  Context := TRttiContext.Create;

  try
    Obj := Context.GetType(Self.ClassInfo);

    (* Reading all entity properties where they are inherited from TDBField. *)
    for Prop in Obj.GetProperties do
    begin
      Value := Prop.GetValue(Self);
      if not TDBField.IsField(Value) then Continue;
      Value.ExtractRawData(@DBField);

      (* I check if the parameter field exists in the DB. *)
      if Database.Query.FindField(DBField.FieldName) = nil then Continue;

      (* I read each field returned from the database and add the value to the respective property. *)
      DBField.Value := Database.Query.FieldByName(DBField.FieldName).Value;

      TValue.Make(@DBField, Prop.PropertyType.Handle, Value);
    end;

    (* In case the search is just to bring some data, not needing to search the FK tables. *)
    if not BringForeignEntity then Exit;

    (* From here I check if the entity has any field with foreign key.
         The system automatically reads these FK fields, creates the objects and searches in the DB. *)

    PKFields := GetForeignKeyField;

    if PKFields = nil then Exit;

    (* Reading of all entity properties where they are inherited from TEntity. *)
    for Prop in Obj.GetProperties do
    begin
      Value := Prop.GetValue(Self);
      if not TEntity.IsEntity(Value) then Continue;

      for Atributo in Prop.GetAttributes do
      begin
        if Atributo is FK then
        begin
          AtributoCampoFK := (Atributo as FK).FieldName;
        end;
      end;

      O := Context.GetType(Value.TypeInfo);

      if O = nil then Continue;

      (* Instance and create the FK object. *)
      Instance := O.AsInstance;
      ValueInstance := InvokeMethod(imCreate, Instance, Instance.MetaclassType, []);

      (* Basically, the routine below sets the value of the FKs of the current entity to the PKs of each dynamically created FK object. *)
      FKObject := Context.GetType(ValueInstance.AsObject.ClassInfo);
      for FKProperty in FKObject.GetProperties do
      begin
        FKValue := FKProperty.GetValue(ValueInstance.AsObject);
        if not TDBField.IsPK(FKValue) then Continue;
        FKValue.ExtractRawData(@FKField);

        for V in PKFields do
        begin
          V.ExtractRawData(@DBField);
          if (FKField.Parent.ClassType = DBField.FK.Entity) and (SameText(DBField.FieldName, AtributoCampoFK)) then
          begin
            FKField.Value := DBField.Value;
            Break;
          end;
        end;
      end;

      (* I invoke the FK object's Search method. *)
      InvokeMethod(imSearch, Instance, ValueInstance, [Database.Connection, BringForeignEntity]);

      ValueInstance.ExtractRawData(@Entity);
      TValue.Make(@Entity, Prop.PropertyType.Handle, Value);
      Prop.SetValue(Self, Value);
    end;

  finally
    Context.Free;
  end;
end;

end.
