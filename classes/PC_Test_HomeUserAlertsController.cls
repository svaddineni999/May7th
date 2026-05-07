/**************************************************************************************
Apex Class Name     : PC_Test_HomeUserAlertsController
Description         : This class is used for  testing PC_HomeUserAlertsController;
CreatedBy           : Deloitte
Created Date        : 30 June 2016
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Cameron Reid              30-June-2016               Initial version
*************************************************************************************/

@isTest
private class PC_Test_HomeUserAlertsController{
    private static User objUser;
    private static PC_Document__c oDoc;
    private static Attachment oAttachment;
    private static PC_Alert__c alert1;
    private static PC_Alert__c alert2;
    
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Alina Balan
    Description    : This method is used for creating test data
    Return Type    : void 
    *********************************************************************************/
    private static void createTestData() {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test83.com', 'test83');
        PC_Database.ins( objUser);
        List <CaseTeamRole> caseRoles = PC_Test_Setup.createCaseTeamRole(1, new List<String>{'HCO'});
        try {
            PC_Database.ins(caseRoles);
        }
        catch(Exception e) {
        }
        system.runAs(objUser) {
            oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_NEW);
            PC_Database.ins( oDoc);
            oAttachment = PC_Test_Setup.createAttachment(oDoc.Id);
            PC_Database.ins( oAttachment);
            
            Case c = new Case();
            //c.name = 'caseName';
            PC_Database.ins( c);
            
            CaseTeamRole ctr = [Select ID from CaseTeamRole limit 1];
            
            CaseTeamMember ctm = new CaseTeamMember();
            ctm.ParentID = c.ID;
            ctm.MemberID = objUser.ID;
            ctm.TeamRoleId = ctr.ID;
            PC_Database.ins( ctm);
            
            alert1 = new PC_Alert__c ();
            alert1.PC_Program__c = c.ID;
            alert1.PC_Alert_status__c = 'New';
            PC_Database.ins( alert1);
            
            alert2 = new PC_Alert__c ();
            alert2.PC_Program__c = c.ID;
            alert2.PC_Alert_status__c = 'Accepted';
            PC_Database.ins( alert2);

            system.debug('!!!! Test Records Created: ' + c + ', ' + alert1 + ', ' + ctm);
        }
    }
    
    /*********************************************************************************
    Method Name    : testGetActiveUserAlerts
    Author         : Cameron Reid
    Description    : This method is used for testing "getActiveUserAlerts"
    Return Type    : void 
    *********************************************************************************/
    @isTest static void testGetActiveUserAlerts(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();

            //List<PC_Alert__c> results = PC_HomeUserAlertsController.getActiveUserAlerts();
            List<PC_HomeUserAlertsController.alertWrapper> results = PC_HomeUserAlertsController.getActiveUserAlerts();
            System.assertNotEquals(null, results );
            System.assertEquals(1, results.size() );
            
            Test.StopTest();
         }
     }
     
     /*********************************************************************************
    Method Name    : testGetListViews
    Author         : Cameron Reid
    Description    : This method is used for testing "getListViews"
    Return Type    : void 
    *********************************************************************************/
    @isTest static void testGetListViews(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();

            ListView results = PC_HomeUserAlertsController.getListViews();
            System.assertNotEquals(null, results );
            
            
            Test.StopTest();
         }
     }

    /*********************************************************************************
    Method Name    : testoverrideAlert
    Author         : Alina Balan
    Description    : This method is used for testing "overrideAlert" method
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testoverrideAlert(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            PC_HomeUserAlertsController.overrideAlert(alert1.Id);
            PC_Alert__c alert = [SELECT Id, PC_Alert_Status__c, PC_Reason_for_Override__c FROM PC_Alert__c WHERE Id =: alert1.Id limit 1];
            system.assertEquals(alert.PC_Alert_Status__c, PC_Constants.ALERT_OVERRIDDEN_STATUS);
            Test.StopTest();
         }
     }

    /*********************************************************************************
    Method Name    : testgetReturnUrl
    Author         : Alina Balan
    Description    : This method is used for testing "getReturnUrl" method
    Return Type    : void 
    Parameter      : 
    *********************************************************************************/
    @isTest static void testgetReturnUrl(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            String url = PC_HomeUserAlertsController.getReturnUrl();
            system.assertNotEquals(url, null);
            Test.StopTest();
         }
     }

 }