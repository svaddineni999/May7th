/**************************************************************************************
Apex Class Name     : PC_Test_InboundFaxLightningController
Description         : This class is used for testing PC_DocInboundFaxLightningController;
CreatedBy           : Deloitte
Created Date        : 16 June 2016
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Alina Balan                 16 June 2016           Initial version
*************************************************************************************/
@isTest(seeAllData=False) 
public with sharing class PC_Test_InboundFaxLightningController {
    private static User objUser;
    private static User objUser2;
    private static PC_Document__c oDoc;
    private static Attachment oAttachment;
    private static final String DOC_CATEGORY = 'Enrollment Form';
    //private static final String DOC_CATEGORY_PRESCRIPTION = 'Prescription';
    
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Alina Balan
    Description    : This method is used for creating test data
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    private static void createTestData() {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.CALL_CENTER_AGENT_PROFILE, 'user@test80.com', 'test80');
        PC_Database.ins(objUser);
        objUser2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test79.com', 'test79');
        PC_Database.ins( objUser2);
        createObjects();
    }
    
    /*********************************************************************************
    Method Name    : createDoc
    Author         : Alina Balan
    Description    : This method is used for creating a document with attachments
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    private static void createObjects() {
        system.runAs(objUser2) {
            oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_NEW);
            Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);
            oDoc.PC_Document_Category__c = DOC_CATEGORY;
            oDoc.RecordTypeId = recordTypeId;
            PC_Database.ins(oDoc);
            oAttachment = PC_Test_Setup.createAttachment(oDoc.Id);
            PC_Database.ins(oAttachment);
        }
    }
    
    /*********************************************************************************
    Method Name    : testgetAttachmentId
    Author         : Alina Balan
    Description    : This method is used for testing "getAttachmentId"
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testgetAttachmentId(){
        createTestData();
        system.runAs(objUser2) {
            Test.StartTest();
            PC_DocumentInboundFaxLightningController.FaxDetailsWrapper faxWrapper = PC_DocumentInboundFaxLightningController.getAttachmentId(oDoc.Id + '');
            system.assertNotEquals(faxWrapper.attachmentId, null);
            Test.StopTest();
         }
     }
}