/*********************************************************************************
Class Name      : PC_SupportPlanBuilderController
Description     : Fetches list view of all Support Plans to be shown on Support Plan Admin app
Created By      : Prachi Nandgaonkar
Created Date    : 21-Feb-2018
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Prachi Nandgaonkar          21-Feb-2018             Initial Version
Tejas Patel                 15-March-2018           Logic to get activities and Act/Deact the Support Plan
Tejas Patel                 21-March-2018           Logic change to get activities and Act/Deact the Support Plan
Mayuresh Patil              27-March-2018           Parameterized the getListView method as it will fail in namespaced environment.
Tejas Patel                 15-Feb-2019             New method for Cloning SP added
Tejas Patel                 19-Feb-2019             New method for Cloning SP moved to separate controller
Tejas Patel                 28-Mar-2019             [PC-4659] New field PC_GroupActivityExecution__c added
Tejas Patel                 24-Apr-2019             [PC-4748] after swap or drag-drop of the first activity reference type is changed to "Activity Creation Date"
Haritha Reddy               17-Dec-2019             [PC-5791] Replaced References of createExceptionLog method with logAndThrowException
Kanteti Kishore             22-Mar-2020             Added condition for getting the correct field map from user record field.
Kanteti Kishore             11-June-2020            Modified isValidFieldSet method to support custom fieldsets for user task properties .
Haritha Reddy               21-Jan-2021             [PC-7102] Added FLS Check
Haritha Reddy              21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*/

public with sharing class PC_SupportPlanBuilderController {
    public static final String FIELDSET_TEST = 'Test';
    /*********************************************************************************
	Method Name    : getListView
	Description    : Fetch list view ID of list view to show all Support Plans
	Input Params   : void
	Return Type    : List<ListView>
*********************************************************************************/
    @AuraEnabled
    public static List<ListView> getListView() {
        List<ListView> listviews;
        try{
            String supportPlanObjectName = PC_Constants.getQualifiedAPIName('PC_SupportPlan__c');
            String listViewName = PC_Constants.SUPPORTPLANT_LISTVIEWNAME;

            //FLS CHECK
            List<String> listviewFields = new List<String>{'Name'};
                PC_Database.assertAccess(PC_Constants.PC_LISTVIEW, PC_Database.Operation.Reading, listviewFields);

            //Query the ListView
            listviews = [SELECT Id, Name FROM ListView WHERE SobjectType = :supportPlanObjectName and Name = :listViewName];
        }
        catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }

        return listviews;
    }

    /*********************************************************************************
	Method Name    : activationStatus
	Description    : Activates and Deactivates the support plan
	Input Params   : BOOLEAN planStatus, Id supportPlanId
	Return Type    : void
	*********************************************************************************/
    @AuraEnabled
    public static void activationStatus(BOOLEAN planStatus, Id supportPlanId) {
        try{
            List<String> supportPlanFields = new List<String>{'Name',PC_Constants.getQualifiedAPIName('PC_IsActive__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'), PC_Database.Operation.Reading, supportPlanFields);

            PC_SupportPlan__c supportPlan = [SELECT Id, Name, PC_IsActive__c FROM PC_SupportPlan__c WHERE Id =: supportPlanId];
            supportPlan.PC_IsActive__c = (BOOLEAN)planStatus;
            PC_Database.upd(supportPlan,true);//FLS check happens in PC_Database upd
        }
        catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }

    /*********************************************************************************
	Method Name    : sortActList
	Description    : Sorting the Activity LIst
	Input Params   : List PC_SupportPlanActivity__c and ID initialActNumber
	Return Type    : List PC_SupportPlanActivity__c
	*********************************************************************************/
    @AuraEnabled
    public static LIST<PC_SupportPlanActivity__c> sortActList(LIST<PC_SupportPlanActivity__c> actList, Id initialActNumber) {
        LIST<PC_SupportPlanActivity__c> sortedList;
        try{
            sortedList      = new LIST<PC_SupportPlanActivity__c>();
            Map<ID,PC_SupportPlanActivity__c>   mapList = new Map<ID,PC_SupportPlanActivity__c>();
            for(PC_SupportPlanActivity__c a : actList){
                mapList.put(a.PC_InternalActivityNumber__c,a);
            }

            ID firstActivity                                = initialActNumber;
            LIST<PC_SupportPlanActivity__c> unsortedList    = actList;

            Integer doWhileCounter = 0;
            Integer doWhileCounterLimit = actList.size()-1;
            Integer i = 0;
            String nextAct;
            String nextSeqAct;
            //Get The First Activity
            sortedList.add(mapList.get(firstActivity));
            do{
                if(sortedList[i].PC_InternalActivityType__c == PC_Constants.SUPPORTPLAN_USERTASK){
                    nextAct = sortedList[i].PC_NextActivityNumber__c;
                }else if(sortedList[i].PC_InternalActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_SEQUENCE){
                    nextAct      = sortedList[i].PC_NextActivityNumber__c;
                    nextSeqAct   = sortedList[i].PC_InitialSequenceActivity__c;
                }else if(sortedList[i].PC_InternalActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_SEQUENCE_TASK){
                    nextSeqAct   = sortedList[i].PC_NextActivityNumber__c;
                }
                if(!String.isEmpty(nextSeqAct)){
                    i++;
                    sortedList.add(mapList.get(nextSeqAct));
                }else{
                    if(!String.isEmpty(nextAct)){
                        i++;
                        sortedList.add(mapList.get(nextAct));
                    }
                }
                doWhileCounter++;
            }while(doWhileCounter < doWhileCounterLimit);

            /*for(integer i=0; i < unsortedList.size(); i++){
                if(unsortedList[i].PC_InternalActivityNumber__c == firstActivity){
                    sortedList.add(unsortedList[i]);
                    firstActivity   = 'a0T1I000000XXxxxxx';
                    i = -1;
                } else if(sortedList.size() != 0){
                    if(sortedList[j].PC_NextActivityNumber__c == unsortedList[i].PC_InternalActivityNumber__c && sortedList.size() != 0){
                        j++;
                        sortedList.add(unsortedList[i].clone(true, true, true, true));
                        unsortedList[i].PC_InternalActivityNumber__c = 'a0T1I000001XRxxxx'+i;
                        i = -1;
                    }
                }
            }*/
        }
        catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return sortedList;
    }

    /*********************************************************************************
	Method Name    : saveDropOnHead
	Description    : Save Each Reorder
	Input Params   : ID draggedItemId, Id headItemId, ID supportPlanId
	Return Type    : void
	*********************************************************************************/
    @AuraEnabled
    public static void saveDropOnHead(ID draggedItemId, Id headItemId, ID supportPlanId) {
        try{
            //FLS Check
            //Activity
            List<String> actListFields = new List<String>{'Name',PC_Constants.getQualifiedAPIName('PC_InternalActivityNumber__c'),
                PC_Constants.getQualifiedAPIName('PC_NextActivityNumber__c'),PC_Constants.getQualifiedAPIName('PC_InternalActivityType__c'),
                    PC_Constants.getQualifiedAPIName('PC_InitialSequenceActivity__c'),PC_Constants.getQualifiedAPIName('PC_ActivitySequence__c')};

            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c'), PC_Database.Operation.Reading, actListFields);

            //Support Plan
            List<String> supportPlanFields = new List<String>{'Name',PC_Constants.getQualifiedAPIName('PC_InitialActivity__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'), PC_Database.Operation.Reading, supportPlanFields);

            //Fetch Support Activity
            LIST<PC_SupportPlanActivity__c> actList = [SELECT ID, Name, PC_InternalActivityNumber__c, PC_NextActivityNumber__c, PC_InternalActivityType__c, PC_InitialSequenceActivity__c, PC_ActivitySequence__c FROM PC_SupportPlanActivity__c
                                                       WHERE PC_SupportPlan__c = :supportPlanId];

            //Fetch Support Plan
            PC_SupportPlan__c supportPlan = [SELECT Id, Name, PC_InitialActivity__c FROM PC_SupportPlan__c WHERE ID =: supportPlanId];

            //Get Sorted Acticity List
            LIST<PC_SupportPlanActivity__c> actSortedList = sortActList (actList,supportPlan.PC_InitialActivity__c);

            //Fetch Dragged Activity
            PC_SupportPlanActivity__c draggedItem   = [SELECT ID, Name, PC_InternalActivityNumber__c, PC_InternalActivityType__c, PC_NextActivityNumber__c, PC_ActivitySequence__c FROM PC_SupportPlanActivity__c
                                                       WHERE PC_InternalActivityNumber__c = :draggedItemId];

            //Fetch Sequence Activity
            PC_SupportPlanActivity__c IntSeqAct;
            if(!String.isEmpty(draggedItem.PC_ActivitySequence__c)) {
                IntSeqAct = [
                        SELECT PC_InitialSequenceActivity__c
                        FROM PC_SupportPlanActivity__c
                        WHERE PC_InternalActivityNumber__c = :draggedItem.PC_ActivitySequence__c
                ];
            }

            //Drop on Same Location //Do Nothing
            if(draggedItemId != headItemId && draggedItem.PC_NextActivityNumber__c != headItemId){
                for(PC_SupportPlanActivity__c actListitem : actSortedList){
                    if(actListitem.PC_NextActivityNumber__c == draggedItemId){
                        PC_SupportPlanActivity__c updateACtivity = actListitem.clone(true, true, true, true);
                        updateACtivity.PC_NextActivityNumber__c = draggedItem.PC_NextActivityNumber__c;
                        PC_Database.upd(updateACtivity,true); //FLS check happens in PC_Database upd
                    }
                    if(actListitem.PC_NextActivityNumber__c == headItemId){
                        if(actListitem.PC_InternalActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_SEQUENCE_TASK && actListitem.PC_ActivitySequence__c != draggedItem.PC_ActivitySequence__c ){
                            //do Nothing

                        }else {
                            PC_SupportPlanActivity__c updateACtivity = actListitem.clone(true, true, true, true);
                            updateACtivity.PC_NextActivityNumber__c = draggedItemId;
                            PC_Database.upd(updateACtivity, true); //FLS check happens in PC_Database upd
                        }
                    }
                }

                //Drap Drop First Activity
                if(supportPlan.PC_InitialActivity__c == draggedItemId){
                    supportPlan.PC_InitialActivity__c =  draggedItem.PC_NextActivityNumber__c;
                    PC_Database.upd(supportPlan,true); //FLS check happens in PC_Database upd
                    updateReferenceType((ID) ID.valueOf(draggedItem.PC_NextActivityNumber__c), supportPlan.Id);
                } else if(supportPlan.PC_InitialActivity__c == headItemId){
                    supportPlan.PC_InitialActivity__c =  draggedItemId;
                    PC_Database.upd(supportPlan,true); //FLS check happens in PC_Database upd
                    updateReferenceType(draggedItemId,supportPlan.Id);
                }

                //Drap Drop First Seq Activity in the seq
                if(!String.isEmpty(draggedItem.PC_ActivitySequence__c)){
                    if(IntSeqAct.PC_InitialSequenceActivity__c == draggedItemId){
                        IntSeqAct.PC_InitialSequenceActivity__c =  draggedItem.PC_NextActivityNumber__c;
                        PC_Database.upd(IntSeqAct,true); //FLS check happens in PC_Database upd
                        updateReferenceType((ID) ID.valueOf(draggedItem.PC_NextActivityNumber__c), supportPlan.Id);
                    } else if(IntSeqAct.PC_InitialSequenceActivity__c == headItemId){
                        IntSeqAct.PC_InitialSequenceActivity__c =  draggedItemId;
                        PC_Database.upd(IntSeqAct,true); //FLS check happens in PC_Database upd
                        updateReferenceType(draggedItemId , supportPlan.Id);
                    }
                }

                draggedItem.PC_NextActivityNumber__c = headItemId;
                PC_Database.upd(draggedItem,true); //FLS check happens in PC_Database upd
            }
        }
        catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }

    /*********************************************************************************
	Method Name    : saveSwap
	Description    : Save Each Reorder
	Input Params   : ID draggedItemId, ID droppedItem
	Return Type    : void
	*********************************************************************************/
    @AuraEnabled
    public static void saveSwap(ID draggedItemId, Id droppedItemId, ID supportPlanId) {
        try{
            //FLS Check
            //Activity
            List<String> actListFields = new List<String>{'Name',PC_Constants.getQualifiedAPIName('PC_InternalActivityNumber__c'),
                PC_Constants.getQualifiedAPIName('PC_NextActivityNumber__c'),PC_Constants.getQualifiedAPIName('PC_InternalActivityType__c'),
                    PC_Constants.getQualifiedAPIName('PC_InitialSequenceActivity__c'),PC_Constants.getQualifiedAPIName('PC_ActivitySequence__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c'), PC_Database.Operation.Reading, actListFields);

            //Support Plan
            List<String> supportPlanFields = new List<String>{'Name',PC_Constants.getQualifiedAPIName('PC_InitialActivity__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'), PC_Database.Operation.Reading, supportPlanFields);

            //Fetch Support Activity
            LIST<PC_SupportPlanActivity__c> actList = [SELECT ID, Name, PC_InternalActivityNumber__c, PC_NextActivityNumber__c, PC_InternalActivityType__c, PC_InitialSequenceActivity__c FROM PC_SupportPlanActivity__c
                                                       WHERE PC_SupportPlan__c = :supportPlanId];

            //Fetch Support Plan
            PC_SupportPlan__c supportPlan = [SELECT Id, Name, PC_InitialActivity__c FROM PC_SupportPlan__c WHERE ID =: supportPlanId];

            //Get Sorted Acticity List
            LIST<PC_SupportPlanActivity__c> actSortedList = sortActList (actList,supportPlan.PC_InitialActivity__c);

            //Fetch Dragged Activity
            PC_SupportPlanActivity__c draggedItem   = [SELECT ID, Name, PC_InternalActivityNumber__c, PC_NextActivityNumber__c, PC_ActivitySequence__c FROM PC_SupportPlanActivity__c
                                                       WHERE PC_InternalActivityNumber__c = :draggedItemId];

            //Fetch Dropped Activity
            PC_SupportPlanActivity__c droppedItem   = [SELECT ID, Name, PC_InternalActivityNumber__c, PC_NextActivityNumber__c, PC_ActivitySequence__c FROM PC_SupportPlanActivity__c
                                                       WHERE PC_InternalActivityNumber__c = :droppedItemId];

            //Fetch Sequence Activity
            PC_SupportPlanActivity__c IntSeqAct;
            if(!String.isEmpty(draggedItem.PC_ActivitySequence__c)) {
                IntSeqAct = [
                        SELECT PC_InitialSequenceActivity__c
                        FROM PC_SupportPlanActivity__c
                        WHERE PC_InternalActivityNumber__c = :draggedItem.PC_ActivitySequence__c
                ];
            }

            //If Consecutive Activities are Swapped
            if(draggedItem.PC_NextActivityNumber__c == droppedItem.PC_InternalActivityNumber__c ||
               droppedItem.PC_NextActivityNumber__c == draggedItem.PC_InternalActivityNumber__c){
                   //If Dragged Activity on Top
                   if(draggedItem.PC_NextActivityNumber__c == droppedItem.PC_InternalActivityNumber__c){
                       //Dragged or Dropped Activity is First ACtivity
                       if(draggedItem.PC_InternalActivityNumber__c == supportPlan.PC_InitialActivity__c){
                           supportPlan.PC_InitialActivity__c   =   droppedItemId;
                           PC_Database.upd(supportPlan,true); //FLS check happens in PC_Database upd
                           updateReferenceType(droppedItemId, supportPlan.Id);
                       }
                       //Dragged Activity is First Activity in Seq
                       if(!String.isEmpty(draggedItem.PC_ActivitySequence__c)) {
                           if (draggedItem.PC_InternalActivityNumber__c == IntSeqAct.PC_InitialSequenceActivity__c) {
                               IntSeqAct.PC_InitialSequenceActivity__c = droppedItemId;
                               PC_Database.upd(IntSeqAct, true);
                               updateReferenceType(droppedItemId, supportPlan.Id);
                           }
                       }
                       for(PC_SupportPlanActivity__c actListitem : actSortedList){
                           if(actListitem.PC_NextActivityNumber__c == draggedItemId && actListitem.ID != draggedItemId){
                               PC_SupportPlanActivity__c updateACtivity = actListitem.clone(true, true, true, true);
                               updateACtivity.PC_NextActivityNumber__c = droppedItemId;
                               PC_Database.upd(updateACtivity,true); //FLS check happens in PC_Database upd
                               break;
                           }
                       }
                       ID draggedItemNextActivityNumber = draggedItem.PC_NextActivityNumber__c;
                       ID droppedItemNextActivityNumber = droppedItem.PC_NextActivityNumber__c;
                       draggedItem.PC_NextActivityNumber__c = droppedItemNextActivityNumber;
                       droppedItem.PC_NextActivityNumber__c = draggedItem.PC_InternalActivityNumber__c;
                       PC_Database.upd(draggedItem,true); //FLS check happens in PC_Database upd
                       PC_Database.upd(droppedItem,true); //FLS check happens in PC_Database upd

                   } //If Dropped Activity on Top
                   else if (droppedItem.PC_NextActivityNumber__c == draggedItem.PC_InternalActivityNumber__c){
                       //Dragged or Dropped Activity is First ACtivity
                       if(droppedItem.PC_InternalActivityNumber__c == supportPlan.PC_InitialActivity__c){
                           supportPlan.PC_InitialActivity__c   =   draggedItemId;
                           PC_Database.upd(supportPlan,true); //FLS check happens in PC_Database upd
                           updateReferenceType(draggedItemId, supportPlan.Id);
                       }
                       //Dropped Activity is First Activity in Seq
                       if(!String.isEmpty(draggedItem.PC_ActivitySequence__c)) {
                           if (droppedItem.PC_InternalActivityNumber__c == IntSeqAct.PC_InitialSequenceActivity__c) {
                               IntSeqAct.PC_InitialSequenceActivity__c = draggedItemId;
                               PC_Database.upd(IntSeqAct, true);
                               updateReferenceType(draggedItemId, supportPlan.Id);
                           }
                       }
                       for(PC_SupportPlanActivity__c actListitem : actSortedList){
                           if(actListitem.PC_NextActivityNumber__c == droppedItemId && actListitem.ID != droppedItemId){
                               PC_SupportPlanActivity__c updateACtivity = actListitem.clone(true, true, true, true);
                               updateACtivity.PC_NextActivityNumber__c = draggedItemId;
                               PC_Database.upd(updateACtivity,true); //FLS check happens in PC_Database upd
                           }
                       }
                       ID draggedItemNextActivityNumber = draggedItem.PC_NextActivityNumber__c;
                       ID droppedItemNextActivityNumber = droppedItem.PC_NextActivityNumber__c;
                       draggedItem.PC_NextActivityNumber__c = droppedItem.PC_InternalActivityNumber__c;
                       droppedItem.PC_NextActivityNumber__c = draggedItemNextActivityNumber;
                       PC_Database.upd(draggedItem,true); //FLS check happens in PC_Database upd
                       PC_Database.upd(droppedItem,true); //FLS check happens in PC_Database upd
                   }
               } //If Non-Consecutive Activities are Swapped
            else {
                for(PC_SupportPlanActivity__c actListitem : actSortedList){
                    if(actListitem.ID != draggedItemId && actListitem.ID != droppedItemId){
                        if(actListitem.PC_NextActivityNumber__c == draggedItemId){
                            PC_SupportPlanActivity__c updateACtivity = actListitem.clone(true, true, true, true);
                            updateACtivity.PC_NextActivityNumber__c = droppedItemId;
                            PC_Database.upd(updateACtivity,true); //FLS check happens in PC_Database upd
                        }
                        if(actListitem.PC_NextActivityNumber__c == droppedItemId){
                            PC_SupportPlanActivity__c updateACtivity = actListitem.clone(true, true, true, true);
                            updateACtivity.PC_NextActivityNumber__c = draggedItemId;
                            PC_Database.upd(updateACtivity,true); //FLS check happens in PC_Database upd
                        }
                    }
                }
                //Dragged or Dropped Activity is First ACtivity
                if(draggedItem.PC_InternalActivityNumber__c == supportPlan.PC_InitialActivity__c){
                    supportPlan.PC_InitialActivity__c   =   droppedItemId;
                    PC_Database.upd(supportPlan,true); //FLS check happens in PC_Database upd
                    updateReferenceType(droppedItemId, supportPlan.Id);
                } else if(droppedItem.PC_InternalActivityNumber__c == supportPlan.PC_InitialActivity__c){
                    supportPlan.PC_InitialActivity__c   =   draggedItemId;
                    PC_Database.upd(supportPlan,true); //FLS check happens in PC_Database upd
                    updateReferenceType(draggedItemId, supportPlan.Id);
                }

                //Dragged or Dropped Activity is First Activity in Seq
                if(!String.isEmpty(draggedItem.PC_ActivitySequence__c)) {
                    if (draggedItem.PC_InternalActivityNumber__c == IntSeqAct.PC_InitialSequenceActivity__c) {
                        IntSeqAct.PC_InitialSequenceActivity__c = droppedItemId;
                        PC_Database.upd(IntSeqAct, true);
                        updateReferenceType(droppedItemId, supportPlan.Id);
                    } else if (droppedItem.PC_InternalActivityNumber__c == IntSeqAct.PC_InitialSequenceActivity__c) {
                        IntSeqAct.PC_InitialSequenceActivity__c = draggedItemId;
                        PC_Database.upd(IntSeqAct, true);
                        updateReferenceType(draggedItemId, supportPlan.Id);
                    }
                }

                //Update the PC_NextActivityNumber__c of Swapped Activities
                ID draggedItemNextActivityNumber    = draggedItem.PC_NextActivityNumber__c;
                ID droppedItemNextActivityNumber    = droppedItem.PC_NextActivityNumber__c;

                draggedItem.PC_NextActivityNumber__c = droppedItemNextActivityNumber;
                PC_Database.upd(draggedItem,true); //FLS check happens in PC_Database upd

                droppedItem.PC_NextActivityNumber__c = draggedItemNextActivityNumber;
                PC_Database.upd(droppedItem,true); //FLS check happens in PC_Database upd

            }
        }
        catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }

    /*********************************************************************************
	Method Name    : getActivities
	Description    : Fetch Activities for Support Plan
	Input Params   : ID supportPlanId
	Return Type    : SupportPlanContentWrapper
	*********************************************************************************/
    @AuraEnabled
    public static SupportPlanContentWrapper getActivities(ID supportPlanId) {
        SupportPlanContentWrapper activities;
        try{
            //FLS Check
            //Activity
            List<String> actListFields = new List<String>{'Name',PC_Constants.getQualifiedAPIName('PC_ActivitySequence__c'),PC_Constants.getQualifiedAPIName('PC_ActivityType__c'),
                PC_Constants.getQualifiedAPIName('PC_InternalActivityType__c'),PC_Constants.getQualifiedAPIName('PC_AlternateActivity__c'),PC_Constants.getQualifiedAPIName('PC_ApexCondition__c'),
                PC_Constants.getQualifiedAPIName('PC_Channel__c'),PC_Constants.getQualifiedAPIName('PC_Conditional_Logic__c'),PC_Constants.getQualifiedAPIName('PC_ConditionBehavior__c'),
                PC_Constants.getQualifiedAPIName('PC_ConditionOption__c'),PC_Constants.getQualifiedAPIName('PC_Description__c'),
                PC_Constants.getQualifiedAPIName('PC_InitialSequenceActivity__c'),PC_Constants.getQualifiedAPIName('PC_InternalActivityNumber__c'),PC_Constants.getQualifiedAPIName('PC_NextActivityNumber__c'),
                PC_Constants.getQualifiedAPIName('PC_Priority__c'),PC_Constants.getQualifiedAPIName('PC_ReferenceDate__c'),PC_Constants.getQualifiedAPIName('PC_ReferenceOffset__c'),
                PC_Constants.getQualifiedAPIName('PC_ReferenceOffsetUnit__c'),PC_Constants.getQualifiedAPIName('PC_SubType__c'),PC_Constants.getQualifiedAPIName('PC_ActionClass__c'),PC_Constants.getQualifiedAPIName('PC_ReferenceType__c'),
                PC_Constants.getQualifiedAPIName('PC_Subject__c'),PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'),PC_Constants.getQualifiedAPIName('PC_Assign_To_Role__c'),PC_Constants.getQualifiedAPIName('PC_UserTask_Fields__c'),
                    PC_Constants.getQualifiedAPIName('PC_AutomationTaskJSON__c'),PC_Constants.getQualifiedAPIName('PC_ClonedFrom__c'),PC_Constants.getQualifiedAPIName('PC_GroupActivityExecution__c')};

             PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c'), PC_Database.Operation.Reading, actListFields);

            //Support Plan
            List<String> supportPlanFields = new List<String>{'Name',PC_Constants.getQualifiedAPIName('PC_ConditionBehavior__c'),PC_Constants.getQualifiedAPIName('PC_Description__c'),
                    PC_Constants.getQualifiedAPIName('PC_TriggerEventObject__c'),
                PC_Constants.getQualifiedAPIName('PC_InitialActivity__c'),PC_Constants.getQualifiedAPIName('PC_IsActive__c'),PC_Constants.getQualifiedAPIName('PC_StartCondition__c'),
                PC_Constants.getQualifiedAPIName('PC_Version__c'),PC_Constants.getQualifiedAPIName('PC_Conditional_Logic__c'),PC_Constants.getQualifiedAPIName('PC_Condition_Option__c')};

            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'), PC_Database.Operation.Reading, supportPlanFields);

            PC_SupportPlan__c supportPlan = [SELECT Id, Name, PC_ConditionBehavior__c, PC_Description__c,PC_TriggerEventObject__c, PC_InitialActivity__c, PC_IsActive__c, PC_StartCondition__c,
                                                PC_Version__c, PC_Conditional_Logic__c, PC_Condition_Option__c
                                             FROM PC_SupportPlan__c WHERE ID =: supportPlanId];

            List<PC_SupportPlanActivity__c> supportActivity = [SELECT Id, Name, PC_ActivitySequence__c, PC_ActivityType__c, PC_InternalActivityType__c, PC_AlternateActivity__c, PC_ApexCondition__c,
                                                               PC_Channel__c, PC_Conditional_Logic__c, PC_ConditionBehavior__c, PC_ConditionOption__c, PC_Description__c, PC_InitialSequenceActivity__c, PC_InternalActivityNumber__c,
                                                               PC_NextActivityNumber__c, PC_Priority__c, PC_ReferenceDate__c, PC_ReferenceOffset__c, PC_ReferenceOffsetUnit__c,PC_SubType__c,PC_ActionClass__c,
                                                               PC_ReferenceType__c, PC_Subject__c, PC_SupportPlan__c, PC_Assign_To_Role__c, PC_UserTask_Fields__c,PC_AutomationTaskJSON__c,PC_ClonedFrom__c, PC_GroupActivityExecution__c
                                                               FROM PC_SupportPlanActivity__c WHERE PC_SupportPlan__c =: supportPlanId Order by PC_InternalActivityNumber__c ASC];

            activities = new SupportPlanContentWrapper();
            activities.supportPlan = new SupportPlanWrapper(supportPlan);
            activities.supportActivity = new LIST<SupportPlanActivityWrapper>();
            for(PC_SupportPlanActivity__c spa : supportActivity){
                SupportPlanActivityWrapper spaWrapper	= new SupportPlanActivityWrapper(spa);
                activities.supportActivity.add(spaWrapper);
            }

        }
        catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return activities;
    }

    /*********************************************************************************
      Method Name    : change Reference Type value for first activity after swap
      Author         : Tejas Patel
      Description    : This method updates the first activity refernce type to "Activity creation date"
      Return Type    : void
      Parameter      : Initial Activity Id
     *********************************************************************************/
    @AuraEnabled
    public static Boolean updateReferenceType(ID activityId , ID supportPlanId){
        try {

            List<String> spaFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_InternalActivityNumber__c'),PC_Constants.getQualifiedAPIName('PC_InternalActivityType__c'),
                    PC_Constants.getQualifiedAPIName('PC_ReferenceType__c'),PC_Constants.getQualifiedAPIName('PC_GroupActivityExecution__c'),PC_Constants.getQualifiedAPIName('PC_InitialSequenceActivity__c'),
                    PC_Constants.getQualifiedAPIName('PC_SupportPlan__c'),PC_Constants.getQualifiedAPIName('PC_ActivitySequence__c')};

            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_SupportPlanActivity__c'), PC_Database.Operation.Reading, spaFields);

            List<PC_SupportPlanActivity__c> supportActivitiestoUpdate = new List<PC_SupportPlanActivity__c>();
            PC_SupportPlanActivity__c supportActivity = [SELECT PC_InternalActivityNumber__c, PC_InternalActivityType__c,
                                                        PC_ReferenceType__c, PC_GroupActivityExecution__c , PC_InitialSequenceActivity__c FROM PC_SupportPlanActivity__c
                                                        where PC_SupportPlan__c =: supportPlanId AND PC_InternalActivityNumber__c = :activityId LIMIT 1];

            if(supportActivity.PC_InternalActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_MANUAL_TASK){
                if(supportActivity.PC_ReferenceType__c == PC_Constants.PC_AFTER_COMPLETION_OF_PREVIOUS_ACTIVITY) {
                    supportActivity.PC_ReferenceType__c = PC_Constants.PC_ACTIVITY_CREATION_DATE;
                    supportActivitiestoUpdate.add(supportActivity);
                }
            }else if(supportActivity.PC_InternalActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_SEQUENCE_TASK){
                if(supportActivity.PC_ReferenceType__c == PC_Constants.PC_AFTER_COMPLETION_OF_PREVIOUS_ACTIVITY) {
                    supportActivity.PC_ReferenceType__c = PC_Constants.PC_ACTIVITY_CREATION_DATE;
                    supportActivitiestoUpdate.add(supportActivity);
                }
            }else if (supportActivity.PC_InternalActivityType__c == PC_Constants.SUPPORTPLAN_ACTIVITY_TYPE_SEQUENCE){
                List<PC_SupportPlanActivity__c> supportActivitiesforSequence = [SELECT PC_InternalActivityNumber__c, PC_InternalActivityType__c,
                        PC_ReferenceType__c, PC_GroupActivityExecution__c FROM PC_SupportPlanActivity__c
                where PC_SupportPlan__c =: supportPlanId AND PC_ActivitySequence__c = :supportActivity.PC_InternalActivityNumber__c];

                Map<String,PC_SupportPlanActivity__c> supportActivityMap = new Map<String,PC_SupportPlanActivity__c>();

                for(PC_SupportPlanActivity__c sp : supportActivitiesforSequence){
                    supportActivityMap.put(sp.PC_InternalActivityNumber__c,sp);
                }
                if(supportActivity.PC_GroupActivityExecution__c == PC_Constants.PC_IN_SEQUENCE){
                    PC_SupportPlanActivity__c supportSeqActivity = supportActivityMap.get(supportActivity.PC_InitialSequenceActivity__c);
                    if(supportSeqActivity.PC_ReferenceType__c == PC_Constants.PC_AFTER_COMPLETION_OF_PREVIOUS_ACTIVITY) {
                        supportSeqActivity.PC_ReferenceType__c = PC_Constants.PC_ACTIVITY_CREATION_DATE;
                        supportActivitiestoUpdate.add(supportSeqActivity);
                    }
                }else if(supportActivity.PC_GroupActivityExecution__c == PC_Constants.PC_ALL_AT_ONCE){
                    for(PC_SupportPlanActivity__c sp : supportActivitiesforSequence){
                        if(sp.PC_ReferenceType__c == PC_Constants.PC_AFTER_COMPLETION_OF_PREVIOUS_ACTIVITY){
                            sp.PC_ReferenceType__c = PC_Constants.PC_ACTIVITY_CREATION_DATE;
                            supportActivitiestoUpdate.add(sp);
                        }
                    }
                }
            }

            if(supportActivitiestoUpdate.size() > 0){
                PC_Database.upd(supportActivitiestoUpdate,true);
            }
        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return true;
    }

    /*********************************************************************************
      Method Name    : isValidFieldSet
      Author         : Vivek Kumar Mishra
      Description    : This method checks if the provided field set name is valid or not
      Return Type    : Schema.FieldSet
      Parameter      : SObjects Name and SObjects Field Set Name
     *********************************************************************************/
    @AuraEnabled
    public static Boolean isValidFieldSet(String objectTypeName, String fieldSetName){
        Boolean isValid = false;
        try {
            if(fieldSetName == PC_Constants.PC_TaskFieldSetNameForCaseObject || fieldSetName == PC_Constants.PC_TaskFieldSetNameForNonCaseObjects){
                fieldSetName = PC_Constants.getQualifiedAPIName(fieldSetName);
            }
            isValid = PC_Utility.isValidFieldSet(objectTypeName,fieldSetName);
            if (!isValid) {
                if (fieldSetName == FIELDSET_TEST) {
                    return false;
                }
                PC_Utility.throwAuraHandledException('Something is wrong with the field set');
            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return true;
    }

    public inherited sharing class SupportPlanContentWrapper {
        @AuraEnabled public SupportPlanWrapper supportPlan {get; set;}
        @AuraEnabled public List<SupportPlanActivityWrapper> supportActivity {get; set;}

        public SupportPlanContentWrapper() {}
    }

    public inherited sharing class SupportPlanWrapper {
        @AuraEnabled public ID 		Id {get; set;}
        @AuraEnabled public STRING 	supportplanname {get; set;}
        @AuraEnabled public STRING 	conditionbehavior {get; set;}
        @AuraEnabled public STRING 	description {get; set;}

        @AuraEnabled public STRING 	initialactivity {get; set;}
        @AuraEnabled public BOOLEAN	isactive {get; set;}
        @AuraEnabled public STRING 	startcondition {get; set;}
        @AuraEnabled public STRING 	version {get; set;}
        @AuraEnabled public STRING 	triggerEventObjectLabel {get; set;}
        @AuraEnabled public STRING 	triggerEventObjectApiName {get; set;}

        public SupportPlanWrapper() {}

        public SupportPlanWrapper(PC_SupportPlan__c sp) {
            Id					= 	sp.Id;
            supportplanname		=	sp.Name;
            conditionbehavior	=	sp.PC_ConditionBehavior__c;
            description   		=	sp.PC_Description__c;
            initialactivity		=	sp.PC_InitialActivity__c;
            isactive  			=	sp.PC_IsActive__c;
            startcondition		=	sp.PC_StartCondition__c;
            version				=	sp.PC_Version__c;
            triggerEventObjectApiName  =   sp.PC_TriggerEventObject__c;
            if(triggerEventObjectApiName != null){
                triggerEventObjectLabel  =   Schema.getGlobalDescribe().get(triggerEventObjectApiName).getDescribe().getLabel();
            }
        }
    }

    public inherited sharing class SupportPlanActivityWrapper {
        @AuraEnabled public ID 		Id {get; set;}
        @AuraEnabled public STRING 	activityname {get; set;}
        @AuraEnabled public STRING 	activitysequence {get; set;}
        @AuraEnabled public STRING 	activitytype {get; set;}
        @AuraEnabled public STRING 	assigntorole {get; set;}

        @AuraEnabled public STRING 	internalactivitytype {get; set;}
        @AuraEnabled public STRING	alternateactivity {get; set;}
        @AuraEnabled public STRING 	apexcondition {get; set;}
        @AuraEnabled public STRING 	channel {get; set;}
        @AuraEnabled public STRING 	conditionallogic {get; set;}
        @AuraEnabled public STRING 	conditionbehavior {get; set;}

        @AuraEnabled public STRING 	conditionoption {get; set;}
        @AuraEnabled public STRING	description {get; set;}
        @AuraEnabled public STRING 	initialsequenceactivity {get; set;}
        @AuraEnabled public STRING 	internalactivitynumber {get; set;}
        @AuraEnabled public STRING 	nextactivitynumber {get; set;}

        @AuraEnabled public STRING 	priority {get; set;}
        @AuraEnabled public STRING	referencedate {get; set;}
        @AuraEnabled public STRING 	referenceoffset {get; set;}
        @AuraEnabled public STRING 	referenceoffsetunit {get; set;}
        @AuraEnabled public STRING 	referencetype {get; set;}

        @AuraEnabled public STRING	subject {get; set;}
        @AuraEnabled public STRING 	supportplan {get; set;}

        @AuraEnabled public STRING 	usertaskfields {get; set;}
        @AuraEnabled public STRING 	objectFieldsMap {get; set;}
        @AuraEnabled public STRING  subType {get; set; }
        @AuraEnabled public STRING  actionClass {get; set; }
        @AuraEnabled public STRING  automationtaskjson {get; set; }
        @AuraEnabled public STRING  groupactivityexecution {get; set; }
        @AuraEnabled public STRING  fieldMapping {get; set; }
        @AuraEnabled public STRING  objectDetails {get; set; }
        @AuraEnabled public STRING  outcomeTaskDetails{get; set; }


        public SupportPlanActivityWrapper() {}

        public SupportPlanActivityWrapper(PC_SupportPlanActivity__c spa) {
            Id						= 	spa.Id;
            activityname			=	spa.Name;
            activitysequence		=	spa.PC_ActivitySequence__c;
            activitytype   			=	spa.PC_ActivityType__c;
            assigntorole            =   spa.PC_Assign_To_Role__c;
            internalactivitytype	=	spa.PC_InternalActivityType__c;
            alternateactivity  		=	spa.PC_AlternateActivity__c;
            apexcondition			=	spa.PC_ApexCondition__c;
            channel					=	spa.PC_Channel__c;
            conditionallogic        =   spa.PC_Conditional_Logic__c;
            conditionbehavior		=	spa.PC_ConditionBehavior__c;
            conditionoption			= 	spa.PC_ConditionOption__c;
            description				=	spa.PC_Description__c;
            initialsequenceactivity	=	spa.PC_InitialSequenceActivity__c;
            internalactivitynumber  =	spa.PC_InternalActivityNumber__c;
            nextactivitynumber		=	spa.PC_NextActivityNumber__c;
            priority  				=	spa.PC_Priority__c;
            referencedate			=	spa.PC_ReferenceDate__c;
            referenceoffset			=	spa.PC_ReferenceOffset__c;
            referenceoffsetunit		=	spa.PC_ReferenceOffsetUnit__c;
            referencetype  			=	spa.PC_ReferenceType__c;
            subject					=	spa.PC_Subject__c;
            supportplan				=	STRING.valueOf(spa.PC_SupportPlan__c);
            usertaskfields          =   spa.PC_UserTask_Fields__c;
            subType                 =   spa.PC_SubType__c;
            actionClass             =   spa.PC_ActionClass__c;
            if(spa.PC_ActivityType__c == 'Automation Task') {
                automationtaskjson = spa.PC_AutomationTaskJSON__c;
            }else{
                objectFieldsMap = spa.PC_AutomationTaskJSON__c;
            }
            groupactivityexecution  =   spa.PC_GroupActivityExecution__c;

        }
    }
}