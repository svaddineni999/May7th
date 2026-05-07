/*********************************************************************************
Class Name: PC_RecordTypeMetadataUtility
Description: This Class Will help us to create Salesforce Metadata Such as RecordTypes
Created By: Tushar Arora
Created Date: June 11, 2019

Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------------
Deloitte               June 7, 2019              Initial Version
Haritha Reddy          21-Jan-2021                 [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/
public with sharing class PC_RecordTypeMetadataUtility {
    /**
    * Property to array of RecordTypes Details
    */
    public  List<PC_RecordTypeData> lstRecordTypeData;

    public PC_RecordTypeMetadataUtility() {
        lstRecordTypeData = new List<PC_RecordTypeData>();
        PC_RecordTypeData objRecordTypeData = new PC_RecordTypeData();
        objRecordTypeData.IsActive = PC_Constants.PC_ISACTIVE;
        objRecordTypeData.fullName = PC_Constants.PC_PERSONACCOUNT + '.' + PC_Constants.PC_PATIENT_PERSONACCOUNT_RECORDTYPE_API;
        objRecordTypeData.label = PC_Constants.PC_PATIENT_PERSONACCOUNT_RECORDTYPE_LABEL;
        objRecordTypeData.description = PC_Constants.PC_PERSONACCOUNT_RECORDTYPE_DESCRIPTION;
        lstRecordTypeData.add(objRecordTypeData);
    }


    public inherited sharing class PC_RecordTypeData {
        /**
        * Property to hold RecordType IsActive Status
        */
        public Boolean IsActive;
        /**
        * Property to hold RecordType FullName
        */
        public String fullName;
        /**
        * Property to hold RecordType Label
        */
        public String label;
        /**
        * Property to hold RecordType Description
        */
        public String description;
    }
}