/**
* Summary:      This is the test class for Document Split Functionality
* Author:       Deloitte
* Company:      Ashfield 
* Created:      19.04.2023 
* <Date>            <Authors Name>            <Brief Description of Change>
* 19/04/2023        Deloitte              Initial Version
**/
@isTest(seeAllData=false)
private class ACLS_Test_DocumentSplitQueueable {

	@testsetup
		private static void dataSetup() {
        User usr = ACLS_Utility.createTestUser('System Administrator', 'TestCaseManager');
        usr.ACLS_Meeting_Link__c='www.abc.invalid';
        insert usr;
        
        // Assigning Required Permission set to Test user
        List<PermissionSetAssignment> lstPsAssignment = new List<PermissionSetAssignment>();
        PermissionSetAssignment psAssignment = ACLS_Utility.assignPermissions(usr.Id, 'ACLS_Base_RW_Permissions');
        lstPsAssignment.add(psAssignment);
        insert lstPsAssignment;

		System.runAs(usr){
		List<PC_Remote_Service_Log__c> testPC_Remote_Service_Logc=ACLS_TestDataFactory.testRemoteServiceLog(1);
        insert testPC_Remote_Service_Logc;
		
		List<PC_Document__c> testPC_Documentc=ACLS_TestDataFactory.PC_DocumentcTestDataMethod(1);
        	testPC_Documentc[0].PC_To_Fax_Name__c='Test Fax';
            testPC_Documentc[0].OwnerId =usr.id;
            testPC_Documentc[0].PC_Document_Status__c='Completed';
            testPC_Documentc[0].PC_Page_Count__c = 1;
        	insert testPC_Documentc;
       
	} 
	}
    
    @isTest
    static void testExecute() {
        String resbody='{"contentDocumentId":"069DO000000L7t5YAC","isSuccess":true}';
        ACLS_DocumentSplitQueueable.res = new HttpResponse();
        ACLS_DocumentSplitQueueable.res.setStatusCode(200);
        ACLS_DocumentSplitQueueable.res.setBody(resbody);
        User u = [Select id from user limit 1];
        System.runAs(u){
            PC_Document__c parentDoc = ACLS_TestDataFactory.createParentDoc();
            List<PC_Document__c> childDocs = ACLS_TestDataFactory.createChildDocuments(parentDoc);
            for(PC_Document__c doc:  childDocs){
                doc.PC_Document_Status__c = ACLS_Constants.SPLIT_FAILURE;
                doc.PC_Sorted_Parent_Pg_Num__c = '4';
            }
            insert childDocs;
    
            
            // Create Content document
                List<ContentVersion> testContentVersion=ACLS_TestDataFactory.testContentDocument(1);
                testContentVersion[0].Title = 'Test1 Document';
                testContentVersion[0].PathOnClient = 'TestDoc.pdf';
                testContentVersion[0].VersionData = Blob.valueOf('Content Test');
                insert testContentVersion;
                     
                //Get content documents 
                Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:testContentVersion[0].Id].ContentDocumentId;
            
               
                
                //Create content document link 
                List<ContentDocumentLink> testCdl = ACLS_TestDataFactory.testContentDocumentLink(1);
                testCdl[0].LinkedEntityId = parentDoc.Id;
                testCdl[0].ContentDocumentId = conDocId;
                testCdl[0].ShareType = 'I';
                testCdl[0].Visibility = 'AllUsers';
                insert testCdl;
    
             Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ACLS_Test_SMSHttpCalloutMock());
    
            // Call the queueable and test results
            
           
            System.enqueueJob(new ACLS_DocumentSplitQueueable(parentDoc, childDocs));
            Test.stopTest();
    
            // Verify parent and child document statuses
            parentDoc = [SELECT PC_Document_Status__c FROM PC_Document__c WHERE Id = :parentDoc.Id];
            System.assertEquals('Split Failure', parentDoc.PC_Document_Status__c);
            childDocs = [SELECT PC_Document_Status__c FROM PC_Document__c WHERE Id IN :childDocs];
            for (PC_Document__c childDoc : childDocs) {
             //System.assertEquals(ACLS_Constants.REVIEW_NEEDED, childDoc.PC_Document_Status__c);
           }
        }
    }
    
    @isTest
    private static void test_getRequestBody() {
      
           PC_Document__c parentDoc = new PC_Document__c();
        insert parentDoc;
           List<PC_Document__c> childDocs = new List<PC_Document__c>{
            new PC_Document__c(PC_Parent_Document__c = parentDoc.Id),
            new PC_Document__c(PC_Parent_Document__c = parentDoc.Id)
        };
        insert childDocs;
            PC_Document__c objChild = new PC_Document__c(PC_Sorted_Parent_Pg_Num__c = '1,2,4,5');
        	insert objChild;
            PC_Document__c objChild1 = new PC_Document__c(PC_Sorted_Parent_Pg_Num__c = '1-2,3-5');
        	insert objChild1;
        	ACLS_DocumentSplitQueueable objACLS_DocumentSplitQueueable = new ACLS_DocumentSplitQueueable(parentDoc,childDocs);
           
        String requestBody = objACLS_DocumentSplitQueueable.getRequestBody(objChild);
        String requestBody1 = objACLS_DocumentSplitQueueable.getRequestBody(objChild1);   	
    }

    @isTest
    static void testExecuteQueued() {
        String resbody='{"contentDocumentId":"069DO000000L7t5YAC","isSuccess":true}';
        ACLS_DocumentSplitQueueable.res = new HttpResponse();
        ACLS_DocumentSplitQueueable.res.setStatusCode(200);
        ACLS_DocumentSplitQueueable.res.setBody(resbody);
        User u = [Select id from user limit 1];
        System.runAs(u){
            PC_Document__c parentDoc = ACLS_TestDataFactory.createParentDoc();
            List<PC_Document__c> childDocs = ACLS_TestDataFactory.createChildDocuments(parentDoc);
            for(PC_Document__c doc:  childDocs){
                doc.PC_Document_Status__c = ACLS_Constants.SPLIT_FAILURE;
                doc.PC_Sorted_Parent_Pg_Num__c = '4';
            }
            insert childDocs;
    
            
            // Create Content document
                List<ContentVersion> testContentVersion=ACLS_TestDataFactory.testContentDocument(1);
                testContentVersion[0].Title = 'Test1 Document';
                testContentVersion[0].PathOnClient = 'TestDoc.pdf';
                testContentVersion[0].VersionData = Blob.valueOf('Content Test');
                insert testContentVersion;
                     
                //Get content documents 
                Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:testContentVersion[0].Id].ContentDocumentId;
            
               
                
                //Create content document link 
                List<ContentDocumentLink> testCdl = ACLS_TestDataFactory.testContentDocumentLink(1);
                testCdl[0].LinkedEntityId = parentDoc.Id;
                testCdl[0].ContentDocumentId = conDocId;
                testCdl[0].ShareType = 'I';
                testCdl[0].Visibility = 'AllUsers';
                insert testCdl;
    
             Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ACLS_Test_SMSHttpCalloutMock());
    
            // Call the queueable and test results
            ACLS_DocumentSplit_IntegrationHandler ds = new ACLS_DocumentSplit_IntegrationHandler();
            ds.splitDocument(parentDoc, childDocs);

            Test.stopTest();
    
            // Verify parent and child document statuses
            parentDoc = [SELECT PC_Document_Status__c FROM PC_Document__c WHERE Id = :parentDoc.Id];
            System.assertEquals('Split Failure', parentDoc.PC_Document_Status__c);
            childDocs = [SELECT PC_Document_Status__c FROM PC_Document__c WHERE Id IN :childDocs];
            for (PC_Document__c childDoc : childDocs) {
             //System.assertEquals(ACLS_Constants.REVIEW_NEEDED, childDoc.PC_Document_Status__c);
           }
        }
    }

    
    
	
}