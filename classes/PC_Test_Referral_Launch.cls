/*
* Class Name      : PC_Test_Referral_Launch
* Created By      : Prachi Nandgaonkar
* @Created Date   : Aug 25, 2017
* Modification Log:
* ----------------------------------------------------------------------------------
* Developer              Date                   	Description
* -----------------------------------------------------------------------------------
* Prachi Nandgaonkar	 25-Aug-2017			    [PC-1705] Initial Version
* Hitha Avalakki         Feb 26, 2021               [PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
*/

@isTest
public class PC_Test_Referral_Launch {
    private static User adminUser;
    private static final Integer OBJECTS_NUMBER = 3;
    
    @isTest static void testMethodReferral() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        //Create multiple patient accounts
        List<Account> patientAccounts = PC_Test_Setup.createAccounts('Patient', OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
        PC_Database.ins(adminUser);
        
        System.runAs(adminUser) {
            Test.StartTest();
            
            //Check if field labels were assigned correctly
            PC_Referral_Launch.FieldLabels fieldlabels =  PC_Referral_Launch.getFieldLabels();
            System.assertEquals(fieldlabels.refID, System.Label.PC_Referral_Number);
            
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
            
            //Check referral default status = Started is considered active
            boolean activeRef = PC_Referral_Launch.isReferralActive(programCases[0].Id);
            system.assertEquals(true, activeRef);
            
            //Check referral status = Discontinued is considered inactive
            referrals[0].PC_Referral_Status__c = PC_Constants.REFERRAL_STATUS_DISCONTINUED;
            PC_Database.upd(referrals[0], false);
            activeRef = PC_Referral_Launch.isReferralActive(programCases[0].Id);
            system.assertEquals(activeRef, false);
            
            LIST<PC_Referral_Launch.refWrapper> refinfo =  PC_Referral_Launch.getRefRecords(programCases[0].Id);
            system.assertEquals(1, refinfo.size());
            Test.StopTest();
        }
    }
    
        
}