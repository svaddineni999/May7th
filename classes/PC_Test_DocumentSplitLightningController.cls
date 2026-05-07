/**************************************************************************************
Apex Class Name     : PC_Test_DocumentSplitLightningController
Description         : This class is used for testing PC_DocumentSplit;
CreatedBy           : Deloitte
Created Date        : 6 February 2017
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Prachi Nandgaonkar          6-Feb-2017            Initial version
Mike Klumpenaar             14-Dec-2017           [PC-2601] Added order by to test, since it is done in controller and
                                                  test was failing during patch creation.
Kishore Kanteti            21-May-2021          [PC-7739] Used method convertRangeToNumbers() to convert Range to Numbers for PC_Sorted_Parent_Pg_Num__c
*************************************************************************************/
@isTest
public class PC_Test_DocumentSplitLightningController {
	
    private static User adminUser;
    private static Attachment oAttachment;
    
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Prachi Nandgaonkar
    Description    : This method is used for creating test data
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    
    private static void createTestData() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'pctest2');
        PC_Database.ins(adminUser, false);
  }
    
    /*********************************************************************************
    Method Name    : testcreateChildDoc
    Author         : Prachi Nandgaonkar
    Description    : This method is used for testing creation of a child document
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest
    static void testcreateChildDoc(){
        createTestData();
        //Constants for creating a document
        String pgRange = '1-3';
	    String sortedPgNum = '1,2,3';
        String pageCount = '6';
        
        Test.StartTest();
        system.runAs(adminUser) {
            
            //Creating a parent document
            PC_Document__c parentDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED);
			PC_Database.ins(parentDoc, false);
            
            //set ownerid and page count
            parentDoc.OwnerId = adminUser.Id;
            parentDoc.PC_Page_Count__c = Integer.valueOf(pageCount);
            
            //check document was created
            System.assertNotEquals(parentDoc.Id, null);
            
            //create an attachment on parent document
            oAttachment = PC_Test_Setup.createAttachment(parentDoc.Id);
            PC_Database.ins(oAttachment, false);
            //check attachment was created
            System.assertNotEquals(oAttachment.Id, null);
            
            //Test createChildDoc()
            PC_DocumentSplitLightningController.createChildDoc(pgRange, parentDoc.Id, sortedPgNum, pageCount);
            List<PC_Document__c> childDoc = [select id, OwnerId, RecordTypeId, PC_From_Name__c,PC_Parent_Document__c, 
                                             PC_Document_Status__c, PC_From_Fax_Number__c,PC_From_Email_Address__c,
                                             PC_Page_Count__c,PC_ParentPgRange__c,PC_Sorted_Parent_Pg_Num__c
                                             FROM PC_Document__c Where PC_Parent_Document__c =: parentDoc.Id];
            //check if child document was created 
            System.assertNotEquals(null, childDoc[0].Id);                      
            
            
            //check if child document inherited required attributes from parent document
            System.assertEquals(parentDoc.RecordTypeId, childDoc[0].RecordTypeId);
            System.assertEquals(parentDoc.OwnerId, childDoc[0].OwnerId);
            System.assertEquals(parentDoc.PC_From_Name__c, childDoc[0].PC_From_Name__c);
            System.assertEquals(parentDoc.PC_From_Email_Address__c, childDoc[0].PC_From_Email_Address__c);
            System.assertEquals(parentDoc.Id, childDoc[0].PC_Parent_Document__c);
            
            //check if page counts were saved on child document
            System.assertEquals(pgRange, childDoc[0].PC_ParentPgRange__c);
            System.assertEquals(sortedPgNum, PC_Utility.convertRangeToNumbers(childDoc[0].PC_Sorted_Parent_Pg_Num__c));
            System.assertEquals(Integer.valueOf(pageCount), childDoc[0].PC_Page_Count__c);
            
            //check if child document status was changed to 'Ready for Split'
            System.assertEquals(PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT, childDoc[0].PC_Document_Status__c);

            PC_Test_Setup.createFile(parentDoc.Id);
            PC_Test_Setup.createFile(childDoc[0].Id);
            PC_DocumentSplitLightningController.updateStatus(parentDoc.Id);
            
      Test.StopTest();
            
      }
    }

    /*********************************************************************************
    Method Name    : testgetChildDocs
    Author         : Prachi Nandgaonkar
    Description    : This method is used for testing fetching a list of child documents
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest
    static void testgetChildDocs(){
        createTestData();
        //Constants for creating a document
        String pgRange = '1-3';
	    String sortedPgNum = '1,2,3';
        String pageCount = '6';
        
        Test.StartTest();
        system.runAs(adminUser) {

            //Creating a parent document
            PC_Document__c pDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED);
			PC_Database.ins(pDoc, false);

            //check document was created
            System.assertNotEquals(pDoc.Id, null);

            PC_Document__c parentDoc = [select id, PC_Document_Status__c FROM PC_Document__c WHERE id =: pDoc.Id];

            //create an attachment on parent document
            oAttachment = PC_Test_Setup.createAttachment(parentDoc.Id);
            PC_Database.ins(oAttachment, false);
            //check attachment was created
            System.assertNotEquals(oAttachment.Id, null);

            //Create multiple child documents
            PC_DocumentSplitLightningController.createChildDoc('1-3', parentDoc.Id, '1,2,3', '6');
            PC_DocumentSplitLightningController.createChildDoc('2', parentDoc.Id, '2', '6');
            List<PC_Document__c> lstchildDoc = [SELECT Id, PC_Parent_Document__c,PC_Document_Status__c,PC_Page_Count__c
                                                FROM PC_Document__c WHERE PC_Parent_Document__c =: parentDoc.Id];
            //check if child documents were created
            System.assertNotEquals(null, lstchildDoc[0].Id);
            System.assertNotEquals(null, lstchildDoc[1].Id);
            System.assertEquals(2, lstchildDoc.size());

            //check if child was linked to parent document
            System.assertEquals(parentDoc.Id, lstchildDoc[0].PC_Parent_Document__c);
            System.assertEquals(parentDoc.Id, lstchildDoc[1].PC_Parent_Document__c);

            //Query updated parent and child documents after trigger executed
            parentDoc = [SELECT Id, PC_Document_Status__c FROM PC_Document__c WHERE id =: pDoc.Id];
            lstchildDoc = [SELECT Id, PC_Parent_Document__c,PC_Document_Status__c,PC_Page_Count__c
                    FROM PC_Document__c WHERE PC_Parent_Document__c =: parentDoc.Id
                    ORDER BY CreatedDate DESC];

            //Test getChildDocs()
            List<PC_DocumentSplitLightningController.DocumentWrapper> docwrap = PC_DocumentSplitLightningController.getChildDocs(parentDoc.Id);

            //check if documents were correctly added to the document wrapper
            System.assertEquals(lstchildDoc[0].Id, docWrap[0].DocumentId);
            System.assertEquals(lstchildDoc[1].Id, docWrap[1].DocumentId);
            
            Test.StopTest();
            
      }
    }

    
    /*********************************************************************************
    Method Name    : testdeleteChildDoc
    Author         : Prachi Nandgaonkar
    Description    : This method is used for testing deletion of a child document
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest
    static void testdeleteChildDoc(){
        createTestData();
        system.runAs(adminUser) {
            
            Test.StartTest();
            
            //Creating a child document
            PC_Document__c childDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED);
            PC_Database.ins(childDoc, false);
            
            //check document was created
            System.assertNotEquals(childDoc.Id, null);
            
            //Test createDeleteChildDoc()
            PC_DocumentSplitLightningController.deleteChildDoc( (String)childDoc.Id );
            List<PC_Document__c> lstchildDoc = [select id,Name FROM PC_Document__c Where id =: childDoc.Id];
            
            //check if the child document has been deleted
            System.assertEquals(0, lstchildDoc.size());
            Test.StopTest();
            
         }
     }
    
    /*********************************************************************************
    Method Name    : testupdateChildDoc
    Author         : Prachi Nandgaonkar
    Description    : This method is used for testing updating a child document page range, status and correlation id
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest
    static void testupdateChildDoc(){
        createTestData();
        //Constants for creating a child document
        String pgRange = '2-4';
	    String sortedPgNum = '2,3,4';
        String pageCount = '6';

        system.runAs(adminUser) {
            
            Test.StartTest();
  
            //Creating a child document
            PC_Document__c childDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED);
            PC_Database.ins(childDoc, false);
            
            //check document was created
            System.assertNotEquals(childDoc.Id, null);
            
            //create an attachment on child document
            oAttachment = PC_Test_Setup.createAttachment(childDoc.Id);
            PC_Database.ins(oAttachment, false);
            //check attachment was created
            System.assertNotEquals(oAttachment.Id, null);
            
            //Test updChildDoc()
            PC_Test_Setup.createFile(childDoc.Id);
            PC_DocumentSplitLightningController.updChildDoc((String)childDoc.Id, pgRange, sortedPgNum, pageCount);

            Boolean  useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();
            system.debug('isSalesforceFileCheck-- intest class'+useSalesforceFiles);
            if(useSalesforceFiles) {

                List<ContentDocumentLink> listContentDocumentsLink = [SELECT ContentDocumentId, Id FROM ContentDocumentLink WHERE LinkedEntityId = :childDoc.Id];

                if (listContentDocumentsLink.size() > 0) {
                    List<ContentDocument> listContentDocuments = [SELECT Id FROM ContentDocument WHERE Id = :listContentDocumentsLink[0].ContentDocumentId];
                    System.assertEquals(0, listContentDocuments.size());
                }
            }
            else {
                List<Attachment> lstAttachments =  [SELECT Id FROM Attachment WHERE ParentId = :childDoc.Id];
                System.assertEquals(0, lstAttachments.size());

            }
            //check if the child document attachment was deleted

            
            PC_Document__c doc = [select id, PC_Parent_Document__c, PC_Document_Status__c,PC_Correlation_Id__c,
                                       PC_Page_Count__c,PC_ParentPgRange__c,PC_Sorted_Parent_Pg_Num__c
                                       FROM PC_Document__c WHERE id =: childDoc.Id];
            
            //check if page range was updated
            System.assertEquals(pgRange, doc.PC_ParentPgRange__c);
            System.assertEquals(sortedPgNum, PC_Utility.convertRangeToNumbers(doc.PC_Sorted_Parent_Pg_Num__c));
            System.assertEquals(Integer.valueOf(pageCount), doc.PC_Page_Count__c);
            
            //check if status was updated to 'Ready for split'
            System.assertEquals(PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT, doc.PC_Document_Status__c);
            
            //check if correlation id was reset to null
            System.assertEquals(null, doc.PC_Correlation_Id__c);
            
            Test.StopTest();
            
         }
     }
          
    /*********************************************************************************
    Method Name    : testgetParentDocCount
    Author         : Prachi Nandgaonkar
    Description    : This method is used for testing fetching parent document page count
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest
    static void testgetParentDocCount(){
        createTestData();
		system.runAs(adminUser) {
            
            Test.StartTest();
            
            //Creating a parent document
            PC_Document__c parentDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED);
            PC_Database.ins(parentDoc, false);            
            
            //Test getParentDocumentCount()
            Integer getpageCount = PC_DocumentSplitLightningController.getParentDocumentCount(parentDoc.Id);
            System.assertEquals(parentDoc.PC_Page_Count__c, getpageCount);
    
            Test.StopTest();
            
         }
     }  
    
    
    /*********************************************************************************
    Method Name    : testupdateStatus
    Author         : Prachi Nandgaonkar
    Description    : This method is used for testing if parent document status is updated when split request is made
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    //THIS METHOD HAS BEEN MOVED TO PC_Test_DocumentSplitWebservice
    
 
} //END OF TEST CLASS