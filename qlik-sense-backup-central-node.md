qlik-sense-backup-central-node.ps1
===

<!-- TOC -->

- [qlik-sense-backup-central-node.ps1](#qlik-sense-backup-central-nodeps1)
    - [Syntax](#syntax)
    - [Description](#description)
    - [Pre-Requisite](#pre-requisite)
        - [Multi-node environment](#multi-node-environment)
        - [Central Node](#central-node)
    - [Examples](#examples)
        - [Example 1](#example-1)
        - [Example 2: Define backup locaiotn and install Qlik CLI](#example-2-define-backup-locaiotn-and-install-qlik-cli)
        - [Example 3:](#example-3)
    - [Required Parameters](#required-parameters)
    - [Optional Parameters](#optional-parameters)
    - [License](#license)

<!-- /TOC -->

## Syntax

```
qlik-sense-backup-central-node.ps1
   [-CentralNode <String>]
   [-BackupFolder <String>]
   [-InstallQlikCLI <switch>]
```

## Description

This script automates backup of Qlik Sense Enterprise for Windows, by copying key items from Qlik Sense Central Node to backup storage.  

* Qlik Sense repository database
* Qlik Sense persistence storage
* Qlik Sense self-signed certificates

The script is expected to be run locally on the Qlik Sense central node. Any Qlik Sense rim nodes must be stopepd priot to running backup. 

See [Backup and restore Qlik Sense](https://help.qlik.com/en-US/sense/Subsystems/PlanningQlikSenseDeployments/Content/Deployment/Backup-and-restore.htm) for more details related to backup process and requirements.

## Pre-Requisite

### Multi-node environment

1. Notify any active users the Qlik Sense server will be down for maintenance
2. Stop all Qlik Sense services on all rim nodes
   
### Central Node

1. Local adminstrator access
1. [Qlik CLI](https://github.com/ahaydon/Qlik-Cli) installed, or internet access to allow download by script
1. Access to backup storage location (SMB fileshare or local disk)
1. Hostname used for signing certificates during Qlik installation

## Examples

### Example 1
```
.\qlik-sense-backup-central-node.ps1
```
Running the command without any parameters will prompt you for input of the backup locaiton. Central node hostname will be assume to be the local hostname or the server FQDN. 
Note, the execution will fail if Qlik CLI is not installed

### Example 2: Define backup locaiotn and install Qlik CLI
```
.\qlik-sense-backup-central-node.ps1 -BackupFolder "d:\backup\" -InstallQlikCLI
```
This execution stores backup to *d:\backup* and installs Qlik CLI during backup if it ca not be found.  

### Example 3: 
```
.\qlik-sense-backup-central-node.ps1 -BackupFolder "d:\backup\" -CentralNode "qlik.server.com"
```
Target backup location to *d:\backup* and extract self-signed certificates for *qlik.server.com*.  

## Required Parameters

N/A

## Optional Parameters

`-CentralNode`

Hostname used during Qlik Sense installation. Qlik Sense self-signed certificates will be exported base don that they are sigend by this host. 

`-BackupFolder`

Destination of backup. Local folder or file share. 

`-InstallQlikCLI`

Flag to indicate if Qlik CLI can be installed when missing.

`-ExcludeArciveLogs`

Flag to exclude the backup for archivelogs folder.  The Archivelogs must be backup through qlik-sense-maintain-archived-logs.ps1.


## License

This project is provided "AS IS", without any warranty, under the MIT License - see the [LICENSE](LICENSE) file for details.
