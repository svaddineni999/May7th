/*********************************************************************************************************
Class Name      : ACLS_DocumentValidator
Description     : This class demonstrates how a Document Action’s visibility and 
accessibility can be shown/hidden conditionally depending on the values 
of the Document’s Categories.  
Created By      : Deloitte
Created Date    : Jan 18, 2023
****************************************************************************************************************
Version History :
Date			  Developer 			  User Story					     Changes
Jan 18, 2023	  Deloitte				   US-137				             Initial Version
*****************************************************************************************************************/

global with sharing class ACLS_DocumentValidator implements PC_ActionValidator.Validator { 
    global static Boolean isVisible(PC_ActionValidator.Params validationParams) { 
        PC_Document__c selectedDoc = getDocDetails(validationParams.recordId);  
        Boolean isVisible = false;  
        // In the condition below, it is decided whether to show the document action or not depending on the document tag value
        if ((selectedDoc.PC_Document_Category__c != null) && (selectedDoc.PC_Document_Category__c.contains('Enrollment Form'))) 
            isVisible = true; 
        return isVisible; 
    } 
    global static PC_ActionValidator.AccessibilityResponse isAccessible(PC_ActionValidator.Params validationParams) 
    { 
        PC_ActionValidator.AccessibilityResponse vdw = new PC_ActionValidator.AccessibilityResponse(); 
        PC_Document__c selectedDoc = getDocDetails(validationParams.recordId); 
        vdw.isAccessible = false; 
        // In the condition below, it is decided whether to allow the click action on document action or not depending on the document tag value 
        if((selectedDoc.PC_Document_Category__c != null) && (selectedDoc.PC_Document_Category__c.contains('Enrollment'))) 
        { 
            vdw.isAccessible = true; 
            vdw.message = 'This action is not accessible if document contains Enrollment'; //This message is shown to the end user. 
        } 
        return vdw; 
    } 
    global static PC_Document__c getDocDetails(String docId) { 
        PC_Document__c selectedDoc = new PC_Document__c ();  

        if(Schema.sObjectType.PC_Document__c.isAccessible()){
            selectedDoc = [SELECT Name, RecordType.DeveloperName, RecordType.NamespacePrefix,PC_Document_Category__c FROM 
                       PC_Document__c WHERE ID =: docId]; 
        }

        return selectedDoc; 
    } 
}