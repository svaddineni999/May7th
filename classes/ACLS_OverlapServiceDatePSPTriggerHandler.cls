/*********************************************************************************************************
Trigger Name    : ACLS_OverlapServiceDatePSPTriggerHandler
Description     : trigger on PC_Program_Service_Permission__c object. 
Created By      : Deloitte
Created Date    : Jan 10, 2023
****************************************************************************************************************
Version History :
Date			  Developer 			  User Story					     Changes
Jan 10, 2023	Vartika Goyal				US-120				Added checkOverlapServicesDates method
Jan 27, 2023	Vartika Goyal				US-176				Added createMissingInfoOnPSP method
*****************************************************************************************************************/
public inherited sharing class ACLS_OverlapServiceDatePSPTriggerHandler extends PC_TriggerHandler {

    static Boolean isInsert = false;
    override public void beforeInsertUpdate(){
        checkOverlapServicesDates((List<PC_Program_Service_Permission__c>)newList, (Map<Id, PC_Program_Service_Permission__c>)oldMap);
    }

    override public void afterInsert(){
        isInsert = true;    
        createMissingInfoOnPSP((List<PC_Program_Service_Permission__c>)newList, (Map<Id, PC_Program_Service_Permission__c>)oldMap);
    }
    override public void afterUpdate(){
        isInsert = false;
        createMissingInfoOnPSP((List<PC_Program_Service_Permission__c>)newList, (Map<Id, PC_Program_Service_Permission__c>)oldMap);
    }


    /*********************************************************************************
	Method Name    : checkOverlapServicesDates 
	Author         : Deloitte
	Description    : This method Validate PSP for overlapping dates on Same services
	Return Type    : void
	Parameter      : List of incoming records - Trigger.new, Trigger.oldMap               
	*********************************************************************************/
     private void checkOverlapServicesDates(List<PC_Program_Service_Permission__c> newPSPList, Map<Id, PC_Program_Service_Permission__c> oldPSPMap){
        List<PC_Program_Service_Permission__c> servicePermissionsToUpdate = new List<PC_Program_Service_Permission__c>();
        List<PC_Program_Service_Permission__c> lstPSPWithSameService= new List<PC_Program_Service_Permission__c>();
        
        Set<id> serviceIds = new Set<id>();
        Set<id> pspIds = new Set<id>();
        Set<id> programCaseIds = new Set<id>(); 
        Map<String, List<PC_Program_Service_Permission__c>> mapOfHCPReqPSP= new Map<String, List<PC_Program_Service_Permission__c>>();
        Map<String, List<PC_Program_Service_Permission__c>> mapOfPatientReqPSP= new Map<String, List<PC_Program_Service_Permission__c>>();

		try {
            for (PC_Program_Service_Permission__c a : newPSPList){
                serviceIds.add(a.PC_Service__c); 
                pspIds.add(a.Id);
                programCaseIds.add(a.PC_ProgramCase__c);

            }

            if(!serviceIds.IsEmpty() && Schema.sObjectType.PC_Program_Service_Permission__c.isAccessible()){
                for(PC_Program_Service_Permission__c pspRecord : [Select Id, Name, PC_Service__c, PC_Start_Date__c, PC_End_Date__c, PC_Active__c, PC_ProgramCase__c, ACLS_HCP_Permission_Required__c, ACLS_PT_Legal_GUA_Permission_Required__c from PC_Program_Service_Permission__c 
                                                                    WHERE PC_Service__c IN :serviceIds AND PC_ProgramCase__c IN: programCaseIds AND Id != null AND Id NOT IN :pspIds AND PC_Active__c = true]){
                    
                    if(pspRecord.ACLS_HCP_Permission_Required__c && !mapOfHCPReqPSP.containsKey('HCP'+pspRecord.PC_Service__c+pspRecord.PC_ProgramCase__c)){
                        mapOfHCPReqPSP.put('HCP'+pspRecord.PC_Service__c+pspRecord.PC_ProgramCase__c, new List<PC_Program_Service_Permission__c>());
                    }
                    if(pspRecord.ACLS_HCP_Permission_Required__c){
                        mapOfHCPReqPSP.get('HCP'+pspRecord.PC_Service__c+pspRecord.PC_ProgramCase__c).add(pspRecord);
                    }
                
                    if(pspRecord.ACLS_PT_Legal_GUA_Permission_Required__c && !mapOfPatientReqPSP.containsKey('PT'+pspRecord.PC_Service__c+pspRecord.PC_ProgramCase__c)){
                            mapOfPatientReqPSP.put('PT'+pspRecord.PC_Service__c+pspRecord.PC_ProgramCase__c, new List<PC_Program_Service_Permission__c>());
                    }
                    if(pspRecord.ACLS_PT_Legal_GUA_Permission_Required__c){
                        mapOfPatientReqPSP.get('PT'+pspRecord.PC_Service__c+pspRecord.PC_ProgramCase__c).add(pspRecord);
                    }
                }
            }

            if(!serviceIds.IsEmpty() && (!mapOfHCPReqPSP.isEmpty() || !mapOfPatientReqPSP.isEmpty())){
                for(PC_Program_Service_Permission__c newRecord: newPSPList){
                    lstPSPWithSameService = (newRecord.ACLS_HCP_Permission_Required__c)? mapOfHCPReqPSP.get('HCP'+newRecord.PC_Service__c+newRecord.PC_ProgramCase__c) : (newRecord.ACLS_PT_Legal_GUA_Permission_Required__c) ? mapOfPatientReqPSP.get('PT'+newRecord.PC_Service__c+newRecord.PC_ProgramCase__c) : null;
                    for(PC_Program_Service_Permission__c oldRecord : lstPSPWithSameService) {
                        if((newRecord.PC_Start_Date__c >= oldRecord.PC_Start_Date__c && newRecord.PC_Start_Date__c <= oldRecord.PC_End_Date__c) || 
                            (newRecord.PC_End_Date__c >= oldRecord.PC_Start_Date__c && newRecord.PC_End_Date__c <= oldRecord.PC_End_Date__c) ||
                            (newRecord.PC_Start_Date__c <= oldRecord.PC_Start_Date__c && newRecord.PC_End_Date__c >= oldRecord.PC_End_Date__c)){
                            newRecord.addError(System.Label.ACLS_PSPDuplicateServiceErrorMsg);
                            break;
                        }
                    }
                }
            }
            
        }
        catch (Exception e) {
            PC_Utility.createExceptionLog(e);
        }
     }

    /*********************************************************************************
	Method Name    : createMissingInfoOnPSP 
	Author         : Deloitte
	Description    : This method is to create missing information on PSP update if Patient Response OR HCP Response field is blank
	Return Type    : void
	Parameter      : List of incoming records - Trigger.new            
	*********************************************************************************/
    private void createMissingInfoOnPSP(List<PC_Program_Service_Permission__c> newPSPList, Map<Id, PC_Program_Service_Permission__c> oldPSPMap){
        Set<id> programCaseIds = new Set<id>();
        List<String> lstAllMissingFields = new List<String>();
        List<String> listOfFields = new List<String>();
        String listOfMissingFields;
        Map<id, String> mapOfRecIdAndFields = new Map<id, String>();
        Map<id, id> mapOfRecIdAndProgCaseId = new Map<id, id>();
        Set<id> inactivePSPIds = new Set<id>();
        List<ACLS_Missing_Information__c> lstMissingInfo = new List<ACLS_Missing_Information__c>();

		try {
            List<ACLS_Missing_Information_Configuration__mdt> lstPSPInformation = new List<ACLS_Missing_Information_Configuration__mdt>();
            
            if(Schema.sObjectType.ACLS_Missing_Information_Configuration__mdt.isAccessible()){
                lstPSPInformation = [Select Id, ACLS_Field_API_Name__c, ACLS_Object_Name__c, DeveloperName from ACLS_Missing_Information_Configuration__mdt where ACLS_Object_Name__c =: ACLS_Constants.OBJ_PROGRAM_SERVICE_PERMISSION AND ACLS_IsActive__c = true];
                for(ACLS_Missing_Information_Configuration__mdt MImdt: lstPSPInformation){
                    listOfFields.add(MImdt.ACLS_Field_API_Name__c);
                }
            }
            
            if(!lstPSPInformation.isEmpty()){                              
               // listOfFields = lstPSPInformation[0].ACLS_Field_API_Name__c.split(',');

                for(PC_Program_Service_Permission__c pspRecord: newPSPList){
                    // TO check inactive PSP records
                    if(!pspRecord.PC_Active__c){
                        inactivePSPIds.add(pspRecord.id);
                    }
                    for(String checkField: listOfFields){
                        if(((pspRecord.ACLS_HCP_Permission_Required__c && checkField == ACLS_Constants.HCP_RESPONSE && pspRecord.get(checkField) == null) ||
                        (pspRecord.ACLS_PT_Legal_GUA_Permission_Required__c && checkField == ACLS_Constants.PATIENT_RESPONSE && pspRecord.get(checkField) == null)) 
                        && ((pspRecord.PC_Active__c && !isInsert) || (isInsert) || (pspRecord.ACLS_HCP_Expiration_Date__c == null && pspRecord.ACLS_Patient_Expiration_Date__c == null))){
                            listOfMissingFields = checkField;
                        }
                    }
                        mapOfRecIdAndFields.put(pspRecord.id, listOfMissingFields);
                        mapOfRecIdAndProgCaseId.put(pspRecord.id, pspRecord.PC_ProgramCase__c);
                }
                ACLS_MissingInfoTriggerHandler.ACLS_MissingInfoRecordCreation(ACLS_Constants.OBJ_PROGRAM_SERVICE_PERMISSION, mapOfRecIdAndFields, mapOfRecIdAndProgCaseId, null);
            } 
            if(Schema.sObjectType.ACLS_Missing_Information__c.isAccessible() && !inactivePSPIds.isEmpty()){
                for(ACLS_Missing_Information__c mirecord: [Select id, ACLS_Status__c from ACLS_Missing_Information__c where (ACLS_Status__c =: ACLS_Constants.ACTIVE_STATUS AND id IN: inactivePSPIds)]){
                    mirecord.ACLS_Status__c = ACLS_Constants.INACTIVE_STATUS;
                    lstMissingInfo.add(mirecord);
            	}
            }

            if(Schema.sObjectType.ACLS_Missing_Information__c.isCreateable() && Schema.sObjectType.ACLS_Missing_Information__c.isUpdateable() && !lstMissingInfo.isEmpty())                             //Insert New MI records and Inactivate existing MI records
            {
                upsert lstMissingInfo;
            }
        }        
        catch (Exception e) {
            PC_Utility.createExceptionLog(e);
        }
    }  
}