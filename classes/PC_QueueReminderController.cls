/*********************************************************************************************************
Class Name    	: PC_QueueReminderController
Description     : Controller for Queue Reminder with activity type as Automation Task type on support plan activity screen
Created By      : Deloitte
Created Date    : May 4, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------
Kishore Kanteti             May 4, 2021           Initial Version
****************************************************************************************************************/

public with sharing class PC_QueueReminderController{

    private static final String PATIENT_CONNECT = 'PatientConnect';

/*********************************************************************************
Method Name    : getReminderOptions
Description    : method used to fetch all dropdown values -Channel options and Custom metadata settings
Return Type    : ReminderOptions
Parameter      : String
*********************************************************************************/

    @AuraEnabled
    public static ReminderOptions getReminderOptions(String supportPlanId){
        ReminderOptions optionsToReturn = new ReminderOptions();
        try{
            // FLS Check for Support Plan
            List<String> supportPlanFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_TriggerEventObject__c')};
            PC_Database.assertAccess(PC_Constants.PC_SUPPORT_PLAN,PC_Database.Operation.Reading, supportPlanFields);

            PC_SupportPlan__c supportPlan = [SELECT Id, PC_TriggerEventObject__c FROM PC_SupportPlan__c WHERE Id =: supportPlanId][0];
            String triggerEventObjectName = supportPlan.PC_TriggerEventObject__c;

            //Getting all Reminder Custom Metadata Settings
            List<PC_ReminderSetting__mdt> allReminderSettings = new List<PC_ReminderSetting__mdt>([
                    SELECT Id, MasterLabel, DeveloperName, PC_Object_ReminderService__c,
                            PC_ReminderChannel__c, PC_ObjectNamespace__c, PC_Description__c, PC_OtherChannelName__c
                    FROM PC_ReminderSetting__mdt
                    WHERE PC_Active__c = TRUE
            ]);

            //Forming Map of Reminder Channel and Reminder Settings
            Map<String,List<ReminderSetting>> reminderChannelSettingsMap = new Map<String,List<ReminderSetting>>();
            reminderChannelSettingsMap = getReminderChannelSettingsMap(allReminderSettings, triggerEventObjectName);

            optionsToReturn.channelSettingsMap = reminderChannelSettingsMap;
            optionsToReturn.channelOptions = reminderChannelSettingsMap.keySet();
        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return optionsToReturn;
    }

    private static Map<String,List<ReminderSetting>> getReminderChannelSettingsMap(List<PC_ReminderSetting__mdt> allReminderSettings, String triggerEventObjectName){

        Map<String,List<ReminderSetting>> allReminderChannelSettingsMap = new Map<String,List<ReminderSetting>>();
        for(PC_ReminderSetting__mdt reminderRecord : allReminderSettings){
            String reminderObjectName =  reminderRecord.PC_Object_ReminderService__c;
            if(reminderRecord.PC_ObjectNamespace__c == PATIENT_CONNECT){
                reminderObjectName = PC_Constants.OrgNamespace + '__' + reminderObjectName;
            }else if(String.isNotBlank(reminderRecord.PC_ObjectNamespace__c) && reminderRecord.PC_ObjectNamespace__c != null && reminderRecord.PC_ObjectNamespace__c != PATIENT_CONNECT){
                reminderObjectName = reminderRecord.PC_ObjectNamespace__c + '__' + reminderObjectName;
            }
            if(reminderObjectName.toUpperCase() ==  triggerEventObjectName.toUpperCase()){
                ReminderSetting eachReminderSetting = new ReminderSetting();
                eachReminderSetting.label = reminderRecord.MasterLabel;
                eachReminderSetting.apiName = reminderRecord.DeveloperName;
                if(reminderRecord.PC_ReminderChannel__c == PC_Constants.PC_OTHER && String.isNotBlank(reminderRecord.PC_OtherChannelName__c)){
                    eachReminderSetting.channel = reminderRecord.PC_OtherChannelName__c;
                }else{
                    eachReminderSetting.channel = reminderRecord.PC_ReminderChannel__c;
                }
                eachReminderSetting.description = reminderRecord.PC_Description__c;
                if(allReminderChannelSettingsMap.containsKey(eachReminderSetting.channel)){
                    allReminderChannelSettingsMap.get(eachReminderSetting.channel).add(eachReminderSetting);
                }else{
                    List<ReminderSetting> reminderSettingsList = new List<ReminderSetting>();
                    reminderSettingsList.add(eachReminderSetting);
                    allReminderChannelSettingsMap.put(eachReminderSetting.channel,reminderSettingsList);
                }
            }
        }
        return allReminderChannelSettingsMap;
    }

    public inherited sharing class ReminderOptions{
        @AuraEnabled
        public Set<String> channelOptions{get;set;}
        @AuraEnabled
        public Map<String,List<ReminderSetting>> channelSettingsMap{get;set;}
        @AuraEnabled
        public List<CriteriaDropdown> criteriaOptions{get;set;}
        public ReminderOptions(){
            List<CriteriaDropdown> queueCriterias = new List<CriteriaDropdown>();
            CriteriaDropdown takeNoAction = new CriteriaDropdown();
            takeNoAction.label = System.label.PC_DoNotTakeAction;
            takeNoAction.value = String.valueOf(PC_ReminderQueueUtility.HandleExistingQueueCriteria.TAKE_NO_ACTION);
            CriteriaDropdown deactivateAndCreateNew = new CriteriaDropdown();
            deactivateAndCreateNew.label = System.label.PC_DeactivateAndCreateNew;
            deactivateAndCreateNew.value = String.valueOf(PC_ReminderQueueUtility.HandleExistingQueueCriteria.DEACTIVATE_AND_CREATE_NEW);
            queueCriterias.add(takeNoAction);
            queueCriterias.add(deactivateAndCreateNew);
            criteriaOptions = queueCriterias;
        }
    }

    public inherited sharing class CriteriaDropdown{
        @AuraEnabled
        public String label{get;set;}
        @AuraEnabled
        public String value{get;set;}
        public CriteriaDropdown(){}
    }

    public inherited sharing class ReminderSetting{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String apiName {get; set;}
        @AuraEnabled
        public String channel {get; set;}
        @AuraEnabled
        public String description {get; set;}
    }
}