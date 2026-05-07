/*********************************************************************************
Class Name      : PC_HCOEWPProcessor
Description     : Associates physian with enrollment case
Created By      : Vijay Kashikar
Created Date    : 4-Jan-2017
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Vijay Kashikar		        4-Jan-17              Initial Version
Vijay Kashikar		        12 Apr 17             [PC-1436] Added condition to avoid calling PC_Database.ups() when the object is null/empty.
Ajinkya Deshmukh			21 Jun 17			  FLS Check Added (Code Merge)
Tejas Patel                 06 Jul 17             Removing the SOQL sattemenst from the for loop
Mayuresh Patil              07 Sep 17             PC-2193 FLS Check updated to new PC303 code
Vijay Kashikar              26 Jun 20             [PC-6398] Stored the records created in the global queue.
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
*********************************************************************************/
public with sharing class PC_HCOEWPProcessor implements PC_EnrollmentWizard.PageProcessor{
    public static void processEnrollment(Case enrollmentCase, Map<String, Object> pageState) {
        if (pageState != null ) {
            ID programId = enrollmentCase.PC_Program__c;

            String role = PC_Constants.ACCOUNT_ROLE;

            List<PC_Association__c> existingHCOs;

            List<String> fields = new List<String>{
                    PC_Constants.getQualifiedAPIName('PC_Program__c'),
                    PC_Constants.getQualifiedAPIName('PC_Role__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Association__c'), PC_Database.Operation.Reading, fields);

            existingHCOs = [SELECT Id FROM PC_Association__c
            WHERE PC_Program__c = :programId
            AND PC_Role__c = :role];

            for (String key : pageState.keySet()) {
                if(key == 'selectedHCOIds') {
                    if(programId != null) {
                        
                        List<Object> selectedHCOs = (List<Object>) pageState.get(key);                         
                        
                        List<PC_Association__c> associations = new List<PC_Association__c>();
                        PC_Association__c hco;

                        Set<String> existingHCOsAsStrSet = new Set<String>();
                        for(PC_Association__c pac : existingHCOs){
                            existingHCOsAsStrSet.add(pac.Id);
                        }
                        for (Object hcoId : selectedHCOs) {
                            
                            if(!existingHCOsAsStrSet.contains((String) hcoId)) {
                                hco = new PC_Association__c();
                                hco.PC_Program__c = programId; 
                                hco.PC_Account__c = (String) hcoId;                             
                                hco.PC_Role__c = role;
                                associations.add(hco);                            }
                            else {
                                System.debug('\t' +'association not created for hcoId since it already exists: ' + (String) hcoId);
                            }
                            
                            
                        }
                        if(!associations.isEmpty()) {
                        	PC_Database.ups(associations);//FLS/CRUD Check enforced in the PC_database method
                            PC_EnrollmentWizard.addToRecordsCreated((List<SObject>) associations);
                        }
                    }
                    else {
                        throw new PC_EnrollmentWizard.PageProcessorException('HCO Processor: Program ID not found');
                    }
                    
                }
            }
        } else {
            throw new PC_EnrollmentWizard.PageProcessorException('Missing page state');
        }
    }
}