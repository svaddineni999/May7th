/*********************************************************************************************************
Trigger Name    : PC_Trigger_SetAdverseEvent2Version
Description     : Trigger handler class on AdverseEvent object to populate latestAdverseEvent/parentAdverseEvent along with version Number .
Created By      : Deloitte
Created Date    :24-Sep-2019
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                       Date                   Description
--------------------------------------------------------------------------------------------------------------
Shishir Bansal                  24-Sep-2019            Initial Version
Shishir Bansal                  26-Sep-2019            [PC-4628] Track revisions on Adverse Event
Hitha Avalakki                  23-Dec-2019            [PC-5776] The SOQL is required in order to avoid governor limit and to keep the functionality as is.
Hitha Avalakki                  02-Dec-2020            [PC-6751] Edited all methods in order to resolve forcereviewer scan issues related to not having SOQL inside for loops
Haritha Reddy                   21-Jan-2021            [PC-7102] Added FLS Check
Satheesh Kumar                  Nov 16, 2021           [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/

public inherited sharing class PC_Trigger_SetAdverseEvent2Version  extends PC_TriggerHandler {
    public static boolean isExecuting = false;


    override public void beforeUpdate(){
        if(isExecuting != true) {
            // fetching changed records of Adverse Events
            List<PC_AdverseEvent2__c> newAETOUpdateList = (List<PC_AdverseEvent2__c>) newList;
            List<PC_AdverseEvent2__c> oldAEList = (List<PC_AdverseEvent2__c>) oldList;
            Map<Id, SObject> newAEMap = (Map<Id, SObject>) newMap;
            Map<Id, SObject> oldAEMap = (Map<Id, SObject>) oldMap;
            updatingChangedAdverseEvent(newList, oldAEList, newAEMap, oldAEMap);
        }
    }

    override public void afterInsert() {
        try {
            if (isExecuting != true) {
                List<PC_AdverseEvent2__c> newAETOUpdateList = (List<PC_AdverseEvent2__c>) newList;
                List<PC_AdverseEvent2__c> parentAERecords = new List<PC_AdverseEvent2__c>();
                List<PC_AdverseEvent2__c> childAERecords = new List<PC_AdverseEvent2__c>();

                for (PC_AdverseEvent2__c aeRecord : newAETOUpdateList) {

                    if (aeRecord.PC_SubmissionStatus__c == PC_Constants.PC_AE_SUBMISSION_STATUS) {

                        if (aeRecord.PC_ParentAdverseEvent__c == Null && aeRecord.PC_LatestAdverseEvent__c != Null) {
                            parentAERecords.add(aeRecord);
                        }

                        if (aeRecord.PC_ParentAdverseEvent__c != Null && aeRecord.PC_LatestAdverseEvent__c == Null) {
                            childAERecords.add(aeRecord);
                        }
                    }
                }
                if (parentAERecords.size() > 0) {
                    populateParentOnChildAdverseEvent(parentAERecords);
                }
                if (childAERecords.size() > 0) {
                    populateChildOnParentAdverseEvent(childAERecords);
                }
            }
        }catch (Exception ex) {
            PC_Utility.createExceptionLog(ex);
        }
    }


    /*********************************************************************************
    Method Name    : updateNewAdverseEventVersion
    Author         : Shishir Bansal
    Description    : This method checks whether the record has adverse event version. If not it is populated to 1.
    Return Type    : void
    Parameter      : List of incoming adverse event - Trigger.new
    *****************************************************************************/
    private void updateNewAdverseEventVersion(List<PC_AdverseEvent2__c> advEvents) {
        try {
            List <PC_AdverseEvent2__c> aeRecordsToUpdate = new List <PC_AdverseEvent2__c>();
            List <Id> aeIdRecordsToUpdate = new List <Id>();
            for (PC_AdverseEvent2__c aeRec : advEvents) {
                if (String.isBlank(String.valueOf(aeRec.PC_VersionNumber__c))) {
                    aeIdRecordsToUpdate.add(aeRec.Id);
                }
            }
            aeRecordsToUpdate = [Select PC_VersionNumber__c, Id from PC_AdverseEvent2__c where Id IN :aeIdRecordsToUpdate];
            for (PC_AdverseEvent2__c aeRec : aeRecordsToUpdate) {
                aeRec.PC_VersionNumber__c = 1;
            }
            if (aeRecordsToUpdate.size() > 0) {
                isExecuting = true;
                PC_Database.upd(aeRecordsToUpdate, false);
            }
        } catch (Exception ex) {
            PC_Utility.createExceptionLog(ex);
        }
    }


    /*********************************************************************************
    Method Name    : updatingChangedAdverseEvent
    Author         : Shishir Bansal
    Description    : This method checks whether the parent or child records are changed and update accordingly
    Return Type    : void
    Parameter      : List of incoming adverse event - Trigger.new
    *****************************************************************************/
    private void updatingChangedAdverseEvent(List<PC_AdverseEvent2__c>  newList,  List<PC_AdverseEvent2__c>  oldAEList, Map<Id, SObject> newAEMap,Map<Id, SObject> oldAEMap ) {
        try {
            List<Id> parentAEIdList = new List<Id>();
            List<Id> childAEIdList = new List<Id>();
            for (PC_AdverseEvent2__c aeObject : oldAEList) {

                // fetching related changes values of AE from newAEMap
                PC_AdverseEvent2__c newValAdverseEvent =(PC_AdverseEvent2__c )newAEMap.get(aeObject.Id);

                // conditon on Parent AE record . The PC_ParentAdverseEvent__c will always be blank
                if ((aeObject.PC_SubmissionStatus__c == PC_Constants.PC_AE_SUBMISSION_STATUS) && (aeObject.PC_ParentAdverseEvent__c == NULL) && (newValAdverseEvent.PC_ParentAdverseEvent__c == Null)) {
                    // storing parent AE Ids in a list
                    parentAEIdList.add(aeObject.Id);
                }

                // condition on Child AE record. The PC_LatestAdverseEvent__c will always be blank
                if ((aeObject.PC_SubmissionStatus__c == PC_Constants.PC_AE_SUBMISSION_STATUS) && (aeObject.PC_LatestAdverseEvent__c == NULL) && (newValAdverseEvent.PC_LatestAdverseEvent__c == null)) {
                    //storing child AE Ids in a list
                    childAEIdList.add(aeObject.Id);
                }
            }
            if (parentAEIdList.size() > 0) {
                // updating first child and than related parent records
                updateParentAERecords(parentAEIdList, oldAEMap, newAEMap);
            }
            if(childAEIdList.size() > 0){
                // updating first parent and than related child records
                updateChildAERecords(childAEIdList, oldAEMap, newAEMap);
            }
        } catch (Exception ex) {
            PC_Utility.createExceptionLog(ex);
        }
    }

    /*********************************************************************************
    Method Name    : updateParentAERecords
    Author         : Hitha Avalakki
    Description    : This method checks on parent Adverse Events and updates the related child record(Latest AdverseEvent). This happens when Adverse Event records are created using 			 Adverse event tabs and NOT via action center.
    Return Type    : void
    Parameter      : List of incoming adverse event - Trigger.new
    *****************************************************************************/
    private void  updateParentAERecords(List<Id>  parentAEIdList,  Map<Id, SObject>  oldAEMap, Map<Id, SObject> newAEMap) {

        Map<Id, PC_AdverseEvent2__c> oldAEObjMap=new Map<Id, PC_AdverseEvent2__c>();
        Map<Id, PC_AdverseEvent2__c> newAEObjMap=new Map<Id, PC_AdverseEvent2__c>();
        List<Id> newAEObjLastChildAEIdList = new List<Id>();
        List<Id> oldAEObjLastChildAEIdList = new List<Id>();
        Map<Id,PC_AdverseEvent2__c> childAEMap = new Map<Id,PC_AdverseEvent2__c>();
        Map<Id,PC_AdverseEvent2__c> oldChildAEObjMap = new Map<Id,PC_AdverseEvent2__c>();

        for(Id idVal : parentAEIdList) {

            PC_AdverseEvent2__c oldAEObj = new PC_AdverseEvent2__c();
            oldAEObj = (PC_AdverseEvent2__c) oldAEMap.get(idVal);
            if(oldAEObj!=null){
                oldAEObjMap.put(idVal, oldAEObj);
                oldAEObjLastChildAEIdList.add(oldAEObj.PC_LatestAdverseEvent__c);
            }

            PC_AdverseEvent2__c newAEObj = new PC_AdverseEvent2__c();
            newAEObj = (PC_AdverseEvent2__c) newAEMap.get(idVal);
            if(newAEObj!=null){
                newAEObjMap.put(idVal, newAEObj);
                newAEObjLastChildAEIdList.add(newAEObj.PC_LatestAdverseEvent__c);
            }
        }

        //FLS is NOT needed in Triggers, as they always run in System Mode.
        /*List<String> aeFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_VersionNumber__c'),PC_Constants.getQualifiedAPIName('PC_ParentAdverseEvent__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c'), PC_Database.Operation.Reading, aeFields);*/

        //Get  new child AE details
        childAEMap = new Map<Id, PC_AdverseEvent2__c>([Select Id, PC_VersionNumber__c, PC_ParentAdverseEvent__c from PC_AdverseEvent2__c where Id IN: newAEObjLastChildAEIdList]);
        //Get old child AE details
        oldChildAEObjMap = new Map<Id, PC_AdverseEvent2__c>([Select Id, PC_VersionNumber__c, PC_ParentAdverseEvent__c from PC_AdverseEvent2__c where id IN: oldAEObjLastChildAEIdList]);

        for(Id idVal : parentAEIdList){

            PC_AdverseEvent2__c oldAEObj = new PC_AdverseEvent2__c();
            oldAEObj =(PC_AdverseEvent2__c) oldAEMap.get(idVal);

            PC_AdverseEvent2__c newAEObj = new PC_AdverseEvent2__c();
            newAEObj =(PC_AdverseEvent2__c) newAEMap.get(idVal);

            if(newAEObj.PC_LatestAdverseEvent__c != null) {

                // when parent doesn't have a child
                if (newAEObj.PC_ParentAdverseEvent__c == Null && newAEObj.PC_LatestAdverseEvent__c != Null && childAEMap.get(newAEObj.PC_LatestAdverseEvent__c).PC_ParentAdverseEvent__c != newAEObj.Id) {

                    if (oldAEObj.PC_LatestAdverseEvent__c == Null) {

                        PC_AdverseEvent2__c lastChildAE = childAEMap.get(newAEObj.PC_LatestAdverseEvent__c);
                        lastChildAE.PC_VersionNumber__c = 2;
                        lastChildAE.PC_ParentAdverseEvent__c = newAEObj.Id;
                        isExecuting = true;
                        PC_Database.upd(lastChildAE, false);
                    }
                    // case 2 when parent have a child and we are replacing with new child
                    else {
                        Decimal versionNumber;
                        PC_AdverseEvent2__c ae = oldChildAEObjMap.get(oldAEObj.PC_LatestAdverseEvent__c);
                        versionNumber = ae.PC_VersionNumber__c;
                        versionNumber = (versionNumber == 1) ? 2 : (++versionNumber);
                        ae = new PC_AdverseEvent2__c();

                        ae = childAEMap.get(newAEObj.PC_LatestAdverseEvent__c);
                        ae.PC_VersionNumber__c = versionNumber;
                        ae.PC_ParentAdverseEvent__c = newAEObj.Id;
                        isExecuting = true;
                        PC_Database.upd(ae, false);
                    }
                }
            }
        }

    }

    /*********************************************************************************
  Method Name    : updateChildAERecords
  Author         : Hitha Avalakki
  Description    : This method checks on child Adverse Event and updates the parent AE record
  Return Type    : void
  Parameter      : List of incoming adverse event - Trigger.new
  *****************************************************************************/
    private void updateChildAERecords(List<Id>  childAEIdList,  Map<Id, SObject>  oldAEMap, Map<Id, SObject> newAEMap) {

        List<Id> parentAEIdList = new List<Id>();
        Map<Id,PC_AdverseEvent2__c> parentAEMap;

        for (Id idVal : childAEIdList) {
            PC_AdverseEvent2__c oldChildAEObj = new PC_AdverseEvent2__c();
            oldChildAEObj = (PC_AdverseEvent2__c) oldAEMap.get(idVal);

            PC_AdverseEvent2__c newChildAEObj = new PC_AdverseEvent2__c();
            newChildAEObj = (PC_AdverseEvent2__c) newAEMap.get(idVal);

            if(newChildAEObj!=null){
                parentAEIdList.add(newChildAEObj.PC_ParentAdverseEvent__c);
            }
        }

        //FLS is NOT needed in Triggers, as they always run in System Mode.
        /*List<String> aeFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_VersionNumber__c'),
                PC_Constants.getQualifiedAPIName('PC_LatestAdverseEvent__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c'), PC_Database.Operation.Reading, aeFields); */

        parentAEMap = new Map<Id, PC_AdverseEvent2__c>([Select Id,PC_LatestAdverseEvent__r.PC_VersionNumber__c, PC_LatestAdverseEvent__c from PC_AdverseEvent2__c where Id IN :parentAEIdList]);

        for (Id idVal : childAEIdList) {
            PC_AdverseEvent2__c oldAEObj = new PC_AdverseEvent2__c();
            oldAEObj = (PC_AdverseEvent2__c) oldAEMap.get(idVal);

            PC_AdverseEvent2__c newAEObj = new PC_AdverseEvent2__c();
            newAEObj = (PC_AdverseEvent2__c) newAEMap.get(idVal);

            // case 1 when changing parent has no child record than this record will be version 2
            if (oldAEObj.PC_ParentAdverseEvent__c != newAEObj.PC_ParentAdverseEvent__c && oldAEObj.PC_LatestAdverseEvent__c == Null && newAEObj.PC_LatestAdverseEvent__c == Null) {
                if (newAEObj.PC_ParentAdverseEvent__c != null) {
                    PC_AdverseEvent2__c newParentAE = new PC_AdverseEvent2__c();

                    newParentAE = parentAEMap.get(newAEObj.PC_ParentAdverseEvent__c);

                    // case when parent child was null
                    if (newAEObj.PC_ParentAdverseEvent__c != null && newParentAE.PC_LatestAdverseEvent__c == null) {

                        newAEObj.PC_VersionNumber__c = 2;
                        newParentAE.PC_LatestAdverseEvent__c = newAEObj.Id;
                        isExecuting = true;
                        PC_Database.upd(newParentAE, false);
                    }
                    // case when parent child was  not null
                    if (newAEObj.PC_ParentAdverseEvent__c != null && newParentAE.PC_LatestAdverseEvent__c != null) {

                        newParentAE = new PC_AdverseEvent2__c();
                        newParentAE = parentAEMap.get(newAEObj.PC_ParentAdverseEvent__c);

                        decimal versionNumber = newParentAE.PC_LatestAdverseEvent__r.PC_VersionNumber__c;
                        versionNumber = versionNumber == null ? 2 : ++versionNumber;
                        newAEObj.PC_VersionNumber__c = versionNumber;
                        newParentAE.PC_LatestAdverseEvent__c = newAEObj.Id;
                        isExecuting = true;
                        PC_Database.upd(newParentAE, false);
                    }
                }
            }
        }

    }

    /*********************************************************************************
       Method Name    : populateParentOnChildAdverseEvent
       Author         : Hitha Avalakki
       Description    : This method checks whether the parent or child records are changed and update accordingly
       Return Type    : void
       Parameter      : List of incoming adverse event - Trigger.new
       *****************************************************************************/
    private void populateParentOnChildAdverseEvent(  List<PC_AdverseEvent2__c>  parentAERecords){
        List<PC_AdverseEvent2__c> aeChildRecords = new List<PC_AdverseEvent2__c>();
        List<Id> childRecordIdsList =  new List<Id>();
        List<PC_AdverseEvent2__c> childAERecordsList =  new List<PC_AdverseEvent2__c>();
        Map<Id,Id> childAEParentAEMap =  new Map<Id, Id>();

        for(PC_AdverseEvent2__c aeRecord : parentAERecords){
            if(aeRecord.PC_LatestAdverseEvent__c!=null){
                childRecordIdsList.add(aeRecord.PC_LatestAdverseEvent__c);
                childAEParentAEMap.put(aeRecord.PC_LatestAdverseEvent__c, aeRecord.Id);
            }
        }


        //FLS is NOT needed in Triggers, as they always run in System Mode.
        /*List<String> aeFields = new List<String>{'Id',PC_Constants.getQualifiedAPIName('PC_VersionNumber__c'),
                PC_Constants.getQualifiedAPIName('PC_LatestAdverseEvent__c'), PC_Constants.getQualifiedAPIName('PC_ParentAdverseEvent__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c'), PC_Database.Operation.Reading, aeFields);*/

        childAERecordsList = [Select Id, PC_LatestAdverseEvent__c, PC_ParentAdverseEvent__c, PC_VersionNumber__c FROM PC_AdverseEvent2__c where Id IN:childRecordIdsList];

        for(PC_AdverseEvent2__c childAERecord : childAERecordsList){

            childAERecord.PC_ParentAdverseEvent__c = childAEParentAEMap.get(childAERecord.Id);
            childAERecord.PC_VersionNumber__c = 2;
            aeChildRecords.add(childAERecord);
        }
        isExecuting =true;
        PC_Database.upd(aeChildRecords, false);
    }

    /*********************************************************************************
      Method Name    : populateChildOnParentAdverseEvent
      Author         : Hitha Avalakki
      Description    : This method checks whether the parent or child records are changed and update accordingly
      Return Type    : void
      Parameter      : List of incoming adverse event - Trigger.new
      *****************************************************************************/
    private void populateChildOnParentAdverseEvent(List<PC_AdverseEvent2__c>  childAERecords){

        List<PC_AdverseEvent2__c> aeParentRecords = new List<PC_AdverseEvent2__c>();
        List<PC_AdverseEvent2__c> aeChildRecordsToUpdate = new List<PC_AdverseEvent2__c>();
        Map<Id,PC_AdverseEvent2__c> childAEIdParentAERecordMap = new Map<Id, PC_AdverseEvent2__c>();
        List<Id> parentAEIdList = new List<Id>();
        List<Id> childAEIdList = new List<Id>();
        Map<Id,PC_AdverseEvent2__c> parentAERecordDetailsMap;
        Map<Id, PC_AdverseEvent2__c> childAERecordVersionNumMap;
        Decimal versionNumber ;

        for(PC_AdverseEvent2__c aeRecord : childAERecords){
            parentAEIdList.add(aeRecord.PC_ParentAdverseEvent__c);
            childAEIdList.add(aeRecord.Id);
        }

        //FLS is NOT needed in Triggers, as they always run in System Mode.
        /*List<String> aeFields = new List<String>{'Id',PC_Constants.getQualifiedAPIName('PC_VersionNumber__c'),
                PC_Constants.getQualifiedAPIName('PC_LatestAdverseEvent__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c'), PC_Database.Operation.Reading, aeFields);*/

        //Get Child AE record version map
        childAERecordVersionNumMap = new Map<Id, PC_AdverseEvent2__c>([Select Id, PC_VersionNumber__c From PC_AdverseEvent2__c  where Id IN:childAEIdList]);
        //Get parent AE record version map
        parentAERecordDetailsMap = new Map<Id,PC_AdverseEvent2__c>([Select Id, PC_LatestAdverseEvent__c ,PC_LatestAdverseEvent__r.PC_VersionNumber__c, PC_VersionNumber__c FROM PC_AdverseEvent2__c where Id IN:parentAEIdList]);

        for(PC_AdverseEvent2__c aeRecord : childAERecords){

            PC_AdverseEvent2__c parentAdverseEvent = new PC_AdverseEvent2__c();
            parentAdverseEvent = parentAERecordDetailsMap.get(aeRecord.PC_ParentAdverseEvent__c);

            if( parentAdverseEvent.PC_LatestAdverseEvent__c !=null) {
                versionNumber = parentAdverseEvent.PC_LatestAdverseEvent__r.PC_VersionNumber__c == 1 ? 2 : ++parentAdverseEvent.PC_LatestAdverseEvent__r.PC_VersionNumber__c;
            }
            else{
                versionNumber =2;
            }

            PC_AdverseEvent2__c childAdverseEvent = new PC_AdverseEvent2__c();
            childAdverseEvent = childAERecordVersionNumMap.get(aeRecord.Id);
            childAdverseEvent.PC_VersionNumber__c = versionNumber;

            aeChildRecordsToUpdate.add(childAdverseEvent);
            parentAdverseEvent.PC_LatestAdverseEvent__c = aeRecord.Id;
            aeParentRecords.add(parentAdverseEvent);
        }
        isExecuting =true;
        PC_Database.upd(aeParentRecords, false);
        PC_Database.upd(aeChildRecordsToUpdate, false);

    }

}