{*******************************************************}
{                                                       }
{ TDatabase is responsible for connecting, managing     }
{   transactions and executing SQL commands on the DB.  }
{                                                       }
{*******************************************************}

{*******************************************************}
{         Created by Thiago R. Morini - 08/2018         }
{*******************************************************}

unit Morini.DB;

interface

uses System.Classes, System.SysUtils, Data.DB, Morini.Exception,

  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.VCLUI.Wait, FireDAC.Comp.Client, FireDAC.Phys.MSSQL,
  FireDAC.Phys.MSSQLDef, FireDAC.Comp.UI, FireDAC.DApt;

resourcestring
  SErrorNewInstance = 'Could not create a new connection instance.';
  SErrorNotConnected = 'Not connected to the database.';
  SErrorTransactionActive = 'There is already an active transaction for this connection instance.';
  SErrorOnTransaction = 'Could not open a transaction for this connection instance.';
  SErrorTransactionNotActive = 'There is no active transaction for this connection instance.';
  SErrorOnCommit = 'Could not commit.';
  SErrorOnRollback = 'Could not rollback.';
  SErrorOpenTable = 'It was not possible to filter the requested information.';
  SErrorExecSQL = 'Could not execute requested SQL statement.';

type
  EMoriniDB = class(EMoriniException);

  TDatabase = class(TComponent)
  private
    FNewInstance: Boolean;
    FConnection: TFDConnection;
    FTransaction: TFDTransaction;
    FOpenTableSQLQuery: TFDQuery;
    FOpenTableDataSource: TDataSource;
    FExecuteSQLQuery: TFDQuery;
  public
    constructor Create(AOwner: TComponent; Connection: TFDConnection; NewInstance: Boolean = False); reintroduce; overload;
    destructor Destroy; override;
    procedure ActivateTransaction;
    procedure ExecuteCommit;
    procedure ExecuteRollback;
    procedure OpenTable(Instruction: String; FetchAll: Boolean = True); overload;
    procedure OpenTable(var pQuery: TFDQuery; Instruction: String; FetchAll: Boolean = True); overload;
    procedure ExecuteSQL(Instruction: String); overload;
    procedure ExecuteSQL(var pQuery: TFDQuery; Instruction: String); overload;
  published
    property Connection: TFDConnection read FConnection;
    property Query: TFDQuery read FOpenTableSQLQuery;
    property DataSource: TDataSource read FOpenTableDataSource;
  end;

implementation

{ TDatabase }

constructor TDatabase.Create(AOwner: TComponent; Connection: TFDConnection; NewInstance: Boolean = False);
begin
  FNewInstance := NewInstance;

  if not FNewInstance then
    FConnection := Connection
  else
  begin
    try
      FConnection := TFDConnection.Create(AOwner);

      FConnection.DriverName := Connection.DriverName;
      FConnection.LoginPrompt := Connection.LoginPrompt;

      (* If you disconnect from the database, we don't want an Opentable to reconnect. The idea is to force the user to close and open the program again *)
      FConnection.ResourceOptions.AutoConnect := Connection.ResourceOptions.AutoConnect;

      (* For an ODBC MSSQL database, set the value of the ODBCAdvanced FDConnection parameter to MARS_Connection=YES. Otherwise,
           when you call the Open method of FDTable, you will get the following error:
           [FireDAC] [Phys] [ODBC] [Microsoft] [SQL Server Native Client 10.0] The connection is busy with the results of another command. *)
      TFDPhysMSSQLConnectionDefParams(FConnection.Params).DriverID := TFDPhysMSSQLConnectionDefParams(Connection.Params).DriverID;
      TFDPhysMSSQLConnectionDefParams(FConnection.Params).Database := TFDPhysMSSQLConnectionDefParams(Connection.Params).Database;
      TFDPhysMSSQLConnectionDefParams(FConnection.Params).UserName := TFDPhysMSSQLConnectionDefParams(Connection.Params).UserName;
      TFDPhysMSSQLConnectionDefParams(FConnection.Params).Password := TFDPhysMSSQLConnectionDefParams(Connection.Params).Password;
      TFDPhysMSSQLConnectionDefParams(FConnection.Params).Server   := TFDPhysMSSQLConnectionDefParams(Connection.Params).Server;
      TFDPhysMSSQLConnectionDefParams(FConnection.Params).MARS     := TFDPhysMSSQLConnectionDefParams(Connection.Params).MARS;

      FConnection.Connected := True;

    except
      (* Raise destroys the class *)
      raise EMoriniDB.Create(SErrorNewInstance);
    end;
  end;

  FTransaction := TFDTransaction.Create(AOwner);
  FTransaction.Connection := FConnection;

  (* These 3 properties are set to True so that if a transaction is not activated, the executed command is directly inserted into the DB *)
  FTransaction.Options.AutoCommit := True;
  FTransaction.Options.AutoStart := True;
  FTransaction.Options.AutoStop := True;

  (* If the connection is lost and it is in transaction, we rollback *) //xdCommit;
  FTransaction.Options.DisconnectAction := xdRollback;
  FTransaction.Options.Isolation := xiReadCommitted;
  (* Disabling nested transactions. We will not allow save points. *)
  FTransaction.Options.EnableNested := False;

  FExecuteSQLQuery := TFDQuery.Create(AOwner);
  FExecuteSQLQuery.Connection := FConnection;

  FOpenTableSQLQuery   := TFDQuery.Create(AOwner);
  FOpenTableDataSource := TDataSource.Create(AOwner);

  FOpenTableSQLQuery.Connection := FConnection;
  FOpenTableDataSource.DataSet  := FOpenTableSQLQuery;

  inherited Create(AOwner);
end;

destructor TDatabase.Destroy;
begin
  if Assigned(FExecuteSQLQuery) then
    FreeAndNil(FExecuteSQLQuery);

  if Assigned(FOpenTableSQLQuery) then
    FreeAndNil(FOpenTableSQLQuery);

  if Assigned(FOpenTableDataSource) then
    FreeAndNil(FOpenTableDataSource);

  if Assigned(FTransaction) then
    FreeAndNil(FTransaction);

  if FNewInstance then
    if Assigned(FConnection) then
      FreeAndNil(FConnection);

  inherited;
end;

procedure TDatabase.ActivateTransaction;
begin
  if not FConnection.Connected then
    raise EMoriniDB.Create(SErrorNotConnected);

  (* As we don't work with nested transactions, we can do this kind of test. *)
  if FConnection.InTransaction then
    raise EMoriniDB.Create(SErrorTransactionActive);

  try
    FTransaction.StartTransaction;

  except
    raise EMoriniDB.Create(SErrorOnTransaction);
  end;
end;

procedure TDatabase.ExecuteCommit;
begin
  if not FConnection.Connected then
    raise EMoriniDB.Create(SErrorNotConnected);

  (* As we don't work with nested transactions, we can do this kind of test. *)
  if not Connection.InTransaction then
    raise EMoriniDB.Create(SErrorTransactionNotActive);

  try
    FTransaction.Commit;
  except
    raise EMoriniDB.Create(SErrorOnCommit);
  end;
end;

procedure TDatabase.ExecuteRollback;
begin
  if not FConnection.Connected then
    raise EMoriniDB.Create(SErrorNotConnected);

  (* As we don't work with nested transactions, we can do this kind of test. *)
  if not Connection.InTransaction then
    raise EMoriniDB.Create(SErrorTransactionNotActive);

  try
    FTransaction.Rollback;
  except
    raise EMoriniDB.Create(SErrorOnRollback);
  end;
end;

procedure TDatabase.OpenTable(Instruction: String; FetchAll: Boolean = True);
begin
  OpenTable(FOpenTableSQLQuery, Instruction, FetchAll);
end;

procedure TDatabase.OpenTable(var pQuery: TFDQuery; Instruction: String; FetchAll: Boolean = True);
begin
  if not FConnection.Connected then
    raise EMoriniDB.Create(SErrorNotConnected);

  try
    pQuery.Close;
    pQuery.Connection := FConnection;
    pQuery.Open(Instruction);

    if FetchAll then
      pQuery.FetchAll;
  except
    raise EMoriniDB.Create(SErrorOpenTable);
  end;
end;

procedure TDatabase.ExecuteSQL(Instruction: String);
begin
  ExecuteSQL(FExecuteSQLQuery, Instruction);
end;

procedure TDatabase.ExecuteSQL(var pQuery: TFDQuery; Instruction: String);
begin
  if not FConnection.Connected then
    raise EMoriniDB.Create(SErrorNotConnected);

  try
    pQuery.Close;
    pQuery.Connection := FConnection;

    pQuery.SQL.Clear;
    pQuery.SQL.Add(Instruction);
    (* We will not run directly *)
    pQuery.ExecSQL(False);
  except
    raise EMoriniDB.Create(SErrorExecSQL);
  end;
end;

end.
