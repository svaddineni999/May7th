/*********************************************************************************
Class Name      : PC_PatientInfoEWPProcessor
Description     : Creates Account, Address, Program Case and Links Manufacturer to Account
Created By      : Tejas Patel
Created Date    : 4-Jan-2017
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Tejas Patel			        4-Jan-17              Initial Version
Prachi Nandgaonkar          6 Mar 17              [PC-1254] Refactored code for SQOL optimization. Moved PC_Manufacturer__c field to EnrollmentWizardLightningController 
Prachi Nandgaonkar          20 Mar 17             [PC-1327] Auto-populated Enrollment Date on Case with enrollment completion date 
Vijay Kashikar		        12 Apr 17             [PC-1436] Added condition to avoid calling PC_Database.ups() when the object is null/empty. 
Prachi Nandgaonkar          28 Apr 17             [PC-1467] Populate case orgin on program case with case origin field from related enrollment case
Prachi Nandgaonkar          16 May 17             [PC-1544] Rollback story PC-1467 populate case orgin on program case with case origin field from related enrollment case
Ajinkya Deshmukh			22 Jun 17			  FLS Check Added (Code Merge)
Tejas Patel                 26 Jun 17             [PC-1772] Default RecordType made as "Patient"
Tejas Patel                 27-Jun-2017           [PC-1774] Remove AccountNumber from FLS as it is not being used in SOQL
Mike Klumpenaar             12-July-2017          [PC-1885] Changed from --Select-- string use PICKLIST_NONE constant
Mayuresh Patil              07-Sep-2017           PC-2193 FLS Check updated to new PC303 code
Kishore Kanteti             11-Jun-2019           [PC-4952] Added person account conditions to associate manufacturer account with Account.
Tushar Arora                18-Jun-2019           [PC-4927] Added person account conditions to create name from person account firstName and LastName fields using UI inputs .
Tushar Arora                30-jul-2019           [PC-5216] Fixed Date of Birth Issue .
Tushar Arora                31-Jul-2019           [PC-5086] Modified Conditions for PersonAccount Enablement.
Tushar Arora                13-Aug-2019                [PC-5308] changed Dynamic field population to standard field population for custom fields and modified hardcorded string fields to PC_Constants .
Vijay Kashikar              26 Jun 20             [PC-6398] Stored the records created in the global queue.
Hitha Avalakki              04-Mar-2021           [PC-6067] Used getProgramRecordTypeIdBasedOnEngProgramId(String engagementProgId) to fetch the case record type configured on engagement progra
Hitha Avalakki              19-Mar-2021           [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
*********************************************************************************/
public with sharing class PC_PatientInfoEWPProcessor implements PC_EnrollmentWizard.PageProcessor {
    private static String FIELDSET_KEY = 'fsFields';
    private static String masterPatient = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_MASTER_PATIENT,'false').toLowerCase();

    public static void processEnrollment(Case enrollmentCase, Map<String, Object> pageState) {

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
        if (enrollmentCase.AccountId != null) {
            acc.Id = enrollmentCase.AccountId;
        }
        //Update the RecordType to Patient Record Type
        acc.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT , PC_Constants.PATIENT_RECORD_TYPE) ;
        acc.PC_First_Name__c = (String) (patientInfoAccount.get('firstName'));
        acc.PC_Last_Name__c = (String) (patientInfoAccount.get('lastName'));
        //Add conditions to check blank values before assigning to picklists
        if ((String) (patientInfoAccount.get('salutation')) != PC_Constants.PICKLIST_NONE) {
            acc.PC_Salutation__c = (String) (patientInfoAccount.get('salutation'));
        }
        acc.Phone = (String) (patientInfoAccount.get('phone'));
        acc.Fax = (String) (patientInfoAccount.get('fax'));
        acc.PC_Email__c = (String) (patientInfoAccount.get('email'));

        if(PC_SYSTEM.isPersonAccountEnabled()) {
            if(masterPatient == 'false'){
                acc.PC_ParentManufacturer__c = enrollmentCase.PC_Engagement_Program__r.PC_Manufacturer__c;
            }
        } else {
            acc.Name = (String) (patientInfoAccount.get('lastName')) + ' , ' + (String) (patientInfoAccount.get('firstName'));
            if(masterPatient == 'false'){
                acc.ParentId = enrollmentCase.PC_Engagement_Program__r.PC_Manufacturer__c;
            }
        }
       
        if ((String) (patientInfoAccount.get('communicationLanguage')) != PC_Constants.PICKLIST_NONE) {
            acc.PC_Communication_Language__c = (String) (patientInfoAccount.get('communicationLanguage'));
        }
        if ((String) (patientInfoAccount.get('preferredCommunicationChannel')) != PC_Constants.PICKLIST_NONE) {
            acc.PC_Preferred__c = (String) (patientInfoAccount.get('preferredCommunicationChannel'));
        }
        if ((String) (patientInfoAccount.get('status')) != PC_Constants.PICKLIST_NONE) {
            acc.PC_Status__c = (String) (patientInfoAccount.get('status'));
        }
        if ((String) (patientInfoAccount.get('caregiverSalutation')) != PC_Constants.PICKLIST_NONE) {
            acc.PC_Caregiver_Salutation__c = (String) (patientInfoAccount.get('caregiverSalutation'));
        }
        if ((String) (patientInfoAccount.get('caregiverRelation')) != PC_Constants.PICKLIST_NONE) {
            acc.PC_Caregiver_Relationship_to_Patient__c = (String) (patientInfoAccount.get('caregiverRelation'));
        }
        acc.PC_Caregiver_First_Name__c = (String) (patientInfoAccount.get('caregiverFirstName'));
        acc.PC_Caregiver_Last_Name__c = (String) (patientInfoAccount.get('caregiverLastName'));
        //Add date with check for null and using date of string
        if (String.isNotBlank((String) patientInfoAccount.get('dob'))) {
            acc.PC_Date_of_Birth__c = Date.valueof(String.valueof((patientInfoAccount.get('dob'))));
        }

        if ((String) (patientInfoAccount.get('gender')) != PC_Constants.PICKLIST_NONE) {
            acc.PC_Gender__c = (String) (patientInfoAccount.get('gender'));
        }

        if (patientInfoAccount.containsKey(FIELDSET_KEY)) {
            Map<String, Object> fieldSetMap = (Map<String, Object>) patientInfoAccount.get(FIELDSET_KEY);
            PC_FieldSetController.copyFieldSetValues(fieldSetMap, acc);
        }
        PC_Database.ups(acc);//FLS/CRUD Check enforced in the PC_database method
        enrollmentCase.AccountId = acc.Id;//Link the account to Enrollment Case

        //Creating Address for patient account
        List<Object> persistentAddress = (List<Object>) pageState.get('persistentAddress');
        String addrID;
        List<PC_Address__c> addresses = new List<PC_Address__c>();
        PC_Address__c addr;
        for (Object o : persistentAddress) {
            addr = new PC_Address__c();
            Map<String, Object> patientInfoAddress = (Map<String, Object>) o;
            addrID = (String) (patientInfoAddress.get('Id'));
            if (!String.isEmpty(addrID)) {
                addr.Id = addrID;
            }
            addr.PC_Account__c = acc.Id;
            addr.PC_Address_1__c = (String) (patientInfoAddress.get('address1'));
            addr.PC_Address_2__c = (String) (patientInfoAddress.get('address2'));
            addr.PC_Address_3__c = (String) (patientInfoAddress.get('address3'));
            //Add conditions to check blank values before assigning to picklists
            if ((String) (patientInfoAddress.get('addressType')) != PC_Constants.PICKLIST_NONE) {
                addr.PC_Address_Description__c = (String) (patientInfoAddress.get('addressType'));
            }
            addr.PC_City__c = (String) (patientInfoAddress.get('city'));
            addr.PC_Country__c = (String) (patientInfoAddress.get('country'));
            addr.PC_State__c = (String) (patientInfoAddress.get('state'));
            //Add conditions to check blank values before assigning to picklists
            if ((String) (patientInfoAddress.get('status')) != PC_Constants.PICKLIST_NONE) {
                addr.PC_Status__c = (String) (patientInfoAddress.get('status'));
            }
            addr.PC_Zip_Code__c = (String) (patientInfoAddress.get('zipCode'));
            addr.PC_Primary_Address__c = ((boolean) (patientInfoAddress.get('primary')));
            addresses.add(addr);
        }
        if(!addresses.isEmpty()) {
        	PC_Database.ups(addresses);//FLS/CRUD Check enforced in the PC_database method
        }

        //Create a new Program Case with patient information 
        Case prgCase = new Case();
        prgCase.Status = PC_Constants.STATUS_ENROLLED;
        prgCase.AccountId = acc.Id;
        prgCase.PC_Engagement_Program__c = enrollmentCase.PC_Engagement_Program__c;
        prgCase.Type = PC_Constants.CASE_PROGRAM_TYPE;

        /* PC-6067: Fetch the case record type id using the values for Program Case Record Type Name and Program Case Record Type Namespace fields from Engagement Program record.
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
        
        PC_Database.ins(prgCase);//FLS/CRUD Check enforced in the PC_database method
        //Link the newly created program to the Enrollment Case
        enrollmentCase.PC_Program__c = prgCase.Id;

        PC_EnrollmentWizard.addToRecordsCreated(acc);
        PC_EnrollmentWizard.addToRecordsCreated((List<SObject>) addresses);
        PC_EnrollmentWizard.addToRecordsCreated(enrollmentCase);
        PC_EnrollmentWizard.addToRecordsCreated(prgCase);
    }       
}