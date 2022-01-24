unit FEntityExample;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MSSQL,
  FireDAC.Phys.MSSQLDef, FireDAC.VCLUI.Wait, Data.DB, FireDAC.Comp.Client,
  Vcl.StdCtrls,

  Morini.DB, Morini.Entity, Morini.SQL, City;

type
  TForm1 = class(TForm)
    FDConnection1: TFDConnection;
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
var
  DB: TDatabase;
  SQL: TSQL;
  City: TCity;
begin
  DB := TDatabase.Create(Self, FDConnection1);
  SQL := TSQL.Create;
  City := TCity.Create;

  try
    DB.Connection.Connected := True;

    DB.ExecuteSQL(SQL.Delete(City).Where(City.IdCity.Equal(2)).ToText);

    City.IdCity.AsInteger := 2;
    City.Name.AsString := 'NAME OF THE CITY';
    City.Save(DB.Connection, acInsert);

    City.Search(DB.Connection, 2, True);
    ShowMessage(City.Name.AsString);

    DB.OpenTable(SQL.Select([City.Name]).From(City).Where([City.IdCity.Equal(1)]).ToText);
    ShowMessage(City.Name.AsString);
  finally
    City.Free;
    SQL.Free;
    DB.Connection.Connected := False;
    DB.Free;
  end;
end;

end.
