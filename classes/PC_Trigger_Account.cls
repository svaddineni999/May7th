/*********************************************************************************************************
Trigger Name    : PC_Trigger_Account
Description     : trigger on Account object.
Created By      : Deloitte
Created Date    : May 17, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Tetiana Danylyshyn              May 17, 2016            Initial Version
Tetiana Danylyshyn              June 16, 2016           Added updatePermissionSetAssignment() method (PC-64)
Alina Balan                     July 14, 2016           Added "createHealthPlan" method
Shabda Bhujad,                  Nov 8, 2016             Removed the updatePermissionSetAssignment since Portal functionality is not included in the current version of managed package
Prachi Nandgaonkar                                      Ref @@RemovePortalPermissionSet 
Shabda Bhujad,                  Nov 10, 2016            Added updateRelatedContacts() for updating the contact when Account Lastname is updated PC-462
Prachi Nandgaonkar                                      
Prachi Nandgaonkar              Nov 15, 2016            Added udpatedAccountName() to update Account Name field on account with Account Last Name and Account First Name PC-475
Shabda Bhujad                   Dec 06, 2016            Added FLS check to updateAccountName, updateRelatedCases methods
Prachi Nandgaonkar              Feb 14, 2016            Updated updateAccountName() PC-1144
Prachi Nandgaonkar              Feb 20, 2017            Added system debug statements for checking governor limits
Mayuresh Patil					Feb 21, 2017			Added check on list size on updateRelatedContacts() to ensure SOQL is fired only when names are updated on account
Prachi Nandgoankar              Mar 3, 2017             Updated updateAccountName() to remove DML statement PC-1213
Ajinkya Deshmukh				Jun 7, 2017				FLS Check for Name in updateAccountName()
Mayuresh Patil                  Jun 28, 2017            PC-1820 As a user when I update the email address on the patient account, it should update the email id on its related contacts accordingly.
Mike Klumpenaar                 23-Jun-2017             Revert to using PC_SYSTEM.recordTypeId to resolve transaction issue PC-1817
Ajinkya Deshmukh                July 6, 2017            Removed SOQL from for loop
Mayuresh Patil                  July 26, 2017           Updated CRUD/FLS checks
Shabda Bhujad                   Nov 14, 2017            PC-2485 Removing the reference to trigger state
Xiukai Ning                     Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                        Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                        We are removing all FLS and With Sharing keywords in the handlers.
Tushar Arora                    Jun 26, 2019            [PC-4894] Stop referencing Case.PC_Is_Program_Case__c and Account.PC_IsIndividual__c from code
Satheesh Kumar                  Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_Trigger_Account extends PC_TriggerHandler {

    override public void beforeInsert(){
       updateAccountName((List<Account>) newList);
    }

    override public void beforeUpdate(){
        updateAccountName((List<Account>) newList);  
    }
    
    override public void afterInsert(){
        createRelatedContact((List<Account>)newList);
    }

    override public void afterUpdate(){
        System.debug('Method name: updateRelatedCases');
        updateRelatedCases((Map<Id, Account>) oldMap, (List<Account>) newList);

        System.debug('Method name: updateRelatedContacts');
        updateRelatedContacts((Map<Id, Account>) oldMap, (List<Account>) newList);
    }

    static Set<String> accountRecordTypesManageContacts = new Set<String> {
        PC_Constants.CASE_PHYSICIAN_RECORD_TYPE
    };

    /*********************************************************************************
    Method Name    : updateAccountName
    Author         : Prachi Nandgaonkar 
    Description    : This method  updates Account Name field on account with Account Last Name and Account First Name PC-475
    Return Type    : void
    Parameter      : List of incoming account records - Trigger.new              
    *********************************************************************************/
    private void updateAccountName(List<Account> accounts) {
        List<Account> accountsToUpdate = new List<Account>();

        for (Account a : accounts) {
            if (a.PC_Individual_Type__c == 'Individual' && String.isNotBlank(a.PC_First_Name__c) && String.isNotBlank(a.PC_Last_Name__c ) ){
                a.Name = a.PC_Last_Name__c + ', ' + a.PC_First_Name__c;
                accountsToUpdate.add(a);

            }else {
                accountsToUpdate.add(a);
            }
        }
    }
    
    /*********************************************************************************
    Method Name    : updateRelatedCases
    Author         : Vasile Paraschiv
    Description    : Fire the update on cases related to accounts when the account name was modified
    Return Type    : void
    Parameter      : oldMap, newList              
    *********************************************************************************/
    private void updateRelatedCases(Map<Id, Account> oldMap, List<Account> newList){
        List <Id> modifiedAccountIds = new List <Id>();
        List <Case> casesToUpdate = new List <Case>();

        try {
            for(Account accountObj : newList) {
                if(accountObj.Id != null && (oldMap != null && oldMap.containsKey(accountObj.Id))) {
                    Account oldAccountObj = oldMap.get(accountObj.Id);
                    if (accountObj.PC_First_Name__c != oldAccountObj.PC_First_Name__c || accountObj.PC_Last_Name__c != oldAccountObj.PC_Last_Name__c){
                        modifiedAccountIds.add(accountObj.Id);
                    }
                }
            }
            if (modifiedAccountIds.size() > 0) {
                casesToUpdate = getRelatedCases(modifiedAccountIds);
            }
            if (casesToUpdate.size() > 0) {
                casesToUpdate = (List<Case>)PC_Database.upd(casesToUpdate, false);//CRUD/FLS checked in the database upd method
            }
        } catch(Exception ex) {
                PC_Utility.createExceptionLog(ex);
        }
    }

    /*********************************************************************************
    Method Name    : getRelatedCases
    Author         : Vasile Paraschiv
    Description    : Get a list of cases related to the account ids
    Return Type    : List<Case>
    Parameter      : List <Id> accountIds         
    *********************************************************************************/
    private List<Case> getRelatedCases(List <Id> accountIds) {
        return [SELECT Id FROM Case WHERE accountId IN :accountIds];
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

        try {
            for(Account accountObj : newList) {
	            if(accountObj.Id != null && (oldMap != null && oldMap.containsKey(accountObj.Id))) {
	                Account oldAccountObj = oldMap.get(accountObj.Id);
	                if (accountObj.PC_First_Name__c != oldAccountObj.PC_First_Name__c || accountObj.PC_Last_Name__c != oldAccountObj.PC_Last_Name__c || accountObj.PC_Email__c != oldAccountObj.PC_Email__c ){
	                    modifiedAccounts.put(accountObj.id, accountObj);
	                }
	        	}
            }
            
            if (modifiedAccounts.size() > 0) {
                relatedContacts = [SELECT Id, accountId, LastName FROM Contact WHERE accountId IN :modifiedAccounts.keySet()];

                if (relatedContacts.size() > 0) {
                    Account acc;
                    for (Contact c : relatedContacts) {
                        acc = modifiedAccounts.get(c.accountId);
                        c.LastName = acc.Name;
                        c.Email = acc.PC_Email__c;
                        contactsToUpdate.add(c);
                    }
                }
                contactsToUpdate = (List<Contact>) PC_Database.upd(contactsToUpdate, false);//CRUD/FLS is checked in the database upd method.
            }
         } catch(Exception ex) {
                PC_Utility.createExceptionLog(ex);
         }
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
        for (Account a : accounts){
            if (a.PC_Individual_Type__c == 'Individual') {
                Contact c = new Contact();
                c = (Contact)PC_Services.copyFields(a, c, true);
                c.AccountId = a.Id;
                c.Email = a.PC_Email__c;
                c.RecordTypeId = contactRecordTypeId;
                c.LastName = a.Name;
                contacts.add(c);
            }
        }
        if (!contacts.isEmpty())  {
            try {
                PC_Database.ins(contacts, false);//CRUD/FLS is checked in the database ins method.
            } catch(Exception ex) {
                PC_Utility.createExceptionLog(ex);
            }
        }
    }
}