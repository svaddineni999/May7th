/**
 * Created by mapatil on 3/20/2018.
 */
/*********************************************************************************
Class Name      : PC_SupportPlan
Description        : <Purpose of the class and do’s and don’t’s, if any. Components using this class >
Created By        : mapatil
Created Date     : 3/20/2018
Modification Log:
-----------------------------------------------------------------------------
Developer             Date        Description
-----------------------------------------------------------------------------
Mike Klumpenaar       2018-03-19  New class for all support plan interfaces
Mayuresh Patil        2018-03-30  New methoid for triggering support plan engine for cases with existing runtimes
                                  and activites with "wait until true" condition.
Mayuresh Patil        2018-04-11  Making method and interfaces global
Haritha Reddy         2020-04-10  [PC-6033] Added new Interface Action2 and new parameter 'actionRecordId' in PerformActionResult
Haritha Reddy         21-Jan-2021   [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
Kishore Kanteti       17-Sep-2021   [PC-8127] Made Action2 interface global.
Kishore Kanteti       28-Sep-2021   [PC-8177] Added additional comments Attribute to PerformActionResult Wrapper
******************************************************************************/

/**
 * Wrapper class for support plan related interfaces and methods
 */
global with sharing class PC_SupportPlan {
    /**
     * Interface to evaluate a condition for a specific record.
     */
    global interface Condition {
        /**
         * Evaluates the condition for a specific record.
         *
         * @param recordId The Id of the record that we are evaluating the condition for.
         */
        Boolean evaluate(Id recordId);
    }

    /**
     * Process the support plan activity for the specified case ids.
     *
     * @param caseIds The Set of case Ids for which the support plan activity needs to be processed.
     *                Only cases with active support plan runtimes with the current activity status = "Pending Condition"
     *                will be processed.
     */
    global void processSupportPlanActivity(Set<Id> recordIds){
        PC_SupportPlanEngine.processSupportPlanActivity(recordIds);
    }

    /**
     * Interface used to implement the actions for automated activities in a support plan. Actions are registered and
     * associated with automated activities using PC_Support_Plan_Automation_Task custom metadata type.
     */
    global interface Action {
        /**
         * Performs the action configured by the support plan activity. This method must return a PerformActionResult
         * to indicate if the action has completed successfully, failed, or is still in progress. Actions that
         * cannot complete synchronously need to call back to the support plan runtime to report on their final outcome.
         *
         * @param source    The source object from which the automated task was triggered
         * @param sourceId  The record id of the source object record which triggered the automated task.
         * @param taskConfiguration The string saved from the lightning component on the support plan .
         * @param taskID  The task id of the support plan task created for the automated process.
         */
        PerformActionResult performAction(String source, String sourceId, String taskConfiguration, String taskID);
    }


    /**
     * Interface used to implement the actions for automated activities in a support plan. Actions are registered and
     * associated with automated activities using PC_Support_Plan_Automation_Task custom metadata type.
     * This is being used for Create Record, Publish Platform Event and Update Record Automation Tasks
     */
    global interface Action2 {
        /**
         * Performs the action configured by the support plan activity. This method must return a PerformActionResult
         * to indicate if the action has completed successfully, failed, or is still in progress. Actions that
         * cannot complete synchronously need to call back to the support plan runtime to report on their final outcome.
         *
         * @param automationTask  The AutomationTaskPlatform event with all action details
         */
        PerformActionResult performAction(PC_Automation_Task__e automationTask);
    }

    /**
     * Enumaration to indicated the runtime status of a support plan <code>Action</code>
     */
    global enum ActionStatus { COMPLETED_SUCCESS, COMPLETED_FAILED, IN_PROGRESS}

    /**
     * Contains the results of performing an action.
     */
    global inherited sharing class PerformActionResult {
        /**
         * Status of the performed action.
         */
        global ActionStatus actionStatus;

        /**
         * Error message of a failed action.
         */
        global String errorMessage;
        /**
         * Status of the performed action.
         */
        public String actionRecordId;
        /**
         * Additional Comments to be added on task about the performed action.
         */
        global String additionalComments;
    }
}