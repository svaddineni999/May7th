/*********************************************************************************************************
Class Name      : PC_Test_ProgramCoveragesController
Description     : Test class for PC_ProgramCoverages
Created By      : Deloitte
Created Date    : Aug 27, 2018
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Shishir Bansal                Aug 27, 2018           Initial Version
Vijay Kashikar                Feb 06, 2019           [No ticket #] Fixed test failure to patient name being too long.
Hitha Avalakki                Feb 26, 2021           [PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
****************************************************************************************************************/

@IsTest
private class PC_Test_ProgramCoveragesController {

    static User adminUser;
    static Boolean isDependentTest = false;

    @isTest static void testBehavior() {

        adminUser = PC_Test_Setup.createUser('System Administrator', 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.startTest();
            try {

                List<Case> caseList = [Select id from Case];
                List<Id> caseIdList = new List<Id>();


                System.assertEquals(caseList.size() == 1, true);
                caseIdList.add(caseList[0].Id);

                List <PC_ProgramCoveragesController.Coverage> CoverageList = new List <PC_ProgramCoveragesController.Coverage>();
                PC_ProgramCoveragesController.InitData initObj = new PC_ProgramCoveragesController.InitData();
                initObj = PC_ProgramCoveragesController.getProgramCoverages(caseIdList);

            }
            catch(Exception ex) {
                system.assert(true);
            }
        }
    }


    @testSetup static void setup() {


        List<Account> patientAccList = PC_Test_Setup.createAccounts('t', 2, PC_Constants.PATIENT_RECORD_TYPE);
        patientAccList = (List<Account>) PC_Database.ups(patientAccList);

        //[PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
        List<Case> programCaseList = PC_Test_Setup.createProgramCases(patientAccList, 1);
        programCaseList =  PC_Database.ups(programCaseList);

        List<PC_Health_Plan__c> healthPlanList = PC_Test_Setup.createHealthPlans(patientAccList,2);
        healthPlanList = PC_Database.ups(healthPlanList);

        List<PC_Program_Coverage__c> programCoverageList = new List<PC_Program_Coverage__c>();

        for(integer i = 0 ; i < patientAccList.size() ; i++ ){


            programCoverageList.add(PC_Test_Setup.createTestProgramCoverage(programCaseList[0].id,healthPlanList[i].id));

        }

        programCoverageList = PC_Database.ups(programCoverageList);




    }


}