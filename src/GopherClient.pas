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

    TGopherMenuItem = record
        ItemType: char;
        DisplayString: RawByteString;
        SelectorString: RawByteString;
        Valid: Boolean;
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
        function Get(Url: string): string;
        function ParseMenu(const Body: string): TGopherMenuItems;
    private
        Logger: PLogger;
        function ParseMenuItem(const ItemLine: RawByteString): TGopherMenuItem;
        function ParseUrl(Url: string): TTokenizedUrl;
    end;

implementation

    constructor TGopherClient.Create(LoggerObject: PLogger);
    begin
        Logger := LoggerObject;
    end;

    function TGopherClient.ParseMenu(const Body: string): TGopherMenuItems;
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
            if (Length(Lines) > 2) then
            begin
                if Lines[I] = '.' then Exit; { Single dot marks the end. }
                MenuItem := ParseMenuItem(Lines[I]);
{                if (MenuItem.Valid <> True) then continue;}
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
        Result.Valid := False;
        (* We need at least a first character to get an item type. *)
        if (Length(ParsedItem) < 1) then Exit;
        Result.ItemType := ParsedItem[1];
        ParsedItem := Copy(ParsedItem, 2, Length(ParsedItem) - 1);
        (* Look for the tab character separating display/selector strings.
           Bail if we can't find one. *)
        tokens := StringSplit(ParsedItem, chr(9), 2);
        if Length(tokens) < 2 then Exit;
        (* Parse display and selector strings out. *)
        Result.DisplayString := Tokens[0];
        Result.SelectorString := Tokens[1];
        Result.Valid := True;
    end;

    function TGopherClient.ParseUrl(Url: string): TTokenizedUrl;
    const
        GopherURI: string = 'gopher://';
        gsPath: string = '/';
        GopherPort: Integer = 70;
    var
        unparsedPath: AnsiString;
        re: TRegExpr;
    begin
        if Pos(GopherURI, Url) <> 0 then
        begin
            Url := Copy(
                Url,
                Pos(GopherURI, Url) + Length(GopherURI), Length(Url)
            );
        end;
        if Pos(gsPath, Url) = 0 then
        begin
            unparsedPath := gsPath
        end else
        begin
            unparsedPath := Copy(Url, Pos(gsPath, Url), Length(Url))
        end;
        if Pos(':', Url) = 0 then
        begin
          if Pos(gsPath, Url) = 0 then
          begin
              Result.Host := Copy(Url, 1, Length(Url))
          end else
          begin
              Result.Host := Copy(Url, 1, Pos(gsPath, Url) - 1)
          end;
          Result.Port := GopherPort
      end else
      begin
          Result.Host := Copy(Url, 1, Pos(':', Url) - 1);
          Result.Port := StrToInt(
              Copy(Url, Pos(':', Url) + 1, Pos(gsPath, Url) - 1)
          );
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

    function TGopherClient.Get(Url: String): String;
    var
        TokenizedUrl: TTokenizedUrl;
        ClientSocket: TSocketStream;
        RequestStr: string = '';
        Part: string = '';
        Buf: array[0..4095] of Char = '';
        Count: Integer = 4094;
        ReadResult: LongInt = 1;
        Menu: TGopherMenuItems;
        I: SizeInt;
    begin
        TokenizedUrl := ParseUrl(Url);
        try
           ClientSocket := TInetSocket.Create(
               TokenizedUrl.Host,
               TokenizedUrl.Port);
        except
            on E: Exception do
            begin
                Logger^.Error('Could not connect to host: ' + TokenizedUrl.Host
                    + ' on port ' + IntToStr(TokenizedUrl.Port)
                    + ' - Error: ' + E. Message);
                ClientSocket.Free;
                Exit;
            end;
        end;
        RequestStr := TokenizedUrl.Path + #13#10;
        ClientSocket.Write(RequestStr[1], Length(RequestStr));
        Result := '';
        while (ReadResult > 0) do
        begin
            try
                ReadResult := ClientSocket.Read(Buf, Count);
            except
                on E: ESocketError do
                begin
                    Result += ' | Error while reading from host: ' + TokenizedUrl.Host;
                    Result += ' on port ' + IntToStr(TokenizedUrl.Port);
                    Result += ' - Error: ' + E. Message;
                    ClientSocket.Free;
                    Exit;
                end;
            end;
            if ReadResult = 0 then break;
            Part := Copy(Buf, 0, ReadResult);
            Result += Part;
            Buf := '';
        end;
        Logger^.Debug('Successfully retrieved ' + Url);
        ClientSocket.Free;
        Menu := ParseMenu(Result);
        if (Length(menu) = 0) then
        begin
            Logger^.Error('Could not parse server response as menu: ' + Result);
        end;
        Result := '';
        for I := 0 to Length(Menu) - 1 do
        begin
            Result += Menu[I].DisplayString + chr(10);
        end;
    end;

end.
