unit MainWindow;

{$mode objfpc}{$H+}

interface

uses
  App,
  Classes,
  SysUtils,
  Objects,
  Views,
  TurboGopherApplication;

type
    TMainWindow = class
    private
        Rect: TRect;
        Win: PWindow;
        App: TTurboGopherApplication;
    public
        constructor Create(var TheApp: TTurboGopherApplication);
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
      end;
    end;

end.

