unit StringUtils;

{$mode objfpc}{$H+}

interface

uses
    Objects,
    SysUtils;

type
    TStringArray = array of AnsiString;

    procedure InsertAt(var Subject: TStringArray; Token: AnsiString; Index: SizeInt);
    function LTrim(Subject: AnsiString; Token: AnsiString): AnsiString;
    function StringSplit(Haystack, Needle: AnsiString; MaxMatches: SizeInt = 0; IncludeRemainder: Boolean = False) : TStringArray;

implementation

procedure InsertAt(var Subject: TStringArray; Token: AnsiString; Index: SizeInt);
var
    I: SizeInt = 0;
begin
    if Length(Subject) = 2 then
    Begin
        I := 0;
    end;
    if Index > Length(Subject) then Index := Length(Subject);
    if Index < 0 then Index := 0;
    I := Length(Subject) - 1;
    SetLength(Subject, Length(Subject) + 1);
    while (I >= Index) do
    begin
         Subject[I + 1] := Subject[I];
         I := I - 1;
    end;
    Subject[Index] := Token;
end;

function LTrim(Subject: AnsiString; Token: AnsiString): AnsiString;
var
    Num: SizeInt = 0;
begin
    Result := Subject;
    if Pos(Token, Subject) <> 1 then Exit;
    Num := Length(Subject) - Length(Token);
    if Num < 1 then Exit;
    Result := RightStr(Subject, Num);
end;

function StringSplit(Haystack, Needle: AnsiString; MaxMatches: SizeInt = 0; IncludeRemainder: Boolean = False) : TStringArray;
var
    foundPos, numMatches: SizeInt;
    token: AnsiString;
begin
    Result := default(TStringArray);
    if Length(Haystack) = 0 then Exit;
    foundPos := Pos(Needle, Haystack);
    numMatches := 0;
    while foundPos > 0 do
    begin
        foundPos := Pos(Needle, Haystack);
        if foundPos = 0 then
        begin
            SetLength(Result, Length(Result) + 1);
            Result[Length(Result) - 1] := Haystack;
            Exit;
        end;
        numMatches += 1;
        if (MaxMatches > 0) and (numMatches = MaxMatches) then
        begin
            if IncludeRemainder = True then
            begin
                SetLength(Result, Length(Result) + 1);
                Result[Length(Result) - 1] += Haystack;
            end;
            Exit;
        end;
        token := Copy(Haystack, 0, foundPos - 1);
        SetLength(Result, Length(Result) + 1);
        Result[Length(Result) - 1] := token;
        Haystack := Copy(
            Haystack,
            1 + Length(token) + Length(Needle),
            Length(Haystack) - Length(token) - Length(Needle))
    end;
end;

end.
