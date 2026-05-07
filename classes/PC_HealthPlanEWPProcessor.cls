/*********************************************************************************
Class Name      : PC_HealthPlanEWPProcessor
Description     : Processor class for the health plan enrollment wizard page.
Created By      : Mayuresh Patil
Created Date    : 12-Jan-17
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------           
Mayuresh Patil            12-Jan-17              Initial Version
Mayuresh Patil            07-Apr-17              [PC-1368]Resolving the Blocker issue raised by the force reviewer scanner
Vijay Kashikar		      12 Apr 17              [PC-1436] Added condition to avoid calling PC_Database.ups() when the object is null/empty.
Tejas PAtel				  31 May 17				 [PC-1588] Disable fields for 'Self' relationship for Cardholder's relationship with Patient.
Ajinkya Deshmukh		  21 Jun 17				 FLS Check Added (Code Merge)
Mayuresh Patil            11 Jul 17              Updated code to work with translation
Mayuresh Patil            07 Sep 17              PC-2193 FLS Check updated to new PC303 code
Shishir Bansal            06-Dec-2019            [PC-5792] Avoid hardcoding of string variable
Hitha Avalakki            17-Dec-2019            [PC-5789] Added code changes in order remove the SOQL statement from within for loop
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
*********************************************************************************/
public with sharing class PC_HealthPlanEWPProcessor implements PC_EnrollmentWizard.PageProcessor {
    Private Static String FIELDSET_KEY = 'fsFields';
    public static void processEnrollment(Case enrollmentCase, Map<String, Object> pageState) {

        if (pageState == null) {
            throw new PC_EnrollmentWizard.PageProcessorException('Missing page state');
        }
        if (enrollmentCase.AccountId == null){
            throw new PC_EnrollmentWizard.PageProcessorException('Patient Account not created'); 
        }

        Account selfAccount;
        List<Object> lstHealthPlan = (List<Object>) pageState.get('lstHealthPlan');
        PC_Health_Plan__c hp;
        List<PC_Health_Plan__c> hps = new List<PC_Health_Plan__c>(); 
        //[PC-1368]Resolving the Blocker issue raised by the force reviewer scanner
        String pObjectName = PC_Constants.PC_HEALTH_PLAN;
        List<RecordType> lstHpRecordTypes = new List<RecordType>();
        if (!String.isBlank(pObjectName)){
            lstHpRecordTypes = [Select Id, Name From RecordType Where SobjectType = :pObjectName];
        }

        /* Task: PC-5776 -- Start
        *  Author: Hitha Avalakki
        *  Description: Get selfAccount details for the enrollment case.
        */

        //FLS check
        List<String> accountFields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c')
        };
        PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, accountFields);

        selfAccount = [Select Name, PC_Date_of_Birth__c from Account where Id = :enrollmentCase.AccountId];
        /* Task: PC-5776 -- End */
        
        for (Object o : lstHealthPlan){
            Map<String, Object> healthPlan = (Map<String, Object>) o;                    
            //String pObjectName = PC_Constants.PC_HEALTH_PLAN;  //[PC-1368]
            String pDeveloperName =  String.valueOf(healthPlan.get('recordName'));
            Id pRecordTypeId;
            if (!lstHpRecordTypes.isEmpty() && !String.isBlank(pDeveloperName)){
                for (RecordType lstHpRt : lstHpRecordTypes){
                    if (lstHpRt.Name == pDeveloperName){
                        pRecordTypeId = lstHpRt.Id;
                    }
                }
            }
            
            hp = new PC_Health_Plan__c(); 
            if (!String.isBlank(String.valueOf(healthPlan.get('healthPlanId')))){
                hp.id = String.valueOf(healthPlan.get('healthPlanId')); 
            }
            hp.Group_No__c = String.valueOf(healthPlan.get('groupNo')); 						
            hp.ID_Policy_No__c = String.valueOf(healthPlan.get('policyNo')); 						
            hp.PC_Cardholder_Employer__c = String.valueOf(healthPlan.get('cardholderEmployer')); 				
            
            String cardholderRelationshipToPatient = (String) healthPlan.get('cardholderRelationshipToPatient');
            if (String.isNotBlank(cardholderRelationshipToPatient) && cardholderRelationshipToPatient != PC_Constants.PICKLIST_NONE){
                if(cardholderRelationshipToPatient.capitalize() == 'SELF'){
                   hp.PC_Cardholder_Relationship_to_Patient__c = cardholderRelationshipToPatient;
                   hp.PC_Card_Holder_Name__c = selfAccount.Name;
                   if (selfAccount.PC_Date_of_Birth__c != NULL){
                   hp.PC_Cardholder_s_Date_of_Birth__c = selfAccount.PC_Date_of_Birth__c;
            }
                } else{
                hp.PC_Cardholder_Relationship_to_Patient__c = cardholderRelationshipToPatient;
                    
                hp.PC_Card_Holder_Name__c = String.valueOf(healthPlan.get('cardholderName'));
                    
                String cardholderDOB = (String) healthPlan.get('cardholdersBirthDate');
            	if (String.isNotBlank(cardholderDOB)){
                hp.PC_Cardholder_s_Date_of_Birth__c = Date.valueOf(cardholderDOB);
            }
                }
            }
            /*String cardholderDOB = (String) healthPlan.get('cardholdersBirthDate');
            if (String.isNotBlank(cardholderDOB)){
                hp.PC_Cardholder_s_Date_of_Birth__c = Date.valueOf(cardholderDOB);
            }*/
            String hpEffectiveDate = (String) healthPlan.get('healthPlanEffectiveDate');
            if (String.isNotBlank(hpEffectiveDate)){
                hp.PC_Effective_Date__c = Date.valueOf(hpEffectiveDate);
            }
            String hpExpirationDate = (String) healthPlan.get('healthPlanExpirationDate');
            if (String.isNotBlank(hpExpirationDate)){
                hp.PC_Expiration_Date__c = Date.valueOf(hpExpirationDate);
            }
            hp.PC_Payer__c = String.valueOf(healthPlan.get('payerRef')); 						
            hp.PC_Plan_Claim_Card_No__c = String.valueOf(healthPlan.get('healthPlanClaimCardNo')); 			
            
            String healthPlanStatus = (String) healthPlan.get('healthPlanStatus');
            if (String.isNotBlank(healthPlanStatus) && healthPlanStatus != PC_Constants.PICKLIST_NONE){
                hp.PC_Plan_Status__c = healthPlanStatus; 				
            }
            
            String healthPlanType = (String) healthPlan.get('healthPlanType');
            if (String.isNotBlank(healthPlanType) && healthPlanType != PC_Constants.PICKLIST_NONE){
                hp.PC_Plan_Type__c = healthPlanType; 					
            }
            hp.PC_Rx_Bin__c = String.valueOf(healthPlan.get('planRxBin')); 						
            hp.PC_Rx_Grp__c = String.valueOf(healthPlan.get('planRxGrp')); 						
            hp.PC_Rx_PCN__c = String.valueOf(healthPlan.get('planRxPCN')); 						
            hp.RecordTypeId = pRecordTypeId;
            if (String.isBlank(String.valueOf(healthPlan.get('healthPlanId')))){
                hp.Patient__c = enrollmentCase.AccountId;
            }
            
            if(healthPlan.containsKey(FIELDSET_KEY)) {
                Map<String, Object> fieldSetMap = (Map<String, Object>) healthPlan.get(FIELDSET_KEY);
                PC_FieldSetController.copyFieldSetValues(fieldSetMap, hp);
            }
            hps.add(hp);
        }
        if(!hps.isEmpty()) {
        	PC_Database.ups(hps);//FLS/CRUD Check enforced in the PC_database method
        }
        System.debug('Completed PC_HealthPlanEWP Processing');
    }    
}