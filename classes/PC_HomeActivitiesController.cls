/**************************************************************************************
Apex Class Name     : PC_HomeActivitiesController
Description         : This class is used for Home Page Task and Alerts ;
CreatedBy           : Deloitte
Created Date        : 23 Mar 2018
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Sahil Garg              23 Mar 2018              Initial version
Soumya Soumya           25 May 2018              [PC-42] Home Page Grouping
Vijay Kashikar          15 Jan 2019              [PC-3814] Conditinal Order by NAME/ID to achieve grouping with shield encryption On/OFF.
Tejas Patel             13 Dec 2019              [PC-5831] PC_System class getStatusAttribute called to get a list of all Closed Task status.
Haritha                 13 May 2019              [PC-4824] Defaulting task Icon for Empty or custom Channel values
Hitha Avalakki          07 Jan 2020              [PC-5848] Added code changes to display case type of service cases instead of Program on Home Page Tasks section
Vijay Kashikar          09 Jul 2020              [PC-6502] Show Action Component in the action icons section of every task.
Vijay Kashikar          15 Mar 2021              [PC-7444] Made changes so that either all tasks & only my tasks can be retrieved through methods.
Satheesh Kumar          17 Mar 2021              [PC-7444] Made changes so that either all alerts or only my alerts can be retrieved through getAllAlertsPagination method.
Hitha Avalakki          26 Apr 2021              [PC-7400] Added new variables to fetch task owner name and task owner id details
*************************************************************************************/
public with sharing class PC_HomeActivitiesController {
    //Use @AuraEnabled to enable client- and server-side access to the method
    public static final Integer PC_QUERY_ALLACTIVITIES = 0;
    public static final Integer PC_QUERY_OVERDUEACTIVITIES = 1;
    public static final Integer PC_QUERY_MYACTIVITIES = 2;
    public static final Integer PC_QUERY_ACTIVITIESDUETODAY = 3;
    public static final Integer PC_QUERY_ACTIVITIESDUETOMORROW = 4;
    public static final Integer PC_QUERY_ACTIVITIESSTARRED = 5;
    public static final Integer PC_QUERY_ACTIVITIESDUETHISWEEK = 6;
    public static final Integer PC_QUERY_HIGHPRIORITY = 7;
    public static final String PC_ACTIVITY_STATUS_COMPLETED = 'Completed';
    public static final String PC_HIGH_PRIORITY = 'High';
    public static final String PC_NORMAL_PRIORITY = 'Normal';

    public static  Integer totalRecords ;
    private static List<PC_PicklistFieldManager.PicklistEntryWrapper> priorityTypes = PC_PicklistFieldManager.getPicklistEntryWrappers(Task.Priority);
    public static  String priorityValue ;
    private static List<PicklistEntry> actionComponentPicklistEntries;
    
    @AuraEnabled
    public static pageActivityWrapper getAllTasksPagination(Decimal pageNumber ,Integer recordToDisply,Datetime fromDate, Datetime toDate, Boolean showAllTasks) {
        try {
            Integer recordSize = Integer.valueOf(recordToDisply);
            actionComponentPicklistEntries = getActionComponentPicklistValues();

            List<activityWrapper > lstActivities = getActivities(PC_QUERY_ALLACTIVITIES, fromDate, toDate, null, pageNumber, recordSize, showAllTasks);
            Integer pageSize = recordSize;
            Integer offset = ((Integer) pageNumber - 1) * pageSize;

            // create a instance of wrapper class.
            pageActivityWrapper obj = new pageActivityWrapper();
            // set the pageSize,Page(Number), total records and cases List(using OFFSET)
            obj.pageSize = pageSize;
            obj.page = (Integer) pageNumber;
            obj.total = totalRecords;
            obj.activityWrapper = lstActivities;
            // return the wrapper class instance .
            return obj;
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }
    
    @AuraEnabled
    public static pageActivityWrapper getHighPriorityTasksPagination(Decimal pageNumber ,Integer recordToDisply,Datetime fromDate, Datetime toDate, Boolean showAllTasks) {
        try {
            Integer recordSize = Integer.valueOf(recordToDisply);

            List<activityWrapper > lstActivities = getActivities(PC_QUERY_HIGHPRIORITY, fromDate, toDate, null, pageNumber, recordSize, showAllTasks);
            Integer pageSize = recordSize;
            Integer offset = ((Integer) pageNumber - 1) * pageSize;

            // create a instance of wrapper class.
            pageActivityWrapper obj = new pageActivityWrapper();
            // set the pageSize,Page(Number), total records and cases List(using OFFSET)
            obj.pageSize = pageSize;
            obj.page = (Integer) pageNumber;
            obj.total = totalRecords;
            obj.activityWrapper = lstActivities;
            // return the wrapper class instance .
            return obj;
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }
    
    @AuraEnabled
    public static pageActivityWrapper getAllAlertsPagination(Decimal pageNumber ,Integer recordToDisply, Boolean showAllAlerts) {
        try {
            Integer recordSize = Integer.valueOf(recordToDisply);
            List<alertWrapper> lstAlertWrappers = getActiveUserAlertsPagination(pageNumber, recordSize, showAllAlerts);
            List<activityWrapper> lstAlerts = convertAlertsAsTasks(lstAlertWrappers);

            Integer pageSize = recordSize;
            Integer offset = ((Integer) pageNumber - 1) * pageSize;

            // create a instance of wrapper class.
            pageActivityWrapper obj = new pageActivityWrapper();
            // set the pageSize,Page(Number), total records and cases List(using OFFSET)
            obj.pageSize = pageSize;
            obj.page = (Integer) pageNumber;
            obj.total = totalRecords;
            obj.activityWrapper = lstAlerts;

            return obj ;
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }
    
    /*********************************************************************************
	Method Name    : getOverDueActivities
    Description    : retrieve Overdue Activities
    Return Type    : pageActivityWrapper
    @Param1        : fromDate, used if a specific time is given
    @Param2        : toDate, used if a specific time is given
    *********************************************************************************/
    @AuraEnabled
    public static pageActivityWrapper getOverDueActivities(Decimal pageNumber ,Integer recordToDisply,Datetime fromDate, Datetime toDate, Boolean showAllTasks) {
        try {
            Integer recordSize = Integer.valueOf(recordToDisply);
            List<activityWrapper > lstActivities = getActivities(PC_QUERY_OVERDUEACTIVITIES, fromDate, toDate, null, pageNumber, recordSize, showAllTasks);
            Integer pageSize = recordSize;
            Integer offset = ((Integer) pageNumber - 1) * pageSize;

            // create a instance of wrapper class.
            pageActivityWrapper obj = new pageActivityWrapper();
            // set the pageSize,Page(Number), total records and cases List(using OFFSET)
            obj.pageSize = pageSize;
            obj.page = (Integer) pageNumber;
            obj.total = totalRecords;
            obj.activityWrapper = lstActivities;
            // return the wrapper class instance .
            return obj;
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }
    
    /*********************************************************************************
Method Name    : getOverDueActivities
Description    : retrieve Overdue Activities
Return Type    : List<activityWrapper >
@Param1        : fromDate, used if a specific time is given
@Param2        : toDate, used if a specific time is given
*********************************************************************************/
    
    @AuraEnabled
    public static pageActivityWrapper getActivitiesDueToday(Decimal pageNumber ,Integer recordToDisply,Datetime fromDate, Datetime toDate, Boolean showAllTasks) {
        try {
            Integer recordSize = Integer.valueOf(recordToDisply);

            List<activityWrapper > lstActivities = getActivities(PC_QUERY_ACTIVITIESDUETODAY, fromDate, toDate, null, pageNumber, recordSize, showAllTasks);
            Integer pageSize = recordSize;
            Integer offset = ((Integer) pageNumber - 1) * pageSize;

            // create a instance of wrapper class.
            pageActivityWrapper obj = new pageActivityWrapper();
            // set the pageSize,Page(Number), total records and cases List(using OFFSET)
            obj.pageSize = pageSize;
            obj.page = (Integer) pageNumber;
            obj.total = totalRecords;
            obj.activityWrapper = lstActivities;
            // return the wrapper class instance .
            return obj;
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }
    
    /*********************************************************************************
Method Name    : getActivitiesDueTomorrow
Description    : retrieve Activities Due Tomorrow
Return Type    : List<activityWrapper >
@Param1        : fromDate, used if a specific time is given
@Param2        : toDate, used if a specific time is given
*********************************************************************************/
    
    @AuraEnabled
    public static pageActivityWrapper getActivitiesDueTomorrow(Decimal pageNumber ,Integer recordToDisply,Datetime fromDate, Datetime toDate, Boolean showAllTasks) {
        try {
            Integer recordSize = Integer.valueOf(recordToDisply);
            List<activityWrapper > lstActivities = getActivities(PC_QUERY_ACTIVITIESDUETOMORROW, fromDate, toDate, null, pageNumber, recordSize, showAllTasks);
            Integer pageSize = recordSize;
            Integer offset = ((Integer) pageNumber - 1) * pageSize;

            // create a instance of wrapper class.
            pageActivityWrapper obj = new pageActivityWrapper();
            // set the pageSize,Page(Number), total records and cases List(using OFFSET)
            obj.pageSize = pageSize;
            obj.page = (Integer) pageNumber;
            obj.total = totalRecords;
            obj.activityWrapper = lstActivities;
            // return the wrapper class instance .
            return obj;
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }
    
    
    
    /*********************************************************************************
Method Name    : updateTask
Description    : Update the Starred Field on a task
Return Type    : activityWrapper
@Param1        : taskID, the ID of the task to be updated
*********************************************************************************/
    @AuraEnabled
    public static activityWrapper updateTask(String taskID) {
        activityWrapper aw = null;

        try {
            //Main query
            String query = getSearchQueryString();
            query += ' WHERE Id = \'' + taskID + '\' LIMIT 1';
            
            //Query without Access check since access has been asserted in the getSearchQueryString method
            List<Task> tasks = PC_Database.queryWithAccess(query , false);
            //List<Task> tasks = Database.query(query);
            if(tasks.size() > 0) {
                Task t = tasks[0];
                t.PC_Starred__c = !t.PC_Starred__c;
                PC_Database.upd(t);//FLS/CRUD Check enforced in the database method
                
                aw = new activityWrapper(t);
            }
        }
        catch(exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return aw;
    }
    
    @AuraEnabled
    public static activityWrapper updatePriority(String taskID) {
        activityWrapper aw = null;
        try {
            //Main query
            String query = getSearchQueryString();
            query += ' WHERE Id = \'' + taskID + '\' LIMIT 1';
            
            //Query without Access check since access has been asserted in the getSearchQueryString method
            List<Task> tasks = PC_Database.queryWithAccess(query , false);
            //List<Task> tasks = Database.query(query);
            if(tasks.size() > 0) {
                Task t = tasks[0];
                t.Priority = PC_HIGH_PRIORITY;
                PC_Database.upd(t);//FLS/CRUD Check enforced in the database method
                
                aw = new activityWrapper(t);
                List<activityWrapper> new_aws = new List<activityWrapper>();
                new_aws.add(aw);
                List<activityWrapper> updated_aw = setAdditionalInfoForActivities(new_aws);
                aw = updated_aw[0];
            }
        }
        catch(exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return aw;
    }
    
    @AuraEnabled
    public static activityWrapper closeTask(String taskID) {
        activityWrapper aw = null;
        
        try {
            List<String> fields = new List<String>{'Subject', 'Status', 'WhatID', 'Priority', 'ActivityDate', PC_Constants.getQualifiedAPIName('PC_Starred__c'), PC_Constants.getQualifiedAPIName('PC_Category__c'), PC_Constants.getQualifiedAPIName('PC_Program__c')};
                PC_Database.assertAccess(PC_Constants.PC_TASK,PC_Database.Operation.Reading, fields);
            fields = new List<String>{'Name', 'IsActive'};
                PC_Database.assertAccess(PC_Constants.PC_USER,PC_Database.Operation.Reading, fields);
            fields = new List<String>{'Name'};
                PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
            //Main query
            String query = getSearchQueryString();
            query += ' WHERE Id = \'' + taskID + '\' LIMIT 1';
            
            //Query without Access check since access has been asserted in the getSearchQueryString method
            List<Task> tasks = PC_Database.queryWithAccess(query , false);
            //List<Task> tasks = Database.query(query);
            if(tasks.size() > 0) {
                /*
* FLS Check Added
*/
                fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Starred__c')};
                    PC_Database.assertAccess(PC_Constants.PC_TASK,PC_Database.Operation.Updating, fields);
                Task t = tasks[0];
                t.Status = PC_ACTIVITY_STATUS_COMPLETED;
                PC_Database.upd(t);
                
                aw = new activityWrapper(t);
                List<activityWrapper> new_aws = new List<activityWrapper>();
                new_aws.add(aw);
                List<activityWrapper> updated_aw = setAdditionalInfoForActivities(new_aws);
                
                aw = updated_aw[0];
            }
        }
        catch(exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return aw;
    }

    /*********************************************************************************
Method Name    : getSearchQueryString
Description    : Returns standard query search string.
Return Type    : String
*********************************************************************************/
    private static string getSearchQueryString() {
        List<String> fields = new List<String>{'Subject', 'Status', 'WhatID', 'WhoID','Priority',
                'ActivityDate', PC_Constants.getQualifiedAPIName('PC_Starred__c'),
                PC_Constants.getQualifiedAPIName('PC_Category__c'), PC_Constants.getQualifiedAPIName('PC_Program__c'),
                PC_Constants.getQualifiedAPIName('PC_ActionComponent__c')
        };
            PC_Database.assertAccess(PC_Constants.PC_TASK,PC_Database.Operation.Reading, fields);
        fields = new List<String>{'Name', 'IsActive'};
            PC_Database.assertAccess(PC_Constants.PC_USER,PC_Database.Operation.Reading, fields);
        fields = new List<String>{'Name'};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
        return 'SELECT Id, toLabel(Subject), Status, WhatID, WhoID, toLabel(Priority), OwnerId, ActivityDate, Owner.Name, Owner.IsActive, PC_ActionComponent__c, PC_Starred__c, PC_Category__c, PC_Program__c, PC_Program__r.account.name, PC_Program__r.account.id, PC_Channel__c, What.RecordTypeId, What.Type, What.Name, toLabel(PC_Program__r.RecordType.Name) FROM Task ';
    }
    
    private static List<activityWrapper> setAdditionalInfoForActivities(List<activityWrapper> lstActivities) {
        List<activityWrapper> ret_lstActivities = new List<activityWrapper>();
        
        List<String> taskRelatedIds = new List<String>();
        for(activityWrapper aw : lstActivities) {
            taskRelatedIds.add(aw.relatedToRecordID);
        }
        
        List<Case> cases = [SELECT ID, AccountId, Account.Name, toLabel(RecordType.Name) FROM Case where ID IN :taskRelatedIds];
        
        Map<String, Case> caseAccountMap = new Map<String, Case>();
        for(Case c : cases) {
            caseAccountMap.put(c.Id, c);
        }
        
        Case relatedCase;
        activityWrapper updatedActivityWrapper = new activityWrapper();
        for(activityWrapper aw : lstActivities) {
            if(caseAccountMap.containsKey(aw.relatedToRecordID)) {
                relatedCase = caseAccountMap.get(aw.relatedToRecordID);
                updatedActivityWrapper = aw;
                updatedActivityWrapper.patientName = relatedCase.Account.Name;
                updatedActivityWrapper.patientID = relatedCase.Account.Id;
                updatedActivityWrapper.patientURL = '../' + relatedCase.Id;
                updatedActivityWrapper.relatedToRecordTypeName = relatedCase.RecordType.Name;
                ret_lstActivities.add(updatedActivityWrapper);
            }
            else {
                ret_lstActivities.add(aw);
            }
        }
        return  ret_lstActivities;
        
    }
    
    /*********************************************************************************
Method Name    : getActivities
Description    : Utility Retrieve activity method.  Returns a list of Activities.
Return Type    : List<activityWrapper >
@Param1        : queryType, Integer to represent the type of query being made.
@Param2        : fromDate, used if a specific time is given
@Param3        : toDate, used if a specific time is given
*********************************************************************************/
    private static List<activityWrapper> getActivities(Integer queryType, dateTime fromDate, dateTime toDate, String filter, Decimal pageNumber ,Integer recordToDisply, Boolean showAllTasks) {
        
        List<activityWrapper > lstActivities = new List<activityWrapper>();
        List<activityWrapper > lstActivitiesWithAdditionalInfo = new List<activityWrapper>();

        try {
            Set<String> PC_ACTIVITY_STATUS_CLOSED = PC_SYSTEM.getStatusAttribute('TaskStatus', false, true);

            Integer pageSize = recordToDisply;

            Integer offset = ((Integer)pageNumber - 1) * pageSize;

            //Main query
            String query = getSearchQueryString(); //'Select Id, Subject, Priority, Status, OwnerId, ActivityDate, Owner.Name, Owner.IsActive, PC_Starred__c, PC_Category__c, PC_Program__c, PC_Program__r.account.name, PC_Program__r.account.id from Task ';
            
            //Where clause that will change depending on type of query
            String whereQuery = '';
            if(!showAllTasks) {
                whereQuery = ' where OwnerId = \''+ userinfo.getUserID() + '\'';
            }
            String offsetQuery = ' LIMIT '+ recordToDisply+' OFFSET '+ offset;
            //Limit or Order
            String orderQuery = '';
            //Specific logic for each type of query
            String whereNotation = ' WHERE ';

            if(queryType == PC_QUERY_ALLACTIVITIES) {
                orderQuery += ' ORDER BY ActivityDate ASC ';
            }
            else if(queryType == PC_QUERY_OVERDUEACTIVITIES) {
                String qString = ' ActivityDate < TODAY ';
                whereQuery += String.isBlank(whereQuery) ? whereNotation + qString : ' AND ' + qString ;
                orderQuery += ' ORDER BY ActivityDate ';
            }
            else if( queryType == PC_QUERY_ACTIVITIESDUETODAY ) {
                String qString = ' ActivityDate = TODAY ';
                system.debug('WHERE = ' + whereQuery + '---');
                whereQuery += String.isBlank(whereQuery) ? whereNotation + qString : ' AND ' + qString ;
            }
            else if( queryType == PC_QUERY_ACTIVITIESDUETOMORROW ) {
                String qString = ' ActivityDate = TOMORROW ';
                whereQuery += String.isBlank(whereQuery) ? whereNotation + qString : ' AND ' + qString ;
            }
            else if( queryType == PC_QUERY_HIGHPRIORITY ) {
                String qString = ' Priority= \'' + PC_HIGH_PRIORITY +'\' ';
                whereQuery += String.isBlank(whereQuery) ? whereNotation + qString : ' AND ' + qString ;
            }
            
            //Add from/to dates if provided
            if(fromDate != null) {
                String fromDateWhereClause = ' ActivityDate >= ' + fromDate.format('yyyy-MM-dd');
                whereQuery += String.isBlank(whereQuery) ? whereNotation + fromDateWhereClause : ' AND ' + fromDateWhereClause;
            }
            if(toDate != null) {
                String toDateWhereClause = ' ActivityDate <= ' + toDate.format('yyyy-MM-dd');
                whereQuery += String.isBlank(whereQuery) ? whereNotation + toDateWhereClause : ' AND ' + toDateWhereClause;
            }
            
            //Query for only non-completed activities
            String statusWhereClause = ' status NOT IN :PC_ACTIVITY_STATUS_CLOSED ';
            whereQuery += String.isBlank(whereQuery) ? whereNotation + statusWhereClause : ' AND ' + statusWhereClause; //' AND status NOT IN :PC_ACTIVITY_STATUS_CLOSED';
            
            if (filter != null) {
                whereQuery += ' AND (' + filter + ')';
            }
            
            whereQuery+=orderQuery;
            query += whereQuery;
            system.debug('********************');
            system.debug(query);
            List<Task> lstTasks = Database.query(query);//PC_Database.queryWithAccess(query , false);
            totalRecords=lstTasks.size();
            query += offsetQuery;
            

            //Query without Access check since access has been asserted in the getSearchQueryString method
            lstTasks = Database.query(query);//PC_Database.queryWithAccess(query , false);
            
            //If activities found, add them to list.
            if(lstTasks.size() > 0)
            {
                for(Task t : lstTasks) {
                    lstActivities.add(new activityWrapper(t));
                }
            }
            
            lstActivitiesWithAdditionalInfo = setAdditionalInfoForActivities(lstActivities);
        }
        catch(exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return lstActivitiesWithAdditionalInfo ;
    }
    
    
    
    
    
    public static List<activityWrapper> convertAlertsAsTasks(List<alertWrapper> lstAlertWrappers) {
        List<activityWrapper> lstAlertsAsTasks = new List<activityWrapper>();
        activityWrapper aw = new activityWrapper();
        for(alertWrapper alertWrapper : lstAlertWrappers) {
            aw = new activityWrapper(alertWrapper);
            lstAlertsAsTasks.add(aw);
        }
        return lstAlertsAsTasks;
    }

    private static TaskActionComponent getActionComponent(String actionComponentAPIName) {
        if(String.isBlank(actionComponentAPIName)) {
            return null;
        }
        else {
            if (actionComponentPicklistEntries != null) {
                if(!actionComponentPicklistEntries.isEmpty()) {
                    for(PicklistEntry picklistEntry : actionComponentPicklistEntries) {
                        if(actionComponentAPIName.toLowerCase() == picklistEntry.value.toLowerCase()) {
                            TaskActionComponent actionComponent = new TaskActionComponent();
                            actionComponent.label = picklistEntry.label;
                            actionComponent.apiName = picklistEntry.value;
                            return actionComponent;
                        }
                    }
                }
            }
            return null;
        }
    }

    public class TaskActionComponent {
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public String apiName {get;set;}
    }
    //Activity wrapper necessary as Lightning has problems retreiving values from child objects in hierarchy (aka objTask).
    public class activityWrapper {
        @AuraEnabled public Object objTask {get;set;}
        @AuraEnabled public String taskID {get;set;}
        @AuraEnabled public String taskURL {get;set;}
        @AuraEnabled public TaskActionComponent actionComponent {get;set;}
        @AuraEnabled public String subject {get;set;}
        @AuraEnabled public String status {get;set;}
        @AuraEnabled public String priority {get;set;}
        @AuraEnabled public Boolean highPriority {get;set;}
        @AuraEnabled public Integer priorityIndex {get;set;}
        @AuraEnabled public Integer index_priorityPlusDueDate {get;set;}
        @AuraEnabled public Integer index_dueDatePlusPriority {get;set;}
        @AuraEnabled public boolean isStarred {get;set;}
        @AuraEnabled public String category {get;set;}
        @AuraEnabled public String programID {get;set;}
        @AuraEnabled public String programURL {get;set;}
        @AuraEnabled public String patientID {get;set;}
        @AuraEnabled public String patientName {get;set;}
        @AuraEnabled public String patientURL {get;set;}
        @AuraEnabled public String navigationText {get;set;}
        @AuraEnabled public String dueDate {get;set;}
        @AuraEnabled public String channel {get;set;}
        @AuraEnabled public Boolean isOverdue {get;set;}
        @AuraEnabled public Boolean isDueToday {get;set;}
        @AuraEnabled public Boolean isDueTomorrow {get;set;}
        @AuraEnabled public Boolean isAlert {get;set;}
        @AuraEnabled public String alertName {get;set;}

        @AuraEnabled public String relatedToRecordID {get;set;}
        @AuraEnabled public String relatedToRecordURL {get;set;}
        @AuraEnabled public String relatedToRecordName {get;set;}
        @AuraEnabled public String relatedToObjectName {get;set;}
        @AuraEnabled public String relatedToRecordTypeName {get;set;}
        @AuraEnabled public String relatedToRecordTypeID {get;set;}
        @AuraEnabled public String svgIconName {get;set;}
        @AuraEnabled public String taskOwnerName {get;set;}
        @AuraEnabled public String taskOwnerId {get;set;}
        
        
        public activityWrapper() {
            
        }
        public activityWrapper(Task t) {
            this.objTask = t;
            this.taskID = t.ID;
            this.taskURL = URL.getSalesforceBaseUrl().toExternalForm() +'/'+t.ID;
            this.actionComponent = getActionComponent(t.PC_ActionComponent__c);
            this.subject = t.Subject;
            this.status = t.Status;
            this.priority = t.Priority;
            for(PC_PicklistFieldManager.PicklistEntryWrapper st : priorityTypes){
                if(t.priority == st.label){
                    priorityValue=st.value;
                }
            }
            this.highPriority = priorityValue == PC_HIGH_PRIORITY ? true : false;
            this.priorityIndex = this.priority == PC_HIGH_PRIORITY ? PC_QUERY_MYACTIVITIES : (this.priority == PC_NORMAL_PRIORITY ? PC_QUERY_ACTIVITIESDUETODAY : PC_QUERY_ACTIVITIESDUETOMORROW);
                this.category = t.PC_Category__c;
            this.programID = t.PC_Program__c;
            this.programURL = URL.getSalesforceBaseUrl().toExternalForm() +'/'+t.PC_Program__c;
            if(t.ActivityDate != null) {
                this.dueDate = t.ActivityDate.format();
            }
            this.isStarred = t.PC_Starred__c;
            this.relatedToRecordID = t.WhatID;
            this.relatedToRecordURL = URL.getSalesforceBaseUrl().toExternalForm() +'/'+t.WhatID;
            this.relatedToRecordTypeID = t.What.RecordTypeId;
            this.relatedToObjectName = t.What.Type;
            this.relatedToRecordName = t.What.Name;

            this.taskOwnerName = UserInfo.getName();
            this.taskOwnerId =t.OwnerId;
            //PC-4824: Defaulting task Icon for Empty or custom Channel values
            if(!string.isBlank(t.PC_Channel__c)){
                if(t.PC_Channel__c.toLowerCase() == 'call'){
                    this.svgIconName = 'call';
                }else if(t.PC_Channel__c.toLowerCase() == 'email'){
                    this.svgIconName = 'email';
                }else if(t.PC_Channel__c.toLowerCase() == 'sms'){
                    this.svgIconName = 'sms';
                }else{
                    this.svgIconName = 'task';
                }
            }else{
                this.svgIconName = 'task';
            }
            this.isOverdue = t.ActivityDate < Date.today();
            this.isDueToday = t.ActivityDate == Date.today();
            this.isDueTomorrow = t.ActivityDate == Date.today().addDays(1);
            this.isAlert = false;
            this.channel = t.PC_Channel__c;
            
            if(t.PC_Program__c != null && t.PC_Program__r.account != null) {
                this.patientID = t.PC_Program__r.account.id;
                this.patientName = t.PC_Program__r.account.name;
                this.patientURL = '../'+this.patientID;
                this.relatedToRecordTypeName = t.PC_Program__r.RecordType.Name;
                this.navigationText = t.PC_Program__r.account.name;
            }
            else {
                this.patientID = PC_Constants.EMPTY_STRING;
                this.patientName = PC_Constants.EMPTY_STRING;
                this.patientURL = PC_Constants.EMPTY_STRING;
                //PC-2504 For non case related tasks add Object Name as Task Title
                this.navigationText = t.What.Name;
            }
            if(t.ActivityDate != null) {
                String dtFormat = getFormattedDate(t.ActivityDate);
                String x = dtFormat + this.priorityIndex;
                String y = this.priorityIndex + dtFormat;
                this.index_dueDatePlusPriority = Integer.valueOf(x);
                this.index_priorityPlusDueDate = Integer.valueOf(y);
            }
            else {
                this.index_dueDatePlusPriority = this.priorityIndex;
                this.index_priorityPlusDueDate = this.priorityIndex;
            }
        }
        public activityWrapper(alertWrapper a) {

            this.alertName=a.alertName;

            this.isAlert = true;
            this.objTask = a;
            this.patientName = a.patientName;
            
            this.taskID = a.alertID;
            if(a.alertDate!=null) {
                this.dueDate = String.valueOf(a.alertDate.date().format());
                this.isOverdue = a.alertDate.date() < Date.today();
                this.isDueToday = a.alertDate.date() == Date.today();
                this.isDueTomorrow = a.alertDate.date() == Date.today().addDays(1);
            }
            else{
                this.isOverdue = false;
                this.isDueToday =false;
                this.isDueTomorrow = false;
            }
            this.subject = a.alertReason;
            
            this.category = a.alertType;
            this.priority = Label.PC_Alert_HighPriority;
            // this.priorityIndex = this.priority == 'High' ? 1 : (this.priority == 'Normal' ? 3 : 4);
            this.priorityIndex = this.priority == PC_HIGH_PRIORITY ? PC_QUERY_MYACTIVITIES : (this.priority == PC_NORMAL_PRIORITY ? PC_QUERY_ACTIVITIESDUETODAY : PC_QUERY_ACTIVITIESDUETOMORROW);
                this.patientName = a.patientName;
            this.patientID = a.patientId;
            
            
            this.relatedToRecordID = a.caseId;
            this.relatedToRecordName = a.caseNumber;
            this.relatedToRecordTypeName = a.caseType;
            
            this.programURL = URL.getSalesforceBaseUrl().toExternalForm() +'/'+a.caseId;
            this.taskURL = URL.getSalesforceBaseUrl().toExternalForm() +'/'+a.alertID;
            this.patientURL = '../'+a.patientId;
            

            
            this.svgIconName = 'warning';
            
            if(a.alertDate != null) {
                
                String dtFormat = getFormattedDate(a.alertDate.date());
                String x = dtFormat + this.priorityIndex;
                String y = this.priorityIndex + dtFormat;
                this.index_dueDatePlusPriority = Integer.valueOf(x);
                this.index_priorityPlusDueDate = Integer.valueOf(y);
            }
            else {
                this.index_dueDatePlusPriority = this.priorityIndex;
                this.index_priorityPlusDueDate = this.priorityIndex;
            }
        }
        public String getFormattedDate(Date dt) {
            String y = String.valueOf(dt.year());
            String m = String.valueOf(dt.month());
            String d = String.valueOf(dt.day());
            m = m.length() > 1 ? m : '0'+m;
            d = d.length() > 1 ? d : '0'+d;
            String dtFormat = y + m + d;
            return dtFormat;
        }
        
        
    }


    
    public class pageActivityWrapper {
        @AuraEnabled public Integer pageSize {get;set;}
        @AuraEnabled public Integer page {get;set;}
        @AuraEnabled public Integer total {get;set;}
        @AuraEnabled public List<activityWrapper> activityWrapper {get;set;}
        
        
    }
    
    
    
    
    /*********************************************************************************
Method Name    : getActiveUserAlertsPagination
Description    : retrieve Users Alerts based on the Programs they are assigned to
Return Type    : List<PC_Alert__c>
*********************************************************************************/
    @AuraEnabled
    public static List<alertWrapper> getActiveUserAlertsPagination(Decimal pageNumber ,Integer recordToDisply, Boolean showAllAlerts) {
        system.debug('showAllAlerts---->'+showAllAlerts);
        List<alertWrapper> lstAlertWrapper = new List<alertWrapper>();
        try {
            Integer pageSize = recordToDisply;
            Integer offset = ((Integer)pageNumber - 1) * pageSize;
            
            
            DateTime newDate = DateTime.Now().AddDays(7);
            List<String> fields = new List<String>{
                    'Name',
                    PC_Constants.getQualifiedAPIName('PC_Program__c'),
                    PC_Constants.getQualifiedAPIName('PC_Patient__c'),
                    PC_Constants.getQualifiedAPIName('PC_Patient_ID__c'),
                    PC_Constants.getQualifiedAPIName('PC_Reason_for_Alert__c'),
                    PC_Constants.getQualifiedAPIName('PC_Type__c'),
                    PC_Constants.getQualifiedAPIName('PC_Date_of_Alert__c'),
                    PC_Constants.getQualifiedAPIName('PC_Alert_Status__c'),
                    PC_Constants.getQualifiedAPIName('PC_ActionComponent__c')
            };
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Alert__c'),PC_Database.Operation.Reading, fields);
            
            fields = new List<String>{'ParentID', 'MemberID'};
                PC_Database.assertAccess(PC_Constants.PC_CASETEAMMEMBER,PC_Database.Operation.Reading, fields);

            List<PC_Alert__c> lstAlerts = new List<PC_Alert__c>();
            Set<Id> programIds = new Set<Id>();
            if (!showAllAlerts) {
                for (CaseTeamMember teamMember : [SELECT ParentID FROM CaseTeamMember WHERE MemberID = :userinfo.getUserID()]) {
                    programIds.add(teamMember.ParentID);
                }
                totalRecords = [
                        SELECT COUNT()
                        FROM PC_Alert__c
                        WHERE PC_Alert_Status__c = :PC_Constants.PC_NEW AND PC_Date_of_Alert__c <= :newDate
                        AND (PC_Program__c IN :programIds OR PC_Program__r.OwnerId = :userinfo.getUserID())
                ];
                lstAlerts = [
                        SELECT Id, Name, PC_Program__c, PC_Program__r.CaseNumber, toLabel(PC_Program__r.RecordType.Name), PC_Patient__c,PC_Program__r.Account.Name, PC_Patient_ID__c, PC_Reason_for_Alert__c, PC_Type__c, PC_Date_of_Alert__c, PC_Alert_Status__c
                        FROM PC_Alert__c
                        WHERE PC_Alert_Status__c = 'New' AND PC_Date_of_Alert__c <= :newDate AND (PC_Program__c IN :programIds OR PC_Program__r.OwnerId = :userinfo.getUserID())
                        ORDER BY PC_Date_of_Alert__c ASC
                        LIMIT :recordToDisply
                        OFFSET :offset
                ];
            } else {
                totalRecords = [SELECT COUNT() FROM PC_Alert__c WHERE PC_Alert_Status__c = :PC_Constants.PC_NEW AND PC_Date_of_Alert__c <= :newDate];
                lstAlerts = [
                        SELECT Id, Name, PC_Program__c, PC_Program__r.CaseNumber, toLabel(PC_Program__r.RecordType.Name), PC_Patient__c,PC_Program__r.Account.Name, PC_Patient_ID__c, PC_Reason_for_Alert__c, PC_Type__c, PC_Date_of_Alert__c, PC_Alert_Status__c
                        FROM PC_Alert__c
                        WHERE PC_Alert_Status__c = 'New' AND PC_Date_of_Alert__c <= :newDate
                        ORDER BY PC_Date_of_Alert__c ASC
                        LIMIT :recordToDisply
                        OFFSET :offset
                ];
            }
            for(PC_Alert__c a : lstAlerts) {
                lstAlertWrapper.add(new alertWrapper(a));
            }
        }
        catch(exception e) {
            PC_Utility.logAndThrowException(e);
        }
        
        return lstAlertWrapper;
    }
    
    
    
    /*********************************************************************************
Method Name    : overrideAlert
Author         : Alina Balan
Description    : This method is used for overridden an alert
Return Type    : void
Parameter      : String objAlertId
*********************************************************************************/
    @AuraEnabled
    public static void overrideAlert(String objAlertId) {
        if (String.isBlank(objAlertId)) {
            return;
        }
        try {
            //CRUD/FLS check for PC_Alert__c
            List<String> fields = new List<String>{'Id'};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Alert__c'),PC_Database.Operation.Reading, fields);
            List<PC_Alert__c> lstAlerts = [SELECT Id FROM PC_Alert__c WHERE Id =: objAlertId];
            PC_Alert__c oAlert;
            if (lstAlerts.size() > 0) {
                oAlert = lstAlerts[0];
            }
            String defaultVal = getDefaultOverriddenReasonValue();
            oAlert.PC_Alert_Status__c = PC_Constants.ALERT_OVERRIDDEN_STATUS;
            if (!String.isBlank(defaultVal)) {
                oAlert.PC_Reason_for_Override__c = defaultVal;
            }
            PC_Database.upd(oAlert);//CRUD/FLS enforced in the database upd method
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }
    
    /*********************************************************************************
Method Name    : getDefaultOverriddenReasonValue
Author         : Alina Balan
Description    : This method is used for getting the default overridden reason
Return Type    : String
Parameter      :
*********************************************************************************/
    private static String getDefaultOverriddenReasonValue() {
        String defaultVal;
        Schema.DescribeFieldResult result = PC_Alert__c.PC_Reason_for_Override__c.getDescribe();
        List<Schema.PicklistEntry> pickVals = result.getPicklistValues();
        for (Schema.PicklistEntry pv: pickVals) {
            if (pv.isDefaultValue()) {
                defaultVal = pv.getValue();
            }
        }
        return defaultVal;
    }
    
    
    public class alertWrapper {
        @AuraEnabled public String patientName {get;set;}
        @AuraEnabled public String patientId {get;set;}
        @AuraEnabled public String alertID {get;set;}
        @AuraEnabled public String alertReason {get;set;}
        @AuraEnabled public String alertType {get;set;}
        @AuraEnabled public DateTime alertDate {get;set;}
        @AuraEnabled public String caseId {get;set;}
        @AuraEnabled public String caseNumber {get;set;}
        @AuraEnabled public String caseType {get;set;}
        @AuraEnabled public String alertName {get;set;}
        public alertWrapper(PC_Alert__c a) {
            this.patientName = a.PC_Program__r.Account.Name;
            this.alertID = a.ID;
            this.alertReason = a.PC_Reason_for_Alert__c;
            this.alertType = a.PC_Type__c;
            this.alertDate = a.PC_Date_of_Alert__c;
            this.caseId = a.PC_Program__c;
            this.caseType = a.PC_Program__r.RecordType.Name;
            this.patientId = a.PC_Patient_ID__c;
            this.caseNumber = a.PC_Program__r.CaseNumber;
            this.alertName=a.Name;
        }
    }
    /*********************************************************************************
	Method Name    : getAllGroupedByTasks
	Description    : retrieve all tasks belonging to the current user which are grouped by Physician / Patient.
	Return Type    : pageActivityMapWrapper
	@Param1        : groupByParameter, can be 'Physician' or 'Patient' only.
	@Param2        : pageNumber, current page number
	@Param3        : recordToDisplay, number of records to display per page
	@Param4        : filterByIndex, filterBy index if filter By is needed
	*********************************************************************************/
    @AuraEnabled
    public static groupedActivityWrapper getAllGroupedByTasks(String groupByParameter, Integer pageNumber, Integer recordToDisplay, Integer filterByIndex, Boolean showAllTasks) {
        try {
            Integer recordSize = Integer.valueOf(recordToDisplay);
            // create a instance of wrapper class.
            groupedActivityWrapper obj = new groupedActivityWrapper();
            Map<String, List<activityWrapper> > activitiesMap = getGroupedByActivities(filterByIndex, null, pageNumber, recordSize, groupByParameter, obj, showAllTasks);
            Integer pageSize = recordSize;
            Integer offset = (Integer.valueOf(pageNumber) - 1) * pageSize;


            // set the pageSize,Page(Number), total records and cases List(using OFFSET)
            obj.pageSize = pageSize ;
            obj.page = Integer.valueOf(pageNumber);
            obj.total = totalRecords;
            obj.activityMapWrapper = activitiesMap;

            // return the wrapper class instance .
            return obj;
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }
    /**
      *This method contains the query which does the group by
      * */
    private static Map<String,List<activityWrapper>> getGroupedByActivities(Integer queryType, String filter, Integer pageNumber ,Integer recordToDisplay, String groupByParam, groupedActivityWrapper obj, Boolean showAllTasks) {

        Map<String,List<activityWrapper> > activitiesMap = new Map<String,List<activityWrapper>>();
        Map<String,List<activityWrapper> > activitiesWithAdditionalInfoMap = new Map<String,List<activityWrapper>>();
        Set<String> PC_ACTIVITY_STATUS_CLOSED = PC_SYSTEM.getStatusAttribute('TaskStatus', false, true);

        Integer pageSize = Integer.valueOf(recordToDisplay);

        Integer offset = (Integer.valueOf(pageNumber) - 1) * pageSize;

        try {
            //Main query
            String query = getSearchQueryStringForGroupBy();
            //Where clause that will change depending on type of query
            String whereQuery = '';

            if(showAllTasks) {
                whereQuery = ' where Id != null ';
            }
            else {
                whereQuery = ' where OwnerId = \''+ userinfo.getUserID() + '\'';
            }
            //String whereQuery = ' where OwnerId = \''+ userinfo.getUserID() + '\'';

            // For Grouped by activities Case Type is 'Program'
            if(groupByParam.equals('Physician')){
            	//whereQuery += ' AND ' + PC_Constants.getQualifiedAPIName('PC_Program__r') + '.' +PC_Constants.getQualifiedAPIName('PC_Physician__r')+'.name != null ';
            }else{
                //whereQuery += ' AND ' + PC_Constants.getQualifiedAPIName('PC_Program__r') + '.account.name != null ';
                whereQuery += ' AND ' + PC_Constants.getQualifiedAPIName('PC_Program__r') + '.account.type = \'Patient\' ';
            }
            String offsetQuery = ' LIMIT '+ recordToDisplay+' OFFSET '+ offset;
            //Limit or Order
            String orderQuery = '';
            SObjectType accountType = Schema.getGlobalDescribe().get(PC_Constants.PC_ACCOUNT);
            Boolean isNameEncrypted = sObjectType.Account.fields.Name.isEncrypted();
            if(groupByParam.equals('Physician')){
            	//orderQuery = ' order by '+PC_Constants.getQualifiedAPIName('PC_Program__r')+'.'+PC_Constants.getQualifiedAPIName('PC_Physician__r')+'.'+PC_Constants.getQualifiedAPIName('PC_Last_Name__c')+' Asc, ';
                //orderQuery += PC_Constants.getQualifiedAPIName('PC_Program__r')+'.'+PC_Constants.getQualifiedAPIName('PC_Physician__r')+'.'+PC_Constants.getQualifiedAPIName('PC_First_Name__c')+' Asc  ';
                // Changing the logic as first name and last name are encrypted fields in QA
                if(isNameEncrypted) {
                    orderQuery = ' order by ' + PC_Constants.getQualifiedAPIName('PC_Program__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.Id Asc NULLS LAST ';
                }
                else {
                    orderQuery = ' order by ' + PC_Constants.getQualifiedAPIName('PC_Program__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.Name Asc NULLS LAST ';
                }
            }else{
                //orderQuery = ' order by '+PC_Constants.getQualifiedAPIName('PC_Program__r')+'.Account.'+PC_Constants.getQualifiedAPIName('PC_Last_Name__c')+' Asc, ';
                //orderQuery += PC_Constants.getQualifiedAPIName('PC_Program__r')+'.Account.'+PC_Constants.getQualifiedAPIName('PC_First_Name__c')+' Asc ';
                if(isNameEncrypted) {
                    orderQuery = ' order by ' + PC_Constants.getQualifiedAPIName('PC_Program__r') + '.Account.Id Asc NULLS LAST';
                }
                else {
                    orderQuery = ' order by ' + PC_Constants.getQualifiedAPIName('PC_Program__r') + '.Account.Name Asc NULLS LAST';
                }
            }
            //Specific logic for each type of query
            if(Integer.valueOf(queryType) == PC_QUERY_ALLACTIVITIES) {
				orderQuery += ', ActivityDate ASC ';
        	}else if(Integer.valueOf(queryType) == PC_QUERY_OVERDUEACTIVITIES) {
                whereQuery += ' AND ActivityDate < TODAY';
                orderQuery += ' , ActivityDate ';
            }else if( Integer.valueOf(queryType) == PC_QUERY_ACTIVITIESDUETODAY ) {
                whereQuery += ' AND ActivityDate= TODAY';
            }else if( Integer.valueOf(queryType) == PC_QUERY_ACTIVITIESDUETOMORROW ) {
                whereQuery += ' AND ActivityDate= TOMORROW';
            }else if( Integer.valueOf(queryType) == PC_QUERY_HIGHPRIORITY ) {
                whereQuery += 'AND Priority= \'' + PC_HIGH_PRIORITY +'\'';
            }
            // Adding Ordering by Priority Value
            orderQuery += ', '+PC_Constants.getQualifiedAPIName('PC_Priority_Value__c')+' ';

            //Query for only non-completed activities
            whereQuery += ' AND status NOT IN :PC_ACTIVITY_STATUS_CLOSED';
            if (filter != null) {
                whereQuery += ' AND (' + filter + ')';
            }

            whereQuery	+= orderQuery;
            query += whereQuery;
            List<Task> lstTasks = Database.query(query);//PC_Database.queryWithAccess(query , true);

            if(lstTasks.size() > 0){
            	totalRecords = lstTasks.size();
            }

            query += offsetQuery;

            //Query without Access check since access has been asserted in the getSearchQueryString method
            lstTasks = Database.query(query);//PC_Database.queryWithAccess(query , true);

            if(lstTasks.size() > 0)
            {
              activitiesMap =  getGroupedByActivitiesMap(lstTasks, groupByParam, obj);
            }
        }
        catch(exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return activitiesMap ;
    }
    /*********************************************************************************
	Method Name    : getSearchQueryStringForGroupBy
	Description    : Returns standard query search string.
	Return Type    : String
	*********************************************************************************/
    private static string getSearchQueryStringForGroupBy() {
        List<String> fields = new List<String>{'Subject', 'Status', 'WhatID', 'WhoID','Priority', 'ActivityDate', PC_Constants.getQualifiedAPIName('PC_Starred__c'),
            PC_Constants.getQualifiedAPIName('PC_Category__c'), PC_Constants.getQualifiedAPIName('PC_Program__c'), PC_Constants.getQualifiedAPIName('PC_Program__r')+'.'+PC_Constants.getQualifiedAPIName('PC_Physician__c'),
            PC_Constants.getQualifiedAPIName('PC_Program__r')+'.'+PC_Constants.getQualifiedAPIName('PC_Physician__r.id'), PC_Constants.getQualifiedAPIName('PC_Program__r')+'.'+PC_Constants.getQualifiedAPIName('PC_Physician__r.name'),
            PC_Constants.getQualifiedAPIName('PC_Program__r.account.name'), PC_Constants.getQualifiedAPIName('PC_Program__r.account.id'), PC_Constants.getQualifiedAPIName('PC_Channel__c'),
            PC_Constants.getQualifiedAPIName('PC_Program__r.RecordType.Name'), PC_Constants.getQualifiedAPIName('PC_ActionComponent__c')};
            PC_Database.assertAccess(PC_Constants.PC_TASK,PC_Database.Operation.Reading, fields);
        fields = new List<String>{'Name', 'IsActive'};
            PC_Database.assertAccess(PC_Constants.PC_USER,PC_Database.Operation.Reading, fields);
        fields = new List<String>{'Name'};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
        String query = 'SELECT Id, toLabel(Subject), Status, WhatID, WhoID, toLabel(Priority), OwnerId, ActivityDate, Owner.Name, Owner.IsActive, ';
        query += PC_Constants.getQualifiedAPIName('PC_Starred__c') +', '+ PC_Constants.getQualifiedAPIName('PC_Category__c') + ', ';
        query += PC_Constants.getQualifiedAPIName('PC_Program__c') +', '+ PC_Constants.getQualifiedAPIName('PC_Program__r')+'.'+PC_Constants.getQualifiedAPIName('PC_Physician__c')+ ', ';
        query += PC_Constants.getQualifiedAPIName('PC_Program__r')+'.'+PC_Constants.getQualifiedAPIName('PC_Physician__r.id')+ ', ';
        query += PC_Constants.getQualifiedAPIName('PC_Program__r')+'.'+PC_Constants.getQualifiedAPIName('PC_Physician__r.name')+ ', ';
        query += PC_Constants.getQualifiedAPIName('PC_Program__r.account.name')+ ', '+PC_Constants.getQualifiedAPIName('PC_Program__r.account.id')+ ', ';
        query += PC_Constants.getQualifiedAPIName('PC_Channel__c') +', ';
        query += PC_Constants.getQualifiedAPIName('PC_ActionComponent__c') +', ';
        query += 'What.RecordTypeId, What.Type, What.Name, toLabel('+PC_Constants.getQualifiedAPIName('PC_Program__r.RecordType.Name')+') FROM Task ';
        //return 'SELECT Id, toLabel(Subject), Status, WhatID, WhoID, toLabel(Priority), OwnerId, ActivityDate, Owner.Name, Owner.IsActive, PC_Starred__c, PC_Category__c, PC_Program__c, PC_Program__r.PC_Physician__c, PC_Program__r.PC_Physician__r.id, PC_Program__r.PC_Physician__r.name, PC_Program__r.account.name, PC_Program__r.account.id, PC_Channel__c, What.RecordTypeId, What.Type, What.Name, toLabel(PC_Program__r.RecordType.Name) FROM Task ';
    	return query;
     }
    /**
     * Method for performing group by logic based on selected parameter.
     * */
    private static Map<String, List<ActivityWrapper>> getGroupedByActivitiesMap(List<Task> lstTasks,  String groupByParam, groupedActivityWrapper obj){

        List<String> taskCaseRelatedIds =  new List<String>();

        //[PC-5848]: Added code changes to display case type of service cases instead of Program on Home Page Tasks section
        for(Task taskRecord:lstTasks){
            if(taskRecord.WhatId !=null && PC_Constants.PC_CASE.equals(String.valueOf(taskRecord.WhatId.getSObjectType()))){
                taskCaseRelatedIds.add(taskRecord.WhatId);
            }
        }
        List<String> caseFields = new List<String>{'Id', 'AccountId', 'Account.Name', 'RecordType.Name'};
        PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, caseFields);
        //[PC-5848]: Fetch record type details of service cases.
        List<Case> cases = [SELECT ID, AccountId, Account.Name, toLabel(RecordType.Name) FROM Case where ID IN :taskCaseRelatedIds];

        Map<String, Case> caseAccountMap = new Map<String, Case>();
        for(Case c : cases) {
            caseAccountMap.put(c.Id, c);
        }

        Map<String, List<ActivityWrapper>> activitiesMap = new Map<String, List<ActivityWrapper>>();
        Map<String, String> nameMap = new Map<String, String>();
        for(Task task: lstTasks){
            List<ActivityWrapper> activityList = new List<ActivityWrapper>();
            String accountOwnerName = '';

            if('Physician'.equals(groupByParam)){
                accountOwnerName = task.PC_Program__r.PC_Physician__r.id;
                nameMap.put(task.PC_Program__r.PC_Physician__r.id, task.PC_Program__r.PC_Physician__r.name);
            }else{
                accountOwnerName = task.PC_Program__r.account.id;
                nameMap.put(task.PC_Program__r.account.id, task.PC_Program__r.account.name);
            }
            ActivityWrapper updatedActivityWrapper = new activityWrapper(task);
            updatedActivityWrapper.patientName = task.PC_Program__r.account.name;
            updatedActivityWrapper.patientID = task.PC_Program__r.account.Id;
            updatedActivityWrapper.patientURL = '../' + task.PC_Program__r.account.Id;

            //[PC-5848] Added code changes to display case type of service cases instead of 'Program' on Home Page Tasks section
            if(taskCaseRelatedIds !=null && !taskCaseRelatedIds.isEmpty() && taskCaseRelatedIds.contains(task.WhatId)){
                Case relatedCase = caseAccountMap.get(task.WhatId);
                if(relatedCase != null){
                    updatedActivityWrapper.relatedToRecordTypeName = relatedCase.RecordType.Name;
                }
            }
            else{
                updatedActivityWrapper.relatedToRecordTypeName = task.PC_Program__r.RecordType.Name;
            }

            activityList.add(updatedActivityWrapper);

            if(activitiesMap.size() > 0 && activitiesMap.containsKey(accountOwnerName)){
                List<activityWrapper> existingActivities = activitiesMap.get(accountOwnerName);
                for(ActivityWrapper newActivity: activityList){
                    existingActivities.add(newActivity);
                }
                activitiesMap.put(accountOwnerName, existingActivities);
            }else{
            	activitiesMap.put(accountOwnerName, activityList);
                }
        }
        obj.namesAndIds = nameMap;
        return activitiesMap;
    }
     /*
     * Method prepares list of case Ids
     * */
    private static List<Id> getListOfCaseIds(List<Task> tasks){
        List<Id> cases = new List<Id>();
        for(Task task: tasks){
            if(null != task.WhatID){
            	cases.add(task.WhatID);
            }
        }
        return cases;
    }

    public class groupedActivityWrapper {
        @AuraEnabled public Integer pageSize {get;set;}
        @AuraEnabled public Integer page {get;set;}
        @AuraEnabled public Integer total {get;set;}
        @AuraEnabled public Map<String, List<activityWrapper>> activityMapWrapper {get;set;}
        @AuraEnabled public Map<String, String> namesAndIds {get;set;}
    }

    @AuraEnabled
    public static Map<String, String> getFilterByValues(){
        Map<String, String> options = new Map<String, String>();

        options.put('soryByDueDate',Label.PC_Task_Filter_Option_All);
        options.put('filterOverdueItems',Label.PC_Task_Filter_Option_Overdue);
    	options.put('filterTodaysItems',Label.PC_Task_Filter_Option_Due_Today);
        options.put('filterTomorrowItems',Label.PC_Task_Filter_Option_Due_Tomorrow);
        options.put('soryByPriority',Label.PC_Task_SortBy_HighPriority);
        return options;
    }

    public static List<PicklistEntry> getActionComponentPicklistValues(){
        Schema.DescribeFieldResult picklistFieldResult = Task.PC_ActionComponent__c.getDescribe();
        List<Schema.PicklistEntry> picklistValueList = picklistFieldResult.getPicklistValues();

        String picklistLabel = '';
        String picklistValue = '';
        List<PicklistEntry> fieldValueWrapperList = new List<PicklistEntry>();
        PicklistEntry picklistObj ;
        for (Schema.PicklistEntry picklistItem : picklistValueList) {
            picklistLabel = picklistItem.getLabel();
            picklistValue = picklistItem.getValue();

            picklistObj = new PicklistEntry();
            // Let's replace the encoding that salesforce has done for double underscore
            // This is the only encoding that is noticed for all the special characters.
            picklistObj.label = picklistLabel.replace('%5F%5F','__');
            picklistObj.value = picklistValue.replace('%5F%5F','__');
            fieldValueWrapperList.add(picklistObj);
        }
        return fieldValueWrapperList;
    }
    public class PicklistEntry {
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get; set;}
    }

}