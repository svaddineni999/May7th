public with sharing class ACLS_Utility {
   

    public static Map<Id, PC_Engagement_Program__c> getEpCode(Set<Id> epIds) {
        Map<Id, PC_Engagement_Program__c> mapEPcode = new Map<Id, PC_Engagement_Program__c>();

        if(Schema.sObjectType.PC_Engagement_Program__c.isAccessible()){   
            mapEPcode = new Map<Id, PC_Engagement_Program__c>([SELECT Id, Name, PC_Program_Code__c FROM PC_Engagement_Program__c WHERE Id = :epIds]);
        }

        return mapEPcode;
    }
    /*
     *  @author	:	Deloitte
     *  @description:	Returns record type ID using Object api name and record type name
     *  @param	:	String
     *  @return	:	Id
     */

    public static Id getRecordTypeId(String objectApiName, String recordTypeName) {
            return Schema.getGlobalDescribe().get(objectApiName).getDescribe().getRecordTypeInfosByDeveloperName()
                        .get(recordTypeName).getRecordTypeId();
    }
    /*
     *  @author	:	Deloitte
     *  @description:	Method to get Map of recordtype and id for a Sobject
     *  @param	:	String
     *  @return	:	Map<String,Id>
     */
    @AuraEnabled
    public static Map<String, Id> getMapOfRecordtype(String objectAPIName) {
        Map<String, Id> mapRecordTypes = new Map<String, Id>();
        if(Schema.sObjectType.Recordtype.isAccessible()){
            for (Recordtype rt : [SELECT Id, developerName FROM Recordtype WHERE SobjectType = :objectAPIName]) {
                mapRecordTypes.put(rt.developerName, rt.Id);
            }
        }
        return mapRecordTypes;
    }

    /*
     *  @author	:	Deloitte
     *  @description:	Method to get Map of recordtype and id for a Sobject
     *  @param	:	String
     *  @return	:	Map<String,Id>
     */
    public static Map<Id, String> getMapOfRecordtypeById(String objectAPIName) {
        Map<Id, String> mapRecordTypes = new Map<Id, String>();
        if(Schema.sObjectType.Recordtype.isAccessible()){
            for (Recordtype rt : [SELECT Id, developerName FROM Recordtype WHERE SobjectType = :objectAPIName]) {
                mapRecordTypes.put(rt.Id, rt.developerName);
            }
        }
        return mapRecordTypes;
    }

    /*
     *  @author	:	Deloitte
     *  @description:	Method to record type id of Sobject on basis of developer name
     *  @param	:	String, String
     *  @return	:	Id
     */
    public static Id getRecordtypeIdByDeveloperName(String objectApiName, String developerName) {
        Id recordTypeId = Schema.getGlobalDescribe().get(objectApiName).getDescribe().getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
        return recordTypeId;
    }
    /*
     *  @author	:	Deloitte
     *  @description:	Method to Create ErrorLogs
     *  @param	:	exception, string, string
     *  @return	:	PC_Error_Log__c
     */
    public static PC_Error_Log__c logErrors(Exception ex,String clsName,String methodName){
      PC_Error_Log__c record = new PC_Error_Log__c(
          PC_Class_Name__c = clsName,
          PC_Method_Name__c = methodName,
          PC_Running_User__c = UserInfo.getUserId(),
          PC_Stack_Trace__c = ex !=null ?ex.getStackTraceString() : '',
          PC_Error_Message__c = ex != null?ex.getMessage() : '',
          PC_Line_Number__c = ex !=null ? ex.getLineNumber() : 0
        );
        
        return record;
    }

    /**
     * Creates and logs an exception instance in the context of the current transaction. If the
     * current transaction is rolled back, the error log record will not be retained.
     *
     * @param e                 The exception to log
     * @param additionalInfo    Additional information to store along with the exception
     *
     * @return  The error log number of the logged exception.
     */
    public static PC_Error_Log__c createExceptionLog(Exception e, String errorMessage, String additionalInfo){
        PC_Error_Log__c errorLog = new PC_Error_Log__c(PC_Error_Datetime__c= DateTime.Now(),
                PC_Error_Message__c= (errorMessage!=null) ? errorMessage : e.getMessage(),
                PC_Running_User__c = UserInfo.getUserId() ,
                PC_Stack_Trace__c = (e!=null) ? '' + e.getStackTraceString() : null,
                PC_Additional_Information__c = additionalInfo);
        return errorLog;
    }
	
    /*
     *  @author	:	Deloitte
     *  @description:	Method to get picklist values in list
     *  @param	:	String, String
     *  @return	:	List<String>
     */
    public static List<String> getPickListValuesIntoList(String objectType, String selectedField) {
        if (String.isNotBlank(objectType) && String.isNotBlank(selectedField)) {
            List<String> pickListValuesList = new List<String>();
            Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(objectType);
            Schema.DescribeSObjectResult res = convertToObj.getDescribe();
            Schema.DescribeFieldResult fieldResult = res.fields.getMap().get(selectedField).getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry pickListVal : ple) {
                pickListValuesList.add(pickListVal.getValue());
            }
            return pickListValuesList;
        } else {
            return null;
        }
    }
    /*
     * @Method Name                    :  createTestUser
     * @Description                    :  Creates a Test User
     * @Return Type                    :  User
     * @Parameters                     :  string profileName, string lastName
     */
    public static User createTestUser(string profileName, string lastName) {
        User usr;
        List<Profile> lProfileId = new List<Profile>();

        if(Schema.sObjectType.Profile.isAccessible()){
            lProfileId = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        }
        if (!lProfileId.isEmpty()) {
            usr = new User(
                alias = 'uqusr',
                email = 'test@testAshfield.com',
                Username = 'test@testAhsfield1.com',
                emailencodingkey = 'UTF-8',
                lastname = lastName,
                languagelocalekey = 'en_US',
                localesidkey = 'en_US',
                ProfileId = lProfileId[0].Id,
                timezonesidkey = 'America/Los_Angeles'
            );
        }
        return usr;
    }
    /*
     * @Method Name                    :  givePermissions
     * @Description                    :  Assigning Permission Set to a User
     * @Return Type                    :  PermissionSetAssignment
     * @Parameters                     :  UserID,PSetName
     */
    public static PermissionSetAssignment assignPermissions(id UserID, string PSetName) {
        PermissionSet ps = new PermissionSet();

        if(Schema.sObjectType.PermissionSet.isAccessible()){
            ps = [SELECT id FROM PermissionSet WHERE Name = :PSetName];
        }
        PermissionSetAssignment psAssignments = new PermissionSetAssignment(AssigneeId = UserID, PermissionSetId = ps.id);
        return psAssignments;
    }

    /*
     * @Method Name                    :  convertDatetoDateTime
     * @Description                    :  Convert Date to DateTime
     * @Return Type                    :  DateTime
     * @Parameters                     :  Date dtvar
     */
    public static DateTime convertDatetoDateTime(Date dtvar) {
        DateTime dtValue = DateTime.newInstance(dtvar.year(), dtvar.month(), dtvar.day(), 11, 0, 0);
        return dtValue;
    }

    /*
     * @Method Name                    :  convertGMTtoEST
     * @Description                    :  Convert GMT DateTime to EST DateTime
     * @Return Type                    :  DateTime
     * @Parameters                     :  DateTime startDate
     */
    public static DateTime convertGMTtoEST(DateTime startDate) {
        System.debug('StartDate '+startDate);
        String startDateESTString = StartDate.format('yyyy-MM-dd HH:mm:ss', 'America/New_York');
        System.debug('startDateESTString '+startDateESTString);
        DateTime startDateEST = DateTime.valueOfGmt(startDateESTString);
        system.debug('startDateEST--' + startDateEST);
        return startDateEST;
    }

    /*
     *  @author	:	Deloitte
     *  @description:Method to get field label from field API
     *  @param	:	String, String
     *  @return	:	String
     */
    public static String getFieldLabelFromFieldAPI(String strObjectName, String strFieldAPI) {
        if (String.isNotBlank(strObjectName) && String.isNotBlank(strFieldAPI)) {
            String strFieldLabel = '';
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType schemaObj = schemaMap.get(strObjectName);
            Map<String, Schema.SObjectField> fieldMap = schemaObj.getDescribe().fields.getMap();
            strFieldLabel = fieldMap.get(strFieldAPI).getDescribe().getLabel();
            return strFieldLabel;
        } else {
            return null;
        }
    }

    /*
     *  @author    :    Deloitte
     *  @description:    Method to create error logs (Integration specific)
     *  @param    :    Exception objException, String strErrorMsg, String strStackTrace, String strAdditionalInfo, String strLogLevel, String strClassName, String strmMethodName, String strRecordId
     *  @return    :    null
     */
    public static void createINTErrorLogs(Exception objException, String strErrorMsg, String strStackTrace, String strAdditionalInfo, String strLogLevel, String strClassName, String strmMethodName, String strRecordId){
        PC_Error_Log_Info__e objErrorLog = new PC_Error_Log_Info__e(
            PC_Error_DateTime__c = DateTime.Now(), 
            PC_Error_Message__c = objException != null ? objException.getMessage() : strErrorMsg, 
            PC_Running_User__c = UserInfo.getUserId(), 
            PC_Stack_Trace__c = objException != null ? objException.getStackTraceString() : strStackTrace, 
            PC_Additional_Information__c = objException != null ? objException.getTypeName() + objException.getCause() + ' .At line: ' + objException.getLineNumber() : strAdditionalInfo,
            PC_Log_Level__c = strLogLevel, 
            PC_Class_Name__c = strClassName,
            PC_Record_ID__c  = strRecordId,
            PC_Method_Name__c = strmMethodName
            );
        System.debug('objErrorLog: '+objErrorLog);
        System.debug('objErrorLog Id: '+objErrorLog.Id);
        Database.SaveResult result = EventBus.publish(objErrorLog);
    }
    public String LogoURL {
        get{
            String Domain=System.URL.getOrgDomainUrl().toExternalForm();
            List<Document> Documnt=new List<Document>();
            if(Schema.sObjectType.Document.isAccessible()){
                Documnt = [Select Id,Name from Document where name='Ashfield logo' limit 1];
            }
            String logoID = Documnt[0].id;

            String OrgID = UserInfo.getOrganizationId();
            String LogoUrl= Domain+'/servlet/servlet.ImageServer?id='+logoID+'&oid='+OrgID;
            
            return LogoUrl;
        }
    }
    
    
    /*
     *  @author    :    Deloitte
     *  @description:    Method to create a Task when any exception occurs during the process flow given a new Inbound Fax is received in CLS or a  new Outbound Fax is being sent out of CLS
     *  @param    :    String Subject,String Category,String SubCategory,Date DueDate, id AssignedTo,id RelatedTo,String Comments
     *  @return    :    Task
     */
    
    public static Task createTask(String Subject,String Category,String SubCategory,Date DueDate, String queueName,id RelatedTo,String Comments){

        Map<String, Id> mapQueueDetails = ACLS_Utility.getQueueDetails();
        Id assignedUserId = (queueName!=null && mapQueueDetails.containsKey(queueName))? mapQueueDetails.get(queueName) : UserInfo.getUserId();
                    

        Task errTask = new Task();
        errTask.WhatId = RelatedTo;
        errTask.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get(ACLS_Constants.PSP_TASK_RECORD_TYPE).getRecordTypeId();
        errTask.Description = Comments;
        errTask.Priority= ACLS_Constants.TASK_PRIORITY_HIGH;
        errTask.Subject= Subject;
        errTask.PC_Category__c= Category;
        errTask.PC_Sub_Category__c = SubCategory;
        errTask.PC_Channel__c= ACLS_Constants.TASK_CHANNEL_TASK;
        errTask.ActivityDate = DueDate;
        errTask.OwnerId = assignedUserId;
        errTask.Status= ACLS_Constants.TASK_STATUS_NOT_STARTED;
        
        return errTask;
        
    }

    /*
     *  @author    :    Deloitte
     *  @description:   Method to query and check the current SFDC environment
     *  @return    :    String
     */
    public static String getCurrentEnvironment(){
        List<PC_Patient_Connect_Setting__mdt> environmentName = new List <PC_Patient_Connect_Setting__mdt> ();
        if(Schema.sObjectType.PC_Patient_Connect_Setting__mdt.isAccessible()){
            environmentName = [Select Id,DeveloperName, PC_SettingValue__c from PC_Patient_Connect_Setting__mdt Where DeveloperName =: ACLS_Constants.ENVIRONMENT_NAME_MDT];       
            System.debug('env name-'+environmentName);
            }
        return (!environmentName.isEmpty())? environmentName[0].PC_SettingValue__c : null;    
}

    /*
     *  @author    :    Deloitte
     *  @description:   Method to query the queue details
     *  @return    :    Map<String, Id>
     */
    public static Map<String, Id> getQueueDetails(){
        Map<String, Id> mapQueueDetails = new Map<String, Id>();
        if(Schema.sObjectType.Group.isAccessible()){
            for(Group g : [SELECT ID, Name, DeveloperName FROM Group WHERE Type = 'Queue']){
                mapQueueDetails.put(g.DeveloperName, g.Id);
            }
    }
        return mapQueueDetails;
    }

    /********************************************************************************************************************
    Method Name    : checkCurrencyValue
    Description    : Convert a String to Currency format
    Return Type    : String
    Parameter      : String
    *********************************************************************************************************************/
    public static String checkCurrencyValue(String value){
        return (value == 'N/A')? value : '$ '+ value;
    }

    /********************************************************************************************************************
    Method Name    : convertToDecimalFormat
    Description    : Convert a String to Decimal format
    Return Type    : Decimal
    Parameter      : String
    *********************************************************************************************************************/
    public static Decimal convertToDecimalFormat(String value){
        return (value!=null && value!='' && value!='N/A')? Decimal.valueOf(value) : null;
    }

    /********************************************************************************************************************
    Method Name    : convertToDateFormat
    Description    : Convert a String to Date format
    Return Type    : Date
    Parameter      : String
    *********************************************************************************************************************/
    public static Date convertToDateFormat(String value){
        return (value!=null && value!='' && value!='N/A')? Date.valueOf(value) : null;
    }
    
    
    /********************************************************************************************************************
    Method Name    : getIntegrationConfigs
    Description    : get list of Integration Config
    Return Type    : List
    Parameter      : 
*********************************************************************************************************************/
     public static ACLS_IntegrationConfig__mdt getIntegrationConfigs(String name, String environment){
        List<ACLS_IntegrationConfig__mdt> apiDetails = new List<ACLS_IntegrationConfig__mdt> ();
        if(Schema.sObjectType.ACLS_IntegrationConfig__mdt.isAccessible()){
            apiDetails = [Select Id,ACLS_IntegrationName__c,ACLS_Integration_Procedure_Name__c,ACLS_Environment__c,ACLS_BaseURL__c,ACLS_Endpoint__c,ACLS_APIKey__c,ACLS_Headers__c,ACLS_Timeout__c from ACLS_IntegrationConfig__mdt Where ACLS_IntegrationName__c =:name and ACLS_Environment__c =:environment];
        }
        return (!apiDetails.isEmpty())? apiDetails[0]: null; 
    }
    /********************************************************************************************************************
    Method Name    : getContentDocumentLink
    Description    : get list of Content Document Link records
    Return Type    : Map<Id, ContentDocumentLink>
    Parameter      : List<Id> parentId
 *********************************************************************************************************************/
    public static Map<Id, ContentDocumentLink> getContentDocumentLink(List<Id> parentId)
    {   
        Map<Id, ContentDocumentLink> mapParentVsCDL = new Map<Id, ContentDocumentLink>();
        if(Schema.sObjectType.ContentDocumentLink.isAccessible()){
            for(ContentDocumentLink cdl : [Select ContentDocumentId,LinkedEntityId FROM ContentDocumentLink Where LinkedEntityId = :parentId WITH SECURITY_ENFORCED LIMIT 1]){
                mapParentVsCDL.put(cdl.LinkedEntityId, cdl);
            }
    }
        return mapParentVsCDL;
    } 
}