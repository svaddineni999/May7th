/*********************************************************************************
Class Name      : PC_DocumentTags
Description     : Controller class used for PC_Document_Tags(lightning)
Created By      : Deloitte
Created Date    : October 04, 2019
Modification Log:
----------------------------------------------------------------------------------
Developer              Date                   Description
-----------------------------------------------------------------------------------
Kishore Kanteti      04 October,2019          [PC-5520] Initial Version(Picked it from PC_DocumentManagementLightningController)
Kishore Kanteti 	 10 October,2019		  [PC-5520] Optimised methods at field level to increase performance.
Vijay Kashikar       03 December, 2019        [PC-5751] Added code to get document tags using Salesforce Interface API
Vijay Kashikar       01 July, 2022            [PC-8967] Moved methods related to fetching dependent picklist values using Interface API to PC_Utility to make them resuable
*********************************************************************************/
public with sharing class PC_DocumentTags{

    private static String statusLabel;

    /*********************************************************************************
Method Name    : saveDocumentCategoryV2
Author         : Haritha Reddy
Description    : This method is used to save a category. Logic related to Category list update is moved to front end.
Return Type    : void
Parameter      : Id docId, String selectedCategory
*********************************************************************************/
    @AuraEnabled
    public static void saveDocumentCategoryV2(Id docId, String selectedCategory) {
        try{
            //Create a list of fields to check if user has field level security on PC_Document__c fields
            List<String> fields = new List<String>{'Id', PC_Constants.getQualifiedAPIName('PC_Document_Category__c'),
                    PC_Constants.getQualifiedAPIName('PC_Document_Status__c')};

            //Check if user has access to peform the READ operation
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'),PC_Database.Operation.Reading, fields);

            PC_Document__c oDoc = [SELECT Id,RecordType.DeveloperName, PC_Document_Category__c, PC_Document_Status__c FROM PC_Document__c
            WHERE Id =: docId LIMIT 1];


            if (oDoc.RecordType.DeveloperName != PC_Constants.DOCUMENT_ARTICLE_KNOWLEDGE_RECORD_TYPE) {
                if(oDoc.PC_Document_Status__c == PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED){
                    oDoc.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_IN_REVIEW;
                }
            }
            String sSelectedCategories = oDoc.PC_Document_Category__c;
            Set<String> setSelectedCategories = new Set<String>();
            if (!String.isBlank(sSelectedCategories)) {
                List<String> lstSelectedCategories = sSelectedCategories.split(';');
                setSelectedCategories = new Set<String>(lstSelectedCategories);
                if (setSelectedCategories.contains(selectedCategory)) {
                    setSelectedCategories.remove(selectedCategory);
                } else {
                    setSelectedCategories.add(selectedCategory);
                }
                oDoc.PC_Document_Category__c = String.join(new List<String>(setSelectedCategories), ';');
            } else {
                oDoc.PC_Document_Category__c = selectedCategory;
            }
            PC_Database.upd(oDoc);

        }catch(Exception e) {

            PC_Utility.logAndThrowException(e);
        }
    }
    /*********************************************************************************
Method Name    : getDocRecordForTags
Author         : Vijay Kashikar
Description    : This method is used to get record for the tags in PC_Document_Tags.
Return Type    : void
Parameter      : Id docId
*********************************************************************************/
    @AuraEnabled
    public static DocumentWrapper getDocRecordForTags(Id docId, Boolean useUserInterfaceAPI, String userInterfaceAPINamedCredential) {
        List<PC_PicklistFieldManager.PicklistEntryWrapper> docStatusLabels = PC_PicklistFieldManager.getPicklistEntryWrappers(PC_Document__c.PC_Document_Status__c);
        DocumentWrapper docWrapper = new DocumentWrapper();
        /*
* FLS, additional fields to capture engagement program and manufacturer of the document
* and contructor for docFieldWrapper updated for [PC-1598]
*/
        if (String.isBlank(docId)) return docWrapper;

        try{
            //Create a list of fields to check if user has field level security on PC_Document__c fields
            List<String> fields = new List<String>{'Name', 'OwnerId', 'CreatedDate', PC_Constants.getQualifiedAPIName('PC_Document_Category__c'), PC_Constants.getQualifiedAPIName('PC_Document_Status__c'),
                    PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};


            //Check if user has access to perform the READ operation
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'),PC_Database.Operation.Reading, fields);


            PC_Document__c oDoc = [SELECT Id, Name, RecordType.DeveloperName, toLabel(RecordType.Name), RecordTypeId, PC_Document_Category__c, PC_Document_Status__c,
                    PC_EngagementProgramCode__c
            FROM PC_Document__c
            WHERE Id =: docId LIMIT 1];

            for(PC_PicklistFieldManager.PicklistEntryWrapper pew : docStatusLabels){
                if(pew.value == oDoc.PC_Document_Status__c){
                    statusLabel = pew.label;
                }
            }


            List<DocFieldWrapper> lstDocFields = new List<DocFieldWrapper>();
            lstDocFields.add(new docFieldWrapper(oDoc , statusLabel));
            String sSelectedCategories = oDoc.PC_Document_Category__c;
            List<CategoryWrapper> lstCategories;
            if(useUserInterfaceAPI != null && useUserInterfaceAPI) {
                lstCategories = getTagsUsingInterfaceAPI(docId, userInterfaceAPINamedCredential);
            }
            else {
                lstCategories = getDependentCategories(oDoc.PC_EngagementProgramCode__c,
                        oDoc.RecordTypeId, oDoc.RecordType.DeveloperName);
                if (!String.isBlank(sSelectedCategories)) {
                    List<String> lstSelectedCategories = sSelectedCategories.split(';');
                    Set<String> setSelectedCategories = new Set<String>(lstSelectedCategories);

                    for (CategoryWrapper categ : lstCategories) {
                        if (setSelectedCategories.contains(categ.categoryName)) {
                            categ.isSelected = true;
                            if (categ.categoryLabel == System.Label.PC_Enrollment_Form) {
                                categ.isEnrollmentForm = true;
                            }
                        }
                    }
                }
            }
            docWrapper.lstCategories = lstCategories;
            docWrapper.lstDocFields = lstDocFields;
            docWrapper.document = oDoc;



        }catch(Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return docWrapper;
    }
    /*********************************************************************************
Method Name    : getCategories
Author         : Alina Balan
Description    : This method is used to get all available categories
Return Type    : List<CategoryWrapper>
Parameter      : none
*********************************************************************************/
    @TestVisible
    private static List<CategoryWrapper> getCategories(String docRecordType){
        List<CategoryWrapper> lstCategories = new List<CategoryWrapper>();
        Schema.DescribeFieldResult fieldResult;
        fieldResult = PC_Document__c.PC_Document_Category__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple) {
            CategoryWrapper categWrapper = new CategoryWrapper();
            categWrapper.categoryName = f.getValue();
            categWrapper.categoryLabel = f.getLabel();
            lstCategories.add(categWrapper);
        }
        return lstCategories;
    }

    /*********************************************************************************
Method Name    : getDependentCategories
Author         : Vivek Kumar Mishra
Description    : This method is used to get all available categories based on
Engagement Program Code controlling field value and Record Type used.
Return Type    : List<CategoryWrapper>
Parameter      : String ctrRecord, Id recordTypeId
*********************************************************************************/
    private static List<CategoryWrapper> getDependentCategories(String ctrRecord, Id recordTypeId,String docRecordType){

        List<CategoryWrapper> lstCategories = new List<CategoryWrapper>();
        List<String> controllingEntries = new List<String>();
        Schema.DescribeFieldResult field = PC_Document__c.PC_EngagementProgramCode__c.getDescribe();
        for (Schema.PicklistEntry f : field.getPicklistValues()){
            controllingEntries.add(f.getLabel());
        }
        // In case there is no active picklist value for PC_EngagementProgramCode__c
        if(controllingEntries.isEmpty()){
            return getCategories(docRecordType);
        }
        // In case if PC_EngagementProgramCode__c is set to null for the document record
        // or there is no such active picklist value for PC_EngagementProgramCode__c
        if(ctrRecord==null || !(controllingEntries.contains(ctrRecord))){
            ctrRecord = PC_Constants.PC_NONE;
        }
        // In case if PC_EngagementProgramCode__c is set to None but None picklist value
        // itself is not present/active
        if(ctrRecord == PC_Constants.PC_NONE && !(controllingEntries.contains(PC_Constants.PC_NONE))){
            return getCategories(docRecordType);
        }
        Map<String, String> allowedValues = PC_PicklistFieldManager.picklistRecordTypeFieldList
                (PC_Document__c.PC_EngagementProgramCode__c, PC_Document__c.PC_Document_Category__c,
                        PC_Constants.getQualifiedAPIName('PC_Document__c'), recordTypeId, ctrRecord);
        // Rare scenario, but in case there is no allowed value
        if(allowedValues==null){
            return getCategories(docRecordType);
        }

        for(String key : allowedValues.keySet()) {
            CategoryWrapper categWrapper = new CategoryWrapper();
            categWrapper.categoryName = key;
            categWrapper.categoryLabel = allowedValues.get(key);
            lstCategories.add(categWrapper);
        }
        return lstCategories;
    }

    /*********************************************************************************
Class Name    : CategoryWrapper
Author        : Alina Balan
Description   : Wrapper class for category
*********************************************************************************/
    public class CategoryWrapper {
        @AuraEnabled public String categoryName {get; set;}
        @AuraEnabled public String categoryLabel {get; set;}
        @AuraEnabled public Boolean isSelected {get; set;}
        @AuraEnabled public Boolean isEnrollmentForm {get; set;}
        public CategoryWrapper() {
            isSelected = false;
            isEnrollmentForm = false;
        }
    }



    public class DocFieldWrapper {
        @AuraEnabled public String docID {get;set;}
        @AuraEnabled public String docStatus {get; set;}
        @AuraEnabled public String docStatusLabel {get; set;}



        public DocFieldWrapper(PC_Document__c d, String statusLabel) {
            this.docID = d.Id;
            this.docStatus = d.PC_Document_Status__c;
            this.docStatusLabel = statusLabel;


        }

    }

    public class DocumentWrapper {
        @AuraEnabled public PC_Document__c document {get; set;}
        @AuraEnabled public List<CategoryWrapper> lstCategories {get; set;}
        @AuraEnabled public List<DocFieldWrapper> lstDocFields {get; set;}


        public DocumentWrapper() {
            lstCategories = new List<CategoryWrapper>();
            lstDocFields = new List<DocFieldWrapper>();

        }
    }

    public static List<PC_DocumentTags.CategoryWrapper> getTagsUsingInterfaceAPI(Id recordId, String userInterfaceAPINamedCredential) {
        if(String.isBlank(userInterfaceAPINamedCredential)) {
            DocumentTagsException ex = new DocumentTagsException();
            ex.setMessage('Named Credential Cannot be blank. Please contact your system administrator.');
            throw ex;
        }
        system.debug('document recordId = ' + recordId);

        String objectName = PC_Constants.getQualifiedAPIName('PC_Document__c');
        String controllingField = PC_Constants.getQualifiedAPIName('PC_EngagementProgramCode__c');
        String dependentField = PC_Constants.getQualifiedAPIName('PC_Document_Category__c');

        PC_Document__c currentDocument = [SELECT recordTypeId, PC_EngagementProgramCode__c, RecordType.DeveloperName FROM PC_Document__c WHERE Id = :recordId];
        String recordTypeId = currentDocument.recordTypeId;
        String engagementProgramCode = currentDocument.PC_EngagementProgramCode__c;
        String recordTypeName = currentDocument.RecordType.DeveloperName;

        system.debug('engagementProgramCode=' + engagementProgramCode);
        system.debug('recordTypeName=' + recordTypeName);

        Map<String, String> dependentCategories =
                PC_Utility.getDependentPicklistsUsingAPI(objectName, recordTypeId,  engagementProgramCode, dependentField, userInterfaceAPINamedCredential);

        Map<String, String> currentDocumentCategories =
                PC_Utility.getCurrentPicklistValuesUsingAPI(recordId, dependentField, userInterfaceAPINamedCredential);

        List<PC_DocumentTags.CategoryWrapper> listCategoryWrapper = convertToCategoryWrapper(dependentCategories, currentDocumentCategories);

        return listCategoryWrapper;
    }

    private static List<PC_DocumentTags.CategoryWrapper>  convertToCategoryWrapper(
            Map<String, String> dependentCategories, Map<String, String> currentDocumentCategories) {
        List<PC_DocumentTags.CategoryWrapper> lstCategoryWrapper = new List<PC_DocumentTags.CategoryWrapper>();
        PC_DocumentTags.CategoryWrapper categoryWrapper;
        String label;
        for(String key : dependentCategories.keyset()) {
            categoryWrapper = new PC_DocumentTags.CategoryWrapper();
            label = dependentCategories.get(key);
            categoryWrapper.categoryLabel = label;
            categoryWrapper.categoryName = key;
            if(currentDocumentCategories.containsKey(key)) {
                categoryWrapper.isSelected = true;
                if(label == System.Label.PC_Enrollment_Form) {
                    categoryWrapper.isEnrollmentForm = true;
                }
            }
            lstCategoryWrapper.add(categoryWrapper);
        }
        return lstCategoryWrapper;
    }

    private class DocumentTagsException extends Exception {}

}