/**
 * Class Name      : PC_PhysicianEWPController
 * Created By      : Mike Klumpenaar
 * Created Date    : December 27, 2016
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                   	Description
 * -----------------------------------------------------------------------------------
 * Prachi Nandgaonkar     31-March-2017             [PC-1387] Added getApplicantPhysician() to modularize physician wizard page  
 * Prachi Nandgaonkar     14-Apr-2017               [PC-1379] Updated getApplicantPhysician() to query applicant object with activeApplicant 
 * 											        input parameter to handle multiple applicants on same enrollment case
 * Ajinkya Deshmukh       27-Jun-2017               with sharing keyword added
 * Tejas Patel            26-Jul-2017               [PC-1952] Translation Issues
 * Mayuresh Patil         07-Sep-2017               PC-2193 FLS Check updated to new PC303 code
 */

public with sharing class PC_PhysicianEWPController {
    private static List<PC_PicklistFieldManager.PicklistEntryWrapper> phyTypes = PC_PicklistFieldManager.getPicklistEntryWrappers(Account.Type);

    private static List<PC_PicklistFieldManager.PicklistEntryWrapper> phyStatuses = PC_PicklistFieldManager.getPicklistEntryWrappers(Account.PC_Status__c);

    private static List<PC_PicklistFieldManager.PicklistEntryWrapper> phySpTypes = PC_PicklistFieldManager.getPicklistEntryWrappers(Account.PC_Specialist_Type__c);

    @AuraEnabled
    public static PhysicianRecord getFields() {
        
        PhysicianRecord displayFields = new PhysicianRecord();
       	
        displayFields.type = Account.Type.getDescribe().getLabel();
        displayFields.recordTypeId = Account.RecordTypeId.getDescribe().getLabel();
        displayFields.name = Account.Name.getDescribe().getLabel();
        displayFields.recordTypeName = Account.RecordType.Name.getDescribe().getLabel();
        
        displayFields.salutation = Account.PC_Salutation__c.getDescribe().getLabel();
        displayFields.firstName = Account.PC_First_Name__c.getDescribe().getLabel();
        displayFields.lastName = Account.PC_Last_Name__c.getDescribe().getLabel();
        
        displayFields.primaryAddress1 = Account.PC_Primary_Address_1__c.getDescribe().getLabel();
        displayFields.primaryAddress2 = Account.PC_Primary_Address_2__c.getDescribe().getLabel();
        displayFields.primaryAddress3 = Account.PC_Primary_Address_3__c.getDescribe().getLabel();
        displayFields.primaryCity = Account.PC_Primary_City__c.getDescribe().getLabel();
        displayFields.primaryState = Account.PC_Primary_State__c.getDescribe().getLabel(); 
        displayFields.primaryZipCode = Account.PC_Primary_Zip_Code__c.getDescribe().getLabel();        
        
        displayFields.email = Account.PC_Email__c.getDescribe().getLabel();
        displayFields.phone = Account.Phone.getDescribe().getLabel();
        displayFields.fax = Account.Fax.getDescribe().getLabel();
        
        displayFields.npi = Account.PC_NPI__c.getDescribe().getLabel();
        
        displayFields.communicationLanguage = Account.PC_Communication_Language__c.getDescribe().getLabel();
        displayFields.preferredCommunicationChannel = Account.PC_Preferred__c.getDescribe().getLabel();
        
        displayFields.status = Account.PC_Status__c.getDescribe().getLabel();
        displayFields.specialistType = Account.PC_Specialist_Type__c.getDescribe().getLabel();
        
        displayFields.city = Account.PC_Primary_City__c.getDescribe().getLabel();
        displayFields.state = Account.PC_Primary_State__c.getDescribe().getLabel();
        
        return displayFields;
    }
    
    /*********************************************************************************
    Method Name    : getApplicantPhysician
    Description    : Returns the applicant's Physician associated with the enrollment case for the active applicant ID provided.
    Input Params   : The Id of the enrollment case for the applicant to retrieve, Active applicant on Enrollment case.
    Return Type    : PhysicianRecord      
    *********************************************************************************/
    @AuraEnabled
    public static List<PhysicianRecord> getApplicantPhysician(Id enrollmentCaseId, Id activeApplicantId) {
        List<PhysicianRecord> records = new List<PhysicianRecord>();
        
        try {            
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Physician_Name__c'),PC_Constants.getQualifiedAPIName('PC_Physician_Phone__c'),PC_Constants.getQualifiedAPIName('PC_Physician_Fax__c'),
                								PC_Constants.getQualifiedAPIName('PC_Physician_Street_Address1__c'),PC_Constants.getQualifiedAPIName('PC_Physician_City__c'), PC_Constants.getQualifiedAPIName('PC_Physician_State__c')
                								};
                
            //FLS check access before SOQL
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Applicant__c'),PC_Database.Operation.Reading, fields);    
            
            //get a list of applicants for active applicant
            List<PC_Applicant__c> lstapplicant = [SELECT PC_Physician_Name__c, PC_Physician_Phone__c, PC_Physician_Fax__c, 
                                                  PC_Physician_Street_Address1__c, PC_Physician_City__c, PC_Physician_State__c
               									  FROM PC_Applicant__c WHERE Id =: activeApplicantId LIMIT 1];
            
            if (lstapplicant != null && !lstapplicant.isEmpty() && !String.isEmpty(lstapplicant[0].PC_Physician_Name__c)) {
                records.add(new PhysicianRecord(lstapplicant[0]));
            }
           
      
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);                
        }
        System.debug('Physician details for online form applicant: '+ records);
        return records;
    }

    
    
    @AuraEnabled
    public static List<PhysicianRecord> searchRecords(String searchString) {
        try {
            List<PhysicianRecord> records = new List<PhysicianRecord>();
            String recordType = 'Physician';
            String newSearchString = '%' + String.escapeSingleQuotes(searchString) + '%';
            String newSOSLSearchString = '*' + String.escapeSingleQuotes(searchString) + '*';

            List<String> fields = new List<String>{
                'Id', PC_Constants.getQualifiedAPIName('PC_First_Name__c'),
                PC_Constants.getQualifiedAPIName('PC_Last_Name__c'), PC_Constants.getQualifiedAPIName('PC_Primary_Address_1__c'),
                PC_Constants.getQualifiedAPIName('PC_Primary_Address_2__c'), PC_Constants.getQualifiedAPIName('PC_Primary_Address_3__c'),
                PC_Constants.getQualifiedAPIName('PC_Primary_City__c'), PC_Constants.getQualifiedAPIName('PC_Primary_State__c'), PC_Constants.getQualifiedAPIName('PC_Status__c'),
                PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'), PC_Constants.getQualifiedAPIName('PC_Salutation__c'),
                PC_Constants.getQualifiedAPIName('PC_Email__c'),'Phone', 'Fax', 'Type', 'RecordTypeId',
                'Name', PC_Constants.getQualifiedAPIName('PC_NPI__c'), 'RecordType.Name', PC_Constants.getQualifiedAPIName('PC_Communication_Language__c'), PC_Constants.getQualifiedAPIName('PC_Preferred__c'),
                PC_Constants.getQualifiedAPIName('PC_Specialist_Type__c')};
                        
             PC_Database.assertAccess('Account', PC_Database.Operation.Reading, fields);        
            
            
            List<List<SObject>> searchResults = [FIND :newSOSLSearchString IN ALL FIELDS
                                                RETURNING Account(
                                                    Id, PC_First_Name__c, 
                                                    PC_Last_Name__c, PC_Primary_Address_1__c, 
                                                    PC_Primary_Address_2__c, PC_Primary_Address_3__c, 
                                                    PC_Primary_City__c, PC_Primary_State__c, PC_Status__c,
                                                    PC_Primary_Zip_Code__c, PC_Salutation__c, 
                                                    PC_Email__c, Phone, Fax, Type, RecordTypeId, 
                                                    Name, PC_NPI__c, RecordType.Name, PC_Communication_Language__c, PC_Preferred__c,
                                                    PC_Specialist_Type__c 
                                                    WHERE Account.RecordType.Name = :recordType
                                                    
                                                )];
            List<Account> accts = searchResults[0];
            PhysicianRecord record;
            
            for(Account a : accts) {
                for(PC_PicklistFieldManager.PicklistEntryWrapper pyt : phyTypes){
                    if(pyt.value == a.Type){
                        a.Type = pyt.label;
                    }
                }
                for(PC_PicklistFieldManager.PicklistEntryWrapper pys : phyStatuses){
                    if(pys.value == a.PC_Status__c){
                        a.PC_Status__c = pys.label;
                    }
                }
                for(PC_PicklistFieldManager.PicklistEntryWrapper pyst : phySpTypes){
                    if(pyst.value == a.PC_Specialist_Type__c){
                        a.PC_Specialist_Type__c = pyst.label;
                    }
                }

                record = new PhysicianRecord(a);  
                records.add(record);
            }
            return records;
        }
        catch(Exception ex){
            PC_Utility.logAndThrowException(ex);     
            return null;
        }
    }
    
    public class PhysicianRecord {
        @AuraEnabled public String Id { get; set; }
        @AuraEnabled public String firstName { get; set; }
        @AuraEnabled public String lastName { get; set; }
        @AuraEnabled public String primaryAddress1 { get; set; }
        @AuraEnabled public String primaryAddress2 { get; set; }
        @AuraEnabled public String primaryAddress3 { get; set; }
        @AuraEnabled public String primaryCity { get; set; }
        @AuraEnabled public String primaryState { get; set; }
        @AuraEnabled public String primaryZipCode { get; set; }
        @AuraEnabled public String salutation { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String fax { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String recordTypeId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String npi { get; set; }
        @AuraEnabled public String recordTypeName { get; set; }
        @AuraEnabled public String isSelected { get; set; }
        @AuraEnabled public String communicationLanguage { get; set; }
        @AuraEnabled public String preferredCommunicationChannel { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String specialistType { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String state { get; set; }
        
                
        public PhysicianRecord() {
            
        }
        
        public PhysicianRecord(Account a) {
            Id = a.Id;
            firstName = a.PC_First_Name__c;
            lastName = a.PC_Last_Name__c;
            
            primaryAddress1 = a.PC_Primary_Address_1__c;
            primaryAddress2 = a.PC_Primary_Address_2__c;
            primaryAddress3 = a.PC_Primary_Address_3__c;
            primaryCity = a.PC_Primary_City__c;
            primaryState = a.PC_Primary_State__c; 
            primaryZipCode = a.PC_Primary_Zip_Code__c;
            salutation = a.PC_Salutation__c;
            email = a.PC_Email__c;
            phone = a.Phone;
            fax = a.Fax;
            type = a.Type;
            recordTypeId = a.RecordTypeId;
            name = a.Name;
            npi = a.PC_NPI__c;
            recordTypeName = a.RecordType.Name;
            isSelected = 'false';
            
            communicationLanguage = a.PC_Communication_Language__c;
            preferredCommunicationChannel = a.PC_Preferred__c;
            status=a.PC_Status__c;
            specialistType = a.PC_Specialist_Type__c;
            city = a.PC_Primary_City__c;
            state = a.PC_Primary_State__c;
        }
        
        public PhysicianRecord(PC_Applicant__c a) {
			name = a.PC_Physician_Name__c;
            phone = a.PC_Physician_Phone__c;
            fax = a.PC_Physician_Fax__c;
            primaryAddress1 = a.PC_Physician_Street_Address1__c;
            city = a.PC_Physician_City__c;
            state = a.PC_Physician_State__c;
        }   
        
    }
}