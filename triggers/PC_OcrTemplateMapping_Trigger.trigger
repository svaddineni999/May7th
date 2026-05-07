/*********************************************************************************************************
Trigger Name    : PC_OcrTemplateMapping_Trigger
Description     : Trigger on OCR Template Mapping custom object. 
Created By      : Satheesh Kumar
Created Date    : Aug 25, 2021
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                  Date                    Description
--------------------------------------------------------------------------------------------------------------            
Satheesh Kumar          Aug 7, 2021              Initial version
****************************************************************************************************************/
trigger PC_OcrTemplateMapping_Trigger on PC_OcrTemplateMapping__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    new PC_TriggerHandlerDispatcher().executeTriggers(); 
}