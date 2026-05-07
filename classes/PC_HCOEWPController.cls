/**
 * Class Name      	: PC_HCOEWPController
 * Created By      	: 
 * Created Date		: 
 * Modification Log	:
 * ----------------------------------------------------------------------------------
 * Developer              Date                   	Description
 * -----------------------------------------------------------------------------------
 * 			        					        	Initial Version
 * Prachi Nandgaonkar     30-March-2017             Added the method getApplicantHCO to get HCO from Applicant Object instead of enrollment case wrapper
 * Vijay Kashikar         31-March-2017             Added the logic for multiple records with to be pulled from online form with separate SOQL                             
 * Shabda Bhujad		  31-March-2017				Optimized the queries to add multiple records and not add HCO at all if there is no information
 * Prachi Nandgaonkar     14-Apr-2017               [PC-1379] Updated getApplicantHCO() to query applicant object with activeApplicant 
 * 											        input parameter to handle multiple applicants on same enrollment case
 * Ajinkya Deshmukh		  20-Jun-2017				FLS Check Added (Code Merge)
 * Ajinkya Deshmukh       27-Jun-2017               with sharing keyword added
 * Shabda Bhujad 		  11-Jul-2017				[PC-1885] Updated method 'getHCOTypes' to retrieve 'Type' labels instead of hardcoded values
 * Tejas Patel            26-Jul-2017               [PC-1956] Translation Issue
 * Mayuresh Patil         07-Sep-2017               PC-2193 FLS Check updated to new PC303 code
 * Vijay Kashikar         11-Sep-2018               PC-3552 Provisioned Status field on the front end
 * Vijay Kashikar         14-Sep-2018               PC-3552 Handled translation of Account Status field
 */
public with sharing class PC_HCOEWPController {
    private static List<PC_PicklistFieldManager.PicklistEntryWrapper> accTypeLabels = PC_PicklistFieldManager.getPicklistEntryWrappers(Account.Type);
    private static List<PC_PicklistFieldManager.PicklistEntryWrapper> accSubTypeLabels = PC_PicklistFieldManager.getPicklistEntryWrappers(Account.PC_Sub_Type__c);
    private static List<PC_PicklistFieldManager.PicklistEntryWrapper> accStatusLabels = PC_PicklistFieldManager.getPicklistEntryWrappers(Account.PC_Status__c);
    private static String accTypeLabel;
    private static String accSubTypeLabel;
    private static String accStatusLabel;
	
    private static string HCOType_Clinic = 'Clinic';
    private static string HCOType_PrivatePractice = 'Private Practice';
    private static string HCOType_Hospital = 'Hospital';
    private static string HCOType_LongTermCare = 'Long Term Care Facility';
    private static string TYPE ='Type';
    
    @AuraEnabled
    public static HCORecord getFields() {
        
        HCORecord displayFields = new HCORecord();
        
        displayFields.type = Account.Type.getDescribe().getLabel();
        displayFields.recordTypeId = Account.RecordTypeId.getDescribe().getLabel();
        displayFields.name = Account.Name.getDescribe().getLabel();
        displayFields.recordTypeName = Account.RecordType.Name.getDescribe().getLabel();
        displayFields.subType = Account.PC_Sub_Type__c.getDescribe().getLabel();
        
        displayFields.primaryAddress1 = Account.PC_Primary_Address_1__c.getDescribe().getLabel();
        displayFields.primaryAddress2 = Account.PC_Primary_Address_2__c.getDescribe().getLabel();
        displayFields.primaryAddress3 = Account.PC_Primary_Address_3__c.getDescribe().getLabel();
        displayFields.primaryAddress = Account.PC_Primary_Address__c.getDescribe().getLabel();
        
        displayFields.primaryCity = Account.PC_Primary_City__c.getDescribe().getLabel();
        displayFields.primaryState = Account.PC_Primary_State__c.getDescribe().getLabel(); 
        displayFields.primaryZipCode = Account.PC_Primary_Zip_Code__c.getDescribe().getLabel();
        
        displayFields.email = Account.PC_Email__c.getDescribe().getLabel();
        displayFields.phone = Account.Phone.getDescribe().getLabel();
        displayFields.fax = Account.Fax.getDescribe().getLabel();
        
        displayFields.status = Account.PC_Status__c.getDescribe().getLabel();
        displayFields.lastModifiedDate = Account.LastModifiedDate.getDescribe().getLabel();
        
        return displayFields;
    }
    @AuraEnabled 
    public static Account getHCOTypes2() {
		Account acc = new Account();
		Id devRecordTypeId = Schema.getGlobalDescribe().get(PC_Constants.PC_ACCOUNT).getDescribe().getRecordTypeInfosByName().get(PC_Constants.HCO_RecordType).getRecordTypeId();
        acc.RecordTypeId = devRecordTypeId;
        acc.Type = acc.Type;
        return acc;
    }
    @AuraEnabled
    public static List<HCORecord> searchRecords(String searchString, String searchFilter) {
        try {
            List<HCORecord> records = new List<HCORecord>();
            String recordType = PC_Constants.HCO_RecordType;
            List<Account> accts = getAccounts(recordType, searchString, searchFilter);
            HCORecord record;
            
            for(Account a : accts) {
                for(PC_PicklistFieldManager.PicklistEntryWrapper acctl : accTypeLabels){
                    if(acctl.value == a.Type){
                        a.Type = acctl.label;
                    }
                }
                for(PC_PicklistFieldManager.PicklistEntryWrapper accstl : accSubTypeLabels){
                    if(accstl.value == a.PC_Sub_Type__c){
                        a.PC_Sub_Type__c = accstl.label;
                    }
                }
                for(PC_PicklistFieldManager.PicklistEntryWrapper accstl : accStatusLabels){
                    if(accstl.value == a.PC_Status__c){
                        a.PC_Status__c = accstl.label;
                    }
                }
                record = new HCORecord(a, PC_Constants.FALSE_STRING);
                records.add(record);
            }
            return records;
        }
        catch(Exception ex){
            PC_Utility.logAndThrowException(ex);     
            return null;
        }
    }
    
    public static List<Account> getAccounts(String recordType, String newSearchString, String searchFilter) {
        String soslSearchString = '*' + String.escapeSingleQuotes(newSearchString) + '*';
        /*
        * FLS Check for Account
        */
    	List<String> fields = new List<String>{'Name', 'Phone', 'Fax','Type',
    								PC_Constants.getQualifiedAPIName('PC_Primary_Address_1__c'),PC_Constants.getQualifiedAPIName('PC_Primary_Address_2__c'),
    								PC_Constants.getQualifiedAPIName('PC_Primary_Address_3__c'),PC_Constants.getQualifiedAPIName('PC_Primary_Address__c'),
    								PC_Constants.getQualifiedAPIName('PC_Primary_City__c'),PC_Constants.getQualifiedAPIName('PC_Primary_State__c'),
    								PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'),PC_Constants.getQualifiedAPIName('PC_Status__c'),
    								PC_Constants.getQualifiedAPIName('PC_Email__c'),PC_Constants.getQualifiedAPIName('PC_Communication_Language__c'),
    								PC_Constants.getQualifiedAPIName('PC_Preferred__c'),PC_Constants.getQualifiedAPIName('PC_Sub_Type__c')};
        PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, fields);
        
        if(recordType != null && recordType != '') {
            if(newSearchString != null && newSearchString != '') {
                if(searchFilter != null && searchFilter != '') {
                    List<List<SObject>> soslQueryResults = [
                            FIND :soslSearchString
                            IN ALL FIELDS
                                    RETURNING Account (Id, Name, Type, RecordTypeId, RecordType.Name,
                                    PC_Primary_Address_1__c,
                                    PC_Primary_Address_2__c, PC_Primary_Address_3__c, PC_Primary_Address__c,
                                    PC_Primary_City__c, PC_Primary_State__c, PC_Primary_Zip_Code__c,
                                    PC_Status__c, PC_Email__c, Phone, Fax, PC_Communication_Language__c,
                                    PC_Preferred__c, PC_Sub_Type__c, LastModifiedDate
                                    WHERE Account.RecordType.Name = :recordType
                                    AND Type = :searchFilter)
                    ];
                    return (List<Account>) soslQueryResults[0];
                } else {
                    List<List<SObject>> soslQueryResults = [
                            FIND :soslSearchString
                            IN ALL FIELDS
                                    RETURNING Account (Id, Name, Type, RecordTypeId, RecordType.Name,
                                    PC_Primary_Address_1__c,
                                    PC_Primary_Address_2__c, PC_Primary_Address_3__c, PC_Primary_Address__c,
                                    PC_Primary_City__c, PC_Primary_State__c, PC_Primary_Zip_Code__c,
                                    PC_Status__c,
                                    PC_Email__c, Phone, Fax,
                                    PC_Communication_Language__c, PC_Preferred__c,
                                    PC_Sub_Type__c,
                                    LastModifiedDate
                                    WHERE Account.RecordType.Name = :recordType)
                    ];
                    return (List<Account>) soslQueryResults[0];
                }
            }
        }
        return null;
    }
    
    @AuraEnabled
    public static List<HCORecord> searchRecordsByIds(List<String> accountIds) {
        try {
            List<HCORecord> records = new List<HCORecord>();
            
            /*
	        * FLS Check for Account
	        */
	    	List<String> fields = new List<String>{'Name', 'Phone', 'Fax','Type',
	    								PC_Constants.getQualifiedAPIName('PC_Primary_Address_1__c'),PC_Constants.getQualifiedAPIName('PC_Primary_Address_2__c'),
	    								PC_Constants.getQualifiedAPIName('PC_Primary_Address_3__c'),PC_Constants.getQualifiedAPIName('PC_Primary_Address__c'),
	    								PC_Constants.getQualifiedAPIName('PC_Primary_City__c'),PC_Constants.getQualifiedAPIName('PC_Primary_State__c'),
	    								PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'),PC_Constants.getQualifiedAPIName('PC_Status__c'),
	    								PC_Constants.getQualifiedAPIName('PC_Email__c'),PC_Constants.getQualifiedAPIName('PC_Communication_Language__c'),
	    								PC_Constants.getQualifiedAPIName('PC_Preferred__c'),PC_Constants.getQualifiedAPIName('PC_Sub_Type__c')};
	        PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, fields);
            
            //Todo change to SOSL.
            List<Account> accts = [SELECT 
                                   Id,  Name, toLabel(Type), RecordTypeId, RecordType.Name,
                                   PC_Primary_Address_1__c, 
                                   PC_Primary_Address_2__c, PC_Primary_Address_3__c, PC_Primary_Address__c, 
                                   PC_Primary_City__c, PC_Primary_State__c, PC_Primary_Zip_Code__c,
                                   PC_Status__c,
                                   PC_Email__c, Phone, Fax,                                    
                                   PC_Communication_Language__c, PC_Preferred__c,                                   
                                   toLabel(PC_Sub_Type__c),
                                   LastModifiedDate 
                                   FROM Account 
                                   WHERE ID IN :accountIds                                   
                                  ];
            HCORecord record;
            
            for(Account a : accts) {
                record = new HCORecord(a, PC_Constants.TRUE_STRING);
                records.add(record);
            }
            return records;
        }
        catch(Exception ex){
            PC_Utility.logAndThrowException(ex);     
            return null;
        }
    }
    @AuraEnabled
    public static Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>> getHCOTypes (String namedCredentialName){
        /*Changes for PC-1885*/
        Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>> picklistEntryMap =
                new Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>>();
        try {
            List<PC_PicklistFieldManager.PicklistEntryWrapper> applicableTypeWrapper = new List<PC_PicklistFieldManager.PicklistEntryWrapper>();
            if (String.isNotBlank(namedCredentialName)) {
                applicableTypeWrapper = getTypePicklistUsingAPI(namedCredentialName);
            } else {
                Set<String> types = new Set<String>();
                types.add(HCOType_Clinic);
                types.add(HCOType_PrivatePractice);
                types.add(HCOType_Hospital);
                types.add(HCOType_LongTermCare);

                for (Schema.PicklistEntry picklistEntry : Account.Type.getDescribe().getPicklistValues()) {
                    if (types.contains(picklistEntry.getValue())) {
                        applicableTypeWrapper.add(new PC_PicklistFieldManager.PicklistEntryWrapper(picklistEntry.getValue(), picklistEntry.getLabel()));
                    }
                }
            }

            picklistEntryMap.put(TYPE, applicableTypeWrapper);
        }
        catch(Exception ex) {
            PC_Utility.createExceptionLog(ex);
            throw new AuraHandledException(ex.getMessage());
        }
        return picklistEntryMap;
    }
      
    public static List<PC_PicklistFieldManager.PicklistEntryWrapper> getTypePicklistUsingAPI(String userInterfaceAPINamedCredential) {
        String hcoRecordTypeId = PC_System.recordTypeId('Account','HCO',PC_Constants.OrgNamespace);
        List<PC_PicklistFieldManager.PicklistEntryWrapper> applicableTypeWrapper = new List<PC_PicklistFieldManager.PicklistEntryWrapper>();

        Map<String, String> hcoTypePicklistValues = PC_Utility.getDependentPicklistsUsingAPI('Account', hcoRecordTypeId,
                NULL, 'Type', userInterfaceAPINamedCredential);

        if(hcoTypePicklistValues != null) {
            for (String key : hcoTypePicklistValues.keySet()) {
                applicableTypeWrapper.add(new PC_PicklistFieldManager.PicklistEntryWrapper(key, hcoTypePicklistValues.get(key)));
            }
        }
        system.debug(applicableTypeWrapper);
        return applicableTypeWrapper;

    }
    
    /*********************************************************************************
    Method Name    : getApplicantHCO
    Description    : Returns the applicant's HCO associated with the enrollment case for the active applicant ID provided.
    Input Params   : The Id of the enrollment case for the applicant to retrieve, Active applicant ID
    Return Type    : HCORecord      
    *********************************************************************************/
    @AuraEnabled
    public static List<HCORecord> getApplicantHCO(Id enrollmentCaseId, Id activeApplicantId) {
        List<HCORecord> records = new List<HCORecord>();
        
        try {            
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_HCO_Name__c'),PC_Constants.getQualifiedAPIName('PC_HCO_Type__c'),PC_Constants.getQualifiedAPIName('PC_HCO_Phone__c'),
                								PC_Constants.getQualifiedAPIName('PC_HCO_Fax__c'),PC_Constants.getQualifiedAPIName('PC_HCO_Street_Address1__c'), PC_Constants.getQualifiedAPIName('PC_HCO_City__c'),
                								PC_Constants.getQualifiedAPIName('PC_HCO_State__c'),
                                                PC_Constants.getQualifiedAPIName('PC_HCO1_Name__c'),PC_Constants.getQualifiedAPIName('PC_HCO1_Type__c'),PC_Constants.getQualifiedAPIName('PC_HCO1_Phone__c'),
                                                PC_Constants.getQualifiedAPIName('PC_HCO1_Fax__c'),PC_Constants.getQualifiedAPIName('PC_HCO1_Street_Address1__c'), PC_Constants.getQualifiedAPIName('PC_HCO1_City__c'),
                                                PC_Constants.getQualifiedAPIName('PC_HCO1_State__c'),
                                                PC_Constants.getQualifiedAPIName('PC_HCO2_Name__c'),PC_Constants.getQualifiedAPIName('PC_HCO2_Type__c'),PC_Constants.getQualifiedAPIName('PC_HCO2_Phone__c'),
                                                PC_Constants.getQualifiedAPIName('PC_HCO2_Fax__c'),PC_Constants.getQualifiedAPIName('PC_HCO2_Street_Address1__c'), PC_Constants.getQualifiedAPIName('PC_HCO2_City__c'),
                                                PC_Constants.getQualifiedAPIName('PC_HCO2_State__c')};
                
            //FLS check access before SOQL
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Applicant__c'),PC_Database.Operation.Reading, fields);    
            
            //get a list of HCOs from online applicants for the enrollment case
            List<PC_Applicant__c> lstapplicant = [SELECT Id, RecordType.Name, 
                								PC_HCO_Name__c, PC_HCO_Phone__c, PC_HCO_Fax__c, PC_HCO_Street_Address1__c, PC_HCO_City__c, PC_HCO_State__c, toLabel(PC_HCO_Type__c),
                                                PC_HCO1_Name__c, toLabel(PC_HCO1_Type__c), PC_HCO1_Phone__c, PC_HCO1_Fax__c, PC_HCO1_Street_Address1__c, PC_HCO1_City__c, PC_HCO1_State__c,
                                                PC_HCO2_Name__c, toLabel(PC_HCO2_Type__c), PC_HCO2_Phone__c, PC_HCO2_Fax__c, PC_HCO2_Street_Address1__c, PC_HCO2_City__c, PC_HCO2_State__c
               									FROM PC_Applicant__c 
               									WHERE PC_Applicant__c.RecordType.Name =:PC_Constants.APPLICANT_ONLINE_RECORD_TYPE_NAME 
                								and 
                								Id =: activeApplicantId LIMIT 1];
            HCORecord applicantHCO;
            if (lstapplicant != null && !lstapplicant.isEmpty()) {
                String fieldPrefix;
                for(integer i=0; i<=2; i++) {
                    applicantHCO = new HCORecord();
                    fieldPrefix = (i==0) ? 'PC_HCO': 'PC_HCO'+i;
                    applicantHCO.name = (String)lstapplicant[0].get(fieldPrefix + '_Name__c');                
                    applicantHCO.phone = (String)lstapplicant[0].get(fieldPrefix + '_Phone__c');
                    applicantHCO.fax = (String)lstapplicant[0].get(fieldPrefix + '_Fax__c');
                    applicantHCO.primaryAddress1 = (String)lstapplicant[0].get(fieldPrefix + '_Street_Address1__c');
                    applicantHCO.primaryCity= (String)lstapplicant[0].get(fieldPrefix + '_City__c');
                    applicantHCO.primaryState= (String)lstapplicant[0].get(fieldPrefix + '_State__c');
                    applicantHCO.type= (String)lstapplicant[0].get(fieldPrefix + '_Type__c');    
                    if (applicantHCO.name != null || applicantHCO.phone!= null ||applicantHCO.fax !=null 
                        || applicantHCO.primaryAddress1 != null || applicantHCO.primaryCity != null || applicantHCO.primaryState !=null
                        || applicantHCO.type !=null) {
                            records.add(applicantHCO);  
                        }
                }     
            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);                
        }
        return records;
    }
    
    
    public class HCORecord {
        @AuraEnabled public String Id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String subType { get; set; }
        @AuraEnabled public String recordTypeId { get; set; }
        @AuraEnabled public String recordTypeName { get; set; }        
        
        @AuraEnabled public String primaryAddress1 { get; set; }
        @AuraEnabled public String primaryAddress2 { get; set; }
        @AuraEnabled public String primaryAddress3 { get; set; }
        @AuraEnabled public String primaryAddress { get; set; }        
        @AuraEnabled public String primaryCity { get; set; }
        @AuraEnabled public String primaryState { get; set; }
        @AuraEnabled public String primaryZipCode { get; set; }
        
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String fax { get; set; } 
        
		@AuraEnabled public String isSelected { get; set; }
        @AuraEnabled public String status { get; set; }  
        @AuraEnabled public String lastModifiedDate { get; set; }  
        @AuraEnabled public Datetime lastModifiedDateInUserTZ { get; set; }
        
        @AuraEnabled public String cssClassName { get; set; } // used in front end.
        
        public HCORecord() {
            
        }
        
        public HCORecord(Account a, String isSelect) {
            Id = a.Id;
            type = a.Type;
            recordTypeId = a.RecordTypeId;
            name = a.Name;
            recordTypeName = a.RecordType.Name;
            subType = a.PC_Sub_Type__c;
            
            primaryAddress1 = a.PC_Primary_Address_1__c;
            primaryAddress2 = a.PC_Primary_Address_2__c;
            primaryAddress3 = a.PC_Primary_Address_3__c;
            primaryAddress = a.PC_Primary_Address__c;            
            primaryCity = a.PC_Primary_City__c;
            primaryState = a.PC_Primary_State__c; 
            primaryZipCode = a.PC_Primary_Zip_Code__c;
            
            email = a.PC_Email__c;
            phone = a.Phone;
            fax = a.Fax;           
            
            isSelected = isSelect;
            status=a.PC_Status__c;
            lastModifiedDateInUserTZ = a.LastModifiedDate;
            
            cssClassName = '';
        }       
 
    }
    
    public class HCOSearchFilter{
        @AuraEnabled public String Id { get; set; }
        public HCOSearchFilter() {
            
        }
    }
}