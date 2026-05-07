/*********************************************************************************************************
Class Name      : PC_Test_SetPrimaryContactOnPCIndividual
Description     : Test class for PC_SetPrimaryContactOnPCIndividual
Created By      : Deloitte
Created Date    : Nov 2, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy               Nov 2, 2021           [PC-8244] Initial Version
****************************************************************************************************************/
@isTest
private class PC_Test_SetPrimaryContactOnPCIndividual {
    @testSetup static void setup() {
        List<Account> physicianAccounts = PC_Test_Setup.createAccounts('physician', 200, PC_Constants.PHYSICIAN_RECORD_TYPE);
        physicianAccounts = (List<Account>) PC_Database.ups(physicianAccounts);
    }
    @isTest static void test() {
        try {
            Test.startTest();
            PC_SetPrimaryContactOnPCIndividual batchJob = new PC_SetPrimaryContactOnPCIndividual();
            Id batchId = Database.executeBatch(batchJob);
            Test.stopTest();
            System.AssertEquals(database.countquery('SELECT COUNT() FROM Account WHERE HealthCloudGA__PrimaryContact__c != null'), 200);
        }
        catch(Exception ex) {

        }
    }
}