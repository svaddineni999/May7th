/**************************************************************************************
Apex Class Name     : PC_Test_PreviewCaseLightningController
Description         : This class is used for testing PC_PreviewCaseLightningController;
CreatedBy           : Deloitte
Created Date        : 13 Feb 2017
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Prachi Nandgaonkar          13 Feb 2017           Initial version
Ajinkya Deshmukh			25 Apr 2017			   [PC-1365] Updated class to associate engagement program to document
*************************************************************************************/
@isTest
private class PC_Test_PreviewCaseLightningController {
    private static User objUser;
    private static Account oPatient;
    private static PC_Document__c oDoc;
    private static PC_Document__c oDoc1;
    private static Case enrollCase;
    private static final String PATIENT_NAME = 'testPatient';
    private static final String DOC_CATEGORY = 'Enrollment Form';
    private static final String ENG_PROGRAM_NAME = 'program';
    
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Prachi Nandgaonkar
    Description    : This method is used for creating test data
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    private static void createTestData() {
        //Create a user
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test93.com', 'test93');
        PC_Database.ins(objUser, false);
        
        //Create a patient account
        oPatient = PC_Test_Setup.createPatient(PATIENT_NAME);
        PC_Database.ins(oPatient, false);
        
        //Create an enrollment case type
        enrollCase = PC_Test_Setup.newCase(oPatient.Id, PC_Constants.CASE_ENROLLMENT_RECORD_TYPE);
        PC_Database.ins(enrollCase, false);
        
        //Create a document
        oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'A');
        Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);
        oDoc.PC_Document_Category__c = DOC_CATEGORY;
        oDoc.RecordTypeId = recordTypeId;
        PC_Database.ins(oDoc, false);
        
        //Create a document which is undergoing splitting
        oDoc1 = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_SPLIT_IN_PROGRESS, ENG_PROGRAM_NAME + 'B');
        Id recordTypeId1 = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);
        oDoc1.PC_Document_Category__c = DOC_CATEGORY;
        oDoc1.RecordTypeId = recordTypeId1;
        PC_Database.ins(oDoc1, false);
   
    }
    
        
   
    /*********************************************************************************
    Method Name    : testlinkDocToCase
    Author         : Prachi Nandgaonkar
    Description    : This method is used for testing "linkDocToCase" for positive test scenarios
    Return Type    : void 
    Parameter      : Id enrollmentCaseId, String documentId
    *********************************************************************************/
    @isTest static void testlinkDocToCase(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            
            //Test linkDoctoCase() method
            PC_PreviewCaseLightningController.linkDocToCase(enrollCase.Id, oDoc.Id);
            
            //Query Document Log to see if records were created
            List<PC_Document_Log__c>  lstLogs = [SELECT Id FROM PC_Document_Log__c WHERE PC_Document__c =: oDoc.Id];
            System.assertEquals(lstLogs.size(), 1);
            
            //Query document to check status
            PC_Document__c doc = [select id, PC_Document_Status__c 
                                        FROM PC_Document__c 
                                        Where Id =: oDoc.Id];
            
            //check if document status was changed to 'Complete and Ready for Use'
            System.assertEquals(PC_Constants.DOCUMENT_STATUS_COMPLETE, doc.PC_Document_Status__c);
            
            Test.StopTest();
         }
     }
    
  
    /*********************************************************************************
    Method Name    : testlinkDocToCaseDocStatus
    Author         : Prachi Nandgaonkar
    Description    : This method is used for testing "linkDocToCase" with splitting related status
    Return Type    : void 
    Parameter      : Id enrollmentCaseId, String documentId
    *********************************************************************************/
     @isTest static void testlinkDocToCaseDocStatus(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            
            //Test linkDoctoCase() method
            PC_PreviewCaseLightningController.linkDocToCase(enrollCase.Id, oDoc1.Id);
            
            //Query Document Log to see if records were created
            List<PC_Document_Log__c>  lstLogs = [SELECT Id FROM PC_Document_Log__c WHERE PC_Document__c =: oDoc1.Id];
            System.assertEquals(lstLogs.size(), 1);
            
            //Query document to check status
            PC_Document__c doc = [select id, PC_Document_Status__c 
                                        FROM PC_Document__c 
                                        Where Id =: oDoc1.Id];
            
            //check if document status was retained as the splitting status
            System.assertNotEquals(PC_Constants.DOCUMENT_STATUS_COMPLETE, doc.PC_Document_Status__c); 
            System.assertEquals(PC_Constants.DOCUMENT_STATUS_SPLIT_IN_PROGRESS, doc.PC_Document_Status__c);
            
            
            Test.StopTest();
         }
     }
}//END OF TEST CLASS