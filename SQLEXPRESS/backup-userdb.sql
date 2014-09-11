SET NOCOUNT ON

DECLARE @PCName			sysname
DECLARE @DBName			sysname
DECLARE @DriveName		nvarchar(max)
DECLARE @DirName		nvarchar(max)
DECLARE @DeviceName		nvarchar(max)
DECLARE @Description	nvarchar(max)

-- データベース・コンピュータ名を取得
SELECT @PCName = CONVERT(sysname, SERVERPROPERTY('MachineName'))
-- バックアップ・デバイスのドライブ名を判定
IF @PCName = 'NET-SVR1'
	SET @DriveName = N'C:'
ELSE
	SET @DriveName = N'D:'
-- バックアップ・デバイスのディレクトリ名を設定
SET @DirName = @DriveName + N'\Microsoft SQL Server\BACKUP'

-- データベース名の一覧を列挙
DECLARE [dbname_cursor] CURSOR FOR
SELECT
	D.name AS [DBName]
FROM
	sys.databases AS D
WHERE
	( D.name <> N'tempdb' )
ORDER BY
	D.name

OPEN [dbname_cursor]
FETCH NEXT FROM [dbname_cursor] INTO @DBName

WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT N'*****************************************************************************'
	PRINT N'*** データベース名 : [' + @DBName + N'] *** START *** ' +
			CONVERT(varchar(20),GETDATE(),111) + ' ' + CONVERT(varchar(20),GETDATE(),108)
	PRINT N'*****************************************************************************'
	PRINT N''

	SET @DeviceName		= @DirName + N'\' + @DBName + N'.bak'
	SET @Description	= @DBName + N' - 完全 データベース バックアップ'
	BACKUP DATABASE @DBName TO DISK = @DeviceName
					WITH NOFORMAT, INIT, NAME = @Description, SKIP, NOREWIND, NOUNLOAD, STATS = 10

	PRINT N''
	PRINT N'*** データベース名 : [' + @DBName + N'] *** E N D *** ' +
			CONVERT(varchar(20),GETDATE(),111) + ' ' + CONVERT(varchar(20),GETDATE(),108)
	PRINT N''

	FETCH NEXT FROM [dbname_cursor] INTO @DBName
END

CLOSE [dbname_cursor]
DEALLOCATE [dbname_cursor]

