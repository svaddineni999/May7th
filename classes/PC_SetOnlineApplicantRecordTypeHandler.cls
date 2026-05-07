/*********************************************************************************************************
Trigger Name    : PC_SetOnlineApplicantRecordType
Description     : trigger on PC_Applicant__c object.
Created By      : Tetiana Danylyshyn
Created Date    : June 1, 2016
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#      	Date                   	Description
--------------------------------------------------------------------------------------------------------------
Tetiana Danylyshyn            	June 1, 2016          	Initial Version
Shabda Bhujad,        		  	Nov 4, 2016				Removed PC_Brand__c,  PC_Country__c field(Document Object)references annotated by @@RemoveBranCntryRef
Prachi Nandgaonkar
Shabda Bhujad					Dec 06, 2016			Added FLS check to attachGeneratedPDF method
Prachi Nandgoankar              Mar 3, 2017             Replaced references to PC_SYSTEM.recordTypeId by PC_SYSTEM.getRecordTypeIdByName [PC-1242]
Prachi Nandgaonkar              Mar 16 2017             Added updateRecordType() to add record type for online form applicants [PC-1321]
Ajinkya Deshmukh				Jun 23, 2017			FLS Check Added (Code Merge)
Mike Klumpenaar                 23-Jun-2017             Revert to using PC_SYSTEM.recordTypeId to resolve transaction issue [PC-1817]
Mayuresh Patil                  Jul 26, 2017            Updated CRUD/FLS checks
Shabda Bhujad                   Nov 14, 2017            PC-2485 Removing the reference to trigger state
Shabda Bhujad                   Dec 14, 2017            PC-1884 Logical breakdown of the trigger handlers
Xiukai Ning                     Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                        Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                        We are removing all FLS and With Sharing keywords in the handlers.
Satheesh Kumar                  Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/

public inherited sharing class PC_SetOnlineApplicantRecordTypeHandler extends PC_TriggerHandler{

    override public void beforeInsert(){
        updateRecordType((List<PC_Applicant__c>) newList);
    }

    /*********************************************************************************
    Method Name    : updateRecordType
    Author         : Prachi Nandgaonkar
    Description    : This method  updates record type for applicants created via Online Form submission [PC-1321]
    Return Type    : void
    Parameter      : List of incoming applicant records - Trigger.new
    *********************************************************************************/
    private void updateRecordType(List<PC_Applicant__c> applicants) {
        List<PC_Applicant__c> applicantsToUpdate = new List<PC_Applicant__c>();
        if(applicants.size() > 0){
            Id applicantRecTypeId = PC_SYSTEM.recordTypeId(PC_Constants.CANDIDATE_PATIENT_OBJECT, PC_Constants.APPLICANT_ONLINE_RECORD_TYPE);
            /*
            * No FLS Check Needed. This should run in the system context.
            */
            for (PC_Applicant__c a : applicants) {
                if (a.PC_Source__c) {
                    a.RecordTypeId = applicantRecTypeId;
                    applicantsToUpdate.add(a);
                }
            }
        }
    }

}