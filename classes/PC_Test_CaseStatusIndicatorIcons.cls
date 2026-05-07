/**************************************************************************************
Apex Class Name     : PC_Test_CaseStatusIndicatorIcons
Description         : This class is used for testing PC_CaseStatusIndicatorIcons and PC_CaseStatusIndicatorIconController;
CreatedBy           : Deloitte
Created Date        : 27 June 2016
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Cameron Reid              27-June-2016               Initial version
*************************************************************************************/
//@isTest(seeAllData=False) 
@isTest 
private class PC_Test_CaseStatusIndicatorIcons {
    private static User objUser;
    private static User objUser2;
    private static PC_Document__c oDoc;
    private static Attachment oAttachment;
    private static Case oCase;
    private static Account oPatient;
    //private static final String DOC_CATEGORY = 'Enrollment Form';
   
    
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Alina Balan
    Description    : This method is used for creating test data
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    private static void createTestData(Boolean bWithAttachments) {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.CALL_CENTER_AGENT_PROFILE, 'user@test98.com', 'test98');
        PC_Database.ins(objUser, false);
        objUser2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test97.com', 'test97');
        PC_Database.ins(objUser2, false);
        oPatient = PC_Test_Setup.createPatient('test patient name');
        PC_Database.ins(oPatient, false);
        system.runAs(objUser2) { //objUser
            oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_NEW);
            PC_Database.ins(oDoc, false);
            if (bWithAttachments) {
                oAttachment = PC_Test_Setup.createAttachment(oDoc.Id);
                PC_Database.ins(oAttachment, false);
            }
            oCase = PC_Test_Setup.createCase(objUser2, oPatient);
            oCase.PC_Appeal_No__c = 'test';
            oCase.Subject = 'test';
            oCase.status = 'In Treatment';
            oCase.PC_Status_Indicator_1__c = 'Action Required';
            PC_Database.ins(oCase, false);
        }
    }
    
    
    
    
    /*********************************************************************************
    Method Name    : testgetStatusIndicatorIcons_controller
    Author         : Cameron Reid
    Description    : This method is used for testing getting the status indicators
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testgetStatusIndicatorIcons_controller() {
        createTestData(true);
        //system.runAs(objUser) {
             Test.StartTest();
             system.assertNotEquals(oCase, null);
             PC_CaseStatusIndicatorIconController cController = new PC_CaseStatusIndicatorIconController();                  
             system.assertNotEquals(cController , null);         
             
             List<PC_CaseStatusIndicatorIconController.iconWrapper> lstCaseIndicators = PC_CaseStatusIndicatorIconController.getStatusIndicatorIcons(oCase.Id);             
             system.assertNotEquals(lstCaseIndicators, null);        
             system.assert(lstCaseIndicators.size() >= 0);    
             
             lstCaseIndicators = PC_CaseStatusIndicatorIconController.getStatusIndicatorIcons(null);             
             system.assertEquals(lstCaseIndicators, null);        
             //system.assert(lstCaseIndicators.size() == 0);    
             
             Test.StopTest();
         //}
    }
    
    /*********************************************************************************
    Method Name    : testgetStatusIndicatorIcons_controller
    Author         : Cameron Reid
    Description    : This method is used for testing getting the status indicators
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testgetStatusIndicatorIcons_GetCasecontroller() {
        createTestData(true);
        //system.runAs(objUser2) {
             Test.StartTest();
             system.assertNotEquals(oCase, null);
             
             Case caseRecord = PC_CaseStatusIndicatorIconController.getCase(null);  
             System.assertEquals(caseRecord, null);
             
             caseRecord = PC_CaseStatusIndicatorIconController.getCase(oCase.Id);
             System.assertNotEquals(caseRecord, null);
             
             Test.StopTest();
         //}
    }
    
    /*********************************************************************************
    Method Name    : testgetStatusIndicatorIcons_controller
    Author         : Cameron Reid
    Description    : This method is used for testing getting the status indicators
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testgetStatusIndicatorIcons() {
        createTestData(true);
        Test.StartTest();
        system.assertNotEquals(oCase, null);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(oCase);
        PC_CaseStatusIndicatorIcons cntrlr = new PC_CaseStatusIndicatorIcons(sc);
        System.assertNotEquals(cntrlr.lstStatusIcons, null);
        System.assert(cntrlr.lstStatusIcons.size()> 0);
        Test.StopTest();
    }
    
 }