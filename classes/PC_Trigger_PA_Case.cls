/*********************************************************************************************************
Class Name      : PC_Trigger_PA_Case 
Description     : Sets Active PA on Coverage and Prescription
Created By      : Shabda Bhujad
Created Date    : Sept 06, 2017
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   	Description
--------------------------------------------------------------------------------------------------------------            
Shabda Bhujad				Sep 24, 2017			Initial version
Shabda Bhujad				Oct 03, 2017 			PC-2335 Updated code to use record type developer name instead of name
Shabda Bhujad               Nov 14, 2017            PC-2485 Removing the reference to trigger state
Xiukai Ning                 Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                    Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                    We are removing all FLS and With Sharing keywords in the handlers.
Hitha Avalakki              Jan 29, 2020            [PC-5945] Modified the code to use PC_Constants.CASE_PA_RECORD_TYPE_NAME instead of fetching the record type id for PA case.
                                                    This was required in order to prevent the SOQL query required to fetch the PA case record type id.
Satheesh Kumar              Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_Trigger_PA_Case extends PC_TriggerHandler {

    override public void beforeUpdate() {
        resetActivePA((List< Case>) newList);
    }
    
    override public void afterInsertUpdate() {
        setActivePA((List< Case>) newList);
    }
    
    
    private void setActivePA(List<Case> newCaseList) {
        Set<Id> programCoverageIds = new Set<Id>();
        Set<Id> prescriptionIds = new Set<Id>();

        /* 
         * Check for active PA on Program Coverage and Prescription
		 */
        for(Case caseObj : newCaseList) {
            if((caseObj.Type == PC_Constants.CASE_PA_RECORD_TYPE_NAME)
               && caseObj.PC_PA_Status__c != PC_Constants.PA_CASE_STATUS_Denied && caseObj.PC_PA_Status__c != PC_Constants.PA_CASE_STATUS_Canceled 
               && caseObj.PC_PA_Status__c != PC_Constants.PA_CASE_STATUS_Expired && caseObj.PC_PA_Status__c != null) {
                   if (caseObj.PC_Program_Coverage__c!=null) {
                       programCoverageIds.add(caseObj.PC_Program_Coverage__c);
                   }
                   if (caseObj.PC_PA_Prescription__c!=null) {
                       prescriptionIds.add(caseObj.PC_PA_Prescription__c);
                   }
               } 
        }        
        
        if(!programCoverageIds.isEmpty()) {
            List<PC_Program_Coverage__c> programCoverageforPA = [SELECT Id, PC_hasActivePA__c
                                                                 FROM PC_Program_Coverage__c 
                                                                 where id IN : programCoverageIds];
            
            if (!programCoverageforPA.isEmpty()) {
                List<PC_Program_Coverage__c> toUpdatePrgCoverages = new List<PC_Program_Coverage__c>();
                for (PC_Program_Coverage__c eachPrgCov : programCoverageforPA) {
                    if(!eachPrgCov.PC_hasActivePA__c) {
                        eachPrgCov.PC_hasActivePA__c= TRUE;
                        toUpdatePrgCoverages.add(eachPrgCov);
                    }            
                }        
                PC_Database.upd(toUpdatePrgCoverages, FALSE);
            }
        }
        
        if(!prescriptionIds.isEmpty()) {
            List<PC_Prescription__c> prescriptionforPA = [SELECT Id, PC_hasActivePA__c
                                                          FROM PC_Prescription__c 
                                                          where id IN : prescriptionIds];
            
            if (!prescriptionforPA.isEmpty()) {
                List<PC_Prescription__c> toUpdatePrescription = new List<PC_Prescription__c>();
                for (PC_Prescription__c eachPrescription : prescriptionforPA) {
                    if(!eachPrescription.PC_hasActivePA__c) {
                        eachPrescription.PC_hasActivePA__c= TRUE;
                        toUpdatePrescription.add(eachPrescription);
                    }
                }        
                PC_Database.upd(toUpdatePrescription, FALSE);
            }  
        }
    }
    
    private void resetActivePA(List<Case> newCaseList) {
        Set<Id> programCoverageIds = new Set<Id>();
        Set<Id> prescriptionIds = new Set<Id>();
        String[] nonActiveStatus  = new String[]{PC_Constants.PA_CASE_STATUS_Denied, PC_Constants.PA_CASE_STATUS_Canceled,PC_Constants.PA_CASE_STATUS_Expired};

        /* 
         * Check for PA on Program Coverage and Prescription 
		 */
        for(Case caseObj : newCaseList) {
                if((caseObj.Type == PC_Constants.CASE_PA_RECORD_TYPE_NAME)) {
                       if (caseObj.PC_Program_Coverage__c!=null) {
                           programCoverageIds.add(caseObj.PC_Program_Coverage__c);
                       }
                       if (caseObj.PC_PA_Prescription__c!=null) {
                           prescriptionIds.add(caseObj.PC_PA_Prescription__c);
                       }
                   } 
            }        

        if(!programCoverageIds.isEmpty()) {
            List<PC_Program_Coverage__c> programCoverageforPA = [SELECT Id, PC_hasActivePA__c
                                                                 FROM PC_Program_Coverage__c 
                                                                 where id IN : programCoverageIds];
            
            List<Case> casesforPrgCoverage = [SELECT Id, PC_Program_Coverage__c
                                              FROM Case 
                                              WHERE PC_Program_Coverage__c IN : programCoverageIds 
                                              AND Type =:PC_Constants.CASE_PA_RECORD_TYPE_NAME
                                              AND PC_PA_Status__c NOT IN :nonActiveStatus
                                              AND Id NOT IN: newCaseList];
            
            if (!programCoverageforPA.isEmpty()) {
                List<PC_Program_Coverage__c> toUpdatePrgCoverages = new List<PC_Program_Coverage__c>();
                for (PC_Program_Coverage__c eachPrgCov : programCoverageforPA) {
                    if(eachPrgCov.PC_hasActivePA__c && casesforPrgCoverage.isEmpty()) {
                        eachPrgCov.PC_hasActivePA__c= FALSE;
                        toUpdatePrgCoverages.add(eachPrgCov);
                    }            
                }        
                PC_Database.upd(toUpdatePrgCoverages, FALSE);
            }    
        }       
        
        if(!prescriptionIds.isEmpty()) {
            List<PC_Prescription__c> prescriptionforPA = [SELECT Id, PC_hasActivePA__c
                                                          FROM PC_Prescription__c 
                                                          where id IN : prescriptionIds];
            
            List<Case> casesforPrescription = [SELECT Id, PC_PA_Prescription__c
                                               FROM Case 
                                               WHERE PC_PA_Prescription__c IN : prescriptionIds 
                                               AND Type =: PC_Constants.CASE_PA_RECORD_TYPE_NAME
                                               AND PC_PA_Status__c NOT IN :nonActiveStatus
                                               AND Id NOT IN: newCaseList];
            if (!prescriptionforPA.isEmpty()) {
                List<PC_Prescription__c> toUpdatePrescriptions = new List<PC_Prescription__c>();
                for (PC_Prescription__c eachPrescription : prescriptionforPA) {
                    if(eachPrescription.PC_hasActivePA__c && casesforPrescription.isEmpty()) {
                        eachPrescription.PC_hasActivePA__c= FALSE;
                        toUpdatePrescriptions.add(eachPrescription);
                    }            
                }        
                PC_Database.upd(toUpdatePrescriptions, FALSE);
            }   
        }
    }
}