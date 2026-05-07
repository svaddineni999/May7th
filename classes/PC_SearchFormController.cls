/*********************************************************************************
Class Name        :     PC_SearchFormController
Description       :     Controller for PC_SearchForm Component
Created By        :     Haritha Reddy
Created Date      :     01-Oct-2019
Modification Log  :
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Haritha Reddy            01-Oct-2019              Initial Version
Haritha Reddy            17-Dec-2019              [PC-5791] Added error handling for initialiseFieldSetFieldsMap,getOrgNamespace methods
Haritha Reddy            21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/

public with sharing class PC_SearchFormController {

    public inherited sharing class InitData {
        @AuraEnabled public List<PC_FieldSetController.FieldSetMember> listFieldSetMembers{get; set;}
        @AuraEnabled public Map<String,Object> fsFields{get; set;}

        public InitData() {
            listFieldSetMembers = new List<PC_FieldSetController.FieldSetMember>();
            fsFields = new Map<String,Object>();
        }
    }

    /*****************************************************************************************************
    * Author       : Haritha Reddy
    * Method name  : getOrgNamespace
    * Return Type  : String
    * Description  : Return the namespace of client Org.
    *****************************************************************************************************/
    @AuraEnabled
    public static String getOrgNamespace() {
        try{
            return PC_Utility.getOrgNamespace();
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return null;
        }
    }

    /*****************************************************************************************************
    * Author       : Haritha Reddy
    * Parameter    : String
    * Method name  : getInitData
    * Return Type  : FieldSetDetailsWrapper
    * Description  : Method to get the fieldset members to be used for the search criteria.
    *****************************************************************************************************/
    @AuraEnabled
    public static InitData getInitData(String searchObjectAPIName, String searchFormFieldsetAPIName) {
        InitData InitDataWrapper = new InitData();
        try {
            List<PC_FieldSetController.FieldSetMember> listFieldSetMembers = PC_FieldSetController.getFields(searchObjectAPIName, searchFormFieldsetAPIName);
            InitDataWrapper.listFieldSetMembers = listFieldSetMembers;

            Map<String, Object> fsFieldsWithEmptyValMap = new Map<String, Object>();
            fsFieldsWithEmptyValMap=initialiseFieldSetFieldsMap(searchObjectAPIName, searchFormFieldsetAPIName);
            InitDataWrapper.fsFields = fsFieldsWithEmptyValMap;

        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return InitDataWrapper;
    }

    /*****************************************************************************************************
    * Author       : Haritha Reddy
    * Parameter    : SObject sobj
    * Method name  : initialiseFieldSetFieldsMap
    * Return Type  : Map<String, Object>
    * Description  : Method to initialise Map of search criteria fieldset member values to empty values.
    *****************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> initialiseFieldSetFieldsMap(String searchObjectAPIName, String fieldSetName) {
        Map<String, Object> fsFields = new Map<String, Object>();
        try {
            SObjectType sObjType = Schema.getGlobalDescribe().get(searchObjectAPIName);
            List<String> fsList = new List<String>();
            if (String.isNotBlank(fieldSetName)) {
                fsList = PC_FieldSetController.getFieldsByName(searchObjectAPIName, fieldSetName);
            }
            for (String fieldName : fsList) {
                Schema.DisplayType fieldType = sObjType.getDescribe().fields.getMap().get(fieldName).getDescribe().getType();

                if (fieldType == Schema.DisplayType.STRING || fieldType == Schema.DisplayType.EMAIL || fieldType == Schema.DisplayType.PICKLIST ||
                        fieldType == Schema.DisplayType.PHONE || fieldType == Schema.DisplayType.TEXTAREA) {
                    fsFields.put(fieldName, PC_Constants.EMPTY_STRING);
                } else if (fieldType == Schema.DisplayType.DATE || fieldType == Schema.DisplayType.DATETIME || fieldType == Schema.DisplayType.BOOLEAN ||
                        fieldType == Schema.DisplayType.DOUBLE) {
                    fsFields.put(fieldName, null);
                } else {
                    fsFields.put(fieldName, PC_Constants.EMPTY_STRING);
                }

            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return fsFields;
    }
}