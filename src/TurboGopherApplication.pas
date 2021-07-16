unit TurboGopherApplication;

{$mode objfpc}{$H+}

interface

uses
    FileLogger,
    GopherClient,
    Logger,

    App,
    Objects,
    Classes,
    CustApp,
    Dialogs,
    Drivers,
    Views,
    Menus,
    SysUtils;

const
    cmGo = 1000;
    cmNewBrowser = 1001;

type

    TTGApp = object(TApplication)
        constructor Init;
        procedure HandleEvent(var Event: TEvent); virtual;
        procedure InitStatusLine; virtual;
        procedure InitMenuBar; virtual;
        private
            WindowMenu: PMenu;
    end;

    PTurboGopherApplication = ^TTurboGopherApplication;
    TTurboGopherApplication = class(TCustomApplication)
    public
        constructor Create(TheOwner: TComponent); override;
        destructor Destroy; override;
        procedure CloseBrowserWindow(WindowNumber: Integer);
        procedure CreateBrowserWindow;
        procedure Draw;
        function ExecuteDialog(P: PDialog; Data: Pointer): Word;
        function GetClient(): TGopherClient;
        procedure GetExtent(var Extent: Objects.TRect);
        function GetLogger(): PLogger;
        procedure Go(Url: AnsiString);
        procedure SetActiveBrowserWindow(WindowNumber: Integer);
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
        BrowserWindow,
        BrowserWindowFactory,
        GoWindow;

    var
        FLogger: PLogger = nil;
        FApplication: PTurboGopherApplication = nil;
        FLogWindow: TLogWindow;
        FGoWindow: TGoWindow;
        FBrowserWindowFactory: TBrowserWindowFactory;

    { TTGApp }

    constructor TTGApp.Init;
    begin
        inherited init;
    end;

    procedure TTGApp.HandleEvent(var Event: TEvent);
    begin
        inherited HandleEvent(Event);
        case Event.What of
            evBroadcast:
            begin
                {
                if FLogger <> nil then
                    FLogger^.Debug('APP Received broadcast: ' + IntToStr(Event.Command));
                }
            end;
            evCommand:
            begin
                case Event.Command of
                    cmGo:
                    begin
                        FGoWindow.Show();
                        ClearEvent(Event);
                    end;
                    cmNewBrowser:
                    begin
                        if FApplication <> nil then
                        begin
                             FApplication^.CreateBrowserWindow;
                        end;
                    end;
                    cmCloseAll:
                    begin
                        FBrowserWindowFactory.CloseAll;
                    end;
                    cmCascade:
                    begin
                        FLogger^.Debug('Received cascade');
                    end;
                    cmTile:
                    begin
                        FLogger^.Debug('Received tile');
                    end;
                end;
            end;
        end;
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
        WindowMenu := NewMenu(
            NewItem('~N~ew browser window', 'Ctrl-T', kbCtrlT, cmNewBrowser, hcNoContext,
                StdWindowMenuItems(nil))
        );
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
                            ),
                            NewSubMenu('~W~indow', hcNoContext, WindowMenu, nil)
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
        StopOnException := True;
        TurboGraphicsApplication.Init;
        Logger := TLogger.Create;
        FLogger := @Logger;
        FileLogger := TFileLogger.Create(@Logger, '/tmp/turbogopher_debug.txt');
        FBrowserWindowFactory := TBrowserWindowFactory.Create(Self);
        Client := TGopherClient.Create(@Logger);
        FLogWindow := TLogWindow.Init(Self);
        FGoWindow := TGoWindow.Create(Self);
    end;

    procedure TTurboGopherApplication.CloseBrowserWindow(WindowNumber: Integer);
    begin
        FBrowserWindowFactory.CloseBrowserWindow(WindowNumber);
    end;

    procedure TTurboGopherApplication.CreateBrowserWindow;
    begin
        FBrowserWindowFactory.NewBrowser;
        if TurboGraphicsApplication.WindowMenu = nil then Exit;

    end;

    procedure TTurboGopherApplication.Draw;
    begin
        TurboGraphicsApplication.Draw;
    end;

    procedure TTurboGopherApplication.DoRun;
    var
        ErrorMsg: String;
    begin
        FApplication := @Self;
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
        CreateBrowserWindow;
        TurboGraphicsApplication.Run;
        { Clean shutdown }
        try
            TurboGraphicsApplication.Done;
        except
            on E: Exception do
                Writeln('Clean shutdown failed.');
        end;
        Terminate;
    end;

    destructor TTurboGopherApplication.Destroy;
    begin
      inherited Destroy;
    end;

    function TTurboGopherApplication.ExecuteDialog(P: PDialog; Data: Pointer): Word;
    begin
        Result := TurboGraphicsApplication.ExecuteDialog(P, Data);
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
    var Browser: TBrowserWindow;
    begin
        Browser := default(TBrowserWindow);
        try
            FBrowserWindowFactory.GetActive(Browser);
        except
            on E: Exception do
            begin
                Logger.Error(E.Message);
                Exit;
            end;
        end;
        Browser.Get(Url);
    end;

    procedure TTurboGopherApplication.SetActiveBrowserWindow(WindowNumber: Integer);
    begin
        FBrowserWindowFactory.SetActive(WindowNumber);
    end;

    function TTurboGopherApplication.ValidView(P: PView) : PView;
    begin
        result := TurboGraphicsApplication.ValidView(P);
    end;

    procedure TTurboGopherApplication.WriteHelp;
    begin
        writeln('Usage: ', ExeName, ' -h');
    end;

end.
