unit BrowserWindowFactory;

{$mode objfpc}

interface

uses

    BrowserWindow,
    TurboGopherApplication,

    fgl,
    sysutils;

type

    TBrowserWindowList = specialize TFPGList<TBrowserWindow>;
    TBrowserWindowFactory = class
        constructor Create(var TheApp: TTurboGopherApplication);
        procedure CloseAll;
        procedure CloseBrowserWindow(WindowNumber: Integer);
        procedure GetActive(var BrowserWindow: TBrowserWindow);
        procedure NewBrowser;
        procedure SetActive(NewActiveWindowNumber: Integer);

        private
            Instances: TBrowserWindowList;
            ActiveIndex: SizeInt;
            App: TTurboGopherApplication;
    end;

implementation

{ TBrowserWindowFactory }

constructor TBrowserWindowFactory.Create(var TheApp: TTurboGopherApplication);
begin
    Instances := TBrowserWindowList.Create;
    ActiveIndex := 0;
    App := TheApp;
end;

procedure TBrowserWindowFactory.CloseAll;
var
    N: SizeInt;
begin
    for N := 0 to Instances.Count -1 do
        Instances.Items[N].Close;
    Instances.Clear;
    ActiveIndex := 0;
end;

procedure TBrowserWindowFactory.CloseBrowserWindow(WindowNumber: Integer);
var
    BrowserWindow: TBrowserWindow;
begin
    if WindowNumber > Instances.Count - 1 then Exit;
    if WindowNumber < 0 then Exit;
    BrowserWindow := Instances.Extract(Instances.Items[WindowNumber]);
    BrowserWindow.Close;
    ActiveIndex := Instances.Count - 1;
end;

procedure TBrowserWindowFactory.GetActive(var BrowserWindow: TBrowserWindow);
begin
    if Instances.Count < 1 then raise Exception.Create('There are no browser windows open.');
    if ActiveIndex > Instances.Count - 1 then ActiveIndex := Instances.Count - 1;
    BrowserWindow := Instances.Items[ActiveIndex];
end;

procedure TBrowserWindowFactory.NewBrowser;

begin
    Instances.Add(TBrowserWindow.Create(App));
    ActiveIndex := Instances.Count - 1;
    Instances.Items[ActiveIndex].SetNumber(ActiveIndex);
end;

procedure TBrowserWindowFactory.SetActive(NewActiveWindowNumber: Integer);
begin
    if NewActiveWindowNumber > Instances.Count - 1 then
        NewActiveWindowNumber := Instances.Count - 1;
    ActiveIndex := NewActiveWindowNumber;
end;

end.
