/*****************************************************************************************
Class Name    	: PC_OcrResponseHelper
Description     : Helper Class for OCR Response Trigger
Created By      : Deloitte
Created Date    : May 03, 2021
Modification Log:
--------------------------------------------------------------------------------------------
Developer                   Date                   Description
---------------------------------------------------------------------------------------------
Satheesh Kumar             May 03, 2021           Initial Version
*********************************************************************************************/

public with sharing class PC_OcrResponseHelper {

    private static List<String> invalidFieldApiNameList = new List<String>();
    public static Map<String, SObjectType> globalDescribe {
        get {
            if (globalDescribe == null)
                globalDescribe = Schema.getGlobalDescribe();
            return globalDescribe;
        }
        set {
        }
    }

    public static Map<Id, List<PC_OcrTemplateMapping__c>> getOcrTemplateMapping(Set<Id> templateTypeIds) {
        Map<Id, List<PC_OcrTemplateMapping__c>> mapTemplateTypeIdToTemplateMappings = new Map<Id, List<PC_OcrTemplateMapping__c>>();
        /*FLS Check for OCRTemplateMapping fields*/
        List<String> ocrTemplateMappingFields = new List<String>{
                'Id', 'Name', PC_Constants.getQualifiedAPIName('PC_OcrTemplateType__c'), PC_Constants.getQualifiedAPIName('PC_TargetObject__c'),
                PC_Constants.getQualifiedAPIName('PC_TargetObjectRecordType__c'), PC_Constants.getQualifiedAPIName('PC_FieldMapping__c'),
                PC_Constants.getQualifiedAPIName('PC_IsActive__c')
        };
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_OcrTemplateMapping__c'), PC_Database.Operation.Reading, ocrTemplateMappingFields);
        for (PC_OcrTemplateMapping__c otm : [SELECT Id, Name, PC_OcrTemplateType__c, PC_TargetObject__c, PC_TargetObjectRecordType__c, PC_FieldMapping__c, PC_IsActive__c FROM PC_OcrTemplateMapping__c WHERE PC_IsActive__c = true AND PC_OcrTemplateType__c IN :templateTypeIds]) {
            if (mapTemplateTypeIdToTemplateMappings.containsKey(otm.PC_OcrTemplateType__c)) {
                List<PC_OcrTemplateMapping__c> getTemplateMappings = mapTemplateTypeIdToTemplateMappings.get(otm.PC_OcrTemplateType__c);
                getTemplateMappings.add(otm);
                mapTemplateTypeIdToTemplateMappings.put(otm.PC_OcrTemplateType__c, getTemplateMappings);
            } else {
                mapTemplateTypeIdToTemplateMappings.put(otm.PC_OcrTemplateType__c, new List<PC_OcrTemplateMapping__c>{ otm });
            }
        }
        return mapTemplateTypeIdToTemplateMappings;
    }

    public static String parseOcrResponse(String ocrResponseId){
        Map<String, String> formResponseMap = new Map<String, String>();
        try {
            //FLS Check
            List<String> cdlFields = new List<String>{'LinkedEntityId', 'ContentDocumentId', 'ContentDocument.ContentModifiedDate'};
            PC_Database.assertAccess('ContentDocumentLink', PC_Database.Operation.Reading, cdlFields);
            List<String> cvFields = new List<String>{ 'Id', 'VersionData', 'Title', 'ContentDocumentId', 'IsLatest'};
            PC_Database.assertAccess('ContentVersion', PC_Database.Operation.Reading, cvFields);

            String contentDocumentId = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :ocrResponseId ORDER BY ContentDocument.ContentModifiedDate DESC Limit 1].ContentDocumentId;
            String ocrRawResponse = [SELECT VersionData,Title,ContentDocumentId, IsLatest FROM ContentVersion WHERE ContentDocumentId = :contentDocumentId AND IsLatest = true] ?.VersionData.toString();

            String ocrService = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_OCR_SERVICE_PROVIDER, PC_Constants.PC_OCR_SERVICE_AMAZON_TEXTRACT);
            if(Test.isRunningTest()) {
                ocrService = PC_Constants.PC_OCR_SERVICE_AMAZON_TEXTRACT;
            }
            if (ocrService.equalsIgnoreCase(PC_Constants.PC_OCR_SERVICE_AMAZON_TEXTRACT)) {
                system.debug('Parsing Start');
                //PC_OCR.ResponseParser parser = PC_OCR.getResponseParserClass(PC_Constants.PC_DEFAULT_TEXTRACT_RESPONSE_PARSER_CLASSNAME);
                PC_AwsTextractParser parser = new PC_AwsTextractParser();
                formResponseMap = parser.getFormData(ocrRawResponse);
                system.debug('Parsing End');
            } else {
                throw new PC_OcrResponseException(String.format('Configured {0} Service is not valid. Please contact your system administrator', new List<Object>{ocrService}));
            }
        } catch (Exception ex) {
            PC_Utility.createExceptionLog(ex);
        }
        return JSON.serialize(formResponseMap);
    }

    public static Map<String, String> createObjectFieldAndResponseMap(String ocrExtractedValues, String fieldMapping) {
        // fieldResponseMap is to store fieldApiName as key and extracted values as value.
        Map<String, String> fieldResponseMap = new Map<String, String>();
        Map<String, String> ocrResponseMap = (Map<String, String>) JSON.deserialize(ocrExtractedValues, Map<String, String>.class);
        FormFieldMapping formFieldMappingObj = (FormFieldMapping) System.JSON.deserialize(fieldMapping, FormFieldMapping.class);
        Map<String, String> mapOfFieldApiNameByFormField = new Map<String, String>();
        // Creating Map of Template Form fields and field Api Names
        for (FormFields mapping : formFieldMappingObj.formFields) {
            system.debug('mapping.order----' + mapping.order);
            String formField = (String.isNotBlank(String.valueOf(mapping.order)) && mapping.order > 1) ? mapping.formField + '_' + (mapping.order - 1) : mapping.formField;
            mapOfFieldApiNameByFormField.put(mapping.apiName, formField);
        }
        system.debug('mapOfFieldApiNameByFormField--' + mapOfFieldApiNameByFormField);
        for (String mappingFieldApiName : mapOfFieldApiNameByFormField.keySet()) {
            String formField = mapOfFieldApiNameByFormField.get(mappingFieldApiName);
            if (ocrResponseMap.get(formField) != null) {
                fieldResponseMap.put(mappingFieldApiName, ocrResponseMap.get(formField));
            }
        }
        return fieldResponseMap;
    }

    public static List<SObject> parseResponseJsonAsSobjects(PC_OcrResponse__c ocrResponse, List<PC_OcrTemplateMapping__c> ocrTemplateMappings) {
        List<SObject> newSObjectList = new List<SObject>();
        String extractedValues = parseOcrResponse(ocrResponse.Id);
        system.debug('extractedValues----------'+extractedValues);
        for (PC_OcrTemplateMapping__c otm : ocrTemplateMappings) {
            Map<String, String> fieldValueAndResponseMap = createObjectFieldAndResponseMap(extractedValues, otm.PC_FieldMapping__c);
            system.debug('fieldValueAndResponseMap----------'+fieldValueAndResponseMap);
            Schema.SObjectType sObjType = globalDescribe.get(otm.PC_TargetObject__c);
            SObject newRecord = sObjType.newSObject();
            if (otm.PC_TargetObject__c == PC_Constants.CANDIDATE_PATIENT_OBJECT) {
                newRecord.put('PC_IsCreatedUsingOCR__c', true);
            }
            //Get the Map of RecordTypeName along with Namespace and Record type Id for all Record Types in Object
            Map<String, Id> recordTypeIdMap = getSObjectRecordTypeMap(otm.PC_TargetObject__c);
            String mappedRecordTypeId = recordTypeIdMap.get(otm.PC_TargetObjectRecordType__c);
            invalidFieldApiNameList = new List<String>();
            for (String fieldApiName : fieldValueAndResponseMap.keySet()) {
                system.debug('fieldValueAndResponseMap.get('+fieldApiName+')----------'+fieldValueAndResponseMap.get(fieldApiName));
                mapFieldValuesForSObjectRecord(newRecord, fieldApiName, fieldValueAndResponseMap.get(fieldApiName), mappedRecordTypeId);
            }
            if (invalidFieldApiNameList.size() > 0) {
                String invalidFieldApiNames = String.join(new List<String>(invalidFieldApiNameList), ', ');
                throw new PC_OcrResponseException(String.format(System.Label.PC_InvalidFieldApiNameOcrMapping, new String[]{ '( '+invalidFieldApiNames+' )', otm.Name }));
            }
            String ownerFieldName = PC_Constants.OWNER_ID_PARAM;
            Boolean ownerFieldExists = Schema.getGlobalDescribe().get(otm.PC_TargetObject__c).getDescribe().fields.getMap().keySet().contains(ownerFieldName.toLowerCase());
            if (ownerFieldExists && String.isEmpty(String.valueOf(newRecord.get(ownerFieldName)))) {
                newRecord.put(ownerFieldName, (String) ocrResponse.get(PC_Constants.OWNER_ID_PARAM));
            }
            if(PC_Utility.isFieldAvailable(otm.PC_TargetObject__c, PC_Constants.PC_RECORD_TYPE_ID)){
                if(String.isNotBlank(mappedRecordTypeId)){
                    newRecord.put(PC_Constants.PC_RECORD_TYPE_ID, mappedRecordTypeId);
                }
            }
            newSObjectList.add(newRecord);
        }
        return newSObjectList;
    }

    public static String getFieldType(SObject sObjectRecord, String fieldName) {
        Schema.SObjectType sObjType = sObjectRecord.getSObjectType();
        Schema.DescribeSObjectResult r = sObjType.getDescribe();
        Schema.DescribeFieldResult f = r.fields.getMap()?.get(fieldName)?.getDescribe();
        String fieldType = f?.getType()?.name();
        return fieldType;
    }

    public static SObject mapFieldValuesForSObjectRecord(SObject sObjectRecord, String fieldApiName, String fieldValue, String recordtypeId) {
        String fieldType = getFieldType(sObjectRecord, fieldApiName);
        if(String.isBlank(fieldType)){
            invalidFieldApiNameList.add(fieldApiName);
        } else {
            if (fieldType == PC_Constants.PC_FIELD_TYPE_BOOLEAN) {
                sObjectRecord.put(fieldApiName, Boolean.valueOf(fieldValue));
            } else if (fieldType == PC_Constants.PC_FIELD_TYPE_DOUBLE
                    || fieldType == PC_Constants.PC_FIELD_TYPE_PERCENT
                    || fieldType == PC_Constants.PC_FIELD_TYPE_CURRENCY) {
                sObjectRecord.put(fieldApiName, Double.valueOf(fieldValue));
            } else if (fieldType == PC_Constants.PC_FIELD_TYPE_DATE) {
                sObjectRecord.put(fieldApiName, getDateValue(fieldValue));
            } else if (fieldType == PC_Constants.PC_FIELD_TYPE_DATETIME) {
                sObjectRecord.put(fieldApiName, PC_Utility.parseDatetimeFromJSON(fieldValue));
            } else if (fieldType == PC_Constants.PC_FIELD_TYPE_TIME) {
                sObjectRecord.put(fieldApiName, PC_Utility.parseTimeFromJSONString(fieldValue));
            } else {
                sObjectRecord.put(fieldApiName, fieldValue);
            }
        }
        return sObjectRecord;
    }

    public static Map<String, Id> getSObjectRecordTypeMap(String sObjectName) {
        Map<String, Id> recordTypeIdMap = new Map<String, Id>();
        //FLS Check
        List<String> recordTypeFields = new List<String>{'Id', 'DeveloperName', 'NamespacePrefix', 'SobjectType', 'isActive'};
        PC_Database.assertAccess('RecordType', PC_Database.Operation.Reading, recordTypeFields);
        for (RecordType recordTypeDetailsObj : [Select Id, DeveloperName, NamespacePrefix FROM RecordType WHERE SobjectType = :sObjectName AND isActive = true]) {
            String recordTypeNameWithNamespace;
            if (String.isNotEmpty(recordTypeDetailsObj.NamespacePrefix)) {
                recordTypeNameWithNamespace = recordTypeDetailsObj.NamespacePrefix + '__' + recordTypeDetailsObj.DeveloperName;
            } else {
                recordTypeNameWithNamespace = recordTypeDetailsObj.DeveloperName;
            }
            recordTypeIdMap.put(recordTypeNameWithNamespace, recordTypeDetailsObj.Id);
        }
        return recordTypeIdMap;
    }

    /*public inherited sharing class FieldMap {
        public String formField { get; set; }
        public String apiName { get; set; }

        public FieldMap() {
            formField = PC_Constants.EMPTY_STRING;
            apiName = PC_Constants.EMPTY_STRING;
        }
    }*/

    public inherited sharing class FormFieldMapping {
        public Properties properties;
        public List<FormFields> formFields;
    }

    public inherited sharing class FormFields {
        public String formField;
        public String apiName;
        public Integer order;
    }

    public inherited sharing class Properties {}

    public static Date getDateValue(String dateString) {
        Date dateObj;
        dateString = String.isNotBlank(dateString) ? dateString.replaceAll( '\\s+', '') : '';
        try {
            try {
                dateObj = Date.parse(dateString); // parse works when date string in dd/MM/YYYY format.
            } catch (Exception e) {
            }
            if (dateObj == null) {
                try {
                    dateObj = Date.valueOf(dateString); // valueOf works when date string in YYYY-MM-dd format.
                } catch (Exception e) {
                }
            }
            if (dateObj == null) {
                throw new PC_OcrResponseException(String.format('Invalid date: {0}', new String[]{ dateString }));
            }
        } catch (Exception ex) {
            PC_Utility.createExceptionLog(ex);
        }
        return dateObj;
    }

    public inherited sharing class PC_OcrResponseException extends Exception {
    }
}