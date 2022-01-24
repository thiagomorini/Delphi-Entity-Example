{*******************************************************}
{                                                       }
{ Attributes are needed for the "markings" of classes   }
{   and properties of all entities inherited from       }
{   TEntity. With these attributes we can map each      }
{   necessary data between the entities and the DB.     }
{                                                       }
{*******************************************************}

{*******************************************************}
{         Created by Thiago R. Morini - 09/2018         }
{*******************************************************}

unit Morini.Attributes;

interface

type
  (* Name of the table in the database for mounting SQL commands. *)
  Table = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(Name: string);
    property Name: string read FName write FName;
  end;

  (* Checking if the property is a primary key. Used for UPDATE and DELETE conditions.
       In the INSERT we check if the key is auto-increment. If yes, the field will not be informed. *)
  PK = class(TCustomAttribute)
  private
    FAutoIncrement: Boolean;
  public
    constructor Create(AutoIncrement: Boolean = False);
    property AutoIncrement: Boolean read FAutoIncrement write FAutoIncrement;
  end;

  (* Checking if the property is a foreign key. Used to autocomplete FKs in entities. *)
  FK = class(TCustomAttribute)
  private
    FEntity: TClass;
    FFieldName: string;
  public
    constructor Create(Entity: TClass); overload;
    constructor Create(FieldName: string); overload;
    property Entity: TClass read FEntity write FEntity;
    property FieldName: string read FFieldName write FFieldName;
  end;

  (* Checking if the property is required or not. If required and the property
       is valueless, a raise is triggered. *)
  Required = class(TCustomAttribute);

  (* Field name in the database for mounting SQL commands. *)
  FieldName = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(Name: string);
    property Name: string read FName write FName;
  end;

  (* How the property name will be displayed. *)
  Display = class(TCustomAttribute)
  private
    FValue: string;
  public
    constructor Create(Value: string);
    property Value: string read FValue write FValue;
  end;

  (* The field size in the DB. *)
  Size = class(TCustomAttribute)
  private
    FValue, FDecimal: Integer;
  public
    constructor Create(Value: Integer); overload;
    constructor Create(Precision, Decimal: Integer); overload;
    property Value: Integer read FValue write FValue;
    property Decimal: Integer read FDecimal write FDecimal;
  end;

implementation

{ Table }

constructor Table.Create(Name: string);
begin
  FName := Name;
end;

{ PK }

constructor PK.Create(AutoIncrement: Boolean);
begin
  FAutoIncrement := AutoIncrement;
end;

{ FK }

constructor FK.Create(Entity: TClass);
begin
  FEntity := Entity;
end;

constructor FK.Create(FieldNAme: string);
begin
  FFieldNAme := FieldName;
end;

{ Field }

constructor FieldNAme.Create(Name: string);
begin
  FName := Name;
end;

{ Display }

constructor Display.Create(Value: string);
begin
  FValue := Value;
end;

{ Size }

constructor Size.Create(Value: Integer);
begin
  FValue := Value;
end;

constructor Size.Create(Precision, Decimal: Integer);
begin
  FValue := Precision;
  FDecimal := Decimal;
end;

end.
