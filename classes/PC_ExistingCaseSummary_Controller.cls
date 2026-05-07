/*********************************************************************************
Class Name      : PC_ExistingCaseSummary_Controller
Description     : Gets the information required to display case summary
Created By      : Shabda Bhujad
Created Date    : 9-Feb-2017
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Shabda Bhujad          9-Feb-2017              Initial Version
Ajinkya Deshmukh	   16-Feb-2017			   Added method linkDocToCase for Doc linking
Shabda Bhujad		   13-June-2017			   [PC-1701] Updated the wrapper and the getCaseDetails method to pull 'Type' instead of 'RecordType'
Mayuresh Patil         07-Sep-2017             PC-2193 FLS Check updated to new PC303 code
*********************************************************************************/
public with sharing class PC_ExistingCaseSummary_Controller{

    /*********************************************************************************
    Method Name    : getCaseDetails
    Description    : Gets case details for the enrollment case
    Input Params   : String enrollCaseId
    Return Type    : CaseWrapper      
    *********************************************************************************/
    @AuraEnabled
    public static CaseWrapper getCaseDetails(String reqCaseId) {
        Case enrollmentCase = new Case();
        CaseWrapper caseSummaryWrapper = new CaseWrapper(enrollmentCase);
        
        try {
			//Check FLS/Crud before SOQL            
            List<String> fields = new List<String>{'CaseNumber', 'OwnerId', 'Status', 'Type',PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
                       
            enrollmentCase = [select Id, RecordType.Name, Type, PC_Engagement_Program__r.Name,CaseNumber, Owner.Name, Status,PC_Engagement_Program__r.PC_Program_Code__c 
                              	FROM Case WHERE Id =: reqCaseId ];
            caseSummaryWrapper= new CaseWrapper(enrollmentCase);
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);                
        }
        return caseSummaryWrapper;
    }
    
   
    /*********************************************************************************
    Method Name    : linkDocToCase
    Description    : This method is Used to create document log records and attach it to the enrollment case
    Input Params   : Id documentId, Id programId,
    Return Type    : void      
    *********************************************************************************/
	@AuraEnabled
    public static void linkDocToCase(Id enrollmentCaseId, String documentId) {
        PC_DocumentToEnrollCaseLinkHelper.linkDocToCase(enrollmentCaseId, documentId);
    }

    /*********************************************************************************
    Method Name    : lstDocumentWorkflowSettingWrapper
    Description    : This method is Used to retrive relevant data for the component
    Input Params   : Id CaseId,
    Return Type    : lstDocumentWorkflowSettingWrapper
    *********************************************************************************/

      @AuraEnabled
    public static lstDocumentWorkflowSettingWrapper CheckMetadata (String reqCaseId){
        Case enrollmentCase = new Case();
        CaseWrapper caseSummaryWrapper = new CaseWrapper(enrollmentCase);
        
        try {
            //Check FLS/Crud before SOQL
            List<String> fields = new List<String>{'CaseNumber', 'OwnerId', 'Status', 'Type',PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
            lstDocumentWorkflowSettingWrapper mWrapper;

            enrollmentCase = [select Id, RecordType.Name, Type, PC_Engagement_Program__r.Name,CaseNumber, Owner.Name, Status,PC_Engagement_Program__r.PC_Program_Code__c
                                FROM Case WHERE Id =: reqCaseId ];
            caseSummaryWrapper= new CaseWrapper(enrollmentCase);

            FieldSetDetailsWrapper fsDetails = new FieldSetDetailsWrapper();
            fsDetails = getFieldSetFields(PC_Constants.PC_ACCOUNT, caseSummaryWrapper.engagementProgramCode);

            List<PC_Document_Custom_Workflow_Setting__mdt> metadata = new List<PC_Document_Custom_Workflow_Setting__mdt>();
            metadata = [Select Id,PC_Action__c,PC_Active__c,PC_Component__c,PC_Engagement_Program__c
                        From PC_Document_Custom_Workflow_Setting__mdt
                        Where PC_Engagement_Program__c=: enrollmentCase.PC_Engagement_Program__r.PC_Program_Code__c And PC_Active__c=: true  And PC_Object_type__c=:'Case' LIMIT 1];
            if(metadata.isEmpty()){
                mWrapper = new lstDocumentWorkflowSettingWrapper(caseSummaryWrapper, fsDetails);
            }else{
                mWrapper = new lstDocumentWorkflowSettingWrapper(metadata[0], caseSummaryWrapper, fsDetails);
            }

            return mWrapper;
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return null;
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
        System.debug('Entered getFieldSetFields');
        FieldSetDetailsWrapper fieldSetDetailsWrapper;
        try {
            String fsNameVal = getFieldSetName(engagementProgramCode);
            System.debug('getFieldSetFields: fsName: ' + fsNameVal);
            List<PC_FieldSetController.FieldSetMember> listFieldSetMembers = PC_FieldSetController.getFields(typeName, fsNameVal);
            fieldSetDetailsWrapper = new FieldSetDetailsWrapper(listFieldSetMembers, fsNameVal);
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        System.debug('getFieldSetFields: fieldSetDetailsWrapper: ' + fieldSetDetailsWrapper);
        return fieldSetDetailsWrapper;
    }

    /*****************************************************************************************************
    * Author       : Hitha Avalakki
    * User Story   : PC-3243
    * Parameter    :
    * Method name  : getFieldSetName
    * Return Type  : String
    * Description  : Method to get the fieldset name for fields required for search criteria.
    *****************************************************************************************************/
    @AuraEnabled
    public static String getFieldSetName(String engagementProgramCode) {
        System.debug('Eneterd getFieldSetName ');
        String fieldSetName;
        try {
            fieldSetName = PC_SYSTEM.getSettingByEngagementProgram(engagementProgramCode,PC_Constants.PC_PRE_ENROLLMENT_SEARCH,PC_Constants.SETTINGS_TYPE.PATIENT_CONNECT_SETTING,PC_Constants.getQualifiedAPIName('PC_PreEnrollmentWizardSearch'));
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        System.debug('getFieldSetName: fieldSetName: ' + fieldSetName);
        return fieldSetName;
    }

    public class lstDocumentWorkflowSettingWrapper {
        @AuraEnabled public CaseWrapper caseDetails {get;set;}
        @AuraEnabled public FieldSetDetailsWrapper fsDetails {get;set;}
        @AuraEnabled public String engagementProgram {get;set;}
        @AuraEnabled public String buttonName {get; set;}
        @AuraEnabled public String componentName {get; set;}
        @AuraEnabled public Boolean Active {get; set;}
        @AuraEnabled public Boolean RequiredAll {get; set;}

        public lstDocumentWorkflowSettingWrapper() {}

        public lstDocumentWorkflowSettingWrapper(CaseWrapper cw, FieldSetDetailsWrapper fsw) {
            this.engagementProgram  = PC_Constants.EMPTY_STRING;
            this.buttonName         = PC_Constants.EMPTY_STRING;
            this.componentName      = PC_Constants.EMPTY_STRING;
            this.Active             = false;
            this.RequiredAll        = false;
            this.caseDetails        = cw ;
            this.fsDetails          = fsw;
        }
        public lstDocumentWorkflowSettingWrapper(PC_Document_Custom_Workflow_Setting__mdt c, CaseWrapper cw, FieldSetDetailsWrapper fsw) {
            this.engagementProgram  = c.PC_Engagement_Program__c;
            this.buttonName         = c.PC_Action__c;
            this.componentName      = (c.PC_Component__c.contains(':')) ? c.PC_Component__c : 'c:'+c.PC_Component__c;
            this.Active             = c.PC_Active__c;
            this.caseDetails        = cw;
            this.fsDetails          = fsw;
        }
    }
    /*********************************************************************************
	Class Name     : CaseWrapper
	Description    : Wrapper class for Case Summary
	*********************************************************************************/
    public class CaseWrapper {
        @AuraEnabled public Id caseId {get;set;}
        @AuraEnabled public String caseType {get; set;}
       	@AuraEnabled public String engagementProgramName {get; set;}
        @AuraEnabled public String engagementProgramCode {get; set;}
        @AuraEnabled public String caseNumber {get; set;}
        @AuraEnabled public String caseOwner {get; set;}
        @AuraEnabled public String caseStatus {get; set;}

        public CaseWrapper(){}

        public CaseWrapper(Case c) {
            this.caseId = c.Id;
            this.caseType = c.Type;/*PC-1701*/
            this.engagementProgramName = c.PC_Engagement_Program__r.Name;
            this.engagementProgramCode = c.PC_Engagement_Program__r.PC_Program_Code__c;
            this.caseNumber = c.CaseNumber;
            this.caseOwner = c.Owner.Name; 
            this.caseStatus = c.Status;
        }
    }

    /*****************************************************************************************************
   * Author       : Hitha Avalakki
   * User Story   : PC-3243
   * Class name   : FieldSetDetailsWrapper
   * Description  : Wrapper class to hold search criteria fieldset name and its fieldset members.
   *****************************************************************************************************/
    public class FieldSetDetailsWrapper{
        @AuraEnabled public String fieldSetName {get;set;}
        @AuraEnabled public List<PC_FieldSetController.FieldSetMember> listFieldSetMembers{get; set;}

        public FieldSetDetailsWrapper(List<PC_FieldSetController.FieldSetMember> fieldSetMembersList , String fsName) {
            fieldSetName = fsName;
            listFieldSetMembers = fieldSetMembersList;
        }

        public FieldSetDetailsWrapper() {
            fieldSetName='';
            listFieldSetMembers = new List<PC_FieldSetController.FieldSetMember>();
        }
    }
    
}