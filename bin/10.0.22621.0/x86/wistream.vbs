' Windows Installer utility to manage binary streams in an installer package
' For use with Windows Scripting Host, CScript.exe or WScript.exe
' Copyright (c) Microsoft Corporation. All rights reserved.
' Demonstrates the use of the database _Streams table
' Used for entering non-database binary streams such as compressed file cabinets
' Streams that persist database binary values should be managed with table views
' Streams that persist database tables and system data are invisible in _Streams
'
Option Explicit

Const msiOpenDatabaseModeReadOnly     = 0
Const msiOpenDatabaseModeTransact     = 1
Const msiOpenDatabaseModeCreate       = 3

Const msiViewModifyInsert         = 1
Const msiViewModifyUpdate         = 2
Const msiViewModifyAssign         = 3
Const msiViewModifyReplace        = 4
Const msiViewModifyDelete         = 6

Const ForAppending = 8
Const ForReading = 1
Const ForWriting = 2
Const TristateTrue = -1

' Check arg count, and display help if argument not present or contains ?
Dim argCount:argCount = Wscript.Arguments.Count
If argCount > 0 Then If InStr(1, Wscript.Arguments(0), "?", vbTextCompare) > 0 Then argCount = 0
If (argCount = 0) Then
	Wscript.Echo "Windows Installer database stream import utility" &_
		vbNewLine & " 1st argument is the path to MSI database (installer package)" &_
		vbNewLine & " 2nd argument is the path to a file containing the stream data" &_
		vbNewLine & " If the 2nd argument is missing, streams will be listed" &_
		vbNewLine & " 3rd argument is optional, the name used for the stream" &_
		vbNewLine & " If the 3rd arugment is missing, the file name is used" &_
		vbNewLine & " To remove a stream, use /D or -D as the 2nd argument" &_
		vbNewLine & " followed by the name of the stream in the 3rd argument" &_
		vbNewLine &_
		vbNewLine & "Copyright (C) Microsoft Corporation.  All rights reserved."
	Wscript.Quit 1
End If

' Connect to Windows Installer object
On Error Resume Next
Dim installer : Set installer = Nothing
Set installer = Wscript.CreateObject("WindowsInstaller.Installer") : CheckError

' Evaluate command-line arguments and set open and update modes
Dim databasePath:databasePath = Wscript.Arguments(0)
Dim openMode    : If argCount = 1 Then openMode = msiOpenDatabaseModeReadOnly Else openMode = msiOpenDatabaseModeTransact
Dim updateMode  : If argCount > 1 Then updateMode = msiViewModifyAssign  'Either insert or replace existing row
Dim importPath  : If argCount > 1 Then importPath = Wscript.Arguments(1)
Dim streamName  : If argCount > 2 Then streamName = Wscript.Arguments(2)
If streamName = Empty And importPath <> Empty Then streamName = Right(importPath, Len(importPath) - InStrRev(importPath, "\",-1,vbTextCompare))
If UCase(importPath) = "/D" Or UCase(importPath) = "-D" Then updateMode = msiViewModifyDelete : importPath = Empty 'Stream will be deleted if no input data

' Open database and create a view on the _Streams table
Dim sqlQuery : Select Case updateMode
	Case msiOpenDatabaseModeReadOnly: sqlQuery = "SELECT `Name` FROM _Streams"
	Case msiViewModifyAssign:         sqlQuery = "SELECT `Name`,`Data` FROM _Streams"
	Case msiViewModifyDelete:         sqlQuery = "SELECT `Name` FROM _Streams WHERE `Name` = ?"
End Select
Dim database : Set database = installer.OpenDatabase(databasePath, openMode) : CheckError
Dim view     : Set view = database.OpenView(sqlQuery)
Dim record

If openMode = msiOpenDatabaseModeReadOnly Then 'If listing streams, simply fetch all records
	Dim message, name
	view.Execute : CheckError
	Do
		Set record = view.Fetch
		If record Is Nothing Then Exit Do
		name = record.StringData(1)
		If message = Empty Then message = name Else message = message & vbNewLine & name
	Loop
	Wscript.Echo message
Else 'If adding a stream, insert a row, else if removing a stream, delete the row
	Set record = installer.CreateRecord(2)
	record.StringData(1) = streamName
	view.Execute record : CheckError
	If importPath <> Empty Then  'Insert stream - copy data into stream
		record.SetStream 2, importPath : CheckError
	Else  'Delete stream, fetch first to provide better error message if missing
		Set record = view.Fetch
		If record Is Nothing Then Wscript.Echo "Stream not present:", streamName : Wscript.Quit 2
	End If
	view.Modify updateMode, record : CheckError
	database.Commit : CheckError
	Set view = Nothing
	Set database = Nothing
	CheckError
End If

Sub CheckError
	Dim message, errRec
	If Err = 0 Then Exit Sub
	message = Err.Source & " " & Hex(Err) & ": " & Err.Description
	If Not installer Is Nothing Then
		Set errRec = installer.LastErrorRecord
		If Not errRec Is Nothing Then message = message & vbNewLine & errRec.FormatText
	End If
	Wscript.Echo message
	Wscript.Quit 2
End Sub

'' SIG '' Begin signature block
'' SIG '' MIImcAYJKoZIhvcNAQcCoIImYTCCJl0CAQExDzANBglg
'' SIG '' hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
'' SIG '' BgEEAYI3AgEeMCQCAQEEEE7wKRaZJ7VNj+Ws4Q8X66sC
'' SIG '' AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
'' SIG '' cI6yPc6nU50pwvCvjhpQqcdV9XZAulr8Q0FGvLPiuv6g
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
'' SIG '' hvcNAQkEMSIEIEKJMAvhxt/02eIG0Jxb+HAQevhZJyCx
'' SIG '' dWuB3JraIrIwMDwGCisGAQQBgjcKAxwxLgwsc1BZN3hQ
'' SIG '' QjdoVDVnNUhIcll0OHJETFNNOVZ1WlJ1V1phZWYyZTIy
'' SIG '' UnM1ND0wWgYKKwYBBAGCNwIBDDFMMEqgJIAiAE0AaQBj
'' SIG '' AHIAbwBzAG8AZgB0ACAAVwBpAG4AZABvAHcAc6EigCBo
'' SIG '' dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vd2luZG93czAN
'' SIG '' BgkqhkiG9w0BAQEFAASCAQASPYQvjhDee+cvrI1fQ4Zm
'' SIG '' bpjleHFNPUFW4vi6bIxvihGjyNvKUurXU/X/fxPZq0Qh
'' SIG '' ywOQGauk4E3CcHlImA34UGqathErxIUavn+3e476ueQ7
'' SIG '' saLoYkKKKpNLdYQwAph6/2aLKvLQKTWzqbi0vtDv4afh
'' SIG '' tSyhzCmjmBCANDI5SYJEmgCjtvljpoam3hVwjjJ1s8de
'' SIG '' dK+azk5jMI9Sdn+YzT2gzbGmaNAKgKQiIB1P9mJKM1e2
'' SIG '' ZOsj1WLJiRmbQ3r3/RON+RTe3+aeoXiD8NcKyXd+BPBB
'' SIG '' elQRsKMbR5YKSpzhrgtbj0cL9TnjEj/T22PnfIAJNQYf
'' SIG '' psSQUCB3kc92oYIXlDCCF5AGCisGAQQBgjcDAwExgheA
'' SIG '' MIIXfAYJKoZIhvcNAQcCoIIXbTCCF2kCAQMxDzANBglg
'' SIG '' hkgBZQMEAgEFADCCAVIGCyqGSIb3DQEJEAEEoIIBQQSC
'' SIG '' AT0wggE5AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZIAWUD
'' SIG '' BAIBBQAEICyOvtU/4G6Qkj0jJ4j7uwLOEnLHmb9f4FlN
'' SIG '' GbD3Yr2pAgZlBDRxaVQYEzIwMjMwOTMwMTM0ODM1LjQw
'' SIG '' N1owBIACAfSggdGkgc4wgcsxCzAJBgNVBAYTAlVTMRMw
'' SIG '' EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
'' SIG '' b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
'' SIG '' b24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9w
'' SIG '' ZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVT
'' SIG '' TjpGMDAyLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9z
'' SIG '' b2Z0IFRpbWUtU3RhbXAgU2VydmljZaCCEeowggcgMIIF
'' SIG '' CKADAgECAhMzAAABzg8Y90WX58b/AAEAAAHOMA0GCSqG
'' SIG '' SIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
'' SIG '' EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
'' SIG '' HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
'' SIG '' BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAy
'' SIG '' MDEwMB4XDTIzMDUyNTE5MTIwOFoXDTI0MDIwMTE5MTIw
'' SIG '' OFowgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
'' SIG '' aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
'' SIG '' ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsT
'' SIG '' HE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAl
'' SIG '' BgNVBAsTHm5TaGllbGQgVFNTIEVTTjpGMDAyLTA1RTAt
'' SIG '' RDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
'' SIG '' bXAgU2VydmljZTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
'' SIG '' ADCCAgoCggIBALkKTBnXKNjHd+cpPD9WfPAYaEo4iOow
'' SIG '' NK4d0aDwmgnYs3acFRSQDDGFgBHhlBaD1BuPFn8NasPb
'' SIG '' F5TAuco4o0M22Ff29oqP5fkK3GLqKhNVTtQHmhDjAamR
'' SIG '' XaSZ+enRFgZ2G1znwBqhRkVy+F0GUnbIRPC4K4RXqmTg
'' SIG '' nuCEbKazOvQdWpH0HYwmNXyt48v4cYjMhtguuTSNaZop
'' SIG '' FE+wV/EorDeeMWAWVKpoEDhJW5XQVgT/i3Rn1SNdQ8ur
'' SIG '' D6IN4tS/eyneH0zig0hnbXpU+VWV/cU4VEuVmDx4J5fj
'' SIG '' GVoGNaJr3mdeVcxdBapojCSA3hOxHPKaB5a5XMylE8Fa
'' SIG '' TqA6PPHBeeMhxarHWU/OchK//G2fUekH4IgXlI8qQJ/y
'' SIG '' UI+JnUS0HTUXMdGP5iFFYmOxGXWAtbWLQQuutZUAWsM+
'' SIG '' siyEEqjPpJQDIoPvI/Hrj1LIsYGj+8kfFmAyViKtyR/1
'' SIG '' 6SWms0N6iyWGt4hjMAmswn5ihaf0PGaD/uEYL9cfx6WO
'' SIG '' YmoEurIcKZ2BL5YCuPzhyJEayapFpQH/iEUZSQu/UZra
'' SIG '' 8Q+1UHJSaMdwCmklHU86aLUBNX0W6w5BDGQPaddZIpZ8
'' SIG '' oCkPu0Z81kxG+S58cXAZ/k2c3QCKbSWMGDU7mCzjcWiT
'' SIG '' +5J7XbNAvSFI/0l/6IIv409M8A8k8Sxt1hq9AgMBAAGj
'' SIG '' ggFJMIIBRTAdBgNVHQ4EFgQUMPsIRkCjkwyOmX4VZOxT
'' SIG '' KfnihcUwHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacb
'' SIG '' UzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3
'' SIG '' dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9z
'' SIG '' b2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSku
'' SIG '' Y3JsMGwGCCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQ
'' SIG '' aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
'' SIG '' ZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENB
'' SIG '' JTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNV
'' SIG '' HSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMC
'' SIG '' B4AwDQYJKoZIhvcNAQELBQADggIBAJcgFhb/RRVMMNk7
'' SIG '' 99DZey00LgNkbxE9uuVkfIW3nvP9Vao+63qu6BrIZbVR
'' SIG '' y8m7F/xES2JO2Z/lJDk3am7SdOXo7gG1Jwi8z8ryl7/K
'' SIG '' PvvHy7q9+TxDpIM5mgWkilWQUffLruKx/j9J+g30zact
'' SIG '' v3emj862Uz0BxZMluq6fML6SZ4tzEmYLEtyyIEwnplO9
'' SIG '' I1ZCeJyAy6/s8XSKn0diPMVag2ryqeuzuD75gY9dTt6m
'' SIG '' XUpIFOv1RHsef+Q1yoKJl/bYOGhk9U/v69kdNj45ejGg
'' SIG '' QQ6fMBsCUEK6n/Btc0mKyyIrxnJEldP9HgVWYTbYJK+m
'' SIG '' 76nkx5GUFPjamQiGEyWpeWx1B1P1xYi2JbzJZGloTVkj
'' SIG '' WbL0Vbwkz0O0JC2Ldm4YdI2m+bhABj/rWvKsqiXhEt/k
'' SIG '' X5ICXijNW8zw8ox5F0SajbA7NkrgwTsPuIfMtxinm5zD
'' SIG '' SSCzLf3p9pzOxd2ctKiZcwCuy0aQe+38XeGrZ4RJDY+C
'' SIG '' tf6Cl0Gjy49XXrLCaekDBiox1kz7IfoH//gyxcS7dGDl
'' SIG '' A6g5Z2M1UHtCbow8mD68Nfn1e8yaJsDNumXEjKntLWTL
'' SIG '' sv6DeGrorGUpD1ptSNilo4Wce0oMUn6/HOdwQxURXcgd
'' SIG '' B2MLu6uo4GA7u/Kl4jCNDrz2q7Y024hDpxlmAyfwS9JJ
'' SIG '' ZHAMbyCJMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJ
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
'' SIG '' IFRTUyBFU046RjAwMi0wNUUwLUQ5NDcxJTAjBgNVBAMT
'' SIG '' HE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoB
'' SIG '' ATAHBgUrDgMCGgMVAF2NlRsU0DIKRUToN1VbKLNNhAfM
'' SIG '' oIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
'' SIG '' Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
'' SIG '' BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
'' SIG '' A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
'' SIG '' MTAwDQYJKoZIhvcNAQELBQACBQDownjnMCIYDzIwMjMw
'' SIG '' OTMwMTAzNzI3WhgPMjAyMzEwMDExMDM3MjdaMHQwOgYK
'' SIG '' KwYBBAGEWQoEATEsMCowCgIFAOjCeOcCAQAwBwIBAAIC
'' SIG '' PbgwBwIBAAICEsIwCgIFAOjDymcCAQAwNgYKKwYBBAGE
'' SIG '' WQoEAjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAweh
'' SIG '' IKEKMAgCAQACAwGGoDANBgkqhkiG9w0BAQsFAAOCAQEA
'' SIG '' wcDPV3j+z0xzVXXchkcdjUT/Zwk/Fp07IAS9k1riTpNA
'' SIG '' rqpLAO2S1mJuIVKvN4gD0XHn4j6wKu3mqheUD4nhV+v5
'' SIG '' OhGgs8oz1V7PFkEhtGskrxQ+X+GJXYfl5NSFLnU3A7Eo
'' SIG '' n1ArdTcFUWfdI8eD48Hwgob08TdSIL44TRGUThJszxXy
'' SIG '' hHUtek0hWOQp3pmqYnrCjeCGBU+CYMxOtM3oHTKLE6lC
'' SIG '' c6xgBn7mu2xFK1rmHF686X8GPnC4OxH+hBZlc8AzK1BF
'' SIG '' 3cJxjpmAYd/2N35P0G1VbrRYt38rMjmfSzYdR4yUakUq
'' SIG '' TQPiPDSFj26SIfXH0xrUaQ4APeFs0j+WZDGCBA0wggQJ
'' SIG '' AgEBMIGTMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
'' SIG '' YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
'' SIG '' VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
'' SIG '' BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
'' SIG '' AhMzAAABzg8Y90WX58b/AAEAAAHOMA0GCWCGSAFlAwQC
'' SIG '' AQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQ
'' SIG '' AQQwLwYJKoZIhvcNAQkEMSIEIEjNPQg/ZSrbQLVOBgZS
'' SIG '' P+gRbhItZ2vbwNVvflDrbp7FMIH6BgsqhkiG9w0BCRAC
'' SIG '' LzGB6jCB5zCB5DCBvQQgMmzPQXovRcNSbnclEF80xmzM
'' SIG '' qyWUsMyJoVnc8v8urGcwgZgwgYCkfjB8MQswCQYDVQQG
'' SIG '' EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
'' SIG '' BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
'' SIG '' cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
'' SIG '' ZS1TdGFtcCBQQ0EgMjAxMAITMwAAAc4PGPdFl+fG/wAB
'' SIG '' AAABzjAiBCC01rfimc/3u+KYR1OtkelowwuVhuOxwIi9
'' SIG '' d6iH4WtYJTANBgkqhkiG9w0BAQsFAASCAgCuBLaa7Jwv
'' SIG '' 7UblBhcaPOSVX4y+zWCvqaQFNRbcfyXPTpahFLXOsVCj
'' SIG '' s1xA/FEbOL3RtwyWHp3ZM6IGMxma2SptAB5sP7U2oXJ9
'' SIG '' TZSpMVnyXjte5QBClEx3kN/KhqnUAEk6y67Qgf1j30bk
'' SIG '' KlKOvjdibPfKRDk/6bVJNyQ0Yi6RZQzZc6srONdcDCqU
'' SIG '' 9M/I5M/xVowu6iJp/hvMuS+wWrseQ2Lr8ZJPWx5LNsaj
'' SIG '' XCavpAWbCT5CGP6TXHLZdoocEqNQrt3lpb1LmbRC7PEf
'' SIG '' 0fdXU7jDWD7wnR2sJ4G/jd57aO5EjN0soRQgzrD+mJlJ
'' SIG '' WBXss0R3+LLt9WZBCo9+t59h543+TkkwDwqFCclNh2xi
'' SIG '' W9uYwAZY3mCQsuo+FCeNjmTyfwI9RkANvOJO3HHKXMDu
'' SIG '' 7Nq+jv0fWinHHu8NlXevlAc3rBbmLWcVYzM+CStvPlbv
'' SIG '' i9ENxufwbDyoHL6XyX1LyKNyZMuPm8DH30l5pwoydkcB
'' SIG '' TuY/S9UUQL6lEp6WTY+odO9Wxfas898377A7fXQSO/2+
'' SIG '' xqws0XInGW/YhJGSYvtjDuX5nkXi3DoePgrx3G4xhpWH
'' SIG '' XPf2RShA6dn5Ai9G2YQ9YJPW0X638UJZdBoRwlL4aP8U
'' SIG '' ZQKc05pHZWHUjiJuxPv2hhKcycLPNKY8dpuhRwlK4LUj
'' SIG '' gJr4eOMLkLw6CA==
'' SIG '' End signature block
