' Windows Installer utility to execute SQL statements against an installer database
' For use with Windows Scripting Host, CScript.exe or WScript.exe
' Copyright (c) Microsoft Corporation. All rights reserved.
' Demonstrates the script-driven database queries and updates
'
Option Explicit

Const msiOpenDatabaseModeReadOnly = 0
Const msiOpenDatabaseModeTransact = 1

Dim argNum, argCount:argCount = Wscript.Arguments.Count
If (argCount < 2) Then
	Wscript.Echo "Windows Installer utility to execute SQL queries against an installer database." &_
		vbLf & " The 1st argument specifies the path to the MSI database, relative or full path" &_
		vbLf & " Subsequent arguments specify SQL queries to execute - must be in double quotes" &_
		vbLf & " SELECT queries will display the rows of the result list specified in the query" &_
		vbLf & " Binary data columns selected by a query will not be displayed" &_
		vblf &_
		vblf & "Copyright (C) Microsoft Corporation.  All rights reserved."
	Wscript.Quit 1
End If

' Scan arguments for valid SQL keyword and to determine if any update operations
Dim openMode : openMode = msiOpenDatabaseModeReadOnly
For argNum = 1 To argCount - 1
	Dim keyword : keyword = Wscript.Arguments(argNum)
	Dim keywordLen : keywordLen = InStr(1, keyword, " ", vbTextCompare)
	If (keywordLen) Then keyword = UCase(Left(keyword, keywordLen - 1))
	If InStr(1, "UPDATE INSERT DELETE CREATE ALTER DROP", keyword, vbTextCompare) Then
		openMode = msiOpenDatabaseModeTransact
	ElseIf keyword <> "SELECT" Then
		Fail "Invalid SQL statement type: " & keyword
	End If
Next

' Connect to Windows installer object
On Error Resume Next
Dim installer : Set installer = Nothing
Set installer = Wscript.CreateObject("WindowsInstaller.Installer") : CheckError

' Open database
Dim databasePath:databasePath = Wscript.Arguments(0)
Dim database : Set database = installer.OpenDatabase(databasePath, openMode) : CheckError

' Process SQL statements
Dim query, view, record, message, rowData, columnCount, delim, column
For argNum = 1 To argCount - 1
	query = Wscript.Arguments(argNum)
	Set view = database.OpenView(query) : CheckError
	view.Execute : CheckError
	If Ucase(Left(query, 6)) = "SELECT" Then
		Do
			Set record = view.Fetch
			If record Is Nothing Then Exit Do
			columnCount = record.FieldCount
			rowData = Empty
			delim = "  "
			For column = 1 To columnCount
				If column = columnCount Then delim = vbLf
				rowData = rowData & record.StringData(column) & delim
			Next
			message = message & rowData
		Loop
	End If
Next
If openMode = msiOpenDatabaseModeTransact Then database.Commit
If Not IsEmpty(message) Then Wscript.Echo message
Wscript.Quit 0

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
'' SIG '' MIImHwYJKoZIhvcNAQcCoIImEDCCJgwCAQExDzANBglg
'' SIG '' hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
'' SIG '' BgEEAYI3AgEeMCQCAQEEEE7wKRaZJ7VNj+Ws4Q8X66sC
'' SIG '' AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
'' SIG '' 4Xv5+5ronXWl5cvPsyZzr63fsdqLVPGyNx2CnUPSw9mg
'' SIG '' gguBMIIFCTCCA/GgAwIBAgITMwAABUKmt2J24tnGYAAA
'' SIG '' AAAFQjANBgkqhkiG9w0BAQsFADB+MQswCQYDVQQGEwJV
'' SIG '' UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
'' SIG '' UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
'' SIG '' cmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBT
'' SIG '' aWduaW5nIFBDQSAyMDEwMB4XDTIzMDgwODE4MzQyNFoX
'' SIG '' DTI0MDgwNzE4MzQyNFowfzELMAkGA1UEBhMCVVMxEzAR
'' SIG '' BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
'' SIG '' bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
'' SIG '' bjEpMCcGA1UEAxMgTWljcm9zb2Z0IFdpbmRvd3MgS2l0
'' SIG '' cyBQdWJsaXNoZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IB
'' SIG '' DwAwggEKAoIBAQCcJZiMAqcd6Aiwle3knHx4Xfe7omzt
'' SIG '' Y2N2RuXal3jkkxHyBU9qtnMouYlNXwHGv/8pIDQDD92x
'' SIG '' 2dTkSUtjFzybOcVl5vL17GEiv6N8XIb4+2fu46EqvQgI
'' SIG '' kAetIl1utCBFkLnLRS8YmnBzJT3wFfFKRdjram+KxZBY
'' SIG '' 3jQL37PIEePWyXSofKbS4qjNRava3JBRMOVN5H5sDHev
'' SIG '' qarLbZAZN5c+kMV9NdKVbcfNr3Y5rT62DfaPT/ObUWfl
'' SIG '' hhDDzjbaIQ5r/Je34BYLOxzr1rsjyOPNHjyoBK7S7ckx
'' SIG '' MYuLmu7TUQ2aEzPed8HyKR7/E8Kv2vJwBSULYwnthzVE
'' SIG '' wRy3AgMBAAGjggF9MIIBeTAfBgNVHSUEGDAWBgorBgEE
'' SIG '' AYI3CgMUBggrBgEFBQcDAzAdBgNVHQ4EFgQUVU6gu1X4
'' SIG '' LeVa3Y26BhI0XCo5LpgwVAYDVR0RBE0wS6RJMEcxLTAr
'' SIG '' BgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlv
'' SIG '' bnMgTGltaXRlZDEWMBQGA1UEBRMNMjI5OTAzKzUwMTQz
'' SIG '' OTAfBgNVHSMEGDAWgBTm/F97uyIAWORyTrX0IXQjMubv
'' SIG '' rDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1p
'' SIG '' Y3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWND
'' SIG '' b2RTaWdQQ0FfMjAxMC0wNy0wNi5jcmwwWgYIKwYBBQUH
'' SIG '' AQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1p
'' SIG '' Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY0NvZFNpZ1BD
'' SIG '' QV8yMDEwLTA3LTA2LmNydDAMBgNVHRMBAf8EAjAAMA0G
'' SIG '' CSqGSIb3DQEBCwUAA4IBAQA4B091Ze9CRzP46FRR98UQ
'' SIG '' JiyyDAb5GPM6BtPGr6QmgaACr/Fo/K25p010d6+Xb5sY
'' SIG '' 2YwQMYkmqIaTV/OBANhbDKMdG7ysQttyxUPy7R1jQ2A1
'' SIG '' /n3wCjcLnVepbZLG8+VZO0IeqDjXCEfSMwr26ls2UPz2
'' SIG '' 65o0kbJIk4MUcabn4Zw7umJarNR3fGIQrTrjkvA0sTxC
'' SIG '' hWF9OsnpDvgW4OgE/XE7kWt7jCeO4de5pX2Ck9z58HmC
'' SIG '' SdL8Xg/iNDDqhRdK1LrQnBf+CWGCkQVAoL1ROY397oyu
'' SIG '' OerkbJE2BLNyKyA3+sCe4SWNXjTT6WPFFpNdezeVsZJM
'' SIG '' Sad1jXDbRYZ6MIIGcDCCBFigAwIBAgIKYQxSTAAAAAAA
'' SIG '' AzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMx
'' SIG '' EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
'' SIG '' ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
'' SIG '' dGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2Vy
'' SIG '' dGlmaWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMTAwNzA2
'' SIG '' MjA0MDE3WhcNMjUwNzA2MjA1MDE3WjB+MQswCQYDVQQG
'' SIG '' EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
'' SIG '' BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
'' SIG '' cnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29k
'' SIG '' ZSBTaWduaW5nIFBDQSAyMDEwMIIBIjANBgkqhkiG9w0B
'' SIG '' AQEFAAOCAQ8AMIIBCgKCAQEA6Q5kUHlntcTj/QkATJ6U
'' SIG '' rPdWaOpE2M/FWE+ppXZ8bUW60zmStKQe+fllguQX0o/9
'' SIG '' RJwI6GWTzixVhL99COMuK6hBKxi3oktuSUxrFQfe0dLC
'' SIG '' iR5xlM21f0u0rwjYzIjWaxeUOpPOJj/s5v40mFfVHV1J
'' SIG '' 9rIqLtWFu1k/+JC0K4N0yiuzO0bj8EZJwRdmVMkcvR3E
'' SIG '' VWJXcvhnuSUgNN5dpqWVXqsogM3Vsp7lA7Vj07IUyMHI
'' SIG '' iiYKWX8H7P8O7YASNUwSpr5SW/Wm2uCLC0h31oVH1RC5
'' SIG '' xuiq7otqLQVcYMa0KlucIxxfReMaFB5vN8sZM4BqiU2j
'' SIG '' amZjeJPVMM+VHwIDAQABo4IB4zCCAd8wEAYJKwYBBAGC
'' SIG '' NxUBBAMCAQAwHQYDVR0OBBYEFOb8X3u7IgBY5HJOtfQh
'' SIG '' dCMy5u+sMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBB
'' SIG '' MAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8G
'' SIG '' A1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYG
'' SIG '' A1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9z
'' SIG '' b2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0Nl
'' SIG '' ckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQRO
'' SIG '' MEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9z
'' SIG '' b2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIw
'' SIG '' MTAtMDYtMjMuY3J0MIGdBgNVHSAEgZUwgZIwgY8GCSsG
'' SIG '' AQQBgjcuAzCBgTA9BggrBgEFBQcCARYxaHR0cDovL3d3
'' SIG '' dy5taWNyb3NvZnQuY29tL1BLSS9kb2NzL0NQUy9kZWZh
'' SIG '' dWx0Lmh0bTBABggrBgEFBQcCAjA0HjIgHQBMAGUAZwBh
'' SIG '' AGwAXwBQAG8AbABpAGMAeQBfAFMAdABhAHQAZQBtAGUA
'' SIG '' bgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAGnTvV08p
'' SIG '' e8QWhXi4UNMi/AmdrIKX+DT/KiyXlRLl5L/Pv5PI4zSp
'' SIG '' 24G43B4AvtI1b6/lf3mVd+UC1PHr2M1OHhthosJaIxrw
'' SIG '' jKhiUUVnCOM/PB6T+DCFF8g5QKbXDrMhKeWloWmMIpPM
'' SIG '' dJjnoUdD8lOswA8waX/+0iUgbW9h098H1dlyACxphnY9
'' SIG '' UdumOUjJN2FtB91TGcun1mHCv+KDqw/ga5uV1n0oUbCJ
'' SIG '' SlGkmmzItx9KGg5pqdfcwX7RSXCqtq27ckdjF/qm1qKm
'' SIG '' huyoEESbY7ayaYkGx0aGehg/6MUdIdV7+QIjLcVBy78d
'' SIG '' TMgW77Gcf/wiS0mKbhXjpn92W9FTeZGFndXS2z1zNfM8
'' SIG '' rlSyUkdqwKoTldKOEdqZZ14yjPs3hdHcdYWch8ZaV4XC
'' SIG '' v90Nj4ybLeu07s8n07VeafqkFgQBpyRnc89NT7beBVaX
'' SIG '' evfpUk30dwVPhcbYC/GO7UIJ0Q124yNWeCImNr7KsYxu
'' SIG '' qh3khdpHM2KPpMmRM19xHkCvmGXJIuhCISWKHC1g2TeJ
'' SIG '' QYkqFg/XYTyUaGBS79ZHmaCAQO4VgXc+nOBTGBpQHTiV
'' SIG '' mx5mMxMnORd4hzbOTsNfsvU9R1O24OXbC2E9KteSLM43
'' SIG '' Wj5AQjGkHxAIwlacvyRdUQKdannSF9PawZSOB3slcUSr
'' SIG '' Bmrm1MbfI5qWdcUxghn2MIIZ8gIBATCBlTB+MQswCQYD
'' SIG '' VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
'' SIG '' A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
'' SIG '' IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQg
'' SIG '' Q29kZSBTaWduaW5nIFBDQSAyMDEwAhMzAAAFQqa3Ynbi
'' SIG '' 2cZgAAAAAAVCMA0GCWCGSAFlAwQCAQUAoIIBBDAZBgkq
'' SIG '' hkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3
'' SIG '' AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQx
'' SIG '' IgQgk6JglrqV6v3DtnQAQb6e6ZRImgh0mz/ZPyqjprDy
'' SIG '' /bswPAYKKwYBBAGCNwoDHDEuDCxzUFk3eFBCN2hUNWc1
'' SIG '' SEhyWXQ4ckRMU005VnVaUnVXWmFlZjJlMjJSczU0PTBa
'' SIG '' BgorBgEEAYI3AgEMMUwwSqAkgCIATQBpAGMAcgBvAHMA
'' SIG '' bwBmAHQAIABXAGkAbgBkAG8AdwBzoSKAIGh0dHA6Ly93
'' SIG '' d3cubWljcm9zb2Z0LmNvbS93aW5kb3dzMA0GCSqGSIb3
'' SIG '' DQEBAQUABIIBADuRbbke2+sf8512Xoj6TAmVWakxTdk8
'' SIG '' Fc6cWCg3JfIVZs8z8pWSSuC6zdYNABSNYhf03R+s51UV
'' SIG '' /HGRUwJdpSmDR5goXkxPzTJMiH2F3OipC85T/dc+CNK+
'' SIG '' aZMXWGjslNyiLNCI580kF2Tw3I4pkCHvXfaxQ0rl3LYX
'' SIG '' f4BQf2p93HUuKqvIVnRFZCdA0WDkPtKH2A0EHUKJvxce
'' SIG '' tkqUaegJDJJ9HrNrdg5vOHH+TLi3du3ffDqV3L21oPo5
'' SIG '' S/r0ZoQMahBg4xeZfbckzZP8E/ekmFT19LY0HZsyx5ol
'' SIG '' 40ZCnX/lSy+bikqOV/M9e2D5XeonfswWI2HYO0CZYmFZ
'' SIG '' rVehghcpMIIXJQYKKwYBBAGCNwMDATGCFxUwghcRBgkq
'' SIG '' hkiG9w0BBwKgghcCMIIW/gIBAzEPMA0GCWCGSAFlAwQC
'' SIG '' AQUAMIIBWQYLKoZIhvcNAQkQAQSgggFIBIIBRDCCAUAC
'' SIG '' AQEGCisGAQQBhFkKAwEwMTANBglghkgBZQMEAgEFAAQg
'' SIG '' 77zv9fgppUpmBHbRYXbGs6q6ExQFGlpeEOHvDGv7wDgC
'' SIG '' BmUK9tM62RgTMjAyMzA5MzAxMDE0MjEuOTQ2WjAEgAIB
'' SIG '' 9KCB2KSB1TCB0jELMAkGA1UEBhMCVVMxEzARBgNVBAgT
'' SIG '' Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
'' SIG '' BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsG
'' SIG '' A1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9u
'' SIG '' cyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVT
'' SIG '' TjowODQyLTRCRTYtQzI5QTElMCMGA1UEAxMcTWljcm9z
'' SIG '' b2Z0IFRpbWUtU3RhbXAgU2VydmljZaCCEXgwggcnMIIF
'' SIG '' D6ADAgECAhMzAAABsm5AA39uqZSSAAEAAAGyMA0GCSqG
'' SIG '' SIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
'' SIG '' EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
'' SIG '' HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
'' SIG '' BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAy
'' SIG '' MDEwMB4XDTIyMDkyMDIwMjIwMVoXDTIzMTIxNDIwMjIw
'' SIG '' MVowgdIxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
'' SIG '' aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
'' SIG '' ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsT
'' SIG '' JE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGlt
'' SIG '' aXRlZDEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046MDg0
'' SIG '' Mi00QkU2LUMyOUExJTAjBgNVBAMTHE1pY3Jvc29mdCBU
'' SIG '' aW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
'' SIG '' AQUAA4ICDwAwggIKAoICAQDKomUyHXv5UOKwvgZpeX/1
'' SIG '' rqv8Sk8a32xttx6H5kPqmQDeBsju9zxd8vTgH6be0H9o
'' SIG '' 3JXVjhlAfh8wbsJZWMj938eDGPM77gLgd+xb6MrZzQtg
'' SIG '' yp1a1ZRzlXBlC/Qp5oQzTANv57JIyH9iKIhvSdKi2K/H
'' SIG '' brx3UCfS4tj6vYLskm/Zr1C+tKILJQjvYJIehYhA8DK8
'' SIG '' FK/Fo2uoxaVE58vLYNDdHJwjdsOHypKeamXG1GBWInC0
'' SIG '' m/+gO6RwrV+sZ46sIZiaIm975CiclcW7hS0YVV8R/eW9
'' SIG '' Cx3jYYn59476No/v+EFddIxKV1VvogvQbE7Uevcb041O
'' SIG '' dWYD+wUeGAxFquybMpUjr+QeUx0w10X9fOFEcxYU8m/D
'' SIG '' mUCmO5qjIe3PCfMNbBDOFw1BdlGTcvNvTVQsxtrX3RF2
'' SIG '' Wh8RfEZsaUGAccoWcGNa6LbiEvoHzdnqvoZAE94qRp/P
'' SIG '' ypg8A7cwG537l4wKYHmasIHGCfKQyfsv8VOqLsyc9Qb3
'' SIG '' uU04oZIgO8ELEHuketGZPXT3Tc8NDCuZ4kc7kGQLeBiP
'' SIG '' ehYY4ZVFnFGTgpL/yVzPzhrv64EqZWMHZjy883w7V8rs
'' SIG '' vxglOSOJdPIOoon18qTIKGJJHHjgAM+L8dcdATp2VnyN
'' SIG '' 30sKjVL6De53E0/jAeFab39UAaaYwQEFLr7ounghtDAl
'' SIG '' TQIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFJnyJ4Bc2RGZ
'' SIG '' T5IwzlZbgUgw2mpxMB8GA1UdIwQYMBaAFJ+nFV0AXmJd
'' SIG '' g/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCGTmh0
'' SIG '' dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3Js
'' SIG '' L01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAy
'' SIG '' MDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4wXAYIKwYB
'' SIG '' BQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
'' SIG '' a2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFt
'' SIG '' cCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQC
'' SIG '' MAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0P
'' SIG '' AQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4ICAQDcR7bt
'' SIG '' xcyGm2g21qrMHSgZQISl0QjfuQkjIr9k2GuItkLliJvv
'' SIG '' faYsAIQ4QA326qK9c8i4veWOhkJ7yFlIHXgu6C9WbWcn
'' SIG '' vds2CvhCH8GGZoUvgh+Ip3wM1L7HB2Rd8JayVHz1CAxl
'' SIG '' T9JQmFbHvZoLrxtHapGOGskDxBzrybm4GWWjnYPzfHSJ
'' SIG '' 3enxnjnPtA6Bswfi4njmydkNALRLd1zd4l/AqevnWU1/
'' SIG '' McBPy74UcD6W//pyrITu01br3p8HU8Kgfy0+gjT2hJcB
'' SIG '' XisSq6kUzzGx3oPovipwS38JoRF7DINrNUF+ySMX70/e
'' SIG '' pndHojI4jBDtti2zs5izDXdyyDaMAJ0QQCbV/t/3t/dA
'' SIG '' fbDBjB6fmtVfoYLOtgKKQZdKf9NJYt9AzecBEOSH9+WZ
'' SIG '' O2/0+qRMeqyVA2ArYu8wm4pIyk2pwZznPfcxjJXo+V/n
'' SIG '' wv5ORMVAqzrN/1cxkQmbeS71UEnVqqv0DM0xJopuLG8w
'' SIG '' EivYphJIzbWWcrwtQrFHA9b6BZLZXeJijIxPrgxFdyHX
'' SIG '' Q/g60ZPeJ1czT0rmV3sH1Tp1x0nqhu8TN1e35dmi+L9T
'' SIG '' oS9vicDtU8dwdIqztTvamzXSZN+eW57XdUUlSoDNtihQ
'' SIG '' R56C+ybO6UYQYmiplU0BqDm/o9UGu6vnIsRqOPFYfZN+
'' SIG '' QQ7CUvwy6FxUjw5eJjCCB3EwggVZoAMCAQICEzMAAAAV
'' SIG '' xedrngKbSZkAAAAAABUwDQYJKoZIhvcNAQELBQAwgYgx
'' SIG '' CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
'' SIG '' MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
'' SIG '' b3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jv
'' SIG '' c29mdCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAy
'' SIG '' MDEwMB4XDTIxMDkzMDE4MjIyNVoXDTMwMDkzMDE4MzIy
'' SIG '' NVowfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
'' SIG '' bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
'' SIG '' FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMd
'' SIG '' TWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwggIi
'' SIG '' MA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDk4aZM
'' SIG '' 57RyIQt5osvXJHm9DtWC0/3unAcH0qlsTnXIyjVX9gF/
'' SIG '' bErg4r25PhdgM/9cT8dm95VTcVrifkpa/rg2Z4VGIwy1
'' SIG '' jRPPdzLAEBjoYH1qUoNEt6aORmsHFPPFdvWGUNzBRMhx
'' SIG '' XFExN6AKOG6N7dcP2CZTfDlhAnrEqv1yaa8dq6z2Nr41
'' SIG '' JmTamDu6GnszrYBbfowQHJ1S/rboYiXcag/PXfT+jlPP
'' SIG '' 1uyFVk3v3byNpOORj7I5LFGc6XBpDco2LXCOMcg1KL3j
'' SIG '' tIckw+DJj361VI/c+gVVmG1oO5pGve2krnopN6zL64NF
'' SIG '' 50ZuyjLVwIYwXE8s4mKyzbnijYjklqwBSru+cakXW2dg
'' SIG '' 3viSkR4dPf0gz3N9QZpGdc3EXzTdEonW/aUgfX782Z5F
'' SIG '' 37ZyL9t9X4C626p+Nuw2TPYrbqgSUei/BQOj0XOmTTd0
'' SIG '' lBw0gg/wEPK3Rxjtp+iZfD9M269ewvPV2HM9Q07BMzlM
'' SIG '' jgK8QmguEOqEUUbi0b1qGFphAXPKZ6Je1yh2AuIzGHLX
'' SIG '' pyDwwvoSCtdjbwzJNmSLW6CmgyFdXzB0kZSU2LlQ+QuJ
'' SIG '' YfM2BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6r1AFemzF
'' SIG '' ER1y7435UsSFF5PAPBXbGjfHCBUYP3irRbb1Hode2o+e
'' SIG '' FnJpxq57t7c+auIurQIDAQABo4IB3TCCAdkwEgYJKwYB
'' SIG '' BAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3FQIEFgQUKqdS
'' SIG '' /mTEmr6CkTxGNSnPEP8vBO4wHQYDVR0OBBYEFJ+nFV0A
'' SIG '' XmJdg/Tl0mWnG1M1GelyMFwGA1UdIARVMFMwUQYMKwYB
'' SIG '' BAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93
'' SIG '' d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBv
'' SIG '' c2l0b3J5Lmh0bTATBgNVHSUEDDAKBggrBgEFBQcDCDAZ
'' SIG '' BgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8E
'' SIG '' BAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAW
'' SIG '' gBTV9lbLj+iiXGJo0T2UkFvXzpoYxDBWBgNVHR8ETzBN
'' SIG '' MEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20v
'' SIG '' cGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAx
'' SIG '' MC0wNi0yMy5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsG
'' SIG '' AQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20v
'' SIG '' cGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIz
'' SIG '' LmNydDANBgkqhkiG9w0BAQsFAAOCAgEAnVV9/Cqt4Swf
'' SIG '' ZwExJFvhnnJL/Klv6lwUtj5OR2R4sQaTlz0xM7U518Jx
'' SIG '' Nj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu6WZnOlNN3Zi6
'' SIG '' th542DYunKmCVgADsAW+iehp4LoJ7nvfam++Kctu2D9I
'' SIG '' dQHZGN5tggz1bSNU5HhTdSRXud2f8449xvNo32X2pFaq
'' SIG '' 95W2KFUn0CS9QKC/GbYSEhFdPSfgQJY4rPf5KYnDvBew
'' SIG '' VIVCs/wMnosZiefwC2qBwoEZQhlSdYo2wh3DYXMuLGt7
'' SIG '' bj8sCXgU6ZGyqVvfSaN0DLzskYDSPeZKPmY7T7uG+jIa
'' SIG '' 2Zb0j/aRAfbOxnT99kxybxCrdTDFNLB62FD+CljdQDzH
'' SIG '' VG2dY3RILLFORy3BFARxv2T5JL5zbcqOCb2zAVdJVGTZ
'' SIG '' c9d/HltEAY5aGZFrDZ+kKNxnGSgkujhLmm77IVRrakUR
'' SIG '' R6nxt67I6IleT53S0Ex2tVdUCbFpAUR+fKFhbHP+Crvs
'' SIG '' QWY9af3LwUFJfn6Tvsv4O+S3Fb+0zj6lMVGEvL8CwYKi
'' SIG '' excdFYmNcP7ntdAoGokLjzbaukz5m/8K6TT4JDVnK+AN
'' SIG '' uOaMmdbhIurwJ0I9JZTmdHRbatGePu1+oDEzfbzL6Xu/
'' SIG '' OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZqELQd
'' SIG '' VTNYs6FwZvKhggLUMIICPQIBATCCAQChgdikgdUwgdIx
'' SIG '' CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
'' SIG '' MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
'' SIG '' b3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jv
'' SIG '' c29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEm
'' SIG '' MCQGA1UECxMdVGhhbGVzIFRTUyBFU046MDg0Mi00QkU2
'' SIG '' LUMyOUExJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0
'' SIG '' YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMVAI4SfhHs
'' SIG '' kkX59igjbI5/XBfQFEk6oIGDMIGApH4wfDELMAkGA1UE
'' SIG '' BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
'' SIG '' BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
'' SIG '' b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
'' SIG '' bWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcNAQEFBQAC
'' SIG '' BQDowfprMCIYDzIwMjMwOTMwMDkzNzQ3WhgPMjAyMzEw
'' SIG '' MDEwOTM3NDdaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIF
'' SIG '' AOjB+msCAQAwBwIBAAICChMwBwIBAAICE64wCgIFAOjD
'' SIG '' S+sCAQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYKKwYBBAGE
'' SIG '' WQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkq
'' SIG '' hkiG9w0BAQUFAAOBgQCrop6AzENSRpL1mn5CwWJs4SoW
'' SIG '' TEtjGcypeEDs6R+hKgSuooHuHo+FfgKpNfQgqO4hUhTf
'' SIG '' yV0XuxFCLIG8HV6ms+A9drWe40EdkjQ8Yrl+cBgEr0Mv
'' SIG '' f+glEp9h8227/+P2MR1FKIYGgFNWA/A+18YHT8sYqlJY
'' SIG '' A3602RR0ubD5sTGCBA0wggQJAgEBMIGTMHwxCzAJBgNV
'' SIG '' BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
'' SIG '' VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
'' SIG '' Q29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBU
'' SIG '' aW1lLVN0YW1wIFBDQSAyMDEwAhMzAAABsm5AA39uqZSS
'' SIG '' AAEAAAGyMA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG
'' SIG '' 9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkE
'' SIG '' MSIEIHr4A8K9aHy3ye9H+a1vOZVCXd31X57da312NMj2
'' SIG '' TOPnMIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQg
'' SIG '' U3jOPOfhPreDxFYnlKBSl+z1ci6P587vobSTwhtOPjUw
'' SIG '' gZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
'' SIG '' V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
'' SIG '' A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
'' SIG '' VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
'' SIG '' MAITMwAAAbJuQAN/bqmUkgABAAABsjAiBCAwgvUzct85
'' SIG '' cyfRHNrKQ7NBbeEJnv5hP/tfGhewH8J0RjANBgkqhkiG
'' SIG '' 9w0BAQsFAASCAgDCxOQkABJEIul4cRdRKTvZfVx2/B7C
'' SIG '' LEA7R3N0yipcGx462lZ75OIwnjfT6M+VenXThFGjK704
'' SIG '' X8CjcHFa7txBqyuXyaSd7R31PIS+UVOt7KfVsdnjSYot
'' SIG '' 7E/SCnSrX/QtYWeFq4WJjetTwMq0zFuLXkAL6z2PqWfr
'' SIG '' SMFuEtKPhbZXkgZw5wAROvalVayKvkGxTVn0WW7sGRL+
'' SIG '' FVuf+JDulJvneruO01NiRGCIlfMaL+86aYEK/tSCWrM3
'' SIG '' M1WB4ankB6NQqpUU4ejcFcYIXQe5LGeDonIzMmtgrPdf
'' SIG '' Rxl1GfJOKKtmd7vQRUi2z3cVEMfIV4/BmiZGWWK1ZxNK
'' SIG '' oMP+fTvyKO/ZHt/jCDyfql37KFamO6zcfzWn00wJDj70
'' SIG '' QUVNl+nE3AWqfNSJNPCKIeGqmw0/1c2NWYNPekzczLMG
'' SIG '' GUi6ogSrwuRUeCjhMOD23l+88GgABHmlJY+I/9OnOJO5
'' SIG '' PGuOK5KlzIege9jhGgO4FXgVMLw8mC2CIXQExZXcRzxd
'' SIG '' GCRHr9cnPLXN1GFFIPWnN8T1g+TczycH+56kpCSra+yE
'' SIG '' /Wr/iV/zcyLlPWEp52oqpdtcd7IUQxZDyvPGHu4EU4FB
'' SIG '' Jpb+rNN1HqgpdWsVOR/M57pw9WpORU8E5lR9NI9b3jz0
'' SIG '' M5t7Qkx1v+9TbgUU7qr8vAIux24zqA5swFSqQQ==
'' SIG '' End signature block
