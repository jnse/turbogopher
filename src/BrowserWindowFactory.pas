unit BrowserWindowFactory;

interface

uses

    BrowserWindow,
    TurboGopherApplication;

type

    TBrowserWindowFactory = class
        constructor Create(var TheApp: TTurboGopherApplication);
        function GetActive: PBrowserWindow;
        procedure NewBrowser;

        private
            Instances: array of TBrowserWindow;
            ActiveIndex: SizeInt;
            App: TTurboGopherApplication;
    end;

implementation

{ TBrowserWindowFactory }

constructor TBrowserWindowFactory.Create(var TheApp: TTurboGopherApplication);
begin
    ActiveIndex := 0;
    App := TheApp;
end;

function TBrowserWindowFactory.GetActive: PBrowserWindow;
begin
    Result := nil;
    if Length(Instances) < 1 then Exit;
    if ActiveIndex > Length(Instances) - 1 then ActiveIndex := Length(Instances) - 1;
    Result := @Instances[ActiveIndex];
end;

procedure TBrowserWindowFactory.NewBrowser;
begin
    SetLength(Instances, Length(Instances) + 1);
    Instances[Length(Instances) -1] := TBrowserWindow.Create(App);
    ActiveIndex := Length(Instances);
end;

end.
