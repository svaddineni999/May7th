/*********************************************************************************
Class Name      : PC_PatientInfoEWP2Processor
Description     : Creates Account, Program Case and Links Manufacturer to Account
Created By      : Kishore Kanteti
Created Date    : 25-Oct-2021
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Kishore Kanteti 	       25-Oct-21              Initial Version
*********************************************************************************/
global virtual with sharing class PC_PatientInfoEWP2Processor implements PC_EnrollmentWizard.PageProcessor {
    private static String masterPatient = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_MASTER_PATIENT,'false').toLowerCase();

    global virtual void processEnrollment(Case enrollmentCase, Map<String, Object> pageState){
        createPatientAccount(enrollmentCase, pageState);
        createProgramCase(enrollmentCase);
    }

    public static void createPatientAccount(Case enrollmentCase, Map<String, Object> pageState){
        if (pageState == null) {
            throw new PC_EnrollmentWizard.PageProcessorException('Missing Page State');
        }
        if (pageState.get('persistentAccount') == null) {
            throw new PC_EnrollmentWizard.PageProcessorException('Missing Account Information');
        }
        Object persistentAccount = (Object) pageState.get('persistentAccount');
        Map<String, Object> patientInfoAccount = (Map<String, Object>) persistentAccount;
        Account acc = new Account();

        //Creating Patient Account
        Object castValue;
        if(patientInfoAccount != null) {
            patientInfoAccount.remove('LastModifiedDate');
            for(String fieldName : patientInfoAccount.keySet()){
                castValue = PC_FieldSetController.castFieldValueBasedOnType(fieldName, patientInfoAccount.get(fieldName), acc);
                acc.put(fieldName, castValue);
            }
        }

        if (enrollmentCase.AccountId != null) {
            acc.put('Id', enrollmentCase.AccountId);
        }
        //Update the RecordType to Patient Record Type
        acc.put('RecordTypeId', PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT , PC_Constants.PATIENT_RECORD_TYPE));

        if(PC_SYSTEM.isPersonAccountEnabled()) {
            if(masterPatient == 'false'){
                acc.put('PC_ParentManufacturer__c',enrollmentCase.PC_Engagement_Program__r.PC_Manufacturer__c);
            }
        } else {
            acc.put('Name',(String) (patientInfoAccount.get(PC_Constants.getQualifiedAPIName('PC_Last_Name__c'))) + ' , ' + (String) (patientInfoAccount.get(PC_Constants.getQualifiedAPIName('PC_First_Name__c'))));
            if(masterPatient == 'false'){
                acc.put('ParentId', enrollmentCase.PC_Engagement_Program__r.PC_Manufacturer__c);
            }
        }

        if(acc != null){
            PC_Database.ups(acc);//FLS/CRUD Check enforced in the PC_database method
            PC_EnrollmentWizard.addToRecordsCreated(acc);
            enrollmentCase.AccountId = acc.Id;
        }
    }

    public static void createProgramCase(Case enrollmentCase){
        //Create a new Program Case with patient information
        Case prgCase = new Case();
        prgCase.Status = PC_Constants.STATUS_ENROLLED;
        prgCase.AccountId = enrollmentCase.AccountId;
        prgCase.PC_Engagement_Program__c = enrollmentCase.PC_Engagement_Program__c;
        prgCase.Type = PC_Constants.CASE_PROGRAM_TYPE;

        /*Fetch the case record type id using the values for Program Case Record Type Name and Program Case Record Type Namespace fields from Engagement Program record.
        If the engagement program has no values defined for the former fields then we would consider
        Patient Connect's case record type developer name and namespace to fetch the record type id*/
        Id programCaseRecordTypeId = null;
        programCaseRecordTypeId = PC_SYSTEM.getProgramRecordTypeIdBasedOnEngProgramId(prgCase.PC_Engagement_Program__c);

        if(programCaseRecordTypeId!=null){
            prgCase.RecordTypeId=programCaseRecordTypeId;
        }else{
            prgCase.RecordTypeId = PC_SYSTEM.getDefaultProgramCaseRecordTypeId();
        }

        /* PC-6067: End*/
        prgCase.PC_Enrollment_Date__c = date.today();
        //[PC-1544] Rolled back PC-1467 that populated case orgin on program case with case origin field from related enrollment case
        if(prgCase != null){
            PC_EnrollmentWizard.addToRecordsCreated(prgCase);
            PC_Database.ins(prgCase);//FLS/CRUD Check enforced in the PC_database method
            //Link the newly created program to the Enrollment Case
            enrollmentCase.PC_Program__c = prgCase.Id;
        }
        PC_EnrollmentWizard.addToRecordsCreated(enrollmentCase);
    }
}