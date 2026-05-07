/**
 * Created by vkashikar on 6/28/2021.
 */

@IsTest
private class PC_Test_PurgeBatch {
    @testSetup
    static void setup() {
        User adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);

        List<Account> accounts = PC_Test_Setup.createAccounts('patient', 20, PC_Constants.PATIENT_RECORD_TYPE);
        PC_Database.ins(accounts);
    }


    @isTest static void testBehaviorEmptyRecycleBin() {
        try {
            Test.startTest();
            PC_PurgeBatch.Parameters parameters = new PC_PurgeBatch.Parameters();
            parameters.emptyRecycleBin = true;
            parameters.scopeQuery = 'SELECT ID FROM Account LIMIT 200';
            parameters.scopeCountQuery = 'SELECT COUNT() FROM Account LIMIT 200';
            parameters.sendSummaryEmailToAllAdmins = false;
            parameters.logFileName = 'PC_Purge';
            PC_PurgeBatch batch = new PC_PurgeBatch(parameters);
            Id batchId = Database.executeBatch(batch);
        }
        catch(Exception ex) {

        }
        finally {
            Test.stopTest();
        }
    }
    @isTest static void testBehaviorDoNotEmptyRecycleBin() {
        try {
            Test.startTest();
            PC_PurgeBatch.Parameters parameters = new PC_PurgeBatch.Parameters();
            parameters.emptyRecycleBin = false;
            parameters.scopeQuery = 'SELECT ID FROM Account LIMIT 200';
            parameters.scopeCountQuery = 'SELECT COUNT() FROM Account LIMIT 200';
            parameters.sendSummaryEmailToAllAdmins = true;
            PC_PurgeBatch batch = new PC_PurgeBatch(parameters);
            Id batchId = Database.executeBatch(batch);
        }
        catch(Exception ex) {

        }
        finally {
            Test.stopTest();
        }
    }
    @isTest static void testBehaviorInvalidQuery() {
        try {
            Test.startTest();
            PC_PurgeBatch.Parameters parameters = new PC_PurgeBatch.Parameters();
            parameters.emptyRecycleBin = true;
            parameters.scopeQuery = 'SELECT INVALID_FIELD FROM Account LIMIT 200';
            parameters.scopeCountQuery = 'SELECT COUNT() FROM Account LIMIT 200';
            parameters.sendSummaryEmailToAllAdmins = true;
            PC_PurgeBatch batch = new PC_PurgeBatch(parameters);
            Id batchId = Database.executeBatch(batch);

        }
        catch(Exception ex) {
            system.assert(false, 'Exception is not expected in spite of invalid query as it gets handled in the main class.');
        }
        finally {
            Test.stopTest();
        }
    }
    @isTest static void testBehaviorWithRecordLocking() {
        // todo This method is not working as expected. Needs to be revisted. We need to find a better way to lock the records.
        try {
            Test.startTest();
            PC_PurgeBatch.Parameters parameters = new PC_PurgeBatch.Parameters();
            parameters.emptyRecycleBin = true;
            List<Account> lockedAccounts = [SELECT ID FROM Account LIMIT 200 FOR UPDATE ];
            parameters.scopeQuery = 'SELECT ID FROM Account LIMIT 200';
            parameters.scopeCountQuery = 'SELECT COUNT() FROM Account LIMIT 200';
            parameters.sendSummaryEmailToAllAdmins = true;
            PC_PurgeBatch batch = new PC_PurgeBatch(parameters);
            Id batchId = Database.executeBatch(batch);

        }
        catch(Exception ex) {
            system.assert(false, 'Exception is not expected in spite of record locking as it gets handled in the main class.');
        }
        finally {
            Test.stopTest();
        }
    }

}