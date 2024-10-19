' Windows Installer database table import for use with Windows Scripting Host
' Copyright (c) Microsoft Corporation. All rights reserved.
' Demonstrates the use of the Database.Import method and MsiDatabaseImport API
'
Option Explicit

Const msiOpenDatabaseModeReadOnly     = 0
Const msiOpenDatabaseModeTransact     = 1
Const msiOpenDatabaseModeCreate       = 3
Const ForAppending = 8
Const ForReading = 1
Const ForWriting = 2
Const TristateTrue = -1

Dim argCount:argCount = Wscript.Arguments.Count
Dim iArg:iArg = 0
If (argCount < 3) Then
	Wscript.Echo "Windows Installer database table import utility" &_
		vbNewLine & " 1st argument is the path to MSI database (installer package)" &_
		vbNewLine & " 2nd argument is the path to folder containing the imported files" &_
		vbNewLine & " Subseqent arguments are names of archive files to import" &_
		vbNewLine & " Wildcards, such as *.idt, can be used to import multiple files" &_
		vbNewLine & " Specify /c or -c anywhere before file list to create new database" &_
		vbNewLine &_
		vbNewLine & "Copyright (C) Microsoft Corporation.  All rights reserved."
	Wscript.Quit 1
End If

' Connect to Windows Installer object
On Error Resume Next
Dim installer : Set installer = Nothing
Set installer = Wscript.CreateObject("WindowsInstaller.Installer") : CheckError

Dim openMode:openMode = msiOpenDatabaseModeTransact
Dim databasePath:databasePath = NextArgument
Dim folder:folder = NextArgument

Dim WshShell, fileSys
Set WshShell = Wscript.CreateObject("Wscript.Shell") : CheckError
Set fileSys = CreateObject("Scripting.FileSystemObject") : CheckError

' Open database and process list of files
Dim database, table
Set database = installer.OpenDatabase(databasePath, openMode) : CheckError
While iArg < argCount
	table = NextArgument
	' Check file name for wildcard specification
	If (InStr(1,table,"*",vbTextCompare) <> 0) Or (InStr(1,table,"?",vbTextCompare) <> 0) Then
		' Obtain list of files matching wildcard specification
		Dim file, tempFilePath
		tempFilePath = WshShell.ExpandEnvironmentStrings("%TEMP%") & "\dir.tmp"
		WshShell.Run "cmd.exe /U /c dir /b " & folder & "\" & table & ">" & tempFilePath, 0, True : CheckError
		Set file = fileSys.OpenTextFile(tempFilePath, ForReading, False, TristateTrue) : CheckError
		' Import each file in directory list
		Do While file.AtEndOfStream <> True
			table = file.ReadLine
			database.Import folder, table : CheckError
		Loop
		file.Close
		fileSys.DeleteFile(tempFilePath)
	Else
		database.Import folder, table : CheckError
	End If
Wend
database.Commit 'commit changes if no import errors
Wscript.Quit 0

Function NextArgument
	Dim arg, chFlag
	Do
		arg = Wscript.Arguments(iArg)
		iArg = iArg + 1
		chFlag = AscW(arg)
		If (chFlag = AscW("/")) Or (chFlag = AscW("-")) Then
			chFlag = UCase(Right(arg, Len(arg)-1))
			If chFlag = "C" Then 
				openMode = msiOpenDatabaseModeCreate
			Else
				Wscript.Echo "Invalid option flag:", arg : Wscript.Quit 1
			End If
		Else
			Exit Do
		End If
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
	Wscript.Echo message
	Wscript.Quit 2
End Sub

'' SIG '' Begin signature block
'' SIG '' MIImHwYJKoZIhvcNAQcCoIImEDCCJgwCAQExDzANBglg
'' SIG '' hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
'' SIG '' BgEEAYI3AgEeMCQCAQEEEE7wKRaZJ7VNj+Ws4Q8X66sC
'' SIG '' AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
'' SIG '' URtattTTdos4rg+Jt96T7zPQ8Pzvx4qAdD0rt5bwgTmg
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
'' SIG '' IgQg7eWUfGzAc/5A7zipkVLl2TNPbIlzesQq/vdNLq54
'' SIG '' wLAwPAYKKwYBBAGCNwoDHDEuDCxzUFk3eFBCN2hUNWc1
'' SIG '' SEhyWXQ4ckRMU005VnVaUnVXWmFlZjJlMjJSczU0PTBa
'' SIG '' BgorBgEEAYI3AgEMMUwwSqAkgCIATQBpAGMAcgBvAHMA
'' SIG '' bwBmAHQAIABXAGkAbgBkAG8AdwBzoSKAIGh0dHA6Ly93
'' SIG '' d3cubWljcm9zb2Z0LmNvbS93aW5kb3dzMA0GCSqGSIb3
'' SIG '' DQEBAQUABIIBADIdIBTaDRermU69Zc/ECdetF3hHxAZm
'' SIG '' +Qoi845mzEDmuRUpZbHeVw+SBbPP8g2LFO+Tk87Xf4Bs
'' SIG '' 2OKO6HtZam4b1izgSozpAtRLPkU2zyN+DADEbNNdW54d
'' SIG '' 1VESzxK7W/CLKkoRlD0i1LAr1+scVoBIPaSlXlrfY3AC
'' SIG '' 0hF//ee0lFlhZvOtCp3pQnPNepb94aFSfbYMG9N8zIy7
'' SIG '' q8e2Q9LJLH0VUfCn/P7KIK4hvFJzIa/BGxqQLRmH/NfW
'' SIG '' UzBVd6KLmd1vPyKOrOmKK8u1R7AX5+AV8U/yVLsEbE/5
'' SIG '' IjU8h5mRKJd3+kTDzcIfybFL0RKETKC9hG2VvPHwXOKv
'' SIG '' yM6hghcpMIIXJQYKKwYBBAGCNwMDATGCFxUwghcRBgkq
'' SIG '' hkiG9w0BBwKgghcCMIIW/gIBAzEPMA0GCWCGSAFlAwQC
'' SIG '' AQUAMIIBWQYLKoZIhvcNAQkQAQSgggFIBIIBRDCCAUAC
'' SIG '' AQEGCisGAQQBhFkKAwEwMTANBglghkgBZQMEAgEFAAQg
'' SIG '' ZXmryYdRSI57dKySAl8FJZB7byB/QDYVS8Nh2E1EU0QC
'' SIG '' BmULlaogaRgTMjAyMzA5MzAxMDE0MjEuOTEzWjAEgAIB
'' SIG '' 9KCB2KSB1TCB0jELMAkGA1UEBhMCVVMxEzARBgNVBAgT
'' SIG '' Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
'' SIG '' BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsG
'' SIG '' A1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9u
'' SIG '' cyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVT
'' SIG '' TjpGQzQxLTRCRDQtRDIyMDElMCMGA1UEAxMcTWljcm9z
'' SIG '' b2Z0IFRpbWUtU3RhbXAgU2VydmljZaCCEXgwggcnMIIF
'' SIG '' D6ADAgECAhMzAAABufYADWVUT7wDAAEAAAG5MA0GCSqG
'' SIG '' SIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
'' SIG '' EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
'' SIG '' HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
'' SIG '' BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAy
'' SIG '' MDEwMB4XDTIyMDkyMDIwMjIxN1oXDTIzMTIxNDIwMjIx
'' SIG '' N1owgdIxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
'' SIG '' aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
'' SIG '' ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsT
'' SIG '' JE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGlt
'' SIG '' aXRlZDEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046RkM0
'' SIG '' MS00QkQ0LUQyMjAxJTAjBgNVBAMTHE1pY3Jvc29mdCBU
'' SIG '' aW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
'' SIG '' AQUAA4ICDwAwggIKAoICAQDjST7JYfUWx8kBAm1CCDcT
'' SIG '' BebkJMjdO1SEoSE17my6VpwDYAQi7wnCZe6P9hxzkZ7E
'' SIG '' XJkiDSf6nJQJiyKzo52J626HAJ4sYjBFwvmtbGfOKsWF
'' SIG '' rRFWO1WMNCwnM2PvOlP/LIYMarGnsyqVq4jznKVdUofE
'' SIG '' rDsX99Mju475XfyAQN0+pRzNqU/x0Y1pP6/bssdEOGrc
'' SIG '' dJpC1WEvcuef6E5SixNNIe/dkvpmmnQHct1YE8HosKBD
'' SIG '' lw+/OcL94fn8B/8E0LQvZYQMYTDuKfjj/fPPFsZG5ega
'' SIG '' kVl7neeEU86qdla/snp9UNQOrpsjAe16tLJyGBuQdQHH
'' SIG '' OFICZT0P2YjJKoMUDRQlkL89BvaC4Ejw/CstAJF9tj3A
'' SIG '' zm6D7jU+EXHlj19FFWVLF/SFILO0BeNR4kEsBHjjhxsq
'' SIG '' 30HZkrJQE625h/9fDOUK7EzOSSDY3LfRuNsajfFRfWfF
'' SIG '' johjIzW75aXBJpsrGJeUMoaxA6BZ0E1O2xaw9yV9HyH7
'' SIG '' tbGy1ngal8G6eGfMgAk7aYStlW8zr4uL3NEQpkTc72EE
'' SIG '' Nj42ezWk1xOBrt74IACfq7c1EwHyaLbzkqnDIDcC2WtW
'' SIG '' PhE/5W9Fco62MBbh7YNEFskIz+d+dC06b9POqclVIeAN
'' SIG '' 8PzrOYUxhWYBXuWwsjJ6WNPTNMj3R2kP+eqGFLEiHMis
'' SIG '' lQIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFLewOHHbWEOa
'' SIG '' CYxNWaq0qJ6eNURSMB8GA1UdIwQYMBaAFJ+nFV0AXmJd
'' SIG '' g/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCGTmh0
'' SIG '' dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3Js
'' SIG '' L01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAy
'' SIG '' MDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4wXAYIKwYB
'' SIG '' BQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
'' SIG '' a2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFt
'' SIG '' cCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQC
'' SIG '' MAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0P
'' SIG '' AQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4ICAQDN3Gez
'' SIG '' RVB0TLCys45e6yTyJL+6CfrPZJLrdIWYn/VkretEs2Bl
'' SIG '' C6dc5nT6nPsPHh05Ial9Bigqdk06kswVwYcBzpvPqeoV
'' SIG '' MTZQ3sBjGVKLPedmk125QE9zigZ31QS0MlGr60o7iRmQ
'' SIG '' Ft9HDWN641Q1JRg/lcoEB8kmg2r4iUGyuv+n0L1FBaKi
'' SIG '' JN5XRn45wLZ3m7FZaoellmplXOQGXaVkdY0szf6MSmKn
'' SIG '' NQRuEscZT7XH6wHQc/3FOG8VV6gAH9NjWbHLyTaUZzgC
'' SIG '' 3+ZFaNh7qSVwrJPU8z+TzVtrE0t05sISEJj8a9BNFKjq
'' SIG '' I1KwSVDoWyEwMXJ0mvyDJbi9R10bS0GSPsbNnkbbjzlL
'' SIG '' ClFu9f9WHqrGAixy77vNnHg1UELz+xhxBJKdpBI4qH24
'' SIG '' 2BKwaNoghGscXl+GfR7wIAODLEJG5+nuBBUH9d7D/ip9
'' SIG '' 14DCLyW6iyXhXEI2vklHjl7uXH5MXtBs0zaI3ciMM2h5
'' SIG '' YTn5VUWTa8XntwfsmcHdyRwyL7+9bkiP0iM87fXFNhsh
'' SIG '' 0FasQUq0bSlulvFcO86Vb6FbCL95Y8YPuzYhkpV19bO8
'' SIG '' 2wTQzFI/Tp8zpRyv95qzlPGBLkX+kcGpFuVAnhmpsuTI
'' SIG '' irtmLsiohgQr+DhoT7LTXuwC5BDofAV9dreJ7bmLvoMP
'' SIG '' S+sgj2NI1mGkLcwD/TCCB3EwggVZoAMCAQICEzMAAAAV
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
'' SIG '' MCQGA1UECxMdVGhhbGVzIFRTUyBFU046RkM0MS00QkQ0
'' SIG '' LUQyMjAxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0
'' SIG '' YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMVAMdiHhh4
'' SIG '' ZOfDEJM80lpJxnC434E6oIGDMIGApH4wfDELMAkGA1UE
'' SIG '' BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
'' SIG '' BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
'' SIG '' b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
'' SIG '' bWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcNAQEFBQAC
'' SIG '' BQDowfCnMCIYDzIwMjMwOTMwMDg1NjA3WhgPMjAyMzEw
'' SIG '' MDEwODU2MDdaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIF
'' SIG '' AOjB8KcCAQAwBwIBAAICBE4wBwIBAAICEdowCgIFAOjD
'' SIG '' QicCAQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYKKwYBBAGE
'' SIG '' WQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkq
'' SIG '' hkiG9w0BAQUFAAOBgQAsAiKqcrRSdkYoRPp3UlwR9wBR
'' SIG '' ylq5PrrSCyffOdxjXvftNHVUuFZ+0YOsAM1A6WuLOYW3
'' SIG '' qJaajYZyLyhJ0TKXFBdhY1FkjmWnyukMhvLrE6kqm0WL
'' SIG '' srFn400On4G3U5n/jUuBKbTo1yK4OiztFTl6NAahMiQA
'' SIG '' Z1bX8144cnArZjGCBA0wggQJAgEBMIGTMHwxCzAJBgNV
'' SIG '' BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
'' SIG '' VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
'' SIG '' Q29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBU
'' SIG '' aW1lLVN0YW1wIFBDQSAyMDEwAhMzAAABufYADWVUT7wD
'' SIG '' AAEAAAG5MA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG
'' SIG '' 9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkE
'' SIG '' MSIEIFGksi167f30wL4wp83+KlKKgmC54SSfT2AwMmc8
'' SIG '' qhpJMIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQg
'' SIG '' ZOtGzvFvObkwHyVRDt719mi2kBXIHBqXcLDqIvn6D/Qw
'' SIG '' gZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
'' SIG '' V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
'' SIG '' A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
'' SIG '' VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
'' SIG '' MAITMwAAAbn2AA1lVE+8AwABAAABuTAiBCD7YW2tOd4B
'' SIG '' YenYf0JJ6ip25/W3mug37uIdjf3BwPEQ2DANBgkqhkiG
'' SIG '' 9w0BAQsFAASCAgAY/enLPrs68vAd3K588FeKh9X25eno
'' SIG '' 8MRKChg9eqHTFLajYrHQeJZKoVRypAkHyw283HxON1vo
'' SIG '' 0RqRQ1YTjUx4XQI1yDGjFKNA/X5R0IW0B8tZZSZUpG3Z
'' SIG '' 3LWjbiocaCxpFPrbfwk5zWt7PRMRqR+jX4pp9edOs9KO
'' SIG '' cETATVDlHWdbfWSkAsI/sDVj0xCFZS9ivxOAgdGoJimA
'' SIG '' 22L3A3RwLejLCqMY8HQm6ayGqWl8W20YzGwg54xCKFZS
'' SIG '' ip/CU6EhDCUllmXQvpzGfxVCNwj4rlmCh4Xs8zi0LLWf
'' SIG '' 9LV79bgQjAXj3v3TUj3QnT6h9dmvk8uoWX3DmV7woG83
'' SIG '' nI9Zmw31ysu1xvpHyuZw+NEmUpoh9Bg864P70Ohq1Urp
'' SIG '' 3leXk/K+3AhQDTJ+7Ju4mRNQxtSR+q6s+8mYun4YhIpr
'' SIG '' SfAPIe1NXe/6KnksdQe7r7RMZkRhPoSBj/L9loiiPSab
'' SIG '' PZ8wS4p47793xbskysd7iLvm+e5Fi0TBkHPDCFB4K2wt
'' SIG '' PoKFJdwBGh/SwF71db+wV8V80FU9fqaxulLAihfBJcnE
'' SIG '' qmx61sKhGRoBZSMnZqBJMSeSfU9KvYl7V2wdmuq/JYTz
'' SIG '' By2kGSRBF1C4LYc6RulGYfzllrvwZH6JGZknZjkKmLyn
'' SIG '' O+ooI/IhmwbHEni1ZdNKV7h75XpeECLaLCcrQg==
'' SIG '' End signature block
