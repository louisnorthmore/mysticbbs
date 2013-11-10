Unit AViewLZH;

// ====================================================================
// Mystic BBS Software               Copyright 1997-2013 By James Coyle
// ====================================================================
//
// This file is part of Mystic BBS.
//
// Mystic BBS is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Mystic BBS is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Mystic BBS.  If not, see <http://www.gnu.org/licenses/>.
//
// ====================================================================

{$I M_OPS.PAS}

Interface

Uses
  Dos,
  AView;

Type
  LFHeader = Record
    HeadSize,
    HeadChk   : Byte;
    HeadID    : Packed Array[1..5] of Char;
    PackSize,
    OrigSize,
    FileTime  : LongInt;
    Attr      : Word;
    FileName  : String[12];
    F32       : String[255];
    DT        : DateTime;
  End;

  PLzhArchive = ^TLzhArchive;
  TLzhArchive = Object(TGeneralArchive)
    Constructor Init;
    Procedure FindFirst (Var SR: ArcSearchRec); Virtual;
    Procedure FindNext  (Var SR: ArcSearchRec); Virtual;
  Private
    _FHdr : LFHeader;
    _SL   : LongInt;
    Procedure GetHeader (Var SR: ArcSearchRec);
  End;

Implementation

Constructor TLzhArchive.Init;
Begin
  _SL := 0;
  FillChar (_FHdr,sizeof(_FHdr), 0);
End;

Procedure TLzhArchive.GetHeader (Var SR: ArcSearchRec);
Var
  NR : LongInt;
Begin
  FillChar (SR, SizeOf(SR), 0);
  Seek     (ArcFile, _SL);

  If Eof(ArcFile) Then Exit;

  BlockRead (ArcFile, _FHdr, SizeOf(LFHeader), NR);

  If _FHdr.HeadSize = 0 Then Exit;

  Inc (_SL, _FHdr.HeadSize);
  Inc (_SL, 2);
  Inc (_SL, _FHdr.PackSize);

  If _FHdr.HeadSize <> 0 Then
    UnPackTime (_FHdr.FileTime, _FHdr.DT);

  If Pos(#0, _FHdr.FileName) > 0 Then
    SR.Name := Copy(_FHdr.FileName, 1, Pos(#0, _FHdr.FileName) - 1)
  Else
    SR.Name := _FHdr.FileName;

  SR.Size := _FHdr.OrigSize;
  SR.Time := _FHdr.FileTime;
End;

Procedure TLzhArchive.FindFirst (Var SR: ArcSearchRec);
Begin
  GetHeader(SR);
End;

Procedure TLzhArchive.FindNext (Var SR: ArcSearchRec);
Begin
  GetHeader(SR);
End;

End.
