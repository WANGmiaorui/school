' Windows Installer utility to report the differences between two databases
' For use with Windows Scripting Host, CScript.exe only, lists to stdout
' Copyright (c) Microsoft Corporation. All rights reserved.
' Simply generates a transform between the databases and then view the transform
'
Option Explicit

Const icdLong       = 0
Const icdShort      = &h400
Const icdObject     = &h800
Const icdString     = &hC00
Const icdNullable   = &h1000
Const icdPrimaryKey = &h2000
Const icdNoNulls    = &h0000
Const icdPersistent = &h0100
Const icdTemporary  = &h0000

Const msiOpenDatabaseModeReadOnly     = 0
Const msiOpenDatabaseModeTransact     = 1
Const msiOpenDatabaseModeCreate       = 3
Const iteViewTransform       = 256

If Wscript.Arguments.Count < 2 Then
	Wscript.Echo "Windows Installer database difference utility" &_
		vbNewLine & " Generates a temporary transform file, then display it" &_
		vbNewLine & " 1st argument is the path to the original installer database" &_
		vbNewLine & " 2nd argument is the path to the updated installer database" &_
		vbNewLine &_
		vbNewLine & "Copyright (C) Microsoft Corporation.  All rights reserved."
	Wscript.Quit 1
End If

' Cannot run with GUI script host, as listing is performed to standard out
If UCase(Mid(Wscript.FullName, Len(Wscript.Path) + 2, 1)) = "W" Then
	WScript.Echo "Cannot use WScript.exe - must use CScript.exe with this program"
	Wscript.Quit 2
End If

' Connect to Windows Installer object
On Error Resume Next
Dim installer : Set installer = Nothing
Set installer = Wscript.CreateObject("WindowsInstaller.Installer") : CheckError

' Create path for temporary transform file
Dim WshShell : Set WshShell = Wscript.CreateObject("Wscript.Shell") : CheckError
Dim tempFilePath:tempFilePath = WshShell.ExpandEnvironmentStrings("%TEMP%") & "\diff.tmp"

' Open databases, generate transform, then list transform
Dim database1 : Set database1 = installer.OpenDatabase(Wscript.Arguments(0), msiOpenDatabaseModeReadOnly) : CheckError
Dim database2 : Set database2 = installer.OpenDatabase(Wscript.Arguments(1), msiOpenDatabaseModeReadOnly) : CheckError
Dim different : different = Database2.GenerateTransform(Database1, tempFilePath) : CheckError
If different Then
	database1.ApplyTransform tempFilePath, iteViewTransform + 0 : CheckError' should not need error suppression flags
	ListTransform database1
End If

' Open summary information streams and compare them
Dim sumInfo1 : Set sumInfo1 = database1.SummaryInformation(0) : CheckError
Dim sumInfo2 : Set sumInfo2 = database2.SummaryInformation(0) : CheckError
Dim iProp, value1, value2
For iProp = 1 to 19              
	value1 = sumInfo1.Property(iProp) : CheckError
	value2 = sumInfo2.Property(iProp) : CheckError
	If value1 <> value2 Then
		Wscript.Echo "\005SummaryInformation   [" & iProp & "] {" & value1 & "}->{" & value2 & "}"
		different = True
	End If
Next
If Not different Then Wscript.Echo "Databases are identical"
Wscript.Quit 0

Function DecodeColDef(colDef)
	Dim def
	Select Case colDef AND (icdShort OR icdObject)
	Case icdLong
		def = "LONG"
	Case icdShort
		def = "SHORT"
	Case icdObject
		def = "OBJECT"
	Case icdString
		def = "CHAR(" & (colDef AND 255) & ")"
	End Select
	If (colDef AND icdNullable)   =  0 Then def = def & " NOT NULL"
	If (colDef AND icdPrimaryKey) <> 0 Then def = def & " PRIMARY KEY"
	DecodeColDef = def
End Function

Sub ListTransform(database)
	Dim view, record, row, column, change
	On Error Resume Next
	Set view = database.OpenView("SELECT * FROM `_TransformView` ORDER BY `Table`, `Row`")
	If Err <> 0 Then Wscript.Echo "Transform viewing supported only in builds 4906 and beyond of MSI.DLL" : Wscript.Quit 2
	view.Execute : CheckError
	Do
		Set record = view.Fetch : CheckError
		If record Is Nothing Then Exit Do
		change = Empty
		If record.IsNull(3) Then
			row = "<DDL>"
			If NOT record.IsNull(4) Then change = "[" & record.StringData(5) & "]: " & DecodeColDef(record.StringData(4))
		Else
			row = "[" & Join(Split(record.StringData(3), vbTab, -1), ",") & "]"
			If record.StringData(2) <> "INSERT" AND record.StringData(2) <> "DELETE" Then change = "{" & record.StringData(5) & "}->{" & record.StringData(4) & "}"
		End If
		column = record.StringData(1) & " " & record.StringData(2)
		if Len(column) < 24 Then column = column & Space(24 - Len(column))
		WScript.Echo column, row, change
	Loop
End Sub

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
'' SIG '' cwzPLmwXndAasgrSds09lWoEa+nEByy+weD1dY9VbGig
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
'' SIG '' hvcNAQkEMSIEIBwkzzhZEkFlS61rw3czupIfe96QCWYA
'' SIG '' 2XTJcIkHwhZ2MDwGCisGAQQBgjcKAxwxLgwsc1BZN3hQ
'' SIG '' QjdoVDVnNUhIcll0OHJETFNNOVZ1WlJ1V1phZWYyZTIy
'' SIG '' UnM1ND0wWgYKKwYBBAGCNwIBDDFMMEqgJIAiAE0AaQBj
'' SIG '' AHIAbwBzAG8AZgB0ACAAVwBpAG4AZABvAHcAc6EigCBo
'' SIG '' dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vd2luZG93czAN
'' SIG '' BgkqhkiG9w0BAQEFAASCAQCqSreTBm1g7n27b/IhRfOV
'' SIG '' E/T8Od/W3Lo7hW+57ELoxV3VdsRARfyAjAYedBMEYF7Y
'' SIG '' 8ZA4xhtmsqqvY0Bmc/fjy0dEY4RTo/N8/OYL8JvAKJT2
'' SIG '' Kqc0fUnvSBnjRxcVaMRGbJ/iUCPrkIz4CzEQgTEx4TlP
'' SIG '' yC+HenixfBhnty5pIzGEo6M+l2UiDjpujwFnlwfqAGYk
'' SIG '' kiRQMWEMDbG4C+CkYofEZQvE7LHHNZ0B5Jq5E96wrC1V
'' SIG '' b+NrXHgFL4TQJDKODSEYm9ca+6ssJJfiz1z+HUp9pfqt
'' SIG '' ddOSF452fMcsmkfMsPOuceXIOrxz14O6nCA+7bLls+il
'' SIG '' cwQmmj3Q2ZLtoYIXlDCCF5AGCisGAQQBgjcDAwExgheA
'' SIG '' MIIXfAYJKoZIhvcNAQcCoIIXbTCCF2kCAQMxDzANBglg
'' SIG '' hkgBZQMEAgEFADCCAVIGCyqGSIb3DQEJEAEEoIIBQQSC
'' SIG '' AT0wggE5AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZIAWUD
'' SIG '' BAIBBQAEIKxSQ8TU7YOSM03Glgpyhu+SwAV199fzk1f9
'' SIG '' 6ff0RTdhAgZlC1+OC4kYEzIwMjMwOTMwMDkyMDE5LjQy
'' SIG '' MVowBIACAfSggdGkgc4wgcsxCzAJBgNVBAYTAlVTMRMw
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
'' SIG '' AQQwLwYJKoZIhvcNAQkEMSIEIJoygYWw6VfL4SFIjQXR
'' SIG '' awEg+IRF/41Z+Vpky4T4EoMeMIH6BgsqhkiG9w0BCRAC
'' SIG '' LzGB6jCB5zCB5DCBvQQg1u5lAcL+wwIT5yApVKTAqkMg
'' SIG '' J+d58VliANsXgetwWOYwgZgwgYCkfjB8MQswCQYDVQQG
'' SIG '' EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
'' SIG '' BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
'' SIG '' cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
'' SIG '' ZS1TdGFtcCBQQ0EgMjAxMAITMwAAAcyGpdw369lhLQAB
'' SIG '' AAABzDAiBCBQ6K8i12VnEIiAgPIstj/XuIzTSGMtgQ5q
'' SIG '' +WpursTouDANBgkqhkiG9w0BAQsFAASCAgACHTchz/qg
'' SIG '' 0wkpmJMJ40W+2ZBgFpnPy+mkPnXM6BaQc/X87f8z7R26
'' SIG '' xH2acday92qi3vkBlSNN8XkaW0yMVDSmNJSsTEwlFdu5
'' SIG '' JLBUA0RIGpahEzxoDiqOCw746ukLXyp56v+rwonSSOGi
'' SIG '' mSYsI6KpbWE3hBYbcf9IT0THmwOMBvNk6xP/iZJ5W+K4
'' SIG '' uy38IceirYZgH4DobGyGX5SgpDtUuxl4fXJEzl6B8lXl
'' SIG '' Cpda8/I3FUCEGurmOiiAIvDdXWzEbNV9BZehNhWF4b1W
'' SIG '' 1tvV4pCEEl7qnww5MKPNYTO69LthO2b58u1A98b7tKHq
'' SIG '' YlSlq4EsCZ1J7S59XfvMDrTGqt1cezgg/rW7dgNj83KA
'' SIG '' u9bA16U/19x3ruZssiyqbcb0dClyA99RNp07JH8JHABP
'' SIG '' 8ZFxJTrhWVwCoyNxmcSmkZNgQqM80X39H4DWRSoN3Npo
'' SIG '' DciOkOvwwbzpZWq/PC1s4PXS1ps/poxgF65WjD5UXMzb
'' SIG '' XNYrQneFqWeKTyZkt5nrUFd9L+gOGEnxLxA+Js/6jFMf
'' SIG '' oD+FVNEoMjc8CPAV7zngTEUaOFazCY2jjWz/u4/oSmXn
'' SIG '' 7M5DmzkKyj7OtpFW4wfot5RxMfMPqs7VgNJvBrexU+yk
'' SIG '' Ds6YEstWhSqBPNA9WBl3fCJR/8/zt94Wp3abKi033FNd
'' SIG '' kGlJy2kqQPH7bg==
'' SIG '' End signature block
