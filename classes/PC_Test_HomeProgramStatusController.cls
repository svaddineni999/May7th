/**************************************************************************************
Apex Class Name     : PC_Test_HomeProgramStatusController 
Description         : This class is used for testing PC_Document_InboundEmailController;
CreatedBy           : Deloitte
Created Date        : 30 June 2016
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Cameron Reid              30-June-2016               Initial version
*************************************************************************************/
@isTest(seeAllData=False) 
private class PC_Test_HomeProgramStatusController {
    private static User objUser;
    private static PC_Document__c oDoc;
    private static Attachment oAttachment;
    
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Alina Balan
    Description    : This method is used for creating test data
    Return Type    : void 
    *********************************************************************************/
    private static void createTestData() {
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test85.com', 'test85');
        PC_Database.ins(objUser);
        system.runAs(objUser) {
            oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_NEW);
            PC_Database.ins(oDoc);
            oAttachment = PC_Test_Setup.createAttachment(oDoc.Id);
            PC_Database.ins(oAttachment);
            
            LIST<CASE> caseList = new LIST<CASE>();
            Case t1= new Case();
            //t1.ActivityDate = date.today();
            t1.PC_Status_Indicator_4__c = 'Complete';
            t1.PC_Status_Indicator_2__c = 'In Progress';
            t1.status = 'New';
            t1.ownerId = objUser.id;
            caseList.add(t1);
            
            Case t2= new Case();
            //t2.ActivityDate = date.today().addDays(1);
            t2.PC_Status_Indicator_4__c = 'Complete';
            t2.PC_Status_Indicator_2__c = 'In Progress';
            t2.status = 'New';
            t2.ownerId = objUser.id;
            caseList.add(t2);
            
            Case t3= new Case();
            //t3.ActivityDate = date.today().addDays(-1);
            t3.PC_Status_Indicator_4__c = 'Complete';
            t3.PC_Status_Indicator_2__c = 'In Progress';
            t3.status = 'New';
            t3.ownerId = objUser.id;
            caseList.add(t3);
            
            Case t4= new Case();
            //t4.ActivityDate = date.today();
            t4.PC_Status_Indicator_4__c = 'Complete';
            t4.PC_Status_Indicator_2__c = 'In Progress';
            t4.status = 'New';
            t4.ownerId = objUser.id;
            caseList.add(t4);
            
            Case t5= new Case();
            //t5.ActivityDate = date.today();
            t5.PC_Status_Indicator_4__c = 'Complete';
            t5.PC_Status_Indicator_2__c = 'In Progress';
            t5.status = 'New';
            t5.ownerId = objUser.id;
            caseList.add(t5);

            PC_Database.ins(caseList);
        }
    }
    
    /*********************************************************************************
    Method Name    : TestgetProgramCaseStatus
    Author         : Tejas Patel
    Description    : This method is used for testing "getProgramCaseStatus"
    Return Type    : void 
    *********************************************************************************/
    @isTest static void testgetProgramCaseStatus(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest(); 
            List<PC_HomeProgramStatusController.programStatusResults> results = new List<PC_HomeProgramStatusController.programStatusResults>(); 
           // PC_HomeProgramStatusController.programStatusResults results = PC_HomeProgramStatusController.getProgramCaseStatus();
            
            results = PC_HomeProgramStatusController.getProgramCaseStatus();
            System.assertNotEquals(null, results );
            System.assertEquals(0.0, results[0].total );
            System.assertEquals(0.0, results[0].completed);
            System.assertEquals(0.0, results[0].completedPercentage);
            /*
            Decimal dTotal = 5.0;
            Decimal dCompleted = 3.0;
            Integer percentage = (Integer)((dCompleted/dTotal) * 100);
            
            Integer tmpResults = (Integer)(results[0].completedPercentage * 100);
            System.assertEquals(percentage , tmpResults );*/
            
            Test.StopTest();
        }
    }
 }