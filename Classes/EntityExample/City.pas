unit City;

interface

uses
  Morini.Entity, Morini.Attributes, Morini.DBField,

  State,

  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.VCLUI.Wait, FireDAC.Comp.Client, FireDAC.Phys.MSSQL,
  FireDAC.Phys.MSSQLDef, FireDAC.Comp.UI, FireDAC.DApt;

type
  [Table('CITY')]
  TCity = class(TEntity)
  private
    FIdCity: TIntegerField;
    FIdState: TStringField;
    FName: TStringField;

    FState: TState;
  public
    procedure Search(Connection: TFDConnection; IdCity: Integer; BringForeignEntity: Boolean = False); overload;

    [PK]
    [Required]
    [FieldName('ID_CITY')]
    [Display('City ID')]
    property IdCity: TIntegerField read FIdCity write FIdCity;

    [FK(TState)]
    [Size(2)]
    [FieldName('ID_ABBREVIATION')]
    [Display('Abbreviation')]
    property IdState: TStringField read FIdState write FIdState;

    [Required]
    [Size(30)]
    [FieldName('Name')]
    [Display('Name')]
    property Name: TStringField read FName write FName;

    [FK('ID_ABBREVIATION')]
    property State: TState read FState write FState;
  end;

implementation

{ TCity }

procedure TCity.Search(Connection: TFDConnection; IdCity: Integer; BringForeignEntity: Boolean = False);
begin
  Self.IdCity.Value := IdCity;
  Self.Search(Connection, BringForeignEntity);
end;

end.
