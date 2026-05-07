/**
 * Created by shisbansal on 8/28/2018.
 */
/*********************************************************************************
Modification Log:
----------------------------------------------------------------------------------
User                          Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy               Dec 13, 2019            [PC-5791] Added Error handling for getEngagementTasks() method
Haritha Reddy              21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/

public with sharing class PC_EngagementTasksController {

    public inherited sharing class InitData {

        @AuraEnabled public FieldLabels fieldLabels ;
        @AuraEnabled public List<Tasks> upcomingOpenTasks;
        @AuraEnabled public List<Tasks> pastClosedTasks;
        @AuraEnabled public List<Tasks> overdueTasks;

        public InitData() {
            upcomingOpenTasks = new List<Tasks>();
            fieldLabels       = new FieldLabels();
            pastClosedTasks   = new List<Tasks>();
            overdueTasks      = new List<Tasks>();
        }
    }

    @AuraEnabled
    public static InitData getEngagementTasks(Id caseId){

        InitData initData = new InitData();
        try {
            initData.upcomingOpenTasks = getUpcomingOpenTasks(caseId);
            initData.fieldLabels = getFieldLabels();
            initData.pastClosedTasks = getPastClosedTasks(caseId);
            initData.overdueTasks = getOverdueTasks(caseId);
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }

        return initData;
    }

    public static List<Tasks> getUpcomingOpenTasks(Id caseId) {

        List<Tasks> listInfo 	= new LIST <Tasks>();

        try{

            List<String> fields = new List<String>{
            PC_Constants.getQualifiedAPIName('Id'),
            PC_Constants.getQualifiedAPIName('WhatId'),
            PC_Constants.getQualifiedAPIName('WhoId'),
            PC_Constants.getQualifiedAPIName('Priority'),
            PC_Constants.getQualifiedAPIName('Subject'),
            PC_Constants.getQualifiedAPIName('Status'),
            PC_Constants.getQualifiedAPIName('ActivityDate')};

            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName(PC_Constants.PC_TASK),PC_Database.Operation.Reading, fields);

            String query = 'SELECT Id, toLabel(Subject), Status, WhatID, WhoID, toLabel(Priority), OwnerId, ActivityDate, Owner.Name, Owner.IsActive FROM Task';
            String whereQuery = ' where OwnerId = \''+ userinfo.getUserID() + '\'';
            whereQuery+= ' AND WhatId = '+ '\''+ caseId + '\'';
            whereQuery+= ' AND Status !='+  '\''+ PC_Constants.PC_TASK_STATUS_COMPLETED +'\'';
            whereQuery+= ' AND ActivityDate >= TODAY  ORDER BY ActivityDate ASC LIMIT 1';

            query+=whereQuery;
            List<Task> upcomingOpenTasks = PC_Database.queryWithAccess(query , true);

            for(Task taskObj : upcomingOpenTasks){
                listInfo.add(new Tasks(taskObj));
            }

        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }

        return listInfo;
    }

    public static List<Tasks> getPastClosedTasks(Id caseId) {

        List<Tasks> listInfo 	= new LIST <Tasks>();

        try{

            List<String> fields = new List<String>{
                    PC_Constants.getQualifiedAPIName('Id'),
                    PC_Constants.getQualifiedAPIName('WhatId'),
                    PC_Constants.getQualifiedAPIName('WhoId'),
                    PC_Constants.getQualifiedAPIName('Priority'),
                    PC_Constants.getQualifiedAPIName('Subject'),
                    PC_Constants.getQualifiedAPIName('Status'),
                    PC_Constants.getQualifiedAPIName('ActivityDate')};

            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName(PC_Constants.PC_TASK),PC_Database.Operation.Reading, fields);

            String query = 'SELECT Id, toLabel(Subject), Status, WhatID, WhoID, toLabel(Priority), OwnerId, ActivityDate, Owner.Name, Owner.IsActive FROM Task';
            String whereQuery = ' where OwnerId = \''+ userinfo.getUserID() + '\'';
            whereQuery+= ' AND WhatId = '+ '\''+ caseId + '\'';
            whereQuery+= ' AND Status ='+  '\''+ PC_Constants.PC_TASK_STATUS_COMPLETED +  '\'' ;
            whereQuery+= ' ORDER BY LastModifiedDate DESC LIMIT 1';

            query+=whereQuery;
            List<Task> pastClosedTasks = PC_Database.queryWithAccess(query , true);

            for(Task taskObj : pastClosedTasks){
                listInfo.add(new Tasks(taskObj));
            }

        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }

        return listInfo;
    }

    public static List<Tasks> getOverdueTasks(Id caseId) {

        List<Tasks> listInfo 	= new LIST <Tasks>();

        try{

            List<String> fields = new List<String>{
                    PC_Constants.getQualifiedAPIName('Id'),
                    PC_Constants.getQualifiedAPIName('WhatId'),
                    PC_Constants.getQualifiedAPIName('WhoId'),
                    PC_Constants.getQualifiedAPIName('Priority'),
                    PC_Constants.getQualifiedAPIName('Subject'),
                    PC_Constants.getQualifiedAPIName('Status'),
                    PC_Constants.getQualifiedAPIName('ActivityDate')};

            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName(PC_Constants.PC_TASK),PC_Database.Operation.Reading, fields);

            String query = 'SELECT Id, toLabel(Subject), Status, WhatID, WhoID, toLabel(Priority), OwnerId, ActivityDate, Owner.Name, Owner.IsActive FROM Task';
            String whereQuery = ' where OwnerId = \''+ userinfo.getUserID() + '\'';
            whereQuery+= ' AND WhatId = '+ '\''+ caseId + '\'';
            whereQuery+= ' AND Status ='+  '\''+PC_Constants.PC_TASK_STATUS_COMPLETED + '\'' ;
            whereQuery+= ' AND ActivityDate < TODAY  ORDER BY ActivityDate DESC LIMIT 1';

            query+=whereQuery;

            List<Task> overdueTasks = PC_Database.queryWithAccess(query , true);

            for(Task taskObj : overdueTasks){
                listInfo.add(new Tasks(taskObj));
            }

        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }

        return listInfo;
    }

    public inherited sharing class Tasks{
        @AuraEnabled public String taskId { get; set; }
        @AuraEnabled public String Subject { get; set; }
        @AuraEnabled public String dueDate { get; set; }


        public Tasks(Task taskObj) {
            taskId = taskObj.Id;
            Subject = taskObj.Subject;
            dueDate = String.valueOf(taskObj.ActivityDate);

        }

        public Tasks() {}
    }

    public static FieldLabels getFieldLabels(){
        FieldLabels fieldlabels         = new FieldLabels();
        fieldlabels.upcomingActivity    = Task.Subject.getDescribe().getLabel();
        fieldlabels.dueOn               = Label.PC_Task_Label_DueDate;
        fieldlabels.completedon         = Label.PC_CompletedOn;
        return fieldlabels;
    }

    public inherited sharing class FieldLabels{
        @AuraEnabled public String upcomingActivity { get; set; }
        @AuraEnabled public String dueOn { get; set; }
        @AuraEnabled public String completedon {get; set;}

        public FieldLabels() {
        }
    }
}