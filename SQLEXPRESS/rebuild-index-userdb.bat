echo off
sqlcmd -S %COMPUTERNAME%\SQLEXPRESS -U sa -P manager -i C:\MyTask\SQLEXPRESS\rebuild-index-UserDB.sql > C:\MyTask\SQLEXPRESS\rebuild-index-UserDB.log
exit