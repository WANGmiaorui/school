' Windows Installer utility to generate file cabinets from MSI database
' For use with Windows Scripting Host, CScript.exe or WScript.exe
' Copyright (c) Microsoft Corporation. All rights reserved.
' Demonstrates the access to install engine and actions
'
Option Explicit

' FileSystemObject.CreateTextFile and FileSystemObject.OpenTextFile
Const OpenAsASCII   = 0 
Const OpenAsUnicode = -1

' FileSystemObject.CreateTextFile
Const OverwriteIfExist = -1
Const FailIfExist      = 0

' FileSystemObject.OpenTextFile
Const OpenAsDefault    = -2
Const CreateIfNotExist = -1
Const FailIfNotExist   = 0
Const ForReading = 1
Const ForWriting = 2
Const ForAppending = 8

Const msiOpenDatabaseModeReadOnly = 0
Const msiOpenDatabaseModeTransact = 1

Const msiViewModifyInsert         = 1
Const msiViewModifyUpdate         = 2
Const msiViewModifyAssign         = 3
Const msiViewModifyReplace        = 4
Const msiViewModifyDelete         = 6

Const msiUILevelNone = 2

Const msiRunModeSourceShortNames = 9

Const msidbFileAttributesNoncompressed = &h00002000

Dim argCount:argCount = Wscript.Arguments.Count
Dim iArg:iArg = 0
If argCount > 0 Then If InStr(1, Wscript.Arguments(0), "?", vbTextCompare) > 0 Then argCount = 0
If (argCount < 2) Then
	Wscript.Echo "Windows Installer utility to generate compressed file cabinets from MSI database" &_
		vbNewLine & " The 1st argument is the path to MSI database, at the source file root" &_
		vbNewLine & " The 2nd argument is the base name used for the generated files (DDF, INF, RPT)" &_
		vbNewLine & " The 3rd argument can optionally specify separate source location from the MSI" &_
		vbNewLine & " The following options may be specified at any point on the command line" &_
		vbNewLine & "  /L to use LZX compression instead of MSZIP" &_
		vbNewLine & "  /F to limit cabinet size to 1.44 MB floppy size rather than CD" &_
		vbNewLine & "  /C to run compression, else only generates the .DDF file" &_
		vbNewLine & "  /U to update the MSI database to reference the generated cabinet" &_
		vbNewLine & "  /E to embed the cabinet file in the installer package as a stream" &_
		vbNewLine & "  /S to sequence number file table, ordered by directories" &_
		vbNewLine & "  /R to revert to non-cabinet install, removes cabinet if /E specified" &_
		vbNewLine & " Notes:" &_
		vbNewLine & "  In order to generate a cabinet, MAKECAB.EXE must be on the PATH" &_
		vbNewLine & "  base name used for files and cabinet stream is case-sensitive" &_
		vbNewLine & "  If source type set to compressed, all files will be opened at the root" &_
		vbNewLine & "  (The /R option removes the compressed bit - SummaryInfo property 15 & 2)" &_
		vbNewLine & "  To replace an embedded cabinet, include the options: /R /C /U /E" &_
		vbNewLine & "  Does not handle updating of Media table to handle multiple cabinets" &_
		vbNewLine &_
		vbNewLine & "Copyright (C) Microsoft Corporation.  All rights reserved."
	Wscript.Quit 1
End If

' Get argument values, processing any option flags
Dim compressType : compressType = "MSZIP"
Dim cabSize      : cabSize      = "CDROM"
Dim makeCab      : makeCab      = False
Dim embedCab     : embedCab     = False
Dim updateMsi    : updateMsi    = False
Dim sequenceFile : sequenceFile = False
Dim removeCab    : removeCab    = False
Dim databasePath : databasePath = NextArgument
Dim baseName     : baseName     = NextArgument
Dim sourceFolder : sourceFolder = NextArgument
If Not IsEmpty(NextArgument) Then Fail "More than 3 arguments supplied" ' process any trailing options
If Len(baseName) < 1 Or Len(baseName) > 8 Then Fail "Base file name must be from 1 to 8 characters"
If Not IsEmpty(sourceFolder) And Right(sourceFolder, 1) <> "\" Then sourceFolder = sourceFolder & "\"
Dim cabFile : cabFile = baseName & ".CAB"
Dim cabName : cabName = cabFile : If embedCab Then cabName = "#" & cabName

' Connect to Windows Installer object
On Error Resume Next
Dim installer : Set installer = Nothing
Set installer = Wscript.CreateObject("WindowsInstaller.Installer") : CheckError

' Open database
Dim database, openMode, view, record, updateMode, sumInfo, sequence, lastSequence
If updateMsi Or sequenceFile Or removeCab Then openMode = msiOpenDatabaseModeTransact Else openMode = msiOpenDatabaseModeReadOnly
Set database = installer.OpenDatabase(databasePath, openMode) : CheckError

' Remove existing cabinet(s) and revert to source tree install if options specified
If removeCab Then
	Set view = database.OpenView("SELECT DiskId, LastSequence, Cabinet FROM Media ORDER BY DiskId") : CheckError
	view.Execute : CheckError
	updateMode = msiViewModifyUpdate
	Set record = view.Fetch : CheckError
	If Not record Is Nothing Then ' Media table not empty
		If Not record.IsNull(3) Then
			If record.StringData(3) <> cabName Then Wscript.Echo "Warning, cabinet name in media table, " & record.StringData(3) & " does not match " & cabName
			record.StringData(3) = Empty
		End If
		record.IntegerData(2) = 9999 ' in case of multiple cabinets, force all files from 1st media
		view.Modify msiViewModifyUpdate, record : CheckError
		Do
			Set record = view.Fetch : CheckError
			If record Is Nothing Then Exit Do
			view.Modify msiViewModifyDelete, record : CheckError 'remove other cabinet records
		Loop
	End If
	Set sumInfo = database.SummaryInformation(3) : CheckError
	sumInfo.Property(11) = Now
	sumInfo.Property(13) = Now
	sumInfo.Property(15) = sumInfo.Property(15) And Not 2
	sumInfo.Persist
	Set view = database.OpenView("SELECT `Name`,`Data` FROM _Streams WHERE `Name`= '" & cabFile & "'") : CheckError
	view.Execute : CheckError
	Set record = view.Fetch
	If record Is Nothing Then
		Wscript.Echo "Warning, cabinet stream not found in package: " & cabFile
	Else
		view.Modify msiViewModifyDelete, record : CheckError
	End If
	Set sumInfo = Nothing ' must release stream
	database.Commit : CheckError
	If Not updateMsi Then Wscript.Quit 0
End If

' Create an install session and execute actions in order to perform directory resolution
installer.UILevel = msiUILevelNone
Dim session : Set session = installer.OpenPackage(database,1) : If Err <> 0 Then Fail "Database: " & databasePath & ". Invalid installer package format"
Dim shortNames : shortNames = session.Mode(msiRunModeSourceShortNames) : CheckError
If Not IsEmpty(sourceFolder) Then session.Property("OriginalDatabase") = sourceFolder : CheckError
Dim stat : stat = session.DoAction("CostInitialize") : CheckError
If stat <> 1 Then Fail "CostInitialize failed, returned " & stat

' Check for non-cabinet files to avoid sequence number collisions
lastSequence = 0
If sequenceFile Then
	Set view = database.OpenView("SELECT Sequence,Attributes FROM File") : CheckError
	view.Execute : CheckError
	Do
		Set record = view.Fetch : CheckError
		If record Is Nothing Then Exit Do
		sequence = record.IntegerData(1)
		If (record.IntegerData(2) And msidbFileAttributesNoncompressed) <> 0 And sequence > lastSequence Then lastSequence = sequence
	Loop	
End If

' Join File table to Component table in order to find directories
Dim orderBy : If sequenceFile Then orderBy = "Directory_" Else orderBy = "Sequence"
Set view = database.OpenView("SELECT File,FileName,Directory_,Sequence,File.Attributes FROM File,Component WHERE Component_=Component ORDER BY " & orderBy) : CheckError
view.Execute : CheckError

' Create DDF file and write header properties
Dim FileSys : Set FileSys = CreateObject("Scripting.FileSystemObject") : CheckError
Dim outStream : Set outStream = FileSys.CreateTextFile(baseName & ".DDF", OverwriteIfExist, OpenAsASCII) : CheckError
outStream.WriteLine "; Generated from " & databasePath & " on " & Now
outStream.WriteLine ".Set CabinetNameTemplate=" & baseName & "*.CAB"
outStream.WriteLine ".Set CabinetName1=" & cabFile
outStream.WriteLine ".Set ReservePerCabinetSize=8"
outStream.WriteLine ".Set MaxDiskSize=" & cabSize
outStream.WriteLine ".Set CompressionType=" & compressType
outStream.WriteLine ".Set InfFileLineFormat=(*disk#*) *file#*: *file* = *Size*"
outStream.WriteLine ".Set InfFileName=" & baseName & ".INF"
outStream.WriteLine ".Set RptFileName=" & baseName & ".RPT"
outStream.WriteLine ".Set InfHeader="
outStream.WriteLine ".Set InfFooter="
outStream.WriteLine ".Set DiskDirectoryTemplate=."
outStream.WriteLine ".Set Compress=ON"
outStream.WriteLine ".Set Cabinet=ON"

' Fetch each file and request the source path, then verify the source path
Dim fileKey, fileName, folder, sourcePath, delim, message, attributes
Do
	Set record = view.Fetch : CheckError
	If record Is Nothing Then Exit Do
	fileKey    = record.StringData(1)
	fileName   = record.StringData(2)
	folder     = record.StringData(3)
	sequence   = record.IntegerData(4)
	attributes = record.IntegerData(5)
	If (attributes And msidbFileAttributesNoncompressed) = 0 Then
		If sequence <= lastSequence Then
			If Not sequenceFile Then Fail "Duplicate sequence numbers in File table, use /S option"
			sequence = lastSequence + 1
			record.IntegerData(4) = sequence
			view.Modify msiViewModifyUpdate, record
		End If
		lastSequence = sequence
		delim = InStr(1, fileName, "|", vbTextCompare)
		If delim <> 0 Then
			If shortNames Then fileName = Left(fileName, delim-1) Else fileName = Right(fileName, Len(fileName) - delim)
		End If
		sourcePath = session.SourcePath(folder) & fileName
		outStream.WriteLine """" & sourcePath & """" & " " & fileKey
		If installer.FileAttributes(sourcePath) = -1 Then message = message & vbNewLine & sourcePath
	End If
Loop
outStream.Close
REM Wscript.Echo "SourceDir = " & session.Property("SourceDir")
If Not IsEmpty(message) Then Fail "The following files were not available:" & message

' Generate compressed file cabinet
If makeCab Then
	Dim WshShell : Set WshShell = Wscript.CreateObject("Wscript.Shell") : CheckError
	Dim cabStat : cabStat = WshShell.Run("MakeCab.exe /f " & baseName & ".DDF", 7, True) : CheckError
	If cabStat <> 0 Then Fail "MAKECAB.EXE failed, possibly could not find source files, or invalid DDF format"
End If

' Update Media table and SummaryInformation if requested
If updateMsi Then
	Set view = database.OpenView("SELECT DiskId, LastSequence, Cabinet FROM Media ORDER BY DiskId") : CheckError
	view.Execute : CheckError
	updateMode = msiViewModifyUpdate
	Set record = view.Fetch : CheckError
	If record Is Nothing Then ' Media table empty
		Set record = Installer.CreateRecord(3)
		record.IntegerData(1) = 1
		updateMode = msiViewModifyInsert
	End If
	record.IntegerData(2) = lastSequence
	record.StringData(3) = cabName
	view.Modify updateMode, record
	Set sumInfo = database.SummaryInformation(3) : CheckError
	sumInfo.Property(11) = Now
	sumInfo.Property(13) = Now
	sumInfo.Property(15) = (shortNames And 1) + 2
	sumInfo.Persist
End If

' Embed cabinet if requested
If embedCab Then
	Set view = database.OpenView("SELECT `Name`,`Data` FROM _Streams") : CheckError
	view.Execute : CheckError
	Set record = Installer.CreateRecord(2)
	record.StringData(1) = cabFile
	record.SetStream 2, cabFile : CheckError
	view.Modify msiViewModifyAssign, record : CheckError 'replace any existing stream of that name
End If

' Commit database in case updates performed
database.Commit : CheckError
Wscript.Quit 0

' Extract argument value from command line, processing any option flags
Function NextArgument
	Dim arg
	Do  ' loop to pull in option flags until an argument value is found
		If iArg >= argCount Then Exit Function
		arg = Wscript.Arguments(iArg)
		iArg = iArg + 1
		If (AscW(arg) <> AscW("/")) And (AscW(arg) <> AscW("-")) Then Exit Do
		Select Case UCase(Right(arg, Len(arg)-1))
			Case "C" : makeCab      = True
			Case "E" : embedCab     = True
			Case "F" : cabSize      = "1.44M"
			Case "L" : compressType = "LZX"
			Case "R" : removeCab    = True
			Case "S" : sequenceFile = True
			Case "U" : updateMsi    = True
			Case Else: Wscript.Echo "Invalid option flag:", arg : Wscript.Quit 1
		End Select
	Loop
	NextArgument = arg
End Function

Sub CheckError
	Dim message, errRec
	If Err = 0 Then Exit Sub
	message = Err.Source & " " & Hex(Err) & ": " & Err.Description
	If Not installer Is Nothing Then
		Set errRec = installer.LastErrorRecord
		If Not errRec Is Nothing Then message = message & vbNewLine & errRec.FormatText
	End If
	Fail message
End Sub

Sub Fail(message)
	Wscript.Echo message
	Wscript.Quit 2
End Sub

'' SIG '' Begin signature block
'' SIG '' MIImcAYJKoZIhvcNAQcCoIImYTCCJl0CAQExDzANBglg
'' SIG '' hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
'' SIG '' BgEEAYI3AgEeMCQCAQEEEE7wKRaZJ7VNj+Ws4Q8X66sC
'' SIG '' AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
'' SIG '' +3czCZ7bOIQLc7kJN8m8lyJpE9uBKr7KXjIe8c3/+0yg
'' SIG '' ggtnMIIE7zCCA9egAwIBAgITMwAABQAn1jJvQ3N7hwAA
'' SIG '' AAAFADANBgkqhkiG9w0BAQsFADB+MQswCQYDVQQGEwJV
'' SIG '' UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
'' SIG '' UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
'' SIG '' cmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBT
'' SIG '' aWduaW5nIFBDQSAyMDEwMB4XDTIzMDIxNjIwMTExMVoX
'' SIG '' DTI0MDEzMTIwMTExMVowdDELMAkGA1UEBhMCVVMxEzAR
'' SIG '' BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
'' SIG '' bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
'' SIG '' bjEeMBwGA1UEAxMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
'' SIG '' MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
'' SIG '' xZG5LUzwCcLo1qngBfRIvaoxHBx4YAznAhlyj2RbHnLe
'' SIG '' j+9v3xg+or/b6vesUC5EiND4X15wcARi1JbWcIuTyWgO
'' SIG '' yBcmkD4y2+UwfRBtEe/DHCLjIMkcHiN4w3HueFjzmiQh
'' SIG '' XX4t4Qbx/wKFu7UB9FGvtkMnMWx2YIPPxKZXAWi1jPz6
'' SIG '' 1yE9zdGZg20glsf5mbv8yRA00u2d+0nOWr5AXTmyuB9V
'' SIG '' 1TS4e+IqKd+Mgc4hTV4UPH0drrMugdrn943JD6IB8MpH
'' SIG '' b4dD4m2PC4KueSJbY71fSpR3ekB8XkSejNBGSoCFH3AB
'' SIG '' dMOV1hSWc3jh1gehOTZnclObBOp0LhqRoQIDAQABo4IB
'' SIG '' bjCCAWowHwYDVR0lBBgwFgYKKwYBBAGCNz0GAQYIKwYB
'' SIG '' BQUHAwMwHQYDVR0OBBYEFJ0K2XcwHGE1ocy2q2IIwzoq
'' SIG '' NSkjMEUGA1UdEQQ+MDykOjA4MR4wHAYDVQQLExVNaWNy
'' SIG '' b3NvZnQgQ29ycG9yYXRpb24xFjAUBgNVBAUTDTIzMDg2
'' SIG '' NSs1MDAyMzEwHwYDVR0jBBgwFoAU5vxfe7siAFjkck61
'' SIG '' 9CF0IzLm76wwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDov
'' SIG '' L2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVj
'' SIG '' dHMvTWljQ29kU2lnUENBXzIwMTAtMDctMDYuY3JsMFoG
'' SIG '' CCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0cDov
'' SIG '' L3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWND
'' SIG '' b2RTaWdQQ0FfMjAxMC0wNy0wNi5jcnQwDAYDVR0TAQH/
'' SIG '' BAIwADANBgkqhkiG9w0BAQsFAAOCAQEA4dJD1I1GLc5T
'' SIG '' xLzKBTVx6OGl+UT6XWeK28q1N1K+CyuIVy16DIp18YEp
'' SIG '' 0sbrCcpV3XpqL4N/EZcYmZYGGHNGHO2IHQVkZfc5ngPq
'' SIG '' 4ENLK30ehdc7YKG62MbRzo6E4YlrwXi5mTo1Fba5ryYB
'' SIG '' rtnoXxXg9q5g8/QoCzpMNnhuPdrydKaABUSEWfAbaYAg
'' SIG '' 8M2YJroQKe4SqMMEcjJP6RETgrQNOESzEoZSJE+DSQQx
'' SIG '' NjlQ+Uz9Pw8za9yPIxBgVc6m/0AJSX9TDAUrR82MU0P1
'' SIG '' Hh/Ty/4K9osi1BEd5uPIswZYtePscr4gVQu3AilwAL9e
'' SIG '' 3PPkEdzSny+ceQI6NfGHRTCCBnAwggRYoAMCAQICCmEM
'' SIG '' UkwAAAAAAAMwDQYJKoZIhvcNAQELBQAwgYgxCzAJBgNV
'' SIG '' BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
'' SIG '' VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
'' SIG '' Q29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBS
'' SIG '' b290IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDEwMB4X
'' SIG '' DTEwMDcwNjIwNDAxN1oXDTI1MDcwNjIwNTAxN1owfjEL
'' SIG '' MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
'' SIG '' EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
'' SIG '' c29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
'' SIG '' b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMDCCASIwDQYJ
'' SIG '' KoZIhvcNAQEBBQADggEPADCCAQoCggEBAOkOZFB5Z7XE
'' SIG '' 4/0JAEyelKz3VmjqRNjPxVhPqaV2fG1FutM5krSkHvn5
'' SIG '' ZYLkF9KP/UScCOhlk84sVYS/fQjjLiuoQSsYt6JLbklM
'' SIG '' axUH3tHSwokecZTNtX9LtK8I2MyI1msXlDqTziY/7Ob+
'' SIG '' NJhX1R1dSfayKi7VhbtZP/iQtCuDdMorsztG4/BGScEX
'' SIG '' ZlTJHL0dxFViV3L4Z7klIDTeXaallV6rKIDN1bKe5QO1
'' SIG '' Y9OyFMjByIomCll/B+z/Du2AEjVMEqa+Ulv1ptrgiwtI
'' SIG '' d9aFR9UQucboqu6Lai0FXGDGtCpbnCMcX0XjGhQebzfL
'' SIG '' GTOAaolNo2pmY3iT1TDPlR8CAwEAAaOCAeMwggHfMBAG
'' SIG '' CSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBTm/F97uyIA
'' SIG '' WORyTrX0IXQjMubvrDAZBgkrBgEEAYI3FAIEDB4KAFMA
'' SIG '' dQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUw
'' SIG '' AwEB/zAfBgNVHSMEGDAWgBTV9lbLj+iiXGJo0T2UkFvX
'' SIG '' zpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3Js
'' SIG '' Lm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9N
'' SIG '' aWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcmwwWgYIKwYB
'' SIG '' BQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3
'' SIG '' Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0Nl
'' SIG '' ckF1dF8yMDEwLTA2LTIzLmNydDCBnQYDVR0gBIGVMIGS
'' SIG '' MIGPBgkrBgEEAYI3LgMwgYEwPQYIKwYBBQUHAgEWMWh0
'' SIG '' dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9QS0kvZG9jcy9D
'' SIG '' UFMvZGVmYXVsdC5odG0wQAYIKwYBBQUHAgIwNB4yIB0A
'' SIG '' TABlAGcAYQBsAF8AUABvAGwAaQBjAHkAXwBTAHQAYQB0
'' SIG '' AGUAbQBlAG4AdAAuIB0wDQYJKoZIhvcNAQELBQADggIB
'' SIG '' ABp071dPKXvEFoV4uFDTIvwJnayCl/g0/yosl5US5eS/
'' SIG '' z7+TyOM0qduBuNweAL7SNW+v5X95lXflAtTx69jNTh4b
'' SIG '' YaLCWiMa8IyoYlFFZwjjPzwek/gwhRfIOUCm1w6zISnl
'' SIG '' paFpjCKTzHSY56FHQ/JTrMAPMGl//tIlIG1vYdPfB9XZ
'' SIG '' cgAsaYZ2PVHbpjlIyTdhbQfdUxnLp9Zhwr/ig6sP4Gub
'' SIG '' ldZ9KFGwiUpRpJpsyLcfShoOaanX3MF+0Ulwqratu3JH
'' SIG '' Yxf6ptaipobsqBBEm2O2smmJBsdGhnoYP+jFHSHVe/kC
'' SIG '' Iy3FQcu/HUzIFu+xnH/8IktJim4V46Z/dlvRU3mRhZ3V
'' SIG '' 0ts9czXzPK5UslJHasCqE5XSjhHamWdeMoz7N4XR3HWF
'' SIG '' nIfGWleFwr/dDY+Mmy3rtO7PJ9O1Xmn6pBYEAackZ3PP
'' SIG '' TU+23gVWl3r36VJN9HcFT4XG2Avxju1CCdENduMjVngi
'' SIG '' Jja+yrGMbqod5IXaRzNij6TJkTNfcR5Ar5hlySLoQiEl
'' SIG '' ihwtYNk3iUGJKhYP12E8lGhgUu/WR5mggEDuFYF3Ppzg
'' SIG '' UxgaUB04lZseZjMTJzkXeIc2zk7DX7L1PUdTtuDl2wth
'' SIG '' PSrXkizON1o+QEIxpB8QCMJWnL8kXVECnWp50hfT2sGU
'' SIG '' jgd7JXFEqwZq5tTG3yOalnXFMYIaYTCCGl0CAQEwgZUw
'' SIG '' fjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
'' SIG '' b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
'' SIG '' Y3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWlj
'' SIG '' cm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMAITMwAA
'' SIG '' BQAn1jJvQ3N7hwAAAAAFADANBglghkgBZQMEAgEFAKCC
'' SIG '' AQQwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYK
'' SIG '' KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZI
'' SIG '' hvcNAQkEMSIEIMQxWWH3f0SoxzhOQoL/5WBpLL+Mh9+5
'' SIG '' YC4NsiyvzvYfMDwGCisGAQQBgjcKAxwxLgwsc1BZN3hQ
'' SIG '' QjdoVDVnNUhIcll0OHJETFNNOVZ1WlJ1V1phZWYyZTIy
'' SIG '' UnM1ND0wWgYKKwYBBAGCNwIBDDFMMEqgJIAiAE0AaQBj
'' SIG '' AHIAbwBzAG8AZgB0ACAAVwBpAG4AZABvAHcAc6EigCBo
'' SIG '' dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vd2luZG93czAN
'' SIG '' BgkqhkiG9w0BAQEFAASCAQB7K40qwyv1acwIdwe7vW48
'' SIG '' cvIKNSAFN9Zu50CcURSS7Q59zv//M7P50v6KFEKoWQMl
'' SIG '' SKAtLUDxC4fzJ03arHnsgNBTVUBbT2qwhf+Nn+Nym+w6
'' SIG '' Z3meZnrY6YWsQZyddEBtYX/kJNilf88q3/9MRv+NVbDN
'' SIG '' 9xO/gTganl/c9LlpK7j8p+AKFOcU3uYfSTOXOpGhYSw2
'' SIG '' MHbqTN2dVlSBIcxgN+7oUiqPU3OCxR05gPIwa+uVus0k
'' SIG '' /2uh3AOegLDOm1TPdY8Ybd+nXTwE2jtAM0dD8NWMDMco
'' SIG '' 3VuO1A8ylLsqT9F9A8VFyNCKMoCiTRh3Sz397E5JEREg
'' SIG '' B0wqhz1a/IM7oYIXlDCCF5AGCisGAQQBgjcDAwExgheA
'' SIG '' MIIXfAYJKoZIhvcNAQcCoIIXbTCCF2kCAQMxDzANBglg
'' SIG '' hkgBZQMEAgEFADCCAVIGCyqGSIb3DQEJEAEEoIIBQQSC
'' SIG '' AT0wggE5AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZIAWUD
'' SIG '' BAIBBQAEIG1X881NaciK4gEkRJ6FTJPTWIqw55nxwd1i
'' SIG '' JtNLH8xpAgZlC1+OC3kYEzIwMjMwOTMwMDkyMDE3LjM2
'' SIG '' NlowBIACAfSggdGkgc4wgcsxCzAJBgNVBAYTAlVTMRMw
'' SIG '' EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
'' SIG '' b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
'' SIG '' b24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9w
'' SIG '' ZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVT
'' SIG '' TjozMzAzLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9z
'' SIG '' b2Z0IFRpbWUtU3RhbXAgU2VydmljZaCCEeowggcgMIIF
'' SIG '' CKADAgECAhMzAAABzIal3Dfr2WEtAAEAAAHMMA0GCSqG
'' SIG '' SIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
'' SIG '' EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
'' SIG '' HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
'' SIG '' BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAy
'' SIG '' MDEwMB4XDTIzMDUyNTE5MTIwMVoXDTI0MDIwMTE5MTIw
'' SIG '' MVowgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
'' SIG '' aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
'' SIG '' ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsT
'' SIG '' HE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAl
'' SIG '' BgNVBAsTHm5TaGllbGQgVFNTIEVTTjozMzAzLTA1RTAt
'' SIG '' RDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
'' SIG '' bXAgU2VydmljZTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
'' SIG '' ADCCAgoCggIBAMyxIgXx702YRz7zc1VkaBZZmL/AFi3z
'' SIG '' OHEB9IYzvHDsrsJsD/UDgaGi8++Qhjzve2fLN3Jl77pg
'' SIG '' dfH5F3rXyVAOaablfh66Jgbnct3tYgr4N36HKLQf3sPo
'' SIG '' czhnMaqi+bAHR9neWH6mEkug9P73KtMsXOSQrDZVxvvB
'' SIG '' cwHOIPQxVVhubBGVFrKlOe2Xf0gQ0ISKNb2PowSVPJc/
'' SIG '' bOtzQ62FA3lGsxNjmJmNrczIcIWZgwaKeYd+2xobdh2L
'' SIG '' wZrwFCN22hObl1WGeqzaoo0Q6plKifbxHhd9/S2UkvlQ
'' SIG '' fIjdvLAf/7NB4m7yqexIKLxUU86xkRvpxnOFcdoCJIa1
'' SIG '' 0oBtBFoAiETFshSl4nKkLuX7CooLcE70AMa6kH1mBQVt
'' SIG '' K/kQIWMwPNt+bwznPPYDjFg09Bepm/TAZYv6NO9vuQVi
'' SIG '' IM8977NHIFvOatKk5sHteqOrNQU0qXCn4zHXmTUXsUyz
'' SIG '' kQza4brwhCx0AYGRltIOa4aaM9tnt22Kb5ce6Hc1LomZ
'' SIG '' dg9LuuKSkJtSwxkyfl5bGJYUiTp/TSyRHhEtaaHQ3o6r
'' SIG '' 4pgjV8Dn0vMaIBs6tzGC9CRGjc4PijUlb3PVM0zARuTM
'' SIG '' +tcyjyusay4ajJhZyyb3GF3QZchEccLrifNsjd7QbmOo
'' SIG '' SxZBzi5pB5JHKvvQpGKPNXJaONh+wS29UyUnAgMBAAGj
'' SIG '' ggFJMIIBRTAdBgNVHQ4EFgQUgqYcZF08h0tFe2xHldFL
'' SIG '' Izf7aQwwHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacb
'' SIG '' UzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3
'' SIG '' dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9z
'' SIG '' b2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSku
'' SIG '' Y3JsMGwGCCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQ
'' SIG '' aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
'' SIG '' ZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENB
'' SIG '' JTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNV
'' SIG '' HSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMC
'' SIG '' B4AwDQYJKoZIhvcNAQELBQADggIBAHkZQyj1e+JSXeDv
'' SIG '' a7yhBOisgoOgB2BZngtD350ARAKZp62xOGTFs2bXmx67
'' SIG '' sabCll2ExA3xM110aSLmzkh75oDZUSj29nPfWWW6wcFc
'' SIG '' BWtC2m59Cq0gD7aee6x9pi+KK2vqnmRVPrT0shM5iB0p
'' SIG '' FYSl/H/jJPlH3Ix4rGjGSTy3IaIY9krjRJPlnXg490l9
'' SIG '' VuRh4K+UtByWxfX5YFk3H9dm9rMmZeO9iNO4bRBtmnHD
'' SIG '' hk7dmh99BjFlhHOfTPjVTswMWVejaKF9qx1se65rqSkf
'' SIG '' En0AihR6+HebO9TFinS7TPfBgM+ku6j4zZViHxc4JQHS
'' SIG '' 7vnEbdLn73xMqYVupliCmCvo/5gp5qjZikHWLOzznRhL
'' SIG '' O7BpfuRHEBRGWY3+Pke/jBpuc59lvfqYOomngh4abA+3
'' SIG '' Ajy0Q+y5ECbKt56PKGRlXt1+Ang3zdAGGkdVmUHgWaUl
'' SIG '' HzIXdoHXlBbq3DgJof48wgO53oZ44k7hxAT6VNzqsgmY
'' SIG '' 3hx+LZNMbt7j1O+EJd8FLanM7Jv1h6ZKbSSuTyMmHrOB
'' SIG '' 4arO2TvN7B8T7eyFBFzvixctjnym9WjOd+B8a/LWWVur
'' SIG '' g57L3oqi7CK6EO3G4qVOdbunDvFo0+Egyw7Fbx2lKn3X
'' SIG '' kW0p86opH918k6xscNIlj+KInPiZYoAajJ14szrMuaiF
'' SIG '' EI9aT9DmMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJ
'' SIG '' mQAAAAAAFTANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UE
'' SIG '' BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
'' SIG '' BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
'' SIG '' b3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJv
'' SIG '' b3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcN
'' SIG '' MjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8MQsw
'' SIG '' CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
'' SIG '' MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
'' SIG '' b2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3Nv
'' SIG '' ZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZI
'' SIG '' hvcNAQEBBQADggIPADCCAgoCggIBAOThpkzntHIhC3mi
'' SIG '' y9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+
'' SIG '' F2Az/1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQ
'' SIG '' GOhgfWpSg0S3po5GawcU88V29YZQ3MFEyHFcUTE3oAo4
'' SIG '' bo3t1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqYO7oa
'' SIG '' ezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/d
'' SIG '' vI2k45GPsjksUZzpcGkNyjYtcI4xyDUoveO0hyTD4MmP
'' SIG '' frVUj9z6BVWYbWg7mka97aSueik3rMvrg0XnRm7KMtXA
'' SIG '' hjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09
'' SIG '' /SDPc31BmkZ1zcRfNN0Sidb9pSB9fvzZnkXftnIv231f
'' SIG '' gLrbqn427DZM9ituqBJR6L8FA6PRc6ZNN3SUHDSCD/AQ
'' SIG '' 8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxCaC4Q
'' SIG '' 6oRRRuLRvWoYWmEBc8pnol7XKHYC4jMYctenIPDC+hIK
'' SIG '' 12NvDMk2ZItboKaDIV1fMHSRlJTYuVD5C4lh8zYGNRiE
'' SIG '' R9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMURHXLvjflS
'' SIG '' xIUXk8A8FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3
'' SIG '' tz5q4i6tAgMBAAGjggHdMIIB2TASBgkrBgEEAYI3FQEE
'' SIG '' BQIDAQABMCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKR
'' SIG '' PEY1Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXS
'' SIG '' ZacbUzUZ6XIwXAYDVR0gBFUwUzBRBgwrBgEEAYI3TIN9
'' SIG '' AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNy
'' SIG '' b3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnku
'' SIG '' aHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQB
'' SIG '' gjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAP
'' SIG '' BgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP
'' SIG '' 6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJoEeG
'' SIG '' RWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3Js
'' SIG '' L3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIz
'' SIG '' LmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKG
'' SIG '' Pmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2Vy
'' SIG '' dHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0G
'' SIG '' CSqGSIb3DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Ge
'' SIG '' ckv8qW/qXBS2Pk5HZHixBpOXPTEztTnXwnE2P9pkbHzQ
'' SIG '' dTltuw8x5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6c
'' SIG '' qYJWAAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2C
'' SIG '' DPVtI1TkeFN1JFe53Z/zjj3G82jfZfakVqr3lbYoVSfQ
'' SIG '' JL1AoL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz/Aye
'' SIG '' ixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTp
'' SIG '' kbKpW99Jo3QMvOyRgNI95ko+ZjtPu4b6MhrZlvSP9pEB
'' SIG '' 9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdUbZ1jdEgs
'' SIG '' sU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QB
'' SIG '' jloZkWsNn6Qo3GcZKCS6OEuabvshVGtqRRFHqfG3rsjo
'' SIG '' iV5PndLQTHa1V1QJsWkBRH58oWFsc/4Ku+xBZj1p/cvB
'' SIG '' QUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0ViY1w
'' SIG '' /ue10CgaiQuPNtq6TPmb/wrpNPgkNWcr4A245oyZ1uEi
'' SIG '' 6vAnQj0llOZ0dFtq0Z4+7X6gMTN9vMvpe784cETRkPHI
'' SIG '' qzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1VM1izoXBm
'' SIG '' 8qGCA00wggI1AgEBMIH5oYHRpIHOMIHLMQswCQYDVQQG
'' SIG '' EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
'' SIG '' BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
'' SIG '' cnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
'' SIG '' cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxk
'' SIG '' IFRTUyBFU046MzMwMy0wNUUwLUQ5NDcxJTAjBgNVBAMT
'' SIG '' HE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoB
'' SIG '' ATAHBgUrDgMCGgMVAE5O5ne5h+KKFLjNFOjGKwO32Ymk
'' SIG '' oIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
'' SIG '' Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
'' SIG '' BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
'' SIG '' A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
'' SIG '' MTAwDQYJKoZIhvcNAQELBQACBQDowmRDMCIYDzIwMjMw
'' SIG '' OTMwMDkwOTIzWhgPMjAyMzEwMDEwOTA5MjNaMHQwOgYK
'' SIG '' KwYBBAGEWQoEATEsMCowCgIFAOjCZEMCAQAwBwIBAAIC
'' SIG '' IHYwBwIBAAICElQwCgIFAOjDtcMCAQAwNgYKKwYBBAGE
'' SIG '' WQoEAjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAweh
'' SIG '' IKEKMAgCAQACAwGGoDANBgkqhkiG9w0BAQsFAAOCAQEA
'' SIG '' ne9S09fIVN8nKoIScOznQ4B6V+7KRnAZLTL+OyKbwywC
'' SIG '' kQB1VA1S8dAc0jhRtJai3YEyXebKq4SvwMkSBo4u+99r
'' SIG '' az9B+lm9taaytKlCUHnrd6X1O/hoaxaBtyqwfzb8Un4y
'' SIG '' xzWXuUhRSI/tXu6WKW/QSFPq+jGMqAqNgGVZ+IRJUKeN
'' SIG '' 7JToXVuIySUwdV98K00cL2OpgvNIJZPI5zI3BcSvKt02
'' SIG '' OcUPbvptr6VXiAN4wEbqzJ1svm2aRuT899Q1QiU1iCWe
'' SIG '' 1zZzWR2BgeLbZBbdD94ld6EoQCGIW2QIDitlpdtEeITn
'' SIG '' YpoR09vtEYC+Xx3CL6FPo6MsjhpBCqAt9TGCBA0wggQJ
'' SIG '' AgEBMIGTMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
'' SIG '' YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
'' SIG '' VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
'' SIG '' BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
'' SIG '' AhMzAAABzIal3Dfr2WEtAAEAAAHMMA0GCWCGSAFlAwQC
'' SIG '' AQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQ
'' SIG '' AQQwLwYJKoZIhvcNAQkEMSIEIBwdt36s3rjQ9ZnAbnVl
'' SIG '' mN9P6X15254A6h3lakHdW2G8MIH6BgsqhkiG9w0BCRAC
'' SIG '' LzGB6jCB5zCB5DCBvQQg1u5lAcL+wwIT5yApVKTAqkMg
'' SIG '' J+d58VliANsXgetwWOYwgZgwgYCkfjB8MQswCQYDVQQG
'' SIG '' EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
'' SIG '' BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
'' SIG '' cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
'' SIG '' ZS1TdGFtcCBQQ0EgMjAxMAITMwAAAcyGpdw369lhLQAB
'' SIG '' AAABzDAiBCBQ6K8i12VnEIiAgPIstj/XuIzTSGMtgQ5q
'' SIG '' +WpursTouDANBgkqhkiG9w0BAQsFAASCAgCsoYLHN+SG
'' SIG '' p8LpfOU0AhEuXCcZkQfvieiNXip58ITq0ocr+nJS9E4N
'' SIG '' qouVXGq+fupCWHGixGIUPwGX1wZFdMiZ2RUu0FoJ0Rg9
'' SIG '' gMt0gsFi3K+6TOzftDD/PnrXVEt+HXfR9kbryqBOBLBs
'' SIG '' tk+iPJ7ReRaDAKaRWsC3hJvdKjQbLmhTGhdLeaGdczRT
'' SIG '' yk0AjF3RWr7XBRcqOxKzu35DDXYYwBC2/ndlcUqVeYxu
'' SIG '' IeSFzXngUta3TaEFOv5qUtSocj4AQgMvWuPvh0Cu5C/4
'' SIG '' JV9P1vuBC+972LW2A4GLE8H8FnAz9AMybptcWl09Isgy
'' SIG '' V0WiX/GAI6FvVypcCfkd7nGm7epN2Wx/06yih3aE+Z3C
'' SIG '' LT3jS4V3g18XYuxM5OsqUs4qXmpYHh9nhEtsYPNPwjQS
'' SIG '' 4xM6HPdFJarTVGX4ytDKlTa9LdJMdCG5ah2Pb00x4YJu
'' SIG '' RTUEOLN+//81itytM+CBUWtlKLd/u8fYcy5Vqbdvt4fi
'' SIG '' nAbwp/QpCy3Rn0XjtBoKRdnIne9bhoV4FYW9DOV6BDsN
'' SIG '' K8y/YPv11BJ5/td9daBzCk4K1wY6Yl0U8u7oDLVkkdnT
'' SIG '' 9msC2dAMkf/5tFvxoz3yPpSNXgh+fv1kRGOefTQGwmOW
'' SIG '' QLKId/nZoBXULp+QYoV5rul+j5BkKoY/B1K7bhzND/Wh
'' SIG '' z/7+K/GrrOFA6A==
'' SIG '' End signature block
