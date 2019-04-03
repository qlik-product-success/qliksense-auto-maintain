#Requires -RunAsAdministrator

MIT License
Copyright (c) 2018 Qlik Support
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
<# .SYNOPSIS Change all Data Connections' password for the specific user.
.DESCRIPTION This script will allow to change all data connections' password the specific user owns. It is quite useful especially when service account's password get expired and reset. .NOTES To run this script, Qlik-Cli needs to be installed firstly. Otherwise please run below files firstly before running this script: 1. qlik-cli-install 2. Connect-cli 3. set-qlik-license
#>

$QlikHostName="qlik.server.com"  

Get-ChildItem -Path "Cert:\CurrentUser\my" |Where-Object {$_.Issuer-like"$QlikHostName"} | Connect-Qlik "$QlikHostName" -TrustAllCerts -Username "$username"  

$username = read-host -Prompt 'Input the user id the data connections password will get updated'

$password = read-host -Prompt 'Input the new password' -AsSecureString  

$credential = New-Object System.Management.Automation.PSCredential ("$username",$password)  

Get-QlikDataConnection | Where-object { $.username -eq "$username"} | ForEach-Object { Update-QlikDataConnection -id  $.id -Credential $credential }