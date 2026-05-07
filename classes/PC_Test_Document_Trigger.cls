/**************************************************************************************
Apex Class Name     : PC_Test_Document_Trigger
Description         : This class is used for testing PC_Trigger_Document;
CreatedBy           : Deloitte
Created Date        : 7 February 2017
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Prachi Nandgaonkar          7-Feb-2017            Initial version
Tejas Patel				    12-Jul-2017           PC-1875 ignore test if trigger is disabled in metadata
Shabda Bhujad               Dec 14, 2017          PC-1884 Updated the name of the handler the test class should check for
*************************************************************************************/
@isTest
public class PC_Test_Document_Trigger {
    
    private static User adminUser;
    public static Boolean isTriggerActive = True;

    /*********************************************************************************
Method Name    : testafterUpdate
Author         : Prachi Nandgaonkar
Description    : This method is used for testing updateParentDocumentStatus() on PC_Trigger_Document
Return Type    : void
Parameter      :
*********************************************************************************/
    @isTest
    static void testafterUpdate(){
        if(isTriggerActive){
            adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser, false);


            Test.StartTest();
            system.runAs(adminUser) {
                //Creating a parent document
                PC_Document__c pDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED);
                PC_Database.ins(pDoc, false);

                //check document was created
                System.assertNotEquals(pDoc.Id, null);

                PC_Document__c parentDoc = [select id, PC_Document_Status__c FROM PC_Document__c WHERE id =: pDoc.Id];

                //Create multiple child documents
                PC_DocumentSplitLightningController.createChildDoc('1-3', parentDoc.Id, '1,2,3', '6');
                PC_DocumentSplitLightningController.createChildDoc('2', parentDoc.Id, '2', '6');
                List<PC_Document__c> lstchildDoc = [select id, PC_Parent_Document__c,PC_Document_Status__c,PC_Page_Count__c
                                                    FROM PC_Document__c Where PC_Parent_Document__c =: parentDoc.Id];
                //check if child documents were created
                System.assertNotEquals(null, lstchildDoc[0].Id);
                System.assertNotEquals(null, lstchildDoc[1].Id);
                System.assertEquals(2, lstchildDoc.size());

                //check if child was linked to parent document
                System.assertEquals(parentDoc.Id, lstchildDoc[0].PC_Parent_Document__c);
                System.assertEquals(parentDoc.Id, lstchildDoc[1].PC_Parent_Document__c);

                //update child document status to 'Split Failure' when no attachment is returned by document splitter service
                lstChildDoc[0].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_SPLIT_FAILURE;
                lstChildDoc[1].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_SPLIT_FAILURE;
                PC_Database.upd(lstchildDoc);
                //Query updated status after trigger executed
                parentDoc = [select id, PC_Document_Status__c FROM PC_Document__c WHERE id =: pDoc.Id];
                lstchildDoc = [select id, PC_Parent_Document__c,PC_Document_Status__c,PC_Page_Count__c
                               FROM PC_Document__c Where PC_Parent_Document__c =: parentDoc.Id];


                System.debug('@@After update parent status:' +parentDoc.PC_Document_Status__c);
                System.debug('@@After update child status: ' +lstchildDoc[0].PC_Document_Status__c);
                System.assertEquals(PC_Constants.DOCUMENT_STATUS_SPLIT_FAILURE, parentDoc.PC_Document_Status__c);
                System.assertEquals(PC_Constants.DOCUMENT_STATUS_SPLIT_FAILURE, lstChildDoc[0].PC_Document_Status__c);
                System.assertEquals(PC_Constants.DOCUMENT_STATUS_SPLIT_FAILURE, lstChildDoc[1].PC_Document_Status__c);


                //update one child document status to 'Ready for Split' when it has just been created
                lstChildDoc[0].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_SPLIT_FAILURE;
                lstChildDoc[1].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT;
                PC_Database.upd(lstchildDoc);
                //Query updated status after trigger executed
                parentDoc = [select id, PC_Document_Status__c FROM PC_Document__c WHERE id =: pDoc.Id];
                lstchildDoc = [select id, PC_Parent_Document__c,PC_Document_Status__c,PC_Page_Count__c
                               FROM PC_Document__c Where PC_Parent_Document__c =: parentDoc.Id];

                System.assertEquals(PC_Constants.DOCUMENT_STATUS_SPLIT_FAILURE, parentDoc.PC_Document_Status__c);
                System.assertEquals(PC_Constants.DOCUMENT_STATUS_SPLIT_FAILURE, lstChildDoc[0].PC_Document_Status__c);
                System.assertEquals(PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT, lstChildDoc[1].PC_Document_Status__c);

                //update both child document status to 'Ready for Split'
                lstChildDoc[0].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT;
                lstChildDoc[1].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT;
                PC_Database.upd(lstchildDoc);
                //Query updated status after trigger executed
                parentDoc = [select id, PC_Document_Status__c FROM PC_Document__c WHERE id =: pDoc.Id];
                lstchildDoc = [select id, PC_Parent_Document__c,PC_Document_Status__c,PC_Page_Count__c
                               FROM PC_Document__c Where PC_Parent_Document__c =: parentDoc.Id];

                System.assertEquals(PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT, parentDoc.PC_Document_Status__c);
                System.assertEquals(PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT, lstChildDoc[0].PC_Document_Status__c);
                System.assertEquals(PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT, lstChildDoc[1].PC_Document_Status__c);

                //update both child document status to 'Awaiting Split' when split request has been sent
                lstChildDoc[0].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_AWAITING_ATTACHMENT;
                lstChildDoc[1].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_AWAITING_ATTACHMENT;
                PC_Database.upd(lstchildDoc);
                //Query updated status after trigger executed
                parentDoc = [select id, PC_Document_Status__c FROM PC_Document__c WHERE id =: pDoc.Id];
                lstchildDoc = [select id, PC_Parent_Document__c,PC_Document_Status__c,PC_Page_Count__c
                               FROM PC_Document__c Where PC_Parent_Document__c =: parentDoc.Id];

                System.assertEquals(PC_Constants.DOCUMENT_STATUS_SPLIT_IN_PROGRESS, parentDoc.PC_Document_Status__c);
                System.assertEquals(PC_Constants.DOCUMENT_STATUS_AWAITING_ATTACHMENT, lstChildDoc[0].PC_Document_Status__c);
                System.assertEquals(PC_Constants.DOCUMENT_STATUS_AWAITING_ATTACHMENT, lstChildDoc[1].PC_Document_Status__c );

                //update one child document status to 'Awaiting Split' and another to 'Split Failure'
                lstChildDoc[0].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_AWAITING_ATTACHMENT;
                lstChildDoc[1].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_SPLIT_FAILURE;
                PC_Database.upd(lstchildDoc);
                //Query updated status after trigger executed
                parentDoc = [select id, PC_Document_Status__c FROM PC_Document__c WHERE id =: pDoc.Id];
                lstchildDoc = [select id, PC_Parent_Document__c,PC_Document_Status__c,PC_Page_Count__c
                               FROM PC_Document__c Where PC_Parent_Document__c =: parentDoc.Id];

                System.assertEquals(PC_Constants.DOCUMENT_STATUS_SPLIT_FAILURE, parentDoc.PC_Document_Status__c);
                System.assertEquals(PC_Constants.DOCUMENT_STATUS_AWAITING_ATTACHMENT, lstChildDoc[0].PC_Document_Status__c);
                System.assertEquals(PC_Constants.DOCUMENT_STATUS_SPLIT_FAILURE, lstChildDoc[1].PC_Document_Status__c);

                //update one child document status to 'Awaiting Split' and another to 'Ready for Split'
                lstChildDoc[0].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_AWAITING_ATTACHMENT;
                lstChildDoc[1].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT;
                PC_Database.upd(lstchildDoc);
                //Query updated status after trigger executed
                parentDoc = [select id, PC_Document_Status__c FROM PC_Document__c WHERE id =: pDoc.Id];
                lstchildDoc = [select id, PC_Parent_Document__c,PC_Document_Status__c,PC_Page_Count__c
                               FROM PC_Document__c Where PC_Parent_Document__c =: parentDoc.Id];

                System.assertEquals(PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT, parentDoc.PC_Document_Status__c);
                System.assertEquals(PC_Constants.DOCUMENT_STATUS_AWAITING_ATTACHMENT, lstChildDoc[0].PC_Document_Status__c);
                System.assertEquals(PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT, lstChildDoc[1].PC_Document_Status__c);

                //update one child document status to 'Awaiting Split' and another to 'Review Needed' if attachment comes back for one
                lstChildDoc[0].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_AWAITING_ATTACHMENT;
                lstChildDoc[1].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED;
                PC_Database.upd(lstchildDoc);
                //Query updated status after trigger executed
                parentDoc = [select id, PC_Document_Status__c FROM PC_Document__c WHERE id =: pDoc.Id];
                lstchildDoc = [select id, PC_Parent_Document__c,PC_Document_Status__c,PC_Page_Count__c
                               FROM PC_Document__c Where PC_Parent_Document__c =: parentDoc.Id];

                System.assertEquals(PC_Constants.DOCUMENT_STATUS_SPLIT_IN_PROGRESS, parentDoc.PC_Document_Status__c);
                System.assertEquals(PC_Constants.DOCUMENT_STATUS_AWAITING_ATTACHMENT, lstChildDoc[0].PC_Document_Status__c);
                System.assertEquals(PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, lstChildDoc[1].PC_Document_Status__c);

                //update both child documents to 'Review Needed' when attachment comes back for both
                lstChildDoc[0].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED;
                lstChildDoc[1].PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED;
                PC_Database.upd(lstchildDoc);
                //Query updated status after trigger executed
                parentDoc = [select id, PC_Document_Status__c FROM PC_Document__c WHERE id =: pDoc.Id];
                lstchildDoc = [select id, PC_Parent_Document__c,PC_Document_Status__c,PC_Page_Count__c
                               FROM PC_Document__c Where PC_Parent_Document__c =: parentDoc.Id];

                System.assertEquals(PC_Constants.DOCUMENT_STATUS_ARCHIVED, parentDoc.PC_Document_Status__c);
                System.assertEquals(PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, lstChildDoc[0].PC_Document_Status__c);
                System.assertEquals(PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, lstChildDoc[1].PC_Document_Status__c);

                PC_Database.del(lstChildDoc, false);

                // check if the parent status got updated to review needed
                parentDoc = [select id, PC_Document_Status__c FROM PC_Document__c WHERE id =: pDoc.Id];
                System.assertEquals(PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED, parentDoc.PC_Document_Status__c);

            }
            Test.StopTest();
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }

    /*********************************************************************************
Method Name    : testBeforeInsertUpdate
Author         : Vivek Kumar Mishra
Description    : This method is used for testing updateEngagementProgramCode() on PC_Trigger_Document
Return Type    : void
Parameter      :
*********************************************************************************/
    @isTest
    static void testBeforeInsertUpdate(){
        if(isTriggerActive){
            adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser, false);
            Test.startTest();
            system.runAs(adminUser){
                //Creating a parent document
                PC_Document__c pDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED);
                /*List<PC_Engagement_Program__c> engProgramIds = [SELECT Id FROM PC_Engagement_Program__c];
                pDoc.PC_Engagement_Program__c = engProgramIds.get(0).Id;
                pDoc.PC_EngagementProgramCode__c = null;*/
                PC_Database.ins(pDoc, false);
                List<String> myPicklist = new List<String>();
                Schema.DescribeFieldResult field = PC_Document__c.PC_EngagementProgramCode__c.getDescribe();
                for (Schema.PicklistEntry f : field.getPicklistValues()){
                    myPicklist.add(f.getLabel());

                }
                //check document was created
                System.assertNotEquals(pDoc.Id, null);

                PC_Document__c newDoc = [select id, PC_Engagement_Program__c, PC_EngagementProgramCode__c
                FROM PC_Document__c WHERE id =: pDoc.Id];
                PC_Engagement_Program__c engProgram = [SELECT Id, PC_Program_Code__c
                FROM PC_Engagement_Program__c WHERE Id =: newDoc.PC_Engagement_Program__c];

                //check if engagement program code is updated properly for the document
                //System.assertEquals(newDoc.PC_EngagementProgramCode__c, engProgram.PC_Program_Code__c);
                if(myPicklist.contains('None')){
                    System.assertEquals(newDoc.PC_EngagementProgramCode__c, 'None');
                } else{
                    System.assertEquals(newDoc.PC_EngagementProgramCode__c, null);
                }
                //create new engagement program
                Account manufacturerAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
                PC_Database.ins(manufacturerAcc, false);
                PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram ('programA75', manufacturerAcc.Id);
                PC_Database.ins(engagementProgram, false);
                newDoc.PC_Engagement_Program__c = engagementProgram.Id;
                //newDoc.PC_Engagement_Program__c = engProgramIds.get(1).Id;

                //update the document record
                PC_Database.upd(newDoc);

                //check if engagement program code is updated properly for the document
                //System.assertEquals(newDoc.PC_EngagementProgramCode__c, engProgram.PC_Program_Code__c);
                if(myPicklist.contains(PC_Constants.PC_NONE)){
                    System.assertEquals(newDoc.PC_EngagementProgramCode__c, PC_Constants.PC_NONE);
                } else{
                    System.assertEquals(newDoc.PC_EngagementProgramCode__c, null);
                }
                //set document's engagement program to null
                newDoc.PC_Engagement_Program__c = null;
                PC_Database.upd(newDoc);

                //check if document's engagement program code has also been updated to 'None'
                PC_Document__c updDoc = [SELECT id, PC_Engagement_Program__c, PC_EngagementProgramCode__c
                FROM PC_Document__c WHERE id =: newDoc.Id];
                System.assert(updDoc.PC_EngagementProgramCode__c==PC_Constants.PC_NONE);
            }
            Test.stopTest();
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }
}//END OF TEST CLASS