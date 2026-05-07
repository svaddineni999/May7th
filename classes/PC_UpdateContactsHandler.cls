/*************************************************************************************************************
--------------------------------------------------------------------------------------------------------------
Developer                   Date                    Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar         Mar 11, 2018                 Initial Version
Tushar Arora           Jun 26, 2019                 [PC-4894] Stop referencing Case.PC_Is_Program_Case__c and Account.PC_IsIndividual__c from code
Satheesh Kumar         Nov 16, 2021                 [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
/**
 * Trigger on Contact object to update the PC_Patient contacts on creation of PC_Patient Accounts. PC_Patient should
 * be mapped in HC Individual Mapping. Only some of the selected fields such as Phone, Birth Date, Salutation, Fax & Email
 * are copied from Account to Contact.
 */
public inherited sharing class PC_UpdateContactsHandler extends PC_TriggerHandler {
    override public void afterInsert() {
        processContacts((List<Contact>) newList);
    }
    override public void afterUpdate() {
        processContacts((List<Contact>) newList);
    }

    /**
     * Updates the contacts with the corresponding values from the account object. As of now, only Phone, Fax and Email
     * are updated
     *
     * @param newList List of contacts to update
     */
    private void processContacts(List<Contact> newList) {
        try{
            integer i=0;
            final String NS = PC_Constants.OrgNamespace;
            Id patientContactRecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.CONTACT, PC_Constants.CONTACT_PATIENT_RECORD_TYPE, NS);
            Id patientAccountRecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT, PC_Constants.PATIENT_RECORD_TYPE, NS);
            
            List<Contact> contactsToUpdate = new List<Contact>();

            List<Account> primaryAccounts = new List<Account>();

            Map<Id, Contact> map_accountIdContact = new Map<Id, Contact>();

            List<Id> contactIds = new List<Id>();

            for (Contact c : newList) {
                if (c.RecordTypeId == patientContactRecordTypeId) {
                    system.debug(i++);
                    if(String.isBlank(c.Phone) || String.isBlank(c.Fax) ||
                            String.isBlank(c.Email) || String.isBlank(c.LastName) ||
                            String.isBlank(String.valueOf(c.Birthdate)) || String.isBlank(c.Salutation))
                    {
                        map_accountIdContact.put(c.AccountId, c);
                    }
                }
            }
            if(map_accountIdContact != null && !map_accountIdContact.isEmpty()) {
                if (PC_SYSTEM.isHealthCloudIndividualRecordType(NS, PC_Constants.CONTACT_PATIENT_RECORD_TYPE)) {
                    Account a;
                    Contact newContact;

                    primaryAccounts = [
                            SELECT ID, PC_Salutation__c, Name, RecordTypeId, Fax, Phone,
                                    PC_Email__c, PC_Individual_Type__c, PC_Last_Name__c, PC_Date_of_Birth__c,
                                    HealthCloudGA__PrimaryContact__c, HealthCloudGA__PrimaryContact__r.Id,
                                    HealthCloudGA__PrimaryContact__r.RecordTypeId
                            FROM Account
                            WHERE Id IN :map_accountIdContact.keySet()
                    ];
                    System.debug('primaryAccounts::::'+primaryAccounts);
                    Contact currentContact;
                    boolean updateNewContact;
                    for (Account acc : primaryAccounts) {
                        System.debug(acc.RecordTypeId);
                        System.debug(patientAccountRecordTypeId );
                        if (acc.RecordTypeId == patientAccountRecordTypeId &&
                                map_accountIdContact.containsKey(acc.Id))
                        {
                               
                            currentContact = map_accountIdContact.get(acc.Id);

                            updateNewContact = false;

                            newContact = new Contact();

                            if(String.isBlank(currentContact.Email) && String.isNotBlank(acc.PC_Email__c)) {
                                newContact.Email = acc.PC_Email__c;
                                updateNewContact = true;
                            }
                            if(String.isBlank(currentContact.Fax) && String.isNotBlank(acc.Fax)) {
                                newContact.Fax = acc.Fax;
                                updateNewContact = true;
                            }
                            if(String.isBlank(currentContact.Phone) && String.isNotBlank(acc.Phone)) {
                                newContact.Phone = acc.Phone;
                                updateNewContact = true;
                            }
                            if(String.isBlank(String.valueOf(currentContact.Birthdate)) &&
                                    String.isNotBlank(String.valueOf(acc.PC_Date_of_Birth__c))) {
                                newContact.Birthdate = acc.PC_Date_of_Birth__c;
                                updateNewContact = true;
                            }
                            if(String.isBlank(currentContact.Salutation) && String.isNotBlank(acc.PC_Salutation__c)) {
                                newContact.Salutation = acc.PC_Salutation__c;
                                updateNewContact = true;
                            }
                            /*if(String.isBlank(currentContact.LastName) && String.isNotBlank(acc.PC_Last_Name__c)) {
                                newContact.LastName = acc.PC_Last_Name__c;
                                updateNewContact = true;
                            }*/

                            //newContact = (Contact) PC_Services.copyFields(a, newContact, true);
                            if(updateNewContact) {
                                newContact.Id = currentContact.Id;
                                contactsToUpdate.add(newContact);
                            }

                        }
                    }
                }
            }
            if(contactsToUpdate != null && !contactsToUpdate.isEmpty()) {
                PC_Database.upd(contactsToUpdate, false);//CRUD/FLS is checked in the database ins method.
            }
        }
        catch(Exception ex) {
            PC_Utility.createExceptionLog(ex);
        }

    }
}