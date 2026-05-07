/*********************************************************************************************************
Class Name      : PC_Test_Trigger_SetAdverseEvent2Version
Description     : Tests PC_Test_Trigger_SetAdverseEvent2Version.
Created By      : Shishir Bansal
Created Date    : 30-Sep-2019
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                     Description
--------------------------------------------------------------------------------------------------------------
Shishir Bansal       30-Sep-2019              Initial version
Hitha Avalakki       26-Feb-2021              [PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
****************************************************************************************************************/

@IsTest
private class PC_Test_Trigger_SetAdverseEvent2Version {
    public static final String ACCOUNT_NAME = 'Test Account';
    private static final Integer OBJECTS_NUMBER = 1;


    @isTest static void adverseEventVersioning(){
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);

        System.runAs(adminUser)
        {
            Test.StartTest();

            try {
                Account patientRecord = [Select Id from Account Limit 1];
                List <PC_AdverseEvent2__c> aeList = [Select id, PC_ParentAdverseEvent__c, PC_VersionNumber__c, PC_LatestAdverseEvent__c from PC_AdverseEvent2__c where PC_Patient__c = :patientRecord.Id];

                PC_Trigger_SetAdverseEvent2Version.isExecuting =false;
                updateParentAERecord(aeList);

                PC_Trigger_SetAdverseEvent2Version.isExecuting =false;
                // updating child
                updateChildAERecord(aeList);

                // inserting parent and child data

                afterInsertLogicTest(patientRecord.Id);
            }catch (Exception ex) {
                PC_Utility.createExceptionLog(ex);
            }
            Test.stopTest();
        }
    }

    public static void updateParentAERecord(List<PC_AdverseEvent2__c> aeList){

        PC_AdverseEvent2__c parentRecord = new PC_AdverseEvent2__c();
        parentRecord = aeList[0];
        PC_AdverseEvent2__c childRecord = new PC_AdverseEvent2__c();
        childRecord = aeList[1];
        parentRecord.PC_LatestAdverseEvent__c = childRecord.Id;
        PC_Database.upd(parentRecord);


        PC_AdverseEvent2__c aeTest = [Select PC_ParentAdverseEvent__c from PC_AdverseEvent2__c where id =:childRecord.Id LIMIT 1];

        //system.assert(aeTest.PC_ParentAdverseEvent__c != null);

    }

    public static void updateChildAERecord(List<PC_AdverseEvent2__c> aeList){
        PC_AdverseEvent2__c parentRecord = new PC_AdverseEvent2__c();
        parentRecord = aeList[2];
        PC_AdverseEvent2__c childRecord = new PC_AdverseEvent2__c();
        childRecord = aeList[3];
        childRecord.PC_ParentAdverseEvent__c = parentRecord.Id;
        PC_Database.upd(childRecord);

        PC_AdverseEvent2__c aeTest = [Select PC_LatestAdverseEvent__c from PC_AdverseEvent2__c where id =:parentRecord.Id LIMIT 1];

        //system.assert(aeTest.PC_LatestAdverseEvent__c != null);

    }

    public static void afterInsertLogicTest(Id patientId){

        PC_AdverseEvent2__c parentRecord = new PC_AdverseEvent2__c();
        parentRecord =PC_Test_Setup.newAdverseEvent2(patientId);
        parentRecord.PC_SubmissionStatus__c = PC_Constants.PC_AE_SUBMISSION_STATUS;

        PC_Database.ins(parentRecord);
        PC_Trigger_SetAdverseEventVersion.isExecuting =false;

        PC_AdverseEvent2__c childAERecord = new PC_AdverseEvent2__c();
        childAERecord =PC_Test_Setup.newAdverseEvent2(patientId);

        system.debug('parentRecord.Id;'+parentRecord.Id);
        childAERecord.PC_SubmissionStatus__c = PC_Constants.PC_AE_SUBMISSION_STATUS;

        childAERecord.PC_ParentAdverseEvent__c =parentRecord.Id;

        PC_Database.ins(childAERecord);



        PC_AdverseEvent2__c aeTest = [Select PC_LatestAdverseEvent__c from PC_AdverseEvent2__c where id =:parentRecord.Id LIMIT 1];

        //system.assert(aeTest.PC_LatestAdverseEvent__c != null);




        PC_Trigger_SetAdverseEventVersion.isExecuting =false;




        childAERecord = new PC_AdverseEvent2__c();
        childAERecord =PC_Test_Setup.newAdverseEvent2(patientId);


        childAERecord.PC_SubmissionStatus__c = PC_Constants.PC_AE_SUBMISSION_STATUS;
        PC_Database.ins(childAERecord);

        PC_Trigger_SetAdverseEventVersion.isExecuting =false;

        parentRecord = new PC_AdverseEvent2__c();
        parentRecord =PC_Test_Setup.newAdverseEvent2(patientId);
        parentRecord.PC_SubmissionStatus__c = PC_Constants.PC_AE_SUBMISSION_STATUS;

        parentRecord.PC_LatestAdverseEvent__c = childAERecord.Id;
        PC_Database.ins(parentRecord);



        PC_AdverseEvent2__c aeTest2 = [Select PC_ParentAdverseEvent__c from PC_AdverseEvent2__c where id=:childAERecord.Id LIMIT 1];

       // system.assert(aeTest2.PC_ParentAdverseEvent__c !=null);

    }



    @testSetup static void setup() {

        List<Account> patientAccounts = PC_Test_Setup.createSampleAccounts(ACCOUNT_NAME, OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
        PC_Database.ins(patientAccounts);
        //[PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
        List<Case> programCases = PC_Test_Setup.createProgramCases(patientAccounts, OBJECTS_NUMBER);
        PC_Database.ins(programCases);
        List<PC_AdverseEvent2__c> aeList = new List<PC_AdverseEvent2__c>();
        for(Integer i = 0; i <8 ; i++){
            PC_AdverseEvent2__c newAE = new PC_AdverseEvent2__c();
            newAE = PC_Test_Setup.newAdverseEvent2(patientAccounts[0].Id);
            newAE.PC_SubmissionStatus__c = PC_Constants.PC_AE_SUBMISSION_STATUS;
            newAE.PC_VersionNumber__c =1;
            newAE.PC_Care_Program__c = programCases[0].Id;
            aeList.add(newAE);
        }
        if(aeList.size()>0){
            PC_Database.ins(aeList);

        }
    }
}