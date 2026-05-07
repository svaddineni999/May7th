/*
Modification Log:
----------------------------------------------------------------------------------
Developer              Date             Description
-----------------------------------------------------------------------------------            
Ajinkya Deshmukh       6/27/2017        with sharing keyword added
Vijay Kashikar         20 Sep, 2018     [PC-3649] Added a new method copyFieldSetValues to copy field set values to health cloud patient object
Mike Klumpenaar        Feb 20, 2019     [PC-4475] Made class and all members global
Mike Klumpenaar        Apr 1, 2019      [PC-4688] Made copyFieldSetValues global
Shishir Bansal        06-Dec-2019      [PC-5792] Avoid hardcoding of string variable
Haritha Reddy         16-Dec-2019       [PC-5791] Added error handling for getFields Method
Chetna Mohapatra      03-Apr-2020       [PC-6125] Created a method castFieldValueAsString which will return fieldValue in String format only.
Vijay Kashikar        21-Jan-2021       [PC-7102] Added sharing clause
Kishore Kanteti       24-Nov-2021       [PC-8239] Modified code in castFieldValuesBasedOnType for supporting Currency and Percent Fields.
*/

/**
 * Utility class for embedding field sets in lightning components.
 */
global with sharing class PC_FieldSetController {

    @AuraEnabled
    global static List<FieldSetMember> getFields(String typeName, String fsName) {
        List<FieldSetMember> fset = new List<FieldSetMember>();
        try {
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(typeName);
            Schema.DescribeSObjectResult describe = targetType.getDescribe();
            Map<String, Schema.FieldSet> fsMap = describe.fieldSets.getMap();
            Schema.FieldSet fs = fsMap.get(fsName);
            if (fs != null) {
                List<Schema.FieldSetMember> fieldSet = fs.getFields();
                for (Schema.FieldSetMember f : fieldSet) {
                    fset.add(new FieldSetMember(f, targetType));
                }
            } else {
                FieldSetNullException fsNullException = new FieldSetNullException(Label.PC_AE_PDF_FIELDSET_NULL, PC_Constants.ERROR);
                throw fsNullException;
            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }

        return fset;
    }

    global inherited sharing class FieldSetMember {
        global FieldSetMember(Schema.FieldSetMember f) {
            this.DBRequired = f.DBRequired;
            this.fieldPath = f.fieldPath;
            this.label = f.label;
            this.required = f.required || f.DBRequired;
            this.type = PC_Constants.EMPTY_STRING + f.getType();
        }
        
		global FieldSetMember(Schema.FieldSetMember f, Schema.SObjectType targetType) {
            this.DBRequired = f.DBRequired;
            this.fieldPath = f.fieldPath;
            this.label = f.label;
            this.required = f.required || f.DBRequired;
            this.type = PC_Constants.EMPTY_STRING + f.getType();
            if(f.getType() == Schema.DisplayType.PICKLIST || f.getType() == Schema.DisplayType.MULTIPICKLIST) {
                List<Schema.PicklistEntry> ple = targetType.getDescribe().fields.getMap().get(f.fieldPath).getDescribe().getPicklistValues();
        		selectOptions = new List<SelectOptionWrapper>();
                
                if(f.getType() == Schema.DisplayType.PICKLIST) {
                	selectOptions.add(new SelectOptionWrapper(PC_Constants.EMPTY_STRING, System.Label.PC_Picklist_None));
                }
               	for( Schema.PicklistEntry pe : ple)
                {
                    selectOptions.add(new SelectOptionWrapper(pe.getValue(), pe.getLabel()));
                }
            }
        }

        global FieldSetMember(Boolean DBRequired) {
            this.DBRequired = DBRequired;
        }

        //@AuraEnabled
        global Boolean DBRequired { get;set; }

        @AuraEnabled
        global String fieldPath { get;set; }

        @AuraEnabled
        global String label { get;set; }

        @AuraEnabled
        global Boolean required { get;set; }

        @AuraEnabled
        global String type { get; set; }
        
        @AuraEnabled
        global List<SelectOptionWrapper> selectOptions { get; set; }
    }
    
    global inherited sharing class SelectOptionWrapper {
        global SelectOptionWrapper(String value, String label) {
            this.value = value;
            this.label = label;
            this.disabled = false;
            this.escapeItem = false;
        }

        global SelectOptionWrapper(String value, String label, Boolean isDisabled) {
            this.value = value;
            this.label = label;
            this.disabled = isDisabled;
            this.escapeItem = false;
        }
        
        @AuraEnabled
        global String label { get;set; }
        @AuraEnabled
        global String value { get;set; }
        //@AuraEnabled
        global Boolean disabled { get;set; }
        //@AuraEnabled
        global Boolean escapeItem { get;set; }
        
    }
    global static void copyFieldSetValues(Map<String, Object> fieldSetMap, sobject to_obj) {
    	if(fieldSetMap != null) {
            Object fieldValue;
            for (String fieldName : fieldSetMap.keySet()){
                fieldValue = fieldSetMap.get(fieldName);
                to_obj.put(fieldName,castFieldValueBasedOnType(fieldName, fieldValue, to_obj));
            }
        }
    }
    global static void copyFieldSetValues(Map<String, Object> fieldSetMap, sobject to_obj, HealthCloudGA.Patient patient) {
        if(fieldSetMap != null) {
            Object fieldValue;
            for (String fieldName : fieldSetMap.keySet()){
                fieldValue = fieldSetMap.get(fieldName);
                //to_obj.put(fieldName,castFieldValueBasedOnType(fieldName, fieldValue, to_obj));
                patient.customFields.put(fieldName,castFieldValueBasedOnType(fieldName, fieldValue, to_obj));
            }
        }
    }

    global static List<String> getFieldsByName(String typeName, String fsName) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(typeName);
        Schema.DescribeSObjectResult describe = targetType.getDescribe();
        Map<String, Schema.FieldSet> fsMap = describe.fieldSets.getMap();
        Schema.FieldSet fs = fsMap.get(fsName);
        List<Schema.FieldSetMember> fieldSet = fs.getFields();
        List<String> fset = new List<String>();
        for (Schema.FieldSetMember f: fieldSet) {
            fset.add(f.fieldPath);
        }
        return fset;
    }

    global static List<String> getFieldLabels(String typeName, String fsName) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(typeName);
        Schema.DescribeSObjectResult describe = targetType.getDescribe();
        Map<String, Schema.FieldSet> fsMap = describe.fieldSets.getMap();
        Schema.FieldSet fs = fsMap.get(fsName);
        List<Schema.FieldSetMember> fieldSet = fs.getFields();
        List<String> fset = new List<String>();
        for (Schema.FieldSetMember f: fieldSet) {
            fset.add(f.label);
        }
        return fset;
    }

    global static object castFieldValueBasedOnType(String fieldName, Object fieldValue, sObject sObj) {
        Schema.SObjectType sObjType = sObj.getSObjectType();
        Schema.DisplayType fieldType = sObjType.getDescribe().fields.getMap().get(fieldName).getDescribe().getType(); 
        object parsedFieldValue;
        if(fieldType == Schema.DisplayType.STRING) {
            parsedFieldValue = (String) fieldValue;
        }
        else if(fieldType == Schema.DisplayType.DATE) {
            if(!String.isEmpty(string.valueOf(fieldValue))){
                parsedFieldValue = Date.valueOf(string.valueOf(fieldValue));// Date.parse(fieldValue);
            }
        }
        else if(fieldType == Schema.DisplayType.DATETIME) {
            String formattedFieldValue = string.valueOf(fieldValue);
            if(!String.isEmpty(formattedFieldValue)){
            	formattedFieldValue = formattedFieldValue.replace('T', ' ');
                formattedFieldValue = formattedFieldValue.substringBeforeLast('.');
                parsedFieldValue = Datetime.valueOf(formattedFieldValue);                
            }
        }
        else if(fieldType == Schema.DisplayType.EMAIL) {
            parsedFieldValue = (String) fieldValue;
        }
        else if(fieldType == Schema.DisplayType.PICKLIST) {
            parsedFieldValue = (String) fieldValue;
        }
        else if(fieldType == Schema.DisplayType.CURRENCY) {
            String currencyValue = (String)fieldValue;
            if(String.isNotBlank(currencyValue)){
                parsedFieldValue = Decimal.valueOf(currencyValue);
            }
        }
        else if(fieldType == Schema.DisplayType.PERCENT) {
            String percentValue = (String)fieldValue;
            if(String.isNotBlank(percentValue)){
                parsedFieldValue = Decimal.valueOf(percentValue);
            }
        }
        else if (fieldType == Schema.DisplayType.BOOLEAN) {
            String formattedFieldValue = string.valueOf(fieldValue);
            if(!String.isEmpty(formattedFieldValue)){
                parsedFieldValue = Boolean.valueOf(fieldValue);
            }
            else {
                parsedFieldValue = false;
            }
        }
        else if (fieldType == Schema.DisplayType.DOUBLE) {
            String formattedFieldValue = string.valueOf(fieldValue);
            if(String.isEmpty(formattedFieldValue)){
                // nothing to do
            }
            else {
                parsedFieldValue = Double.valueOf(fieldValue);
            }
        }
        else if (fieldType == Schema.DisplayType.PHONE) {
            parsedFieldValue = (String) fieldValue;
        }
        else if (fieldType == Schema.DisplayType.TEXTAREA) {
            parsedFieldValue = (String) fieldValue;
        }
        else {
            parsedFieldValue = (String) fieldValue;
        }
        return parsedFieldValue;
    }
    /*********************************************************************************************
      * Method name: castFieldValueAsString
     * Description: This method will return the fieldValue in String format only.
     ******************************************************************************************/
    public static String castFieldValueAsString(String fieldName, Object fieldValue, sObject sObj) {
        Schema.SObjectType sObjType = sObj.getSObjectType();
        Schema.DisplayType fieldType = sObjType.getDescribe().fields.getMap().get(fieldName).getDescribe().getType();
        String parsedFieldValue;
        if(fieldType == Schema.DisplayType.STRING) {
            parsedFieldValue = (String) fieldValue;
        }
        else if(fieldType == Schema.DisplayType.DATE) {
            if(!String.isEmpty(string.valueOf(fieldValue))){
                Date dt = (Date) fieldValue;
                parsedFieldValue = dt.format();
            }
        }
        else if(fieldType == Schema.DisplayType.DATETIME) {
            String formattedFieldValue = string.valueOf(fieldValue);
            if(!String.isEmpty(formattedFieldValue)){
                formattedFieldValue = formattedFieldValue.replace('T', ' ');
                formattedFieldValue = formattedFieldValue.substringBeforeLast('.');
                parsedFieldValue = Datetime.valueOf(formattedFieldValue).format();
            }
        }
        else if(fieldType == Schema.DisplayType.EMAIL) {
            parsedFieldValue = (String) fieldValue;
        }
        else if(fieldType == Schema.DisplayType.PICKLIST) {
            parsedFieldValue = (String) fieldValue;
        }
        else if (fieldType == Schema.DisplayType.BOOLEAN) {
            String formattedFieldValue = string.valueOf(fieldValue);
            parsedFieldValue = formattedFieldValue;
        }
        else if (fieldType == Schema.DisplayType.DOUBLE) {
            String formattedFieldValue = string.valueOf(fieldValue);
            parsedFieldValue = formattedFieldValue;
        }
        else if (fieldType == Schema.DisplayType.PHONE) {
            parsedFieldValue = (String) fieldValue;
        }
        else if (fieldType == Schema.DisplayType.TEXTAREA) {
            parsedFieldValue = (String) fieldValue;
        }
        else {
            parsedFieldValue = (String) fieldValue;
        }
        return parsedFieldValue;
    }

    /********************************************************************************
   Class Name           : FieldSetNullException
   Description          : Hold the exception object if fieldset is null
   *********************************************************************************/
    public inherited sharing class FieldSetNullException extends Exception{
        public String errorMessage;
        public String errorCode;

        public FieldSetNullException(String message, String errCode){
            this.errorMessage=message;
            this.errorCode=errCode;
        }
    }
}