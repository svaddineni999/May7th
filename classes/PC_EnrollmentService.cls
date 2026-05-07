/*********************************************************************************************************
Class Name    	: PC_EnrollmentService
Description     : REST class for Enrollment Case object 
Created By      : Deloitte
Created Date    : Jul 27, 2017
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Vijay Kashikar         		   Jul 27, 2017           Initial Version
****************************************************************************************************************/
/**
 * NOT IN USE
 */
@RestResource(urlMapping='/Enrollment/1.0/*')
global with sharing class PC_EnrollmentService {
	
    /*@HttpGet
    global static PC_EnrollmentWizardLightningController.EnrollmentWizardWrapper doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String enrollmentCaseId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        //Account result = [SELECT Id, Name, Phone, Website FROM Account WHERE Id = :accountId];
        return PC_EnrollmentWizardLightningController.setupEnrollmentWizard(enrollmentCaseId);
    }*/
    /*
    @HttpGet
    global static sObject doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String enrollmentCaseId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        sObject enrollmentCase = PC_RestAPIUtilities.getEnrollmentCase(enrollmentCaseId);
        return enrollmentCase;
    }
    */
    @HttpPost
    global static void doPost(String programCode, Account patient, Account provider, List<PC_Health_Plan__c> healthPlans, Case enrollmentCase) {
        /*PC_Engagement_Program__c engagementProgram = PC_RestAPIUtilities.getEngagementProgram(programCode);
        if(engagementProgram == null){
            return 'Program does not exist';
        }
        Case existingEnrollmentCase = PC_RestAPIUtilities.getEnrollmentCase(patient.Id, engagementProgram.Id);
        if(existingEnrollmentCase == null) {
         	// Create the enrollmentCase
         	Case newEnrollmentCase = new Case();
            
            String patientId;
            if(patient.Id == null) {
            	patientId = PC_PatientService.doPost(patient);    
            }
            else {
            	patientId = patient.Id;
            }
            
            // Link enrollment case with Account
            newEnrollmentCase.AccountId = patientId;
            newEnrollmentCase.RecordTypeId = PC_SYSTEM.recordTypeId('Case', PC_Constants.CASE_ENROLLMENT_RECORD_TYPE);
            // Link enrollment case with Engagement Program
            newEnrollmentCase.PC_Engagement_Program__c = engagementProgram.Id;
            newEnrollmentCase.Status = 'Open';
            newEnrollmentCase.Type = PC_Constants.CASE_ENROLLMENT_RECORD_TYPE_NAME;
            newEnrollmentCase.Origin = PC_Constants.CASE_ORIGIN_OTHER;
            
            
            insert newEnrollmentCase;
            
            
            String providerId;
            if(provider.Id == null) {
            	providerId = PC_ProviderService.doPost(provider);    
            }
            else {
            	providerId = provider.Id;
            }
            
            
            List<String> hps = new List<String>();
            String hpId;
            for(PC_Health_Plan__c hp : healthPlans) {
                if(String.isBlank(hp.Patient__c)) {
                	hp.Patient__c = newEnrollmentCase.AccountId;  
                }
                else {
                    // Abort?
                }                
                hpId = PC_HealthPlanService.doPost(hp);
                hps.add(hpId);
            }
            
            newEnrollmentCase.Status = PC_Constants.COMPLETED;
            
            //Create a new Program Case with patient information 
        	Case prgCase = new Case();
            prgCase.Status = PC_Constants.STATUS_ENROLLED;
            prgCase.AccountId = newEnrollmentCase.AccountId;
            prgCase.PC_Engagement_Program__c = newEnrollmentCase.PC_Engagement_Program__c;
            prgCase.Type = PC_Constants.CASE_PROGRAM_RECORD_TYPE_NAME;
            prgCase.PC_Enrollment_Date__c = date.today();
            
            insert prgCase;
            //Link the newly created program to the Enrollment Case
            newEnrollmentCase.PC_Program__c = prgCase.Id;
            update newEnrollmentCase;
            
            return 'tbd';
        }
        else {
            // check if programCase Exists
            // If exists, exit - Otherwise continue
        }
        return 'tbd';*/
        
    }
}