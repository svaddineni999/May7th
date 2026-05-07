/*********************************************************************************************************
Trigger Name    : PC_Trigger_Pharmacy_Referral
Description     : Trigger handler class on Pharmacy Referral object to avoid muktiple active referrals for a case.
Created By      : Deloitte
Created Date    : Sep 21, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                       Date                   Description
--------------------------------------------------------------------------------------------------------------
Ramtej Juloori              Sep 21, 2017            [PC-2174] Initial Version
Xiukai Ning                 Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                    Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                    We are removing all FLS and With Sharing keywords in the handlers.
Shishir Bansal              Aug 29, 2019            As a part of [PC-4924] bug fix add check if the pharmacy referral and case id is not null
Tejas Patel                 Nov 06, 2020            PC-6902 Removing the check for referral Id, since it is never available in beforeInsert and always available in beforeUpdate
Satheesh Kumar              Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_Trigger_Referral_ActiveCheck extends PC_TriggerHandler {
    override public void beforeInsert(){
        checkDuplicateActiveReferral((List<PC_Pharmacy_Referral__c>)newList, false);
    }

    override public void beforeUpdate(){
        checkDuplicateActiveReferral((List<PC_Pharmacy_Referral__c>)newList, true);
    }
    /*********************************************************************************
    Method Name    : checkDuplicateActiveReferral
    Author         : Ramtej Juloori
    Description    : This method avoid user to create an active referral more than once for a given case
    Return Type    : void
    Parameter      : List of incoming Pharmacy Referral records - Trigger.new
    *********************************************************************************/

    private void checkDuplicateActiveReferral(List<PC_Pharmacy_Referral__c> referrals, boolean isUpdate) {

        //Inactive statuses
        List<string> inactiveStatus = new List<string>{
                PC_Constants.REFERRAL_STATUS_DISCONTINUED, PC_Constants.REFERRAL_STATUS_CLOSED, PC_Constants.REFERRAL_STATUS_CANCELED
        };
        List<Id> caseIds = new List<Id>();
        List<Id> referralIds = new List<Id>();
        for (PC_Pharmacy_Referral__c ref : referrals) {
            if (String.isNotBlank(String.valueOf(ref.PC_Program__c))) {
                caseIds.add(ref.PC_Program__c);
                referralIds.add(ref.Id);
            }
        }

        if ((!caseIds.isEmpty())) {
            List<AggregateResult> referralList = [
                    SELECT COUNT(Id), PC_Program__c
                    FROM PC_Pharmacy_Referral__c
                    WHERE PC_Program__c IN :caseIds AND Id NOT IN :referralIds AND PC_Referral_Status__c NOT IN :inactiveStatus
                    GROUP BY PC_Program__c
            ];
            Map<string, Integer> referralActiveCount = new Map<string, Integer>();
            string pcProgram = PC_Constants.getQualifiedAPIName('PC_Program__c');
            for (AggregateResult res : referralList) {
                referralActiveCount.put(string.valueOf(res.get(pcProgram)), Integer.valueOf(res.get('expr0')));
            }

            for (PC_Pharmacy_Referral__c ref : referrals) {
                if (referralActiveCount.get(ref.PC_Program__c) > 0) {
                    if (isUpdate) {
                        if (ref.PC_Referral_Status__c != PC_Constants.REFERRAL_STATUS_DISCONTINUED &&
                                ref.PC_Referral_Status__c != PC_Constants.REFERRAL_STATUS_CLOSED &&
                                ref.PC_Referral_Status__c != PC_Constants.REFERRAL_STATUS_CANCELED) {
                            ref.addError(Label.PC_Pharmacy_Referral_DuplicateErrorMessage);
                        }
                    } else {
                        ref.addError(Label.PC_Pharmacy_Referral_DuplicateErrorMessage);
                    }
                }
            }
        }
    }
}