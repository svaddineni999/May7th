/*********************************************************************************************************
Trigger Name    : PC_UpdateAccBillingAddr_PrimaryAddr
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
Shabda Bhujad                   Dec 18, 2017            PC-1884 Logical breakdown of the trigger handlers
Xiukai Ning                     Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                        Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                        We are removing all FLS and With Sharing keywords in the handlers.
Kishore Kanteti                 June 28,2019            [PC-4926]Added Google Map Api for geocoding Line-57
Kishore Kanteti                 August 23,2019          [PC-5331] Added condition to check whether person account enabled/disabled line 56
Satheesh Kumar                  Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
Vijay Kashikar                  Jun 16, 2022            [PC-8918] Ensured that the Geolocation fields are updated only for Person Accounts
****************************************************************************************************************/

public inherited sharing class PC_UpdateAccBillingAddr_PriAddrHandler extends PC_TriggerHandler{
    override public void afterInsertUpdate() {
        updatePrimaryAddress(newList);
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
            if (accountsToUpdate != null && !accountsToUpdate.isEmpty()) {
                PC_Database.ups(accountsToUpdate.values(), false);
                updateGeoLocations(accountsToUpdate);
            }

        } catch(Exception e) {
            PC_Utility.createExceptionLog(e);
        }
    }

    private static void updateGeoLocations(Map<Id, Account> accounts) {
        if (PC_ProtectedApiSettings__c.getInstance(PC_Constants.PC_GEOCODE_API_NAME) != null && PC_System.isPersonAccountEnabled()) {
            Set<Id> accountIds = accounts.keySet();
            // Need to do dynamic query as the code needs to be lightly coupled with the Person Account related objs n fields
            // FLS not needed as triggers run in system context
            String query = 'SELECT ID, IsPersonAccount FROM Account WHERE ID IN :accountIds AND IsPersonAccount = true';
            List<Account> personAccounts = Database.query(query);

            Set<Id> personAccountIds = new Set<Id>();
            for (Account acc : personAccounts) {
                personAccountIds.add(acc.Id);
            }

            if (!test.isRunningTest()) {
                PC_GoogleMapServiceV2.updateGeoLocations(personAccountIds);
            }
        }
    }
}