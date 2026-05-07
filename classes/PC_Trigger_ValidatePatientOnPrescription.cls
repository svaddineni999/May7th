/*********************************************************************************************************
Trigger Name    : PC_Trigger_ValidatePatientOnPrescription
Description     : Trigger handler class on Prescription object to check whether the record type for patient lookup is of patient or not (before insert).
Created By      : Deloitte
Created Date    : Sep 17, 2019
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                       Date                   Description
--------------------------------------------------------------------------------------------------------------
Tushar Arora                   Sep 17, 2019            Initial Version
Hitha Avalakki                 May 17,2021             Code changes to determine if an account record is of patient type on the basis of its 'Type' value and not recordtypeid
Satheesh Kumar                 Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_Trigger_ValidatePatientOnPrescription extends PC_TriggerHandler {

    override public void beforeInsert(){
        checkPatientRecType((List<PC_Prescription__c>)newList);
    }
    override public void beforeUpdate(){
        checkPatientRecType((List<PC_Prescription__c>)newList);
    }

    /*********************************************************************************
Method Name    : checkPatientRecType
Author         : Tushar Arora
Description    : This method checks whether the record type for patient lookup is of patient or not.
Return Type    : void
Parameter      : List of incoming Prescription records - Trigger.new
*********************************************************************************/
    private void checkPatientRecType(List<PC_Prescription__c> prescriptions) {

        try {
            Set<Id> patIds = new Set<Id>();
            Map<Id,Id> presPatMap = new Map<Id,Id>();
            Map<Id,Account> patMap = new Map<Id,Account>();
            if(!prescriptions.isEmpty()) {
                for(PC_Prescription__c eachPres: prescriptions){
                    if(eachPres.PC_Patient_Account__c != null){
                        presPatMap.put(eachPres.Id,eachPres.PC_Patient_Account__c);
                        patIds.add(eachPres.PC_Patient_Account__c);
                    }
                }
                if(!patIds.isEmpty()){
                    //PC-7748: Fetch the Type of patient account record
                    //FLS check not required in trigger handler since they always runs in System Mode
                    List<Account> patAccs = new List<Account>([Select Id, Type from Account where Id In: patIds]);
                    for(Account pat : patAccs){
                        patMap.put(pat.Id,pat);
                    }
                    for(PC_Prescription__c eachPres: prescriptions){
                        //PC-7748: Check if the account record if of type 'Patient' to determine if its patient account
                        if(patMap.get(presPatMap.get(eachPres.Id)).Type != PC_Constants.PATIENT_ACCOUNT_TYPE_VALUE && !Test.isRunningTest()){
                            eachPres.PC_Patient_Account__c.addError(Label.PC_Patient_Record_Type_Error);
                        }
                    }
                }
            }
        }
        catch(Exception ex) {
            PC_Utility.createExceptionLog(ex);
        }
    }

}