unit Logger;

{$mode objfpc}{$H+}

interface

uses
    SysUtils,
    Classes;

type

    TLogLevel = (debug, info, warning, error, fatal);
    TLogLevelFilter = set of TLogLevel;

    TLogMessage = record
        Level: TLogLevel;
        Message: string;
    end;

    TLogMessages = array of TLogMessage;

    TLogCallback = procedure(
        const Message: string;
        const Level: TLogLevel
    ) of object;

    TLogger = class
    public
        constructor Create;
        function Count(Filter: TLogLevelFilter): SizeInt;
        procedure Debug(const Message: AnsiString);
        procedure Error(const Message: AnsiString);
        procedure Fatal(const Message: AnsiString);
        function GetRange(
            const FromMsg, ToMsg: SizeInt;
            const Filter: TLogLevelFilter
        ): TLogMessages;
        procedure Info(const Message: AnsiString);
        procedure Log(const Message: AnsiString; const Level: TLogLevel);
        function ParseLevel(const Level: TLogLevel): AnsiString;
        procedure RegisterCallback(Callback: TLogCallback);
        procedure Warning(const Message: AnsiString);
    private
        LogMessages: TLogMessages;
        LogCallbacks: array of TLogCallback;
    end;

    PLogger = ^TLogger;

implementation

    constructor TLogger.Create;
    begin
    end;

    function TLogger.Count(Filter: TLogLevelFilter): SizeInt;
    var
        I: SizeInt;
    begin
        Result := 0;
        for I := 0 to (Length(LogMessages) - 1) do
        begin
            if LogMessages[I].Level in Filter then Result += 1;
        end;
    end;

    procedure TLogger.Debug(const Message: AnsiString);
    begin
        Log(Message, TLogLevel.debug);
    end;

    procedure TLogger.Error(const Message: AnsiString);
    begin
        Log(Message, TLogLevel.error);
    end;

    procedure TLogger.Fatal(const Message: AnsiString);
    begin
        Log(Message, TLogLevel.fatal);
    end;

    function TLogger.GetRange(
        const FromMsg, ToMsg: SizeInt;
        const Filter: TLogLevelFilter
    ): TLogMessages;
    var
        AdjustedTo, I, Len: SizeInt;
    begin
        Result := default(TLogMessages);
        Len := Length(LogMessages);
        AdjustedTo := ToMsg;
        if Len = 0 then Exit;
        if FromMsg > Len then Exit;
        if ToMsg > (Len - 1) then AdjustedTo := Len - 1;
        if AdjustedTo < FromMsg then
            raise Exception.Create(
                'TLogger.GetRange() - ToMsg has to be larger than FromMsg.'
            );
        for I := FromMsg to AdjustedTo do
        begin
            if LogMessages[I].Level in Filter then
            begin
                SetLength(Result, Length(Result) + 1);
                Result[Length(Result) - 1] := LogMessages[I];
            end;
        end;
    end;

    procedure TLogger.Info(const Message: AnsiString);
    begin
        Log(Message, TLogLevel.info);
    end;

    procedure TLogger.Log(const Message: AnsiString; const Level: TLogLevel);
    var
      NewMessage: TLogMessage;
      I: SizeInt;
    begin
        NewMessage.Message := Message;
        NewMessage.Level := Level;
        SetLength(LogMessages, Length(LogMessages) + 1);
        LogMessages[Length(LogMessages) - 1] := NewMessage;
        for I := 0 to Length(LogCallbacks) - 1 do
        begin
            LogCallbacks[I](Message, Level);
        end;
    end;

    function TLogger.ParseLevel(const Level: TLogLevel): AnsiString;
    begin
        Result := 'unknown';
        case Level of
            TLogLevel.debug: Result := 'debug';
            TLogLevel.info: Result := 'info';
            TLogLevel.warning: Result := 'warning';
            TLogLevel.error: Result := 'error';
            TLogLevel.fatal: Result := 'fatal';
        end;
    end;

    procedure TLogger.RegisterCallback(Callback: TLogCallback);
    begin
        SetLength(LogCallbacks, Length(LogCallbacks) + 1);
        LogCallbacks[Length(LogCallbacks) - 1] := Callback;
    end;

    procedure TLogger.Warning(const Message: AnsiString);
    begin
        Log(Message, TLogLevel.warning);
    end;

end.
