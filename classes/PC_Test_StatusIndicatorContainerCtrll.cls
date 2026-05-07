/**
* Class Name      : PC_Test_PC_StatusIndicatorContainerCtrllr
* Created By      : Shishir Bansal
* @Created Date   : Aug 13, 2018
* Modification Log:
* ----------------------------------------------------------------------------------
* Developer              Date                     Description
* -----------------------------------------------------------------------------------
* Hitha Avalakki         27 Nov,2019              [PC-5757] Added a LIMIT to query in testBehaviour() method
* Hitha Avalakki         Feb 26, 2021             [PC-7442]:1) Replaced PC_Test_Setup.createEnrlCase() with PC_Test_Setup.createProgramCases() method.
                                                            2) Replaced PC_System.recordTypeId('Case',PC_Constants.CASE_PROGRAM_RECORD_TYPE) with PC_System.getProgramCaseRecordTypeId()
* Hitha Avalakki          Mar 04,2021            [PC-7442] Replaced getProgramCaseRecordTypeId() with getDefaultProgramCaseRecordTypeId()
*/
@IsTest(SeeAllData=false)
private class PC_Test_StatusIndicatorContainerCtrll {

    static final Integer count = 2;

    @testSetup static void setup() {
        // Create common test  data



        Account manufacturerAcc1 = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
        PC_Database.ins(manufacturerAcc1);
        Account manufacturerAcc2 = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
        PC_Database.ins(manufacturerAcc2);
        List<Account> accountsList = new List<Account>();
        accountsList.add(manufacturerAcc1);
        accountsList.add(manufacturerAcc2);

        String programName = 'PRP';
        PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram (programName, manufacturerAcc1.Id);
        PC_Database.ins(engagementProgram);
        String caseRecordType = PC_Constants.CASE_PROGRAM_RECORD_TYPE;
        //[PC-7442]:1) Replaced PC_Test_Setup.createEnrlCase() with PC_Test_Setup.createProgramCases() method.
        List<Case> caseList = PC_Test_Setup.createProgramCases(accountsList, count);
        caseList[0].Status = 'Enrolled';
        caseList[0].PC_Engagement_Program__c = engagementProgram.Id;
        PC_Database.ins(caseList);


    }


    @isTest static void testBehavior() {
        User adminUser;
        // running as system admin
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            List<Case> caseList = [Select Id ,RecordTypeId  from Case LIMIT 2];
            // system assertion to test the created data
            System.assertEquals( (caseList.size() == count) , true);
            PC_StatusIndicatorContainerCtrllr.InitData obj = new PC_StatusIndicatorContainerCtrllr.InitData();
            obj =  PC_StatusIndicatorContainerCtrllr.InitData.getInitData(caseList[0].Id);
            //[PC-7442] Replaced PC_System.recordTypeId('Case',PC_Constants.CASE_PROGRAM_RECORD_TYPE) with PC_System.getProgramCaseRecordTypeId()
            Id caseRecordType = PC_SYSTEM.getDefaultProgramCaseRecordTypeId();
            System.assertEquals( (caseList[0].RecordTypeId == caseRecordType), true );


            Test.stopTest();


        }
    }
}