/**************************************************************************************
Apex Class Name     : PC_Test_HomeProgramStatusController
Description         : This class is used for testing PC_HomeProgramActivitiesController ;
CreatedBy           : Deloitte
Created Date        : 11 July 2016
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Cameron Reid              11-July-2016               Initial version
*************************************************************************************/
@isTest(seeAllData=False) 
private class PC_Test_HomeProgramActivitiesTodayContr {
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
        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test86.com', 'test86');
        PC_Database.ins(objUser);
        system.runAs(objUser) {
            oDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_NEW);
            PC_Database.ins(oDoc);
            oAttachment = PC_Test_Setup.createAttachment(oDoc.Id);
            PC_Database.ins(oAttachment);
            
            Task t1= new Task();
            t1.ActivityDate = date.today();
            t1.subject = 'Test Subject - today - In Progress';
            t1.status = 'In Progress';
            t1.ownerId = objUser.id;
            PC_Database.ins(t1);
            
            Task t2= new Task();
            t2.ActivityDate = date.today().addDays(1);
            t2.subject = 'Test Subject - tomorrow - Completed - Starred';
            t2.status = 'Completed';
            t2.ownerId = objUser.id;
            t2.PC_Starred__c = true;
            PC_Database.ins(t2);
            
            Task t3= new Task();
            t3.ActivityDate = date.today().addDays(-1);
            t3.subject = 'Test Subject - yesterday - In Progress - Starred';
            t3.status = 'In Progress';
            t3.ownerId = objUser.id;
            t3.PC_Starred__c = true;
            PC_Database.ins(t3);
            
            Task t4= new Task();
            t4.ActivityDate = date.today();
            t4.subject = 'Test Subject - Today - In Progress - Starred';
            t4.status = 'In Progress';
            t4.ownerId = objUser.id;
            t4.PC_Starred__c = true;
            PC_Database.ins(t4);
            
            Task t5= new Task();
            t5.ActivityDate = date.today();
            t5.subject = 'Test Subject - Today - Completed';
            t5.status = 'Completed';
            t5.ownerId = objUser.id;
            PC_Database.ins(t5);
            
            Task t6= new Task();
            t6.ActivityDate = date.today().addDays(-6);
            t6.subject = 'Test Subject - Overdue';
            t6.status = 'Completed';
            t6.ownerId = objUser.id;
            PC_Database.ins(t6);
            
            Task t7= new Task();
            t7.ActivityDate = date.today().addDays(-6);
            t7.subject = 'Test Subject - Overdue - In Progress - Starred';
            t7.status = 'In Progress';
            t7.ownerId = objUser.id;
            t7.PC_Starred__c = true;
            PC_Database.ins(t7);
            
            Task t8= new Task();
            t8.ActivityDate = date.today().addDays(1);
            t8.subject = 'Test Subject - tomorrow - In Progress - Starred';
            t8.status = 'In Progress';
            t8.ownerId = objUser.id;
            t8.PC_Starred__c = true;
            PC_Database.ins(t8);
        }
    }
    
    /*********************************************************************************
    Method Name    : testgetTodaysActivities
    Author         : Cameron Reid
    Description    : This method is used for testing "getTodaysActivities"
    Return Type    : void 
    *********************************************************************************/
    @isTest static void testGetTodaysActivities(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            PC_HomeProgramActivitiesTodayController.activityTotalWrapper results = PC_HomeProgramActivitiesTodayController.getTodaysActivities();
            
            System.assertNotEquals(null, results );
            System.assertEquals(1.0, results.completed);
            System.assertEquals(3.0, results.total);
            
            Decimal expectedPercentage = (Decimal)(1.0 / 3.0);
            Integer expectedPercentageInt = (Integer)(expectedPercentage*100);
            Integer resultPercentageInt = (Integer)(results.completedPercentage*100);
            System.assertEquals(expectedPercentageInt , resultPercentageInt );
            
            Test.StopTest();
         }
     }
     
     /*********************************************************************************
    Method Name    : testOtherActivities
    Author         : Cameron Reid
    Description    : This method is to test negative and other scenarios
    Return Type    : void 
    *********************************************************************************/
    @isTest static void testOtherActivities(){
        createTestData();
        system.runAs(objUser) {
            Test.StartTest();
            //PC_HomeProgramActivitiesTodayController sController = new PC_HomeProgramActivitiesTodayController(); //Not Used           
            
            PC_HomeProgramActivitiesTodayController.activityTotalWrapper actTotalWrapper = new PC_HomeProgramActivitiesTodayController.activityTotalWrapper(-1,-1);
            system.assert(actTotalWrapper.completed >= 0);
            system.assert(actTotalWrapper.Total >= 0);
            system.assert(actTotalWrapper.completedPercentage >= 0);
            
            Test.StopTest();
         }
     }
 }