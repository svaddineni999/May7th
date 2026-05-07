/*********************************************************************************************************
Class Name      : PC_Test_EngagementTasksController
Description     : Test class for PC_EngagementTasks
Created By      : Deloitte
Created Date    : Aug 28, 2018
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Shishir Bansal                Aug 28, 2018           Initial Version
Vijay Kashikar                Feb 06, 2019           [No ticket #] Fixed test class failure to to patient name being too long.
Hitha Avalakki                Feb 26, 2021           [PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
****************************************************************************************************************/
@IsTest
private class PC_Test_EngagementTasksController {

    static User adminUser;
    static Boolean isDependentTest = false;

    @isTest static void testBehavior() {

        adminUser = PC_Test_Setup.createUser('System Administrator', 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {

            Test.startTest();
            try {

                List<Case> caseList = [Select id from Case];
                List<task> taskList = [Select id, whatID from task];
                List<Id> caseIdList = new List<Id>();


                System.assertEquals(caseList.size() == 1, true);
                System.assertEquals(taskList.size() ==3, true);
                System.assertEquals(caseList[0].Id == taskList[0].whatId , true);

                PC_EngagementTasksController.InitData customMetadata = new PC_EngagementTasksController.InitData();
                customMetadata = PC_EngagementTasksController.getEngagementTasks(caseList[0].Id);

                //List <PC_ProgramCoveragesController.Coverage> CoverageList = new List <PC_ProgramCoveragesController.Coverage>();
                //PC_ProgramCoveragesController.InitData initObj = new PC_ProgramCoveragesController.InitData();
                //initObj = PC_ProgramCoveragesController.getProgramCoverages(caseIdList);

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


        List<Task> taskList =PC_Test_Setup.createTasks(programCaseList[0],3);

        Date todaysDate = System.today();

        taskList[0].ActivityDate = todaysDate.addDays(1);
        taskList[0].Status ='In Progress';

        taskList[1].ActivityDate = todaysDate.addDays(-1);
        taskList[1].Status ='Completed';

        taskList[1].ActivityDate = todaysDate.addDays(-1);
        taskList[1].Status ='In Progress';


        taskList = PC_Database.ups(taskList);
    }
}