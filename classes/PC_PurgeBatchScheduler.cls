/**
 * Created by vkashikar on 6/30/2021.
 */

/**
 * Scheduler batch job to schedule PC_PurgeBatch as per the settings in PC_PurgeBatchScope of Patient Connect Setting.
 */
global with sharing class PC_PurgeBatchScheduler implements Schedulable {
    private final static String SETTING_NAME = 'PC_PurgeBatchSetting';
    private static String CONFIGURED_SETTING_VALUE = PC_System.getPatientConnectSetting(SETTING_NAME, '');
    private static String EXAMPLE_SETTING = '{"scope":[{"context":"SPAL_RO","offset":365},{"context":"SPAL_NRO","offset":365},{"context":"ERR","offset":365},{"context": "MSG_TWL","offset":365},{"context":"RSL","offset":365},{"context":"RQ","offset":365}],"emptyRecycleBin":true}';
    private static Datetime dateTimeNow = datetime.now();

    /**
     * Execute method that is auto-called by SF while scheduling the batch job.
     * This method schedules as per the settings in PC_PurgeBatchSetting & PC_BatchJobProperties of Patient Connect Settings
     * For each context set in PC_PurgeBatchSetting, the PC_PurgeBatch is executed.
     * For any invalid setting, InvalidSettingsException is thrown.
     * @param sc SchedulableContext having trigger id.
     */
    global void execute(SchedulableContext sc) {
        final String BATCH_JOB_NAME = 'PC_PurgeBatch';
        Setting setting = getSetting(CONFIGURED_SETTING_VALUE);
        PC_BatchUtility.BatchJobProperties batchProperties = PC_BatchUtility.getBatchJobSetting(BATCH_JOB_NAME);
        for(ContextSetting contextSetting : setting.scope) {
            String contextName = contextSetting.context;
            Integer offset = contextSetting.offset;
            PC_PurgeBatch.Parameters batchParameters = getBatchParameters(contextSetting, batchProperties.notifyAllAdmins, setting.emptyRecycleBin);
            system.debug(batchParameters);
            PC_PurgeBatch batch = new PC_PurgeBatch(batchParameters);
            Id batchId = Database.executeBatch(batch, batchProperties.size);
        }
    }

    private static PC_PurgeBatch.Parameters getBatchParameters(ContextSetting contextSetting, Boolean notifyAllAdmins, Boolean emptyRecycleBin) {
        PC_PurgeBatch.Parameters parameters = new PC_PurgeBatch.Parameters();
        parameters.emptyRecycleBin = emptyRecycleBin;
        parameters.sendSummaryEmailToAllAdmins = notifyAllAdmins;
        parameters.scopeQuery = getQuery(contextSetting);
        parameters.scopeCountQuery = getCountQuery(contextSetting);
        parameters.logFileName = 'PC_PurgeJob_' + contextSetting.context;
        return parameters;
    }

    public static Setting getSetting(String settingString) {
        Setting setting = new Setting();
        system.debug('***');
        system.debug(settingString);
        if(String.isNotBlank(settingString)) {
            setting = (Setting) JSON.deserialize(settingString, Setting.class);
        }
        if(setting == null || setting.scope == null || setting.scope.isEmpty()) {
            throw new InvalidSettingsException('Invalid Setting - Ensure that the Settings are in the format - ' + EXAMPLE_SETTING);
        }
        return setting;
    }

    private static String getQuery(ContextSetting contextSetting) {
        String c = contextSetting.context;
        Integer modifiedDateOffsetInDays = contextSetting.offset;
        String query = '';
        String limitDatetime = dateTimeNow.addDays(-1*modifiedDateOffsetInDays).format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        if(c == 'SPAL_RO') {
            query =
                    ' SELECT Id ' + ' FROM PC_SupportPlanActivityLog__c ' +
                            ' WHERE ' +
                            ' LastModifiedDate <= ' + limitDatetime + ' ' +
                            ' AND ' +
                            ' isDeleted = false ' +
                            ' AND ' +
                            ' PC_SupportPlanActivity__r.PC_SupportPlan__r.PC_SupportPlan_Behavior__c = \'RunOncePerRecord\' ' +
                            ' AND ' +
                            ' ( ' +
                            ' PC_SupportPlanRuntime__r.PC_CurrentActivityStatus__c = \'Completed\' ' +
                            ' OR ' +
                            ' PC_SupportPlanRuntime__r.PC_Current_Group_Status__c = \'Completed\' ' +
                            ' ) ' +
                            ' ORDER BY LastModifiedDate ASC ';
        }
        else if(c == 'SPAL_NRO') {
            query =
                    ' SELECT Id ' +
                    ' FROM PC_SupportPlanActivityLog__c ' +
                    ' WHERE ' +
                    ' LastModifiedDate <= ' + limitDatetime + ' ' +
                    ' AND ' +
                    ' isDeleted = false ' +
                    ' AND ' +
                    ' PC_SupportPlanActivity__r.PC_SupportPlan__r.PC_SupportPlan_Behavior__c != \'RunOncePerRecord\'' +
                    ' AND ' +
                    ' ( ' +
                            ' PC_SupportPlanRuntime__r.PC_CurrentActivityStatus__c = \'Completed\'' +
                            ' OR ' +
                            ' PC_SupportPlanRuntime__r.PC_Current_Group_Status__c = \'Completed\'' +
                    ' ) ' +
                    ' ORDER BY LastModifiedDate ASC ';
        }
        else if(c == 'ERR') {
            query =
                    ' SELECT Id ' +
                    ' FROM PC_Error_Log__c ' +
                    ' WHERE ' +
                    ' LastModifiedDate <= ' + limitDatetime + ' ' +
                    ' AND ' +
                    ' isDeleted = false ' +
                    ' ORDER BY LastModifiedDate ASC ';
        }
        else if(c == 'MSG_TWL') {
            query =
                    ' SELECT Id ' +
                    ' FROM PC_Message__c ' +
                    ' WHERE ' +
                    ' LastModifiedDate <= ' + limitDatetime + ' ' +
                    ' AND ' +
                    ' isDeleted = false ' +
                    ' AND ' +
                    ' PC_Type__c = \'Outbound\'' +
                    ' AND ' +
                    ' PC_Source_Type__c=\'SMS\'' +
                    ' AND ' +
                    ' (PC_Message_Status__c = \'Delivered\' OR PC_Message_Status__c = \'Undelivered\')' +
                    ' AND ' +
                    ' PC_SMSVendorName__c = \'Twilio\'' +
                    ' ORDER BY LastModifiedDate ASC ';
        }
        else if(c == 'RSL') {
            query =
                    ' SELECT Id ' +
                    ' FROM PC_Remote_Service_Log__c ' +
                    ' WHERE ' +
                    ' LastModifiedDate <= ' + limitDatetime + ' ' +
                    ' AND ' +
                    ' isDeleted = false ' +
                    ' ORDER BY LastModifiedDate ASC ';
        }
        else if(c == 'RQ') {
            query =
                    'SELECT ID ' +
                            ' FROM PC_ReminderQueue__c ' +
                            ' WHERE ' +
                            ' LastModifiedDate <= ' + limitDatetime + ' ' +
                            ' AND ' +
                            ' isDeleted = false ' +
                            ' AND ' +
                            ' (PC_Active__c = FALSE OR PC_AllRemindersSent__c = TRUE) ' +
                            ' ORDER BY LastModifiedDate ASC ';
        }
        return query;
    }
    private static String getCountQuery(ContextSetting contextSetting) {
        String c = contextSetting.context;
        Integer modifiedDateOffsetInDays = contextSetting.offset;
        String query = '';
        String limitDatetime = dateTimeNow.addDays(-1*modifiedDateOffsetInDays).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        if(c == 'SPAL_RO') {
            query =
                    ' SELECT COUNT() ' + ' FROM PC_SupportPlanActivityLog__c ' +
                            ' WHERE ' +
                            ' LastModifiedDate <= ' + limitDatetime + ' ' +
                            ' AND ' +
                            ' isDeleted = false ' +
                            ' AND ' +
                            ' PC_SupportPlanActivity__r.PC_SupportPlan__r.PC_SupportPlan_Behavior__c = \'RunOncePerRecord\' ' +
                            ' AND ' +
                            ' ( ' +
                            ' PC_SupportPlanRuntime__r.PC_CurrentActivityStatus__c = \'Completed\' ' +
                            ' OR ' +
                            ' PC_SupportPlanRuntime__r.PC_Current_Group_Status__c = \'Completed\' ' +
                            ' ) ';
        }
        else if(c == 'SPAL_NRO') {
            query =
                    ' SELECT COUNT() ' +
                            ' FROM PC_SupportPlanActivityLog__c ' +
                            ' WHERE ' +
                            ' LastModifiedDate <= ' + limitDatetime + ' ' +
                            ' AND ' +
                            ' isDeleted = false ' +
                            ' AND ' +
                            ' PC_SupportPlanActivity__r.PC_SupportPlan__r.PC_SupportPlan_Behavior__c != \'RunOncePerRecord\'' +
                            ' AND ' +
                            ' ( ' +
                            ' PC_SupportPlanRuntime__r.PC_CurrentActivityStatus__c = \'Completed\'' +
                            ' OR ' +
                            ' PC_SupportPlanRuntime__r.PC_Current_Group_Status__c = \'Completed\'' +
                            ' ) ';
        }
        else if(c == 'ERR') {
            query =
                    ' SELECT COUNT() ' +
                            ' FROM PC_Error_Log__c ' +
                            ' WHERE ' +
                            ' LastModifiedDate <= ' + limitDatetime + ' ' +
                            ' AND ' +
                            ' isDeleted = false ';
        }
        else if(c == 'MSG_TWL') {
            query =
                    ' SELECT COUNT() ' +
                            ' FROM PC_Message__c ' +
                            ' WHERE ' +
                            ' LastModifiedDate <= ' + limitDatetime + ' ' +
                            ' AND ' +
                            ' isDeleted = false ' +
                            ' AND ' +
                            ' PC_Type__c = \'Outbound\'' +
                            ' AND ' +
                            ' PC_Source_Type__c=\'SMS\'' +
                            ' AND ' +
                            ' (PC_Message_Status__c = \'Delivered\' OR PC_Message_Status__c = \'Undelivered\')' +
                            ' AND ' +
                            ' PC_SMSVendorName__c = \'Twilio\'';
        }
        else if(c == 'RSL') {
            query =
                    ' SELECT COUNT() ' +
                            ' FROM PC_Remote_Service_Log__c ' +
                            ' WHERE ' +
                            ' LastModifiedDate <= ' + limitDatetime + ' ' +
                            ' AND ' +
                            ' isDeleted = false ';
        }

        else if(c == 'RQ') {
            query =
                    'SELECT COUNT() ' +
                            ' FROM PC_ReminderQueue__c ' +
                            ' WHERE ' +
                            ' LastModifiedDate <= ' + limitDatetime + ' ' +
                            ' AND ' +
                            ' isDeleted = false ' +
                            ' AND ' +
                            ' (PC_Active__c = FALSE OR PC_AllRemindersSent__c = TRUE) ';
        }
        return query;
    }

    public Class ContextSetting {
        public String context;
        public Integer offset;
    }
    public Class Setting {
        public List<ContextSetting> scope;
        public Boolean emptyRecycleBin;
    }
    global Class InvalidSettingsException extends Exception {

    }

}