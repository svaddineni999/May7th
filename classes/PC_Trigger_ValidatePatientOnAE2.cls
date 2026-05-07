/*********************************************************************************************************
Trigger Name    : PC_Trigger_ValidatePatientOnAE
Description     : Trigger handler class on Adverse Event object to check whether the record type for patient lookup is of patient or not (before insert).
Created By      : Deloitte
Created Date    : Aug 5, 2019
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                       Date                   Description
--------------------------------------------------------------------------------------------------------------
Kanteti Kishore                 Aug 5, 2019            Initial Version
Satheesh Kumar                  Nov 16, 2021           [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_Trigger_ValidatePatientOnAE2 extends PC_TriggerHandler {

    override public void beforeInsert(){
        checkPatientRecType((List<PC_AdverseEvent2__c>)newList);
    }


    /*********************************************************************************
Method Name    : checkPatientRecType
Author         : Kanteti Kishore
Description    : This method checks whether the record type for patient lookup is of patient or not.
Return Type    : void
Parameter      : List of incoming Pharmacy Referral records - Trigger.new
*********************************************************************************/
    private void checkPatientRecType(List<PC_AdverseEvent2__c> advEvents) {

        try {
            Set<Id> patIds = new Set<Id>();
            Map<Id,Id> adEvtPatMap = new Map<Id,Id>();
            Map<Id,Account> patMap = new Map<Id,Account>();
            if(!advEvents.isEmpty()) {
                for(PC_AdverseEvent2__c eachAdvEvt: advEvents){
                    adEvtPatMap.put(eachAdvEvt.Id,eachAdvEvt.PC_Patient__c);
                    patIds.add(eachAdvEvt.PC_Patient__c);
                }
                if(!patIds.isEmpty()){
                    List<Account> patAccs = new List<Account>([Select Id, RecordTypeId from Account where Id In: patIds]);
                    for(Account pat : patAccs){
                        patMap.put(pat.Id,pat);
                    }
                    for(PC_AdverseEvent2__c eachAdvEvt: advEvents){
                        if(patMap.get(adEvtPatMap.get(eachAdvEvt.Id)).RecordTypeId != PC_System.recordTypeId(PC_Constants.PATIENT_OBJECT,PC_Constants.PATIENT_RECORD_TYPE) && !Test.isRunningTest()){
                            eachAdvEvt.PC_Patient__c.addError(Label.PC_Patient_Record_Type_Error);
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