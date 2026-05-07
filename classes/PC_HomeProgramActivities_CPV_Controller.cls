/**
 * Created by vkashikar on 2/13/2018.
 */

public with sharing class PC_HomeProgramActivities_CPV_Controller {
//Use @AuraEnabled to enable client- and server-side access to the method
    public static final Integer PC_QUERY_OVERDUEACTIVITIES = 1;
    public static final Integer PC_QUERY_MYACTIVITIES = 2;
    public static final Integer PC_QUERY_ACTIVITIESDUETODAY = 3;
    public static final Integer PC_QUERY_ACTIVITIESDUETOMORROW = 4;
    public static final Integer PC_QUERY_ACTIVITIESSTARRED = 5;
    public static final Integer PC_QUERY_ACTIVITIESDUETHISWEEK = 6;
    public static final String PC_ACTIVITY_STATUS_COMPLETED = 'Completed';
    public static final String PC_HIGH_PRIORITY = 'High';
    public static final String PC_NORMAL_PRIORITY = 'Normal';

    /*********************************************************************************
     Method Name    : getThisWeekActivities
     Description    : retrieve Overdue Activities
     Return Type    : List<activityWrapper >
     @Param1        : fromDate, used if a specific time is given
     @Param2        : toDate, used if a specific time is given
     *********************************************************************************/
    @AuraEnabled
    public static List<activityWrapper > getThisWeekActivities(Datetime fromDate, Datetime toDate) {
        List<activityWrapper > lstActivities = getActivities(PC_QUERY_ACTIVITIESDUETHISWEEK, fromDate, toDate, null);
        List<alertWrapper> lstAlertWrappers = getActiveUserAlerts();
        List<activityWrapper> lstAlerts = convertAlertsAsTasks(lstAlertWrappers);

        system.debug('xxxxxx');
        List<activityWrapper> lstActivityAndAlerts = new List<activityWrapper>();
        lstActivityAndAlerts.addAll(lstActivities);
        lstActivityAndAlerts.addAll(lstAlerts);
        return lstActivityAndAlerts ;
    }


    /*********************************************************************************
      Method Name    : getOverDueActivities
      Description    : retrieve Overdue Activities
      Return Type    : List<activityWrapper >
      @Param1        : fromDate, used if a specific time is given
      @Param2        : toDate, used if a specific time is given
      *********************************************************************************/
    @AuraEnabled
    public static List<activityWrapper > getOverDueActivities(Datetime fromDate, Datetime toDate, String filter) {
        List<activityWrapper > lstActivities = getActivities(PC_QUERY_OVERDUEACTIVITIES, fromDate, toDate, filter);
        return lstActivities ;
    }

    /*********************************************************************************
    Method Name    : getOverDueActivities
    Description    : retrieve Overdue Activities
    Return Type    : List<activityWrapper >
    @Param1        : fromDate, used if a specific time is given
    @Param2        : toDate, used if a specific time is given
    *********************************************************************************/
    @AuraEnabled
    public static List<activityWrapper > getActivitiesDueToday(String filter) {
        List<activityWrapper > lstActivities = getActivities(PC_QUERY_ACTIVITIESDUETODAY, null, null, filter);
        return lstActivities ;
    }

    /*********************************************************************************
    Method Name    : getActivitiesDueTomorrow
    Description    : retrieve Activities Due Tomorrow
    Return Type    : List<activityWrapper >
    @Param1        : fromDate, used if a specific time is given
    @Param2        : toDate, used if a specific time is given
    *********************************************************************************/
    @AuraEnabled
    public static List<activityWrapper > getActivitiesDueTomorrow(String filter) {
        List<activityWrapper > lstActivities = getActivities(PC_QUERY_ACTIVITIESDUETOMORROW , null, null, filter);
        return lstActivities ;
    }

    /*********************************************************************************
    Method Name    : getStarredActivities
    Description    : retrieve Activities that have been starred by the user
    Return Type    : List<activityWrapper >
    @Param1        : fromDate, used if a specific time is given
    @Param2        : toDate, used if a specific time is given
    *********************************************************************************/
    @AuraEnabled
    public static List<activityWrapper > getStarredActivities(Datetime fromDate, Datetime toDate, String filter) {
        List<activityWrapper > lstActivities = getActivities(PC_QUERY_ACTIVITIESSTARRED , fromDate, toDate, filter);
        return lstActivities ;
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
                PC_Database.assertAccess('Task',PC_Database.Operation.Updating, fields);
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

    /*@AuraEnabled
    public static void overrideAlert(String taskID) {
        system.debug('Dismissing alert = ' + taskID);
        overrideAlert(taskID);
    }*/

    /*********************************************************************************
    Method Name    : getSearchQueryString
    Description    : Returns standard query search string.
    Return Type    : String
    *********************************************************************************/
    private static string getSearchQueryString() {
        List<String> fields = new List<String>{'Subject', 'Status', 'WhatID', 'WhoID','Priority', 'ActivityDate', PC_Constants.getQualifiedAPIName('PC_Starred__c'), PC_Constants.getQualifiedAPIName('PC_Category__c'), PC_Constants.getQualifiedAPIName('PC_Program__c')};
        PC_Database.assertAccess(PC_Constants.PC_TASK,PC_Database.Operation.Reading, fields);
        fields = new List<String>{'Name', 'IsActive'};
        PC_Database.assertAccess(PC_Constants.PC_USER,PC_Database.Operation.Reading, fields);
        fields = new List<String>{'Name'};
        PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
        return 'SELECT Id, toLabel(Subject), Status, WhatID, WhoID, toLabel(Priority), OwnerId, ActivityDate, Owner.Name, Owner.IsActive, PC_Starred__c, PC_Category__c, PC_Program__c, PC_Program__r.account.name, PC_Program__r.account.id, PC_Channel__c, What.RecordTypeId, What.Type, What.Name, toLabel(PC_Program__r.RecordType.Name) FROM Task ';
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
    private static List<activityWrapper> getActivities(Integer queryType, dateTime fromDate, dateTime toDate, String filter) {
        List<activityWrapper > lstActivities = new List<activityWrapper>();
        List<activityWrapper > lstActivitiesWithAdditionalInfo = new List<activityWrapper>();

        try {
            //Main query
            String query = getSearchQueryString(); //'Select Id, Subject, Priority, Status, OwnerId, ActivityDate, Owner.Name, Owner.IsActive, PC_Starred__c, PC_Category__c, PC_Program__c, PC_Program__r.account.name, PC_Program__r.account.id from Task ';

            //Where clause that will change depending on type of query
            String whereQuery = ' where OwnerId = \''+ userinfo.getUserID() + '\'';

            //Limit or Order
            String orderQuery = '';

            //Specific logic for each type of query
            if(queryType == PC_QUERY_OVERDUEACTIVITIES) {
                whereQuery += ' AND ActivityDate < TODAY';
                orderQuery += ' ORDER BY ActivityDate ';
            }
            else if( queryType == PC_QUERY_ACTIVITIESDUETODAY ) {
                whereQuery += ' AND ActivityDate= TODAY';
            }
            else if( queryType == PC_QUERY_ACTIVITIESDUETOMORROW ) {
                whereQuery += ' AND ActivityDate= TOMORROW';
            }
            else if( queryType == PC_QUERY_ACTIVITIESSTARRED ) {
                whereQuery += ' AND PC_Starred__c = true';
            }
            else if(queryType == PC_QUERY_ACTIVITIESDUETHISWEEK) {
                Date today = Date.today();
                Date newDate = today.addDays(7);
                whereQuery += ' AND ActivityDate <= ' + String.valueOf(newDate);
                orderQuery += ' ORDER BY ActivityDate ';
            }

            //Add from/to dates if provided
            if(fromDate != null) {
                whereQuery += ' AND ActivityDate >= ' + fromDate;
            }
            if(toDate != null) {
                whereQuery += ' AND ActivityDate <= ' + toDate;
            }

            //Query for only non-completed activities
            whereQuery += ' AND status != \'' + PC_ACTIVITY_STATUS_COMPLETED +'\'';

            if (filter != null) {
                whereQuery += ' AND (' + filter + ')';
            }

            query += whereQuery;
            query += orderQuery;

            system.debug('Task query -> ' + query);
            //Query without Access check since access has been asserted in the getSearchQueryString method
            List<Task> lstTasks = PC_Database.queryWithAccess(query , false);

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

    //Activity wrapper necessary as Lightning has problems retreiving values from child objects in hierarchy (aka objTask).
    public class activityWrapper {
        @AuraEnabled public Object objTask {get;set;}
        @AuraEnabled public String taskID {get;set;}
        @AuraEnabled public String taskURL {get;set;}
        @AuraEnabled public String subject {get;set;}
        @AuraEnabled public String status {get;set;}
        @AuraEnabled public String priority {get;set;}
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

        @AuraEnabled public String relatedToRecordID {get;set;}
        @AuraEnabled public String relatedToRecordURL {get;set;}
        @AuraEnabled public String relatedToRecordName {get;set;}
        @AuraEnabled public String relatedToObjectName {get;set;}
        @AuraEnabled public String relatedToRecordTypeName {get;set;}
        @AuraEnabled public String relatedToRecordTypeID {get;set;}
        @AuraEnabled public String svgIconName {get;set;}


        public activityWrapper() {

        }
        public activityWrapper(Task t) {
            this.objTask = t;
            this.taskID = t.ID;
            this.taskURL = URL.getSalesforceBaseUrl().toExternalForm() +'/'+t.ID;
            this.subject = t.Subject;
            this.status = t.Status;
            this.priority = t.Priority;
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
            this.svgIconName = String.isBlank(t.PC_Channel__c) ? 'task' : t.PC_Channel__c.toLowerCase() ;
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
                this.patientID = '';
                this.patientName = '';
                this.patientURL = '';
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

    /*////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /*********************************************************************************
    Method Name    : getActiveUserAlerts
    Description    : retrieve Users Alerts based on the Programs they are assigned to
    Return Type    : List<PC_Alert__c>
    *********************************************************************************/
    @AuraEnabled
    public static List<alertWrapper> getActiveUserAlerts() {

        List<alertWrapper> lstAlertWrapper = new List<alertWrapper>();
        try {
            DateTime newDate = DateTime.Now().AddDays(7);
            List<String> fields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_Program__c'), PC_Constants.getQualifiedAPIName('PC_Patient__c'), PC_Constants.getQualifiedAPIName('PC_Patient_ID__c'), PC_Constants.getQualifiedAPIName('PC_Reason_for_Alert__c'), PC_Constants.getQualifiedAPIName('PC_Type__c'), PC_Constants.getQualifiedAPIName('PC_Date_of_Alert__c'), PC_Constants.getQualifiedAPIName('PC_Alert_Status__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Alert__c'),PC_Database.Operation.Reading, fields);

            fields = new List<String>{'ParentID', 'MemberID'};
            PC_Database.assertAccess(PC_Constants.PC_CASETEAMMEMBER,PC_Database.Operation.Reading, fields);

            List<PC_Alert__c> lstAlerts = [SELECT Id, Name, PC_Program__c, PC_Program__r.CaseNumber, toLabel(PC_Program__r.RecordType.Name), PC_Patient__c, PC_Patient_ID__c, PC_Reason_for_Alert__c, PC_Type__c, PC_Date_of_Alert__c, PC_Alert_Status__c FROM PC_Alert__c WHERE PC_Alert_Status__c = 'New' AND PC_Date_of_Alert__c <= :newDate AND PC_Program__c IN (SELECT ParentID FROM CaseTeamMember WHERE MemberID =: userinfo.getUserID()) ORDER BY PC_Date_of_Alert__c ASC];

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
    Method Name    : getListViews
    Description    : retrieve List View for Alerts.  This is a standard Salesforce Method found Here:
                     https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/ref_force_navigateToList.htm
    Return Type    : List<ListView>
    *********************************************************************************/
    @AuraEnabled
    public static ListView getListViews() {
        String alertObj = PC_Constants.getQualifiedAPIName('PC_Alert__c');

        try {
            List<String> fields = new List<String>{'Name', 'SobjectType'};
            PC_Database.assertAccess(PC_Constants.PC_LISTVIEW,PC_Database.Operation.Reading, fields);

            List<ListView> listviews = [SELECT Id, Name FROM ListView WHERE SobjectType =: alertObj and Name='New Alerts'];

            if(listviews.size() <= 0) {
                listviews = [SELECT Id, Name FROM ListView WHERE SobjectType =: alertObj  limit 1];
            }

            ListView listview = null;
            if(listviews.size() > 0) {
                listview = listviews[0];
            }
            return listview;
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return null;
        }
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

    /*********************************************************************************
    Method Name    : getReturnUrl
    Author         : Tetiana Danylyshyn
    Description    : This method is used to get the return url
    Return Type    : String
    *********************************************************************************/
    @AuraEnabled
    public static String getReturnUrl() {
        String key = PC_Alert__c.getSobjectType().getDescribe().getKeyPrefix();
        return '/' + key;
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
        public alertWrapper(PC_Alert__c a) {
            this.patientName = a.PC_Patient__c;
            this.alertID = a.ID;
            this.alertReason = a.PC_Reason_for_Alert__c;
            this.alertType = a.PC_Type__c;
            this.alertDate = a.PC_Date_of_Alert__c;
            this.caseId = a.PC_Program__c;
            this.caseType = a.PC_Program__r.RecordType.Name;
            this.patientId = a.PC_Patient_ID__c;
            this.caseNumber = a.PC_Program__r.CaseNumber;
        }
    }
}