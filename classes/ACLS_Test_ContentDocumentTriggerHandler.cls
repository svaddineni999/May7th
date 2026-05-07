/**
* Summary:      This is the test class for Content Document Trigger Handler
* Author:       Deloitte
* Company:      Ashfield 
* Created:      31.03.2023 
* <Date>            <Authors Name>            <Brief Description of Change>
* 24/3/2023        Deloitte              Initial Version
**/
@isTest(seeAllData=false)
private class ACLS_Test_ContentDocumentTriggerHandler {
    @testsetup
	private static void dataSetup() {
       User usr = ACLS_Utility.createTestUser('ACLS Base Profile', 'TestCaseManager');
        usr.ACLS_Meeting_Link__c='www.sdahksdka.invalid';
        insert usr;
        
        // Assigning Required Permission set to Test user
        List<PermissionSetAssignment> lstPsAssignment = new List<PermissionSetAssignment>();
        PermissionSetAssignment psAssignment = ACLS_Utility.assignPermissions(usr.Id, 'ACLS_Base_RW_Permissions');
        lstPsAssignment.add(psAssignment);
        insert lstPsAssignment;
        
         System.runAs(usr){
             
            //Create eFax 
    		List<EFX__efax__c> testEFXefaxc=ACLS_TestDataFactory.faxTestDataMethod(1);
            testEFXefaxc[0].EFX__Status__c = 'STORED';
            testEFXefaxc[0].recordTypeId =  ACLS_Utility.getRecordTypeId(ACLS_Constants.OBJ_FAX,ACLS_Constants.FAX_RECEIVED);
            testEFXefaxc[0].EFX__Page__c =1;
            insert testEFXefaxc;
            //Create Engagement 
    		List<PC_Engagement_Program__c> lstEngageProgram=ACLS_TestDataFactory.createEngagmentProgram(1);
            lstEngageProgram[0].PC_Program_Code__c = 'ASHF';
            insert lstEngageProgram;
            // Create document
    		List<PC_Document__c> testPC_Documentc=ACLS_TestDataFactory.PC_DocumentcTestDataMethod(1);
        	testPC_Documentc[0].PC_To_Fax_Name__c='Test Fax';
            testPC_Documentc[0].OwnerId =usr.id;
            testPC_Documentc[0].PC_Document_Status__c='New';
            testPC_Documentc[0].PC_Page_Count__c = 1;
        	insert testPC_Documentc;
         
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
            testCdl[0].LinkedEntityId = testEFXefaxc[0].Id;
            testCdl[0].ContentDocumentId = conDocId;
            testCdl[0].ShareType = 'I';
            testCdl[0].Visibility = 'AllUsers';
            insert testCdl;
            
            Test.startTest();
            ACLS_ContentDocumentTriggerHandler.createDocumentRecordForFaxInbound(testCdl);
            Test.stopTest();

}
    }
        
    @isTest 
	private static void test_afterInsert() {
        	EFX__efax__c faxRecord = new EFX__efax__c(
        	EFX__Status__c = 'STORED',recordTypeId =  ACLS_Utility.getRecordTypeId(ACLS_Constants.OBJ_FAX,ACLS_Constants.FAX_RECEIVED)
       
    );
        
           //Check doc record is created
            
            List<PC_Document__c> listDoc = [Select Id,RecordTypeId,ACLS_Subject__c,PC_Document_Status__c,PC_Fax_Unique_Id__c,PC_From_Fax_Number__c,PC_Page_Count__c,PC_To_Fax_Number__c,ACLS_Fax__c,ACLS_Message__c,PC_Engagement_Program__c From PC_Document__c Where ACLS_Fax__c = :faxRecord.Id];
            
            System.assertEquals(1,listDoc.size());
            
            List<Task> exceptionList = [Select Id, WhoId,ActivityDate From Task Where WhoId =:faxRecord.Id And Subject ='Exception Occurred' And ActivityDate = Today];
 
    }
 
}