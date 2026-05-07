/*********************************************************************************************************
Class Name      : PC_CreateContactForPC_Individual
Description     : trigger on Account object create the contacts on creation of PC Individual Accounts
Created By      : Tejas Patel
Created Date    : Feb 5, 2020
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Tejas Patel            		Feb 5, 2020        		Initial Version
Hitha Avalakki              May 25,2021             [PC-7545]: Removed 'with sharing' class level declaration since trigger handler code runs in system context.
Haritha Reddy               Sep 15, 2021            [PC-8157] Removed SOQL inside for loop. Removed usage of recordTypeDeveloperNameAndNamespaceById
                                                    inside for loop and added logic to populate record type map before processing accounts.
Haritha Reddy               Oct 13, 2021            [PC-8161] Made changes to remove Individual mapper SOQL inside for loop
Satheesh Kumar              Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/

/* PC-7545: 'with sharing' class level declaration is not required since trigger handler code runs in Trigger Context*/
public inherited sharing class PC_CreateContactForPC_Individual extends PC_TriggerHandler {
    override public void afterInsert(){
        createRelatedContact((List<Account>)newList);
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

        Id contactRecordTypeId = PC_System.recordTypeId(PC_Constants.CONTACT, PC_Constants.CONTACT_INDIVIDUAL_RECORD_TYPE); //Generic Record Type IndustriesIndividual
        Id contactPhysicianRecordTypeId = PC_System.recordTypeId(PC_Constants.CONTACT, PC_Constants.CONTACT_PHYSICIAN_RECORD_TYPE);// PC_Physician Record Type

        Map<String, String> recordTypeKeyValueWrappers;
        String accountRecordTypeNamespace = null;
        String accountRecordTypeName = null;

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

        for (Account a : accounts){

            if (a.PC_Individual_Type__c == 'Individual') {
                recordTypeKeyValueWrappers = developerNamesByRecordTypeId.get(a.RecordTypeId);
                if(recordTypeKeyValueWrappers != null) {
                    accountRecordTypeNamespace = recordTypeKeyValueWrappers.get(PC_Constants.NAMESPACE_KEY);
                    accountRecordTypeName = recordTypeKeyValueWrappers.get(PC_Constants.RECORD_TYPE_DEV_NAME_KEY);
                    if (!PC_SYSTEM.isHealthCloudIndividualRecordType(accountRecordTypeNamespace, accountRecordTypeName,individualMapperList)) {
                        if((String.isBlank(accountRecordTypeNamespace) ||
                                (accountRecordTypeNamespace.equalsIgnoreCase(PC_Constants.OrgNamespace))) &&
                                accountRecordTypeName.equalsIgnoreCase(PC_Constants.PATIENT_RECORD_TYPE)) {
                            // This is the case when PC_Patient is not mapped in Individual Mapper.
                            // We will not create the contact here because it is expected that the mapping always exists.
                            //c.RecordTypeId = contactPatientRecordTypeId;
                        }
                        else {
                            Contact c = new Contact();
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
}