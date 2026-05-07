/*********************************************************************************
Class Name      : PC_DocumentToEnrollCaseLinkHelper
Description     : 
Created By      : Prachi Nandgaonkar
Created Date    : 13-Feb-2017
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Prachi Nandgaonkar          13-Feb-17              Initial Version
Prachi Nandgaonkar          14-Apr-17              [PC-1379] Refactored linkDocToCase(). Updated enrollment case's applicant id from applicant id from 
Prachi Nandgaonkar          17-Mar-17              [PC-1377] Updated Enrollment case on latest applicant when a second online form for an existing online applicant comes in
Shabda Bhujad 				08-Jun-17			   [PC-1701] Updated document log to populate Type instead of RecordType.
Ajinkya Deshmukh			21-Jun-17			   FLS Check Added (Code Merge)
Mayuresh Patil              07-Sep-17              [PC-2193] FLS Check updated to new PC303 code
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
*********************************************************************************/
public with sharing class PC_DocumentToEnrollCaseLinkHelper {
	
    /*********************************************************************************
    Method Name    : linkDocToCase
    Author         : Prachi Nandgaonkar
    Description    : This method creates a document log entry
    Return Type    : void
    Parameter      : 
    *********************************************************************************/
    public static void linkDocToCase(Id enrollmentCaseId, String documentId) {
		//FLS/CRUD check before SOQL
		List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Program__c'),PC_Constants.getQualifiedAPIName('PC_Document__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'),PC_Database.Operation.Reading, fields); 
        
        try {
            if(String.isNotBlank(documentId) && enrollmentCaseId != null) {
                //Get document log entry if already exists
                List<PC_Document_log__c> getDocumentLog = [SELECT Id FROM PC_Document_Log__c 
                                                           WHERE PC_Document__c =: documentId 
                                                           AND PC_Program__c =: enrollmentCaseId];
                
                //FLS/CRUD check before SOQL             
                fields = new List<String>{'CaseNumber', 'Type', PC_Constants.getQualifiedAPIName('PC_ActiveApplicant__c')};
                PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
                /*
                 * Fetch case details - added 'Type' for [PC-1701]  
				 */
                Case caseDetails = [SELECT Id, CaseNumber, RecordType.Name, Type, PC_ActiveApplicant__c FROM Case WHERE Id =:enrollmentCaseId];
                
                //Create a new entry in Document Modification Log if no matching entry found
                if(getDocumentLog.isEmpty()) {
                    PC_Document_Log__c docObj = new PC_Document_Log__c();
                    docObj.PC_Document__c = documentId;
                    docObj.PC_Program__c = caseDetails.Id;
                    docObj.PC_Association_Record_ID__c = caseDetails.Id;
                    docObj.PC_Association_Record_Name__c = caseDetails.CaseNumber;
                    /*
                     * Set the document log with Type [PC-1701]
					 */
                    docObj.PC_Association_Type__c = caseDetails.Type;
                    
                    PC_Database.ins(docObj);
                }
                
                //FLS/CRUD check before SOQL
                fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Document_Status__c'), PC_Constants.getQualifiedAPIName('PC_Applicant__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'),PC_Database.Operation.Reading, fields); 
                //Fetch document details to update status
                PC_Document__c docObj = [SELECT Id, RecordType.Name, PC_Document_Status__c, PC_Applicant__c FROM PC_Document__c WHERE Id=:documentId];
                if(docObj != null) {
                    //if document does not have any splitting related status
                    if (docObj.PC_Document_Status__c != PC_Constants.DOCUMENT_STATUS_SPLIT_IN_PROGRESS && docObj.PC_Document_Status__c != PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT &&
                        docObj.PC_Document_Status__c != PC_Constants.DOCUMENT_STATUS_AWAITING_ATTACHMENT  && docObj.PC_Document_Status__c != PC_Constants.DOCUMENT_STATUS_SPLIT_FAILURE ){
                            //change status to complete and ready for use
                            docObj.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_COMPLETE; 
                        }
                    PC_Database.upd(docObj);
                }
                
               //For an online form   
                if(docObj.RecordType.Name == PC_Constants.DOCUMENT_SMARTFORM_RECORD_TYPE_NAME ){
                    Id activeApplicantId;
                    
                    //Check if Document's Applicant Id matches with Enrollment Case's Applicant Id. 
                    //Condition satisfied only for second online form for an existing online applicant
                    if(caseDetails.PC_ActiveApplicant__c != docObj.PC_Applicant__c ){
                        //Update Enrollment case's applicant id with Document's applicant id
                        caseDetails.PC_ActiveApplicant__c = docObj.PC_Applicant__c;
                        activeApplicantId = docObj.PC_Applicant__c;
                        PC_Database.upd(caseDetails);
                    }
                    
                    //If second online form for an existing online applicant
                    if(activeApplicantId != null) {
                    	fields = new List<String>{'Id'};
            			PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Applicant__c'),PC_Database.Operation.Reading, fields);
                        //Update Enrollment Case on latest applicant
                        PC_Applicant__c activeApplicant = [SELECT Id FROM PC_Applicant__c WHERE Id =: activeApplicantId];
                        activeApplicant.PC_Enrollment_Case__c = caseDetails.Id;
                        PC_Database.upd(activeApplicant,true);
                    }
                }
            }    
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }
        
}