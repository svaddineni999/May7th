/*********************************************************************************
Modification Log  :
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy            10-Oct-2019              Initial Version
Shishir Bansal           06-Dec-2019              [PC-5792] Avoid hardcoding of string variable
Haritha Reddy             21-Jan-2021                 [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/
/**
 * Class with the interface SearchProcessor to qualify the implementing class as a valid Search Result class.
 */
global with sharing class PC_SearchResults {

    public static final String ROW_ACTION_SHOW_DETAILS = 'PC_SHOW_DETAILS';
    /**
    * Implement the interface SearchProcessor to qualify the class as a valid Search Result class.
    */
    global interface SearchProcessor {
        /**
         * performs search based on the search Form Fields Input and provides search Result with search Result Fields
         * @param Identifier Holds Identifier of the feature where search is performed
         * @param searchParams Holds values of search Field API Names of referenceObjectAPIName and corresponding values entered
         * @param referenceResultFieldSetAPIName Fieldset name based on which the configured Fields are displayed in Search Results
         */
        SearchResult getResults(String identifier, List<SearchParam> searchParams,
                String referenceObjectAPIName, String referenceResultFieldSetAPIName);

    }
    /**
    * Implement the interface SearchProcessor2 to qualify the class as a valid Search Result class.
    */
    global interface SearchProcessor2 {
        /**
         * performs search based on the search Form Fields Input and provides search Result with search Result Fields
         * @param SearchRequest Holds the request parameters
         */
        SearchResult getResults(SearchRequest request);

    }

    /**
    * Wrapper class to hold Search Result.
    */
    global inherited sharing class SearchRequest {
        /**
         * Holds Identifier of the feature where search is performed
         */
        global String identifier {get; set;}
        /**
         * Holds values of search Field API Names of referenceObjectAPIName and corresponding values entered
         */
        global List<SearchParam> searchParams {get; set;}
        /**
         * Object name based on which the search results are displayed
         */
        global String referenceObjectAPIName {get; set;}
        /**
         * Fieldset name based on which the configured Fields are displayed in Search Results
         */
        global String referenceResultFieldSetAPIName {get; set;}
        /**
         * Comma separated values of default row actions
         */
        public String defaultRowActionsString {get; set;}
        /**
         * List of default row actions
         */
        global List<String> defaultRowActions {get {
            List<String> actions = new List<String>();
            if(String.isNotBlank(defaultRowActionsString)) {
                List<String> tokens = defaultRowActionsString.split(',');
                String t;
                for(integer i = 0; i < tokens.size(); i++) {
                    t = tokens[i];
                    if(String.isNotBlank(t)) {
                        t = t.trim();
                        if(String.isNotBlank(t)) {
                            actions.add(t);
                        }
                    }
                }
            }
            return actions;
        }}

    }

    /**
    * Wrapper class to hold Search Result.
    */
    global inherited sharing class SearchResult {
        /**
         * List of result rows
         */
        @AuraEnabled global List<SObject> rows {get;set;}
        /**
         * List of result columns
         */
        @AuraEnabled global List<Column> columns {get;set;}
        /**
         * Key column API name that uniquely identifies a record. Usually the ID field.
         */
        @AuraEnabled global String keyFieldAPIName {get;set;}
        /**
         * Message to be shown when there are no results
         */
        @AuraEnabled global String noResultsMessage {get;set;}
        /**
         * Title to be shown on the results block
         */
        @AuraEnabled global String title {get;set;}
        /**
         * A unique id that can identify the source of the data.
         */
        @AuraEnabled global String sourceUniqueId {get;set;}
        /**
         * List of Actions
         */
        @AuraEnabled global List<Action> customRowActions {get;set;}


        global SearchResult() {
            rows = new List<SObject>();
            columns = new List<Column>();
            keyFieldAPIName = 'Id';
            noResultsMessage = Label.PC_NoSearchResultsMessage;
            sourceUniqueId = String.valueOf(Datetime.now()) + String.valueOf(Math.random());

            // By default let's add the Show Details row action.
            customRowActions = new List<Action>();
            Action gotoRecord = new Action();
            gotoRecord.label = Label.PC_SearchActionGoToRecord; // custom label
            gotoRecord.name = ROW_ACTION_SHOW_DETAILS; //value
            customRowActions.add(gotoRecord);
        }
    }

    /**
    * Wrapper class to hold Action Details
    */
    global inherited sharing class Action {
        /**
         * Column label
         */
        @AuraEnabled global String label {get;set;}
        /**
         * Action Component Name
         */
        @AuraEnabled global String name {get;set;}
        /**
         * Action Component Name
         */
        global ActionType actionType {get;set;}

        /**
         * String form of actionType
         * We need this as enum's are not visible on the front end.
         * We don't allow values to be set directly to this variable. Instead set the actionType
         */
        @AuraEnabled global String actionTypeName {
            get {
                return actionType == null ? null : actionType.name();
            }
        }
        /**
         * Action Type value
         */
        @AuraEnabled global String actionTypeValue {get;set;}
    }

    /**
     * Action Type Values
     */
    global enum ActionType {OPEN_COMPONENT, OPEN_PAGE, OTHER}

    /**
    * Wrapper class to hold Field info
    */
    global inherited sharing class Column {
        /**
         * Column label
         */
        @AuraEnabled global String label {get;set;}
        /**
         * API name of the column
         */
        @AuraEnabled global String fieldName {get;set;}
        /**
         * Type of the column name
         */
        @AuraEnabled global String type {get;set;}
    }

    /**
    * Wrapper class to hold Field API Name and the corresponding Value given in Search Form Field
    */
    global inherited sharing class SearchParam {
        /**
         * Key field - API name of the field
         */
        @AuraEnabled global String fieldAPIName {get;set;}
        /**
         * Value - search param value for the given fieldAPIName
         */
        @AuraEnabled global String fieldValue {get;set;}

        global SearchParam() {
            fieldAPIName = PC_Constants.EMPTY_STRING;
            fieldValue =PC_Constants.EMPTY_STRING;
        }
    }

    /**
     * ResultException class
     */
    global inherited sharing class ResultException extends Exception {}

}