unit LogWindow;

{$mode objfpc}{$H+}

interface

uses
    App,
    Logger,
    TurboGopherApplication,

    Classes,
    Drivers,
    Objects,
    SysUtils,
    Views;

type

    TLogWidget = object(TScroller)
        constructor Init(
            LoggerObject: PLogger;
            Bounds: TRect;
            AHScrollBar, AVScrollBar: PScrollBar
        );
        procedure Draw; virtual;
        private
            Logger: PLogger;
            Filter: TLogLevelFilter;
    end;
    PLogWidget = ^TLogWidget;

    TLogWindow = class
    public
        constructor Create(var TheApp: TTurboGopherApplication);
        procedure OnLogMessage(
            const Message: string;
            const Level: TLogLevel
        );
    private
        App: TTurboGopherApplication;
        LogWidget: PLogWidget;
        Rect: TRect;
        Win: PWindow;
    end;

implementation

    { TLogWidget }

    constructor TLogWidget.Init(
        LoggerObject: PLogger;
        Bounds: TRect;
        AHScrollBar, AVScrollBar: PScrollBar);
    begin
        TScroller.Init(Bounds, AHScrollBar, AVScrollBar);
        GrowMode := gfGrowHiX + gfGrowHiY;
        SetLimit(Bounds.B.X, Bounds.B.Y);
        Logger := LoggerObject;
        Filter := [
            TLogLevel.debug,
            TLogLevel.info,
            TLogLevel.warning,
            TLogLevel.error,
            TLogLevel.fatal
        ];
    end;

    procedure TLogWidget.Draw;
    var
      Color: Byte;
      DrawBuffer: TDrawBuffer;
      L, Y, LineCount, LongestLine, FromLine, ToLine: SizeInt;
      LogEntries: TLogMessages;
      LogEntry: TLogMessage;
      Str: string;
    begin
        DrawBuffer := default(TDrawBuffer);
        LongestLine := 0;

        FromLine := Delta.Y;
        ToLine := FromLine + Size.Y;
        LogEntries := Logger^.GetRange(FromLine, ToLine, Filter);

        Color := GetColor($FF);
        LineCount := Length(LogEntries);

        { clear the screen }
        MoveChar(DrawBuffer, ' ', Color, Size.X);
        WriteLine(0, 0, Size.X, Size.Y, DrawBuffer);

        { render characters }
        for L := 0 to LineCount - 1 do
        begin
            Y := L;
            LogEntry := LogEntries[L];
            if Length(LogEntry.Message) > LongestLine then
                LongestLine := Length(LogEntry.Message);
            Str := Copy(LogEntry.Message, Delta.X + 1, Size.X);
            WriteStr(0, Y, Str, Color);
        end;
        SetLimit(LongestLine, Logger^.Count(Filter));
    end;

    { TLogWindow }

    constructor TLogWindow.Create(var TheApp: TTurboGopherApplication);
    begin
        App := TheApp;
        (* Figure out where we're going to put ourselves - a window height of
           5 seems like a sane default. *)
        App.GetExtent(Rect);
        Rect.A.Y := Rect.B.Y - 7; { = 5 + 2 because of the top/bottom border }
        Rect.Move(0, -2);         { move up to account for the borders }
        Win := New(PWindow, Init(Rect, 'Log messages', wnNoNumber));
        Desktop^.Insert(Win);

        Win^.GetExtent(Rect);
        Rect.Grow(-2, -1);
        LogWidget := New(
            PLogWidget,
            Init(
                App.GetLogger(),
                Rect,
                Win^.StandardScrollBar(sbHorizontal),
                Win^.StandardScrollBar(sbVertical)
            )
        );
        Win^.Insert(LogWidget);

        (* Register our callback into the logger. *)
        App.GetLogger()^.RegisterCallback(@OnLogMessage);

    end;

    procedure TLogWindow.OnLogMessage(
        const Message: string;
        const Level: TLogLevel
    );
    begin
        LogWidget^.Draw;
    end;

end.

