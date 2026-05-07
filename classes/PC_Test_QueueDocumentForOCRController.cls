/**
 * Created by sathekumar on 10/25/2021.
 */

@IsTest
private class PC_Test_QueueDocumentForOCRController {

    private static User objUser;
    private static PC_SupportPlan__c oSupPlan;
    private static final String USER_ALIAS = 'ocrUser1';
    private static final String USER_EMAIL = 'ocruser1@test.com';
    private static final String OCR_TEMPLATE_TYPE_NAME = 'test_QueueDocumentForOCR_TemplateType1';
    private static final String OCR_TEMPLATE_TYPE2_NAME = 'test_QueueDocumentForOCR_TemplateType2';

    @testSetup static void createTestData(){
        //Insert User
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, USER_EMAIL, USER_ALIAS);
        objUser = (User) PC_Database.ins(objUser);
        system.runAs(objUser){
            //Create template type
            PC_OcrTemplateType__c ocrTemplateTypeObj = new PC_OcrTemplateType__c();
            ocrTemplateTypeObj.Name = OCR_TEMPLATE_TYPE_NAME;
            ocrTemplateTypeObj.PC_Label__c = OCR_TEMPLATE_TYPE_NAME;
            ocrTemplateTypeObj.PC_APIName__c = OCR_TEMPLATE_TYPE_NAME;
            ocrTemplateTypeObj.PC_IsActive__c = PC_Constants.TRUE_BOOLEAN;
            ocrTemplateTypeObj.PC_CreateResultsAfterOCRCompletion__c = PC_Constants.TRUE_BOOLEAN;
            PC_Database.ins(ocrTemplateTypeObj, false);

            //Create template type 2
            PC_OcrTemplateType__c ocrTemplateTypeObj2 = new PC_OcrTemplateType__c();
            ocrTemplateTypeObj2.Name = OCR_TEMPLATE_TYPE2_NAME;
            ocrTemplateTypeObj2.PC_Label__c = OCR_TEMPLATE_TYPE2_NAME;
            ocrTemplateTypeObj2.PC_APIName__c = OCR_TEMPLATE_TYPE2_NAME;
            ocrTemplateTypeObj2.PC_IsActive__c = PC_Constants.TRUE_BOOLEAN;
            PC_Database.ins(ocrTemplateTypeObj2, false);

            //Create Support Plan for Object Document
            oSupPlan = PC_Test_Setup.createSupportPlan();
            oSupPlan.PC_TriggerEventObject__c = PC_Constants.getQualifiedAPIName('PC_Document__c');
            PC_Database.ins(oSupPlan, false);
        }

    }

    @isTest static void testGetOcrTemplateOptions() {
        objUser = [Select Id from User where Alias =: USER_ALIAS];
        PC_QueueDocumentForOCRController.OcrTemplateOptions templateOptions = new PC_QueueDocumentForOCRController.OcrTemplateOptions();
        system.runAs(objUser){
            Test.startTest();
            PC_SupportPlan__c supportPlan = [SELECT Id, PC_TriggerEventObject__c FROM PC_SupportPlan__c LIMIT 1];
            try {
                System.assertEquals(2, (PC_QueueDocumentForOCRController.getOcrTemplateOptions(supportPlan.Id)).templateTypeSettingList.size());
            } catch (Exception e) {
                System.assertNotEquals(null, e, 'Exception should be thrown');
            }
            Test.stopTest();
        }
    }
}