{*******************************************************}
{                                                       }
{ EMoriniException is the base class for all exceptions }
{   that will be thrown by the system. The class also   }
{   stores the screen image of the error to be used in  }
{   problem identification.                             }
{                                                       }
{*******************************************************}

{*******************************************************}
{         Created by Thiago R. Morini - 08/2018         }
{*******************************************************}

unit Morini.Exception;

interface

uses
  System.SysUtils, Winapi.Windows, Vcl.Graphics, Vcl.Imaging.jpeg;

type
  EMoriniException = class(Exception)
  private
    FImage: TJPEGImage;
    procedure Printscreen;
  public
    constructor Create(const Msg: string); reintroduce;
    constructor CreateFmt(const Msg: string; const Args: array of const); reintroduce;
    property Image: TJPEGImage read FImage;
  end;

implementation

{ EMoriniException }

constructor EMoriniException.Create(const Msg: string);
begin
  Printscreen;

  if Assigned(Exception(ExceptObject)) then
    Message := PChar(Exception(ExceptObject).Message);
end;

constructor EMoriniException.CreateFmt(const Msg: string;
  const Args: array of const);
begin
  Printscreen;

  if Assigned(Exception(ExceptObject)) then
    Message := PChar(Exception(ExceptObject).Message);
end;

procedure EMoriniException.Printscreen;
const
  FULL_WINDOW = True;

var
  Win: HWND;
  DC: HDC;
  WinRect: TRect;
  Width: Integer;
  Height: Integer;
  Bmp: TBitmap;
begin
  Win := GetForegroundWindow;

  if FULL_WINDOW then
  begin
    GetWindowRect(Win, WinRect);
    DC := GetWindowDC(Win);
  end
  else
  begin
    GetClientRect(Win, WinRect);
    DC := GetDC(Win);
  end;

  try
    Width := WinRect.Right - WinRect.Left;
    Height := WinRect.Bottom - WinRect.Top;

    Bmp := TBitmap.Create;
    FImage := TJPEGImage.Create;
    try
      Bmp.Height := Height;
      Bmp.Width := Width;
      Bmp.Transparent := false;

      BitBlt(Bmp.Canvas.Handle, 0, 0, Width, Height, DC, 0, 0, SRCCOPY);

      FImage.Assign(Bmp);
      FImage.PixelFormat := jf24Bit;
    finally
      FreeAndNil(Bmp);
    end;
  finally
    ReleaseDC(Win, DC);
  end;
end;

end.
