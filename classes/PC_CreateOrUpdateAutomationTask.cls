/*********************************************************************************************************
Class Name      : PC_CreateOrUpdateAutomationTask
Description     : controller class for update record activity type in support plan PC_CreateOrUpdateAutomationTask
Created By      : Kishore Kanteti
Created Date    : June 22, 2020
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------
Kishore Kanteti           June22,2020            Initial Version
Haritha Reddy             21-Jan-2021                 [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
************************************************************************************************************/
public with sharing class PC_CreateOrUpdateAutomationTask {

    /**All objects and childUpdateOptions will be returned to the given sObject and child object.
   *In edit mode both objects and child update options are returned or else only objects.
* @param triggerEventObject
* @param selectedChildObject
* @return returns Objects and childUpdateOptions Wrapper if both params are present or else only objects.
*/
    @AuraEnabled
    public static ObjectsAndChildUpdateOptions getObjectsAndChildUpdateOptions(String triggerEventObject, String selectedChildObject) {
        ObjectsAndChildUpdateOptions objectsAndOptions = new ObjectsAndChildUpdateOptions();
        try {
            objectsAndOptions = new ObjectsAndChildUpdateOptions(triggerEventObject, selectedChildObject);
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return objectsAndOptions;
    }

    /*********************************************************
   Method Name          : getObjects
   Description          : returns All lookup Objects,related objects to the given sObject
   Input Params         : String sObject Name
   Return Type          : Returns all Objects Wrapper.
   *********************************************************************************/
    @AuraEnabled
    public static Objects getObjects(String triggerEventObject) {
        List<objectDetail> lookUpObjects = new List<objectDetail>();
        List<objectDetail> childObjects = new List<objectDetail>();
        try {
            Map<String, String> lookUpFields = new Map<String, String>();
            lookUpFields = getLookUpFields(triggerEventObject);
            childObjects = getChildObjects(triggerEventObject);
            String lookupFieldObjectLabel = '';
            String lookupFieldObjectApiName = '';
            String lookupFieldLabel = '';
            for (String eachField : lookUpFields.keySet()) {
                Schema.DescribeFieldResult lookUpFieldDescription = Schema.getGlobalDescribe()
                        .get(triggerEventObject)
                        .getDescribe()
                        .fields
                        .getMap()
                        .get(eachField)
                        .getDescribe();

                for (Schema.SObjectType reference : lookUpFieldDescription.getReferenceTo()) {
                    lookupFieldObjectLabel = reference.getDescribe().getLabel();
                    lookupFieldObjectApiName = reference.getDescribe().getName();
                }
                lookupFieldLabel = lookUpFields.get(eachField) + ' (' + lookupFieldObjectLabel  + ')';
                objectDetail lookUpObjectDetail = new objectDetail(lookupFieldLabel, eachField, lookupFieldObjectLabel,
                        lookupFieldObjectApiName, PC_Constants.SUPPORTPLAN_UPDATE_LOOKUP_RECORD, '');
                lookUpObjects.add(lookUpObjectDetail);
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        Objects lookupAndChildObjects = new Objects(lookUpObjects, childObjects);
        return lookupAndChildObjects;
    }
    /*********************************************************************************
      Method Name    : getChildObjects
      Author         : Kanteti Kishore
      Description    : This method returns a Map of all child object values and labels of the
                       given SObject's API name
      Return Type    : List<objectDetail>
      Parameter      : SObjects API Name
    *********************************************************************************/
    @AuraEnabled
    public static List<objectDetail> getChildObjects(String triggerEventObjectName) {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(triggerEventObjectName);
        Schema.DescribeSObjectResult triggerEventObjectResults = leadSchema.getDescribe();
        List<objectDetail> childObjects = new List<objectDetail>();
        Map<String, Schema.ChildRelationship> fieldLabelChildRelationshipMap = new Map<String, Schema.ChildRelationship>();
        List<String> fieldLabelsSortKeys = new List<String>();
        for (Schema.ChildRelationship eachChildRelationship : triggerEventObjectResults.getChildRelationships()) {
            if (eachChildRelationship.getRelationshipName() != null) {
                fieldLabelChildRelationshipMap.put(eachChildRelationship.getChildSObject().getDescribe().getLabel().toUpperCase() + ',' + eachChildRelationship.getRelationshipName(), eachChildRelationship);
                fieldLabelsSortKeys.add(eachChildRelationship.getChildSObject().getDescribe().getLabel().toUpperCase() + ',' + eachChildRelationship.getRelationshipName());
            }
        }
        fieldLabelsSortKeys.sort();
        for (String fieldLabel : fieldLabelsSortKeys) {
            Schema.ChildRelationship cr = fieldLabelChildRelationshipMap.get(fieldLabel);
            objectDetail childObjectDetail = new objectDetail('', '', cr.getChildSObject().getDescribe().getLabel(), cr.getChildSObject().getDescribe().getName(),
                    PC_Constants.SUPPORTPLAN_UPDATE_CHILD_RECORDS, cr.getRelationshipName());
            childObjects.add(childObjectDetail);
        }
        return childObjects;
    }

    /*********************************************************************************
      Method Name    : getLookUpFields
      Author         : Kanteti Kishore
      Description    : This method returns a Map of all lookup values and labels of the
                       supplied SObject's API name
      Return Type    : Map<String, String>
      Parameter      : SObjects API Name
    *********************************************************************************/
    @AuraEnabled
    public static Map<String, String> getLookUpFields(String triggerEventObjectName) {
        Map<String, String> fieldsMapSorted = new Map<String, String>();
        try {
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType leadSchema = schemaMap.get(triggerEventObjectName);
            Map<String, Schema.SObjectField> fieldMapWithSystemFields = (Map<String, SObjectField>) leadSchema.getDescribe().fields.getMap();
            Map<String, Schema.SObjectField> fieldMap = PC_Utility.removeSystemFields(fieldMapWithSystemFields);
            Map<String, String> fieldsMap = new Map<String, String>();
            List<String> fieldsMapSortKey = new List<String>();

            if (!fieldMap.isEmpty()) {
                String label = '';
                String value = '';
                for (String fieldName : fieldMap.keySet()) {
                    String fieldType = PC_Constants.EMPTY_STRING + fieldMap.get(fieldName).getDescribe().getType();
                    if (fieldType != PC_Constants.PC_FIELDTYPE_REFERENCE) {
                        continue;
                    }

                    label = fieldMap.get(fieldName).getDescribe().getLabel() ;
                    value = fieldMap.get(fieldName).getDescribe().getName();
                    fieldsMap.put(value, label);

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
                        fieldsMap.remove(fKey);//remove the key for better looping
                    }
                }
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return fieldsMapSorted;
    }
    /*********************************************************************************
     Method Name    : getOrderByFields
     Author         : Kanteti Kishore
     Description    : This method returns orderByfields required
                        in updating child records scenario
     Return Type    : List<Option>
     Parameter      : SObjects API Name
   *********************************************************************************/
    @AuraEnabled
    public static List<Option> getOrderByFields(String selectedChildObject) {
        List<Option> orderByFields = new List<Option>();
        //Adding orderByFields
        try {
            Map<String, String> fieldsMapSorted = new Map<String, String>();
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType leadSchema = schemaMap.get(selectedChildObject);
            Map<String, Schema.SObjectField> fieldMap = (Map<String, SObjectField>) leadSchema.getDescribe().fields.getMap();
            Map<String, String> fieldsMap = new Map<String, String>();
            List<String> fieldsMapSortKey = new List<String>();
            if (!fieldMap.isEmpty()) {
                String label = '';
                String value = '';
                for (String fieldName : fieldMap.keySet()) {
                    if(fieldName != PC_Constants.PC_MasterRecordId && fieldName != PC_Constants.PC_IsDeleted){
                        String fieldType = PC_Constants.EMPTY_STRING + fieldMap.get(fieldName).getDescribe().getType();
                        if (fieldType == PC_Constants.PC_FIELDTYPE_REFERENCE || fieldType == PC_Constants.PC_TEXTAREA ||
                                fieldType == PC_Constants.PC_ENCRYPTEDSTRING || fieldType == PC_Constants.PC_MULTIPICKLIST ||
                                fieldMap.get(fieldName).getDescribe().isEncrypted()) {
                            continue;
                        }
                        label = fieldMap.get(fieldName).getDescribe().getLabel();
                        value = fieldMap.get(fieldName).getDescribe().getName();
                        fieldsMap.put(value, label);
                    }
                }
                //Sorting
                for (String fKey : fieldsMap.keySet()) {
                    fieldsMapSortKey.add(fieldsMap.get(fKey).toUpperCase()); // Convert to upper case as sorting is case sensitive.
                }
                fieldsMapSortKey.sort(); // Apply Sort on the list of labels
                for (String fSortKey : fieldsMapSortKey) { // loop through the sorted labels
                    for (String fKey : fieldsMap.keySet()) { // loop through the Map
                        if (fSortKey == fieldsMap.get(fKey).toUpperCase()) { // if the labels match
                            fieldsMapSorted.put(fKey, fieldsMap.get(fKey)); // add the key and value to new map
                            fieldsMap.remove(fKey);//remove the key for better looping
                        }
                    }
                }
                for (String eachField : fieldsMapSorted.keySet()) {
                    Option eachOrderByField = new Option(fieldsMapSorted.get(eachField), eachField);
                    orderByFields.add(eachOrderByField);
                }
            }
        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return orderByFields;
    }
    /*********************************************************************************
     Method Name    : getOrderOptions
     Author         : Kanteti Kishore
     Description    : This method returns orderOptions required
                        in updating child records scenario
     Return Type    : List<Option>
     Parameter      : SObjects API Name
   *********************************************************************************/
    @AuraEnabled
    public static List<Option> getOrderOptions() {
        List<Option> orderOptions = new List<Option>();
        try {
            //Adding Order Options
            Option ascendingOrderOption = new Option(System.Label.PC_Ascending, PC_Constants.PC_ASCENDING);
            Option descendingOrderOption = new Option(System.Label.PC_Descending, PC_Constants.PC_DESCENDING);
            orderOptions.add(ascendingOrderOption);
            orderOptions.add(descendingOrderOption);
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return orderOptions;
    }
    /*********************************************************************************
     Method Name    : getNullsOptions
     Author         : Kanteti Kishore
     Description    : This method returns nullsOptions required
                        in updating child records scenario
     Return Type    : List<Option>
     Parameter      : SObjects API Name
   *********************************************************************************/
    @AuraEnabled
    public static List<Option> getNullsOptions() {
        List<Option> nullsOptions = new List<Option>();
        try {
            //Adding Order Options
            Option lastOption = new Option(System.Label.PC_AtEnd, PC_Constants.PC_LAST);
            Option firstOption = new Option(System.Label.PC_AtBeginning, PC_Constants.PC_FIRST);
            nullsOptions.add(lastOption);
            nullsOptions.add(firstOption);
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return nullsOptions;
    }
    /*********************************************************************************
     Method Name    : getCriteriaOptions
     Author         : Kanteti Kishore
     Description    : This method returns criteriaOptions required
                        in updating child records scenario
     Return Type    : List<Option>
     Parameter      : SObjects API Name
   *********************************************************************************/
    @AuraEnabled
    public static List<Option> getCriteriaOptions() {
        List<Option> criteriaOptions = new List<Option>();
        try {
            //Adding Criteria Options
            Option allRecordsCriteria = new Option(System.Label.PC_UpdateRecord_CriteriaAllRecords, PC_Constants.PC_UPDATE_ALL_RECORDS);
            Option firstRecordCriteria = new Option(System.Label.PC_UpdateRecord_CriteriaFirstRecord, PC_Constants.PC_UPDATE_FIRST_RECORD);
            Option onlyRecordCriteria = new Option(System.Label.PC_UpdateRecord_CriteriaOnlyRecord, PC_Constants.PC_UPDATE_ONLY_RECORD);
            criteriaOptions.add(allRecordsCriteria);
            criteriaOptions.add(firstRecordCriteria);
            criteriaOptions.add(onlyRecordCriteria);
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return criteriaOptions;
    }
    /*********************************************************************************
     Method Name    : getChildUpdateOptions
     Author         : Kanteti Kishore
     Description    : This method returns orderByfields,Order Options,criteria options required
                        in updating child records scenario in one wrapper ChildUpdateOptions
     Return Type    : ChildUpdateOptions
     Parameter      : SObjects API Name
   *********************************************************************************/
    @AuraEnabled
    public static ChildUpdateOptions getChildUpdateOptions(String selectedChildObject) {
        ChildUpdateOptions allChildUpdateOptions = new ChildUpdateOptions();
        if (selectedChildObject != '') {
            allChildUpdateOptions = new ChildUpdateOptions(selectedChildObject);
        }
        return allChildUpdateOptions;
    }

    public inherited sharing class Option {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String value { get; set; }
        @AuraEnabled
        public Boolean selected { get; set; }

        public Option(String picklistLabel, String picklistValue) {
            this.label = picklistLabel;
            this.value = picklistValue;
            this.selected = false;
        }
    }
    public inherited sharing class ChildUpdateOptions {
        @AuraEnabled
        public List<Option> orderByFields { get; set; }
        @AuraEnabled
        public List<Option> orderOptions { get; set; }
        @AuraEnabled
        public List<Option> criteriaOptions { get; set; }
        @AuraEnabled
        public List<Option> nullsOptions { get; set; }

        public ChildUpdateOptions() {}
        public ChildUpdateOptions(String selectedChildObject) {
            this.orderByFields = getOrderByFields(selectedChildObject);
            this.orderOptions = getOrderOptions();
            this.criteriaOptions = getCriteriaOptions();
            this.nullsOptions = getNullsOptions();
        }
    }

    public inherited sharing class ObjectDetail {
        @AuraEnabled
        public String lookupFieldLabel { get; set; }
        @AuraEnabled
        public String lookupFieldApiName { get; set; }
        @AuraEnabled
        public String objectLabel { get; set; }
        @AuraEnabled
        public String objectApiName { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public Boolean selected { get; set; }
        @AuraEnabled
        public String childRelationshipName { get; set; }

        public ObjectDetail(String fieldLabel, String fieldApiName, String objectLabel, String objectApiName, String type, String childRelationshipName) {
            this.lookupFieldLabel = fieldLabel ;
            this.lookupFieldApiName = fieldApiName;
            this.objectLabel = objectLabel;
            this.objectApiName = objectApiName;
            this.type = type;
            this.selected = false;
            this.childRelationshipName = childRelationshipName;
        }
    }

    public inherited sharing class Objects {
        @AuraEnabled
        public List<objectDetail> triggerEventLookupObjects { get; set; }
        @AuraEnabled
        public List<objectDetail> triggerEventChildObjects { get; set; }

        public Objects(List<objectDetail> lookupObjects, List<objectDetail> childObjects) {
            triggerEventLookupObjects = lookupObjects;
            triggerEventChildObjects = childObjects;
        }
    }

    public inherited sharing class ObjectsAndChildUpdateOptions {
        @AuraEnabled
        public Objects lookupAndChildObjects { get; set; }
        @AuraEnabled
        public childUpdateOptions childUpdateOptions { get; set; }
        public ObjectsAndChildUpdateOptions() {
        }
        public ObjectsAndChildUpdateOptions(String triggerEventObjectName, String selectedChildObject) {
            this.lookupAndChildObjects = getObjects(triggerEventObjectName);
            this.childUpdateOptions = getChildUpdateOptions(selectedChildObject);
        }
    }
}