/*********************************************************************************
Class Name      : PC_Trigger_Case_ProgramCoverage
Description        : This trigger creates a program coverage record for each health plan associated with the case
Created By        : mapatil
Created Date     : 8/9/2017
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------           
mapatil                   8/9/2017                [PC-1898] Initial Version
Mayuresh Patil            8/18/2017               [PC-2126] program coverage update to insert only active coverages
Shabda Bhujad             Nov 14, 2017            PC-2485 Removing the reference to trigger state
Mayuresh Patil            Aug 20, 2018            PC-3241 Adding access to medical health plan recordtype
Xiukai Ning               Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                  Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                  We are removing all FLS and With Sharing keywords in the handlers.
Hitha Avalakki            Jan 29, 2020           [PC-5945] Modified the code to fetch the record type id values using callout PC_SYSTEM.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE ,recordTypeDevNamesList)
                                                  to prevent SOQL limit hit issue
Hitha Avalakki            Mar 19, 2021            [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
Satheesh Kumar            Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
*********************************************************************************/

public inherited sharing class PC_Trigger_Case_ProgramCoverage extends PC_TriggerHandler {

    override public void afterInsert() {
        createProgramCoverage((List<Case>) newList);
    }

/*********************************************************************************
Method Name    : createProgramCoverage
Author         : mapatil
Description    : This method created the program coverage
Return Type    : void
Parameter      : List of incoming case records - Trigger.new
*********************************************************************************/
    private void createProgramCoverage(List<Case> newCases) {
        Set<Id> patientAccountIds = new Set<Id>();
        List<PC_Program_Coverage__c> programCoveragesToCreate = new List<PC_Program_Coverage__c>();
        Date todaysDate = Date.today();
        // get all program case document ids
        for(case eachCase : newCases) {
            if((String.valueOf(eachCase.RecordType.Name) == PC_Constants.CASE_PROGRAM_TYPE) || (String.valueOf(eachCase.Type) == PC_Constants.CASE_PROGRAM_TYPE))  {
                patientAccountIds.add(String.valueOf(eachCase.AccountId));
            }
        }

        List<PC_Health_Plan__c> lsthealthPlans = new List<PC_Health_Plan__c>();
        if(!patientAccountIds.isEmpty()) {
            lsthealthPlans = [
                    SELECT Id, PC_Plan_Type__c, RecordType.DeveloperName, PC_Effective_Date__c, PC_Expiration_Date__c, Patient__c, PC_Plan_Status__c, PC_Public_Or_Private__c
                    FROM PC_Health_Plan__c
                    WHERE Patient__c in :patientAccountIds
            ];
        }

        Id privateCoverageRecordTypeId;
        Id publicCoverageRecordTypeId;
        Id medicalCoverageRecordTypeId;

        /* PC-5945: Added code to fetch the record type details of program coverage object using Schema.RecordTypeInfo class to prevent SOQL query hit*/
        Map<String,Id> recordTypeDeveloperNameRecordTypeIdMap =  new Map<String,Id>();

        List<String> recordTypeDevNamesList = new List<String>();
        recordTypeDevNamesList.add(PC_Constants.PROGRAM_COVERAGE_PRIVATE_RECORD_TYPE);
        recordTypeDevNamesList.add(PC_Constants.PROGRAM_COVERAGE_PUBLIC_RECORD_TYPE);
        recordTypeDevNamesList.add(PC_Constants.PROGRAM_COVERAGE_MEDICAL_RECORD_TYPE);

        recordTypeDeveloperNameRecordTypeIdMap = PC_SYSTEM.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE ,recordTypeDevNamesList);

        privateCoverageRecordTypeId = recordTypeDeveloperNameRecordTypeIdMap.get(PC_Constants.PROGRAM_COVERAGE_PRIVATE_RECORD_TYPE);
        publicCoverageRecordTypeId = recordTypeDeveloperNameRecordTypeIdMap.get(PC_Constants.PROGRAM_COVERAGE_PUBLIC_RECORD_TYPE);
        medicalCoverageRecordTypeId = recordTypeDeveloperNameRecordTypeIdMap.get(PC_Constants.PROGRAM_COVERAGE_MEDICAL_RECORD_TYPE);

        /* PC-5945: Added code to fetch the record type details of program coverage object using Schema.RecordTypeInfo class to prevent SOQL query hit*/

        for (Case eachCase : newCases) {
            if((String.valueOf(eachCase.RecordType.Name) == PC_Constants.CASE_PROGRAM_TYPE) || (String.valueOf(eachCase.Type) == PC_Constants.CASE_PROGRAM_TYPE))  {
                for(PC_Health_Plan__c eachHealthPlan : lsthealthPlans) {
                    If(eachHealthPlan.Patient__c == eachCase.AccountId) {
                        if (eachHealthPlan.PC_Plan_Status__c == PC_Constants.ACTIVE
                            || (eachHealthPlan.PC_Effective_Date__c != null && eachHealthPlan.PC_Expiration_Date__c != null && eachHealthPlan.PC_Expiration_Date__c > todaysDate && eachHealthPlan.PC_Effective_Date__c <= todaysDate)
                            || (eachHealthPlan.PC_Effective_Date__c != null && eachHealthPlan.PC_Expiration_Date__c == null && eachHealthPlan.PC_Effective_Date__c <= todaysDate)){
                            PC_Program_Coverage__c pc = new PC_Program_Coverage__c(
                                    PC_Program__c = eachCase.Id,
                                    PC_Coverage_Status__c = PC_Constants.ACTIVE,
                                    PC_Health_Plan__c = eachHealthPlan.Id,
                                    PC_Expiration_Date__c = eachHealthPlan.PC_Expiration_Date__c
                            );
                            if (eachHealthPlan.RecordType.DeveloperName == PC_Constants.HEALTH_PLAN_PRIVATE_RECORD_TYPE) {
                                pc.RecordTypeId = privateCoverageRecordTypeId;
                                pc.PC_Coverage_Type__c = PC_Constants.PRIVATE_COVERAGE_TYPE;
                            } else if (eachHealthPlan.RecordType.DeveloperName == PC_Constants.HEALTH_PLAN_PUBLIC_RECORD_TYPE) {
                                pc.RecordTypeId = publicCoverageRecordTypeId;
                                pc.PC_Coverage_Type__c = PC_Constants.PUBLIC_COVERAGE_TYPE;
                            } else if (eachHealthPlan.RecordType.DeveloperName == PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE) {
                                pc.RecordTypeId = medicalCoverageRecordTypeId;
                                if (eachHealthPlan.PC_Public_Or_Private__c == PC_Constants.HEALTH_PLAN_TYPE_PUBLIC) {
                                    pc.PC_Coverage_Type__c = PC_Constants.PUBLIC_COVERAGE_TYPE;
                                } else if (eachHealthPlan.PC_Public_Or_Private__c == PC_Constants.HEALTH_PLAN_TYPE_PRIVATE) {
                                    pc.PC_Coverage_Type__c = PC_Constants.PRIVATE_COVERAGE_TYPE;
                                }
                            }
                            programCoveragesToCreate.add(pc);
                        }
                    }
                }
            }
        }
        if (programCoveragesToCreate != null && !programCoveragesToCreate.isEmpty()) {
            PC_Database.ins(programCoveragesToCreate, false);
        }
    }
}