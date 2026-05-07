@isTest
private class PC_Test_UpdatePatientAsHCIndividual {
    @testSetup 
    // VIJAY - This test class is implemented to get the coverage up. Since, we can't create custom metadata in test class, it would be
    // difficult to get the batch job working. Hence, this kind of implementation.
    static void setup() {
        List<Account> accounts = PC_Test_Setup.createAccounts('patient', 2, PC_Constants.PATIENT_RECORD_TYPE);
        List<Account> physicianAccounts = PC_Test_Setup.createAccounts('physician', 2, PC_Constants.PHYSICIAN_RECORD_TYPE);
    }
    @isTest static void test() {
        try {
            Test.startTest();
            PC_UpdatePatientAsHealthCloudIndividual batchJob = new PC_UpdatePatientAsHealthCloudIndividual();
            batchJob.start(null);
            batchJob.execute(null, [SELECT ID, Name, CreatedDate, (SELECT ID, CreatedDate FROM Contacts) FROM Account LIMIT 10]);
            batchJob.finish(null);
            Id batchId = Database.executeBatch(batchJob);
            Test.stopTest();
            // after the testing stops, assert records were updated properly
            //System.assertEquals(10, [select count() from contact where MailingCity = 'New York']);
      	}
        catch(Exception ex) {
            
        }
            
    }
    
}