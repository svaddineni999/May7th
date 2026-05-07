/*********************************************************************************************************
Class Name      : ACLS_ContentDocumentTriggerHandler
Description     : trigger on ContentDocumentLink object. 
Created By      : Deloitte
Created Date    : March 23, 2023
****************************************************************************************************************
Version History :
Date			  Developer 			  User Story					     Changes
March 23, 2023	Nandita Vyas				US-647				Created Inbound Document Record
*****************************************************************************************************************/
public inherited sharing class ACLS_ContentDocumentTriggerHandler extends PC_TriggerHandler {
  
    override public void afterInsert(){
         createDocumentRecordForFaxInbound((List<ContentDocumentLink>) newList);
     }
     
      /*********************************************************************************
     Method Name    : createDocumentRecordForFaxInbound 
     Author         : Deloitte
     Description    : This method will create Documents record of Inbound Fax
     Return Type    : void
     Parameter      : List of incoming records               
     *********************************************************************************/
     public static void createDocumentRecordForFaxInbound(list<ContentDocumentLink> newList)
     {
         List<PC_Document__c> docToInsert = new List<PC_Document__c>();
         ContentDocumentLink cdlLink = new ContentDocumentLink();
         Set<Id> faxRecordIds = new Set<Id>();
         Map<Id,ContentDocumentLink> mapDocVsCDL = new Map<Id,ContentDocumentLink>();
         Map<String,Id> mapPhoneEP = new Map<String,Id>();
         Map<Id, PC_Document__c> mapFaxVsDoc = new Map<Id, PC_Document__c>();
         List<Task> exceptionTaskList = new List<Task>();
         Id recordTypeIdFaxInboundDocument = ACLS_Utility.getRecordTypeId(ACLS_Constants.PCDocument,ACLS_Constants.FAX_INBOUND); 
         Id recordTypeIdFaxReceivedFax = ACLS_Utility.getRecordTypeId(ACLS_Constants.OBJ_FAX,ACLS_Constants.FAX_RECEIVED);
 
         if(Schema.sObjectType.PC_Engagement_Program__c.isAccessible()){
            for(PC_Engagement_Program__c  ep : [Select Id, ACLS_Program_Fax__c from PC_Engagement_Program__c]){
                    mapPhoneEP.put(ep.ACLS_Program_Fax__c,ep.Id);
            }
         } 
         
         try
         {
              
             for(ContentDocumentLink objCdl : newList){
                 if(objCdl.LinkedEntityId.getSobjectType() == EFX__efax__c.SObjectType){
                     faxRecordIds.add(objCdl.LinkedEntityId);
                 }
             }
             if(faxRecordIds.isEmpty()){
                 return;
             }
             
             //Query to get fax records related to CDL
             Map<Id, EFX__efax__c> faxRecords = new Map<Id, EFX__efax__c>([SELECT Id, EFX__Status__c,EFX__Message__c,EFX__From__c, EFX__Subject__c,EFX__eFax_Id__c,EFX__Page__c,EFX__To__c,RecordTypeId,Name From EFX__efax__c WHERE ID IN :faxRecordIds]);
             if(Schema.sObjectType.ContentDocumentLink.isAccessible()){
             for(ContentDocumentLink objCdl : newList){            
                 if(faxRecords.containsKey(objCdl.LinkedEntityId) &&  
                     faxRecords.get(objCdl.LinkedEntityId).EFX__Status__c == 'STORED' &&
                     faxRecords.get(objCdl.LinkedEntityId).RecordTypeId == recordTypeIdFaxReceivedFax){ 
                         
                     PC_Document__c objDoc = new PC_Document__c();
                         objDoc.RecordTypeId = recordTypeIdFaxInboundDocument;
                         objDoc.ACLS_Subject__c = faxRecords.get(objCdl.LinkedEntityId).EFX__Subject__c;
                         objDoc.PC_Document_Status__c = 'New';
                         objDoc.PC_Fax_Unique_Id__c = faxRecords.get(objCdl.LinkedEntityId).EFX__eFax_Id__c;
                         objDoc.PC_From_Fax_Number__c = faxRecords.get(objCdl.LinkedEntityId).EFX__From__c;
                         objDoc.PC_Page_Count__c = faxRecords.get(objCdl.LinkedEntityId).EFX__Page__c;
                         objDoc.PC_To_Fax_Number__c = faxRecords.get(objCdl.LinkedEntityId).EFX__To__c;
                         objDoc.ACLS_Fax__c = faxRecords.get(objCdl.LinkedEntityId).Id; 
                         objDoc.ACLS_Message__c= faxRecords.get(objCdl.LinkedEntityId).EFX__Message__c;
                         objDoc.PC_Engagement_Program__c = (mapPhoneEP.containsKey(objDoc.PC_To_Fax_Number__c))? mapPhoneEP.get(objDoc.PC_To_Fax_Number__c) : null;
                         docToInsert.add(objDoc); 
                         mapDocVsCDL.put(faxRecords.get(objCdl.LinkedEntityId).Id, objCdl); 
                         mapFaxVsDoc.put(objDoc.ACLS_Fax__c, objDoc);
                    }
                }
            }
             if(!docToInsert.isEmpty()){
                if(Schema.sObjectType.PC_Document__c.isCreateable())
                    {
                        Database.insert(docToInsert,False);
                    }             
            } 
             
             List<ContentDocumentLink> cdlLinkToInsert = new List <ContentDocumentLink>();
             for(PC_Document__c document : docToInsert)
             {
                 ContentDocumentLink contentLink = new ContentDocumentLink();
                 contentLink.ContentDocumentId = mapDocVsCDL.get(document.ACLS_Fax__c)?.ContentDocumentId; 
                 contentLink.LinkedEntityId = document.Id;
                 contentLink.ShareType = 'I';
                 contentLink.Visibility = 'AllUsers';
                 cdlLinkToInsert.add(contentLink);
             }
             if(Schema.sObjectType.ContentDocumentLink.isCreateable())
                {
                insert cdlLinkToInsert;
                }         
            }
     
         catch (Exception e) {
             PC_Utility.createExceptionLog(e);   
             for(Id faxId : mapFaxVsDoc.keySet()){
                 if(mapFaxVsDoc.get(faxId)!=null && mapFaxVsDoc.get(faxId).Id == null){
                     exceptionTaskList.add(ACLS_Utility.createTask(ACLS_Constants.INBOUND_FAX_EXCEPTION, ACLS_Constants.INBOUND_FAX_INTEGRATION, ACLS_Constants.INBOUND_FAX_FAX, DATE.today(), ACLS_Constants.ACLS_ADMIN_QUEUE,faxId, 'Error occurred while receiving Fax Communication. Error Message: Failed to create Document record'));
                 }
             }
             if(Schema.sObjectType.Task.isCreateable())
             {
            insert exceptionTaskList;
             }            
         }
     
     }
 }