unit DrawUtils;

interface

uses
    Views;

(* This is a custom version of MoveChar that doesn't preserve the original
   attributes in the buffer if attributes equals zero. *)
procedure AddToDrawBuf(
    var buffer: TDrawBuffer;
    character: Byte;
    attributes: Byte;
    count: SizeInt);

(* Same as above, but allows for setting characters at a specific index. *)
procedure SetInDrawBuf(
    var buffer: TDrawBuffer;
    character: Byte;
    attributes: Byte;
    position: SizeInt);

implementation

procedure AddToDrawBuf(
    var buffer: TDrawBuffer;
    character: Byte;
    attributes: Byte;
    count: SizeInt);
var
    P: SizeInt;
begin
    for P := 0 to count do
        buffer[P] := (attributes * 256) + Byte(character);
end;

procedure SetInDrawBuf(
    var buffer: TDrawBuffer;
    character: Byte;
    attributes: Byte;
    position: SizeInt);
begin
    buffer[position] := (attributes * 256) + Byte(character);
end;

end.
