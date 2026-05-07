/**
 * Created by vkashikar on 8/29/2022.
 */

@IsTest
private class PC_Test_ClearBillingAddrsOnAccAfterDel {
    @testSetup static void setup() {
        Account patient = PC_Test_Setup.createAccount('test', PC_SYSTEM.recordTypeId('Account', PC_Constants.PATIENT_RECORD_TYPE));
        patient = (Account) PC_Database.ins(patient);

        PC_Address__c nonPrimaryAddress = PC_Test_Setup.createAddress(patient.Id);
        nonPrimaryAddress.PC_Primary_Address__c = false;
        nonPrimaryAddress = (PC_Address__c) PC_Database.ins(nonPrimaryAddress);

        PC_Address__c primaryAddress = PC_Test_Setup.createAddress(patient.Id);
        nonPrimaryAddress.PC_Primary_Address__c = true;
        primaryAddress = (PC_Address__c) PC_Database.ins(primaryAddress);
    }
    static testMethod void testBehaviorWithoutDelete() {

        Test.StartTest();
        Account patient = [SELECT ID, PC_Primary_Address__c, BillingAddress FROM Account LIMIT 1];
        system.assert(patient.PC_Primary_Address__c != null);
        system.assert(patient.BillingAddress != null);

        PC_Address__c primaryAddress = [SELECT ID FROM PC_Address__c WHERE PC_Account__c =:patient.Id AND PC_Primary_Address__c = true];
        primaryAddress.PC_Primary_Address__c = false;
        PC_Database.upd(primaryAddress);

        Account patientAfterClearingAddress = [SELECT ID, PC_Primary_Address__c, BillingAddress FROM Account LIMIT 1];
        system.assert(patientAfterClearingAddress.BillingAddress == null);
        system.assert(String.isBlank(patientAfterClearingAddress.PC_Primary_Address__c));

        Test.stopTest();
    }
    static testMethod void testBehaviorAfterDelete() {

        Test.StartTest();
        Account patient = [SELECT ID, PC_Primary_Address__c, BillingAddress FROM Account LIMIT 1];
        system.assert(patient.PC_Primary_Address__c != null);
        system.assert(patient.BillingAddress != null);

        List<PC_Address__c> addresses = [SELECT ID FROM PC_Address__c WHERE PC_Account__c =:patient.Id];
        PC_Database.del(addresses, true);
        Account patientAfterDeleteOfAddresses = [SELECT ID, PC_Primary_Address__c, BillingAddress FROM Account LIMIT 1];
        system.assert(patientAfterDeleteOfAddresses.PC_Primary_Address__c == null);
        system.assert(patientAfterDeleteOfAddresses.BillingAddress == null);

        Test.stopTest();
    }
}