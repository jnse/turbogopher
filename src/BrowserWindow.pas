unit BrowserWindow;

{$mode objfpc}{$H+}

interface

uses
    GopherClient,
    BrowserWidget,
    TurboGopherApplication,
    TurboGopherWindow,

    App,
    Classes,
    Objects,
    SysUtils,
    Views;

type
    PBrowserWindow = ^TBrowserWindow;
    TBrowserWindow = class(TTurboGopherWindow)
    public
        constructor Create(var TheApp: TTurboGopherApplication);
        procedure Get(url: AnsiString);
    private
        Rect: TRect;
        Win: PWindow;
        Text: AnsiString;
        Browser: PBrowserWidget;
        App: TTurboGopherApplication;
    end;

implementation

    constructor TBrowserWindow.Create(var TheApp: TTurboGopherApplication);
    begin
        App := TheApp;
        (* Figure out where to position ourselves *)
        App.GetExtent(Rect);
        Rect.Grow(0, -5); { Leave some room for the log window. }
        Rect.Move(0, -5);

        Win := New(PWindow, Init(Rect, 'TurboGopher!', wnNoNumber));
        if App.ValidView(Win) <> nil then
        begin
            Desktop^.Insert(Win);
            (* Create browser widget *)
            Win^.GetClipRect(Rect);
            Rect.Grow(-1, -1);
            Browser := New(PBrowserWidget,Init(
                TheApp,
                Rect,
                Win^.StandardScrollBar(sbHorizontal),
                Win^.StandardScrollBar(sbVertical)
            ));
            Win^.Insert(Browser);
        end;
    end;

    procedure TBrowserWindow.Get(url: AnsiString);
    var
        client: TGopherClient;
    begin
        client := App.GetClient();
        text := client.Get(url);
        Browser^.Reset();
        Browser^.Add(text);
        Browser^.Draw;
        Win^.Draw;
    end;

end.

