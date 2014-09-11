SET NOCOUNT ON

DECLARE @DBName		sysname
DECLARE @SQL		nvarchar(max)

-- ユーザ・データベース名の一覧を列挙
DECLARE [dbname_cursor] CURSOR FOR
SELECT
	D.name AS [DBName]
FROM
	sys.databases AS D
WHERE
	( D.name LIKE N'User%' )
	AND ( D.name <> N'UserFileStreamDB' )
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

	-- データベース名を変数化するためにＳＱＬ文を組み立てる
	SELECT @SQL = N'
	SET NOCOUNT ON

	USE [' + @DBName + ']

	DECLARE @SchemaName		sysname
	DECLARE @TableName		sysname
	DECLARE @SQL			nvarchar(max)

	-- インデックスの断片化率２０％以上のテーブルを列挙
	DECLARE [table_cursor] CURSOR FOR
	SELECT
		Schema_name(T.Schema_id) AS [schema_name]
	,	T.name AS [table_name]
	FROM
		sys.indexes AS I
	INNER JOIN
		sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
		ON I.object_id = indexstats.object_id
		AND I.index_id = indexstats.index_id
	INNER JOIN
		sys.tables AS T
		ON I.Object_id = T.Object_id
	WHERE ( indexstats.avg_fragmentation_in_percent >= 20 )
	GROUP BY
		T.Schema_id
	,	T.name
	ORDER BY
		Schema_name(T.Schema_id)
	,	T.name

	OPEN [table_cursor]
	FETCH NEXT FROM [table_cursor] INTO @SchemaName, @TableName

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- インデックスを再構築
		SET @SQL =
			N''ALTER INDEX ALL ON ['' + @SchemaName + N''].['' + @TableName + N''] REBUILD'' +
			N'' WITH (PAD_INDEX = OFF'' +
			N'', STATISTICS_NORECOMPUTE = OFF'' +
			N'', ALLOW_ROW_LOCKS = ON'' +
			N'', ALLOW_PAGE_LOCKS = ON'' +
			N'', SORT_IN_TEMPDB = ON'' +
			N'', ONLINE = OFF)''
		EXECUTE sp_executesql @SQL

		PRINT N''　テーブル名 : ['' + @SchemaName + N''].['' + @TableName + N'']''

		FETCH NEXT FROM [table_cursor] INTO @SchemaName, @TableName
	END

	CLOSE [table_cursor]
	DEALLOCATE [table_cursor]
	'
	-- ＳＱＬを実行
	EXEC sp_executesql @SQL, N'@DBName sysname', @DBName

	PRINT N''
	PRINT N'*** データベース名 : [' + @DBName + N'] *** E N D *** ' +
			CONVERT(varchar(20),GETDATE(),111) + ' ' + CONVERT(varchar(20),GETDATE(),108)
	PRINT N''

	FETCH NEXT FROM [dbname_cursor] INTO @DBName
END

CLOSE [dbname_cursor]
DEALLOCATE [dbname_cursor]

