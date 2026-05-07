/*********************************************************************************************************
Class Name      : PC_SearchResultsHelper
Description     :
Created By      : Vijay Kashikar
Created Date    : Oct 17, 2019
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Vijay Kashikar              10/17/2019                    Initial Version
Kanteti Kishore             13-Dec-2019                 [PC-5795] Reduced parameters for search method
*********************************************************************************************************/

public with sharing class PC_SearchResultsHelper {
    @AuraEnabled
    public static PC_SearchResults.SearchResult search(Map<String,String> searchDetails) {

        try {
            String identifier = '';
            identifier = searchDetails.get('identifier');
            String searchObjectAPIName = '';
            searchObjectAPIName = searchDetails.get('searchObjectAPIName');
            String searchFormFieldsetAPIName = '';
            searchFormFieldsetAPIName = searchDetails.get('searchFormFieldsetAPIName');
            String searchResultFieldsetAPIName = '';
            searchResultFieldsetAPIName = searchDetails.get('searchResultFieldsetAPIName');
            String searchParamsJSON = '';
            searchParamsJSON = searchDetails.get('searchParamsJSON');
            String resultClass = '';
            resultClass = searchDetails.get('resultClass');
            String defaultRowActions = '';
            defaultRowActions = searchDetails.get('defaultRowActions');

            if (resultClass != null) {
                Type t = Type.forName(resultClass);

                if (t != null) {

                    Object o = t.newInstance();

                    List<PC_SearchResults.SearchParam> searchParamsList = new List<PC_SearchResults.SearchParam>();
                    Map<String, Object> searchParams;
                    if(String.isNotBlank(searchParamsJSON)) {
                        searchParams = (Map<string, Object>) JSON.deserializeUntyped(searchParamsJSON);
                    }
                    if (searchParams != null && searchParams.size() > 0) {
                        for (String key : searchParams.keySet()) {
                            PC_SearchResults.SearchParam param = new PC_SearchResults.SearchParam();
                            param.fieldAPIName = key;
                            param.fieldValue = String.valueOf(searchParams.get(key));
                            searchParamsList.add(param);
                        }
                    }

                    if (o instanceof PC_SearchResults.SearchProcessor) {
                        PC_SearchResults.SearchProcessor processor = (PC_SearchResults.SearchProcessor) o;
                        return processor.getResults(identifier, searchParamsList, searchObjectAPIName, searchResultFieldsetAPIName);
                    }
                    else if(o instanceof PC_SearchResults.SearchProcessor2) {
                        PC_SearchResults.SearchRequest request = new PC_SearchResults.SearchRequest();
                        request.identifier = identifier;
                        request.searchParams = searchParamsList;
                        request.referenceObjectAPIName = searchObjectAPIName;
                        request.referenceResultFieldSetAPIName = searchResultFieldsetAPIName;
                        request.defaultRowActionsString = defaultRowActions;
                        PC_SearchResults.SearchProcessor2 processor = (PC_SearchResults.SearchProcessor2) o;
                        return processor.getResults(request);
                    }
                    else {
                        PC_SearchResults.ResultException e = new PC_SearchResults.ResultException('Result Class: ' +
                                resultClass + ' not found/does not implement PC_SearchResults.SearchProcessor or PC_SearchResults.SearchProcessor2 interface.');
                        throw e;
                    }

                } else {
                    PC_SearchResults.ResultException e = new PC_SearchResults.ResultException('Result Class: ' +
                            resultClass + ' not found/does not implement PC_SearchResults.SearchProcessor or PC_SearchResults.SearchProcessor2 interface.');
                    throw e;

                }
            }
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }
}