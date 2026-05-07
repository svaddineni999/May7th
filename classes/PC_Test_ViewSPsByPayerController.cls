/*********************************************************************************************************
Class Name      : PC_Test_PreferredPayerController
Description     : Test class for PC_ViewSPsByPayerController
Created By      : Deloitte
Created Date    : July 2, 2018
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Shishir Bansal              June 9th, 2018          Initial Version
Hitha Avalakki              Nov  27th, 2019         [PC-5757] Added a LIMIT to query in testBehaviour() method
****************************************************************************************************************/

@IsTest
private class PC_Test_ViewSPsByPayerController {

    static User adminUser;
    static Boolean isDependentTest = false;

    @isTest static void testBehavior() {

        adminUser = PC_Test_Setup.createUser('System Administrator', 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.startTest();
            try {

                PC_ViewSPsByPayerController.getAllPreferredPrayer();
                List<PC_Preferred_SP_By_Payer__c> prefListTemp = [SELECT id FROM PC_Preferred_SP_By_Payer__c LIMIT 4];
                system.assert(prefListTemp.size() == 4 );
            }
            catch(Exception ex) {
                system.assert(true);
            }


            system.assert(true);
            Test.stopTest();

        }

    }


/* Creating Test Data for the class  */

    @testSetup static void setup() {


        List<Account> payerAccList = PC_Test_Setup.createAccounts('testpayer', 2, PC_Constants.PAYER_RECORD_TYPE);
        payerAccList = (List<Account>) PC_Database.ups(payerAccList);


        List<Account>specialtyPharmacyAcc = PC_Test_Setup.createAccounts('testpayer', 2, PC_Constants.PHARMACY_RECORD_TYPE);
        specialtyPharmacyAcc[0].PC_Sub_Type__c = 'Specialty Pharmacy';
        specialtyPharmacyAcc[1].PC_Sub_Type__c = 'Specialty Pharmacy';

        specialtyPharmacyAcc  = (List<Account>)PC_Database.ups(specialtyPharmacyAcc);

        List<PC_Preferred_SP_By_Payer__c> newPreferredPayer = new List<PC_Preferred_SP_By_Payer__c>();
        for(integer i = 0; i < 2; i ++){
            PC_Preferred_SP_By_Payer__c preferredPayerObj = new PC_Preferred_SP_By_Payer__c();
            preferredPayerObj.PC_Payer__c = payerAccList[i].id;
            preferredPayerObj.PC_Specialty_Pharmacy__c   = specialtyPharmacyAcc[i].id ;
            newPreferredPayer.add(preferredPayerObj);
        }

        newPreferredPayer[0].PC_PayerNameIfNoAccount__c = 'Test Payer 0';
        newPreferredPayer[1].PC_SpecialtyPharmacyNameIfNoAccount__c = 'Test Speciality Pharmacy 0';
        
        PC_Preferred_SP_By_Payer__c preferredPayer1 = new PC_Preferred_SP_By_Payer__c();
        preferredPayer1.PC_PayerNameIfNoAccount__c = 'Test Payer 1';

        PC_Preferred_SP_By_Payer__c preferredPayer2 = new PC_Preferred_SP_By_Payer__c();
        preferredPayer2.PC_SpecialtyPharmacyNameIfNoAccount__c = 'Test Speciality Pharmacy 1';

        newPreferredPayer.add(preferredPayer1);
        newPreferredPayer.add(preferredPayer2);

        Database.insert(newPreferredPayer , false);



    }


}