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

    (*
        Users of this unit will typically use the TGopherClient.Get() function
        to retrieve a result from a gopher server.

        A result can either be displayable content (in the case of plain text
        (0 type) or a menu (1 type)) - or it can be 'data' to either be
        downloaded or handled by an external application.

        Internally we handle plain text and gopher menu's in the same way via
        the TGopherMenuItem record. Non-text data is handled via the
        TGopherDownload record.

        A TGetResult contains either an array of TGopherMenuItems or a
        TGopherDownload instance - the ResultType indicates which.
    *)

    PGopherMenuItem = ^TGopherMenuItem;
    TGopherMenuItem = record
        ItemType: char;
        DisplayString: RawByteString;
        SelectorString: RawByteString;
        Host: RawByteString;
        Port: RawByteString;
        Valid: Boolean;
        Source: RawByteString;
        Position: SizeInt;
    end;
    TGopherMenuItems = array of TGopherMenuItem;

    TGopherDownload = record
        Data: AnsiString;
        FileName: RawByteString;
        Size: SizeInt;
    end;

    TGetResultType = (GET_RESULT_NOTHING, GET_RESULT_CONTENT, GET_RESULT_DATA);

    TGetResult = record
        MenuItems: TGopherMenuItems;
        DownloadData: TGopherDownload;
        ResultType: TGetResultType;
    end;

    TTokenizedUrl = record
        Host: string;
        DocumentType: string;
        Path: string;
        Port: Word;
    end;

    TGopherClient = class
    public
        constructor Create(LoggerObject: PLogger);
        function Get(Url: string): TGetResult;
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
    var
        I: SizeInt;
    begin
        Result := inputString;
        Result := Result.Replace(chr($20) + chr($cc) + chr($b6), '');
        Result := Result.Replace(chr($20) + chr($cc) + chr($b8), '');
        Result := Result.Replace(chr($b9) + chr($cc) + chr($a7), '');
        Result := Result.Replace(chr($e2) + chr($80) + chr($a2), chr(7));
        Result := Result.Replace(chr($e2) + chr($80) + chr($ba), '>');
        Result := Result.Replace(chr($e2) + chr($88) + chr($99), chr($f9));
        Result := Result.Replace(chr($e2) + chr($94) + chr($81), chr(254));
        Result := Result.Replace(chr($e2) + chr($94) + chr($88), chr(196));
        Result := Result.Replace(chr($e2) + chr($94) + chr($8f), chr(218));
        Result := Result.Replace(chr($e2) + chr($94) + chr($93), chr(191));
        Result := Result.Replace(chr($e2) + chr($94) + chr($bb), chr(193));
        Result := Result.Replace(chr($e2) + chr($95) + chr($b1), '/');
        Result := Result.Replace(chr($e2) + chr($95) + chr($b2), '\');
        Result := Result.Replace(chr($e2) + chr($95) + chr($bc), chr(196));
        Result := Result.Replace(chr($e2) + chr($95) + chr($be), chr(196));
        Result := Result.Replace(chr($e2) + chr($96) + chr($80), chr($df));
        Result := Result.Replace(chr($e2) + chr($96) + chr($81), '_');
        Result := Result.Replace(chr($e2) + chr($96) + chr($82), chr(220));
        Result := Result.Replace(chr($e2) + chr($96) + chr($83), chr(220));
        Result := Result.Replace(chr($e2) + chr($96) + chr($84), chr($dc));
        Result := Result.Replace(chr($e2) + chr($96) + chr($85), chr(220));
        Result := Result.Replace(chr($e2) + chr($96) + chr($86), chr(220));
        Result := Result.Replace(chr($e2) + chr($96) + chr($87), chr(219));
        Result := Result.Replace(chr($e2) + chr($96) + chr($88), chr($db));
        Result := Result.Replace(chr($e2) + chr($96) + chr($89), chr(219));
        Result := Result.Replace(chr($e2) + chr($96) + chr($8a), chr(219));
        Result := Result.Replace(chr($e2) + chr($96) + chr($8b), chr(221));
        Result := Result.Replace(chr($e2) + chr($96) + chr($8c), chr($dd));
        Result := Result.Replace(chr($e2) + chr($96) + chr($8d), chr(221));
        Result := Result.Replace(chr($e2) + chr($96) + chr($8e), chr(221));
        Result := Result.Replace(chr($e2) + chr($96) + chr($8f), chr(7));
        Result := Result.Replace(chr($e2) + chr($96) + chr($90), chr(222));
        Result := Result.Replace(chr($e2) + chr($96) + chr($91), chr($b0));
        Result := Result.Replace(chr($e2) + chr($96) + chr($92), chr($b1));
        Result := Result.Replace(chr($e2) + chr($96) + chr($93), chr($b2));
        Result := Result.Replace(chr($e2) + chr($96) + chr($94), chr(223));
        Result := Result.Replace(chr($e2) + chr($96) + chr($95), chr(222));
        Result := Result.Replace(chr($e2) + chr($96) + chr($96), chr($dd));
        Result := Result.Replace(chr($e2) + chr($96) + chr($97), chr($de));
        Result := Result.Replace(chr($e2) + chr($96) + chr($98), chr($dd));
        Result := Result.Replace(chr($e2) + chr($96) + chr($99), chr($db));
        Result := Result.Replace(chr($e2) + chr($96) + chr($9a), chr(219));
        Result := Result.Replace(chr($e2) + chr($96) + chr($9b), chr(219));
        Result := Result.Replace(chr($e2) + chr($96) + chr($9c), chr($de));
        Result := Result.Replace(chr($e2) + chr($96) + chr($9d), chr($de));
        Result := Result.Replace(chr($e2) + chr($96) + chr($9b), chr($db));
        Result := Result.Replace(chr($e2) + chr($96) + chr($9c), chr($db));
        Result := Result.Replace(chr($e2) + chr($96) + chr($9d), chr(223));
        Result := Result.Replace(chr($e2) + chr($96) + chr($9e), chr(219));
        Result := Result.Replace(chr($e2) + chr($96) + chr($9f), chr($db));
        Result := Result.Replace(chr($e2) + chr($96) + chr($a0), chr(220));
        Result := Result.Replace(chr($e2) + chr($96) + chr($aa), chr(250));
        Result := Result.Replace(chr($e2) + chr($96) + chr($bc), chr(31));
        Result := Result.Replace(chr($e2) + chr($97) + chr($86), chr(4));
        Result := Result.Replace(chr($e2) + chr($97) + chr($8f), chr(7));
        Result := Result.Replace(chr($c2) + chr($b7), chr($fa));
        for I := 128 to 255 do
        begin
            Result := Result.Replace(chr($cd) + chr(I), '');
            Result := Result.Replace(chr($cc) + chr(I), '');
        end;
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
                begin
                    MenuItem := ParseMenuItem(Lines[I]);
                    MenuItem.Position := I;
                end
                else
                begin
                    MenuItem.ItemType := 'i';
                    MenuItem.SelectorString := '';
                    MenuItem.DisplayString := Lines[I];
                    MenuItem.Valid := True;
                    MenuItem.Position := I;
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
        Result.Position := 0;
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

    function TGopherClient.Get(Url: String): TGetResult;
    var
        TokenizedUrl: TTokenizedUrl;
        CharNum: SizeInt;
        ClientSocket: TSocketStream;
        DownloadData: TGopherDownload;
        KeepReading: Boolean;
        ResultStr: AnsiString = '';
        RequestStr: AnsiString = '';
        Part: AnsiString = '';
        Buf: array[0..1048577] of Char = '';
        Count: Integer = 1048576;
        IsMenu: Boolean = False;
        ReadResult: LongInt = 1;
        Menu: TGopherMenuItems;
    begin
        ResultStr := '';
        TokenizedUrl := ParseUrl(Url);
        Result.ResultType := GET_RESULT_NOTHING;
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
        KeepReading := True;
        while (KeepReading = True) do
        begin
            try
                ReadResult := ClientSocket.Read(Buf, Count);
                Logger^.Debug('Downloading...: ' + IntToStr(ResultStr.Length) + ' bytes.');
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

            (* Internally, Read() uses the recv() syscall, which returns 0
               if the connection has been terminated, or -1 on error. *)
            if ReadResult <= 0 then
            begin
                if ReadResult < 0 then
                begin
                    Logger^.Debug('Socket error: ' + IntToStr(ClientSocket.LastError));
                end;
                break;
            end;
            Part := '';
            for CharNum := 0 to ReadResult - 1 do
            begin
                Part := Part + Buf[CharNum];
            end;
            ResultStr += Part;
            Buf := '';
            Part := '';
        end;
        ClientSocket.Free;
        (* If ResultStr is blank, we didn't get anything. *)
        if Length(ResultStr) = 0 then
        begin
            Logger^.Error('No result received from server for: ' + Url);
            Exit;
        end;
        Logger^.Debug('Successfully retrieved ' + Url);
        if TokenizedUrl.DocumentType = '1' then IsMenu := True;
        if (TokenizedUrl.DocumentType = '0') or (TokenizedUrl.DocumentType = '1') then
        begin
            ResultStr := UTF8Hack(ResultStr);
            Menu := ParseMenu(ResultStr, IsMenu);
            if (Length(menu) = 0) then
            begin
                Logger^.Error('Could not parse server response as menu: ' + ResultStr);
            end;
            Result.MenuItems := Menu;
            Result.ResultType := GET_RESULT_CONTENT;
        end
        else
        begin
            { handle different types of content here. download? }
            Result.ResultType := GET_RESULT_DATA;
            DownloadData.FileName := TokenizedUrl.Path;
            DownloadData.Data := ResultStr;
            DownloadData.Size := ResultStr.Length;
            Result.DownloadData := DownloadData;
        end;
    end;

end.
