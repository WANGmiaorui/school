' Windows Installer utility to applay a transform to an installer database
' For use with Windows Scripting Host, CScript.exe or WScript.exe
' Copyright (c) Microsoft Corporation. All rights reserved.
' Demonstrates use of Database.ApplyTransform and MsiDatabaseApplyTransform
'
Option Explicit

' Error conditions that may be suppressed when applying transforms
Const msiTransformErrorAddExistingRow         = 1 'Adding a row that already exists. 
Const msiTransformErrorDeleteNonExistingRow   = 2 'Deleting a row that doesn't exist. 
Const msiTransformErrorAddExistingTable       = 4 'Adding a table that already exists. 
Const msiTransformErrorDeleteNonExistingTable = 8 'Deleting a table that doesn't exist. 
Const msiTransformErrorUpdateNonExistingRow  = 16 'Updating a row that doesn't exist. 
Const msiTransformErrorChangeCodePage       = 256 'Transform and database code pages do not match 

Const msiOpenDatabaseModeReadOnly     = 0
Const msiOpenDatabaseModeTransact     = 1
Const msiOpenDatabaseModeCreate       = 3

If (Wscript.Arguments.Count < 2) Then
	Wscript.Echo "Windows Installer database tranform application utility" &_
		vbNewLine & " 1st argument is the path to an installer database" &_
		vbNewLine & " 2nd argument is the path to the transform file to apply" &_
		vbNewLine & " 3rd argument is optional set of error conditions to suppress:" &_
		vbNewLine & "     1 = adding a row that already exists" &_
		vbNewLine & "     2 = deleting a row that doesn't exist" &_
		vbNewLine & "     4 = adding a table that already exists" &_
		vbNewLine & "     8 = deleting a table that doesn't exist" &_
		vbNewLine & "    16 = updating a row that doesn't exist" &_
		vbNewLine & "   256 = mismatch of database and transform codepages" &_
		vbNewLine &_
		vbNewLine & "Copyright (C) Microsoft Corporation.  All rights reserved."
	Wscript.Quit 1
End If

' Connect to Windows Installer object
On Error Resume Next
Dim installer : Set installer = Nothing
Set installer = Wscript.CreateObject("WindowsInstaller.Installer") : CheckError

' Open database and apply transform
Dim database : Set database = installer.OpenDatabase(Wscript.Arguments(0), msiOpenDatabaseModeTransact) : CheckError
Dim errorConditions:errorConditions = 0
If Wscript.Arguments.Count >= 3 Then errorConditions = CLng(Wscript.Arguments(2))
Database.ApplyTransform Wscript.Arguments(1), errorConditions : CheckError
Database.Commit : CheckError

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
'' SIG '' MIImHwYJKoZIhvcNAQcCoIImEDCCJgwCAQExDzANBglg
'' SIG '' hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
'' SIG '' BgEEAYI3AgEeMCQCAQEEEE7wKRaZJ7VNj+Ws4Q8X66sC
'' SIG '' AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
'' SIG '' ocXRzPIBsTOs40BugTYvo1tESbFrFB3U6AbYVQhStNmg
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
'' SIG '' IgQgLQn6o9kUODATKIS+smjNPFWNt2x3Bw5gzkZaBTK4
'' SIG '' sbgwPAYKKwYBBAGCNwoDHDEuDCxzUFk3eFBCN2hUNWc1
'' SIG '' SEhyWXQ4ckRMU005VnVaUnVXWmFlZjJlMjJSczU0PTBa
'' SIG '' BgorBgEEAYI3AgEMMUwwSqAkgCIATQBpAGMAcgBvAHMA
'' SIG '' bwBmAHQAIABXAGkAbgBkAG8AdwBzoSKAIGh0dHA6Ly93
'' SIG '' d3cubWljcm9zb2Z0LmNvbS93aW5kb3dzMA0GCSqGSIb3
'' SIG '' DQEBAQUABIIBAIWPRvvczPoQbLAbeCQNIVtwE+VLIk6C
'' SIG '' GNPQIffnfvzRSeqfc5sFmdP3doIES0xB4h5Q6+4TcXJ9
'' SIG '' jCxs2QRwoncq9L3kBbaasHbFro4pUGDMgZe/fy0RtYTw
'' SIG '' L7kzvHYX7KTAxAGVcg1j6VtjzeRC38raTIkAbXib34xL
'' SIG '' PHpcARt18iQk4VFq5mgw0j2+aKIpAf6Dqd5PDAAobYb+
'' SIG '' Vih3dz7udE/cDqkYh0PNwFt9CojAQpMnKL31e7tXeo3t
'' SIG '' e4t5BW+a2EKIP0ro5XfVxP6P0Pu/U/ggq6jEyVFJV6Hj
'' SIG '' lkiuvPnjcVaBG+2lTCIFDcTgaLovMDwy60/PJ7qpM4ui
'' SIG '' TdahghcpMIIXJQYKKwYBBAGCNwMDATGCFxUwghcRBgkq
'' SIG '' hkiG9w0BBwKgghcCMIIW/gIBAzEPMA0GCWCGSAFlAwQC
'' SIG '' AQUAMIIBWQYLKoZIhvcNAQkQAQSgggFIBIIBRDCCAUAC
'' SIG '' AQEGCisGAQQBhFkKAwEwMTANBglghkgBZQMEAgEFAAQg
'' SIG '' /d0oY6p4537EjQsXmQvPXLZfgKPWCxehtTI42cKdEcsC
'' SIG '' BmULqjiWORgTMjAyMzA5MzAxMDE0MjIuNDI0WjAEgAIB
'' SIG '' 9KCB2KSB1TCB0jELMAkGA1UEBhMCVVMxEzARBgNVBAgT
'' SIG '' Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
'' SIG '' BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsG
'' SIG '' A1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9u
'' SIG '' cyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVT
'' SIG '' TjpEMDgyLTRCRkQtRUVCQTElMCMGA1UEAxMcTWljcm9z
'' SIG '' b2Z0IFRpbWUtU3RhbXAgU2VydmljZaCCEXgwggcnMIIF
'' SIG '' D6ADAgECAhMzAAABuh8/GffBdb18AAEAAAG6MA0GCSqG
'' SIG '' SIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
'' SIG '' EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
'' SIG '' HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
'' SIG '' BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAy
'' SIG '' MDEwMB4XDTIyMDkyMDIwMjIxOVoXDTIzMTIxNDIwMjIx
'' SIG '' OVowgdIxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
'' SIG '' aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
'' SIG '' ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsT
'' SIG '' JE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGlt
'' SIG '' aXRlZDEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046RDA4
'' SIG '' Mi00QkZELUVFQkExJTAjBgNVBAMTHE1pY3Jvc29mdCBU
'' SIG '' aW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
'' SIG '' AQUAA4ICDwAwggIKAoICAQCIThWDM5I1gBPVFZ1xfYUR
'' SIG '' r9MQUcXPiOR7t4cVRV8it7t/MbrBG9KS5MI4BrQ7Giy2
'' SIG '' 65TMal97RW/9wYBDxAty9MF++oA/Mx7fsIgVeZquQVqK
'' SIG '' dvaka4DCSigj3KUJ0o7PQf+FzBRb66XT4nGQ7+NxS4M/
'' SIG '' Xx6jKtCyQ8OSQBxg0t9EwmPTheNz+HeOGfZROwmlUtqS
'' SIG '' TBdy+OdzFwecmCvyg24pYRET9Y8Z9spfrRgkYLiALDBt
'' SIG '' KHjoV2sPLkhjoUugAkh2/nm4tNN/DBR8qEzYSn/kmKOD
'' SIG '' qUmN8T+PrMAQUyg6GD9cB/gn8RuofX8pgSUD0GWqn5dK
'' SIG '' 4ogy45g7p0LR9Rg+uAIq+ZPSXcIaucC5kll48hVS/iA3
'' SIG '' zqXYsSen+aPjIROh+Ld9cPqa8oB5ndlB0Oue1BsehTbs
'' SIG '' 8AvkqQB5le+jGWGnOLgIU4Gj+Oz9nnktaHJL8oZfcmvv
'' SIG '' Scz3zJLoN8Xr8xQA1oi0TK9OuhDFe6tyUkQLJwkvRkNP
'' SIG '' AuBSj20ofDjzN9y54NH38QDZxwAF/wxO3B3Me5fY2ldw
'' SIG '' HJpI+6Koq+BIdruWMcImkxN+12jLpl9hEtzyeTQWl6u2
'' SIG '' HSycMkg/lPaZP7ZeHUNbfxHqO7g05YjskJA/CO+MaVQd
'' SIG '' E99f+uyh35AZBVb8usMnttVfvSAvLkg/vkYA90cLTdpB
'' SIG '' PwIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFIpi5vEDHiWt
'' SIG '' uY/TFnmmyNh0r2TlMB8GA1UdIwQYMBaAFJ+nFV0AXmJd
'' SIG '' g/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCGTmh0
'' SIG '' dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3Js
'' SIG '' L01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAy
'' SIG '' MDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4wXAYIKwYB
'' SIG '' BQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
'' SIG '' a2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFt
'' SIG '' cCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQC
'' SIG '' MAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0P
'' SIG '' AQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4ICAQBfyPFO
'' SIG '' oW2Ybw3J/ep2erZG0hI1z7ymesK6Gl3ILLRIaYGnhMJX
'' SIG '' i7j1xy8xFrbibmM+HrIZoV6ha+PZWwHF+Ujef3BLD9MX
'' SIG '' RWsm+1OT/eCWXdx4xb6VkTaDQYRd0gzNAN/LCNh/oY4Q
'' SIG '' f1X19V3GYnotUTjwMgh3AYBy8kKxLupp29x4WyHa/IdE
'' SIG '' 2u1hcpRoS0hVusJsyrrD+mjpZpxkmnOTTH5WupUb02B3
'' SIG '' dvK22woH0ptUYU4KGY/lvA0yrYhDMLmxyd5iDypqPMbS
'' SIG '' SFlz516ulyoJXay+XMpyzF/9Fl+uTrlmx1eRkxC3X1rx
'' SIG '' ldw2maxz1EP1D99Snqm9sY1Qm99C1cIG4yL2Eu+zdXQE
'' SIG '' ZDfBf/aSdYDuCL2VjMMjJSihRqIztX9cG40lnAP+e7bH
'' SIG '' Prdm5azFoEjR4Mw69NY2z0rqUY8tx7fWWbOMTdNnol93
'' SIG '' htveza7QupeHP4M59tHqqKlsf7h1sZk4AdBeaLAbkxzn
'' SIG '' u+w8hANLoQKxpYCj/dY4IYLfzlR6B+uYNEKgrYGft+pp
'' SIG '' whIOiDoRaBawnNHyRRlZm9fte4BHvh0TDO4wZODtOifi
'' SIG '' KKBayN3tzyYz60Gp6PzMhN4fswLgVhjA0XFJTSgg1O3R
'' SIG '' p1rx911sC6wgiHM/txsEVDLC7A3T1tjlb+79XhCYjEiG
'' SIG '' dj/jOy9tEPGs51ODgDCCB3EwggVZoAMCAQICEzMAAAAV
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
'' SIG '' MCQGA1UECxMdVGhhbGVzIFRTUyBFU046RDA4Mi00QkZE
'' SIG '' LUVFQkExJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0
'' SIG '' YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMVAHajR3td
'' SIG '' d4AifO2mSBmuUAVKiMLyoIGDMIGApH4wfDELMAkGA1UE
'' SIG '' BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
'' SIG '' BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
'' SIG '' b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
'' SIG '' bWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcNAQEFBQAC
'' SIG '' BQDowVztMCIYDzIwMjMwOTI5MjIyNTQ5WhgPMjAyMzA5
'' SIG '' MzAyMjI1NDlaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIF
'' SIG '' AOjBXO0CAQAwBwIBAAICAmQwBwIBAAICEaYwCgIFAOjC
'' SIG '' rm0CAQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYKKwYBBAGE
'' SIG '' WQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkq
'' SIG '' hkiG9w0BAQUFAAOBgQBapQ1PYPVC51zkd+6Gj/JwnHrv
'' SIG '' L5X8iLpEsBkPR935d/OHxlj2LAUuXVE3OZPUzuKKT989
'' SIG '' b+qjBzlajGPkzjHlNurgxOeTpjd6PUcFB5TrKJB4dSeJ
'' SIG '' VZMveK/WHkzFvGLEhelbvsEWqfdooUl/eo+ZKsW9FYrM
'' SIG '' ice7Ms56CqRQVzGCBA0wggQJAgEBMIGTMHwxCzAJBgNV
'' SIG '' BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
'' SIG '' VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
'' SIG '' Q29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBU
'' SIG '' aW1lLVN0YW1wIFBDQSAyMDEwAhMzAAABuh8/GffBdb18
'' SIG '' AAEAAAG6MA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG
'' SIG '' 9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkE
'' SIG '' MSIEID0Gy2EA5RzPcos5vcWbVcIvHXVfzazFFvi3lg4q
'' SIG '' iPqeMIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQg
'' SIG '' KVW9PDNucPrWBlrJpRradYMtZz3Kln6oDBd55VmFcwUw
'' SIG '' gZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
'' SIG '' V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
'' SIG '' A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
'' SIG '' VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
'' SIG '' MAITMwAAAbofPxn3wXW9fAABAAABujAiBCDJEqCbReGe
'' SIG '' zBw0ar6aEpa22sUGTczU+DZTI4Z1PhhmgTANBgkqhkiG
'' SIG '' 9w0BAQsFAASCAgA+aKTemep8hcDSNFvvqvjhItW/fIna
'' SIG '' iR7ku0KKNxFTV2yJx7HMYWOBk8n9Sj9K/I3scfZz5Anf
'' SIG '' seG5LDMcrGxqmht6a5eLgoh8tCoLZno3qkXJFm/CZKjp
'' SIG '' XnCqOhmAW2uxso/38Uxny/vG7sGzWy7/eJ0286C1MvZf
'' SIG '' D24RB3GVLOHt1/NCALH3UydByHuqBa+Whc0CoUjZjk2y
'' SIG '' WO20t5JoUNg8KlNn+B0SpSHd4KRHPclesJA2IVh3WVH1
'' SIG '' P7CJQ859Q2aNHRyEW6xkT8GPUETvJv+A5D74Y8mEtU0P
'' SIG '' Je1f8GfteKHzEDmDG7+rmGuZsK3ivIHp8eixkoUEyXRR
'' SIG '' P5zSiedz0Ubr2w7T+Zx74ICVFoWpFz6GU4NKf+GEzFds
'' SIG '' JvbYhHBA40UJOpm2sfEemrPm8L+gqdpQ0MI2ER8+VBXw
'' SIG '' AP/waRhBrpoIO388dJk3VWR6Jqe4b0btwxOyF+oYJLPW
'' SIG '' 57uS8K71Om8h9XIR6+r9/ZQLPquwLcT5kMkLjCIXTRNI
'' SIG '' v+hbbdmNFOuIpa4VD50RpzJr4VbJIEsscSX7AwbN4dGD
'' SIG '' vgmvRjW2ghvKsWV2jhWLM/PTwlf7hLKV1nO7yjY2b+oc
'' SIG '' rRZUiwu8xEyTc2s74SF9nrlScbRL6m1pA/NchOSmG9ru
'' SIG '' vRUuP05bOKvcVs1WYLmPJAeeFeX7HgZtTWbKNw==
'' SIG '' End signature block
