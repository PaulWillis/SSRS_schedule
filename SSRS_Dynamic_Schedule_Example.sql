CREATE Proc dbo.usp_tvc_PromoSales_MonthToDate    
as          
            
declare @params nvarchar(max)          
declare @bodybuilt  varchar(max)          
declare @SubjectBuilt varchar(1000)          
declare @EmailAddress varchar(max)          
declare @Comment varchar(255)          
declare @SubjectPrefix varchar(255)          
    
    
set @SubjectBuilt = 'PromoSalesReport_MonthToDate'    
set @bodybuilt = 'PromoSalesReport_MonthToDate'    
set @Comment = 'executed by operations.dbo.usp_PromoSalesReport_MonthToDate'    
set @SubjectPrefix = 'Month To Date'    
          
set @EmailAddress =   'address1@acme.biz;address2@acme.biz;address3@acme.biz'
     
declare @scheduleid varchar(200)          
select @scheduleid = scheduleid  From ReportServer$<SERVERNAME>..ReportSchedule where reportid in           
 (select itemid from ReportServer$<SERVERNAME>..Catalog where path = '/Marketing/PromoSalesReport_MonthToDate')          
          
          
declare @FetchedSubscriptionID varchar(200)          
select @FetchedSubscriptionID = sch.subscriptionid From ReportServer$<SERVERNAME>..ReportSchedule sch          
 inner join ReportServer$<SERVERNAME>..Subscriptions subs on subs.subscriptionid= sch.subscriptionid          
 where sch.scheduleid = @scheduleid              
          
declare @StartDate varchar(200)          
declare @EndDate varchar(200)         
     
    
--Get first day of this month    
select @StartDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) 
select @EndDate =    GETDATE()      
     
declare @MonthName varchar(20)    
set @MonthName = datename(month,@StartDate)    
    
set @SubjectPrefix = @SubjectPrefix + ' for ' + @MonthName    
    
--update report parameters          
update ReportServer$<SERVERNAME>..Subscriptions          
 set parameters = '<ParameterValues><ParameterValue><Name>ModifyDate</Name><Value>'+@StartDate+'</Value></ParameterValue><ParameterValue><Name>EndModifyDate</Name><Value>'+@EndDate+'</Value></ParameterValue></ParameterValues>'          
 where subscriptionid = @FetchedSubscriptionID          
         
              
--update email          
update ReportServer$<SERVERNAME>..Subscriptions          
 set ExtensionSettings='<ParameterValues><ParameterValue><Name>TO</Name><Value>'+@EmailAddress+'</Value></ParameterValue><ParameterValue><Name>IncludeReport</Name><Value>True</Value></ParameterValue><ParameterValue><Name>RenderFormat</Name><Value>EXCELOPENXML</Value></ParameterValue><ParameterValue><Name>Subject</Name><Value>'+@SubjectPrefix+' -  @ReportName was executed at @ExecutionTime</Value></ParameterValue><ParameterValue><Name>Comment</Name><Value>'+@Comment+'</Value></ParameterValue><ParameterValue><Name>IncludeLink</Name><Value>True</Value></ParameterValue><ParameterValue><Name>Priority</Name><Value>NORMAL</Value></ParameterValue></ParameterValues>'    
  where subscriptionid =@FetchedSubscriptionID          
          
--kick off report          
   exec ReportServer$<SERVERNAME>.dbo.AddEvent     
   @EventType='SharedSchedule',     
   @EventData=@scheduleid      
print 'kicking off scheduleid event'          
print @scheduleid          
    
    
--send notification          
EXEC msdb.dbo.sp_send_dbmail          
  @profile_name = 'noreply'          
,@recipients = 'johndoe@acme.biz'          
,@body = @bodybuilt           
,@subject = @SubjectBuilt    
,@body_format = 'HTML'          
          
          
    