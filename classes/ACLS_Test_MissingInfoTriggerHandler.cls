/*********************************************************************************
Class Name      : ACLS_Test_OverlapServiceDatePSPHandler
Description     : The test class for PC_Program_Service_Permission trigger
Created By      : Deloitte
Created Date    : Jan 10, 2023
*********************************************************************************
Version History :
Date			  Developer 			  User Story					     Changes
Jan 10, 2023	Vartika Goyal				US-120				Added checkOverlapServicesDatesTest
*****************************************************************************************************************/

@isTest(seeAllData=false)
public class ACLS_Test_MissingInfoTriggerHandler {

    @testsetup
	private static void setup(){
        User baseProfUser = ACLS_TestDataFactory.createUser('ACLS Base Profile', 'userpctest@test2.com', 'test2');
        PC_Database.ins(baseProfUser);
        system.runAs(baseProfUser) {
            ACLS_TestDataFactory.assignUserPermissionSet(baseProfUser.Id, 'ACLS_Base_RW_Permissions');

            String sObjectName = 'PC_Program_Service_Permission__c';
            String recordTypeName = null;
                
            //Creating Missing Information
            List<ACLS_Missing_Information__c> missingInformationRecord = ACLS_TestDataFactory.ACLS_Missing_InformationcTestDataMethod(1, sObjectName, recordTypeName);
             missingInformationRecord[0].ACLS_Status__c = ACLS_Constants.INACTIVE_STATUS;
            missingInformationRecord[0].ACLS_Category__c = ACLS_Constants.CONSENT_CATEGORY;
            missingInformationRecord[0].ACLS_Missing_Information_Fields__c = ACLS_Constants.PROVIDER_CONSENT;
            insert missingInformationRecord;

        }
	}

	@isTest 
	public static void ACLS_Test_MissingInfoRecordCreation() {  
        User baseProfUser = [select id from User where Alias = 'test2'];         
        system.runAs(baseProfUser) {
            try{
                String sObjectName = 'PC_Program_Service_Permission__c';
                Map<Id, String>  mapOfRecIdAndFields = new Map<Id, String>();
                Map<Id, Id>  mapOfRecIdAndProgCaseId = new Map<Id, Id>();
                String recordTypeName = null;
                Test.startTest();
                
                //Creating Missing Information
                List<ACLS_Missing_Information__c> missingInformationRecord = [Select id, Name, ACLS_Object_Name__c,ACLS_Status__c, ACLS_Object_Record_Type_Name__c from ACLS_Missing_Information__c where ACLS_Object_Name__c = 'PC_Program_Service_Permission__c'];
                                
               String lstMissingFields = 'PC_Patient_Response__c';
 

                mapOfRecIdAndFields.put(missingInformationRecord[0].Id, lstMissingFields);
                mapOfRecIdAndProgCaseId.put(missingInformationRecord[0].Id, null);

                system.assertEquals(missingInformationRecord[0].ACLS_Object_Record_Type_Name__c, null);
                system.assertEquals(missingInformationRecord[0].ACLS_Object_Name__c, sObjectName);

                ACLS_MissingInfoTriggerHandler.ACLS_MissingInfoRecordCreation(missingInformationRecord[0].ACLS_Object_Name__c,mapOfRecIdAndFields,mapOfRecIdAndProgCaseId,recordTypeName);
                
                Test.stopTest();
                
            }
            catch(Exception ex){
                System.debug('VG'+ex.getMessage());
            }
        }
    }
}