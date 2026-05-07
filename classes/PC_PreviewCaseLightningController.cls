/*********************************************************************************
Class Name      : PC_PreviewCaseLightningController
Description     : Links a case and document. Creates an entry in Document Modification Log and Document Log
Created By      : Prachi Nandgaonkar
Created Date    : 10-Feb-2017
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Prachi Nandgaonkar          10-Feb-2017            Initial Version
*********************************************************************************/
public with sharing class PC_PreviewCaseLightningController {

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
    
}