unit MainWindow;

{$mode objfpc}{$H+}

interface

uses
    App,
    Classes,
    SysUtils,
    Objects,
    Views,
    TurboGopherApplication,
    GopherClient,
    BrowserWidget;
type
    TMainWindow = class
    private
        Rect: TRect;
        Win: PWindow;
        App: TTurboGopherApplication;
        Text: AnsiString;
        Browser: PBrowserWidget;
    public
        constructor Create(var TheApp: TTurboGopherApplication);
        procedure Get();
    end;

implementation

    constructor TMainWindow.Create(var TheApp: TTurboGopherApplication);
    begin
        App := TheApp;
        Rect.Assign(0, 0, 60, 20);
        Win := New(PWindow, Init(Rect, 'TurboGopher!', wnNoNumber));
        if App.ValidView(Win) <> nil then
        begin
            Desktop^.Insert(Win);

            (* Create browser widget *)
            Win^.GetClipRect(Rect);
            Rect.Grow(-1, -1);
            Browser := New(PBrowserWidget, Init(
                Rect,
                Win^.StandardScrollBar(sbHorizontal),
                Win^.StandardScrollBar(sbVertical)
            ));
            Win^.Insert(Browser);
        end;
    end;

    procedure TMainWindow.Get();
    var
        url: string;
        client: TGopherClient;
    begin
        client := App.GetClient();
        url := 'gopher://sdf.org';
        text := client.Get(url);
        Browser^.Add(text);
    end;

end.

