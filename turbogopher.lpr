Program turbogopher;

{$mode objfpc}{$H+}

Uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
cthreads,
  {$ENDIF}{$ENDIF}
Classes,
SysUtils,
CustApp,
TurboGopherApplication;

Var
  Application: TTurboGopherApplication;
Begin
  Application := TTurboGopherApplication.Create(Nil);
  Application.Title:='TurboGopher';
  Application.Run;
  Application.Free;
End.

