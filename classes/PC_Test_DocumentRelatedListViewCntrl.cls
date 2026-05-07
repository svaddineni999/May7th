/*********************************************************************************
Class Name         : PC_Test_DocumentRelatedListViewCntrl
Description        : Test Class for PC_DocumentRelatedListViewController Class
Created By         : Haritha Reddy
Created Date       : 07-Jul-2019
Modification Log   :
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy          07-Jul-2019              Initial Version
*********************************************************************************/
@isTest
public class PC_Test_DocumentRelatedListViewCntrl {
    private static User adminUser;
    private static PC_Document__c oDoc,childDoc,childSplitDoc,parentDoc;
    private static Attachment childAttachment,parentAttachment;
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
        
		Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.DOCUMENT_OBJECT, PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE);
        
        //Insert Parent Document
        parentDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'P');
        parentDoc.RecordTypeId = recordTypeId;
        PC_Database.ins(parentDoc, false);
        
        oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'A');
        oDoc.RecordTypeId = recordTypeId;
        oDoc.PC_Parent_Document__c = parentDoc.Id;
        PC_Database.ins(oDoc, false);

        childDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'B');
        childDoc.RecordTypeId = recordTypeId;
        childDoc.PC_Parent_Document__c = oDoc.Id;
        PC_Database.ins(childDoc, false);
        
        //Insert Split Child Document
        childSplitDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'C');
        childSplitDoc.RecordTypeId = recordTypeId;
        childSplitDoc.PC_Parent_Document__c = oDoc.Id;
        childSplitDoc.PC_IsSplit__c = true;
        PC_Database.ins(childSplitDoc, false);

        PC_Test_Setup.createFile(oDoc.Id);
        PC_Test_Setup.createFile(childDoc.Id);
        PC_Test_Setup.createFile(childSplitDoc.Id);
    }
    
    //Test Scenario: Both Attachments and Files are there related to Document.
    @isTest static void testGetDocumentDetailsForAttachment() {
        createTestData();
        Test.StartTest();
        system.runAs(adminUser) {
            childAttachment = PC_Test_Setup.createAttachment(childDoc.Id);
            childAttachment.ContentType = 'text';
            PC_Database.ins(childAttachment, false);
            parentAttachment = PC_Test_Setup.createAttachment(childSplitDoc.Id);
            parentAttachment.ContentType = 'text';
            PC_Database.ins(parentAttachment, false);
            PC_DocumentRelatedListViewController.getChildDocs(oDoc.Id,true);
        }
        Test.StopTest();
    }
}