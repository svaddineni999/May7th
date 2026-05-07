/*********************************************************************************
Class Name      : PC_Test_PostInstall
Description     : Test Post Install Script to be run after every package installation
Created By      : Vijay Kashikar
Created Date    : 16 Jan 2019
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Vijay Kashikar              16-Jan-19                  Initial Version
Vijay Kashikar              08-Jul-19                  [] Updated test class to cover exception log method.
*********************************************************************************/
@isTest
public class PC_Test_PostInstall {
    @isTest
    static void testInstall() {
        PC_PostInstall postinstall = new PC_PostInstall();

        List<Account> patientAccounts = PC_Test_Setup.createAccounts('test', 10, PC_Constants.PATIENT_RECORD_TYPE);
        List<Account> physicianAccounts = PC_Test_Setup.createAccounts('test', 10, PC_Constants.PHYSICIAN_RECORD_TYPE);
        PC_Database.ins(patientAccounts);
        PC_Database.ins(physicianAccounts);

        Test.testInstall(postinstall, new Version(6, 5), true);
        //system.assert(Limits.getEmailInvocations() > 0);
        Test.testInstall(postinstall, new Version(6, 5), false);
        //system.assert(Limits.getEmailInvocations() > 0);
        Test.testInstall(postinstall, null, false);


        // Below try/catch is for test coverage purposes only since we cannot mimic post install failure.
        try {
            Integer i = 1/(1-1);
        }
        catch(Exception ex) {
            PC_PostInstall.logException(ex);
        }
    }

}