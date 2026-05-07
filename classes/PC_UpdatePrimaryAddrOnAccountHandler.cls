/*********************************************************************************************************
Trigger Name    : PC_UpdatePrimaryAddrOnAccount
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
Xiukai Ning                     Feb 5, 2019             PC-3202 Add After Delete Handler
Xiukai Ning                     Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                        Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                        We are removing all FLS and With Sharing keywords in the handlers.
Hitha Avalakki                  Nov 16, 2021            [PC-8225]: Added new method: updateBulkAddressesOnAccount(), which will take care of the scenario when there is a bulk load of addresses for accounts
Satheesh Kumar                  Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
Hitha Avalakki                  Nov 17, 2021           [PC-8225]: Added null pointer check to map logic.
Hitha Avalakki                  Nov 30, 2021            [PC-8378]:Added code logic to set the address field on Account record to null when the same address record is marked as non-primary manually
Tejas Patel                     Feb 05, 2022            [PC-8486] hotfix on updateBulkAddressesOnAccount, adding account set in query.
Hitha Avalakki                  Feb 18, 2022            [PC-8521]: Bugfix for updating address records in bulk.
****************************************************************************************************************/

public inherited sharing class PC_UpdatePrimaryAddrOnAccountHandler extends PC_TriggerHandler{

    override public void beforeInsert() {

        if(newList!=null && !newList.isEmpty() && newList.size()>1){
            updateBulkAddressesOnAccount(newList);
        }
        else{
            updatePrimaryAddressOnAccount(newList);
        }
    }

    override public void beforeUpdate() {

        if(newList!=null && !newList.isEmpty() && newList.size()>1){
            List<PC_Address__c> subsetList = new List<PC_Address__c>();

            List<PC_Address__c> newAddressList = new List<PC_Address__c>();
            newAddressList = (List<PC_Address__c>) newList;

            for(PC_Address__c newAddressRecord: newAddressList){

                if(oldMap!=null && !oldMap.isEmpty() && oldMap.containsKey(newAddressRecord.Id)){
                    PC_Address__c oldAddressRecord=(PC_Address__c) oldMap.get(newAddressRecord.Id);

                    if(oldAddressRecord.PC_Primary_Address__c != newAddressRecord.PC_Primary_Address__c){
                        subsetList.add(newAddressRecord);
                    }
                }
            }

            if(subsetList!=null && !subsetList.isEmpty()){
                updateBulkAddressesOnAccount(subsetList);
            }
        }
        else{
            updatePrimaryAddressOnAccount(newList);
        }
    }

    override public void afterDelete() {
        updatePrimaryAddressOnAccountAfterDelete(oldList);
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
        List<Account> accountToBeUpdated = new List<Account>();

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

            /*[PC-8378]Please note the following piece of code will set the address field on Account record to null when the same address record is marked as non-primary manually*/
            if(setAccountsIdsNotPrimary!=null && !setAccountsIdsNotPrimary.isEmpty()){
                Map<Id,Account> mapOfAccounts = new Map<Id, Account>([SELECT Id,PC_Primary_Address__c FROM Account WHERE ID IN: setAccountsIdsNotPrimary]);

                for(PC_Address__c addressRecord:addresses){

                    if(mapOfAccounts.containsKey(addressRecord.PC_Account__c) && mapOfAccounts.get(addressRecord.PC_Account__c).PC_Primary_Address__c == addressRecord.Id){
                        Account accountRecord = mapOfAccounts.get(addressRecord.PC_Account__c);
                        accountRecord.PC_Primary_Address__c = null;
                        accountToBeUpdated.add(accountRecord);
                    }
                }

                if(accountToBeUpdated!=null && !accountToBeUpdated.isEmpty()){
                    PC_Database.upd(accountToBeUpdated);
                }
            }
        } catch(Exception e) {
            PC_Utility.createExceptionLog(e);
        }
    }

   /*********************************************************************************
    Method Name    : updateBulkAddressesOnAccount
    Author         : Hitha Avalakki
    Description    : This method  updates the primary address records for accounts
    Return Type    : void
    Parameter      : List of incoming account address records - Trigger.new
    *********************************************************************************/
    private void updateBulkAddressesOnAccount(List<PC_Address__c> newAddresses){

        Map<Id,List<PC_Address__c>> mapOfNoPrimaryAddressAccountsAndNewAddressList = new Map<Id,List<PC_Address__c>>();
        Map<Id, Boolean> accountIdAndPrimaryAddressStatus = new Map<Id, Boolean>();
        Map<Id,Integer> accountIdAndCountOfPrimaryAddresses = new Map<Id, Integer>();
        Map<Id,List<PC_Address__c>> accountIdAndListOfNewPrimaryAddressesMap = new Map<Id, List<PC_Address__c>>();
        Map<Id, PC_Address__c> mapOfAccountsAndExistingPrimaryAddressRecordMap = new Map<Id, PC_Address__c>();
        List<PC_Address__c> existingPrimaryAddressRecordsToBeMarkedAsNonPrimary = new List<PC_Address__c>();

        //Create set of accountIds related to address
        Set<Id> accountIds = new Set<Id>();
        for (PC_Address__c a : newAddresses) {
            accountIds.add(a.PC_Account__c);
        }

        //Only bring account related to addresses
        Map<Id,Account> mapOfAccountsWithPrimaryAddress =  new Map<Id,Account>([SELECT Id,PC_Primary_Address__c FROM Account WHERE ID in :accountIds and PC_Primary_Address__c!=null]);
        Map<Id,Account> mapOfAllAccountsWithoutPrimaryAddress =  new Map<Id,Account>([SELECT Id,PC_Primary_Address__c FROM Account WHERE ID in :accountIds and PC_Primary_Address__c=null]);

        /* PC-8521: mapOfIdAndAddressRecord map is related to Addredd record id and the address record as value for all existing  accounts which have primary address*/
        Map<Id, PC_Address__c> mapOfIdAndAddressRecord = new Map<Id, PC_Address__c>([SELECT Id,PC_Account__c FROM PC_Address__c WHERE PC_Account__c in :mapOfAccountsWithPrimaryAddress.keySet()]);

        if (mapOfAccountsWithPrimaryAddress!=null && !mapOfAccountsWithPrimaryAddress.isEmpty()) {

            for (Id accountRecordId : mapOfAccountsWithPrimaryAddress.keySet()) {

                if (mapOfIdAndAddressRecord != null && !mapOfIdAndAddressRecord.isEmpty()) {

                    Id addressRecordId = mapOfAccountsWithPrimaryAddress.get(accountRecordId).PC_Primary_Address__c;

                    if (addressRecordId != null) {
                        mapOfAccountsAndExistingPrimaryAddressRecordMap.put(accountRecordId, mapOfIdAndAddressRecord.get(addressRecordId));
                    }
                }
            }
        }

        /* PC-8521: END*/

        if(newAddresses!=null && !newAddresses.isEmpty()){

            for(PC_Address__c newAddress: newAddresses){

                if(mapOfAccountsWithPrimaryAddress!=null && !mapOfAccountsWithPrimaryAddress.isEmpty() && mapOfAccountsWithPrimaryAddress.containsKey(newAddress.PC_Account__c)){

                    /*accountIdAndListOfNewPrimaryAddressesMap: Here we prepare a map with account id as key and value as list of its new primary address records.
                      accountIdAndCountOfPrimaryAddresses: This map would be used when account has/have multiple primary address records.
                      mapOfNoPrimaryAddressAccountsAndNewAddressList: This map is related to those accounts which dont have primary address and the new address records are related to the corresponding accounts.
                     */
                    if(newAddress.PC_Primary_Address__c){

                        /* PC-8521: The following code will take care of keeping track of how many primary address records are present for any existing account which already has a primary address */
                        if(accountIdAndCountOfPrimaryAddresses.containsKey(newAddress.PC_Account__c)){

                            Integer numberOfPrimaryAddresses = accountIdAndCountOfPrimaryAddresses.get(newAddress.PC_Account__c)+1;
                            accountIdAndCountOfPrimaryAddresses.put(newAddress.PC_Account__c,numberOfPrimaryAddresses);

                        }else{
                            accountIdAndCountOfPrimaryAddresses.put(newAddress.PC_Account__c,1);
                        }
                        /* PC-8521:END */

                        if(accountIdAndListOfNewPrimaryAddressesMap!=null && !accountIdAndListOfNewPrimaryAddressesMap.isEmpty() &&
                                accountIdAndListOfNewPrimaryAddressesMap.containsKey(newAddress.PC_Account__c)){

                            List<PC_Address__c> newlyAddedAddressList = accountIdAndListOfNewPrimaryAddressesMap.get(newAddress.PC_Account__c);
                            newlyAddedAddressList.add(newAddress);
                            accountIdAndListOfNewPrimaryAddressesMap.put(newAddress.PC_Account__c,newlyAddedAddressList);
                        }
                        else{
                            List<PC_Address__c> newAddressList = new List<PC_Address__c>();
                            newAddressList.add(newAddress);
                            accountIdAndListOfNewPrimaryAddressesMap.put(newAddress.PC_Account__c,newAddressList);
                        }
                    }else{

                        /* PC-8521: The following code will update the count of to 0 if any account does not have a primary address record in the newly uploaded list of address records*/
                        if(accountIdAndCountOfPrimaryAddresses!=null && !accountIdAndCountOfPrimaryAddresses.containsKey(newAddress.PC_Account__c)){
                            accountIdAndCountOfPrimaryAddresses.put(newAddress.PC_Account__c,0);
                        }
                        /* PC-8521:END */
                    }


                }
                else if(mapOfAllAccountsWithoutPrimaryAddress!=null && !mapOfAllAccountsWithoutPrimaryAddress.isEmpty() && mapOfAllAccountsWithoutPrimaryAddress.containsKey(newAddress.PC_Account__c)){

                    if(mapOfNoPrimaryAddressAccountsAndNewAddressList.containsKey(newAddress.PC_Account__c)){

                        List<PC_Address__c> existingListOfAddresses = new List<PC_Address__c>();
                        existingListOfAddresses = mapOfNoPrimaryAddressAccountsAndNewAddressList.get(newAddress.PC_Account__c);
                        existingListOfAddresses.add(newAddress);
                        mapOfNoPrimaryAddressAccountsAndNewAddressList.put(newAddress.PC_Account__c,existingListOfAddresses);
                    }
                    else{

                        List<PC_Address__c> newListOfAddresses = new List<PC_Address__c>();
                        newListOfAddresses.add(newAddress);
                        mapOfNoPrimaryAddressAccountsAndNewAddressList.put(newAddress.PC_Account__c,newListOfAddresses);
                    }
                }
            }

        }

        /*** For accounts that already have primary address:START ***/
        if(accountIdAndCountOfPrimaryAddresses!=null && !accountIdAndCountOfPrimaryAddresses.isEmpty()){

            for(Id accountId:accountIdAndCountOfPrimaryAddresses.keySet()) {

                Integer countOfPrimaryAdddresses = accountIdAndCountOfPrimaryAddresses.get(accountId);

                //The following logic should work only when there exist 1 or more primary addresses for any account
                if(countOfPrimaryAdddresses!=null && countOfPrimaryAdddresses>0){

                    if (countOfPrimaryAdddresses == 1) {

                        if(accountIdAndListOfNewPrimaryAddressesMap.containsKey(accountId) && accountIdAndListOfNewPrimaryAddressesMap.get(accountId)!=null){

                            /*PC-8521:  When an account already has a primary address and in the newly added address records only one primary address record is present,
                               then the new address record is marked as primary on account and existing primary address record is marked as non-primary */

                            PC_Address__c existingPrimaryAddressRecord = new PC_Address__c();

                            if(mapOfAccountsAndExistingPrimaryAddressRecordMap!=null && !mapOfAccountsAndExistingPrimaryAddressRecordMap.isEmpty() &&
                                    mapOfAccountsAndExistingPrimaryAddressRecordMap.containsKey(accountId) &&
                                    accountIdAndListOfNewPrimaryAddressesMap.get(accountId)[0].Id!= mapOfAccountsAndExistingPrimaryAddressRecordMap.get(accountId).Id){

                                existingPrimaryAddressRecord = mapOfAccountsAndExistingPrimaryAddressRecordMap.get(accountId);
                                existingPrimaryAddressRecord.PC_Primary_Address__c = false;

                                existingPrimaryAddressRecordsToBeMarkedAsNonPrimary.add(existingPrimaryAddressRecord);
                            }
                            /* PC-8521:END */
                        }

                    } else {

                        /* When an account already has a primary address and in the newly added address records has one or more marked as primary address, then all the new  address records are marked as non primary*/
                        List<PC_Address__c> multiplePrimaryAddressList = new List<PC_Address__c>();
                        multiplePrimaryAddressList = accountIdAndListOfNewPrimaryAddressesMap.get(accountId);

                        if(multiplePrimaryAddressList!= null){
                            for (PC_Address__c newAddressRecord : multiplePrimaryAddressList) {
                                newAddressRecord.PC_Primary_Address__c = false;
                            }
                        }
                    }
                }
            }

            if(existingPrimaryAddressRecordsToBeMarkedAsNonPrimary!=null && !existingPrimaryAddressRecordsToBeMarkedAsNonPrimary.isEmpty()){
                PC_Database.upd(existingPrimaryAddressRecordsToBeMarkedAsNonPrimary,false);
            }
        }

        /*** For accounts that already have primary address:END ***/

        /** For accounts which don't have primary addresses : START ***/

        /**  If account record does not have a primary address, and in the new address records we have one or more marked as primary, then we select the first primary address record and
             mark it as primary on the account record. The rest of the address records are marked as non primary **/
        for(Id accountId: mapOfNoPrimaryAddressAccountsAndNewAddressList.keySet()){

            accountIdAndPrimaryAddressStatus.put(accountId,false);

            List<PC_Address__c> addressList = mapOfNoPrimaryAddressAccountsAndNewAddressList.get(accountId);

            if(addressList!= null){

                for (PC_Address__c newAddressRecord : addressList) {

                    if (!accountIdAndPrimaryAddressStatus.get(accountId)) {

                        if (newAddressRecord.PC_Primary_Address__c) {
                            accountIdAndPrimaryAddressStatus.put(accountId, true);
                        }

                    } else {
                        if (newAddressRecord.PC_Primary_Address__c) {
                            newAddressRecord.PC_Primary_Address__c = false;
                        }
                    }
                }
            }

        }

        /**  If account record does not have a primary address, and in the new address records we dont have any address record marked as primary, then we select the first non-primary address record and
             mark it as primary on the account record. The rest of the new address records remain unchanged.**/
        for(Id accountIdWithNoPrimaryAddress: accountIdAndPrimaryAddressStatus.keySet()){

            if(!accountIdAndPrimaryAddressStatus.get(accountIdWithNoPrimaryAddress)){

                List<PC_Address__c> addressList = mapOfNoPrimaryAddressAccountsAndNewAddressList.get(accountIdWithNoPrimaryAddress);

                if(addressList!= null){

                    for (PC_Address__c newAddressRecord : addressList) {

                        if (!accountIdAndPrimaryAddressStatus.get(accountIdWithNoPrimaryAddress)) {
                            if (!newAddressRecord.PC_Primary_Address__c) {
                                newAddressRecord.PC_Primary_Address__c = true;
                                accountIdAndPrimaryAddressStatus.put(accountIdWithNoPrimaryAddress, true);
                            }
                        }
                    }
                }
            }
        }

        /** For accounts which don't have primary addresses : END ***/
    }

    private void updatePrimaryAddressOnAccountAfterDelete(List<PC_Address__c> addresses) {
        Set<Id> accountIds = new Set<Id> ();
        List<PC_Address__c> primaryAddresses= new List<PC_Address__c>();

        try {
            for (PC_Address__c address : addresses) {
                accountIds.add(address.PC_Account__c);
            }
            for (Account account : [SELECT Id, (SELECT Id FROM Addresses__r) FROM Account WHERE Id IN :accountIds]) {
                if (account.Addresses__r !=null&& account.Addresses__r.size() == 1) {
                    account.Addresses__r[0].PC_Primary_Address__c = true;
                    primaryAddresses.add(account.Addresses__r[0]);
                }
            }
            if (primaryAddresses.size() > 0) {
                PC_Database.upd(primaryAddresses, false);
            }
        }catch(Exception e) {
            PC_Utility.createExceptionLog(e);
        }


    }
}