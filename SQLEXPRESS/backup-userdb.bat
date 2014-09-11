echo off
sqlcmd -S %COMPUTERNAME%\SQLEXPRESS -U sa -P manager -i C:\MyTask\SQLEXPRESS\backup-userdb.sql > C:\MyTask\SQLEXPRESS\backup-userdb.log
exit