/*********************************************************************************************************
Class Name      : PC_UpdateContactForHC_Individual
Description     : trigger on Account object to update the contacts on updation of HC Individual Accounts
Created By      : Tejas Patel
Created Date    : Feb 5, 2020
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Tejas Patel            		Feb 5, 2020        		Initial Version
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
Hitha Avalakki              May 25, 2021            PC-7545: Removed 'with sharing' class level declaration since trigger handler code runs in system context.
Haritha Reddy               Sep 15, 2021            [PC-8157] Removed SOQL inside for loop. Removed usage of recordTypeDeveloperNameAndNamespaceById
                                                    inside for loop and added logic to populate record type map before processing accounts.
Haritha Reddy               Oct 13, 2021            [PC-8161] Made changes to remove Individual mapper SOQL inside for loop
Satheesh Kumar              Nov 16, 2021            [PC-8213] Exclude FLS Check and added inherited sharing
****************************************************************************************************************/

/* PC-7545: 'with sharing' class level declaration is not required since trigger handler code runs in Trigger Context*/
public inherited sharing class PC_UpdateContactForHC_Individual extends PC_TriggerHandler{

    override public void afterUpdate(){
        updateRelatedContacts((Map<Id, Account>) oldMap, (List<Account>) newList);
    }

    /*********************************************************************************
    Method Name    : updateRelatedContacts
    Author         : Prachi Nandgaonkar and Shabda Bhujad
    Description    : Fire the update on Contacts related to accounts when the account name was modified
    Return Type    : void
    Parameter      : oldMap, newList
    *********************************************************************************/
    private void updateRelatedContacts(Map<Id, Account> oldMap, List<Account> newList){
        Map<Id, Account> modifiedAccounts = new Map<Id, Account>();
        Set<Id> primaryContact = new Set<Id>();
        List <Contact> relatedContacts = new List <Contact>();
        List <Contact> contactsToUpdate = new List <Contact>();
        Map<String, String> recordTypeKeyValueWrappers;
        try {
            List<RecordType> allAccountRecordTypes =  [SELECT Id, DeveloperName, NamespacePrefix FROM RecordType WHERE SobjectType =: PC_Constants.PC_ACCOUNT];
            Map<Id, Map<String, String>> developerNamesByRecordTypeId = new Map<Id, Map<String, String>>();
            Map<String, String> keyValue;

            for(RecordType rt : allAccountRecordTypes) {
                keyValue = new Map<String, String>();
                keyValue.put(PC_Constants.NAMESPACE_KEY, rt.NamespacePrefix );
                keyValue.put(PC_Constants.RECORD_TYPE_DEV_NAME_KEY, rt.DeveloperName);
                developerNamesByRecordTypeId.put(rt.Id, keyValue);
            }

            List<HealthCloudGA__IndividualRecordTypeMapper__mdt> individualMapperList = [SELECT Id,HealthCloudGA__AccountRecordTypeNamespace__c,
                    HealthCloudGA__AccountRecordType__c FROM HealthCloudGA__IndividualRecordTypeMapper__mdt
                    WHERE HealthCloudGA__AccountRecordType__c != null Limit 10000];
            String accountRecordTypeNamespace = null;
            String accountRecordTypeName = null;

            for(Account accountObj : newList) {
                if(accountObj.Id != null && accountObj.PC_Individual_Type__c == 'Individual' && (oldMap != null && oldMap.containsKey(accountObj.Id)) && accountObj.HealthCloudGA__PrimaryContact__c != null) {
                    Account oldAccountObj = oldMap.get(accountObj.Id);
                    if (accountObj.PC_First_Name__c != oldAccountObj.PC_First_Name__c || accountObj.PC_Last_Name__c != oldAccountObj.PC_Last_Name__c || accountObj.PC_Email__c != oldAccountObj.PC_Email__c
                            || accountObj.PC_Date_of_Birth__c != oldAccountObj.PC_Date_of_Birth__c || accountObj.PC_Salutation__c  != oldAccountObj.PC_Salutation__c
                            || accountObj.Fax != oldAccountObj.Fax || accountObj.Phone != oldAccountObj.Phone){
                        recordTypeKeyValueWrappers = developerNamesByRecordTypeId.get(accountObj.RecordTypeId);

                        if(recordTypeKeyValueWrappers != null) {
                            accountRecordTypeNamespace = recordTypeKeyValueWrappers.get(PC_Constants.NAMESPACE_KEY);
                            accountRecordTypeName = recordTypeKeyValueWrappers.get(PC_Constants.RECORD_TYPE_DEV_NAME_KEY);
                            if (PC_SYSTEM.isHealthCloudIndividualRecordType(accountRecordTypeNamespace,accountRecordTypeName)) {
                                modifiedAccounts.put(accountObj.id, accountObj);
                                primaryContact.add(accountObj.HealthCloudGA__PrimaryContact__c);
                            }
                        }
                    }
                }
            }

            if (modifiedAccounts.size() > 0) {
                //FLS is NOT needed in Triggers, as they always run in System Mode.
                /*
                //FLS check
                List<String> contactFields = new List<String>{
                         'AccountId','Email','Fax','Phone','Birthdate'
                };
                PC_Database.assertAccess(PC_Constants.CONTACT, PC_Database.Operation.Reading, contactFields);
                 */

                relatedContacts = [SELECT Id, accountId, LastName, FirstName, Email, Fax, Phone, Birthdate, Salutation FROM Contact WHERE Id IN :primaryContact];

                if (relatedContacts.size() > 0) {
                    Account acc;
                    for (Contact c : relatedContacts) {
                        acc = modifiedAccounts.get(c.accountId);
                        c.LastName      =   acc.PC_Last_Name__c;
                        c.FirstName     =   acc.PC_First_Name__c;
                        c.Email         =   acc.PC_Email__c;
                        c.Fax           =   acc.Fax;
                        c.Phone         =   acc.Phone;
                        c.Birthdate     =   acc.PC_Date_of_Birth__c;
                        c.Salutation    =   acc.PC_Salutation__c;
                        contactsToUpdate.add(c);
                    }
                }
                contactsToUpdate = (List<Contact>) PC_Database.upd(contactsToUpdate, false);
            }
        } catch(Exception ex) {
            PC_Utility.createExceptionLog(ex);
        }
    }
}