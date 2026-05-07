/*********************************************************************************
Class Name      : PC_QueueDocumentForOCRController
Description     : Controller for Queue Document for OCR(Automation Task) on support plan activity screen
Created By      : Deloitte
Created Date    : 20-Oct-2021
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   	Description
-----------------------------------------------------------------------------------
Satheesh Kumar            20-Oct-2021              Initial Version (PC-8235)
*********************************************************************************/

public with sharing class PC_QueueDocumentForOCRController {

    /*********************************************************************************
    Method Name    : getOcrTemplateOptions
    Description    : method used to fetch all OCR template types
    Return Type    : OcrTemplateOptions
    Parameter      : String
    *********************************************************************************/
    @AuraEnabled
    public static OcrTemplateOptions getOcrTemplateOptions(String supportPlanId){
        OcrTemplateOptions optionsToReturn = new OcrTemplateOptions();
        try{
            PC_OcrQueueUtil.validateOcrSetup();
            // FLS Check for Support Plan
            List<String> supportPlanFields = new List<String>{ PC_Constants.getQualifiedAPIName('PC_TriggerEventObject__c'), PC_Constants.getQualifiedAPIName('PC_SupportPlan_Behavior__c') };
            PC_Database.assertAccess(PC_Constants.PC_SUPPORT_PLAN, PC_Database.Operation.Reading, supportPlanFields);

            PC_SupportPlan__c supportPlan = [SELECT Id, PC_TriggerEventObject__c, PC_SupportPlan_Behavior__c FROM PC_SupportPlan__c WHERE Id = :supportPlanId][0];
            String triggerEventObjectName = supportPlan.PC_TriggerEventObject__c;

            if ((supportPlan.PC_SupportPlan_Behavior__c).contains('RunEveryTime')) {
                optionsToReturn.isSPBehaviorRunEverytime = PC_Constants.TRUE_BOOLEAN;
            } else {
                optionsToReturn.isSPBehaviorRunEverytime = PC_Constants.FALSE_BOOLEAN;
            }

            if (String.isNotBlank(triggerEventObjectName) && triggerEventObjectName.toUpperCase() == PC_Constants.DOCUMENT_OBJECT) {
                optionsToReturn.isValidTriggerEventObject = PC_Constants.TRUE_BOOLEAN;
            } else {
                optionsToReturn.isValidTriggerEventObject = PC_Constants.FALSE_BOOLEAN;
            }
            // FLS Check PC_OcrTemplateType__c
            List<String> ocrTemplateTypeFields = new List<String>{ PC_Constants.getQualifiedAPIName('PC_IsActive__c'), PC_Constants.getQualifiedAPIName('PC_Label__c'), PC_Constants.getQualifiedAPIName('PC_APIName__c'), PC_Constants.getQualifiedAPIName('PC_Description__c'), PC_Constants.getQualifiedAPIName('PC_CreateResultsAfterOCRCompletion__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_OcrTemplateType__c'), PC_Database.Operation.Reading, ocrTemplateTypeFields);
            //Getting all OCR Template Types
            List<PC_OcrTemplateType__c> templateTypeList = [
                    SELECT Id, Name, PC_IsActive__c, PC_Label__c, PC_APIName__c, PC_Description__c, PC_CreateResultsAfterOCRCompletion__c
                    FROM PC_OcrTemplateType__c
                    WHERE PC_IsActive__c = true
            ];
            List<TemplateTypeSetting> templateTypeSettings = new List<TemplateTypeSetting>();
            for (PC_OcrTemplateType__c templateType : templateTypeList) {
                templateTypeSettings.add(new TemplateTypeSetting(templateType));
            }
            optionsToReturn.templateTypeSettingList = templateTypeSettings;
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return optionsToReturn;
    }

    public inherited sharing class OcrTemplateOptions{
        @AuraEnabled
        public Set<String> category{get;set;}
        @AuraEnabled
        public Boolean isSPBehaviorRunEverytime{get;set;}
        @AuraEnabled
        public Boolean isValidTriggerEventObject{get;set;}
        @AuraEnabled
        public List<TemplateTypeSetting> templateTypeSettingList{get;set;}
        public OcrTemplateOptions(){
            category = new Set<String>();
            isSPBehaviorRunEverytime = PC_Constants.FALSE_BOOLEAN;
            isValidTriggerEventObject = PC_Constants.FALSE_BOOLEAN;
            templateTypeSettingList = new List<TemplateTypeSetting>();
        }
    }

    public inherited sharing class TemplateTypeSetting {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String apiName { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public Boolean createResultsImmediately { get; set; }
        public TemplateTypeSetting(){
            label = PC_Constants.EMPTY_STRING;
            apiName = PC_Constants.EMPTY_STRING;
            description = PC_Constants.EMPTY_STRING;
            createResultsImmediately = PC_Constants.FALSE_BOOLEAN;
        }

        public TemplateTypeSetting(PC_OcrTemplateType__c templateType){
            label = templateType.Name;
            apiName = templateType.PC_APIName__c;
            description = templateType.PC_Description__c;
            createResultsImmediately = templateType.PC_CreateResultsAfterOCRCompletion__c;
        }
    }

    public inherited sharing class PC_QueueDocumentForOCRException extends Exception {}
}