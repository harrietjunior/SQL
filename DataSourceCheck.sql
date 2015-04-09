/*

Leigh Haynes
March 2015
Takes the name of a table as parameter, checks validity, returns database and table name if valid.

*/


ALTER PROCEDURE [dbo].[DataSourceCheck] 
	@dataSource varchar (100) = NULL,
	@db varchar(50) = NULL output,
	@table varchar(100) = NULL output

AS

DECLARE 
	@buffer varchar(100),
	@object varchar(100),
	@objectId bigint,
	@schema varchar(50),
	@rcd_cnt int,
	@tableHtml varchar(200),
	@sql nvarchar(1000)
	
SET @buffer = @dataSource;

--cannot accesss a local temp table. Return.
IF SUBSTRING (@buffer, 1, 1) = '#' and SUBSTRING (@buffer, 2, 1) <> '#'
BEGIN
	SET @table = '<br>Cannot access local temp table ' + @dataSource + '.<br>';
	RETURN;
END;

--set up the object name in the right format so you can check the OBJECT_ID
ELSE IF (SUBSTRING (@buffer, 1, 2) = '##')
BEGIN
	SET @db = 'tempdb';
	SET @table = @dataSource;
	SET @object = @db + '..' + @table; --need to include tempdb so OBJECT_ID finds the temp table
END;
ELSE
BEGIN
	--deal with schema
	SET @db = SUBSTRING (@buffer, 1, charindex ('.', @buffer) - 1);
	SET @buffer = replace (@buffer, @db + '.', '');
	IF SUBSTRING (@buffer, 1, 1) = '.' 
	BEGIN
		SET @schema = '..';
		SET @buffer = replace (@buffer, '.', '');
	END
	ELSE 
	BEGIN
		SET @schema = SUBSTRING (@buffer, 1, charindex ('.', (@buffer)) - 1);
		SET @buffer = replace (@buffer, @schema + '.', '');
	END
	SET @table = @buffer;
	SET @object = @dataSource;
END;

--does our data source exist? Check the object_id. If object does not exist, return.
SET @objectId = OBJECT_ID (@object, 'U');
IF @objectId is NULL 
BEGIN
	SET @db = NULL;
	SET @table = '<br>Data source ' + @dataSource + ' is invalid or improperly qualified.<br>';
	RETURN;
END;

--we have a valid data source. Check that it has rows and notify if empty.
SET @sql = 'SELECT @rcd_cnt = count(*) from ' + @dataSource;
EXEC master.sys.sp_executesql @sql, N'@rcd_cnt int OUTPUT', @rcd_cnt OUTPUT; 
IF @rcd_cnt = 0 
BEGIN
	SET @db = NULL;
	SET @table = '<br>Table ' + @dataSource + ' is empty.<br>';
	RETURN;
END;
