/*********************************************************************************************************
Class Name      : PC_UpdatePatientAsHealthCloudIndividual
Description     : Script to migrate PC Patient's to HC Individual
Created By      : Deloitte
Created Date    : Dec 01, 2018
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar                Dec 01, 2018           Initial Version
Shishir Bansal                Dec 05, 2019           [PC-5787] Added null check before DML operation
Haritha Reddy                 May 05, 2020           [PC-6249] Added limit to the SOQL query
Vijay Kashikar                Jun 05, 2020           [PC-6369] Avoid sub query in the start method to avoid APEX TIME OUT ISSUE.
****************************************************************************************************************/
/**
 * Batch class to migrate PC Patients to HC Individual
 */
global class PC_UpdatePatientAsHealthCloudIndividual implements Database.Batchable<sObject>, Database.Stateful
{
    // instance member to retain state across transactions
    public static final String TXT_KEY = 'txt';
    global Integer totalRecordsProcessed = 0;
    global Integer totalRecords = 0;
    global List<ID> validAccountsWithOneContact = new List<ID>();
    global List<ID> invalidAccountsWithNoContact = new List<ID>();
    global List<ID> invalidAccountsWithPCPatientAsPrimaryContact = new List<ID>();
    global List<ID> invalidAccountsWithInvalidPrimaryContact = new List<ID>();
    global List<ID> invalidAccountsWithMultipleContacts = new List<ID>();

    global List<ID> validPhyAccountsWithOneContact = new List<ID>();
    global List<ID> invalidPhyAccountsWithNoContact = new List<ID>();
    global List<ID> invalidPhyAccountsWithPCPhysicianAsPrimaryContact = new List<ID>();
    global List<ID> invalidPhyAccountsWithInvalidPrimaryContact = new List<ID>();
    global List<ID> invalidPhyAccountsWithMultipleContacts = new List<ID>();

    global Document processLog = new Document();
    global List<ID> allBatchLogIds = new List<ID>();
    global List<ID> failedBatchLogIds = new List<ID>();
    global String processLogContent = PC_Constants.EMPTY_STRING;
    global Boolean mailSent = false;

    /**
    * Implements Database.Batchable method
    */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        try {
            //Boolean hasRecords = false;
            Database.QueryLocator queryLocator;
            processLog.Name = 'PC_v7.1-' + PC_Constants.EMPTY_STRING + String.valueOf(DateTime.now()) + PC_Constants.LOG_FORMAT;
            processLog.Type = TXT_KEY;
            processLog.folderid = UserInfo.getUserId();

            
            processLogContent += 'Initiating migration of PC Patient and Physician Accounts... \n';
            
            String PC_NAMESPACE = PC_Constants.OrgNamespace;
            String PC_PATIENT_RECORD_TYPE = PC_Constants.PATIENT_RECORD_TYPE;
            String PC_PHYSICIAN_RECORD_TYPE = PC_Constants.PHYSICIAN_RECORD_TYPE;

            Id contactIndividualRecordTypeId = PC_System.recordTypeId(PC_Constants.CONTACT, PC_Constants.CONTACT_INDIVIDUAL_RECORD_TYPE);

            List<RecordType> pcPatientRecordTypes =
                [SELECT ID FROM RecordType WHERE DeveloperName=:PC_PATIENT_RECORD_TYPE 
                 AND NamespacePrefix=:PC_NAMESPACE AND IsActive = TRUE AND SobjectType = 'Account'];

            List<RecordType> pcPhysicianRecordTypes = [
                    SELECT ID
                    FROM RecordType
                    WHERE DeveloperName = :PC_PHYSICIAN_RECORD_TYPE
                    AND NamespacePrefix = :PC_NAMESPACE AND IsActive = TRUE AND SobjectType = 'Account'
            ];
            
            if((pcPatientRecordTypes != null && pcPatientRecordTypes.size() == 1) &&
                    (pcPhysicianRecordTypes!= null && pcPhysicianRecordTypes.size() == 1)) {
                if(PC_System.isHealthCloudIndividualRecordType(PC_NAMESPACE, PC_PATIENT_RECORD_TYPE)) {
                    processLogContent += 'PC_Patient record type is configured in HC Individual Mapper. Please remove the config and try again.\n';
                    processLogContent += 'No accounts will be migrated.\n';
                }
                else {
                    String pcPhysicianRecordTypeId = pcPhysicianRecordTypes[0].ID;

                    String pcPatientRecordTypeId = pcPatientRecordTypes[0].ID;
                    String dobQualifieldName = PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c');
                    String genderQualifiedName = PC_Constants.getQualifiedAPIName('PC_Gender__c');
                    String firstNameQualifieldName = PC_Constants.getQualifiedAPIName('PC_First_Name__c');
                    String lastNameQualifieldName = PC_Constants.getQualifiedAPIName('PC_Last_Name__c');
                    String emailQualifiedName = PC_Constants.getQualifiedAPIName('PC_Email__c');
                    String salutationQualifieldName = PC_Constants.getQualifiedAPIName('PC_Salutation__c');
                    queryLocator = Database.getQueryLocator(
                            ' SELECT ID, Name, RecordTypeId, ' +
                                    dobQualifieldName + ', ' +
                                    genderQualifiedName + ', ' +
                                    firstNameQualifieldName + ', ' +
                                    lastNameQualifieldName + ', ' +
                                    emailQualifiedName + ', ' +
                                    salutationQualifieldName + ', ' +
                                    ' CreatedDate, Fax, Phone, ' +
                                    ' HealthCloudGA__IndividualId__c, HealthCloudGA__SourceSystem__c ' +
                                    ' FROM Account WHERE (RecordTypeId =:pcPatientRecordTypeId ' +
                                    ' AND ' +
                                    ' (' +
                                        ' HealthCloudGA__IndividualId__c = NULL' +
                                        ' OR' +
                                        ' (HealthCloudGA__IndividualId__c != NULL AND HealthCloudGA__PrimaryContact__r.RecordTypeId =:contactIndividualRecordTypeId) ' +
                                    ' )) ' +
                                    ' OR RecordTypeId =:pcPhysicianRecordTypeId '
                                    //+ ' AND HealthCloudGA__IndividualId__c = null'
                    );
                    return queryLocator;
                    /*if(queryLocator != null && queryLocator.iterator().hasNext()) {
                        hasRecords = true;
                    }*/

                }
            }
            else {
                processLogContent += 'PC_Patient/PC_Physician record type is either not active or not found. Please activate and try again.\n';
                processLogContent += 'No accounts will be migrated.\n';
            }
            processLog.Body = Blob.valueOf(processLogContent);
            upsert processLog;
            sendEmail(processLog);
            mailSent = true;
            /*if(!hasRecords) {
                // send out email since batch log won't go into the execute and finalize stages.
                processLog.Body = Blob.valueOf(processLogContent);
                UpdateException ue = new UpdateException();
                ue.setMessage(processLogContent);
                PC_Utility.publishAndThrowException(ue, processLogContent);
                //upsert processLog;
            }
            system.debug('vj+');
            system.debug(hasRecords);
            system.debug(queryLocator.iterator().hasNext());
            return queryLocator;*/
        }
        catch(Exception ex) {
            processLogContent += ex.getMessage();
            PC_Utility.publishAndThrowException(ex, ex.getMessage() + '\n' + processLogContent);
        }
        finally {
            //Savepoint sp = Database.setSavepoint();
            //sendEmail(processLog);
        }
        return Database.getQueryLocator('SELECT ID FROM Account LIMIT 0');
    }


    /**
    * Implements Database.Batchable method
    */
    global void execute(Database.BatchableContext bc, List<Account> scope){
        Document batchLog = new Document();
        String batchLogContent = PC_Constants.EMPTY_STRING;
        batchLog.Name = 'PC_v7.1-Batch-' + PC_Constants.EMPTY_STRING + String.valueOf(DateTime.now()) + PC_Constants.LOG_FORMAT;
        batchLog.Type = TXT_KEY;
        batchLog.folderid = UserInfo.getUserId();
        Integer totalRecordsInThisBatch = 0;
        Integer totalRecordsProcessedInThisBatch = 0;
        List<ID> validAccountsWithOneContactInThisBatch = new List<ID>();
    	List<ID> invalidAccountsWithNoContactInThisBatch = new List<ID>();
    	List<ID> invalidAccountsWithMultipleContactsInThisBatch = new List<ID>();
        List<ID> invalidAccountsWithPCPatientAsPrimaryContactInThisBatch = new List<ID>();
        List<ID> invalidAccountsWithInvalidPrimaryContactInThisBatch = new List<ID>();

        List<ID> validPhyAccountsWithOneContactInThisBatch = new List<ID>();
        List<ID> invalidPhyAccountsWithNoContactInThisBatch = new List<ID>();
        List<ID> invalidPhyAccountsWithMultipleContactsInThisBatch = new List<ID>();
        List<ID> invalidPhyAccountsWithPCPhysicianAsPrimaryContactInThisBatch = new List<ID>();
        List<ID> invalidPhyAccountsWithInvalidPrimaryContactInThisBatch = new List<ID>();
    
        Boolean isError = false;
        try 
        {
        
            system.debug('in execute');            
            // process each batch of records
            String SOURCE_SYSTEM_PREFIX = 'Health1-'; // todo - do we pull this from some setting. Ensure new patient individuals that get created in your org have this prefix for the source system. Otherwise, change it to new value.
            String orgId = [SELECT Id, Name FROM Organization LIMIT 1].Id;
            String SOURCE_SYSTEM = SOURCE_SYSTEM_PREFIX + orgId.substring(0,orgId.length()-3);
            
            List<Account> accounts = new List<Account>();
            List<Contact> contacts = new List<Contact>();
            
            String accountIndividualId;
            String contactIndividualId;
            
            system.debug('executing ' + scope.size() + ' records');

            Id contactIndividualRecordTypeId = PC_System.recordTypeId(PC_Constants.CONTACT, PC_Constants.CONTACT_INDIVIDUAL_RECORD_TYPE);
            Id contactPatientRecordTypeId = PC_SYSTEM.recordTypeId('Contact',PC_Constants.CONTACT_PATIENT_RECORD_TYPE);
            Id contactPhysicianRecordTypeId = PC_SYSTEM.recordTypeId('Contact',PC_Constants.CONTACT_PHYSICIAN_RECORD_TYPE);
            Id accountPatientRecordTypeId = PC_SYSTEM.recordTypeId('Account',PC_Constants.PATIENT_RECORD_TYPE);

            Map<Id, List<Contact>> contactsByAccountId = getContactsByAccountId(scope);
            List<Contact> accountContacts;
            for (Account account : scope) {                
                accountContacts = contactsByAccountId.get(account.Id);
                if(account.RecordTypeId == accountPatientRecordTypeId) {
                    if (accountContacts == null || accountContacts.size() == 0) {
                        // account without contact
                        invalidAccountsWithNoContactInThisBatch.add(account.Id);

                        system.debug('Ignored patient record --> ' + account.Id + ' since it has no contact');
                        batchLogContent += account.Id + ', Ignored patient record --> ' + account.Id + ' since it has no contact' + '\n';
                    } else if (accountContacts.size() == 1) {
                        // account with only one contact. Valid scenario.
                        // todo remove this account from other invalid lists
                        validAccountsWithOneContactInThisBatch.add(account.Id);
                        Contact primaryContact = accountContacts[0];
                        if (primaryContact.RecordTypeId == contactPatientRecordTypeId && String.isNotBlank(account.HealthCloudGA__IndividualId__c)) {
                            // nothing to do.
                            invalidAccountsWithPCPatientAsPrimaryContactInThisBatch.add(account.Id);

                            system.debug('Skipped patient record --> ' + account.Id + ' since it is already linked to PC_Patient contact record.');
                            batchLogContent += account.Id + ', Skipped patient record --> ' + account.Id + ' since it is already linked to PC_Patient contact record.' + '\n';
                        } else if ((primaryContact.RecordTypeId == contactPatientRecordTypeId && String.isBlank(account.HealthCloudGA__IndividualId__c)) ||
                                primaryContact.RecordTypeId == contactIndividualRecordTypeId) {
                            validAccountsWithOneContactInThisBatch.add(account.Id);
                            accountIndividualId = account.ID + '' + account.CreatedDate.getTime();

                            account.HealthCloudGA__IndividualId__c =
                                    String.isBlank(account.HealthCloudGA__IndividualId__c) ? accountIndividualId : account.HealthCloudGA__IndividualId__c;
                            account.HealthCloudGA__SourceSystem__c =
                                    String.isBlank(account.HealthCloudGA__SourceSystem__c) ? SOURCE_SYSTEM : account.HealthCloudGA__SourceSystem__c;
                            account.HealthCloudGA__IndividualType__c = 'Individual'; // let's overwrite since we want it to be 'Individual'
                            account.HealthCloudGA__PrimaryContact__c = primaryContact.Id; // let's set this since it is the only contact.

                            accounts.add(account);

                            system.debug('Queued patient record --> ' + account.Id + ' to migrate and link it with contact ' + primaryContact.Id);
                            batchLogContent += account.Id + ', Queued patient record --> ' + account.Id + ' to migrate and link it with contact ' + primaryContact.Id + '\n';

                            contactIndividualId = accountIndividualId;

                            //primaryContact.HealthCloudGA__IndividualId__c = contactIndividualId; // This is not writeable
                            primaryContact.HealthCloudGA__SourceSystem__c =
                                    String.isBlank(primaryContact.HealthCloudGA__SourceSystem__c) ? SOURCE_SYSTEM : primaryContact.HealthCloudGA__SourceSystem__c;
                            primaryContact.HealthCloudGA__IndividualType__c = 'Individual'; // let's overwrite since we want it to be 'Individual'
                            primaryContact.RecordTypeId = contactPatientRecordTypeId;
                            primaryContact.AccountId = account.ID;
                            if (String.isBlank(primaryContact.Phone)) {
                                primaryContact.Phone = account.Phone;
                            }
                            if (String.isBlank(primaryContact.Title)) {
                                primaryContact.Title = account.PC_Salutation__c;
                            }
                            if (String.isBlank(primaryContact.Fax)) {
                                primaryContact.Fax = account.Fax;
                            }
                            if (String.isBlank(primaryContact.Email)) {
                                primaryContact.Email = account.PC_Email__c;
                            }
                            /*if(primaryContact.FirstName == null) {
                            primaryContact.FirstName = account.PC_First_Name__c;
                        }
                        if(primaryContact.LastName == null) {
                            primaryContact.LastName = account.PC_Last_Name__c;
                        }*/ // Let's not set first name and last name as setting this makes the contact name hunky dory.
                            if (primaryContact.Birthdate == null) {
                                primaryContact.Birthdate = account.PC_Date_of_Birth__c;
                            }
                            if (String.isBlank(primaryContact.HealthCloudGA__Gender__c)) {
                                primaryContact.HealthCloudGA__Gender__c = account.PC_Gender__c;
                            }

                            contacts.add(primaryContact);

                            totalRecordsProcessed = totalRecordsProcessed + 1;
                            totalRecordsProcessedInThisBatch = totalRecordsProcessedInThisBatch + 1;
                        } else {
                            invalidAccountsWithInvalidPrimaryContactInThisBatch.add(account.Id);

                            system.debug('Ignored patient record --> ' + account.Id + ' since primary contact record type is not Individual(Patient Connect)');
                            batchLogContent += account.Id + ', Ignored patient record --> ' + account.Id + ' since primary contact record type is not Individual(Patient Connect)' + '\n';
                        }
                    } else {
                        // account with more than one contact. // Invalid
                        invalidAccountsWithMultipleContactsInThisBatch.add(account.Id);

                        system.debug('Ignored patient record --> ' + account.Id + ' since it has multiple contacts');
                        batchLogContent += account.Id + ', Ignored patient record --> ' + account.Id + ' since it has multiple contacts' + '\n';
                    }
                }
                else {
                    if (accountContacts == null || accountContacts.size() == 0) {
                        // account without contact
                        invalidPhyAccountsWithNoContactInThisBatch.add(account.Id);

                        system.debug('Ignored physician record --> ' + account.Id + ' since it has no contact');
                        batchLogContent += account.Id + ', Ignored physician record --> ' + account.Id + ' since it has no contact' + '\n';
                    } else if (accountContacts.size() == 1) {
                        // account with only one contact. Valid scenario.
                        // todo remove this account from other invalid lists
                        validPhyAccountsWithOneContactInThisBatch.add(account.Id);
                        Contact primaryContact = accountContacts[0];
                        if (primaryContact.RecordTypeId == contactPhysicianRecordTypeId) {
                            // nothing to do.
                            invalidPhyAccountsWithPCPhysicianAsPrimaryContactInThisBatch.add(account.Id);

                            system.debug('Skipped physician record --> ' + account.Id + ' since it is already linked to PC_Physician contact record.');
                            batchLogContent += account.Id + ', Skipped physician record --> ' + account.Id + ' since it is already linked to PC_Physician contact record.' + '\n';
                        } else if (primaryContact.RecordTypeId == contactIndividualRecordTypeId) {
                            validAccountsWithOneContactInThisBatch.add(account.Id);

                            system.debug('Queued physician record --> ' + account.Id + ' to migrate and link it with contact ' + primaryContact.Id);
                            batchLogContent += account.Id + ', Queued physician record --> ' + account.Id + ' to migrate and link it with contact ' + primaryContact.Id + '\n';

                            primaryContact.RecordTypeId = contactPhysicianRecordTypeId;

                            contacts.add(primaryContact);

                            totalRecordsProcessed = totalRecordsProcessed + 1;
                            totalRecordsProcessedInThisBatch = totalRecordsProcessedInThisBatch + 1;
                        } else {
                            invalidPhyAccountsWithInvalidPrimaryContactInThisBatch.add(account.Id);

                            system.debug('Ignored physician record --> ' + account.Id + ' since primary contact record type is not Individual(Patient Connect)');
                            batchLogContent += account.Id + ', Ignored physician record --> ' + account.Id + ' since primary contact record type is not Individual(Patient Connect)' + '\n';
                        }
                    } else {
                        // account with more than one contact. // Invalid
                        invalidPhyAccountsWithMultipleContactsInThisBatch.add(account.Id);

                        system.debug('Ignored physician record --> ' + account.Id + ' since it has multiple contacts');
                        batchLogContent += account.Id + ', Ignored physician record --> ' + account.Id + ' since it has multiple contacts' + '\n';
                    }
                }
                totalRecordsInThisBatch = totalRecordsInThisBatch + 1;
            	totalRecords = totalRecords + 1;                
            }
            batchLogContent += 'Updating the queued records.\n';



            if( (accounts != null) && !accounts.isEmpty() ) {
                update accounts;
            }

            if( (contacts !=null) && !contacts.isEmpty() ) {
                update contacts;
            }
            batchLogContent += 'Updated the queued records.\n';
        }
        catch(Exception ex) {
            isError = true; 
            batchLogContent += '\nException Message,' + ex.getMessage();
            batchLogContent += '\nException StackTrace,' + ex.getStackTraceString();
            batchLogContent += '\nException LineNumber' + ex.getLineNumber();
            batchLogContent += '\nException Cause' + ex.getCause();
            PC_Utility.publishErrorLog(ex, ex.getMessage());
            totalRecords = totalRecords - totalRecordsInThisBatch; // Should not be done? since totalRecords should include all accounts
            totalRecordsProcessed = totalRecordsProcessed - totalRecordsProcessedInThisBatch; 
            invalidAccountsWithNoContactInThisBatch = new List<ID>();
            validAccountsWithOneContactInThisBatch = new List<ID>();
            invalidAccountsWithMultipleContactsInThisBatch = new List<ID>();
            invalidAccountsWithInvalidPrimaryContact = new List<ID>();
            invalidAccountsWithPCPatientAsPrimaryContact = new List<ID>();

            invalidPhyAccountsWithNoContactInThisBatch = new List<ID>();
            validPhyAccountsWithOneContactInThisBatch = new List<ID>();
            invalidPhyAccountsWithMultipleContactsInThisBatch = new List<ID>();
            invalidPhyAccountsWithInvalidPrimaryContact = new List<ID>();
            invalidPhyAccountsWithPCPhysicianAsPrimaryContact = new List<ID>();
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
            invalidAccountsWithNoContact.addAll(invalidAccountsWithNoContactInThisBatch);
            invalidAccountsWithMultipleContacts.addAll(invalidAccountsWithMultipleContactsInThisBatch);
            validAccountsWithOneContact.addAll(validAccountsWithOneContactInThisBatch);
            invalidAccountsWithPCPatientAsPrimaryContact.addAll(invalidAccountsWithPCPatientAsPrimaryContactInThisBatch);
            invalidAccountsWithInvalidPrimaryContact.addAll(invalidAccountsWithInvalidPrimaryContactInThisBatch);

            invalidPhyAccountsWithNoContact.addAll(invalidPhyAccountsWithNoContactInThisBatch);
            invalidPhyAccountsWithMultipleContacts.addAll(invalidPhyAccountsWithMultipleContactsInThisBatch);
            validPhyAccountsWithOneContact.addAll(validPhyAccountsWithOneContactInThisBatch);
            invalidPhyAccountsWithPCPhysicianAsPrimaryContact.addAll(invalidPhyAccountsWithPCPhysicianAsPrimaryContactInThisBatch);
            invalidPhyAccountsWithInvalidPrimaryContact.addAll(invalidPhyAccountsWithInvalidPrimaryContactInThisBatch);
        }
    }
    /**
    * Implements Database.Batchable method
    */
    global void finish(Database.BatchableContext bc){
        try {
            if(!mailSent) {
                system.debug('in finish');
                processLogContent += 'Total records that needed migration (Excluding Records in any failed batches) : ' + totalRecords + '\n';
                processLogContent += 'Total records that were migrated : ' + totalRecordsProcessed + '\n';
                if (invalidAccountsWithNoContact.size() > 0) {
                    processLogContent += 'Invalid patient accounts with no contact that were ignored : ' + invalidAccountsWithNoContact.size() + '\n';
                }
                if (invalidAccountsWithMultipleContacts.size() > 0) {
                    processLogContent += 'Invalid patient accounts with multiple contacts that were ignored : ' + invalidAccountsWithMultipleContacts.size() + '\n';
                }
                if (invalidAccountsWithPCPatientAsPrimaryContact.size() > 0) {
                    processLogContent += 'Accounts with PC_Patient as its primary contact that do not need migration : ' + invalidAccountsWithPCPatientAsPrimaryContact.size() + '\n';
                }
                if (invalidAccountsWithInvalidPrimaryContact.size() > 0) {
                    processLogContent += 'Invalid patient accounts having other than Individual(Patient Connect) primary contact that were ignored : ' + invalidAccountsWithInvalidPrimaryContact.size() + '\n';
                }

                if (invalidPhyAccountsWithNoContact.size() > 0) {
                    processLogContent += 'Invalid physician accounts with no contact that were ignored : ' + invalidPhyAccountsWithNoContact.size() + '\n';
                }
                if (invalidPhyAccountsWithMultipleContacts.size() > 0) {
                    processLogContent += 'Invalid physician accounts with multiple contacts that were ignored : ' + invalidPhyAccountsWithMultipleContacts.size() + '\n';
                }
                if (invalidPhyAccountsWithPCPhysicianAsPrimaryContact.size() > 0) {
                    processLogContent += 'Account physicians with PC_Physician as its primary contact that do not need migration : ' + invalidPhyAccountsWithPCPhysicianAsPrimaryContact.size() + '\n';
                }
                if (invalidPhyAccountsWithInvalidPrimaryContact.size() > 0) {
                    processLogContent += 'Invalid physician accounts having other than Individual(Patient Connect) primary contact that were ignored : ' + invalidPhyAccountsWithInvalidPrimaryContact.size() + '\n';
                }

                // we do not want to log validAccountsWithOneContact since run time exceptions while updating can not be rules out. Giving
                // this info will lead to confusion when runtime exceptions are encountered.

                if (failedBatchLogIds.size() > 0) {
                    processLogContent += 'Following batches need your attention since the transactions part of these were rolled back - ' + failedBatchLogIds;
                }

                //processLogContent += 'refer to these logs - ' + allBatchLogIds;
                System.debug(totalRecordsProcessed + ' records processed. Shazam!');
                system.debug('invalidAccountsWithNoContact-> ' + invalidAccountsWithNoContact);
                system.debug('invalidAccountsWithMultipleContacts-> ' + invalidAccountsWithMultipleContacts);
                system.debug('validAccountsWithOneContact-> ' + validAccountsWithOneContact);
                system.debug('invalidAccountsWithPCPatientAsPrimaryContact-> ' + invalidAccountsWithPCPatientAsPrimaryContact);
                system.debug('invalidAccountsWithInvalidPrimaryContact-> ' + invalidAccountsWithInvalidPrimaryContact);

                system.debug('invalidPhyAccountsWithNoContact-> ' + invalidPhyAccountsWithNoContact);
                system.debug('invalidPhyAccountsWithMultipleContacts-> ' + invalidPhyAccountsWithMultipleContacts);
                system.debug('validPhyAccountsWithOneContact-> ' + validPhyAccountsWithOneContact);
                system.debug('invalidPhyAccountsWithPCPhysicianAsPrimaryContact-> ' + invalidPhyAccountsWithPCPhysicianAsPrimaryContact);
                system.debug('invalidPhyAccountsWithInvalidPrimaryContact-> ' + invalidPhyAccountsWithInvalidPrimaryContact);


                AsyncApexJob job = [
                        SELECT Id, Status, NumberOfErrors,
                                JobItemsProcessed,
                                TotalJobItems, CreatedBy.Email
                        FROM AsyncApexJob
                        WHERE Id = :bc.getJobId()
                ];
                processLogContent += '\nMigration Process over. Logs are placed in your Personal Document Folder of Document Object\n';
                processLogContent += '\nJob Id - ' + bc.getJobId();
                processLogContent += '\nBatch Files - ' + String.join(allBatchLogIds, ',');
                processLog.Body = Blob.valueOf(processLogContent);
                upsert processLog;

                sendEmail(processLog);
                // call some utility to send email
                //EmailUtils.sendMessage(a, totalRecordsProcessed);
            }
        }
        catch(Exception ex) {
            PC_Utility.publishAndThrowException(ex, ex.getMessage());
        }
    }

    private static Map<Id, List<Contact>> getContactsByAccountId(List<Account> scope) {
        Map<Id, List<Contact>> contactsByAccountId = new Map<Id, List<Contact>>();
        Set<Id> accountIds = new Set<Id>();
        for(Account acc : scope) {
            accountIds.add(acc.Id);
        }


        Map<Id, Account> accountsById = new Map<Id, Account>(
            [
                    SELECT (
                            SELECT ID, CreatedDate, BirthDate, AccountId,
                                    HealthCloudGA__Gender__c, HealthCloudGA__SourceSystem__c, Title,
                                    FirstName, LastName, RecordTypeId, Email, Fax, Phone
                            FROM Contacts LIMIT 2
                    )
                    FROM Account
                    WHERE Id = :accountIds
            ]
        );
        // limit clause in the above SOQL is added to improve the performance of the SOQL
        for(Id accountId : accountsById.keySet()) {
            contactsByAccountId.put(accountId, accountsById.get(accountId).Contacts);
        }

        /*List<Contact> contacts = [
                SELECT ID, CreatedDate, BirthDate, AccountId,
                        HealthCloudGA__Gender__c, HealthCloudGA__SourceSystem__c, Title,
                        FirstName, LastName, RecordTypeId, Email, Fax, Phone
                FROM Contacts WHERE AccountId IN :accountIds
        ];
        for(Contact _contact : contacts) {
            if(contactsByAccountId.containsKey(contacts.AccountId)) {
                List<Contact> existingContacts = contactsByAccountId.get(contacts.AccountId);
                existingContacts.add(_contact);
                contactsByAccountId.remove(_contact.AccountId);
                contactsByAccountId.put(_contact.AccountId, existingContacts);
            }
            else {
                contactsByAccountId.put(_contact.AccountId, new List<Contact>[_contact]);
            }
        }*/
        return contactsByAccountId;

    }
    private static void sendEmail(Document processLog) {
        List<Messaging.EmailfileAttachment> fileAttachments = new List<Messaging.EmailfileAttachment>();
        Messaging.Emailfileattachment efa;

        efa = new Messaging.Emailfileattachment();
        efa.setFileName(processLog.Name);
        efa.setBody(processLog.Body);
        fileAttachments.add(efa);

        /*for(Document d : [SELECT Name, Body FROM Document WHERE ID IN :allBatchLogIds]) {
            efa = new Messaging.Emailfileattachment();
            efa.setFileName(d.Name);
            efa.setBody(d.Body);
            fileAttachments.add(efa);
        }*/

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject('Patient Connect Migration Logs');
        email.setPlainTextBody('Migration logs attached');
        email.setToAddresses(new String[] {UserInfo.getUserEmail()});
        email.setFileAttachments(fileAttachments);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
    private static void appendlog(String logString) {
        logString += logString;
        system.debug(logString);
    }
    
    
}