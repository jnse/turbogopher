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
        procedure AppendHistory(url: AnsiString);
        procedure Close; virtual;
        procedure CloseReal;
        procedure Draw; virtual;
        procedure Get(url: AnsiString);
        function GetCaption: AnsiString;
        procedure HandleEvent(var Event: TEvent); virtual;
        procedure PositionWidgets;
        procedure SetCaption(NewTitle: AnsiString);
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
        procedure Close;
        procedure Get(url: AnsiString);
        function GetHistory: TStringArray;
        function GetNumber: Integer;
        function GetTitle: AnsiString;
        procedure SetNumber(NewNumber: Integer);
        procedure SetTitle(NewTitle: AnsiString);
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
    Self.Flags := Self.Flags or ofTileable;
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
    Rect.Grow(-3, -1);
    Rect.Move(2, 0);
    Browser := New(PBrowserWidget, Init(
        TheApp,
        SideBar,
        Rect,
        StandardScrollBar(sbHorizontal),
        StandardScrollBar(sbVertical)
    ));
    Insert(Browser);
    PositionWidgets;
end;

procedure TBrowserView.AppendHistory(url: AnsiString);
begin
    SetLength(History, Length(History) + 1);
    History[Length(History) - 1] := url;
end;

procedure TBrowserView.Close;
begin
    App.CloseBrowserWindow(Number);
end;

procedure TBrowserView.CloseReal;
begin
    inherited Close;
end;

procedure TBrowserView.Draw;
begin
    PositionWidgets;
    inherited Draw;
end;

function TBrowserView.GetCaption: AnsiString;
begin
    Result := GetTitle(255);
end;

procedure TBrowserView.HandleEvent(var Event: TEvent);
var
    Bounds: TRect;
    SelectedItem: PGopherMenuItem = nil;
    Url: AnsiString = '';
begin
    inherited HandleEvent(Event);
    Bounds := Default(TRect);
    case Event.What of
        evBroadcast:
        begin
            {App.GetLogger^.Debug('Received broadcast: ' + IntToStr(Event.Command));}
            case Event.Command of
                cmReceivedFocus:
                begin
                    App.SetActiveBrowserWindow(Number);
                end;
            end;
        end;
        evKeyDown:
        begin
            case Event.KeyCode of
                kbAltLeft:
                begin
                    if HistoryIndex > 0 then
                    begin
                        HistoryIndex := HistoryIndex - 1;
                        Get(History[HistoryIndex]);
                    end;
                end;
                kbAltRight:
                begin
                    if HistoryIndex < (Length(History) - 1) then
                    begin
                        HistoryIndex := HistoryIndex + 1;
                        Get(History[HistoryIndex]);
                    end;
                end;
                kbAltUp:
                begin
                    SideBar^.SelectPrevious(Browser^);
                    ClearEvent(Event);
                    Draw;
                end;
                kbAltDown:
                begin
                    SideBar^.SelectNext(Browser^);
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
        SideBar^.SelectFirst(Browser^);
        SetCaption(IntToStr(Number) + ': ' + url);
    end;
end;

procedure TBrowserView.PositionWidgets;
var
    WinRect, BrowserRect, SidebarRect : TRect;
begin
    WinRect := default(TRect);
    BrowserRect := default(TRect);
    SidebarRect := default(TRect);
    GetBounds(WinRect);
    SidebarRect := WinRect;
    SideBarRect.B.X := 8;
    SideBarRect.B.Y := SideBarRect.B.Y - 1;
    BrowserRect := WinRect;
    BrowserRect.A.X := 8;
    BrowserRect.B.X := BrowserRect.B.X - 1;
    BrowserRect.B.Y := BrowserRect.B.Y - 1;
    SideBar^.SetBounds(SidebarRect);
    Browser^.SetBounds(BrowserRect);
end;

procedure TBrowserView.SetCaption(NewTitle: AnsiString);
var
    TmpTitle: ShortString;
begin
    TmpTitle := NewTitle; (* Cast by assigning to temp. This will truncate to 255 chars. *)
    DisposeStr(Title);
    Title := NewStr(TmpTitle);
    Draw;
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

procedure TBrowserWindow.Close;
begin
    Win^.CloseReal;
end;

procedure TBrowserWindow.Get(url: AnsiString);
begin
    Win^.Get(url);
    Win^.AppendHistory(url);
    if (Length(Win^.History) > 1) then
        Win^.HistoryIndex := Win^.HistoryIndex + 1;
end;

function TBrowserWindow.GetHistory: TStringArray;
begin
    Result := Win^.History;
end;

function TBrowserWindow.GetNumber: Integer;
begin
    Result := Win^.Number;
end;

function TBrowserWindow.GetTitle: AnsiString;
begin
    Result := Win^.GetCaption;
end;

procedure TBrowserWindow.SetNumber(NewNumber: Integer);
begin
    Win^.Number := NewNumber;
end;

procedure TBrowserWindow.SetTitle(NewTitle: AnsiString);
begin
    Win^.SetCaption(NewTitle);
end;

end.

