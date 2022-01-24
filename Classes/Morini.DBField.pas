{*******************************************************}
{                                                       }
{ TDBField is the base class for all fields of each     }
{   specific type. The fields store the data coming     }
{   from the attributes of each property of the         }
{   entities, being a mirror for each field of the DB.  }
{                                                       }
{*******************************************************}

{*******************************************************}
{         Created by Thiago R. Morini - 10/2018         }
{*******************************************************}

unit Morini.DBField;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.TypInfo, Generics.Collections, System.Variants, Vcl.Imaging.jpeg, Morini.Exception;

resourcestring
  SErrorConvertingData = 'An error occurred while converting data';

type
  TDBField = class;

  TFieldOperator = (fiNull, fiEqual, fiNotEqual, fiGreaterThan, fiGreaterThanOrEqual, fiLessThan, fiLessThanOrEqual, fiBetween, fiDesc, fiLike, fiIsNull);
  TFunctionOperator = (fuNull, fuSum, fuMin, fuMax, fuCount, fuGetDate, fuIsNull, fuCoalesce, fuDesc);

  TPK = record
  private
    FAutoIncrement: Boolean;
    FValue: Boolean;
    function GetAutoIncrement: Boolean;
    procedure SetAutoIncrement(Value: Boolean);
  public
    class operator Implicit(Value: Boolean): TPK;
    class operator Implicit(Value: TPK): Boolean;
    class operator Equal(a: TPK; b: TPK): Boolean;
    class operator NotEqual(a: TPK; b: TPK): Boolean;
    class operator GreaterThan(a: TPK; b: TPK): Boolean;
    class operator GreaterThanOrEqual(a: TPK; b: TPK): Boolean;
    class operator LessThan(a: TPK; b: TPK): Boolean;
    class operator LessThanOrEqual(a: TPK; b: TPK): Boolean;
    property AutoIncrement: Boolean read GetAutoIncrement write SetAutoIncrement;
    property Value: Boolean read FValue write FValue;
  end;

  TFK = record
  private
    FEntity: TClass;
    FValue: Boolean;
    function GetEntity: TClass;
    procedure SetEntity(Value: TClass);
  public
    class operator Implicit(Value: Boolean): TFK;
    class operator Implicit(Value: TFK): Boolean;
    class operator Equal(a: TFK; b: TFK): Boolean;
    class operator NotEqual(a: TFK; b: TFK): Boolean;
    class operator GreaterThan(a: TFK; b: TFK): Boolean;
    class operator GreaterThanOrEqual(a: TFK; b: TFK): Boolean;
    class operator LessThan(a: TFK; b: TFK): Boolean;
    class operator LessThanOrEqual(a: TFK; b: TFK): Boolean;
    property Entity: TClass read GetEntity write SetEntity;
    property Value: Boolean read FValue write FValue;
  end;

  TFunction = record
    FunctionOperator: TFunctionOperator;
    DBField: TDBField;
    Value: Variant;
  end;

  TCondition = record
    FieldOperador: TFieldOperator;
    TargetDBField: TDBField;
    DBField1: TDBField;
    Value1: Variant;
    Function1: TFunction;
    DBField2: TDBField;
    Value2: Variant;
    Function2: TFunction;
  end;

  TListOfConditions = TList<TCondition>;
  TDBFields = array of TValue;

  TDBValue = record
  public
    Value: Variant;
    class operator Implicit(Value: Variant): TDBValue;
    class operator Implicit(Value: TDBValue): Variant;
    class operator Equal(a: TDBValue; b: TDBValue): Boolean;
    class operator NotEqual(a: TDBValue; b: TDBValue): Boolean;
    class operator GreaterThan(a: TDBValue; b: TDBValue): Boolean;
    class operator GreaterThanOrEqual(a: TDBValue; b: TDBValue): Boolean;
    class operator LessThan(a: TDBValue; b: TDBValue): Boolean;
    class operator LessThanOrEqual(a: TDBValue; b: TDBValue): Boolean;
  end;

  TEditMask = type string;

  IDBField = Interface
  ['{DA153DB5-CDA1-4C83-B74A-ED40BFF07003}']
    function GetValue: TDBValue; stdCall;
    function GetType: PTypeInfo; stdCall;
    function GetParent: TObject; stdCall;
    function GetProperty: string; stdCall;
    function GetRequired: Boolean; stdCall;
    function GetFieldName: string; stdCall;
    function GetDisplay: string; stdCall;
    function GetHasValue: Boolean; stdCall;
    function GetEditMask: TEditMask; stdCall;
    procedure SetValue(Value: TDBValue); stdCall;
    procedure SetType(Value: PTypeInfo); stdCall;
    procedure SetParent(Value: TObject); stdCall;
    procedure SetProperty(Value: string); stdCall;
    procedure SetRequired(Value: Boolean); stdCall;
    procedure SetFieldName(Value: string); stdCall;
    procedure SetDisplay(Value: string); stdCall;
    procedure SetEditMask(Value: TEditMask); stdCall;

    function SetCondition(Value1, Value2: TValue; LogicalOperator: TFieldOperator): TCondition; stdCall;
    procedure Clear; stdCall;

    function IsPK: Boolean; overload; stdCall;
    function IsFK: Boolean; overload; stdCall;
    function IsAutoIncrement: Boolean; overload; stdCall;
    function IsRequired: Boolean; overload; stdCall;

    property Value: TDBValue read GetValue write SetValue;
    property PType: PTypeInfo read GetType write SetType;
    property Parent: TObject read GetParent write SetParent;
    property Prop: string read GetProperty write SetProperty;
    property Required: Boolean read GetRequired write SetRequired;
    property FieldName: string read GetFieldName write SetFieldName;
    property Display: string read GetDisplay write SetDisplay;
    property HasValue: Boolean read GetHasValue;
    property EditMask: TEditMask read GetEditMask write SetEditMask;
  end;

  TDBField = class(TInterfacedObject, IDBField)
  private
    FValue: TDBValue;
    FPType: PTypeInfo;
    FParent: TObject;
    FProperty: string;
    FPK: TPK;
    FFK: TFK;
    FRequired: Boolean;
    FFieldName: string;
    FDisplay: string;
    FEditMask: TEditMask;
    function GetValue: TDBValue; virtual; stdCall; abstract;
    function GetType: PTypeInfo; stdCall;
    function GetParent: TObject; stdCall;
    function GetProperty: string; stdCall;
    function GetRequired: Boolean; stdCall;
    function GetFieldName: string; stdCall;
    function GetDisplay: string; stdCall;
    function GetHasValue: Boolean; stdCall;
    function GetEditMask: TEditMask; stdCall;
    procedure SetValue(Value: TDBValue); virtual; stdCall; abstract;
    procedure SetType(Value: PTypeInfo); stdCall;
    procedure SetParent(Value: TObject); stdCall;
    procedure SetProperty(Value: string); stdCall;
    procedure SetRequired(Value: Boolean); stdCall;
    procedure SetFieldName(Value: string); stdCall;
    procedure SetDisplay(Value: string); stdCall;
    procedure SetEditMask(Value: TEditMask); stdCall;
  protected
    function SetCondition(Value1, Value2: TValue; LogicalOperator: TFieldOperator): TCondition; stdCall;
  public
    constructor Create(Tipo: PTypeInfo); virtual;
    procedure Clear; stdCall;

    function Equal(Value: TValue): TCondition;
    function NotEqual(Value: TValue): TCondition;
    function GreaterThan(Value: TValue): TCondition;
    function GreaterThanOrEqual(Value: TValue): TCondition;
    function LessThan(Value: TValue): TCondition;
    function LessThanOrEqual(Value: TValue): TCondition;
    function Between(Value1, Value2: TValue): TCondition;
    function Desc: TValue;
    function Like(Value: TValue): TCondition;
    function IsNull: TCondition;

    class function IsField(Value: TValue): Boolean;
    class function IsPK(Value: TValue): Boolean; overload;
    class function IsFK(Value: TValue): Boolean; overload;
    class function IsAutoIncrement(Value: TValue): Boolean; overload;
    class function IsRequired(Value: TValue): Boolean; overload;
    function IsPK: Boolean; overload;  stdCall;
    function IsFK: Boolean; overload;  stdCall;
    function IsAutoIncrement: Boolean; overload; stdCall;
    function IsRequired: Boolean; overload; stdCall;

    property Value: TDBValue read GetValue write SetValue;
    property PType: PTypeInfo read GetType write SetType;
    property Parent: TObject read GetParent write SetParent;
    property Prop: string read GetProperty write SetProperty;
    property PK: TPK read FPK write FPK;
    property FK: TFK read FFK write FFK;
    property Required: Boolean read GetRequired write SetRequired;
    property FieldName: string read GetFieldName write SetFieldName;
    property Display: string read GetDisplay write SetDisplay;
    property HasValue: Boolean read GetHasValue;
    property EditMask: TEditMask read GetEditMask write SetEditMask;
  end;

  TVariantField = class(TDBField)
  protected
    function GetValue: TDBValue; override;
    function GetAsVariant: Variant;
    function GetAsInteger: Integer;
    function GetAsString: string;
    function GetAsDateTime: TDateTime;
    function GetAsFloat: Double;
    function GetAsBoolean: Boolean;
    procedure SetValue(Value: TDBValue); override;
    procedure SetAsVariant(Value: Variant);
    procedure SetAsInteger(Value: Integer);
    procedure SetAsString(Value: string);
    procedure SetAsDateTime(Value: TDateTime);
    procedure SetAsFloat(Value: Double);
    procedure SetAsBoolean(Value: Boolean);
  public
    property AsVariant: Variant read GetAsVariant write SetAsVariant;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsString: string read GetAsString write SetAsString;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
  end;

  TIntegerField = class(TDBField)
  protected
    function GetValue: TDBValue; override;
    function GetAsVariant: Variant;
    function GetAsInteger: Integer;
    function GetAsString: string;
    function GetAsDateTime: TDateTime;
    function GetAsFloat: Double;
    function GetAsBoolean: Boolean;
    procedure SetValue(Value: TDBValue); override;
    procedure SetAsVariant(Value: Variant);
    procedure SetAsInteger(Value: Integer);
    procedure SetAsString(Value: string);
    procedure SetAsDateTime(Value: TDateTime);
    procedure SetAsFloat(Value: Double);
    procedure SetAsBoolean(Value: Boolean);
  public
    property AsVariant: Variant read GetAsVariant write SetAsVariant;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsString: string read GetAsString write SetAsString;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
  end;

  TStringField = class(TDBField)
  private
    FSize: Integer;
  protected
    function GetValue: TDBValue; override;
    function GetAsVariant: Variant;
    function GetAsInteger: Integer;
    function GetAsString: string;
    function GetAsDateTime: TDateTime;
    function GetAsFloat: Double;
    function GetAsBoolean: Boolean;
    procedure SetValue(Value: TDBValue); override;
    procedure SetAsVariant(Value: Variant);
    procedure SetAsInteger(Value: Integer);
    procedure SetAsString(Value: string);
    procedure SetAsDateTime(Value: TDateTime);
    procedure SetAsFloat(Value: Double);
    procedure SetAsBoolean(Value: Boolean);
  public
    constructor Create(Tipo: PTypeInfo); override;
    property AsVariant: Variant read GetAsVariant write SetAsVariant;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsString: string read GetAsString write SetAsString;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property Size: Integer read FSize write FSize default 0;
  end;

  TDateTimeField = class(TDBField)
  protected
    function GetValue: TDBValue; override;
    function GetAsVariant: Variant;
    function GetAsInteger: Integer;
    function GetAsString: string;
    function GetAsDateTime: TDateTime;
    function GetAsFloat: Double;
    procedure SetValue(Value: TDBValue); override;
    procedure SetAsVariant(Value: Variant);
    procedure SetAsInteger(Value: Integer);
    procedure SetAsString(Value: string);
    procedure SetAsDateTime(Value: TDateTime);
    procedure SetAsFloat(Value: Double);
  public
    constructor Create(Tipo: PTypeInfo); override;
    property AsVariant: Variant read GetAsVariant write SetAsVariant;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsString: string read GetAsString write SetAsString;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
  end;

  TFloatField = class(TDBField)
  private
    FCurrency: Boolean;
    FPrecision: Integer;
    FDecimal: Integer;
  protected
    function GetValue: TDBValue; override;
    function GetAsVariant: Variant;
    function GetAsInteger: Integer;
    function GetAsString: string;
    function GetAsDateTime: TDateTime;
    function GetAsFloat: Double;
    function GetAsBoolean: Boolean;
    procedure SetValue(Value: TDBValue); override;
    procedure SetAsVariant(Value: Variant);
    procedure SetAsInteger(Value: Integer);
    procedure SetAsString(Value: string);
    procedure SetAsDateTime(Value: TDateTime);
    procedure SetAsFloat(Value: Double);
    procedure SetAsBoolean(Value: Boolean);
  public
    constructor Create(Tipo: PTypeInfo); override;
    property AsVariant: Variant read GetAsVariant write SetAsVariant;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsString: string read GetAsString write SetAsString;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property Currency: Boolean read FCurrency write FCurrency default False;
    property Precision: Integer read FPrecision write FPrecision default 15;
    property Decimal: Integer read FDecimal write FDecimal default 2;
  end;

  TCurrencyField = class(TFloatField)
  public
    constructor Create(PType: PTypeInfo); override;
  end;

  TBooleanField = class(TDBField)
  protected
    function GetValue: TDBValue; override;
    function GetAsVariant: Variant;
    function GetAsInteger: Integer;
    function GetAsString: string;
    function GetAsFloat: Double;
    function GetAsBoolean: Boolean;
    procedure SetValue(Value: TDBValue); override;
    procedure SetAsVariant(Value: Variant);
    procedure SetAsInteger(Value: Integer);
    procedure SetAsString(Value: string);
    procedure SetAsFloat(Value: Double);
    procedure SetAsBoolean(Value: Boolean);
  public
    property AsVariant: Variant read GetAsVariant write SetAsVariant;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsString: string read GetAsString write SetAsString;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
  end;

  TBlobField = class(TDBField)
  protected
    function GetValue: TDBValue; override;
    procedure SetValue(Value: TDBValue); override;
  public
    procedure LoadFromStream(Stream: TStream);
    procedure LoadFromJPEGImage(Imagem: TJPEGImage);
    procedure LoadFromFile(const FileName: string);
    procedure SaveToStream(Stream: TStream);
    procedure SaveToJPEGImage(Imagem: TJPEGImage);
    procedure SaveToFile(const FileName: string);
  end;

  TMemoField = class(TBlobField);

implementation

{ TPK }

class operator TPK.Implicit(Value: Boolean): TPK;
begin
  Result.Value := Value;
end;

class operator TPK.Implicit(Value: TPK): Boolean;
begin
  Result := Value.Value;
end;

class operator TPK.Equal(a, b: TPK): Boolean;
begin
  Result := a.Value = b.Value;
end;

class operator TPK.NotEqual(a, b: TPK): Boolean;
begin
  Result := a.Value <> b.Value;
end;

class operator TPK.GreaterThan(a, b: TPK): Boolean;
begin
  Result := a.Value > b.Value;
end;

class operator TPK.GreaterThanOrEqual(a, b: TPK): Boolean;
begin
  Result := a.Value >= b.Value;
end;

class operator TPK.LessThan(a, b: TPK): Boolean;
begin
  Result := a.Value < b.Value;
end;

class operator TPK.LessThanOrEqual(a, b: TPK): Boolean;
begin
  Result := a.Value <= b.Value;
end;

function TPK.GetAutoIncrement: Boolean;
begin
  Result := FAutoIncrement;
end;

procedure TPK.SetAutoIncrement(Value: Boolean);
begin
  FAutoIncrement := Value;
end;

{ TFK }

class operator TFK.Implicit(Value: Boolean): TFK;
begin
  Result.Value := Value;
end;

class operator TFK.Implicit(Value: TFK): Boolean;
begin
  Result := Value.Value;
end;

class operator TFK.Equal(a, b: TFK): Boolean;
begin
  Result := a.Value = b.Value;
end;

class operator TFK.NotEqual(a, b: TFK): Boolean;
begin
  Result := a.Value <> b.Value;
end;

class operator TFK.GreaterThan(a, b: TFK): Boolean;
begin
  Result := a.Value > b.Value;
end;

class operator TFK.GreaterThanOrEqual(a, b: TFK): Boolean;
begin
  Result := a.Value >= b.Value;
end;

class operator TFK.LessThan(a, b: TFK): Boolean;
begin
  Result := a.Value < b.Value;
end;

class operator TFK.LessThanOrEqual(a, b: TFK): Boolean;
begin
  Result := a.Value <= b.Value;
end;

function TFK.GetEntity: TClass;
begin
  Result := FEntity;
end;

procedure TFK.SetEntity(Value: TClass);
begin
  FEntity := Value;
end;

{ TDBValue<T> }

class operator TDBValue.Implicit(Value: Variant): TDBValue;
begin
  Result.Value := Value;
end;

class operator TDBValue.Implicit(Value: TDBValue): Variant;
begin
  Result := Value.Value;
end;

class operator TDBValue.Equal(a, b: TDBValue): Boolean;
begin
  Result := a.Value = b.Value;
end;

class operator TDBValue.NotEqual(a, b: TDBValue): Boolean;
begin
  Result := a.Value <> b.Value;
end;

class operator TDBValue.GreaterThan(a, b: TDBValue): Boolean;
begin
  Result := a.Value > b.Value;
end;

class operator TDBValue.GreaterThanOrEqual(a, b: TDBValue): Boolean;
begin
  Result := a.Value >= b.Value;
end;

class operator TDBValue.LessThan(a, b: TDBValue): Boolean;
begin
  Result := a.Value < b.Value;
end;

class operator TDBValue.LessThanOrEqual(a, b: TDBValue): Boolean;
begin
  Result := a.Value <= b.Value;
end;

{ TDBField<T> }

constructor TDBField.Create(Tipo: PTypeInfo);
begin
  Self.PType := Tipo;
  Self.Parent := nil;
  Self.Prop := '';
  Self.PK := False;
  Self.PK.AutoIncrement := False;
  Self.FK := False;
  Self.FK.Entity := nil;
  Self.Required := False;
  Self.FieldName := '';
  Self.Display := '';

  Self.EditMask := '';

  Self.Clear;
end;

procedure TDBField.Clear;
begin
  Self.Value := Null;
end;

function TDBField.GetType: PTypeInfo;
begin
  Result := FPType;
end;

function TDBField.GetParent: TObject;
begin
  Result := FParent;
end;

function TDBField.GetProperty: string;
begin
  Result := FProperty;
end;

function TDBField.GetRequired: Boolean;
begin
  Result := FRequired;
end;

function TDBField.GetFieldName: string;
begin
  Result := FFieldName;
end;

function TDBField.GetDisplay: string;
begin
  Result := FDisplay;
end;

function TDBField.GetHasValue: Boolean;
begin
  Result := not VarIsNull(Self.Value);
end;

function TDBField.GetEditMask: TEditMask;
begin
  Result := FEditMask;
end;

procedure TDBField.SetType(Value: PTypeInfo);
begin
  FPType := Value;
end;

procedure TDBField.SetParent(Value: TObject);
begin
  FParent := Value;
end;

procedure TDBField.SetProperty(Value: string);
begin
  FProperty := Value;
end;

procedure TDBField.SetRequired(Value: Boolean);
begin
  FRequired := Value;
end;

procedure TDBField.SetFieldName(Value: string);
begin
  FFieldName := Value;
end;

procedure TDBField.SetDisplay(Value: string);
begin
  FDisplay := Value;
end;

procedure TDBField.SetEditMask(Value: TEditMask);
begin
  FEditMask := Value;
end;

function TDBField.SetCondition(Value1, Value2: TValue;
  LogicalOperator: TFieldOperator): TCondition;
begin
  Result.FieldOperador := LogicalOperator;
  Result.TargetDBField := Self;
  Result.DBField1 := nil;
  Result.Value1 := Null;
  Result.Function1.FunctionOperator := fuNull;
  Result.Function1.DBField := nil;
  Result.Function1.Value := Null;
  Result.DBField2 := nil;
  Result.Value2 := Null;
  Result.Function2.FunctionOperator := fuNull;
  Result.Function2.DBField := nil;
  Result.Function2.Value := Null;

  if Value1.TypeInfo = nil then Exit;

  (* When conditional TValue is a TDBField. *)
  if IsField(Value1) then
    Value1.ExtractRawData(@Result.DBField1)
  else
  (* When conditional TValeu is a function. *)
  if Value1.TypeInfo.Name = 'TFunction' then
    Value1.ExtractRawData(@Result.Function1)
  else
    (* When the conditional TValue is any value. *)
    Result.Value1 := Value1.AsVariant;

  if Value2.TypeInfo = nil then Exit;

  (* We will have 2 fields when the condition needs an extra field, for example
       the BETWEEN. *)
  if IsField(Value2) then
    Value2.ExtractRawData(@Result.DBField2)
  else
  if Value2.TypeInfo.Name = 'TFunction' then
    Value2.ExtractRawData(@Result.Function2)
  else
    Result.Value2 := Value2.AsVariant;
end;

function TDBField.Equal(Value: TValue): TCondition;
begin
  Result := SetCondition(Value, nil, fiEqual);
end;

function TDBField.NotEqual(Value: TValue): TCondition;
begin
  Result := SetCondition(Value, nil, fiNotEqual);
end;

function TDBField.GreaterThan(Value: TValue): TCondition;
begin
  Result := SetCondition(Value, nil, fiGreaterThan);
end;

function TDBField.GreaterThanOrEqual(Value: TValue): TCondition;
begin
  Result := SetCondition(Value, nil, fiGreaterThanOrEqual);
end;

function TDBField.LessThan(Value: TValue): TCondition;
begin
  Result := SetCondition(Value, nil, fiLessThan);
end;

function TDBField.LessThanOrEqual(Value: TValue): TCondition;
begin
  Result := SetCondition(Value, nil, fiLessThanOrEqual);
end;

function TDBField.Between(Value1, Value2: TValue): TCondition;
begin
  Result := SetCondition(Value1, Value2, fiBetween);
end;

function TDBField.Desc: TValue;
var
  Func: TFunction;
begin
  Func.FunctionOperator := fuDesc;
  Func.DBField := Self;
  Func.Value := Null;

  Result := TValue.From<TFunction>(Func);
end;

function TDBField.IsNull: TCondition;
begin
  Result := SetCondition(nil, nil, fiIsNull);
end;

function TDBField.Like(Value: TValue): TCondition;
begin
  Result := SetCondition(Value, nil, fiLike);
end;

class function TDBField.IsField(Value: TValue): Boolean;

  function FindAncestralClass(Classe: TClass): TClass;
  begin
    Result := Classe;
    if (Classe = TDBField) or (Classe = TObject) then Exit;
    Result := FindAncestralClass(Classe.ClassParent);
  end;

begin
  if Value.TypeInfo = nil then
  begin
    Result := False;
    Exit;
  end;

  Result := (Value.TypeInfo.Kind = tkClass) and (FindAncestralClass(Value.TypeInfo.TypeData.ClassType.ClassParent) = TDBField);
end;

class function TDBField.IsPK(Value: TValue): Boolean;
var
  DBField: TDBField;
begin
  Result := False;

  if not TDBField.IsField(Value) then Exit;

  Value.ExtractRawData(@DBField);
  Result := DBField.IsPK;
end;

function TDBField.IsPK: Boolean;
begin
  Result := Self.PK;
end;

class function TDBField.IsFK(Value: TValue): Boolean;
var
  DBField: TDBField;
begin
  Result := False;

  if not TDBField.IsField(Value) then Exit;

  Value.ExtractRawData(@DBField);
  Result := DBField.IsFK;
end;

function TDBField.IsFK: Boolean;
begin
  Result := Self.FK;
end;

class function TDBField.IsAutoIncrement(Value: TValue): Boolean;
var
  DBField: TDBField;
begin
  Result := False;

  if not TDBField.IsPK(Value) then Exit;

  Value.ExtractRawData(@DBField);
  Result := DBField.IsAutoIncrement;
end;

function TDBField.IsAutoIncrement: Boolean;
begin
  Result := Self.PK.AutoIncrement;
end;

class function TDBField.IsRequired(Value: TValue): Boolean;
var
  DBField: TDBField;
begin
  Result := False;

  if not TDBField.IsField(Value) then Exit;

  Value.ExtractRawData(@DBField);
  Result := DBField.IsRequired;
end;

function TDBField.IsRequired: Boolean;
begin
  Result := Self.Required;
end;

{ TVariantField }

function TVariantField.GetValue: TDBValue;
begin
  Result.Value := GetAsVariant;
end;

function TVariantField.GetAsVariant: Variant;
begin
  Result := Self.FValue.Value;
end;

function TVariantField.GetAsInteger: Integer;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := 0
    else
      Result := Integer(Self.FValue.Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TVariantField.GetAsString: string;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := ''
    else
      Result := string(Self.FValue.Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TVariantField.GetAsDateTime: TDateTime;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := 0
    else
      Result := TDateTime(Self.FValue.Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TVariantField.GetAsFloat: Double;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := 0
    else
      Result := Double(Self.FValue.Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TVariantField.GetAsBoolean: Boolean;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := False
    else
      Result := Boolean(Self.FValue.Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TVariantField.SetValue(Value: TDBValue);
begin
  FValue.Value := Value.Value;
end;

procedure TVariantField.SetAsVariant(Value: Variant);
begin
  Self.FValue.Value := Value;
end;

procedure TVariantField.SetAsInteger(Value: Integer);
begin
  try
    Self.FValue.Value := Variant(Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TVariantField.SetAsString(Value: string);
begin
  try
    Self.FValue.Value := Variant(Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TVariantField.SetAsDateTime(Value: TDateTime);
begin
  try
    Self.FValue.Value := Variant(Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TVariantField.SetAsFloat(Value: Double);
begin
  try
    Self.FValue.Value := Variant(Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TVariantField.SetAsBoolean(Value: Boolean);
begin
  try
    Self.FValue.Value := Variant(Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

{ TIntegerField }

function TIntegerField.GetValue: TDBValue;
begin
  if VarIsNull(Self.FValue.Value) then
    Result := Self.FValue.Value
  else
    Result := Integer(Self.FValue.Value);
end;

function TIntegerField.GetAsVariant: Variant;
begin
  try
    Result := Self.FValue.Value;
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TIntegerField.GetAsInteger: Integer;
begin
  if VarIsNull(Self.FValue.Value) then
    Result := 0
  else
    Result := Integer(Self.FValue.Value);
end;

function TIntegerField.GetAsString: string;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := ''
    else
      Result := IntToStr(Integer(Self.FValue.Value));
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TIntegerField.GetAsDateTime: TDateTime;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := 0
    else
      Result := TDateTime(Self.FValue.Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TIntegerField.GetAsFloat: Double;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := 0
    else
      Result := Double(Self.FValue.Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TIntegerField.GetAsBoolean: Boolean;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := False
    else
      Result := not (Integer(Self.FValue.Value) = 0);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TIntegerField.SetValue(Value: TDBValue);
begin
  try
    if VarIsNull(Value) then
      FValue.Value := Value.Value
    else
      FValue.Value := Integer(Value.Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TIntegerField.SetAsVariant(Value: Variant);
begin
  try
    Self.FValue.Value := Integer(Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TIntegerField.SetAsInteger(Value: Integer);
begin
  Self.FValue.Value := Value;
end;

procedure TIntegerField.SetAsString(Value: string);
begin
  try
    Self.FValue.Value := StrToInt(Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TIntegerField.SetAsDateTime(Value: TDateTime);
begin
  try
    Self.FValue.Value := Trunc(Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TIntegerField.SetAsFloat(Value: Double);
begin
  try
    Self.FValue.Value := Integer(Round(Double(Value)));
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TIntegerField.SetAsBoolean(Value: Boolean);
begin
  try
    if Value then
      Self.FValue.Value := 1
    else
      Self.FValue.Value := 0;
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

{ TStringField }

constructor TStringField.Create(Tipo: PTypeInfo);
begin
  inherited Create(Tipo);
  FSize := 0;
end;

function TStringField.GetValue: TDBValue;
begin
  if VarIsNull(Self.FValue.Value) then
    Result := Self.FValue.Value
  else
    Result := string(Self.FValue.Value);
end;

function TStringField.GetAsVariant: Variant;
begin
  try
    Result := Self.FValue.Value;
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TStringField.GetAsInteger: Integer;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := 0
    else
      Result := StrToInt(string(Self.FValue.Value));
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TStringField.GetAsString: string;
begin
  if VarIsNull(Self.FValue.Value) then
    Result := ''
  else
    Result := string(Self.FValue.Value);
end;

function TStringField.GetAsDateTime: TDateTime;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := 0
    else
      Result := StrToDateTime(string(Self.FValue.Value));
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TStringField.GetAsFloat: Double;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := 0
    else
      Result := StrToFloat(string(Self.FValue.Value));
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TStringField.GetAsBoolean: Boolean;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := False
    else
      Result := string(Self.FValue.Value) = 'True';
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TStringField.SetValue(Value: TDBValue);
begin
  try
    if VarIsNull(Value) then
      FValue.Value := Value.Value
    else
      FValue.Value := string(Value.Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TStringField.SetAsVariant(Value: Variant);
begin
  try
    Self.FValue.Value := string(Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TStringField.SetAsInteger(Value: Integer);
begin
  try
    Self.FValue.Value := IntToStr(Integer(Value));
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TStringField.SetAsString(Value: string);
begin
  Self.FValue.Value := Value;
end;

procedure TStringField.SetAsDateTime(Value: TDateTime);
begin
  try
    Self.FValue.Value := DateTimeToStr(Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TStringField.SetAsFloat(Value: Double);
begin
  try
    Self.FValue.Value := FloatToStr(Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TStringField.SetAsBoolean(Value: Boolean);
begin
  try
    if Boolean(Self.FValue.Value) then
      Self.FValue.Value := 'True'
    else
      Self.FValue.Value := 'False';
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

{ TDateTimeField }

constructor TDateTimeField.Create(Tipo: PTypeInfo);
begin
  inherited Create(Tipo);
  Self.EditMask := 'dd.MM.yyyy';
end;

function TDateTimeField.GetValue: TDBValue;
begin
  if VarIsNull(Self.FValue.Value) then
    Result := Self.FValue.Value
  else
    Result := TDateTime(Self.FValue.Value);
end;

function TDateTimeField.GetAsVariant: Variant;
begin
  try
    Result := Self.FValue.Value;
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TDateTimeField.GetAsInteger: Integer;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := 0
    else
      Result := Trunc(TDateTime(Self.FValue.Value));
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TDateTimeField.GetAsString: string;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := ''
    else
      Result := FormatDateTime(Self.EditMask, TDateTime(Self.FValue.Value));
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TDateTimeField.GetAsDateTime: TDateTime;
begin
  if VarIsNull(Self.FValue.Value) then
    Result := 0
  else
    Result := TDateTime(Self.FValue.Value);
end;

function TDateTimeField.GetAsFloat: Double;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := 0
    else
      Result := Double(Self.FValue.Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TDateTimeField.SetValue(Value: TDBValue);
begin
  try
    if VarIsNull(Value) then
      FValue.Value := Value.Value
    else
      FValue.Value := TDateTime(Value.Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TDateTimeField.SetAsVariant(Value: Variant);
begin
  try
    Self.FValue.Value := TDateTime(Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TDateTimeField.SetAsInteger(Value: Integer);
begin
  try
    Self.FValue.Value := TDateTime(Integer(Value).ToDouble);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TDateTimeField.SetAsString(Value: string);
begin
  try
    Self.FValue.Value := StrToDateTime(Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TDateTimeField.SetAsDateTime(Value: TDateTime);
begin
  Self.FValue.Value := Value;
end;

procedure TDateTimeField.SetAsFloat(Value: Double);
begin
  try
    Self.FValue.Value := TDateTime(Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

{ TFloatField }

constructor TFloatField.Create(Tipo: PTypeInfo);
begin
  inherited Create(Tipo);
  FCurrency := False;
  FPrecision := 15;
  FDecimal := 2;
end;

function TFloatField.GetValue: TDBValue;
begin
  if VarIsNull(Self.FValue.Value) then
    Result := Self.FValue.Value
  else
    Result := Double(Self.FValue.Value);
end;

function TFloatField.GetAsVariant: Variant;
begin
  try
    Result := Self.FValue.Value;
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TFloatField.GetAsInteger: Integer;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := 0
    else
      Result := Integer(Round(Double(Self.FValue.Value)));
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TFloatField.GetAsString: string;
var
  Temp: Double;

  function Round(Valor: Extended): Extended;
  var
    cString: string[15];
  begin
    Str(Valor: FPrecision: FDecimal, cString);
    cString[Pos('.', string(cString))] := AnsiChar(FormatSettings.DecimalSeparator);
    Result := StrToCurr(string(cString));
  end;

begin
  try
    if VarIsNull(Self.FValue.Value) then
      Temp := 0
    else
      Temp := Self.FValue.Value;

    if FCurrency then
      Result := FloatToStrF(Round(Temp), ffCurrency, FPrecision, FDecimal)
    else
      Result := FloatToStrF(Round(Temp), ffNumber, FPrecision, FDecimal);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TFloatField.GetAsDateTime: TDateTime;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := 0
    else
      Result := TDateTime(Self.FValue.Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TFloatField.GetAsFloat: Double;
begin
  if VarIsNull(Self.FValue.Value) then
    Result := 0
  else
    Result := Double(Self.FValue.Value);
end;

function TFloatField.GetAsBoolean: Boolean;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := False
    else
      Result := not (Double(Self.FValue.Value) = 0);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TFloatField.SetValue(Value: TDBValue);
begin
  try
    if VarIsNull(Value) then
      FValue.Value := Value.Value
    else
      FValue.Value := Double(Value.Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TFloatField.SetAsVariant(Value: Variant);
begin
  try
    Self.FValue.Value := Double(Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TFloatField.SetAsInteger(Value: Integer);
begin
  try
    Self.FValue.Value := Value.ToDouble;
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TFloatField.SetAsString(Value: string);
begin
  try
    Self.FValue.Value := StrToFloat(Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TFloatField.SetAsDateTime(Value: TDateTime);
begin
  try
    Self.FValue.Value := Double(Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TFloatField.SetAsFloat(Value: Double);
begin
  Self.FValue.Value := Value;
end;

procedure TFloatField.SetAsBoolean(Value: Boolean);
begin
  try
    if Value then
      Self.FValue.Value := 1
    else
      Self.FValue.Value := 0;
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

{ TCurrencyField }

constructor TCurrencyField.Create(PType: PTypeInfo);
begin
  inherited Create(PType);
  FCurrency := True;
end;

{ TBooleanField }

function TBooleanField.GetValue: TDBValue;
begin
  if VarIsNull(Self.FValue.Value) then
    Result := Self.FValue.Value
  else
    Result := Boolean(Self.FValue.Value);
end;

function TBooleanField.GetAsVariant: Variant;
begin
  try
    Result := Self.FValue.Value;
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TBooleanField.GetAsInteger: Integer;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := 0
    else
    begin
      if Boolean(Self.FValue.Value) then
        Result := 1
      else
        Result := 0;
    end;
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TBooleanField.GetAsString: string;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := ''
    else
    begin
      if Boolean(Self.FValue.Value) then
        Result := 'True'
      else
        Result := 'False';
    end;
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TBooleanField.GetAsFloat: Double;
begin
  try
    if VarIsNull(Self.FValue.Value) then
      Result := 0
    else
    begin
      if Boolean(Self.FValue.Value) then
        Result := 1
      else
        Result := 0;
    end;
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

function TBooleanField.GetAsBoolean: Boolean;
begin
  if VarIsNull(Self.FValue.Value) then
    Result := False
  else
    Result := Boolean(Self.FValue.Value);
end;

procedure TBooleanField.SetValue(Value: TDBValue);
begin
  try
    if VarIsNull(Value) then
      FValue.Value := Value.Value
    else
      FValue.Value := Boolean(Value.Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TBooleanField.SetAsVariant(Value: Variant);
begin
  try
    Self.FValue.Value := Boolean(Value);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TBooleanField.SetAsInteger(Value: Integer);
begin
  try
    Self.FValue.Value := not (Value = 0);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TBooleanField.SetAsString(Value: string);
begin
  try
    Self.FValue.Value := Value = 'True';
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TBooleanField.SetAsFloat(Value: Double);
begin
  try
    Self.FValue.Value := not (Value = 0);
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TBooleanField.SetAsBoolean(Value: Boolean);
begin
  Self.FValue.Value := Value;
end;

{ TBlobField }

function TBlobField.GetValue: TDBValue;
begin
  Result.Value := FValue.Value;
end;

procedure TBlobField.SetValue(Value: TDBValue);
var
  Stream: TStream;
  P: Pointer;
begin
  try
    FValue.Value := Value.Value;

    if VarIsClear(Value) or VarIsEmpty(Value) or VarIsNull(Value) or (VarCompareValue(Value, Unassigned) = vrEqual) or not VarIsArray(Value) then
      Exit;

    Stream := TMemoryStream.Create;
    Stream.Position := 0;
    P := VarArrayLock(FValue.Value);
    Stream.Write(P^, VarArrayHighBound(FValue.Value, 1));
    VarArrayUnlock(FValue.Value);

    try
      LoadFromStream(Stream);
    finally
      FreeAndNil(Stream);
    end;
  except
    raise EMoriniException.Create(SErrorConvertingData);
  end;
end;

procedure TBlobField.LoadFromStream(Stream: TStream);
var
  P: Pointer;
  Buffer: array [1..1] of byte;
  I: Integer;
  Str: string;
  StrStream: TStringStream;
begin
  Str := '';

  if Self.ClassType = TBlobField then
  begin
    (* Create variant array and copy Stream content to array. *)
    Stream.Seek(0, 0);
    Self.FValue.Value := VarArrayCreate([0, Stream.Size-1], varByte);
    if Stream.Size > 0 then
    begin
      P := VarArrayLock(Self.FValue.Value);
      Stream.ReadBuffer(P^, Stream.Size);
      VarArrayUnlock(Self.FValue.Value);
    end;

    (* Convert the array to hexa. *)
    Stream.Seek(0, 0);
    for I := 1 to Stream.Size do
    begin
      Stream.Read(Buffer, 1);
      Str := Str + IntToHex(Buffer[1], 2);
    end;

    (* Copy the hex value to the DBField's Value. *)
    Self.FValue.Value := '0x' + Str;
  end
  else
  if Self.ClassType = TMemoField then
  begin
    StrStream := TStringStream.Create;
    try
      StrStream.LoadFromStream(Stream);
      Str := StrStream.DataString;
      Self.FValue.Value := Str;
    finally
      FreeAndNil(StrStream);
    end;
  end
end;

procedure TBlobField.LoadFromJPEGImage(Imagem: TJPEGImage);
var
  Stream: TStream;
begin
  if Self.ClassType = TMemoField then Exit;

  Stream := TMemoryStream.Create;
  Imagem.SaveToStream(Stream);

  try
    LoadFromStream(Stream);
  finally
    FreeAndNil(Stream);
  end;
end;

procedure TBlobField.LoadFromFile(const FileName: string);
var
  Stream: TStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead);

  try
    LoadFromStream(Stream);
  finally
    FreeAndNil(Stream);
  end;
end;

procedure TBlobField.SaveToStream(Stream: TStream);
var
  HexStr: AnsiString;
  M: TMemoryStream;
begin
  (* I do the Copy because I don't want the '0x' at the beginning of the string that comes from the database. *)
  if Copy(Self.FValue.Value, 1, 2) = '0x' then
    HexStr := AnsiString(Copy(Self.FValue.Value, 3, Length(Self.FValue.Value)))
  else
    HexStr := AnsiString(Self.FValue.Value);

  M := TMemoryStream.Create;

  try
    M.Size := Length(HexStr) div 2;
    if M.Size > 0 then
    begin
      if Self.ClassType = TBlobField then
      begin
        HexToBin(PAnsiChar(HexStr), M.Memory, M.Size);
        Stream.CopyFrom(M, M.Size);
      end
      else
      if Self.ClassType = TMemoField then
        Stream.Write(Pointer(HexStr)^, Length(HexStr));
    end;
  finally
    FreeAndNil(M);
  end;
end;

procedure TBlobField.SaveToJPEGImage(Imagem: TJPEGImage);
var
  Stream: TMemoryStream;
begin
  if Self.ClassType = TMemoField then Exit;

  Stream := TMemoryStream.Create;

  try
    SaveToStream(Stream);

    Stream.Seek(0, 0);
    Imagem.PixelFormat := jf24Bit;
    Imagem.Scale := jsFullSize;
    Imagem.GrayScale := False;
    Imagem.Performance := jpBestQuality;
    Imagem.ProgressiveDisplay := True;
    Imagem.ProgressiveEncoding := True;
    Imagem.LoadFromStream(Stream);
  finally
    FreeAndNil(Stream);
  end;
end;

procedure TBlobField.SaveToFile(const FileName: string);
var
  Stream: TMemoryStream;
begin
  Stream := TMemoryStream.Create;

  try
    SaveToStream(Stream);
    Stream.SaveToFile(FileName);
  finally
    FreeAndNil(Stream);
  end;
end;

end.
