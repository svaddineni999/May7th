/*********************************************************************************
Class Name      : PC_Document_InboundEmailController 
Description     : This class is used for displaying Document details for an Inbound Email
Created By      : Deloitte               
Created Date    : July 23, 2015    
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Urmi Chatterjee           	July 23, 2015          Initial Version
Alina Balan             	26-May-2016            Imported from Lilly & code refactoring, PC-20
Ajinkya Deshmukh			08-Jun-2017
Mayuresh Patil              26-Jul-2017            Updated CRUD/FLS Checks
Haritha Reddy               May 05,2020            [PC-6249] Added limit to the inner SOQL query
*********************************************************************************/
public with sharing class PC_Document_InboundEmailController {
  public List<PC_Document__c> contRecords {get;set;}
  public Id sAttachmentId {set; get;}
  public String parentBody {get;set;}
  public ID docId{get; set{
          docId=value;
          setupAttachment();
      }
  }
  
    /*********************************************************************************
    Method Name    : PC_Document_InboundEmailController
    Description    : Class constructor
    Return Type    : Void 
    Parameter      : None             
    *********************************************************************************/
  public PC_Document_InboundEmailController () {
      contRecords = new List<PC_Document__c>();
    } 
    
    /*********************************************************************************
    Method Name    : setupAttachment
    Description    : method used to display the attachment
    Return Type    : Void 
    Parameter      : None             
    *********************************************************************************/
    public void setupAttachment() {
    	/*
        * FLS Check for Attachment
        */
    	List<String> fields = new List<String>{'Name','Body'};
        PC_Database.assertAccess(PC_Constants.PC_ATTACHMENT,PC_Database.Operation.Reading, fields);
        List<Attachment> lstAttachments = [SELECT Id, Name, Body FROM Attachment WHERE ParentId=:docId order by CreatedDate desc];
        
        /*
        * FLS Check for PC_Document__c
        */
    	fields = new List<String>{'Name',PC_Constants.getQualifiedAPIName('PC_Description__c'),PC_Constants.getQualifiedAPIName('PC_Parent_Document__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'),PC_Database.Operation.Reading, fields);

        contRecords = [SELECT PC_Description__c, RecordType.DeveloperName, Name, (SELECT Id, Name FROM Attachments LIMIT 2000)
                       FROM PC_Document__c WHERE PC_Parent_Document__c =:docId];
        Attachment att;
        if (lstAttachments.size() > 0) {
            att = lstAttachments[0];
        }
        try{
            if(att != null && att.body.size() > 0) {
                parentBody = (att.body).toString(); 
            }
            sAttachmentId = att.Id;
        }
        catch(Exception e){
            parentBody = Label.PC_Cannot_Display_Document;
        }
    }
}