/*********************************************************************************
Class Name      : PC_AddressInfoEWPProcessor
Description     : Creates Address records and Links to Patient Account
Created By      : Kishore Kanteti
Created Date    : 18-Nov-21
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Kishore Kanteti 	       18-Nov-21              Initial Version
*********************************************************************************/
global virtual with sharing class PC_AddressInfoEWPProcessor implements PC_EnrollmentWizard.PageProcessor {
    private static String masterPatient = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_MASTER_PATIENT, 'false').toLowerCase();

    global virtual void processEnrollment(Case enrollmentCase, Map<String, Object> pageState) {
        if (pageState == null){
            throw new PC_EnrollmentWizard.PageProcessorException('Missing Page State in PC_AddressInfoEWPProcessor');
        }
        if (pageState.get('persistentAddress') == null) {
            throw new PC_EnrollmentWizard.PageProcessorException('Missing Address Information in PC_AddressInfoEWPProcessor');
        }

        List<Object> addressObjects = (List<Object>) pageState.get('persistentAddress');
        List<PC_Address__c> patientAddresses = new List<PC_Address__c>();
        List<PC_Address__c> patientAddressesToUpdate = new List<PC_Address__c>();
        List<Map<String,Object>> patientInfoAddresses = new List<Map<String, Object>>();
        for(Object address : addressObjects){
            Map<String, Object> patientInfoAddress = (Map<String, Object>) address;
            patientInfoAddresses.add(patientInfoAddress);
        }
        //Get Account Id
        List<sObject> allRecords = PC_EnrollmentWizard.getRecordsCreated();
        String accountId = '';
        if(allRecords != null && !allRecords.isEmpty()){
            for(sObject eachObject : allRecords){
                if(eachObject.getSObjectType().getDescribe().getName() == PC_Constants.PATIENT_OBJECT){
                    accountId = String.valueOf(eachObject.get('Id'));
                    break;
                }
            }
        }
        if(String.isNotBlank(accountId)){
            for(Map<String,Object> patientInfoAddress : patientInfoAddresses){
                PC_Address__c address = new PC_Address__c();
                address.PC_Account__c = accountId;
                //Creating Patient Address
                if(patientInfoAddress != null){
                    if(patientInfoAddress.containsKey('LastModifiedDate')){
                        patientInfoAddress.remove('LastModifiedDate');
                    }
                    if(patientInfoAddress.containsKey('Source')){
                        patientInfoAddress.remove('Source');
                    }
                    if(patientInfoAddress.containsKey('Name')){
                        patientInfoAddress.remove('Name');
                    }
                    if(patientInfoAddress.containsKey('AddressId')){
                        try {
                            Id addressId = Id.valueOf(String.valueOf(patientInfoAddress.get('AddressId')));
                            String objNm = addressId.getSObjectType().getDescribe().getName();
                            patientInfoAddress.put('Id',patientInfoAddress.get('AddressId'));
                            patientInfoAddress.remove('AddressId');
                        }catch (Exception ex){
                            patientInfoAddress.remove('AddressId');
                        }
                    }
                    Object castValue;
                    for(String fieldName : patientInfoAddress.keySet()){
                        castValue = PC_FieldSetController.castFieldValueBasedOnType(fieldName, patientInfoAddress.get(fieldName), address);
                        address.put(fieldName, castValue);
                    }
                    if(String.isNotBlank(address.Id)){
                        patientAddressesToUpdate.add(address);
                    }
                    patientAddresses.add(address);
                }
            }
            if(patientAddresses != null && !patientAddresses.isEmpty()){
                PC_Database.ups(patientAddresses);
                PC_EnrollmentWizard.addToRecordsCreated((List<SObject>) patientAddresses);
                if(patientAddressesToUpdate != null && !patientAddressesToUpdate.isEmpty()){
                    PC_EnrollmentWizard.addToRecordsToBeUpdated((List<SObject>)patientAddressesToUpdate);
                }
            }
        }else{
            throw new PC_EnrollmentWizard.PageProcessorException('Error in PC_AddressInfoEWPProcessor : Cannot Proceed without an Account Id');
        }
    }
}