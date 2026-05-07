/*********************************************************************************************************
Class Name      : PC_GenerateOcrTemplateMappingIdHandler
Description     : Trigger handler on OCR Template Mapping to generate a unique internal mapping number
Created By      : Satheesh Kumar
Created Date    : Aug 25, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Satheesh Kumar          Aug 25, 2021              Initial Version
Satheesh Kumar          Nov 16, 2021              [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/

/**
*   'with sharing' class level declaration is not required since trigger handler code runs in Trigger Context
*   FLS check also not required in trigger handler since they always runs in System Mode
*/
public inherited sharing class PC_GenerateOcrTemplateMappingIdHandler extends PC_TriggerHandler {

    override public void afterInsert() {
        generateIntTemplateMappingNum((Map<Id, PC_OcrTemplateMapping__c>) newMap);
    }

    /**
    * Creates unique Internal Template Mapping Number for all OCR Template Mapping
    */
    private void generateIntTemplateMappingNum(Map<Id, PC_OcrTemplateMapping__c> newTemplateMappingMap) {
        List<PC_OcrTemplateMapping__c> lstTemplateMapping = [SELECT Id, PC_InternalMappingNumber__c FROM PC_OcrTemplateMapping__c WHERE Id IN :newTemplateMappingMap.keySet()];
        List<PC_OcrTemplateMapping__c> lstTemplateMappingToUpd = new List<PC_OcrTemplateMapping__c>();
        try {
            if (!lstTemplateMapping.isEmpty()) {
                for (PC_OcrTemplateMapping__c a : lstTemplateMapping) {
                    if (String.isBlank(a.PC_InternalMappingNumber__c)) {
                        a.PC_InternalMappingNumber__c = 'OCRTM-' + a.Id; //Copy Salesforce record id
                        lstTemplateMappingToUpd.add(a);
                    }
                }
            }
            if (!lstTemplateMappingToUpd.isEmpty()) {
                PC_Database.upd(lstTemplateMappingToUpd, false);
            }
        } catch (Exception ex) {
            PC_Utility.createExceptionLog(ex);
        }
    }
}