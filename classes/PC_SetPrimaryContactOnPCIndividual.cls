/*********************************************************************************************************
Class Name      : PC_SetPrimaryContactOnPCIndividual
Description     : Script to set Primary Contact on PC Individual type of Accounts
Created By      : Deloitte
Created Date    : Oct 25, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy                Oct 25, 2021           [PC-8244] Initial Version
****************************************************************************************************************/
global class PC_SetPrimaryContactOnPCIndividual implements Database.Batchable<sObject>, Database.Stateful{

    // instance member to retain state across transactions
    public static final String TXT_KEY = 'txt';
    private static final String BATCH_JOB_NAME = 'PC_SetPrimaryContactOnPCIndividual';
    global Integer totalRecordsProcessed = 0;
    global Integer totalRecords = 0;

    global List<ID> invalidHCIndividualAccounts = new List<ID>();
    global List<ID> invalidAccountsWithNoContact = new List<ID>();
    global List<ID> invalidAccountsWithNoPhysicianContact = new List<ID>();
    global List<ID> invalidAccountsWithNoIndividualContact = new List<ID>();
    global List<ID> invalidAccountsWithMultiplePhysicianContacts = new List<ID>();
    global List<ID> invalidAccountsWithMultipleIndividualContacts = new List<ID>();
    global List<ID> validAccountsWithOnePhysicianContact = new List<ID>();
    global List<ID> validAccountsWithOneIndividualContact = new List<ID>();

    global Document processLog = new Document();
    global List<ID> allBatchLogIds = new List<ID>();
    global List<ID> failedBatchLogIds = new List<ID>();
    global String processLogContent = PC_Constants.EMPTY_STRING;
    /**
    * Implements Database.Batchable method
    */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        try {
            processLog.Name = 'PC_v15.0-' + PC_Constants.EMPTY_STRING + String.valueOf(DateTime.now()) + PC_Constants.LOG_FORMAT;
            processLog.Type = TXT_KEY;
            processLog.folderid = PC_BatchUtility.getFolderId(BATCH_JOB_NAME);
            processLogContent += 'Initiating migration of PC Individual Accounts... \n';

            List<RecordType> pcPatientRecordTypes = [SELECT ID FROM RecordType WHERE DeveloperName=:PC_Constants.PATIENT_RECORD_TYPE
            AND NamespacePrefix=:PC_Constants.OrgNamespace AND IsActive = TRUE AND SobjectType = 'Account'];

            String pcPatientRecordTypeId;
            if(pcPatientRecordTypes != null && pcPatientRecordTypes.size() == 1){
                pcPatientRecordTypeId = pcPatientRecordTypes[0].ID;
            }
            String individualType = PC_Constants.getQualifiedAPIName('PC_Individual_Type__c');
            String query = 'Select Id, RecordTypeId, HealthCloudGA__PrimaryContact__c, ' + individualType +
                    ' FROM Account WHERE HealthCloudGA__PrimaryContact__c = null AND ' + individualType +
                    ' = \'Individual\' AND RecordTypeId != ' +'\''+pcPatientRecordTypeId+'\'';
            System.debug('query::::'+query);
            Database.QueryLocator queryLocator = Database.getQueryLocator(query);

            processLog.Body = Blob.valueOf(processLogContent);
            upsert processLog;

            return queryLocator;
        }
        catch(Exception ex) {
            processLogContent += ex.getMessage();
            PC_Utility.publishAndThrowException(ex, ex.getMessage() + '\n' + processLogContent);
        }
        return Database.getQueryLocator('SELECT ID FROM Account LIMIT 0');
    }

    /**
    * Implements Database.Batchable method
    */
    global void execute(Database.BatchableContext bc, List<Account> scope){
        Document batchLog = new Document();
        String batchLogContent = PC_Constants.EMPTY_STRING;
        batchLog.Name = 'PC_v15.0-Batch-' + PC_Constants.EMPTY_STRING + String.valueOf(DateTime.now()) + PC_Constants.LOG_FORMAT;
        batchLog.Type = TXT_KEY;
        batchLog.folderid = PC_BatchUtility.getFolderId(BATCH_JOB_NAME);

        Integer totalRecordsInThisBatch = 0;
        Integer totalRecordsProcessedInThisBatch = 0;
        Boolean isError = false;
        List<ID> invalidAccountsWithNoContactInThisBatch = new List<ID>();
        List<ID> invalidHCIndividualAccountsInThisBatch = new List<ID>();
        List<ID> invalidAccountsWithNoPhysicianContactInThisBatch = new List<ID>();
        List<ID> invalidAccountsWithNoIndividualContactInThisBatch = new List<ID>();
        List<ID> invalidAccountsWithMultiplePhysicianContactsInThisBatch = new List<ID>();
        List<ID> invalidAccountsWithMultipleIndividualContactsInThisBatch = new List<ID>();
        List<ID> validAccountsWithOnePhysicianContactInThisBatch = new List<ID>();
        List<ID> validAccountsWithOneIndividualContactInThisBatch = new List<ID>();

        try {
            Id contactRecordTypeId = PC_System.recordTypeId(PC_Constants.CONTACT, PC_Constants.CONTACT_INDIVIDUAL_RECORD_TYPE); //Generic Record Type IndustriesIndividual
            Id contactPhysicianRecordTypeId = PC_System.recordTypeId(PC_Constants.CONTACT, PC_Constants.CONTACT_PHYSICIAN_RECORD_TYPE);// PC_Physician Record Type

            List<RecordType> allAccountRecordTypes =  [SELECT Id, DeveloperName, NamespacePrefix FROM RecordType WHERE SobjectType =: PC_Constants.PC_ACCOUNT];
            Map<Id, Map<String, String>> developerNamesByRecordTypeId = new Map<Id, Map<String, String>>();
            Map<String, String> keyValue;

            for(RecordType rt : allAccountRecordTypes) {
                keyValue = new Map<String, String>();
                keyValue.put(PC_Constants.NAMESPACE_KEY, rt.NamespacePrefix );
                keyValue.put(PC_Constants.RECORD_TYPE_DEV_NAME_KEY, rt.DeveloperName);
                developerNamesByRecordTypeId.put(rt.Id, keyValue);
            }

            List<HealthCloudGA__IndividualRecordTypeMapper__mdt> individualMapperList =
                [SELECT Id,HealthCloudGA__AccountRecordTypeNamespace__c,HealthCloudGA__AccountRecordType__c
                FROM HealthCloudGA__IndividualRecordTypeMapper__mdt WHERE HealthCloudGA__AccountRecordType__c != null];
            Map<String, String> recordTypeKeyValueWrappers;
            String accountRecordTypeNamespace = null;
            String accountRecordTypeName = null;
            List<Account> individualPCAccountsToBeUpdated = new List<Account>();

            Map<Id, List<Contact>> contactsByAccountId = getContactsByAccountId(scope);
            List<Contact> accountContacts;

            for(Account acc: scope){
                accountContacts = contactsByAccountId.get(acc.Id);
                if (accountContacts == null || accountContacts.size() == 0) {
                    // account without contact
                    invalidAccountsWithNoContactInThisBatch.add(acc.Id);
                    system.debug('Ignored account record --> ' + acc.Id + ' since it has no contact');
                    batchLogContent += ' Ignored account record --> ' + acc.Id + ' since it has no contact' + '\n';
                }
                else if(accountContacts.size() >= 1){
                    recordTypeKeyValueWrappers = developerNamesByRecordTypeId.get(acc.RecordTypeId);
                    if(recordTypeKeyValueWrappers != null){
                        accountRecordTypeNamespace = recordTypeKeyValueWrappers.get(PC_Constants.NAMESPACE_KEY);
                        accountRecordTypeName = recordTypeKeyValueWrappers.get(PC_Constants.RECORD_TYPE_DEV_NAME_KEY);

                        if(!PC_SYSTEM.isHealthCloudIndividualRecordType(accountRecordTypeNamespace,accountRecordTypeName,individualMapperList)){
                            Integer physicianContactCount = 0;
                            Integer individualContactCount = 0;
                            Contact primaryContact;
                            if((String.isBlank(accountRecordTypeNamespace) || accountRecordTypeNamespace.equalsIgnoreCase(PC_Constants.OrgNamespace))
                                    && accountRecordTypeName.equalsIgnoreCase(PC_Constants.PHYSICIAN_RECORD_TYPE)){
                                for(Contact cont: accountContacts){
                                    if(cont.RecordTypeId == contactPhysicianRecordTypeId ) {
                                        primaryContact = cont;
                                        physicianContactCount = physicianContactCount+1;
                                    }
                                }
                                if(physicianContactCount == 1){
                                    //Populate physician primary contact for Physician Individual Account
                                    acc.HealthCloudGA__PrimaryContact__c = primaryContact.Id;
                                    individualPCAccountsToBeUpdated.add(acc);
                                    validAccountsWithOnePhysicianContactInThisBatch.add(acc.Id);
                                    totalRecordsProcessed = totalRecordsProcessed + 1;
                                    totalRecordsProcessedInThisBatch = totalRecordsProcessedInThisBatch + 1;
                                }
                                else if(physicianContactCount == 0){
                                    invalidAccountsWithNoPhysicianContactInThisBatch.add(acc.Id);
                                    system.debug('Ignored account record --> ' + acc.Id + ' since there is no related physician contact');
                                    batchLogContent += ' Ignored account record --> ' + acc.Id + ' since there is no related physician contact' + '\n';
                                }
                                else if(physicianContactCount > 1){
                                    invalidAccountsWithMultiplePhysicianContactsInThisBatch.add(acc.Id);
                                    system.debug('Ignored account record --> ' + acc.Id + ' since there are more than one related physician contacts');
                                    batchLogContent += ' Ignored account record --> ' + acc.Id + ' since there are more than one related physician contacts' + '\n';
                                }
                            }
                            else{
                                for(Contact cont: accountContacts){
                                    if(cont.RecordTypeId == contactRecordTypeId ) {
                                        primaryContact = cont;
                                        individualContactCount = individualContactCount+1;
                                    }
                                }
                                if(individualContactCount == 1){
                                    //Populate individual primary contact for Individual Account
                                    acc.HealthCloudGA__PrimaryContact__c = primaryContact.Id;
                                    individualPCAccountsToBeUpdated.add(acc);
                                    validAccountsWithOneIndividualContactInThisBatch.add(acc.Id);
                                    totalRecordsProcessed = totalRecordsProcessed + 1;
                                    totalRecordsProcessedInThisBatch = totalRecordsProcessedInThisBatch + 1;
                                }
                                else if(individualContactCount == 0){
                                    invalidAccountsWithNoIndividualContactInThisBatch.add(acc.Id);
                                    system.debug('Ignored account record --> ' + acc.Id + ' since there is no related individual contact');
                                    batchLogContent += ' Ignored account record --> ' + acc.Id + ' since there is no related individual contact' + '\n';
                                }
                                else if(individualContactCount > 1){
                                    invalidAccountsWithMultipleIndividualContactsInThisBatch.add(acc.Id);
                                    system.debug('Ignored account record --> ' + acc.Id + ' since there are more than one related individual contacts');
                                    batchLogContent += ' Ignored account record --> ' + acc.Id + ' since there are more than one related individual contacts' + '\n';
                                }
                            }
                        }else{
                            invalidHCIndividualAccountsInThisBatch.add(acc.Id);
                            system.debug('Ignored account record --> ' + acc.Id + ' since it is HC Individual Account');
                            batchLogContent += ' Ignored account record --> ' + acc.Id + ' since it is HC Individual Account' + '\n';
                        }
                    }
                }
                totalRecordsInThisBatch = totalRecordsInThisBatch + 1;
                totalRecords = totalRecords + 1;
            }
            PC_Database.upd(individualPCAccountsToBeUpdated, true);
        }
        catch(Exception ex) {
            isError = true;
            batchLogContent += '\nException Message,' + ex.getMessage();
            batchLogContent += '\nException StackTrace,' + ex.getStackTraceString();
            batchLogContent += '\nException LineNumber' + ex.getLineNumber();
            batchLogContent += '\nException Cause' + ex.getCause();
            PC_Utility.publishErrorLog(ex, ex.getMessage());

            totalRecords = totalRecords - totalRecordsInThisBatch;
            totalRecordsProcessed = totalRecordsProcessed - totalRecordsProcessedInThisBatch;
            validAccountsWithOnePhysicianContactInThisBatch = new List<ID>();
            validAccountsWithOneIndividualContactInThisBatch = new List<ID>();
            invalidAccountsWithNoContactInThisBatch = new List<ID>();
            invalidHCIndividualAccountsInThisBatch = new List<ID>();
            invalidAccountsWithNoPhysicianContactInThisBatch = new List<ID>();
            invalidAccountsWithNoIndividualContactInThisBatch = new List<ID>();
            invalidAccountsWithMultiplePhysicianContactsInThisBatch = new List<ID>();
            invalidAccountsWithMultipleIndividualContactsInThisBatch = new List<ID>();
        }
        finally {
            batchLog.Body = Blob.valueOf(batchLogContent);
            upsert batchLog;
            allBatchLogIds.add(batchLog.Id);
            batchLogContent += 'Total records in this batch : ' + totalRecordsInThisBatch + '\n';
            batchLogContent += 'Total records processed in this batch : ' + totalRecordsProcessedInThisBatch + '\n';
            if(isError) {
                failedBatchLogIds.add(batchLog.Id);
            }
            validAccountsWithOnePhysicianContact.addAll(validAccountsWithOnePhysicianContactInThisBatch);
            validAccountsWithOneIndividualContact.addAll(validAccountsWithOneIndividualContactInThisBatch);
            invalidAccountsWithNoContact.addAll(invalidAccountsWithNoContactInThisBatch);
            invalidHCIndividualAccounts.addAll(invalidHCIndividualAccountsInThisBatch);
            invalidAccountsWithNoPhysicianContact.addAll(invalidAccountsWithNoPhysicianContactInThisBatch);
            invalidAccountsWithNoIndividualContact.addAll(invalidAccountsWithNoIndividualContactInThisBatch);
            invalidAccountsWithMultiplePhysicianContacts.addAll(invalidAccountsWithMultiplePhysicianContactsInThisBatch);
            invalidAccountsWithMultipleIndividualContacts.addAll(invalidAccountsWithMultipleIndividualContactsInThisBatch);
        }
    }

    /**
    * Implements Database.Batchable method
    */
    global void finish(Database.BatchableContext bc){
        try {
            system.debug('in finish');
            processLogContent += 'Total records that needed migration (Excluding Records in any failed batches) : ' + totalRecords + '\n';
            processLogContent += 'Total records that were migrated : ' + totalRecordsProcessed + '\n';

            if (invalidAccountsWithNoContact.size() > 0) {
                processLogContent += 'Invalid accounts with no contact that were ignored : ' + invalidAccountsWithNoContact.size() + '\n';
            }
            if (invalidHCIndividualAccounts.size() > 0) {
                processLogContent += 'Invalid HC individual accounts that were ignored : ' + invalidHCIndividualAccounts.size() + '\n';
            }
            if (invalidAccountsWithNoPhysicianContact.size() > 0) {
                processLogContent += 'Invalid accounts with no physician contact that were ignored : ' + invalidAccountsWithNoPhysicianContact.size() + '\n';
            }
            if (invalidAccountsWithNoIndividualContact.size() > 0) {
                processLogContent += 'Invalid accounts with no individual contact that were ignored : ' + invalidAccountsWithNoIndividualContact.size() + '\n';
            }
            if (invalidAccountsWithMultiplePhysicianContacts.size() > 0) {
                processLogContent += 'Invalid accounts with multiple physician contacts that were ignored : ' + invalidAccountsWithMultiplePhysicianContacts.size() + '\n';
            }
            if (invalidAccountsWithMultipleIndividualContacts.size() > 0) {
                processLogContent += 'Invalid accounts with multiple individual contacts that were ignored : ' + invalidAccountsWithMultipleIndividualContacts.size() + '\n';
            }
            if (failedBatchLogIds.size() > 0) {
                processLogContent += 'Following batches need your attention since the transactions part of these were rolled back - ' + failedBatchLogIds;
            }

            System.debug(totalRecordsProcessed + ' records processed.');
            system.debug('validAccountsWithOnePhysicianContact-> ' + validAccountsWithOnePhysicianContact);
            system.debug('validAccountsWithOneIndividualContact-> ' + validAccountsWithOneIndividualContact);
            system.debug('invalidAccountsWithNoContact-> ' + invalidAccountsWithNoContact);
            system.debug('invalidHCIndividualAccounts-> ' + invalidHCIndividualAccounts);
            system.debug('invalidAccountsWithNoPhysicianContact-> ' + invalidAccountsWithNoPhysicianContact);
            system.debug('invalidAccountsWithNoIndividualContact-> ' + invalidAccountsWithNoIndividualContact);
            system.debug('invalidAccountsWithMultiplePhysicianContacts-> ' + invalidAccountsWithMultiplePhysicianContacts);
            system.debug('invalidAccountsWithMultipleIndividualContacts-> ' + invalidAccountsWithMultipleIndividualContacts);

            AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob WHERE Id = :bc.getJobId()];

            processLogContent += '\nMigration Process over. Logs are placed in your Personal Document Folder of Document Object\n';
            processLogContent += '\nJob Id - ' + bc.getJobId();
            processLogContent += '\nBatch Files - ' + String.join(allBatchLogIds, ',');
            processLog.Body = Blob.valueOf(processLogContent);
            upsert processLog;

            sendEmail(processLog);

        } catch(Exception ex) {
            PC_Utility.publishAndThrowException(ex, ex.getMessage());
        }
    }

    private static Map<Id, List<Contact>> getContactsByAccountId(List<Account> scope) {
        Map<Id, List<Contact>> contactsByAccountId = new Map<Id, List<Contact>>();
        Set<Id> accountIds = new Set<Id>();
        for(Account acc : scope) {
            accountIds.add(acc.Id);
        }
        Id contactRecordTypeId = PC_System.recordTypeId(PC_Constants.CONTACT, PC_Constants.CONTACT_INDIVIDUAL_RECORD_TYPE); //Generic Record Type IndustriesIndividual
        Id contactPhysicianRecordTypeId = PC_System.recordTypeId(PC_Constants.CONTACT, PC_Constants.CONTACT_PHYSICIAN_RECORD_TYPE);// PC_Physician Record Type

        Map<Id, Account> accountsById = new Map<Id, Account>([SELECT
        (SELECT id, RecordTypeId, AccountId FROM Contacts WHERE RecordTypeId =: contactRecordTypeId OR RecordTypeId =: contactPhysicianRecordTypeId )
                                                    FROM Account WHERE Id = :accountIds]);
        for(Id accountId : accountsById.keySet()) {
            contactsByAccountId.put(accountId, accountsById.get(accountId).Contacts);
        }
        return contactsByAccountId;
    }

    private static void sendEmail(Document processLog) {
        List<Messaging.EmailfileAttachment> fileAttachments = new List<Messaging.EmailfileAttachment>();
        Messaging.Emailfileattachment efa;

        efa = new Messaging.Emailfileattachment();
        efa.setFileName(processLog.Name);
        efa.setBody(processLog.Body);
        fileAttachments.add(efa);

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject('Patient Connect Migration Logs');
        email.setPlainTextBody('Migration logs attached');
        email.setToAddresses(new String[] {UserInfo.getUserEmail()});
        email.setFileAttachments(fileAttachments);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}