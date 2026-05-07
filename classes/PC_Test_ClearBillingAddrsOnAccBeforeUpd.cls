/**
 * Created by vkashikar on 7/13/2022.
 */
@isTest
public with sharing class PC_Test_ClearBillingAddrsOnAccBeforeUpd {
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
    @isTest public static void testClearingOfBillingAddress() {
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
}