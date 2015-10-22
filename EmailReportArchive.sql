SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
Author: Leigh
Date:		March 2014

*/


CREATE PROCEDURE [dbo].[EmailReportArchive]
   @file_attachments               VARCHAR(MAX)  = NULL

AS

DECLARE @sprocName varchar(200)
SET @sprocName = dbo.GetSprocName (NULL, DB_NAME(), SCHEMA_NAME(), OBJECT_NAME (@@PROCID))

SET NOCOUNT ON

CREATE table #files (filename varchar(200), folder varchar(200))
DECLARE @full_path varchar(200), @folder varchar(200), @len int, @filename_len int

--need to parse files in case there are multiple files in the attachment
WHILE @file_attachments like '%;%'
BEGIN
	SET @full_path = SUBSTRING (@file_attachments, 1, charindex (';', @file_attachments) - 1)
	SET @full_path = LTRIM (RTRIM (@full_path))
	SET @len = len (@full_path)
	SET @folder = REVERSE (@full_path)
	SET @filename_len = charindex ('\', @folder)
	SET @folder = SUBSTRING (@full_path, 1, @len - @filename_len + 1)
	INSERT into #files VALUES (@full_path, @folder)
	SET @file_attachments = SUBSTRING (@file_attachments, @len + 2, len (@file_attachments) - charindex (';', @file_attachments))
END 

SET @full_path = LTRIM (RTRIM (@file_attachments))
SET @len = len (@full_path)
SET @folder = REVERSE (@full_path)		
SET @filename_len = charindex ('\', @folder)
SET @folder = SUBSTRING (@full_path, 1, @len - @filename_len + 1)
INSERT into #files VALUES (@full_path, @folder)
--SELECT * from #files

DECLARE 
	@cmd varchar(300), 
	@archiveFolder varchar(200), 
	@filename varchar(200),
	@result int

WHILE (SELECT count(*) from #files) > 0
BEGIN
	SELECT @filename = filename, @folder = folder from #files order by filename
	SET @archiveFolder = @folder + 'Archive'	
	SET @cmd = 'DIR /b ' + @archiveFolder
	EXEC @result = master.sys.xp_cmdshell @cmd
	IF @result = 0 --archive folder exists
	BEGIN
		PRINT 'Archive folder exists'
	END
	ELSE
	BEGIN
		PRINT 'Archive folder needs to be created'
		SET @cmd = 'MKDIR ' + @archiveFolder
		--PRINT @cmd
		EXEC master.sys.xp_cmdshell @cmd
	END

	--SET @cmd = 'MOVE ' + @folder + '*.csv ' + @archiveFolder
	SET @cmd = 'MOVE ' + @filename + ' ' + @archiveFolder
	EXEC master.sys.xp_cmdshell @cmd
	DELETE from #files where filename = @filename
END

PRINT 'END ' + @sprocName



GO

