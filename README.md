# Entity Example em Delphi

Este é um exemplo de um Entity Framework em Delphi. Eu criei durante o meu tempo livre apenas como uma brincadeira, e para treinar os novos conceitos e bibliotecas do Delphi.

## Descrição

O Entity Example em Delphi é um framework para persistência de dados que permite mapear entidades de banco de dados para objetos em sua aplicação Delphi. Com ele, você pode trabalhar com bancos de dados relacionais sem precisar escrever código SQL. No momento apenas em SQL Server.

## Tecnologias utilizadas

- Delphi 10.1 Berlin Update 1
- Componentes FireDAC (TFDConnection, TFDTransaction, TFDQuery)
- Marcações (TCustomAttribute)
- Class operators
- RTTI - para a leitura das propriedades (TRttiContext, TRttiType, TRttiProperty, TRttiInstanceType)

## Como usar

Para usar o Entity Example em sua aplicação Delphi, basta seguir os seguintes passos:

1. Crie uma nova classe para representar a sua entidade, utilizando os marcadores, conforme exemplo na pasta Classes/EntityExample:

```delphi
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
```

2. Use a sua nova classe para acessar os dados e executar os comandos SQL:

```delphi
DB.Connection.Connected := True;

DB.ExecuteSQL(SQL.Delete(City).Where(City.IdCity.Equal(2)).ToText);

City.IdCity.AsInteger := 2;
City.Name.AsString := 'NAME OF THE CITY';
City.Save(DB.Connection, acInsert);

City.Search(DB.Connection, 2, True);
ShowMessage(City.Name.AsString);

DB.OpenTable(SQL.Select([City.Name]).From(City).Where([City.IdCity.Equal(1)]).ToText);
```

## Contribuição

Você pode contribuir com o Entity Example de várias formas:

1. Reportando bugs e problemas no Github.
2. Fazendo pull requests com correções e novas funcionalidades.
3. Compartilhando o projeto e incentivando outros desenvolvedores a usá-lo.

## Licença
O Entity Example é distribuído sob a licença MIT. Veja o arquivo LICENSE.md para mais informações.

## Contato
Você pode entrar em contato comigo sempre que tiver alguma dúvida ou sugestão de melhorias. Lembrando que esse projeto é apenas uma brincadeira e está incompleto, mas já é um ótimo ponto de partida para novas implementações.
