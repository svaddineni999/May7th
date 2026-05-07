/*********************************************************************************
Class Name      : PC_PhysicianEWPProcessor
Description     : Associates physian with enrollment case
Created By      : Vijay Kashikar
Created Date    : 4-Jan-2017
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Vijay Kashikar		        4-Jan-17              Initial Version
Vijay Kashikar		        12 Apr 17             Added condition to avoid calling PC_Database.ups() when the object is null/empty. [PC-1436]
Vijay Kashikar              26 Jun 20             [PC-6398] Stored the records to be updated in the global queue.
*********************************************************************************/
public with sharing class PC_PhysicianEWPProcessor implements PC_EnrollmentWizard.PageProcessor{
    public static void processEnrollment(Case enrollmentCase, Map<String, Object> pageState) {
        
        if (pageState != null ) {
            for (String key : pageState.keySet()) {
                if(key == 'selectedResult') {

                        ID programId = enrollmentCase.PC_Program__c;
                        if(programId != null) {
                            Map<String,Object> selectedPhysician = (Map<String,Object>) pageState.get(key);
                            
                            if(selectedPhysician != null && selectedPhysician.get('Id') != null) {
                                 Case caseProgram = new Case(Id = programId, PC_Physician__c = (Id) selectedPhysician.get('Id') );
                                //update caseProgram;//Changed to PC_Database Update Statement
                                //PC_Database.upd(caseProgram);
                                PC_EnrollmentWizard.addToRecordsToBeUpdated(caseProgram);

                            }
                            
                        }
                        else {
                            throw new PC_EnrollmentWizard.PageProcessorException('Physician Processor: Program Id is not found');
                        }                       
                    
                }
            }
        } else {
            throw new PC_EnrollmentWizard.PageProcessorException('Missing page state');
        }
        System.debug('Completed HOCEWPProcessor Processing');
    }    
}