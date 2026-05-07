/**
 * Created by sathekumar on 9/1/2022.
 */

@isTest
public with sharing class PC_Test_DocumentSplitMockService {
    private static User adminUser;
    private static PC_Document__c parentDoc;
    private static PC_Document__c[] childDocs;
    private static Attachment parentAttachment;
    private static final String ENG_PROGRAM_NAME = 'Program';

    /**
     * Creates test data for other unit test methods
     */
    private static void createTestData() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'pctest2');
        PC_Database.ins(adminUser, false);
        //create a parent Document
        parentDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'A');
        parentDoc.OwnerId = adminUser.Id;
        parentDoc.PC_Page_Count__c = 50;
        parentDoc.PC_Correlation_Id__c = '100';
        PC_Database.ins(parentDoc, false);
        //check document was created
        System.assertNotEquals(parentDoc.Id, null);
        //create an attachment on parent document
        parentAttachment = PC_Test_Setup.createAttachment(parentDoc.Id);
        PC_Database.ins(parentAttachment, false);
        //check attachment was created
        System.assertNotEquals(parentAttachment.Id, null);

        childDocs = new PC_Document__c[2];

        //create a parent Document
        childDocs[0] = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'B');
        childDocs[0].OwnerId = adminUser.Id;
        childDocs[0].PC_Page_Count__c = 3;
        childDocs[0].PC_Sorted_Parent_Pg_Num__c = '1,2,3';
        childDocs[0].PC_Parent_Document__c = parentDoc.Id;
        PC_Database.ins(childDocs[0], false);
        //check document was created
        System.assertNotEquals(childDocs[0].Id, null);

        //create a parent Document
        childDocs[1] = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, ENG_PROGRAM_NAME + 'C');
        childDocs[1].OwnerId = adminUser.Id;
        childDocs[1].PC_Page_Count__c = 5;
        childDocs[1].PC_Sorted_Parent_Pg_Num__c = '1,2,3,4,5';
        childDocs[1].PC_Parent_Document__c = parentDoc.Id;
        PC_Database.ins(childDocs[1], false);
        //check document was created
        System.assertNotEquals(childDocs[1].Id, null);

        PC_System_Settings__c docSplitSystemSetting = new PC_System_Settings__c();
        docSplitSystemSetting.PC_Document_Splitter_Class__c = 'PC_DocumentSplitMockService';
        PC_Database.ins(docSplitSystemSetting, false);
    }

    @IsTest
    static void testMissingIntegrationSettings() {
        createTestData();

        system.runAs(adminUser) {
            Test.startTest();
            PC_Document.Splitter splitService = new PC_DocumentSplitMockService();

            try {
                splitService.splitDocument(parentDoc, childDocs);

                System.assert(false, 'Exception split exception due to missing configuration');
            } catch (PC_Document.SplitException e) {
                // expected exception
                //PC_Utility.logAndThrowException(e);
            }

            PC_Integration_Settings__c docSplitIntegrationSetting = new PC_Integration_Settings__c();
            docSplitIntegrationSetting.Name = PC_Constants.DOCUMENT_SPLIT_SERVICE;
            docSplitIntegrationSetting.endpoint_Url__c = null;
            docSplitIntegrationSetting.username__c = 'user';
            docSplitIntegrationSetting.password__c = 'password';
            PC_Database.ins(docSplitIntegrationSetting, false);

            try {
                splitService.splitDocument(parentDoc, childDocs);

                System.assert(false, 'Exception split exception due to missing endpoint');
            } catch (PC_Document.SplitException e) {
                // expected exception
                // PC_Utility.logAndThrowException(e);
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testCalloutPass() {
        createTestData();

        PC_Integration_Settings__c docSplitIntegrationSetting = new PC_Integration_Settings__c();
        docSplitIntegrationSetting.Name = PC_Constants.DOCUMENT_SPLIT_SERVICE;
        docSplitIntegrationSetting.endpoint_Url__c = '/SomePath';
        docSplitIntegrationSetting.username__c = 'user';
        docSplitIntegrationSetting.password__c = 'password';
        PC_Database.ins(docSplitIntegrationSetting, false);

        system.runAs(adminUser) {
            Test.startTest();
            PC_DocumentSplitMockService callout = new PC_DocumentSplitMockService();
            callout.splitDocument(parentDoc, childDocs);
            Test.stopTest();
        }
    }

    @IsTest
    static void testCalloutFailWithoutAttachment() {
        createTestData();
        PC_Database.del(parentAttachment);

        system.runAs(adminUser) {
            Test.startTest();

            try {
                PC_DocumentSplitMockService callout = new PC_DocumentSplitMockService();
                callout.splitDocument(parentDoc, childDocs);
                System.assert(false, 'Expected failure due to missing attachment on parent doc');
            } catch (PC_Document.SplitException e) {
                // expected exception
                //PC_Utility.logAndThrowException(e);
            }

            Test.stopTest();
        }
    }

}