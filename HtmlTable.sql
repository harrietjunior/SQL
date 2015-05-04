/*

Author: Leigh Haynes
Date: February 2015
Notes: takes a table name as parameter and returns a string that contains html markup to display the table contents as an html table.



*/


CREATE PROCEDURE [dbo].[HtmlTable]
	@data_source varchar (100) = NULL,
	@tableHTML varchar(max) OUTPUT
AS

SET NOCOUNT ON;

DECLARE 
	@db varchar(50), 
	@table varchar(100), 
	@cmd varchar(400), 
	@rcd_cnt int,
	@sql nvarchar(1000);

--use procedure DataSourceCheck to see if @data_source is valid
EXEC dbo.DataSourceCheck @data_source, @db output, @table output;
	
IF @db is NULL --if the data source is not good, @db comes back NULL and @table holds info as to the problem.
BEGIN
	SET @tableHtml = @table;
	RETURN;
END;

--We have a good table. Use information_schema metadata for table to get column names.
IF OBJECT_ID ('tempdb..##columnNames') IS not null DROP TABLE ##columnNames;
CREATE table ##columnNames (column_name varchar(50), position int identity);

SET @sql = 'USE ' + @db + '; INSERT into ##columnNames SELECT column_name from information_schema.columns where table_name = ''' + @table + ''' order by ordinal_position';
EXEC master.sys.sp_executesql @sql;

--use ##columnNames to create a temp table with the proper number of fields to hold data
IF OBJECT_ID ('tempdb..##columnPivot') IS not null DROP TABLE ##columnPivot;
CREATE table ##columnPivot (f1 varchar(200));

DECLARE 
	@i int = 2,
	@fieldct int, 
	@column varchar(50), 
	@field varchar(200),
	@value varchar(100), 
	@html varchar(max) = '';
	
SET @fieldct = (SELECT COUNT(*) from ##columnNames);
WHILE @i <= @fieldct --loop through adding a field to ##columnPivot for each column. Max field len is 200.
BEGIN
	SET @sql = 'ALTER table ##columnPivot ADD f' + cast (@i as varchar(2)) + ' varchar(200)';
	EXEC master.sys.sp_executesql @sql;
	SET @i = @i + 1;
END

--at this point, ##columnPivot is constructed but empty.
SET @sql = 'INSERT into ##columnPivot SELECT ';
SET @i = 1;
SET @fieldct = (SELECT count(*) from ##columnNames);

WHILE @i <= @fieldct - 1
BEGIN
	SET @column = (SELECT top 1 column_name from ##columnNames where position = cast (@i as varchar(2)));
	SET @field = 'CAST([' + @column + '] as varchar(200)),';
	SET @sql = @sql + @field;
	SET @i = @i + 1;
END
SET @column = (SELECT top 1 column_name from ##columnNames where position = @fieldct);
SET @field = 'CAST([' + @column + '] as varchar(200)) FROM ' + @data_source;
SET @sql = @sql + @field;
EXEC master.sys.sp_executesql @sql;
--##columnPivot now contains the report data with a header row.

--formatting
IF OBJECT_ID ('tempdb..#cn') IS not null DROP TABLE #cn;
--use a copy of ##columnnames because next steps delete from ##columnnames, and you will need ##columnnames further below. Does not need to be a global temp.
SELECT *
into #cn
from ##columnNames
order by position;

SET @fieldct = (SELECT count(*) from #cn);
SET @i = 1;

--set up the header row for the table
WHILE @i <= @fieldct 
BEGIN
	SET @field = (SELECT top 1 column_name from #cn order by position);
	SET @html = @html + '<td bgcolor="#dedede"><b>' + @field + '</b></td>';
	SET @i = @i + 1;
	DELETE from #cn where column_name = @field;
END

SET @html = '<tr>' + @html + '</tr>';

--now will work through the data row by row. 
ALTER table ##columnPivot add id_key int identity;

DECLARE 
	@j int = 1, 
	@fieldcnt int, 
	@cell varchar(100), 
	@row varchar(500) = '';

SET @i = 1;
SET @fieldcnt = (SELECT count(*) from ##columnNames);
SET @rcd_cnt = (SELECT count(*) from ##columnPivot);

WHILE @i <= @rcd_cnt
BEGIN
	SET @j = 1;
	WHILE @j <= @fieldcnt
	BEGIN
		SET @sql = 'SELECT @value = f' + cast (@j as varchar(2)) + ' from ##columnPivot where id_key = ' + cast (@i as varchar(2));
		EXEC master.sys.sp_executesql @sql, N'@value varchar(200) OUTPUT', @value OUTPUT;
		SET @cell = '<td>' + ISNULL (@value, '<br>') + '</td>'; --need to use <br> if the cell is empty
		SET @row = @row + @cell;
		SET @j = @j + 1;
	END
	SET @row = '<tr>' + @row + '</tr>';		
	SET @html = @html + @row;
	SET @row = '';
	DELETE from ##columnPivot where id_key = cast (@i as varchar(2));
	SET @i = @i + 1;
END

SET @tableHTML = '<table border="1" cellspacing="0" cellpadding="5">' + @html + '</table><br>'; 
