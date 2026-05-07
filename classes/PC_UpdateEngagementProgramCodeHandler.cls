/*********************************************************************************************************
Trigger Name    : PC_UpdateEngagementProgramCodeHandler
Description     : trigger on PC_Document__c object.
Created By      : Vivek Kumar Mishra
Created Date    : May 24, 2018
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#      	Date                   	Description
--------------------------------------------------------------------------------------------------------------
Xiukai Ning                     Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                        Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                        We are removing all FLS and With Sharing keywords in the handlers.
Satheesh Kumar                  Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/

public inherited sharing class PC_UpdateEngagementProgramCodeHandler extends PC_TriggerHandler{
    override public void beforeInsertUpdate(){
        updateEngagementProgramCode((List<PC_Document__c>)newList, (Map<Id, PC_Document__c>)oldMap);
    }
    /*********************************************************************************
      Method Name    : updateEngagementProgramCode
      Author         : Vivek Kumar Mishra
      Description    : This method will update the engagement program code based on
                       the engagement program associated with the new/update document
                       record
      Return Type    : void
      Parameter      : List of incoming document records - Trigger.new
     *********************************************************************************/
    private void updateEngagementProgramCode(List<PC_Document__c> newDocuments, Map<Id, PC_Document__c> oldDocuments){
        Set<Id> engProgramIds = new Set<Id>();

        //Collect associated engagement program ids out of new records
        for(PC_Document__c document : newDocuments){
            //In case of update event Engagement program ids should only be added to the set
            // if there is a change in  associated Engagement program between old and new records.
            if (oldMap == null || (oldMap.containsKey(document.Id)
                    && !(((PC_Document__c)oldMap.get(document.Id)).PC_Engagement_Program__c
                    == document.PC_Engagement_Program__c)))
            engProgramIds.add(document.PC_Engagement_Program__c);
        }

        if(!engProgramIds.isEmpty()){
            //Get an id->Object__c map of PC_Engagement_Program__c
            Map<Id, PC_Engagement_Program__c> engPrograms = new Map<Id, PC_Engagement_Program__c>([SELECT Id, PC_Program_Code__c
            FROM PC_Engagement_Program__c WHERE Id IN: engProgramIds]);

            //Fetching out the list of existing values for Engagement Program Picklist
            List<String> myPicklist = new List<String>();
            Schema.DescribeFieldResult field = PC_Document__c.PC_EngagementProgramCode__c.getDescribe();

            for (Schema.PicklistEntry f : field.getPicklistValues()){
                myPicklist.add(f.getLabel());

            }

            //Attach engagement program id with new record
            for(PC_Document__c document : newDocuments){
                if(document.PC_Engagement_Program__c != null){
                    ID engProgramId = document.PC_Engagement_Program__c;
                    String pcProgramCode = (engPrograms.get(engProgramId)).PC_Program_Code__c;
                    if(myPicklist.contains(pcProgramCode)){
                        (document.PC_EngagementProgramCode__c) = pcProgramCode;
                    } else if(myPicklist.contains(PC_Constants.PC_NONE)){
                        //Setting up the Engagement Program Code as 'None' in no such
                        // Picklist Value Scenario
                        (document.PC_EngagementProgramCode__c) = PC_Constants.PC_NONE;
                    } else{
                        document.PC_EngagementProgramCode__c = null;
                    }

                } else{
                    //Setting up engagement program code as 'None' in case of
                    //no engagement program associated
                    if(myPicklist.contains(PC_Constants.PC_NONE)){
                        (document.PC_EngagementProgramCode__c) = PC_Constants.PC_NONE;
                    } else{
                        document.PC_EngagementProgramCode__c = null;
                    }

                }
            }
        }
    }
}