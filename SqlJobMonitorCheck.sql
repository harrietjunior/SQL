USE [Meta]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
02/19/15 Leigh

Created to make sure that the jobs that create job failure emails are running properly.

*/

CREATE PROC [dbo].[SqlJobMonitorCheck]

AS

DECLARE @sprocName varchar(200)
SET @sprocName = dbo.GetSprocName (NULL, DB_NAME(), SCHEMA_NAME(), OBJECT_NAME (@@PROCID))

SET NOCOUNT ON

DECLARE 
	@rundate datetime,
	@faildate datetime,
	@lag int,
	@bodyHtml varchar(400)

SET @rundate = (SELECT max (RunDate) from dbo.JobRunMessages where Server = 'SQLDM')
SET @lag = datediff (minute, @rundate, getdate())
PRINT @lag
--SELECT * from JobRunMessages order by id_key desc

IF ABS (@lag) > 20
BEGIN

	SET @bodyHtml = 'SQLDM Job SqlJobMonitor is not updating SQLDM table Meta.dbo.JobRunMessages as expected. The lag is ' + cast (@lag as varchar) + ' minutes. Check to make sure SQLDM Job SqlJobMonitor is running.<br><br>'
	
	EXEC dbo.EmailSend
		--SELECT * from Meta.dbo.EmailRecipients where Subject like 'SqlJobMonitor%'
		@sign = 1,
		@subject = 'SqlJobMonitor on SQLDM is not updating',
		@body = @bodyHtml,
		@body_format = 'HTML',
		@sproc = @sprocName 
	
END


SET @rundate = (SELECT max (RunDate) from dbo.JobRunMessages where Server = 'WORKI-SQL')
SET @lag = datediff (minute, @rundate, getdate())
PRINT @lag

IF ABS (@lag) > 20
BEGIN

	SET @bodyHtml = 'WORKI-SQL Job SqlJobMonitor is not updating SQLDM table Meta.dbo.JobRunMessages as expected. The lag is ' + cast (@lag as varchar) + ' minutes. Check to make sure WORKI-SQL Job SqlJobMonitor is running.<br><br>'

	EXEC dbo.EmailSend
		--SELECT * from Meta.dbo.EmailRecipients where Subject like 'SqlJobMonitor%'
		@sign = 1,
		@subject = 'SqlJobMonitor on WORKI-SQL is not updating',
		@body = @bodyHtml,
		@body_format = 'HTML',
		@sproc = @sprocName 
		
END


PRINT 'END ' + @sprocName

GO

