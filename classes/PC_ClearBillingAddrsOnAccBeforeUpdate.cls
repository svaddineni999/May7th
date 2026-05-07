/**
 * Created by vkashikar on 7/13/2022.
 */

public inherited sharing class PC_ClearBillingAddrsOnAccBeforeUpdate extends PC_TriggerHandler {

    override public void beforeUpdate() {
        clearBillingAddress((Map<Id, Account>)oldMap, (Map<Id, Account>)newMap);
    }
    private static void clearBillingAddress(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        try {
            Id oldAddressId;
            Id newAddressId;
            Account oldAccount;
            Account newAccount;
            for (Id oldAccountId : oldMap.keySet()) {
                oldAccount = oldMap.get(oldAccountId);
                newAccount = newMap.get(oldAccountId);
                oldAddressId = oldAccount.PC_Primary_Address__c;
                newAddressId = newAccount.PC_Primary_Address__c;
                if (String.isBlank(newAddressId) && String.isNotBlank(oldAddressId)) {
                    // Clear the Billing address.
                    newAccount.BillingStreet = '';
                    newAccount.BillingCity = '';
                    newAccount.BillingState = '';
                    newAccount.BillingPostalCode = '';
                    newAccount.BillingCountry = '';
                }
            }
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }
}