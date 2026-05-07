/*************************************************************************************
Source - https://github.com/vipultaylor/sf-activity-timeline
Class Name          : PC_DynamicActivityTimelineModel
Description         : Wrapper class for PC_DynamicActivityTimelineController.
CreatedBy           : Deloitte
Created Date        : 1 March 2021
Modification Log    :
*****************************************************************************************************
Developer                   Date                   Description
********************************************************************************************
Kanteti Kishore            1 March 2021           Initial version[PC-7427]
Haritha Reddy              19 Oct  2022           PC-9273: Updated logic to sort activities based on last modified date when due date is not available
*****************************************************************************************/

public with sharing class PC_DynamicActivityTimelineModel implements Comparable{
    @AuraEnabled
    public Id recordId {get;set;}

    @AuraEnabled
    public String sobjectName {get;set;}

    @AuraEnabled
    public String activityTimelineType {get;set;}

    @AuraEnabled
    public DateTime activityDate {get;set;}

    @AuraEnabled
    public DateTime lastModifiedDate {get;set;}

    @AuraEnabled
    public String subject {get;set;}

    @AuraEnabled
    public String detail {get;set;}

    // Task contact (whoId), Email "to"
    @AuraEnabled
    public List<RecordReference> recipients {get;set;}

    // Task/Email related to (what) or list of attendees for events
    @AuraEnabled
    public RecordReference relatedTo {get;set;}

    // Task/Event Asignee, or Email From
    @AuraEnabled
    public RecordReference assignedTo {get;set;}

    @AuraEnabled
    public EmailReference fromEmail {get;set;}

    @AuraEnabled
    public EmailReference toEmail {get;set;}

    // Event Start DateTime
    @AuraEnabled
    public DateTime startDateTime {get;set;}

    // Event End DateTime
    @AuraEnabled
    public DateTime endDateTime {get;set;}

    // For indicating task completion
    @AuraEnabled
    public boolean isPriority {get;set;}

    // For indicating task completion
    @AuraEnabled
    public boolean isComplete {get;set;}

    // For indicating recurring task
    @AuraEnabled
    public boolean isRecurring {get;set;}

    // For indicating overdue task
    @AuraEnabled
    public boolean isOverdue {get;set;}

    // For indicating email messages with attachments
    @AuraEnabled
    public boolean hasAttachments {get;set;}

    public class RecordReference {
        @AuraEnabled
        public Boolean isCurrentUser {get;set;}
        @AuraEnabled
        public Id recordId {get;set;}
        @AuraEnabled
        public String recordName {get;set;}
        @AuraEnabled
        public String sobjectName {get;set;}

        public RecordReference(Id recordId, String recordName){
            this.recordId = recordId;
            this.isCurrentUser = recordId == UserInfo.getUserId();
            this.recordName = recordName;
            this.sobjectName = String.valueOf(recordId.getSobjectType());
        }
    }

    public class EmailReference {
        @AuraEnabled
        public String address {get;set;}

        public EmailReference(String address){
            this.address = address;
        }
    }

    public Integer compareTo(Object instance) {
        PC_DynamicActivityTimelineModel compareToActivity = (PC_DynamicActivityTimelineModel) instance;
        if (this.activityDate == compareToActivity.activityDate) return 0;
        if (this.activityDate < compareToActivity.activityDate) return 1;
        return -1;
    }
}