/**************************************************************************************
Apex Class Name     : PC_Test_Document_InboundEmailController
Description         : This class is used for testing PC_Document_InboundEmailController;
CreatedBy           : Deloitte
Created Date        : 30 May 2016
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Alina Balan              26-May-2016               Initial version, PC-20-PC26
*************************************************************************************/
@isTest(seeAllData=False) 
private class PC_Test_Document_InboundEmailController {
    private static User objUser;
    private static PC_Document__c oDoc;
    private static Attachment oAttachment;
    
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Alina Balan
    Description    : This method is used for creating test data
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    private static void createTestData() {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test92.com', 'test92');
        PC_Database.ins(objUser, false);
        system.runAs(objUser) {
            oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_NEW);
            PC_Database.ins(oDoc, false);
            oAttachment = PC_Test_Setup.createAttachment(oDoc.Id);
            PC_Database.ins(oAttachment, false);
        }
    }
    
    /*********************************************************************************
    Method Name    : testSetupAttachment
    Author         : Alina Balan
    Description    : This method is used for testing "SetupAttachment"
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testSetupAttachment(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            system.assertNotEquals(oDoc.Id, null);
            system.assertNotEquals(oAttachment.Id, null);
            PC_Document_InboundEmailController controller = new PC_Document_InboundEmailController();
            controller.docId = oDoc.Id;
            controller.setupAttachment();
            system.assertNotEquals(controller.sAttachmentId, null);
            Test.StopTest();
         }
     }
 }