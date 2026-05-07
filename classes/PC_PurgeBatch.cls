/**
 * Created by vkashikar on 6/28/2021.
 */

/**
 * Generic batch job that deletes records as per the given query.
 */
global with sharing class PC_PurgeBatch implements Database.Batchable<sObject>, Database.Stateful {
    private String query;
    private String countQuery;
    private Boolean emptyRecycleBin;
    private Boolean emailSummaryLogToAllAdmins;
    private String logFileName;

    private List<String> summaryLogs = new List<String>();
    private Boolean anyExceptionsFound = false;

    private static final String TXT_KEY = 'txt';
    global Document summaryLogDocument = new Document();

    private Integer batchCounter = 0;
    private static final String BATCH_JOB_NAME = 'PC_PurgeBatch';

    /**
     * Constructor to set the initialization properties.
     * @param parameters input parameters required to initialize the batch job.
     */
    global PC_PurgeBatch(Parameters parameters) {
        summaryLogs.add('Initiating Purge Job');

        summaryLogs.add('\n');

        summaryLogs.add('Parameters Received...');
        summaryLogs.add('\t' + 'query = ' + parameters.scopeQuery);
        summaryLogs.add('\t' + 'emptyRecycleBin = ' + parameters.emptyRecycleBin);
        summaryLogs.add('\t' + 'sendSummaryEmailToAllAdmins = ' + parameters.sendSummaryEmailToAllAdmins);
        summaryLogs.add('\t' + 'logFileName = ' + parameters.logFileName);
        summaryLogs.add('\t' + 'countQuery = ' + parameters.scopeCountQuery);

        summaryLogs.add('\n');

        this.query = parameters.scopeQuery;
        this.emptyRecycleBin = parameters.emptyRecycleBin;
        this.emailSummaryLogToAllAdmins = parameters.sendSummaryEmailToAllAdmins;
        this.logFileName = String.isBlank(parameters.logFileName) ? 'PC_Purge' : parameters.logFileName;
        this.countQuery = parameters.scopeCountQuery;
    }

    /**
     * Start method of the batch job auto-called by the SF while executing a batch job
     * @param bc Database.BatchableContext having job id and child job id.
     *
     * @return Database.QueryLocator
     */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        summaryLogDocument.Name = this.logFileName + '_Summary-' + bc.getJobId() + '-' + String.valueOf(DateTime.now()) + '.txt';
        summaryLogDocument.Type = TXT_KEY;
        summaryLogDocument.folderid = PC_BatchUtility.getFolderId(BATCH_JOB_NAME);
        Database.QueryLocator queryLocator;
        try {
            summaryLogs.add('Start of Batch Job with Job Id = ' + bc.getJobId() + '.' + 'File Name = ' + summaryLogDocument.Name);
            summaryLogDocument.Type = TXT_KEY;
            queryLocator = Database.getQueryLocator(this.query);

            Integer totalRecordsCounter = Database.countQuery(countQuery);
            summaryLogs.add('Number of records to be deleted as per count query = ' + totalRecordsCounter);
        }
        catch(Exception ex) {
            anyExceptionsFound = true;

            summaryLogs.add('ATTENTION: Exception in start method of the batch.');
            updateLogWithException(summaryLogs, ex, '\t');

            summaryLogDocument.Body = Blob.valueOf(String.join(summaryLogs, '\n'));
            upsert summaryLogDocument;

            //sendEmail(summaryLogDocument);

            queryLocator = Database.getQueryLocator('SELECT ID FROM PC_Applicant__c LIMIT 0');
        }

        return queryLocator;
    }

    /**
     * Execute method of the batch job auto-called by SF while executing a batch job
     *
     * @param bc Database.BatchableContext having job id and child job id.
     * @param scope List of sObjects
     */
    global void execute(Database.BatchableContext bc, List<sObject> scope){
        batchCounter = batchCounter + 1;
        Document executeLogDocument = new Document();
        executeLogDocument.Name = this.logFileName + '_Batch' + batchCounter + '-' + bc.getChildJobId() + '-' + String.valueOf(DateTime.now()) + '.txt';
        executeLogDocument.Type = TXT_KEY;
        executeLogDocument.folderid = PC_BatchUtility.getFolderId(BATCH_JOB_NAME);

        List<String> executeLogs = new List<String>();

        Integer successCounter = 0;
        Integer failureCounter = 0;
        List<sObject> deletedScope = new List<sObject>();
        try {
            summaryLogs.add('\n');
            summaryLogs.add('Processing ' + scope.size() + ' records in child batch job -> ' + bc.getChildJobId());
            executeLogs.add('Start of Child Batch Job Id = ' + bc.getChildJobId() + '.' + 'File Name = ' + executeLogDocument.Name);

            executeLogs.add('Deleting ' + scope.size() + ' records...');
            Database.DeleteResult[] drList = Database.delete(scope, false);

            // Start: Create a map of the position of the scoped records with their Id
            Map<Id, Integer> scopePositionsByIds = new Map<Id, Integer>();
            Integer position = 0;
            for (sObject s : scope) {
                scopePositionsByIds.put(s.Id, position++);
            }
            // End: Create a map of the position of the scoped records with their Id

            for (Database.DeleteResult dr : drList) {
                if (dr.isSuccess()) {
                    deletedScope.add(scope.get(scopePositionsByIds.get(dr.getId())));
                    successCounter++;
                    executeLogs.add('Successfully deleted record with ID: ' + dr.getId());

                } else {
                    // Operation failed, so get all errors
                    for (Database.Error err : dr.getErrors()) {
                        failureCounter++;
                        executeLogs.add('Failed to delete record with ID: ' + dr.getId());
                        executeLogs.add('\t' + 'The following error has occurred.');
                        executeLogs.add('\t' + err.getStatusCode() + ': ' + err.getMessage());
                        if (err.getFields() != null) {
                            executeLogs.add('\t' + 'Fields that affected this error: ' + String.join(err.getFields(), ','));
                        }
                    }
                }
            }
            executeLogs.add('Deleted ' + successCounter + ' records successfully');
            if (failureCounter > 0) {
                anyExceptionsFound = true;
                summaryLogs.add('ATTENTION : Child Batch Job Id ' + bc.getChildJobId() + ' could not delete ' + failureCounter + ' records. Check the batch job log ' + executeLogDocument.Name + ' for more details');
                executeLogs.add('ATTENTION : Could not delete ' + failureCounter + ' records');
            }

            if (this.emptyRecycleBin && deletedScope.size() > 0) {
                executeLogs.add('Emptying Recycle Bin for the successfully deleted ' + deletedScope.size() + ' records...');
                DataBase.emptyRecycleBin(deletedScope);
                executeLogs.add('Emptied Recycle Bin successfully.');
            }
        }
        catch(Exception ex) {
            anyExceptionsFound = true;

            summaryLogs.add('ATTENTION: Exception in execute method of the batch with child job id ' + bc.getChildJobId());
            updateLogWithException(summaryLogs, ex, '\t');

            executeLogs.add('ATTENTION: Exception in the execute method');
            updateLogWithException(executeLogs, ex, '\t');
        }
        finally{
            executeLogs.add('End of Child Batch Job Id = ' + bc.getChildJobId());
            summaryLogs.add('Processed ' + deletedScope.size() + '/' + scope.size() + ' records in child batch job -> ' + bc.getChildJobId());
            summaryLogs.add('\n');
            executeLogDocument.Body = Blob.valueOf(String.join(executeLogs, '\n'));
            upsert executeLogDocument;
        }

    }
    /**
     * Finish method of the batch job auto-called by SF while executing a batch job
     *
     * @param bc Database.BatchableContext having job id and child job id.
     */
    global void finish(Database.BatchableContext bc) {
        summaryLogs.add('End of Batch Job with Job Id = ' + bc.getJobId());
        system.debug(String.join(summaryLogs, '\n'));
        summaryLogDocument.Body = Blob.valueOf(String.join(summaryLogs, '\n'));
        upsert summaryLogDocument;

        if(anyExceptionsFound || this.emailSummaryLogToAllAdmins) {
            sendEmail(summaryLogDocument, this.emailSummaryLogToAllAdmins);
        }

    }
    /**
     * Wrapper class used to pass parameters to the batch job
     */
    global Class Parameters {
        /**
         * SELECT query that should be used to get the list of sobjects that need to be deleted.
         */
        global String scopeQuery;
        /**
         * COUNT query that should be used to get the count of sobjects which need to be deleted as per the scopeQuery
         */
        global String scopeCountQuery;
        /**
         * Property to indicate if the records need to be deleted from recycle bin too after deleting
         */
        global Boolean emptyRecycleBin;
        /**
         * Property to indicate if summary email needs to be sent to all admins.
         */
        global Boolean sendSummaryEmailToAllAdmins;
        /**
         * Property to set the log file name of the batch job that is stored in the Document folder.
         */
        global String logFileName;
    }
    private static void sendEmail(Document processLog, Boolean sendToAllAdmins) {
        List<Messaging.EmailfileAttachment> fileAttachments = new List<Messaging.EmailfileAttachment>();
        Messaging.Emailfileattachment efa;

        efa = new Messaging.Emailfileattachment();
        efa.setFileName(processLog.Name);
        efa.setBody(processLog.Body);
        fileAttachments.add(efa);

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject('Patient Connect Purge Logs');
        email.setPlainTextBody('Purge logs attached for your reference');
        List<String> emailRecipients = new List<String>();
        if(sendToAllAdmins) {
            for(User u : [SELECT Email FROM User WHERE IsActive = TRUE AND Profile.Name = 'System Administrator']) {
                emailRecipients.add(u.Email);
            }
        }
        else {
            emailRecipients.add(UserInfo.getUserEmail());
        }
        email.setToAddresses(emailRecipients);
        email.setFileAttachments(fileAttachments);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
    private static void updateLogWithException(List<String> logList, Exception ex, String separator) {
        logList.add(separator + 'Exception Message -> ' + ex.getMessage());
        logList.add(separator + 'Exception Line Number -> ' + ex.getLineNumber());
        logList.add(separator + 'Exception Cause -> ' + ex.getCause());
        logList.add(separator + 'Exception Stack Trace -> ' + ex.getStackTraceString());
        logList.add(separator + 'Exception Type -> ' + ex.getTypeName());
    }
}