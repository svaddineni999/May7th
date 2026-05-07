/**
 * Class Name      : PC_EnrollPatientWZLightningController
 * Created By      : Mayuresh Patil
 * Created Date   : January 10, 2016
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                   	Description
 * -----------------------------------------------------------------------------------
 * Mayuresh Patil		  10-January-2017			Initial Version
 * Vijay Kashikar		  13-Apr-2017				Checks added to see if an enrollment case has associated applicant[PC-1424]
 * Ajinkya Deshmukh		  20-Jun-2017				FLS Check Added (Code Merge)
 * Shabda Bhujad		  27-Jun-2017				[PC-1701] - Change from record type to Type for case object
 * Mayuresh Patil         07-Sep-2017               PC-2193 FLS Check updated to new PC303 code
 * Tejas Patel            15-Jul-2021               PC-7914 Remove dependency on Active applicant when account exists on enrollment case
 */

/**
 * Method to get Case type to display the enroll button only if the case is of type enrollment.  
 */
public with sharing class PC_EnrollPatientWZLightningController {
	
    @AuraEnabled
    public static String getCaseType(Id caseId) {
    	String enrollmentCase = PC_Constants.NOT_ENROLLMENT;
        try {
        	/*
	        * FLS Check for PC_Document__c
	        */
	    	List<String> fields = new List<String>{'Status','Type',PC_Constants.getQualifiedAPIName('PC_ActiveApplicant__c')};
	        PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, fields);
            Case c = [SELECT Id, Status ,RecordType.DeveloperName, Type, PC_ActiveApplicant__c, AccountId
                      FROM Case
                      WHERE Id =:caseId LIMIT 1];
            /*PC-1701 - Change from record type to Type for case object*/
            if (c.Type == PC_Constants.CASE_ENROLLMENT_RECORD_TYPE_NAME){
                if(c.Status == PC_Constants.COMPLETED){
                    enrollmentCase = PC_Constants.COMPLETED_ENROLLMENT;
                } else {
                    enrollmentCase = PC_Constants.NEW_ENROLLMENT;
                }
                
                if(enrollmentCase == PC_Constants.NEW_ENROLLMENT && (String.isEmpty((String) c.PC_ActiveApplicant__c)) && (String.isEmpty((String) c.AccountId))){
                    enrollmentCase = PC_Constants.NEW_ENROLLMENT_WITHOUT_APPLICANT;
                }
            }
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);           
        }
        return enrollmentCase;
    }

}