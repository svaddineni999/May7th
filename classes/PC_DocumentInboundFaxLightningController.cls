/*********************************************************************************
Class Name      : PC_DocumentInboundFaxLightningController
Description     : Controller class used for PC_Document_InboundFax.cmp (lightning)
Created By      : Deloitte               
Created Date    : June 08, 2016
Modification Log:
---------------------------------------------------------------------------------- 
Developer              Date                   Description
-----------------------------------------------------------------------------------            
Alina Balan           June 16, 2016           Initial Version
Ajinkya Deshmukh	  June 20, 2017			  FLS Check Added (Code Merge)
Haritha Reddy          Dec 13, 2019          [PC-5791] Added error handling for getAttachmentId Method
Haritha Reddy         21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/

public with sharing class PC_DocumentInboundFaxLightningController {
    
    /*********************************************************************************
    Method Name    : getAttachmentId
    Author         : Alina Balan
    Description    : This method is used to get all the fax details
    Return Type    : FaxDetailsWrapper
    Parameter      : String docId
    *********************************************************************************/
    @AuraEnabled 
    public static FaxDetailsWrapper getAttachmentId(String docId) {
        FaxDetailsWrapper faxDetailsWrapper = new FaxDetailsWrapper();
        try {

            /*
        * FLS Check for Attachment
        */
            List<String> fields = new List<String>{
                    'Name'
            };
            PC_Database.assertAccess(PC_Constants.PC_ATTACHMENT, PC_Database.Operation.Reading, fields);
            List<Attachment> lstAttachments = [SELECT Id FROM Attachment WHERE parentId = :docId limit 1];
            if (lstAttachments.size() > 0) {
                faxDetailsWrapper.attachmentId = lstAttachments[0].Id;
            }
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return faxDetailsWrapper; 
    }
    
    /*********************************************************************************
    Class Name    : FaxDetailsWrapper
    Author        : Alina Balan
    Description   : Wrapper class for fax details
    *********************************************************************************/
    public inherited sharing class FaxDetailsWrapper {
        @AuraEnabled public Id attachmentId {get; set;}
    }
}