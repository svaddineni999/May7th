/****************************************************************************************************************
Trigger Name    : ACLS_MissingInfoTriggerHandler
Description     : Handler for ACLS_Missing_Information__c object. 
Created By      : Deloitte
Created Date    : Jan 19, 2023
*****************************************************************************************************************
Version History :
Date			  Developer 			  User Story					     Changes
Jan 27, 2023	Vartika Goyal				US-176				Added ACLS_MissingInfoRecordCreation method
*****************************************************************************************************************/
public with sharing class ACLS_MissingInfoTriggerHandler{

    /**********************************************************************************************************
	Method Name    : ACLS_MissingInfoRecordCreation 
	Author         : Deloitte
	Description    : This method Validate PSP for overlapping dates on Same services
	Return Type    : void
	Parameter      : sObjectName, map Of Rec Id And Fields,map Of RecId And ProgCaseId, recordTypeName            
	**********************************************************************************************************/
    public static void ACLS_MissingInfoRecordCreation(String sObjectName, Map<Id, String> mapOfRecIdAndFields, Map<Id, Id> mapOfRecIdAndProgCaseId, String recordTypeName){
        
		try {
            Set<Id> setProgramCaseId = new Set<Id>();
            List<Case> lstCase = new List<Case>();
            List<ACLS_Missing_Information__c> lstMissingInfo = new List<ACLS_Missing_Information__c>();
            Schema.SObjectType objSchema = Schema.getGlobalDescribe().get(sObjectName);
            Map<String, Schema.SObjectField> fieldMap = objSchema.getDescribe().fields.getMap();
            Map<Id, String> mapRecordIdFieldLabel = new Map<Id, String>();
            String fieldLabels;
            Map<id, String> mapPSPIdMIField = new Map<id, String>();

            if(Schema.sObjectType.ACLS_Missing_Information_Configuration__mdt.isAccessible()){
                for(ACLS_Missing_Information_Configuration__mdt MImetaRecord :[Select Id, ACLS_Field_API_Name__c, ACLS_Object_Name__c, DeveloperName, ACLS_MI_matching_field__c from ACLS_Missing_Information_Configuration__mdt where (ACLS_Object_Name__c =:sObjectName AND ACLS_IsActive__c = true)])
                {
                    for(Id recordId: mapOfRecIdAndFields.keySet())
                    {
                        if(mapOfRecIdAndFields.get(recordId) == MImetaRecord.ACLS_Field_API_Name__c){
                            mapPSPIdMIField.put(recordId, MImetaRecord.ACLS_MI_matching_field__c);
                        }
                    }
                }
            }

            for(Id recordId: mapOfRecIdAndFields.keySet()){
                fieldLabels = fieldMap?.get(mapOfRecIdAndFields?.get(recordId))?.getDescribe()?.getLabel();    
                mapRecordIdFieldLabel.put(recordId, fieldLabels);
            }           
            
            if(!mapOfRecIdAndFields.isEmpty()){
                for(Id recordkey: mapOfRecIdAndFields.keySet()){
                    ACLS_Missing_Information__c newMIRecord         = new ACLS_Missing_Information__c();
                    newMIRecord.ACLS_Object_Name__c                 = (String)objSchema.getDescribe().getLabel();
                    newMIRecord.ACLS_Object_Record_Type_Name__c     = recordTypeName;
                    newMIRecord.ACLS_Missing_Information_Field_Labels__c = mapRecordIdFieldLabel?.get(recordkey);
                    newMIRecord.ACLS_Missing_Information_Fields__c = mapPSPIdMIField?.get(recordkey);
                    newMIRecord.ACLS_Related_Case__c                = mapOfRecIdAndProgCaseId.get(recordkey);
                    newMIRecord.ACLS_Object_Record_Id__c            = recordkey;
                    newMIRecord.ACLS_Status__c                      = ACLS_Constants.ACTIVE_STATUS;
                    newMIRecord.ACLS_Category__c                    = sObjectName == ACLS_Constants.OBJ_PROGRAM_SERVICE_PERMISSION ? ACLS_Constants.CONSENT_CATEGORY : null;
                    
                    if(mapOfRecIdAndFields.get(recordkey) != null){
                        setProgramCaseId.add(mapOfRecIdAndProgCaseId.get(recordkey));
                        lstMissingInfo.add(newMIRecord);
                    }
                }
            }

            if(Schema.sObjectType.ACLS_Missing_Information__c.isAccessible() && !mapOfRecIdAndFields.isEmpty()){
                List<ACLS_Missing_Information__c> miRecords = [Select Id, ACLS_Status__c from ACLS_Missing_Information__c where ACLS_Status__c =: ACLS_Constants.ACTIVE_STATUS AND ACLS_Object_Record_Id__c IN: mapOfRecIdAndFields.keySet()];  
					for(ACLS_Missing_Information__c mIrecord: miRecords ){
                    mirecord.ACLS_Status__c = ACLS_Constants.INACTIVE_STATUS;
                    lstMissingInfo.add(mirecord);
            	}
            }

            // for(Id pId: setProgramCaseId){                                                             
            //     lstCase.add(new Case(id = pId, Status = ACLS_Constants.MISSINGINFO_STATUS));              //To Update Program case Status to Missing Information
            // }

            if(Schema.sObjectType.ACLS_Missing_Information__c.isCreateable() && Schema.sObjectType.ACLS_Missing_Information__c.isUpdateable() && !lstMissingInfo.isEmpty())                             //Insert New MI records and Inactivate existing MI records
            {
                upsert lstMissingInfo;
            }

            // if(Schema.sObjectType.Case.isUpdateable() && !lstCase.isEmpty())           
            // {
            //     update lstCase;
            // }
            
        }            
        catch (Exception e) {
            PC_Utility.createExceptionLog(e);
        }
    }  
}