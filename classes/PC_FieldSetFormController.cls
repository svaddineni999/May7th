/**
 * Created by sathekumar on 9/30/2021.
 */

public with sharing class PC_FieldSetFormController {

    /**
    * Retrieves all the fields of the provided fieldset list
    *
    * @param sObjectName   API Name of the object
    * @param fieldSetNames   List of fieldset names
    * @return List<FieldSetWrapper>  List of Wrapper Object <FieldSetWrapper>
    */
    @AuraEnabled(cacheable=true)
    public static List<FieldSetWrapper> getFields(String sObjectName, List<String> fieldSetNames) {
        Schema.sObjectType sObjectType = null;
        List<FieldSetWrapper> fieldSetWrapperList = new List<FieldSetWrapper>();

        try {
            if (!String.isBlank(sObjectName)) {
                sObjectType = Schema.getGlobalDescribe().get(sObjectName.toLowerCase());
            }
            // Get the SObject
            Schema.DescribeSObjectResult sobjectDescribe = sObjectType.getDescribe();
            // Get the Object fields
            Map<String, Schema.FieldSet> fieldSetMap = sobjectDescribe.fieldSets.getMap();

            if (fieldSetNames.size() > 0) {
                for (String fieldSetName : fieldSetNames) {
                    // Check if we have a fieldset with that name
                    if (fieldSetMap.containsKey(fieldSetName)) {
                        FieldSetWrapper fieldSetWrapper = new FieldSetWrapper();
                        List<FieldSetField> fields = new List<FieldSetField>();
                        Schema.FieldSet fieldSet = fieldSetMap.get(fieldSetName);
                        if (fieldSet != null) {
                            List<Schema.FieldSetMember> fieldSetMemberList = fieldSet.getFields();
                            fieldSetWrapper.fieldSetLabel = fieldSet.getLabel();
                            Map<String, SObjectField> fieldsMap = sObjectType.getDescribe().fields.getMap();
                            if (fieldSetMemberList != null && !fieldSetMemberList.isEmpty()) {
                                for (Schema.FieldSetMember fsm : fieldSetMemberList) {
                                    String fieldApiName = fsm.getFieldPath();
                                    if (fieldsMap.get(fieldApiName).getDescribe().isAccessible()) {
                                        FieldSetField fieldSetField = new FieldSetField(fsm);
                                        //fieldSetField.isAccessible = fieldsMap.get(fsm.getFieldPath()).getDescribe().isAccessible();
                                        fieldSetField.isUpdateable = fieldsMap.get(fieldApiName).getDescribe().isUpdateable();
                                        fields.add(fieldSetField);
                                    }
                                }
                                if (fields.isEmpty()) {
                                    throw new PC_FieldSetFormException(String.format(System.Label.PC_NoAccessibleFieldsError, new List<Object>{fieldSetName}));
                                }
                                fieldSetWrapper.fieldSetFields = fields;
                                fieldSetWrapperList.add(fieldSetWrapper);
                            }
                        }
                    } else {
                        throw new PC_FieldSetFormException(String.format(System.Label.PC_FieldSetNotFoundError, new List<Object>{fieldSetName, sObjectName}));
                    }
                }
            } else {
                throw new PC_FieldSetFormException(System.Label.PC_FieldSetRequiredError);
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return fieldSetWrapperList;
    }

    /**
    * Wrapper class for Field set Field
    */
    public inherited sharing class FieldSetField {
        @AuraEnabled
        public Boolean dbRequired;
        @AuraEnabled
        public String apiName;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public Boolean required;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public Boolean isUpdateable;

        public FieldSetField(Schema.FieldSetMember fieldSetMember) {
            this.dbRequired = fieldSetMember.dbRequired;
            this.apiName = fieldSetMember.fieldPath;
            this.label = fieldSetMember.label;
            this.required = fieldSetMember.required || fieldSetMember.DBRequired;
            this.type = String.valueOf(fieldSetMember.getType());
        }
    }

    /**
    * Wrapper class for FieldSet
    */
    public inherited sharing class FieldSetWrapper {
        @AuraEnabled
        public String fieldSetLabel;
        @AuraEnabled
        public List<FieldSetField> fieldSetFields;

        public FieldSetWrapper() {
            this.fieldSetLabel = PC_Constants.EMPTY_STRING;
            this.fieldSetFields = new List<FieldSetField>();
        }
    }

    public inherited sharing class PC_FieldSetFormException extends Exception {
    }
}