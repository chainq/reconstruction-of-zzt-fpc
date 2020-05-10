{
	Copyright (c) 2020 Adrian Siekierka

	Based on a reconstruction of code from ZZT,
	Copyright 1991 Epic MegaGames, used with permission.

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
}

{$I-}
unit zztVideo;

interface
	type
		TVideoLine = string[80];
		TVideoWriteTextProc = procedure(x, y, color: byte; text: TVideoLine);
	const
		PORT_CGA_PALETTE = $03D9;
	var
		VideoWriteText: TVideoWriteTextProc;
		VideoMonochrome: boolean;
		VideoColumns: integer;
		VideoBorderColor: integer;
		VideoTextSegment: word;
		VideoTextPointer: pointer;
		VideoCursorVisible: boolean;
	function VideoConfigure: boolean;
	procedure VideoInstall(columns, borderColor: integer);
	procedure VideoUninstall;
	procedure VideoShowCursor;
	procedure VideoHideCursor;
	procedure VideoSetBorderColor(value: integer);
	procedure VideoMove(x, y, chars: integer; data: pointer; toVideo: boolean);

implementation
uses vidCrt, video, Dos;

{$F+}

procedure VideoWriteTextCO(x, y, color: byte; text: TVideoLine);
	var
		i: integer;
		ofs: integer;
		attr: word;
	begin
		attr:=color shl 8;
		if length(text) > 0 then begin
			attr:=color shl 8;
			ofs:=y * VideoColumns + x;
			for i:=0 to length(text)-1 do
				VideoBuf^[ofs+i]:=attr + ord(text[i+1]);
		end;
		UpdateScreen(false);
	end;

procedure VideoWriteTextBW(x, y, color: byte; text: TVideoLine);
	var
		i: integer;
		ofs: integer;
		attr: word;
	begin
		if (color and $08) = $08 then begin
			if (color and $F0) = 0 then
				color := $0F
			else
				color := $7F;
		end else begin
			if (color and $07) <> 0 then
				color := $07
			else
				color := $70;
		end;

		attr:=color shl 8;
		if length(text) > 0 then begin
			attr:=color shl 8;
			ofs:=y * VideoColumns + x;
			for i:=0 to length(text)-1 do
				VideoBuf^[ofs+i]:=attr + ord(text[i+1]);
		end;
		UpdateScreen(false);
	end;

{$F-}

function VideoConfigure: boolean;
	var
		charTyped: Char;
	begin
		charTyped := ' ';
		Writeln;
		Write('  Video mode:  C)olor,  M)onochrome?  ');
		repeat
			repeat until KeyPressed;
			charTyped := UpCase(ReadKey);
		until charTyped in [#27, 'C', 'M'];
		case charTyped of
			'C': VideoMonochrome := false;
			'M': VideoMonochrome := true;
			#27: VideoMonochrome := (LastMode = 7);
		end;
		VideoConfigure := charTyped <> #27;
	end;

procedure VideoInstall(columns, borderColor: integer);
	begin
		TextBackground(borderColor);

		VideoColumns := columns;
		TextMode(CO80);
		if VideoMonochrome then
			VideoWriteText := VideoWriteTextBW
		else
			VideoWriteText := VideoWriteTextCO;
		ClrScr;
		if not VideoCursorVisible then
			VideoHideCursor;
		VideoSetBorderColor(borderColor);
	end;

procedure VideoUninstall;
	begin
	{ only called on exit, video unit will clean itself up }
	end;

procedure VideoSetCursorShape(value: integer);
	begin
	{ custom cursor shapes are not supported by video unit }
	end;

procedure VideoShowCursor;
	begin
	SetCursorType(crUnderLine);
	VideoCursorVisible := true;
	end;

procedure VideoHideCursor;
	begin
	SetCursorType(crHidden);
	VideoCursorVisible := false;
	end;

procedure VideoSetBorderColor(value: integer);
	begin
	{ there is no border color with the video unit }
	end;

procedure VideoMove(x, y, chars: integer; data: pointer; toVideo: boolean);
	var
		offset: integer;
	begin
		offset := (y * VideoColumns + x);
		VideoWriteTextCO(0, 0, 0, '');
		if toVideo then begin
			Move(data^, VideoBuf^[offset], chars * 2);
			UpdateScreen(false);
		end else
			Move(VideoBuf^[offset], data^, chars * 2);
	end;


begin
	VideoBorderColor := 0;
	VideoColumns := 80;
	VideoWriteText := VideoWriteTextCO;
	VideoMonochrome := false;
	VideoCursorVisible := true;
end.
