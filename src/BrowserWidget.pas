unit BrowserWidget;

{$mode objfpc}{$H+}

interface

uses
    DrawUtils,
    Logger,
    TurboGopherApplication,

    Classes,
    CustApp,
    Drivers,
    Objects,
    Regexpr,
    StrUtils,
    SysUtils,
    Views;
type

    TCsiParseResult = record
        attributes: byte;
        tokensConsumed: SizeInt;
    end;

    TBrowserCharacter = record
        character: byte;
        attributes: byte;
    end;

    TBrowserString = array of TBrowserCharacter;

    TBrowserWidget = object(TScroller)
        constructor Init(
            var TheApp: TTurboGopherApplication;
            Bounds: TRect;
            AHScrollBar, AVScrollBar: PScrollBar
        );
        procedure Add(text: string);
        procedure Draw; virtual;
        private
            App: TTurboGopherApplication;
            Lines: array of TBrowserString;
            CurrentForegroundColor: byte;
            CurrentBackgroundColor: byte;
            const defaultAttrs = $1f;

    end;
    PBrowserWidget = ^TBrowserWidget;

implementation

var
    sgrTokenRe: TRegExpr;

{ some static helper funcs }

(* ANSI SGR / CSI parsing helper *)
function IsCsiParam(character: Char): Boolean;
begin
    Result := false;
    if (ord(character) >= $30) and (ord(character) <= $3f) then Result := true;
end;

(* ANSI SGR / CSI parsing helper *)
function IsCsiIntermediate(character: Char): Boolean;
begin
    Result := false;
    if (ord(character) >= $20) and (ord(character) <= $2f) then Result := true;
end;

(* ANSI SGR / CSI parsing helper *)
function IsCsiFinal(character: Char): Boolean;
begin
    Result := false;
    if (ord(character) >= $40) and (ord(character) <= $7e) then Result := true;
end;

(* ANSI SGR / CSI parsing helper *)
function ParseCsiToken(
    csi: AnsiString;
    currentAttrs, defaultAttrs: Byte): TCsiParseResult;
var
  code: Integer;
  token: AnsiString;
  fg, bg, sepPos: Integer;
begin
    { default result if we can't parse anything is to preseve current attrs. }
    Result.tokensConsumed := 0;
    Result.attributes := currentAttrs;
    { get position of first token end. (either up to the first ; or m) }
    sepPos := Pos(';', csi);
    if sepPos = 0 then sepPos := Pos('m', csi);
    { if we couldn't get a position, we can't parse anything. }
    if sepPos = 0 then Exit;
    { use position to get first token }
    token := Copy(csi, 1, sepPos - 1);
    { CSI Reset }
    if token = '0' then
    begin
        Result.attributes := defaultAttrs;
        Result.tokensConsumed := 1;
        Exit;
    end;
    { split current attrs into a bg and fg. }
    bg := Hi(currentAttrs) * 16;
    fg := Lo(currentAttrs);
    { parse token }
    case token of
        '30':
        begin { fg = black }
            Result.attributes := bg + $00;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '31':
        begin { fg = red }
            Result.attributes := bg + $04;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '32':
        begin { fg = green }
            Result.attributes := bg + $02;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '33':
        begin { fg = yellow }
            Result.attributes := bg + $06;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '34':
        begin { fg = blue }
            Result.attributes := bg + $01;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '35':
        begin { fg = magenta }
            Result.attributes := bg + $05;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '36':
        begin { fg = cyan }
            Result.attributes := bg + $03;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '37':
        begin { fg = white }
            Result.attributes := bg + $07;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '90':
        begin { fg = bright black }
            Result.attributes := bg + $08;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '91':
        begin { fg = bright red }
            Result.attributes := bg + $0c;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '92':
        begin { fg = bright green }
            Result.attributes := bg + $0a;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '93':
        begin { fg = bright yellow }
            Result.attributes := bg + $0e;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '94':
        begin { fg = bright blue }
            Result.attributes := bg + $09;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '95': { fg = bright magenta }
        begin
            Result.attributes := bg + $0d;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '96':
        begin { fg = bright cyan }
            Result.attributes := bg + $0b;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '97':
        begin { fg = bright white }
            Result.attributes := bg + $0f;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '40':
        begin { bg = black }
            Result.attributes := $00 + fg;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '41':
        begin { bg = red }
            Result.attributes := $40 + fg;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '42':
        begin { bg = green }
            Result.attributes := $20 + fg;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '43':
        begin { bg = yellow }
            Result.attributes := $60 + fg;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '44':
        begin { bg = blue }
            Result.attributes := $10 + fg;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '45':
        begin { bg = magenta }
            Result.attributes := $50 + fg;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '46':
        begin { bg = cyan }
            Result.attributes := $30 + fg;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '47': { bg = white }
        begin
            Result.attributes := $70 + fg;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '100':
        begin { bg = bright black }
            Result.attributes := $80 + fg;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '101':
        begin { bg = bright red }
            Result.attributes := $c0 + fg;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '102':
        begin { bg = bright green }
            Result.attributes := $a0 + fg;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '103':
        begin { bg = bright yellow }
            Result.attributes := $e0 + fg;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '104':
        begin { bg = bright blue }
            Result.attributes := $90 + fg;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '105':
        begin { bg = bright magenta }
            Result.attributes := $d0 + fg;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '106':
        begin { bg = bright cyan }
            Result.attributes := $b0 + fg;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '107': { bg = bright white }
        begin
            Result.attributes := $f0 + fg;
            Result.tokensConsumed := 1;
            Exit;
        end;
        '38': { indexed fg color }
        begin
            if sgrTokenRe.Exec(csi) then
            begin
                if sgrTokenRe.Match[2] <> '5' then
                begin
                    Result.tokensConsumed := 0;
                    Exit;
                end;
                code := StrToInt(sgrTokenRe.Match[3]);
                if code = 233 then
                begin
                    Result.tokensConsumed := 0;
                end;
                case code of
                    0, 16, 232..237:
                    begin { black }
                        Result.attributes := bg + $00;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    1, 52, 88, 124, 202..205:
                    begin { red }
                        Result.attributes := bg + $04;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    2, 22, 23, 58, 94, 130, 166, 28, 64, 65, 100, 34..36, 70..72, 106..108:
                    begin { green }
                        Result.attributes := bg + $02;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    3, 136, 172, 208, 142..145, 178..181, 214..216:
                    begin { yellow }
                        Result.attributes := bg + $06;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    4, 17..21, 24..27:
                    begin { blue }
                        Result.attributes := bg + $01;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    5, 53..57, 89..93, 125..129, 59..63, 95..99, 131..135, 109..110, 146..147, 182, 183:
                    begin { magenta }
                        Result.attributes := bg + $05;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    6, 29..31, 66..67, 37..39, 73..75:
                    begin { cyan }
                        Result.attributes := bg + $03;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    7, 231, 101, 102, 244..251:
                    begin { white }
                        Result.attributes := bg + $07;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    8, 238..243:
                    begin { bright black }
                        Result.attributes := bg + $08;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    9, 160, 196, 217..218:
                    begin { bright red }
                        Result.attributes := bg + $0c;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    10, 40..43, 76..79, 112..115, 148..151, 46..49, 82..84, 118..121, 154..157, 190..193:
                    begin { bright green }
                        Result.attributes := bg + $0a;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    11, 184..188, 220..223, 226..230:
                    begin { bright yellow }
                        Result.attributes := bg + $0e;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    12, 32..33, 68..69, 103..105, 111, 152..153, 87, 123, 159, 195:
                    begin { bright blue }
                        Result.attributes := bg + $09;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    13, 161..165, 197..201, 167..171, 206..207, 137..141, 173..177, 209..213, 219, 189, 224, 225:
                    begin { bright magenta }
                        Result.attributes := bg + $0d;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    14, 44..45, 80..81, 116..117, 50..51, 85..86, 122, 158, 194:
                    begin { bright cyan }
                        Result.attributes := bg + $0b;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    15, 252..255:
                    begin { bright white }
                        Result.attributes := bg + $0f;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                end;
            end;
        end;
        '48': { indexed bg color }
        begin
            if sgrTokenRe.Exec(csi) then
            begin
                code := StrToInt(sgrTokenRe.Match[3]);
                case code of
                    0, 16, 232..237:
                    begin { black }
                        Result.attributes := $00 + fg;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    1, 52, 88, 124, 202..205:
                    begin { red }
                        Result.attributes := $40 + fg;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    2, 22, 23, 58, 94, 130, 166, 28, 64, 65, 100, 34..36, 70..72, 106..108:
                    begin { green }
                        Result.attributes := $20 + fg;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    3, 136, 172, 208, 142..145, 178..181, 214..216:
                    begin { yellow }
                        Result.attributes := $60 + fg;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    4, 17..21, 24..27:
                    begin { blue }
                        Result.attributes := $10 + fg;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    5, 53..57, 89..93, 125..129, 59..63, 95..99, 131..135, 109..110, 146..147, 182, 183:
                    begin { magenta }
                        Result.attributes := $50 + fg;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    6, 29..31, 66..67, 37..39, 73..75:
                    begin { cyan }
                        Result.attributes := $30 + fg;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    7, 231, 101, 102, 244..251:
                    begin { white }
                        Result.attributes := $70 + fg;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    8, 238..243:
                    begin { bright black }
                        Result.attributes := $80 + fg;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    9, 160, 196, 217..218:
                    begin { bright red }
                        Result.attributes := $c0 + fg;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    10, 40..43, 76..79, 112..115, 148..151, 46..49, 82..84, 118..121, 154..157, 190..193:
                    begin { bright green }
                        Result.attributes := $a0 + fg;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    11, 184..188, 220..223, 226..230:
                    begin { bright yellow }
                        Result.attributes := $e0 + fg;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    12, 32..33, 68..69, 103..105, 111, 152..153, 87, 123, 159, 195:
                    begin { bright blue }
                        Result.attributes := $90 + fg;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    13, 161..165, 197..201, 167..171, 206..207, 137..141, 173..177, 209..213, 219, 189, 224, 225:
                    begin { bright magenta }
                        Result.attributes := $d0 + fg;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    14, 44..45, 80..81, 116..117, 50..51, 85..86, 122, 158, 194:
                    begin { bright cyan }
                        Result.attributes := $b0 + fg;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                    15, 252..255:
                    begin { bright white }
                        Result.attributes := $f0 + fg;
                        Result.tokensConsumed := 3;
                        Exit;
                    end;
                end;
            end;
        end;
    end;
end;

(* ANSI SGR / CSI parsing helper *)
function ParseCsi(
    Logger: PLogger;
    csi: string;
    currentAttrs, defaultAttrs: Byte
): Byte;
var
    prevPos, nextPos, I: Integer;
    sgrBuffer: AnsiString;
    parsedToken: TCsiParseResult;
    success: Boolean;
begin
    if csi = '38;5;233m' then
    begin
        sgrBuffer := 'a';
    end;
    sgrBuffer := '';
    Result := currentAttrs;
    success := False;
    if Length(csi) < 2 then
    begin
        Logger^.Info('Ignoring unsupported CSI sequence: ' + csi);
        Exit;
    end;
    if csi[Length(csi)] <> 'm' then
    begin
        Logger^.Info('Ignoring unsupported CSI sequence: ' + csi);
        Exit;
    end;
    I := 1;
    prevPos := 0;
    while I <= Length(csi) do
    begin
        { read up to the next token or terminator }
        nextPos := NPos(';', csi, I);
        if nextPos = 0 then nextPos := Pos('m', csi);
        if nextPos = 0 then break;
        sgrBuffer := Copy(csi, prevPos + 1, nextPos);
        { attempt to parse the tokens so far }
        parsedToken := ParseCsiToken(sgrBuffer, Result, defaultAttrs);
        if parsedToken.tokensConsumed > 0 then
        begin
            { parse success, write attrs, advance counter #tokens consumed. }
            Result := parsedToken.attributes;
            prevPos := nextPos;
            success := True;
        end;
        { parse fail, try next token. }
        I += 1;
    end;
    if success <> True then
    begin
        Logger^.Warning('Unable to parse csi token: ' + csi);
    end;
end;

{ TBrowserWidget }

constructor TBrowserWidget.Init(
            var TheApp: TTurboGopherApplication;
            Bounds: TRect;
            AHScrollBar, AVScrollBar: PScrollBar
        );
begin
    TScroller.Init(Bounds, AHScrollBar, AVScrollBar);
    App := TheApp;
    CurrentForegroundColor := Hi(defaultAttrs);
    CurrentBackgroundColor := Lo(defaultAttrs);
    GrowMode := gfGrowHiX + gfGrowHiY;
    SetLimit(128, 10);
    sgrTokenRe := TRegExpr.Create('^(\d+);(\d+);(\d+)');
end;

procedure TBrowserWidget.Add(text: string);
type TCsiParseStage = (None, Parameter, Intermediate, Final);
var
  Attrs: Byte;
  CC, PC: char;
  NewChar: TBrowserCharacter;
  I: SizeInt;
  Line: TBrowserString;
  Logger: PLogger;
  InAnsiParse: Boolean;
  CsiStage: TCsiParseStage;
  CsiBuffer: AnsiString;
begin
    Logger := App.GetLogger();
    CsiBuffer := '';
    CsiStage := None;
    InAnsiParse := False;
    PC := chr(0);
    Line := default(TBrowserString);
    { determine attributes for characters }
    Attrs := (CurrentForegroundColor * 15) + CurrentBackgroundColor;
    { iterate characters in text to be added }
    for I := 0 to (Length(text) - 1) do
    begin
        (* If the character is a new line, allocate a new line and save the
           previous one. *)
        CC := text[I + 1];
        if (ord(CC) = 10) or (ord(CC) = 13) then
        begin
            (* If the previous character was a <CR> and the current character is
               an <LF> then ignore and don't add an additional new line. *)
            if not ((ord(PC) = 13) and (ord(CC) = 10)) then
            begin
                SetLength(Lines, Length(Lines) + 1);
                Lines[Length(Lines) - 1] := Line;
                Line := default(TBrowserString);
            end;
            PC := CC;
            continue;
        end;
        (* Parse CSI escapes. *)
        if CsiStage <> TCsiParseStage.None then
        begin
            { detect parameter bytes }
            if CsiStage = TCsiParseStage.Parameter then
            begin
                if IsCsiParam(CC) then
                begin
                    CsiBuffer += CC;
                end
                else if IsCsiIntermediate(CC) then
                begin
                    CsiBuffer += CC;
                    CsiStage := TCsiParseStage.Intermediate;
                end
                else if IsCsiFinal(CC) then
                begin
                    CsiBuffer += CC;
                    CsiStage := TCsiParseStage.Final;
                end
                else
                begin
                    Logger^.Warning(
                        'Could not parse ANSI CSI sequence (after parsing parameter): '
                        + 'Character: ' + CC + ' Buffer: ' + CsiBuffer);
                    CsiStage := TCsiParseStage.None;
                    CsiBuffer := '';
                end;
            end
            else if CsiStage = TCsiParseStage.Intermediate then
            begin
                if IsCsiIntermediate(CC) then
                begin
                    CsiBuffer += CC;
                end
                else if IsCsiFinal(CC) then
                begin
                    CsiBuffer += CC;
                    CsiStage := TCsiParseStage.Final;
                end
                else
                begin
                    Logger^.Warning(
                        'Could not parse ANSI CSI sequence (after parsing intermediate): '
                        + 'Character: ' + CC + ' Buffer: ' + CsiBuffer);
                    CsiStage := TCsiParseStage.None;
                    CsiBuffer := '';
                end;
            end;
            if CsiStage = TCsiParseStage.Final then
            begin
                Attrs := ParseCsi(Logger, CsiBuffer, Attrs, defaultAttrs);
                CsiStage := TCsiParseStage.None;
                CsiBuffer := '';
            end;
            PC := CC;
            continue;
        end;
        (* Parse ANSI escapes. *)
        if InAnsiParse = true then
        begin
            case text[I + 1] of
                '[': CsiStage := TCsiParseStage.Parameter;
            end;
            PC := CC;
            InAnsiParse := False;
            continue;
        end;
        (* Initiate ANSI escape parsing. *)
        if text[I + 1] = chr(27) then
        begin
            PC := CC;
            InAnsiParse := True;
            continue;
        end;
        NewChar.character := ord(text[I + 1]);
        NewChar.attributes := Attrs;
        SetLength(Line, Length(Line) + 1);
        Line[Length(Line) - 1] := NewChar;
        PC := CC;
    end;
    { add the line to our lines array. }
    if (Line <> nil) then
    begin
        SetLength(Lines, Length(Lines) + 1);
        Lines[Length(Lines) - 1] := Line;
    end;
end;

procedure TBrowserWidget.Draw;
var
  I: Integer;
  DrawBuffer: TDrawBuffer;
  DrawBufferIndex, X, Y, LineCount, LongestLine: SizeInt;
  C: TBrowserCharacter;
begin
    DrawBuffer := default(TDrawBuffer);
    DrawBufferIndex := 0;
    LongestLine := 0;
    LineCount := Length(Lines);
    { clear the screen }
    AddToDrawBuf(DrawBuffer, 32, defaultAttrs, Size.X);
    WriteLine(0, 0, Size.X, Size.Y, DrawBuffer);
    DrawBuffer := default(TDrawBuffer);
    { render characters }
    for Y := Delta.Y to Length(Lines) - 1 - Delta.Y do
    begin
        I := Delta.Y + Y;
        if (I < LineCount) and (Lines[I] <> nil) then
        begin
            if Length(Lines[I]) > LongestLine then LongestLine := Length(Lines[I]);
            for X := Delta.X to (Delta.X + Size.X) do
            begin
                if (Length(Lines[I]) - 1 < X) then continue;
                C := Lines[I][X];
                SetInDrawBuf(DrawBuffer, C.character, C.attributes, DrawBufferIndex);
                DrawBufferIndex += 1;
            end;
            WriteBuf(0, Y - Delta.Y, DrawBufferIndex, 1, DrawBuffer);
            DrawBufferIndex := 0;
        end;
    end;
    SetLimit(LongestLine, LineCount);
end;

end.

