/**
 * Created by vkashikar on 10/17/2019.
 * Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Shishir Bansal              06-Dec-2019            [PC-5792] Avoid hardcoding of string variable
Vijay Kashikar              21-Jan-2021            [PC-7102] Added sharing clause
Satheesh Kumar              09-Feb-2021            [PC-7373] Escape SOSL Reserved Characters in Search text and fixed PC search issues
*********************************************************************************/


public with sharing class PC_GetSearchResults implements PC_SearchResults.SearchProcessor2{

    private static final String ROW_ACTION_LAUNCH_PAP = 'PC_LAUNCH_PAP';
    private static final String ROW_ACTION_LAUNCH_COPAY = 'PC_LAUNCH_COPAY';
    private static final String ROW_ACTION_SHOW_DETAILS = PC_SearchResults.ROW_ACTION_SHOW_DETAILS;
    public static PC_SearchResults.SearchResult getResults(PC_SearchResults.SearchRequest request) {
        String identifier = request.identifier ;
        List<PC_SearchResults.SearchParam> searchParams = request.searchParams;
        String referenceObjectAPIName = request.referenceObjectAPIName;
        String referenceResultFieldSetAPIName = request.referenceResultFieldSetAPIName;
        List<String> defaultRowActions = request.defaultRowActions;
        if(String.isNotBlank(referenceObjectAPIName) && String.isNotBlank(referenceResultFieldSetAPIName)) {
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(referenceObjectAPIName);
            Schema.DescribeSObjectResult describe = targetType.getDescribe();

            List<PC_FieldSetController.FieldSetMember> members =
                    PC_FieldSetController.getFields(referenceObjectAPIName, referenceResultFieldSetAPIName);

            // lOOP
            List<String> fields = new List<String>();
            for(PC_FieldSetController.FieldSetMember member : members) {
                fields.add(member.fieldPath);
            }

            PC_Database.assertAccess(referenceObjectAPIName, PC_Database.Operation.Reading, fields);

            Map<String, String> searchParamsMap = new Map<String, String>();
            for(PC_SearchResults.SearchParam param : searchParams) {
                searchParamsMap.put(param.fieldAPIName, (param.fieldValue)?.trim());  // PC-7373 - Removed whitespaces
            }

            if(String.isNotBlank(identifier) && identifier.equalsIgnoreCase(PC_Constants.PC_PatientSearchIdentifier)) {
                String recordTypeId = PC_SYSTEM.recordTypeId('Account',PC_Constants.PATIENT_RECORD_TYPE);
                searchParamsMap.put(PC_Constants.RECORD_TYPE_ID, recordTypeId);
            }

            if(!searchParamsMap.isEmpty() && !fields.isEmpty()) {
                Integer queryLimit = 100;
                FilterCriteriaEncryptedFieldsWrapper soslFilterWrapper = getFilterCriteriaAndEncryptedFields(searchParamsMap, targetType.newSObject());
                String filterCriteria = soslFilterWrapper.filterCriteria;
                Map<string,string> encryptedFieldMap = soslFilterWrapper.encryptedFieldsAndValues;

                String searchString = '\'' + soslFilterWrapper.searchString + '\'';

                String searchQuery = 'FIND ' + searchString + ' IN ALL FIELDS RETURNING ' + referenceObjectAPIName + ' (Id,' + String.join(fields, ',');

                searchQuery = searchQuery + ' WHERE ' + filterCriteria + ' LIMIT ' + queryLimit + ')';
                system.debug('searchQuery-->'+searchQuery);
                List<List<SObject>>searchList=search.query(searchQuery);

                List<SObject> objects = searchList[0];
                List<SObject> filteredObjects = recordCuration(objects, encryptedFieldMap);
                PC_SearchResults.SearchResult searchResult = new PC_SearchResults.SearchResult();
                searchResult.rows = filteredObjects;
                searchResult.columns = getColumns(members);
                String title = filteredObjects.size() < queryLimit ?
                        '(' + String.valueOf(filteredObjects.size()) + ')' :
                        '(' + String.valueOf(filteredObjects.size()) + '+)';
                title = describe.getLabelPlural() + ' ' + title;
                searchResult.title = title;

                system.debug('1');
                system.debug(defaultRowActions);

                handleRowActions(request.defaultRowActions, searchResult);
                return searchResult;
            }
        }
        else {
            PC_SearchResults.ResultException e =
                    new PC_SearchResults.ResultException('Cannot continue without the object and result field set information');
            throw e;
        }
        return null;
    }

    private static void handleRowActions(List<String> defaultRowActions, PC_SearchResults.SearchResult searchResult) {
        handleShowDetailsAction(defaultRowActions, searchResult);
        handleOtherPCActions(defaultRowActions, searchResult, ROW_ACTION_LAUNCH_PAP);
        handleOtherPCActions(defaultRowActions, searchResult, ROW_ACTION_LAUNCH_COPAY);
    }
    private static void handleShowDetailsAction(List<String> defaultRowActions, PC_SearchResults.SearchResult searchResult) {
        if(
                // If we don't find PC_SHOW_DETAILS in custom actions,
                // then we should remove it as it gets added in the constructor. See interface code.
                (defaultRowActions == null || defaultRowActions.isEmpty())
                        ||
                        (defaultRowActions != null && !defaultRowActions.isEmpty()
                                && !defaultRowActions.contains(ROW_ACTION_SHOW_DETAILS))
                )
        {
            if(searchResult.customRowActions != null && !searchResult.customRowActions.isEmpty())
            {
                List<PC_SearchResults.Action> revisedActions = new List<PC_SearchResults.Action>();
                for(Integer i = 0; i < searchResult.customRowActions.size(); i++) {
                    PC_SearchResults.Action action = searchResult.customRowActions[i];
                    if(action.name == ROW_ACTION_SHOW_DETAILS) {
                        // Do not add it to revised actions list. As good as removed!
                        //Integer index = searchResult.customRowActions.indexOf(action);
                        //searchResult.customRowActions.remove(i);
                        //break;
                    }
                    else {
                        revisedActions.add(action);
                    }
                }
                searchResult.customRowActions = revisedActions;

            }
        }
    }

    private static void handleOtherPCActions(List<String> defaultRowActions, PC_SearchResults.SearchResult searchResult, String actionName) {
        if(
                defaultRowActions != null && !defaultRowActions.isEmpty()
                                && defaultRowActions.contains(actionName))

        {

            if(searchResult.customRowActions == null || searchResult.customRowActions.isEmpty())
            {
                searchResult.customRowActions = new List<PC_SearchResults.Action>();
            }
            List<PC_SearchResults.Action> revisedActions = searchResult.customRowActions;

            if(actionName == ROW_ACTION_LAUNCH_PAP) {
                PC_SearchResults.Action papAction = new PC_SearchResults.Action();
                papAction.name = ROW_ACTION_LAUNCH_PAP;
                papAction.label = Label.PC_SearchActionLaunchPAP;
                papAction.actionType = PC_SearchResults.ActionType.OPEN_COMPONENT;
                revisedActions.add(papAction);
            }
            else if(actionName == ROW_ACTION_LAUNCH_COPAY) {
                PC_SearchResults.Action copayAction = new PC_SearchResults.Action();
                copayAction.name = ROW_ACTION_LAUNCH_COPAY;
                copayAction.label = Label.PC_SearchActionLaunchCopay;
                copayAction.actionType = PC_SearchResults.ActionType.OPEN_COMPONENT;
                revisedActions.add(copayAction);
            }
            searchResult.customRowActions = revisedActions;
        }
    }

    /*****************************************************************************************************
    * Author       : Haritha Reddy
    * Parameters   : List<SObject> Records to be filtered, Map<String, String> Encrypted Field names and Values
    * Method name  : recordCuration
    * Return Type  : List<sObject>
    * Description  : This method removes records that don't match the search criteria.
    *                As Salesforce doesn't allow Encrypted Fields to be used in Where clause of SOSL or SOQL,
    *                this is mostly used to filter records.
    *****************************************************************************************************/
    private static List<sObject> recordCuration(List<sObject> sObjectList, Map<String, String> fsFieldsMap) {
        if(!fsFieldsMap.isEmpty()){
            List<sObject> filteredsObjectList = new List<sObject>();
            Set<sObject> filteredObjectSet = new Set<sObject>();
            Map<String,Object> objMap = new Map<String,Object>();

            for(sObject obj : sObjectList) {
                objMap = obj.getPopulatedFieldsAsMap();
                Integer mismatch = 0;
                for (String fieldAPI : fsFieldsMap.keySet()) {
                    Object fieldValue = objMap.get(fieldAPI);
                    if(String.isNotBlank(fsFieldsMap.get(fieldAPI)) && String.isNotBlank(String.valueOf(objMap.get(fieldAPI))) && mismatch == 0) {
                        if (String.valueOf(objMap.get(fieldAPI)).containsIgnoreCase(fsFieldsMap.get(fieldAPI))) {
                            filteredObjectSet.add(obj);
                        }else{
                            filteredObjectSet.remove(obj);
                            mismatch = 1;
                        }
                    }
                }
            }
            filteredsObjectList.addAll(filteredObjectSet);
            return filteredsObjectList;
        }else{
            return sObjectList;
        }
    }

    private static List<PC_SearchResults.Column> getColumns(List<PC_FieldSetController.FieldSetMember> members) {
        List<PC_SearchResults.Column> columns = new List<PC_SearchResults.Column>();
        for(PC_FieldSetController.FieldSetMember member : members) {
            PC_SearchResults.Column column = new PC_SearchResults.Column();
            column.label = member.label;
            column.fieldName = member.fieldPath;
            column.type = member.type;
            columns.add(column);
        }
        return columns;
    }

    /*****************************************************************************************************
    * Author       : Haritha Reddy
    * Parameter    : Map<String,String> fsFieldsMap,SObject sObj
    * Method name  : getFilterCriteriaAndEncryptedFields
    * Return Type  : Map<String, String>
    * Description  : This method is used to get Where Clause String used in SOSL and a
    *                Map of Encrypted Fields and corresponding search values in specified SObject
    *****************************************************************************************************/
    public static FilterCriteriaEncryptedFieldsWrapper getFilterCriteriaAndEncryptedFields(Map<String,String> fsFieldsMap,SObject sObj) {
        Map<String, String> encryptedSearchFieldMap = new Map<String, String>();
        String filterCriteriaWhereClause = PC_Constants.EMPTY_STRING;
        List<String> filterCriteria = new List<String>();
        Map<String, Schema.DisplayType> fieldNameFieldTypeMap = new Map<String, Schema.DisplayType>();
        Schema.SObjectType sObjType = sObj.getSObjectType();
        Map<String, Schema.SObjectField> fieldDetailsMap = sObjType.getDescribe().fields.getMap();
        String searchString = PC_Constants.EMPTY_STRING;

        try {
            /*** Run through fieldDetailsMap and create a map fieldName is the key, i.e. field API name is key and field's DescribeFieldResult object is the value ***/
            for (String fieldDetailKey : fieldDetailsMap.keySet()) {
                Schema.SObjectField fieldDetail = fieldDetailsMap.get(fieldDetailKey);
                fieldNameFieldTypeMap.put(fieldDetailKey.toUpperCase(), fieldDetail.getDescribe().getType());
            }
            /*** Run through the fsFieldsMap and create a list of those field API names which are to be included in WHERE clause of SOSL query ***/
            for (String fieldsMapKey : fsFieldsMap.keySet()) {

                //Following check is required if any of the fieldSet field has been left blank, so as we don't include them in the where clause our SOSL query
                if (!String.isEmpty(fsFieldsMap.get(fieldsMapKey)) || fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.BOOLEAN) {

                    if(!String.isEmpty(fieldsMapKey)){
                        //Build Search String for searchable fields
                        if(fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.STRING ||
                                fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.EMAIL ||
                                fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.PHONE ){
                            searchString += ' ' + PC_Utility.escapeSoslSearchText(fsFieldsMap.get(fieldsMapKey)) + '*';  // PC-7373 - Escape SOSL Reserved Characters
                        }

                        Boolean isFieldEncrypted = Schema.getGlobalDescribe().get(String.valueOf(sObjType)).getDescribe().fields.getMap().get(fieldsMapKey).getDescribe().isEncrypted();
                        //Add encrypted Fields into a Map and Build filterCriteria String to be used in Where Clause
                        if(isFieldEncrypted) {
                            encryptedSearchFieldMap.put(fieldsMapKey,fsFieldsMap.get(fieldsMapKey));
                        }
                        else if(fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.STRING||
                                fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.EMAIL){
                            filterCriteria.add(fieldsMapKey + ' LIKE \'%' + String.escapeSingleQuotes(fsFieldsMap.get(fieldsMapKey))+'%\'');  // PC-7373 - Escape Single Quotes
                        }
                        else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.DATE ||
                                fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.DATETIME) {
                            filterCriteria.add(fieldsMapKey + ' = ' + fsFieldsMap.get(fieldsMapKey));
                        }
                        else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.BOOLEAN) {
                            filterCriteria.add(fieldsMapKey + ' = ' + Boolean.valueOf(fsFieldsMap.get(fieldsMapKey)));
                        }
                        else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.MULTIPICKLIST) {
                            filterCriteria.add(fieldsMapKey + ' INCLUDES (\'' + String.valueOf(fsFieldsMap.get(fieldsMapKey))+'\')');
                        }
                        else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.INTEGER) {
                            filterCriteria.add(fieldsMapKey + ' = ' + fsFieldsMap.get(fieldsMapKey));
                        }
                        else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.LONG) {
                            filterCriteria.add(fieldsMapKey + ' = ' + Long.valueOf(fsFieldsMap.get(fieldsMapKey)));
                        }
                        else if (fieldNameFieldTypeMap.get(fieldsMapKey.toUpperCase()) == Schema.DisplayType.DOUBLE) {
                            filterCriteria.add(fieldsMapKey + ' = ' + Double.valueOf(fsFieldsMap.get(fieldsMapKey)));
                        }
                        else {
                            filterCriteria.add(fieldsMapKey + ' = \'' + String.valueOf(fsFieldsMap.get(fieldsMapKey))+'\'');
                        }
                        filterCriteriaWhereClause = String.join(filterCriteria, ' AND ');
                    }
                }
            }

        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        FilterCriteriaEncryptedFieldsWrapper wrapperObj = new FilterCriteriaEncryptedFieldsWrapper();
        wrapperObj.searchString = searchString;
        wrapperObj.filterCriteria = filterCriteriaWhereClause;
        wrapperObj.encryptedFieldsAndValues = encryptedSearchFieldMap;
        return wrapperObj;
    }

    /*****************************************************************************************************
    * Author       : Haritha Reddy
    * Method name  : FilterCriteriaEncryptedFieldsWrapper
    * Description  : Wrapper class to hold filter Criteria String that is used in the WHERE clause of SOSL query to search patients records
                     and map of Encrypted Fields & their corresponding search values
    *****************************************************************************************************/
    public inherited sharing class FilterCriteriaEncryptedFieldsWrapper{
        @AuraEnabled public String filterCriteria {get;set;}
        @AuraEnabled public Map<String, String> encryptedFieldsAndValues{get; set;}
        public String searchString;

        public FilterCriteriaEncryptedFieldsWrapper(String filterCriteria ,Map<String, String> encryptedFieldsAndValues) {
            filterCriteria = filterCriteria;
            encryptedFieldsAndValues = encryptedFieldsAndValues;
            searchString = PC_Constants.EMPTY_STRING;
        }
        public FilterCriteriaEncryptedFieldsWrapper() {
        }
    }

}