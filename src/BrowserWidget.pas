unit BrowserWidget;

{$mode objfpc}{$H+}

interface

uses
    Classes,
    SysUtils,
    Objects,
    Views,
    Drivers;
type

    TBrowserCharacter = record
        character: byte;
        attributtes: byte;
    end;

    TBrowserString = array of TBrowserCharacter;

    TBrowserWidget = object(TScroller)
        constructor Init(var Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar);
        procedure Add(text: string);
        procedure Draw; virtual;
        private
            Lines: array of TBrowserString;
            CurrentForegroundColor: byte;
            CurrentBackgroundColor: byte;
    end;
    PBrowserWidget = ^TBrowserWidget;

implementation

constructor TBrowserWidget.Init(var Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar);
begin
    CurrentForegroundColor := 16;
    CurrentBackgroundColor := 1;
    TScroller.Init(Bounds, AHScrollBar, AVScrollBar);
    GrowMode := gfGrowHiX + gfGrowHiY;
    SetLimit(128, 10);
end;

procedure TBrowserWidget.Add(text: string);
var
  LineCount: SizeInt;
  Attrs: Byte;
  CC: char;
  NewChar: TBrowserCharacter;
  I: SizeInt;
  Line: TBrowserString;
begin
    Line := default(TBrowserString);
    { get line count, allocate a line if needed. }
    LineCount := Length(Lines);
    if (LineCount = 0) then SetLength(Lines, LineCount + 1);
    { determine attributes for characters }
    Attrs := (CurrentForegroundColor * 16) + CurrentBackgroundColor;
    { iterate characters in text to be added }
    for I := 0 to (Length(text) - 1) do
    begin
        { if the character is a new line, allocate a new line and save the previous one. }
        CC := text[I + 1];
        if (ord(CC) = 10) or (ord(CC) = 13) then
        begin
            Lines[LineCount] := Line;
            Line := default(TBrowserString);
            LineCount := Length(Lines);
            SetLength(Lines, LineCount + 1);
            continue;
        end;
        NewChar.character := ord(text[I + 1]);
        NewChar.attributtes := Attrs;
        SetLength(Line, Length(Line) + 1);
        Line[Length(Line) - 1] := NewChar;
    end;
    { add the line to our lines array. }
    Lines[LineCount] := Line;
end;

procedure TBrowserWidget.Draw;
var
  Color: Byte;
  I: Integer;
  DrawBuffer: TDrawBuffer;
  X, Y, LineCount, LongestLine: SizeInt;
  C: TBrowserCharacter;
begin
    DrawBuffer := default(TDrawBuffer);
    LongestLine := 0;
    Color := GetColor($FF);
    LineCount := Length(Lines);
    { clear the screen }
    MoveChar(DrawBuffer, ' ', Color, Size.X);
    WriteLine(0, 0, Size.X, Size.Y, DrawBuffer);
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
                WriteChar(X - Delta.X, Y - Delta.Y, chr(C.character), C.attributtes, 1);
            end;
        end;
    end;
    SetLimit(LongestLine, LineCount);
end;

end.

