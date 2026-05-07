/*********************************************************************************
Class Name      : PC_Launch_PreEnrollment
Description     : Checks if the PC_Docmunent Object as an associated enrollemnt case, and returns True or False
Created By      : TEJAS PATEL
Created Date    : 25-Apr-2017

Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------           
TEJAS PATEL		         25-Apr-2017	              Initial Version
TEJAS PATEL				 02-May-2017				  else if condition to handel NULL account and applicant on the doc,i.e no active applicant
Mike Klumpenaar          23-Jun-2017                  PC-1817 Revert to using PC_SYSTEM.recordTypeId to resolve transaction issue
Mayuresh Patil           07-Sep-2017                  PC-2193 FLS Check updated to new PC303 code
Tejas Patel				 08-Nov-2017				  created new custom label PC_Not_Assigned
Roopsai / Ventkat        20-Aug-2018                  PC-2524 Placeholder button to initiate client custom workflow
*********************************************************************************/
public with sharing class PC_Launch_PreEnrollment {
    private static String nameNotAssigned = System.Label.PC_Not_Assigned;

    /*********************************************************
	Method Name          : checkEnrollment
	Description          : Check If the Documnet has an enrollment case assigned
	Input Params         : Documnet Id
	Return Type          : Returns True if No Enrollment Case assigned and False if Enrollment case is assigned. 
	*********************************************************************************/
    @AuraEnabled
    public static CaseDetails checkEnrollment (ID docID){
        List<PC_Document_Log__c> doc = new List<PC_Document_Log__c>();
        Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE, PC_Constants.CASE_ENROLLMENT_RECORD_TYPE);
        Case enrollmentcase = new Case();
        Account acc			= new Account();
        PC_Applicant__c app	= new PC_Applicant__c();
        
        try {
            //Check FLS/Crud before SOQL            
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Program__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'),PC_Database.Operation.Reading, fields);
            List<String> caseFields = new List<String>{'AccountId', PC_Constants.getQualifiedAPIName('PC_ActiveApplicant__c')};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, caseFields);
            doc	= [SELECT PC_Program__c, PC_Program__r.AccountId, PC_Program__r.PC_ActiveApplicant__c,PC_Program__r.PC_Engagement_Program__c
            		FROM PC_Document_Log__c 
                   	WHERE PC_Document__c =: docID 
                   	AND (PC_Program__r.RecordTypeId =: recordTypeId) 
                   	LIMIT 1];
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);                
        }      
        if(doc.isEmpty()) {
            CaseDetails casedetails = NULL;
            return casedetails;
        }else if (doc[0].PC_Program__r.AccountId == NULL && doc[0].PC_Program__r.PC_ActiveApplicant__c == NULL) {
            Id enrollmentCaseId	= doc[0].PC_Program__c;
            try {
                //Check FLS/Crud before SOQL            
                List<String> fields = new List<String>{'Id', 'CaseNumber', 'Status', 'Owner.Name', 'CreatedDate'};
                    PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
                
                enrollmentcase = [SELECT Id, CaseNumber, Status, Owner.Name, CreatedDate 
                					FROM Case 
                					WHERE Id =: enrollmentCaseId 
                					LIMIT 1];
            }catch(Exception ex) {
                PC_Utility.logAndThrowException(ex);                
            }
            
            CaseDetails casedetails = new CaseDetails(enrollmentcase);
            return casedetails;
            
        }else {
            Id enrollmentCaseId	= doc[0].PC_Program__c;
            Id accountId 		= doc[0].PC_Program__r.AccountId;
            Id applicantId		= doc[0].PC_Program__r.PC_ActiveApplicant__c;
            try {
                //Check FLS/Crud before SOQL            
                List<String> fields = new List<String>{'Id', 'CaseNumber', 'Status', 'Owner.Name', 'CreatedDate'};
                PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
                
                enrollmentcase = [SELECT Id, CaseNumber, Status, Owner.Name, CreatedDate 
                					FROM Case 
                					WHERE Id =: enrollmentCaseId 
                					LIMIT 1];  
            }catch(Exception ex) {
                PC_Utility.logAndThrowException(ex);                
            }
            
            if(!String.isEmpty(accountId)) {
                try {
                    //Check FLS/Crud before SOQL            
                    List<String> fields = new List<String>{'Id', 'Name', PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c')};
                    PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
                    
                    acc = [SELECT Id, Name, PC_Date_of_Birth__c 
                    		FROM Account 
                    		WHERE Id =: accountId 
                    		LIMIT 1];
                    		
                }catch(Exception ex) {
                    PC_Utility.logAndThrowException(ex);                
                }
                
                CaseDetails casedetails = new CaseDetails(acc, enrollmentcase);
                return casedetails;
                
            }else {
                try {
                    //Check FLS/Crud before SOQL            
                    List<String> fields = new List<String>{'Id',PC_Constants.getQualifiedAPIName('PC_Last_Name__c'), PC_Constants.getQualifiedAPIName('PC_First_Name__c'),
                        									PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c')};
                    PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Applicant__c'),PC_Database.Operation.Reading, fields);
                    
                    app = [SELECT Id, PC_Last_Name__c, PC_First_Name__c, PC_Date_of_Birth__c 
                    		FROM PC_Applicant__c 
                    		WHERE Id =: applicantId 
                    		LIMIT 1];   
                }catch(Exception ex) {
                    PC_Utility.logAndThrowException(ex);                
                }
                
                CaseDetails casedetails = new CaseDetails(app, enrollmentcase);
                return casedetails;
            }
        }
    }
    @AuraEnabled
    public static lstDocumentWorkflowSettingWrapper CheckMetadata (ID docID){
         List<PC_Document_Log__c> doc = new List<PC_Document_Log__c>();
        Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE, PC_Constants.CASE_ENROLLMENT_RECORD_TYPE);
        Case enrollmentcase = new Case();
        Account acc			= new Account();
        PC_Applicant__c app	= new PC_Applicant__c();
        
        try {
            //Check FLS/Crud before SOQL            
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Program__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'),PC_Database.Operation.Reading, fields);
            List<String> caseFields = new List<String>{'AccountId', PC_Constants.getQualifiedAPIName('PC_ActiveApplicant__c')};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, caseFields);
            doc	= [SELECT PC_Program__c, PC_Program__r.AccountId, PC_Program__r.PC_ActiveApplicant__c,PC_Program__r.PC_Engagement_Program__c,PC_Program__r.PC_Engagement_Program__r.PC_Program_Code__c
            		FROM PC_Document_Log__c 
                   	WHERE PC_Document__c =: docID 
                   	AND (PC_Program__r.RecordTypeId =: recordTypeId) 
                   	LIMIT 1];
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);                
        }
        System.debug('Document Id is' + doc);
        if (!doc.isEmpty()){
            List<lstDocumentWorkflowSettingWrapper> lstDocumentWorkflowSetting = new List<lstDocumentWorkflowSettingWrapper>();
                lstDocumentWorkflowSettingWrapper mWrapper;
                for (PC_Document_Custom_Workflow_Setting__mdt metadata : [select Id,PC_Action__c,PC_Active__c,PC_Component__c,PC_Engagement_Program__c from PC_Document_Custom_Workflow_Setting__mdt where PC_Engagement_Program__c=: doc[0].PC_Program__r.PC_Engagement_Program__r.PC_Program_Code__c and PC_Object_type__c=:'Document'and PC_Active__c=: true LIMIT 1]) {
                mWrapper = new lstDocumentWorkflowSettingWrapper(metadata);
                lstDocumentWorkflowSetting.add(mWrapper);
            }
            System.debug('lstDocumentWorkflowSetting  is' + lstDocumentWorkflowSetting);
            if(lstDocumentWorkflowSetting.size()>0){
                return  lstDocumentWorkflowSetting[0];}
        }
        return null;
    }
	
    
    public class lstDocumentWorkflowSettingWrapper {
       @AuraEnabled public String engagementProgram {get;set;}
        @AuraEnabled public String buttonName {get; set;}
        @AuraEnabled public String componentName {get; set;}
        @AuraEnabled public Boolean Active {get; set;}
        @AuraEnabled public Boolean RequiredAll {get; set;} 
        public lstDocumentWorkflowSettingWrapper() {}
        public lstDocumentWorkflowSettingWrapper(PC_Document_Custom_Workflow_Setting__mdt c) {
            this.engagementProgram = c.PC_Engagement_Program__c;
            this.buttonName = c.PC_Action__c; 
            this.componentName = (c.PC_Component__c.contains(':')) ? c.PC_Component__c : 'c:'+c.PC_Component__c;
            this.Active = c.PC_Active__c;
        }
    }
    public class CaseDetails {
        @AuraEnabled public Id caseId { get; set; }
        @AuraEnabled public Id accountId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Date dob { get; set; }
        @AuraEnabled public Date createddate { get; set; }
        @AuraEnabled public String caseowner { get; set; }
        @AuraEnabled public String casenumber { get; set; }
        @AuraEnabled public String casestatus { get; set; }
        
        public CaseDetails() {
        }
        
        public CaseDetails(Account a, Case c) {
            caseId 				= c.Id;
            accountId			= a.Id;
            name	 			= a.Name;
            dob 				= a.PC_Date_of_Birth__c;
            caseowner 			= c.Owner.Name ;
            casenumber 			= c.CaseNumber ;
            casestatus 			= c.Status ;
            createddate 		= c.CreatedDate.date();            
        } 
        
        public CaseDetails(PC_Applicant__c a, Case c) {
            caseId 				= c.Id;
            accountId			= a.Id;
            name                = '';
            if(a.PC_First_Name__c != null && a.PC_Last_Name__c != null){
                name = a.PC_Last_Name__c + ', ' + a.PC_First_Name__c;
            }else if(a.PC_Last_Name__c != null){
                name = a.PC_Last_Name__c;
            }else if(a.PC_First_Name__c != null){
                name = a.PC_First_Name__c;
            }
            dob 				= a.PC_Date_of_Birth__c;
            caseowner 			= c.Owner.Name ;
            casenumber 			= c.CaseNumber ;
            casestatus 			= c.Status ;
            createddate 		= c.CreatedDate.date();
        } 
        
        public CaseDetails(Case c) {
            caseId 				= c.Id;
            accountId			= NULL;
            name	 			= nameNotAssigned;
            dob 				= NULL;
            caseowner 			= c.Owner.Name ;
            casenumber 			= c.CaseNumber ;
            casestatus 			= c.Status ;
            createddate 		= c.CreatedDate.date();
        } 
    }
}