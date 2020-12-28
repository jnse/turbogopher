unit GoWindow;

{$mode objfpc}{$H+}

interface

uses
    TurboGopherApplication,
    TurboGopherWindow,

    App,
    Classes,
    Dialogs,
    Drivers,
    Objects,
    SysUtils,
    Views;

type
    PGoDialog = ^TGoDialog;
    TGoDialog = object(TDialog)
        constructor Init(
            var TheApp: TTurboGopherApplication;
            Rect: TRect;
            Caption: AnsiString);
        var
            App: TTurboGopherApplication;
            TxtUrl: PInputLine;
    end;

    PGoWindow = ^TGoWindow;
    TGoWindow = class(TTurboGopherWindow)
    private
        Rect: TRect;
        Win: PGoDialog;
        App: TTurboGopherApplication;
        procedure Center;
    public
        constructor Create(var TheApp: TTurboGopherApplication);
        procedure Show();
    end;

implementation

const
    Width: Integer = 40;
    Height: Integer = 5;

(* TGoDialog *)

constructor TGoDialog.Init(
    var TheApp: TTurboGopherApplication;
    Rect: TRect;
    Caption: AnsiString);
var
    TmpRect: TRect;
const
    OkButtonWidth: Integer = 5;
    OkButtonHeight: Integer = 2;
begin
    inherited Init(Rect, Caption);
    App := TheApp;
    (* Create URL input box. *)
    TmpRect.Assign(
        1,
        2,
        Width - 1 - OkButtonWidth - 1,
        3
    );
    TxtUrl := New(PInputLine, Init(TmpRect, 2083));
    (* Create text label. *)
    TmpRect.Assign(1, 1, 11, 2);
    Insert(New(PStaticText, Init(TmpRect, 'Enter URL:')));
    Insert(TxtUrl);
    (* Create OK button. *)
    TmpRect.Assign(
        Width - OkButtonWidth - 1,
        Height - OkButtonHeight - 1,
        Width - 1, Height - 1
    );
    Insert(New(PButton, Init(TmpRect, 'O~k~', cmOk, bfDefault)));
    TxtUrl^.MakeFirst;
end;

(* TGoWindow *)

constructor TGoWindow.Create(var TheApp: TTurboGopherApplication);
var
    TmpRect: TRect;
begin
    App := TheApp;
    (* Create and center window. *)
    Center();
    Win := New(PGoDialog, Init(TheApp, Rect, 'Go to URL'));
end;

procedure TGoWindow.Show();
var
    Data: AnsiString = '';
begin
    if App.ValidView(Win) <> nil then
    begin
        Center();
        Win^.TxtUrl^.SetData(Data);
        Desktop^.ExecView(Win);
        App.Go(Win^.TxtUrl^.Data^);
    end;
end;

procedure TGoWindow.Center();
var
    x1, y1, x2, y2: Integer;
begin
    App.GetExtent(Rect);
    x1 := Round(Rect.B.X/2) - Round(width/2);
    y1 := Round(Rect.B.Y/2) - Round(height/2);
    x2 := x1 + width;
    y2 := y1 + height;
    Rect.Assign(x1, y1, x2, y2);
end;

end.
