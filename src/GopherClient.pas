unit GopherClient;

{$mode objfpc}{$H+}

interface

uses
    ssockets,
    SysUtils,
    Classes;

type

    TTokenizedUrl = record
        Host: string;
        Path: string;
        Port: Word;
    end;

    TGopherClient = class
    private
        function ParseUrl(Url: string): TTokenizedUrl;
    public
        constructor Create();
        function Get(Url: String): String;
    end;

implementation

    function TGopherClient.ParseUrl(Url: string): TTokenizedUrl;
    const
        GopherURI: string = 'gopher://';
        gsPath: string = '/';
        GopherPort: Integer = 70;
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
            Result.Path := gsPath
        end else
        begin
            Result.Path := Copy(Url, Pos(gsPath, Url), Length(Url))
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
      end    
    end;

    constructor TGopherClient.Create();
    begin
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
    begin
        TokenizedUrl := ParseUrl(Url);
        try
           ClientSocket := TInetSocket.Create(
               TokenizedUrl.Host,
               TokenizedUrl.Port);
        except
            on E: Exception do
            begin
                Result := 'Could not connect to host: ' + TokenizedUrl.Host;
                Result += ' on port ' + IntToStr(TokenizedUrl.Port);
                Result += ' - Error: ' + E. Message;
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
                on E: Exception do
                begin
                    Result += ' | Error while reading from host: ' + TokenizedUrl.Host;
                    Result += ' on port ' + IntToStr(TokenizedUrl.Port);
                    Result += ' - Error: ' + E. Message;
                    ClientSocket.Free;
                    Exit;
                end;
            end;
            Part := Part + Copy(Buf, 0, Count);
            Result += Part;
        end;
        ClientSocket.Free;
    end;

end.
