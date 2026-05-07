/*************************************************************************************************************
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Deloitte               April 1, 2015              	Initial Version
Alina Balan            July 19, 2016              	Added 'createExceptionLog' method
Shabda Bhujad		   Dec 05, 	2016				Added 'logAndThrowException' method and bypass for FLS check to createExceptionLog method
Ajinkya Deshmukh	   Apr 11, 	2017				AddedcreateErrorLog() as a helper class to handle error logging
Ajinkya Deshmukh       Jun 27, 2017                 [PC-1797] createExceptionForFutureCallout method to handle exception for async operations
Mayuresh Patil         Jul 26, 2017                 Added comments for bypassing FLS check
Vijay Kashikar         Mar 29, 2018                 Added new method to get populated fields of a sObject
Vijay Kashikar         Apr 16, 2018                 [PC-2696] Added new methods to send out a platform event and/or throw exceptions.
Vijay Kashikar         Apr 16, 2018                 [PC-2722] Added getMissingInfoMessageEBV
Vijay Kashikar         Nov 20, 2018                 [PC-3649] Added hasHealthCloudPermissionSetAssigned
Mike Klumpenaar        Feb 20, 2019                 [PC-4475] Make class and subset of methods global and convert to apex doc.
Tejas Patel            Feb 26, 2019                 [PC-3886] Added createExceptionLog for DML Exceptions
Tejas Patel	           Feb 25, 2019	                [PC-4479] getClosedCaseStatus() method added to fetch closed Case Status
Xiukai Ning            Jun 24, 2019                 [PC-5002] New global error handling methods
Tushar Arora           Oct 17, 2019                 [PC-5508] Added getGroups method to fetch groups on the basis of object parameter and field parameters of Sobject
Haritha Reddy          Nov 03, 2019                 [PC-5690] Added New Method to get the namespace of the client org
Chetna Mohapatra       Jun 10, 2020                 [PC-5948] Added new method isValidFieldset() for respective object fieldset validation.
Kanteti Kishore       Jun 16, 2020                 [PC-6143] Added new method removeSystemFields() for removing system fields whose values cannot be overwritten.
Haritha Reddy          Jun 23, 2020                 [PC-6453] Added new method parseDatetimeFromJSON() for parsing JSON Date Time to DateTime Type.
Haritha Reddy          Jul 30, 2020                 [PC-6593] Added new method parseTimeFromJSONString() for parsing JSON Time to Time Type.
Satheesh Kumar         Aug 06, 2020                 [PC-6642] Added new methods for enclose the string with html pre tag and generating threadId.
Haritha Reddy          Oct 13, 2020                 [PC-6332] Added new method to evaluate Condition Logic string expression and provide boolean result
Haritha Reddy          Nov 20, 2020                 [PC-6888] Added support for 'Not' operator in evaluate Condition Logic method
Haritha Reddy          Nov 23, 2020                 [PC-7001] Added new method to generate transaction Id
Satheesh Kumar         Dec 10, 2020                 [PC-6699] Added new method isValidEmail, isFieldAvailable, and getRecordTypeNameByRecordId method.
Satheesh Kumar         Dec 15, 2020                 [PC-7148] Added null check to isValidEmail method
Satheesh Kumar         Feb 05, 2021                 [PC-7358] Added new method escapeSoslSearchText() to escape SOSL Reserved Keywords
Satheesh Kumar         Mar 23, 2021                 [PC-7127] Added new method isCommaSeparatedEmail() to check multiple email addresses separated by commas
Kishore Kanteti        May 21, 2021                 [PC-7739] Added methods convertRangeToNumbers(),convertNumbersToRange() to convert Range to Numbers and vice-versa respectively
Kishore Kanteti        Jul 12, 2021                 [PC-7843] Added method replacePatientConnectNamespace() to replace Patient Connect Namespace with Package Namespace
Tejas Patel            Mar 07, 2022                 [PC-8582] Added method isLicensedUser() to check for managed package user via permission set assignment.
Vijay Kashikar         Jul 01, 2022                 [PC-8967] Added new methods (moved from PC_DocumentTags file) to fetch dependent picklist values using Interface API
****************************************************************************************************************/
/**
 * PC_Utility is a utility class with methods used for various purposes including logging errors in the system.
 * To prevent errors logged to PC_Error_Log__c from being rolled back with failed transactions,
 * except where noted, logging methods will publish the errors through platform events and create the records
 * in a separate transaction context.
 */
global with sharing class PC_Utility {

    public static Integer DISPLAY_ERROR = 0;
    public static Integer DISPLAY_WARNING = 1;
    public static Integer DISPLAY_INFO = 2;

    global static final String ERROR_LOG_LEVEL_DEBUG = 'DEBUG';
    global static final String ERROR_LOG_LEVEL_INFO = 'INFO';
    global static final String ERROR_LOG_LEVEL_WARN = 'WARN';
    global static final String ERROR_LOG_LEVEL_ERROR = 'ERROR';

    /**
     * Return true for licensed user, unmanaged code org and site license org
     * Return false for unlicensed users
     */
    public static Boolean isLicensedUser() {
        Boolean licensedUser = true;
        Boolean performManagedPackageUserCheck = (Boolean) Boolean.valueOf(PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_MANAGED_PACKAGE_USER_CHECK,'false').toLowerCase());
        if(performManagedPackageUserCheck) {
            List<PermissionSetAssignment> permissionDetails = [
                    SELECT Id
                    FROM PermissionSetAssignment
                    WHERE PermissionSet.NamespacePrefix = :PC_Constants.OrgNamespace
                    AND PermissionSet.Name = :PC_Constants.MANDATORY_PERMISSIONSET
                    AND AssigneeId = :UserInfo.getUserId()
            ];
            //AND IsActive = true];//Will be empty list if permission set is not assigned

            if (permissionDetails.isEmpty()) {//If permission set is not applied to the current logged in user above list is empty
                licensedUser = false;
            }
        }
        return licensedUser;
    }

    /**
     * Return the Case status marked/tagged as closed
     */
    public static List<String> getClosedCaseStatus() {
        List<String> closedCaseStatus = new List<String>();
        List<CaseStatus> caseStatus = [Select ApiName From CaseStatus Where IsClosed = true];
        for(CaseStatus cs : caseStatus){
            closedCaseStatus.add(cs.ApiName);
        }

        return closedCaseStatus;
    }

    /**
     * Return the namespace of client Org.
     */
    public static String getOrgNamespace() {
        String orgNamespace = [SELECT NamespacePrefix FROM Organization].NamespacePrefix;
        return orgNamespace;
    }

    /**
     * Creates a new PC_Error_Log__c record based on the given exception. The message
     * and a stack trace are captured.
     *
     * @param e The exception to log.
     */
    global static void createExceptionLog(Exception e) {
        publishErrorLog(e, null);
    }

    /**
     * Creates a new PC_Error_Log__c record based on the what is provided in the wrapper class. The record will always be
     * published with platform event and inserted by the subscriber trigger
     *
     * @param errorInfoWrapper Wrapper with all information going to Error Log.
     */
    global static void createExceptionLog(PC_Utility.ErrorInfoWrapper errorInfoWrapper){
        publishErrorLog(errorInfoWrapper.aException, errorInfoWrapper.errorMessage, errorInfoWrapper.className,
                errorInfoWrapper.methodName, errorInfoWrapper.lineNumber, errorInfoWrapper.listRecords,
                errorInfoWrapper.logLevel, errorInfoWrapper.additionalInfo);
    }

    /**
     * Creates and logs an exception in the context of the current transaction. If the
     * current transaction is rolled back, the error log record will not be retained.
     *
     * @param e                 The exception to log
     * @param additionalInfo    Additional information to store along with the exception
     *
     * @return  The error log number of the logged exception.
     */
    public static String createExceptionLog(Exception e, String additionalInfo){
        PC_Error_Log__c errorLog = new PC_Error_Log__c(PC_Error_Datetime__c= DateTime.Now(),
                PC_Error_Message__c= e.getMessage(),
                PC_Running_User__c = UserInfo.getUserId() ,
                PC_Stack_Trace__c = '' + e.getStackTraceString(),
                PC_Additional_Information__c = additionalInfo);

        insert errorLog;

        PC_Error_Log__c errorLogDuplicate = [SELECT Name FROM PC_Error_Log__c WHERE ID = :errorLog.Id];

        return errorLogDuplicate.Name;

    }

    /**
     * Creates a new PC_Error_Log__c record based on the given exception and then
     * re-throws the exception.
     *
     * @param e The exception to log and throw
     */
    global static void logAndThrowException(Exception e) {
        logAndThrowException(e, null);
    }

    /**
     *Creates a new PC_Error_Log__c record based on the what is provided in the wrapper class. The record will always be
     * published with platform event and inserted by the subscriber trigger. An Exception will be re-thrown is it is provided
     * in the wrapper.
     *
     * @param errorInfoWrapper Wrapper with all information going to Error Log.
     */
    global static void logAndThrowException(PC_Utility.ErrorInfoWrapper errorInfoWrapper) {
        publishErrorLog(errorInfoWrapper.aException, errorInfoWrapper.errorMessage, errorInfoWrapper.className,
                errorInfoWrapper.methodName, errorInfoWrapper.lineNumber, errorInfoWrapper.listRecords,
                errorInfoWrapper.logLevel, errorInfoWrapper.additionalInfo);
        if (errorInfoWrapper.aException!=null)
            throw errorInfoWrapper.aException;
    }

    /**
     * Creates a new PC_Error_Log__c record based on the given exception and then
     * @param e                 The exception to publish
     * @param additionalInfo    Additional information stored in PC_Additional_Information__c
     */
    public static void logAndThrowException(Exception e, String additionalInfo) {
        publishErrorLog(e, additionalInfo);

        throw e;
    }

    /**
     * Creates and throws a new AuraHandledException with the given message.
     *
     * @param exceptionMessage  The message to user for the created exception;
     */
    public static void throwAuraHandledException(String exceptionMessage) {
        AuraHandledException ex = new AuraHandledException(exceptionMessage);
        ex.setMessage(exceptionMessage);
        throw ex;
    }

    /**
     * Publishes and throws and exception.
     *
     * @param e                 The exception to publish
     * @param additionalInfo    Additional information stored in PC_Additional_Information__c
     */
    // This methods is deprecated. Use logAndThrowException(Exception exception, additionalInfo).
    public static void publishAndThrowException(Exception e, String additionalInfo) {
        publishErrorLog(e, additionalInfo);
        throw e;
    }

    /**
     * Logs the given exception in PC_Error_Log__c and adds the message to ApexPages with severity
     * based on the given displayType.
     * <p>
     *
     * @param e             The exception to be logged
     * @param displayType   The severity of the ApexPages message based on constants defined in this utility class
     */
    public static void createExceptionLog(Exception e, Integer displayType) {
        createExceptionLog(e);

        if (ApexPages.currentPage() == null) {
            return;
        }
        if (displayType == DISPLAY_WARNING) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, e.getMessage()));
        } else if (displayType == DISPLAY_INFO) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, e.getMessage()));
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
        }
    }

    /**
     * Creates a new PC_Error_Log__c record for the given error message.
     * <p><strong>NOTE: </strong> This method was renamed from createExceptionLog in 7.1</strong</p>
     *
     * @param errorMessage The message for the error to log.
     */
    global static void createErrorLog(String errorMessage) {
        PC_Error_Log_Info__e errorLogInfo = new PC_Error_Log_Info__e(
                PC_Error_DateTime__c = DateTime.Now(),
                PC_Error_Message__c = errorMessage,
                PC_Running_User__c = UserInfo.getUserId()
        );

        publishErrorLog(errorLogInfo);
    }

    /**
     * Creates and logs an error in the context of the current transaction. If the
     * current transaction is rolled back, the error log record will not be retained.
     *
     * @param errorMessage      The message for the error to log.
     * @param additionalInfo    Additional information to store along with the exception
     *
     * @return  The error log number of the logged exception.
     */
    public static String createErrorLog(String errorMessage, String additionalInfo){
        PC_Error_Log__c errorLog = new PC_Error_Log__c(   PC_Error_Datetime__c= DateTime.Now(),
                PC_Error_Message__c = errorMessage,
                PC_Running_User__c = UserInfo.getUserId() ,
                PC_Stack_Trace__c = '',
                PC_Additional_Information__c = additionalInfo);
        Database.SaveResult result = Database.insert(errorLog);
        PC_Error_Log__c errorLogDuplicate = [SELECT Name FROM PC_Error_Log__c WHERE ID = :errorLog.Id];

        return  errorLogDuplicate.Name;
    }

    /**
     * Publishes an exception with additional information as a platform event.
     * The event will be handled by PC_RemoteServiceLogHandler and logged as a
     * PC_Error_Log__c record.
     *
     * @param e                 The exception to publish
     * @param additionalInfo    Additional information stored in PC_Additional_Information__c
     *
     * TODO: Make this method private.
     */
    public static void publishErrorLog(Exception e, String additionalInfo) {
        PC_Error_Log_Info__e errorLog = new PC_Error_Log_Info__e(
                PC_Error_DateTime__c = DateTime.Now(),
                PC_Error_Message__c = e.getMessage(),
                PC_Running_User__c = UserInfo.getUserId(),
                PC_Stack_Trace__c = '' + e.getStackTraceString(),
                PC_Additional_Information__c = additionalInfo
        );

        publishErrorLog(errorLog);
    }

    /**
     * Prepare Error Log Info Platform Event to be published.
     * PC_Error_Log__c record.
     *
     * @param e                 The exception to publish. Can be null.
     * @param errorMessage      Error message manually provided. Can be null.
     * @param className         Class where exception is thrown. Can be null.
     * @param methodName        Method where exception is thrown. Can be null.
     * @param lineNumber        Line number manually provided to indicate the location of the error. Can be null.
     * @param lRecords          List of records involved in the exception or error. Can be null.
     * @param logLevel          Cause of the exception. Can be null.
     * @param additionalInfo    Additional information stored in PC_Additional_Information__c. Can be null.
     */
    private static void publishErrorLog(Exception e, String errorMessage, String className, String methodName, Integer lineNumber, List<Sobject> lRecords, String logLevel, String additionalInfo) {
        List<PC_Error_Log_Info__e> lErrorLog = new List <PC_Error_Log_Info__e>();
        if (lRecords==null ||(lRecords!=null)&&(lRecords.isEmpty())) {
            PC_Error_Log_Info__e errorLog = new PC_Error_Log_Info__e(
                    PC_Error_DateTime__c = DateTime.Now(),
                    PC_Error_Message__c = (errorMessage!=null?errorMessage : '') + (e!=null? '--' + e.getMessage() : ''),
                    PC_Running_User__c = UserInfo.getUserId(),
                    PC_Stack_Trace__c = (e != null ? '' + e.getStackTraceString() : ''),
                    PC_Additional_Information__c = additionalInfo,
                    PC_Class_Name__c = className,
                    PC_Method_Name__c = methodName,
                    PC_Line_Number__c = (e != null ? e.getLineNumber() : lineNumber),
                    PC_Record_ID__c = '',
                    PC_Log_Level__c = logLevel
            );
            lErrorLog.add(errorLog);
        }
        else{
            for (Sobject record : lRecords) {
            PC_Error_Log_Info__e errorLog = new PC_Error_Log_Info__e(
            PC_Error_DateTime__c = DateTime.Now(),
            PC_Error_Message__c = (errorMessage!=null?errorMessage : '') + (e!=null? '--' + e.getMessage() : ''),
            PC_Running_User__c = UserInfo.getUserId(),
            PC_Stack_Trace__c = (e != null ? '' + e.getStackTraceString() : ''),
            PC_Additional_Information__c = additionalInfo,
            PC_Class_Name__c = className,
            PC_Method_Name__c = methodName,
            PC_Line_Number__c = (e != null ? e.getLineNumber() : lineNumber),
            PC_Record_ID__c = record.Id,
            PC_Log_Level__c = logLevel
            );
            lErrorLog.add(errorLog);
            }
        }

        if (lErrorLog!=null&& !lErrorLog.isEmpty()) {
            publishErrorLog(lErrorLog);
        }
    }

    /**
     * Publishes a platform event to be handled by PC_RemoteServiceLogHandler and logged as a
     * PC_Error_Log__c record.
     *
     * @param errorLogInfo  The platform event to publish.
     */
    private static void publishErrorLog(PC_Error_Log_Info__e errorLogInfo) {
        Database.SaveResult result = EventBus.publish(errorLogInfo);
        if(result != null && result.isSuccess()) {
            // published successfully
            System.debug('Error log info published successfully');
        }
        else {
            // critical error.
            System.debug('Critical Error. Error log info publish failed');
        }
    }

    /**
    * Publishes a list of platform events and log a list of PC_Error_Log__c record.
    *
    * @param lErrorLogInfo  The list of platform event to be published.
    */
    private static void publishErrorLog(List <PC_Error_Log_Info__e> lErrorLogInfo) {
        list<Database.SaveResult> lResult = EventBus.publish(lErrorLogInfo);
        if (lResult != null && !lResult.isEmpty()) {
            for (Database.SaveResult result: lResult){
                if(result != null && result.isSuccess()) {
                // published successfully
                    System.debug('Error log info published successfully');
                }
                else {
                // critical error.
                    System.debug('Critical Error. Error log info publish failed');
                }
            }
        }
    }

    /**
     * Returns a list of populated fields on the given object.
     *
     * @param obj   The object to get the populated fields from.
     *
     * @return The list of populated fields.
     * @author Vijay Kashikar
     */
    public static List<String> getPopulatedFields(SObject obj){
        List<String> fields = new List<String>();
        if(obj != null) {
            Map<String, Object> populatedFields = obj.getPopulatedFieldsAsMap();
            for (String key : populatedFields.keySet()) {
                system.debug('Populated field ' + key);
                fields.add(key);
            }
        }
        return fields;
    }

    /**
     * Validates the respective object's fieldset and returns a boolean value.
     *
     * @param objectAPIName The object whose fieldset requires validation.
     * @param fieldSetAPIName The fieldset that gets validated.
     *
     * @return Returns a boolean value after the validation of the respective fieldset.
     * 
     */
    public static Boolean isValidFieldSet(String objectAPIName, String fieldSetAPIName){
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(objectAPIName);
        Schema.FieldSet fieldSetObj = leadSchema.getDescribe().FieldSets.getMap().get(fieldSetAPIName);
        if(fieldSetObj == null) {
            return false;
        }
        return true;
    }

    /**
     * Checks if the current user has health cloud permission set assigned
     *
     * @return  <code>true</code> if the health cloud permission set is assigned, <code>false</code> otherwise.
     *
     * @author Vijay Kashikar
     */
    public static Boolean hasHealthCloudPermissionSetAssigned(){
        String healthCloudNamespace = PC_Constants.HealthCloudNamespace;
        String healthCloudPermissionSetLicenseName = PC_Constants.HealthCloudPermissionSetLicenseName;
        system.debug('@vj - current user id');
        system.debug(UserInfo.getUserId());
        Integer resultsCount = [
                SELECT count()
                FROM PermissionSetAssignment
                WHERE AssigneeId = :UserInfo.getUserId() AND
                PermissionSet.NamespacePrefix = :healthCloudNamespace AND
                PermissionSet.Name = :healthCloudPermissionSetLicenseName
        ];
        return resultsCount > 0;
    }

    /**
     * Provides a mapping betwee Account and Applicant fields.
     *
     * @param accFields The account fields to be mapped.
     * @return The fields mapped to Applicant.
     * @author Tejas Patel
     */
    public static Map<String, String> accountToApplicantMapping(List<String> accFields){
        MAP<STRING,STRING> applicantFields = new MAP<STRING,STRING>();

        String defaultJSONString='{"Phone" : "'+PC_Constants.getQualifiedAPIName('PC_Phone__c')+'", "'+
                PC_Constants.getQualifiedAPIName('PC_Email__c')+'" : "'+PC_Constants.getQualifiedAPIName('PC_Patient_Email__c')+'", "'+
                PC_Constants.getQualifiedAPIName('PC_Primary_Address_1__c')+'": "'+
                PC_Constants.getQualifiedAPIName('PC_Address_1__c')+'", "'+
                PC_Constants.getQualifiedAPIName('PC_Primary_City__c')+'":"'+
                PC_Constants.getQualifiedAPIName('PC_City__c')+'","'+
                PC_Constants.getQualifiedAPIName('PC_Primary_State__c')+'":"'+
                PC_Constants.getQualifiedAPIName('PC_State__c')+'","'+
                PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c')+'":"'+
                PC_Constants.getQualifiedAPIName('PC_Zip_Code__c')+'" }';
        String mappingJSON = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ACCOUNT_APPLICANT_MAPPING,defaultJSONString);
        Map<String, String> m = (Map<String, String>) JSON.deserialize(mappingJSON, Map<String, String>.class);

        for(String s : accFields){
            if (m.get(s) == null){
                applicantFields.put(s,s);
            } else if (String.isNotBlank(m.get(s)) && m.get(s) != 'NA'){
                applicantFields.put(s,m.get(s));
            }
        }

        return applicantFields;
    }

    /*********************************************************
    Method Name          : getFormattedDate
    Description          : Changing the date format for display purpose
    Input Params         : Date input date, String dateFormat
    Return Type          : String
    *********************************************************************************/


    public static String getFormattedDate (Date inputDate ,String dateFormat ) {
        if (String.isNotBlank(dateFormat) && inputDate != null) {
            DateTime dateTimeFormat = Datetime.newInstance(inputDate.year(), inputDate.month(), inputDate.day());
            String dateOutput = dateTimeFormat.format(dateFormat);
            System.debug('Debug: ' + dateOutput);
            return dateOutput;
        }
        return null;
    }
    /**
     *  ErrorInfoWrapper is the wrapper object for holding information related to Error
     */
    global class ErrorInfoWrapper {

        global Exception aException{get;set;}
        global String errorMessage{get;set;}
        global String className{get;set;}
        global String methodName{get;set;}
        global Integer lineNumber{get;set;}
        global List<Sobject> listRecords{get;set;}
        global String logLevel{get;set;}
        global String additionalInfo{get;set;}

        global ErrorInfoWrapper(Exception aException, String errorMessage, String className, String methodName,
                Integer lineNumber, List<Sobject> listRecords, PC_Utility.ERROR_LOG_LEVEL logLevel, String additionalInfo){
            this.aException = aException;
            this.errorMessage = errorMessage;
            this.className = className;
            this.methodName = methodName;
            this.lineNumber = lineNumber;
            this.listRecords = listRecords;
            this.logLevel = (logLevel==PC_Utility.ERROR_LOG_LEVEL.ERROR_LOG_LEVEL_DEBUG)?ERROR_LOG_LEVEL_DEBUG:
                            (logLevel==PC_Utility.ERROR_LOG_LEVEL.ERROR_LOG_LEVEL_INFO)?ERROR_LOG_LEVEL_INFO:
                            (logLevel==PC_Utility.ERROR_LOG_LEVEL.ERROR_LOG_LEVEL_WARN)?ERROR_LOG_LEVEL_WARN:
                            (logLevel==PC_Utility.ERROR_LOG_LEVEL.ERROR_LOG_LEVEL_ERROR)?ERROR_LOG_LEVEL_ERROR:'';
            this.additionalInfo = additionalInfo;
        }
    }

    public static Set<String> getGroups (CustomMetadataWrapper.GroupWrapper groupDetail) {

        Set<String> groups = NEW Set<String>();

        LIST<PC_GroupMember__mdt> groupMetaData_Detail = [SELECT Id, PC_ObjectName__c, PC_Object_Namespace__c, PC_FieldName__c, PC_Field_Namespace__c,
                PC_Group__c FROM PC_GroupMember__mdt WHERE PC_Active__c  = : true AND PC_ObjectName__c = : groupDetail.objectAPIName  AND PC_Object_Namespace__c = : groupDetail.objectNamespace AND
        PC_FieldName__c = : groupDetail.fieldAPIName AND PC_Field_Namespace__c = : groupDetail.fieldNamespace  AND PC_FieldValue__c = : groupDetail.fieldValue AND
        PC_Group__c IN : [SELECT Id FROM PC_Group__mdt WHERE PC_Active__c =: true]];

        for(PC_GroupMember__mdt objGroup : groupMetaData_Detail){
            groups.add(objGroup.PC_Group__c);
        }
        return  groups;
    }

    public static Map<String, Schema.SObjectField> removeSystemFields(Map<String, Schema.SObjectField> fieldMapWithSystemFields){
        Map<String, Schema.SObjectField> updateFieldsMap = new Map<String, Schema.SObjectField>();
        updateFieldsMap.putAll(fieldMapWithSystemFields);
        for(String fieldName : fieldMapWithSystemFields.keySet()){
            if(fieldName == PC_Constants.PC_CreatedDate || fieldName == PC_Constants.PC_CreatedById || fieldName == PC_Constants.PC_LastModifiedDate
                    || fieldName == PC_Constants.PC_LastModifiedById || fieldName == PC_Constants.PC_SystemModstamp || fieldName == PC_Constants.PC_IsDeleted
                    || fieldName == PC_Constants.PC_LastReferencedDate || fieldName == PC_Constants.PC_LastViewedDate || fieldName == PC_Constants.PC_MasterRecordId
                    || fieldName == PC_Constants.PC_LastActivityDate){
                updateFieldsMap.remove(fieldName);
            }
        }
        return updateFieldsMap;
    }

    /*********************************************************************************
    Method Name    : parseDatetimeFromJSON
    Description    : This method parses JSON Date Time value and returns Date Time
    Return Type    : Datetime
    Parameter      : jsonDateTime
    *********************************************************************************/
    public static Datetime parseDatetimeFromJSON(String jsonDateTime) {
        // DateTime.parse() function does not work for json format datetime and hence this workaround.
        // Example of correct json format is 2018-05-07T05:23:52.7362363Z
        String JSONContent = '{"transactionDate":"' + jsonDateTime + '"}';
        JSONParser parser = JSON.createParser(JSONContent);
        // Advance to the start object marker.
        parser.nextToken();
        // Advance to the next value.
        parser.nextValue();
        // Get the transaction date.
        Datetime transactionDate = parser.getDatetimeValue();
        return transactionDate;
    }

    /*********************************************************************************
    Method Name    : parseTimeFromJSONString
    Description    : This method parses JSON Time value and returns Time
    Return Type    : Time
    Parameter      : jsonTime
    *********************************************************************************/
    public static Time parseTimeFromJSONString(String jsonTime) {
        String[] strTimeSplit = jsonTime.split(':');
        Time formattedTime = Time.newInstance(Integer.valueOf(strTimeSplit[0]),Integer.valueOf(strTimeSplit[1]),0,0);
        return formattedTime;
    }
    global Enum ERROR_LOG_LEVEL {ERROR_LOG_LEVEL_DEBUG, ERROR_LOG_LEVEL_INFO, ERROR_LOG_LEVEL_WARN, ERROR_LOG_LEVEL_ERROR}

    //get threadId by passing List of Strings
    public static String getThreadId(List<String> recIds) {
        String threadIdPattern = '[ ref:{0}.{1}:ref ]';
        return String.format(threadIdPattern, recIds);
    }

    //Enclose String with Pre Tag
    public static String encloseStringWithPreTag(List<String> inputStr) {
        String preTagPattern = '<pre>{0}</pre>';
        return String.format(preTagPattern, inputStr);
    }

    /**
     *Returns a map of Group Names (PC_Group__mdt) by record Id based on the record Id passed
     *
     * @param recordIds List of Salesforce Record Ids.
     */
    global static Map<Id,Set<GroupInfo>> getGroupInfoByIds(List<Id> recordIds) {
        Map<Id, Set<GroupInfo>> RecordToGroupMap = new Map<Id, Set<GroupInfo>>();
        try {
            Set<Id> recordIdsToQuery = new Set<Id>();
            recordIdsToQuery.addAll(recordIds);

            Map<Id, CustomMetadataWrapper.GroupWrapper> recordGroupDetails = new Map<Id, CustomMetadataWrapper.GroupWrapper>();
            Map<Id, List<Map<String, String>>> finalRecordDetails = new Map<Id, List<Map<String, String>>>();
            String objectAPI;
            String objectNamespace;

            for (Id rId : recordIds) {
                Schema.SObjectType sObj = rId.getSobjectType();
                Schema.DescribeSObjectResult sObjResult = sObj.getDescribe();
                String localName = sObjResult.getLocalName();
                String nameWithNamespace = sObjResult.getName();
                String ObjNameSpaceTemp = nameWithNamespace.removeEndIgnoreCase(localName).removeEndIgnoreCase('__');
                String ObjNameSpace = String.isNotBlank(ObjNameSpaceTemp) ? ObjNameSpaceTemp : null;

                CustomMetadataWrapper.GroupWrapper groupDetail = new CustomMetadataWrapper.GroupWrapper();
                groupDetail.objectAPIName = localName;
                groupDetail.objectNamespace = ObjNameSpace;
                groupDetail.fieldAPIName = PC_Constants.EMPTY_STRING;
                groupDetail.fieldNamespace = PC_Constants.EMPTY_STRING;
                groupDetail.fieldValue = PC_Constants.EMPTY_STRING;

                recordGroupDetails.put(rId, groupDetail);

                objectAPI = localName;
                objectNamespace = ObjNameSpace;
                break; //Assuming all the records are of same type.
            }

            LIST<PC_GroupMember__mdt> groupMembers = [
                    SELECT Id, PC_ObjectName__c, PC_Object_Namespace__c, PC_FieldName__c, PC_Field_Namespace__c, PC_FieldValue__c,
                            PC_Group__c, PC_Group__r.DeveloperName, PC_Group__r.MasterLabel, PC_Group__r.PC_Active__c, PC_Group__r.PC_Description__c
                    FROM PC_GroupMember__mdt
                    WHERE PC_Active__c = :true AND PC_ObjectName__c = :objectAPI AND PC_Object_Namespace__c = :objectNamespace
            ];

            if(Test.isRunningTest() && groupMembers.size() == 0){
                groupMembers = PC_Test_Utility.getGroupMembersForTest(objectAPI,objectNamespace);
            }

            for (Id rid : recordGroupDetails.keySet()) {
                List<Map<String, String>> fieldValuePairList = new List<Map<String, String>>();
                for (PC_GroupMember__mdt gm : groupMembers) {
                    if (recordGroupDetails.get(rid).objectAPIName == gm.PC_ObjectName__c && recordGroupDetails.get(rid).objectNamespace == gm.PC_Object_Namespace__c) {
                        Map<String, String> fieldValuePair = new Map<String, String>();
                        String fieldName = String.isNotBlank(gm.PC_Field_Namespace__c) ? gm.PC_Field_Namespace__c + '__' + gm.PC_FieldName__c : gm.PC_FieldName__c;
                        fieldValuePair.put(fieldName, gm.PC_FieldValue__c);
                        fieldValuePairList.add(fieldValuePair);
                    }
                }
                finalRecordDetails.put(rid, fieldValuePairList);
            }

            Set<String> fieldsSet = new Set<String>();
            List<String> fieldsToQuery = new List<String>();

            for (Id rId : finalRecordDetails.keySet()) {
                List<Map<String, String>> ListmapFieldValuePair = finalRecordDetails.get(rId);
                for (Map<String, String> mapFieldValuePair : ListmapFieldValuePair) {
                    fieldsSet.addAll(mapFieldValuePair.keySet());
                }
            }
            fieldsSet.add('ID'); //Adding the ID field to be used in Map as key.
            fieldsToQuery.addAll(fieldsSet);
            String query = 'SELECT ';
            String fieldList = String.join(fieldsToQuery, ', ');
            String objectAPIwithNamespce = String.isNotBlank(objectNamespace) ? objectNamespace + '__' + objectAPI : objectAPI;
            String fromClause = ' FROM ' + objectAPIwithNamespce;
            String whereClause = ' WHERE Id IN :recordIdsToQuery';
            query = query + fieldList + fromClause + whereClause;
            List<sObject> dynamicObject = Database.query (query);

            for (sObject obj : dynamicObject) {
                Map<String,GroupInfo> removeDuplicateMap = new Map<String,GroupInfo>();
                Set<GroupInfo> groupDetailInfo = new Set<GroupInfo>();
                for (PC_GroupMember__mdt gm : groupMembers) {
                    String fieldName = String.isNotBlank(gm.PC_Field_Namespace__c) ? gm.PC_Field_Namespace__c + '__' + gm.PC_FieldName__c : gm.PC_FieldName__c;
                    String objLevel1;
                    String objLevel2;
                    String objLevel3;
                    if (fieldName.countMatches('.') == 3) {
                        objLevel1 = fieldName.substringBefore('.');
                        objLevel2 = fieldName.substringAfter('.').substringBefore('.');
                        objLevel3 = fieldName.substringAfter('.').substringAfter('.').substringBefore('.');
                        fieldName = fieldName.substringAfterLast('.');
                        if (obj.getSObject(objLevel1).getSObject(objLevel2).getSObject(objLevel3).get(fieldName) == gm.PC_FieldValue__c) {
                            GroupInfo groupDetails = new GroupInfo();
                            groupDetails.groupName          = gm.PC_Group__r.DeveloperName;
                            groupDetails.groupLabel         = gm.PC_Group__r.MasterLabel;
                            groupDetails.groupDescription   = gm.PC_Group__r.PC_Description__c;
                            groupDetails.isActive           = gm.PC_Group__r.PC_Active__c;
                            removeDuplicateMap.put(gm.PC_Group__r.DeveloperName,groupDetails);
                        }
                    } else if (fieldName.countMatches('.') == 2) {
                        objLevel1 = fieldName.substringBefore('.');
                        objLevel2 = fieldName.substringAfter('.').substringBefore('.');
                        fieldName = fieldName.substringAfterLast('.');
                        if (obj.getSObject(objLevel1).getSObject(objLevel2).get(fieldName) == gm.PC_FieldValue__c) {
                            GroupInfo groupDetails = new GroupInfo();
                            groupDetails.groupName          = gm.PC_Group__r.DeveloperName;
                            groupDetails.groupLabel         = gm.PC_Group__r.MasterLabel;
                            groupDetails.groupDescription   = gm.PC_Group__r.PC_Description__c;
                            groupDetails.isActive           = gm.PC_Group__r.PC_Active__c;
                            removeDuplicateMap.put(gm.PC_Group__r.DeveloperName,groupDetails);
                        }
                    } else if (fieldName.countMatches('.') == 1) {
                        objLevel1 = fieldName.substringBefore('.');
                        fieldName = fieldName.substringAfterLast('.');
                        if (obj.getSObject(objLevel1).get(fieldName) == gm.PC_FieldValue__c) {
                            GroupInfo groupDetails = new GroupInfo();
                            groupDetails.groupName          = gm.PC_Group__r.DeveloperName;
                            groupDetails.groupLabel         = gm.PC_Group__r.MasterLabel;
                            groupDetails.groupDescription   = gm.PC_Group__r.PC_Description__c;
                            groupDetails.isActive           = gm.PC_Group__r.PC_Active__c;
                            removeDuplicateMap.put(gm.PC_Group__r.DeveloperName,groupDetails);
                        }
                    } else {
                        if (obj.get(fieldName) == gm.PC_FieldValue__c) {
                            GroupInfo groupDetails = new GroupInfo();
                            groupDetails.groupName          = gm.PC_Group__r.DeveloperName;
                            groupDetails.groupLabel         = gm.PC_Group__r.MasterLabel;
                            groupDetails.groupDescription   = gm.PC_Group__r.PC_Description__c;
                            groupDetails.isActive           = gm.PC_Group__r.PC_Active__c;
                            removeDuplicateMap.put(gm.PC_Group__r.DeveloperName,groupDetails);
                        }
                    }
                }
                groupDetailInfo.addAll(removeDuplicateMap.values());
                RecordToGroupMap.put(obj.Id, groupDetailInfo);
            }
        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return RecordToGroupMap;
    }
    /**
     * Evaluates custom logic which is in String format and returns Boolean result of that expression.
     *
     * @param customLogicString Custom logic to be evaluated. Ex: (TRUE AND (FALSE OR TRUE))
     */
    public static Boolean evaluateCustomLogic(String customLogicString) {
        Boolean customLogicResult = FALSE;
        if(String.isNotEmpty(customLogicString)){
            customLogicString = customLogicString.toUpperCase();
            // If custom Logic String contains all TRUE or FALSE
            if(customLogicString.containsNone('F')) { customLogicResult = TRUE; }
            if(customLogicString.containsNone('T')) { customLogicResult = FALSE; }

            Map<String, Map<String, String>> expressionLogic = getExpressionLogic();
            Map<String, String> logicTypes = getLogicTypes();

            Integer counter = 0;
            customLogicResult = Boolean.valueOf(evaluateExpression(customLogicString,logicTypes,expressionLogic, counter));
        }
        return customLogicResult;
    }

    /**
    * Evaluates the expression
    */
    private static String evaluateExpression(String expression, Map<String, String> logicTypes, Map<String, Map<String, String>> expressionLogic, Integer counter) {
        counter = counter+1;
        if(counter < 900){
            for(String logicType : logicTypes.keySet()) {
                if(expression.contains(logicType)) {
                    expression = simplifyExpression(expression, logicTypes.get(logicType),expressionLogic);
                }
            }
            if(expression.contains('AND') || expression.contains('OR') || expression.contains('(') || expression.contains('NOT')) {
                expression = evaluateExpression(expression,logicTypes,expressionLogic,counter);
            }else if(expression != 'TRUE' && expression != 'FALSE'){
                PC_SupportPlanEngine.SupportPlan_Exception supportPlanException = new PC_SupportPlanEngine.SupportPlan_Exception();
                supportPlanException.setMessage(Label.PC_SupportPlan_CustomLogicErrorMessage);
                throw supportPlanException;
            }
        }else{
            PC_SupportPlanEngine.SupportPlan_Exception supportPlanException = new PC_SupportPlanEngine.SupportPlan_Exception();
            supportPlanException.setMessage(Label.PC_SupportPlan_CustomLogicErrorMessage);
            throw supportPlanException;
        }
        return expression;
    }
    /**
     * Simplifies the expression
     */
    private static string simplifyExpression(String expression, String LogicType, Map<String, Map<String, String>> expressionLogic ){
        Map<String, String> Logic = new Map<String, String>(expressionLogic.get(LogicType));
        for(String key : Logic.keySet()) {
            expression = expression.normalizeSpace();
            expression = expression.replace('( ','(');
            expression = expression.replace('NOT (','NOT(');
            expression = expression.replace(' )',')');
            system.debug('expression1>>'+expression);
            expression = expression.replace(key, Logic.get(key));
        }
        return expression;
    }
    /**
     * Populate Logic Types Map
     */
    private static Map<String, String> getLogicTypes() {
        Map<String, String> logicTypes = new Map<String, String>();
        logicTypes.put('AND', 'AND');
        logicTypes.put('OR', 'OR');
        logicTypes.put('NOT', 'NOT');
        logicTypes.put('(', 'BRACES');

        return logicTypes;
    }
    /**
     * Populate Expression Logic Map
     */
    private static Map<String, Map<String, String>> getExpressionLogic() {
        Map<String, Map<String, String>> expressionLogic = new Map<String, Map<String, String>>();

        Map<String, String> ANDLogic = new Map<String, String>();
        Map<String, String> ORLogic = new Map<String, String>();
        Map<String, String> BRACELogic = new Map<String, String>();
        Map<String, String> NOTLogic = new Map<String, String>();

        //Not Logic
        NOTLogic.put('NOT TRUE', 'FALSE');
        NOTLogic.put('NOT FALSE', 'TRUE');
        NOTLogic.put('NOT(TRUE)', 'FALSE');
        NOTLogic.put('NOT(FALSE)', 'TRUE');
        expressionLogic.put('NOT', NOTLogic);

        // AND Logic
        ANDLogic.put('TRUE AND TRUE', 'TRUE');
        ANDLogic.put('TRUE AND FALSE', 'FALSE');
        ANDLogic.put('FALSE AND TRUE', 'FALSE');
        ANDLogic.put('FALSE AND FALSE', 'FALSE');
        expressionLogic.put('AND', ANDLogic);

        // OR Logic
        ORLogic.put('TRUE OR TRUE', 'TRUE');
        ORLogic.put('TRUE OR FALSE', 'TRUE');
        ORLogic.put('FALSE OR TRUE', 'TRUE');
        ORLogic.put('FALSE OR FALSE', 'FALSE');
        expressionLogic.put('OR', ORLogic);

        // Braces Logic
        BRACELogic.put('(TRUE)', 'TRUE');
        BRACELogic.put('(FALSE)', 'FALSE');
        expressionLogic.put('BRACES', BRACELogic);

        return expressionLogic;
    }
    /*********************************************************************************
    Method Name    : generateTransactionId
    Description    : This method generates transaction Id with milliseconds since January 1, 1970, 00:00:00 GMT till current time.
    Return Type    : String
    *********************************************************************************/
    public static String generateTransactionId(String key) {
        Long timeInNanoSeconds = System.now().getTime();
        String transactionId = PC_Constants.PC_TRANSACTION_ID_KEY + PC_Constants.PC_HYPHEN;
        if(String.isNotEmpty(key)){
            transactionId = transactionId+ key + PC_Constants.PC_HYPHEN;
        }
        transactionId = transactionId+timeInNanoSeconds;
        return transactionId;
    }

    /**
    * The isValidEmail method checks whether a string is formatted as a valid email address
    *
    * @param email     String which needs to be validated.
    * @return Boolean  True if the string is a valid email.
    *
    * @author Satheesh Kumar
    */
    public static Boolean isValidEmail(String email) {
        if (String.isNotBlank(email)) {
            String inputString = email;
            String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
            Pattern MyPattern = Pattern.compile(emailRegex);
            Matcher MyMatcher = MyPattern.matcher(inputString);
            if (!MyMatcher.matches()) {
                return PC_Constants.FALSE_BOOLEAN;
            } else {
                return PC_Constants.TRUE_BOOLEAN;
            }
        } else {
            return PC_Constants.FALSE_BOOLEAN;
        }
    }

    /**
   * Validate Multiple Email Addresses Separated by Commas.
   * If input string is valid then returns true, otherwise false.
   *
   * @param email     String which needs to be validated.
   * @return Boolean  True if the string is comma separated email
   *
   * @author Satheesh Kumar
   */
    public static Boolean isCommaSeparatedEmail(String commaSeparatedEmailString) {
        if (String.isNotBlank(commaSeparatedEmailString)) {
            String inputString = commaSeparatedEmailString;
            String emailRegex = '^(\\s?[^\\s,]+@[^\\s,]+\\.[^\\s,]+\\s?,)*(\\s?[^\\s,]+@[^\\s,]+\\.[^\\s,]+)$';
            Pattern MyPattern = Pattern.compile(emailRegex);
            Matcher MyMatcher = MyPattern.matcher(inputString);
            if (!MyMatcher.matches()) {
                return PC_Constants.FALSE_BOOLEAN;
            } else {
                return PC_Constants.TRUE_BOOLEAN;
            }
        } else {
            return PC_Constants.FALSE_BOOLEAN;
        }
    }

    /**
    * This method helps to check whether the field is availble or not.
    * ex. can validate if RecordTypeId for a object is available or not
    *
    * @param sObjectAPIName     API Name of the sObject.
    * @param fieldAPIName       API Name of the field.
    * @return Boolean           Returns True if field is available.
    *
    * @author Satheesh Kumar
    */
    public static Boolean isFieldAvailable(String sObjectAPIName, String fieldAPIName) {
        // call to get the appropriate object's describe
        Map<String, Schema.SObjectType> mapGlobalDescribe = Schema.getGlobalDescribe();
        Schema.SObjectType objSObjectType = mapGlobalDescribe.get(sObjectAPIName);

        // field describe
        Schema.DescribeSObjectResult objectDescribe = objSObjectType.getDescribe();
        Map<String, Schema.SObjectField> mapFieldDescribe = objSObjectType.getDescribe().fields.getMap();

        // check if field exists in describe call
        return mapFieldDescribe.containsKey(fieldAPIName);
    }

    /**
     * Returns record type name for a record based on the record Id
     *
     * @param recordId  record Id
     *
     * @author Satheesh Kumar
     */
    public static String getRecordTypeNameByRecordId(String recordId) {
        String objType = String.valueOf(Id.valueOf(recordId).getSobjectType());
        String recordTypeName = PC_Constants.EMPTY_STRING;
        SObject selectedObj = null;
        // check if field is available
        if (isFieldAvailable(objType, PC_Constants.PC_RECORD_TYPE_ID)) {
            selectedObj = Database.query('SELECT Id, RecordType.Name FROM ' + objType + ' WHERE Id = :recordId');
            RecordType recordType = (RecordType) selectedObj.getSObject(PC_Constants.RECORD_TYPE_PARAM);
            recordTypeName = recordType ?.Name;
        }
        return recordTypeName;
    }

    /**
     * Converts into range when input is array of numbers
     * Example -
     * Input - 1,2,3,4,5,6,7,8,9,10,11,13,15
     * Output - 1-11,13,15
     *
     * @param  text Numbers
     * @return text Range
     */
    public static String convertNumbersToRange(String sortedPageNumbers){
        String result = '';
        List<String> pageNumbersList = sortedPageNumbers.split(',');
        List<Integer> sortedIntegers = new List<Integer>();
        for(String pageNumber : pageNumbersList){
            sortedIntegers.add(Integer.valueOf(pageNumber));
        }
        Integer initialPageNumber ,endPageNumber;  // track start and end
        endPageNumber = initialPageNumber = sortedIntegers[0];
        for (Integer i = 1; i < sortedIntegers.size(); i++) {
            // as long as entries are consecutive, move end forward
            if (sortedIntegers[i] == (sortedIntegers[i - 1] + 1)) {
                endPageNumber = sortedIntegers[i];
            }
            else{
                // when no longer consecutive, add group to result
                // depending on whether start=end (single item) or not
                if (initialPageNumber == endPageNumber) {
                    result += initialPageNumber + ',';
                }
                else {
                    result += initialPageNumber + '-' + endPageNumber + ',';
                }
                initialPageNumber = endPageNumber = sortedIntegers[i];
            }
        }

        // handle the final group
        if (initialPageNumber == endPageNumber){
            result += initialPageNumber;
        }
        else {
            result += initialPageNumber + '-' + endPageNumber;
        }
        return result;
    }
    /**
     * Converts into array of numbers when input is range
     * Example - Input - 1-6,7-11,13,15
     *           Output - 1,2,3,4,5,6,7,8,9,10,11,13,15
     * @param  text Range
     * @return text Numbers
     */
    public static String convertRangeToNumbers(String sortedPageRanges){
        String sortedPageNumbers = '';
        List<Integer> lstNumber = new List<Integer>();
        String[] cNumberArray = sortedPageRanges.Split(',');

        for (Integer k = 0; k < cNumberArray.size(); k++){
            String temporaryDigit = cNumberArray[k];
            if (temporaryDigit.Contains('-')){
                Integer initialValue = Integer.valueOf(temporaryDigit.Split('-')[0]);
                Integer endValue = Integer.valueOf(temporaryDigit.Split('-')[1]);

                for (Integer j = initialValue; j <= endValue; j++) {
                    if (!sortedPageNumbers.contains(String.valueOf(j))){
                        if(sortedPageNumbers != ''){
                            sortedPageNumbers = sortedPageNumbers + ',' + String.valueOf(j);
                        }else{
                            sortedPageNumbers = String.valueOf(j);
                        }
                    }
                }
            }else{
                if(sortedPageNumbers != '') {
                    sortedPageNumbers = sortedPageNumbers + ',' + String.valueOf(temporaryDigit);
                }else{
                    sortedPageNumbers = String.valueOf(temporaryDigit);
                }
            }
        }
        return sortedPageNumbers;
    }
    /**
     * Replaces Patient Connect Namespace with Package Namespace
     * Example -
     * Input - PatientConnect__PC_Document
     * Output - In Managed Package Installed Org it will be PatientConnect__PC_Document else <orgNamespace>__PC_Document
     *
     * @param  qualifiedAPIName
     * @return String apiName
     */
    public static String replacePatientConnectNamespace(String qualifiedAPIName) {
        if(String.isNotBlank(qualifiedAPIName)) {
            if(qualifiedAPIName.startsWithIgnoreCase(PC_Constants.PATIENTCONNECTNAMESPACE_WITHUNDERSCORES)){
                String packageNamespace = PC_Constants.OrgNamespace;
                String apiName = qualifiedAPIName.removeStartIgnoreCase(PC_Constants.PATIENTCONNECTNAMESPACE_WITHUNDERSCORES);
                if(String.isBlank(packageNamespace)) {
                    qualifiedAPIName = apiName;
                }else{
                    qualifiedAPIName = packageNamespace + '__' + apiName;
                }
            }
        }
        return qualifiedAPIName;
    }


    /**
     * Designed to prepare text input for the FIND { phrase } part of SOSL query.
     *
     * Removes reserved logical operators: AND NOT, AND, OR
     * Escapes special characters: ? & | ! { } [ ] ( ) ^ ~ * : " ' + -
     *
     * Does not handle backslash (\) so do not include it in the text input.
     * Returns null if text is blank.
     *
     * @param  text    Search Text
     */
    public static String escapeSoslSearchText(String text) {
        // Ex. text = O'Reilly (1)
        String escapedText;
        if (String.isBlank(text)) {
            escapedText = null;
        } else {
            // escape single quotes.
            escapedText = String.escapeSingleQuotes(text) ;  // escapedText = O\'Reilly (1)
            // match special characters to escape
            Pattern myPattern = Pattern.compile('(\\?|\\&|\\||\\!|\\{|\\}|\\[|\\]|\\(|\\)|\\^|\\~|\\*|\\:|\\"|\\+|\\-)');
            Matcher myMatcher = myPattern.matcher(escapedText);
            // escape special characters
            escapedText = myMatcher.replaceAll('\\\\\\\\$1');  // escapedText = O\'Reilly \\(1\\)
            // collapse repeated whitespace
            escapedText = escapedText.replaceAll('( )+', ' ').trim();  // escapedText = O\'Reilly \\(1\\)
        }
        return escapedText;
    }

    /**
     * Method to get the Dependent picklist values using Salesforce Interface UI.
     *
     *
     * @param objectName Fully qualified API Name of the object
     * @param recordTypeId Record Type ID
     * @param controllingFieldValue Controlling field's fully qualifield API name : pass null if controlling field is out of picture.
     * @param dependentFieldName Dependent field's fully qualified API name
     * @param userInterfaceAPINamedCredential Name of Named Credential. Refer to implementation guide on how to set it up.
     *
     * @return Map of API name of the picklist and the label of the picklist
     */
    public static Map<String, String> getDependentPicklistsUsingAPI(String objectName, String recordTypeId,
            String controllingFieldValue, String dependentFieldName, String userInterfaceAPINamedCredential ) {
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + userInterfaceAPINamedCredential + '/services/data/v53.0/ui-api/object-info/' +
                objectName + '/picklist-values/' + recordTypeId + '/' + dependentFieldName);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        system.debug('Calling user interface api in getDependentPicklistsUsingAPI');
        system.debug(res.getBody());
        Map<String, String> categories = new Map<String, String>();
        if(res.getStatusCode() == 200) {

            Map<String, Object> root = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            Integer validForOfControllingField = -1;
            if(controllingFieldValue != null) {
                Map<String, Object> controllerValues_Name_ValidFor_Map = (Map<String, Object>) root.get('controllerValues');
                validForOfControllingField = (Integer) controllerValues_Name_ValidFor_Map.get(controllingFieldValue);
                system.debug('validForOfControllingField=' + validForOfControllingField);
            }

            List<Object> categoryObjects = (List<Object>)root.get('values');

            if(categoryObjects != null) {
                Map<String, Object> temp;
                List<Object> validFor;
                for(Object categoryObject : categoryObjects) {
                    temp = (Map<String, Object>) categoryObject;
                    validFor = (List<Object>) temp.get('validFor');
                    if(controllingFieldValue == null || validFor.contains(validForOfControllingField)) {
                        categories.put((String) temp.get('value'), (String) temp.get('label'));
                    }
                }
            }
            system.debug('current document categories');
            system.debug(categories);
        }
        else {
            InterfaceAPIException ex = new InterfaceAPIException();
            ex.setMessage('Unable to call Salesforce Interface API. ' + '. Status Code - ' + res.getStatusCode() +
                    '. Response Body - ' + res.getBody());
            throw ex;
        }

        return categories;
    }

    /**
     * Method to get the current picklist values of a dependent field on a record using Interface API
     *
     * @param recordId Record Id
     * @param dependentField Fully qualified API name of the dependent field
     * @param userInterfaceAPINamedCredential  Name of Named Credential. Refer to implementation guide on how to set it up.
     *
     * @return ap of API name of the picklist and the label of the picklist
     */
    public static Map<String, String> getCurrentPicklistValuesUsingAPI(Id recordId, String dependentField, String userInterfaceAPINamedCredential) {
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + userInterfaceAPINamedCredential + '/services/data/v53.0/ui-api/record-ui/' + recordId);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        system.debug('Calling api in getCurrentPicklistValuesUsingAPI');
        system.debug(res.getBody());
        Map<String, String> categories = new Map<String, String>();
        if(res.getStatusCode() == 200) {

            Map<String, Object> root = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());

            Map<String, Object> records = (Map<String, Object>) root.get('records');
            Map<String, Object> currentDocNode = (Map<String, Object>) records.get(recordId);
            Map<String, Object> fields = (Map<String, Object>) currentDocNode.get('fields');
            Map<String, Object> categoryField = (Map<String, Object>) fields.get(dependentField);
            if(categoryField == null) {
                InterfaceAPIException ex = new InterfaceAPIException();
                String exceptionMessage = 'Unable to proceed since ' +  dependentField + ' field could not be found on the layout';
                ex.setMessage(exceptionMessage);
                throw ex;
            }
            String categoryDisplayValues = (String) categoryField.get('displayValue');
            String categoryValues = (String) categoryField.get('value');
            if(String.isNotBlank(categoryDisplayValues) && String.isNotBlank(categoryValues)) {
                List<String> displayValues = categoryDisplayValues.split(';');
                List<String> values = categoryValues.split(';');
                if(displayValues != null && values != null && displayValues.size() == values.size()) {
                    for(Integer i = 0; i < displayValues.size() ; i++) {
                        categories.put(values[i], displayValues[i]);
                    }
                }
            }
        }
        else {
            InterfaceAPIException ex = new InterfaceAPIException();
            ex.setMessage('Unable to call Salesforce Interface API. ' + 'Status Code - ' + res.getStatusCode() +
                    'Response Body - ' + res.getBody());
            throw ex;
        }
        system.debug('getCurrentDocumentCategoriesUsingAPI returns....');
        system.debug(categories);
        return categories;

    }


    public class InterfaceAPIException extends Exception {}

    /**
     *  GroupInfo is the wrapper object for holding information related to Group
     */
    global class GroupInfo{
        global String groupName {get; set;}
        global String groupLabel {get; set;}
        global String groupDescription {get; set;}
        global Boolean isActive {get; set;}

        global GroupInfo(){}
    }
}