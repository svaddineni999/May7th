/*******************************************************************************************************************************************************************************************************
Class Name      : PC_Doc_Management_LinkDetailsController
Description     : Controller class used for PC_Document_Management_LinkDetails.cmp (lightning)
Created By      : Deloitte
Created Date    : February 02, 2018
Modification Log:
----------------------------------------------------------------------------------
Developer              Date                   Description
-----------------------------------------------------------------------------------
Hitha Avalakki         Feb 02, 2018           Initial Version
Hitha Avalakki         Mar 26, 2019           [PC-4651] Added exception classes: NoRecordsException, InvalidObjectException and methods:
                                               isObjectExist() to handle exceptions related to Document linking so as user can be notified with appropriate error message.
Hitha Avalakki         Mar 29, 2019           [PC-4678] Added paramater docEngagementProgId to getFieldsWithLookup() method call
Hitha Avalakki         April 02,2019          [PC-4696] Replaced custom labels related to document linking errors with String templates
Hitha Avalakki         Sep 06,2019            [PC-5380] Updated 'saveUpdateDocLogsServer' method to throw exception in order to display
                                              exact error message for 'Link' Document Action Icon
Tejas Patel            Nov 11 2019            [PC-5689] [PC-5701] Removing the if condition checking for Name and CaseNumber to allow other standard API Name
Shishir Bansal         Dec-06-2019            [PC-5792] Avoid hardcoding of string variable
Kishore Kanteti        Dec 10,11 2019         [PC-5795] Updated saveUpdateDocLogsServer to decrease the no. of parameters in createDocumentLogRecord method
Haritha Reddy          Dec 13, 2019           [PC-5791] Added error handling for getCaseIds Method
Haritha Reddy          May 05, 2020           [PC-6249] Added comment related to Force Reviewer scan issue
Haritha Reddy          21-Jan-2021            [PC-7102] Added FLS Check
Vijay Kashikar         21-Jan-21                 [PC-7102] Added sharing clause
*******************************************************************************************************************************************************************************************************/
public with sharing class PC_Doc_Management_LinkDetailsController {

    /*********************************************************************************
    Method Name    : getAccountDetails
    Author         : Shabda Bhujad
    Description    : This method retrieve patient name
    Return Type    : Account
    Parameter      : Id accountId
    *********************************************************************************/
    @AuraEnabled
    public static AccountWrapper getAccountDetails(String accountId) {
        Account acc = new Account();
        AccountWrapper acctWrapper = new AccountWrapper(acc);
        try {
            List<String> fields = new List<String>{
                    PC_Constants.getQualifiedAPIName('PC_Last_Name__c'), PC_Constants.getQualifiedAPIName('PC_First_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c'),'Type',
                    PC_Constants.getQualifiedAPIName('PC_Status__c'), PC_Constants.getQualifiedAPIName('PC_Primary_Address_1__c'),
                    PC_Constants.getQualifiedAPIName('PC_Primary_City__c'), PC_Constants.getQualifiedAPIName('PC_Primary_State__c'),
                    PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c')
            };
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, fields);
            //check access before SOQL
            acc = [
                    SELECT Id, RecordType.DeveloperName, PC_Last_Name__c, PC_First_Name__c, Name, Type, PC_Date_of_Birth__c, PC_Status__c, PC_Primary_Address_1__c, PC_Primary_City__c, PC_Primary_State__c, PC_Primary_Zip_Code__c
                    FROM Account
                    WHERE Id = :accountId
            ];
            acctWrapper = new AccountWrapper(acc);
        } catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return acctWrapper;
    }

    /**********************************************************************************************************
    Method Name    : saveUpdateDocLogsServer
    Author         : Hitha Avalakki
    Description    : This method is Used to create document log records and link different objects to the document.
    Return Type    : Boolean
    Parameter      : Id documentId,String stringOfListOfAllObjectRecordsFieldsets
    ***********************************************************************************************************/
    @AuraEnabled
    public static String saveUpdateDocLogsServer(Id documentId, String stringOfListOfAllObjectRecordsFieldsets) {

        PC_Document_Log__c documentLogObj = new PC_Document_Log__c();
        Boolean success = true;
        String resultString = PC_Constants.SUCCESS;

        List<ObjectFieldsWrapper> listOfAllObjectRecordsFieldsets = new List<ObjectFieldsWrapper>();
        listOfAllObjectRecordsFieldsets = (List<ObjectFieldsWrapper>) JSON.deserialize(stringOfListOfAllObjectRecordsFieldsets, List<ObjectFieldsWrapper>.class);
        Map<String, List<String>> mapOfObjectRecordsToBeLinked = new Map<String, List<String>>();
        List<PC_Document_Log__c> documentLogInsertionList = new List<PC_Document_Log__c>();
        List<PC_Document_Log__c> documentLogDeletionList = new List<PC_Document_Log__c>();
        Map<Id, PC_Document_Log__c> documentLogAssociationIdMap = new Map<Id, PC_Document_Log__c>();
        Set<Id> listOfAssociationRecordIdsToBeDeletedFromDocLog = new Set<Id>();

        try {

            List<String> fields = new List<String>{
                    PC_Constants.getQualifiedAPIName('PC_Association_Record_Id__c'), PC_Constants.getQualifiedAPIName('PC_Document_Log__c'), PC_Constants.getQualifiedAPIName('PC_Document__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'), PC_Database.Operation.Reading, fields);
            //check access before SOQL
            for (PC_Document_Log__c documentLogRecord : [SELECT Id, PC_Association_Record_Id__c, PC_Document_Log__c FROM PC_Document_Log__c WHERE PC_Document__c = :documentId]) {
                documentLogAssociationIdMap.put(documentLogRecord.PC_Association_Record_Id__c, documentLogRecord);
            }

            for (ObjectFieldsWrapper obj : listOfAllObjectRecordsFieldsets) {
                List<String> recordIdsToBeLinked = new List<String>();
                String objectLookupFieldOnDocLog = obj.objectLookupFieldOnDocLog;

                List<PC_FieldSet.ObjectFieldsDocLinkedWrapper> listOfFieldsSetsForObject = obj.listOfObjectFieldsSetDocLinkedWrapper;

                for (PC_FieldSet.ObjectFieldsDocLinkedWrapper objectFieldsetWrappperObj : listOfFieldsSetsForObject) {

                    /*The field value isLinked is being modified on the
                    component, whereas persistedLinkedUnlinkedStatus stores the unmanipulated value of whether the
                    object is linked or not to the document
                    */

                    Id objectRecordId = objectFieldsetWrappperObj.recordId;
                    Boolean currentLinkedStatus = objectFieldsetWrappperObj.isLinked;
                    Boolean persistedLinkedStatus = objectFieldsetWrappperObj.persistedLinkedUnlinkedStatus;

                    if (null != currentLinkedStatus &&
                            null != persistedLinkedStatus &&
                            currentLinkedStatus != persistedLinkedStatus) {

                        if (currentLinkedStatus) {
                            recordIdsToBeLinked.add('\'' + objectRecordId + '\'');
                            mapOfObjectRecordsToBeLinked.put(obj.objectName, recordIdsToBeLinked);
                        } else {
                            listOfAssociationRecordIdsToBeDeletedFromDocLog.add(objectRecordId);
                        }
                    }
                }
                /*Code callout to check if the document modification log lookup field
                is present on object PC_Document_Log__c*/
                Boolean isValid = hasSObjectField(documentLogObj, objectLookupFieldOnDocLog);

                if (!mapOfObjectRecordsToBeLinked.isEmpty()) {
                    String sObjectNameString = obj.objectName;
                    List<String> listOfIdsTobeInserted = new List<String>();
                    listOfIdsTobeInserted = (List<String>) mapOfObjectRecordsToBeLinked.get(sObjectNameString);

                    if (null != listOfIdsTobeInserted && !listOfIdsTobeInserted.isEmpty()) {
                        Boolean recordTypesPresent = hasRecordTypes(obj.objectName);
                        Boolean recordTypeIdPresent = false;
                        Set<String> fieldApinamesSet = new Set<String>(obj.fsListApiNames); //Convert to set
                        fieldApinamesSet.add('Id'); // Add Id to Set, even if it already exists Set will take care of it
                        List<String> fieldApinamesList = new List<String>(fieldApinamesSet);
                        String joinedfieldApinamesList = String.join(fieldApinamesList, ', ');
                        String joinedlistOfIdsTobeInserted = String.join(listOfIdsTobeInserted, ', ');

                        String finalQueryString = PC_Constants.EMPTY_STRING;
                        String firstHalfString = 'SELECT '; //Remove ID
                        String fromClause = ' FROM ' + sObjectNameString + ' WHERE Id IN (' + joinedlistOfIdsTobeInserted+')';

                        List<sObject> sObjectList = new List<SObject>();

                        if (recordTypesPresent) {

                            if (fieldApinamesSet.contains(PC_Constants.RECORD_TYPE_ID)) {
                                recordTypeIdPresent = true;
                            }
                        }

                        finalQueryString = firstHalfString + joinedfieldApinamesList + fromClause;
                        //PC-6249: The following SOQL is required here in order to keep the functionality as is.
                        sObjectList = Database.query(finalQueryString);

                        if (null != sObjectList && !sObjectList.isEmpty()) {
                            for (SObject sobjRecord : sObjectList) {
                                PC_Document_Log__c docLogObj = new PC_Document_Log__c();

                                Id sObjecRecordId = (Id) String.valueOf(sobjRecord.get('Id'));
                                String sobjectRecordName = String.valueOf(sobjRecord.get(fieldApinamesList[0]));

                                if (recordTypesPresent && recordTypeIdPresent) {
                                    String recordTypeDevName = PC_SYSTEM.getRecordTypeNameById(obj.objectName, (String) sobjRecord.get(PC_Constants.RECORD_TYPE_ID));
                                    Map<String, String> docLogDetailsMap = new Map<String, String>();
                                    docLogDetailsMap.put('documentId', documentId);
                                    docLogDetailsMap.put('recordId', sObjecRecordId);
                                    docLogDetailsMap.put('recordName', sobjectRecordName);
                                    docLogDetailsMap.put('docLogLookupFieldName', objectLookupFieldOnDocLog);
                                    docLogDetailsMap.put('defaultRecType', obj.objectLabel + ': ' + recordTypeDevName);
                                    docLogObj = createDocumentLogRecord(documentLogAssociationIdMap, docLogDetailsMap);
                                } else {
                                    Map<String, String> docLogDetailsMap1 = new Map<String, String>();
                                    docLogDetailsMap1.put('documentId', documentId);
                                    docLogDetailsMap1.put('recordId', sObjecRecordId);
                                    docLogDetailsMap1.put('recordName', sobjectRecordName);
                                    docLogDetailsMap1.put('docLogLookupFieldName', objectLookupFieldOnDocLog);
                                    docLogDetailsMap1.put('defaultRecType', obj.objectLabel);
                                    docLogObj = createDocumentLogRecord(documentLogAssociationIdMap, docLogDetailsMap1);
                                }

                                documentLogInsertionList.add(docLogObj);
                            }
                        }
                    }

                }

            }

            if (null != listOfAssociationRecordIdsToBeDeletedFromDocLog &&
                    !listOfAssociationRecordIdsToBeDeletedFromDocLog.isEmpty()) {

                for (String toBeDeletedId : listOfAssociationRecordIdsToBeDeletedFromDocLog) {

                    PC_Document_Log__c docLogRecToBeDeleted = new PC_Document_Log__c();
                    docLogRecToBeDeleted = documentLogAssociationIdMap.get(toBeDeletedId);
                    documentLogDeletionList.add(docLogRecToBeDeleted);
                }

            }

            if (null != documentLogInsertionList && !documentLogInsertionList.isEmpty()) {
                List<sObject> listOfInsertedRec = PC_Database.ups(documentLogInsertionList);
            }

            if (null != documentLogDeletionList && !documentLogDeletionList.isEmpty()) {
                List<sObject> listOfDeletedRec = PC_Database.del(documentLogDeletionList, true);
            }

            if ((null != documentLogInsertionList && documentLogInsertionList.isEmpty()) &&
                    (null != documentLogDeletionList && documentLogDeletionList.isEmpty())) {
                resultString = PC_Constants.WARNING;
            }

        } catch (Exception ex) {
            resultString = PC_Constants.ERROR;
            PC_Utility.logAndThrowException(ex);
            throw ex;
        }

        return resultString;

    }

    public static Boolean hasRecordTypes(String sObjectName) {
        Boolean recordTypesPresent = false;
        List<RecordType> listOfRecordTypes = new List<RecordType>();
        listOfRecordTypes = PC_SYSTEM.getAllRecordType(sObjectName);

        if (null != listOfRecordTypes && !listOfRecordTypes.isEmpty()) {
            recordTypesPresent = true;
        }
        return recordTypesPresent;
    }

    public static PC_Document_Log__c createDocumentLogRecord(Map<Id, PC_Document_Log__c> documentLogAssociationIdMap, Map<String, String> docLogDetailsMap) {

        Id documentId = (Id) docLogDetailsMap.get('documentId');
        Id recordId = (Id) docLogDetailsMap.get('recordId');
        String recordName = '';
        recordName = docLogDetailsMap.get('recordName');
        String docLogLookupFieldName = '';
        docLogLookupFieldName = docLogDetailsMap.get('docLogLookupFieldName');
        String defaultRecType = '';
        defaultRecType = docLogDetailsMap.get('defaultRecType');
        PC_Document_Log__c docObj = new PC_Document_Log__c();
        docObj.id = (documentLogAssociationIdMap != null && documentLogAssociationIdMap.containsKey(recordId)) ? documentLogAssociationIdMap.get(recordId).id : null;
        docObj.PC_Document_Log__c = (documentLogAssociationIdMap != null && documentLogAssociationIdMap.containsKey(recordId)) ? documentLogAssociationIdMap.get(recordId).PC_Document_Log__c : null;
        if (docObj.id == null) {
            docObj.PC_Document__c = documentId;
            docObj.put(docLogLookupFieldName, recordId);
            docObj.PC_Association_Record_ID__c = recordId;
            docObj.PC_Association_Record_Name__c = recordName;
            docObj.PC_Association_Type__c = defaultRecType;
        }
        return docObj;
    }

    /*********************************************************************************
    Class Name    : AccountWrapper
    Author        : Prachi Nandgaonkar
    Description   : Wrapper class for Account
    *********************************************************************************/
    public inherited sharing class AccountWrapper {
        @AuraEnabled public Id AccId { get; set; }
        @AuraEnabled public String AccLastName { get; set; }
        @AuraEnabled public String AccFirstName { get; set; }
        @AuraEnabled public String AccName { get; set; }
        @AuraEnabled public String AccType { get; set; }
        @AuraEnabled public Date AccDoB { get; set; }
        @AuraEnabled public String AccStatus { get; set; }
        @AuraEnabled public String AccAddr { get; set; }
        @AuraEnabled public String AccCity { get; set; }
        @AuraEnabled public String AccState { get; set; }
        @AuraEnabled public String AccZipCode { get; set; }
        @AuraEnabled public String isSelected { get; set; }
        @AuraEnabled public String recordTypeDevName { get; set; }


        public AccountWrapper(Account a) {
            this.AccId = a.Id;
            this.AccLastName = a.PC_Last_Name__c;
            this.AccFirstName = a.PC_First_Name__c;
            this.AccName = a.Name;
            this.AccType = a.Type;
            this.AccDoB = a.PC_Date_of_Birth__c;
            this.AccStatus = a.PC_Status__c;
            this.AccAddr = a.PC_Primary_Address_1__c;
            this.AccCity = a.PC_Primary_City__c;
            this.AccState = a.PC_Primary_State__c;
            this.AccZipCode = a.PC_Primary_Zip_Code__c;
            this.isSelected = PC_Constants.FALSE_STRING;
            this.recordTypeDevName = a.RecordType.DeveloperName;

        }
    }

    @AuraEnabled
    public static List<String> getCaseIds(String patientId, String docEngagementProgId) {
        List<String> caseIdsList = new List<String>();
        try {
            List<Case> casesList = new List<Case>();
            List<String> fields = new List<String>{'AccountId',
                    PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')
            };
            PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, fields);

            if (null != docEngagementProgId && '' != docEngagementProgId) {
                casesList = [SELECT Id FROM Case WHERE AccountId = :patientId and PC_Engagement_Program__c = :docEngagementProgId];
            } else {
                casesList = [SELECT Id FROM Case WHERE AccountId = :patientId];
            }

            for (Case caseObj : casesList) {
                String caseId = '\'' + (String) caseObj.Id + '\'';
                caseIdsList.add(caseId);
            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }

        return caseIdsList;
    }


    /***************************************************************************************************
    Method Name    : getApexFields
    Author         : Hitha Avalakki
    Description    : This method fetches the fields for the object types as per their respective fieldsets
    Return Type    : String
    Parameter      : Id recordId,String docEngagementProgId,String accountRecordType,String docId
    *****************************************************************************************************/
    @AuraEnabled
    public static String getApexFields(Id recordId, String docEngagementProgId, String accountRecordType, String docId) {

        List<ObjectFieldsWrapper> lstObjectFields = new List<ObjectFieldsWrapper>();
        List<List<PC_FieldSet.FieldSet>> listOfFieldSetList = new List<List<PC_FieldSet.FieldSet>>();
        Map<String, String> objectTypeNameColumnLabelMap = new Map<String, String>();
        Map<String, String> objectNamesDisplayNames = new Map<String, String>();
        Map<String, String> objectLabelMap = new Map<String, String>();
        List<String> caseIdsList = new List<String>();
        List<String> columnLabels = new List<String>();
        ObjectFieldsWrapper objectFieldsWrapperError = new ObjectFieldsWrapper();

        caseIdsList = getCaseIds(recordId, docEngagementProgId);

        try {
            Map<String, PC_Document_Link_Related_Object_Setting__mdt> objectFieldSetNameMap = new Map<String, PC_Document_Link_Related_Object_Setting__mdt>();
            if (recordId != null) {

                List <PC_Document_Link_Related_Object_Setting__mdt> docLinkObjectFieldSetList = [
                        SELECT Id,PC_Ordinal__c,PC_Linked_Obj_Lookup_Field__c,PC_FieldSetName__c, PC_sObject__c, PC_Account_Lookup_Field__c, PC_Case_Lookup_Field__c
                        FROM PC_Document_Link_Related_Object_Setting__mdt
                        WHERE PC_Account_Record_Type__c = :accountRecordType
                        AND PC_Active__c = true
                        ORDER BY PC_Ordinal__c ASC
                ];

                if (docLinkObjectFieldSetList != null && !docLinkObjectFieldSetList.isEmpty()) {

                    for (PC_Document_Link_Related_Object_Setting__mdt docLinkRelatedObjSettingMDT : docLinkObjectFieldSetList) {

                        String objectName = docLinkRelatedObjSettingMDT.PC_sObject__c;
                        String objectLookupFieldOnDocLog = docLinkRelatedObjSettingMDT.PC_Linked_Obj_Lookup_Field__c;

                        List<PC_FieldSet.ObjectFieldsDocLinkedWrapper> listOfObjectFieldsSetDocLinkedWrapper = new List<PC_FieldSet.ObjectFieldsDocLinkedWrapper>();

                        if (isObjectExist(objectName)) {

                            List<Schema.DescribeSObjectResult> describeSobjectsResult = Schema.describeSObjects(new List<String>{
                                    objectName
                            });
                            String objectLabel = describeSobjectsResult[0].getLabel();

                            if (docLinkRelatedObjSettingMDT.PC_Case_Lookup_Field__c != null && caseIdsList != null) {

                                //PC-4678: Added paramater docEngagementProgId to method call
                                Map<String,String> lookUpFieldDetails = new Map<String,String>();
                                lookUpFieldDetails.put('typeName',objectName);
                                lookUpFieldDetails.put('fsName',docLinkRelatedObjSettingMDT.PC_FieldSetName__c);
                                lookUpFieldDetails.put('recordId',recordId);
                                lookUpFieldDetails.put('lookupFieldName',docLinkRelatedObjSettingMDT.PC_Case_Lookup_Field__c);
                                lookUpFieldDetails.put('docId',docId);
                                lookUpFieldDetails.put('docEngagementProgId',docEngagementProgId);
                                listOfObjectFieldsSetDocLinkedWrapper = PC_FieldSet.getFieldsWithLookup(lookUpFieldDetails, caseIdsList);

                            } else if (docLinkRelatedObjSettingMDT.PC_Account_Lookup_Field__c != null) {

                                //PC-4678: Added paramater docEngagementProgId to method call
                                Map<String,String> lookUpFieldDetails1 = new Map<String,String>();
                                lookUpFieldDetails1.put('typeName',objectName);
                                lookUpFieldDetails1.put('fsName',docLinkRelatedObjSettingMDT.PC_FieldSetName__c);
                                lookUpFieldDetails1.put('recordId',recordId);
                                lookUpFieldDetails1.put('lookupFieldName',docLinkRelatedObjSettingMDT.PC_Account_Lookup_Field__c);
                                lookUpFieldDetails1.put('docId',docId);
                                lookUpFieldDetails1.put('docEngagementProgId',docEngagementProgId);
                                listOfObjectFieldsSetDocLinkedWrapper = PC_FieldSet.getFieldsWithLookup(lookUpFieldDetails1, null);

                            } else {

                                //PC-4678: Added paramater docEngagementProgId to method call
                                Map<String,String> lookUpFieldDetails2 = new Map<String,String>();
                                lookUpFieldDetails2.put('typeName',objectName);
                                lookUpFieldDetails2.put('fsName',docLinkRelatedObjSettingMDT.PC_FieldSetName__c);
                                lookUpFieldDetails2.put('recordId',recordId);
                                lookUpFieldDetails2.put('lookupFieldName',null);
                                lookUpFieldDetails2.put('docId',docId);
                                lookUpFieldDetails2.put('docEngagementProgId',docEngagementProgId);
                                listOfObjectFieldsSetDocLinkedWrapper = PC_FieldSet.getFieldsWithLookup(lookUpFieldDetails2, null);
                            }
                            if (listOfObjectFieldsSetDocLinkedWrapper.size() > 0) {
                                ObjectFieldsWrapper objectFieldsWrapper = new ObjectFieldsWrapper();
                                objectFieldsWrapper.objectName = objectName;
                                objectFieldsWrapper.objectLabel = objectLabel;
                                objectFieldsWrapper.listOfObjectFieldsSetDocLinkedWrapper = listOfObjectFieldsSetDocLinkedWrapper;
                                objectFieldsWrapper.objectColumnLabels = listOfObjectFieldsSetDocLinkedWrapper[0].fsListLabels;
                                objectFieldsWrapper.fsListApiNames = listOfObjectFieldsSetDocLinkedWrapper[0].fsListApiNames;
                                objectFieldsWrapper.objectLookupFieldOnDocLog = objectLookupFieldOnDocLog;
                                lstObjectFields.add(objectFieldsWrapper);
                            }
                        } else {
                            /*PC-4651: Custom exception is thrown if the object present on custom metadata is invalid.*/
                            List<Object> formattingArguments = new List<Object>{
                                    objectName, Label.PC_Doc_Link_Error_Msg
                            };
                            InvalidObjectException invalidObjectException = new InvalidObjectException(PC_FieldSet.getErrorMessage(Label.PC_InvalidObjectMessageTemplate, formattingArguments), PC_Constants.ERROR);
                            throw invalidObjectException;
                        }
                    }

                    if(lstObjectFields.size() == 0){
                        NoRecordsException noRecordsException = new NoRecordsException(Label.PC_NoPatientFound,PC_Constants.ERROR);
                        throw noRecordsException;
                    }

                } else {
                    /*PC-4651: Custom exception is thrown if no custom metadata records are found for an account record type.*/
                    NoRecordsException noRecordsException = new NoRecordsException(Label.PC_IncorrectAccountRecType, PC_Constants.ERROR);
                    throw noRecordsException;
                }

            }
        } catch (PC_FieldSet.ObjectNameException objNameException) {
            Exception e = objNameException;
            e.setMessage(objNameException.errorMessage);
            objectFieldsWrapperError = logExceptionDetails(objNameException);
            lstObjectFields.add(objectFieldsWrapperError);
        } catch (PC_FieldSet.FieldSetNullException fsException) {
            Exception e = fsException;
            e.setMessage(fsException.errorMessage);
            objectFieldsWrapperError = logExceptionDetails(fsException);
            lstObjectFields.add(objectFieldsWrapperError);
        } catch (PC_FieldSet.LookupFieldNameException lookupFldException) {
            Exception e = lookupFldException;
            e.setMessage(lookupFldException.errorMessage);
            objectFieldsWrapperError = logExceptionDetails(lookupFldException);
            lstObjectFields.add(objectFieldsWrapperError);
        } catch (NoRecordsException noRecordsException) {
            Exception e = noRecordsException;
            e.setMessage(noRecordsException.errorMessage);
            objectFieldsWrapperError = logExceptionDetails(noRecordsException);
            lstObjectFields.add(objectFieldsWrapperError);
        } catch (InvalidObjectException invalidObjectException) {
            Exception e = invalidObjectException;
            e.setMessage(invalidObjectException.errorMessage);
            objectFieldsWrapperError = logExceptionDetails(invalidObjectException);
            lstObjectFields.add(objectFieldsWrapperError);
        } catch (Exception e) {
            objectFieldsWrapperError = logExceptionDetails(e);
            lstObjectFields.add(objectFieldsWrapperError);
        }
        return JSON.serialize(lstObjectFields);

    }

    /*Author        : Hitha Avalakki
    * Method Name   : logExceptionDetails
    * Description   : Method to log exception details
    * Parameter     : Exception e
    * Return Type   : ObjectFieldsWrapper
    * */
    public static ObjectFieldsWrapper logExceptionDetails(Exception e) {
        ObjectFieldsWrapper objectFieldsWrapper = new ObjectFieldsWrapper();
        objectFieldsWrapper.isError = true;
        objectFieldsWrapper.errorMessage = e.getMessage();
        PC_Utility.createExceptionLog(e, e.getMessage());
        return objectFieldsWrapper;
    }

    /*********************************************************************************
   Class Name    : ObjectFieldsWrapper
   Author        : Hitha Avalakki
   Description   : Wrapper class for DocumentLinkObjectFieldSet
   *********************************************************************************/
    public inherited sharing class ObjectFieldsWrapper {
        @AuraEnabled public String objectName { get; set; }
        @AuraEnabled public String objectLabel { get; set; }
        @AuraEnabled public List<List<PC_FieldSet.FieldSet>> objectFieldsList { get; set; }
        @AuraEnabled public List<String> objectColumnLabels { get; set; }
        @AuraEnabled public List<PC_FieldSet.ObjectFieldsDocLinkedWrapper> listOfObjectFieldsSetDocLinkedWrapper { get; set; }
        @AuraEnabled public Boolean isError { get; set; }
        @AuraEnabled public Map<String, List<Id>> objectNameAndListIdsMap { get; set; }
        @AuraEnabled public String objectLookupFieldOnDocLog { get; set; }
        @AuraEnabled public List<String> fsListApiNames { get; set; }
        @AuraEnabled public String errorMessage { get; set; }

        ObjectFieldsWrapper() {
            objectFieldsList = new List<List<PC_FieldSet.FieldSet>>();
            objectColumnLabels = new List<String>();
            listOfObjectFieldsSetDocLinkedWrapper = new List<PC_FieldSet.ObjectFieldsDocLinkedWrapper>();
            objectName = PC_Constants.EMPTY_STRING;
            objectLabel = PC_Constants.EMPTY_STRING;
            isError = false;
            objectNameAndListIdsMap = new Map<String, List<Id>>();
            objectLookupFieldOnDocLog = PC_Constants.EMPTY_STRING;
            fsListApiNames = new List<String>();
            errorMessage = PC_Constants.EMPTY_STRING;
        }

    }

    /****************************************************************
    * Author        : Hitha Avalakki
    * Method Name   : hasSObjectField
    * Description   : Method to check if an Sobject has a field
    * Parameter     : SObject sobjectRecord,String fieldName
    * Return Type   : Boolean
    ****************************************************************/
    public static Boolean hasSObjectField(SObject sobjectRecord, String fieldName) {
        Boolean isFieldPresent = false;
        Schema.SObjectType objectType = sobjectRecord.getSObjectType();
        Schema.DescribeSObjectResult describe = objectType.getDescribe();
        Map<String, Schema.SObjectField> mapOfFields = describe.fields.getMap();
        for (String fieldNameString : mapOfFields.keySet()) {
            if (null != fieldNameString && null != fieldName) {
                if (fieldNameString.equalsIgnoreCase(fieldName)) {
                    isFieldPresent = true;
                }
            }
        }
        return isFieldPresent;
    }

    /****************************************************************
    * Author        : Hitha Avalakki
    * Method Name   : isObjectExist
    * Description   : Method to check if an Sobject exists
    * Parameter     : String objectNameParam
    * Return Type   : Boolean
    ****************************************************************/
    public static Boolean isObjectExist(String objectNameParam) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectNameParam);
        if (targetType != null) {
            return true;
        }
        return false;
    }

    /********************************************************************************
   Class Name           : NoRecordsException
   Description          : Hold the exception object if no records are found
                          in document link related object settings
   *********************************************************************************/
    public inherited sharing class NoRecordsException extends Exception {
        public String errorMessage;
        public String errorCode;

        public NoRecordsException(String message, String errorCode) {
            this.errorMessage = message;
            this.errorCode = errorCode;
        }
    }

    /********************************************************************************
   Class Name           : InvalidObjectException
   Description          : Hold the exception object if an object value is incorrect
                          in document link related object settings
   **********************************************************************************/
    public inherited sharing class InvalidObjectException extends Exception {
        public String errorMessage;
        public String errorCode;

        public InvalidObjectException(String message, String errorCode) {
            this.errorMessage = message;
            this.errorCode = errorCode;
        }
    }
}