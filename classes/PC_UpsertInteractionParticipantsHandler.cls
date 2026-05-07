/*********************************************************************************************************
Class Name      : PC_UpsertInteractionParticipantsHandler
Description     : trigger on Interaction object to create Interaction Participants for selected participant roles
Created By      : Haritha Reddy
Created Date    : Nov 11, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------
Haritha Reddy            Nov 11, 2021       		[PC-8278]Initial Version
Satheesh Kumar           Nov 16, 2021               [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_UpsertInteractionParticipantsHandler extends PC_TriggerHandler {
    override public void afterInsert(){
        createInteractionParticipants((List<PC_Interaction__c>)newList);
    }

    override public void afterUpdate(){
        updateInteractionParticipants((Map<Id, PC_Interaction__c>)oldMap, (List<PC_Interaction__c>)newList);
    }

    /*********************************************************************************
    Method Name    : createInteractionParticipant
    Return Type    : void
    Parameter      : List of incoming Interaction records - Trigger.new
    *********************************************************************************/
    private void createInteractionParticipants(List<PC_Interaction__c> interactions) {
        Set<Id> caseIds = new Set<Id>();
        for(PC_Interaction__c interaction: interactions){
            caseIds.add(interaction.PC_Patient_Program__c);
        }
        if(caseIds != null && !caseIds.isEmpty()){
            Map<String, List<PC_Association__c>> caseIdToCareTeamMap = new Map<String, List<PC_Association__c>>();

            List<PC_Association__c> associationList = [Select Id, PC_Role__c, PC_AssociationStatus__c, PC_Account__c, PC_Associated_User__c,PC_Program__c
                                                        FROM PC_Association__c where PC_Program__c IN:caseIds AND PC_AssociationStatus__c = 'Active'];
            for(PC_Interaction__c interaction: interactions){
                List<PC_Association__c> programAssociationList = new List<PC_Association__c>();
                for(PC_Association__c association: associationList){
                    if(association.PC_Program__c == interaction.PC_Patient_Program__c){
                        programAssociationList.add(association);
                    }
                }
                caseIdToCareTeamMap.put(interaction.PC_Patient_Program__c, programAssociationList);
            }
            List<PC_InteractionParticipant__c> interactionParticipantList = new List<PC_InteractionParticipant__c>();
            for(PC_Interaction__c interaction: interactions){
                if(interaction.PC_Participants__c != null){
                    List<PC_Association__c> careTeamList =  new List<PC_Association__c>();
                    careTeamList = caseIdToCareTeamMap.get(interaction.PC_Patient_Program__c);
                    if(careTeamList != null && !careTeamList.isEmpty()){
                        List<String> participantRoles =  new List<String>();
                        participantRoles.addAll(interaction.PC_Participants__c.split(';'));
                        for(String role: participantRoles){
                            for(PC_Association__c careTeamMember : careTeamList){
                                if(careTeamMember.PC_Role__c == role){
                                    PC_InteractionParticipant__c interactionParticipant =  new PC_InteractionParticipant__c();
                                    interactionParticipant.PC_Interaction__c = interaction.Id;
                                    interactionParticipant.PC_Association__c = careTeamMember.Id;
                                    interactionParticipantList.add(interactionParticipant);
                                }
                            }
                        }
                    }
                }
            }
            if(interactionParticipantList != null && !interactionParticipantList.isEmpty()){
                PC_Database.ins(interactionParticipantList, false);
            }
        }
    }

    /*********************************************************************************
    Method Name    : updateInteractionParticipants
    Return Type    : void
    Parameter      : oldMap, newList
    *********************************************************************************/
    private void updateInteractionParticipants(Map<Id, PC_Interaction__c> oldMap, List<PC_Interaction__c> newList){
        List<PC_Interaction__c> incompleteInteractionsToBeProcessed = new List<PC_Interaction__c>();
        for(PC_Interaction__c interaction: newList){
            if((interaction.PC_Status__c == 'Confirmed' || interaction.PC_Status__c == 'Requested')
                    && oldMap.get(interaction.id).PC_Participants__c != interaction.PC_Participants__c){
                incompleteInteractionsToBeProcessed.add(interaction);
            }
        }
        Set<Id> toBeProcessedInteractionIds = (new Map<Id,SObject>(incompleteInteractionsToBeProcessed)).keySet();
        Set<Id> caseIds = new Set<Id>();
        for(PC_Interaction__c interaction: incompleteInteractionsToBeProcessed){
            caseIds.add(interaction.PC_Patient_Program__c);
        }

        if(caseIds != null && !caseIds.isEmpty()){
            List<PC_InteractionParticipant__c> participantList = [Select Id,PC_Association__r.PC_Role__c,PC_Interaction__c FROM PC_InteractionParticipant__c
            WHERE PC_Interaction__c IN:toBeProcessedInteractionIds];

            List<PC_Association__c> associationList = [Select Id, PC_Role__c, PC_AssociationStatus__c, PC_Account__c, PC_Associated_User__c,PC_Program__c
            FROM PC_Association__c WHERE PC_Program__c IN:caseIds AND PC_AssociationStatus__c = 'Active'];

            Map<String, List<PC_Association__c>> caseIdToCareTeamMap = new Map<String, List<PC_Association__c>>();
            Map<String, List<PC_InteractionParticipant__c>> interactionParticipantMap = new Map<String, List<PC_InteractionParticipant__c>>();

            for(PC_Interaction__c interaction: incompleteInteractionsToBeProcessed){
                List<PC_Association__c> programAssociationList = new List<PC_Association__c>();
                for(PC_Association__c association: associationList){
                    if(association.PC_Program__c == interaction.PC_Patient_Program__c){
                        programAssociationList.add(association);
                    }
                }
                List<PC_InteractionParticipant__c> interactionParticipantList = new List<PC_InteractionParticipant__c>();
                for(PC_InteractionParticipant__c participant: participantList){
                    if(participant.PC_Interaction__c == interaction.Id){
                        interactionParticipantList.add(participant);
                    }
                }
                caseIdToCareTeamMap.put(interaction.PC_Patient_Program__c, programAssociationList);
                interactionParticipantMap.put(interaction.Id, interactionParticipantList);
            }

            List<PC_InteractionParticipant__c> interactionParticipantsToBeCreated = new List<PC_InteractionParticipant__c>();
            List<PC_InteractionParticipant__c> interactionParticipantsToBeRevoked = new List<PC_InteractionParticipant__c>();

            for(PC_Interaction__c interaction: incompleteInteractionsToBeProcessed){
                List<PC_Association__c> careTeamList =  new List<PC_Association__c>();
                careTeamList = caseIdToCareTeamMap.get(interaction.PC_Patient_Program__c);

                List<String> newParticipantRoles =  new List<String>();
                if(interaction.PC_Participants__c != null){
                    newParticipantRoles.addAll(interaction.PC_Participants__c.split(';'));
                }
                List<String> oldParticipantRoles =  new List<String>();
                if(oldMap.get(interaction.id).PC_Participants__c != null){
                    oldParticipantRoles.addAll(oldMap.get(interaction.id).PC_Participants__c.split(';'));
                }

                List<String> newRolesAdded =  getFilteredList(newParticipantRoles,oldParticipantRoles);
                List<String> rolesRemoved =  getFilteredList(oldParticipantRoles,newParticipantRoles);

                if(careTeamList != null && !careTeamList.isEmpty()){
                    for(String role: newRolesAdded){
                        for(PC_Association__c careTeamMember : careTeamList){
                            if(careTeamMember.PC_Role__c == role){
                                //Create new Interaction Participant for new role added
                                PC_InteractionParticipant__c newInteractionParticipant =  new PC_InteractionParticipant__c();
                                newInteractionParticipant.PC_Interaction__c = interaction.Id;
                                newInteractionParticipant.PC_Association__c = careTeamMember.Id;
                                interactionParticipantsToBeCreated.add(newInteractionParticipant);
                            }
                        }
                    }
                }
                List<PC_InteractionParticipant__c> existingInteractionParticipantList =  new List<PC_InteractionParticipant__c>();
                existingInteractionParticipantList = interactionParticipantMap.get(interaction.Id);
                if(existingInteractionParticipantList != null && !existingInteractionParticipantList.isEmpty()){
                    for(String removedRole: rolesRemoved){
                        for(PC_InteractionParticipant__c existingParticipant : existingInteractionParticipantList){
                            if(existingParticipant.PC_Association__r.PC_Role__c == removedRole){
                                //Mark existing Interaction Participant as revoked for the role removed
                                existingParticipant.PC_Revoked__c = true;
                                interactionParticipantsToBeRevoked.add(existingParticipant);
                            }
                        }
                    }
                }
            }
            if(interactionParticipantsToBeCreated != null && !interactionParticipantsToBeCreated.isEmpty()){
                PC_Database.ins(interactionParticipantsToBeCreated, false);
            }
            if(interactionParticipantsToBeRevoked != null && !interactionParticipantsToBeRevoked.isEmpty()){
                PC_Database.upd(interactionParticipantsToBeRevoked, false);
            }
        }
    }


    /*********************************************************************************
    Method Name    : getFilteredList
    Return Type    : List<String>
    Description    : This method fetches list of string values present in 1st list and not in 2nd list
    Parameter      : list1, list2
    *********************************************************************************/
    private List<String> getFilteredList(List<String> list1, List<String> list2) {
        List<String> filteredList =  new List<String>();
        for(String value1: list1) {
            Boolean valueFound = false;
            for(String value2: list2){
                if(value1 == value2){
                    valueFound = true;
                    break;
                }
            }
            if(!valueFound){
                filteredList.add(value1);
            }
        }
        return filteredList;
    }
}