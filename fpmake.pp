{$mode objfpc}{$H+}

program fpmake;

uses 
    fpmkunit,
    SysUtils,
    Classes;

var
    Info : TSearchRec;

begin
    with Installer.AddPackage('turbogopher') do
    begin
        OSes := [linux];
        with Targets do
        begin

            If FindFirst('src/*.pas', faAnyFile, Info)=0 then
            begin
                repeat
                    with Info do
                    begin
                        AddUnit('src/'+Name);
                    end;
                until FindNext(Info) <> 0;
            end;
        
        end;
    end;
    Installer.Run
end.

