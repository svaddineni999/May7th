/**
* Created by tejas patel on 23 Jan 2018.
*/
/*********************************************************************************
Class Name      : PC_ActionIconsLightningController
Description     : Read the meta data to craete action icons on the document management page
Created By      : tejas patel
Created Date    : 23 Jan 2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------           
Teajs Patel                 23-Jan-18                  Initial Version
Tejas Patel					31-Jan-18				   [PC-2727] Display general icons on all record types with blank field
Prachi Nandgaonkar          3-Feb-18                   [PC-2727] Display general icons on all record types with 'ALL' keyword
Mayuresh Patil				26-Feb-18				   [PC-2822] Fixed Namespace issue with icon label.
Mayuresh Patil				9-Apr-18				   [PC-2958] Ability to add action to custom component.
Tejas Patel                 26-Sep-19                  [PC-5511] Updating the class with new field added to custom metadata for config.
Tushar Arora                10-Oct-19                  [PC-5508] Added RecordType Grouping support for Document Actions.
Tushar Arora                30-jan-20                  [PC-5963] Added fix for Document Action Center settings if Document Record Type is given as 'ALL' should not require namespaceprefix
Tushar Arora                4-feb-20                  [PC-5958] Added getAccessibilityStatus and getVisibilityStatus method as well as added one more parameterized constructor in ActionIconsWrapper
Tushar Arora                30-Apr-20                 [PC-6235] Added logic for Grouping of document action icons should be done for recordtype(s) which do not have namespace.
Tushar Arora                05-May-20                 [PC-6250] Modified code for removing hardcoded exception string to Label PC_Document_ComponentNameExceptionErrorMessage.
Satheesh Kumar              09-Sep-20                 [PC-6747] Modified code to fix the document action center icon label Translation Issue
*********************************************************************************/
public with sharing class PC_ActionIconsLightningController {
    private static String componentExceptionMessage = System.Label.PC_Document_ComponentNameExceptionErrorMessage;

    @AuraEnabled
    public static PC_Document__c getDocDetails(Id docId) {
        PC_Document__c selectedDoc = new PC_Document__c();
        //FLS Check on PC_Document__c
        List<String> fields = new List<String>{'Name', 'RecordTypeId'};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, fields);

        selectedDoc = [SELECT Name, RecordType.DeveloperName, RecordType.NamespacePrefix  FROM PC_Document__c WHERE ID =: docId];
        return selectedDoc;
    }

    @AuraEnabled
    public static LIST<ActionIconsWrapper> setupActionIcons(Id docId) {
        PC_Document__c selectedDoc = getDocDetails(docId);
        String qualifiedRecordTypeName = '';
        if(String.isBlank(selectedDoc.RecordType.NamespacePrefix)) {
            qualifiedRecordTypeName  = selectedDoc.RecordType.DeveloperName;
        } else {
            qualifiedRecordTypeName  = selectedDoc.RecordType.NamespacePrefix + '__' + selectedDoc.RecordType.DeveloperName;
        }
        String sObjectQualifiedAPIName = ((Id)docId).getSobjectType().getDescribe().getName();
        String sObjectDeveloperName = ((Id)docId).getSobjectType().getDescribe().getLocalName();
        String isNamespacePresent = sObjectQualifiedAPIName.removeEndIgnoreCase(sObjectDeveloperName);
        String sObjectNamespace = isNamespacePresent == null ? '' : isNamespacePresent.removeEndIgnoreCase('__');



        CustomMetadataWrapper.GroupWrapper groupDetail = new CustomMetadataWrapper.GroupWrapper();
        groupDetail.objectAPIName = sObjectDeveloperName;
        groupDetail.objectNamespace = sObjectNamespace;
        groupDetail.fieldAPIName = PC_Constants.PC_RecordTypeDeveloperName;
        groupDetail.fieldNamespace = '';
        groupDetail.fieldValue = qualifiedRecordTypeName;

        System.debug('groupDetail::::'+groupDetail);

        Set<String> setGroups = PC_Utility.getGroups(groupDetail);
        System.debug('setGroups::::'+setGroups);

        LIST<PC_Document_Action_Setting__mdt> actionIconMetaData = NEW LIST<PC_Document_Action_Setting__mdt>();
        LIST<PC_Document_Action_Setting__mdt> actionIconMetaData_GroupRecordType = new LIST<PC_Document_Action_Setting__mdt>();
        LIST<PC_Document_Action_Setting__mdt> actionIconMetaData_AllRecordType = new LIST<PC_Document_Action_Setting__mdt>();
        LIST<PC_Document_Action_Setting__mdt> actionIconMetaData_NotAllRecordType = new LIST<PC_Document_Action_Setting__mdt>();
        if(!setGroups.IsEmpty()){
            actionIconMetaData_GroupRecordType = [SELECT PC_Active__c, PC_Action__c, PC_Component__c, PC_Icon__c,
                    PC_Document_Record_Type__c, PC_ComponentAttributes__c, PC_Label__c, PC_Ordinal__c, PC_ValidatorClass__c
            FROM PC_Document_Action_Setting__mdt ng__mdt
            WHERE PC_Active__c =: TRUE AND PC_Group_of_RecordTypes__c != null AND PC_Group_of_RecordTypes__c IN : setGroups
            ORDER BY PC_Ordinal__c
            ];
        }
        System.debug('actionIconMetaData_GroupRecordType::::'+actionIconMetaData_GroupRecordType);

        actionIconMetaData_AllRecordType = [SELECT PC_Active__c, PC_Action__c, PC_Component__c, PC_Icon__c,
                PC_Document_Record_Type__c, PC_ComponentAttributes__c, PC_Label__c, PC_Ordinal__c, PC_ValidatorClass__c
        FROM PC_Document_Action_Setting__mdt ng__mdt
        WHERE PC_Active__c =: TRUE
        AND(PC_Document_Record_Type__c = 'ALL'
        OR PC_Document_Record_Type__c = 'all')
        ORDER BY PC_Ordinal__c];
        System.debug('actionIconMetaData_AllRecordType::::'+actionIconMetaData_AllRecordType);

        actionIconMetaData_NotAllRecordType = [SELECT PC_Active__c, PC_Action__c, PC_Component__c, PC_Icon__c,
                PC_Document_Record_Type__c, PC_ComponentAttributes__c, PC_Label__c, PC_Ordinal__c, PC_ValidatorClass__c
        FROM PC_Document_Action_Setting__mdt ng__mdt
        WHERE PC_Active__c =: TRUE
        AND PC_Document_Record_Type__c != 'ALL'
        AND PC_Document_Record_Type__c != 'all'
        AND PC_Document_Record_Type__c =: selectedDoc.RecordType.DeveloperName
        AND PC_Document_Recordtype_Namespaceprefix__c  =: selectedDoc.RecordType.NamespacePrefix
        ORDER BY PC_Ordinal__c];
        System.debug('actionIconMetaData_NotAllRecordType::::'+actionIconMetaData_NotAllRecordType);


        if(!actionIconMetaData_GroupRecordType.IsEmpty()) {
            actionIconMetaData.addAll(actionIconMetaData_GroupRecordType);
        }
        if(!actionIconMetaData_AllRecordType.IsEmpty()) {
            actionIconMetaData.addAll(actionIconMetaData_AllRecordType);
        }
        if(!actionIconMetaData_NotAllRecordType.IsEmpty()) {
            actionIconMetaData.addAll(actionIconMetaData_NotAllRecordType);
        }

        Map<Id,PC_Document_Action_Setting__mdt> mapToRemoveDuplicates = new Map<Id,PC_Document_Action_Setting__mdt>();
        Map<Integer,List<PC_Document_Action_Setting__mdt>> mapToSortDocumentActions = new Map<Integer,List<PC_Document_Action_Setting__mdt>>();
        LIST<ActionIconsWrapper> actionIconsWrapper	= 	NEW LIST<ActionIconsWrapper>();

        for(PC_Document_Action_Setting__mdt docActions : actionIconMetaData){
            mapToRemoveDuplicates.put(docActions.id,docActions);
        }

        actionIconMetaData.clear();
        actionIconMetaData.addAll(mapToRemoveDuplicates.values());
        List<PC_Document_Action_Setting__mdt> templist;
        for(PC_Document_Action_Setting__mdt docActions : actionIconMetaData){
            if(!mapToSortDocumentActions.containskey(Integer.valueof(docActions.PC_Ordinal__c))){
                templist = new List<PC_Document_Action_Setting__mdt>();
                mapToSortDocumentActions.put(Integer.valueof(docActions.PC_Ordinal__c),templist);
            }
            mapToSortDocumentActions.get(Integer.valueof(docActions.PC_Ordinal__c)).add(docActions);
        }

        List<Integer> docActionOrdinalKeyList = new List<Integer>();
        docActionOrdinalKeyList.addAll(mapToSortDocumentActions.keyset());
        docActionOrdinalKeyList.sort();
        actionIconMetaData.clear();

        for(Integer ordinalKey : docActionOrdinalKeyList){
            actionIconMetaData.addAll(mapToSortDocumentActions.get(ordinalKey));
        }

        for (PC_Document_Action_Setting__mdt a : actionIconMetaData){
            if(String.isBlank(a.PC_ValidatorClass__c)){
                actionIconsWrapper.add(new ActionIconsWrapper(a));
            } else {
                actionIconsWrapper.add(new ActionIconsWrapper(a,String.valueOf(docId)));
            }
        }
        System.debug('actionIconsWrapper::::'+actionIconsWrapper);
        RETURN actionIconsWrapper;
    }

    @AuraEnabled
    public static PC_ActionValidator.AccessibilityResponse getAccessibilityStatus(Id recordId, String validatorClass, String componentName) {
        PC_ActionValidator.AccessibilityResponse accessibilityResponse = new PC_ActionValidator.AccessibilityResponse();
        try{

            PC_ActionValidator.Params actionParams = new PC_ActionValidator.Params();
            if(String.isBlank(validatorClass))
                return accessibilityResponse;

            if( String.isBlank(componentName))
                 throw new componentNameException(componentExceptionMessage);


            if(String.isNotBlank(validatorClass)) {
                Type t = Type.forName(validatorClass);
                if (t != null)
                {
                    Object o = t.newInstance();
                    if (o instanceof PC_ActionValidator.Validator){
                        PC_ActionValidator.Validator validationClass = (PC_ActionValidator.Validator) o;
                        actionParams.recordId	= String.valueof(recordId);
                        accessibilityResponse = validationClass.isAccessible(actionParams);
                    }
                }
            }

        }catch(Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return accessibilityResponse;
    }

    private static Boolean getVisibilityStatus(Id recordId, String validatorClass, String componentName) {
        Boolean isVisible = true;
        try{
            PC_ActionValidator.Params actionParams = new PC_ActionValidator.Params();

            if(String.isBlank(componentName))
                throw new componentNameException(componentExceptionMessage);

                if(String.isNotBlank(validatorClass)) {
                    Type t = Type.forName(validatorClass);
                    if (t != null)
                    {
                        Object o = t.newInstance();
                        if (o instanceof PC_ActionValidator.Validator){
                            PC_ActionValidator.Validator validationClass = (PC_ActionValidator.Validator) o;
                            actionParams.recordId	= String.valueof(recordId);
                            actionParams.componentName = componentName;
                            isVisible = validationClass.isVisible(actionParams);
                        }
                    }
                }

        }catch(Exception e) {
            PC_Utility.logAndThrowException(e);
        }
        return isVisible;
    }

    /**
	* Wrapper for the action icons setup. Includes all information needed to initialize the
	* action icons.
	*/
    public class ActionIconsWrapper {
        @AuraEnabled public Boolean iconActive {get; set;}
        @AuraEnabled public String 	iconActionComponent {get; set;}
        @AuraEnabled public String 	iconDocRecordType {get; set;}
        @AuraEnabled public String 	iconImage {get; set;}
        @AuraEnabled public String 	iconLabel {get; set;}
        @AuraEnabled public Decimal iconOrdinal {get; set;}
        @AuraEnabled public Boolean iconIsVisible {get; set;}

        public ActionIconsWrapper() {}

        public ActionIconsWrapper(PC_Document_Action_Setting__mdt a) {
            iconActive 			= a.PC_Active__c;
            iconActionComponent =   (String.isEmpty(a.PC_Action__c) && String.isEmpty(a.PC_ComponentAttributes__c) && String.isEmpty(a.PC_ValidatorClass__c)) ? ((a.PC_Component__c.contains(':')) ? a.PC_Component__c : 'c:'+a.PC_Component__c) :
                                    ((a.PC_Component__c.contains(':')) ?
                                    (a.PC_Component__c + '::' + (String.isNotEmpty(a.PC_Action__c) ? a.PC_Action__c : PC_Constants.EMPTY_STRING) + '::' + (String.isNotEmpty(a.PC_ComponentAttributes__c) ? a.PC_ComponentAttributes__c : PC_Constants.EMPTY_STRING) + '::' + (String.isNotEmpty(a.PC_ValidatorClass__c) ? a.PC_ValidatorClass__c : PC_Constants.EMPTY_STRING)) :
                                    ('c:'+a.PC_Component__c + '::' + (String.isNotEmpty(a.PC_Action__c) ? a.PC_Action__c : PC_Constants.EMPTY_STRING) + '::' + (String.isNotEmpty(a.PC_ComponentAttributes__c) ? a.PC_ComponentAttributes__c : PC_Constants.EMPTY_STRING) + '::' + (String.isNotEmpty(a.PC_ValidatorClass__c) ? a.PC_ValidatorClass__c : PC_Constants.EMPTY_STRING)));
            iconDocRecordType 	= a.PC_Document_Record_Type__c;
            iconImage 			= a.PC_Icon__c;
            iconLabel 			= a.PC_Label__c;
            iconOrdinal 		= a.PC_Ordinal__c;
            iconIsVisible 		= true;
        }
        public ActionIconsWrapper(PC_Document_Action_Setting__mdt a, String docId) {
            iconActive 			= a.PC_Active__c;
            iconActionComponent =   (String.isEmpty(a.PC_Action__c) && String.isEmpty(a.PC_ComponentAttributes__c) && String.isEmpty(a.PC_ValidatorClass__c)) ? ((a.PC_Component__c.contains(':')) ? a.PC_Component__c : 'c:'+a.PC_Component__c) :
                    ((a.PC_Component__c.contains(':')) ?
                            (a.PC_Component__c + '::' + (String.isNotEmpty(a.PC_Action__c) ? a.PC_Action__c : PC_Constants.EMPTY_STRING) + '::' + (String.isNotEmpty(a.PC_ComponentAttributes__c) ? a.PC_ComponentAttributes__c : PC_Constants.EMPTY_STRING) + '::' + (String.isNotEmpty(a.PC_ValidatorClass__c) ? a.PC_ValidatorClass__c : PC_Constants.EMPTY_STRING)) :
                            ('c:'+a.PC_Component__c + '::' + (String.isNotEmpty(a.PC_Action__c) ? a.PC_Action__c : PC_Constants.EMPTY_STRING) + '::' + (String.isNotEmpty(a.PC_ComponentAttributes__c) ? a.PC_ComponentAttributes__c : PC_Constants.EMPTY_STRING) + '::' + (String.isNotEmpty(a.PC_ValidatorClass__c) ? a.PC_ValidatorClass__c : PC_Constants.EMPTY_STRING)));
            iconDocRecordType 	= a.PC_Document_Record_Type__c;
            iconImage 			= a.PC_Icon__c;
            iconLabel 			= a.PC_Label__c;
            iconOrdinal 		= a.PC_Ordinal__c;
            iconIsVisible 		= getVisibilityStatus(docId, a.PC_ValidatorClass__c ,a.PC_Component__c) == null ? true : getVisibilityStatus(docId, a.PC_ValidatorClass__c ,a.PC_Component__c);
        }
    }

    private class componentNameException extends Exception {}

}