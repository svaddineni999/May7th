/*********************************************************************************
Class Name      : PC_FieldSet
Description     : Controller class used for PC_FieldSet.cmp (lightning)
Created By      : Deloitte               
Created Date    : March 31, 2017
Modification Log:
---------------------------------------------------------------------------------- 
Developer              Date                   Description
-----------------------------------------------------------------------------------            
Tejas Patel           March 31, 2017           Initial Version
Ajinkya Deshmukh	  June 21, 2017			   with sharing added
Ajinkya Deshmukh	  Aug 1, 2017			   [PC-1973] Updated FieldSet class to handle other data types
Ajinkya Deshmukh	  Aug 2, 2017			   [PC-1973] Added null check for lookup fields
Hitha Avalakki        Mar 26, 2019             [PC-4651] Added custom exception classes:FieldSetNullException, LookupFieldNameException, ObjectNameException
                                               and corresponding logic to handle exceptions related to Document linking so as user can be notified with appropriate error message.
Hitha Avalakki        Mar 29, 2019             [PC-4678] Added a separate inner query to fetch case record ids required to fetch sobject records related to case object.
Hitha Avalakki        April 02,2019            [PC-4696] Replaced custom labels related to document linking errors with String templates and introduced getErrorMessage() method callout for the same
Shishir Bansal        06-Dec-2019              [PC-5792] Avoid hardcoding of string variable
Kishore Kanteti       11-Dec-2019              [PC-5795] Reduced the parameters for getFieldsWithLookup Method
Haritha Reddy         16-Dec-2019              [PC-5791] Added error handling for getFields Method
Tejas Patel           30-June-2020             [PC-6401] Replacing the FieldSet callout with new getListFieldSet callout to eliminate SOQL query in getFieldsWithLookup method.
Haritha Reddy         21-Jan-2021              [PC-7102] Added FLS Check
Haritha Reddy         21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/
public with sharing class PC_FieldSet {
    @AuraEnabled
    public static List<FieldSet> getFields(String typeName, String fsName, Id recordId) {
        List<FieldSet> finalfieldset = new List<FieldSet>();
        try {
            if(String.isNotBlank(typeName)){
                typeName = String.escapeSingleQuotes(typeName);
            }
            if(String.isNotBlank(fsName)){
                fsName = String.escapeSingleQuotes(fsName);
            }
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(typeName);
            Schema.DescribeSObjectResult describe = targetType.getDescribe();
            Map<String, Schema.FieldSet> fsMap = describe.fieldSets.getMap();
            Schema.FieldSet fs = fsMap.get(fsName);
            List<Schema.FieldSetMember> fieldSet = fs.getFields();
            Schema.SObjectType objectType = fs.getSObjectType();
            List<FieldSetMember> fset = new List<FieldSetMember>();
            for (Schema.FieldSetMember f : fieldSet) {
                fset.add(new FieldSetMember(f));
            }
            List<String> fsList = new List<String>();
            List<String> fsListtoLabel = new List<String>();
            List<String> fsListLabels = new List<String>();
            List<String> fsListType = new List<String>();
            List<String> fsListToQuery = new List<String>();

            for (Schema.FieldSetMember f : fieldSet) {
                if(f.getType().name().toUpperCase() == 'REFERENCE'){
                    String nameField = getNameFieldForSObject(f);
                    String relationShipName = f.getSObjectField().getDescribe().getRelationshipName();
                    List<Schema.sObjectType> relationShipObject = f.getSObjectField().getDescribe().getReferenceTo();
                    Schema.DescribeSObjectResult lookupObject = relationShipObject[0].getDescribe();
                    String lookupObjectNameString = lookupObject.getLocalName();
                    if(lookupObjectNameString == PC_Constants.PC_RecordTypeDeveloperName){
                        nameField = 'DeveloperName';
                        fsListToQuery.add(relationShipName+'.'+nameField);
                    }else{
                        fsListToQuery.add(relationShipName+'.'+nameField);
                    }
                }else{
                    fsListToQuery.add(f.getFieldPath());
                }
                fsList.add(f.getFieldPath());
                fsListLabels.add(f.getLabel());
                fsListType.add(f.getType().name());
            }

            /*for (Integer i = 0; i < fset.size(); i++) {
                fsList.add(fset.get(i).fieldPath);
                if (fset.get(i).type.toUpperCase() == 'PICKLIST' || fset.get(i).type.toUpperCase() == 'MULTIPICKLIST') {
                    fsListtoLabel.add('toLabel(' + fset.get(i).fieldPath + ')');
                } else {
                    fsListtoLabel.add(fset.get(i).fieldPath);
                }
                fsListLabels.add(fset.get(i).label);
                fsListType.add(fset.get(i).type);
            }*/

            String query = PC_Constants.EMPTY_STRING + String.join(fsListToQuery, ', ');
            query = 'SELECT ' + query + ' ' + 'FROM ' + typeName +
                    ' WHERE ' + ' Id' + '=' + '\'' + recordId + '\'' + ' Limit 1';

            List<sObject> temp = Database.query(query);
            FieldSet tempfieldset;

            Map<Id,List<FieldSet>> returnedMapFieldSet = new Map<Id,List<FieldSet>>();
            returnedMapFieldSet = getListFieldSet(temp, fsList);
            finalfieldset = returnedMapFieldSet.get(recordId);

            /*for (Integer i = 0; i < temp.size(); i++) {
                for (Integer j = 0; j < fsList.size(); j++) {
                    tempfieldset = new FieldSet(temp[i], fsList[j], fsListLabels[j], fsListType[j]);
                    finalfieldset.add(tempfieldset);
                }
            }*/
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return finalfieldset;
    }

    //Mayuresh patil - added new method getFieldsWithLookup to get fields for document linking when there is addional lookup field
    //Hitha Avalakki - edited the method getFieldsWithLookup for fetching the document records related to account and case
    @AuraEnabled
    public static List<ObjectFieldsDocLinkedWrapper> getFieldsWithLookup(Map<String,String> lookUpFieldDetails , List<String> lookupIds) {
        String typeName = '';
        typeName = lookUpFieldDetails.get('typeName');
        String fsName = '';
        fsName = lookUpFieldDetails.get('fsName');
        Id recordId = (Id) lookUpFieldDetails.get('recordId');
        String lookupFieldName = '';
        lookupFieldName = lookUpFieldDetails.get('lookupFieldName');
        String docId = '';
        docId = lookUpFieldDetails.get('docId');
        String docEngagementProgId = '';
        docEngagementProgId = lookUpFieldDetails.get('docEngagementProgId');

        List<ObjectFieldsDocLinkedWrapper> listOfObjectFieldsSetDocLinkedWrapper = new List<PC_FieldSet.ObjectFieldsDocLinkedWrapper>();
        try{
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(typeName);
            Schema.DescribeSObjectResult describe = targetType.getDescribe();
            Map<String, Schema.FieldSet> fsMap = describe.fieldSets.getMap();
            Schema.FieldSet fs = fsMap.get(fsName);
            /*PC-4651: Custom exception is thrown if the fieldset name is incorrect on custom metadata.*/
            if(fs==null){

                if(fsName==null){
                    //[PC-4696]: Used string templates to create cusomtized document linking errors
                    List<Object> formattingArguments=new List<Object>{describe.label,Label.PC_Doc_Link_Error_Msg};
                    FieldSetNullException fieldSetNullException=new FieldSetNullException(getErrorMessage(Label.PC_FieldSetNullMessageTemplate,formattingArguments),PC_Constants.ERROR);
                    throw fieldSetNullException;
                }

                //[PC-4696]: Used string templates to create cusomtized document linking errors
                List<Object> formattingArguments=new List<Object>{fsName,describe.label,Label.PC_Doc_Link_Error_Msg};
                FieldSetNullException fieldSetNullException=new FieldSetNullException(getErrorMessage(Label.PC_FieldSetIncorrectMessageTemplate,formattingArguments),PC_Constants.ERROR);
                throw fieldSetNullException;
            }
            List<Schema.FieldSetMember> fieldSet = fs.getFields();
            Schema.SObjectType objectType = fs.getSObjectType();

            List<String> fsList = new List<String>();
            List<String> fsListLabels = new List<String>();
            List<String> fsListType = new List<String>();
            List<String> fsListToQuery = new List<String>();

            for (Schema.FieldSetMember f : fieldSet) {
                if(f.getType().name().toUpperCase() == 'REFERENCE'){

                    String nameField = getNameFieldForSObject(f);
                    String relationShipName = f.getSObjectField().getDescribe().getRelationshipName();
                    List<Schema.sObjectType> relationShipObject = f.getSObjectField().getDescribe().getReferenceTo();
                    Schema.DescribeSObjectResult lookupObject = relationShipObject[0].getDescribe();
                    String lookupObjectNameString = lookupObject.getLocalName();
                    if(lookupObjectNameString == PC_Constants.PC_RecordTypeDeveloperName){
                        nameField = 'DeveloperName';
                        fsListToQuery.add(relationShipName+'.'+nameField);
                    }else{
                        fsListToQuery.add(relationShipName+'.'+nameField);
                    }
                }else{
                    fsListToQuery.add(f.getFieldPath());
                }
                fsList.add(f.getFieldPath());
                fsListLabels.add(f.getLabel());
                fsListType.add(f.getType().name());
            }

            String fields = PC_Constants.EMPTY_STRING + String.join(fsListToQuery, ', ');

            String finalQuery = 'SELECT Id,' + fields + ' ' + 'FROM ' + typeName;

            if (PC_Constants.PC_ACCOUNT.equalsIgnoreCase(typeName)) {
                String whereClause = ' WHERE ' + ' Id ' + '=' + '\'' + recordId + '\'';
                finalQuery = finalQuery + whereClause;
            } else if (PC_Constants.PC_CASE.equalsIgnoreCase(typeName)) {
                String whereClause = ' WHERE ' + ' AccountId ' + '=' + '\'' + recordId + '\'';
                finalQuery = finalQuery + whereClause;

            } else if (null != lookupIds) {
                if(lookupFieldName!=null) {

                    /*PC-4651: Custom exception is thrown if the Lookup Field name is incorrect on custom metadata.*/
                    if(describe.fields.getMap()!=null && !describe.fields.getMap().keySet().contains(lookupFieldName.toLowerCase())){

                        //[PC-4696]: Used string templates to create cusomtized document linking errors
                        List<Object> formattingArguments=new List<Object>{lookupFieldName,describe.getLabel(),Label.PC_Doc_Link_Error_Msg};
                        LookupFieldNameException lookupFieldNameError=new LookupFieldNameException(getErrorMessage(Label.PC_CaseLookupFldNameIncorrectMessageTemplate, formattingArguments),PC_Constants.ERROR);
                        throw lookupFieldNameError;
                    }
                    if (!lookupIds.isEmpty()) {

                        /*PC-4678: Following inner query string: 'caseInnerQuery' has been devised to fetch case Ids as per account record and document engagement program.
                        This helps to deal with the scenario where there are more than 10 cases for an Account record. Appending individual case ids in a string as comma
                        separated values causes issues as a String object can hold only limited number of characters and hence few of the case ids would be skipped as
                        Apex automatically truncates the values after a certain limit.*/
                        String caseInnerQuery='(SELECT Id FROM Case WHERE AccountId =:recordId and PC_Engagement_Program__c =:docEngagementProgId)';

                        String whereClause = ' WHERE ' + lookupFieldName + ' IN '+ caseInnerQuery;
                        finalQuery = finalQuery + whereClause;

                    } else {
                        String whereClause = ' WHERE ' + lookupFieldName + '=' + '\'' + +'\'';
                        finalQuery = finalQuery + whereClause;
                    }
                }else{
                    /*PC-4651: Custom exception is thrown if the Lookup Field name is null on custom metadata.*/
                    //[PC-4696]: Used string templates to create cusomtized document linking errors
                    List<Object> formattingArguments=new List<Object>{describe.getLabel(),Label.PC_Doc_Link_Error_Msg};
                    LookupFieldNameException lookupFieldNameNullException=new LookupFieldNameException(getErrorMessage(Label.PC_LookupFldNameNullMessageTemplate, formattingArguments),PC_Constants.ERROR);
                    throw lookupFieldNameNullException;
                }
            } else {
                if(lookupFieldName!=null) {
                    /*PC-4651: Custom exception is thrown if the Lookup Field name is incorrect on custom metadata.*/
                    if(describe.fields.getMap()!=null && !describe.fields.getMap().keySet().contains(lookupFieldName.toLowerCase())){

                        //[PC-4696]: Used string templates to create cusomtized document linking errors
                        List<Object> formattingArguments=new List<Object>{lookupFieldName,describe.label,Label.PC_Doc_Link_Error_Msg};
                        LookupFieldNameException lookupFieldNameError=new LookupFieldNameException(getErrorMessage(Label.PC_AccountLookupFldNameIncorrectMessageTemplate, formattingArguments),PC_Constants.ERROR);
                        throw lookupFieldNameError;
                    }
                    String whereClause = ' WHERE ' + lookupFieldName + '=' + '\'' + recordId + '\'';
                    finalQuery = finalQuery + whereClause;
                }else{
                    /*PC-4651: Custom exception is thrown if the Lookup Field name is null on custom metadata.*/
                    //[PC-4696]: Used string templates to create cusomtized document linking errors
                    List<Object> formattingArguments=new List<Object>{describe.getLabel(),Label.PC_Doc_Link_Error_Msg};
                    LookupFieldNameException lookupFieldNameNullException=new LookupFieldNameException(getErrorMessage(Label.PC_LookupFldNameNullMessageTemplate, formattingArguments),PC_Constants.ERROR);
                    throw lookupFieldNameNullException;
                }
            }
            List<sObject> temp = Database.query(finalQuery);

            List<FieldSet> finalfieldset = new List<FieldSet>();
            FieldSet tempfieldset;

            List<String> documentLogAssociationRecIds = new List<String>();

            List<String> documentLogFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Association_Record_Id__c'),PC_Constants.getQualifiedAPIName('PC_Document__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'),PC_Database.Operation.Reading, documentLogFields);

            List<PC_Document_Log__c> docModLogRecords = [SELECT PC_Association_Record_Id__c FROM PC_Document_Log__c WHERE PC_Document__c = :docId];

            for (PC_Document_Log__c docLogObj : docModLogRecords) {
                documentLogAssociationRecIds.add(docLogObj.PC_Association_Record_Id__c);
            }

            Map<Id,List<FieldSet>> returnedMapFieldSet = new Map<Id,List<FieldSet>>();
            returnedMapFieldSet = getListFieldSet(temp, fsList);

            ObjectFieldsDocLinkedWrapper objectFieldsDocLinkedWrapper;

            if ((null != temp) && (!temp.isEmpty())) {

                for(sObject t : temp){
                    List<FieldSet> fieldSetList = returnedMapFieldSet.get(t.Id);
                    objectFieldsDocLinkedWrapper = new ObjectFieldsDocLinkedWrapper();

                    if(documentLogAssociationRecIds.contains((String) t.Id)){
                        objectFieldsDocLinkedWrapper.isLinked = true;
                        objectFieldsDocLinkedWrapper.persistedLinkedUnlinkedStatus=true;
                    }
                    objectFieldsDocLinkedWrapper.recordId=t.Id;
                    objectFieldsDocLinkedWrapper.fsListApiNames = fsList;
                    objectFieldsDocLinkedWrapper.fieldSetList = fieldSetList;
                    objectFieldsDocLinkedWrapper.fsListLabels = fsListLabels;
                    listOfObjectFieldsSetDocLinkedWrapper.add(objectFieldsDocLinkedWrapper);
                }
            }

        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }

        return listOfObjectFieldsSetDocLinkedWrapper;
    }

    public inherited sharing class ObjectFieldsDocLinkedWrapper{
        @AuraEnabled public List<FieldSet> fieldSetList {get;set;}
        @AuraEnabled public Boolean isLinked {get;set;}
        @AuraEnabled public List<String> fsListLabels {get;set;}
        @AuraEnabled public Id recordId {get;set;}
        @AuraEnabled public Boolean persistedLinkedUnlinkedStatus {get;set;}
        @AuraEnabled public List<String> fsListApiNames {get;set;}

        ObjectFieldsDocLinkedWrapper(){
            fieldSetList=new List<PC_FieldSet.FieldSet>();
            fsListLabels=new List<String>();
            fsListApiNames=new List<String>();
            isLinked=false;
            persistedLinkedUnlinkedStatus=false;
        }
    }


    public inherited sharing class FieldSetMember {
        
        public FieldSetMember(Schema.FieldSetMember f) {
            this.DBRequired = f.DBRequired;
            this.fieldPath = f.fieldPath;
            this.label = f.label;
            this.required = f.required;
            this.type = PC_Constants.EMPTY_STRING + f.getType();
        }
        
        public FieldSetMember(Boolean DBRequired) {
            this.DBRequired = DBRequired;
        }
        
        @AuraEnabled
        public Boolean DBRequired { get;set; }
        
        @AuraEnabled
        public String fieldPath { get;set; }
        
        @AuraEnabled
        public String label { get;set; }
        
        @AuraEnabled
        public Boolean required { get;set; }
        
        @AuraEnabled
        public String type { get; set; }
    }
    
    //FieldSet
    public inherited sharing class FieldSet {
        @AuraEnabled public String label{get; set;}
        @AuraEnabled public String value{get; set;}
        public FieldSet() {
        }
        public FieldSet(sObject a, String fsList, String fsListLabels, String fsListType) {
            label	= fsListLabels;
            
            if(fsListType == 'DATE') {
                value = (String.valueOf(Date.valueOf(a.get(fsList))));
            } else if(fsListType == 'DATETIME'){
                    value	= (String.valueOf(Datetime.valueOf(a.get(fsList))));
            } else if (fsListType == 'BOOLEAN') {
                value = (a.get(fsList) == true) ? 'true' : 'false';
            }else if (fsListType == 'INTEGER' || fsListType == 'DOUBLE') {
                value = String.valueOf(a.get(fsList));
            }else if (fsListType == 'REFERENCE') {
                if (String.valueOf(a.get(fsList)) != null) {
                    Id recId = (Id) String.valueOf(a.get(fsList));
                	value = (String) Database.query('SELECT Name FROM ' + recId.getSobjectType() + ' WHERE Id =: recId')[0].get('Name');
                }
                
            }
            else if('Percent'==fsListType&&null!=a.get(fsList)){
                Double percentValue=Double.valueOf(a.get(fsList));
                value=String.valueOf(percentValue);
            }
            else {
                value	= (String) (a.get(fsList));
            }
        }
    }

    /********************************************************************************
   Mthod Name           : getListFieldSet
   Description          : Return a List of FieldSet
   Author               : Tejas Patel
   *********************************************************************************/
    public static Map<Id,List<FieldSet>> getListFieldSet(List<sObject> ListsObj, List<String> fieldList){
        Map<Id,List<FieldSet>> returnMapFieldSet = new Map<Id,List<FieldSet>>();
        for(sObject a : ListsObj){
            Schema.SObjectType sObj = a.getSObjectType();
            Schema.DescribeSObjectResult sObjDetails = sObj.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = sObjDetails.fields.getMap();
            Set<String> objectFields = fieldMap.keySet();
            List<FieldSet> returnFieldSet = new List<FieldSet>();
            Map<String,Object> populatedObject = a.getPopulatedFieldsAsMap();
            Set<String> populatedFields = populatedObject.keySet();

            for (String fieldName : fieldList) {
                FieldSet fsToAdd = new FieldSet();
                Schema.sObjectField fld = fieldMap.get(fieldName);
                Schema.DescribeFieldResult flsResult = fld.getDescribe();
                Schema.DisplayType fType = flsResult.type;
                String fsListType = fType.name();
                String fsList = flsResult.getName();
                fsToAdd.label = flsResult.getLabel();
                fsToAdd.value = PC_Constants.EMPTY_STRING;
                if (populatedFields.contains(fieldName)) {
                    if (fsListType == 'DATE') {
                        fsToAdd.value = (String.valueOf(Date.valueOf(a.get(fsList))));
                    } else if (fsListType == 'DATETIME') {
                        fsToAdd.value = (String.valueOf(Datetime.valueOf(a.get(fsList))));
                    } else if (fsListType == 'BOOLEAN') {
                        fsToAdd.value = (a.get(fsList) == true) ? 'true' : 'false';
                    } else if (fsListType == 'INTEGER' || fsListType == 'DOUBLE') {
                        fsToAdd.value = String.valueOf(a.get(fsList));
                    } else if (fsListType == 'REFERENCE') {
                        String relationShipName = flsResult.getRelationshipName();
                        String nameField = 'Name';
                        List<Schema.sObjectType> lookupObjectName = flsResult.getReferenceTo();
                        Schema.DescribeSObjectResult lookupObject = lookupObjectName[0].getDescribe();

                        String lookupObjectNameString = lookupObject.getLocalName();

                        if(lookupObjectNameString == PC_Constants.PC_RecordTypeDeveloperName){
                            Map<String, Schema.RecordTypeInfo> recordTypeInfo = sObjDetails.getRecordTypeInfosByDeveloperName();
                            nameField = 'DeveloperName';
                            fsToAdd.value = recordTypeInfo.get((String) a.getSobject(relationShipName).get(nameField)).getName();
                            //fsToAdd.value = (String) a.getSobject(relationShipName).get(nameField);
                        }else{
                            Map<String, Schema.SObjectField> LookupfieldMap = lookupObjectName[0].getDescribe().fields.getMap();
                            for (String LookupfieldName : LookupfieldMap.keySet()) {
                                Schema.DescribeFieldResult eachFieldResult = LookupfieldMap.get(LookupfieldName).getDescribe();
                                if (eachFieldResult.isNameField()) {
                                    nameField = eachFieldResult.getName();
                                    break;
                                }
                            }
                            if (a.getSobject(relationShipName).get(nameField) != null) {
                                fsToAdd.value = (String) a.getSobject(relationShipName).get(nameField);
                            } else {
                                fsToAdd.value = PC_Constants.EMPTY_STRING;
                            }
                        }
                    } else if (fsListType == 'PERCENT') {
                        Double percentValue = Double.valueOf(a.get(fsList));
                        fsToAdd.value = String.valueOf(percentValue);
                    } else if (fsListType == 'PICKLIST' || fsListType == 'MULTIPICKLIST') {
                        List<Schema.PicklistEntry> lstPicklistValue = flsResult.getPicklistValues();
                        for(Schema.PicklistEntry p : lstPicklistValue){
                            if(p.getValue() == String.valueOf(a.get(fsList))){
                                fsToAdd.value = p.getLabel();
                                break;
                            }
                        }
                    } else {
                        fsToAdd.value = (String) (a.get(fsList));
                    }
                }
                returnFieldSet.add(fsToAdd);
            }
            returnMapFieldSet.put(a.Id,returnFieldSet);
        }
        return returnMapFieldSet;
    }

    /********************************************************************************
   Class Name           : FieldSetNullException
   Description          : Hold the exception object if fieldset is null
   *********************************************************************************/
    public inherited sharing class FieldSetNullException extends Exception{
        public String errorMessage;
        public String errorCode;

        public FieldSetNullException(String message,String errorCode){
            this.errorMessage=message;
            this.errorCode=errorCode;
        }
    }

    /********************************************************************************
   Class Name           : FieldSetNullException
   Description          : Hold the exception object if fieldset is null
   *********************************************************************************/
    public inherited sharing class LookupFieldNameException extends Exception{
        public String errorMessage;
        public String errorCode;

        public LookupFieldNameException(String message,String errorCode){
            this.errorMessage=message;
            this.errorCode=errorCode;
        }
    }
    /********************************************************************************
   Class Name           : FieldSetNullException
   Description          : Hold the exception object if fieldset is null
   *********************************************************************************/
    public inherited sharing class ObjectNameException extends Exception{
        public String errorMessage;
        public String errorCode;

        public ObjectNameException(String message,String errorCode){
            this.errorMessage=message;
            this.errorCode=errorCode;
        }
    }

   /********************************************************************************
   Mthod Name           : getErrorMessage
   Description          : Returns the customized error message constructed using string template
   Author               : Hitha Avalakki
   *********************************************************************************/
    public static String getErrorMessage(String errorMessageTemplate, List<Object> formattingArguments){
        return String.format(errorMessageTemplate, formattingArguments);
    }

    /*********************************************************************************
   Method Name    : getNameFieldForSObject
   Description    : This method fetches the Name Field for a SObject, if it is available.
                    If not, it will get the value of first Auto number field in a particular SObject.
   Return Type    : String
   Parameter      : sObjectAPIName
   *********************************************************************************/
    private static String getNameFieldForSObject(Schema.FieldSetMember fsm){
        String nameField = 'Name';
        try {
            if (fsm != null) {
                if (fsm.getSObjectField().getDescribe().isNamePointing()) {
                    String errorMessage = fsm.getLabel() + ' Field has multiple parent objects remove from fieldset';
                    LookupFieldNameException lookupFieldNameError = new LookupFieldNameException(errorMessage, PC_Constants.ERROR);
                }
                List<Schema.sObjectType> lookupObjectName = fsm.getSObjectField().getDescribe().getReferenceTo();
                Schema.DescribeSObjectResult lookupObject = lookupObjectName[0].getDescribe();
                Map<String, Schema.SObjectField> fieldMap = lookupObjectName[0].getDescribe().fields.getMap();
                for (String fieldName : fieldMap.keySet()) {
                    Schema.DescribeFieldResult eachFieldResult = fieldMap.get(fieldName).getDescribe();
                    if (eachFieldResult.isNameField()) {
                        nameField = eachFieldResult.getName();
                        break;
                    }
                }
            }
        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return nameField;
    }
}