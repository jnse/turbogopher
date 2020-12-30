unit BrowserWindow;

{$mode objfpc}{$H+}

interface

uses
    GopherClient,
    BrowserWidget,
    SideBarWidget,
    TurboGopherApplication,
    TurboGopherWindow,
    StringUtils,

    App,
    Classes,
    Drivers,
    Objects,
    SysUtils,
    Views;

type

    PBrowserView = ^TBrowserView;
    TBrowserView = object(TWindow)
        constructor Init(var TheApp: TTurboGopherApplication; Rect: TRect);
        procedure Get(url: AnsiString);
        procedure AppendHistory(url: AnsiString);
        procedure HandleEvent(var Event: TEvent); virtual;
        var
            App: TTurboGopherApplication;
            Browser: PBrowserWidget;
            SideBar: PSideBarWidget;
            History: array of AnsiString;
            HistoryIndex: SizeInt;
    end;

    PBrowserWindow = ^TBrowserWindow;
    TBrowserWindow = class(TTurboGopherWindow)
    public
        constructor Create(var TheApp: TTurboGopherApplication);
        procedure Get(url: AnsiString);
        function GetHistory: TStringArray;
    private
        Rect: TRect;
        Win: PBrowserView;
        App: TTurboGopherApplication;
    end;

implementation

{ TBrowserView }

constructor TBrowserView.Init(var TheApp: TTurboGopherApplication; Rect: TRect);
begin
    inherited Init(Rect, 'TurboGopher!', wnNoNumber);
    App := TheApp;
    HistoryIndex := 0;
    (* Create sidebar widget *)
    GetClipRect(Rect);
    Rect.Assign(Rect.A.X + 1, Rect.A.Y + 1, 9, Rect.B.Y - 1);
    SideBar := New(PSideBarWidget, Init(
        TheApp,
        Rect
    ));
    Insert(SideBar);
    (* Create browser widget *)
    GetClipRect(Rect);
    Rect.Grow(-8, -1);
    Rect.Move(2, 0);
    Browser := New(PBrowserWidget, Init(
        TheApp,
        SideBar,
        Rect,
        StandardScrollBar(sbHorizontal),
        StandardScrollBar(sbVertical)
    ));
    Insert(Browser);
end;

procedure TBrowserView.AppendHistory(url: AnsiString);
var I : SizeInt;
begin
    InsertAt(History, url, HistoryIndex + 1);
    for I := 0 to Length(History) - 1 do
        App.GetLogger^.Debug('History[' + IntToStr(I) + '] = ' + History[I]);
end;

procedure TBrowserView.HandleEvent(var Event: TEvent);
var
    Bounds: TRect;
    SelectedItem: PGopherMenuItem = nil;
    Url: AnsiString = '';
begin
    Bounds := Default(TRect);
    inherited HandleEvent(Event);
    case Event.What of
        evKeyDown:
        begin
            case Event.KeyCode of
                kbAltLeft:
                begin
                    if HistoryIndex > 0 then
                    begin
                        HistoryIndex := HistoryIndex - 1;
                        Get(History[HistoryIndex]);
                        App.GetLogger^.Debug('History index = ' + IntToStr(HistoryIndex));
                    end;
                end;
                kbAltRight:
                begin
                    if HistoryIndex < (Length(History) - 1) then
                    begin
                        HistoryIndex := HistoryIndex + 1;
                        Get(History[HistoryIndex]);
                        App.GetLogger^.Debug('History index = ' + IntToStr(HistoryIndex));
                    end;
                end;
                kbAltUp:
                begin
                    SideBar^.SelectPrevious;
                    ClearEvent(Event);
                    Draw;
                end;
                kbAltDown:
                begin
                    SideBar^.SelectNext;
                    ClearEvent(Event);
                    Draw;
                end;
                kbEnter:
                begin
                    SelectedItem := SideBar^.GetSelected;
                    if SelectedItem <> nil then
                    begin
                        Url := 'gopher://' + SelectedItem^.Host + ':'
                               + SelectedItem^.Port + '/' + SelectedItem^.ItemType + '/'
                               + SelectedItem^.SelectorString;
                        Get(Url);
                        AppendHistory(Url);
                        HistoryIndex := HistoryIndex + 1;
                        App.GetLogger^.Debug('History index = ' + IntToStr(HistoryIndex));
                    end;
                end;
                kbUp:
                begin
                    Browser^.ScrollTo(Browser^.Delta.X, Browser^.Delta.Y - 1);
                    ClearEvent(Event);
                end;
                kbDown:
                begin
                    Browser^.ScrollTo(Browser^.Delta.X, Browser^.Delta.Y + 1);
                    ClearEvent(Event);
                end;
                kbLeft:
                begin
                    Browser^.ScrollTo(Browser^.Delta.X - 1, Browser^.Delta.Y);
                    ClearEvent(Event);
                end;
                kbRight:
                begin
                    Browser^.ScrollTo(Browser^.Delta.X + 1, Browser^.Delta.Y);
                    ClearEvent(Event);
                end;
                kbPgUp:
                begin
                    Browser^.GetBounds(Bounds);
                    Browser^.ScrollTo(Browser^.Delta.X, Browser^.Delta.Y - (Bounds.B.Y - 2));
                    ClearEvent(Event);
                end;
                kbPgDn:
                begin
                    Browser^.GetBounds(Bounds);
                    Browser^.ScrollTo(Browser^.Delta.X, Browser^.Delta.Y + (Bounds.B.Y - 2));
                    ClearEvent(Event);
                end;

            end;
        end;
    end;
end;

procedure TBrowserView.Get(url: AnsiString);
var
    Client: TGopherClient;
    MenuItems: TGopherMenuItems;
    I: SizeInt = 0;
begin
    Client := App.GetClient();
    MenuItems := Client.Get(url);
    if (MenuItems <> nil) then
    begin
        Browser^.Reset;
        Sidebar^.Reset;
        for I := 0 to Length(MenuItems) - 1 do
        begin
            Browser^.Add(MenuItems[I].DisplayString);
        end;
        SideBar^.SetItems(MenuItems);
        Draw;
    end;
end;

{ TBrowserWindow }

constructor TBrowserWindow.Create(var TheApp: TTurboGopherApplication);
begin
    App := TheApp;
    (* Figure out where to position ourselves *)
    App.GetExtent(Rect);
    Rect.Grow(0, -5); { Leave some room for the log window. }
    Rect.Move(0, -5);
    Win := New(PBrowserView, Init(App, Rect));
    if App.ValidView(Win) <> nil then
    begin
        Desktop^.Insert(Win);
    end;
end;

procedure TBrowserWindow.Get(url: AnsiString);
begin
    Win^.Get(url);
    Win^.AppendHistory(url);
    Win^.HistoryIndex := Win^.HistoryIndex + 1;
end;

function TBrowserWindow.GetHistory: TStringArray;
begin
    Result := Win^.History;
end;

end.

