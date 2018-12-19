## Description

This script can help to automatically change the service account/password for all Qlik Sense services.             
                                                                                               
## Prerequisits

The user with administrator privilege.

## Steps

1. Remotely login Qlik Sense server with the user who has the administrator privilege.

1. Notify all users the Qlik Sense server will be down and back in few minutes.

1. Open PowerShell and run as administrator

1. Run Set-QlikService-Credentials-AutoElevate powershell script.

1. Double check all services except Qlik Sense Database Service have new service account assigned. 

1. Double check whether all services are back to 'running' status or not. 

1. If one or two services was not running yet, simply start. 

1. Qlik Sense is now ready to use.

