unit TurboGopherApplication;

{$mode objfpc}{$H+}

interface

uses
  App,
  Objects,
  Classes,
  CustApp,
  Drivers,
  FileLogger,
  Logger,
  Views,
  Menus,
  SysUtils,
  GopherClient;

const cmGo = 1000;

type

    TTGApp = object(TApplication)
        constructor Init;
        procedure HandleEvent(var Event: TEvent); virtual;
        procedure InitStatusLine; virtual;
        procedure InitMenuBar; virtual;
    end;

    TTurboGopherApplication = class(TCustomApplication)
    public
        constructor Create(TheOwner: TComponent); override;
        destructor Destroy; override;
        procedure CreateBrowserWindow;
        function GetClient(): TGopherClient;
        procedure GetExtent(var Extent: Objects.TRect);
        function GetLogger(): PLogger;
        procedure Go(Url: AnsiString);
        function ValidView(P: PView): PView;
        procedure WriteHelp; virtual;
    protected
        procedure DoRun; override;
    private
        TurboGraphicsApplication: TTGApp;
        Client: TGopherClient;
        Logger: TLogger;
        FileLogger: TFileLogger;
    end;

    PTurboGopherApplication = ^TTurboGopherApplication;

implementation

    uses
        LogWindow,
        BrowserWindow,
        GoWindow;

    var
        FLogWindow: TLogWindow;
        FGoWindow: TGoWindow;
        FBrowserWindows: array of TBrowserWindow;
        ActiveBrowserWindow: SizeInt;

    { TTGApp }

    constructor TTGApp.Init;
    begin
        inherited init;
    end;

    procedure TTGApp.HandleEvent(var Event: TEvent);
        begin
            inherited HandleEvent(Event);
            if Event.What = evCommand then
                case Event.Command of
                    cmGo:
                    begin
                        FGoWindow.Show();
                    end;
            end;
            ClearEvent(Event);
        end;

    procedure TTGApp.InitStatusLine;
    var
        Rect: Objects.TRect;
    begin
        Rect := default(Objects.TRect);
        GetExtent(Rect);
        Rect.A.Y := Rect.B.Y - 1;
        StatusLine := New(
            PStatusLine, Init(
                Rect, NewStatusDef(0, $FFFF,
                    NewStatusKey('~Alt+X~ Quit application', kbAltX, cmQuit,
                        NewStatusKey('~F10~ Menu', kbF10, cmMenu,
                            NewStatusKey('~F1~ Help', kbF1, cmHelp, nil)
                        )
                    ), nil
                )
            )
        );
    end;

    procedure TTGApp.InitMenuBar;
    var 
        Rect: Objects.TRect;
    begin
        Rect := default(Objects.TRect);
        GetExtent(Rect);
        Rect.B.Y := Rect.A.Y + 1;
        MenuBar := New(
            PMenuBar,
            Init(
                Rect,
                NewMenu(
                    NewSubMenu('~F~ile', hcNoContext,
                        NewMenu(
                            NewItem('~Q~uit', 'Alt-X', kbAltX, cmQuit, hcNoContext, nil)
                        ),
                        NewSubMenu('~B~rowse', hcNoContext,
                            NewMenu(
                                NewItem('~G~o', 'Alt-G', kbAltG, cmGo, hcNoContext, nil)
                            ), nil
                        )
                    )   
                )   
            )   
        );  
    end;

    { TTurboGopherApplication }

    constructor TTurboGopherApplication.Create(TheOwner: TComponent);
    begin
      inherited Create(TheOwner);
      ActiveBrowserWindow := 0;
      StopOnException := True;
      TurboGraphicsApplication.Init;
      Logger := TLogger.Create;
      FileLogger := TFileLogger.Create(@Logger, '/tmp/turbogopher_debug.txt');
      Client := TGopherClient.Create(@Logger);
      FLogWindow := TLogWindow.Init(Self);
      FGoWindow := TGoWindow.Create(Self);
      CreateBrowserWindow;
    end;

    procedure TTurboGopherApplication.CreateBrowserWindow;
    begin
        SetLength(FBrowserWindows, Length(FBrowserWindows) + 1);
        FBrowserWindows[Length(FBrowserWindows) -1] := TBrowserWindow.Create(Self);
        ActiveBrowserWindow := Length(FBrowserWindows);
    end;

    procedure TTurboGopherApplication.DoRun;
    var
        ErrorMsg: String;
    begin
        { quick check parameters }
        ErrorMsg:=CheckOptions('h', 'help');
        if ErrorMsg<>'' then
        begin
             ShowException(Exception.Create(ErrorMsg));
             Terminate;
             Exit;
        end;
        { parse parameters }
        if HasOption('h', 'help') then
        begin
             WriteHelp;
             Terminate;
             Exit;
        end;
        { Run TG app }
        TurboGraphicsApplication.Run;
        { Clean shutdown }
        TurboGraphicsApplication.Done;
        Terminate;
    end;

    destructor TTurboGopherApplication.Destroy;
    begin
      inherited Destroy;
    end;

    function TTurboGopherApplication.GetClient(): TGopherClient;
    begin
        result := Client;
    end;

    function TTurboGopherApplication.GetLogger(): PLogger;
    begin
        Result := @Logger;
    end;

    procedure TTurboGopherApplication.GetExtent(var Extent: Objects.TRect);
    begin
        TurboGraphicsApplication.GetExtent(Extent);
    end;

    procedure TTurboGopherApplication.Go(Url: AnsiString);
    begin
        if (Length(FBrowserWindows) < 1) then
        begin
             Logger.Error('No browser window open.');
             Exit;
        end;
        if (ActiveBrowserWindow > Length(FBrowserWindows)) then
        begin
             ActiveBrowserWindow := Length(FBrowserWindows);
        end;
        FBrowserWindows[ActiveBrowserWindow - 1].Get(Url);
    end;

    function TTurboGopherApplication.ValidView(P: PView) : PView;
    begin
        result := TurboGraphicsApplication.ValidView(P);
    end;

    procedure TTurboGopherApplication.WriteHelp;
    begin
      { add your help code here }
      writeln('Usage: ', ExeName, ' -h');
    end;

end.
