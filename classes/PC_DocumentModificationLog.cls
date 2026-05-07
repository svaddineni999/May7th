/*********************************************************************************
Class Name      : PC_DocumentModificationLog
Description     : Controller class used for PC_Document_Modification_Log(lightning)
Created By      : Deloitte
Created Date    : October 04, 2019
Modification Log:
----------------------------------------------------------------------------------
Developer              Date                   Description
-----------------------------------------------------------------------------------
Kishore Kanteti      04 October,2019          [PC-5518] Initial Version(Picked it from PC_DocumentManagementLightningController)
Kishore Kanteti 	 11 October,2019		  [PC-5518] Removed methods that are not used for document modification log.
Hitha Avalakki       12 November,2019         [PC-5715] Added logic to display only those records of the Adverse Event object configured in the custom metadata in Link Log section
Shishir Bansal        06-Dec-2019             [PC-5792] Avoid hardcoding of string variable
Satheesh Kumar       17-Jun-2020              [PC-6461] Added try catch in getModificationLogs inside for loop to handle when invalid data is given in the PC_Association_Record_Id__c field
Haritha Reddy         21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/
public with sharing class PC_DocumentModificationLog {

/*********************************************************************************
Method Name    : getModificationLogs
Author         : Alina Balan
Description    : Get all document logs for the current document
Return Type    : List<PC_Document_Log__c>
Parameter      : Id docId
*********************************************************************************/
    @AuraEnabled
    public static DocLogAndDescWrapper getModificationLogs(Id docId) {

        //PC-4608: Code to fetch the condition required to display PC_Document_Log__c field value on UI
        DocLogAndDescWrapper docLogAndDescWrapper=new DocLogAndDescWrapper();
        String patientConnectSettingValue = PC_Constants.EMPTY_STRING;
        List<DocLogWrapper> lstDocLogWrapper = new List<DocLogWrapper>();
        List<String> missingInfoDocLogs = new List<String>();
        String adverseEventObjectNotInUse =PC_Constants.EMPTY_STRING;

        patientConnectSettingValue=  PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_SHOW_DOC_LOG_AND_DESCRIPTION,PC_Constants.FALSE_STRING);

        try {
            //[PC-5715]: Get the label of the Adverse Event object which we need to exclude in the Link Log section
            adverseEventObjectNotInUse = PC_DocumentManagementHelper.getAdverseEventObjectAPINameNotInUse();

            //PC-4608: Code to fetch the condition required to display PC_Document_Log__c field value on UI

            if(!String.isBlank(patientConnectSettingValue) && PC_Constants.TRUE_STRING.equalsIgnoreCase(patientConnectSettingValue)){
                docLogAndDescWrapper.showDocumentLogFieldVal=true;
            }

            //Create a list of fields to check if user has field level security on PC_Document_Log__c fields
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Document_Log__c'), PC_Constants.getQualifiedAPIName('PC_Program__c'), 'LastModifiedBy', 'LastModifiedDate', PC_Constants.getQualifiedAPIName('PC_Association_Record_Id__c'), PC_Constants.getQualifiedAPIName('PC_Association_Type__c'), PC_Constants.getQualifiedAPIName('PC_Association_Record_Name__c')
                    ,PC_Constants.getQualifiedAPIName('PC_Document__c')};
            //Check if user has access to perform the READ operation
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'),PC_Database.Operation.Reading, fields);

            List<PC_Document_Log__c> lstDocLogs = [
                    SELECT Name, PC_Document_Log__c, PC_Program__c, LastModifiedBy.Name, LastModifiedDate, PC_Association_Record_Id__c, PC_Association_Type__c, PC_Association_Record_Name__c
                    FROM PC_Document_Log__c
                    WHERE PC_Document__c = :docId
                    ORDER BY LastModifiedDate DESC
            ];

            for(PC_Document_Log__c l : lstDocLogs) {
                String sObjectAPIName = PC_Constants.EMPTY_STRING;
                if(!String.isBlank(l.PC_Association_Record_Id__c)){
                    try {
                        sObjectAPIName = String.valueOf(Id.valueOf(l.PC_Association_Record_Id__c).getSobjectType());
                    }
                    catch(exception e) {
                        PC_Utility.publishErrorLog(e, 'The value in field PC_Association_Record_Id__c is invalid for :'+l.Name);
                        l.PC_Association_Record_Id__c = PC_Constants.EMPTY_STRING;
                    }
                    //[PC-5715]: The following ternary operator will take care of org namespace for Patient Connect and Client defined custom objects alongwith standard objects
                    String sObjectAPINameToCompare = sObjectAPIName.contains('__') ? (sObjectAPIName.countMatches('__') == 2 ? sObjectAPIName.substringAfter('__') : sObjectAPIName)
                        : sObjectAPIName;

                    //[PC-5715]: Added logic to display only those records of the Adverse Event object configured in the custom metadata
                    if(!String.isBlank(adverseEventObjectNotInUse) && !sObjectAPINameToCompare.toLowerCase().equals(adverseEventObjectNotInUse)){
                        lstDocLogWrapper.add(new DocLogWrapper(l));
                    }
                }else{
                    missingInfoDocLogs.add(l.Name);
                }
            }

            //PC-4608: Code to fetch the condition required to display PC_Document_Log__c field value on UI
            docLogAndDescWrapper.documentLogWrapperList.addAll(lstDocLogWrapper);
            if(!missingInfoDocLogs.isEmpty()){
                DocumentLogsException en = new DocumentLogsException();
                en.setMessage('The field PC_Association_Record_Id__c is missing for : '+missingInfoDocLogs);
                throw en;
            }
        }
        catch(DocumentLogsException e) {
            PC_Utility.createExceptionLog(e);
        }
        catch(exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return docLogAndDescWrapper;
    }

    private inherited sharing class DocumentLogsException extends Exception {}


/*********************************************************************************
Class Name    : DocumentWrapper
Author        : Alina Balan
Description   : Wrapper class for document
*********************************************************************************/
    public inherited sharing class DocLogWrapper {
        @AuraEnabled public String docLog {get;set;}
        @AuraEnabled public String program {get; set;}
        @AuraEnabled public String associationRecordId {get; set;}
        @AuraEnabled public String associationType {get; set;}
        @AuraEnabled public String associationRecordName {get; set;}
        @AuraEnabled public String lastModifiedName {get; set;}
        @AuraEnabled public DateTime lastModifiedDate {get; set;}
        @AuraEnabled public String objectName {get; set;}

        public DocLogWrapper(PC_Document_Log__c d) {
            this.docLog = d.PC_Document_Log__c;
            this.program = d.PC_Program__c;
            this.associationRecordId = d.PC_Association_Record_Id__c;
            this.associationType = d.PC_Association_Type__c;
            this.associationRecordName = d.PC_Association_Record_Name__c;
            this.lastModifiedName = d.LastModifiedBy.Name;
            this.lastModifiedDate = d.LastModifiedDate;
            this.objectName = '';
            if(d.PC_Association_Record_Id__c != null){
                this.objectName = ((Id)d.PC_Association_Record_Id__c).getSObjectType().getDescribe().getName();
            }
        }
    }

/*********************************************************************************
Class Name    : DocLogWrapper
Author        : Hitha Avalakki
User-Story    : PC-4608
Description   : Wrapper class for document logs list and boolean value to display Document Log
*********************************************************************************/
    public inherited sharing class DocLogAndDescWrapper{
        @AuraEnabled public Boolean showDocumentLogFieldVal{get;set;}
        @AuraEnabled public Boolean isCommunity{get;set;}
        @AuraEnabled public List<DocLogWrapper> documentLogWrapperList{get;set;}

        public DocLogAndDescWrapper(){
            showDocumentLogFieldVal=false;
            Id siteId = Site.getSiteId();
            if (siteId != null){
                isCommunity = true;
            }else{
                isCommunity = false;
            }
            documentLogWrapperList=new List<DocLogWrapper>();
        }
    }
}