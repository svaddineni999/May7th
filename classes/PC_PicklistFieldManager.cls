/*********************************************************************************************************
Class Name      : PC_PicklistFieldManager
Description     : Manage dependend picklist values
Created By      : Roxana Ivan
Created Date    : May 31, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------            
Roxana Ivan                 May 31, 2016           Initial Version
Mike Klumpenaar             Jul 12, 2017           PC-1885 Aura enabled PicklistEntryWrapper and added picklist helper
                                                   methods for dependent and fields to return picklist entry wrapper
                                                   objects needed for supporting translated picklists.
Mayuresh Patil      		Jul 12, 2017           PC-1885 updated code to fetch picklist value, label pair
Mike Klumpenaar             2017-08-10             [PC-2007] Replace bit checking with new implementation found on
                                                   stackexchange: https://salesforce.stackexchange.com/questions/4462/get-lists-of-dependent-picklist-options-in-apex/4876
Vijay Kashikar              2019-03-26             [PC-4666] Updated logic to return picklist values along with their API names
Vijay Kashikar              2019-11-19             [PC-5735] Controlling field value is now considered while returning valid picklist values.
                                                   (Introduced overloaded method picklistFieldMap)
Haritha Reddy             21-Jan-2021                 [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
****************************************************************************************************************/
public with sharing class PC_PicklistFieldManager {
    // Given two SObjectField of type PickList, return the value to picklist entry list mapping
    public static Map<String, List<PicklistEntryWrapper>> picklistFieldMap(SObjectField contollingField, SObjectField dependentField) {
        Map<String, List<PicklistEntryWrapper>> objResults = new Map<String, List<PicklistEntryWrapper>>();
        //get the control values
        List<Schema.PicklistEntry> controllingEntries = contollingField.getDescribe().getPicklistValues();
        //get the dependent values
        List<Schema.PicklistEntry> dependentEntries = dependentField.getDescribe().getPicklistValues();

        //set up the results
        for (Schema.PicklistEntry controllingEntry : controllingEntries) {
            //create the entry with the value
            objResults.put(controllingEntry.getValue(), new List<PicklistEntryWrapper>());
        }

        BitsetChecker bitsetChecker = new BitsetChecker();

        //check the dependent values
        for (Schema.PicklistEntry dependantEntry : dependentEntries) {
            //get the valid for
            String entryStructure = JSON.serialize(dependantEntry);
            PicklistEntryWrapper dependentEntryWrapper = (PicklistEntryWrapper) JSON.deserialize(entryStructure, PicklistEntryWrapper.class);
            //if valid for is empty, skip
            if (dependentEntryWrapper.validFor == null || dependentEntryWrapper.validFor == '') {
                continue;
            }
            //iterate through the controlling values
            for (Integer controllingIndex = 0; controllingIndex < controllingEntries.size(); controllingIndex++) {
                bitsetChecker.setValidFor(dependentEntryWrapper.validFor);
                if (bitsetChecker.testBit(controllingIndex)) {
                    //get the label
                    String controllingValue = controllingEntries[controllingIndex].getValue();
                    objResults.get(controllingValue).add(dependentEntryWrapper);
                }
            }
        }

        return objResults;
    }

    // Given two SObjectField of type PickList, return the value to picklist entry list mapping
    public static Map<String, List<PicklistEntryWrapper>> picklistFieldMap(SObjectField controllingField, SObjectField dependentField, String controllingFieldValue) {
        Map<String, List<PicklistEntryWrapper>> objResults = new Map<String, List<PicklistEntryWrapper>>();
        //get the control values
        List<Schema.PicklistEntry> controllingEntries = controllingField.getDescribe().getPicklistValues();
        //get the dependent values
        List<Schema.PicklistEntry> dependentEntries = dependentField.getDescribe().getPicklistValues();

        //set up the results

        for (Schema.PicklistEntry controllingEntry : controllingEntries) {
            //create the entry with the value
            objResults.put(controllingEntry.getValue(), new List<PicklistEntryWrapper>());
        }


        BitsetChecker bitsetChecker = new BitsetChecker();

        //check the dependent values
        for (Schema.PicklistEntry dependantEntry : dependentEntries) {
            //get the valid for
            String entryStructure = JSON.serialize(dependantEntry);
            PicklistEntryWrapper dependentEntryWrapper = (PicklistEntryWrapper) JSON.deserialize(entryStructure, PicklistEntryWrapper.class);
            //if valid for is empty, skip
            if (dependentEntryWrapper.validFor == null || dependentEntryWrapper.validFor == '') {
                continue;
            }
            //iterate through the controlling values
            for (Integer controllingIndex = 0; controllingIndex < controllingEntries.size(); controllingIndex++) {
                bitsetChecker.setValidFor(dependentEntryWrapper.validFor);
                if (bitsetChecker.testBit(controllingIndex)) {
                    //get the label
                    String controllingValue = controllingEntries[controllingIndex].getValue();
                    if(String.isNotBlank(controllingFieldValue) && controllingFieldValue.equalsIgnoreCase(controllingValue)) {
                        objResults.get(controllingValue).add(dependentEntryWrapper);
                    }
                }
            }
        }

        return objResults;
    }

    /*********************************************************************************
    Method Name    : picklistRecordTypeFieldList
    Author         : Vivek Kumar Mishra
    Description    : Method which returns list of respective picklist values based on
                     Record Type and Controlling Field
    Return Type    : List<String>
    Parameter      : SObjectField controllingField, SObjectField dependentField,
                     String sobjectType, Id recordTypeId, String ctrRecord
    *********************************************************************************/
    public static Map<String, String> picklistRecordTypeFieldList(SObjectField controllingField,
            SObjectField dependentField, String sobjectType, Id recordTypeId, String ctrRecord) {
        Map<String, List<PicklistEntryWrapper>> dependentMap = picklistFieldMap(controllingField, dependentField, ctrRecord);
        List<String> dependentList = new List<String> ();
        Map<String, String> map_dependentList = new Map<String, String> ();
        if(dependentMap.get(ctrRecord) == null){
            return null;
        }
        for (PicklistEntryWrapper subtype : dependentMap.get(ctrRecord)) {
            dependentList.add(subtype.label);
            map_dependentList.put(subtype.value, subtype.label);
        }
        Map<String, String> recordTypeMap = PC_PicklistDescriber.describeAsMap
                (sobjectType, recordTypeId, dependentField.getDescribe().name, controllingField.getDescribe().name);
        Map<String, String> dependentCommonValues = new Map<String, String>();
        for(String key : recordTypeMap.keySet()){
            if(map_dependentList.containsKey(key)){
                dependentCommonValues.put(key, recordTypeMap.get(key));
            }
        }
        return dependentCommonValues;
    }

    // Returns a list of PicklistEntryWrappers for the given field
    public static List<PicklistEntryWrapper> getPicklistEntryWrappers(Schema.SObjectField field) {
        return getPicklistEntryWrappersFordescFields(field.getDescribe());
    }

    // Returns a list of PicklistEntryWrappers for the given describe results of field
    public static List<PicklistEntryWrapper> getPicklistEntryWrappersFordescFields(Schema.DescribeFieldResult descField) {
        List<PicklistEntryWrapper> picklistEntryWrappers  = new List<PicklistEntryWrapper>();
        for (Schema.PicklistEntry picklistEntry : descField.getPicklistValues()) {
            picklistEntryWrappers.add(new PicklistEntryWrapper(picklistEntry.getValue(), picklistEntry.getLabel()));
        }

        return picklistEntryWrappers;
    }

    public static Decimal hexToDecimal(String sourceHex) {
        String hex = '0123456789abcdef';
        String[] hexValue = sourceHex.split('');
        Decimal result = 0;
        for(Integer index = 0; index < hexValue.size(); index++) {
            result = (result * 16) + hex.indexOf(hexValue[index]);
        }

        return result;
    }

    /*********************************************************************************
    Method Name      : getPicklistLabelValue
    Description     : Return a Map of Value and Label for the picklist field
    Created By      : Tejas Patel
    Created Date    : July 30, 2020
    Modification Log:
    ----------------------------------------------------------------------------------
    Developer                   Date                   Description
    -----------------------------------------------------------------------------------
    Tejas Patel               July 30, 2020              Initial Version
    *********************************************************************************/
    public static Map<String,String> getPicklistLabelValue(Schema.DescribeFieldResult descField) {
        Map<String,String> picklistMap  = new Map<String,String>();

        for (Schema.PicklistEntry picklistEntry : descField.getPicklistValues()) {
            picklistMap.put(picklistEntry.getValue(),picklistEntry.getLabel());
        }

        return picklistMap;
    }

    /*********************************************************************************
    Class Name      : PicklistEntryWrapper
    Description     : Wrapper used for storing picklist results
    Created By      : Roxana Ivan
    Created Date    : May 31, 2016
    Modification Log:
    ----------------------------------------------------------------------------------
    Developer                   Date                   Description
    -----------------------------------------------------------------------------------
    Roxana Ivan               May 31, 2016              Initial Version
    *********************************************************************************/
    public inherited sharing class PicklistEntryWrapper {
        public PicklistEntryWrapper(String value, String label) {
            this.value = value;
            this.label = label;
        }

        // Somehow gets populated when deserializing a serialized Schema.PicklistEntry.
        public String validFor { get;set; }

        @AuraEnabled
        public String label { get;set; }
        @AuraEnabled
        public String value { get;set; }
    }

    public inherited sharing class BitsetChecker {
        String validFor {get;private set;}
        String vfDecoded {get;private set;}
        String[] hexBytes {get;private set;}
        Integer[] bytes {get;private set;}

        public void setValidFor(String validFor) {
            this.validFor = validFor;
            this.vfDecoded = null;
            hexBytes = new String[] {};
            bytes = new Integer[] {};
            if (String.isNotBlank(validFor)) {
                this.vfDecoded = String.isNotBlank(validFor) ?
                        EncodingUtil.convertToHex(EncodingUtil.base64Decode(validFor)).toLowerCase() : '';
                if (String.isNotBlank(vfDecoded) && Math.mod(vfDecoded.length(), 2) == 0) {
                    for (Integer i = 0; i < vfDecoded.length(); i += 2) {
                        String hexByte = vfDecoded.substring(i, i + 2);
                        hexBytes.add(hexByte);
                        bytes.add(hexToDecimal(hexByte).intValue());
                    }
                }
            }
        }

        public Boolean testBit(Integer n) {
            Boolean result = false;
            if (n != null && n < size() && hexBytes != null) {
                Integer bytesPos = n >> 3;
                Integer targetByte = bytesPos < bytes.size() ? bytes[bytesPos] : null;
                if (targetByte != null) {
                    Integer mask = 128 >> Math.mod(n, 8);
                    Integer maskedByte = targetByte & mask;
                    result = maskedByte != 0;
                }
            }
            return result;
        }

        public Integer size() {
            return bytes.size() * 8;
        }
    }
}