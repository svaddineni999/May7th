/**************************************************************************************
Apex Class Name     : PC_Test_AdverseEventMenuLauncher
Description         : This class is used for testing PC_AdverseEventMenuLauncher;
CreatedBy           : Deloitte
Created Date        : 16 October 2019
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Kanteti Kishore        	16 October 2019           Initial version
Shishir Bansal         18-Dec-2019            Ability to launch AE creation action from a custom button
Haritha Reddy          20-Dec-2019            Removed Assert Statement for fieldsetName to be not null.
                                              As Default fieldset is removed from code, it can be null when there is no value given in Patient Connect Setting.
*************************************************************************************/
@isTest(seeAllData=False)
public with sharing class PC_Test_AdverseEventMenuLauncher {
    private static final String engagementProgramName = 'engPgm';

    private static User objUser;
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Kishore Kanteti
    Description    : This method is used for creating test data
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    private static void createTestData() {

        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test95.com', 'test95');
        PC_Database.ins(objUser, false);
        system.assertNotEquals(objUser.Id, Null);

    }
    /*********************************************************************************
   Method Name    : testGetAdverseEventConfigData
   Author         : Kishore Kanteti
   Description    : This method is used for testing "getAdverseEventConfigData"
   Return Type    : void
   Parameter      :
   *********************************************************************************/
    @isTest static void testGetAdverseEventConfigData() {
		createTestData();
        system.runAs(objUser) {
            PC_AdverseEventMenuLauncher.AdverseEventConfig adverseEventConfig = new PC_AdverseEventMenuLauncher.AdverseEventConfig();

            Account patientRecord = [Select Id from Account LIMIT 1];

            Case caseRecord = [Select Id from case LIMIT 1];




            if(patientRecord !=null) {
                adverseEventConfig = PC_AdverseEventMenuLauncher.getAdverseEventConfigData(patientRecord.Id);
                system.assertNotEquals('', adverseEventConfig.dateFormat);
            }

            if(caseRecord !=null){
                adverseEventConfig = PC_AdverseEventMenuLauncher.getAdverseEventConfigData(caseRecord.Id);
                system.assertNotEquals('', adverseEventConfig.dateFormat);
            }
        }
    }


    @testSetup static void setup() {

        Account  patient = PC_Test_Setup.createPatient('testpatient');
        patient = (Account)PC_Database.ins(patient, false);

        List<Account> manufacturers = PC_Test_Setup.createAccounts('testManufacturer', 1, 'Manufacturer');
        manufacturers = (List<Account>) PC_Database.ups(manufacturers);
        Account manufacturer = manufacturers[0];


        PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram(engagementProgramName, manufacturer.Id);
        engagementProgram.PC_Program_Code__c = engagementProgramName;
        engagementProgram = (PC_Engagement_Program__c) PC_Database.ups(engagementProgram);
        // check if engagement program is created
        system.assertNotEquals(engagementProgram.Id, Null);



        Case programCase = PC_Test_Setup.createProgram(patient);
        programCase.PC_Engagement_Program__c = engagementProgram.Id;
       // programCase.PC_Program_Product__c = programProduct.Id;
        //enrollmentCase.AccountId = patient.Id;
        programCase = (Case) PC_Database.ups(programCase);
    }
}