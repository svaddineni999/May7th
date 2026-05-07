/*********************************************************************************************************
Class Name      : PC_CreateAndUpdateContacts 
Description     : trigger on Account object create and update the contacts on creation and updation of Accounts
Created By      : Tejas Patel
Created Date    : Jan 4, 2018
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                    Description
--------------------------------------------------------------------------------------------------------------            
Tejas Patel                 Jan 4, 2018             Initial Version
Vijay Kashikar              Nov 29, 2018            [PC-3649] Added condition to run the trigger only if the account record type is
                                                    not mapped in the HC individual mapper.
Vijay Kashikar              Feb 06, 2019            [PC-4220] If PC_Patient is not configured in Individual Mapper, then we will
                                                    create an associated contact of type PC_Patient
Vijay Kashikar              Feb 12, 2019            [PC-4220] If PC_Patient is not configured in Individual Mapper, then we will not
                                                    create an associated contact
Vijay Kashikar              Feb 25, 2019            [PC-4493] PC_Physician accounts will now have PC_Physician contacts.
Xiukai Ning                 Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                    Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                    We are removing all FLS and With Sharing keywords in the handlers.
Tushar Arora               Jun 26, 2019            [PC-4894] Stop referencing Case.PC_Is_Program_Case__c and Account.PC_IsIndividual__c from code
Tejas Patel                Dec 5, 2019             [PC-5788] For HC individual records, updating Account information does not update Contact
Haritha Reddy             21-Jan-2021              [PC-7102] Added FLS Check
Satheesh Kumar            Nov 16, 2021             [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_CreateAndUpdateContactsHandler extends PC_TriggerHandler {
    override public void afterInsert(){
        createRelatedContact((List<Account>)newList);
    }
    
    override public void afterUpdate(){
        updateRelatedContacts((Map<Id, Account>) oldMap, (List<Account>) newList);
    }
    
    /*********************************************************************************
    Method Name    : createRelatedContact
    Author         : Tetiana Danylyshyn
    Description    : This method  creates new contact for account with Individual record type.
    Return Type    : void
    Parameter      : List of incoming account records - Trigger.new              
    *********************************************************************************/
    private void createRelatedContact(List<Account> accounts) {
        List<Contact> contacts = new List<Contact>();

        Id contactRecordTypeId = PC_System.recordTypeId(PC_Constants.CONTACT, PC_Constants.CONTACT_INDIVIDUAL_RECORD_TYPE);
        Id contactPhysicianRecordTypeId = PC_System.recordTypeId(PC_Constants.CONTACT, PC_Constants.CONTACT_PHYSICIAN_RECORD_TYPE);
        //Id contactPatientRecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.CONTACT,PC_Constants.CONTACT_PATIENT_RECORD_TYPE);

        Map<String, String> recordTypeKeyValueWrappers;
        String accountRecordTypeNamespace = null;
        String accountRecordTypeName = null;
        for (Account a : accounts){

            if (a.PC_Individual_Type__c == 'Individual') {
                recordTypeKeyValueWrappers = PC_SYSTEM.recordTypeDeveloperNameAndNamespaceById(a.RecordTypeId);
                if(recordTypeKeyValueWrappers != null) {
                    accountRecordTypeNamespace = recordTypeKeyValueWrappers.get(PC_Constants.NAMESPACE_KEY);
                    accountRecordTypeName = recordTypeKeyValueWrappers.get(PC_Constants.RECORD_TYPE_DEV_NAME_KEY);
                    if (!PC_SYSTEM.isHealthCloudIndividualRecordType(accountRecordTypeNamespace, accountRecordTypeName)) {
                        if((String.isBlank(accountRecordTypeNamespace) ||
                                (accountRecordTypeNamespace.equalsIgnoreCase(PC_Constants.OrgNamespace))) &&
                                accountRecordTypeName.equalsIgnoreCase(PC_Constants.PATIENT_RECORD_TYPE)) {
                            // This is the case when PC_Patient is not mapped in Individual Mapper.
                            // We will not create the contact here because it is expected that the mapping always exists.
                            //c.RecordTypeId = contactPatientRecordTypeId;
                        }
                        else {
                            Contact c = new Contact();
                            c = (Contact) PC_Services.copyFields(a, c, true);
                            if((String.isBlank(accountRecordTypeNamespace) ||
                                    (accountRecordTypeNamespace.equalsIgnoreCase(PC_Constants.OrgNamespace))) &&
                                    accountRecordTypeName.equalsIgnoreCase(PC_Constants.PHYSICIAN_RECORD_TYPE)) {
                                c.RecordTypeId = contactPhysicianRecordTypeId;
                            }
                            else {
                                c.RecordTypeId = contactRecordTypeId;
                            }
                            c.AccountId     =   a.Id;
                            c.Email         =   a.PC_Email__c;
                            c.LastName      =   a.PC_Last_Name__c;
                            c.FirstName     =   a.PC_First_Name__c;
                            c.Fax           =   a.Fax;
                            c.Phone         =   a.Phone;
                            c.Birthdate     =   a.PC_Date_of_Birth__c;
                            c.Salutation    =   a.PC_Salutation__c;

                            contacts.add(c);
                            system.debug(c);
                        }
                    }
                }
            }
        }
        if (!contacts.isEmpty())  {
            try {
                PC_Database.ins(contacts, false);
            } catch(Exception ex) {
                PC_Utility.createExceptionLog(ex);
            }
        }
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
        List <Contact> relatedContacts = new List <Contact>();
        List <Contact> contactsToUpdate = new List <Contact>();
        Map<String, String> recordTypeKeyValueWrappers;
        try {
            for(Account accountObj : newList) {
                if(accountObj.Id != null && accountObj.PC_Individual_Type__c == 'Individual' && (oldMap != null && oldMap.containsKey(accountObj.Id))) {
                    Account oldAccountObj = oldMap.get(accountObj.Id);
                    if (accountObj.PC_First_Name__c != oldAccountObj.PC_First_Name__c || accountObj.PC_Last_Name__c != oldAccountObj.PC_Last_Name__c || accountObj.PC_Email__c != oldAccountObj.PC_Email__c
                        || accountObj.Fax != oldAccountObj.Fax || accountObj.Phone != oldAccountObj.Phone || accountObj.PC_Date_of_Birth__c != oldAccountObj.PC_Date_of_Birth__c
                        || accountObj.PC_Salutation__c  != oldAccountObj.PC_Salutation__c ){
                        recordTypeKeyValueWrappers = PC_SYSTEM.recordTypeDeveloperNameAndNamespaceById(accountObj.RecordTypeId);
                        if(recordTypeKeyValueWrappers != null  /*&&
                               !PC_SYSTEM.isHealthCloudIndividualRecordType(
                                        recordTypeKeyValueWrappers.get(PC_Constants.NAMESPACE_KEY),
                                        recordTypeKeyValueWrappers.get(PC_Constants.RECORD_TYPE_DEV_NAME_KEY))*/
                                ) {
                            modifiedAccounts.put(accountObj.id, accountObj);
                        }
                    }
                }
            }
            
            if (modifiedAccounts.size() > 0) {
                //FLS is NOT needed in Triggers, as they always run in System Mode.
                /*//FLS check
                List<String> contactFields = new List<String>{'AccountId', 'Email', 'Fax', 'Phone', 'Birthdate'};
                PC_Database.assertAccess(PC_Constants.CONTACT, PC_Database.Operation.Reading, contactFields);*/

                relatedContacts = [SELECT Id, accountId, LastName, FirstName, Email, Fax, Phone, Birthdate, Salutation FROM Contact WHERE accountId IN :modifiedAccounts.keySet()];

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