/****************************************************************************************************************************************************
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Deloitte                    Feb 1, 2018		           Initial Version
Vijay Kashikar              Mar 26, 2019               [PC-4666] Update getDocRecord to retrieve the label values instead of API value.
****************************************************************************************************************************************************/

/**
 * Controller for PC_Document_Management_ChangeStatus.
 */

public class PC_ChangeStatusLightningController {


    public class picklistWrapper {
        @AuraEnabled
        public String strValue {get;set;}
        @AuraEnabled
        public String strLabel {get;set;}

        public picklistWrapper(String strValue, String strLabel) {
            this.strValue = strValue;
            this.strLabel = strLabel;
        }
    }

 
    @AuraEnabled
    public static List<picklistWrapper> getRecTypeBasedPicklistValues( String sobjectType, String pickListFieldAPIName, Id docId) {
        
        DocumentWrapper dw = getDocRecord(docId);
        Id recordTypeId = dw.document.recordTypeId;
        //List<String> options = PC_PicklistFieldManager.describe(sobjectType,recordTypeId,pickListFieldAPIName);
        //return options;
        //Vivek K Mishra : Added namespace changes PC-3138
        String ns = PC_Constants.OrgNamespace;
        if(!String.isBlank(ns)){
            ns = ns+'__';
            if(!sobjectType.contains(ns)){
                sobjectType = ns+sobjectType;
            }
            if(!pickListFieldAPIName.contains(ns)){
                pickListFieldAPIName = ns+pickListFieldAPIName;
            }
        }
        Map<String, String> options = PC_PicklistDescriber.describeAsMap(sobjectType, recordTypeId, pickListFieldAPIName);
        
        List<picklistWrapper> pickList = new List<picklistWrapper>();
        for (String key : options.keySet()) {
            pickList.add(new picklistWrapper(key, options.get(key)));
        }
        system.debug(pickList);
        return pickList;
        
    }
    @AuraEnabled
    public static DocumentWrapper updateDocumentStatus(Id docId, String status) {
        String newStatus = status;
        DocumentWrapper docWrapper;
        try {
            if (status == PC_Constants.PC_NONE_LC) {
                newStatus = PC_Constants.EMPTY_STRING;
            } else {
                newStatus = status;
            }

            docWrapper = getDocRecord(docId);
            //check if the status is already the current status
            if (docWrapper.document.docStatus != newStatus) {
                DocWrapper doc = updateDocStatus(docWrapper.document, newStatus);
                docWrapper.document = doc;
            }
        }
        catch(Exception ex){
            throw ex;
        }
        return docWrapper;
    }

    /*********************************************************************************
  Method Name    : updateDocStatus
  Author         : Tetiana Danylyshyn
  Description    : This method is used to update the document status with the status sent as param
  Return Type    : PC_Document__c
  Parameter      : PC_Document__c doc, String status, String sUserName
  *********************************************************************************/
    public static DocWrapper updateDocStatus(DocWrapper doc, String status) {

        try {

            PC_Document__c docu = new PC_Document__c();

            docu.Id=doc.docId;
            docu.PC_Document_Status__c=status;



            PC_Database.upd(docu, true);
            doc.docStatus=status;
          
        } catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return doc;
    }


    public class DocumentWrapper {
        @AuraEnabled public DocWrapper document {get; set;}
  
        @AuraEnabled public Id loggedInUserId {get { return userinfo.getUserId();}}
        @AuraEnabled public Boolean loadFaxContainer {get; set;}
        @AuraEnabled public Boolean loadEmailContainer {get; set;}

        public DocumentWrapper() {
          

        }
    }
    public class DocWrapper {


        @AuraEnabled public Id docId {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String docStatus {get; set;}
        @AuraEnabled public Id recordTypeId {get; set;}


        public DocWrapper(PC_Document__c doc) {

            this.docId =doc.Id;
            this.docStatus = doc.PC_Document_Status__c;
            this.name = doc.Name;
            this.recordTypeId = doc.RecordTypeId;
        }
    }

    @AuraEnabled
    public static DocumentWrapper getDocRecord(Id docId) {
       
        DocumentWrapper docWrapper = new DocumentWrapper();
        DocWrapper docu ;
        /*
         * FLS, additional fields to capture engagement program and manufacturer of the document
         * and contructor for docFieldWrapper updated for [PC-1598]
         */
        if (String.isBlank(docId)) return docWrapper;

        try{
            //Create a list of fields to check if user has field level security on PC_Document__c fields
            List<String> fields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_Document_Status__c')};

            //Check if user has access to peform the READ operation
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'),PC_Database.Operation.Reading, fields);

            PC_Document__c oDoc = [SELECT Id, Name, RecordTypeId, toLabel(PC_Document_Status__c) FROM PC_Document__c
            WHERE Id =: docId ];


            docu=new DocWrapper(oDoc);
            docWrapper.document=docu;

      
        }catch(Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return docWrapper;
    }
}