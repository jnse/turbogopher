unit BrowserWidget;

{$mode objfpc}{$H+}

interface

uses
    Logger,
    TurboGopherApplication,

    Classes,
    Drivers,
    Objects,
    SysUtils,
    Views;

type

    TBrowserCharacter = record
        character: byte;
        attributtes: byte;
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
            var App: TTurboGopherApplication;
            Lines: array of TBrowserString;
            CurrentForegroundColor: byte;
            CurrentBackgroundColor: byte;
            const defaultAttrs = $10;

    end;
    PBrowserWidget = ^TBrowserWidget;

implementation

{ some static helper funcs }

function IsCsiParam(character: Char): Boolean;
begin
    Result := false;
    if (ord(character) >= $30) and (ord(character) <= $3f) then Result := true;
end;

function IsCsiIntermediate(character: Char): Boolean;
begin
    Result := false;
    if (ord(character) >= $20) and (ord(character) <= $2f) then Result := true;
end;

function IsCsiFinal(character: Char): Boolean;
begin
    Result := false;
    if (ord(character) >= $40) and (ord(character) <= $7e) then Result := true;
end;

function ParseCsiToken(
    Logger: PLogger;
    token: string;
    currentAttrs, defaultAttrs: Byte): Byte;
begin
    if token = '0' then
    begin
        Result := defaultAttrs;
        Exit;
    end;
    case token of
        '30': Result := (Hi(currentAttrs) * $10) + $00; { fg = black }
        '31': Result := (Hi(currentAttrs) * $10) + $04; { fg = red }
        '32': Result := (Hi(currentAttrs) * $10) + $02; { fg = green }
        '33': Result := (Hi(currentAttrs) * $10) + $06; { fg = yellow }
        '34': Result := (Hi(currentAttrs) * $10) + $01; { fg = blue }
        '35': Result := (Hi(currentAttrs) * $10) + $05; { fg = magenta }
        '36': Result := (Hi(currentAttrs) * $10) + $03; { fg = cyan }
        '37': Result := (Hi(currentAttrs) * $10) + $07; { fg = white }
        '90': Result := (Hi(currentAttrs) * $10) + $08; { fg = bright black }
        '91': Result := (Hi(currentAttrs) * $10) + $0c; { fg = bright red }
        '92': Result := (Hi(currentAttrs) * $10) + $0a; { fg = bright green }
        '93': Result := (Hi(currentAttrs) * $10) + $0e; { fg = bright yellow }
        '94': Result := (Hi(currentAttrs) * $10) + $09; { fg = bright blue }
        '95': Result := (Hi(currentAttrs) * $10) + $0d; { fg = bright magenta }
        '96': Result := (Hi(currentAttrs) * $10) + $0b; { fg = bright cyan }
        '97': Result := (Hi(currentAttrs) * $10) + $0f; { fg = bright white }
        '40': Result := $00 + Lo(currentAttrs); { bg = black }
        '41': Result := $40 + Lo(currentAttrs); { bg = red }
        '42': Result := $20 + Lo(currentAttrs); { bg = green }
        '43': Result := $60 + Lo(currentAttrs); { bg = yellow }
        '44': Result := $10 + Lo(currentAttrs); { bg = blue }
        '45': Result := $50 + Lo(currentAttrs); { bg = magenta }
        '46': Result := $30 + Lo(currentAttrs); { bg = cyan }
        '47': Result := $70 + Lo(currentAttrs); { bg = white }
        '100': Result := $80 + Lo(currentAttrs); { bg = bright black }
        '101': Result := $c0 + Lo(currentAttrs); { bg = bright red }
        '102': Result := $a0 + Lo(currentAttrs); { bg = bright green }
        '103': Result := $e0 + Lo(currentAttrs); { bg = bright yellow }
        '104': Result := $90 + Lo(currentAttrs); { bg = bright blue }
        '105': Result := $d0 + Lo(currentAttrs); { bg = bright magenta }
        '106': Result := $b0 + Lo(currentAttrs); { bg = bright cyan }
        '107': Result := $f0 + Lo(currentAttrs); { bg = bright white }
    end;
end;

function ParseCsi(Logger: PLogger; csi: string; defaultAttrs: Byte): Byte;
var
    I: Integer;
    sgrBuffer: AnsiString;
begin
    sgrBuffer := '';
    Result := defaultAttrs;
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
    for I := 1 to Length(csi) do
    begin
        if csi[I] = 'm' then
        begin
            Result := ParseCsiToken(Logger, sgrBuffer, Result, defaultAttrs);
            Exit;
        end;
        if csi[I] = ';' then
        begin
            Result := ParseCsiToken(Logger, sgrBuffer, Result, defaultAttrs);
            sgrBuffer := '';
            continue;
        end;
        sgrBuffer += csi[I];
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
                Attrs := ParseCsi(Logger, CsiBuffer, defaultAttrs);
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
        NewChar.attributtes := Attrs;
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
  X, Y, LineCount, LongestLine: SizeInt;
  C: TBrowserCharacter;
begin
    DrawBuffer := default(TDrawBuffer);
    LongestLine := 0;
    LineCount := Length(Lines);
    { clear the screen }
    MoveChar(DrawBuffer, ' ', defaultAttrs, Size.X);
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
                MoveChar(DrawBuffer, chr(C.character), C.attributtes, 1);
                WriteBuf(x - Delta.X, Y - Delta.Y, 1, 1, DrawBuffer);
            end;
        end;
    end;
    SetLimit(LongestLine, LineCount);
end;

end.

