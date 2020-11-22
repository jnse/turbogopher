unit StringUtils;

{$mode objfpc}{$H+}

interface

uses
    Objects;

type
    TStringArray = array of AnsiString;

    function StringSplit(Haystack, Needle: AnsiString; MaxMatches: SizeInt = 0) : TStringArray;

implementation

    function StringSplit(Haystack, Needle: AnsiString; MaxMatches: SizeInt = 0) : TStringArray;
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
            if (MaxMatches > 0) and (numMatches > MaxMatches) then Exit;
            token := Copy(Haystack, 0, foundPos - 1);
            SetLength(Result, Length(Result) + 1);
            Result[Length(Result) - 1] := token;
            Haystack := Copy(
                Haystack,
                1 + Length(token) + Length(Needle),
                Length(Haystack) - Length(token) - Length(Needle));
        end;
    end;

end.
