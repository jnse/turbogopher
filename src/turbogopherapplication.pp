unit TurboGopherApplication;

{$mode objfpc}{$H+}

interface

uses
  App,
  Objects,
  Classes,
  CustApp,
  Drivers,
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
    private
        TurboGraphicsApplication: TTGApp;
        Client: TGopherClient;
    protected
        procedure DoRun; override;
    public
        constructor Create(TheOwner: TComponent); override;
        destructor Destroy; override;
        procedure GetExtent(var Extent: Objects.TRect);
        function ValidView(P: PView) : PView;
        procedure WriteHelp; virtual;
    end;

implementation

    uses MainWindow;

    var
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

    procedure TTurboGopherApplication.DoRun;
    var
        ErrorMsg: String;
    begin
        // quick check parameters
        ErrorMsg:=CheckOptions('h', 'help');
        if ErrorMsg<>'' then
        begin
             ShowException(Exception.Create(ErrorMsg));
             Terminate;
             Exit;
        end;
        // parse parameters
        if HasOption('h', 'help') then
        begin
             WriteHelp;
             Terminate;
             Exit;
        end;
        // Init TG app
        TurboGraphicsApplication.Init;
        // Create main window
        FMainWindow := TMainWindow.Create(Self);
        // Run TG app
        TurboGraphicsApplication.Run;
        // Clean shutdown
        TurboGraphicsApplication.Done;
        Terminate;
    end;

    constructor TTurboGopherApplication.Create(TheOwner: TComponent);
    begin
      inherited Create(TheOwner);
      StopOnException:=True;
    end;

    destructor TTurboGopherApplication.Destroy;
    begin
      inherited Destroy;
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
