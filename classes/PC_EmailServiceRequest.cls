/*********************************************************************************
Class Name      : PC_EmailServiceRequest
Description     : 
Created By      : Deloitte               
Created Date    : June 03, 2016
Modification Log:
---------------------------------------------------------------------------------- 
Developer              Date                   Description
-----------------------------------------------------------------------------------            
Roxana Ivan        June 03, 2016            Initial Version
Haritha Reddy         21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/
/**
 * This is the utility class for PC_EmailWebService
 */
global with sharing class PC_EmailServiceRequest {
    /*public PC_EmailServiceRequest(){}*/
    
    public String fromName {get;set;}
    public String fromAddress {get;set;}
    public String subject {get;set;}
    public EmailBody body {get;set;}

    /*********************************************************************************
    Class Name      : EmailAttachement
    Description     : Email Attachement inner class - build to be able to add multiple attachements on the same email
    Created By      : Roxana Ivan
    Created Date    : June 03, 2016 
    Modification Log:
    ---------------------------------------------------------------------------------- 
    Developer                   Date                   Description
    -----------------------------------------------------------------------------------            
    Roxana Ivan            June 03, 2016               Initial Version
    *********************************************************************************/
    public inherited sharing class EmailAttachement{
        public EmailAttachement(){}

        public String fileName {get;set;}
        public String body {get;set;}
    }
    /*********************************************************************************
    Class Name      : EmailBody
    Description     : Email Body inner class
    Created By      : Roxana Ivan
    Created Date    : June 03, 2016 
    Modification Log:
    ---------------------------------------------------------------------------------- 
    Developer                   Date                   Description
    -----------------------------------------------------------------------------------            
    Roxana Ivan               16-June-16              Initial Version
    *********************************************************************************/
    public inherited sharing class EmailBody{
        public EmailBody(){}
        public String plainTextBody {get;set;}
        public List<EmailAttachement> textAttachments {get;set;}
    }

}