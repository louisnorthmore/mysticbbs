Program QwkPoll;

{$I M_OPS.PAS}

Uses
  m_DateTime,
  m_Strings,
  m_FileIO,
  m_TCP_Client_FTP,
  BBS_Records,
  BBS_DataBase,
  BBS_MsgBase_QWK;

Var
  TempPath : String;

Function PollByQWKNet (QwkNet: RecQwkNetwork) : Boolean;
Var
  QWK  : TQwkEngine;
  FTP  : TFTPClient;
  User : RecUser;
Begin
  Result := False;

  If (QwkNet.MemberType <> 1) or
     (QwkNet.PacketID = '') or
     (QwkNet.ArcType = '') Then Exit;

  WriteLn ('- Exchanging Mail for ' + QwkNet.Description);

  User.Handle     := QwkNet.PacketID;
  User.QwkNetwork := QwkNet.Index;

  QWK := TQwkEngine.Create (TempPath, QwkNet.PacketID, 1, User);

  QWK.IsNetworked := True;
  QWK.IsExtended  := QwkNet.UseQWKE;

  QWK.ExportPacket(True);

  ExecuteArchive (TempPath, TempPath + QwkNet.PacketID + '.rep', QwkNet.ArcType, TempPath + '*', 1);

  WriteLn ('      - Exported @' + QwkNet.PacketID + '.rep -> ', QWK.TotalMessages, ' msgs ');
  WriteLn ('      - Connecting via FTP to ' + QWkNet.HostName);

  FTP := TFTPClient.Create;

  If FTP.OpenConnection(QwkNet.HostName) Then Begin
    If FTP.Authenticate(QwkNet.Login, QwkNet.Password) Then Begin
      FTP.SendFile (QwkNet.UsePassive, TempPath + QwkNet.PacketID + '.rep');

      // if was sent successfully THEN update by setting
      // isSent on all messages UP until the QLR.DAT information?
      // also need to remove the SetLocal crap and make an UpdateSentFlags
      // in QWK class if we do this.

      DirClean       (TempPath, '');
      FTP.GetFile    (QwkNet.UsePassive, TempPath + QwkNet.PacketID + '.qwk');
      ExecuteArchive (TempPath, TempPath + QwkNet.PacketID + '.qwk', QwkNet.ArcType, '*', 2);

      QWK.ImportPacket(True);
    End;
  End;

  FTP.Free;
  QWK.Free;

  DirClean (TempPath, '');

  WriteLn;
End;

Var
  Str    : String;
  F      : File;
  QwkNet : RecQwkNetwork;
  Count  : Byte = 0;
Begin
  WriteLn;
  WriteLn ('QWKPOLL Version ' + mysVersion);
  WriteLn;

  Case bbsCfgStatus of
    1 : WriteLn ('Unable to read MYSTIC.DAT');
    2 : WriteLn ('Data file version mismatch');
  End;

  If bbsCfgStatus <> 0 Then Halt(1);

  TempPath := bbsCfg.SystemPath + 'tempqwk' + PathChar;

  DirCreate (TempPath);

  WriteLn ('Program session start at ' + FormatDate(CurDateDT, 'NNN DD YYYY HH:II:SS'));
  WriteLn;

  Str := strUpper(strStripB(ParamStr(1), ' '));

  If (Str = 'ALL') Then Begin
    Assign (F, bbsCfg.DataPath + 'qwknet.dat');

    If ioReset (F, SizeOf(RecQwkNetwork), fmRWDN) Then Begin
      While Not Eof(F) Do Begin
        ioRead (F, QwkNet);

        If PollByQwkNet(QwkNet) Then
          Inc (Count);
      End;

      Close (F);
    End;
  End Else
  If strS2I(Str) > 0 Then Begin
    If GetQwkNetByIndex(strS2I(Str), QwkNet) Then
      If PollByQwkNet(QwkNet) Then
        Inc (Count);
  End Else Begin
    WriteLn ('Invalid command line.');
    WriteLn;
    WriteLn ('Syntax: QWKPOLL [ALL] or [Qwk Network Index]');
    WriteLn;
    WriteLn ('Ex: QWKPOLL ALL - Exchange with ALL configured QWK hubs via FTP');
    WriteLn ('    QWKPOLL 1   - Exchange with only Qwk Network #1');
    WriteLn;
  End;

  WriteLn ('Processed ', Count, ' QWK networks');
End.