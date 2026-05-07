/*********************************************************************************
Class Name      : PC_Test_DocumentSplitWebservice
Description     : Test class for PC_DocumentSplitWebservice
Created By      : Ajinkya Deshmukh
Created Date    : 2/7/2017
Modification Log:
---------------------------------------------------------------------------------- 
Developer               Date            Description
-----------------------------------------------------------------------------------            
Ajinkya Deshmukh        2/7/2017        Initial Version
Prachi Nandgaonkar      2/16/2017       Updated documentSplitCallout() to handle scenario if parent document is deleted immediately after split has been executed [PC-1171]
Ajinkya Deshmukh		4/25/2017		[PC-1365] Updated class to associate engagement program to document
Mayuresh Patil          7/07/2017       [PC-1867] Remove hardcoding of the Integration serive name.
Mike Klumpenaar         2/25/2019       [PC-4474] Updated testing based on new Mock HTTP class
Shishir Bansal          Dec-16-2019       [PC-5792] Avoid hardcoding of string variable
*********************************************************************************/
@isTest
private class PC_Test_DocumentSplitWebservice {
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
        docSplitSystemSetting.PC_Document_Splitter_Class__c = 'PC_DocumentSplitWebservice';
        PC_Database.ins(docSplitSystemSetting, false);
	}

    @IsTest
    static void testMissingIntegrationSettings() {
        createTestData();

        system.runAs(adminUser) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new DocumentSplitServiceMock(false));

            PC_Document.Splitter splitService = new PC_DocumentSplitWebservice();

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

        DocumentSplitServiceMock mock = new DocumentSplitServiceMock(true);

        system.runAs(adminUser) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, mock);

            PC_DocumentSplitWebservice callout = new PC_DocumentSplitWebservice();
            callout.splitDocument(parentDoc, childDocs);

            Test.stopTest();

            System.assert(mock.receivedValidRequest());
        }       
    }

    @IsTest
    static void testCalloutFailInService() {
        createTestData();

        system.runAs(adminUser) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new DocumentSplitServiceMock(true));

            // method check
            String body = PC_DocumentSplitWebservice.generateJson(parentDoc, childDocs);

            PC_DocumentSplitWebservice.splitDocumentCallout('/Fail', body, 'user', 'pass');

            // stop test before checking results, since we are invoking a future method
            Test.stopTest();

            PC_Document__c updatedParentDoc = [SELECT Id, PC_Document_Status__c FROM  PC_Document__c WHERE Id = :parentDoc.Id];
            System.assertEquals(PC_Constants.DOCUMENT_STATUS_SPLIT_FAILURE, updatedParentDoc.PC_Document_Status__c);
        }
    }

    @IsTest
    static void testCalloutFailWithoutAttachment() {
        createTestData();
        PC_Database.del(parentAttachment);

        system.runAs(adminUser) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new DocumentSplitServiceMock(false));

            try {
                PC_DocumentSplitWebservice callout = new PC_DocumentSplitWebservice();
                callout.splitDocument(parentDoc, childDocs);
                System.assert(false, 'Expected failure due to missing attachment on parent doc');
            } catch (PC_Document.SplitException e) {
                // expected exception
                //PC_Utility.logAndThrowException(e);
            }

            Test.stopTest();
        }
    }

    @IsTest
    static void testGenerateJson() {
        createTestData();

        Test.startTest();

        // method check
        String jsonBody = PC_DocumentSplitWebservice.generateJson(parentDoc, childDocs);

        Map<String, Object> bodyMap = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
        System.assertEquals(parentDoc.Id, bodyMap.get('parentDocId'));

        List<Object> documentGroupings = (List<Object>) bodyMap.get('documentGroupings');
        System.assertEquals(2, documentGroupings.size());

        Test.stopTest();
    }

    public class DocumentSplitServiceMock implements HttpCalloutMock {
        private Boolean failOnRespond = false;
        private Boolean receivedValidRequest = false;

        public DocumentSplitServiceMock(Boolean failOnRespond) {
            this.failOnRespond = failOnRespond;
        }

        public Boolean receivedValidRequest() {
            return receivedValidRequest;
        }

        // implementing the interface method
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();

            Map<String, Object> jsonBody = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
            List<Object> documentGroupings = (List<Object>) jsonBody.get('documentGroupings');
            System.assertEquals(2, documentGroupings.size());

            Map<String, Object> childDoc1 = (Map<String, Object>) documentGroupings[0];
            List<Object> pages = (List<Object>) childDoc1.get('pages');
            System.assertEquals(3, pages.size());

            receivedValidRequest = true;

            if(!failOnRespond) {
                res.setStatusCode(200);
            } else if (failOnRespond || req.getEndpoint().endsWith('Fail')) {
                res.setStatusCode(400);
            } else if (req.getEndpoint().endsWith('Timeout')) {
                throw new System.CalloutException('Timeout');
            }

            return res;
        }
    }
}