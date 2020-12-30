unit SideBarWidget;

{$mode objfpc}{$H+}

interface

uses

    DrawUtils,
    GopherClient,
    TurboGopherApplication,

    Classes,
    Drivers,
    Objects,
    SysUtils,
    Views;

type

    PSideBarWidget = ^TSideBarWidget;
    TSideBarWidget = object(TView)
        constructor Init(
            var TheApp: TTurboGopherApplication;
            Bounds: TRect
        );
        procedure Add(Item: TGopherMenuItem);
        procedure Draw; virtual;
        function GetFirst: SizeInt;
        function GetLast: SizeInt;
        function GetSelected: PGopherMenuItem;
        procedure Reset;
        procedure SetDelta(d: SizeInt);
        procedure SetItems(MenuItems: TGopherMenuItems);
        procedure SelectFirst;
        procedure SelectNext;
        procedure SelectPrevious;
        procedure SelectLast;
        private
            App: TTurboGopherApplication;
            Delta: SizeInt;
            Items: TGopherMenuItems;
            Rect: TRect;
            SelectedIndex: SizeInt;
            const
                defaultBackgroundAttrs = $0f;
                defaultTextAttrs = $0f;
                defaultDirAttrs = $02;
                defaultCsoNsAttrs = $0f;
                defaultHqxFilerAttrs = $0f;
                defaultBinaryAttrs = $0f;
                defaultUuFileAttrs = $0f;
                defaultSearchAttrs = $03;
                defaultTelnetAttrs = $0f;
                defaultCalAttrs = $0f;
                defaultEventAttrs = $0f;
                defaultGifAttrs = $0f;
                defaultHtmlAttrs = $0f;
                defaultSoundAttrs = $0f;
                defaultImageAttrs = $0f;
                defaultMimeAttrs = $0f;
                defaultTnAttrs = $0f;
    end;

implementation

{ Helper functions }

function IsSelectable(Item: TGopherMenuItem): Boolean;
begin
    Result := False;
    if Item.ItemType in [
        '0', '1', '2', '4', '5', '6', '7', '8', '9',
        'c', 'e', 'g', 'h', 's', 'I', 'M', 'T'
    ] then Result := True;
end;

{ TSideBarWidget }

constructor TSideBarWidget.Init(
    var TheApp: TTurboGopherApplication;
    Bounds: TRect
);
begin
    Delta := 0;
    Rect := Bounds;
    TView.Init(Bounds);
    App := TheApp;
    SelectedIndex := 0;
end;

procedure TSideBarWidget.Add(Item: TGopherMenuItem);
begin
    SetLength(Items, Length(Items) + 1);
    Items[Length(Items) - 1] := Item;
    SelectFirst;
end;

procedure TSideBarWidget.Draw;
var
    Color: Byte;
    DrawBuffer: TDrawBuffer;
    I, L: SizeInt;
    Entry: AnsiString = '';
    Selectable: Boolean = False;
begin
    DrawBuffer := default(TDrawBuffer);
    Color := defaultBackgroundAttrs;
    { clear the screen }
    AddToDrawBuf(DrawBuffer, 32, Color, Size.X);
    WriteLine(0, 0, Size.X, Size.Y, DrawBuffer);
    DrawBuffer := default(TDrawBuffer);
    { render characters }
    GetBounds(Rect);
    for L := 0 to Rect.B.Y do
    begin
        Entry := '   ';
        I := Delta + L;
        Selectable := False;
        if I < Length(Items) then
        begin
            Entry := Items[I].ItemType;
            Selectable := IsSelectable(Items[I]);
        end;
        case Entry of
            '0':
            begin
                Entry := ' text  ';
                Color := defaultTextAttrs;
            end;
            '1':
            begin
                Entry := ' dir   ';
                Color := defaultDirAttrs;
            end;
            '2':
            begin
                Entry := ' cso ns';
                Color := DefaultCsoNsAttrs;
            end;
            '3':
            begin
                Entry := '       ';
                Color := DefaultBackgroundAttrs;
            end;
            '4':
            begin
                Entry := ' hqxflr';
                Color := DefaultHqxFilerAttrs;
            end;
            '5':
            begin
                Entry := ' binary';
                Color := DefaultBinaryAttrs;
            end;
            '6':
            begin
                Entry := ' uufile';
                Color := DefaultUuFileAttrs;
            end;
            '7':
            begin
                Entry := ' search';
                Color := DefaultSearchAttrs;
            end;
            '8':
            begin
                Entry := ' telnet';
                Color := DefaultTelnetAttrs;
            end;
            '9':
            begin
                Entry := ' binary';
                Color := DefaultBinaryAttrs;
            end;
            'c':
            begin
                Entry := ' cal   ';
                Color := DefaultCalAttrs;
            end;
            'e':
            begin
                Entry := ' event ';
                Color := DefaultEventAttrs;
            end;
            'g':
            begin
                Entry := ' gifimg';
                Color := DefaultGifAttrs;
            end;
            'h':
            begin
                Entry := ' html  ';
                Color := DefaultHtmlAttrs;
            end;
            'i':
            begin
                Entry := '       ';
                Color := DefaultBackgroundAttrs;
            end;
            's':
                begin
                    Entry := ' sound ';
                    Color := DefaultSoundAttrs;
                end;
            'I':
            begin
                Entry := ' image ';
                Color := DefaultImageAttrs;
            end;
            'M':
            begin
                Entry := ' mime  ';
                Color := DefaultMimeAttrs;
            end;
            'T':
            begin
                Entry := ' TN3270';
                Color := DefaultTnAttrs;
            end
        else
            Entry := '       '
        end;
        if (Selectable = True) and (I = SelectedIndex) then InvertColor(Color);
        MoveStr(DrawBuffer, Entry, Color);
        WriteBuf(0, L, Length(Entry), 1, DrawBuffer);
        MoveStr(DrawBuffer, Chr(179), DefaultBackgroundAttrs);
        WriteBuf(Length(Entry), L, 1, 1, DrawBuffer);
    end;
end;

function TSideBarWidget.GetFirst: SizeInt;
begin
    Result := 0;
    if Length(Items) = 0 then
    begin
        Exit;
    end;
    for Result := 0 to Length(Items) - 1 do
    begin
        if IsSelectable(Items[Result]) = True then break;
    end;
end;

function TSideBarWidget.GetLast: SizeInt;
begin
    Result := Length(Items) - 1;
    if Result = 0 then
    begin
        Exit;
    end;
    while Result > 0 do
    begin
        if IsSelectable(Items[Result]) = True then break;
        Result := Result - 1;
    end;
end;

function TSideBarWidget.GetSelected: PGopherMenuItem;
begin
    Result := nil;
    if Length(Items) = 0 then Exit;
    if SelectedIndex > Length(Items) - 1 then
    begin
        SelectedIndex := 0;
        Exit;
    end;
    Result := @Items[SelectedIndex];
end;

procedure TSideBarWidget.SetDelta(d: SizeInt);
begin
    Delta := d;
end;

procedure TSideBarWidget.SetItems(MenuItems: TGopherMenuItems);
begin
    Items := MenuItems;
    SelectFirst;
end;

procedure TSideBarWidget.Reset;
begin
    SetLength(Items, 0);
    SelectedIndex := 0;
end;

procedure TSideBarWidget.SelectFirst;
begin
    SelectedIndex := GetFirst;
end;

procedure TSideBarWidget.SelectLast;
begin
    SelectedIndex := GetLast;
end;

procedure TSideBarWidget.SelectNext;
var
    I: SizeInt = 0;
    Last: SizeInt = 0;
begin
    if Length(Items) = 0 then
    begin
        SelectedIndex := 0;
        Exit;
    end;
    Last := GetLast;
    for I := SelectedIndex + 1 to Length(Items) - 1 do
    begin
        if IsSelectable(Items[I]) = True then break;
    end;
    if I > Last then I := Last;
    SelectedIndex := I;
end;

procedure TSideBarWidget.SelectPrevious;
var
    First: SizeInt = 0;
    I: SizeInt = 0;
begin
    if Length(Items) = 0 then
    begin
        SelectedIndex := 0;
        Exit;
    end;
    First := GetFirst;
    I := SelectedIndex - 1;
    while (I > 0) do
    begin
        if IsSelectable(Items[I]) = True then break;
        I := I - 1;
    end;
    if I < First then I := First;
    SelectedIndex := I;
end;


end.
