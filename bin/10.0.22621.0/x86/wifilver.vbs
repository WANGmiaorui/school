' Windows Installer utility to report or update file versions, sizes, languages
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
If (argCount < 1) Then
	Wscript.Echo "Windows Installer utility to updata File table sizes and versions" &_
		vbNewLine & " The 1st argument is the path to MSI database, at the source file root" &_
		vbNewLine & " The 2nd argument can optionally specify separate source location from the MSI" &_
		vbNewLine & " The following options may be specified at any point on the command line" &_
		vbNewLine & "  /U to update the MSI database with the file sizes, versions, and languages" &_
		vbNewLine & "  /H to populate the MsiFileHash table (and create if it doesn't exist)" &_
		vbNewLine & " Notes:" &_
		vbNewLine & "  If source type set to compressed, all files will be opened at the root" &_
		vbNewLine & "  Using CSCRIPT.EXE without the /U option, the file info will be displayed" &_
		vbNewLine & "  Using the /H option requires Windows Installer version 2.0 or greater" &_
		vbNewLine & "  Using the /H option also requires the /U option" &_
		vbNewLine &_
		vbNewLine & "Copyright (C) Microsoft Corporation.  All rights reserved."
	Wscript.Quit 1
End If

' Get argument values, processing any option flags
Dim updateMsi    : updateMsi    = False
Dim populateHash : populateHash = False
Dim sequenceFile : sequenceFile = False
Dim databasePath : databasePath = NextArgument
Dim sourceFolder : sourceFolder = NextArgument
If Not IsEmpty(NextArgument) Then Fail "More than 2 arguments supplied" ' process any trailing options
If Not IsEmpty(sourceFolder) And Right(sourceFolder, 1) <> "\" Then sourceFolder = sourceFolder & "\"
Dim console : If UCase(Mid(Wscript.FullName, Len(Wscript.Path) + 2, 1)) = "C" Then console = True

' Connect to Windows Installer object
On Error Resume Next
Dim installer : Set installer = Nothing
Set installer = Wscript.CreateObject("WindowsInstaller.Installer") : CheckError

Dim errMsg

' Check Installer version to see if MsiFileHash table population is supported
Dim supportHash : supportHash = False
Dim verInstaller : verInstaller = installer.Version
If CInt(Left(verInstaller, 1)) >= 2 Then supportHash = True
If populateHash And NOT supportHash Then
	errMsg = "The version of Windows Installer on the machine does not support populating the MsiFileHash table."
	errMsg = errMsg & " Windows Installer version 2.0 is the mininum required version. The version on the machine is " & verInstaller & vbNewLine
	Fail errMsg
End If

' Check if multiple language package, and force use of primary language
REM	Set sumInfo = database.SummaryInformation(3) : CheckError

' Open database
Dim database, openMode, view, record, updateMode, sumInfo
If updateMsi Then openMode = msiOpenDatabaseModeTransact Else openMode = msiOpenDatabaseModeReadOnly
Set database = installer.OpenDatabase(databasePath, openMode) : CheckError

' Create MsiFileHash table if we will be populating it and it is not already present
Dim hashView, iTableStat, fileHash, hashUpdateRec
iTableStat = Database.TablePersistent("MsiFileHash")
If populateHash Then
	If NOT updateMsi Then
		errMsg = "Populating the MsiFileHash table requires that the database be open for writing. Please include the /U option"
		Fail errMsg		
	End If

	If iTableStat <> 1 Then
		Set hashView = database.OpenView("CREATE TABLE `MsiFileHash` ( `File_` CHAR(72) NOT NULL, `Options` INTEGER NOT NULL, `HashPart1` LONG NOT NULL, `HashPart2` LONG NOT NULL, `HashPart3` LONG NOT NULL, `HashPart4` LONG NOT NULL PRIMARY KEY `File_` )") : CheckError
		hashView.Execute : CheckError
	End If

	Set hashView = database.OpenView("SELECT `File_`, `Options`, `HashPart1`, `HashPart2`, `HashPart3`, `HashPart4` FROM `MsiFileHash`") : CheckError
	hashView.Execute : CheckError

	Set hashUpdateRec = installer.CreateRecord(6)
End If

' Create an install session and execute actions in order to perform directory resolution
installer.UILevel = msiUILevelNone
Dim session : Set session = installer.OpenPackage(database,1) : If Err <> 0 Then Fail "Database: " & databasePath & ". Invalid installer package format"
Dim shortNames : shortNames = session.Mode(msiRunModeSourceShortNames) : CheckError
If Not IsEmpty(sourceFolder) Then session.Property("OriginalDatabase") = sourceFolder : CheckError
Dim stat : stat = session.DoAction("CostInitialize") : CheckError
If stat <> 1 Then Fail "CostInitialize failed, returned " & stat

' Join File table to Component table in order to find directories
Dim orderBy : If sequenceFile Then orderBy = "Directory_" Else orderBy = "Sequence"
Set view = database.OpenView("SELECT File,FileName,Directory_,FileSize,Version,Language FROM File,Component WHERE Component_=Component ORDER BY " & orderBy) : CheckError
view.Execute : CheckError

' Create view on File table to check for companion file version syntax so that we don't overwrite them
Dim companionView
set companionView = database.OpenView("SELECT File FROM File WHERE File=?") : CheckError

' Fetch each file and request the source path, then verify the source path, and get the file info if present
Dim fileKey, fileName, folder, sourcePath, fileSize, version, language, delim, message, info
Do
	Set record = view.Fetch : CheckError
	If record Is Nothing Then Exit Do
	fileKey    = record.StringData(1)
	fileName   = record.StringData(2)
	folder     = record.StringData(3)
REM	fileSize   = record.IntegerData(4)
REM	companion  = record.StringData(5)
	version    = record.StringData(5)
REM	language   = record.StringData(6)

	' Check to see if this is a companion file
	Dim companionRec
	Set companionRec = installer.CreateRecord(1) : CheckError
	companionRec.StringData(1) = version
	companionView.Close : CheckError
	companionView.Execute companionRec : CheckError
	Dim companionFetch
	Set companionFetch = companionView.Fetch : CheckError
	Dim companionFile : companionFile = True
	If companionFetch Is Nothing Then
		companionFile = False
	End If

	delim = InStr(1, fileName, "|", vbTextCompare)
	If delim <> 0 Then
		If shortNames Then fileName = Left(fileName, delim-1) Else fileName = Right(fileName, Len(fileName) - delim)
	End If
	sourcePath = session.SourcePath(folder) & fileName
	If installer.FileAttributes(sourcePath) = -1 Then
		message = message & vbNewLine & sourcePath
	Else
		fileSize = installer.FileSize(sourcePath) : CheckError
		version  = Empty : version  = installer.FileVersion(sourcePath, False) : Err.Clear ' early MSI implementation fails if no version
		language = Empty : language = installer.FileVersion(sourcePath, True)  : Err.Clear ' early MSI implementation doesn't support language
		If language = version Then language = Empty ' Temp check for MSI.DLL version without language support
		If Err <> 0 Then version = Empty : Err.Clear
		If updateMsi Then
			' update File table info
			record.IntegerData(4) = fileSize
			If Len(version)  > 0 Then record.StringData(5) = version
			If Len(language) > 0 Then record.StringData(6) = language
			view.Modify msiViewModifyUpdate, record : CheckError

			' update MsiFileHash table info if this is an unversioned file
			If populateHash And Len(version) = 0 Then
				Set fileHash = installer.FileHash(sourcePath, 0) : CheckError
				hashUpdateRec.StringData(1) = fileKey
				hashUpdateRec.IntegerData(2) = 0
				hashUpdateRec.IntegerData(3) = fileHash.IntegerData(1)
				hashUpdateRec.IntegerData(4) = fileHash.IntegerData(2)
				hashUpdateRec.IntegerData(5) = fileHash.IntegerData(3)
				hashUpdateRec.IntegerData(6) = fileHash.IntegerData(4)
				hashView.Modify msiViewModifyAssign, hashUpdateRec : CheckError
			End If
		ElseIf console Then
			If companionFile Then
				info = "* "
				info = info & fileName : If Len(info) < 12 Then info = info & Space(12 - Len(info))
				info = info & "  skipped (version is a reference to a companion file)"
			Else
				info = fileName : If Len(info) < 12 Then info = info & Space(12 - Len(info))
				info = info & "  size=" & fileSize : If Len(info) < 26 Then info = info & Space(26 - Len(info))
				If Len(version)  > 0 Then info = info & "  vers=" & version : If Len(info) < 45 Then info = info & Space(45 - Len(info))
				If Len(language) > 0 Then info = info & "  lang=" & language
			End If
			Wscript.Echo info
		End If
	End If
Loop
REM Wscript.Echo "SourceDir = " & session.Property("SourceDir")
If Not IsEmpty(message) Then Fail "Error, the following files were not available:" & message

' Update SummaryInformation
If updateMsi Then
	Set sumInfo = database.SummaryInformation(3) : CheckError
	sumInfo.Property(11) = Now
	sumInfo.Property(13) = Now
	sumInfo.Persist
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
			Case "U" : updateMsi    = True
			Case "H" : populateHash = True
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
'' SIG '' MIImcwYJKoZIhvcNAQcCoIImZDCCJmACAQExDzANBglg
'' SIG '' hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
'' SIG '' BgEEAYI3AgEeMCQCAQEEEE7wKRaZJ7VNj+Ws4Q8X66sC
'' SIG '' AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
'' SIG '' 90R1z4uuv6FSmeekmrnJ1Xqp08A0D4fjgi9+4dO31L2g
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
'' SIG '' jgd7JXFEqwZq5tTG3yOalnXFMYIaZDCCGmACAQEwgZUw
'' SIG '' fjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
'' SIG '' b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
'' SIG '' Y3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWlj
'' SIG '' cm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMAITMwAA
'' SIG '' BQAn1jJvQ3N7hwAAAAAFADANBglghkgBZQMEAgEFAKCC
'' SIG '' AQQwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYK
'' SIG '' KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZI
'' SIG '' hvcNAQkEMSIEIGmfNV+gU7H142Wg3iiKcouFLXlxhlbe
'' SIG '' XXkSES4MIO1pMDwGCisGAQQBgjcKAxwxLgwsc1BZN3hQ
'' SIG '' QjdoVDVnNUhIcll0OHJETFNNOVZ1WlJ1V1phZWYyZTIy
'' SIG '' UnM1ND0wWgYKKwYBBAGCNwIBDDFMMEqgJIAiAE0AaQBj
'' SIG '' AHIAbwBzAG8AZgB0ACAAVwBpAG4AZABvAHcAc6EigCBo
'' SIG '' dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vd2luZG93czAN
'' SIG '' BgkqhkiG9w0BAQEFAASCAQA9yxUr8kqYrU0unPoCsu89
'' SIG '' 7tW544+CfC/kgl+SQWq4UhDwx8bU86/Trci+a41IxJNu
'' SIG '' 8SEjymalN3DpiS/xpVt1S3iaLV1y1cnWHoD/+Lv7WSwe
'' SIG '' IhD0njpZEYleiqevyKKqrHsxk5OzxqaQhRxiwX5kCu31
'' SIG '' pYVjG0n6jk3b2w46ZcDsCKTxkG+nDPKeiYdnrMWv5gAC
'' SIG '' TV2vaOHsmvB8EOhzCjd9r+5Rc8f4Shl23DqyTQBiIln0
'' SIG '' KIpzfEWV0S954DUFoJi1kNSLgsNlAy/Qk5oF6z7fRQ1m
'' SIG '' bxNyrhbLWnnNbiAo0xMQvmLE/an7UJ9rjVL/IsLwvnll
'' SIG '' S6HmwNe5XtHcoYIXlzCCF5MGCisGAQQBgjcDAwExgheD
'' SIG '' MIIXfwYJKoZIhvcNAQcCoIIXcDCCF2wCAQMxDzANBglg
'' SIG '' hkgBZQMEAgEFADCCAVIGCyqGSIb3DQEJEAEEoIIBQQSC
'' SIG '' AT0wggE5AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZIAWUD
'' SIG '' BAIBBQAEIEFaE9fgHxaEq3d3jprZy/FqwnialCRuSiuk
'' SIG '' YAXF0kARAgZlBBl5xgUYEzIwMjMwOTMwMTM0ODI0LjE5
'' SIG '' N1owBIACAfSggdGkgc4wgcsxCzAJBgNVBAYTAlVTMRMw
'' SIG '' EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
'' SIG '' b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
'' SIG '' b24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9w
'' SIG '' ZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVT
'' SIG '' Tjo4OTAwLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9z
'' SIG '' b2Z0IFRpbWUtU3RhbXAgU2VydmljZaCCEe0wggcgMIIF
'' SIG '' CKADAgECAhMzAAAB0x0ymhc7QDBzAAEAAAHTMA0GCSqG
'' SIG '' SIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
'' SIG '' EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
'' SIG '' HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
'' SIG '' BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAy
'' SIG '' MDEwMB4XDTIzMDUyNTE5MTIyNFoXDTI0MDIwMTE5MTIy
'' SIG '' NFowgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
'' SIG '' aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
'' SIG '' ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsT
'' SIG '' HE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAl
'' SIG '' BgNVBAsTHm5TaGllbGQgVFNTIEVTTjo4OTAwLTA1RTAt
'' SIG '' RDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
'' SIG '' bXAgU2VydmljZTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
'' SIG '' ADCCAgoCggIBALSOq5M3iDXFuFcJzwxX5067xSpzcptt
'' SIG '' pa2Lm92wBYzUPh9VKL7g1aAa0/8FVFitWPahWeczLR5r
'' SIG '' OJ1A4ni5SxwExs8dozFo2mBtEb0URBEWdwBSm1acj5U+
'' SIG '' Xnc8Pow8vTLPxwcLZkPfB4XjD64wMAacvfoGSbSys41e
'' SIG '' +cz142+cbl2OikSqIeh1ZJq5HJ7i5+0FHaxPAYdWbEq7
'' SIG '' QZLh87zs2BsnhUbMgJHJlfD35G+9cwb+OEzXUfwBYrMq
'' SIG '' mfSgwabUxIx428tRZvfUdJl6TH80ES1e+Z2jvk5XTfQ0
'' SIG '' eAheKHFgR5KBQjF9sjk6aAyr9UMJCnav9/L/k1VrcqMJ
'' SIG '' Cg2qaYQzqisAnZcqNiEQnOinidYJwn3vRTqtekE8rhcY
'' SIG '' 0oEWGEtrvhMz/KxMUisRc4kbV9S5d9x1ZvQTHQUB5NOv
'' SIG '' qCaYKqt4k16M0d98b9UR4Xss29Sq5gVGd2IJSGDLrbit
'' SIG '' bqm1ydBOJF8TRAv+AsXjWQDa9kxjNxzXoSJhdBAFoXdc
'' SIG '' C0x26HV2lepM89AQ7cyzn/kH8q2OFKykxw9S9G9vfkhY
'' SIG '' 36r4v7MTCKmGacIYVO7I4ypzlATSu4Y3czHRW/rH+Fw6
'' SIG '' ZpfGsdAak0ojk+fv1iTz0ByWpTaZcfPVkdan4oFzcPpU
'' SIG '' /svfYmXDGEnHdqxrTznG/Rc8PnwxFbVZoa9pAgMBAAGj
'' SIG '' ggFJMIIBRTAdBgNVHQ4EFgQU0scghrgUAPj3jPfmG/MK
'' SIG '' abTjXmIwHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacb
'' SIG '' UzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3
'' SIG '' dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9z
'' SIG '' b2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSku
'' SIG '' Y3JsMGwGCCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQ
'' SIG '' aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
'' SIG '' ZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENB
'' SIG '' JTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNV
'' SIG '' HSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMC
'' SIG '' B4AwDQYJKoZIhvcNAQELBQADggIBAEBiWFihRD7hppDn
'' SIG '' gwU18ToTLy/ita/4u0NFKMwzZf2Di5qcD1xTtWK12kg9
'' SIG '' X/MTq/gASF79WeDZQBHmqPZJXezP58Oo3pUtZRmwpHRB
'' SIG '' HYlhcqcU9FWPXp7NnI/vN3kfwiy+xwRyid5f5pEcXTEY
'' SIG '' Yzi0MutLzi+PpGbRuChYtdacxNnmQ/ijCcaabQuyYie6
'' SIG '' 7QYqsNmeR5NWZ+TyBNPLx3XLc/YhhzZQjiIlhcK5JooK
'' SIG '' 4V47TCrKxym+EZBKejVcAUrehrJu4PWZKhDFP2rvv4sA
'' SIG '' YZBuJKgaWBONBBrJixBo9wbVDhA3A40aqQBIJlNvMmWe
'' SIG '' aQeCRaUpItO6U5qKVYhjiFLURn7D6xfQEn0twzXjaHnU
'' SIG '' 6Vcsyg8unMcBvrHbaKloAnkp/e7IVo4pbDiGe7TNaz48
'' SIG '' o93X3ad14raiBZ9oV1+cS+RYMMfZ2gv5kDlAF3xeeCz+
'' SIG '' Z3cGueWXYGRn+CJkT98rKiWuJHdpMBYLEUJcoiX8KW7Z
'' SIG '' tueP2p9VgukBVARw9oJ9MB/s5kGVeaW4RO+rVj9I2HEL
'' SIG '' ownVAsKeRdIj/+JdimZEpPvzdApGCaj/jO2Pe4v1nvFt
'' SIG '' sbEhKD4/QdNFfXnLhNF4Fs7ZEU3IKPzyA45GT6zBPWRo
'' SIG '' pdR8YHjOODle6XFJvLe4s3FB5sTpMTdwArT5+djlSkdo
'' SIG '' R2XDh7uKMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJ
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
'' SIG '' 8qGCA1AwggI4AgEBMIH5oYHRpIHOMIHLMQswCQYDVQQG
'' SIG '' EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
'' SIG '' BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
'' SIG '' cnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1l
'' SIG '' cmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxk
'' SIG '' IFRTUyBFU046ODkwMC0wNUUwLUQ5NDcxJTAjBgNVBAMT
'' SIG '' HE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoB
'' SIG '' ATAHBgUrDgMCGgMVAFLHbdwxw0HUhDCz8tiRFdrsjkmw
'' SIG '' oIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
'' SIG '' Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
'' SIG '' BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
'' SIG '' A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
'' SIG '' MTAwDQYJKoZIhvcNAQELBQACBQDowl1zMCIYDzIwMjMw
'' SIG '' OTMwMDg0MDE5WhgPMjAyMzEwMDEwODQwMTlaMHcwPQYK
'' SIG '' KwYBBAGEWQoEATEvMC0wCgIFAOjCXXMCAQAwCgIBAAIC
'' SIG '' EfICAf8wBwIBAAICFRAwCgIFAOjDrvMCAQAwNgYKKwYB
'' SIG '' BAGEWQoEAjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQAC
'' SIG '' AwehIKEKMAgCAQACAwGGoDANBgkqhkiG9w0BAQsFAAOC
'' SIG '' AQEAOYqlDLQ4sfip+OH6JLRJ2XEXra1bo2+9ectxaY/i
'' SIG '' RGDDZqKAl4EwmmIEqbsUdpr2KfPxu3trPXDKf3T4hjVs
'' SIG '' MWrUFDNAoujZ2K9Ljyh9bFjNb4szJo4lrdKxW5Es1bZ5
'' SIG '' ggH+Iw+IfUKeFq5WjwD43phgRDfmHUUXvcWf8wM2ULfW
'' SIG '' KT2kpEowd/PvBut2hjt1dnBtBlVq+Yiw+OEuck5dX0A1
'' SIG '' pZM8V+4sZpJDAEuh0ATrdTOhu8HsYN1c3OUIGvXIYrSu
'' SIG '' iTwCQxN3kJbpU1CUCyx8XSG5N8S8zremwiJWhz7aJMrr
'' SIG '' HRqDyw3yuo2Bf40082zQoJYqxQ3Eb0KDK0B8gTGCBA0w
'' SIG '' ggQJAgEBMIGTMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
'' SIG '' EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
'' SIG '' HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
'' SIG '' BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAy
'' SIG '' MDEwAhMzAAAB0x0ymhc7QDBzAAEAAAHTMA0GCWCGSAFl
'' SIG '' AwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcN
'' SIG '' AQkQAQQwLwYJKoZIhvcNAQkEMSIEILKw15JJRYU5aY7j
'' SIG '' fDDSXi+qU07l3y/PLyAZOT7HVduhMIH6BgsqhkiG9w0B
'' SIG '' CRACLzGB6jCB5zCB5DCBvQQgkmb06sTg7k9YDUpoVrO2
'' SIG '' v24/3qtCASf62Aa1jfE6qvUwgZgwgYCkfjB8MQswCQYD
'' SIG '' VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
'' SIG '' A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
'' SIG '' IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQg
'' SIG '' VGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAdMdMpoXO0Aw
'' SIG '' cwABAAAB0zAiBCB3otzYyMnmh+RbpR6iljn2DeAY1vVj
'' SIG '' bafB0riTgnlq3zANBgkqhkiG9w0BAQsFAASCAgBUHs2D
'' SIG '' 1JEcbOGzBUAAwDkwiH/EHbsvgSBm4fbex3Aklh5rWKjG
'' SIG '' zf8Utzl855bNlhmO6m+JAgywcGy17MNWOSHXvEMAC8wp
'' SIG '' W4KF10Y1UYYOW1o36zHBYQm8zza65XNy0pbgh5ZCWV7Z
'' SIG '' twrRTvne/Ax1n9DeCEORIQpeMI1+ScXRFqBCnWsaiY0/
'' SIG '' KGHhuMre0BMqJY6vpXMiSyZFePUoapzPLaMkfXwDPLZr
'' SIG '' ygb/0noTIAxyh9qZGwc8IIGUBLAmr9yPNpsfjf77t+BO
'' SIG '' AcsvkT4yDl22zOxqcaCPnQrx8rncmHaWQS/ywz9gQYMK
'' SIG '' 2OZO5HIqic5dQ+JB/TxuApGRE7q7i/dE9hnogEw6J3DT
'' SIG '' 4UjZTVp/KfiBTvCYdABdhFAPr7YpOnTGXIh/sv6YDTG2
'' SIG '' iWsV7VYO4GtH9Ndqe+syTZSHkX2F6ckjCjiZ4MO4vsYk
'' SIG '' PI6olwWQ5KHIbxm9D6xQ4doyQv/H6iBvSdBkN8xDz3U6
'' SIG '' 7x9cR2Eu3Lfijm55FzJuoQbBqxNdk0TCu6TQVDtN1SXf
'' SIG '' eIaJmbkTVpmnz9I7uac5sRMapAZocULKT5ORfoBAxcir
'' SIG '' MAuSsuwdluHXyD5f3Z03u78gXihXPQodiXkWaisL4tOC
'' SIG '' Hd9NS6/yp/XghhjtM4N58ecybhtseaFXIGektToO7zJw
'' SIG '' t0CBldPgNY3il4NsMA==
'' SIG '' End signature block
