/*********************************************************************************************************
Class Name      : PC_CreateParticipantForNewCareTeamMember
Description     : Trigger handler on Association object to create Interaction participant when new care team member is added for related case.
Created By      : Haritha Reddy
Created Date    : Nov 20, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy           Nov 20, 2021            [PC-8312]Initial Version
************************************************************************************************************/
public inherited sharing class PC_CreateParticipantForNewCareTeamMember extends PC_TriggerHandler {
    override public void afterInsert(){
        createInteractionParticipants((List<PC_Association__c>)newList);
    }

    /*********************************************************************************
    Method Name    : createInteractionParticipants
    Description    : This method creates new interaction participant for new care team member added in related case.
    Return Type    : void
    Parameter      : List of incoming association records - Trigger.new
    *********************************************************************************/
    private void createInteractionParticipants(List<PC_Association__c> newAssociations) {
        Set<Id> caseIds = new Set<Id>();
        for(PC_Association__c association : newAssociations){
            caseIds.add(association.PC_Program__c);
        }
        List<PC_Interaction__c> interactionList = new List<PC_Interaction__c>();
        interactionList = [Select Id,PC_Participants__c,PC_Patient_Program__c FROM PC_Interaction__c WHERE PC_Participants__c != null
        AND PC_Patient_Program__c IN: caseIds AND (PC_Status__c = 'Confirmed' OR PC_Status__c = 'Requested')];

        if(interactionList != null && !interactionList.isEmpty()){
            //Create new Interaction Participant for new care team member added if corresponding role is selected in Interaction record
            List<PC_InteractionParticipant__c> interactionParticipantsToBeCreated = new List<PC_InteractionParticipant__c>();
            for(PC_Association__c association : newAssociations){
                for(PC_Interaction__c interaction : interactionList){
                    if(interaction.PC_Patient_Program__c == association.PC_Program__c && interaction.PC_Participants__c.containsIgnoreCase(association.PC_Role__c)){
                        PC_InteractionParticipant__c newInteractionParticipant =  new PC_InteractionParticipant__c();
                        newInteractionParticipant.PC_Interaction__c = interaction.Id;
                        newInteractionParticipant.PC_Association__c = association.Id;
                        interactionParticipantsToBeCreated.add(newInteractionParticipant);
                    }
                }
            }
            if(interactionParticipantsToBeCreated != null && !interactionParticipantsToBeCreated.isEmpty()){
                PC_Database.ins(interactionParticipantsToBeCreated, false);
            }
        }
    }
}