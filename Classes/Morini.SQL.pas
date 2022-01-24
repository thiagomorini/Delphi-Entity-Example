{*******************************************************}
{                                                       }
{ Classes responsible for facilitating the generation   }
{   of SQL commands. Executes the four basic commands:  }
{   SELECT, INSERT, UPDATE and DELETE.                  }
{                                                       }
{*******************************************************}

{*******************************************************}
{         Created by Thiago R. Morini - 10/2018         }
{*******************************************************}

unit Morini.SQL;

interface

uses
  System.SysUtils, System.StrUtils, System.Rtti, System.TypInfo, Generics.Collections, System.Variants, Morini.Entity, Morini.DBField;

type
  TOrigin = (orSelect, orUpdate, orDelete);
  TJoinType = (jnJoin, jnLeftJoin, jnRightJoin);

  TEntityAndAlias = record
    Entity: TEntity;
    Alias: string;
  end;

  TJoinEntity = record
    Jointype: TJoinType;
    Entity: TEntityAndAlias;
    ListOfConditions: TListOfConditions;
  end;

  TJoinEntities = TList<TJoinEntity>;

  Func = class
  private
    class function SetFunction(FunctionOperator: TFunctionOperator; DBField: TDBField; Value: Variant): TFunction;
  public
    class function Sum(DBField: TDBField): TValue;
    class function Min(DBField: TDBField): TValue;
    class function Max(DBField: TDBField): TValue;
    class function Count(DBField: TDBField): TValue;
    class function GetDate: TValue;
    class function IsNull(DBField: TDBField; Value: Variant): TValue;
    class function Coalesce(DBField: TDBField; Value: Variant): TValue;
  end;

  TSelect = class;
  TFrom = class;

  TGroupBy = class
  private
    FDBFields: TDBFields;
    FFrom: TFrom;
  public
    constructor Create(From: TFrom; DBFields: TDBFields);
    function ToText: string;
  end;

  TOrderBy = class
  private
    FDBFields: TDBFields;
    FFrom: TFrom;
  public
    constructor Create(From: TFrom; DBFields: TDBFields);
    function GroupBy(const DBFields: TDBFields): TGroupBy;
    function ToText: string;
  end;

  TWhere = class
  private
    FOrigin: TOrigin;
    FFrom: TFrom;
    FListOfConditions: TListOfConditions;
    FListOfConditionsOr: array of TListOfConditions;
  public
    constructor Create(From: TFrom; Origem: TOrigin);
    destructor Destroy; override;
    function Or_(Conditions: array of TCondition): TWhere;
    function OrderBy(const DBFields: TDBFields): TOrderBy;
    function GroupBy(const DBFields: TDBFields): TGroupBy;
    function ToText: string;
  end;

  TJoin = class
  private
    FJoin: TJoinEntity;
    FFrom: TFrom;
  public
    constructor Create(JoinType: TJoinType; Entity: TEntity; From: TFrom);
    function As_(Alias: string): TJoin;
    function On_(Conditions: array of TCondition): TFrom;
  end;

  TFrom = class
  private
    FEntityAndAlias: TEntityAndAlias;
    FSelect: TSelect;
    FJoins: TJoinEntities;
    FWhere: TWhere;
    FOrderBy: TOrderBy;
    FGroupBy: TGroupBy;
  public
    constructor Create(Entity: TEntity; Select: TSelect);
    destructor Destroy; override;
    function As_(Alias: string): TFrom;
    function Join(Entity: TEntity): TJoin;
    function LeftJoin(Entity: TEntity): TJoin;
    function RightJoin(Entity: TEntity): TJoin;
    function Where(Conditions: array of TCondition): TWhere;
    function OrderBy(const DBFields: TDBFields): TOrderBy;
    function GroupBy(const DBFields: TDBFields): TGroupBy;
    function ToText: string;
  end;

  TSelect = class
  private
    FDBFields: TDBFields;
    FTop: Integer;
    FDistinct: Boolean;
  public
    constructor Create(const DBFields: TDBFields);
    function Top(Top: Integer): TSelect;
    function Distinct: TSelect;
    function From(Entity: TEntity): TFrom;
  end;

  TInsert = class
  private
    FEntity: TEntity;
    FDBFields: TDBFields;
  public
    constructor Create(Entity: TEntity);
    function Values(const DBFields: TDBFields): TInsert;
    function ToText: string;
  end;

  TUpdate = class
  private
    FEntity: TEntity;
    FDBFields: TDBFields;
  public
    constructor Create(Entity: TEntity);
    function Set_(const DBFields: TDBFields): TUpdate;
    function Where(Conditions: array of TCondition): TWhere;
    function ToText: string;
  end;

  TDelete = class
  private
    FEntity: TEntity;
  public
    constructor Create(Entity: TEntity);
    function Where(Conditions: array of TCondition): TWhere;
    function ToText: string;
  end;

  TSQL = class
  public
    function Select(const DBFields: TDBFields): TSelect; overload;
    function Select: TSelect; overload;
    function Insert(Entity: TEntity): TInsert;
    function Update(Entity: TEntity): TUpdate;
    function Delete(Entity: TEntity): TDelete;
  end;

  TSQLBuilder = class
  private
    FFrom: TFrom;
    function CheckField(Parent: TObject; Field: string): string; overload;
    function FieldToString(Field: TValue): string; overload;
    function FieldToString(DBField: TDBField): string; overload;
    function ValueToString(TypeInfo: PTypeInfo; Value: Variant): string; overload;
    function ValueToString(DBField: TDBField; Value: Variant): string; overload;
    function ValueToString(DBField: TDBField): string; overload;
    function FieldOperatorToString(FieldOperator: TFieldOperator): string;
    function FunctionToString(Func: TFunction; WithAlias: Boolean): string;
    function MountWhere(Condition: TCondition): string;
  public
    constructor Create(From: TFrom);
    destructor Destroy; override;
    function SelectToString: string;
    function InsertToString: string;
    function UpdateToString: string;
    function DeleteToString: string;
    property From: TFrom read FFrom write FFrom;
  end;

implementation

{ TSQL }

function TSQL.Select(const DBFields: TDBFields): TSelect;
begin
  Result := TSelect.Create(DBFields);
end;

function TSQL.Select: TSelect;
begin
  Result := TSelect.Create([]);
end;

function TSQL.Insert(Entity: TEntity): TInsert;
begin
  Result := TInsert.Create(Entity);
end;

function TSQL.Update(Entity: TEntity): TUpdate;
begin
  Result := TUpdate.Create(Entity);
end;

function TSQL.Delete(Entity: TEntity): TDelete;
begin
  Result := TDelete.Create(Entity);
end;

{ TSelect }

constructor TSelect.Create(const DBFields: TDBFields);
begin
  FTop := 0;
  FDistinct := False;
  FDBFields := DBFields;
end;

function TSelect.Top(Top: Integer): TSelect;
begin
  FTop := Top;
  Result := Self;
end;

function TSelect.Distinct: TSelect;
begin
  FDistinct := True;
  Result := Self;
end;

function TSelect.From(Entity: TEntity): TFrom;
begin
  Result := TFrom.Create(Entity, Self);
end;

{ TInsert }

constructor TInsert.Create(Entity: TEntity);
begin
  FEntity := Entity;
end;

function TInsert.Values(const DBFields: TDBFields): TInsert;
begin
  FDBFields := DBFields;
  Result := Self;
end;

function TInsert.ToText: string;
var
  SQL: TSQLBuilder;
begin
  SQL := TSQLBuilder.Create(TFrom.Create(FEntity, TSelect.Create(FDBFields)));

  try
    Result := SQL.InsertToString;
  finally
    FreeAndNil(SQL);
  end;
end;

{ TUpdate }

constructor TUpdate.Create(Entity: TEntity);
begin
  FEntity := Entity;
end;

function TUpdate.Set_(const DBFields: TDBFields): TUpdate;
begin
  FDBFields := DBFields;
  Result := Self;
end;

function TUpdate.Where(Conditions: array of TCondition): TWhere;
var
  Condition: TCondition;
begin
  Result := TWhere.Create(TFrom.Create(FEntity, TSelect.Create(FDBFields)), orUpdate);

  for Condition in Conditions do
    Result.FListOfConditions.Add(Condition);
end;

function TUpdate.ToText: string;
var
  SQL: TSQLBuilder;
begin
  SQL := TSQLBuilder.Create(TFrom.Create(FEntity, TSelect.Create(FDBFields)));

  try
    Result := SQL.UpdateToString;
  finally
    FreeAndNil(SQL);
  end;
end;

{ TDelete }

constructor TDelete.Create(Entity: TEntity);
begin
  FEntity := Entity;
end;

function TDelete.Where(Conditions: array of TCondition): TWhere;
var
  Condition: TCondition;
begin
  Result := TWhere.Create(TFrom.Create(FEntity, TSelect.Create(nil)), orDelete);

  for Condition in Conditions do
    Result.FListOfConditions.Add(Condition);
end;

function TDelete.ToText: string;
var
  SQL: TSQLBuilder;
begin
  SQL := TSQLBuilder.Create(TFrom.Create(FEntity, TSelect.Create(nil)));

  try
    Result := SQL.DeleteToString;
  finally
    FreeAndNil(SQL);
  end;
end;

{ TFrom }

constructor TFrom.Create(Entity: TEntity; Select: TSelect);
begin
  FEntityAndAlias.Entity := Entity;
  FSelect := Select;
  FJoins := TJoinEntities.Create;
end;

destructor TFrom.Destroy;
begin
  if Assigned(FJoins) then
    FreeAndNil(FJoins);

  if Assigned(FSelect) then
    FreeAndNil(FSelect);

  if Assigned(FOrderBy) then
    FreeAndNil(FOrderBy);

  inherited;
end;

function TFrom.As_(Alias: string): TFrom;
begin
  FEntityAndAlias.Alias := Alias;
  Result := Self;
end;

function TFrom.Join(Entity: TEntity): TJoin;
begin
  Result := TJoin.Create(jnJoin, Entity, Self);
end;

function TFrom.LeftJoin(Entity: TEntity): TJoin;
begin
  Result := TJoin.Create(jnLeftJoin, Entity, Self);
end;

function TFrom.RightJoin(Entity: TEntity): TJoin;
begin
  Result := TJoin.Create(jnRightJoin, Entity, Self);
end;

function TFrom.Where(Conditions: array of TCondition): TWhere;
var
  Condition: TCondition;
begin
  Result := TWhere.Create(Self, orSelect);

  for Condition in Conditions do
    Result.FListOfConditions.Add(Condition);
end;

function TFrom.OrderBy(const DBFields: TDBFields): TOrderBy;
begin
  Result := TOrderBy.Create(Self, DBFields);
end;

function TFrom.GroupBy(const DBFields: TDBFields): TGroupBy;
begin
  Result := TGroupBy.Create(Self, DBFields);
end;

function TFrom.ToText: string;
var
  SQL: TSQLBuilder;
begin
  SQL := TSQLBuilder.Create(Self);

  try
    if FWhere = nil then
      Result := SQL.SelectToString
    else
    begin
      case FWhere.FOrigin of
        orSelect: Result := SQL.SelectToString;
        orUpdate: Result := SQL.UpdateToString;
        orDelete: Result := SQL.DeleteToString;
      end;
    end;
  finally
    FreeAndNil(SQL);
  end;
end;

{ TJoin }

constructor TJoin.Create(JoinType: TJoinType; Entity: TEntity;
  From: TFrom);
begin
  FJoin.JoinType := JoinType;
  FJoin.Entity.Entity := Entity;

  FFrom := From;
end;

function TJoin.As_(Alias: string): TJoin;
begin
  FJoin.Entity.Alias := Alias;
  Result := Self;
end;

function TJoin.On_(Conditions: array of TCondition): TFrom;
var
  EntityAndAlias: TEntityAndAlias;
  Condition: TCondition;
begin
  EntityAndAlias.Entity := FFrom.FEntityAndAlias.Entity;
  EntityAndAlias.Alias := FFrom.FEntityAndAlias.Alias;

  FJoin.ListOfConditions := TListOfConditions.Create;

  for Condition in Conditions do
    FJoin.ListOfConditions.Add(Condition);

  FFrom.FJoins.Add(FJoin);

  Result := FFrom;
end;

{ TWhere }

constructor TWhere.Create(From: TFrom; Origem: TOrigin);
begin
  FOrigin := Origem;
  FFrom := From;
  FListOfConditions := TListOfConditions.Create;

  SetLength(FListOfConditionsOr, 0);
end;

destructor TWhere.Destroy;
var
  I: Integer;
begin
  for I := Low(FListOfConditionsOr) to High(FListOfConditionsOr) do
  begin
    if Assigned(FListOfConditionsOr[I]) then
      FreeAndNil(FListOfConditionsOr[I]);
  end;

  if Assigned(FListOfConditions) then
    FreeAndNil(FListOfConditions);

  inherited;
end;

function TWhere.Or_(Conditions: array of TCondition): TWhere;
var
  Condition: TCondition;
begin
  SetLength(FListOfConditionsOr, Length(FListOfConditionsOr)+1);
  FListOfConditionsOr[Length(FListOfConditionsOr)-1] := TListOfConditions.Create;

  for Condition in Conditions do
    FListOfConditionsOr[Length(FListOfConditionsOr)-1].Add(Condition);

  Result := Self;
end;

function TWhere.OrderBy(const DBFields: TDBFields): TOrderBy;
begin
  FFrom.FWhere := Self;
  Result := TOrderBy.Create(FFrom, DBFields);
end;

function TWhere.GroupBy(const DBFields: TDBFields): TGroupBy;
begin
  FFrom.FWhere := Self;
  Result := TGroupBy.Create(FFrom, DBFields);
end;

function TWhere.ToText: string;
begin
  FFrom.FWhere := Self;
  Result := FFrom.ToText;
end;

{ TOrderBy }

constructor TOrderBy.Create(From: TFrom; DBFields: TDBFields);
begin
  FFrom := From;
  FDBFields := DBFields;
end;

function TOrderBy.GroupBy(const DBFields: TDBFields): TGroupBy;
begin
  FFrom.FOrderBy := Self;
  Result := TGroupBy.Create(FFrom, DBFields);
end;

function TOrderBy.ToText: string;
begin
  FFrom.FOrderBy := Self;
  Result := FFrom.ToText;
end;

{ TGroupBy }

constructor TGroupBy.Create(From: TFrom; DBFields: TDBFields);
begin
  FFrom := From;
  FDBFields := DBFields;
end;

function TGroupBy.ToText: string;
begin
  FFrom.FGroupBy := Self;
  Result := FFrom.ToText;
end;

{ TSQLBuilder }

constructor TSQLBuilder.Create(From: TFrom);
begin
  FFrom := From;
end;

destructor TSQLBuilder.Destroy;
begin
  if Assigned(FFrom) then
    FreeAndNil(FFRom);

  inherited;
end;

function TSQLBuilder.CheckField(Parent: TObject; Field: string): string;
var
  Join: TJoinEntity;
begin
  Result := '';

  if Parent = FFrom.FEntityAndAlias.Entity then
  begin
    if Trim(FFrom.FEntityAndAlias.Alias) <> '' then
      Result := FFrom.FEntityAndAlias.Alias + '.';

    Result := Result + Field;
  end
  else
  begin
    for Join in FFrom.FJoins.ToArray do
    begin
      if Parent = Join.Entity.Entity then
      begin
        if Trim(Join.Entity.Alias) <> '' then
          Result := Join.Entity.Alias + '.';

        Result := Result + Field;
      end;
    end;
  end;
end;

function TSQLBuilder.FieldToString(Field: TValue): string;
var
  Entity: TEntity;
  Join: TJoinEntity;
  DBField: TDBField;
  Func: TFunction;
begin
  Result := '';

  if Field.TypeInfo = nil then
  begin
    Result := ValueToString(Field.TypeInfo, Null);
    Exit;
  end;

  (* Fields and Entity *)
  if Field.TypeInfo.Kind = tkClass then
  begin
    (* Fields *)
    if TDBField.IsField(Field) then
    begin
      Field.ExtractRawData(@DBField);
      Result := CheckField(DBField.Parent, DBField.FieldName);
    end
    else

    (* Entity *)
    if TEntity.IsEntity(Field) then
    begin
      Field.ExtractRawData(@Entity);

      if Entity = FFrom.FEntityAndAlias.Entity then
        Result := FFrom.FEntityAndAlias.Alias + '.*'
      else
      begin
        for Join in FFrom.FJoins.ToArray do
        begin
          if Entity = Join.Entity.Entity then
            Result := Join.Entity.Alias + '.*';
        end;
      end;
    end;

  end
  else
  (* Functions *)
  if Field.TypeInfo.Kind = tkRecord then
  begin
    if Field.TypeInfo.Name = 'TFuncao' then
    begin
      Field.ExtractRawData(@Func);
      Result := FunctionToString(Func, True);
    end;
  end
  else
  begin
    (* Here are Delphi's native types. *)
    Result := ValueToString(Field.TypeInfo, Field.AsVariant);
  end;
end;

function TSQLBuilder.FieldToString(DBField: TDBField): string;
begin
  Result := CheckField(DBField.Parent, DBField.FieldName);
end;

function TSQLBuilder.ValueToString(TypeInfo: PTypeInfo;
  Value: Variant): string;

  function Round(Value: Extended): Extended;
  var
    cString: string[15];
  begin
    Str(Value: 15: 2, cString);
    cString[Pos('.', string(cString))] := AnsiChar(FormatSettings.DecimalSeparator);
    Result := StrToCurr(string(cString));
  end;

begin
  (* This function is responsible for receiving the type and value of the data
       and formatting it to the required format of the database. *)

  (* I can't get a native type TDateTime because it is Double, because of TValue's implicit typecast. *)

  if VarIsNull(Value) then
  begin
    Result := 'NULL';
    Exit;
  end;

  (* Native types *)
  if TypeInfo.Name = 'Variant' then
    Result := QuotedStr(Value)
  else
  if TypeInfo.Name = 'Integer' then
    Result := IntToStr(Value)
  else
  if TypeInfo.Name = 'string' then
    Result := QuotedStr(Value)
  else
  if (TypeInfo.Name = 'Double') or (TypeInfo.Name = 'Extended')  then
    Result := FloatToStr(Round(Value)).Replace('.', '').Replace(',', '.')
  else
  (* In SQL Server there is no Boolean type, so must use the BIT type that receives True or False normally. *)
  if TypeInfo.Name = 'Boolean' then
    Result := QuotedStr(Value)
  else
    Result := '';
end;

function TSQLBuilder.ValueToString(DBField: TDBField; Value: Variant): string;

  function Round(Value: Extended; Precision, Decimal: Integer): Extended;
  var
    cString: string[15];
  begin
    Str(Value: Precision: Decimal, cString);
    cString[Pos('.', string(cString))] := AnsiChar(FormatSettings.DecimalSeparator);
    Result := StrToCurr(string(cString));
  end;

begin
  (* This function is responsible for receiving the type and value of the data
       and formatting it to the required format of the database. *)

  if VarIsNull(Value) then
  begin
    Result := 'NULL';
    Exit;
  end;

  (* Types of TDBField *)
  if DBField.ClassType = TVariantField then
    Result := QuotedStr(Value)
  else
  if DBField.ClassType = TIntegerField then
    Result := IntToStr(Value)
  else
  if DBField.ClassType = TStringField then
    Result := QuotedStr(Value)
  else
  if DBField.ClassType = TDateTimeField then
    Result := QuotedStr(Value)
  else
  if (DBField.ClassType = TFloatField) or (DBField.ClassType = TCurrencyField) then
    Result := FloatToStr(Round(Value, TFloatField(DBField).Precision, TFloatField(DBField).Decimal)).Replace('.', '').Replace(',', '.')
  else
  (* In SQL Server there is no Boolean type, so must use the BIT type that receives True or False normally. *)
  if DBField.ClassType = TBooleanField then
    Result := QuotedStr(Value)
  else
  if (DBField.ClassType = TBlobField) then
    Result := Value
  else
  if (DBField.ClassType = TMemoField) then
    Result := QuotedStr(Value)
  else
    Result := '';
end;

function TSQLBuilder.ValueToString(DBField: TDBField): string;
begin
  Result := ValueToString(DBField, DBField.Value);
end;

function TSQLBuilder.FieldOperatorToString(
  FieldOperator: TFieldOperator): string;
begin
  case FieldOperator of
    fiIsNull: Result := 'IS ';
    fiEqual: Result := '=';
    fiNotEqual: Result := '<>';
    fiGreaterThan: Result := '>';
    fiGreaterThanOrEqual: Result := '>=';
    fiLessThan: Result := '<';
    fiLessThanOrEqual: Result := '<=';
    fiBetween: Result := 'BETWEEN';
    fiLike: Result := 'LIKE';
  end;
end;

function TSQLBuilder.FunctionToString(Func: TFunction; WithAlias: Boolean): string;
var
  Field: string;
begin
  (*
      If the WithAlias parameter is true, the function field will be renamed like this:
        <FUNCTION>_<FIELD_NAME_WITHOUT_ALIAS>

        For example:
          SUM_ID_CITY
  *)

  if Func.DBField <> nil then
    Field := CheckField(Func.DBField.Parent, Func.DBField.FieldName);

  case Func.FunctionOperator of
    fuSum: Result := 'SUM(' + Field + ')' + IfThen(WithAlias, ' AS SUM_' + Func.DBField.FieldName, '');
    fuMin: Result := 'MIN(' + Field + ')' + IfThen(WithAlias, ' AS MIN_' + Func.DBField.FieldName, '');
    fuMax: Result := 'MAX(' + Field + ')' + IfThen(WithAlias, ' AS MAX_' + Func.DBField.FieldName, '');
    fuCount: Result := 'COUNT(' + Field + ')' + IfThen(WithAlias, ' AS COUNT_' + Func.DBField.FieldName, '');
    fuGetDate: Result := 'GETDATE()' + IfThen(WithAlias, ' AS GETDATE', '');
    fuIsNull: Result := 'ISNULL(' + Field + ', ' + ValueToString(Func.DBField, Func.Value) + ')' + IfThen(WithAlias, ' AS ISNULL_' + Func.DBField.FieldName, '');
    fuCoalesce: Result := 'COALESCE(' + Field + ', ' + ValueToString(Func.DBField, Func.Value) + ')' + IfThen(WithAlias, ' AS COALESCE_' + Func.DBField.FieldName, '');
  end;
end;

function TSQLBuilder.MountWhere(Condition: TCondition): string;
begin
  Result := '';

  (* Field (with alias if there is) and operator, for example 'NAME = ' ou 'A.NAME = ' *)
  Result := Result + FieldToString(Condition.TargetDBField) + ' ' + FieldOperatorToString(Condition.FieldOperador) + ' ';

  (* If it's a TDBField *)
  if Condition.DBField1 <> nil then
    Result := Result + FieldToString(Condition.DBField1)
  else
  (* If it's a function *)
  if Condition.Function1.FunctionOperator <> fuNull then
    Result := Result + FunctionToString(Condition.Function1, False)
  else
    (* If it's any value *)
    Result := Result + ValueToString(Condition.TargetDBField, Condition.Value1);

  (* Specific for between, where we need the second TValue. *)

  (* If it's a TDBField *)
  if Condition.DBField2 <> nil then
    Result := Result + ' AND ' + FieldToString(Condition.DBField2)
  else
  (* If it's a function *)
  if Condition.Function2.FunctionOperator <> fuNull then
    Result := Result + ' AND ' +  FunctionToString(Condition.Function2, False)
  else
  (* If it's any value *)
  if Condition.Value2 <> Null then
    Result := Result + ' AND ' + ValueToString(Condition.TargetDBField, Condition.Value2);

  Result := Result + ' AND ';
end;

function TSQLBuilder.SelectToString: string;
var
  Command: TStringBuilder;
  Line: string;

  Field: TValue;
  Join: TJoinEntity;
  Condition: TCondition;
  DBField: TDBField;
  Func: TFunction;

  I: Integer;
begin
  Command := TStringBuilder.Create;

  try
    Command.Clear;

    (* SELECT block *)
    Line := '';

    Line := Line + ' SELECT';

    if FFrom.FSelect.FDistinct then
      Line := Line + ' DISTINCT';

    if FFrom.FSelect.FTop > 0 then
      Line := Line + ' TOP ' + FFrom.FSelect.FTop.ToString;

    Command.Append(Line);

    (* Fields block *)
    Line := ' ';

    if Length(FFrom.FSelect.FDBFields) > 0 then
    begin
      for Field in FFrom.FSelect.FDBFields do
        Line := Line + FieldToString(Field) + ', ';

      Line := Copy(Line, 1, Length(Line)-2);
    end
    else
    begin
      if Trim(FFrom.FEntityAndAlias.Alias) <> '' then
        Line := Line + FFrom.FEntityAndAlias.Alias + '.*'
      else
        Line := Line + '*';
    end;

    Command.Append(Line);

    (* FROM block *)

    Line := ' FROM ' + FFrom.FEntityAndAlias.Entity.GetTableName;

    if Trim(FFrom.FEntityAndAlias.Alias) <> '' then
      Line := Line + ' ' + FFrom.FEntityAndAlias.Alias;

    Command.Append(Line);

    (* JOIN block *)

    for Join in FFrom.FJoins.ToArray do
    begin
      Line := '';

      case Join.Jointype of
        jnJoin: Line := Line + ' JOIN ';
        jnLeftJoin: Line := Line + ' LEFT JOIN ';
        jnRightJoin: Line := Line + ' RIGHT JOIN ';
      end;

      Line := Line + Join.Entity.Entity.GetTableName;
      if Trim(FFrom.FEntityAndAlias.Alias) <> '' then
        Line := Line + ' ' + Join.Entity.Alias;

      Line := Line + ' ON (';

      for Condition in Join.ListOfConditions.ToArray do
      begin
        Line := Line + FieldToString(Condition.TargetDBField) + ' ' + FieldOperatorToString(Condition.FieldOperador) + ' ';

        if Condition.DBField1 <> nil then
          Line := Line + FieldToString(Condition.DBField1)
        else
          Line := Line + ValueToString(Condition.TargetDBField, Condition.Value1);

        Line := Line + ' AND ';
      end;

      Line := Copy(Line, 1, Length(Line)-5);
      Line := Line +')';

      Command.Append(Line);
    end;

    (* WHERE block *)

    if FFrom.FWhere <> nil then
    begin
      Command.Append(' WHERE ');

      Line := '';

      for Condition in FFrom.FWhere.FListOfConditions.ToArray do
        Line := Line + MountWhere(Condition);

      Line := Copy(Line, 1, Length(Line)-5);
      Command.Append(Line);

      (* OR block *)

      for I := Low(FFrom.FWhere.FListOfConditionsOr) to High(FFrom.FWhere.FListOfConditionsOr) do
      begin
        Command.Append(' OR (');

        Line := '';

        for Condition in FFrom.FWhere.FListOfConditionsOr[I].ToArray do
          Line := Line + MountWhere(Condition);

        Line := Copy(Line, 1, Length(Line)-5);
        Line := Line + ')';

        Command.Append(Line);
      end;
    end;

    (* ORDER BY block *)

    if FFrom.FOrderBy <> nil then
    begin
      Command.Append(' ORDER BY ');

      Line := '';

      for Field in FFrom.FOrderBy.FDBFields do
        (* Normal TDBField *)
        if TDBField.IsField(Field) then
        begin
          Field.ExtractRawData(@DBField);
          Line := Line + FieldToString(Field) + ', ';
        end
        else
        (* TDBField function for Descending sort *)
        if Field.TypeInfo.Name = 'TFuncao' then
        begin
          Field.ExtractRawData(@Func);
          if Func.FunctionOperator = fuDesc then
            Line := Line + FieldToString(Func.DBField) + ' DESC, ';
        end;

      Line := Copy(Line, 1, Length(Line)-2);

      Command.Append(Line);
    end;

    (* GROUP BY block *)

    if FFrom.FGroupBy <> nil then
    begin
      Command.Append(' GROUP BY ');

      Line := '';

      for Field in FFrom.FGroupBy.FDBFields do
        if TDBField.IsField(Field) then
        begin
          Field.ExtractRawData(@DBField);
          Line := Line + FieldToString(Field) + ', ';
        end;

      Line := Copy(Line, 1, Length(Line)-2);

      Command.Append(Line);
    end;

    (* Ending *)
    Result := Command.ToString;
  finally
    FreeAndNil(Command);
  end;
end;

function TSQLBuilder.InsertToString: string;
var
  Command: TStringBuilder;
  Line: string;

  Field: TValue;
  Context: TRttiContext;
  Obj: TRttiType;
  Prop: TRttiProperty;
  DBField: TDBField;
begin
  (* Checking if the required fields are filled in. *)
  FFrom.FEntityAndAlias.Entity.CheckFilling(acInsert, FFrom.FSelect.FDBFields);

  Command := TStringBuilder.Create;

  try
    Command.Clear;

    (* INSERT INTO block *)
    Line := '';

    Line := Line + ' INSERT INTO ' + FFrom.FEntityAndAlias.Entity.GetTableName;

    Command.Append(Line);

    (* Fields block *)
    Line := '';

    if Length(FFrom.FSelect.FDBFields) > 0 then
    begin
      Line := Line + ' (';

      for Field in FFrom.FSelect.FDBFields do
        if TDBField.IsField(Field) then
        begin
          Field.ExtractRawData(@DBField);
          if DBField.Parent = FFrom.FEntityAndAlias.Entity then
            Line := Line + FieldToString(Field) + ', ';
        end;

      Line := Copy(Line, 1, Length(Line)-2);

      Line := Line + ')';

      Command.Append(Line);
    end
    else
    begin
      Context := TRttiContext.Create;

      try
        Line := Line + ' (';
        Obj := Context.GetType(FFrom.FEntityAndAlias.Entity.ClassInfo);

        for Prop in Obj.GetProperties do
        begin
          Field := Prop.GetValue(FFrom.FEntityAndAlias.Entity);
          if (TDBField.IsField(Field)) and not TDBField.IsAutoIncrement(Field) then
            Line := Line + FieldToString(Field) + ', ';
        end;
        Line := Copy(Line, 1, Length(Line)-2);
        Line := Line + ')';
        Command.Append(Line);
      finally
        Context.Free;
      end;
    end;


    (* VALUES block *)
    Line := ' VALUES (';

    if Length(FFrom.FSelect.FDBFields) > 0 then
    begin
      for Field in FFrom.FSelect.FDBFields do
        if TDBField.IsField(Field) then
        begin
          Field.ExtractRawData(@DBField);
          if DBField.Parent = FFrom.FEntityAndAlias.Entity then
            Line := Line + ValueToString(DBField) + ', ';
        end;
    end
    else
    begin
      Context := TRttiContext.Create;

      try
        Obj := Context.GetType(FFrom.FEntityAndAlias.Entity.ClassInfo);

        for Prop in Obj.GetProperties do
        begin
          Field := Prop.GetValue(FFrom.FEntityAndAlias.Entity);
          if (TDBField.IsField(Field)) and not TDBField.IsAutoIncrement(Field) then
          begin
            Field.ExtractRawData(@DBField);
            Line := Line + ValueToString(DBField) + ', ';
          end;
        end;
      finally
        Context.Free;
      end;
    end;

    Line := Copy(Line, 1, Length(Line)-2);
    Line := Line + ')';

    Command.Append(Line);

    Result := Command.ToString;
  finally
    FreeAndNil(Command);
  end;
end;

function TSQLBuilder.UpdateToString: string;
var
  Command: TStringBuilder;
  Line: string;

  Condition: TCondition;

  Field: TValue;
  Context: TRttiContext;
  Obj: TRttiType;
  Prop: TRttiProperty;

  DBField: TDBField;
begin
  (* Checking if the required fields are filled in. *)
  FFrom.FEntityAndAlias.Entity.CheckFilling(acUpdate, FFrom.FSelect.FDBFields);

  Command := TStringBuilder.Create;

  try
    Command.Clear;

    (* UPDATE block *)
    Line := '';

    Line := Line + ' UPDATE ' + FFrom.FEntityAndAlias.Entity.GetTableName;

    Command.Append(Line);

    (* SET block *)
    Line := ' SET ';

    if Length(FFrom.FSelect.FDBFields) > 0 then
    begin
      for Field in FFrom.FSelect.FDBFields do
      begin
        if (TDBField.IsField(Field)) and not (TDBField.IsPK(Field)) then
        begin
          Field.ExtractRawData(@DBField);
          if DBField.Parent = FFrom.FEntityAndAlias.Entity then
          begin
            Line := Line + FieldToString(Field) + ' ' + FieldOperatorToString(fiEqual) + ' ';
            Line := Line + ValueToString(DBField) + ', ';
          end;
        end;
      end;
    end
    else
    begin
      Context := TRttiContext.Create;

      try
        Obj := Context.GetType(FFrom.FEntityAndAlias.Entity.ClassInfo);

        for Prop in Obj.GetProperties do
        begin
          Field := Prop.GetValue(FFrom.FEntityAndAlias.Entity);

          if (TDBField.IsField(Field)) and not (TDBField.IsPK(Field)) then
          begin
            Field.ExtractRawData(@DBField);
            Line := Line + FieldToString(Field) + ' ' + FieldOperatorToString(fiEqual) + ' ';
            Line := Line + ValueToString(DBField) + ', ';
          end;
        end;
      finally
        Context.Free;
      end;
    end;

    Line := Copy(Line, 1, Length(Line)-2);
    Command.Append(Line);

    (* WHERE block *)

    Command.Append(' WHERE ');

    Line := '';

    if FFrom.FWhere <> nil then
    begin
      for Condition in FFrom.FWhere.FListOfConditions.ToArray do
        Line := Line + MountWhere(Condition);
    end
    else
    begin
      Context := TRttiContext.Create;

      try
        Obj := Context.GetType(FFrom.FEntityAndAlias.Entity.ClassInfo);

        for Prop in Obj.GetProperties do
        begin
          Field := Prop.GetValue(FFrom.FEntityAndAlias.Entity);

          if (TDBField.IsField(Field)) and (TDBField.IsPK(Field)) then
          begin
            Field.ExtractRawData(@DBField);
            Line := Line + FieldToString(Field) + ' ' + FieldOperatorToString(fiEqual) + ' ';
            Line := Line + ValueToString(DBField);

            Line := Line + ' AND ';
          end;
        end;
      finally
        Context.Free;
      end;
    end;

    Line := Copy(Line, 1, Length(Line)-5);
    Command.Append(Line);

    Result := Command.ToString;
  finally
    FreeAndNil(Command);
  end;
end;

function TSQLBuilder.DeleteToString: string;
var
  Command: TStringBuilder;
  Line: string;

  Condition: TCondition;

  Field: TValue;
  Context: TRttiContext;
  Obj: TRttiType;
  Prop: TRttiProperty;

  DBField: TDBField;
begin
  (* Checking if the required fields are filled in. *)
  FFrom.FEntityAndAlias.Entity.CheckFilling(acDelete, []);

  Command := TStringBuilder.Create;

  try
    Command.Clear;

    (* DELETE FROM block *)
    Line := '';

    Line := Line + ' DELETE FROM ' + FFrom.FEntityAndAlias.Entity.GetTableName;

    Command.Append(Line);

    (* WHERE block *)

    Command.Append(' WHERE ');

    Line := '';

    if FFrom.FWhere <> nil then
    begin
      for Condition in FFrom.FWhere.FListOfConditions.ToArray do
        Line := Line + MountWhere(Condition);
    end
    else
    begin
      Context := TRttiContext.Create;

      try
        Obj := Context.GetType(FFrom.FEntityAndAlias.Entity.ClassInfo);

        for Prop in Obj.GetProperties do
        begin
          Field := Prop.GetValue(FFrom.FEntityAndAlias.Entity);

          if (TDBField.IsField(Field)) and (TDBField.IsPK(Field)) then
          begin
            Field.ExtractRawData(@DBField);
            Line := Line + FieldToString(Field) + ' ' + FieldOperatorToString(fiEqual) + ' ';
            Line := Line + ValueToString(DBField);

            Line := Line + ' AND ';
          end;
        end;
      finally
        Context.Free;
      end;
    end;

    Line := Copy(Line, 1, Length(Line)-5);
    Command.Append(Line);

    Result := Command.ToString;
  finally
    FreeAndNil(Command);
  end;
end;

{ Func }

class function Func.SetFunction(FunctionOperator: TFunctionOperator; DBField: TDBField;
  Value: Variant): TFunction;
begin
  Result.FunctionOperator := FunctionOperator;
  Result.DBField := DBField;
  Result.Value := Value;
end;

class function Func.Sum(DBField: TDBField): TValue;
begin
  Result := TValue.From<TFunction>(SetFunction(fuSum, DBField, Null));
end;

class function Func.Min(DBField: TDBField): TValue;
begin
  Result := TValue.From<TFunction>(SetFunction(fuMin, DBField, Null));
end;

class function Func.Max(DBField: TDBField): TValue;
begin
  Result := TValue.From<TFunction>(SetFunction(fuMax, DBField, Null));
end;

class function Func.Count(DBField: TDBField): TValue;
begin
  Result := TValue.From<TFunction>(SetFunction(fuCount, DBField, Null));
end;

class function Func.GetDate: TValue;
begin
  (* GETDATE() doesn't need a TDBField. *)
  Result := TValue.From<TFunction>(SetFunction(fuGetDate, nil, Null));
end;

class function Func.IsNull(DBField: TDBField; Value: Variant): TValue;
begin
  (* ISNULL needs a value. *)
  Result := TValue.From<TFunction>(SetFunction(fuIsNull, DBField, Value));
end;

class function Func.Coalesce(DBField: TDBField; Value: Variant): TValue;
begin
  (* COALESCE needs a value. *)
  Result := TValue.From<TFunction>(SetFunction(fuCoalesce, DBField, Value));
end;

end.
