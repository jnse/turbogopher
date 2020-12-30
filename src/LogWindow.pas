unit LogWindow;

{$mode objfpc}{$H+}

interface

uses

    Logger,
    TurboGopherApplication,
    TurboGopherWindow,

    App,
    Classes,
    CustApp,
    Drivers,
    Objects,
    SysUtils,
    Views;

type

    PCustomApplication = ^TCustomApplication;

    TLogWidget = object(TScroller)
        constructor Init(
            LoggerObject: PLogger;
            Bounds: TRect;
            AHScrollBar, AVScrollBar: PScrollBar
        );
        procedure Draw; virtual;
        procedure ScrollToBottom;
        private
            var LineCount: SizeInt;
            var Logger: PLogger;
            var Filter: TLogLevelFilter;
            const defaultAttrs = $1f;
    end;
    PLogWidget = ^TLogWidget;

    TLogWindow = class(TTurboGopherWindow)
    public

        constructor Init(TheApp: TTurboGopherApplication); virtual;
        procedure OnLogMessage(
            const Message: string;
            const Level: TLogLevel
        );
    private
        LogWidget: PLogWidget;
        Rect: TRect;
        Win: PWindow;
        var App: TTurboGopherApplication;
    end;
    PLogWindow = ^TLogWindow;

implementation

    uses
        DrawUtils;

    { TLogWidget }

    constructor TLogWidget.Init(
        LoggerObject: PLogger;
        Bounds: Objects.TRect;
        AHScrollBar, AVScrollBar: PScrollBar);
    begin
        LineCount := 0;
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
      L, Y, LongestLine, FromLine, ToLine: SizeInt;
      LogEntries: TLogMessages;
      LogEntry: TLogMessage;
      Str: string;
    begin
        DrawBuffer := default(TDrawBuffer);
        LongestLine := 0;

        FromLine := Delta.Y;
        ToLine := FromLine + Size.Y;
        LogEntries := Logger^.GetRange(FromLine, ToLine, Filter);

        Color := defaultAttrs;
        LineCount := Length(LogEntries);

        { clear the screen }
        MoveChar(DrawBuffer, ' ', Color, Size.X);
        WriteLine(0, 0, Size.X, Size.Y, DrawBuffer);
        DrawBuffer := default(TDrawBuffer);

        { render characters }
        for L := 0 to LineCount - 1 do
        begin
            Y := L;
            LogEntry := LogEntries[L];
            if Length(LogEntry.Message) > LongestLine then
                LongestLine := Length(LogEntry.Message);
            Str := Copy(LogEntry.Message, Delta.X + 1, Size.X);
            case LogEntry.Level of
                TLogLevel.debug: Color := (Hi(Color) * 16) + 2;
                TLogLevel.info: Color := (Hi(Color) * 16) + 15;
                TLogLevel.warning: Color := (Hi(Color) * 16) + 6;
                TLogLevel.error: Color := (Hi(Color) * 16) + 12;
                TLogLevel.fatal: Color := (4 * 16) + 0;
            end;
            MoveStr(DrawBuffer, Str, Color);
            WriteBuf(0, Y, Length(Str), 1, DrawBuffer);
        end;
        SetLimit(LongestLine, Logger^.Count(Filter));
    end;

    procedure TLogWidget.ScrollToBottom;
    begin
        ScrollTo(0, LineCount);
        Draw;
    end;

    { TLogWindow }

    constructor TLogWindow.Init(TheApp: TTurboGopherApplication);
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
        LogWidget := New(PLogWidget, Init(
            App.GetLogger(),
            Rect,
            Win^.StandardScrollBar(sbHorizontal),
            Win^.StandardScrollBar(sbVertical)
        ));
        if LogWidget = nil then
            raise Exception.Create('Could not instantiate log widget.');
        Win^.Insert(LogWidget);
        (* Register our callback into the logger. *)
        App.GetLogger()^.RegisterCallback(@OnLogMessage);
    end;

    procedure TLogWindow.OnLogMessage(
        const Message: string;
        const Level: TLogLevel
    );
    begin
        LogWidget^.ScrollToBottom;
        LogWidget^.Draw;
        Win^.Draw;
    end;

end.

