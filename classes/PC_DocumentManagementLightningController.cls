/*********************************************************************************
Class Name      : PC_DocumentManagementLightningController
Description     : Controller class used for PC_Document_Management (lightning)
Created By      : Deloitte               
Created Date    : June 08, 2016
Modification Log:
---------------------------------------------------------------------------------- 
Developer              Date                   Description
-----------------------------------------------------------------------------------            
Tetiana Danylyshyn    June 08, 2016          Initial Version
Alina Balan           June 16, 2016          Code Refactoring
Shabda Bhujad,        Nov 3, 2016            Removed PC_Article_Effective_Date__c, PC_Article_Reference_No__c, PC_Article_Retirement_Date__c, PC_Article_Title__c field(Document Object)references annotated by @@RemoveArtRef
Prachi Nandgaonkar
Mayuresh Patil        Dec 09,2016            Added FLS check to getDocRecord(), changeDocumentOwnerToCurrentUser(), updateDocumentOwner(), archiveDocumentFax()
                                             searchForPatient(), getModificationLogs(), updateReportSpam(), saveDocumentCategory() methods
Shabda Bhujad		  13-Jan-17 			 Added Parent Document Id and Parent Document Name to provide the link to Parent doc from child document to getDocRecord()
Prachi Nandgaonkar	  17-Jan-17 			 Added Parent Document Id and Parent Document Name to use the updated wrapper above to saveDocumentCategory()
Prachi Nandgaonkar    24-Jan-17              Updated searchPatient() to search all Accounts (PC-549)
Prachi Nandgaonkar    26-Jan-17              Added fields From Fax, From Name and From Email to document wrapper and query to show under Document Details (PC-864)
Ajinkya Deshmukh	  26-Jan-17				 Added method accountRecordTypes() to get the List of record Types for Account
Prachi Nandgaonkar    26-Jan-17              Added fields to search table for document linking PC-847
Shabda Bhujad 		  30-Jan-17				 Updated createDocumentLog method with the code to change status to 'In Review' when document is linked
Shabda Bhujad		  07-Feb-17				 Removed docId parameter from getRecordTypeForAccount()
Shabda Bhujad		  13-Feb-17				 Added FLS check to createDocumentLog()
Ajinkya Deshmukh	  03-Apr-17				 Added reportComplete() for PC-1342
Mayuresh Patil		  03-Apr-17				 Updated to remove SOSL dependency on field set. SOSL cannot contain encrypted fields in the where clause.
Shabda Bhujad		  17-May-17				 [PC-1616] Added a condition to set the loadFaxContainer variable true for FAX OUTBOUND Documents
Shabda Bhujad		  26-May-17				 [PC-1598] Added the Manufacturer,docEngagementProgId (5/30) field to DocFieldWrapper, modified the doc query to pull it and logic to search the results relevant to Manufacturer
Prachi Nandgaonkar    30-May-17              [PC-1339] Replaced label for Enrollment Form with a constant to enable translation
Shabda Bhujad		  02-June-17 			 [PC-864] Added missing FLS check for 
Shabda Bhujad		  05-June-2017			 [PC-1664] Rollback the changes done for [PC-1339]
Ajinkya Deshmukh	  June 8, 2017			 FLS Check Updated
Shabda Bhujad		  22-June-2017			 [PC-1795] Excluding non-patient accounts from search for engagement program
Mayuresh Patil        26-June-2017           [PC-1667] Updated code to display the email attachment document using the fax viewer
                                             and the issue with the display of engagement program name on the document viewer document details section.
Mayuresh Patil        27-June-2017           [PC-1669] Child Doc or email attachments should not appear in the split section since they are attachments of the email.
Tejas Patel           July 25 2017           [PC-1927],[PC-1928],[PC-1918] Translation Issues
Mayuresh Patil        July 26,2017           Additional FLS Check Added
Mayuresh Patil        Aug 28,2017            Merged PC30 changes into PC303 version and updated FLS checks to the updated code
Mayuresh Patil        Nov 1, 2017            Removed changing doc owner to currentuser as part of getDocRecord method
Tejas Patel			  Nov 10,2017			 New avriable using custom label "accountLabel"
Tejas Patel           Jan 12,2018            [PC-2641] Removed the default fieldset value
Prachi Nandgaonkar    Jan 24, 2018           [PC-2565] Updated getDocRecord() to fetch document's record type name to show in UI
Vijay Kashikar        Sep 09, 2018           [PC-3526 Render Document Previewer based on content type making it independent of the record type of document.
Hitha Avalakki        Mar 15, 2019           [PC-4608] Code to fetch document logs list and the condition required to display PC_Document_Log__c field value on UI
Vijay Kashikar        Mar 26, 2019           [PC-4666] Updated getDependentCategories to return a map of picklist api and label
Hitha Avalakki        May 31, 2019           [PC-4763] Redesigned the logic in order to fetch account record types from active PC_Document_Link_Related_Object_Setting__mdt custom metadata records for document linking
Haritha Reddy         Jun 18, 2019           [PC-4912] Updated Change Owner logic to support Files
Tushar Arora          Aug 06,2019            [PC-5242] Updated the Code for Document Link Search functionality for Person Account Patients with Engagement Program.
Tushar Arora          13-Aug-2019           [PC-5308] Updated Query from small 'or' to 'OR'.
Haritha Reddy         Sep 04, 2019           [PC-5384] Updated saveDocumentCategory method to improve performance by moving category list update part to front end.
Hitha Avalakki        Sep 05, 2019           [PC-5415] Updated accountRecordTypes method to include custom record types of Account in managed package environments.
Vijay Kashikar        Sep 10, 2019           [PC-5437] Created new aura enabled methods to improve performance during page load.
Haritha Reddy         Sep 25, 2019           [PC-5416] Updated searchForPatient to search for Accounts of only configured Record types when All option is selected.
Vijay Kashikar        Sep 10, 2019           [PC-5437] Created new aura enabled methods to improve performance during page load.
Kanteti Kishore 	  Oct 17, 2019			 [PC-5513] Commented out getDocRecordForDetails,getDocRecordForTags,saveDocumentCategoryV2 as these methods are not used in the
											 PC_Document_Management Component.
Hitha Avalakki        Nov 12, 2019           [PC-5715] Added logic to display only those records of the Adverse Event object configured in the custom metadata in Link Log section
Satheesh Kumar        Oct 12, 2022           [PC-9262] Added condition to avoid removing namespace prefix from sObject when sobject contains no namespace.
*********************************************************************************/
public with sharing class PC_DocumentManagementLightningController {

    //private static List<PC_PicklistFieldManager.PicklistEntryWrapper> docStatusLabels = PC_PicklistFieldManager.getPicklistEntryWrappers(PC_Document__c.PC_Document_Status__c);
    private static String statusLabel;
    private static List<RecordType> recTypeLabels = PC_SYSTEM.getAllRecordType(PC_Constants.PC_ACCOUNT);
    private static String recTypeLabel;
    private static String accountLabel = System.Label.PC_Account;

    /*********************************************************************************
    Method Name    : getDocRecord
    Description    : This method retrieve init data from the database.
    Return Type    : DocumentWrapper
    Parameter      : Id docId
    *********************************************************************************/
    @AuraEnabled
    public static DocumentWrapper getDocRecord(Id docId) {
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
                    'Name', 'OwnerId', 'CreatedDate', PC_Constants.getQualifiedAPIName('PC_Document_Category__c'), PC_Constants.getQualifiedAPIName('PC_Document_Status__c'),
                    PC_Constants.getQualifiedAPIName('PC_Parent_Document__c'), PC_Constants.getQualifiedAPIName('PC_Archived_On__c'),
                    PC_Constants.getQualifiedAPIName('PC_Archived_By__c'), PC_Constants.getQualifiedAPIName('PC_Marked_Spam_By__c'),
                    PC_Constants.getQualifiedAPIName('PC_From_Fax_Number__c'), PC_Constants.getQualifiedAPIName('PC_From_Email_Address__c'),
                    PC_Constants.getQualifiedAPIName('PC_From_Name__c'), PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'),
                    PC_Constants.getQualifiedAPIName('PC_IsSplit__c'), PC_Constants.getQualifiedAPIName('PC_Marked_Spam_On__c')
            };

            //Check if user has access to perform the READ operation
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, fields);

            //List<String> attachmentFields = new List<String> {'Id', 'ContentType'};
            //PC_Database.assertAccess('Attachments',PC_Database.Operation.Reading, attachmentFields); // haven't done Attachments' FLS here since it was leading to error.

            PC_Document__c oDoc = [
                    SELECT Id, Name, RecordType.DeveloperName, toLabel(RecordType.Name), RecordTypeId, PC_Document_Category__c, PC_Document_Status__c, PC_IsSplit__c,
                            PC_Parent_Document__c, PC_Parent_Document__r.Name, OwnerId, PC_From_Fax_Number__c,
                            PC_Archived_On__c, PC_Archived_By__r.Name, PC_Marked_Spam_By__r.Name, PC_Marked_Spam_On__c,
                            PC_From_Email_Address__c, PC_From_Name__c, CreatedDate, PC_Engagement_Program__c, PC_EngagementProgramCode__c, PC_Engagement_Program__r.Name,
                            PC_Engagement_Program__r.PC_Manufacturer__c, PC_Engagement_Program__r.PC_Manufacturer__r.Name
                    FROM PC_Document__c
                    WHERE Id = :docId
                    LIMIT 1
            ];

            for (PC_PicklistFieldManager.PicklistEntryWrapper pew : docStatusLabels) {
                if (pew.value == oDoc.PC_Document_Status__c) {
                    statusLabel = pew.label;
                }
            }

            List<CategoryWrapper> lstCategories = getDependentCategories(oDoc.PC_EngagementProgramCode__c,
                    oDoc.RecordTypeId, oDoc.RecordType.DeveloperName);
            List<DocFieldWrapper> lstDocFields = new List<DocFieldWrapper>();
            lstDocFields.add(new docFieldWrapper(oDoc, statusLabel));
            String sSelectedCategories = oDoc.PC_Document_Category__c;
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
            docWrapper.lstCategories = lstCategories;
            docWrapper.lstDocFields = lstDocFields;
            docWrapper.document = oDoc;

            /*if(oDoc.RecordType.DeveloperName.equalsIgnoreCase(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE)
                || oDoc.RecordType.DeveloperName.equalsIgnoreCase(PC_Constants.DOCUMENT_FAX_OUTBOUND_RECORD_TYPE)
                || oDoc.RecordType.DeveloperName.equalsIgnoreCase(PC_Constants.DOCUMENT_SMARTFORM_RECORD_TYPE)
                || oDoc.RecordType.DeveloperName.equalsIgnoreCase(PC_Constants.DOCUMENT_ARTICLE_KNOWLEDGE_RECORD_TYPE)
                || oDoc.RecordType.DeveloperName.equalsIgnoreCase(PC_Constants.DOCUMENT_MANUALY_UPLOADED)
                || oDoc.RecordType.DeveloperName.equalsIgnoreCase(PC_Constants.DOCUMENT_EMAIL_ATTACHMENT_RECORD_TYPE)){
                docWrapper.loadFaxContainer = true;
            } else if(oDoc.RecordType.DeveloperName.equalsIgnoreCase(PC_Constants.DOCUMENT_EMAIL_INBOUND_RECORD_TYPE)
                      || oDoc.RecordType.DeveloperName.equalsIgnoreCase(PC_Constants.DOCUMENT_EMAIL_OUTBOUND_RECORD_TYPE)){
                docWrapper.loadEmailContainer = true;
            }*/
            docWrapper.loadFaxContainer = false;
            docWrapper.loadEmailContainer = true;

        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return docWrapper;
    }

    /*
    * Method to get document record when called from PC_Document_Tags.cmp
     */
    /* @AuraEnabled
     public static DocumentWrapper getDocRecordForTags(Id docId) {
         List<PC_PicklistFieldManager.PicklistEntryWrapper> docStatusLabels = PC_PicklistFieldManager.getPicklistEntryWrappers(PC_Document__c.PC_Document_Status__c);
         DocumentWrapper docWrapper = new DocumentWrapper();
         /*
          * FLS, additional fields to capture engagement program and manufacturer of the document
          * and contructor for docFieldWrapper updated for [PC-1598]
          *
         if (String.isBlank(docId)) return docWrapper;

         try{
             //Create a list of fields to check if user has field level security on PC_Document__c fields
             List<String> fields = new List<String>{'Name', 'OwnerId', 'CreatedDate', PC_Constants.getQualifiedAPIName('PC_Document_Category__c'), PC_Constants.getQualifiedAPIName('PC_Document_Status__c'),
                     PC_Constants.getQualifiedAPIName('PC_Parent_Document__c'), PC_Constants.getQualifiedAPIName('PC_Archived_On__c'),
                     PC_Constants.getQualifiedAPIName('PC_Archived_By__c'), PC_Constants.getQualifiedAPIName('PC_Marked_Spam_By__c'),
                     PC_Constants.getQualifiedAPIName('PC_From_Fax_Number__c'), PC_Constants.getQualifiedAPIName('PC_From_Email_Address__c'),
                     PC_Constants.getQualifiedAPIName('PC_From_Name__c'), PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'),
                     PC_Constants.getQualifiedAPIName('PC_IsSplit__c'),PC_Constants.getQualifiedAPIName('PC_Marked_Spam_On__c'),
                     PC_Constants.getQualifiedAPIName('PC_Attachment_Id__c')};

             //Check if user has access to perform the READ operation
             PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'),PC_Database.Operation.Reading, fields);

             //List<String> attachmentFields = new List<String> {'Id', 'ContentType'};
             //PC_Database.assertAccess('Attachments',PC_Database.Operation.Reading, attachmentFields); // haven't done Attachments' FLS here since it was leading to error.

             PC_Document__c oDoc = [SELECT Id, Name, RecordType.DeveloperName, toLabel(RecordType.Name), RecordTypeId, PC_Document_Category__c, PC_Document_Status__c, PC_IsSplit__c,
                     PC_Parent_Document__c, PC_Parent_Document__r.Name, OwnerId, PC_Attachment_Id__c, PC_From_Fax_Number__c,
                     PC_Archived_On__c, PC_Archived_By__r.Name, PC_Marked_Spam_By__r.Name, PC_Marked_Spam_On__c,
                     PC_From_Email_Address__c, PC_From_Name__c, CreatedDate, PC_Engagement_Program__c, PC_EngagementProgramCode__c, PC_Engagement_Program__r.Name,
                     PC_Engagement_Program__r.PC_Manufacturer__c,   PC_Engagement_Program__r.PC_Manufacturer__r.Name,
             (Select Id, ContentType from Attachments)
             FROM PC_Document__c
             WHERE Id =: docId LIMIT 1];

             for(PC_PicklistFieldManager.PicklistEntryWrapper pew : docStatusLabels){
                 if(pew.value == oDoc.PC_Document_Status__c){
                     statusLabel = pew.label;
                 }
             }

             List<CategoryWrapper> lstCategories = getDependentCategories(oDoc.PC_EngagementProgramCode__c,
                     oDoc.RecordTypeId, oDoc.RecordType.DeveloperName);
             List<DocFieldWrapper> lstDocFields = new List<DocFieldWrapper>();
             lstDocFields.add(new docFieldWrapper(oDoc , statusLabel));
             String sSelectedCategories = oDoc.PC_Document_Category__c;
             if (!String.isBlank(sSelectedCategories)) {
                 List<String> lstSelectedCategories = sSelectedCategories.split(';');
                 Set<String> setSelectedCategories = new Set<String>(lstSelectedCategories);
                 for (CategoryWrapper categ : lstCategories) {
                     if (setSelectedCategories.contains(categ.categoryName)) {
                         categ.isSelected = true;
                         if (categ.categoryLabel == System.Label.PC_Enrollment_Form){
                             categ.isEnrollmentForm = true;
                         }
                     }
                 }
             }
             docWrapper.lstCategories = lstCategories;
             docWrapper.lstDocFields = lstDocFields;
             docWrapper.document = oDoc;

             docWrapper.loadFaxContainer = false;
             docWrapper.loadEmailContainer = true;

         }catch(Exception e) {
             PC_Utility.logAndThrowException(e);
         }
         return docWrapper;
     }*/

    /*
    * Method to get document record when called from PC_Document_Management_Document_Details.cmp
     */
    /*   @AuraEnabled
       public static DocumentWrapper getDocRecordForDetails(Id docId) {
           List<PC_PicklistFieldManager.PicklistEntryWrapper> docStatusLabels = PC_PicklistFieldManager.getPicklistEntryWrappers(PC_Document__c.PC_Document_Status__c);
           DocumentWrapper docWrapper = new DocumentWrapper();
           *
            * FLS, additional fields to capture engagement program and manufacturer of the document
            * and contructor for docFieldWrapper updated for [PC-1598]
            *
           if (String.isBlank(docId)) return docWrapper;

           try{
               //Create a list of fields to check if user has field level security on PC_Document__c fields
               List<String> fields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_Document_Status__c')};

               //Check if user has access to perform the READ operation
               PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'),PC_Database.Operation.Reading, fields);

               //List<String> attachmentFields = new List<String> {'Id', 'ContentType'};
               //PC_Database.assertAccess('Attachments',PC_Database.Operation.Reading, attachmentFields); // haven't done Attachments' FLS here since it was leading to error.

               PC_Document__c oDoc = [SELECT Name, RecordType.DeveloperName, toLabel(RecordType.Name), RecordTypeId,
                       PC_Document_Status__c
               FROM PC_Document__c
               WHERE Id =: docId LIMIT 1];

               for(PC_PicklistFieldManager.PicklistEntryWrapper pew : docStatusLabels){
                   if(pew.value == oDoc.PC_Document_Status__c){
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

           }catch(Exception e) {
               PC_Utility.logAndThrowException(e);
           }
           return docWrapper;
       }*/

    /*********************************************************************************
    Method Name    : changeDocumentOwner
    Author         : Alina Balan
    Description    : This method changes the doc owner to current user
    Return Type    : DocumentWrapper
    Parameter      : Id docId
    *********************************************************************************/
    @AuraEnabled
    public static DocumentWrapper changeDocumentOwner(Id docId) {
        DocumentWrapper docWrapper = getDocRecord(docId);
        //check if the owner is already the current user
        if (docWrapper.document.OwnerId != UserInfo.getUserId()) {
            PC_Document__c doc = updateDocumentOwner(docWrapper.document, Userinfo.getUserId(), userinfo.getName());
            docWrapper.document = doc;
        }
        return docWrapper;
    }

    /*********************************************************************************
    Method Name    : getFields
    Author         : Tejas Patel
    Description    : This method changes the doc owner to current user
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
    Method Name    : accountRecordTypes
    Author         : Ajinkya Deshmukh
    Description    : This method returns the account RT as a picklist
    Return Type    : List<RecordType>
    Parameter      :
    User Story     : PC-4763
    *********************************************************************************/
    @AuraEnabled
    public static List<RecordType> accountRecordTypes() {

        //Fetch active 'Document Link Related Objects Setting' custom metadata records
        List <PC_Document_Link_Related_Object_Setting__mdt> activeDocLinkCustomMetadataRecList = PC_System.getActiveDocumentLinkCustomMetadataRecs();
        List<RecordType> validRecordTypeList = new List<RecordType>();

        //Prepare a set of Account record type names from the above list
        Set<String> recordTypeDevNameSet = new Set<String>();
        for (PC_Document_Link_Related_Object_Setting__mdt activeDocLinkCustomMetadataRec : activeDocLinkCustomMetadataRecList) {
            recordTypeDevNameSet.add(activeDocLinkCustomMetadataRec.PC_Account_Record_Type__c);
        }

        //Fetch record type details from Account object as per the Set created above
        List<RecordType> recordTypeList = PC_SYSTEM.getSpecificAccountRecordTypeDetails(recordTypeDevNameSet);

        /* PC-5415: Match the namespaceprefix of the record types to the account record type namespace defined in the custom metadata record. This
        is required if there is a custom record type defined in the managed package org, and the org has a namespace defined.*/
        for (PC_Document_Link_Related_Object_Setting__mdt docLinkObject : activeDocLinkCustomMetadataRecList) {

            for (RecordType recordType : recordTypeList) {

                if (!validRecordTypeList.contains(recordType)) {

                    if (recordType.DeveloperName.equals(docLinkObject.PC_Account_Record_Type__c)) {

                        if (docLinkObject.PC_Account_Record_Type_Namespace_Prefix__c == null && recordType.NamespacePrefix == null) {

                            validRecordTypeList.add(recordType);

                        } else if (docLinkObject.PC_Account_Record_Type_Namespace_Prefix__c == '' && recordType.NamespacePrefix == '') {

                            validRecordTypeList.add(recordType);

                        } else if (!String.isBlank(recordType.NamespacePrefix) && !String.isBlank(docLinkObject.PC_Account_Record_Type_Namespace_Prefix__c)
                                && recordType.NamespacePrefix.toLowerCase().equals(docLinkObject.PC_Account_Record_Type_Namespace_Prefix__c.toLowerCase())) {

                            validRecordTypeList.add(recordType);
                        }
                    }
                }
            }
        }


        return validRecordTypeList;
    }

    /*********************************************************************************
    Method Name    : getRecordTypeForAccount
    Author         : Ajinkya Deshmukh
    Description    : This method returns the account RT as a picklist
    Return Type    : String recordType
    Parameter      : String accountId, String documentId
    *********************************************************************************/
    @AuraEnabled
    public static String getRecordTypeForAccount(String accountId) {
        String recordType;
        List<Account> aAccount = [SELECT Id, Type, RecordType.Name FROM Account WHERE Id = :accountId];
        if (aAccount.size() > 0) {
            recordType = aAccount[0].Type;
        }
        return recordType;
    }

    /*********************************************************************************
    Method Name    : createDocumentLog
    Author         : Ajinkya Deshmukh
    Description    : This method returns the account RT as a picklist
    Return Type    : void
    Parameter      : String accountId, String documentId
    *********************************************************************************/
    @AuraEnabled
    public static void createDocumentLog(String accountId, String documentId) {
        /*
        * FLS Check for PC_Document_Log__c
        */
        List<String> fields = new List<String>{
                PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Constants.getQualifiedAPIName('PC_Account__c')
        };
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'), PC_Database.Operation.Reading, fields);

        List<PC_Document_log__c> getDocumentLog = [
                SELECT Id
                FROM PC_Document_Log__c
                WHERE PC_Account__c = :accountId
                AND PC_Document__c = :documentId
        ];
        try {
            if (getDocumentLog.size() == 0) {
                //Check FLS/CRUD before SOQL
                fields = new List<String>{
                        'Name'
                };
                PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, fields);
                Account accountDetails = [SELECT Id, Name, RecordType.Name FROM Account WHERE Id = :accountId];
                PC_Document_Log__c docObj = new PC_Document_Log__c();
                docObj.PC_Document__c = documentId;
                docObj.PC_Account__c = accountId;
                docObj.PC_Association_Record_ID__c = accountId;
                docObj.PC_Association_Record_Name__c = accountDetails.Name;
                docObj.PC_Association_Type__c = accountLabel + ': ' + accountDetails.RecordType.Name;
                PC_Database.ins(docObj); //FLS/CRUD is enforced in the database.ins method
            }

            //Check FLS/CRUD before SOQL
            fields = new List<String>{
                    PC_Constants.getQualifiedAPIName('PC_Document_Status__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, fields);

            //Extending method to set the status of linked document to 'In review'
            if (documentId != null) {
                PC_Document__c docObj = [select Id, PC_Document_Status__c from PC_Document__c where Id = :documentId];
                if (docObj != null) {
                    if (docObj.PC_Document_Status__c == PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED) {
                        docObj.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_IN_REVIEW;
                    }
                    PC_Database.upd(docObj);
                }
            }
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }

    }

    /*********************************************************************************
    Method Name    : reassignDocumentOwner
    Author         : Alina Balan
    Description    : This method changes the doc owner to a user given as param
    Return Type    : DocumentWrapper
    Parameter      : Id docId, Id ownerId, String sUserName
    *********************************************************************************/
    @AuraEnabled
    public static DocumentWrapper reassignDocumentOwner(Id docId, Id ownerId, String sUserName) {
        DocumentWrapper docWrapper = getDocRecord(docId);
        //check if the owner is already the current user
        if (docWrapper.document.OwnerId != ownerId) {
            PC_Document__c doc = updateDocumentOwner(docWrapper.document, ownerId, sUserName);
            docWrapper.document = doc;
        }
        return docWrapper;
    }

    /*********************************************************************************
    Method Name    : updateDocumentOwner
    Author         : Tetiana Danylyshyn
    Description    : This method is used to update the document owner with the owner sent as param
    Return Type    : PC_Document__c
    Parameter      : PC_Document__c doc, Id ownerId, String sUserName
    *********************************************************************************/
    @AuraEnabled
    public static PC_Document__c updateDocumentOwner(PC_Document__c doc, Id ownerId, String sUserName) {
        try {
            Boolean useSalesforceFiles = PC_SYSTEM.useSalesforceFiles();
            doc.OwnerId = ownerId;

            PC_Database.upd(doc);//Updated by mapatil to enforce CRUD/FLS

            if (useSalesforceFiles) {
                //FLS Check
                List<String> cdlFields = new List<String>{
                        'LinkedEntityId', 'ContentDocument'
                };
                PC_Database.assertAccess('ContentDocumentLink', PC_Database.Operation.Reading, cdlFields);

                List<String> contentDocFields = new List<String>{
                        'Id', 'OwnerId', 'ContentModifiedDate'
                };
                PC_Database.assertAccess('ContentDocument', PC_Database.Operation.Reading, contentDocFields);

                List<ContentDocumentLink> lstContentDocs = [
                        SELECT ContentDocumentId, ContentDocument.ContentModifiedDate
                        FROM ContentDocumentLink
                        WHERE LinkedEntityId = :doc.Id
                        order by ContentDocument.ContentModifiedDate desc
                ];

                if (lstContentDocs.size() > 0) {
                    List<ContentDocument> relFile = [SELECT Id, OwnerId FROM ContentDocument WHERE Id = :lstContentDocs[0].ContentDocumentId Limit 1];
                    if (relFile != null && relFile.size() > 0) {
                        relFile[0].OwnerId = ownerId;
                        PC_Database.upd(relFile, true);
                    }
                }

            } else {
                //Create a list of fields to check if user has field level security on Attachment fields
                List<String> fields = new List<String>{
                        'Name', 'Body'
                };
                //Check if user has access to peform the READ operation
                PC_Database.assertAccess(PC_Constants.PC_ATTACHMENT, PC_Database.Operation.Reading, fields);
                List<Attachment>lstAttachments = [SELECT Id, Name, Body FROM Attachment WHERE ParentId = :doc.Id order by CreatedDate desc];

                if (lstAttachments != null && lstAttachments.size() > 0) {
                    lstAttachments[0].OwnerId = ownerId;
                    PC_Database.upd(lstAttachments, true);//Updated by mapatil to enforce CRUD/FLS
                }
            }

            PC_Document_Log__c docLog = new PC_Document_Log__c();
            docLog.PC_Document__c = doc.Id;
            docLog.PC_Document_Log__c = Label.PC_Ownership_changed_to + ' ' + sUserName;
            docLog.PC_Document_Owner_Id__c = ownerId;
            PC_Database.ins(docLog);//Updated by mapatil to enforce CRUD/FLS
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return doc;
    }

    /*********************************************************************************
    Method Name    : archiveDocumentFax
    Author         : Alina Balan
    Description    : This method changes the fax status to archived
    Return Type    : String
    Parameter      : Id docId
    *********************************************************************************/
    @AuraEnabled
    public static DocumentWrapper archiveDocumentFax(Id docId) {
        //Alterate code added to make the methods consistent and implement PC-1018
        DocumentWrapper docWrapper = getDocRecord(docId);
        PC_Document__c docObj = docWrapper.document;
        try {
            if (docObj != null) {
                docObj.PC_Archived_By__c = UserInfo.getuserId();
                docObj.PC_Archived_On__c = System.now();
                docObj.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_ARCHIVED;
                PC_Database.upd(docObj);
            }
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        docWrapper.document = docObj;
        return docWrapper;
    }

    /*********************************************************************************
    Method Name    : searchPatient
    Author         : Alina Balan
    Description    : Searches for the Patient records
    Return Type    : List<PatParticWrapper>
    Parameter      : String searchString
    *********************************************************************************/
    @AuraEnabled
    public static List<PatParticWrapper> searchForPatient(String p_searchString, String p_recordTypeName, String docManufacturer, String docEngagementProg, String allRecordTypeList) {
        List<PatParticWrapper> sObjctWrapper = new List<PatParticWrapper> ();
        List<Account> lstManuAccounts = new List<Account>();
        List<Case> casesofEngagementProgForAcc = new List<Case>();
        List<Account> lstAccounts = new List<Account>();

        //check if the searched string is a valid date
        String originalSearchString = p_searchString;
        String searchString;
        searchString = '\'%' + String.escapeSingleQuotes(p_searchString) + '%\'';
        String soslSearchString = '{*' + String.escapeSingleQuotes(p_searchString) + '*}';
        DateTime searchDateTime;
        DateTime searchDate;
        String formatedDt;
        try {
            searchDateTime = DateTime.valueOf(originalSearchString);
        } catch (Exception e) {
        }
        try {
            searchDate = Date.valueOf(originalSearchString);
        } catch (Exception e) {
        }
        if (searchDateTime != null) {
            formatedDt = searchDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        }
        if (searchDate != null) {
            formatedDt = searchDate.format('yyyy-MM-dd');
        }

        /*
        * FLS Check for Account
        */
        List<String> fields = new List<String>{
                'Name', PC_Constants.getQualifiedAPIName('PC_NPI__c'), PC_Constants.getQualifiedAPIName('PC_Status__c'),
                PC_Constants.getQualifiedAPIName('PC_Primary_Address_1__c'), PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'),
                PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c'), PC_Constants.getQualifiedAPIName('PC_Primary_State__c'),
                PC_Constants.getQualifiedAPIName('PC_Primary_City__c')
        };
        PC_Database.assertAccess('Account', PC_Database.Operation.Reading, fields);

        String sQuery = 'SELECT ID,Name,RecordType.Name,RecordType.DeveloperName,'
                + PC_Constants.getQualifiedAPIName('PC_NPI__c') + ','
                + PC_Constants.getQualifiedAPIName('PC_Status__c') + ','
                + PC_Constants.getQualifiedAPIName('PC_Primary_Address_1__c') + ','
                + PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c') + ','
                + PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c') + ','
                + PC_Constants.getQualifiedAPIName('PC_Primary_State__c') + ','
                + PC_Constants.getQualifiedAPIName('PC_Primary_City__c')
                + ' FROM Account';


        String sWhereClause = PC_Constants.EMPTY_STRING;
        List<Schema.FieldSetMember> lstFieldSetMembers = readFieldSet(PC_Constants.SEARCH_PATIENT_FIELDSET_OBJECT, PC_Constants.PATIENT_OBJECT);
        sQuery += ' WHERE ';
        if (p_recordTypeName != PC_Constants.PC_ALL) {
            sQuery += 'RecordType.DeveloperName =\'' + p_recordTypeName + '\'';
            sQuery += ' AND ';
        }

        if (lstFieldSetMembers.size() > 0) {
            sQuery += '(';
        }
        for (Schema.FieldSetMember fieldSetMember : lstFieldSetMembers) {
            system.debug('get type:' + fieldSetMember.getType());
            //check if the field is date or date/time
            if ((fieldSetMember.getType() == Schema.DisplayType.Date || fieldSetMember.getType() == Schema.DisplayType.DateTime) && !String.isBlank(formatedDt)) {
                if (!String.isBlank(sWhereClause)) {
                    sWhereClause += ' OR ';
                }
                sWhereClause += fieldSetMember.getFieldPath() + ' = ' + formatedDt;
                fields.add(fieldSetMember.getFieldPath());//Updated by mapatil to enforce CRUD/FLS
            } else if (fieldSetMember.getType() != Schema.DisplayType.Date && fieldSetMember.getType() != Schema.DisplayType.DateTime) {
                if (!String.isBlank(sWhereClause)) {
                    sWhereClause += ' OR ';
                }
                sWhereClause += fieldSetMember.getFieldPath() + ' LIKE ' + searchString;
                fields.add(fieldSetMember.getFieldPath());//Updated by mapatil to enforce CRUD/FLS
            }
        }
        if (!String.isBlank(sWhereClause)) {
            sQuery += sWhereClause + ')';
        }

        string accountType = PC_Constants.EMPTY_STRING;
        /*
         * [PC-1598]
         * Added logic to search records for the manufacturer that the Document is tagged with, if the tagging exists
		 */
        /*if(p_recordTypeName != 'All' && (docManufacturer=='' || docManufacturer == null)) {
            accountType = ' WHERE RecordType.DeveloperName =\'' + p_recordTypeName + '\'';
        } else if(p_recordTypeName != 'All' && docManufacturer!='' && docManufacturer!=null) {
            accountType = ' WHERE RecordType.DeveloperName =\'' + p_recordTypeName + '\' and ParentId =\'' + docManufacturer + '\'';
        }else if (p_recordTypeName == 'All' && docManufacturer!='' && docManufacturer!=null ) {
            accountType = ' WHERE ParentId =\'' + docManufacturer + '\'';
        }*/

        /*
        * [PC-3082]
        * Modified logic to search Patient records for the manufacturer that the Document is tagged with, if the tagging exists.
        * All non patient records based on query string should appear regardless of manufacturer that the Document is tagged with.
        * In case of no manufacturer all Patient and non patient records should appear based on query string.
         */
        //Build Where clause for Filtering Accounts of only configured record Types.
        List<String> recordTypesList = new List<String>();
        String recordTypeFilterCondition = '';
        recordTypesList = allRecordTypeList.split(',');
        for (String recordType : recordTypesList) {
            recordTypeFilterCondition = recordTypeFilterCondition + ' RecordType.DeveloperName =\'' + recordType + '\' or';
        }
        recordTypeFilterCondition = recordTypeFilterCondition.removeEndIgnoreCase(' or');

        if (p_recordTypeName != PC_Constants.PC_ALL && (String.isBlank(docManufacturer) || docManufacturer == null)) {
            accountType = ' WHERE RecordType.DeveloperName =\'' + p_recordTypeName + '\'';
        } else if (p_recordTypeName != PC_Constants.PC_ALL && !String.isBlank(docManufacturer) && docManufacturer != null
                && p_recordTypeName == PC_Constants.PATIENT_RECORD_TYPE) {
            accountType = ' WHERE RecordType.DeveloperName =\'' + p_recordTypeName + '\' and  (ParentId =\'' + docManufacturer + '\'' + +'OR PC_ParentManufacturer__c =\'' + docManufacturer + '\')';
        } else if (p_recordTypeName != PC_Constants.PC_ALL && !String.isBlank(docManufacturer) && docManufacturer != null) {
            accountType = ' WHERE RecordType.DeveloperName =\'' + p_recordTypeName + '\'';
        } else if (p_recordTypeName == PC_Constants.PC_ALL && !String.isBlank(docManufacturer) && docManufacturer != null) {
            accountType = ' WHERE  ((NOT RecordType.DeveloperName like \'' + PC_Constants.PATIENT_RECORD_TYPE + '\') ' +
                    'or ParentId =\'' + docManufacturer + '\' ' + 'or PC_ParentManufacturer__c =\'' + docManufacturer + '\')';
            if (recordTypeFilterCondition != '') {
                accountType = accountType + ' and (' + recordTypeFilterCondition + ')';
            }
        } else if (p_recordTypeName == PC_Constants.PC_ALL && (String.isBlank(docManufacturer) || docManufacturer == null)) {
            if (recordTypeFilterCondition != '') {
                accountType = ' WHERE ' + recordTypeFilterCondition;
            }
        }
        String soslQuery = 'FIND ' + soslSearchString + ' IN ALL FIELDS RETURNING Account'
                + '(ID,Name,RecordType.Name,RecordType.DeveloperName,'
                + PC_Constants.getQualifiedAPIName('PC_NPI__c') + ','
                + PC_Constants.getQualifiedAPIName('PC_Status__c') + ','
                + PC_Constants.getQualifiedAPIName('PC_Primary_Address_1__c') + ','
                + PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c') + ','
                + PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c') + ','
                + PC_Constants.getQualifiedAPIName('PC_Primary_State__c') + ','
                + PC_Constants.getQualifiedAPIName('PC_Primary_City__c')
                + accountType
                + ' )';

        sQuery += ' LIMIT 1000';

        try {
            //Updated to check FLS on Account fields
            fields = new List<String>{
                    'Name', PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c')
            };
            PC_Database.assertAccess('Account', PC_Database.Operation.Reading, fields);
            List<List<sObject>> soslResults = search.query(soslQuery);
            lstManuAccounts = soslResults[0]; //PC-1598 Get all accounts for the Manufacturer
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }

        if (!lstManuAccounts.isEmpty() && !String.isBlank(docEngagementProg) && docEngagementProg != null) {
            for (Account account : lstManuAccounts) {
                casesofEngagementProgForAcc = PC_DocumentManagementHelper.getProgramRecords(account.Id, docEngagementProg);
                if (account.RecordType.Name == PC_Constants.PATIENT_ACCOUNT_TYPE_VALUE) {
                    casesofEngagementProgForAcc = PC_DocumentManagementHelper.getProgramRecords(account.Id, docEngagementProg);
                    if (!casesofEngagementProgForAcc.isEmpty()) {
                        lstAccounts.add(account);
                    }
                } else {
                    lstAccounts.add(account);
                }

            }
        } else {
            for (Account account : lstManuAccounts) {
                lstAccounts.add(account);
            }
        }
        for (Account account : lstAccounts) {
            for (RecordType rec : recTypeLabels) {
                if (rec.DeveloperName == account.RecordType.DeveloperName) {
                    recTypeLabel = rec.Name;
                }
            }
            PatParticWrapper wrprObj = new PatParticWrapper(null, false);
            wrprObj.sPatientName = account.Name;
            wrprObj.sPatientBirthDate = String.valueOf(account.PC_Date_of_Birth__c);
            wrprObj.sPatientId = String.valueOf(account.Id);
            wrprObj.sAccountType = account.RecordType.Name;
            wrprObj.sAccountTypeLabel = recTypeLabel;
            wrprObj.sPhysicianNPI = account.PC_NPI__c;
            wrprObj.sAccStatus = account.PC_Status__c;
            wrprObj.sAccAddr = account.PC_Primary_Address_1__c;
            wrprObj.sAccCity = account.PC_Primary_City__c;
            wrprObj.sAccState = account.PC_Primary_State__c;
            wrprObj.sAccZipCode = account.PC_Primary_Zip_Code__c;

            sObjctWrapper.add(wrprObj);
        }
        return sObjctWrapper;
    }

    /*********************************************************************************
    Method Name    : readFieldSet
    Author         : Alina Balan
    Description    : Get all fields from a field set
    Return Type    : List<Schema.FieldSetMember>
    Parameter      : String fieldSetName, String ObjectName
    *********************************************************************************/
    public static List<Schema.FieldSetMember> readFieldSet(String fieldSetName, String ObjectName) {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        return fieldSetObj.getFields();
    }

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
        DocLogAndDescWrapper docLogAndDescWrapper = new DocLogAndDescWrapper();
        List<DocLogWrapper> lstDocLogWrapper = new List<DocLogWrapper>();
        String adverseEventObjectNotInUse ='';

        List<PC_Patient_Connect_Setting__mdt> patientConnectSettingList = [
                SELECT Id, PC_SettingName__c,PC_SettingValue__c
                FROM PC_Patient_Connect_Setting__mdt
                WHERE PC_SettingName__c = :PC_Constants.PC_SHOW_DOC_LOG_AND_DESCRIPTION AND PC_Active__c = :PC_Constants.TRUE_BOOLEAN
        ];

        try {
            //[PC-5715]: Get the label of the Adverse Event object which we need to exclude in the Link Log section
            adverseEventObjectNotInUse = PC_DocumentManagementHelper.getAdverseEventObjectAPINameNotInUse();

            //PC-4608: Code to fetch the condition required to display PC_Document_Log__c field value on UI
            if (patientConnectSettingList != null && !patientConnectSettingList.isEmpty()) {

                if (!String.isBlank(patientConnectSettingList[0].PC_SettingValue__c) && PC_Constants.TRUE_STRING.equalsIgnoreCase(patientConnectSettingList[0].PC_SettingValue__c)) {
                    docLogAndDescWrapper.showDocumentLogFieldVal = true;
                }
            }
            //Create a list of fields to check if user has field level security on PC_Document_Log__c fields
            List<String> fields = new List<String>{
                    PC_Constants.getQualifiedAPIName('PC_Document_Log__c'), PC_Constants.getQualifiedAPIName('PC_Program__c'), 'LastModifiedBy', 'LastModifiedDate', PC_Constants.getQualifiedAPIName('PC_Association_Record_Id__c'), PC_Constants.getQualifiedAPIName('PC_Association_Type__c'), PC_Constants.getQualifiedAPIName('PC_Association_Record_Name__c')
                    , PC_Constants.getQualifiedAPIName('PC_Document__c')
            };
            //Check if user has access to perform the READ operation
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'), PC_Database.Operation.Reading, fields);

            List<PC_Document_Log__c> lstDocLogs = [
                    SELECT PC_Document_Log__c, PC_Program__c, LastModifiedBy.Name, LastModifiedDate, PC_Association_Record_Id__c, PC_Association_Type__c, PC_Association_Record_Name__c
                    FROM PC_Document_Log__c
                    WHERE PC_Document__c = :docId
                    order by LastModifiedDate DESC
            ];

            for (PC_Document_Log__c l : lstDocLogs) {
                String sObjectAPIName = String.valueOf(Id.valueOf(l.PC_Association_Record_Id__c).getSobjectType());
                String sObjectAPINameToCompare = sObjectAPIName.contains('__') ? (sObjectAPIName.countMatches('__') == 2 ? sObjectAPIName.substringAfter('__') : sObjectAPIName): sObjectAPIName;
                //[PC-5715] Added logic to display only those records of the Adverse Event object configured in the custom metadata
                if(!String.isBlank(adverseEventObjectNotInUse) &&
                        !sObjectAPINameToCompare.toLowerCase().equals(adverseEventObjectNotInUse)){

                    lstDocLogWrapper.add(new DocLogWrapper(l));
                }
            }

            //PC-4608: Code to fetch the condition required to display PC_Document_Log__c field value on UI
            docLogAndDescWrapper.documentLogWrapperList.addAll(lstDocLogWrapper);
        } catch (exception e) {
            PC_Utility.logAndThrowException(e);
        }

        return docLogAndDescWrapper;
    }

    /*********************************************************************************
    Method Name    : UpdateReportSpam
    Author         : Alina Balan
    Description    : This method will update document object when report spam button is clicked
    Return Type    : String
    Parameter      : Id docId
    *********************************************************************************/
    @AuraEnabled
    public static DocumentWrapper updateReportSpam(Id docId) {
        DocumentWrapper docWrapper = getDocRecord(docId);
        PC_Document__c docObj = docWrapper.document;
        try {
            if (docId != null && docObj != null) {
                docObj.PC_Marked_Spam_By__c = UserInfo.getuserId();
                docObj.PC_Marked_Spam_On__c = System.today();
                docObj.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_SPAM;
                PC_Database.upd(docObj);//Updated by mapatil to enforce CRUD/FLS;
            }
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        docWrapper.document = docObj;
        return docWrapper;
    }

    /*********************************************************************************
    Method Name    : updateReportUnspam
    Author         : Alina Balan
    Description    : This method will update document object when unspam button is clicked
    Return Type    : DocumentWrapper
    Parameter      : Id docId
    *********************************************************************************/
    @AuraEnabled
    public static DocumentWrapper updateReportUnspam(Id docId) {
        DocumentWrapper docWrapper = getDocRecord(docId);
        PC_Document__c docObj = docWrapper.document;
        try {
            if (docObj != null) {
                docObj.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_CATEGORIZED;
                docObj.PC_Marked_Spam_By__c = null;
                docObj.PC_Marked_Spam_On__c = null;
                PC_Database.upd(docObj);//Updated by mapatil to enforce CRUD/FLS;
            }
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        docWrapper.document = docObj;
        return docWrapper;
    }

    /*********************************************************************************
    Method Name    : reportIllegible
    Author         : Alina Balan
    Description    : This method will update document object when illegible button is clicked
    Return Type    : String
    Parameter      : Id docId
    *********************************************************************************/
    @AuraEnabled
    //Alterate code added to make the methods consistent and implement PC-1018
    public static DocumentWrapper reportIllegible(Id docId) {
        DocumentWrapper docWrapper = getDocRecord(docId);
        PC_Document__c docObj = docWrapper.document;
        try {
            if (docObj != null) {
                docObj.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_ILLEGIBLE;
                PC_Database.upd(docObj);//Updated by mapatil to enforce CRUD/FLS;
            }
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        docWrapper.document = docObj;
        return docWrapper;
    }

    /*********************************************************************************
    Method Name    : reportComplete
    Author         : Ajinkya Deshmukh
    Description    : This method will update document object when illegible button is clicked
    Return Type    : DocumentWrapper
    Parameter      : Id docId
    *********************************************************************************/
    @AuraEnabled
    public static DocumentWrapper reportComplete(Id docId) {
        DocumentWrapper docWrapper = getDocRecord(docId);
        PC_Document__c docObj = docWrapper.document;
        try {
            if (docObj != null) {
                docObj.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_COMPLETED;
                PC_Database.upd(docObj);//Updated by mapatil to enforce CRUD/FLS;
            }
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        docWrapper.document = docObj;
        return docWrapper;
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
                /*
                * FLS Check for PC_Document__c
                */
                List<String> fields = new List<String>{
                        'Id'
                };
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


    /*********************************************************************************
    Method Name    : getCategories
    Author         : Alina Balan
    Description    : This method is used to get all available categories
    Return Type    : List<CategoryWrapper>
    Parameter      : none
    *********************************************************************************/
    private static List<CategoryWrapper> getCategories(String docRecordType) {
        List<CategoryWrapper> lstCategories = new List<CategoryWrapper>();
        Schema.DescribeFieldResult fieldResult;
        fieldResult = PC_Document__c.PC_Document_Category__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple) {
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
                     Engagement Program Code controlling field value and Record Type
                     used
    Return Type    : List<CategoryWrapper>
    Parameter      : String ctrRecord, Id recordTypeId
    *********************************************************************************/
    private static List<CategoryWrapper> getDependentCategories(String ctrRecord, Id recordTypeId,
            String docRecordType) {
        List<CategoryWrapper> lstCategories = new List<CategoryWrapper>();
        List<String> controllingEntries = new List<String>();
        Schema.DescribeFieldResult field = PC_Document__c.PC_EngagementProgramCode__c.getDescribe();
        for (Schema.PicklistEntry f : field.getPicklistValues()) {
            controllingEntries.add(f.getLabel());
        }
        // In case there is no active picklist value for PC_EngagementProgramCode__c
        if (controllingEntries.isEmpty()) {
            return getCategories(docRecordType);
        }
        // In case if PC_EngagementProgramCode__c is set to null for the document record
        // or there is no such active picklist value for PC_EngagementProgramCode__c
        if (ctrRecord == null || !(controllingEntries.contains(ctrRecord))) {
            ctrRecord = PC_Constants.PC_NONE;
        }
        // In case if PC_EngagementProgramCode__c is set to None but None picklist value
        // itself is not present/active
        if (ctrRecord == PC_Constants.PC_NONE && !(controllingEntries.contains(PC_Constants.PC_NONE))) {
            return getCategories(docRecordType);
        }
        Map<String, String> allowedValues = PC_PicklistFieldManager.picklistRecordTypeFieldList
                (PC_Document__c.PC_EngagementProgramCode__c, PC_Document__c.PC_Document_Category__c,
                        PC_Constants.getQualifiedAPIName('PC_Document__c'), recordTypeId, ctrRecord);
        // Rare scenario, but in case there is no allowed value
        if (allowedValues == null) {
            return getCategories(docRecordType);
        }

        for (String key : allowedValues.keySet()) {
            CategoryWrapper categWrapper = new CategoryWrapper();
            categWrapper.categoryName = key;
            categWrapper.categoryLabel = allowedValues.get(key);
            lstCategories.add(categWrapper);
        }
        return lstCategories;
    }
    /*********************************************************************************
    Method Name    : saveDocumentCategoryV2
    Author         : Haritha Reddy
    Description    : This method is used to save a category. Logic related to Category list update is moved to front end.
    Return Type    : void
    Parameter      : Id docId, String selectedCategory
    *********************************************************************************/
    /* @AuraEnabled
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
             PC_Database.upd(oDoc);//Updated by mapatil to enforce CRUD/FLS;

         }catch(Exception e) {
             system.debug('error ==' + e);
             PC_Utility.logAndThrowException(e);
         }
     }*/
    /*********************************************************************************
    Method Name    : saveDocumentCategory
    Author         : Alina Balan
    Description    : This method is used to save a category
    Return Type    : DocumentWrapper
    Parameter      : Id docId, String selectedCategory
    *********************************************************************************/
    @AuraEnabled
    public static DocumentWrapper saveDocumentCategory(Id docId, String selectedCategory) {
        List<PC_PicklistFieldManager.PicklistEntryWrapper> docStatusLabels = PC_PicklistFieldManager.getPicklistEntryWrappers(PC_Document__c.PC_Document_Status__c);
        DocumentWrapper docWrapper = new DocumentWrapper();

        try {
            //Create a list of fields to check if user has field level security on PC_Document__c fields
            List<String> fields = new List<String>{
                    'Name', PC_Constants.getQualifiedAPIName('PC_Document_Category__c'), PC_Constants.getQualifiedAPIName('PC_Document_Status__c'), PC_Constants.getQualifiedAPIName('PC_Parent_Document__c'),
                    PC_Constants.getQualifiedAPIName('PC_Archived_On__c'), PC_Constants.getQualifiedAPIName('PC_Archived_By__c'), PC_Constants.getQualifiedAPIName('PC_Marked_Spam_By__c'), PC_Constants.getQualifiedAPIName('PC_Marked_Spam_On__c'),
                    PC_Constants.getQualifiedAPIName('PC_IsSplit__c'), PC_Constants.getQualifiedAPIName('PC_From_Fax_Number__c'), PC_Constants.getQualifiedAPIName('PC_From_Email_Address__c'), PC_Constants.getQualifiedAPIName('PC_From_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'), PC_Constants.getQualifiedAPIName('PC_EngagementProgramCode__c')
            };

            //Check if user has access to peform the READ operation
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, fields);

            fields = new List<String>{
                    'Name'
            };
            //Check if user has access to peform the READ operation
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'), PC_Database.Operation.Reading, fields);

            fields = new List<String>{
                    'Name'
            };
            //Check if user has access to perform the READ operation
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, fields);

            PC_Document__c oDoc = [
                    SELECT Id, Name, RecordType.DeveloperName, RecordTypeId, PC_Document_Category__c, PC_Document_Status__c, PC_Parent_Document__c, PC_IsSplit__c,
                            PC_Parent_Document__r.Name, OwnerId, PC_Archived_On__c, PC_Archived_By__r.Name, PC_Marked_Spam_By__r.Name, PC_Marked_Spam_On__c,
                            PC_From_Fax_Number__c, PC_From_Email_Address__c, PC_From_Name__c, PC_Engagement_Program__r.Name, PC_EngagementProgramCode__c, PC_Engagement_Program__r.PC_Manufacturer__r.Name
                    FROM PC_Document__c
                    WHERE Id = :docId
                    LIMIT 1
            ];

            for (PC_PicklistFieldManager.PicklistEntryWrapper pew : docStatusLabels) {
                if (pew.value == oDoc.PC_Document_Status__c) {
                    statusLabel = pew.label;
                }
            }

            /*List<CategoryWrapper> lstCategories = getDependentCategories(oDoc.PC_EngagementProgramCode__c,
                    oDoc.RecordTypeId, oDoc.RecordType.DeveloperName);*/
            List<DocFieldWrapper> lstDocFields = new List<DocFieldWrapper>();
            lstDocFields.add(new docFieldWrapper(oDoc, statusLabel));

            if (oDoc.RecordType.DeveloperName != PC_Constants.DOCUMENT_ARTICLE_KNOWLEDGE_RECORD_TYPE) {
                if (oDoc.PC_Document_Status__c == PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED) {
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
                setSelectedCategories.add(selectedCategory);
            }
            /*for (CategoryWrapper categ : lstCategories) {
                if (setSelectedCategories.contains(categ.categoryName)) {
                    categ.isSelected = true;
                    if (categ.categoryLabel == System.Label.PC_Enrollment_Form) {
                        categ.isEnrollmentForm = true;
                    }
                }
            }*/
            PC_Database.upd(oDoc);//Updated by mapatil to enforce CRUD/FLS;

            //docWrapper.lstCategories = lstCategories;
            docWrapper.lstDocFields = lstDocFields;
            docWrapper.document = oDoc;

        } catch (Exception e) {
            system.debug('error ==' + e);
            PC_Utility.logAndThrowException(e);
        }

        return docWrapper;
    }

    /*********************************************************************************
    Method Name    : getReturnUrl
    Author         : Alina Balan
    Description    : This method is used to get the return url
    Return Type    : String
    Parameter      : none
    *********************************************************************************/
    @AuraEnabled
    public static String getReturnUrl() {
        String key = PC_Document__c.getSobjectType().getDescribe().getKeyPrefix();
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String prefix = Site.getPathPrefix();
        if (prefix == null) {
            prefix = PC_Constants.EMPTY_STRING;
        }
        return baseUrl + prefix + '/' + key;
    }

    /*********************************************************************************
    Method Name    : getChildComponentsMetadata
    Description    : Retrieves the list of components to be placed in the Document Management Component
    Return Type    : componentMetadataWrapper
    Parameter      : none
    *********************************************************************************/
    @AuraEnabled
    public static List<componentMetadataWrapper> getSubComponentsList() {
        List<PC_Document_Management_Components__mdt> subCompList = new List<PC_Document_Management_Components__mdt>();
        List<componentMetadataWrapper> subCompWrapper = new List<componentMetadataWrapper>();
        subCompList = [
                SELECT Id, PC_Component_Name__c, PC_Ordinal__c, PC_Active__c
                FROM PC_Document_Management_Components__mdt
                WHERE PC_Active__c = TRUE
                ORDER BY PC_Ordinal__c ASC
        ];
        for (PC_Document_Management_Components__mdt a : subCompList) {
            subCompWrapper.add(new componentMetadataWrapper(a));
        }
        System.debug(' Sub component Wrapper: ' + subCompWrapper);
        return subCompWrapper;
    }

    /*********************************************************************************
    Class Name    : componentMetadataWrapper
    Author        : Shabda Bhujad
    Description   : Wrapper class for child component metadata for the document management component
    *********************************************************************************/
    public class componentMetadataWrapper {
        @AuraEnabled public boolean compActive { get; set; }
        @AuraEnabled public String componentName { get; set; }
        @AuraEnabled public Decimal ordinal { get; set; }

        public componentMetadataWrapper(PC_Document_Management_Components__mdt comp_mdt) {
            this.compActive = comp_mdt.PC_Active__c;
            this.componentName = comp_mdt.PC_Component_Name__c;
            this.ordinal = comp_mdt.PC_Ordinal__c;
        }
    }

    /*********************************************************************************
    Class Name    : PatParticWrapper
    Author        : Alina Balan
    Description   : Wrapper class for patients
    *********************************************************************************/
    public class PatParticWrapper {
        @AuraEnabled public sObject objct { get; set; }
        @AuraEnabled public Boolean bIsChecked { get; set; }
        @AuraEnabled public String sPatientId { get; set; }
        @AuraEnabled public String sPatientName { get; set; }
        @AuraEnabled public String sPatientBirthDate { get; set; }
        @AuraEnabled public String sAccountType { get; set; }
        @AuraEnabled public String sAccountTypeLabel { get; set; }
        @AuraEnabled public String sPhysicianNPI { get; set; }
        @AuraEnabled public String sAccStatus { get; set; }
        @AuraEnabled public String sAccAddr { get; set; }
        @AuraEnabled public String sAccCity { get; set; }
        @AuraEnabled public String sAccState { get; set; }
        @AuraEnabled public String sAccZipCode { get; set; }

        @AuraEnabled public String onFocus {
            get {
                return 'LookupHoverDetail.getHover(\'' + sPatientId + '\', \'/' + sPatientId + '/m?retURL=%2F' + sPatientId + '&isAjaxRequest=1).show();';
            }
        }
        public PatParticWrapper(sObject pat, Boolean bisChkd) {
            objct = pat;
            bIsChecked = bisChkd;
            sAccountType = 'default';
        }
    }

    /*********************************************************************************
    Class Name    : CategoryWrapper
    Author        : Alina Balan
    Description   : Wrapper class for category
    *********************************************************************************/
    public class CategoryWrapper {
        @AuraEnabled public String categoryName { get; set; }
        @AuraEnabled public String categoryLabel { get; set; }
        @AuraEnabled public Boolean isSelected { get; set; }
        @AuraEnabled public Boolean isEnrollmentForm { get; set; }
        public CategoryWrapper() {
            isSelected = false;
            isEnrollmentForm = false;
        }
    }

    /*********************************************************************************
    Class Name    : DocumentWrapper
    Author        : Alina Balan
    Description   : Wrapper class for document
    *********************************************************************************/
    public class DocLogWrapper {
        @AuraEnabled public String docLog { get; set; }
        @AuraEnabled public String program { get; set; }
        @AuraEnabled public String associationRecordId { get; set; }
        @AuraEnabled public String associationType { get; set; }
        @AuraEnabled public String associationRecordName { get; set; }
        @AuraEnabled public String lastModifiedName { get; set; }
        @AuraEnabled public DateTime lastModifiedDate { get; set; }

        public DocLogWrapper(PC_Document_Log__c d) {
            this.docLog = d.PC_Document_Log__c;
            this.program = d.PC_Program__c;
            this.associationRecordId = d.PC_Association_Record_Id__c;
            this.associationType = d.PC_Association_Type__c;
            this.associationRecordName = d.PC_Association_Record_Name__c;
            this.lastModifiedName = d.LastModifiedBy.Name;
            this.lastModifiedDate = d.LastModifiedDate;
        }
    }


    public class DocFieldWrapper {
        @AuraEnabled public String docID { get; set; }
        @AuraEnabled public String docStatus { get; set; }
        @AuraEnabled public String docStatusLabel { get; set; }
        @AuraEnabled public String archivedBy { get; set; }
        @AuraEnabled public DateTime archivedOn { get; set; }
        @AuraEnabled public String spamBy { get; set; }
        @AuraEnabled public DateTime spamOn { get; set; }
        @AuraEnabled public String parentDocId { get; set; }
        @AuraEnabled public String parentDocName { get; set; }
        //@AuraEnabled public List<Attachment> parentDocAttachments {get; set;}
        @AuraEnabled public String fromFaxNum { get; set; }
        @AuraEnabled public String fromEmail { get; set; }
        @AuraEnabled public String fromName { get; set; }
        @AuraEnabled public String engagementProgram { get; set; }
        @AuraEnabled public String docManufacturerId { get; set; }
        @AuraEnabled public String docEngagementProgId { get; set; }
        @AuraEnabled public Boolean isSplit { get; set; }

        public DocFieldWrapper(PC_Document__c d, String statusLabel) {
            this.docID = d.Id;
            this.docStatus = d.PC_Document_Status__c;
            this.docStatusLabel = statusLabel;
            this.archivedBy = d.PC_Archived_By__r.Name;
            this.archivedOn = d.PC_Archived_On__c;
            this.spamBy = d.PC_Marked_Spam_By__r.Name;
            this.spamOn = d.PC_Marked_Spam_On__c;
            this.parentDocId = d.PC_Parent_Document__c;
            this.parentDocName = d.PC_Parent_Document__r.Name;
            //this.parentDocAttachments = d.Attachments;
            this.fromFaxNum = d.PC_From_Fax_Number__c;
            this.fromEmail = d.PC_From_Email_Address__c;
            this.fromName = d.PC_From_Name__c;
            this.engagementProgram = (string.isNotBlank(d.PC_Engagement_Program__r.Name)) ? (d.PC_Engagement_Program__r.PC_Manufacturer__r.Name + ' : ' + d.PC_Engagement_Program__r.Name) : PC_Constants.EMPTY_STRING;
            this.docManufacturerId = d.PC_Engagement_Program__r.PC_Manufacturer__c;
            this.docEngagementProgId = d.PC_Engagement_Program__c;
            this.isSplit = d.PC_IsSplit__c;
        }
        public DocFieldWrapper() {

        }
    }

    public class DocumentWrapper {
        @AuraEnabled public PC_Document__c document { get; set; }
        @AuraEnabled public List<CategoryWrapper> lstCategories { get; set; }
        @AuraEnabled public List<DocFieldWrapper> lstDocFields { get; set; }
        @AuraEnabled public Id loggedInUserId { get {return userinfo.getUserId();} }
        @AuraEnabled public Boolean loadFaxContainer { get; set; }
        @AuraEnabled public Boolean loadEmailContainer { get; set; }

        public DocumentWrapper() {
            lstCategories = new List<CategoryWrapper>();
            lstDocFields = new List<DocFieldWrapper>();
            loadFaxContainer = false;
            loadEmailContainer = false;
        }
    }

    /*********************************************************************************
    Class Name    : DocLogWrapper
    Author        : Hitha Avalakki
    User-Story    : PC-4608
    Description   : Wrapper class for document logs list and boolean value to display Document Log
    *********************************************************************************/
    public class DocLogAndDescWrapper {
        @AuraEnabled public Boolean showDocumentLogFieldVal { get; set; }
        @AuraEnabled public List<DocLogWrapper> documentLogWrapperList { get; set; }

        public DocLogAndDescWrapper() {
            showDocumentLogFieldVal = false;
            documentLogWrapperList = new List<DocLogWrapper>();
        }
    }
}