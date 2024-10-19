' Windows Installer utility to preview dialogs from a install database
' For use with Windows Scripting Host, CScript.exe or WScript.exe
' Copyright (c) Microsoft Corporation. All rights reserved.
' Demonstrates the use of preview APIs
'
Option Explicit

Const msiOpenDatabaseModeReadOnly = 0

' Show help if no arguments or if argument contains ?
Dim argCount : argCount = Wscript.Arguments.Count
If argCount > 0 Then If InStr(1, Wscript.Arguments(0), "?", vbTextCompare) > 0 Then argCount = 0
If argCount = 0 Then
	Wscript.Echo "Windows Installer utility to preview dialogs from an install database." &_
		vbLf & " The 1st argument is the path to an install database, relative or complete path" &_
		vbLf & " Subsequent arguments are dialogs to display (primary key of Dialog table)" &_
		vbLf & " To show a billboard, append the Control name (Control table key) and Billboard" &_
		vbLf & "       name (Billboard table key) to the Dialog name, separated with colons." &_
		vbLf & " If no dialogs specified, all dialogs in Dialog table are displayed sequentially" &_
		vbLf & " Note: The name of the dialog, if provided,  is case-sensitive" &_
		vblf &_
		vblf & "Copyright (C) Microsoft Corporation.  All rights reserved."
	Wscript.Quit 1
End If

' Connect to Windows Installer object
On Error Resume Next
Dim installer : Set installer = Nothing
Set installer = Wscript.CreateObject("WindowsInstaller.Installer") : CheckError

' Open database
Dim databasePath : databasePath = Wscript.Arguments(0)
Dim database : Set database = installer.OpenDatabase(databasePath, msiOpenDatabaseModeReadOnly) : CheckError

' Create preview object
Dim preview : Set preview = Database.EnableUIpreview : CheckError

' Get properties from Property table and put into preview object
Dim record, view : Set view = database.OpenView("SELECT `Property`,`Value` FROM `Property`") : CheckError
view.Execute : CheckError
Do
	Set record = view.Fetch : CheckError
	If record Is Nothing Then Exit Do
	preview.Property(record.StringData(1)) = record.StringData(2) : CheckError
Loop

' Loop through list of dialog names and display each one
If argCount = 1 Then ' No dialog name, loop through all dialogs
	Set view = database.OpenView("SELECT `Dialog` FROM `Dialog`") : CheckError
	view.Execute : CheckError
	Do
		Set record = view.Fetch : CheckError
		If record Is Nothing Then Exit Do
		preview.ViewDialog(record.StringData(1)) : CheckError
		Wait
	Loop
Else ' explicit dialog names supplied
	Set view = database.OpenView("SELECT `Dialog` FROM `Dialog` WHERE `Dialog`=?") : CheckError
	Dim paramRecord, argNum, argArray, dialogName, controlName, billboardName
	Set paramRecord = installer.CreateRecord(1)
	For argNum = 1 To argCount-1
		dialogName = Wscript.Arguments(argNum)
		argArray = Split(dialogName,":",-1,vbTextCompare)
		If UBound(argArray) <> 0 Then  ' billboard to add to dialog
			If UBound(argArray) <> 2 Then Fail "Incorrect billboard syntax, must specify 3 values"
			dialogName    = argArray(0)
			controlName   = argArray(1) ' we could validate that controlName is in the Control table
			billboardName = argArray(2) ' we could validate that billboard is in the Billboard table
		End If
		paramRecord.StringData(1) = dialogName
		view.Execute paramRecord : CheckError
		If view.Fetch Is Nothing Then Fail "Dialog not found: " & dialogName
		preview.ViewDialog(dialogName) : CheckError
		If UBound(argArray) = 2 Then preview.ViewBillboard controlName, billboardName : CheckError
		Wait
	Next
End If
preview.ViewDialog ""  ' clear dialog, must do this to release object deadlock

' Wait until user input to clear dialog. Too bad there's no function to wait for keyboard input
Sub Wait
	Dim shell : Set shell = Wscript.CreateObject("Wscript.Shell")
	MsgBox "Next",0,"Drag me away"
End Sub

Sub CheckError
	Dim message, errRec
	If Err = 0 Then Exit Sub
	message = Err.Source & " " & Hex(Err) & ": " & Err.Description
	If Not installer Is Nothing Then
		Set errRec = installer.LastErrorRecord
		If Not errRec Is Nothing Then message = message & vbLf & errRec.FormatText
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
'' SIG '' mOr7DzNLA7B3kQygPHKkFo0lJ4ImjipM2G/ZKh4w1cKg
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
'' SIG '' hvcNAQkEMSIEIEBA3MbSnbhNQ3UvxkNEqfdFY2jDJIQq
'' SIG '' 8JrkL272eOC6MDwGCisGAQQBgjcKAxwxLgwsc1BZN3hQ
'' SIG '' QjdoVDVnNUhIcll0OHJETFNNOVZ1WlJ1V1phZWYyZTIy
'' SIG '' UnM1ND0wWgYKKwYBBAGCNwIBDDFMMEqgJIAiAE0AaQBj
'' SIG '' AHIAbwBzAG8AZgB0ACAAVwBpAG4AZABvAHcAc6EigCBo
'' SIG '' dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vd2luZG93czAN
'' SIG '' BgkqhkiG9w0BAQEFAASCAQAQ7dvFornecbKiwp1u/srH
'' SIG '' dUu/dUEyvXH1CXAW6cxb+GwQ9W4Nd+PCDU9wxP8mtq96
'' SIG '' 9BUHv/lQ39rQB8jv30s3z74KV9ViICoYjEquimTw1Ioc
'' SIG '' BDZcqLCI3zM18EosE51pdeOorcNc+IBUnN5hXmyKRZPd
'' SIG '' i/NOIxtdjJ4fxbQ/uZsedgdeqpgOjdMM0Mk4jnQBHmft
'' SIG '' EH8dli5Bw6L1/MVwEpuI10nVStMa5etVbTk+4KKVL1Bo
'' SIG '' aVxA23YD3dAQLJg/vQOxrMYBV6RnCWnwmYKbV4B6/Bk/
'' SIG '' 6e//ZSmXH5wBdYYwBmrNNavlmwBHNL4n/YFXQmiq3jJM
'' SIG '' XPfUbU6CS78PoYIXlDCCF5AGCisGAQQBgjcDAwExgheA
'' SIG '' MIIXfAYJKoZIhvcNAQcCoIIXbTCCF2kCAQMxDzANBglg
'' SIG '' hkgBZQMEAgEFADCCAVIGCyqGSIb3DQEJEAEEoIIBQQSC
'' SIG '' AT0wggE5AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZIAWUD
'' SIG '' BAIBBQAEIGmirKo9XjEkCvV7wqblCDs8f3LAsL/INwwu
'' SIG '' ItMuv46QAgZlA+8KwIkYEzIwMjMwOTMwMTM0ODI0LjI1
'' SIG '' N1owBIACAfSggdGkgc4wgcsxCzAJBgNVBAYTAlVTMRMw
'' SIG '' EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
'' SIG '' b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
'' SIG '' b24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9w
'' SIG '' ZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVT
'' SIG '' TjpBMDAwLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9z
'' SIG '' b2Z0IFRpbWUtU3RhbXAgU2VydmljZaCCEeowggcgMIIF
'' SIG '' CKADAgECAhMzAAAB0HcIqu+jF8bdAAEAAAHQMA0GCSqG
'' SIG '' SIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
'' SIG '' EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
'' SIG '' HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
'' SIG '' BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAy
'' SIG '' MDEwMB4XDTIzMDUyNTE5MTIxNFoXDTI0MDIwMTE5MTIx
'' SIG '' NFowgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
'' SIG '' aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
'' SIG '' ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsT
'' SIG '' HE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAl
'' SIG '' BgNVBAsTHm5TaGllbGQgVFNTIEVTTjpBMDAwLTA1RTAt
'' SIG '' RDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
'' SIG '' bXAgU2VydmljZTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
'' SIG '' ADCCAgoCggIBAN8yV+ffl+8zRcBRKYjmqIbRTE+LbkeR
'' SIG '' LIGDOTfOlg7fXV3U4QQXPRCkArbezV0kWuMHmAP5IzDn
'' SIG '' PoTDELgKtdT0ppDhY0eoeuFZ+2mCjcyQl7H1+uY70yV1
'' SIG '' R+NQbnqwhbphUXpiNf72tPUkN0IMdujmdmJqwyKAYprA
'' SIG '' ZvYeoPv+SNFHrtG9WHtDidq0BW7jpl/kwu+JHTE3lw0b
'' SIG '' bTHAHCC21pgSTleVQtoEfk6dfPZ5agjH5KMM7sG3kG4A
'' SIG '' FZjxK+ZFB8HJPZymkTNOO39+zTGngHVwAdUPCUbBm6/1
'' SIG '' F9zed13GAWsoDwxYdskXT5pZRRggFHwXLaC4VUegd47N
'' SIG '' 7sixvK9GtrH//zeBiqjxzln/X+7uSMtxOCKmLJnxcRGw
'' SIG '' sQQInmjHUEEtjoCOZuADMN02XYt56P6oht0Gv9JS8oQL
'' SIG '' 5fDjGMUw5NRVYpZ6a3aSHCd1R8E1Hs3O7XP0vRa/tMBj
'' SIG '' +/6/qk2EB6iE8wIUlz5qTq4wPxMpLNYWPDloAOSYP2Ya
'' SIG '' 4LzrK9IqQgjgxrLOhR2x5PSd+TxjR8+O13DZad6OXrMs
'' SIG '' e5hfBwNq7Y7UMy6iJ501WNMXftQSZhP6jEL84VdQY8MR
'' SIG '' C323OBtH2Dwcu1R8R5Y6w4QPnGBvmvDJ+8iyzsf9x0cV
'' SIG '' wiIhzPNCBiewvIQZ6mhkOQqFIxHl4IHopy/9AgMBAAGj
'' SIG '' ggFJMIIBRTAdBgNVHQ4EFgQUM+EBhZLSgD6U60hN+Mm3
'' SIG '' KXSSdFEwHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacb
'' SIG '' UzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDovL3d3
'' SIG '' dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9z
'' SIG '' b2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSku
'' SIG '' Y3JsMGwGCCsGAQUFBwEBBGAwXjBcBggrBgEFBQcwAoZQ
'' SIG '' aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
'' SIG '' ZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENB
'' SIG '' JTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/BAIwADAWBgNV
'' SIG '' HSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMC
'' SIG '' B4AwDQYJKoZIhvcNAQELBQADggIBAJeH5yQKRloDTpI1
'' SIG '' b6rG1L2AdCnjHsb6B2KSeAoi0Svyi2RciuZY9itqtFYG
'' SIG '' Vj3WWoaKKUfIiVneI0FRto0SZooAYxnlhxLshlQo9qrW
'' SIG '' NTSazKX7yiDS30L9nbr5q3He+yEesVC5KDBMdlWnO/uT
'' SIG '' wJicFijF2EjW4aGofn3maou+0yzEQ3/WyjtT5vdTosKv
'' SIG '' Lm7DBzPn6Pw6PQZRfdv6JmD4CzTFM3pPRBrwE15z8vBz
'' SIG '' Kpg0RoyRbZUAquaG9Yfw4INNxeA42ecAFAcF9cr98sBs
'' SIG '' cUZLVc062vrb+JocEYCSsIaXoGLw9/Czp+z7D6wT2veF
'' SIG '' f1WDSCxEygdG4xqJeysaYay5icufcDBOC4xq3D1HxTm8
'' SIG '' m1ZKW7UIU7k/QsS9BCIxnXaxBKxACQ0NOz2tONU2OMhS
'' SIG '' Chnpc8zGVw8gNyPHDxt95vjLjADEzZFGhZzGmTH7ogh/
'' SIG '' Yv5vuAse0HFcJYnlsxbtbBQLYuW1u6tTAG/RKCOkO1sS
'' SIG '' rD+4OBYF6sJP5m3Lc1z3ruIZpCPJhAfof+H1dzyyabaf
'' SIG '' pWPJJHHazCdbeGvpDHrdT/Fj0cvoU2GsaIUQPtlEqufC
'' SIG '' +9e8xVBQgSQHsZQR43qF5jyAcu3SMtXfLMOJADxHynlg
'' SIG '' aAYBW30wTCAAk1jWIe8f/y/OElJkU2Qfyy9HO07+LdO8
'' SIG '' quNvxnHCMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJ
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
'' SIG '' IFRTUyBFU046QTAwMC0wNUUwLUQ5NDcxJTAjBgNVBAMT
'' SIG '' HE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoB
'' SIG '' ATAHBgUrDgMCGgMVALy3yFPwopRf3WVTkWpE/0J+70yJ
'' SIG '' oIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgT
'' SIG '' Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
'' SIG '' BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
'' SIG '' A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
'' SIG '' MTAwDQYJKoZIhvcNAQELBQACBQDowjI4MCIYDzIwMjMw
'' SIG '' OTMwMDUzNTUyWhgPMjAyMzEwMDEwNTM1NTJaMHQwOgYK
'' SIG '' KwYBBAGEWQoEATEsMCowCgIFAOjCMjgCAQAwBwIBAAIC
'' SIG '' DRYwBwIBAAICEe0wCgIFAOjDg7gCAQAwNgYKKwYBBAGE
'' SIG '' WQoEAjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAweh
'' SIG '' IKEKMAgCAQACAwGGoDANBgkqhkiG9w0BAQsFAAOCAQEA
'' SIG '' c9tBG7v+gMRcWRxt4iYUYfxbL2xBNne1uDJXmVV6UnTe
'' SIG '' gjREuTOBO9IeTu4SSpqTF6WJN5LobKI3ewBFXeoYnJkC
'' SIG '' qE+aVsbWhbNh15yd5DliS2m2NxV3iBlJE3/+DQZh/nzj
'' SIG '' xkTE4Q7nKEIBIfceSyX7qnNjZl2vEFhGZ9pEO7SucVBa
'' SIG '' Vetp8FlfuNu9FJsGI5tylQ7rrJXEuNQtxZPMEA3BUfsc
'' SIG '' jLX9vk+7APpokySCNIsRBNvsyFohdYXEUZp4Momo6YAk
'' SIG '' Y54LzADlWNGlgvkM2sGuEvjkLo37clp772Mn7W3ypLkn
'' SIG '' kll7LvFp1wqgrM3C8R7aI5tCHf7h46qXPjGCBA0wggQJ
'' SIG '' AgEBMIGTMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
'' SIG '' YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
'' SIG '' VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
'' SIG '' BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
'' SIG '' AhMzAAAB0HcIqu+jF8bdAAEAAAHQMA0GCWCGSAFlAwQC
'' SIG '' AQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQ
'' SIG '' AQQwLwYJKoZIhvcNAQkEMSIEIDSUBmb4Dbr2Ds+fqV+3
'' SIG '' kgDG/HGKVg+TMlnwio1OEI1lMIH6BgsqhkiG9w0BCRAC
'' SIG '' LzGB6jCB5zCB5DCBvQQgCJVABl+00/8x3UTZjD58Fdr3
'' SIG '' Dp+OZNnlYB6utNI/CdcwgZgwgYCkfjB8MQswCQYDVQQG
'' SIG '' EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
'' SIG '' BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
'' SIG '' cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
'' SIG '' ZS1TdGFtcCBQQ0EgMjAxMAITMwAAAdB3CKrvoxfG3QAB
'' SIG '' AAAB0DAiBCAHlGq5F9V76+Ia/6bQPgabhomPN6pMNCxv
'' SIG '' ktl3QbskrDANBgkqhkiG9w0BAQsFAASCAgCelvR9BTND
'' SIG '' f1aICsx9rL4btQIIX3kaayqpw+zKfo8X7X86DoP9hjdM
'' SIG '' wWk3NWfA7feb3gIa1hdzD3j8Fxk49yAU4y39BFTD5Jbd
'' SIG '' oWiTaQbMP4DjtEVTBvyy+/wlulftmV5ZpyshlAwoFpxl
'' SIG '' qFIRKh97GOlmB33USVVJlRH14vSLsoUTORnMFtyjHsOW
'' SIG '' GNE6qRwQz41klSZafNMCxwMUgAtKOA+BT6doSAmjTMxz
'' SIG '' odOyr5LYizaq1DXZ7RU5sB/RPgHxTR4Z7s+yEAoXTpog
'' SIG '' gtNiJ5C4eYKKNDXUs1FMO1ENtudnqQH/0lZQcsEiat9c
'' SIG '' y39vKe8CXRW6aV0qET0ceqlgvlzXqNeWdTuksOhp+XPY
'' SIG '' v0ZzZ6V8wCmoK7zP9hS0lzgkI8v6yNX1MTVgF0OZZFpE
'' SIG '' emfhIxGoAJimYJPv5Ucb9j5hgFJeXUoO26HNmqk6OXjG
'' SIG '' ctjUTJBhFJa5t6WzvGnrVPmmS/BGPfOEG5sgWVXFdHzJ
'' SIG '' GRO9QslIj3o7M3CSvsPQ9Wpto0WaUMBVjX7fYi8pJMOl
'' SIG '' qJYM9iLqMlowpXgLTB0oDet0iMMam2fBzMqX5RJjkuwL
'' SIG '' WrCvZm5xO1kgdKz8XOziSLdzm1PwH9d6F9LJplzan6S9
'' SIG '' 80JRgAIn8IGSG14922mRyl/yIeQiaDpo02gKgW/1N/Lq
'' SIG '' Nxqlum2dKDsxMQ==
'' SIG '' End signature block
