/*********************************************************************************
Class Name      : PC_DocumentManagement_DocumentDetails
Description     : Controller class used for PC_Document_Management_Document_Details (lightning)
Created By      : Deloitte
Created Date    : October 04, 2019
Modification Log:
----------------------------------------------------------------------------------
Developer              Date                   Description
-----------------------------------------------------------------------------------
Kishore Kanteti      October 04, 2019         [PC-5514] Initial Version(Picked it from PC_DocumentManagementLightningController)
Kishore Kanteti 	 October 15,2019		  [PC-5514] Optimised methods at field level to increase performance.
Satheesh Kumar  	 23-Jul-2020		      [PC-6483] Included PC_Document_Name__c field in getDocRecordForDetails SOQL query.
*********************************************************************************/
public with sharing class PC_DocumentManagement_DocumentDetails {

    private static String statusLabel;

    /*********************************************************************************
    Method Name    : getDocRecordForDetails
    Description    : This method retrieve init data from the database.
    Return Type    : DocumentWrapper
    Parameter      : Id docId
    *********************************************************************************/

    @AuraEnabled
    public static DocumentWrapper getDocRecordForDetails(Id docId) {
        List<PC_PicklistFieldManager.PicklistEntryWrapper> docStatusLabels = PC_PicklistFieldManager.getPicklistEntryWrappers(PC_Document__c.PC_Document_Status__c);
        DocumentWrapper docWrapper = new DocumentWrapper();
        /*
         * FLS, additional fields to capture engagement program and manufacturer of the document
         * and contructor for docFieldWrapper updated for [PC-1598]
         */
        if (String.isBlank(docId)) return docWrapper;

        try {
            //Create a list of fields to check if user has field level security on PC_Document__c fields
            List<String> fields = new List<String>{
                    'Name', PC_Constants.getQualifiedAPIName('PC_Document_Status__c'), PC_Constants.getQualifiedAPIName('PC_Document_Name__c')
            };

            //Check if user has access to perform the READ operation
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, fields);

            PC_Document__c oDoc = [
                    SELECT Name, RecordType.DeveloperName, toLabel(RecordType.Name), RecordTypeId,
                            PC_Document_Status__c, PC_Document_Name__c
                    FROM PC_Document__c
                    WHERE Id = :docId
                    LIMIT 1
            ];

            for (PC_PicklistFieldManager.PicklistEntryWrapper pew : docStatusLabels) {
                if (pew.value == oDoc.PC_Document_Status__c) {
                    statusLabel = pew.label;
                }
            }

            List<DocFieldWrapper> lstDocFields = new List<DocFieldWrapper>();

            DocFieldWrapper wrapper = new DocFieldWrapper();
            wrapper.docID = oDoc.Id;
            wrapper.docStatusLabel = statusLabel;

            lstDocFields.add(wrapper);
            docWrapper.lstDocFields = lstDocFields;
            docWrapper.document = oDoc;

        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return docWrapper;
    }


    /*********************************************************************************
    Method Name    : getFields
    Author         : Tejas Patel
    Description    : This method is used for getting the fields of the document
    Return Type    : DocumentWrapper
    Parameter      : Id docId
    *********************************************************************************/
    @AuraEnabled
    public static List<PC_FieldSet.FieldSet> getFields(String typeName, String fsName, Id recordId) {
        List<PC_FieldSet.FieldSet> fieldSet = new List<PC_FieldSet.FieldSet>();
        fieldSet = PC_FieldSet.getFields(typeName, fsName, recordId);
        return fieldSet;
    }


    /*********************************************************************************
    Method Name    : fieldSetName
    Author         : Ajinkya Deshmukh
    Description    : This method will update document object when illegible button is clicked
    Return Type    : String
    Parameter      : Id docId
    *********************************************************************************/
    @AuraEnabled
    public static String fieldSetName(Id docId) {
        String fieldSetName = PC_Constants.FALSE_STRING;

        try {

            if (docId != null) {

                //FLS Check for PC_Document__c
                List<String> fields = new List<String>{'Id','RecordType'};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, fields);
                PC_Document__c getRecordTypeName = [SELECT Id, RecordType.DeveloperName, RecordType.NamespacePrefix FROM PC_Document__c WHERE Id = :docId];
                String recTypeName = getRecordTypeName.RecordType.DeveloperName;
                String recTypeNamespace = getRecordTypeName.RecordType.NamespacePrefix;

                List <PC_DocumentDetails_FieldSet__mdt> docDetailFieldSet = [SELECT PC_FieldSetName__c FROM PC_DocumentDetails_FieldSet__mdt WHERE PC_Document_RecordType__c = :recTypeName AND PC_Document_RecordType_Namespaceprefix__c = :recTypeNamespace];
                if (docDetailFieldSet.size() > 0) {
                    fieldSetName = docDetailFieldSet[0].PC_FieldSetName__c;
                }

            }
        } catch (Exception e) {
            PC_Utility.createExceptionLog(e);

        }
        return fieldSetName;
    }


    public class DocFieldWrapper {
        @AuraEnabled public String docID { get; set; }
        @AuraEnabled public String docStatusLabel { get; set; }
        public DocFieldWrapper() {

        }
    }

    public class DocumentWrapper {
        @AuraEnabled public PC_Document__c document { get; set; }
        @AuraEnabled public List<DocFieldWrapper> lstDocFields { get; set; }
        public DocumentWrapper() {

            lstDocFields = new List<DocFieldWrapper>();

        }
    }
}