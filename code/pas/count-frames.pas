program XTXTFrameCounter;

uses
  SysUtils;

const
  MarkerHigh: Byte = $FF;
  MarkerLow: Byte = $FD;

function CountFramesInXtxt(const FilePath: string): Integer;
var
  FileStream: TFileStream;
  Buffer: array[1..1024] of Byte;
  BytesRead, I: Integer;
  FrameCount: Integer;
  PreviousByte: Byte;
  FirstByte: Boolean;
begin
  FrameCount := 0;
  FirstByte := True;

  try
    FileStream := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyWrite);
    try
      while True do
      begin
        BytesRead := FileStream.Read(Buffer, SizeOf(Buffer));
        if BytesRead = 0 then
          Break;

        for I := 1 to BytesRead do
        begin
          if not FirstByte and (PreviousByte = MarkerHigh) and (Buffer[I] = MarkerLow) then
            Inc(FrameCount);

          PreviousByte := Buffer[I];
          FirstByte := False;
        end;
      end;

      Result := FrameCount;
    finally
      FileStream.Free;
    end;
  except
    on E: EFOpenError do
    begin
      Writeln('Error: Unable to open file ', FilePath, '.');
      Result := -1;
    end;
    on E: Exception do
    begin
      Writeln('Error: ', E.Message);
      Result := -1;
    end;
  end;
end;

var
  FilePath: string;
  FrameCount: Integer;
begin
  if ParamCount < 1 then
  begin
    Writeln('Usage: XTXTFrameCounter <file_path>');
    Halt(1);
  end;

  FilePath := ParamStr(1);
  FrameCount := CountFramesInXtxt(FilePath);

  if FrameCount >= 0 then
    Writeln('Total frames: ', FrameCount)
  else
    Writeln('Failed to count frames.');
end.
