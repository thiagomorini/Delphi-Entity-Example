unit State;

interface

uses
  Morini.Entity, Morini.Attributes, Morini.DBField,

  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.VCLUI.Wait, FireDAC.Comp.Client, FireDAC.Phys.MSSQL,
  FireDAC.Phys.MSSQLDef, FireDAC.Comp.UI, FireDAC.DApt;

type
  [Table('STATE')]
  TState = class(TEntity)
  private
    FAbbreviation: TStringField;
    FName: TStringField;
  public
    procedure Search(Connection: TFDConnection; Abbreviation: string; BringForeignEntity: Boolean = False); overload;

    [PK]
    [Required]
    [Size(2)]
    [FieldName('ID_ABBREVIATION')]
    [Display('Abbreviation')]
    property Abbreviation: TStringField read FAbbreviation write FAbbreviation;

    [Required]
    [Size(20)]
    [FieldName('NAME')]
    [Display('Name')]
    property Name: TStringField read FName write FName;
  end;

implementation

{ TState }

procedure TState.Search(Connection: TFDConnection; Abbreviation: string; BringForeignEntity: Boolean = False);
begin
  Self.Abbreviation.Value := Abbreviation;
  Self.Search(Connection, BringForeignEntity);
end;

end.
