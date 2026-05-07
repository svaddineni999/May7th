/*********************************************************************************
Modification Log:
---------------------------------------------------------------------------------- 
Developer              Date                   Description
-----------------------------------------------------------------------------------            
Shabda Bhujad 		  May 30,2017          	 Initial Version
Shabda Bhujad 		  June 13,2017			 [PC-1701]Added Type to replace the RecordType use for cases
Ajinkya Deshmukh      June 27, 2017          with sharing keyword added
Mayuresh Patil        Aug 22, 2017           Additional FLS Check Added (PC303 Managed merge)
Mayuresh Patil        Sep 07, 2017           PC-2193 FLS Check updated to new PC303 code
Vijay Kashikar        Mar 15, 2019           [PC-4609] Marked method getProgramRecords global & made Apex doc compliant
Hitha Avalakki        Oct 25, 2019           [PC-5624] Added methods getAdverseEvents2Records to get PC_AdverseEvent2__c records
Hitha Avalakki        Nov 12, 2019           [PC-5715] Added getAdverseEventObjectAPINameNotInUse() to fetch the sobject API name of the Adverse Event object which
                                             has not been configured in the Patient Connect Setting custom metadata
Shishir Bansal        Dec-06-2019            [PC-5792] Avoid hardcoding of string variable
Haritha Reddy         May 05,2020            [PC-6249] Added limit to the inner SOQL queries
*********************************************************************************/

/**
 * This is a utility class for Document Management Wizard feature.
 *
 * @date 2016-05-30
 */
global with sharing class PC_DocumentManagementHelper {
    /**
    * Returns list of program cases along with their document logs
    *
    * @param patientId    Salesforce ID of the Patient(Account)
    */
    global static List<Case> getProgramRecords(Id patientId) {
        try {
            List<String> fields = new List<String>{'CaseNumber', 'Status', 'CreatedDate', 'ClosedDate', 'Type'};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
            fields = new List<String>{'Name'};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
			fields = new List<String>{'Id'};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'),PC_Database.Operation.Reading, fields);
            //check access before SOQL - Added Type for [PC-1701]
        	return [SELECT Id, AccountId, Account.Name, CaseNumber, Status, RecordType.Name, Type, CreatedDate, ClosedDate, 
        			(SELECT Id FROM Document_Logs__r LIMIT 2000)
        			FROM Case 
        			WHERE AccountId =: patientId];
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
			return null;            
        }
    }

    /**
    * Returns list of program cases along with their document logs for a given enagement program
    *
    * @param patientId    Salesforce ID of the Patient(Account)
    * @param docEngagementProg Salesforce ID of the engagement program (PC_Engagement_Program__c)
    */
    global static List<Case> getProgramRecords(Id patientId, String docEngagementProg) {
        try {
            List<String> fields = new List<String>{'CaseNumber', 'Status', 'CreatedDate', 'ClosedDate', 'AccountId', 'Type', PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
            fields = new List<String>{'Name'};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
            fields = new List<String>{'Id'};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'),PC_Database.Operation.Reading, fields);
            //check access before SOQL - Added Type for [PC-1701]
        	return [SELECT Id, AccountId, Account.Name, CaseNumber, Status, RecordType.Name, Type, CreatedDate, ClosedDate,
            (select Id from Document_Logs__r LIMIT 2000) FROM Case WHERE AccountId =: patientId and PC_Engagement_Program__c =: docEngagementProg];
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
			return null;            
        }
    }

    /**
    * Returns Map of Account Id and List of program cases along with their document logs for a given engagement program
    *
    * @param patientId    List Salesforce ID of the Patient(Account)
    * @param docEngagementProg Salesforce ID of the engagement program (PC_Engagement_Program__c)
    */
    global static Map<ID,List<Case>> getProgramRecords(List<Id> patientIdList, String docEngagementProg) {
        try {
            Map<ID,List<Case>> patientCases = new Map<ID,List<Case>>();
            system.debug('@patientCases'+patientCases);
            List<Case> allCases = new List<Case>();
            List<String> fields = new List<String>{'CaseNumber', 'Status', 'CreatedDate', 'ClosedDate', 'AccountId', 'Type', PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c')};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
            fields = new List<String>{'Name'};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
            fields = new List<String>{'Id'};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'),PC_Database.Operation.Reading, fields);
            //check access before SOQL - Added Type for [PC-1701]
            allCases = [SELECT Id, AccountId, Account.Name, CaseNumber, Status, RecordType.Name, Type, CreatedDate, ClosedDate,
            (select Id from Document_Logs__r LIMIT 2000) FROM Case WHERE AccountId IN : patientIdList and PC_Engagement_Program__c =: docEngagementProg];

            for(Id pId : patientIdList){
                List<Case> pCases = new List<Case>();
                for(Case c : allCases){
                    if(c.AccountId == pId){
                        pCases.add(c);
                    }
                }
                patientCases.put(pId,pCases);
            }

            return patientCases;

        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return null;
        }
    }
    
    /*********************************************************************************
    Method Name    : getAdverseEventsRecords
    Description    : This method retrieves adverse events of the given engagement program for a patient 
    *********************************************************************************/
    public static List<PC_AdverseEvent__c> getAdverseEventsRecords(Id patientId) {
        try {
            List<String> fields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_Patient__c'),PC_Constants.getQualifiedAPIName('PC_Care_Program__c'),PC_Constants.getQualifiedAPIName('PC_Event_Onset_Date__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'),PC_Database.Operation.Reading, fields);  
			fields = new List<String>{'CaseNumber'};
            PC_Database.assertAccess('Case',PC_Database.Operation.Reading, fields);			
            //check access before SOQL    
            return [SELECT Id, Name, PC_Patient__c, PC_Care_Program__r.CaseNumber, PC_Care_Program__r.Id, PC_Event_Onset_Date__c FROM PC_AdverseEvent__c WHERE PC_Patient__c =: patientId];
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return null;            
        } //@@RemoveDateRecByManf - removed field PC_Date_Received_By_Manufacturer__c from select
    }
    
    /*********************************************************************************
    Method Name    : getAdverseEventsRecords
    Description    : This method retrieves adverse events of the given engagement program for a patient 
    *********************************************************************************/
    public static List<PC_AdverseEvent__c> getAdverseEventsRecords(Id patientId, String docEngagementProg) {
        try {
            List<String> fields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_Patient__c'),PC_Constants.getQualifiedAPIName('PC_Care_Program__c'),PC_Constants.getQualifiedAPIName('PC_Event_Onset_Date__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'),PC_Database.Operation.Reading, fields);    
            fields = new List<String>{'CaseNumber'};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
			
            List<Case> relatedCases =   getProgramRecords(patientId, docEngagementProg);
            List<PC_AdverseEvent__c> patientAdverseEvents= [SELECT Id, Name, PC_Patient__c, 
                                                            PC_Care_Program__r.CaseNumber, PC_Care_Program__r.Id, 
                                                            PC_Event_Onset_Date__c FROM PC_AdverseEvent__c 
                                                            WHERE PC_Patient__c =: patientId ];
            List<PC_AdverseEvent__c> progSpecificAdverseEvents = new List<PC_AdverseEvent__c>();
            if(!relatedCases.isEmpty()) {
                for (Case relCase : relatedCases) {
                    for(integer i = 0 ; i< patientAdverseEvents.size(); i++)
                    {
                        if(relCase.Id == patientAdverseEvents[i].PC_Care_Program__r.Id)
                            progSpecificAdverseEvents.add(patientAdverseEvents[i]);
                    }
                }            
            }
            return progSpecificAdverseEvents;
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return null;            
        } 
    }

    //Hitha's code

    /*********************************************************************************
    Method Name    : getAdverseEvents2Records
    Description    : This method retrieves PC_AdverseEvent2__c records of the given engagement program for a patient
    *********************************************************************************/
    public static List<PC_AdverseEvent2__c> getAdverseEvents2Records(Id patientId) {
        try {
            List<String> fields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_Patient__c'),PC_Constants.getQualifiedAPIName('PC_Care_Program__c'),PC_Constants.getQualifiedAPIName('PC_Event_Onset_Date__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c'),PC_Database.Operation.Reading, fields);
            fields = new List<String>{'CaseNumber'};
            PC_Database.assertAccess('Case',PC_Database.Operation.Reading, fields);
            //check access before SOQL
            return [SELECT Id, Name, PC_Patient__c, PC_Care_Program__r.CaseNumber, PC_Care_Program__r.Id, PC_Event_Onset_Date__c FROM PC_AdverseEvent2__c WHERE PC_Patient__c =: patientId];
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return null;
        } //@@RemoveDateRecByManf - removed field PC_Date_Received_By_Manufacturer__c from select
    }

    /*********************************************************************************
    Method Name    : getAdverseEvents2Records
    Description    : This method retrieves PC_AdverseEvent2__c records of the given engagement program for a patient
    *********************************************************************************/
    public static List<PC_AdverseEvent2__c> getAdverseEvents2Records(Id patientId, String docEngagementProg) {
        try {
            List<String> fields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_Patient__c'),PC_Constants.getQualifiedAPIName('PC_Care_Program__c'),PC_Constants.getQualifiedAPIName('PC_Event_Onset_Date__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c'),PC_Database.Operation.Reading, fields);
            fields = new List<String>{'CaseNumber'};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);

            List<Case> relatedCases =   getProgramRecords(patientId, docEngagementProg);
            List<PC_AdverseEvent2__c> patientAdverseEvents= [SELECT Id, Name, PC_Patient__c,
                                                             PC_Care_Program__r.CaseNumber, PC_Care_Program__r.Id,
                                                             PC_Event_Onset_Date__c FROM PC_AdverseEvent2__c
                                                             WHERE PC_Patient__c =: patientId ];
            List<PC_AdverseEvent2__c> progSpecificAdverseEvents = new List<PC_AdverseEvent2__c>();
            if(!relatedCases.isEmpty()) {
                for (Case relCase : relatedCases) {
                    for(integer i = 0 ; i< patientAdverseEvents.size(); i++)
                    {
                        if(relCase.Id == patientAdverseEvents[i].PC_Care_Program__r.Id)
                            progSpecificAdverseEvents.add(patientAdverseEvents[i]);
                    }
                }
            }
            return progSpecificAdverseEvents;
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return null;
        }
    }
    
    /*********************************************************************************
    Method Name    : getInteractionRecords
    Description    : This method retrieves interactions of the given engagement program for a patient 
    *********************************************************************************/
    public static List<PC_Interaction__c> getInteractionRecords(Id patientId) {
        try {
            List<String> fields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_Patient__c'),PC_Constants.getQualifiedAPIName('PC_Type__c'), PC_Constants.getQualifiedAPIName('PC_Patient_Program__c'), PC_Constants.getQualifiedAPIName('PC_Status__c'), PC_Constants.getQualifiedAPIName('PC_Start__c'), PC_Constants.getQualifiedAPIName('PC_End__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Interaction__c'),PC_Database.Operation.Reading, fields);    
			fields = new List<String>{'CaseNumber','AccountId'};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
            return [SELECT Id, Name, PC_Patient__c, PC_Patient_Program__r.CaseNumber, PC_Patient_Program__r.Id, PC_Type__c,  PC_Status__c, PC_Start__c, PC_End__c FROM PC_Interaction__c WHERE PC_Patient_Program__r.AccountId =: patientId];
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return null;            
        }
    }
    
    /*********************************************************************************
    Method Name    : getInteractionRecords
    Description    : This method retrieves interactions of the given engagement program for a patient 
    *********************************************************************************/
    public static List<PC_Interaction__c> getInteractionRecords(Id patientId, String docEngagementProg) {
        try {
            List<String> fields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_Patient__c'),PC_Constants.getQualifiedAPIName('PC_Type__c'), PC_Constants.getQualifiedAPIName('PC_Patient_Program__c'), PC_Constants.getQualifiedAPIName('PC_Status__c'), PC_Constants.getQualifiedAPIName('PC_Start__c'), PC_Constants.getQualifiedAPIName('PC_End__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Interaction__c'),PC_Database.Operation.Reading, fields);    
			fields = new List<String>{'CaseNumber','AccountId'};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
            //check access before SOQL  
            List<Case> relatedCases =   getProgramRecords(patientId, docEngagementProg);
            List<PC_Interaction__c> patientInteractions= [SELECT Id, Name, PC_Patient__c, PC_Patient_Program__r.CaseNumber,
                                                            PC_Patient_Program__r.Id, PC_Type__c,  PC_Status__c, PC_Start__c, PC_End__c 
                                                            FROM PC_Interaction__c 
                                                            WHERE PC_Patient_Program__r.AccountId =: patientId];
            List<PC_Interaction__c> progSpecificInteractions = new List<PC_Interaction__c>();
            if(!relatedCases.isEmpty()) {
                for (Case relCase : relatedCases) {
                    for(integer i = 0 ; i< patientInteractions.size(); i++)
                    {
                        if(relCase.Id == patientInteractions[i].PC_Patient_Program__r.Id)
                            progSpecificInteractions.add(patientInteractions[i]);
                    }
                }            
            }
            return progSpecificInteractions;
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return null;            
        }
    }

    /*********************************************************************************
    Method Name    : getAdverseEventObjectAPINameNotInUse
    Description    : This method the API name of the Adverse Event object which has 'NOT' been configured in Patient Connect Setting custom metadata
    *********************************************************************************/
    public static String getAdverseEventObjectAPINameNotInUse() {
        String adverseEventObjectAPINameNotInUse = PC_Constants.EMPTY_STRING;

        try {
            //Fetch the Adverse Event configured in the Patient Connect setting custom metadata
            String adverseEventObjectInUse = PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AdverseEventObjectInUse,PC_Constants.PC_AdverseEvent_Object);

            //Check which Adverse Event is configured to be used and return the Adverse Event object API name which should not be shown on Link Log section
            if(adverseEventObjectInUse.equals(PC_Constants.PC_AdverseEvent_Object)){
                return PC_Constants.PC_AdverseEvent2_Object.toLowerCase();
            }
            else if(adverseEventObjectInUse.equals(PC_Constants.PC_AdverseEvent2_Object)){
                return PC_Constants.PC_AdverseEvent_Object.toLowerCase();
            }
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return adverseEventObjectAPINameNotInUse;
    }

}