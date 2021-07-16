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
      destructor Destroy; override;
      procedure OnLogMessage(
          const Message: AnsiString;
          const Level: TLogLevel
      );
  private
      Logger: PLogger;
      LogFile: AnsiString;
      Filter: TLogLevelFilter;
      OutStream: TFileStream;
  end;

implementation

    constructor TFileLogger.Create(
        LoggerObject: PLogger;
        LogFileName: AnsiString
    );
    var
        OutMode: Word;
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

        OutMode := fmOpenWrite;
        if not FileExists(LogFile) then OutMode := OutMode or fmCreate;
        OutStream := TFileStream.Create(LogFile, OutMode);
        OutStream.Seek(0, soEnd);
    end;

    destructor TFileLogger.Destroy();
    begin
        OutStream.Free;
    end;

    procedure TFileLogger.OnLogMessage(
        const Message: AnsiString;
        const Level: TLogLevel
    );
    var
        OutString: UTF8String;
        Len: Cardinal;
    begin
        if not (Level in Filter) then Exit;
        OutString := UTF8String(Message + Chr(10));
        Len := Length(OutString);
        OutStream.WriteBuffer(OutString[1], Len);
    end;

end.
