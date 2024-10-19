' Windows Installer utility to list component composition of an MSI database
' For use with Windows Scripting Host, CScript.exe or WScript.exe
' Copyright (c) Microsoft Corporation. All rights reserved.
' Demonstrates the various tables having foreign keys to the Component table
'
Option Explicit
Public isGUI, installer, database, message, compParam  'global variables access across functions

Const msiOpenDatabaseModeReadOnly     = 0

' Check if run from GUI script host, in order to modify display
If UCase(Mid(Wscript.FullName, Len(Wscript.Path) + 2, 1)) = "W" Then isGUI = True

' Show help if no arguments or if argument contains ?
Dim argCount:argCount = Wscript.Arguments.Count
If argCount > 0 Then If InStr(1, Wscript.Arguments(0), "?", vbTextCompare) > 0 Then argCount = 0
If argCount = 0 Then
	Wscript.Echo "Windows Installer utility to list component composition in an install database." &_
		vbLf & " The 1st argument is the path to an install database, relative or complete path" &_
		vbLf & " The 2nd argument is the name of the component (primary key of Component table)" &_
		vbLf & " If the 2nd argument is not present, the names of all components will be listed" &_
		vbLf & " If the 2nd argument is a ""*"", the composition of all components will be listed" &_
		vbLf & " Large databases or components are better displayed using CScript than WScript." &_
		vbLf & " Note: The name of the component, if provided,  is case-sensitive" &_
		vbNewLine &_
		vbNewLine & "Copyright (C) Microsoft Corporation.  All rights reserved."
	Wscript.Quit 1
End If

' Connect to Windows Installer object
On Error Resume Next
Set installer = Nothing
Set installer = Wscript.CreateObject("WindowsInstaller.Installer") : CheckError

' Open database
Dim databasePath:databasePath = Wscript.Arguments(0)
Set database = installer.OpenDatabase(databasePath, msiOpenDatabaseModeReadOnly) : CheckError

If argCount = 1 Then  'If no component specified, then simply list components
	ListComponents False
	ShowOutput "Components for " & databasePath, message
ElseIf Left(Wscript.Arguments(1), 1) = "*" Then 'List all components
	ListComponents True
Else
	QueryComponent Wscript.Arguments(1) 
End If
Wscript.Quit 0

' List all table rows referencing a given component
Function QueryComponent(component)
	' Get component info and format output header
	Dim view, record, header, componentId
	Set view = database.OpenView("SELECT `ComponentId` FROM `Component` WHERE `Component` = ?") : CheckError
	Set compParam = installer.CreateRecord(1)
	compParam.StringData(1) = component
	view.Execute compParam : CheckError
	Set record = view.Fetch : CheckError
	Set view = Nothing
	If record Is Nothing Then Fail "Component not in database: " & component
	componentId = record.StringData(1)
	header = "Component: "& component & "  ComponentId = " & componentId

	' List of tables with foreign keys to Component table - with subsets of columns to display
	DoQuery "FeatureComponents","Feature_"                           '
	DoQuery "PublishComponent", "ComponentId,Qualifier"              'AppData,Feature
	DoQuery "File",             "File,Sequence,FileName,Version"     'FileSize,Language,Attributes
	DoQuery "SelfReg,File",     "File_"                              'Cost
	DoQuery "BindImage,File",   "File_"                              'Path
	DoQuery "Font,File",        "File_,FontTitle"                    '
	DoQuery "Patch,File",       "File_"                              'Sequence,PatchSize,Attributes,Header
	DoQuery "DuplicateFile",    "FileKey,File_,DestName"             'DestFolder
	DoQuery "MoveFile",         "FileKey,SourceName,DestName"        'SourceFolder,DestFolder,Options
	DoQuery "RemoveFile",       "FileKey,FileName,DirProperty"       'InstallMode
	DoQuery "IniFile",          "IniFile,FileName,Section,Key"       'Value,Action
	DoQuery "RemoveIniFile",    "RemoveIniFile,FileName,Section,Key" 'Value,Action
	DoQuery "Registry",         "Registry,Root,Key,Name"             'Value
	DoQuery "RemoveRegistry",   "RemoveRegistry,Root,Key,Name"       '
	DoQuery "Shortcut",         "Shortcut,Directory_,Name,Target"    'Arguments,Description,Hotkey,Icon_,IconIndex,ShowCmd,WkDir
	DoQuery "Class",            "CLSID,Description"                  'Context,ProgId_Default,AppId_,FileType,Mask,Icon_,IconIndex,DefInprocHandler,Argument,Feature_
	DoQuery "ProgId,Class",     "Class_,ProgId,Description"          'ProgId_Parent,Icon_IconIndex,Insertable
	DoQuery "Extension",        "Extension,ProgId_"                  'MIME_,Feature_
	DoQuery "Verb,Extension",   "Extension_,Verb"                    'Sequence,Command.Argument
	DoQuery "MIME,Extension",   "Extension_,ContentType"             'CLSID
	DoQuery "TypeLib",          "LibID,Language,Version,Description" 'Directory_,Feature_,Cost
	DoQuery "CreateFolder",     "Directory_"                         ' 
	DoQuery "Environment",      "Environment,Name"                   'Value
	DoQuery "ODBCDriver",       "Driver,Description"                 'File_,File_Setup
	DoQuery "ODBCAttribute,ODBCDriver", "Driver_,Attribute,Value" '
	DoQuery "ODBCTranslator",   "Translator,Description"             'File_,File_Setup
	DoQuery "ODBCDataSource",   "DataSource,Description,DriverDescription" 'Registration
	DoQuery "ODBCSourceAttribute,ODBCDataSource", "DataSource_,Attribute,Value" '
	DoQuery "ServiceControl",   "ServiceControl,Name,Event"          'Arguments,Wait
	DoQuery "ServiceInstall",   "ServiceInstall,Name,DisplayName"    'ServiceType,StartType,ErrorControl,LoadOrderGroup,Dependencies,StartName,Password
	DoQuery "ReserveCost",      "ReserveKey,ReserveFolder"           'ReserveLocal,ReserveSource

	QueryComponent = ShowOutput(header, message)
	message = Empty
End Function

' List all components in database
Sub ListComponents(queryAll)
	Dim view, record, component
	Set view = database.OpenView("SELECT `Component`,`ComponentId` FROM `Component`") : CheckError
	view.Execute : CheckError
	Do
		Set record = view.Fetch : CheckError
		If record Is Nothing Then Exit Do
		component = record.StringData(1)
		If queryAll Then
			If QueryComponent(component) = vbCancel Then Exit Sub
		Else
			If Not IsEmpty(message) Then message = message & vbLf
			message = message & component
		End If
	Loop
End Sub

' Perform a join to query table rows linked to a given component, delimiting and qualifying names to prevent conflicts
Sub DoQuery(table, columns)
	Dim view, record, columnCount, column, output, header, delim, columnList, tableList, tableDelim, query, joinTable, primaryKey, foreignKey, columnDelim
	On Error Resume Next
	tableList  = Replace(table,   ",", "`,`")
	tableDelim = InStr(1, table, ",", vbTextCompare)
	If tableDelim Then  ' need a 3-table join
		joinTable = Right(table, Len(table)-tableDelim)
		table = Left(table, tableDelim-1)
		foreignKey = columns
		Set record = database.PrimaryKeys(joinTable)
		primaryKey = record.StringData(1)
		columnDelim = InStr(1, columns, ",", vbTextCompare)
		If columnDelim Then foreignKey = Left(columns, columnDelim - 1)
		query = " AND `" & foreignKey & "` = `" & primaryKey & "`"
	End If
	columnList = table & "`." & Replace(columns, ",", "`,`" & table & "`.`")
	query = "SELECT `" & columnList & "` FROM `" & tableList & "` WHERE `Component_` = ?" & query
	If database.TablePersistent(table) <> 1 Then Exit Sub
	Set view = database.OpenView(query) : CheckError
	view.Execute compParam : CheckError
	Do
		Set record = view.Fetch : CheckError
		If record Is Nothing Then Exit Do
		If IsEmpty(output) Then
			If Not IsEmpty(message) Then message = message & vbLf
			message = message & "----" & table & " Table----  (" & columns & ")" & vbLf
		End If
		output = Empty
		columnCount = record.FieldCount
		delim = "  "
		For column = 1 To columnCount
			If column = columnCount Then delim = vbLf
			output = output & record.StringData(column) & delim
		Next
		message = message & output
	Loop
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

Function ShowOutput(header, message)
	ShowOutput = vbOK
	If IsEmpty(message) Then Exit Function
	If isGUI Then
		ShowOutput = MsgBox(message, vbOKCancel, header)
	Else
		Wscript.Echo "> " & header
		Wscript.Echo message
	End If
End Function

Sub Fail(message)
	Wscript.Echo message
	Wscript.Quit 2
End Sub

'' SIG '' Begin signature block
'' SIG '' MIImHwYJKoZIhvcNAQcCoIImEDCCJgwCAQExDzANBglg
'' SIG '' hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
'' SIG '' BgEEAYI3AgEeMCQCAQEEEE7wKRaZJ7VNj+Ws4Q8X66sC
'' SIG '' AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
'' SIG '' WoLLQA6rHA8fttRtGpZpVGF985uNg+TIhlmzKb0W2sOg
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
'' SIG '' IgQgU+H2zhtPO/bs1TiBZyzIPq79ccTVGaHmw1wCd9Wp
'' SIG '' jFgwPAYKKwYBBAGCNwoDHDEuDCxzUFk3eFBCN2hUNWc1
'' SIG '' SEhyWXQ4ckRMU005VnVaUnVXWmFlZjJlMjJSczU0PTBa
'' SIG '' BgorBgEEAYI3AgEMMUwwSqAkgCIATQBpAGMAcgBvAHMA
'' SIG '' bwBmAHQAIABXAGkAbgBkAG8AdwBzoSKAIGh0dHA6Ly93
'' SIG '' d3cubWljcm9zb2Z0LmNvbS93aW5kb3dzMA0GCSqGSIb3
'' SIG '' DQEBAQUABIIBAIYkMsQZ0E+4e6IkB6dZTp7B8tY5uxkS
'' SIG '' 5NC2OS3FTJRg8nBz9WL2YOgX0FvUmk6JaOHjyij5qKYC
'' SIG '' hRrbz+2G1zEg2BiJSzoaryCHJ0gHoxSWGovksRfxrpbI
'' SIG '' ZoIgARBNqp4ZPe9fKy8qi2kOcW9OVbYvpxYC4GHjPUMl
'' SIG '' 0FIaOic1YeblG5Ud2H8kEBL74jn4QBx4pZy+6Cg5UjkV
'' SIG '' UbWcchvdDmJlSTYuUkNu1lynYoZXD6xon2tSYJE9jSPM
'' SIG '' Hg31dMEJnBEAgn5iDsC45+xTPmyiVkoib2zY+qRUTXqc
'' SIG '' LMGSSrTKrK26w82Qu47z5pyLIZegnbxClO0ze8xFBqI8
'' SIG '' y9qhghcpMIIXJQYKKwYBBAGCNwMDATGCFxUwghcRBgkq
'' SIG '' hkiG9w0BBwKgghcCMIIW/gIBAzEPMA0GCWCGSAFlAwQC
'' SIG '' AQUAMIIBWQYLKoZIhvcNAQkQAQSgggFIBIIBRDCCAUAC
'' SIG '' AQEGCisGAQQBhFkKAwEwMTANBglghkgBZQMEAgEFAAQg
'' SIG '' nEjr8nJ+SYdX0WnEVF/w/naRmYKxT4f4z3YXruYWQbsC
'' SIG '' BmUK5CT7phgTMjAyMzA5MzAxMDE0MjcuNzE3WjAEgAIB
'' SIG '' 9KCB2KSB1TCB0jELMAkGA1UEBhMCVVMxEzARBgNVBAgT
'' SIG '' Cldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
'' SIG '' BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsG
'' SIG '' A1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9u
'' SIG '' cyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVT
'' SIG '' TjoyQUQ0LTRCOTItRkEwMTElMCMGA1UEAxMcTWljcm9z
'' SIG '' b2Z0IFRpbWUtU3RhbXAgU2VydmljZaCCEXgwggcnMIIF
'' SIG '' D6ADAgECAhMzAAABscqQQ+4L8AOrAAEAAAGxMA0GCSqG
'' SIG '' SIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
'' SIG '' EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
'' SIG '' HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
'' SIG '' BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAy
'' SIG '' MDEwMB4XDTIyMDkyMDIwMjE1OVoXDTIzMTIxNDIwMjE1
'' SIG '' OVowgdIxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
'' SIG '' aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
'' SIG '' ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsT
'' SIG '' JE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGlt
'' SIG '' aXRlZDEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046MkFE
'' SIG '' NC00QjkyLUZBMDExJTAjBgNVBAMTHE1pY3Jvc29mdCBU
'' SIG '' aW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
'' SIG '' AQUAA4ICDwAwggIKAoICAQCGoqs+1ewbx+yDjDxHgzNl
'' SIG '' MAqTPC8QFD3ie1L7vatEYgwXQYLIQv0g63t/2CQahqZ9
'' SIG '' u2u11jjL4ogVHzDX3+dTcShaEl+thqat+mC0WZNoTdcI
'' SIG '' oKwjuues+aVU4yad0PI3WACV967iXmt3HH04MQIE91L/
'' SIG '' 7D+MNPsmQGGtiWWpVdzAYCBYt1cChQOApUHK/leEqRs6
'' SIG '' s/H2qmm5mMqbid+WZ/Bv9tNaQDdowxDru0GgwtKxsg3c
'' SIG '' Ek1Zl3BzOOhBVejdhevZ8H49g2Ye+IJwNQwezRXGZ/uL
'' SIG '' 9ZKkFp+wMwSfpZjsbyq1EZVf7tfTMNWD/s1UMsyp+f+K
'' SIG '' /77mEkY/7YWa/hZmQFLUwGnC86LgRDbmkgbjmNZN99Hj
'' SIG '' KfJ53UjVLFI4/55+4HHRas3UDbnSW/l8ZkcIvS8IwNP/
'' SIG '' D5TrCk2fF8OhBFj1S3zaI0rlqWTE2jM8/8M0j6eSdNpK
'' SIG '' WJpHZedJcMhkSzuV+4liDSpqF8knUJkXYhjE5L0UrVys
'' SIG '' SKBJvxCcQmiPpOEt/gVilgtOxFeU91Bu8GxW+C374G22
'' SIG '' ijOfB8rQMow5zvXxItL66fCRU7RoXbcIRBJK2jLRlbfg
'' SIG '' r5xtGZR+Jr6T0T7iW6hOdPXugqph8M07lGTxTBVryZ+H
'' SIG '' z79Hd9lrPY79mGJhP9FkdX1C7Pk8caVoJ9c9DwDrMUmU
'' SIG '' TwIDAQABo4IBSTCCAUUwHQYDVR0OBBYEFPSbZ5HvDa2E
'' SIG '' ivXxZ6FRNKa9DjmTMB8GA1UdIwQYMBaAFJ+nFV0AXmJd
'' SIG '' g/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCGTmh0
'' SIG '' dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3Js
'' SIG '' L01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAy
'' SIG '' MDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4wXAYIKwYB
'' SIG '' BQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
'' SIG '' a2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFt
'' SIG '' cCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQC
'' SIG '' MAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0P
'' SIG '' AQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4ICAQDY5zeS
'' SIG '' aqXlUoSK0CGgEJzVTr9XAxJgpA+qELn1/TRjl9vCcP4H
'' SIG '' ZBrTCcmoANJVW7psEJWuSz4QZuS4yFFv+WmIc0pWe5cX
'' SIG '' g8pMOe8KdgKqDACZu213F7Sbfx8mkZTd+YQIQVfg5hpw
'' SIG '' SEXBOQtm0hRWN2rA+dClEgj5ipf9DRWnT3qDam4+WVJ2
'' SIG '' vFQHzEg7HcXssY7PK//VaasvJYCFQaka17Rbep9fhhaS
'' SIG '' ftgIz7KXzzu2PmP6M7+XUxGLpuXgyw3Q9bYUJh5FvLNA
'' SIG '' QQ2yDk93fnVnTxE5H+dHzP5wC5DBHb2KNoMoiazkhtGv
'' SIG '' Wdkv+pmyQVK4K5ID6dh4y5MnEeDYcJeu3oQIVsSRig9o
'' SIG '' EZPPE9iily4kRwKGE2VaR24JGC7KQSybPQu+2ZLsV7ry
'' SIG '' DhmiHexCQgTlUTCcoLcfBV6aErt41hHWrtFgTF8YVQMx
'' SIG '' B07u1Cltw8PihoFu0UZYa7efPUivJaz0rzzOjz56hBX+
'' SIG '' j1LE1TtGzpMypwt0zoLouCYZVpYooLRLYNUpTzMXHTLn
'' SIG '' PbmHVkntf9mFpq/Wa1dUbr6UkiryS0mA5Tn+mia6Z1+2
'' SIG '' CizEaMinc05HL18NSWX4pCXhiY30bNnE9iSG4jRBiuIu
'' SIG '' bK0G1Qr4Ar3WFRFWV1VtSM/yySyvV2yJDDI5hAiRLGtO
'' SIG '' 6GnSnDuHnfb2OmGARjCCB3EwggVZoAMCAQICEzMAAAAV
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
'' SIG '' MCQGA1UECxMdVGhhbGVzIFRTUyBFU046MkFENC00Qjky
'' SIG '' LUZBMDExJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0
'' SIG '' YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMVAO1ksb6k
'' SIG '' A2wO78suvU59MD+QRscroIGDMIGApH4wfDELMAkGA1UE
'' SIG '' BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
'' SIG '' BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
'' SIG '' b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
'' SIG '' bWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcNAQEFBQAC
'' SIG '' BQDowefkMCIYDzIwMjMwOTMwMDgxODQ0WhgPMjAyMzEw
'' SIG '' MDEwODE4NDRaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIF
'' SIG '' AOjB5+QCAQAwBwIBAAICE7IwBwIBAAICEVcwCgIFAOjD
'' SIG '' OWQCAQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYKKwYBBAGE
'' SIG '' WQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkq
'' SIG '' hkiG9w0BAQUFAAOBgQAtS08LvEjg65ZIolYh2ntsojBq
'' SIG '' JT9TXqnCRaBB98h4dhshqqCQHbzyskPnTOlBs21tIXJd
'' SIG '' gb8GK83I6yzzGu36gflsyJtkjPDv5Ki7CkEXCaPLg+9K
'' SIG '' kMIwbcIf0ufAV5bmE+V9/KEFxxrH+al3wtFKl/2wt+5w
'' SIG '' GGXVSvMrfE5zPDGCBA0wggQJAgEBMIGTMHwxCzAJBgNV
'' SIG '' BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
'' SIG '' VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
'' SIG '' Q29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBU
'' SIG '' aW1lLVN0YW1wIFBDQSAyMDEwAhMzAAABscqQQ+4L8AOr
'' SIG '' AAEAAAGxMA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG
'' SIG '' 9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkE
'' SIG '' MSIEIFTwYGDxat7mZFq+uSpHD2+1lHoH2f3xALZra+QV
'' SIG '' Z3zvMIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQg
'' SIG '' g+0NixRb36ng6MvYKbt+benWHq6wztHDE5TiKJs0z2ww
'' SIG '' gZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
'' SIG '' V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
'' SIG '' A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
'' SIG '' VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
'' SIG '' MAITMwAAAbHKkEPuC/ADqwABAAABsTAiBCBaGKmFvjiD
'' SIG '' 5oEjZsk7i1MxZaNFAhssXhXaKfJgPHa/qTANBgkqhkiG
'' SIG '' 9w0BAQsFAASCAgCCyarns+Q/XA2NB8NsFmlyrCRUcZmU
'' SIG '' AEeY1thX1xym5DO1+NN5b+kVlN8qXlHUBDrO4M4y/kH4
'' SIG '' NdMO0lJhEbJrb2KPvTnZcNbJVbotdEZSZbCZDJF5soHy
'' SIG '' WVG37Bt2lB3zcDuIKuFY0lGGBuVtUeu1vmXbKL5sZ3kA
'' SIG '' zuhmnk5IWi2eKCmZtNMC3oAtg8pw5ohJ55UInQVS6RVT
'' SIG '' Y7tTJEKmGwAuVydAG+3ES+x/duaM1TtWqDwjr1q2MwPi
'' SIG '' 35AYsZVX0ay0503YZcFCP0MOI6X0iBOzUX2aJymE9bRM
'' SIG '' zaWbYaIwhlggRq0swFjCg2iAQ55hRZ+rHcF+JrYw4NUt
'' SIG '' SsER8rxqgJJxFc8huH5lJYYUfd1zQ2ymxSG3lwTGDBns
'' SIG '' jtr7JBP5Q+rGrEc+fZab7dadxsCQ0mWVo6uaNqTJFNr8
'' SIG '' YK29g9ddEfVfHkf5u784RzX6MR/AkvHOlyMNCSI6ip09
'' SIG '' t+ezW24eUQMJLOP9AIxon5MSnrPdiwmSN6XrEy/j3a7l
'' SIG '' qVSj842p+tXghhGOresX51upniPkYeckP6QGKgKT6HCe
'' SIG '' NaJhXhnMX8bJH6sZJQkAuKHM5EVgzZcmi9H+KlN1qtQ8
'' SIG '' 4K+6p0Towlr2y3/a1B3NDa16QatM0u4KQMJcevyAywiP
'' SIG '' a4jQar/R4wM7qhes3+XOKoH1MC+//KM6TeHT3A==
'' SIG '' End signature block
