'******************************************************************************
'Microsoft Confidential. © 2002-2003 Microsoft Corporation. All rights reserved.
'
' This file may contain preliminary information or inaccuracies, 
' and may not correctly represent any associated Microsoft 
' Product as commercially released. All Materials are provided entirely 
' “AS IS.” To the extent permitted by law, MICROSOFT MAKES NO 
' WARRANTY OF ANY KIND, DISCLAIMS ALL EXPRESS, IMPLIED AND STATUTORY 
' WARRANTIES, AND ASSUMES NO LIABILITY TO YOU FOR ANY DAMAGES OF 
' ANY TYPE IN CONNECTION WITH THESE MATERIALS OR ANY INTELLECTUAL PROPERTY IN THEM. 
'******************************************************************************

Option Explicit

Wscript.Echo "" 
Wscript.Echo "REGISTER_APP.VBS version 1.6 for Windows Server 2008"
Wscript.Echo "Copyright (C) Microsoft Corporation 2002-2003. All rights reserved."
Wscript.Echo "" 


'******************************************************************************
' Parse command line arguments
'******************************************************************************
Dim Args
Set Args = Wscript.Arguments
If Args.Count < 1 Then 
	PrintsUsage
End If

Dim ProviderName, ProviderDLL, ProviderDescription
If Args.Item(0) = "-register" Then 
	If Args.Count <> 4 Then PrintsUsage

	ProviderName = Args.Item(1)
	ProviderDLL = Args.Item(2)
	ProviderDescription = Args.Item(3)

	UninstallProvider
	InstallProvider
	Wscript.Quit 0
End If 

If Args.Item(0) = "-unregister" Then 
	If Not Args.Count = 2 Then PrintsUsage
	ProviderName = Args.Item(1)
	UninstallProvider
	Wscript.Quit 0
End If

' Wrong options?
PrintsUsage

Wscript.Quit 0

'******************************************************************************
' Prints the usage
'******************************************************************************
Sub PrintsUsage

	Wscript.Echo "Usage:" 
	Wscript.Echo "" 
	Wscript.Echo " 1) Registering a VSS/VDS Provider as a COM+ application:" 
	Wscript.Echo "      CScript.exe " & Wscript.ScriptName & " -register <Provider_Name> <Provider.DLL>  <Provider_Description>" 
	Wscript.Echo "" 
	Wscript.Echo " 2) Unregistering a COM+ application associated with a VSS/VDS provider:" 
	Wscript.Echo "      CScript.exe " & Wscript.ScriptName & " -unregister <Provider_Name>" 
	Wscript.Echo "" 
	Wscript.Quit 1

End Sub


'******************************************************************************
' Installs the Provider
'******************************************************************************
Sub InstallProvider
	On Error Resume Next

	Wscript.Echo "Creating a new COM+ application:" 

	Wscript.Echo "- Creating the catalog object "
	Dim cat
	Set cat = CreateObject("COMAdmin.COMAdminCatalog") 	
	CheckError 101

	wscript.echo "- Get the Applications collection"
	Dim collApps
	Set collApps = cat.GetCollection("Applications")
	CheckCollectionError 102, cat

	Wscript.Echo "- Populate..." 
	collApps.Populate 
	CheckCollectionError 103, collApps

	Wscript.Echo "- Add new application object" 
	Dim app
	Set app = collApps.Add 
	CheckCollectionError 104, collApps

	Wscript.Echo "- Set app name = " & ProviderName & " "
	app.Value("Name") = ProviderName
	CheckObjectError 105, collApps, app

	Wscript.Echo "- Set app description = " & ProviderDescription & " "
	app.Value("Description") = ProviderDescription 
	CheckObjectError 106, collApps, app

	' Only roles added below are allowed to call in.
	Wscript.Echo "- Set app access check = true "
	app.Value("ApplicationAccessChecksEnabled") = 1   
	CheckObjectError 107, collApps, app

	' Encrypting communication
	Wscript.Echo "- Set encrypted COM communication = true "
	app.Value("Authentication") = 6	                  
	CheckObjectError 108, collApps, app

	' Secure references
	Wscript.Echo "- Set secure references = true "
	app.Value("AuthenticationCapability") = 2         
	CheckObjectError 109, collApps, app

	' Do not allow impersonation
	Wscript.Echo "- Set impersonation = false "
	app.Value("ImpersonationLevel") = 2               
	CheckObjectError 110, collApps, app

	Wscript.Echo "- Save changes..."
	collApps.SaveChanges
	CheckCollectionError 111, collApps

	wscript.echo "- Create Windows service running as Local System"
	cat.CreateServiceForApplication ProviderName, ProviderName , "SERVICE_AUTO_START", "SERVICE_ERROR_NORMAL", "", ".\localsystem", "", 0
	CheckCollectionError 112, cat

	wscript.echo "- Add the DLL component"
	cat.InstallComponent ProviderName, ProviderDLL , "", ""
        CheckCollectionError 113, cat

	'
	' Add the new role for the Local SYSTEM account
	'

	wscript.echo "Secure the COM+ application:"
	wscript.echo "- Get roles collection"
	Dim collRoles
	Set collRoles = collApps.GetCollection("Roles", app.Key)
	CheckCollectionError 120, cat

	wscript.echo "- Populate..."
	collRoles.Populate
	CheckCollectionError 121, collRoles

	wscript.echo "- Add new role"
	Dim role
	Set role = collRoles.Add
	CheckCollectionError 122, collRoles

	wscript.echo "- Set name = Administrators "
	role.Value("Name") = "Administrators"
	CheckObjectError 123, collRoles, role

	wscript.echo "- Set description = Administrators group "
	role.Value("Description") = "Administrators group"
	CheckObjectError 124, collRoles, role

	wscript.echo "- Save changes ..."
	collRoles.SaveChanges
	CheckCollectionError 125, collRoles
	
	'
	' Add users into role
	'

	wscript.echo "Granting user permissions:"
	Dim collUsersInRole
	Set collUsersInRole = collRoles.GetCollection("UsersInRole", role.Key)
	CheckCollectionError 130, collRoles

	wscript.echo "- Populate..."
	collUsersInRole.Populate
	CheckCollectionError 131, collUsersInRole

	wscript.echo "- Add new user"
	Dim user
	Set user = collUsersInRole.Add
	CheckCollectionError 132, collUsersInRole

	wscript.echo "- Searching for the Administrators account using WMI..."

	' Get the Administrators account domain and name
	Dim strQuery
	strQuery = "select * from Win32_Account where SID='S-1-5-32-544' and localAccount=TRUE"
	Dim objSet
	set objSet = GetObject("winmgmts:").ExecQuery(strQuery)
	CheckError 133

	Dim obj, Account
	for each obj in objSet
	    set Account = obj
		exit for
	next

	wscript.echo "- Set user name = .\" & Account.Name & " "
	user.Value("User") = ".\" & Account.Name
	CheckObjectError 140, collUsersInRole, user

	wscript.echo "- Add new user"
	Set user = collUsersInRole.Add
	CheckCollectionError 141, collUsersInRole

	wscript.echo "- Set user name = Local SYSTEM "
	user.Value("User") = "NT AUTHORITY\SYSTEM"
	CheckObjectError 142, collUsersInRole, user

	wscript.echo "- Save changes..."
	collUsersInRole.SaveChanges
	CheckCollectionError 143, collUsersInRole
	
	Set app      = Nothing
	Set cat      = Nothing
	Set role     = Nothing
	Set user     = Nothing

	Set collApps = Nothing
	Set collRoles = Nothing
	Set collUsersInRole	= Nothing

	set objSet   = Nothing
	set obj      = Nothing

	Wscript.Echo "Done." 

	On Error GoTo 0
End Sub


'******************************************************************************
' Uninstalls the Provider
'******************************************************************************
Sub UninstallProvider
	On Error Resume Next

	Wscript.Echo "Unregistering the existing application..." 

	wscript.echo "- Create the catalog object"
	Dim cat
	Set cat = CreateObject("COMAdmin.COMAdminCatalog")
	CheckError 201
	
	wscript.echo "- Get the Applications collection"
	Dim collApps
	Set collApps = cat.GetCollection("Applications")
	CheckCollectionError 202, cat

	wscript.echo "- Populate..."
	collApps.Populate
	CheckCollectionError 203, collApps
	
	wscript.echo "- Search for " & ProviderName & " application..."
	Dim numApps
	numApps = collApps.Count
	Dim i
	For i = numApps - 1 To 0 Step -1
	    If collApps.Item(i).Value("Name") = ProviderName Then
	        collApps.Remove(i)
		CheckCollectionError 204, collApps
                WScript.echo "- Application " & ProviderName & " removed!"
	    End If
	Next
	
	wscript.echo "- Saving changes..."
	collApps.SaveChanges
	CheckCollectionError 205, collApps

	Set collApps = Nothing
	Set cat      = Nothing

	Wscript.Echo "Done." 

	On Error GoTo 0
End Sub



'******************************************************************************
' Sub CheckError
'******************************************************************************
Sub CheckError(exitCode)
    If Err = 0 Then Exit Sub
    DumpVBScriptError exitCode

    Wscript.Quit exitCode
End Sub


'******************************************************************************
' Sub CheckCollectionError
'******************************************************************************
Sub CheckCollectionError(exitCode, coll)
    If Err = 0 Then Exit Sub
    DumpVBScriptError exitCode

    DumpComPlusError(coll.GetCollection("ErrorInfo"))

    Wscript.Quit exitCode
End Sub


'******************************************************************************
' Sub CheckObjectError
'******************************************************************************
Sub CheckObjectError(exitCode, coll, object)
    If Err = 0 Then Exit Sub
    DumpVBScriptError exitCode

    ' DumpComPlusError(coll.GetCollection("ErrorInfo", object.Key))
    DumpComPlusError(coll.GetCollection("ErrorInfo"))

    Wscript.Quit exitCode
End Sub



'******************************************************************************
' Sub DumpVBScriptError
'******************************************************************************
Sub DumpVBScriptError(exitCode)
    WScript.Echo vbNewLine & "ERROR:"
    WScript.Echo "- Error code: " & Err & " [0x" & Hex(Err) & "]"
    WScript.Echo "- Exit code: " & exitCode
    WScript.Echo "- Description: " & Err.Description
    WScript.Echo "- Source: " & Err.Source
    WScript.Echo "- Help file: " & Err.Helpfile
    WScript.Echo "- Help context: " & Err.HelpContext
End Sub


'******************************************************************************
' Sub DumpComPlusError
'******************************************************************************
Sub DumpComPlusError(errors)
    errors.Populate
    WScript.Echo "- COM+ Errors detected: (" & errors.Count & ")"

    Dim error
    Dim I
    For I = 0 to errors.Count - 1
	Set error = errors.Item(I)
        WScript.Echo "   * (COM+ ERROR " & I & ") on " & error.Value("Name")
        WScript.Echo "       ErrorCode: " & error.Value("ErrorCode") & " [0x" & Hex(error.Value("ErrorCode")) & "]"
        WScript.Echo "       MajorRef: " & error.Value("MajorRef")
        WScript.Echo "       MinorRef: " & error.Value("MinorRef")
    Next
End Sub


'' SIG '' Begin signature block
'' SIG '' MIImBQYJKoZIhvcNAQcCoIIl9jCCJfICAQExDzANBglg
'' SIG '' hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
'' SIG '' BgEEAYI3AgEeMCQCAQEEEE7wKRaZJ7VNj+Ws4Q8X66sC
'' SIG '' AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
'' SIG '' t2OGjVuwrDi7m9eD1oGHZt1e8mT97G6PYHdAzoXpmRWg
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
'' SIG '' jgd7JXFEqwZq5tTG3yOalnXFMYIZ9jCCGfICAQEwgZUw
'' SIG '' fjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
'' SIG '' b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
'' SIG '' Y3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWlj
'' SIG '' cm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMAITMwAA
'' SIG '' BQAn1jJvQ3N7hwAAAAAFADANBglghkgBZQMEAgEFAKCC
'' SIG '' AQQwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYK
'' SIG '' KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZI
'' SIG '' hvcNAQkEMSIEIKK6iEgLHrRNtkju0ARNJFYXKWBPVpnu
'' SIG '' yofrkEcDFCOSMDwGCisGAQQBgjcKAxwxLgwsc1BZN3hQ
'' SIG '' QjdoVDVnNUhIcll0OHJETFNNOVZ1WlJ1V1phZWYyZTIy
'' SIG '' UnM1ND0wWgYKKwYBBAGCNwIBDDFMMEqgJIAiAE0AaQBj
'' SIG '' AHIAbwBzAG8AZgB0ACAAVwBpAG4AZABvAHcAc6EigCBo
'' SIG '' dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vd2luZG93czAN
'' SIG '' BgkqhkiG9w0BAQEFAASCAQBLiOeHlydPIF+7PpAdqEVE
'' SIG '' uXMd2WNMpXNN8ObAua0CqOblRjJmN1RKS8cmD7Gv88mo
'' SIG '' V0JSS9G9Ipyj4crx5+qQw5pHvI/x2XO1LgMmRAwqikR0
'' SIG '' GzevtCEE8GSTQcJYVGl7gSLzubJKyygVJfgUh+f0imbL
'' SIG '' njvc3CrLhW2Yp2aJ1VxSwedio0KtFt2HTkmQriKPK9Bh
'' SIG '' q3evyvbffiM/EswPVud06HdWLIuAM6vJHWDsUfDf4c3X
'' SIG '' Ub+7Vvh6BcwBkQfDvjrxrBsCb1pkS2rBF52yp/S1quwA
'' SIG '' 15aOAIWPK2LXj22h4ntKjyvy6/ADE+4lGlL446/MlEMS
'' SIG '' sjg4JJc9AGn3oYIXKTCCFyUGCisGAQQBgjcDAwExghcV
'' SIG '' MIIXEQYJKoZIhvcNAQcCoIIXAjCCFv4CAQMxDzANBglg
'' SIG '' hkgBZQMEAgEFADCCAVkGCyqGSIb3DQEJEAEEoIIBSASC
'' SIG '' AUQwggFAAgEBBgorBgEEAYRZCgMBMDEwDQYJYIZIAWUD
'' SIG '' BAIBBQAEIH48Lvtu+NTqrR+i7D3AXo+frnMkBBsqA9ET
'' SIG '' 3H/0+isBAgZlC6o2NEIYEzIwMjMwOTMwMDkxODQwLjk3
'' SIG '' N1owBIACAfSggdikgdUwgdIxCzAJBgNVBAYTAlVTMRMw
'' SIG '' EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
'' SIG '' b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
'' SIG '' b24xLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9w
'' SIG '' ZXJhdGlvbnMgTGltaXRlZDEmMCQGA1UECxMdVGhhbGVz
'' SIG '' IFRTUyBFU046RDA4Mi00QkZELUVFQkExJTAjBgNVBAMT
'' SIG '' HE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WgghF4
'' SIG '' MIIHJzCCBQ+gAwIBAgITMwAAAbofPxn3wXW9fAABAAAB
'' SIG '' ujANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzET
'' SIG '' MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
'' SIG '' bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
'' SIG '' aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFt
'' SIG '' cCBQQ0EgMjAxMDAeFw0yMjA5MjAyMDIyMTlaFw0yMzEy
'' SIG '' MTQyMDIyMTlaMIHSMQswCQYDVQQGEwJVUzETMBEGA1UE
'' SIG '' CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
'' SIG '' MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0w
'' SIG '' KwYDVQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRp
'' SIG '' b25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1Mg
'' SIG '' RVNOOkQwODItNEJGRC1FRUJBMSUwIwYDVQQDExxNaWNy
'' SIG '' b3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkq
'' SIG '' hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAiE4VgzOSNYAT
'' SIG '' 1RWdcX2FEa/TEFHFz4jke7eHFUVfIre7fzG6wRvSkuTC
'' SIG '' OAa0OxostuuUzGpfe0Vv/cGAQ8QLcvTBfvqAPzMe37CI
'' SIG '' FXmarkFainb2pGuAwkooI9ylCdKOz0H/hcwUW+ul0+Jx
'' SIG '' kO/jcUuDP18eoyrQskPDkkAcYNLfRMJj04Xjc/h3jhn2
'' SIG '' UTsJpVLakkwXcvjncxcHnJgr8oNuKWERE/WPGfbKX60Y
'' SIG '' JGC4gCwwbSh46FdrDy5IY6FLoAJIdv55uLTTfwwUfKhM
'' SIG '' 2Ep/5Jijg6lJjfE/j6zAEFMoOhg/XAf4J/EbqH1/KYEl
'' SIG '' A9Blqp+XSuKIMuOYO6dC0fUYPrgCKvmT0l3CGrnAuZJZ
'' SIG '' ePIVUv4gN86l2LEnp/mj4yETofi3fXD6mvKAeZ3ZQdDr
'' SIG '' ntQbHoU27PAL5KkAeZXvoxlhpzi4CFOBo/js/Z55LWhy
'' SIG '' S/KGX3Jr70nM98yS6DfF6/MUANaItEyvTroQxXurclJE
'' SIG '' CycJL0ZDTwLgUo9tKHw48zfcueDR9/EA2ccABf8MTtwd
'' SIG '' zHuX2NpXcByaSPuiqKvgSHa7ljHCJpMTftdoy6ZfYRLc
'' SIG '' 8nk0Fperth0snDJIP5T2mT+2Xh1DW38R6ju4NOWI7JCQ
'' SIG '' PwjvjGlUHRPfX/rsod+QGQVW/LrDJ7bVX70gLy5IP75G
'' SIG '' APdHC03aQT8CAwEAAaOCAUkwggFFMB0GA1UdDgQWBBSK
'' SIG '' YubxAx4lrbmP0xZ5psjYdK9k5TAfBgNVHSMEGDAWgBSf
'' SIG '' pxVdAF5iXYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSg
'' SIG '' UqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
'' SIG '' b3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIw
'' SIG '' UENBJTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBe
'' SIG '' MFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29m
'' SIG '' dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRp
'' SIG '' bWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNV
'' SIG '' HRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
'' SIG '' MA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOC
'' SIG '' AgEAX8jxTqFtmG8Nyf3qdnq2RtISNc+8pnrCuhpdyCy0
'' SIG '' SGmBp4TCV4u49ccvMRa24m5jPh6yGaFeoWvj2VsBxflI
'' SIG '' 3n9wSw/TF0VrJvtTk/3gll3ceMW+lZE2g0GEXdIMzQDf
'' SIG '' ywjYf6GOEH9V9fVdxmJ6LVE48DIIdwGAcvJCsS7qadvc
'' SIG '' eFsh2vyHRNrtYXKUaEtIVbrCbMq6w/po6WacZJpzk0x+
'' SIG '' VrqVG9Ngd3byttsKB9KbVGFOChmP5bwNMq2IQzC5scne
'' SIG '' Yg8qajzG0khZc+derpcqCV2svlzKcsxf/RZfrk65ZsdX
'' SIG '' kZMQt19a8ZXcNpmsc9RD9Q/fUp6pvbGNUJvfQtXCBuMi
'' SIG '' 9hLvs3V0BGQ3wX/2knWA7gi9lYzDIyUooUaiM7V/XBuN
'' SIG '' JZwD/nu2xz63ZuWsxaBI0eDMOvTWNs9K6lGPLce31lmz
'' SIG '' jE3TZ6Jfd4bb3s2u0LqXhz+DOfbR6qipbH+4dbGZOAHQ
'' SIG '' XmiwG5Mc57vsPIQDS6ECsaWAo/3WOCGC385UegfrmDRC
'' SIG '' oK2Bn7fqacISDog6EWgWsJzR8kUZWZvX7XuAR74dEwzu
'' SIG '' MGTg7Ton4iigWsjd7c8mM+tBqej8zITeH7MC4FYYwNFx
'' SIG '' SU0oINTt0ada8fddbAusIIhzP7cbBFQywuwN09bY5W/u
'' SIG '' /V4QmIxIhnY/4zsvbRDxrOdTg4AwggdxMIIFWaADAgEC
'' SIG '' AhMzAAAAFcXna54Cm0mZAAAAAAAVMA0GCSqGSIb3DQEB
'' SIG '' CwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
'' SIG '' aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
'' SIG '' ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQD
'' SIG '' EylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRo
'' SIG '' b3JpdHkgMjAxMDAeFw0yMTA5MzAxODIyMjVaFw0zMDA5
'' SIG '' MzAxODMyMjVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
'' SIG '' EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
'' SIG '' HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
'' SIG '' BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAy
'' SIG '' MDEwMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKC
'' SIG '' AgEA5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwHB9KpbE51
'' SIG '' yMo1V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64
'' SIG '' NmeFRiMMtY0Tz3cywBAY6GB9alKDRLemjkZrBxTzxXb1
'' SIG '' hlDcwUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9cmmv
'' SIG '' Haus9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl3GoP
'' SIG '' z130/o5Tz9bshVZN7928jaTjkY+yOSxRnOlwaQ3KNi1w
'' SIG '' jjHINSi947SHJMPgyY9+tVSP3PoFVZhtaDuaRr3tpK56
'' SIG '' KTesy+uDRedGbsoy1cCGMFxPLOJiss254o2I5JasAUq7
'' SIG '' vnGpF1tnYN74kpEeHT39IM9zfUGaRnXNxF803RKJ1v2l
'' SIG '' IH1+/NmeRd+2ci/bfV+AutuqfjbsNkz2K26oElHovwUD
'' SIG '' o9Fzpk03dJQcNIIP8BDyt0cY7afomXw/TNuvXsLz1dhz
'' SIG '' PUNOwTM5TI4CvEJoLhDqhFFG4tG9ahhaYQFzymeiXtco
'' SIG '' dgLiMxhy16cg8ML6EgrXY28MyTZki1ugpoMhXV8wdJGU
'' SIG '' lNi5UPkLiWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFdEtsl
'' SIG '' uq9QBXpsxREdcu+N+VLEhReTwDwV2xo3xwgVGD94q0W2
'' SIG '' 9R6HXtqPnhZyacaue7e3PmriLq0CAwEAAaOCAd0wggHZ
'' SIG '' MBIGCSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUC
'' SIG '' BBYEFCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQW
'' SIG '' BBSfpxVdAF5iXYP05dJlpxtTNRnpcjBcBgNVHSAEVTBT
'' SIG '' MFEGDCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIBFjNo
'' SIG '' dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0Rv
'' SIG '' Y3MvUmVwb3NpdG9yeS5odG0wEwYDVR0lBAwwCgYIKwYB
'' SIG '' BQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEw
'' SIG '' CwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYD
'' SIG '' VR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQwVgYD
'' SIG '' VR0fBE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3Nv
'' SIG '' ZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2Vy
'' SIG '' QXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4w
'' SIG '' TDBKBggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3Nv
'' SIG '' ZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAx
'' SIG '' MC0wNi0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIBAJ1V
'' SIG '' ffwqreEsH2cBMSRb4Z5yS/ypb+pcFLY+TkdkeLEGk5c9
'' SIG '' MTO1OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi7ulm
'' SIG '' ZzpTTd2YurYeeNg2LpypglYAA7AFvonoaeC6Ce5732pv
'' SIG '' vinLbtg/SHUB2RjebYIM9W0jVOR4U3UkV7ndn/OOPcbz
'' SIG '' aN9l9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECWOKz3
'' SIG '' +SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWKNsId
'' SIG '' w2FzLixre24/LAl4FOmRsqlb30mjdAy87JGA0j3mSj5m
'' SIG '' O0+7hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3UwxTSwethQ
'' SIG '' /gpY3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+c23Kjgm9
'' SIG '' swFXSVRk2XPXfx5bRAGOWhmRaw2fpCjcZxkoJLo4S5pu
'' SIG '' +yFUa2pFEUep8beuyOiJXk+d0tBMdrVXVAmxaQFEfnyh
'' SIG '' YWxz/gq77EFmPWn9y8FBSX5+k77L+DvktxW/tM4+pTFR
'' SIG '' hLy/AsGConsXHRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0
'' SIG '' +CQ1ZyvgDbjmjJnW4SLq8CdCPSWU5nR0W2rRnj7tfqAx
'' SIG '' M328y+l7vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJtpQUQ
'' SIG '' wXEGahC0HVUzWLOhcGbyoYIC1DCCAj0CAQEwggEAoYHY
'' SIG '' pIHVMIHSMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
'' SIG '' aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
'' SIG '' ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQL
'' SIG '' EyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExp
'' SIG '' bWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkQw
'' SIG '' ODItNEJGRC1FRUJBMSUwIwYDVQQDExxNaWNyb3NvZnQg
'' SIG '' VGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoD
'' SIG '' FQB2o0d7XXeAInztpkgZrlAFSojC8qCBgzCBgKR+MHwx
'' SIG '' CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
'' SIG '' MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
'' SIG '' b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jv
'' SIG '' c29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMA0GCSqGSIb3
'' SIG '' DQEBBQUAAgUA6MFc7TAiGA8yMDIzMDkyOTIyMjU0OVoY
'' SIG '' DzIwMjMwOTMwMjIyNTQ5WjB0MDoGCisGAQQBhFkKBAEx
'' SIG '' LDAqMAoCBQDowVztAgEAMAcCAQACAgJkMAcCAQACAhGm
'' SIG '' MAoCBQDowq5tAgEAMDYGCisGAQQBhFkKBAIxKDAmMAwG
'' SIG '' CisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMB
'' SIG '' hqAwDQYJKoZIhvcNAQEFBQADgYEAWqUNT2D1Qudc5Hfu
'' SIG '' ho/ycJx67y+V/Ii6RLAZD0fd+Xfzh8ZY9iwFLl1RNzmT
'' SIG '' 1M7iik/fPW/qowc5Woxj5M4x5Tbq4MTnk6Y3ej1HBQeU
'' SIG '' 6yiQeHUniVWTL3iv1h5MxbxixIXpW77BFqn3aKFJf3qP
'' SIG '' mSrFvRWKzInHuzLOegqkUFcxggQNMIIECQIBATCBkzB8
'' SIG '' MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
'' SIG '' bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWlj
'' SIG '' cm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNy
'' SIG '' b3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAbof
'' SIG '' Pxn3wXW9fAABAAABujANBglghkgBZQMEAgEFAKCCAUow
'' SIG '' GgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqG
'' SIG '' SIb3DQEJBDEiBCA8F0v57f9rVRWlCWY/VlrOLpIsOt4B
'' SIG '' athRA2uDf3QqRTCB+gYLKoZIhvcNAQkQAi8xgeowgecw
'' SIG '' geQwgb0EIClVvTwzbnD61gZayaUa2nWDLWc9ypZ+qAwX
'' SIG '' eeVZhXMFMIGYMIGApH4wfDELMAkGA1UEBhMCVVMxEzAR
'' SIG '' BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
'' SIG '' bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
'' SIG '' bjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAg
'' SIG '' UENBIDIwMTACEzMAAAG6Hz8Z98F1vXwAAQAAAbowIgQg
'' SIG '' yRKgm0XhnswcNGq+mhKWttrFBk3M1Pg2UyOGdT4YZoEw
'' SIG '' DQYJKoZIhvcNAQELBQAEggIAdiV6qGpl3LRxkZGzz1dL
'' SIG '' 2vgZKGJO4iH6Hi6gRwCv21qM24l/Wa0ipdNryhQrx8/5
'' SIG '' o/nNPLFB1YQcDTbQFqI84EY1kHRwhPxJwMUqj2XtPrkE
'' SIG '' +Tv4+nNwPWHRRXk/++jKVmSEk3K6wTbMSrKcxIzqMFYW
'' SIG '' vri+Ifrf9WN018G/v78bbifuR/uZBFpIQOEcD3E8sSL7
'' SIG '' 4tggc8ArfQdJcS3/5KCe9ZW/shat90uzxLwLZFrKygWR
'' SIG '' V5pnbHBFXaRrQR6ZquuNNXAeZalycdxfHQIa1exylPiW
'' SIG '' A0VANvBas7C4hBJG3ujQESkop1FU2OwWUhrRRRJjyhwX
'' SIG '' KogpC/xv7ylfB31gZ4oaTYYJl/5wbFUiablhAsP6whIk
'' SIG '' 1XmZSvY+wnlOj9U/OBkomgL3WXnNizrpbNWMqBe1stZs
'' SIG '' 7MRtRgFJL445PPJp2OIqEFH9n471ZiC78czxp8FXDoJE
'' SIG '' vT0FOBKknkdK8BjoEyVMy+NbJXMhKDEyiTu94sVOtdj5
'' SIG '' +LyHpu700A4HGY/sBp7Usa/P7XM8xIWnUSQdN7lOI/Kg
'' SIG '' 4ybg1B5QLqOD5T74kpMf7g/YB8QYVYDcZJMJdacBA4ld
'' SIG '' HElgpwwKzRq+v37y/wiqZQ3oz0e5wV8W2EECX52SZYNw
'' SIG '' ZgDPnCDFRzxoWjMMalpZDUTBuw9aYzCXIjdXCIMshVhpOT0=
'' SIG '' End signature block
