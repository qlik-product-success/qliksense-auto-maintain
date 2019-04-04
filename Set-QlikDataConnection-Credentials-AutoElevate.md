# Description
This script can help to automatically change the data connections user id/password for all data connections the specific user owns.

# Prerequisits
The user with administrator privilege.

# Steps
1.Remotely login Qlik Sense server with the user who has the administrator privilege.

2.Notify all users the Qlik Sense server will be down and back in few minutes.

3.Open PowerShell and run as administrator

4.Run Set-QlikDataConnection-Credentials-AutoElevate powershell script.

5.Double check all services except Qlik Sense Database Service have new service account assigned.

6.Double check whether all services are back to 'running' status or not.

7.If one or two services was not running yet, simply start.

8.Qlik Sense is now ready to use.
