/*********************************************************************************
Class Name      : PC_PatientInfoEWP2
Description     : Gets Account or Applicant for Patient Info Page
Created By      : Kishore Kanteti
Created Date    : 27-Oct-2021
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Kishore Kanteti	          27-Oct-21              Initial Version
*********************************************************************************/
public with sharing class PC_PatientInfoEWP2 {
    private static Map<String,Object> convertApplicantIntoAccountMap(PC_Applicant__c applicant, Map<String,Object> accountOrApplicant){
        accountOrApplicant = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(applicant));
        Map<String,String> defaultAccountApplicantMapping = new Map<String, String>();
        Map<String,String> applicantFieldByAccountFields = new Map<String, String>();
        defaultAccountApplicantMapping = getDefaultAccountApplicantMapping();
        String mappingJSON = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ACCOUNT_APPLICANT_MAPPING,'');
        if(String.isNotBlank(mappingJSON)){
            applicantFieldByAccountFields = (Map<String, String>) JSON.deserialize(mappingJSON, Map<String, String>.class);
            for(String accountField : defaultAccountApplicantMapping.keySet()){
                if(!applicantFieldByAccountFields.containsKey(accountField)){
                    applicantFieldByAccountFields.put(accountField,defaultAccountApplicantMapping.get(accountField));
                }
            }
        }else{
            applicantFieldByAccountFields = defaultAccountApplicantMapping;
        }
        for(String accountField : applicantFieldByAccountFields.keySet()){
            if(String.isNotBlank(applicantFieldByAccountFields.get(accountField)) && applicantFieldByAccountFields.get(accountField) != 'NA') {
                accountOrApplicant.put(accountField, accountOrApplicant.get(applicantFieldByAccountFields.get(accountField)));
            }
        }
        accountOrApplicant.put('LastModifiedDate',String.valueOf(applicant.LastModifiedDate));
        accountOrApplicant.remove('attributes');
        return accountOrApplicant;
    }
    private static Map<String,String> getDefaultAccountApplicantMapping(){
        Map<String,String> defaultMap = new Map<String, String>();
        defaultMap.put('Phone',PC_Constants.getQualifiedAPIName('PC_Phone__c'));
        defaultMap.put('Fax','NA');
        defaultMap.put(PC_Constants.getQualifiedAPIName('PC_Email__c'),PC_Constants.getQualifiedAPIName('PC_Patient_Email__c'));
        defaultMap.put(PC_Constants.getQualifiedAPIName('PC_Communication_Language__c'),PC_Constants.getQualifiedAPIName('PC_Communication__c'));
        defaultMap.put(PC_Constants.getQualifiedAPIName('PC_Preferred__c'),PC_Constants.getQualifiedAPIName('PC_Preferred_Channel__c'));
        defaultMap.put(PC_Constants.getQualifiedAPIName('PC_Primary_Address_1__c'),PC_Constants.getQualifiedAPIName('PC_Address_1__c'));
        defaultMap.put(PC_Constants.getQualifiedAPIName('PC_Primary_City__c'),PC_Constants.getQualifiedAPIName('PC_City__c'));
        defaultMap.put(PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'),PC_Constants.getQualifiedAPIName('PC_Zip_Code__c'));
        defaultMap.put(PC_Constants.getQualifiedAPIName('PC_Primary_State__c'),PC_Constants.getQualifiedAPIName('PC_State__c'));
        return defaultMap;
    }
    @AuraEnabled
    public static Map<String,Object> getAccountOrApplicant(Map<String,String> enrollDetails){
        Map<String,Object> accountOrApplicant = new Map<String, Object>();
        try {
            Id patientId = (Id) enrollDetails.get('patientId');
            List<String> fieldSetNames = new List<String>();
            fieldSetNames = enrollDetails.get('fieldSetNames').split(',');
            if (patientId == null) {
                PC_Applicant__c applicant =  getApplicant (enrollDetails);
                if(applicant != null){
                    accountOrApplicant = convertApplicantIntoAccountMap(applicant,accountOrApplicant);
                }
            } else {
                accountOrApplicant =  getAccount(patientId, fieldSetNames);
            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return accountOrApplicant;
    }
    private static PC_Applicant__c getApplicant(Map<String,String> enrollDetails) {
        Id patientId = (Id) enrollDetails.get('patientId');
        Id enrollmentId = (Id) enrollDetails.get('enrollmentId');
        Id activeApplicantId = (Id) enrollDetails.get('activeApplicantId');
        List<String> fieldSetNames = new List<String>();
        fieldSetNames = enrollDetails.get('fieldSetNames').split(',');

        List<PC_Applicant__c> applicants = new List<PC_Applicant__c>();
        Map<String, Object> applicantFieldsToValue = new Map<String, Object>();
        try {

            List<String> fields = new List<String>();
            /*
             * Logic for FieldSet; Get the FieldSet fields
             */

            if (fieldSetNames != null && !fieldSetNames.isEmpty()){
                for(String fieldSetName : fieldSetNames){
                    List<String> fsList = new List<String>();
                    fsList = PC_FieldSetController.getFieldsByName(PC_Constants.PC_ACCOUNT, fieldSetName);
                    if(fsList != null && !fsList.isEmpty()){
                        fields.addAll(fsList);
                    }
                }
            }

            Set<String> fieldsAsSet = new Set<String>();
            fieldsAsSet.addAll(fields);

            //Remove Account Fields and Add Applicant Fields
            Map<String,String> defaultAccountApplicantMapping = new Map<String, String>();
            Map<String,String> accountApplicantFields = new Map<String, String>();
            defaultAccountApplicantMapping = getDefaultAccountApplicantMapping();
            String mappingJSON = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_ACCOUNT_APPLICANT_MAPPING,'');
            if(String.isNotBlank(mappingJSON)){
                accountApplicantFields = (Map<String, String>) JSON.deserialize(mappingJSON, Map<String, String>.class);
                for(String accountField : defaultAccountApplicantMapping.keySet()){
                    if(!accountApplicantFields.containsKey(accountField)){
                        accountApplicantFields.put(accountField,defaultAccountApplicantMapping.get(accountField));
                    }
                }
            }else{
                accountApplicantFields = defaultAccountApplicantMapping;
            }
            fieldsAsSet.removeAll(accountApplicantFields.keySet());
            fieldsAsSet.addAll(accountApplicantFields.values());
            fieldsAsSet.add('LastModifiedDate');
            fieldsAsSet.remove('NA');
            fieldsAsSet.remove(null);


            List<String> fieldsWithoutDuplicates = new List<String>();
            fieldsWithoutDuplicates.addAll(fieldsAsSet);

            //FLS Check
            PC_Database.assertAccess(PC_Constants.CANDIDATE_PATIENT_OBJECT,PC_Database.Operation.Reading, fieldsWithoutDuplicates);

            String query = PC_Constants.EMPTY_STRING + String.join(fieldsWithoutDuplicates, ', ');
            query = 'SELECT ' + query + ' ' + 'FROM ' + ' PC_Applicant__c' +
                    ' WHERE Id' + '=' + '\'' + activeApplicantId + '\'' + ' Limit 1';
            try{
                applicants = PC_Database.queryWithAccess(query, fieldsWithoutDuplicates);
            }catch(Exception ex){
                String errorMessage = ex.getMessage();
                ex.setMessage(System.Label.PC_EWP_ApplicantMappingError +errorMessage);
                PC_Utility.logAndThrowException(ex);
            }
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        if(applicants != null && !applicants.isEmpty()){
            return applicants[0];
        }else{
            return null;
        }
    }
    public static Map<String, Object> getAccount(Id patientId, List<String> fieldSetNames) {
        List<Account> accounts = new List<Account>();
        Map<String, Object> accountFieldsToValue = new Map<String, Object>();
        try {
            List<String> fields = new List<String>();

            /*
             * Logic for FieldSet - Get the FieldSet fields
             */

            if(fieldSetNames != null && !fieldSetNames.isEmpty()){
                for(String fieldSetName : fieldSetNames){
                    List<String> fsList = new List<String>();
                    fsList = PC_FieldSetController.getFieldsByName(PC_Constants.PC_ACCOUNT,fieldSetName);
                    if(fsList != null && !fsList.isEmpty()) {
                        fields.addAll(fsList);
                    }
                }
            }

            Set<String> fieldsAsSet = new Set<String>();
            List<String> fieldsWithoutDuplicates = new List<String>();
            fieldsAsSet.addAll(fields);
            fieldsAsSet.add('LastModifiedDate');
            fieldsWithoutDuplicates.addAll(fieldsAsSet);

            //FLS Check
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fieldsWithoutDuplicates);

            String query = PC_Constants.EMPTY_STRING + String.join(fieldsWithoutDuplicates, ', ');
            query = 'SELECT ' + query + ' ' + 'FROM ' + ' Account WHERE Id = \'' + patientId + '\' Limit 1';

            accounts = PC_Database.queryWithAccess(query, fieldsWithoutDuplicates);
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        if(accounts != null && !accounts.isEmpty()){
            accountFieldsToValue = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(accounts[0]));
            accountFieldsToValue.remove('attributes');
            accountFieldsToValue.put('LastModifiedDate', String.valueOf(accounts[0].LastModifiedDate));
            return accountFieldsToValue;
        }else{
            return null;
        }
    }
}