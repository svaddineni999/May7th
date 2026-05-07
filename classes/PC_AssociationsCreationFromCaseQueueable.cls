/*********************************************************************************************************
Class Name      : PC_AssociationsCreationFromCaseQueueable
Description     : Queueable class which will be called by case handler and association handler to create Associations asynchronously
Created By      : Pavankumar
Created Date    : March 08, 2022
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Pavan Kumar                 Mar 08, 2022            [PC-8568] Added logic to create Association records
****************************************************************************************************************/

public with sharing class PC_AssociationsCreationFromCaseQueueable implements Queueable {
    public List<PC_Association__c> associationsToCreate = new List<PC_Association__c>();
    public List<PC_ProgramRegionUserHistory__c> programRegionHistoryCreateList = new List<PC_ProgramRegionUserHistory__c>();
    public List<PC_ProgramRegionUserHistory__c> programRegionHistoryDeleteList = new List<PC_ProgramRegionUserHistory__c>();
    String handlerName;
    public PC_AssociationsCreationFromCaseQueueable(PC_WorkCaseDistributionHelper.WCDOutputWrapper wcdOutputWrapper, String handler) {
        associationsToCreate = wcdOutputWrapper.associationListToCreate;
        programRegionHistoryCreateList = wcdOutputWrapper.programRegionHistoryCreateList;
        programRegionHistoryDeleteList = wcdOutputWrapper.programRegionHistoryDeleteList;
        handlerName = handler;

        system.debug('QUEQEABLE APEX --- associationsToCreate '+associationsToCreate);
        system.debug('QUEQEABLE APEX --- programRegionHistoryCreateList '+programRegionHistoryCreateList);
        system.debug('QUEQEABLE APEX --- programRegionHistoryDeleteList '+programRegionHistoryDeleteList);
    }

    /**
     * This method is used to create Associations
     *
     * @param context
     */
    public void execute(QueueableContext context) {

        if (handlerName == String.valueOf(PC_WorkCaseDistributionHelper.Handlers.CaseHandler)){
            PC_WorkCaseDistributionForCaseHandler.isProcessed = true;
            PC_WorkCaseDistributionForCaseHandler.processedAsynchronously = true;
            PC_Database.ins(associationsToCreate, false);
            PC_Database.del(programRegionHistoryDeleteList, false);
            PC_Database.ins(programRegionHistoryCreateList, false);
        } else if (handlerName == String.valueOf(PC_WorkCaseDistributionHelper.Handlers.AssociationHandler)){
            PC_WorkCaseDistributionForAssocHandler.isProcessed = true;
            PC_WorkCaseDistributionForAssocHandler.processedAsynchronously = true;
            PC_Database.ins(associationsToCreate, false);
            PC_Database.del(programRegionHistoryDeleteList, false);
            PC_Database.ins(programRegionHistoryCreateList, false);
        } else if (handlerName == String.valueOf(PC_WorkCaseDistributionHelper.Handlers.AccountHandler)){
            PC_WorkCaseRedistributionForAccHandler.isProcessed = true;
            PC_Database.ins(associationsToCreate, false);
            PC_Database.del(programRegionHistoryDeleteList, false);
            PC_Database.ins(programRegionHistoryCreateList, false);
        } else if (handlerName == String.valueOf(PC_WorkCaseDistributionHelper.Handlers.AddressHandler)){
            PC_WorkCaseRedistributionForAddrHandler.isProcessed = true;
            PC_Database.ins(associationsToCreate, false);
            PC_Database.del(programRegionHistoryDeleteList, false);
            PC_Database.ins(programRegionHistoryCreateList, false);
        } else if (handlerName == String.valueOf(PC_WorkCaseDistributionHelper.Handlers.UserHandler)){
            PC_WorkCaseRedistributionForUserHandler.isProcessed = true;
            PC_Database.ins(associationsToCreate, false);
            PC_Database.del(programRegionHistoryDeleteList, false);
            PC_Database.ins(programRegionHistoryCreateList, false);
        }
    }
}