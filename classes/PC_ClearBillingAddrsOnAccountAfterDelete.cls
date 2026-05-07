/**
 * Created by vkashikar on 8/29/2022.
 */

public with sharing class PC_ClearBillingAddrsOnAccountAfterDelete extends PC_TriggerHandler {
    override public void afterDelete() {
        updatePrimaryAddressOnAccountAfterDelete(oldList);
    }
    private void updatePrimaryAddressOnAccountAfterDelete(List<PC_Address__c> addresses) {
        Set<Id> accountIds = new Set<Id> ();
        List<Account> accountsToBeUpdated = new List<Account>();
        try {
            for (PC_Address__c address : addresses) {
                accountIds.add(address.PC_Account__c);
            }
            for (Account account : [SELECT Id, (SELECT Id FROM Addresses__r) FROM Account WHERE Id IN :accountIds]) {
                if (account.Addresses__r == null || account.Addresses__r.size() == 0) {
                    account.BillingStreet = '';
                    account.BillingCity = '';
                    account.BillingState = '';
                    account.BillingPostalCode = '';
                    account.BillingCountry = '';
                    accountsToBeUpdated.add(account);
                }
            }
            if (accountsToBeUpdated.size() > 0) {
                PC_Database.upd(accountsToBeUpdated, false);
            }
        }catch(Exception e) {
            PC_Utility.createExceptionLog(e);
        }


    }
}