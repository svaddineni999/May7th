/**************************************************************************************
Apex Class Name     : PC_PropertiesAndConditionsBuilder
Description         : This class is used as controller for PC_PropertiesAndConditionsBuilder component;
CreatedBy           : Deloitte
Created Date        : 30 Sept 2020
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Kanteti Kishore            30 Sept 2020           Initial version[PC-6144]
Kanteti Kishore            15 Oct 2020            PC-6813 Added server side logic evaluation method-getLogicEvaluationResult.
Kanteti Kishore            1 Nov 2020            PC-6825 Added getAllFormulaOptions method and related methods for Date Formula
Vijay Kashikar            21-Jan-2021            [PC-7102] Added sharing clause
Kanteti Kishore            13 Apr 2021           [PC-7009] Added whatId,ActivityDate variables and modified methods to support
                                                    property builder for User Task Activities
*****************************************************************************************/

public with sharing class PC_PropertiesAndConditionsBuilder {
    private static final String WHAT_ID = 'WhatId';
    private static final String ACTIVITY_DATE = 'ActivityDate';

    /*********************************************************************************
      Method Name    : getObjectFields
      Author         : Kanteti Kishore
      Description    : This method returns a Map of field's label(Key) and field's
                       type, API Name(value) of all the fields for the supplied
                       SObject's API name
      Return Type    : List<objectFields>
      Parameter      : objectFieldsRequest
     *********************************************************************************/
    @AuraEnabled
    public static List<ObjectFieldsResponse> getObjectFields(List<ObjectFieldsRequest> ObjectFieldsRequests){
        List<ObjectFieldsDetailedRequest> ObjectFieldsDetailedRequests = new List<ObjectFieldsDetailedRequest>();
        ObjectFieldsDetailedRequest eachObjectFieldsDetailedRequest = new ObjectFieldsDetailedRequest();
        for(ObjectFieldsRequest eachObjectFieldsRequest : ObjectFieldsRequests){
            eachObjectFieldsDetailedRequest.includeRecordTypeId = eachObjectFieldsRequest.includeRecordTypeId;
            eachObjectFieldsDetailedRequest.objectName = eachObjectFieldsRequest.objectName;
            if(eachObjectFieldsRequest.builderContext == String.valueOf(PC_Constants.BuilderContext.PropertyBuilder)){
                eachObjectFieldsDetailedRequest.showMandatoryFieldIndicator = true;
                eachObjectFieldsDetailedRequest.includeLookUpFields = true;
                eachObjectFieldsDetailedRequest.includeNonUpdateableFields = true;
                eachObjectFieldsDetailedRequest.includeFormulaFields = false;
                eachObjectFieldsDetailedRequest.includeEncryptedFields = true;
            }else if(eachObjectFieldsRequest.builderContext == String.valueOf(PC_Constants.BuilderContext.PropertyBuilderInUpdate)){
                eachObjectFieldsDetailedRequest.showMandatoryFieldIndicator = true;
                eachObjectFieldsDetailedRequest.includeLookUpFields = true;
                eachObjectFieldsDetailedRequest.includeNonUpdateableFields = false;
                eachObjectFieldsDetailedRequest.includeFormulaFields = false;
                eachObjectFieldsDetailedRequest.includeEncryptedFields = true;
            }else{
                eachObjectFieldsDetailedRequest.showMandatoryFieldIndicator = false;
                eachObjectFieldsDetailedRequest.includeLookUpFields = false;
                eachObjectFieldsDetailedRequest.includeNonUpdateableFields = true;
                eachObjectFieldsDetailedRequest.includeFormulaFields = true;
                eachObjectFieldsDetailedRequest.includeEncryptedFields = true;
            }
            ObjectFieldsDetailedRequests.add(eachObjectFieldsDetailedRequest);
        }

        List<ObjectFieldsResponse> responseObjectFields = new List<ObjectFieldsResponse>();
        for(ObjectFieldsDetailedRequest eachObjectFieldsRequest : ObjectFieldsDetailedRequests){
            ObjectFieldsResponse eachObjectFields =  new ObjectFieldsResponse();
            eachObjectFields.objectName = eachObjectFieldsRequest.objectName;
            Map<String, Schema.SObjectType> objectSchemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType objectSchema = objectSchemaMap.get(eachObjectFieldsRequest.objectName);
            eachObjectFields.objectLabel = objectSchema.getDescribe().getLabel();
            eachObjectFields.fields = getFields(eachObjectFieldsRequest);
            responseObjectFields.add(eachObjectFields);
        }
        return responseObjectFields;
    }
    public static List<FieldDetail> getFields(ObjectFieldsDetailedRequest eachObjectFieldsRequest){
        String recType = eachObjectFieldsRequest.objectName;
        Boolean includeFormulaFields        =   eachObjectFieldsRequest.includeFormulaFields;
        Boolean includeRecordTypeId         =   eachObjectFieldsRequest.includeRecordTypeId;
        Boolean includeLookUps              =   eachObjectFieldsRequest.includeLookUpFields;
        Boolean showMandatoryFields         =   eachObjectFieldsRequest.showMandatoryFieldIndicator;
        Boolean includeNonUpdateableFields  =   eachObjectFieldsRequest.includeNonUpdateableFields;
        Boolean includeEncryptedFields      =   eachObjectFieldsRequest.includeEncryptedFields;
        Map<String, String> fieldsMapSorted = new Map<String, String>();
        List<FieldDetail> fields = new List<FieldDetail>();
        try {
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType leadSchema = schemaMap.get(recType);
            Map<String, Schema.SObjectField> fieldMapWithSystemFields = (Map<String, SObjectField>) leadSchema.getDescribe().fields.getMap();
            Map<String, Schema.SObjectField> fieldMap = new Map<String, Schema.SObjectField>();
            if(showMandatoryFields) {
                fieldMap = PC_Utility.removeSystemFields(fieldMapWithSystemFields);
            }else{
                fieldMap = fieldMapWithSystemFields;
            }
            Map<String, String> fieldsMap = new Map<String, String>();
            List<String> fieldsMapSortKey = new List<String>();
            if (!fieldMap.isEmpty()) {
                String label = '';
                String value = '';
                for (String fieldName : fieldMap.keySet()){
                    String fieldType = PC_Constants.EMPTY_STRING + fieldMap.get(fieldName).getDescribe().getType();
                    if(!includeNonUpdateableFields && !fieldMap.get(fieldName).getDescribe().isUpdateable()){
                        continue;
                    }
                    if(recType == PC_Constants.PC_TASK && fieldName == ACTIVITY_DATE){
                        continue;
                    }
                    if(!fieldMap.get(fieldName).getDescribe().isAutoNumber() && fieldType != PC_Constants.ID_PARAM){ //Excluding Autonumber and ID field types.
                        if(!includeFormulaFields) {
                            if (fieldMap.get(fieldName).getDescribe().isCalculated()) {
                                continue;
                            }
                        }
                        if(!includeLookUps) {
                            if(fieldType == PC_Constants.PC_FIELDTYPE_REFERENCE) {
                                continue;
                            }
                        }
                        if(!includeEncryptedFields) {
                            if(fieldMap.get(fieldName).getDescribe().isEncrypted()){
                                continue;
                            }
                        }
                        if(!includeRecordTypeId){
                            if (fieldName.toUpperCase() != PC_Constants.PC_RECORD_TYPE_ID.toUpperCase()) {
                                //Boolean type fields cannot be made required at field level and cannot be null. So all boolean type fields are not mandatory.
                                if(fieldMap.get(fieldName).getDescribe().isNillable() || fieldType == PC_Constants.PC_FIELD_TYPE_BOOLEAN){
                                    label = fieldMap.get(fieldName).getDescribe().getLabel() + ',' + fieldMap.get(fieldName).getDescribe().getType() + ','+ PC_Constants.PC_NOTMANDATORY;
                                }else {
                                    label = fieldMap.get(fieldName).getDescribe().getLabel() + ',' + fieldMap.get(fieldName).getDescribe().getType() + ',' + PC_Constants.PC_MANDATORY;
                                }
                                value = fieldMap.get(fieldName).getDescribe().getName();
                                fieldsMap.put(value, label);
                            }
                        }else{
                            if(fieldMap.get(fieldName).getDescribe().isNillable() || fieldType == PC_Constants.PC_FIELD_TYPE_BOOLEAN){
                                label = fieldMap.get(fieldName).getDescribe().getLabel() + ',' + fieldMap.get(fieldName).getDescribe().getType() + ','+ PC_Constants.PC_NOTMANDATORY;
                            }else{
                                label = fieldMap.get(fieldName).getDescribe().getLabel() + ',' + fieldMap.get(fieldName).getDescribe().getType() + ','+ PC_Constants.PC_MANDATORY;
                            }
                            value = fieldMap.get(fieldName).getDescribe().getName();
                            fieldsMap.put(value, label);
                        }
                    }
                }
                List<RecordType> allRecordTypes = new List<RecordType>();
                allRecordTypes = PC_SYSTEM.getAllRecordType(recType);
                if(!allRecordTypes.isEmpty()){
                    fieldsMap.put(PC_Constants.PC_RecordTypeDeveloperName,PC_Constants.PC_RECORD_TYPE_NAME+','+PC_Constants.PC_PicklistType +','+PC_Constants.PC_NOTMANDATORY);
                }
                //Sorting
                List<String> requiredFieldsMapSortKey = new List<String>();
                for (String fKey : fieldsMap.keySet()){
                    if(fieldsMap.get(fKey).split(',')[2] == PC_Constants.PC_MANDATORY && showMandatoryFields){
                        requiredFieldsMapSortKey.add(fieldsMap.get(fKey).toUpperCase());
                    }else {
                        fieldsMapSortKey.add(fieldsMap.get(fKey).toUpperCase()); // Convert to upper case as sorting is case sensitive
                    }
                }
                if(showMandatoryFields) {
                    requiredFieldsMapSortKey.sort(); //required fields sorting
                    for (String fSortKey : requiredFieldsMapSortKey) { // loop through the sorted labels
                        for (String fKey : fieldsMap.keySet()) { // loop through the Map
                            if (fSortKey == fieldsMap.get(fKey).toUpperCase()) { // if the labels match
                                FieldDetail eachFieldDetail = new FieldDetail();
                                eachFieldDetail.apiName = fKey;
                                eachFieldDetail.type = fieldsMap.get(fKey).split(',')[1];
                                eachFieldDetail.mandatory = true;
                                eachFieldDetail.labelWithMandatoryIndicator = '* ' + fieldsMap.get(fKey).split(',')[0];
                                eachFieldDetail.label = fieldsMap.get(fKey).split(',')[0];
                                eachFieldDetail.active = true;
                                fields.add(eachFieldDetail);
                                fieldsMap.remove(fKey);//remove the key for better looping
                            }
                        }
                    }
                }
                fieldsMapSortKey.sort(); // Apply Sort on the list of labels
                for (String fSortKey : fieldsMapSortKey) { // loop through the sorted labels
                    for (String fKey : fieldsMap.keySet()) { // loop through the Map
                        if (fSortKey == fieldsMap.get(fKey).toUpperCase()) { // if the labels match
                            FieldDetail eachFieldDetail = new FieldDetail();
                            eachFieldDetail.apiName = fKey;
                            eachFieldDetail.label = fieldsMap.get(fKey).split(',')[0];
                            eachFieldDetail.labelWithMandatoryIndicator = fieldsMap.get(fKey).split(',')[0];
                            eachFieldDetail.type = fieldsMap.get(fKey).split(',')[1];
                            eachFieldDetail.mandatory = false;
                            if(showMandatoryFields) {
                                eachFieldDetail.label = '  ' + fieldsMap.get(fKey).split(',')[0];
                            }
                            eachFieldDetail.active = true;
                            fields.add(eachFieldDetail);
                            fieldsMap.remove(fKey);//remove the key for better looping
                        }
                    }
                }
            }
        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }

        return fields;
    }
    /*********************************************************************************
      Method Name    : getFieldDropdownValues
      Author         : Kanteti Kishore
      Description    : This method returns a list of all Dropdown Values and labels of the
                       supplied SObject's API name and its field
      Return Type    : List<DropdownValue>
      Parameter      : SObjects Name and SObjects field API Name
     *********************************************************************************/
    @AuraEnabled
    public static List<DropdownValue> getFieldDropdownValues(String recType, String fieldApiName){
        List<DropdownValue> fieldDropdownValues = new List<DropdownValue>();
        try{
            if(fieldApiName == PC_Constants.PC_RecordTypeDeveloperName){
                List<RecordType> allRecordTypes = new List<RecordType>();
                allRecordTypes = PC_SYSTEM.getAllRecordType(recType);
                for(RecordType eachRecordType : allRecordTypes){
                    DropdownValue recordTypeDropdownValue  = new DropdownValue();
                    if(!String.isBlank(eachRecordType.NamespacePrefix)) {
                        recordTypeDropdownValue.label = eachRecordType.Name;
                        recordTypeDropdownValue.value = eachRecordType.NamespacePrefix + '__' + eachRecordType.DeveloperName;
                        //fieldPickListValues.put(eachRecordType.NamespacePrefix + '__' + eachRecordType.DeveloperName, eachRecordType.Name);
                    }else{
                        recordTypeDropdownValue.label = eachRecordType.Name;
                        recordTypeDropdownValue.value = eachRecordType.DeveloperName;
                        //fieldPickListValues.put(eachRecordType.DeveloperName, eachRecordType.Name);
                    }
                    fieldDropdownValues.add(recordTypeDropdownValue);
                }
            }else {
                //Create a Map of LocalName w/o Namespace and API name with Namespace
                Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                Schema.SObjectType leadSchema = schemaMap.get(recType);
                Map<String, Schema.SObjectField> fieldMap = (Map<String, SObjectField>) leadSchema.getDescribe().fields.getMap();
                Map<String, String> fieldsMap = new Map<String, String>();
                for (String fieldName : fieldMap.keySet()) {
                    fieldsMap.put(fieldMap.get(fieldName).getDescribe().getName(), fieldName);
                }

                Schema.SobjectField theField = (SObjectField) Schema.getGlobalDescribe().get(recType).getDescribe().fields.getMap().get(fieldsMap.get(fieldApiName));
                List<Schema.PicklistEntry> controllingEntries = theField.getDescribe().getPicklistValues();
                for (Schema.PicklistEntry entry : controllingEntries) {
                    DropdownValue eachDropdownValue = new DropdownValue();
                    eachDropdownValue.label = entry.label;
                    eachDropdownValue.value = entry.value;
                    fieldDropdownValues.add(eachDropdownValue);
                }
            }
        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return fieldDropdownValues;
    }

    /*********************************************************************************
      Method Name    : getTriggerObjectLookupFields
      Author         : Kanteti Kishore
      Description    : This method returns a Map of LookUp field's label(Key) and field's
                       type, API Name(value) of all the fields for the supplied
                       SObject's API name
      Return Type    : List<DropdownValue>
      Parameter      : SObjects API Name
     *********************************************************************************/
    @AuraEnabled
    public static List<DropdownValue> getTriggerObjectLookupFields(String triggerEventObjectName,String triggerEventObjectType,String recordObjectName,String recordFieldApiName) {
        Map<String, String> fieldsMapSorted = new Map<String, String>();
        List<DropdownValue> referenceDropdownValues = new List<DropdownValue>();
        try {

            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType leadSchema = schemaMap.get(triggerEventObjectName);
            Map<String, Schema.SObjectField> fieldMap = (Map<String, SObjectField>) leadSchema.getDescribe().fields.getMap();
            Map<String, String> fieldsMap = new Map<String, String>();
            List<String> fieldsMapSortKey = new List<String>();
            String recordFieldType = '';
            if(triggerEventObjectType == 'Platform Event Object') {
                Schema.SObjectType recordLeadSchema = schemaMap.get(recordObjectName);
                Map<String, Schema.SObjectField> recordFieldsMap = (Map<String, SObjectField>) recordLeadSchema.getDescribe().fields.getMap();
                recordFieldType = PC_Constants.EMPTY_STRING + recordFieldsMap.get(recordFieldApiName).getDescribe().getType();
            }
            if (!fieldMap.isEmpty()) {
                String label = '';
                String value = '';
                String fieldLookUpObjectName = '';
                String lookUpObjectName = '';
                String fieldType = '';
                lookUpObjectName = getLookupFieldObjectInfo(recordObjectName, recordFieldApiName);

                for (String fieldName : fieldMap.keySet()) {

                    fieldType = PC_Constants.EMPTY_STRING + fieldMap.get(fieldName).getDescribe().getType();
                    if(recordFieldApiName == WHAT_ID){
                        label = fieldMap.get(fieldName).getDescribe().getLabel() ;
                        value = fieldMap.get(fieldName).getDescribe().getName();
                        fieldsMap.put(value, label);
                        continue;
                    }
                    if(triggerEventObjectType == 'Data Object'){
                        if (fieldType != PC_Constants.PC_FIELDTYPE_REFERENCE && fieldType != PC_Constants.ID_PARAM){
                            continue;
                        }
                        fieldLookUpObjectName = getLookupFieldObjectInfo(triggerEventObjectName,fieldName);
                        if(fieldLookUpObjectName == lookUpObjectName && fieldType == PC_Constants.PC_FIELDTYPE_REFERENCE){
                            label = fieldMap.get(fieldName).getDescribe().getLabel() ;
                            value = fieldMap.get(fieldName).getDescribe().getName();
                            fieldsMap.put(value, label);
                        }else if(fieldType == PC_Constants.ID_PARAM && lookUpObjectName == triggerEventObjectName){
                            label = fieldMap.get(fieldName).getDescribe().getLabel() ;
                            value = fieldMap.get(fieldName).getDescribe().getName();
                            fieldsMap.put(value, label);
                        }
                    }
                    else if(triggerEventObjectType == 'Platform Event Object'){
                        if(recordFieldType != PC_Constants.PC_FIELDTYPE_REFERENCE) {
                            label = fieldMap.get(fieldName).getDescribe().getLabel() ;
                            value = fieldMap.get(fieldName).getDescribe().getName();
                            fieldsMap.put(value, label);
                        }else{
                            fieldLookUpObjectName = getLookupFieldObjectInfo(triggerEventObjectName,fieldName);
                            if(fieldLookUpObjectName == lookUpObjectName && recordFieldType == PC_Constants.PC_FIELDTYPE_REFERENCE) {
                                if(fieldType == PC_Constants.ID_PARAM && lookUpObjectName == triggerEventObjectName) {
                                    label = fieldMap.get(fieldName).getDescribe().getLabel() ;
                                    value = fieldMap.get(fieldName).getDescribe().getName();
                                    fieldsMap.put(value, label);
                                }else{
                                    label = fieldMap.get(fieldName).getDescribe().getLabel() ;
                                    value = fieldMap.get(fieldName).getDescribe().getName();
                                    fieldsMap.put(value, label);
                                }
                            }
                        }
                    }
                }
                //Sorting
                for (String fKey : fieldsMap.keySet()) {
                    fieldsMapSortKey.add(fieldsMap.get(fKey).toUpperCase()); // Covert to upper case as sorting is case sensitive
                }
                fieldsMapSortKey.sort(); // Apply Sort on the list of labels
                for (String fSortKey : fieldsMapSortKey) { // loop through the sorted labels
                    for (String fKey : fieldsMap.keySet()) { // loop through the Map
                        if (fSortKey == fieldsMap.get(fKey).toUpperCase()) { // if the labels match
                            DropdownValue eachDropdownValue = new DropdownValue();
                            eachDropdownValue.label = fieldsMap.get(fKey);
                            eachDropdownValue.value = fKey;
                            referenceDropdownValues.add(eachDropdownValue);
                            fieldsMap.remove(fKey);//remove the key for better looping
                        }
                    }
                }
            }
        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return referenceDropdownValues;
    }
    /*********************************************************************************
      Method Name    : getUserLookUpValues
      Author         : Kanteti Kishore
      Description    : This method returns a Map of all user lookup values and labels of the
                       supplied SObject's API name
      Return Type    : Map<String, String>
      Parameter      : SObjects API Name
    *********************************************************************************/
    @AuraEnabled
    public static List<DropdownValue> getUserLookUpValues(String triggerEventObjectName){
        Map<String, String> fieldsMapSorted = new Map<String, String>();
        List<DropdownValue> userDropdownValues = new List<DropdownValue>();
        try {
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType leadSchema = schemaMap.get(triggerEventObjectName);
            Map<String, Schema.SObjectField> fieldMap = (Map<String, SObjectField>) leadSchema.getDescribe().fields.getMap();
            Map<String, String> fieldsMap = new Map<String, String>();
            List<String> fieldsMapSortKey = new List<String>();

            if (!fieldMap.isEmpty()) {
                String label = '';
                String value = '';
                String fieldLookUpObjectName = '';
                for (String fieldName : fieldMap.keySet()) {
                    String fieldType = PC_Constants.EMPTY_STRING + fieldMap.get(fieldName).getDescribe().getType();
                    if (fieldType != PC_Constants.PC_FIELDTYPE_REFERENCE) {
                        continue;
                    }
                    fieldLookUpObjectName = getLookupFieldObjectInfo(triggerEventObjectName,fieldName);
                    system.debug(fieldLookUpObjectName);
                    if(fieldLookUpObjectName == PC_Constants.PC_USER && fieldType == PC_Constants.PC_FIELDTYPE_REFERENCE){
                        label = fieldMap.get(fieldName).getDescribe().getLabel() ;
                        value = fieldMap.get(fieldName).getDescribe().getName();
                        fieldsMap.put(value, label);
                    }
                }
            }
            //Sorting
            for (String fKey : fieldsMap.keySet()) {
                fieldsMapSortKey.add(fieldsMap.get(fKey).toUpperCase()); // Covert to upper case as sorting is case sensitive
            }
            fieldsMapSortKey.sort(); // Apply Sort on the list of labels
            for (String fSortKey : fieldsMapSortKey) { // loop through the sorted labels
                for (String fKey : fieldsMap.keySet()) { // loop through the Map
                    if (fSortKey == fieldsMap.get(fKey).toUpperCase()) { // if the labels match
                        fieldsMapSorted.put(fKey, fieldsMap.get(fKey)); // add the key and value to new map
                        dropdownValue eachUserDropdownValue = new dropdownValue();
                        eachUserDropdownValue.label = fieldsMap.get(fKey);
                        eachUserDropdownValue.value = fKey;
                        userDropdownValues.add(eachUserDropdownValue);
                        fieldsMap.remove(fKey);//remove the key for better looping
                    }
                }
            }
        }
        catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return userDropdownValues;
    }
    /*********************************************************************************
      Method Name    : getLogicEvaluationResult
      Author         : Kanteti Kishore
      Description    : This method returns result of custom logic of conditions
      Return Type    : Boolean
      @param         : String logic
     *********************************************************************************/
    @AuraEnabled
    public static void getLogicEvaluationResult(String logic){
        try {
            PC_Utility.evaluateCustomLogic(logic);
        }catch (Exception ex){
            PC_Utility.throwAuraHandledException(ex.getMessage());
        }
    }
    /*********************************************************************************
      Method Name    : getAllFormulaOptions
      Author         : Kanteti Kishore
      Description    : This method returns all date/datetime fields,offset type and operation options of provided object api name
      Return Type    : DateAndDatetimeFormulaOptions
      @param         : String triggerEventObjectApiName
     *********************************************************************************/
    @AuraEnabled
    public static DateAndDatetimeFormulaOptions getAllFormulaOptions(String triggerEventObjectApiName){
        DateAndDatetimeFormulaOptions allFormulaOptions = new DateAndDatetimeFormulaOptions();
        try {
            allFormulaOptions.dateAndDatetimeFields = getReferenceDateOrDatetimeFields(triggerEventObjectApiName);
            allFormulaOptions.offsetTypeOptions = getOffsetTypeOptions();
            allFormulaOptions.operationOptions = getOperationOptions();
        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return allFormulaOptions;
    }
    /*********************************************************************************
      Method Name    : getOffsetTypeOptions
      Author         : Kanteti Kishore
      Description    : This method returns all offset type options of Date/Datetime formula
      Return Type    : List<DropdownValue>
     *********************************************************************************/
    @AuraEnabled
    public static List<DropdownValue> getOffsetTypeOptions(){
        List<DropdownValue> allOffsetTypeOptions = new List<DropdownValue>();
        DropdownValue days = new DropdownValue();
        days.label = Label.PC_Days;
        days.value = String.valueOf(PC_Constants.OffsetType.Days);
        DropdownValue months = new DropdownValue();
        months.label = Label.PC_Months;
        months.value = String.valueOf(PC_Constants.OffsetType.Months);
        DropdownValue years = new DropdownValue();
        years.label = Label.PC_Years;
        years.value = String.valueOf(PC_Constants.OffsetType.Years);
        allOffsetTypeOptions.add(days);
        allOffsetTypeOptions.add(months);
        allOffsetTypeOptions.add(years);
        return allOffsetTypeOptions;
    }
    /*********************************************************************************
      Method Name    : getOperatorOptions
      Author         : Kanteti Kishore
      Description    : This method returns all operation options of Date/Datetime formula
      Return Type    : List<DropdownValue>
     *********************************************************************************/
    @AuraEnabled
    public static List<DropdownValue> getOperationOptions(){
        List<DropdownValue> allOperationOptions = new List<DropdownValue>();
        DropdownValue add = new DropdownValue();
        add.label = Label.PC_After;
        add.value = String.valueOf(PC_Constants.FormulaOperators.Add);
        DropdownValue subtract = new DropdownValue();
        subtract.label = Label.PC_Before;
        subtract.value = String.valueOf(PC_Constants.FormulaOperators.Subtract);
        allOperationOptions.add(add);
        allOperationOptions.add(subtract);
        return allOperationOptions;
    }
    /*********************************************************************************
      Method Name    : getReferenceDateOrDatetimeFields
      Author         : Kanteti Kishore
      Description    : This method returns all date/datetime fields of provided object api name
      Return Type    : List<ReferenceField>
      @param         : String triggerEventObjectApiName
     *********************************************************************************/
    @AuraEnabled
    public static List<ReferenceField> getReferenceDateOrDatetimeFields(String triggerEventObjectApiName){
        List<ReferenceField> fieldsList = new List<ReferenceField>();
        try {
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType objSchema = schemaMap.get(triggerEventObjectApiName);
            Map<String, Schema.SObjectField> fieldsMap = objSchema.getDescribe().fields.getMap();
            String fieldType = '';
            for (String fieldName : fieldsMap.keySet()){
                fieldType = PC_Constants.EMPTY_STRING + fieldsMap.get(fieldName).getDescribe().getType();
                if (fieldType == PC_Constants.PC_FIELD_TYPE_DATE || fieldType == PC_Constants.PC_FIELD_TYPE_DATETIME){ //Todo: Add In constants class
                    ReferenceField eachField  = new ReferenceField();
                    eachField.label = fieldsMap.get(fieldName).getDescribe().getLabel();
                    eachField.value = fieldsMap.get(fieldName).getDescribe().getName();
                    eachField.type = fieldType;
                    fieldsList.add(eachField);
                }
            }
        }catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return fieldsList;
    }
    /*********************************************************************************
      Method Name    : getLookupFieldObjectInfo
      Author         : Tushar Arora
      Description    : This method returns a record lookup field object api name. This method can further be extended to get lookup field details.
      Return Type    : String
      Parameter      : selectedObject (API Name) and lookupField (Api Name)
     *********************************************************************************/
    @AuraEnabled
    public static String getLookupFieldObjectInfo(String selectedObject, String lookupField){
        String strLookupFieldObject = '';
        try{
            Schema.DescribeFieldResult f = Schema.getGlobalDescribe()
                    .get(selectedObject)
                    .getDescribe()
                    .fields
                    .getMap()
                    .get(lookupField)
                    .getDescribe();

            for(Schema.SObjectType reference : f.getReferenceTo()) {
                strLookupFieldObject = reference.getDescribe().getName();
            }

        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return strLookupFieldObject;
    }

    public inherited sharing class DateAndDatetimeFormulaOptions{
        @AuraEnabled
        public List<ReferenceField> dateAndDatetimeFields {get;set;}
        @AuraEnabled
        public List<DropdownValue> operationOptions {get;set;}
        @AuraEnabled
        public List<DropdownValue> offsetTypeOptions {get;set;}

        public void DateAndDatetimeFormulaOptions(){}
    }
    public inherited sharing class ReferenceField{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}
        @AuraEnabled
        public String type {get; set;}
    }
    public inherited sharing class DropdownValue{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}
    }
    public inherited sharing class FieldDetail{           //check if it can be private

        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String labelWithMandatoryIndicator {get; set;}
        @AuraEnabled
        public String apiName {get; set;}
        @AuraEnabled
        public String type {get; set;}
        @AuraEnabled
        public Boolean mandatory {get; set;}
        @AuraEnabled
        public Boolean active {get; set;}

        public void fieldDetail(){}
    }
    public inherited sharing class ObjectFieldsResponse{            //check if it can be private  //Response
        @AuraEnabled
        public String objectName {get; set;}
        @AuraEnabled
        public String objectLabel {get; set;}
        @AuraEnabled
        public List<fieldDetail> fields {get; set;}

        public void ObjectFields(){}
    }
    public inherited sharing class ObjectFieldsDetailedRequest{       //Request
        @AuraEnabled
        public String objectName {get; set;}
        @AuraEnabled
        public Boolean includeFormulaFields {get; set;}
        @AuraEnabled
        public Boolean includeLookUpFields {get; set;}
        @AuraEnabled
        public Boolean includeRecordTypeId {get; set;}  //reqd
        @AuraEnabled
        public Boolean showMandatoryFieldIndicator {get; set;}
        @AuraEnabled
        public Boolean includeNonUpdateableFields {get; set;}
        @AuraEnabled
        public Boolean includeEncryptedFields {get; set;}

        public void objectFieldsDetailedRequest(){}
    }

    public inherited sharing class ObjectFieldsRequest{
        @AuraEnabled
        public String objectName {get; set;}
        @AuraEnabled
        public String builderContext {get; set;}
        @AuraEnabled
        public Boolean includeRecordTypeId {get;set;}

        public void objectFieldsRequest(){}
    }
}