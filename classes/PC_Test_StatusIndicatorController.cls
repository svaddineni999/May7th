/**
* Class Name      : PC_Test_StatusIndicatorController
* Created By      : Shishir Bansal
* @Created Date   : Aug 13, 2018
* Modification Log:
* ----------------------------------------------------------------------------------
* Developer              Date                     Description
* -----------------------------------------------------------------------------------
* Hitha Avalakki         27 Nov,2019              [PC-5757] Added a LIMIT to query in testBehaviour() method
*/

@IsTest
private class PC_Test_StatusIndicatorController {

    static final Integer count = 2;

    @testSetup static void setup() {
        // Create common test  data

        Account manufacturerAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
        PC_Database.ins(manufacturerAcc);
        String programName = 'PRP';
        PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram (programName, manufacturerAcc.Id);
        PC_Database.ins(engagementProgram);
        String caseRecordType = PC_Constants.CASE_PROGRAM_RECORD_TYPE;
        List<Case> caseList = PC_Test_Setup.createEnrlCase(manufacturerAcc.id, count, caseRecordType, String.valueOf(engagementProgram.Id));
        caseList[0].Status = 'Enrolled';
        PC_Database.ins(caseList);


    }

    @isTest static void testBehavior() {
        User adminUser;
        // running as system admin
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');

        String jsonAttribute = '{"statuses": [{"name": "Action Required","icon": "action:approval"},{"name": "","icon": "action:add_photo_video"}],'+'"statusFieldAPIName": "'+PC_Constants.getQualifiedAPIName('PC_Status_Indicator_4__c')+'","isDebugMode": false}';

        String errorJsonAttribute = '{"statuses": [{"name": "Action Required","icon": "action:approval"},{"name": "","icon": "action:add_photo_video"}],'+'"statusFieldAPIName": '+PC_Constants.getQualifiedAPIName('PC_Status_Indicator_4__c')+',"isDebugMode": false}';




        //'{"statuses": [{"name": "Action Required","icon": "action:approval"},{"name": "","icon": "action:add_photo_video"}],"statusFieldAPIName": "PC_Status_Indicator_4__c","isDebugMode": false}';
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            List<Case> caseList = [Select Id from Case LIMIT 2];
            System.assertEquals( (caseList.size() == count) , true);
            PC_StatusIndicatorController.InitData obj = new PC_StatusIndicatorController.InitData();
            PC_StatusIndicatorController.status statusObj = new PC_StatusIndicatorController.status();
            obj =  PC_StatusIndicatorController.InitData.getInitData(String.valueOf(caseList[0].Id),jsonAttribute );
            PC_StatusIndicatorController.InitData.getInitData(String.valueOf(caseList[0].Id),errorJsonAttribute );
            PC_StatusIndicatorController.checkIfFieldExists('Description');
            PC_StatusIndicatorController.checkIfFieldExists('');
            Test.stopTest();


        }

    }
}