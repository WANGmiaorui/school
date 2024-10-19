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
'' SIG '' MIImewYJKoZIhvcNAQcCoIImbDCCJmgCAQExDzANBglg
'' SIG '' hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
'' SIG '' BgEEAYI3AgEeMCQCAQEEEE7wKRaZJ7VNj+Ws4Q8X66sC
'' SIG '' AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
'' SIG '' t2OGjVuwrDi7m9eD1oGHZt1e8mT97G6PYHdAzoXpmRWg
'' SIG '' ggt2MIIE/jCCA+agAwIBAgITMwAABP5ZyrfmKqUiwQAA
'' SIG '' AAAE/jANBgkqhkiG9w0BAQsFADB+MQswCQYDVQQGEwJV
'' SIG '' UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
'' SIG '' UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
'' SIG '' cmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBT
'' SIG '' aWduaW5nIFBDQSAyMDEwMB4XDTIzMDIxNjIwMTEwOVoX
'' SIG '' DTI0MDEzMTIwMTEwOVowdDELMAkGA1UEBhMCVVMxEzAR
'' SIG '' BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
'' SIG '' bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
'' SIG '' bjEeMBwGA1UEAxMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
'' SIG '' MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
'' SIG '' z3f7xCys04gd0YOCNV0ne5cF0lBv/2JHBY9tq3TcTFD0
'' SIG '' vhKbavNE5YR9N8bSBMq22FfukubOwgmOgo4XWtn6CTnM
'' SIG '' lWsjyjq0MmGaMPCmyCgy/0BGn2a/rG18t+HPJxsHioKl
'' SIG '' 41XwsiRbke8LUZGk1fpooi87E3Ackx1Pi83W+GPuQRGL
'' SIG '' XTCcAiJCGPZF08ggB5t/9cfRgC1qblD0R8jgbA0HAoTh
'' SIG '' p73rSgVWITkZ/GNy2/9gZ8EE/liFXUJarBfMoVcD4Hse
'' SIG '' 6hHx6Imp614Qvlh/tQG2g9G6onLXnkSWERsRnQeWAdQZ
'' SIG '' sNtVt9Yl6f4a8wpyvJpR1QlAwu+JUjTSLwIDAQABo4IB
'' SIG '' fTCCAXkwHwYDVR0lBBgwFgYKKwYBBAGCNz0GAQYIKwYB
'' SIG '' BQUHAwMwHQYDVR0OBBYEFL0GxbHi+uJ81vGc16kH8ISx
'' SIG '' 7qA4MFQGA1UdEQRNMEukSTBHMS0wKwYDVQQLEyRNaWNy
'' SIG '' b3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQx
'' SIG '' FjAUBgNVBAUTDTIzMDg2NSs1MDAyMzMwHwYDVR0jBBgw
'' SIG '' FoAU5vxfe7siAFjkck619CF0IzLm76wwVgYDVR0fBE8w
'' SIG '' TTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQuY29t
'' SIG '' L3BraS9jcmwvcHJvZHVjdHMvTWljQ29kU2lnUENBXzIw
'' SIG '' MTAtMDctMDYuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggr
'' SIG '' BgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQuY29t
'' SIG '' L3BraS9jZXJ0cy9NaWNDb2RTaWdQQ0FfMjAxMC0wNy0w
'' SIG '' Ni5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsF
'' SIG '' AAOCAQEAAiqCfEyn5tk7Q32rie2d/w/FVI3KSuCdt80y
'' SIG '' oJW/S+kGg3iq/h3vaQ+2IO+Dw5loWSnDXHkEnuQRXAyo
'' SIG '' ylqphbvOaoyJA2+c56gLVcqtssQUuMhsjId3mPE6W6gU
'' SIG '' WlxHCPcwSjJv47Pk7zknr9uBJOcu665WTiD16mYz0nMe
'' SIG '' j86lvbQtxhZ8yXhOk2kyJwysZTM0QjEcRYEklNayF4/T
'' SIG '' XrtwHskCnpnYUP+8OW1vnrZGgY03a+78iJ5j5WJs37E+
'' SIG '' aDswD0d1Fk37i5OViDP7wI3lrclE7DauMebF/5s4X7tv
'' SIG '' 6li62T0iHPcynxwbUz48OILfGmlOgM4XXF2n81hanjCC
'' SIG '' BnAwggRYoAMCAQICCmEMUkwAAAAAAAMwDQYJKoZIhvcN
'' SIG '' AQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
'' SIG '' YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
'' SIG '' VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xMjAwBgNV
'' SIG '' BAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1
'' SIG '' dGhvcml0eSAyMDEwMB4XDTEwMDcwNjIwNDAxN1oXDTI1
'' SIG '' MDcwNjIwNTAxN1owfjELMAkGA1UEBhMCVVMxEzARBgNV
'' SIG '' BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
'' SIG '' HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEo
'' SIG '' MCYGA1UEAxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQ
'' SIG '' Q0EgMjAxMDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
'' SIG '' AQoCggEBAOkOZFB5Z7XE4/0JAEyelKz3VmjqRNjPxVhP
'' SIG '' qaV2fG1FutM5krSkHvn5ZYLkF9KP/UScCOhlk84sVYS/
'' SIG '' fQjjLiuoQSsYt6JLbklMaxUH3tHSwokecZTNtX9LtK8I
'' SIG '' 2MyI1msXlDqTziY/7Ob+NJhX1R1dSfayKi7VhbtZP/iQ
'' SIG '' tCuDdMorsztG4/BGScEXZlTJHL0dxFViV3L4Z7klIDTe
'' SIG '' XaallV6rKIDN1bKe5QO1Y9OyFMjByIomCll/B+z/Du2A
'' SIG '' EjVMEqa+Ulv1ptrgiwtId9aFR9UQucboqu6Lai0FXGDG
'' SIG '' tCpbnCMcX0XjGhQebzfLGTOAaolNo2pmY3iT1TDPlR8C
'' SIG '' AwEAAaOCAeMwggHfMBAGCSsGAQQBgjcVAQQDAgEAMB0G
'' SIG '' A1UdDgQWBBTm/F97uyIAWORyTrX0IXQjMubvrDAZBgkr
'' SIG '' BgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMC
'' SIG '' AYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV
'' SIG '' 9lbLj+iiXGJo0T2UkFvXzpoYxDBWBgNVHR8ETzBNMEug
'' SIG '' SaBHhkVodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtp
'' SIG '' L2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAxMC0w
'' SIG '' Ni0yMy5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUF
'' SIG '' BzAChj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
'' SIG '' L2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNy
'' SIG '' dDCBnQYDVR0gBIGVMIGSMIGPBgkrBgEEAYI3LgMwgYEw
'' SIG '' PQYIKwYBBQUHAgEWMWh0dHA6Ly93d3cubWljcm9zb2Z0
'' SIG '' LmNvbS9QS0kvZG9jcy9DUFMvZGVmYXVsdC5odG0wQAYI
'' SIG '' KwYBBQUHAgIwNB4yIB0ATABlAGcAYQBsAF8AUABvAGwA
'' SIG '' aQBjAHkAXwBTAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJ
'' SIG '' KoZIhvcNAQELBQADggIBABp071dPKXvEFoV4uFDTIvwJ
'' SIG '' nayCl/g0/yosl5US5eS/z7+TyOM0qduBuNweAL7SNW+v
'' SIG '' 5X95lXflAtTx69jNTh4bYaLCWiMa8IyoYlFFZwjjPzwe
'' SIG '' k/gwhRfIOUCm1w6zISnlpaFpjCKTzHSY56FHQ/JTrMAP
'' SIG '' MGl//tIlIG1vYdPfB9XZcgAsaYZ2PVHbpjlIyTdhbQfd
'' SIG '' UxnLp9Zhwr/ig6sP4GubldZ9KFGwiUpRpJpsyLcfShoO
'' SIG '' aanX3MF+0Ulwqratu3JHYxf6ptaipobsqBBEm2O2smmJ
'' SIG '' BsdGhnoYP+jFHSHVe/kCIy3FQcu/HUzIFu+xnH/8IktJ
'' SIG '' im4V46Z/dlvRU3mRhZ3V0ts9czXzPK5UslJHasCqE5XS
'' SIG '' jhHamWdeMoz7N4XR3HWFnIfGWleFwr/dDY+Mmy3rtO7P
'' SIG '' J9O1Xmn6pBYEAackZ3PPTU+23gVWl3r36VJN9HcFT4XG
'' SIG '' 2Avxju1CCdENduMjVngiJja+yrGMbqod5IXaRzNij6TJ
'' SIG '' kTNfcR5Ar5hlySLoQiElihwtYNk3iUGJKhYP12E8lGhg
'' SIG '' Uu/WR5mggEDuFYF3PpzgUxgaUB04lZseZjMTJzkXeIc2
'' SIG '' zk7DX7L1PUdTtuDl2wthPSrXkizON1o+QEIxpB8QCMJW
'' SIG '' nL8kXVECnWp50hfT2sGUjgd7JXFEqwZq5tTG3yOalnXF
'' SIG '' MYIaXTCCGlkCAQEwgZUwfjELMAkGA1UEBhMCVVMxEzAR
'' SIG '' BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
'' SIG '' bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
'' SIG '' bjEoMCYGA1UEAxMfTWljcm9zb2Z0IENvZGUgU2lnbmlu
'' SIG '' ZyBQQ0EgMjAxMAITMwAABP5ZyrfmKqUiwQAAAAAE/jAN
'' SIG '' BglghkgBZQMEAgEFAKCCAQQwGQYJKoZIhvcNAQkDMQwG
'' SIG '' CisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisG
'' SIG '' AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKK6iEgLHrRN
'' SIG '' tkju0ARNJFYXKWBPVpnuyofrkEcDFCOSMDwGCisGAQQB
'' SIG '' gjcKAxwxLgwsc1BZN3hQQjdoVDVnNUhIcll0OHJETFNN
'' SIG '' OVZ1WlJ1V1phZWYyZTIyUnM1ND0wWgYKKwYBBAGCNwIB
'' SIG '' DDFMMEqgJIAiAE0AaQBjAHIAbwBzAG8AZgB0ACAAVwBp
'' SIG '' AG4AZABvAHcAc6EigCBodHRwOi8vd3d3Lm1pY3Jvc29m
'' SIG '' dC5jb20vd2luZG93czANBgkqhkiG9w0BAQEFAASCAQCf
'' SIG '' AtVldIHXcKbh4i9BKH/m+EpOPEbz6mKHbhBPSUo5pioc
'' SIG '' +KJZBPshcjm1+rFFba9y+W96craUgbmsgxlQJTsBaHjU
'' SIG '' gqsZj4rZoYtB3tebVhNGGO8miaxq/oKtRWpEXBSNzi9g
'' SIG '' YUMMZ4PjUgelqa1mx5UR2sm7TGnkJfPXliXpjMGohbEP
'' SIG '' jnahfPl1B7mikrvs0/erWJQ0NbCdaMwUd1kn0yQJok3e
'' SIG '' VQsIYq+fBeuFf81MbaDDdt8Mdz7cexUbemOrYEmie7YC
'' SIG '' hLFmHqUgM+3jf2GMVfFco+DbefU/ciO9/qhW4vDkUgfH
'' SIG '' hwkhrCp2EGkUnxtwUa8FG/JLRJwvy78OoYIXkDCCF4wG
'' SIG '' CisGAQQBgjcDAwExghd8MIIXeAYJKoZIhvcNAQcCoIIX
'' SIG '' aTCCF2UCAQMxDzANBglghkgBZQMEAgEFADCCAU4GCyqG
'' SIG '' SIb3DQEJEAEEoIIBPQSCATkwggE1AgEBBgorBgEEAYRZ
'' SIG '' CgMBMDEwDQYJYIZIAWUDBAIBBQAEILw1KJCX6QPb7tVh
'' SIG '' BFDv6GGbiwOOuNZecnUoxTIVFL0qAgZlA/cKIcsYDzIw
'' SIG '' MjMwOTMwMTM0NzI4WjAEgAIB9KCB0aSBzjCByzELMAkG
'' SIG '' A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
'' SIG '' BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
'' SIG '' dCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0
'' SIG '' IEFtZXJpY2EgT3BlcmF0aW9uczEnMCUGA1UECxMeblNo
'' SIG '' aWVsZCBUU1MgRVNOOjhEMDAtMDVFMC1EOTQ3MSUwIwYD
'' SIG '' VQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
'' SIG '' oIIR6jCCByAwggUIoAMCAQICEzMAAAHNVQcq58rBmR0A
'' SIG '' AQAAAc0wDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMC
'' SIG '' VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
'' SIG '' B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
'' SIG '' b3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
'' SIG '' U3RhbXAgUENBIDIwMTAwHhcNMjMwNTI1MTkxMjA1WhcN
'' SIG '' MjQwMjAxMTkxMjA1WjCByzELMAkGA1UEBhMCVVMxEzAR
'' SIG '' BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
'' SIG '' bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
'' SIG '' bjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3Bl
'' SIG '' cmF0aW9uczEnMCUGA1UECxMeblNoaWVsZCBUU1MgRVNO
'' SIG '' OjhEMDAtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3Nv
'' SIG '' ZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkqhkiG
'' SIG '' 9w0BAQEFAAOCAg8AMIICCgKCAgEA0zgi1Uto5hFjqsc8
'' SIG '' oFu7OmC5ptvaY7wPgoelS+x5Uy/MlLd2dCiM02tjvx76
'' SIG '' /2ic2tahFZJauzT4jq6QQCM+uey1ccBHOAcSYr+gevGv
'' SIG '' A0IhelgBRTWit1h4u038UZ6i6IYDc+72T8pWUF+/ea/D
'' SIG '' EL1+ersI4/0eIV50ezWuC5buJlrJpf8KelSagrsWZ7vY
'' SIG '' 1+KmlMZ4HK3xU+/s75VwpcC2odp9Hhip2tXTozoMitNI
'' SIG '' 2Kub7c6+TWfqlcamsPQ5hLI/b36mJH0Ga8tiTucJoF1+
'' SIG '' /TsezyzFH6k+PvMOSZHUjKF99m9Q+nAylkVL+ao4mIeK
'' SIG '' P2vXoRPygJFFpUj22w0f2hpzySwBj8tqgPe2AgXniCY0
'' SIG '' SlEYHT5YROTuOpDo7vJ2CZyL8W7gtkKdo8cHOqw/TOj7
'' SIG '' 3PLGSHENdGCmVWCrPeGD0pZIcF8LbW0WPo2Z0Ig5tmRY
'' SIG '' x/Ej3tSOhEXH3mF9cwmIxM3cFnJvnxWZpSQPR0Fu2SQJ
'' SIG '' jhAjjbXytvBERBBOcs6vk90DFT4YhHxIYHGLIdA3qFom
'' SIG '' BrA4ihLkvhRJTDMk+OevlNmUWtoW0UPe0HG72gHejlUC
'' SIG '' 6d00KjRLtHrOWatMINggA3/kCkEf2OvnxoJPaiTSVtzL
'' SIG '' u+9SrYbj5TXyrLNAdc4dMWtcjeKgt86BPVKuk/K+xt/z
'' SIG '' rUhZrOMCAwEAAaOCAUkwggFFMB0GA1UdDgQWBBShk/mm
'' SIG '' NmmawQCVSGYeZInKJHzVmjAfBgNVHSMEGDAWgBSfpxVd
'' SIG '' AF5iXYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSgUqBQ
'' SIG '' hk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
'' SIG '' L2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENB
'' SIG '' JTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBeMFwG
'' SIG '' CCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
'' SIG '' b20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUt
'' SIG '' U3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNVHRMB
'' SIG '' Af8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMA4G
'' SIG '' A1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEA
'' SIG '' Uqht6aSiFPovxDMMLaLaMZyn8NEl/909ehD248LACJlj
'' SIG '' meZywG2raKZfMxWPONYG+Xoi9Y/NYeA4hIl7fgSYByAN
'' SIG '' iyISoUrHHe/aDG6+t9Q4hKn/V+S2Ud1dyiGLLVNyu3+Q
'' SIG '' 5O7W6G7h7vun2DP4DseOLIEVO2EPmE2B77/JOJjJ7omo
'' SIG '' SUZVPxdr2r3B1OboV4tO/CuJ0kQD51sl+4FYuolTAQVB
'' SIG '' ePNt6Dxc5xHB7qe1TRkbRntcb55THdQrssXLTPHf6Ksk
'' SIG '' 7McJSQDORf5Q8ZxFqEswJGndZ1r5GgHjFe/t/SKV4bn/
'' SIG '' Rt8W33yosgZ493EHogOEsUsAnZ8dNEQZV0uq/bRg2v6P
'' SIG '' UUtNRTgAcypD+QgQ6ZuMKSnSFO+CrQR9rBOUGGJ+5YmF
'' SIG '' ma9n/1PoIU5nThDj5FxHF/NR+HUSVNvE4/4FGXcC/NcW
'' SIG '' ofCp/nAe7zPx7N/yfLRdd2Tz/vDbV977uDa3IRwyWIIz
'' SIG '' ovtSbkn/uI6Rf6RBD16fQLrIs5kppASuIlU+zcFbUZ0t
'' SIG '' bbPKgBhxj4Nhz2uG9rvZnrnlKKjVbTIW7piNcvnfWZE4
'' SIG '' TVwV89miLU9gvfQzN096mKgFJrylK8lUqTC1abHuI3uV
'' SIG '' jelVZQgxSlhUR9tNmMRFVrGeW2jfQmqgmwktBGu7PThS
'' SIG '' 2hDOXzZ/ZubOvZQ/3pHFtqkwggdxMIIFWaADAgECAhMz
'' SIG '' AAAAFcXna54Cm0mZAAAAAAAVMA0GCSqGSIb3DQEBCwUA
'' SIG '' MIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
'' SIG '' Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
'' SIG '' TWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylN
'' SIG '' aWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3Jp
'' SIG '' dHkgMjAxMDAeFw0yMTA5MzAxODIyMjVaFw0zMDA5MzAx
'' SIG '' ODMyMjVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
'' SIG '' YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
'' SIG '' VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
'' SIG '' BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
'' SIG '' MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
'' SIG '' 5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwHB9KpbE51yMo1
'' SIG '' V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64NmeF
'' SIG '' RiMMtY0Tz3cywBAY6GB9alKDRLemjkZrBxTzxXb1hlDc
'' SIG '' wUTIcVxRMTegCjhuje3XD9gmU3w5YQJ6xKr9cmmvHaus
'' SIG '' 9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl3GoPz130
'' SIG '' /o5Tz9bshVZN7928jaTjkY+yOSxRnOlwaQ3KNi1wjjHI
'' SIG '' NSi947SHJMPgyY9+tVSP3PoFVZhtaDuaRr3tpK56KTes
'' SIG '' y+uDRedGbsoy1cCGMFxPLOJiss254o2I5JasAUq7vnGp
'' SIG '' F1tnYN74kpEeHT39IM9zfUGaRnXNxF803RKJ1v2lIH1+
'' SIG '' /NmeRd+2ci/bfV+AutuqfjbsNkz2K26oElHovwUDo9Fz
'' SIG '' pk03dJQcNIIP8BDyt0cY7afomXw/TNuvXsLz1dhzPUNO
'' SIG '' wTM5TI4CvEJoLhDqhFFG4tG9ahhaYQFzymeiXtcodgLi
'' SIG '' Mxhy16cg8ML6EgrXY28MyTZki1ugpoMhXV8wdJGUlNi5
'' SIG '' UPkLiWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFdEtsluq9Q
'' SIG '' BXpsxREdcu+N+VLEhReTwDwV2xo3xwgVGD94q0W29R6H
'' SIG '' XtqPnhZyacaue7e3PmriLq0CAwEAAaOCAd0wggHZMBIG
'' SIG '' CSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUCBBYE
'' SIG '' FCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQWBBSf
'' SIG '' pxVdAF5iXYP05dJlpxtTNRnpcjBcBgNVHSAEVTBTMFEG
'' SIG '' DCsGAQQBgjdMg30BATBBMD8GCCsGAQUFBwIBFjNodHRw
'' SIG '' Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3Mv
'' SIG '' UmVwb3NpdG9yeS5odG0wEwYDVR0lBAwwCgYIKwYBBQUH
'' SIG '' AwgwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYD
'' SIG '' VR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0j
'' SIG '' BBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQwVgYDVR0f
'' SIG '' BE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQu
'' SIG '' Y29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0
'' SIG '' XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4wTDBK
'' SIG '' BggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQu
'' SIG '' Y29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0w
'' SIG '' Ni0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIBAJ1Vffwq
'' SIG '' reEsH2cBMSRb4Z5yS/ypb+pcFLY+TkdkeLEGk5c9MTO1
'' SIG '' OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGhlBgi7ulmZzpT
'' SIG '' Td2YurYeeNg2LpypglYAA7AFvonoaeC6Ce5732pvvinL
'' SIG '' btg/SHUB2RjebYIM9W0jVOR4U3UkV7ndn/OOPcbzaN9l
'' SIG '' 9qRWqveVtihVJ9AkvUCgvxm2EhIRXT0n4ECWOKz3+SmJ
'' SIG '' w7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWKNsIdw2Fz
'' SIG '' Lixre24/LAl4FOmRsqlb30mjdAy87JGA0j3mSj5mO0+7
'' SIG '' hvoyGtmW9I/2kQH2zsZ0/fZMcm8Qq3UwxTSwethQ/gpY
'' SIG '' 3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+c23Kjgm9swFX
'' SIG '' SVRk2XPXfx5bRAGOWhmRaw2fpCjcZxkoJLo4S5pu+yFU
'' SIG '' a2pFEUep8beuyOiJXk+d0tBMdrVXVAmxaQFEfnyhYWxz
'' SIG '' /gq77EFmPWn9y8FBSX5+k77L+DvktxW/tM4+pTFRhLy/
'' SIG '' AsGConsXHRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0+CQ1
'' SIG '' ZyvgDbjmjJnW4SLq8CdCPSWU5nR0W2rRnj7tfqAxM328
'' SIG '' y+l7vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJtpQUQwXEG
'' SIG '' ahC0HVUzWLOhcGbyoYIDTTCCAjUCAQEwgfmhgdGkgc4w
'' SIG '' gcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
'' SIG '' dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
'' SIG '' aWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1p
'' SIG '' Y3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNV
'' SIG '' BAsTHm5TaGllbGQgVFNTIEVTTjo4RDAwLTA1RTAtRDk0
'' SIG '' NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAg
'' SIG '' U2VydmljZaIjCgEBMAcGBSsOAwIaAxUAaKn3ptiis7kW
'' SIG '' YyEmInxqJVTncgSggYMwgYCkfjB8MQswCQYDVQQGEwJV
'' SIG '' UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
'' SIG '' UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
'' SIG '' cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1T
'' SIG '' dGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQsFAAIFAOjC
'' SIG '' Os8wIhgPMjAyMzA5MzAwNjEyMzFaGA8yMDIzMTAwMTA2
'' SIG '' MTIzMVowdDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA6MI6
'' SIG '' zwIBADAHAgEAAgIJ+jAHAgEAAgIU4DAKAgUA6MOMTwIB
'' SIG '' ADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMC
'' SIG '' oAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3
'' SIG '' DQEBCwUAA4IBAQAv40mSo597QZCpZNxrfI/Uh+myixmp
'' SIG '' xeQIYdv3/MheL2ToteqjDrMeMYXGKr7dGxjYNi31xClg
'' SIG '' 2FWo4n5ZSpAu7l6r3m7NVhllIbL+WqK0V9arLoSiD95L
'' SIG '' 611crc/IZ4+gpFPlQBV1GMaA6ytvuzVZbkflCpKoPdSw
'' SIG '' 5QbMhBnM6CfSEl5adxh7W+V5kYdggoo+7yOXN5BADkYU
'' SIG '' 9lFuZRA/L1sIFOh/Hq9q0stsa6UdrQFtOBs6WWXqe9Dj
'' SIG '' WBpvuO7i5wolSHlRGnTGwZr5NeuqtEgMyOja1PqO9NpM
'' SIG '' JiDvRstSokSuGUikD3M4Ctj6Wcf/b7gsEpH4cPuSUt6U
'' SIG '' 78agMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMCVVMx
'' SIG '' EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
'' SIG '' ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
'' SIG '' dGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3Rh
'' SIG '' bXAgUENBIDIwMTACEzMAAAHNVQcq58rBmR0AAQAAAc0w
'' SIG '' DQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzEN
'' SIG '' BgsqhkiG9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQgxcw/
'' SIG '' rGbGFiMYE9RHZ6FM7XqT1hRiJsgRgDIDKsvt7jkwgfoG
'' SIG '' CyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCDiZqX4rVa9
'' SIG '' T2RoL0xHU6UrVHOhjYeyza6EASsKVEaZCjCBmDCBgKR+
'' SIG '' MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
'' SIG '' dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
'' SIG '' aWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
'' SIG '' Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB
'' SIG '' zVUHKufKwZkdAAEAAAHNMCIEIJWOvMSifgyZSMi8vfCr
'' SIG '' zPXCTi/E9J8jt1YVJp7vP2JRMA0GCSqGSIb3DQEBCwUA
'' SIG '' BIICAKTwI2IyXcNXfkVf8ST0OHeGm2YMAIgGrY4NDWZ5
'' SIG '' wX6y9Q7xQyRxj4aq1h6hMvP8gAr2rMlA+ESrh7l6+qBn
'' SIG '' YeeLXPAG+dfz7QKp7FgFjJmrydLotZNyEFveyWJg39Td
'' SIG '' 77PIuZ4MjegDwNVVdqvhLALG133y1cQrTFsLjtS3Cu4D
'' SIG '' 98ZiSX43EJPKSGfGnlwbqEuO6Tsk7ReOQk9Smm37hUm4
'' SIG '' gy9OJHq/+nIavDnGS7qUjaTzczDBsF3yfXh2Cccl+Rvf
'' SIG '' 2jSUFYc6fyX3KKxhhDsg+p7NOCEzbRvxJDYgZ2uoPSGz
'' SIG '' xZCZeyEv1DQHoiHqoilq771B+XoSpCKxIE4S2gasnG5j
'' SIG '' ti7RVgC6EAf98KZ+2TNeOGrkaMmqUwDY2yb/3Jbfj8y1
'' SIG '' pAVcOnJUngA3TrcIFugpXIX+VtSDzbU1Vyt+mzXR8jBH
'' SIG '' JvSKs2tBtAFeeLtQQ+k6sOOpABAT1j46ZkmCBSvm8y97
'' SIG '' cyST7KPekt7LRRfxz2wgi9ofJuARK16D3ShM5Gw6hPUQ
'' SIG '' E/Y83V7eEhJn0jjYDsa9pXZaUcQdsXzsQNycSM2XD9LN
'' SIG '' DkX8TQzbQT4ur7CaxNYpVQW2V236aVpKBLMFU0p9p8D1
'' SIG '' RQGPhAYXqw2Zvsc/wt+jBu/PoWR49Nt9ZqYBKNALG6WP
'' SIG '' cA5/+oikxxXwXBAlCoIOAB4RxGmb
'' SIG '' End signature block
