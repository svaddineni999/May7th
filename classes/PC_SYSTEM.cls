/*********************************************************************************
----------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------------
Deloitte               April 1, 2015              Initial Version
Alina Balan            August 08, 2016            Added "recordTypeName" method
Ajinkya Deshmukh	   January 26, 2017			  Added getAllRecordType() method
Prachi Nandgaonkar     March 3, 2017              Added getRecordTypeIdByName() and getRecordTypeName() to be used in all triggers for retrieving record type id without SOQL [PC-1242]
Shabda Bhujad          May 10,2017                Added the clause to query active recordtypes only in the method getAllRecordType [PC-1523]
Ajinkya Deshmukh	   June 08, 2017			  Removed isMigration and isPortalUser setter, class made With Sharing
Tejas Patel            Jul 06,2017                Removed SOQL, for loop and variable from the class recordTypeId and recordTypeName
Mayuresh Patil         Jul 11,2017                PC-1855 Added code to work for translation getRecordTypeInfoById
Tejas Patel            July 25 2017               [PC-1927],[PC-1928],[PC-1918] Translation Issues
Mayuresh Patil         Aug 18,2017                PC-1898 Added method recordTypeDeveloperNameById
Shabda Bhujad		   Oct 05,2017				  PC-2335 Deleted getRecordTypeIdByName, getRecordTypeName method which has been deprecated and used recordTypeId method instead
Mike Klumpenaar        Jan 29, 2018               PC-2698 Added new recordTypeId and recordTypeName methods that include namespace and defaulted old methods to package namespace.
Vijay Kashikar         Nov 29, 2018               PC-3649 Added new methods - recordTypeDeveloperNameAndNamespaceById, isHealthCloudIndividualRecordType
Mike Klumpenaar        Feb 20, 2019               [PC-4475] Make class and subset of methods global and convert to apex doc. Also fixed implmentation of getAllRecordTypes without namespace
Vijay Kashikar         Mar 04, 2019               [PC-4426] Updated isHealthCloudIndividualRecordType to handle case when individual mapper does not exist.
Hitha Avalakki         Mar 14,2019                [PC-4147] Added new methods to fetch Account Identifier field values dynamically.
Shishir Bansal         Mar 27, 2019               [PC-4147] Added method to the PC_System class for Masking patient SSN
Hitha Avalakki         May 31, 2019               [PC-4763] Added a method to fetch active metadata records from PC_Document_Link_Related_Object_Setting__mdt custom metadata
Hitha Avalakki         May 31, 2019               [PC-4763] Added a method to fetch account record type details
Haritha Reddy          Jun 11, 2019               [PC-4910] Added methods to fetch value given in Patient Connect settings "PC_UseSalesforceFiles", "PC_DocumentPreviewStrictMode".
Tushar Arora           Jul 31,2019                [PC-5179] Added isPersonAccountExists method for checking ispersonaccount field in Schema.
Tushar Arora           Aug 05,2019                [PC-5255] Updated conditions in isPersonAccountEnabled method.
Tushar Arora           Aug 12,2019                [PC-5255] Updated conditions in isPersonAccountEnabled method and added isPatientPersonAccountRecordType method to check patient recordtype is person account recordtype.
Tushar Arora           Aug 13,2019                [PC-5308] Modified Conditions for PersonAccount Enablement Method.
Tushar Arora           Aug 13,2019                [PC-5255] Code Refinement For Person Account.
Vijay Kashikar         Aug 20,2019                [PC-5330] Made changes to isPatientPersonAccountRecordTypeExists to read record type
                                                  from Patient Connect setting.
Hitha Avalakki         Sep 05, 2019               [PC-5415] Added a new method callout 'getSpecificAccountRecordTypeDetails' to get record type details
                                                  of specific account record types.
Vijay Kashikar         Sep 20, 2019               [PC-5498] updated recordTypeId method to handle NULL or blank namespace case for Person Account record type.
Tejas Patel            13 Dec 2019                [PC-5831] getStatusAttribute class added we send the set of closed or default status
Hitha Avalakki         Jan 24, 2020               [PC-5945] Added two new methods: recordTypeId(String objectName, List<String> developerNameList) and getRecordTypeFromSchema
                                                  to fetch recordtype id details using Schema.RecordTypeInfo class in order to prevent SOQL query hit issue.
Haritha Reddy          Jul 07, 2020               [PC-6455] Moved getAllOperatorMap method to PC_AutomationTaskHelper class which is specific to Support Plan
                                                    and also this is not being generally used.
Satheesh Kumar         Nov 24, 2020               [PC-7053] Added FLS Check to getEmailTemplateDetails method
Hitha Avalakki         Feb 26, 2021              [PC-7442] Added getProgramCaseRecordTypeNamespace(),getProgramCaseRecordTypeId() methods to fetch configured/default program case record type developer name and program case record type namespace
Hitha Avalakki         Feb 26, 2021              [PC-7442] Added getProgramCaseRecordTypeDeveloperName() method to fetch configured/default program case record type developer name
Hitha Avalakki         Mar 01, 2021              [PC-7442] Removed redundant code from getProgramCaseRecordTypeDeveloperName() and getProgramCaseRecordTypeNamespace()
Hitha Avalakki         Mar 02, 2021              [PC-7442] Added comments to methods getProgramCaseRecordTypeDeveloperName() and getProgramCaseRecordTypeNamespace()
                                                           in order to use the corresponding constants defined in PC_Constants instead of using these methods
Hitha Avalakki         Mar 04,2021               [PC-7442] 1) Moved methods:getProgramCaseRecordTypeDeveloperName(),getProgramCaseRecordTypeNamespace() to PC_Constants class.
                                                           2) Removed method: getProgramCaseRecordTypeId() and added getDefaultProgramCaseRecordTypeId()
Hitha Avalakki         Mar 04,2021               [PC-6067] Added getProgramRecordTypeIdBasedOnEngProgramId(String engagementProgId), getProgramRecordTypeIdBasedOnEngProgramCode(String engagementProgCode),getProgramRecordTypeIdForEngagementProgram(List<PC_Engagement_Program__c> engagementProgramsList)
Hitha Avalakki         Mar 12,2021               [PC-6067] Formulate an exception message using values of PC_Constants.CASE_PROGRAM_RECORD_TYPE and PC_Constants.CASE_PROGRAM_RECORD_TYPE_NAMESPACE.
Haritha Reddy          Mar 23,2021               [PC-7010] Added new method to get Trigger handler register list that are configured for an sObject
Chetna Mohapatra       Apr 01,2021               [PC-7546] Added new method getIntegrationSetting() to get the value for each of those settings from the custom metadata.
Hitha Avalakki         Oct 12,2021               [PC-8197] Added method to fetch if salesforce file or attachment needs to be used for any functionality
Haritha Reddy          Oct 12,2021               [PC-8161] Added new method isHealthCloudIndividualRecordType to check if corresponding individual mapper is configured for a account record type.
Vijay Kashikar         Jul 05, 2022              [PC-8722] Queried DeveloperName and NamespacePrefix in getTriggerHandlerRegisters method to support bypassing of Trigger Handler Registers
Vijay Kashikar         Jul 06, 2022              [PC-8908] Refined getPatientConnectSettings() and getIntegrationSettings() to avoid SOQL query when the value is less than 255 characters
*********************************************************************************/

/**
 * Utility methods used for getting system level information.
 * @date 2015-04-01
 */
global with sharing class PC_SYSTEM {
    //TODO: move this and related static methods to
    private static String triggerSource;

    /**
     * Sets the source of the Trigger
     * @param source String to store Source
     */
    public static void setTriggerSource(String source) {
        if (triggerSource == null)
            triggerSource = source;
    }
    /**
     * Get the source of the Trigger
     */
    public static String getTriggerSource() {
        return triggerSource == null ? '' : triggerSource;
    }

    /**
     * Check if the given Source is same as TriggerSource
     *
     * @param source source to compare
     */
    public static Boolean isTriggerSource(String source) {
        return source == triggerSource;
    }

    /**
     * Returns the Id of the RecordType on the given object with the specified developer name
     * in the current Patient Connect namespace (e.g. PatientConnect).
     *
     * @param objectName    The name of the object that contains the record type
     * @param developerName The developer name of the record type
     */
    global static Id recordTypeId(String objectName, String developerName){
        if(objectName.equals(PC_Constants.PATIENT_OBJECT) && developerName.equals(PC_Constants.PATIENT_RECORD_TYPE) &&  isPersonAccountEnabled())
           return recordTypeId(objectName, developerName, getPersonAccountNamespace());
        else{

            Id recordTypeId;
            Map<String,Id> recordTypeDevNameRecordTypeIdMap =  new Map<String,Id>();

            List<String> recordTypeDevNamesList = new List<String>();
            recordTypeDevNamesList.add(developerName);

            try{
                /* Get Map of record type developerName(as key) and record type id(as value) from the below callout. */
                recordTypeDevNameRecordTypeIdMap = getRecordTypeFromSchema(objectName ,recordTypeDevNamesList,PC_Constants.OrgNamespace);

                recordTypeId = recordTypeDevNameRecordTypeIdMap.get(developerName);
            }
            catch (Exception ex){
                PC_Utility.logAndThrowException(ex);
            }

            return recordTypeId;
        }

    }

    /*********************************************************************************
    @MethodName    : recordTypeId
    @Description   : Method to get record type details from Schema
    @Parameter     : SString, List<String>
    @ReturnType    : Map<String, Id>
    @Author        : Hitha Avalakki
    @UserStory     : PC-5945
    *********************************************************************************/
    public static Map<String, Id> recordTypeId(String objectName, List<String> developerNameList){
        /* Following Map would contain record type developer name as key and its corresponding record type id as value */
        Map<String,Id> recordTypeDevNameRecordTypeIdMap;

        /* Following is required to remove duplicate entries of same record type developer name */
        Set<String> recordTypeDeveloperNamesSet = new Set<String>(developerNameList);
        developerNameList = new List<String>(recordTypeDeveloperNamesSet);

        /* if condition: Used to create a Map of record type developer name(key) and record type id(value) for Account object
        *  else condition: Used to create a Map of record type developer name(key) and record type id(value) for objects other than Account ***/
        if(objectName.equalsIgnoreCase(PC_Constants.PATIENT_OBJECT) && !developerNameList.isEmpty())
        {
            /* Map of record type developer names(as key) and record type developer ids(as value) */
            recordTypeDevNameRecordTypeIdMap =  new Map<String,Id>();

            /* List of person account enabled record types of Account object */
            List<String> personAccountEnabledRecordTypeDevNameList =  new List<String>();

            /* List of record types other than person account enabled record types of Account object */
            List<String> nonPersonAccountEnabledRecordTypeDevNameList =  new List<String>();

            for(String recordTypeDeveloperName: developerNameList){

                /***if condition: To check if the patient record type returned by 'PC_Constants.PATIENT_RECORD_TYPE' is person account record type, we need to use isPersonAccountEnabled() callout.
                    else condition: populate record types which are other than person account record types.This can contain any sobject's record types like Account's, Case's , etc ***/
                if(recordTypeDeveloperName.equalsIgnoreCase(PC_Constants.PATIENT_RECORD_TYPE) && isPersonAccountEnabled()){
                    personAccountEnabledRecordTypeDevNameList.add(PC_Constants.PATIENT_RECORD_TYPE);
                }
                else{
                    nonPersonAccountEnabledRecordTypeDevNameList.add(recordTypeDeveloperName);
                }
            }

            if(personAccountEnabledRecordTypeDevNameList!= null && !personAccountEnabledRecordTypeDevNameList.isEmpty()){

                /* Get the Map of person account record type developer names and corresponding record type id values and populate in the final Map 'recordTypeDevNameRecordTypeIdMap' */
                recordTypeDevNameRecordTypeIdMap = getRecordTypeFromSchema(objectName, personAccountEnabledRecordTypeDevNameList, getPersonAccountNamespace());
            }
            if(nonPersonAccountEnabledRecordTypeDevNameList!=null && !nonPersonAccountEnabledRecordTypeDevNameList.isEmpty()){

                /* Map of record types other than person account record types and corresponding record type id values */
                Map<String,Id> personAccountEnabledRecordTypeDevNameRecordTypeIdMap = new Map<String, Id>();

                /* Get the Map of non person account record type developer names and corresponding record type id values and populate in the final Map 'recordTypeDevNameRecordTypeIdMap' */
                personAccountEnabledRecordTypeDevNameRecordTypeIdMap = getRecordTypeFromSchema(objectName ,nonPersonAccountEnabledRecordTypeDevNameList,PC_Constants.OrgNamespace);

                if(personAccountEnabledRecordTypeDevNameRecordTypeIdMap != null && !personAccountEnabledRecordTypeDevNameRecordTypeIdMap.isEmpty()){
                    recordTypeDevNameRecordTypeIdMap.putAll(personAccountEnabledRecordTypeDevNameRecordTypeIdMap);
                }
            }
        }
        else{

            recordTypeDevNameRecordTypeIdMap =  new Map<String,Id>();

            /* Get the Map of record type developer names and corresponding record type id values from objects other than Account */
            recordTypeDevNameRecordTypeIdMap = getRecordTypeFromSchema(objectName ,developerNameList,PC_Constants.OrgNamespace);
        }

        return recordTypeDevNameRecordTypeIdMap;
    }
    /**
     * Returns the Id of the RecordType on the given object with the specified developer name
     * and namespace prefix.
     *
     * @param objectName    The name of the object that contains the record type
     * @param developerName The developer name of the record type
     * @param namespacePrefix   The namespace prefix of the record type, or <code>null</code> if the record type
     *                          is not in a package with a namespace.
     */
    global static Id recordTypeId(String objectName, String developerName, String namespacePrefix) {
        RecordType rt = new RecordType();
        String strRecordTypeQuery = 'Select id from RecordType Where ' ;

        try{
            if (objectName.equalsIgnoreCase(PC_Constants.PATIENT_OBJECT) && developerName.equalsIgnoreCase(PC_Constants.PATIENT_RECORD_TYPE) && isPersonAccountEnabled()) {
                String personPatientNs = getPersonAccountNamespace();
                system.debug(personPatientNs);
                if (((namespacePrefix == '' || namespacePrefix == NULL)
                        && (personPatientNs == '' || personPatientNs == NULL))
                        || personPatientNs.equalsIgnoreCase(namespacePrefix)) {
                    strRecordTypeQuery += ' sObjectType =: objectName and IsPersonType= true and developerName =: developerName and NamespacePrefix = :namespacePrefix and isActive= true';
                } else {
                    PC_Utility.logAndThrowException(new HealthCloudPersonAccountException('No Individual Mapper Entry Found for RecordType ' + developerName +
                            ' with NamespacePrefix ' + (String.isNotBlank(namespacePrefix) ? namespacePrefix : '(blank)')));
                }

            } else {
                strRecordTypeQuery += ' SobjectType = :objectName AND DeveloperName = :developerName AND NamespacePrefix = :namespacePrefix AND isActive= true';
            }
            rt = Database.query(strRecordTypeQuery);
        }
        catch (Exception ex){
            PC_Utility.logAndThrowException(new RecordTypeException('Error occurred while fetching record type Id for record type: '+developerName+' of sObject: '+objectName+' for namespaceprefix: '+namespacePrefix));
            return NULL;
        }
        
        return rt.Id;
    }

    /**
     * Returns the Name of the RecordType on the given object with the specified developer name
     * in the current Patient Connect namespace (e.g. PatientConnect).
     *
     * @param objectName    The name of the object that contains the record type
     * @param developerName The developer name of the record type
     */
    public static String recordTypeName(String objectName, String developerName){
        if(objectName.equals(PC_Constants.PATIENT_OBJECT) && developerName.equals(PC_Constants.PATIENT_RECORD_TYPE) &&  isPersonAccountEnabled())
            return recordTypeName(objectName, developerName, getPersonAccountNamespace());
        else
            return recordTypeName(objectName, developerName, PC_Constants.OrgNamespace);
    }

    /**
     * Returns the Name of the RecordType on the given object with the specified developer name
     * and namespace prefix.
     *
     * @param objectName    The name of the object that contains the record type
     * @param developerName The developer name of the record type
     * @param namespacePrefix   The namespace prefix of the record type, or <code>null</code> for
     *                          unpackaged record types.
     */
    public static String recordTypeName(String objectName, String developerName, String namespacePrefix) {
        RecordType rt = new RecordType();
        String strRecordTypeQuery = 'Select Name from RecordType Where ' ;
        if(objectName.equals(PC_Constants.PATIENT_OBJECT) && developerName.equals(PC_Constants.PATIENT_RECORD_TYPE) && isPersonAccountEnabled()){
            if(namespacePrefix.equalsIgnoreCase(getPersonAccountNamespace())){
                strRecordTypeQuery += ' sObjectType =: objectName and IsPersonType=True and developerName =: developerName AND NamespacePrefix = : ' + getPersonAccountNamespace() ;
            }
            else {
                PC_Utility.logAndThrowException(new HealthCloudPersonAccountException('Not able to find Patient Person Account RecordType ' + developerName +
                ' with NamespacePrefix ' + (String.IsBlank(namespacePrefix) ? '(blank)' : namespacePrefix) ));
            }
        }
        else{
            strRecordTypeQuery += ' SobjectType = :objectName AND DeveloperName = :developerName AND NamespacePrefix = :namespacePrefix';
        }
        rt = Database.query(strRecordTypeQuery);
        return rt == NULL ? NULL : rt.Name;
    }

    /**
     * Returns a record type DeveloperName for a given record type Id
     *
     * TODO: get rid of object name, since it isn't needed
     *
     * @param pObjName      The name of the object
     * @param pRecordTypeId The Id of the record type
     */
    public static String recordTypeDeveloperNameById(String pObjName, String pRecordTypeId){
        RecordType rt = [SELECT DeveloperName FROM RecordType WHERE SobjectType = :pObjName AND Id = :pRecordTypeId];
        return rt == NULL ? NULL : rt.DeveloperName;
    }

    /**
     * Returns a map containing the Record Type Developer Name and Namespace Prefix
     * for the given record Type Id
     *
     * TODO: just return the RecordType object
     *
     * @param pRecordTypeId The Id of the record type
     */
    public static Map<String, String> recordTypeDeveloperNameAndNamespaceById(String pRecordTypeId){
        RecordType rt = [Select DeveloperName, NamespacePrefix From RecordType Where Id = :pRecordTypeId LIMIT 1];
        if(rt == null) {
            return null;
        }
        else {
            Map<String, String> keyValue = new Map<String, String>();
            keyValue.put(PC_Constants.NAMESPACE_KEY, rt.NamespacePrefix );
            keyValue.put(PC_Constants.RECORD_TYPE_DEV_NAME_KEY, rt.DeveloperName);
            return keyValue;
        }
    }

    /**
     * Returns record type name for a record type in an object based on the record type Id
     * without using SOQL.
     *
     * @param objectAPIName Object name
     * @param recordTypeId  Record type Id
     *
     * @author Mayuresh Patil
     */
    public static String getRecordTypeNameById(String objectAPIName, Id recordTypeId){
        //If object name or record type label is blank
        if(String.isBlank(objectAPIName) || String.isBlank(recordTypeId)){
            return null;
        }

        //Generate a map of tokens for the sObjects
        Map<String, Schema.SObjectType> sobjectSchemaMap = Schema.getGlobalDescribe();

        //Get the desired sObject using the object API Name
        Schema.SObjectType sObjType = sobjectSchemaMap.get(objectAPIName);

        //Retrieve the describe result for the desired objec
        Schema.DescribeSObjectResult cfrSchema = sObjType.getDescribe() ;

        //Generate a map of tokens for all the Record Types for the desired object
        Map<Id,Schema.RecordTypeInfo> RecordTypeInfo = cfrSchema.getRecordTypeInfosById();

        //Retrieve the record type name by id
        String rtName = RecordTypeInfo.get(recordTypeId).getName();
        return rtName;
    }

    /**
     * Returns all active record types in the given object type.
     *
     * @param objectType    The object type
     */
    global static List<RecordType> getAllRecordType(String objectType){
        List<RecordType> allRecordTypes = [
                SELECT Id, toLabel(Name), DeveloperName, NamespacePrefix
                FROM RecordType WHERE SobjectType =: objectType AND IsActive = true];
        return allRecordTypes;
    }

    /**
     * Returns all active record types in an object type with a given namespace prefix.
     *
     * @param objectType        The object type
     * @param namespacePrefix   The namespace prefix
     */
    global static List<RecordType> getAllRecordType(String objectType, String namespacePrefix){
        List<RecordType> allRecordTypes = [
                SELECT Id, toLabel(Name), DeveloperName, NamespacePrefix
                FROM RecordType WHERE SobjectType =: objectType AND IsActive = true AND NamespacePrefix = :namespacePrefix];
        return allRecordTypes;
    }

    /**
     *
     *
     * @param settingName The name of the setting
     * @param defaultValue The value to return if the setting is not defined.
     *
     * @return Value of the setting
     */
    public static String getPatientConnectSetting(String settingName, String defaultValue){
        String  settingValue;
        if(String.isNotBlank(settingName)) {
            String qualifiedAPIName = getPatientConnectSettingQualifiedAPIName(settingName);
            PC_Patient_Connect_Setting__mdt pcSetting = PC_Patient_Connect_Setting__mdt.getInstance(qualifiedAPIName);
            if(
                    pcSetting == NULL ||
                    pcSetting.PC_Active__c == false ||
                    String.isBlank(pcSetting.PC_SettingValue__c)
                    )
            {
                settingValue = defaultValue;
            }
            else if(pcSetting.PC_SettingValue__c.length() < 255) {
                settingValue = pcSetting.PC_SettingValue__c;
            }
            else {
                settingValue = getPatientConnectSettingUsingSOQL(settingName, defaultValue);
            }
        }
        else {
            settingValue = defaultValue;
        }
        return  settingValue;
    }
    /**
     * Returns the Qualifield API name of the Patient Connect Setting Name
     *
     * @param settingName Patient Connect Setting Name (PC_SettingName__c of PC_Patient_Connect_Setting__mdt)
     *
     * @return Qualifield API name
     */
    private static String getPatientConnectSettingQualifiedAPIName(String settingName) {
        String developerName = settingName;
        if(settingName == PC_Constants.PC_PersonAccountPatientNamespaceSettingName) {
            developerName = PC_Constants.PC_PersonAccountPatientNamespaceDeveloperName;
        }
        // Add more else-if's if the Developer name is different from the Setting Name.
        return developerName;
        //return getSettingQualifiedAPIName(developerName);
    }
    /**
     * Returns the Qualifield API name of the Integration Setting Name
     *
     * @param settingName Integration Setting Name (PC_SettingName__c of PC_IntegrationSetting__mdt)
     *
     * @return Qualifield API name
     */
    private static String getIntegrationSettingQualifiedAPIName(String settingName) {
        String developerName = settingName;
        // Add if else-if's, if the Developer name is different from the Setting Name.
        return developerName;
        //return getSettingQualifiedAPIName(developerName);
    }
    /**
     * Returns the Qualified API name (Appends the namespace, if available)
     *
     * @param developerName Developer Name of the setting
     *
     * @return Qualified API name
     */
    private static String getSettingQualifiedAPIName(String developerName) {
        return PC_Constants.getQualifiedAPIName(developerName);
    }
    /**
     * Returns the value of a Patient Connect system setting in the PC_Patient_Connect_Setting
     * custom metadata type.
     *
     * @param settingName   The name of the setting
     * @param defaultValue  The value to return if the setting is not defined.
     *
     * @author Tejas Patel
     */
    private static String getPatientConnectSettingUsingSOQL(String settingName, String defaultValue) {
        system.debug('Querying for ' + settingName);
        String  settingValue;
        LIST<PC_Patient_Connect_Setting__mdt> pcSetting = [
                SELECT PC_SettingValue__c
                FROM PC_Patient_Connect_Setting__mdt
                WHERE PC_Active__c = TRUE AND PC_SettingName__c =: settingName];
        if (pcSetting.size() == 0) {
            settingValue = defaultValue;
        } else {
            if (String.isBlank(pcSetting[0].PC_SettingValue__c)) {
                settingValue = defaultValue;
            } else {
                settingValue = pcSetting[0].PC_SettingValue__c;
            }
        }
        return settingValue;
    }
    /**
     *
     *
     * @param settingName The name of the setting
     * @param defaultValue The value to return if the setting is not defined.
     *
     * @return Value of the setting
     */
    public static String getIntegrationSetting(String settingName, String defaultValue){
        String  settingValue;
        if(String.isNotBlank(settingName)) {
            String qualifiedAPIName = getIntegrationSettingQualifiedAPIName(settingName);
            PC_IntegrationSetting__mdt setting = PC_IntegrationSetting__mdt.getInstance(qualifiedAPIName);
            if(
                    setting == NULL ||
                    setting.PC_Active__c == false ||
                    String.isBlank(setting.PC_SettingValue__c)
                    )
            {
                settingValue = defaultValue;
            }
            else if(setting.PC_SettingValue__c.length() < 255) {
                settingValue = setting.PC_SettingValue__c;
            }
            else {
                settingValue = getIntegrationSettingUsingSOQL(settingName, defaultValue);
            }
        }
        else {
            settingValue = defaultValue;
        }
        return  settingValue;

    }

    /**
    * Returns the value of an Integration setting in the PC_IntegrationSetting__mdt
    * custom metadata type.
    *
    * @param settingName   The name of the setting
    * @param defaultValue  The value to return if the setting is not defined.
    *
    * @author Chetna Mohapatra
    */
    private static String getIntegrationSettingUsingSOQL(String settingName, String defaultValue){
        system.debug('Querying for ' + settingName);
        String  settingValue;
        LIST<PC_IntegrationSetting__mdt> integrationSetting = [
                SELECT PC_SettingValue__c
                FROM PC_IntegrationSetting__mdt
                WHERE PC_Active__c = TRUE AND PC_SettingName__c =: settingName];
        if(integrationSetting.size() == 0){
            settingValue = defaultValue;
        }else {
            if(String.isBlank(integrationSetting[0].PC_SettingValue__c)){
                settingValue = defaultValue;
            }else{
                settingValue = integrationSetting[0].PC_SettingValue__c;
            }
        }
        return  settingValue;
    }

    /**
    * Returns the Protected Api Value of an Protected Api Setting in the PC_ProtectedApiSettings__c custom setting.
    * @param settingName   The name of the Protected Api setting
    * @author Satheesh Kumar
    */
    public static String getProtectedApiSetting(String settingName) {
        String settingValue = PC_Constants.EMPTY_STRING;
        Map<String, PC_ProtectedApiSettings__c> protectedApiSettingsMap = PC_ProtectedApiSettings__c.getAll();
        PC_ProtectedApiSettings__c protectedApiSettings = protectedApiSettingsMap.get(settingName);
        if (protectedApiSettings != null && String.isNotBlank(protectedApiSettings.PC_ProtectedApiValue__c)) {
            settingValue = protectedApiSettings.PC_ProtectedApiValue__c;
        }
        return settingValue;
    }

    /**
    * Returns the value of either Patient Connect Setting or Integration setting
    * from custom metadata type PC_EngagementProgramSettings__mdt
    *
    * @param engagementProgramCode  Engagement Program Code whose setting value needs to be fetched
    * @param settingName Name of either the Patient Connect Setting Name or the Integration Setting Name
    * @param settingType Type of the setting (either Patient Connect Setting or Integration Setting?)
    * @param defaultValue  Default value to be returned if no value is found.
    *
    * @author Vijay Kashikar
    */
    public static String getSettingByEngagementProgram(String engagementProgramCode,
            String settingName, PC_Constants.SETTINGS_TYPE settingType, String defaultValue)
    {
        List<PC_EngagementProgramSetting__mdt> settings;
        if(settingType == PC_Constants.SETTINGS_TYPE.PATIENT_CONNECT_SETTING) {
            return getPatientConnectSettingByEngagementProgram(engagementProgramCode, settingName, defaultValue);
        }
        else if (settingType == PC_Constants.SETTINGS_TYPE.INTEGRATION_SETTING){
            return getIntegrationSettingByEngagementProgram(engagementProgramCode, settingName, defaultValue);
        }
        else {
            return defaultValue;
        }
    }

    /**
    * Returns the value of either Patient Connect Setting or Integration setting
    * from custom metadata type PC_EngagementProgramSettings__mdt
    *
    * @param engagementProgramCode  Set of Engagement Program Code whose setting value needs to be fetched
    * @param settingName Name of either the Patient Connect Setting Name or the Integration Setting Name
    * @param settingType Type of the setting (either Patient Connect Setting or Integration Setting?)
    * @param defaultValue  Default value to be returned if no value is found.
    *
    * @author Tejas Patel
    */
    public static Map<String,String> getSettingByEngagementProgram(Set<String> engagementProgramCode,
            String settingName, PC_Constants.SETTINGS_TYPE settingType, String defaultValue)
    {
        Map<String,String> engToDefaultValue = new Map<String,String>();
        List<PC_EngagementProgramSetting__mdt> settings;
        if(settingType == PC_Constants.SETTINGS_TYPE.PATIENT_CONNECT_SETTING) {
            return getPatientConnectSettingByEngagementProgram(engagementProgramCode, settingName, defaultValue);
        }
        else if (settingType == PC_Constants.SETTINGS_TYPE.INTEGRATION_SETTING){
            return getIntegrationSettingByEngagementProgram(engagementProgramCode, settingName, defaultValue);
        }
        else {
            for(String eId : engagementProgramCode){
                engToDefaultValue.put(eId,defaultValue);
            }
            return engToDefaultValue;
        }
    }

    private static String getPatientConnectSettingByEngagementProgram(String engagementProgramCode,
            String settingName, String defaultValue) {
        final String SETTING_TYPE_PATIENT_CONNECT = 'Patient Connect Setting';
        List<PC_EngagementProgramSetting__mdt> settings;
        settings = [
                SELECT PC_SettingValue__c, PC_PatientConnectSetting__r.PC_SettingValue__c
                FROM PC_EngagementProgramSetting__mdt

                WHERE PC_IsActive__c = true
                AND PC_SettingType__c = :SETTING_TYPE_PATIENT_CONNECT

                AND PC_EngagementProgram__r.PC_IsActive__c = true
                AND PC_EngagementProgram__r.PC_EngagementProgramCode__c = :engagementProgramCode

                AND PC_PatientConnectSetting__r.PC_Active__c = true
                AND PC_PatientConnectSetting__r.PC_IsOverridable__c = true
                AND PC_PatientConnectSetting__r.PC_SettingName__c = :settingName LIMIT 1
        ];
        if(settings == null || settings.isEmpty()) {
            return getPatientConnectSetting(settingName, defaultValue);
        }
        else {
            return settings[0].PC_SettingValue__c;
        }

    }

    /**
    * Returns the value of either Patient Connect Setting or Integration setting
    * from custom metadata type PC_EngagementProgramSettings__mdt
    *
    * @param engagementProgramCode  Set of Engagement Program Code whose setting value needs to be fetched
    * @param settingName Name of either the Patient Connect Setting Name or the Integration Setting Name
    * @param settingType Type of the setting (either Patient Connect Setting or Integration Setting?)
    * @param defaultValue  Default value to be returned if no value is found.
    *
    * @author Tejas Patel
    */

    private static Map<String,String> getPatientConnectSettingByEngagementProgram(Set<String> engagementProgramCode,
            String settingName, String defaultValue) {
        final String SETTING_TYPE_PATIENT_CONNECT = 'Patient Connect Setting';
        List<PC_EngagementProgramSetting__mdt> settings;
        Map<String,String> engToDefaultValue = new Map<String,String>();
        settings = [
                SELECT PC_SettingValue__c, PC_PatientConnectSetting__r.PC_SettingValue__c, PC_EngagementProgram__r.PC_EngagementProgramCode__c
                FROM PC_EngagementProgramSetting__mdt

                WHERE PC_IsActive__c = true
                AND PC_SettingType__c = :SETTING_TYPE_PATIENT_CONNECT

                AND PC_EngagementProgram__r.PC_IsActive__c = true
                AND PC_EngagementProgram__r.PC_EngagementProgramCode__c IN :engagementProgramCode

                AND PC_PatientConnectSetting__r.PC_Active__c = true
                AND PC_PatientConnectSetting__r.PC_IsOverridable__c = true
                AND PC_PatientConnectSetting__r.PC_SettingName__c = :settingName
        ];
        if(Test.isRunningTest()){
            settings.addAll(PC_Test_Setup.createUnassignedTaskTriage(PC_Constants.PC_UNASSIGNED_TASK_TRIAGE, SETTING_TYPE_PATIENT_CONNECT));
        }
        string tempDefaultValue = getPatientConnectSetting(settingName, defaultValue);

        for(String eng : engagementProgramCode){
            for(PC_EngagementProgramSetting__mdt s : settings){
                if(s.PC_EngagementProgram__r.PC_EngagementProgramCode__c == eng && String.isNotBlank(s.PC_SettingValue__c)){
                    engToDefaultValue.put(s.PC_EngagementProgram__r.PC_EngagementProgramCode__c,s.PC_SettingValue__c);
                }else if (s.PC_EngagementProgram__r.PC_EngagementProgramCode__c == eng && String.isBlank(s.PC_SettingValue__c)){
                    engToDefaultValue.put(s.PC_EngagementProgram__r.PC_EngagementProgramCode__c,tempDefaultValue);
                }
            }
            if(!engToDefaultValue.containsKey(eng)){
                engToDefaultValue.put(eng,tempDefaultValue);
            }
        }
        return engToDefaultValue;
    }

    private static String getIntegrationSettingByEngagementProgram(String engagementProgramCode,
            String settingName, String defaultValue) {
        final String SETTING_TYPE_INTEGRATION_SETTING = 'Integration Setting';
        List<PC_EngagementProgramSetting__mdt> settings;
        settings = [
                SELECT PC_SettingValue__c, PC_IntegrationSetting__r.PC_SettingValue__c
                FROM PC_EngagementProgramSetting__mdt

                WHERE PC_IsActive__c = true
                AND PC_SettingType__c = :SETTING_TYPE_INTEGRATION_SETTING

                AND PC_EngagementProgram__r.PC_IsActive__c = true
                AND PC_EngagementProgram__r.PC_EngagementProgramCode__c = :engagementProgramCode

                AND PC_IntegrationSetting__r.PC_Active__c = true
                AND PC_IntegrationSetting__r.PC_IsOverridable__c = true
                AND PC_IntegrationSetting__r.PC_SettingName__c = :settingName LIMIT 1
        ];
        if(settings == null || settings.isEmpty()) {
            return getIntegrationSetting(settingName, defaultValue);
        }
        else {
            return settings[0].PC_SettingValue__c;
        }

    }

    private static Map<String,String> getIntegrationSettingByEngagementProgram(Set<String> engagementProgramCode,
            String settingName, String defaultValue) {
        final String SETTING_TYPE_INTEGRATION_SETTING = 'Integration Setting';
        List<PC_EngagementProgramSetting__mdt> settings;
        Map<String,String> engToDefaultValue = new Map<String,String>();
        settings = [
                SELECT PC_SettingValue__c, PC_IntegrationSetting__r.PC_SettingValue__c, PC_EngagementProgram__r.PC_EngagementProgramCode__c
                FROM PC_EngagementProgramSetting__mdt

                WHERE PC_IsActive__c = true
                AND PC_SettingType__c = :SETTING_TYPE_INTEGRATION_SETTING

                AND PC_EngagementProgram__r.PC_IsActive__c = true
                AND PC_EngagementProgram__r.PC_EngagementProgramCode__c IN :engagementProgramCode

                AND PC_IntegrationSetting__r.PC_Active__c = true
                AND PC_IntegrationSetting__r.PC_IsOverridable__c = true
                AND PC_IntegrationSetting__r.PC_SettingName__c = :settingName
        ];
        string tempDefaultValue = getIntegrationSetting(settingName, defaultValue);
        for(String eng : engagementProgramCode){
            for(PC_EngagementProgramSetting__mdt s : settings){
                if(s.PC_EngagementProgram__r.PC_EngagementProgramCode__c == eng && String.isNotBlank(s.PC_SettingValue__c)){
                    engToDefaultValue.put(s.PC_EngagementProgram__r.PC_EngagementProgramCode__c,s.PC_SettingValue__c);
                }else if (s.PC_EngagementProgram__r.PC_EngagementProgramCode__c == eng && String.isBlank(s.PC_SettingValue__c)){
                    engToDefaultValue.put(s.PC_EngagementProgram__r.PC_EngagementProgramCode__c,tempDefaultValue);
                }
            }
            if(!engToDefaultValue.containsKey(eng)){
                engToDefaultValue.put(eng,tempDefaultValue);
            }
        }
         return engToDefaultValue;
    }

    /**
     * Returns the Trigger Handler Register custom metadata type List which match the objectName/otherObjectName.
     * @param objectName API Name of SObject.
     * @param otherObjectName API Name of other Sobject.
     */
    public static List<PC_TriggerHandlerRegister__mdt> getTriggerHandlerRegisters(String objectName, String otherObjectName){

        List<PC_TriggerHandlerRegister__mdt> trigglerHandlerList = new List<PC_TriggerHandlerRegister__mdt>();
        List<PC_TriggerHandlerRegister__mdt> trigglerHandlerList_StandardObject = new List<PC_TriggerHandlerRegister__mdt>();
        List<PC_TriggerHandlerRegister__mdt> trigglerHandlerList_CustomObject = new List<PC_TriggerHandlerRegister__mdt>();

        if(objectName != null){
            trigglerHandlerList_StandardObject = [SELECT PC_ApexClass__c,PC_Active__c,PC_OtherObject__c,PC_sObject__c,PC_OrderOfExecution__c, DeveloperName, NamespacePrefix
            FROM PC_TriggerHandlerRegister__mdt
            WHERE PC_sObject__c =: objectName AND PC_Active__c = true
            ORDER BY PC_OrderOfExecution__c ASC];
            if(trigglerHandlerList_StandardObject != null && !trigglerHandlerList_StandardObject.isEmpty()){
                trigglerHandlerList.addAll(trigglerHandlerList_StandardObject);
            }
        }

        if(trigglerHandlerList_StandardObject.isEmpty() && otherObjectName != null) {
            trigglerHandlerList_CustomObject = [SELECT PC_ApexClass__c,PC_Active__c,PC_OtherObject__c,PC_sObject__c,PC_OrderOfExecution__c, DeveloperName, NamespacePrefix
            FROM PC_TriggerHandlerRegister__mdt
            WHERE PC_sObject__c =: PC_Constants.TriggerHandler_sObject AND PC_OtherObject__c =: otherObjectName AND PC_Active__c = true
            ORDER BY PC_OrderOfExecution__c ASC];

            if(trigglerHandlerList_CustomObject != null && !trigglerHandlerList_CustomObject.isEmpty()) {
                trigglerHandlerList.addAll(trigglerHandlerList_CustomObject);
            }
        }
        return trigglerHandlerList;
    }


    /**
     * Returns the Trigger Handler Register custom metadata type List which match the objectName/otherObjectName and apex class name.
     * @param className Handler class name
     * @param objectName API Name of SObject.
     * @param otherObjectName API Name of other Sobject.
     */
    public static List<PC_TriggerHandlerRegister__mdt> getTriggerHandlerRegisters(String className, String objectName, String otherObjectName){

        List<PC_TriggerHandlerRegister__mdt> trigglerHandlerList = new List<PC_TriggerHandlerRegister__mdt>();
        List<PC_TriggerHandlerRegister__mdt> trigglerHandlerList_StandardObject = new List<PC_TriggerHandlerRegister__mdt>();
        List<PC_TriggerHandlerRegister__mdt> trigglerHandlerList_CustomObject = new List<PC_TriggerHandlerRegister__mdt>();

        if(objectName != null && className != null){
            trigglerHandlerList_StandardObject = [SELECT PC_ApexClass__c,PC_Active__c,PC_OtherObject__c,PC_sObject__c,PC_OrderOfExecution__c
            FROM PC_TriggerHandlerRegister__mdt
            WHERE PC_sObject__c =: objectName AND PC_Active__c = true AND PC_ApexClass__c =: className
            ORDER BY PC_OrderOfExecution__c ASC];
            if(trigglerHandlerList_StandardObject != null && !trigglerHandlerList_StandardObject.isEmpty()){
                trigglerHandlerList.addAll(trigglerHandlerList_StandardObject);
            }
        }

        if(trigglerHandlerList_StandardObject.isEmpty() && otherObjectName != null && className != null) {
            trigglerHandlerList_CustomObject = [SELECT PC_ApexClass__c,PC_Active__c,PC_OtherObject__c,PC_sObject__c,PC_OrderOfExecution__c
            FROM PC_TriggerHandlerRegister__mdt WHERE PC_sObject__c =: PC_Constants.TriggerHandler_sObject
            AND PC_OtherObject__c =: otherObjectName AND PC_Active__c = true AND PC_ApexClass__c =: className
            ORDER BY PC_OrderOfExecution__c ASC];

            if(trigglerHandlerList_CustomObject != null && !trigglerHandlerList_CustomObject.isEmpty()) {
                trigglerHandlerList.addAll(trigglerHandlerList_CustomObject);
            }
        }
        return trigglerHandlerList;
    }

    /**
     * Returns <code>true</code> if a record type is mapped to Account in HC individual record type
     * mapper, <code>false</code> otherwise.
     *
     * @param accountRecordTypeNamespace
     * @param accountRecordType
     *
     * @author VIjay Kashikar
     */
    public static boolean isHealthCloudIndividualRecordType(String accountRecordTypeNamespace, String accountRecordType) {
        List<HealthCloudGA__IndividualRecordTypeMapper__mdt> records;
        try {
            if (String.isNotBlank(accountRecordTypeNamespace)) {
                records = [
                        SELECT Id
                        FROM HealthCloudGA__IndividualRecordTypeMapper__mdt
                        WHERE HealthCloudGA__AccountRecordTypeNamespace__c = :accountRecordTypeNamespace
                        AND HealthCloudGA__AccountRecordType__c = :accountRecordType
                ];
            } else {
                records = [
                        SELECT Id
                        FROM HealthCloudGA__IndividualRecordTypeMapper__mdt
                        WHERE
                        (
                                HealthCloudGA__AccountRecordTypeNamespace__c = NULL OR
                                HealthCloudGA__AccountRecordTypeNamespace__c = ''
                        ) AND HealthCloudGA__AccountRecordType__c = :accountRecordType
                ];
            }
            return (records != null && records.size() > 0);
        }
        catch(Exception ex) {
            PC_Utility.publishErrorLog(ex, 'Exception while finding the individual mapping for ' + accountRecordType + ' of namespace ' + accountRecordTypeNamespace);
            return false;
        }
    }
    /**
     * Returns <code>true</code> if a record type is mapped to Account in HC individual record type
     * mapper, <code>false</code> otherwise.
     *
     * @param accountRecordTypeNamespace
     * @param accountRecordType
     * @param individualMapperList
     *
     * @return
     */
    public static boolean isHealthCloudIndividualRecordType(String accountRecordTypeNamespace, String accountRecordType,List<HealthCloudGA__IndividualRecordTypeMapper__mdt> individualMapperList) {
        Boolean isHealthCloudIndividualRecordType = false;

        for(HealthCloudGA__IndividualRecordTypeMapper__mdt mapper:individualMapperList){
            //check to verify if Account record type is configured in Individual record type mapper custom metadata
            if(((String.isNotBlank(accountRecordTypeNamespace)
                    && mapper.HealthCloudGA__AccountRecordTypeNamespace__c == accountRecordTypeNamespace
                    && mapper.HealthCloudGA__AccountRecordType__c == accountRecordType) ||
                    (String.isBlank(accountRecordTypeNamespace)
                            && (mapper.HealthCloudGA__AccountRecordTypeNamespace__c == NULL
                            || mapper.HealthCloudGA__AccountRecordTypeNamespace__c == '' )
                            && mapper.HealthCloudGA__AccountRecordType__c == accountRecordType))) {
                isHealthCloudIndividualRecordType = true;
                break;
            }
        }
        return isHealthCloudIndividualRecordType;
    }
    /**
     * Define custom exceptions
     * @author Tushar Arora
     */
    public class HealthCloudPersonAccountException extends Exception {}

    /**
     * Returns <code>true</code> if a record type is mapped to Account in HC Person Account record type
     * mapper, <code>false</code> otherwise.
     *
     *
     * @author Tushar Arora
     */
    /*public static boolean isHealthCloudPersonAccountRecordType() {
        List<HealthCloudGA__IndividualRecordTypeMapper__mdt> records;
        String accountRecordTypeNamespace = getPersonAccountNamespace();
        String accountRecordType = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_PersonAccountPatientRecordTypeSettingName,PC_Constants.PC_PersonAccountPatientRecordTypeDefaultSettingValue) ;

            if (String.isNotBlank(accountRecordTypeNamespace)) {
                records = [
                        SELECT Id
                        FROM HealthCloudGA__IndividualRecordTypeMapper__mdt
                        WHERE HealthCloudGA__AccountRecordTypeNamespace__c = :accountRecordTypeNamespace
                        AND HealthCloudGA__AccountRecordType__c = :accountRecordType
                ];
            } else {
                records = [
                        SELECT Id
                        FROM HealthCloudGA__IndividualRecordTypeMapper__mdt
                        WHERE
                        (
                                HealthCloudGA__AccountRecordTypeNamespace__c = NULL OR
                                HealthCloudGA__AccountRecordTypeNamespace__c = ''
                        ) AND HealthCloudGA__AccountRecordType__c = :accountRecordType
                ];
            }

            if(records != null && records.size() > 0){
                return (records != null && records.size() > 0);
            }
            else {
                PC_Utility.logAndThrowException(new HealthCloudPersonAccountException('Incorrect Configuration Exception : did not find the person account mapping for '
                        + accountRecordType + ' in Individual Mapper for Person Account ' +
                        'according to the value of PC_PersonAccountPatientRecordType in Patient Connect Setting.'));
                return false;
            }
    }*/

    /**
     * Returns <code>true</code> if PC_UseSalesforceFiles in Patient Connect Settings is set to true,
     * <code>false</code> otherwise. False would mean that the Attachments would be used.
     *
     * @author Haritha Reddy
     */
    public static Boolean useSalesforceFiles() {
        String useSalesforceFiles;
        useSalesforceFiles=PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_USE_DOCUMENT_FILES,PC_Constants.FALSE_STRING);
        return Boolean.valueOf(useSalesforceFiles.toLowercase());
    }
    /**
     * Returns <code>true</code> if PC_DocumentPreviewStrictMode in Patient Connect Settings is set to true,
     * <code>false</code> otherwise.
     *
     * @author Haritha Reddy
     */
    public static Boolean useDocumentPreviewInStrictMode() {
        String useDocumentPreviewInStrictMode;
        useDocumentPreviewInStrictMode=PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_DOCUMENT_PREVIEW_STRICT_MODE,PC_Constants.TRUE_STRING);
        return Boolean.valueOf(useDocumentPreviewInStrictMode.toLowercase());

    }
    /*********************************************************************************
    Method Name    : getAccountIdentifiers
    Description    : Method to fetch Account identifiers
    Parameter      : patientRecordId,fieldApiName
    *********************************************************************************/
   /* public static Object getAccountIdentifiers(Id patientRecordId,String fieldApiName) {

        Object fieldValue=null;
        String finalQueryToFetchAccIdentifiers='';

        String selectClause='SELECT Id, ';
        selectClause=selectClause+fieldApiName;
        String fromClause=' FROM '+PC_Constants.ACCOUNT_IDENTIFIER_OBJ;
        String whereClause=' WHERE PC_Account__c=: patientRecordId';

        finalQueryToFetchAccIdentifiers=selectClause + fromClause + whereClause;

        List<PC_Account_Identifier__c> accountIdentifierList=(List<PC_Account_Identifier__c>)Database.query(finalQueryToFetchAccIdentifiers);

        if(accountIdentifierList!=null && !accountIdentifierList.isEmpty()){
            for (PC_Account_Identifier__c accountIdentifier: accountIdentifierList) {
                fieldValue=accountIdentifier.get(fieldApiName);
            }
        }
        return fieldValue;
    }*/

    /*********************************************************************************
    Method Name    : getAccountIdentifier
    Description    : Method to fetch Account identifiers
    Parameter      : patientRecordId,type and assigner
    *********************************************************************************/
    public static String getAccountIdentifier(Id patientRecordId,String type, String assigner) {



        if(String.isNotBlank(type) && String.isNotBlank(assigner) && patientRecordId != null) {

            List<PC_Account_Identifier__c> accountIdentifierList = new List<PC_Account_Identifier__c>();
            accountIdentifierList = [
                    SELECT PC_Value__c
                    FROM PC_Account_Identifier__c
                    where PC_Type__c = :type
                    AND PC_Assigner__c = :assigner
                    AND PC_Account__c = :patientRecordId
                    LIMIT 1
            ];


            if (!accountIdentifierList.isEmpty()) {
                return accountIdentifierList[0].PC_Value__c;
            }
        }
        return null;
    }


    /**
    * Get the masked value of SSN of the patient
    */
    public static String  getMaskedSSNvalue(String ssnVal) {
        String maskSSNval = '';
        if(ssnVal !=null){
            if(ssnVal.length()>4) {
                for (Integer i = 0; i < ssnVal.length()-4; i++) {
                    maskSSNval +='*';
                }
                maskSSNval += ssnVal.substring(ssnVal.length()-4, ssnVal.length());
                system.debug(maskSSNval);
            }
            else{
                maskSSNval= ssnVal;
            }
        }
        else{
            maskSSNval =ssnVal;
        }
        system.debug('maskSSNval'+maskSSNval);
        return maskSSNval;
    }


    /*********************************************************************************
    Method Name    : getAccountIdentifiers
    Description    : Method to fetch Account identifiers
    Parameter      : patientRecordId,fieldApiNames
    *********************************************************************************/
    public static Map<String,Object> getAccountIdentifiers(Id patientRecordId,List<String> fieldApiNames) {
        Map<String,Object> fieldApiNamesAndValues=new Map<String, Object>();
        String listOfFieldApiNames=String.join(fieldApiNames,', ');

        Object fieldValue=null;
        String finalQueryToFetchAccIdentifiers='';

        String selectClause='SELECT Id, ';
        selectClause=selectClause+listOfFieldApiNames;
        String fromClause=' FROM '+PC_Constants.ACCOUNT_IDENTIFIER_OBJ;
        String whereClause=' WHERE PC_Account__c=: patientRecordId';

        finalQueryToFetchAccIdentifiers=selectClause + fromClause + whereClause;

        List<PC_Account_Identifier__c> accountIdentifierList=(List<PC_Account_Identifier__c>)Database.query(finalQueryToFetchAccIdentifiers);

        if(accountIdentifierList!=null && !accountIdentifierList.isEmpty()){
            for (PC_Account_Identifier__c accountIdentifier: accountIdentifierList) {
                for(String fieldApiName: fieldApiNames){
                    fieldApiNamesAndValues.put(fieldApiName, accountIdentifier.get(fieldApiName));
                }
            }
        }
        return fieldApiNamesAndValues;
    }

    /*********************************************************************************
    Method Name    : getEmailTemplateDetails
    Description    : Method to get email template record
    Parameter      : String emailTemplateName
    *********************************************************************************/
    public static EmailTemplate getEmailTemplateDetails(String emailTemplateName){
        /** FLS Check for EmailTemplate */
        List<String> emailTemplateFields = new List<String>{'Name', 'Body', 'HtmlValue', 'TemplateType', 'DeveloperName'};
        PC_Database.assertAccess(PC_Constants.PC_EMAIL_TEMPLATE,PC_Database.Operation.Reading, emailTemplateFields);

        EmailTemplate emailTemplate = [SELECT Id,Name,Body,HtmlValue,TemplateType FROM EmailTemplate WHERE DeveloperName = :emailTemplateName];
        return emailTemplate;
    }

    /*********************************************************************************
    @MethodName    : getActiveDocumentLinkCustomMetadataRecs
    @Description   : Method to get active Document Link Related Objects Setting
    @Parameter     : NA
    @ReturnType    : List<PC_Document_Link_Related_Object_Setting__mdt>
    @Author        : Hitha Avalakki
    @UserStory     : PC-4763
    *********************************************************************************/
    public static List<PC_Document_Link_Related_Object_Setting__mdt> getActiveDocumentLinkCustomMetadataRecs(){
        List<PC_Document_Link_Related_Object_Setting__mdt> activeDocLinkCustomMetadataRecList = new List<PC_Document_Link_Related_Object_Setting__mdt>();

        activeDocLinkCustomMetadataRecList=[SELECT Id,PC_Account_Record_Type__c,PC_Account_Record_Type_Namespace_Prefix__c
                                            FROM PC_Document_Link_Related_Object_Setting__mdt
                                            WHERE PC_Active__c = true];

        return activeDocLinkCustomMetadataRecList;
    }

    /*********************************************************************************
    @MethodName    : getAccountRecordTypeDetails
    @Description   : Method to get account record type details
    @Parameter     : Set
    @ReturnType    : List<RecordType>
    @Author        : Hitha Avalakki
    @UserStory     : PC-4763
    *********************************************************************************/
    public static List<RecordType> getAccountRecordTypeDetails(Set<String> recordTypeDevNameSet){
        List<RecordType> recordTypeList=[SELECT Id, toLabel(Name), DeveloperName
                                         FROM RecordType
                                         WHERE SobjectType =: PC_Constants.PC_ACCOUNT AND
                                               IsActive = TRUE AND
                                               NamespacePrefix=:PC_Constants.OrgNamespace AND
                                               DeveloperName IN: recordTypeDevNameSet
                                         ORDER BY Name ASC];

        return recordTypeList;
    }


    /*********************************************************************************
    @MethodName    : isPersonAccountEnabled
    @Description    : Method to check if person account is enabled or not.
    @Parameter      : String
    @ReturnType    : Boolean
    @Author        : Tushar Arora
    *********************************************************************************/
    private static String isPersonAccountEnabled ;
    public static Boolean isPersonAccountEnabled(){

        if(String.isBlank(isPersonAccountEnabled)) {
            if(HealthCloudGA__UsePersonAccount__c.getInstance(PC_Constants.PC_USE_PERSON_ACCOUNT) != null ) {
                HealthCloudGA__UsePersonAccount__c usePersonAccountCheck = HealthCloudGA__UsePersonAccount__c.getInstance(PC_Constants.PC_USE_PERSON_ACCOUNT);
                if (isPersonAccountExists() && usePersonAccountCheck.HealthCloudGA__Enable__c ) {
                    isPersonAccountEnabled = 'true';
                } else {
                    isPersonAccountEnabled = 'false';
                }
            } else {
                isPersonAccountEnabled = 'false';
            }
        }
        return Boolean.valueof(isPersonAccountEnabled);
    }

    /*********************************************************************************
    @MethodName    : isPersonAccountExists
    @Description    : Method to check if ispersonaccount field exists in schema.
    @Parameter      :
    @ReturnType    : Boolean
    @Author        : Tushar Arora
    *********************************************************************************/
    private static String isPersonAccountExists ;
    public static Boolean isPersonAccountExists(){
        if(String.isBlank(isPersonAccountExists)) {
            if (Schema.sObjectType.Account.fields.getMap().containsKey(PC_Constants.PC_ISPERSONACCOUNT)) {
                isPersonAccountExists = 'true';
            } else {
                isPersonAccountExists = 'false';
            }
        }
        return Boolean.valueof(isPersonAccountExists);
    }

    /*********************************************************************************
    @MethodName    : getPersonAccountNamespace
    @Description    : Method to get getPersonAccountNamespace from Individual Record Type Mapper
                      using Patient Connect Setting RecordType Setting.
    @Parameter      :
    @ReturnType    : String
    @Author        : Tushar Arora
    *********************************************************************************/
    private static String strPersonAccountNamespace ;
    public static String getPersonAccountNamespace(){
        if(String.isBlank(strPersonAccountNamespace)) {
            strPersonAccountNamespace = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_PersonAccountPatientNamespaceSettingName,PC_Constants.PC_PersonAccountPatientNamespaceDefaultSettingValue) ;

        }
        return  strPersonAccountNamespace == NULL ? '' : strPersonAccountNamespace;
    }

    /*********************************************************************************
    @MethodName    : isPatientPersonAccountRecordType
    @Description    : Method to get ClientOrgNamespaceName
    @Param      :objectName    The name of the object that contains the record type
    @Param  : developerName The developer name of the record type
    @ReturnType    : Boolean
    @Author        : Tushar Arora
    *********************************************************************************/
    /*public static Boolean isPatientPersonAccountRecordTypeExists(){
        Boolean boolPatientPersonAccount = Boolean.valueof(PC_Constants.PC_DEFAULT_VALUE_OF_USE_PERSON_ACCOUNT_FOR_PC);
        List<RecordType> rt = new List<RecordType>();
        String objectName = PC_Constants.PATIENT_OBJECT ;
        String developerName = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_PersonAccountPatientRecordTypeSettingName,
                PC_Constants.PC_PersonAccountPatientRecordTypeDefaultSettingValue) ;
        String strRecordTypeQuery = 'Select Id from RecordType Where isActive = True' ;
        if(isPersonAccountExists()){
            strRecordTypeQuery += ' and sObjectType =: objectName and IsPersonType=True and developerName =: developerName ';
            rt = Database.query(strRecordTypeQuery);
            return rt.IsEmpty() ? boolPatientPersonAccount : true;
        }
        return boolPatientPersonAccount;
    } */

    /*********************************************************************************
    @MethodName    : getSpecificAccountRecordTypeDetails
    @Description   : Method to get account record type details
    @Parameter     : Set
    @ReturnType    : List<RecordType>
    @Author        : Hitha Avalakki
    @UserStory     : PC-5415
    *********************************************************************************/
    public static List<RecordType> getSpecificAccountRecordTypeDetails(Set<String> recordTypeDevNameSet){
        List<RecordType> recordTypeList = [SELECT Id, toLabel(Name), DeveloperName, NamespacePrefix
                                           FROM RecordType
                                           WHERE  SobjectType =: PC_Constants.PC_ACCOUNT AND
                                                  IsActive = TRUE AND
                                                  DeveloperName IN: recordTypeDevNameSet
                                                  ORDER BY Name ASC];

        return recordTypeList;
    }
    
    /*********************************************************************************
    @MethodName    : getRecordTypeFromSchema
    @Description   : Method to get record type details from Schema
    @Parameter     : String, List<String>, String
    @ReturnType    : Map<String, Id>
    @Author        : Hitha Avalakki
    @UserStory     : PC-5945
    *********************************************************************************/
    public static Map<String, Id> getRecordTypeFromSchema(String sobjectName, List<String> recordTypeDeveloperNameList,String namespacePrefix) {
        /* Map of record type developer names and record type id values */
        Map<String, Id> recTypeDeveloperNameRecTypeIdMap = new Map<String, Id>();

        /* Map of record type developer names and record type id values */
        Map<String, Id> finalRecTypeDeveloperNameRecTypeIdMap = new Map<String, Id>();

        /* Map of record type developer names and set of record type id values. This is required in case there are duplicate record type developer names for different record types */
        Map<String, Set<Id>> developerNameAndRecTypeIdSetMap = new Map<String, Set<Id>>();

        /* List of record type ids of all the duplicate record type developer names */
        List<Id> listOfRecordTypeIdsForDuplicateRecordTypeDeveloperNames = new List<Id>();

        /* List of record type details of all the duplicate record type developer names */
        List<RecordType> listOfRecordTypeDetailsOfDuplicateRecordTypeDeveloperNames = new List<RecordType>();

        try{

            /* Create SObjectType using sobjectName */
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sobjectName);

            /* Get DescribeSObjectResult of SObject */
            Schema.DescribeSObjectResult describeSObjectResult = sObjectType.getDescribe();

            /* Get DescribeSObjectResult of SObject */
            Map<Id, Schema.RecordTypeInfo> recordTypeIdInfoMap = describeSObjectResult.getRecordTypeInfosById();

            /* recordTypeIdInfoMap: */
            for (Id recordTypeId : recordTypeIdInfoMap.keySet()) {

                /* Get RecordTypeInfo details of recordTypeId */
                Schema.RecordTypeInfo recordTypeInfoDetail = recordTypeIdInfoMap.get(recordTypeId);

                for (String recordTypeDeveloperName : recordTypeDeveloperNameList) {

                    if (recordTypeInfoDetail.getDeveloperName().equalsIgnoreCase(recordTypeDeveloperName)) {

                        /* 'developerNameAndRecTypeIdSetMap' is a Map of record type developer name(as key) and set of record type ids(as value).
                            If any record type developer name is duplicate in the org for an SObject, we would create a set of record ids for it and store it in the above map.
                            If any record type developer name is unique in org, then record type developer name will have only single record type id in the set in the map.
                        */
                        if (developerNameAndRecTypeIdSetMap != null &&
                                !developerNameAndRecTypeIdSetMap.isEmpty() &&
                                developerNameAndRecTypeIdSetMap.containsKey(recordTypeDeveloperName)) {

                            Set<Id> recordTypeIdSet = new Set<Id>();
                            recordTypeIdSet = developerNameAndRecTypeIdSetMap.get(recordTypeDeveloperName);
                            recordTypeIdSet.add(recordTypeId);
                            developerNameAndRecTypeIdSetMap.put(recordTypeDeveloperName, recordTypeIdSet);
                        } else {
                                Set<Id> recordTypeIdSet = new Set<Id>();
                                recordTypeIdSet.add(recordTypeId);
                                developerNameAndRecTypeIdSetMap.put(recordTypeDeveloperName, recordTypeIdSet);
                        }
                    }
                }
            }

            if (!developerNameAndRecTypeIdSetMap.isEmpty()) {
                for (String recordTypeDevName : developerNameAndRecTypeIdSetMap.keySet()) {

                    Set<Id> recordTypeIdSet = developerNameAndRecTypeIdSetMap.get(recordTypeDevName);

                    /* Traverse through 'developerNameAndRecTypeIdSetMap' and check if any record type developer name has more than one record type id in its corresponding set.
                    * If any record type developer name has more than one record type id in the set, then we need to populate 'listOfRecordTypeIdsForDuplicateRecordTypeDeveloperNames'
                    * with the record type ids.
                    * If any record type developer name has only one record type id in the set, then populate the record type developer name(as key) and its record type id(as value) in
                    * the final 'recTypeDeveloperNameRecTypeIdMap' map. */
                    if (recordTypeIdSet != null && !recordTypeIdSet.isEmpty() && recordTypeIdSet.size() > 1) {

                        listOfRecordTypeIdsForDuplicateRecordTypeDeveloperNames.addAll(recordTypeIdSet);

                    } else if (recordTypeIdSet != null && !recordTypeIdSet.isEmpty() && recordTypeIdSet.size() == 1) {

                        Id recordTypeIdvalue = (new List<Id>(recordTypeIdSet))[0];
                        Schema.RecordTypeInfo recordTypeInfoDetail = recordTypeIdInfoMap.get(recordTypeIdvalue);

                        /* Check if the extracted record type developer name is active record type */
                        if(recordTypeInfoDetail.isActive()){
                            /* As Set is an unordered collection, we cannot pick an element using index, hence we need to convert it into List to use 0 index */
                            recTypeDeveloperNameRecTypeIdMap.put(recordTypeDevName, (new List<Id>(recordTypeIdSet))[0]);
                        }

                    }

                }
            }

            /* Using 'listOfRecordTypeIdsForDuplicateRecordTypeDeveloperNames' we need to identify the single record type id for a record type developer name using the namespace prefix.
            *  If we are checking for person account type patient record type developer name, we need to check if 'IsPersonType' holds true for the record type, else we drop the condition
            *  and use the default query */
            if (listOfRecordTypeIdsForDuplicateRecordTypeDeveloperNames != null && !listOfRecordTypeIdsForDuplicateRecordTypeDeveloperNames.isEmpty()) {

                /* Default query to get record types' details for an sobject, list of record type ids and given namespaceprefix */
                String strRecordTypeQuery = 'Select Id, DeveloperName from RecordType Where ' ;
                strRecordTypeQuery += ' SobjectType = :sobjectName AND Id IN :listOfRecordTypeIdsForDuplicateRecordTypeDeveloperNames AND NamespacePrefix = :namespacePrefix AND isActive= true';

                if (recordTypeDeveloperNameList.contains(PC_Constants.PATIENT_RECORD_TYPE) && isPersonAccountEnabled()) {

                    strRecordTypeQuery += ' AND IsPersonType = True';
                    listOfRecordTypeDetailsOfDuplicateRecordTypeDeveloperNames = (List<RecordType>) Database.query(strRecordTypeQuery);

                } else {

                    listOfRecordTypeDetailsOfDuplicateRecordTypeDeveloperNames = (List<RecordType>) Database.query(strRecordTypeQuery);
                }

                /* We populate the final map 'recTypeDeveloperNameRecTypeIdMap' with the record type developer name and corresponding record type id value from
                 * the list 'listOfRecordTypeDetailsOfDuplicateRecordTypeDeveloperNames' */
                if (listOfRecordTypeDetailsOfDuplicateRecordTypeDeveloperNames != null && !listOfRecordTypeDetailsOfDuplicateRecordTypeDeveloperNames.isEmpty()) {

                    for (RecordType recordTypeDetailsObj : listOfRecordTypeDetailsOfDuplicateRecordTypeDeveloperNames) {

                        if (!recTypeDeveloperNameRecTypeIdMap.containsKey(recordTypeDetailsObj.DeveloperName)) {
                            recTypeDeveloperNameRecTypeIdMap.put(recordTypeDetailsObj.DeveloperName, recordTypeDetailsObj.Id);
                        }
                    }
                }
            }
        }
        catch(Exception ex){
            PC_Utility.logAndThrowException(new RecordTypeException('Error occurred while fetching record types: '+ recordTypeDeveloperNameList+ ' for Sobject: '+ sobjectName+' with namespaceprefix: '+ namespaceprefix));
        }
        return recTypeDeveloperNameRecTypeIdMap;
    }

    public class RecordTypeException extends Exception{

    }

    /*********************************************************************************
    Method Name    : getStatusAttribute
    Description    : Method to get Status API value that are Closed or Default
    Parameter      : Set<String>
    *********************************************************************************/
    public static Set<String> getStatusAttribute(String sObjectName, Boolean getIsDefault, Boolean getIsClosed){
        Set<String> setStatus       = new Set<String>();
        List<String> returnStatus   = new List<String>();
        String  selectStatment      = 'Select ApiName FROM ' + sObjectName;
        String whereClause          = ' Where ';
        if(getIsDefault){
            whereClause = whereClause + 'IsDefault = true';
        }else if(getIsClosed){
            whereClause = whereClause + 'IsClosed = true';
        } else{
            whereClause = whereClause + 'IsDefault = true or IsClosed = true';
        }
        String query = selectStatment + whereClause;
        try {
            List<sObject> sObj = new List<sObject>();
            sObj    =    PC_Database.queryWithAccess(query, false);
            if (!sObj.isEmpty()) {
                for (sObject s : sObj) {
                    setStatus.add((String) s.get('ApiName'));
                }
                returnStatus.addAll(setStatus);
            }
        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return setStatus;
    }

    /**********************************************************************************************
    Method Name    : getDefaultProgramCaseRecordTypeId
    Description    : PC-7442 Get the configured/default record type for program case
    Return Type    : Id
    **********************************************************************************************/
    public static Id getDefaultProgramCaseRecordTypeId() {
        RecordType rt = new RecordType();
        String programRecordType;
        String namespaceStr;
        String strRecordTypeQuery = 'Select id from RecordType Where SobjectType =\'' + PC_Constants.PC_CASE ;

        strRecordTypeQuery += '\' AND DeveloperName =\'' + PC_Constants.CASE_PROGRAM_RECORD_TYPE + '\' AND NamespacePrefix =\'' + PC_Constants.CASE_PROGRAM_RECORD_TYPE_NAMESPACE + '\' AND isActive= true';

        try{
            rt = Database.query(strRecordTypeQuery);
        }
        catch (Exception ex){
            /* PC-6067: Formulate an exception message using values of PC_Constants.CASE_PROGRAM_RECORD_TYPE and PC_Constants.CASE_PROGRAM_RECORD_TYPE_NAMESPACE. */
            String programRecordTypeExceptionMessage='';
            List<Object> caseProgramRecordTypeValue=new List<Object>();
            caseProgramRecordTypeValue.add(PC_Constants.CASE_PROGRAM_RECORD_TYPE);

            /* Default part of exception message which contains details regarding case program record type */
            programRecordTypeExceptionMessage = String.format(Label.PC_ConfiguredCaseProgramRecordTypeTemplate,caseProgramRecordTypeValue);

            /* Append the namespace details to the exception message if the configured namespace is not empty */
            if(!String.isBlank(PC_Constants.CASE_PROGRAM_RECORD_TYPE_NAMESPACE)){
                List<Object> caseProgramRecordTypeNamespaceValue=new List<Object>();
                caseProgramRecordTypeNamespaceValue.add(PC_Constants.CASE_PROGRAM_RECORD_TYPE_NAMESPACE);
                programRecordTypeExceptionMessage += ' '+ String.format(Label.PC_NamespaceTemplate,caseProgramRecordTypeNamespaceValue);
            }

            PC_Utility.logAndThrowException(new RecordTypeException(programRecordTypeExceptionMessage));
        }

        return rt.Id;
    }
    /*PC-7442: END*/

    /**********************************************************************************************
    Method Name    : getProgramRecordTypeIdBasedOnEngProgramId
    Description    : This method fetches the program case record type and program case record type namespace details present on Engagement Program object.
    parameters     : String engagementProgId
    Return Type    : String
    User Story     : PC-6067
    **********************************************************************************************/
    public static Id getProgramRecordTypeIdBasedOnEngProgramId(String engagementProgId)
    {
        Id caseRecordTypeId=null;

        List<String> engagementProgFieldsList = new List<String>{PC_Constants.getQualifiedAPIName('PC_ProgramCaseRecordType__c'),
                PC_Constants.getQualifiedAPIName('PC_ProgramCaseRecordTypeNamespace__c')};

        //Check if user has access to perform the READ operation
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'),PC_Database.Operation.Reading, engagementProgFieldsList);

        List<String> recordTypeFieldsList = new List<String>{'DeveloperName','NamespacePrefix'};

        //Check if user has access to perform the READ operation
        PC_Database.assertAccess(PC_Constants.RECORD_TYPE_PARAM,PC_Database.Operation.Reading, recordTypeFieldsList);

        List<PC_Engagement_Program__c> engagementProgramsList = [SELECT Id, PC_ProgramCaseRecordType__c,PC_ProgramCaseRecordTypeNamespace__c
        FROM PC_Engagement_Program__c
        WHERE Id = :engagementProgId];

        caseRecordTypeId = getProgramRecordTypeIdForEngagementProgram(engagementProgramsList);

        return caseRecordTypeId;
    }

    /**********************************************************************************************
    Method Name    : getProgramCaseRecordForEngagementProgCode
    Description    : This method fetches the program case record type and program case record type namespace details present on Engagement Program object.
    parameters     : String engagementProgCode
    Return Type    : Id
    User Story     : PC-6067
    **********************************************************************************************/
    public static Id getProgramRecordTypeIdBasedOnEngProgramCode(String engagementProgCode)
    {
        Id caseRecordTypeId=null;

        List<String> engagementProgFieldsList = new List<String>{PC_Constants.getQualifiedAPIName('PC_ProgramCaseRecordType__c'),
                PC_Constants.getQualifiedAPIName('PC_ProgramCaseRecordTypeNamespace__c')};

        //Check if user has access to perform the READ operation
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'),PC_Database.Operation.Reading, engagementProgFieldsList);

        List<String> recordTypeFieldsList = new List<String>{'DeveloperName','NamespacePrefix'};

        //Check if user has access to perform the READ operation
        PC_Database.assertAccess(PC_Constants.RECORD_TYPE_PARAM,PC_Database.Operation.Reading, recordTypeFieldsList);

        List<PC_Engagement_Program__c> engagementProgramsList = [SELECT Id, PC_ProgramCaseRecordType__c,PC_ProgramCaseRecordTypeNamespace__c
        FROM PC_Engagement_Program__c
        WHERE PC_Program_Code__c = :engagementProgCode];

        caseRecordTypeId = getProgramRecordTypeIdForEngagementProgram(engagementProgramsList);

        return caseRecordTypeId;
    }

    /**********************************************************************************************
    Method Name    : getCaseRecordTypeIdForEngagementProgram
    Description    : This method fetches the program case record type id for engagement program
    parameters     : List<PC_Engagement_Program__c> engagementProgramsList
    Return Type    : Id
    User Story     : PC-6067
    **********************************************************************************************/
    public static Id getProgramRecordTypeIdForEngagementProgram(List<PC_Engagement_Program__c> engagementProgramsList){
        Id caseRecordTypeId=null;

        if (engagementProgramsList != null && !engagementProgramsList.isEmpty()) {
            PC_Engagement_Program__c engagementProgram = engagementProgramsList[0];

            if (engagementProgram.PC_ProgramCaseRecordType__c != null) {

                RecordType[] recordTypeObjList = [
                        SELECT Id, DeveloperName, NamespacePrefix
                        FROM RecordType
                        WHERE DeveloperName = :engagementProgram.PC_ProgramCaseRecordType__c AND NamespacePrefix = :engagementProgram.PC_ProgramCaseRecordTypeNamespace__c
                ];
                if (recordTypeObjList!=null && !recordTypeObjList.isEmpty()) {
                    caseRecordTypeId = recordTypeObjList[0].Id;
                }
                else{
                    PC_Utility.logAndThrowException(new RecordTypeException(Label.PC_ProgramRecordTypeNotFound));
                }
            }
            else{
                caseRecordTypeId = getDefaultProgramCaseRecordTypeId();
            }
        }
        else{
            caseRecordTypeId = getDefaultProgramCaseRecordTypeId();
        }
        return caseRecordTypeId;
    }

    /**********************************************************************************************
    Method Name    : getFileOrAttachmentInUse
    Description    : This method fetches information if salesforce file or attachment needs to be used for any functionality
    parameters     : None
    Return Type    : String
    User Story     : PC-8197
    **********************************************************************************************/
    public static PC_Constants.UseAttachmentOrSalesforceFile getFileOrAttachmentInUse() {
        PC_Constants.UseAttachmentOrSalesforceFile useAttachmentOrSalesforceFile;
        Boolean useSalesforceFiles=useSalesforceFiles();
        Boolean useDocumentStrictMode = useDocumentPreviewInStrictMode();
        /* PC-8438
        * UseAttachmentAndFile (Prefer Attachment if exist otherwise File)
        * UseFileAndAttachment (Prefer File if exist otherwise Attachment)
        */
        if (useSalesforceFiles) {
            if (useDocumentStrictMode) {
                useAttachmentOrSalesforceFile = PC_Constants.UseAttachmentOrSalesforceFile.UseFile;
            } else {
                useAttachmentOrSalesforceFile = PC_Constants.UseAttachmentOrSalesforceFile.UseFileAndAttachment;
            }
        } else {
            if (useDocumentStrictMode) {
                useAttachmentOrSalesforceFile = PC_Constants.UseAttachmentOrSalesforceFile.UseAttachment;
            } else {
                useAttachmentOrSalesforceFile = PC_Constants.UseAttachmentOrSalesforceFile.UseAttachmentAndFile;
            }
        }
        return useAttachmentOrSalesforceFile;
    }

    public class taskTriageWrapper{
        public String type;
        public String value;
    }
}