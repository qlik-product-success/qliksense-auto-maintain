$qlik_share_path  = "C:\Qlik-Share\ArchivedLogs"
$qlik_backup_path = "C:\Qlik-Backup\ArchivedLogs"
$days_in_share    = 90
$days_in_backup   = 180

# Copy all current archived logs form share to backup
# Remove files and fodlers older than limit from share

robocopy "$qlik_share_path" "$qlik_backup_path" /E

$limit = (Get-Date).AddDays(-$days_in_share)

Get-ChildItem -Path $qlik_share_path -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force
Get-ChildItem -Path $qlik_share_path -Recurse -Force | Where-Object { $_.PSIsContainer -and (Get-ChildItem -Path $_.FullName -Recurse -Force | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse

$limit = (Get-Date).AddDays(-$days_in_backup)

Get-ChildItem -Path $qlik_backup_path -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force
Get-ChildItem -Path $qlik_backup_path -Recurse -Force | Where-Object { $_.PSIsContainer -and (Get-ChildItem -Path $_.FullName -Recurse -Force | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse