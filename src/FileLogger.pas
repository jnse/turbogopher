unit FileLogger;
{$mode objfpc}{$H+}

interface

uses
    Logger,

    Classes,
    SysUtils;

type

  TFileLogger = class
  public
      constructor Create(LoggerObject: PLogger; LogFileName: AnsiString);
      procedure OnLogMessage(
          const Message: string;
          const Level: TLogLevel
      );
  private
      Logger: PLogger;
      LogFile: AnsiString;
      Filter: TLogLevelFilter;
  end;

implementation

    constructor TFileLogger.Create(
        LoggerObject: PLogger;
        LogFileName: AnsiString
    );
    begin
        Logger := LoggerObject;
        LogFile := LogFileName;
        Filter := [
            TLogLevel.debug,
            TLogLevel.info,
            TLogLevel.warning,
            TLogLevel.error,
            TLogLevel.fatal
        ];
        Logger^.RegisterCallback(@OnLogMessage);
    end;

    procedure TFileLogger.OnLogMessage(
        const Message: string;
        const Level: TLogLevel
    );
    var
        OutStream: TFileStream;
    begin
        if not (Level in Filter) then Exit;
        OutStream := TFileStream.Create(LogFile, fmCreate or fmOpenWrite);
        OutStream.WriteAnsiString(Message + '#10');
        OutStream.Free;
    end;

end.
