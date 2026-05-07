/*********************************************************************************
Class Name      : PC_DocumentManagementController
Description     : This class is the controller for the Document Management page which
                  is used for fax and email management. The logic to filter the container
                  type based on record type of the document resides in this class.
Created By      : Deloitte               
Created Date    : April 1, 2015
Modification Log:
---------------------------------------------------------------------------------- 
Developer              	Date                   	Description
-----------------------------------------------------------------------------------            
Abhinav G             	June 16, 2015          	Initial Version
Urmi C                	August 18, 2015       	Added isSmartform boolean
Alina Balan           	26-May-2016           	PC-20 Added "changeDocumentOwner" method
Shabda Bhujad			Dec 06, 2016			Added FLS check to loadData, changeDocumentOwner method
Ajinkya Deshmukh		Jun 08, 2017			FLS Check Added
Mayuresh Patil          Jul 26, 2017            Updated CRUD/FLS Checks
*********************************************************************************/

public with sharing class PC_DocumentManagementController {
    public string sAttachmentId {get;set;}
    public Id docId {get;set;}
    public boolean loaded {set; get;}
    public boolean loadFaxContainer {set; get;}
    public boolean loadEmailContainer {set; get;}
    public boolean isSmartform {get;set;}
    @TestVisible private PC_Document__c oDocument;
    private List<Attachment> lstAttachments;
    private ApexPages.StandardController controller;
    
    /*********************************************************************************
    Method Name    : PC_DocumentManagementController
    Description    : Class constructor
    Return Type    : Void 
    Parameter      : None             
    *********************************************************************************/
    public PC_DocumentManagementController(ApexPages.StandardController controller) {
        this.controller = controller;
        loadData();
    }  
    
    /*********************************************************************************
    Method Name    : loadData
    Description    : This method is used to load all necessary data
    Return Type    : Void 
    Parameter      : None             
    *********************************************************************************/
    private void loadData() {
        docId = controller.getRecord().Id;
        try{
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Document_Status__c'), PC_Constants.OWNER_ID_PARAM, PC_Constants.getQualifiedAPIName('PC_Archived_On__c'), PC_Constants.getQualifiedAPIName('PC_Archived_By__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'),PC_Database.Operation.Reading, fields);    
            List<PC_Document__c> contRecords = [SELECT Id, RecordType.DeveloperName, PC_Document_Status__c, OwnerId, PC_Archived_On__c, PC_Archived_By__c
                                                FROM PC_Document__c WHERE Id =:controller.getRecord().Id];
            loadFaxContainer = false;
            loadEmailContainer = false;
            isSmartform = false;
            if(contRecords.size() > 0) {
                oDocument = contRecords[0];
                if(  contRecords[0].RecordType.DeveloperName.equalsIgnoreCase(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE)){
                    loadFaxContainer = true;
                }
                else if(contRecords[0].RecordType.DeveloperName.equalsIgnoreCase(PC_Constants.DOCUMENT_EMAIL_INBOUND_RECORD_TYPE) || 
                        contRecords[0].RecordType.DeveloperName.equalsIgnoreCase(PC_Constants.DOCUMENT_EMAIL_OUTBOUND_RECORD_TYPE)){
                            loadEmailContainer = true;
                        }
                else if(contRecords[0].RecordType.DeveloperName.equalsIgnoreCase(PC_Constants.DOCUMENT_SMARTFORM_RECORD_TYPE)){
                    isSmartform = true;
                }
                fields = new List<String>{'Name','Body'};
            	PC_Database.assertAccess(PC_Constants.PC_ATTACHMENT,PC_Database.Operation.Reading, fields);
            	lstAttachments = [SELECT Id, Name, Body FROM Attachment WHERE ParentId =: contRecords[0].Id order by CreatedDate desc];
            } 
        } catch(Exception ex){
            PC_Utility.logAndThrowException(ex);    
        }
        
        if ((lstAttachments == null || lstAttachments.size() == 0) /*&& !isSmartform*/) {
            loaded = false;
            addErrorToPage(Label.PC_No_Attachment);
            return;
        } else {
            sAttachmentId = lstAttachments[0].Id;
        }
    }
    
    /*********************************************************************************
    Method Name    : addErrorToPage
    Description    : This method displays error messages
    Return Type    : Void 
    Parameter      : None             
    *********************************************************************************/
    private void addErrorToPage(String message) {
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, message));
    }
    
    /*********************************************************************************
    Method Name    : loadData
    Author         : Alina Balan
    Description    : This method is used to set the document owner, when the user enter on view page and the document has been categorized
    Return Type    : Void 
    Parameter      : None             
    *********************************************************************************/
    public void changeDocumentOwner() {
        try {            
            //List<String> fields = new List<String>{}; Need if fields other than Id are added to the query
            //PC_Database.assertAccess('User',PC_Database.Operation.Reading, fields);    
            List<User> lstUsers = [SELECT Id FROM User WHERE Id =: oDocument.OwnerId];
            //check if the doc status is not categorized or the owner is already the current user or the owner is another user (not a queue)
            if (!oDocument.PC_Document_Status__c.equalsIgnoreCase(PC_Constants.DOCUMENT_STATUS_CATEGORIZED) || oDocument.OwnerId == userinfo.getUserId() || lstUsers.size() > 0) return;
            Attachment oAttachement;
            //check if the attachments list hasn't any element
            if (lstAttachments.size() == 0) {
                addErrorToPage(Label.PC_No_Attachment); 
                return;
            }
            
            oAttachement = lstAttachments[0];
            oDocument.OwnerId = userinfo.getUserId();
            if(oDocument!=null){
                PC_Database.upd(oDocument);//CRUD/FLS check enforced
            }
            //check if the attachment is not null
            if (oAttachement != null) {
                oAttachement.OwnerId = userinfo.getUserId();
                PC_Database.upd(oAttachement);//CRUD/FLS check enforced
            }
            
            PC_Document_Log__c oDocLog = new PC_Document_Log__c();
            oDocLog.PC_Document__c = oDocument.Id;
            oDocLog.PC_Document_Log__c =  Label.PC_Ownership_changed_to +' '+userinfo.getName();
            oDocLog.PC_Document_Owner_Id__c = userinfo.getUserId();
            if(oDocLog!=null) {
                PC_Database.ins(oDocLog);//CRUD/FLS Check enforced
            }           
        } catch(Exception ex){
           PC_Utility.logAndThrowException(ex);          
        }
    }
}