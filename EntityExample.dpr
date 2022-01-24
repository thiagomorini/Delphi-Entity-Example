program EntityExample;

uses
  Vcl.Forms,
  FEntityExample in 'FEntityExample.pas' {Form1},
  Morini.SQL in 'Classes\Morini.SQL.pas',
  Morini.Exception in 'Classes\Morini.Exception.pas',
  Morini.DB in 'Classes\Morini.DB.pas',
  Morini.Attributes in 'Classes\Morini.Attributes.pas',
  Morini.DBField in 'Classes\Morini.DBField.pas',
  Morini.Entity in 'Classes\Morini.Entity.pas',
  State in 'Classes\EntityExample\State.pas',
  City in 'Classes\EntityExample\City.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
