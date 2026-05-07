/*********************************************************************************
Class Name      : PC_Enrollment_NewApplicant
Description     : Creates Applicant for Pre-Enrollment process
Created By      : Ajinkya Deshmukh
Created Date    : 4-Jan-2017
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Ajinkya Deshmukh            9-Feb-17              Initial Version
Prachi Nandgaonkar          17-Mar-17             Updated createApplicants() to handle applicants already created by online form [PC-1325]
Prachi Nandgaonkar          17-Apr-17             [PC-1444] Moved updateActiveApplicantonCase() from PC_EnrollmentWizardLightningController that updates active applicant on an enrollment case
Shabda Bhujad				16-May-17			  Added logic to update the subject along with Active Applicant in method updateActiveApplicantOfCase() [PC-1012]
Ajinkya Deshmukh			30-May-17			  Removed code to set Subject on Case from updateActiveApplicantOfCase(). Moved it to PC_Trigger_Case [PC-1628]
Ajinkya Deshmukh			30-May-17			  Removed else block to set case origin. It was set as default in beginning of the method.
Ajinkya Deshmukh			20-Jun-17			  FLS Check Added (Code Merge)
Shabda Bhujad				22-Jun-17             Added the logic to set case 'Type' to Enrollment along with case record type [PC-1701]
Mayuresh Patil              07-Sep-17            PC-2193 FLS Check updated to new PC303 code
Hitha Avalakki              05-Dec-18            PC-3243 Logic to configure the search criteria fields which would be used for Applicant creation.
Shishir Bansal              06-Dec-2019          [PC-5792] Avoid hardcoding of string variable
Haritha Reddy              16-Dec-2019           [PC-5791] Added error handling for linkDocToCase Method
Chetna Mohapatra           17-Mar-2020           [PC-6008] Updated getFieldSetName() by changing the fieldset name to PC_PreEnrollmentFormFieldset.
Chetna Mohapatra           15-Jun-2020           [PC-6152] Added the logic for fieldset error handling in getFieldSetFields().
Haritha Reddy              21-Jan-2021           [PC-7102] Added FLS Check
Haritha Reddy             21-Jan-2021            [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/
public with sharing class PC_Enrollment_NewApplicant {
    public static Map<String,String> accountApplicantFieldsMapping=new Map<String, String>();

    /*********************************************************************************
    Method Name    : createApplicants
    Description    : Create an applicant for pre enrollment
    Input Params   : 
    Return Type    : void
    *********************************************************************************/
    @AuraEnabled
    //public static Id createApplicants(String firstName, String lastName, string dob, String programId, String documentId, String onlineApplicantId, String patientId) {
    public static Case createApplicants(Map<String, Object> fsFieldsMap, String programId, String documentId, String onlineApplicantId, String patientId) {
        Case caseRecord = new Case();
        List<String> fsFieldNamesList=new List<String>(fsFieldsMap.keySet());
        accountApplicantFieldsMapping=PC_Utility.AccountToApplicantMapping(fsFieldNamesList);
        try {
            Case enrollmentCase = new Case();
            PC_Applicant__c activeApplicant;
            enrollmentCase.PC_Engagement_Program__c = programId;
            enrollmentCase.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE, PC_Constants.CASE_ENROLLMENT_RECORD_TYPE);
            enrollmentCase.Type = PC_Constants.CASE_ENROLLMENT_RECORD_TYPE_NAME; /*PC-1701*/ 
            enrollmentCase.Status = PC_Constants.STATUS_INDICATOR_OPEN;
            enrollmentCase.Origin = PC_Constants.CASE_ORIGIN_OTHER;
            if(String.isNotBlank(patientId)){
          		enrollmentCase.AccountId = patientId;
            }            
            //If enrollment wizard is launched from a document
            if(String.isNotBlank(documentId)) { 
                List<PC_Document__c> oDoc = [SELECT Id, RecordType.DeveloperName FROM PC_Document__c WHERE Id =: documentId];
                if (oDoc[0].RecordType.DeveloperName == PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE) {
                    enrollmentCase.origin = PC_Constants.CASE_ORIGIN_FAX;
                }else if (oDoc[0].RecordType.DeveloperName == PC_Constants.DOCUMENT_EMAIL_INBOUND_RECORD_TYPE) {
                    enrollmentCase.origin = PC_Constants.CASE_ORIGIN_EMAIL;
                }else if (oDoc[0].RecordType.DeveloperName == PC_Constants.DOCUMENT_SMARTFORM_RECORD_TYPE) {
                    enrollmentCase.origin = PC_Constants.CASE_ORIGIN_WEB;
                }                
            }
            PC_Database.ins(enrollmentCase);//FLS/CRUD Check enforced in the PC_database method

            //Check FLS
            List<String> fields = new List<String>{'CaseNumber'};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);

            caseRecord = [SELECT Id,CaseNumber  FROM Case WHERE Id =: enrollmentCase.Id];
            //Create new applicant only if online applicant does not exist
            if(String.isBlank(onlineApplicantId)) {
                PC_Applicant__c newApplicant = new PC_Applicant__c();
                newApplicant.PC_Engagement_Program__c = programId;
                //Assign enrollment case to the applicant
                newApplicant.PC_Enrollment_Case__c = enrollmentCase.Id;
                newApplicant.PC_Source__c = false;

                /****** Author:Hitha Avalakki ******/
                /************ Added as a part of PC-3243 --- START ***************/
                /*** 'accountApplicantFieldsMapping' holds the mapping of Account field names(as keys) and Applicant field names (as values).
                * This mapping is required in the following scenarios:
                * 1) For an Account field name there might be same field name on Applicant object.
                * 2) For an Account field name there might be different field name on Applicant object.
                * 3) For an Account field name there might be no field name on Applicant object.***/
                Map<String,Object> applicantFsFieldMap=new Map<String, Object>();
                for(String fsFieldKey:fsFieldsMap.keySet()){
                    if(!String.isEmpty(accountApplicantFieldsMapping.get(fsFieldKey))){
                        applicantFsFieldMap.put(accountApplicantFieldsMapping.get(fsFieldKey),fsFieldsMap.get(fsFieldKey));
                    }
                }

                Map<String,Object> applicantFieldAndValMap=new Map<String, Object>();
                for(String fsFieldKey:applicantFsFieldMap.keySet()){
                    Object fieldValue=PC_FieldSetController.castFieldValueBasedOnType(fsFieldKey,applicantFsFieldMap.get(fsFieldKey),newApplicant);
                    applicantFieldAndValMap.put(fsFieldKey,fieldValue);
                }

                for(String fsFieldKey:applicantFieldAndValMap.keySet()){
                    newApplicant.put(fsFieldKey,applicantFieldAndValMap.get(fsFieldKey));
                }
                /************ Added as a part of PC-3243 --- END ***************/

                if(String.isNotBlank(patientId)){
                    newApplicant.PC_Account__c = patientId;
                }
                PC_Database.ins(newApplicant);//FLS/CRUD Check enforced in the PC_database method
                activeApplicant = newApplicant;
            }
            //if online applicant
            else {
                List<PC_Applicant__c> onlineApplicant = [SELECT Id, Name FROM PC_Applicant__c WHERE Id =: onlineApplicantId];
                onlineApplicant[0].PC_Enrollment_Case__c = enrollmentCase.Id;
                
                if(String.isNotBlank(patientId)) {
                    onlineApplicant[0].PC_Account__c = patientId;
            	}
                PC_Database.upd(onlineApplicant[0]);//FLS/CRUD Check enforced in the PC_database method
                activeApplicant = onlineApplicant[0];
            }
            
            //Update Active Applicant field on Enrollment Case
            updateActiveApplicantOfCase(enrollmentCase, activeApplicant);
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return caseRecord;
    }
    
    /*********************************************************************************
    Method Name    : updateActiveApplicantOfCase
    Description    : Updates PC_Applicant__c on Enrollment case with latest applicant
    Input Params   : Enrollment case, Latest Applicant
    Return Type    : void      
    *********************************************************************************/
    
    private static void updateActiveApplicantOfCase(Case enrollmentCase, PC_Applicant__c activeApplicant) {
		Case eCase = enrollmentCase;
        eCase.PC_ActiveApplicant__c = activeApplicant.Id;
        /*
		 * Moved logic to PC_Trigger_Case [PC-1628]
		 */
        
        PC_Database.upd(eCase);
        
    }
    
    /*********************************************************************************
    Method Name    : linkDocToCase
    Description    : Links enrollment case to document and creates and entry in the Document Modification Log
    Input Params   : Id enrollmentCaseId, String documentId
    Return Type    : void      
    *********************************************************************************/
    @AuraEnabled
    public static void linkDocToCase(Id enrollmentCaseId, String documentId) {
        try {
            PC_DocumentToEnrollCaseLinkHelper.linkDocToCase(enrollmentCaseId, documentId);
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }

    /*****************************************************************************************************
    * Author       : Hitha Avalakki
    * User Story   : PC-3243
    * Parameter    : String
    * Method name  : getFieldSetFields
    * Return Type  : FieldSetDetailsWrapper
    * Description  : Method to get the fieldset members to be used for the search criteria.
    *****************************************************************************************************/
    @AuraEnabled
    public static FieldSetDetailsWrapper getFieldSetFields(String typeName, String engagementProgramCode) {
        FieldSetDetailsWrapper fieldSetDetailsWrapper;
        try {
            String fsNameVal = getFieldSetName(engagementProgramCode);
            Boolean isValid= PC_Utility.isValidFieldSet('Account', fsNameVal);
            if(!isValid){
                throw new AuraHandledException(Label.PC_Enrollment_Fieldset_ErrorMessage);
            }
            else {
                List<PC_FieldSetController.FieldSetMember> listFieldSetMembers = PC_FieldSetController.getFields(typeName, fsNameVal);
                fieldSetDetailsWrapper = new FieldSetDetailsWrapper(listFieldSetMembers, fsNameVal);
            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return fieldSetDetailsWrapper;
    }

    /*****************************************************************************************************
    * Author       : Hitha Avalakki
    * User Story   : PC-3243
    * Parameter    :
    * Method name  : getFieldSetName
    * Return Type  : String
    * Description  : Method to get the fieldset name for fields required for search criteria
    *****************************************************************************************************/
    @AuraEnabled
    public static String getFieldSetName(String engagementProgramCode) {
        String fieldSetName;
        try {
            fieldSetName = PC_SYSTEM.getSettingByEngagementProgram(engagementProgramCode, PC_Constants.PC_PRE_ENROLLMENT_FORM_FIELDSET,PC_Constants.SETTINGS_TYPE.PATIENT_CONNECT_SETTING,PC_Constants.getQualifiedAPIName('PC_PreEnrollmentWizardSearch'));
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return fieldSetName;
    }

    /*****************************************************************************************************
   * Author       : Hitha Avalakki
   * User Story   : PC-3243
   * Class name   : FieldSetDetailsWrapper
   * Description  : Wrapper class to hold search criteria fieldset name and its fieldset members.
   *****************************************************************************************************/
    public inherited sharing class FieldSetDetailsWrapper{
        @AuraEnabled public String fieldSetName {get;set;}
        @AuraEnabled public List<PC_FieldSetController.FieldSetMember> listFieldSetMembers{get; set;}

        public FieldSetDetailsWrapper(List<PC_FieldSetController.FieldSetMember> fieldSetMembersList , String fsName) {
            fieldSetName = fsName;
            listFieldSetMembers = fieldSetMembersList;
        }

        public FieldSetDetailsWrapper() {
            fieldSetName=PC_Constants.EMPTY_STRING;
            listFieldSetMembers = new List<PC_FieldSetController.FieldSetMember>();
        }
    }

}