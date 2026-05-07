/**
 * Created by vkashikar on 8/17/2018.
 * Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Shishir Bansal        10-Dec-2019      [PC-5792] Avoid hardcoding of string variable
Hitha Avalakki        26-Feb-2021      [PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
*********************************************************************************/
@isTest
public class PC_Test_NewReferral {
    private static User adminUser;
    private static final Integer OBJECTS_NUMBER = 3;
    private static final String ACTIVE_PICKLISTRING='ACTIVE';

    @isTest static void testMethodReferral() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        //Create multiple patient accounts

        PC_Database.ins(adminUser);

        System.runAs(adminUser) {
            Test.StartTest();

            List<Account> patientAccounts = PC_Test_Setup.createAccounts('Patient', OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
            PC_Database.ins(patientAccounts);
            // Check if 3 patients are created for bulk testing
            System.assertEquals(3, patientAccounts.size());

            //Create multiple program cases
            //[PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
            List<Case> programCases = PC_Test_Setup.createProgramCases(patientAccounts, OBJECTS_NUMBER);
            PC_Database.ins(programCases);
            // Check if 3 cases are created for bulk testing
            system.assertEquals(3, programCases.size());

            //Create multiple pharmacy referrals
            List<PC_Pharmacy_Referral__c> referrals = PC_Test_Setup.createReferrals(programCases, OBJECTS_NUMBER);
            PC_Database.ins(referrals);
            // Check if 3 referrals are created for bulk testing
            system.assertEquals(3, referrals.size());
            //Check if referral 1 was created on program case 1
            system.assertEquals(programCases[0].Id, referrals[0].PC_Program__c);



            PC_Program_Coverage__c programCoverage = PC_Test_Setup.createProgramCoverage(programCases[0].Id);
            programCoverage.PC_Coverage_Status__c = ACTIVE_PICKLISTRING;
            PC_Database.ins(programCoverage);

            PC_NewReferral.InitData initData = PC_NewReferral.getData(programCases[0].id); // without pharmacy
            system.assert(initData.programCoverages.isEmpty());

            List<Account> pharmacies = PC_Test_Setup.createAccounts('pharmacy',1,PC_Constants.PHARMACY_RECORD_TYPE);
            PC_Database.ins(pharmacies);

            programCoverage.PC_Pharmacy__c = pharmacies[0].Id;
            PC_Database.upd(programCoverage);

            PC_NewReferral.InitData initData2 = PC_NewReferral.getData(programCases[0].id); // with pharmacy
            system.assert(!initData2.programCoverages.isEmpty());

            Case paCase = PC_Test_Setup.createCase(adminUser, patientAccounts[0]);
            paCase.RecordTypeId = PC_System.recordTypeId('Case',PC_Constants.CASE_PA_RECORD_TYPE);
            paCase.PC_Program__c = programCases[0].Id;
            PC_Database.ins(paCase);

            paCase.PC_Program_Coverage__c = programCoverage.Id;
            PC_Database.upd(paCase);

            PC_NewReferral.InitData initData3 = PC_NewReferral.getData(programCases[0].id); // with pharmacy
            system.assert(!initData3.programCoverages.isEmpty());

            try {
                PC_NewReferral.InitData initData4 = PC_NewReferral.getData(null); // with pharmacy
            }
            catch(Exception ex) {
                system.assert(true);
            }

            Test.StopTest();
        }
    }
}