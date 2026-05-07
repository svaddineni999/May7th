/*********************************************************************************************************
Class Name      : PC_SetPrimaryContactForPC_Individual
Description     : Sets the Primary contact on PC Individual Account
Created By      : Haritha Reddy
Created Date    : Sep 30, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                Date                 Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy        Sep 30, 2021       [PC-8161] Initial Version
Satheesh Kumar       Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_SetPrimaryContactForPC_Individual extends PC_TriggerHandler {
    override public void afterInsert(){
        populatePrimaryContactOnAccount((List<Contact>)newList);
    }

    /*********************************************************************************
    Method Name    : populatePrimaryContactOnAccount
    Description    : This method populates primary contact on PC Individual Account
    Return Type    : void
    Parameter      : List of contact records
    *********************************************************************************/
    private void populatePrimaryContactOnAccount(List<Contact> contacts) {
        if(contacts != null && !contacts.isEmpty() ){
            Id contactRecordTypeId = PC_System.recordTypeId(PC_Constants.CONTACT, PC_Constants.CONTACT_INDIVIDUAL_RECORD_TYPE); //Generic Record Type IndustriesIndividual
            Id contactPhysicianRecordTypeId = PC_System.recordTypeId(PC_Constants.CONTACT, PC_Constants.CONTACT_PHYSICIAN_RECORD_TYPE);// PC_Physician Record Type
            Set<Id> accountIds =  new Set<Id>();
            for(Contact cont: contacts){
                if(cont.RecordTypeId == contactRecordTypeId || cont.RecordTypeId == contactPhysicianRecordTypeId ){
                    accountIds.add(cont.accountId);
                }
            }
            List<RecordType> allAccountRecordTypes =  [SELECT Id, DeveloperName, NamespacePrefix FROM RecordType WHERE SobjectType =: PC_Constants.PC_ACCOUNT];
            Map<Id, Map<String, String>> developerNamesByRecordTypeId = new Map<Id, Map<String, String>>();
            Map<String, String> keyValue;

            for(RecordType rt : allAccountRecordTypes) {
                keyValue = new Map<String, String>();
                keyValue.put(PC_Constants.NAMESPACE_KEY, rt.NamespacePrefix );
                keyValue.put(PC_Constants.RECORD_TYPE_DEV_NAME_KEY, rt.DeveloperName);
                developerNamesByRecordTypeId.put(rt.Id, keyValue);
            }

            if(accountIds != null && !accountIds.isEmpty()){
                Map<Id, Account> individualAccountsPC = new Map<Id, Account>([Select Id,HealthCloudGA__PrimaryContact__c,PC_Individual_Type__c,RecordTypeId
                FROM Account where Id IN:accountIds AND PC_Individual_Type__c = 'Individual' AND HealthCloudGA__PrimaryContact__c = null]);

                List<HealthCloudGA__IndividualRecordTypeMapper__mdt> individualMapperList =
                [SELECT Id,HealthCloudGA__AccountRecordTypeNamespace__c,HealthCloudGA__AccountRecordType__c
                        FROM HealthCloudGA__IndividualRecordTypeMapper__mdt WHERE HealthCloudGA__AccountRecordType__c != null Limit 10000];
                Map<String, String> recordTypeKeyValueWrappers;
                String accountRecordTypeNamespace = null;
                String accountRecordTypeName = null;
                List<Account> individualPCAccountsToBeUpdated = new List<Account>();

                for(Contact cont: contacts){
                    if(individualAccountsPC.containsKey(cont.accountId) && individualAccountsPC.get(cont.accountId) != null ){
                        recordTypeKeyValueWrappers = developerNamesByRecordTypeId.get(individualAccountsPC.get(cont.accountId).RecordTypeId);
                        if(recordTypeKeyValueWrappers != null){
                            accountRecordTypeNamespace = recordTypeKeyValueWrappers.get(PC_Constants.NAMESPACE_KEY);
                            accountRecordTypeName = recordTypeKeyValueWrappers.get(PC_Constants.RECORD_TYPE_DEV_NAME_KEY);
                            if(!PC_SYSTEM.isHealthCloudIndividualRecordType(accountRecordTypeNamespace,accountRecordTypeName,individualMapperList)){
                                if((String.isBlank(accountRecordTypeNamespace) || accountRecordTypeNamespace.equalsIgnoreCase(PC_Constants.OrgNamespace))
                                        && accountRecordTypeName.equalsIgnoreCase(PC_Constants.PATIENT_RECORD_TYPE)){
                                    // This is the case when PC_Patient is not mapped in Individual Mapper.
                                    // We will not set the primary contact here because it is expected that the mapping always exists and HC will take care of that.
                                }
                                else if((String.isBlank(accountRecordTypeNamespace) || accountRecordTypeNamespace.equalsIgnoreCase(PC_Constants.OrgNamespace))
                                        && accountRecordTypeName.equalsIgnoreCase(PC_Constants.PHYSICIAN_RECORD_TYPE)
                                        && cont.RecordTypeId == contactPhysicianRecordTypeId ){
                                    //Populate physician primary contact for Physician Individual Account
                                    individualAccountsPC.get(cont.accountId).HealthCloudGA__PrimaryContact__c = cont.Id;
                                    individualPCAccountsToBeUpdated.add(individualAccountsPC.get(cont.accountId));
                                }
                                else if(cont.RecordTypeId == contactRecordTypeId){
                                    //Populate individual primary contact for Individual Account
                                    individualAccountsPC.get(cont.accountId).HealthCloudGA__PrimaryContact__c = cont.Id;
                                    individualPCAccountsToBeUpdated.add(individualAccountsPC.get(cont.accountId));
                                }
                            }
                        }
                    }
                }
                PC_Database.upd(individualPCAccountsToBeUpdated, false);
            }
        }
    }
}