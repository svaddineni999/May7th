/*********************************************************************************************************
Trigger Name    : PC_Trigger_Address 
Description     : trigger on PC_Address__c object.
Created By      : Tetiana Danylyshyn
Created Date    : May 17, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   	Description
--------------------------------------------------------------------------------------------------------------            
Tetiana Danylyshyn             	May 17, 2016          	Initial Version
Alina Balan                    	July 11, 2016         	Added "updatePrimaryAddressOnAccount" method
Shabda Bhujad					Dec 05, 2016			Added FLS check to updatePrimaryAddressOnAccount,updatePrimaryAddress methods
Ajinkya Deshmukh				June 07, 2017			FLS Check Added
Mayuresh Patil                  July 26, 2017           Updated comments for FLS/CRUD checks
Mayuresh Patil                  Nov 1, 2017             Removed google map API to be replaced by salesforce geocoding
Shabda Bhujad                   Nov 14, 2017            PC-2485 Removing the reference to trigger state
Xiukai Ning                     Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                        Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                        We are removing all FLS and With Sharing keywords in the handlers.
Satheesh Kumar                  Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_Trigger_Address extends PC_TriggerHandler {

    override public void beforeInsertUpdate() {
        updatePrimaryAddressOnAccount(newList);
        processUpdate((List<PC_Address__c>) newList, (Map<Id, PC_Address__c>) oldMap);
    }

    override public void beforeInsert() {
        setAddressFields(newList);
    }

    override public void afterInsertUpdate() {
        updatePrimaryAddress(newList);
    }

    private void processUpdate(List<PC_Address__c> newList, Map<Id, PC_Address__c> oldMap) {
        List<PC_Address__c> addressesToUpdate = new List<PC_Address__c> ();
        for (PC_Address__c addressObj : newList) {
            if (addressObj.Id != null && (oldMap != null && oldMap.containsKey(addressObj.Id))) {
                PC_Address__c oldAddressObj = oldMap.get(addressObj.Id);
                if (addressObj.PC_Status__c == PC_Constants.INACTIVE && addressObj.PC_End_Date__c > Date.today()) {
                    addressObj.PC_End_Date__c = Date.today();

                }
                if (addressObj.PC_End_Date__c < Date.today() && oldAddressObj.PC_End_Date__c != addressObj.PC_End_Date__c) {
                    addressObj.PC_Status__c = PC_Constants.INACTIVE;
                }
            }
        }
    }

    private void setAddressFields(List<PC_Address__c> addresses) {
        for (PC_Address__c a : addresses) {
            //set status if none was set already
            if (a.PC_Status__c != PC_Constants.ACTIVE && a.PC_Status__c != PC_Constants.INACTIVE) {
                a.PC_Status__c = PC_Constants.ACTIVE;
            }
            //set start date
            if (a.PC_Start_Date__c == null) {
                a.PC_Start_Date__c = Date.today();
            }
        }
    }

    /*********************************************************************************
      Method Name    : updatePrimaryAddressOnAccount
      Author         : Tetiana Danylyshyn
      Description    : This method  updates the account record's primary address fields of the
      					incoming account address record is marked as primary for that account
      Return Type    : void
      Parameter      : List of incoming account address records - Trigger.new              
     *********************************************************************************/
    private void updatePrimaryAddressOnAccount(List<PC_Address__c> addresses) {
        Set<Id> addressIds = new Set<Id> ();
        Set<Id> setAccountsIdsChangePrimary = new Set<Id> ();
        Set<Id> setAccountsIdsNotPrimary = new Set<Id> ();
        for (PC_Address__c a : addresses) {
            if (a.PC_Primary_Address__c) {
                setAccountsIdsChangePrimary.add(a.PC_Account__c);
                addressIds.add(a.Id);
            } else {
                setAccountsIdsNotPrimary.add( a.PC_Account__c);
            }
        }
        List<PC_Address__c> primaryAddresses;
        try {
            //addresses for accounts that not have a primary address inserted
            List<PC_Address__c> lstPrimaryAddresses = [SELECT ID, PC_Account__c FROM PC_Address__c
                                                       WHERE PC_Account__c IN :setAccountsIdsNotPrimary
                                                       AND PC_Account__c NOT IN :setAccountsIdsChangePrimary
                                                       AND PC_Primary_Address__c = : true];
            Set<Id> setAccountsIdsWithPrimaryAddress = new Set<Id> ();
            for (PC_Address__c address : lstPrimaryAddresses) {
                setAccountsIdsWithPrimaryAddress.add(address.PC_Account__c);
            }
            //for every inserted address check if another primary address was inserted, or if an existing primary address already exists
            Set<Id> setPrimaryAccountsAddresses = new Set<Id> ();
            for (PC_Address__c address : addresses) {
                if (!setAccountsIdsChangePrimary.contains(address.PC_Account__c) && !setAccountsIdsWithPrimaryAddress.contains(address.PC_Account__c) && !setPrimaryAccountsAddresses.contains(address.PC_Account__c)) {
                    address.PC_Primary_Address__c = true;
                }
            }
			
            if (addressIds.size() > 0) {
				primaryAddresses = [SELECT ID, PC_Primary_Address__c
                                    FROM PC_Address__c
                                    WHERE ID NOT IN :addressIds AND PC_Account__c IN :setAccountsIdsChangePrimary AND PC_Primary_Address__c = :true];

                if (primaryAddresses.size() > 0) {
                    for (PC_Address__c a : primaryAddresses) {
                        a.PC_Primary_Address__c = false;
                    }
                    PC_Database.upd(primaryAddresses, false);
                } 
            }
        } catch(Exception e) {
            PC_Utility.createExceptionLog(e);
        }
    }

    /*********************************************************************************
      Method Name    : updatePrimaryAddress
      Author         : Alina BAlan
      Description    : This method will update the billing address on account if its marked
						as primary on address record.
      Return Type    : void
      Parameter      : List of incoming account address records - Trigger.new              
     *********************************************************************************/
    private void updatePrimaryAddress(List<PC_Address__c> lstAddresses) {
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();

        for (PC_Address__c address : lstAddresses) {
            if (address.PC_Primary_Address__c) {
                Account account = new Account();
                account.Id = address.PC_Account__c;
                account.BillingStreet = address.PC_Address_1__c;
                account.BillingCity = address.PC_City__c;
                account.BillingState = address.PC_State__c;
                account.BillingPostalCode = address.PC_Zip_Code__c;
                account.BillingCountry = address.PC_Country__c;
                account.PC_Primary_Address__c = address.Id;
                accountsToUpdate.put(account.Id, account); 
            }
        }
        
        try{
            PC_Database.ups(accountsToUpdate.values(), false);
        } catch(Exception e) {
            PC_Utility.createExceptionLog(e);
        }
    }
}