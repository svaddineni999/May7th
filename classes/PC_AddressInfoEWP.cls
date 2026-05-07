/*********************************************************************************
Class Name      : PC_AddressInfoEWP
Description     : Gets Address records and Fields to Populate Address Info Page
Created By      : Kishore Kanteti
Created Date    : 22-Nov-21
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Kishore Kanteti 	       22-Nov-21              Initial Version
*********************************************************************************/
public with sharing class PC_AddressInfoEWP {

    @AuraEnabled
    public static AddressDetails getAddressFieldsAndRecords(Map<String,String> enrollDetails){
        AddressDetails addressDetails = new AddressDetails();
        try{
            //validating fieldset on address object
            String displayFieldSetName = '';
            displayFieldSetName = enrollDetails.get('displayFieldSetName');
            Boolean validFieldSet = PC_Utility.isValidFieldSet(PC_Constants.ADDRESS_OBJ_API, displayFieldSetName);
            if(!validFieldSet){
                throw new AuraHandledException(System.Label.PC_Enrollment_Fieldset_Error);
            }

            //Getting address fields from fieldset
            List<Map<String,Object>> patientAddresses = new List<Map<String,Object>>();
            List<AddressFieldDetail> addressFields = new List<AddressFieldDetail>();
            addressFields = getAddressFieldsByFieldSet(displayFieldSetName);
            if(addressFields == null){
                List<Object> formattingArguments = new List<Object>{
                        displayFieldSetName, PC_Constants.ADDRESS_OBJ_API
                };
                throw new AuraHandledException(String.format(System.Label.PC_NoFieldsInFieldsetError, formattingArguments));
            }
            addressDetails.addressFields = addressFields;

            //Getting saved/existing addresses
            String patientId = enrollDetails.get('patientId');
            if(String.isBlank(patientId)){
                String activeApplicantId = enrollDetails.get('activeApplicantId');
                patientAddresses = getApplicantAddresses(activeApplicantId,addressFields);
            }else{
                patientAddresses = getAccountAddresses(patientId,addressFields);
            }
            addressDetails.patientAddresses = patientAddresses;

        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return addressDetails;
    }

    private static Map<String,List<String>> getAddressApplicantFieldsMap(){
        String mappingJSON = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ADDRESS_APPLICANT_MAPPING,'');
        Map<String, List<String>> applicantFieldsByAddressField = new Map<String, List<String>>();
        if(String.isNotBlank(mappingJSON)){
            applicantFieldsByAddressField = (Map<String, List<String>>) JSON.deserialize(mappingJSON, Map<String, List<String>>.class);
        }
        Map<String, List<String>> defaultApplicantFieldsByAddressField = new Map<String, List<String>>();
        defaultApplicantFieldsByAddressField = getDefaultApplicantAddressFieldsMapping();
        for(String addressField : defaultApplicantFieldsByAddressField.keySet()){
            if(!applicantFieldsByAddressField.containsKey(addressField)){
                applicantFieldsByAddressField.put(addressField,defaultApplicantFieldsByAddressField.get(addressField));
            }
        }
        return applicantFieldsByAddressField;
    }
    private static Map<String, List<String>> getDefaultApplicantAddressFieldsMapping(){
        Map<String, List<String>> defaultMapping = new Map<String, List<String>>();
        defaultMapping.put(PC_Constants.getQualifiedAPIName('PC_Address_1__c'), new List<String>{PC_Constants.getQualifiedAPIName('PC_Address_1__c'),PC_Constants.getQualifiedAPIName('PC_Address1_1__c')});
        defaultMapping.put(PC_Constants.getQualifiedAPIName('PC_Address_2__c'), new List<String>{PC_Constants.getQualifiedAPIName('PC_Address_2__c'),PC_Constants.getQualifiedAPIName('PC_Address1_2__c')});
        defaultMapping.put(PC_Constants.getQualifiedAPIName('PC_Address_Description__c'), new List<String>{PC_Constants.getQualifiedAPIName('PC_Address_Description__c'),PC_Constants.getQualifiedAPIName('PC_Address1_Description__c')});
        defaultMapping.put(PC_Constants.getQualifiedAPIName('PC_City__c'), new List<String>{PC_Constants.getQualifiedAPIName('PC_City__c'),PC_Constants.getQualifiedAPIName('PC_City1__c')});
        defaultMapping.put(PC_Constants.getQualifiedAPIName('PC_Country__c'), new List<String>{PC_Constants.getQualifiedAPIName('PC_Country__c'),PC_Constants.getQualifiedAPIName('PC_Country1__c')});
        defaultMapping.put(PC_Constants.getQualifiedAPIName('PC_State__c'), new List<String>{PC_Constants.getQualifiedAPIName('PC_State__c'),PC_Constants.getQualifiedAPIName('PC_State1__c')});
        defaultMapping.put(PC_Constants.getQualifiedAPIName('PC_Zip_Code__c'), new List<String>{PC_Constants.getQualifiedAPIName('PC_Zip_Code__c'),PC_Constants.getQualifiedAPIName('PC_Zip_Code1__c')});
        defaultMapping.put(PC_Constants.getQualifiedAPIName('PC_Primary_Address__c'), new List<String>{PC_Constants.getQualifiedAPIName('PC_Primary_Address__c'),PC_Constants.getQualifiedAPIName('PC_Primary_Address1__c')});
        return defaultMapping;
    }
    private static List<AddressFieldDetail> getAddressFieldsByFieldSet(String fieldSetName){
        List<AddressFieldDetail> addressFields = new List<AddressFieldDetail>();
        for(PC_FieldSetController.FieldSetMember fieldSetMember : PC_FieldSetController.getFields(PC_Constants.ADDRESS_OBJ_API,fieldSetName)){
            AddressFieldDetail eachField = new AddressFieldDetail(fieldSetMember);
            addressFields.add(eachField);
        }
        return addressFields;
    }
    private static List<Map<String,Object>> getApplicantAddresses(String activeApplicantId,List<AddressFieldDetail> addressFieldsByFieldSet){
        List<Map<String,Object>> savedAddresses = new List<Map<String,Object>>();
        if(addressFieldsByFieldSet != null && !addressFieldsByFieldSet.isEmpty()){

            //get address applicant fields map
            Map<String,List<String>> addressApplicantFieldsMap = getAddressApplicantFieldsMap();
            //prepare SOQL query based on fieldAPIs
            String query = 'SELECT ';

            for(AddressFieldDetail addressField : addressFieldsByFieldSet){
                if(addressApplicantFieldsMap.get(addressField.fieldName) != null){
                    for(String applicantAddressField : addressApplicantFieldsMap.get(addressField.fieldName)){
                        query += applicantAddressField + ', ';
                    }
                }else{
                    List<Object> formattingArguments = new List<Object>{
                            addressField.fieldName
                    };
                    throw new AuraHandledException(String.format(System.Label.PC_IncorrectAddressApplicantMapping,formattingArguments));
                }
            }
            query += 'Id, RecordType.Name, LastModifiedDate FROM ' + PC_Constants.getQualifiedAPIName('PC_Applicant__c') +
                    ' WHERE Id' + '=' + '\'' + activeApplicantId + '\'' + ' Limit 1';

            PC_Applicant__c applicant = new PC_Applicant__c();
            //execute query and get applicant
            applicant = Database.query(query);
            //Forming address records based on applicant info and address applicant mapping
            Integer i = 0;
            while(i < addressApplicantFieldsMap.get(addressFieldsByFieldSet[0].fieldName).size()){
                Map<String,Object> address = new Map<String,Object>();
                for(AddressFieldDetail addressField : addressFieldsByFieldSet){
                    if(addressApplicantFieldsMap.get(addressField.fieldName) != null){
                        if(applicant.get(addressApplicantFieldsMap.get(addressField.fieldName)[i]) != null){
                            address.put(addressField.fieldName, applicant.get(addressApplicantFieldsMap.get(addressField.fieldName)[i]));
                        }
                    }else{
                        List<Object> formattingArguments = new List<Object>{
                                addressField.fieldName
                        };
                        throw new AuraHandledException(String.format(System.Label.PC_IncorrectAddressApplicantMapping,formattingArguments));
                    }
                }
                if(address.get(PC_Constants.getQualifiedAPIName('PC_Address_1__c')) != null){
                    address.put('LastModifiedDate', String.valueOf(applicant.LastModifiedDate));
                    address.put('Source', applicant.RecordType.Name);
                    address.put('Name', PC_Constants.NA);
                    address.put('AddressId', applicant.Id + String.valueOf(i));
                    savedAddresses.add(address);
                }
                i++;
            }
        }
        return savedAddresses;
    }
    private static List<Map<String,Object>> getAccountAddresses(String patientId,List<AddressFieldDetail> addressFieldsByFieldSet){
        List<Map<String,Object>> existingAddresses = new List<Map<String,Object>>();

        //FLS Check on Address Object
        List<String> fields = new List<String>();
        for(AddressFieldDetail addressField : addressFieldsByFieldSet){
            fields.add(addressField.fieldName);
        }
        PC_Database.assertAccess(PC_Constants.ADDRESS_OBJ_API,PC_Database.Operation.Reading, fields);

        //Get multiple addresses from existing account
        List<PC_Address__c> accountAddresses = new List<PC_Address__c>();
        accountAddresses = [SELECT Id,PC_Account__c,Name,PC_Address_1__c,PC_Address_2__c,PC_Address_3__c,PC_Address_Description__c,
                PC_City__c, PC_Country__c,PC_State__c, PC_Status__c,PC_Zip_Code__c,PC_Primary_Address__c,LastModifiedDate
                FROM PC_Address__c WHERE PC_Account__c =: patientId];
        for(PC_Address__c address : accountAddresses){
            Map<String, Object> addressFieldsToValue = new Map<String, Object>();
            addressFieldsToValue = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(address));
            addressFieldsToValue.remove('attributes');
            addressFieldsToValue.put('LastModifiedDate', String.valueOf(address.LastModifiedDate));
            addressFieldsToValue.put('AddressId', address.Id);
            existingAddresses.add(addressFieldsToValue);
        }
        return existingAddresses;
    }

    public inherited sharing class AddressDetails{
        @AuraEnabled public List<AddressFieldDetail> addressFields{get;set;}
        @AuraEnabled public List<Map<String,Object>> patientAddresses{get;set;}
        @AuraEnabled public String objectName{get;set;}
        public AddressDetails(){
            objectName = PC_Constants.ADDRESS_OBJ_API;
        }
    }
    public inherited sharing class AddressFieldDetail{
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public String fieldName{get;set;}
        @AuraEnabled public String type{get;set;}
        public AddressFieldDetail(PC_FieldSetController.FieldSetMember fieldDetail){
            label = fieldDetail.label;
            fieldName = fieldDetail.fieldPath;
            type = fieldDetail.type;
        }
    }
}