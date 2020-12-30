unit GopherClient;

{$mode objfpc}{$H+}

interface

uses

    Logger,
    StringUtils,

    Classes,
    Regexpr,
    Ssockets,
    SysUtils;

type

    PGopherMenuItem = ^TGopherMenuItem;
    TGopherMenuItem = record
        ItemType: char;
        DisplayString: RawByteString;
        SelectorString: RawByteString;
        Host: RawByteString;
        Port: RawByteString;
        Valid: Boolean;
        Source: RawByteString;
    end;

    TGopherMenuItems = array of TGopherMenuItem;

    TTokenizedUrl = record
        Host: string;
        DocumentType: string;
        Path: string;
        Port: Word;
    end;

    TGopherClient = class
    public
        constructor Create(LoggerObject: PLogger);
        function Get(Url: string): TGopherMenuItems;
        function ParseMenu(const Body: string; IsMenu: Boolean): TGopherMenuItems;
    private
        Logger: PLogger;
        CurrentHost: AnsiString;
        CurrentPort: AnsiString;
        function ParseMenuItem(const ItemLine: RawByteString): TGopherMenuItem;
        function ParseUrl(Url: string): TTokenizedUrl;
    end;

implementation

    { Helper functions }

    (* The idea of this is to replace widely used multibyte characters in UTF8
       (mostly block drawing stuff, with their nearest equivalent in ANSI rather
       than just showing an unknown glyph question mark. *)
    function UTF8Hack(const inputString: RawByteString): AnsiString;
    begin
        Result := inputString;
        Result := Result.Replace(chr($e2) + chr($95) + chr($b1), '/');
        Result := Result.Replace(chr($e2) + chr($95) + chr($b2), '\');
        Result := Result.Replace(chr($e2) + chr($96) + chr($80), chr($df));
        Result := Result.Replace(chr($e2) + chr($96) + chr($84), chr($dc));
        Result := Result.Replace(chr($e2) + chr($96) + chr($91), chr($b0));
        Result := Result.Replace(chr($e2) + chr($96) + chr($92), chr($b1));
        Result := Result.Replace(chr($e2) + chr($96) + chr($93), chr($b2));
        Result := Result.Replace(chr($e2) + chr($96) + chr($88), chr($db));
        Result := Result.Replace(chr($e2) + chr($96) + chr($8c), chr($dd));
        Result := Result.Replace(chr($e2) + chr($96) + chr($96), chr($dd));
        Result := Result.Replace(chr($e2) + chr($96) + chr($98), chr($dd));
        Result := Result.Replace(chr($e2) + chr($96) + chr($90), chr($de));
        Result := Result.Replace(chr($e2) + chr($96) + chr($97), chr($de));
        Result := Result.Replace(chr($e2) + chr($96) + chr($9c), chr($de));
        Result := Result.Replace(chr($e2) + chr($96) + chr($9d), chr($de));
        Result := Result.Replace(chr($e2) + chr($96) + chr($99), chr($db));
        Result := Result.Replace(chr($e2) + chr($96) + chr($9b), chr($db));
        Result := Result.Replace(chr($e2) + chr($96) + chr($9c), chr($db));
        Result := Result.Replace(chr($e2) + chr($96) + chr($9f), chr($db));
        Result := Result.Replace(chr($e2) + chr($88) + chr($99), chr($f9));
        Result := Result.Replace(chr($e2) + chr($80) + chr($ba), '>');
        Result := Result.Replace(chr($c2) + chr($b7), chr($fa));
    end;

    { TGopherClient }

    constructor TGopherClient.Create(LoggerObject: PLogger);
    begin
        Logger := LoggerObject;
        CurrentHost := '';
        CurrentPort := '';
    end;

    function TGopherClient.ParseMenu(const Body: string; IsMenu: Boolean): TGopherMenuItems;
    var
        Lines: TStringArray;
        I: SizeInt;
        MenuItem: TGopherMenuItem;
    begin
        Result := default(TGopherMenuItems);
        Lines := StringSplit(Body, chr(13) + chr(10));
        if (Length(Lines) = 0) then
        begin
            { eh.... not a menu? fallback. }
            Lines := Body.Split([chr(13), chr(10)]);
        end;

        for I := 0 to Length(Lines) - 1 do
        begin
            if (Length(Lines) > 0) then
            begin
                if Lines[I] = '.' then Exit; { Single dot marks the end. }
                if IsMenu = True then
                    MenuItem := ParseMenuItem(Lines[I])
                else
                begin
                    MenuItem.ItemType := 'i';
                    MenuItem.SelectorString := '';
                    MenuItem.DisplayString := Lines[I];
                    MenuItem.Valid := True;
                end;
                SetLength(Result, Length(Result) + 1);
                Result[Length(Result) - 1] := MenuItem;
            end;
        end;
    end;

    function TGopherClient.ParseMenuItem(const ItemLine: RawByteString): TGopherMenuItem;
    var
        Tokens: TStringArray;
        ParsedItem: RawByteString;
    begin
        (* Initialize with some default values first. *)
        ParsedItem := ItemLine;
        Result.ItemType := '3';
        Result.DisplayString := ItemLine;
        Result.SelectorString := '';
        Result.Host := CurrentHost;
        Result.Port := CurrentPort;
        Result.Valid := False;
        Result.Source := ItemLine;
        (* We need at least a first character to get an item type. *)
        if (Length(ParsedItem) < 1) then Exit;
        Result.ItemType := ParsedItem[1];
        ParsedItem := Copy(ParsedItem, 2, Length(ParsedItem) - 1);
        if ItemLine = ('1Super-Dimensional Fortress: SDF Gopherspace'+Chr(9)+Chr(9)+'sdf.org'+chr(9)+'70') then
        begin
            SetLength(Tokens, 0); { break here }
        end;
        (* Look for the tab character separating display/selector strings.
           Bail if we can't find one. *)
        tokens := StringSplit(ParsedItem, chr(9), 2, True);
        if Length(tokens) < 2 then Exit;
        (* Display string is the first token, the other token has everything else. *)
        Result.DisplayString := Tokens[0];
        ParsedItem := Tokens[1];
        (* If we got here, the result is basically valid, the other fields are
           optional. We will try to parse out as many as we can. *)
        Result.Valid := True;
        (* Next up is the selector *)
        Tokens := StringSplit(ParsedItem, chr(9), 2, True);
        if Length(tokens) < 1 then Exit;
        Result.SelectorString := Tokens[0];
        (* Trim the leading slash if there is one. *)
        if Result.SelectorString <> '' then
            Result.SelectorString := LTrim(Result.SelectorString, '/');
        if Length(tokens) < 2 then Exit;
        ParsedItem := Tokens[1];
        (* Next up is the host. *)
        Tokens := StringSplit(ParsedItem, chr(9), 2, True);
        if Length(tokens) < 1 then Exit;
        Result.Host := Tokens[0];
        if Length(tokens) < 2 then Exit;
        (* All that's left now should be the port. *)
        ParsedItem := Tokens[1];
        Tokens := StringSplit(ParsedItem, chr(9), 2);
        if Length(tokens) < 1 then
            Result.Port := ParsedItem
        else
            Result.Port := Tokens[0];
        Result.Port := Trim(Result.Port);
    end;

    function TGopherClient.ParseUrl(Url: string): TTokenizedUrl;
    const
        gsPath: string = '/';
        GopherPort: Integer = 70;
    var
        unparsedPath, PortStr: AnsiString;
        PortInt: LongInt;
        re: TRegExpr;
        ColonPos, PathPos: SizeInt;
    begin
        Result.DocumentType := '1'; (* Default unless overridden by url *)
        Url := LTrim(Url, 'gopher://');
        if Pos(gsPath, Url) = 0 then
        begin
            unparsedPath := gsPath
        end else
        begin
            unparsedPath := Copy(Url, Pos(gsPath, Url), Length(Url))
        end;
        ColonPos := Pos(':', Url);
        if ColonPos = 0 then
        begin
            (* No port specified? *)
            if Pos(gsPath, Url) = 0 then
                Result.Host := Copy(Url, 1, Length(Url))
            else
                Result.Host := Copy(Url, 1, Pos(gsPath, Url) - 1);
            Result.Port := GopherPort
        end else
        begin
            (* Port specified. *)
            Result.Host := Copy(Url, 1, ColonPos - 1);
            PathPos := Pos(gsPath, Url) - 1;
            if PathPos = 0 then PathPos := Length(Url) - 1;
            PortStr := Copy(Url, ColonPos + 1, PathPos - ColonPos);
            if TryStrToInt(PortStr, PortInt) <> True then
            begin
                Logger^.Warning('Could not parse gopher port: ' + PortStr);
                Result.Port := GopherPort;
            end
            else
                Result.Port := PortInt;
        end;
        if Length(unparsedPath) = 0 then Exit;
        unparsedPath := ReplaceRegExpr('/+', unparsedPath, '/', True);
        re := TRegExpr.Create('^/?(.)/(.*)');
        if re.Exec(unparsedPath) then
        begin
            Result.DocumentType := re.Match[1];
            Result.Path := '/' + re.Match[2];
        end;
    end;

    function TGopherClient.Get(Url: String): TGopherMenuItems;
    var
        TokenizedUrl: TTokenizedUrl;
        ClientSocket: TSocketStream;
        ResultStr: AnsiString = '';
        RequestStr: string = '';
        Part: string = '';
        Buf: array[0..4095] of Char = '';
        Count: Integer = 4094;
        IsMenu: Boolean = False;
        ReadResult: LongInt = 1;
        Menu: TGopherMenuItems;
    begin
        ResultStr := '';
        TokenizedUrl := ParseUrl(Url);
        try
           ClientSocket := TInetSocket.Create(
               TokenizedUrl.Host,
               TokenizedUrl.Port);
        except
            on E: Exception do
            begin
                CurrentHost := '';
                CurrentPort := '';
                Logger^.Error('Could not connect to host: ' + TokenizedUrl.Host
                    + ' on port ' + IntToStr(TokenizedUrl.Port)
                    + ' - Error: ' + E.Message);
                Exit;
            end;
        end;
        CurrentHost := TokenizedUrl.Host;
        CurrentPort := IntToStr(TokenizedUrl.Port);
        RequestStr := TokenizedUrl.Path + #13#10;
        ClientSocket.Write(RequestStr[1], Length(RequestStr));
        while (ReadResult > 0) do
        begin
            try
                ReadResult := ClientSocket.Read(Buf, Count);
            except
                on E: ESocketError do
                begin
                    Logger^.Error(
                        ' | Error while reading from host: ' + TokenizedUrl.Host
                        + ' on port ' + IntToStr(TokenizedUrl.Port)
                        + ' - Error: ' + E. Message
                    );
                    ClientSocket.Free;
                    Exit;
                end;
            end;
            if ReadResult = 0 then break;
            Part := Copy(Buf, 0, ReadResult);
            ResultStr += Part;
            Buf := '';
        end;
        ResultStr := UTF8Hack(ResultStr);
        Logger^.Debug('Successfully retrieved ' + Url);
        ClientSocket.Free;
        if TokenizedUrl.DocumentType = '1' then IsMenu := True;
        Menu := ParseMenu(ResultStr, IsMenu);
        if (Length(menu) = 0) then
        begin
            Logger^.Error('Could not parse server response as menu: ' + ResultStr);
        end;
        Result := Menu;
    end;

end.
