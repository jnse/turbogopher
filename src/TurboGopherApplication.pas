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

type

    TTGApp = object(TApplication)
        constructor Init;
        procedure InitStatusLine; virtual;
        procedure InitMenuBar; virtual;
    end;

    TTurboGopherApplication = class(TCustomApplication)
    public
        constructor Create(TheOwner: TComponent); override;
        destructor Destroy; override;
        function GetClient(): TGopherClient;
        procedure GetExtent(var Extent: Objects.TRect);
        function GetLogger(): PLogger;
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

implementation

    uses
        LogWindow,
        MainWindow;

    var
        FLogWindow: TLogWindow;
        FMainWindow: TMainWindow;

    { TTGApp }

    constructor TTGApp.Init;
    begin
        inherited init;
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
                        ), nil 
                    )   
                )   
            )   
        );  
    end;

    { TTurboGopherApplication }

    constructor TTurboGopherApplication.Create(TheOwner: TComponent);
    begin
      inherited Create(TheOwner);
      StopOnException := True;
      TurboGraphicsApplication.Init;
      Logger := TLogger.Create;
      FileLogger := TFileLogger.Create(@Logger, '/tmp/turbogopher_debug.txt');
      Client := TGopherClient.Create(@Logger);
      FLogWindow := TLogWindow.Create(Self);
      FMainWindow := TMainWindow.Create(Self);
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
        { TEST }
        FMainWindow.Get;
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

    procedure TTurboGopherApplication.GetExtent(Var Extent: Objects.TRect);
    begin
        TurboGraphicsApplication.GetExtent(Extent);
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
