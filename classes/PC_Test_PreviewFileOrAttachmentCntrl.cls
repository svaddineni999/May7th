/*********************************************************************************
Class Name         : PC_Test_PreviewFileOrAttachmentCntrl
Description        : Test Class for PC_PreviewFileOrAttachmentController Class
Created By         : Haritha Reddy
Created Date       : 07-Jul-2019
Modification Log   :
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy          07-Jul-2019              Initial Version
*********************************************************************************/
@isTest
public with sharing class PC_Test_PreviewFileOrAttachmentCntrl {
    private static User adminUser;
    private static PC_Document__c oDoc,childDoc;
    private static Attachment oAttachment;
    private static final String ENG_PROGRAM_NAME = 'Program';
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Haritha Reddy
    Description    : This method is used for creating test data
    Return Type    : void
    Parameter      : N/A
    *********************************************************************************/
    private static void createTestData() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@email.com', 'pctest');
        PC_Database.ins(adminUser, false);

        oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'A');
        Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);
        oDoc.RecordTypeId = recordTypeId;
        PC_Database.ins(oDoc, false);

        childDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'B');
        childDoc.RecordTypeId = recordTypeId;
        childDoc.PC_Parent_Document__c = oDoc.Id;
        PC_Database.ins(childDoc, false);

        PC_Test_Setup.createFile(oDoc.Id);
        PC_Test_Setup.createFile(childDoc.Id);
    }
    //Test Scenario: Only File is there related to Document.
    @isTest
    static void testGetDocumentDetailsForFile() {
        createTestData();
        Test.StartTest();
        system.runAs(adminUser) {
            PC_PreviewFileOrAttachmentController.getDocumentDetails(oDoc.Id);
        }
        Test.StopTest();
    }
    //Test Scenario: Both Attachments anf Files are there related to Document.
    @isTest
    static void testGetDocumentDetailsForAttachment() {
        createTestData();
        Test.StartTest();
        system.runAs(adminUser) {
            oAttachment = PC_Test_Setup.createAttachment(oDoc.Id);
            oAttachment.ContentType = 'text';
            PC_Database.ins(oAttachment, false);
            PC_PreviewFileOrAttachmentController.getDocumentDetails(oDoc.Id);
        }
        Test.StopTest();
    }

}