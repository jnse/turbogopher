program turbogopher;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes,
  SysUtils,
  CustApp,
  MainWindow,
  TurboGopherApplication;

var
  Application: TTurboGopherApplication;
begin
  Application := TTurboGopherApplication.Create(nil);
  Application.Title := 'TurboGopher';
  Application.Run;
  Application.Free;
end.
