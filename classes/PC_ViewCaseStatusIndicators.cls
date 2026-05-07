/*********************************************************************************
  Class Name      : PC_ViewCaseStatusIndicators
  Description     : Helper class for viewing case Indicator Aura Component
  Created By      : Deloitte               
  Created Date    : 10-July-2016
  Modification Log:
  ---------------------------------------------------------------------------------- 
  Developer            	Date                   	Description
  -----------------------------------------------------------------------------------            
 Cameron Reid          	10-July-2016           	Initial version, PC-47
 Shabda Bhujad			Dec 06, 2016			Added FLS check to getStages, getNextStatus, hasPreviousStage method
 Ajinkya Deshmukh		May 09, 2017			Deleted getNextStatus, and Updated getStages to handle metadata model
 Ajinkya Deshmukh		Jun 23, 2017			FLS Check Added (Code Merge)
 Mayuresh Patil         Jul 06, 2017            PC-1854 - To identify last stage and show as completed when status is updated.
 Mayuresh Patil         Jul 26, 2017            Updated CRUD/FLS Checks
 Vijay Kashikar         Mar 28, 2018            PC-2929 - Added null check
Haritha Reddy           21-Jan-2021            [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
 Vijay Kashikar         Mar 08, 2021            [PC-7440] Provided ability to configure indicators on any record type.
 *********************************************************************************/
public with sharing class PC_ViewCaseStatusIndicators {
	
	private static String recordTypeName;
    private static Boolean isLastStage = false;

    /*********************************************************************************
    Method Name    : getStages
    Description    : retreive list of initial stages for a case
    Return Type    : List<stageWrapper>
    Parameter      : 1. CaseID the Case to get the indicators (stages) from
    *********************************************************************************/
    @AuraEnabled
    public static List<stageWrapper> getStages(String caseID) {
        List<stageWrapper> stageWrappers = new List<stageWrapper>();        
        try {
            
            List<PC_Program_Status__mdt> stageTypes = new List<PC_Program_Status__mdt>();
            
            //Map for Name > Status Meta Data
            Map<String, PC_Program_Status__mdt> mStageTypesByName = new Map<String, PC_Program_Status__mdt>();
            //Map for Order > Status Meta Data
            Map<String, PC_Program_Status__mdt> mStageTypesByOrder = new Map<String, PC_Program_Status__mdt>();
            
            /*
            * FLS Check for Case
            */
            List<String> fields = new List<String>{'Status', PC_Constants.getQualifiedAPIName('PC_Previous_Status__c')};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
			/*
            * FLS Check for PC_Engagement_Program__c
            */
            fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Program_Code__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'),PC_Database.Operation.Reading, fields);
            
            //Retrieve Case
            List<Case> cases = [SELECT Id, Status, PC_Previous_Status__c, PC_Engagement_Program__r.PC_Program_Code__c, RecordType.DeveloperName
                                FROM Case 
                                WHERE Id =: caseID];
            //Decimals
            decimal dCompletedTo = -9999;
            decimal dInProgressTo = - 9999;
            decimal dLastStage = - 9999;


            if (cases.size() > 0) {
                Case c = cases[0];
                recordTypeName = c.RecordType.DeveloperName;
                //Update Case
                stageTypes = getStatusTypes(c.PC_Engagement_Program__r.PC_Program_Code__c, c.RecordTypeId);
                
                if(stageTypes != null && stageTypes.size() > 0) {

                	dLastStage = stageTypes[stageTypes.size()-1].Order__c;
                }

                //Create maps
                for(PC_Program_Status__mdt stageType : stageTypes) {
                    mStageTypesByName.put(stageType.PC_Case_Status__c, stageType);
                    mStageTypesByOrder.put(String.ValueOf(stageType.Order__c), stageType);
				}  

                if (c.status == System.Label.PC_On_Hold || c.status == System.Label.PC_Withdrawn) {
                    c.Status = c.PC_Previous_Status__c;
                }

                PC_Program_Status__mdt st = mStageTypesByName.get(c.status);
                
                if(st != null) {                
                    dCompletedTo = st.Order__c - 1;
                    dInProgressTo = st.Order__c;
                    if (dLastStage == st.Order__c){
                        isLastStage = true;
                    }
                }
            } 
            
            stageWrappers = createStageWrappers(stageTypes, dCompletedTo, dInProgressTo, isLastStage);
        }
        catch (exception e) {
            PC_Utility.logAndThrowException(e);
        }
        
        return stageWrappers;
    }
    
    /*********************************************************************************
    Method Name    : createStageWrappers
    Description    : Create a list of stage Wrapper objects
    Return Type    : List<stageWrapper>
    *********************************************************************************/
    private static List<stageWrapper> createStageWrappers(List<PC_Program_Status__mdt> stageTypes, Decimal dCompletedTo, Decimal dInProgressTo, Boolean isLastStage) {
        List<stageWrapper> stageWrappers = new List<stageWrapper>();
        for(PC_Program_Status__mdt stage : stageTypes) {
            Boolean isComp = stage.Order__c <= dCompletedTo;
            stageWrapper sw = new stageWrapper(stage.PC_Indicator_Status__c, stage.Order__c, stage.Order__c <= dCompletedTo ? 'complete' : isLastStage ? 'complete' : stage.Order__c == dInProgressTo ? 'inprogress' : 'incomplete' );
            stageWrappers.add(sw);
        }
        return stageWrappers;
    }
    
    /*********************************************************************************
    Method Name    : getStatusTypes
    Description    : retrieve status types
    Return Type    : List<PC_Program_Status__mdt>
    *********************************************************************************/
    private static List<PC_Program_Status__mdt> getStatusTypes(String programCode, Id recordTypeId) {
        try {
	        List<String> fields = new List<String>{
                    PC_Constants.getQualifiedAPIName('PC_Indicator_Status__c'),
                    PC_Constants.getQualifiedAPIName('Order__c'),
                    PC_Constants.getQualifiedAPIName('PC_Active__c'),
                    PC_Constants.getQualifiedAPIName('PC_Case_Status__c'),
                    PC_Constants.getQualifiedAPIName('PC_RecordType__c'),
                    PC_Constants.getQualifiedAPIName('PC_OtherRecordType__c'),
                    PC_Constants.getQualifiedAPIName('PC_RecordType_Namespaceprefix__c'),
                    PC_Constants.getQualifiedAPIName('PC_Program_Code__c')};
	        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Program_Status__mdt'),PC_Database.Operation.Reading, fields);
            RecordType recordTypeObj=[SELECT Id, DeveloperName, NamespacePrefix FROM RecordType where Id=:recordTypeId];

            List<PC_Program_Status__mdt> programStatuses = [
                    SELECT Id, Order__c, PC_Case_Status__c, PC_Indicator_Status__c
                    FROM PC_Program_Status__mdt
                    WHERE PC_Program_Code__c = :programCode
                    AND PC_Active__c = true
                    AND PC_RecordType__c = :recordTypeObj.DeveloperName
                    AND PC_RecordType_Namespaceprefix__c = :recordTypeObj.NamespacePrefix
                    ORDER BY Order__c ASC
            ];
            /* Note: in the above code PC_RecordType_Namespaceprefix__c could have been omitted. However, the same hasn't been
            done to avoid backward compatibility issues. Previously, as per the PC guideline, the namespace had to be
            set to PC Namespace even if the record type was that of the PC.*/
            if(programStatuses != null && programStatuses.size() > 0) {
                return programStatuses;
            }
            else {
                List<PC_Program_Status__mdt> otherProgramStatuses = [
                        SELECT Id, Order__c, PC_Case_Status__c, PC_Indicator_Status__c
                        FROM PC_Program_Status__mdt
                        WHERE PC_Program_Code__c = :programCode
                        AND PC_Active__c = true
                        AND PC_RecordType__c = :PC_Constants.CASE_OTHER_RECORD_TYPE
                        AND PC_OtherRecordType__c = :recordTypeObj.DeveloperName
                        AND PC_RecordType_Namespaceprefix__c = :recordTypeObj.NamespacePrefix
                        ORDER BY Order__c ASC
                ];
                return otherProgramStatuses;
            }
       	} catch (exception e) {
            PC_Utility.logAndThrowException(e);
            return null;
        }
    }
    
    /*********************************************************************************
    Method Name    : getpreviousStage
    Description    : retrieve previous status if the current one is "on hold"
    Return Type    : String
    *********************************************************************************/
    @AuraEnabled
    public static Boolean hasPreviousStage(String caseID) {
        try {
        	List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Previous_Status__c')};
            PC_Database.assertAccess('Case',PC_Database.Operation.Reading, fields); 
        	List<Case> cases = [select ID, PC_Previous_Status__c from Case where  ID =: caseID limit 1];
	        if (cases.size() == 1 && !String.isBlank(cases[0].PC_Previous_Status__c)) {
	            return true;
	        }
	    }
        catch (exception e) {
            PC_Utility.logAndThrowException(e);
        }
	   	return false;
    }
    
    public inherited sharing class stageWrapper {
        @AuraEnabled public String stageName {get; set;}
        @AuraEnabled public Decimal stageOrder {get; set;}
        @AuraEnabled public String stageStatus {get; set;}
        public stageWrapper(String stageSetName, Decimal stageSetOrder, string isSetStatus) {
            this.stageName = stageSetName;
            this.stageOrder = stageSetOrder;
            this.stageStatus = isSetStatus;
        }
    }
}