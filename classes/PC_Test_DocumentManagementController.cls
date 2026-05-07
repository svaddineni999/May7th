/**************************************************************************************
Apex Class Name     : PC_Test_DocumentManagementController
Description         : This class is used for testing DTPC_DocumentManagementController;
CreatedBy           : Deloitte
Created Date        : 30 May 2016
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Alina Balan              26-May-2016               Initial version, PC-20-PC26
Ajinkya Deshmukh			25 Apr 2017			   [PC-1365] Updated class to associate engagement program to document
*************************************************************************************/
@isTest(seeAllData=False) 
private class PC_Test_DocumentManagementController {
    private static User objUser;
    private static User objUser2;
    private static QueuesObject oQueue;
    private static Group oGroup;
    private static final String ENG_PROGRAM_NAME = 'program';
    
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Alina Balan
    Description    : This method is used for creating test data
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    private static void createTestData() {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.CALL_CENTER_AGENT_PROFILE, 'userpctest@test1.com', 'pctest1');
        PC_Database.ins(objUser, false);
        objUser2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'pctest2');
        PC_Database.ins(objUser2, false);
        oGroup = PC_Test_Setup.createGroup();
        PC_Database.ins(oGroup, false);
        oQueue = PC_Test_Setup.createQueue(oGroup);
        PC_Database.ins(oQueue, false);
    }
    
    /*********************************************************************************
    Method Name    : testController
    Author         : Alina Balan
    Description    : This method is used for testing the constructor 
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testController(){
        createTestData();
        system.runAs(objUser2) {
            PC_Document__c oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_CATEGORIZED);
            PC_Database.ins(oDoc, false);
            system.assertNotEquals(oDoc.Id, null);
            Attachment oAttachment = PC_Test_Setup.createAttachment(oDoc.Id);
            PC_Database.ins(oAttachment, false);
            system.assertNotEquals(oAttachment.Id, null);
            
            Test.StartTest();
            ApexPages.StandardController sscController = new ApexPages.StandardController(oDoc);
            PC_DocumentManagementController controller = new PC_DocumentManagementController(sscController);
            system.assertEquals(controller.sAttachmentId, oAttachment.Id);
            system.assertEquals(controller.loadFaxContainer, true);
            Test.StopTest();
            
         }
     }
     
    /*********************************************************************************
    Method Name    : testController
    Author         : Alina Balan
    Description    : This method is used for testing the constructor without any attachment, for many document types
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testControllerNoAttachment(){
        createTestData();
        system.runAs(objUser2) {
            PC_Document__c oDoc1 = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_CATEGORIZED, ENG_PROGRAM_NAME + 'A');
            PC_Database.ins(oDoc1, false);
            PC_Document__c oDoc2 = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_EMAIL_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_CATEGORIZED, ENG_PROGRAM_NAME + 'B');
            PC_Database.ins(oDoc2, false);
            PC_Document__c oDoc3 = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_SMARTFORM_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_CATEGORIZED, ENG_PROGRAM_NAME + 'C');
            PC_Database.ins(oDoc3, false);
            system.assertNotEquals(oDoc1.Id, null);
            Test.StartTest();
            ApexPages.StandardController sscController1 = new ApexPages.StandardController(oDoc1);
            ApexPages.StandardController sscController2 = new ApexPages.StandardController(oDoc2);
            ApexPages.StandardController sscController3 = new ApexPages.StandardController(oDoc3);
            PC_DocumentManagementController controller = new PC_DocumentManagementController(sscController1);
            controller = new PC_DocumentManagementController(sscController2);
            controller = new PC_DocumentManagementController(sscController3);
            system.assertEquals(controller.sAttachmentId, null);
            oDoc1.OwnerId = oGroup.Id;
            PC_Database.upd(oDoc1);
            controller.oDocument = oDoc1;
            
            Test.StopTest();
            controller.changeDocumentOwner();
            system.assertEquals(controller.oDocument.OwnerId, oGroup.Id);
         }
     }
    
    /*********************************************************************************
    Method Name    : testChangeDocumentOwner
    Author         : Alina Balan
    Description    : This method is used for testing "changeDocumentOwner"
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testChangeDocumentOwner(){
        createTestData();
        system.runAs(objUser2) {
            PC_Document__c oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_CATEGORIZED);
            PC_Database.ins(oDoc, false);
            Attachment oAttachment = PC_Test_Setup.createAttachment(oDoc.Id);
            PC_Database.ins(oAttachment, false);

            Test.StartTest();
            ApexPages.StandardController sscController = new ApexPages.StandardController(oDoc);
            PC_DocumentManagementController controller = new PC_DocumentManagementController(sscController);
            oDoc.OwnerId = oGroup.Id;
            PC_Database.upd(oDoc);
            controller.oDocument = oDoc;

            List<PC_Document__c> lstDocs = [Select Id, OwnerId, PC_Document_Status__c from PC_Document__c where Id =: oDoc.Id];
            List<User> lstUsers = [SELECT Id FROM User WHERE Id =: oDoc.OwnerId];
            
            system.assertEquals(lstDocs.size(), 1);
            system.assertNotEquals(controller.oDocument.OwnerId, userinfo.getUserId());
            system.assertEquals(controller.oDocument.PC_Document_Status__c, PC_Constants.DOCUMENT_STATUS_CATEGORIZED);
            system.assertEquals(lstUsers.size(), 0);
            controller.changeDocumentOwner();
            system.assertEquals(controller.oDocument.OwnerId, objUser2.Id);
            
            Test.StopTest();
         }
     }
 }