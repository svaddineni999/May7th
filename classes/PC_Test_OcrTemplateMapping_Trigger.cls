/*********************************************************************************************************
Class Name      : PC_Test_OcrTemplateMapping_Trigger
Description     : Test class for PC_OcrTemplateMapping_Trigger
Created By      : Deloitte
Created Date    : Aug 31, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                       Date                   Description
--------------------------------------------------------------------------------------------------------------
Satheesh Kumar                Aug 31, 2021           Initial Version
****************************************************************************************************************/

@IsTest
private class PC_Test_OcrTemplateMapping_Trigger {
    private static User adminUser;
    private static String OCR_TEMPLATE_TYPE_NAME = 'test_OcrTemplateMapping_OcrTemplateType1';
    private static String OCR_TEMPLATE_MAPPING_NAME = 'testEnrollmentForm_CreateApplicant';

    @isTest static void testGenerateOcrTemplateMappingId() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
        PC_Database.ins(adminUser, false);
        system.runAs(adminUser) {
            Test.StartTest(); 
            
            //Create template type
            PC_OcrTemplateType__c ocrTemplateTypeObj = new PC_OcrTemplateType__c();
            ocrTemplateTypeObj.Name = OCR_TEMPLATE_TYPE_NAME;
            ocrTemplateTypeObj.PC_APIName__c = OCR_TEMPLATE_TYPE_NAME;
            ocrTemplateTypeObj.PC_Label__c = OCR_TEMPLATE_TYPE_NAME;
            ocrTemplateTypeObj.PC_IsActive__c = PC_Constants.TRUE_BOOLEAN;
            ocrTemplateTypeObj.PC_CreateResultsAfterOCRCompletion__c = PC_Constants.TRUE_BOOLEAN;
            PC_Database.ins(ocrTemplateTypeObj, false);
            
            //Create template type mappings
            PC_OcrTemplateMapping__c ocrTemplateMappingObj = new PC_OcrTemplateMapping__c();
            ocrTemplateMappingObj.Name = OCR_TEMPLATE_MAPPING_NAME;
            ocrTemplateMappingObj.PC_OcrTemplateType__c = ocrTemplateTypeObj.Id;
            ocrTemplateMappingObj.PC_TargetObject__c = PC_Constants.CANDIDATE_PATIENT_OBJECT;
            ocrTemplateMappingObj.PC_IsActive__c = PC_Constants.TRUE_BOOLEAN;
            ocrTemplateMappingObj.PC_FieldMapping__c = '{"properties": {},"formFields":[{"formField": "First Name", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_First_Name__c')+'"},'+
                '{"formField": "Last Name", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_Last_Name__c')+'"},'+
                '{"formField": "Email", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_Patient_Email__c')+'"},'+
                '{"formField": "Date of Birth", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c')+'"},'+
                '{"formField": "Phone Number", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_Phone__c')+'"},'+
                '{"formField": "City", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_City__c')+'"},'+
                '{"formField": "State", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_State__c')+'"},'+
                '{"formField": "Zip", "apiName": "'+PC_Constants.getQualifiedAPIName('PC_Zip_Code__c')+'"}]}';
            PC_Database.ins(ocrTemplateMappingObj, false);
            system.assertNotEquals(ocrTemplateMappingObj.Id, null);
            
            PC_OcrTemplateMapping__c newOcrTemplateMappingObj = [SELECT Id,PC_InternalMappingNumber__c FROM PC_OcrTemplateMapping__c WHERE Id = :ocrTemplateMappingObj.Id];
            System.assertEquals(newOcrTemplateMappingObj.PC_InternalMappingNumber__c, 'OCRTM-'+ newOcrTemplateMappingObj.Id);
            
            Test.stopTest();
        }
    }
}