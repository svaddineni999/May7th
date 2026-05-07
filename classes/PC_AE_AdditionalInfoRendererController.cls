/*
 - Created by vkashikar on 12/5/2018.
Modification Log:
----------------------------------------------------------------------------------
Developer              Date             Description
-----------------------------------------------------------------------------------
Shishir Bansal        Nov-15-2019       [PC-5730] bug fix checkbox availability in fieldset
Shishir Bansal        Dec-06-2019      [PC-5792] Avoid hardcoding of string variable
Haritha Reddy         Dec-10-2019      [PC-5791] Removed getFieldsetFieldsLabels which is not in use
Chetna Mohapatra      Jun-10-2020       [PC-5948] Added logic in getPopulatedFieldSet for validation and error handling w.r.t Additional Info Tab fieldset.
Haritha Reddy         21-Jan-2021       [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*/

public with sharing class PC_AE_AdditionalInfoRendererController implements PC_AdverseEventMenuController.AdverseEventProcessor{

    public void updateAdverseEvent(PC_AdverseEvent__c aeRec, Map<Object,Object> additionalInfoObj) {
        try{
            String value;
            Object castValue;
            String fieldName;
            if(additionalInfoObj != null) {
                for(Object fieldNameObject : additionalInfoObj.keySet()) {
                    fieldName = (String) fieldNameObject;
                    //value = (String) additionalInfoObj.get(fieldName);
                    castValue = PC_FieldSetController.castFieldValueBasedOnType(fieldName, additionalInfoObj.get(fieldName), aeRec);
                    aeRec.put(fieldName, castValue);
                }
            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }

    @AuraEnabled
    public static FieldPathAndValue getPopulatedFieldSet(String aeId, Map<Object,Object> additionalInfoObj, String typeName, String fsName) {
        try {
            FieldPathAndValue fieldPathAndValue = new FieldPathAndValue();
            if(fsName != null && fsName != PC_Constants.EMPTY_STRING && fsName != PC_Constants.UNDEFINED_STRING){

                Boolean isValid = PC_Utility.isValidFieldset(PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'),fsName );
                if(!isValid){
                    PC_AdverseEvent_PDF_Controller.AdverseEvent_PDF_Exception fieldSetException  = new PC_AdverseEvent_PDF_Controller.AdverseEvent_PDF_Exception();
                    fieldSetException.errorMessage = Label.PC_AdverseEvent_PDF_FieldsetErrorMessage;
                    fieldSetException.errorCode = null;
                    throw fieldSetException;
                }
                List<String> fieldPath = PC_FieldSetController.getFieldsByName(typeName, fsName);
                //PC-3937: Added for PDF
                List<PC_FieldSetController.FieldSetMember> fieldSetMembers=PC_FieldSetController.getFields(typeName,fsName);

                if (fieldPath!=null && !fieldPath.isEmpty()) {
                    String commaSeparatedFields = String.join(fieldPath, ',');
                    Map<Object, Object> fieldValuePair = new Map<Object, Object>();
                    if (additionalInfoObj == null) {
                        additionalInfoObj = new Map<Object, Object>();
                    }
                    //FLS check
                    PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'), PC_Database.Operation.Reading, fieldPath);
                    String queryAe = 'Select ' + commaSeparatedFields + ' from PC_AdverseEvent__c ' + 'where id =:aeId';
                    for (SObject sob : Database.query (queryAe)) {
                        for (String field : fieldPath) {
                            Object value = sob.get(field);
                            if (value != null) {
                                if ((value == true) || (value == false)) {
                                    fieldValuePair.put(field, value);
                                } else {
                                    fieldValuePair.put(field, String.valueOf(value));
                                }
                            }  else
                                    fieldValuePair.put(field, PC_Constants.EMPTY_STRING);
                        }
                    }

                    //PC-3937: Added for PDF
                    Map<Object, Object> fieldLabelsMap = new Map<Object, Object>();
                    for (PC_FieldSetController.FieldSetMember fieldSetMember : fieldSetMembers) {
                        fieldLabelsMap.put(fieldSetMember.fieldPath, fieldSetMember.label);
                    }

                    fieldPathAndValue.fieldPath = fieldPath;
                    fieldPathAndValue.fieldValue = fieldValuePair;
                    //PC-3937: Added for PDF
                    fieldPathAndValue.fieldLabels = fieldLabelsMap;
                    return fieldPathAndValue;
                }else{
                    return null;
                }
        }

        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
		return null;
    }

    public inherited sharing class FieldPathAndValue {
        @AuraEnabled public List<String> fieldPath { get; set; }
        @AuraEnabled public Map<Object,Object> fieldValue { get; set; }
        @AuraEnabled public Map<Object,Object> fieldLabels { get; set; }

        public FieldPathAndValue() {
        }
    }
}