/*********************************************************************************
 Class Name     : ACLS_DocumentSplit_IntegrationHandler
Description     : Handler class to handle Document Split 
Created Date    : March 23, 2023
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Nandita Vyas            March 23, 2023             Initial Version - US-915/915
*********************************************************************************/
global with sharing class ACLS_DocumentSplit_IntegrationHandler implements PC_Document.Splitter {
    /*********************************************************************************
	Method Name    : splitDocument 
	Author         : Deloitte
	Description    : Use this method to perform an HTTP callout to initiate document splitting in an external service.
	Return Type    : void
	Parameter      : 
    @param parentDoc The document to split with a Id and PC_Correlation__c
    @param childDocs The child documents to create attachments for with Id and PC_Sorted_Parent_Pg_Num__c           
	*********************************************************************************/
    global void splitDocument(PC_Document__c parentDoc, List<PC_Document__c> childDocs) {
        System.enqueueJob(new ACLS_DocumentSplitQueueable(parentDoc,childDocs));
    }
}