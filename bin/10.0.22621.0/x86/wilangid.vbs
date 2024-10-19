' Windows Installer utility to report the language and codepage for a package
' For use with Windows Scripting Host, CScript.exe or WScript.exe
' Copyright (c) Microsoft Corporation. All rights reserved.
' Demonstrates the access of language and codepage values                 
'
Option Explicit

Const msiOpenDatabaseModeReadOnly     = 0
Const msiOpenDatabaseModeTransact     = 1
Const ForReading = 1
Const ForWriting = 2
Const TristateFalse = 0

Const msiViewModifyInsert         = 1
Const msiViewModifyUpdate         = 2
Const msiViewModifyAssign         = 3
Const msiViewModifyReplace        = 4
Const msiViewModifyDelete         = 6

Dim argCount:argCount = Wscript.Arguments.Count
If argCount > 0 Then If InStr(1, Wscript.Arguments(0), "?", vbTextCompare) > 0 Then argCount = 0
If (argCount = 0) Then
	message = "Windows Installer utility to manage language and codepage values for a package." &_
		vbNewLine & "The package language is a summary information property that designates the" &_
		vbNewLine & " primary language and any language transforms that are available, comma delim." &_
		vbNewLine & "The ProductLanguage in the database Property table is the language that is" &_
		vbNewLine & " registered for the product and determines the language used to load resources." &_
		vbNewLine & "The codepage is the ANSI codepage of the database strings, 0 if all ASCII data," &_
		vbNewLine & " and must represent the text data to avoid loss when persisting the database." &_
		vbNewLine & "The 1st argument is the path to MSI database (installer package)" &_
		vbNewLine & "To update a value, the 2nd argument contains the keyword and the 3rd the value:" &_
		vbNewLine & "   Package  {base LangId optionally followed by list of language transforms}" &_
		vbNewLine & "   Product  {LangId of the product (could be updated by language transforms)}" &_
		vbNewLine & "   Codepage {ANSI codepage of text data (use with caution when text exists!)}" &_
		vbNewLine &_
		vbNewLine & "Copyright (C) Microsoft Corporation.  All rights reserved."
	Wscript.Echo message
	Wscript.Quit 1
End If

' Connect to Windows Installer object
On Error Resume Next
Dim installer : Set installer = Nothing
Set installer = Wscript.CreateObject("WindowsInstaller.Installer") : CheckError


' Open database
Dim databasePath:databasePath = Wscript.Arguments(0)
Dim openMode : If argCount >= 3 Then openMode = msiOpenDatabaseModeTransact Else openMode = msiOpenDatabaseModeReadOnly
Dim database : Set database = installer.OpenDatabase(databasePath, openMode) : CheckError

' Update value if supplied
If argCount >= 3 Then
	Dim value:value = Wscript.Arguments(2)
	Select Case UCase(Wscript.Arguments(1))
		Case "PACKAGE"  : SetPackageLanguage database, value
		Case "PRODUCT"  : SetProductLanguage database, value
		Case "CODEPAGE" : SetDatabaseCodepage database, value
		Case Else       : Fail "Invalid value keyword"
	End Select
	CheckError
End If

' Extract language info and compose report message
Dim message:message = "Package language = "         & PackageLanguage(database) &_
					", ProductLanguage = " & ProductLanguage(database) &_
					", Database codepage = "        & DatabaseCodepage(database)
database.Commit : CheckError  ' no effect if opened ReadOnly
Set database = nothing
Wscript.Echo message
Wscript.Quit 0

' Get language list from summary information
Function PackageLanguage(database)
	On Error Resume Next
	Dim sumInfo  : Set sumInfo = database.SummaryInformation(0) : CheckError
	Dim template : template = sumInfo.Property(7) : CheckError
	Dim iDelim:iDelim = InStr(1, template, ";", vbTextCompare)
	If iDelim = 0 Then template = "Not specified!"
	PackageLanguage = Right(template, Len(template) - iDelim)
	If Len(PackageLanguage) = 0 Then PackageLanguage = "0"
End Function

' Get ProductLanguge property from Property table
Function ProductLanguage(database)
	On Error Resume Next
	Dim view : Set view = database.OpenView("SELECT `Value` FROM `Property` WHERE `Property` = 'ProductLanguage'")
	view.Execute : CheckError
	Dim record : Set record = view.Fetch : CheckError
	If record Is Nothing Then ProductLanguage = "Not specified!" Else ProductLanguage = record.IntegerData(1)
End Function

' Get ANSI codepage of database text data
Function DatabaseCodepage(database)
	On Error Resume Next
	Dim WshShell : Set WshShell = Wscript.CreateObject("Wscript.Shell") : CheckError
	Dim tempPath:tempPath = WshShell.ExpandEnvironmentStrings("%TEMP%") : CheckError
	database.Export "_ForceCodepage", tempPath, "codepage.idt" : CheckError
	Dim fileSys : Set fileSys = CreateObject("Scripting.FileSystemObject") : CheckError
	Dim file : Set file = fileSys.OpenTextFile(tempPath & "\codepage.idt", ForReading, False, TristateFalse) : CheckError
	file.ReadLine ' skip column name record
	file.ReadLine ' skip column defn record
	DatabaseCodepage = file.ReadLine
	file.Close
	Dim iDelim:iDelim = InStr(1, DatabaseCodepage, vbTab, vbTextCompare)
	If iDelim = 0 Then Fail "Failure in codepage export file"
	DatabaseCodepage = Left(DatabaseCodepage, iDelim - 1)
	fileSys.DeleteFile(tempPath & "\codepage.idt")
End Function

' Set ProductLanguge property in Property table
Sub SetProductLanguage(database, language)
	On Error Resume Next
	If Not IsNumeric(language) Then Fail "ProductLanguage must be numeric"
	Dim view : Set view = database.OpenView("SELECT `Property`,`Value` FROM `Property`")
	view.Execute : CheckError
	Dim record : Set record = installer.CreateRecord(2)
	record.StringData(1) = "ProductLanguage"
	record.StringData(2) = CStr(language)
	view.Modify msiViewModifyAssign, record : CheckError
End Sub

' Set ANSI codepage of database text data
Sub SetDatabaseCodepage(database, codepage)
	On Error Resume Next
	If Not IsNumeric(codepage) Then Fail "Codepage must be numeric"
	Dim WshShell : Set WshShell = Wscript.CreateObject("Wscript.Shell") : CheckError
	Dim tempPath:tempPath = WshShell.ExpandEnvironmentStrings("%TEMP%") : CheckError
	Dim fileSys : Set fileSys = CreateObject("Scripting.FileSystemObject") : CheckError
	Dim file : Set file = fileSys.OpenTextFile(tempPath & "\codepage.idt", ForWriting, True, TristateFalse) : CheckError
	file.WriteLine ' dummy column name record
	file.WriteLine ' dummy column defn record
	file.WriteLine codepage & vbTab & "_ForceCodepage"
	file.Close : CheckError
	database.Import tempPath, "codepage.idt" : CheckError
	fileSys.DeleteFile(tempPath & "\codepage.idt")
End Sub     

' Set language list in summary information
Sub SetPackageLanguage(database, language)
	On Error Resume Next
	Dim sumInfo  : Set sumInfo = database.SummaryInformation(1) : CheckError
	Dim template : template = sumInfo.Property(7) : CheckError
	Dim iDelim:iDelim = InStr(1, template, ";", vbTextCompare)
	Dim platform : If iDelim = 0 Then platform = ";" Else platform = Left(template, iDelim)
	sumInfo.Property(7) = platform & language
	sumInfo.Persist : CheckError
End Sub

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
'' SIG '' P5ZR+tRLXw+tvFB7cXDc0jFoO6HhZPDQciZh+dfNY5qg
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
'' SIG '' hvcNAQkEMSIEIACfHEUjpbb6OMsQM89w72uZFdkYNMUa
'' SIG '' oednrszUaXmzMDwGCisGAQQBgjcKAxwxLgwsc1BZN3hQ
'' SIG '' QjdoVDVnNUhIcll0OHJETFNNOVZ1WlJ1V1phZWYyZTIy
'' SIG '' UnM1ND0wWgYKKwYBBAGCNwIBDDFMMEqgJIAiAE0AaQBj
'' SIG '' AHIAbwBzAG8AZgB0ACAAVwBpAG4AZABvAHcAc6EigCBo
'' SIG '' dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vd2luZG93czAN
'' SIG '' BgkqhkiG9w0BAQEFAASCAQBUK6E2EOfyERHUsk1SGcvH
'' SIG '' w9yTmi8YuxPICjjKnpF/aPhzkQEkDwzSDb4VZ2cDJzL3
'' SIG '' +x5zh4CKx+JpoDQ+UVIoGPUQMp4/IPbK4QEnMzi1g+kX
'' SIG '' aok/YQ6AbL33/EIdZF2lvlAoTvIXltoDrzexoJJSeo5L
'' SIG '' 7WA+ZQdCy0fiBoXo8ui0v/4/gx6MkpWN6BItrp3TIazY
'' SIG '' 2/eXNvJhSQ79WJntUCNquF9+QO/IDC+GU17CPye4XZxS
'' SIG '' GtA/maQ100B+ri1YRBj/Bojsq+3CS4FcRZ6gxcejSJLn
'' SIG '' j/ib2iWkT+OsvvBDjKO8lng56yaqFtS0L7WBYjrtCM64
'' SIG '' H/Brbc8IR+cjoYIXlDCCF5AGCisGAQQBgjcDAwExgheA
'' SIG '' MIIXfAYJKoZIhvcNAQcCoIIXbTCCF2kCAQMxDzANBglg
'' SIG '' hkgBZQMEAgEFADCCAVIGCyqGSIb3DQEJEAEEoIIBQQSC
'' SIG '' AT0wggE5AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZIAWUD
'' SIG '' BAIBBQAEILtTERItCwYeD7bybxf6fyvZF82Y+XWAehe0
'' SIG '' YGjoKeG9AgZlA/5Hj9IYEzIwMjMwOTMwMTM0ODI3Ljg3
'' SIG '' OFowBIACAfSggdGkgc4wgcsxCzAJBgNVBAYTAlVTMRMw
'' SIG '' EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
'' SIG '' b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
'' SIG '' b24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9w
'' SIG '' ZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVT
'' SIG '' Tjo4NjAzLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9z
'' SIG '' b2Z0IFRpbWUtU3RhbXAgU2VydmljZaCCEeowggcgMIIF
'' SIG '' CKADAgECAhMzAAAB15sNHlcujFGOAAEAAAHXMA0GCSqG
'' SIG '' SIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
'' SIG '' EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
'' SIG '' HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
'' SIG '' BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAy
'' SIG '' MDEwMB4XDTIzMDUyNTE5MTIzN1oXDTI0MDIwMTE5MTIz
'' SIG '' N1owgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
'' SIG '' aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
'' SIG '' ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsT
'' SIG '' HE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAl
'' SIG '' BgNVBAsTHm5TaGllbGQgVFNTIEVTTjo4NjAzLTA1RTAt
'' SIG '' RDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
'' SIG '' bXAgU2VydmljZTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
'' SIG '' ADCCAgoCggIBAMSsYKQ3Zf9S+40Jx+XTJUE2j4sgjLMb
'' SIG '' sDXRfmRWAaen2zyZ/hpmy6Rm7mu8uzs2po0TFzCc+4ch
'' SIG '' Z2nqSzCNrVjD1LFNf4TSV6r5YG5whEpZ1wy6YgMGAsTQ
'' SIG '' Rv/f8Fj3lm1PVeyedq0EVmGvS4uQOJP0eCtFvXbaybv9
'' SIG '' iTIyKAWRPQm6iJI9egsvvBpQT214j1A6SiOqNGVwgLhh
'' SIG '' U1j7ZQgEzlCiso1o53P+yj5MgXqbPFfmfLZT+j+IwVVN
'' SIG '' +/CbhPyD9irHDJ76U6Zr0or3y/q/B7+KLvZMxNVbApcV
'' SIG '' 1c7Kw/0aKhxe3fxy4/1zxoTV4fergV0ZOAo53Ssb7GEK
'' SIG '' CxEXwaotPuTnxWlCcny77KNFbouia3lFyuimB/0Qfx7h
'' SIG '' +gNShTJTlDuI+DA4nFiGgrFGMZmW2EOanl7H7pTrO/3m
'' SIG '' t33vfrrykakKS7QgHjcv8FPMxwMBXj/G7pF9xUXBqs3/
'' SIG '' Imrmp9nIyykfmBxpMJUCi5eRBNzwvC1/G2AjPneoxJVH
'' SIG '' 1z2CRKfEzlzW0eCIxfcPYYGdBqf3m3L4J1NgACGOAFNz
'' SIG '' KP0/s4YQyGveXJpnGOveCmzpmajjtU5Mjy2xJgeEe0Pw
'' SIG '' GkGiDf0vl7j+UMmD86risawUpLExe4hFnUTTx2Zfrtcz
'' SIG '' uqa+bbs7zTgKESZv4I5HxZvjowUQTPraO77FAgMBAAGj
'' SIG '' ggFJMIIBRTAdBgNVHQ4EFgQUrqfAu/1ZAvc0jEQnI+4k
'' SIG '' xnowjY0wHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacb
'' SIG '' UzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3
'' SIG '' dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9z
'' SIG '' b2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSku
'' SIG '' Y3JsMGwGCCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQ
'' SIG '' aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
'' SIG '' ZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENB
'' SIG '' JTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNV
'' SIG '' HSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMC
'' SIG '' B4AwDQYJKoZIhvcNAQELBQADggIBAFIF3dQn4iy90wJf
'' SIG '' 4rvGodrlQG1ULUJpdm8dF36y1bSVcD91M2d4JbRMWsGg
'' SIG '' ljn1v1+dtOi49F5qS7aXdfluaGxqjoMJFW6pyaFU8BnJ
'' SIG '' JcZ6hV+PnZwsaLJksTDpNDO7oP76+M04aZKJs7QoT0Z2
'' SIG '' /yFARHHlEbQqCtOaTxyR4LVVSq55RAcpUIRKpMNQMPx1
'' SIG '' dMtYKaboeqZBfr/6AoNJeCDClzvmGLYBspKji26UzBN9
'' SIG '' cl0Z3CuyIeOTPyfMhb9nc+cyAYVTvoq7NgVXRfIf0NNL
'' SIG '' 8M87zpEu1CMDlmVUbKZM99OfDuTGiIsk3/KW4wciQdLO
'' SIG '' lom8KKpf4OfVAZEQSc0hl5F6S8ui6uo9EQg5ObVslEnT
'' SIG '' rlz1hftsnSdo+LHObnLxjYH5gggQCLiNSto6HegTtrgm
'' SIG '' 8hbcSDeg2o/uqGl3vEwvGrZacz5T1upZN5PhUKikCFe7
'' SIG '' a4ZB7F0urttZ1xjDIQUOFLhn03S7DeHpuMHtLgxf3ql9
'' SIG '' hIRXQwoUY4puZ8JRLtZ6aS4WpnLSg0c8/H5x901h5IXp
'' SIG '' uE48d2yujURV3fNYiR0PUbmQQM+cRC0Vqu0zwf5u/nNS
'' SIG '' EBQmzyovO4UB0FlAu54P1dl7KeNArAR4DPrfEBMgKHy0
'' SIG '' 5QzbMyBISFUvwebjlIHp+h6zgFMLRjxJlai/chqG2/DI
'' SIG '' cVtSqzViMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJ
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
'' SIG '' IFRTUyBFU046ODYwMy0wNUUwLUQ5NDcxJTAjBgNVBAMT
'' SIG '' HE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoB
'' SIG '' ATAHBgUrDgMCGgMVADFb26LMbeERjz24va675f6Yb+t1
'' SIG '' oIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
'' SIG '' Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
'' SIG '' BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
'' SIG '' A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
'' SIG '' MTAwDQYJKoZIhvcNAQELBQACBQDowkFIMCIYDzIwMjMw
'' SIG '' OTMwMDY0MDA4WhgPMjAyMzEwMDEwNjQwMDhaMHQwOgYK
'' SIG '' KwYBBAGEWQoEATEsMCowCgIFAOjCQUgCAQAwBwIBAAIC
'' SIG '' C+gwBwIBAAICEzwwCgIFAOjDksgCAQAwNgYKKwYBBAGE
'' SIG '' WQoEAjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAweh
'' SIG '' IKEKMAgCAQACAwGGoDANBgkqhkiG9w0BAQsFAAOCAQEA
'' SIG '' AKYM236G+GeCzWicuDWHOgDzyWTeiU2WA2uruJ6MO+zg
'' SIG '' bZi0Tj79H5mbNqKI39ZvBGMr+XaqQIVE8CNhbe5MH/On
'' SIG '' hsdkVvvcUyvqNnH3aOUDWZ44ZH7OVNZD3IgBgAhxXq/R
'' SIG '' BEtU7gBOFt8+6/b7o2VKQkV4yCpYNrJkyMabfNHTGSDj
'' SIG '' MdkGETtoBE8OADxtYtX+QKIp/VS4vTOi7qJ29EQ99pSx
'' SIG '' QHmZjxhkjJnTmCitQC/aXDztw6qGjjE4A1gA2orPaP+F
'' SIG '' seZG7V3PweYMy9+glg8NT8Xjq9/tYePF8KUNj+7ac4UD
'' SIG '' A13OmnqWEMcEGZYtdhB0l0Zof75aUBSmETGCBA0wggQJ
'' SIG '' AgEBMIGTMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
'' SIG '' YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
'' SIG '' VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
'' SIG '' BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
'' SIG '' AhMzAAAB15sNHlcujFGOAAEAAAHXMA0GCWCGSAFlAwQC
'' SIG '' AQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQ
'' SIG '' AQQwLwYJKoZIhvcNAQkEMSIEIGVdUmVt4ApXy3rZZJ2/
'' SIG '' TeV7GfYHM3IPALaR8Vb2DUHBMIH6BgsqhkiG9w0BCRAC
'' SIG '' LzGB6jCB5zCB5DCBvQQgnN4+XktefU+Ko2PHxg3tM3Vk
'' SIG '' jR3Vlf/bNF2cj3usmjswgZgwgYCkfjB8MQswCQYDVQQG
'' SIG '' EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
'' SIG '' BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
'' SIG '' cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
'' SIG '' ZS1TdGFtcCBQQ0EgMjAxMAITMwAAAdebDR5XLoxRjgAB
'' SIG '' AAAB1zAiBCACzJHJ10OExys9ZTXQAX88pYzF+30bThQt
'' SIG '' qHiD8LX8nTANBgkqhkiG9w0BAQsFAASCAgCjvt6qCUAT
'' SIG '' kttrHPs/4hfMla35ZIhkbyMZlwKf74rRtU3YGoJuNhYx
'' SIG '' u6lQKFkB3XdMDQuKTpexZv0JnlEmT4PZel85iBbdKYaA
'' SIG '' EY5YMr1Bqi9GpeYBT4HonVciHEeRCc5ryWaWKj0h2Vol
'' SIG '' i29YO24VuIkO/bxYcuQ2BIhBI+gv47ugeLJ79LES7Bej
'' SIG '' KTeg9XI7UPcv+N/iaumnvh+d53xpUrwNA2vCqGn32x/+
'' SIG '' krAl5CIW9GqdOtx91305rTXtywcoKuDFFRezYRunIjIm
'' SIG '' Z7utyeCy9dNHqBxG4oRIrxioUFQQM62xFAkxOisiDVCN
'' SIG '' iD/Xj2G6oRBxdkovOCv0DN+4i11Mi0UBoPtb0hGH1BG9
'' SIG '' tAd+mHHojA4xylPRecePaHfeeIQ7k3x+1+J9iaI5SRe0
'' SIG '' AFMhpJI1DPighAH/FfQV1TqspPoI1UY0IW+0EedzMsPR
'' SIG '' CNqdQEIrYyiYzqbkbQ2JdrmtZcaTS7XIz7lsu/JnwZ7P
'' SIG '' gydn8vPKFtPP+s99/3DXCCNtZKEQ98wv54vebw7kQhBk
'' SIG '' 7naq7XD4K3DsOm1VIrBkoyFtN0PByOdKPtOhDhIBxemY
'' SIG '' umLYzPe8iaDum8VaWPQW0l4mlsUrrF02DDD2KqYo1TmD
'' SIG '' dTLVwpwTc1+bnbVvN+9x4A7NJBLCvLehNICQ8u+gKcVe
'' SIG '' j3+2Cvw6MkW7Eg==
'' SIG '' End signature block
