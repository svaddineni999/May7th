/**
* Class Name      : PC_HealthPlanEWPLightningController
* Created By      : Mayuresh Patil
* @Created Date   : January 10, 2016
* Modification Log:
* ----------------------------------------------------------------------------------
* Developer              Date                   	Description
* -----------------------------------------------------------------------------------
* Mayuresh Patil		 10-January-2017			Initial Version
  Prachi Nandgaonkar     7-April-2017               [PC-1404] Updated getApplicantHealthPlans() with shorter API name of Health Plan Cardholder relationhip
													field on Applicant object to respect Salesforce text length for field name 
  Prachi Nandgaonkar     9-April-2017               [PC- 1405] Updated getApplicantHealthPlans() to show multiple Health Plan records
  Vijay Kashikar	     12-April-2017              [PC- 1423] source is set to 'Online' in healthPlanPageWrapper if it is an online applicant.
  Prachi Nandgaonkar     14-Apr-2017                [PC-1379] Updated getApplicantHealthPlans() to query applicant object with activeApplicant 
  											        input parameter to handle multiple applicants on same enrollment case
  Prachi Nandgaonkar     19-Apr-2017                [PC-1430] Replaced  String recordType = 'Payer' in getPayer() with value from PC_Constants.
  Vijay Kashikar	     17-Mar-2017                [PC-1609] - Bug Fix. 
  Tejas Patel            06-Jul-2017                Removed SOQL from for loop
  Mayuresh Patil         11-Jul-2017                PC1885 Updated code to work with translation.
  Vijay Kashikar		 17-Jan-2018				PC-2672 Modified to query with access with fields that do not have duplicates;
  Vijay Kashikar		 31-Jul-2018				PC-3287 Added isActive check while fetching health plan record types

*/

/**
* Health Plan wizard page Controller for retrieving  
*/
Public with sharing class PC_HealthPlanEWPLightningController {
    Private Static String FIELDSET_KEY = 'fieldSet';
    Private Static String RECORDTYPEID_KEY ='RecordTypeId';
	/**
	* getFieldLabels
	*/
    @AuraEnabled
    public static Map<String, FieldWrapper> getFieldLabel() {
        Map<String, FieldWrapper> fDescribe = new Map<String, FieldWrapper>();
        List<String> sObjectName = new List<String>();
        sObjectName.add(PC_Constants.PC_HEALTH_PLAN);
        sObjectName.add(PC_Constants.PC_ACCOUNT);
        
        return fDescribe = getFieldDescribe(sObjectName);        
    }
    
    /**
	* Method to fetch sobject details
	*/ 
    public static Map<String, FieldWrapper> getFieldDescribe(List<String> sObjectName) {
        Map<String, FieldWrapper> fDescribe = new Map<String, FieldWrapper>();
        List<RecordType> sRecordTypeList = [SELECT Id, Name, SobjectType FROM RecordType WHERE sObjectType =: sObjectName AND IsActive = TRUE];

        for(String s : sObjectName){
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(s);
            Schema.DescribeSObjectResult describe = targetType.getDescribe();

            list<SelectOption> options = new list<SelectOption>();
            List<PC_PicklistFieldManager.PicklistEntryWrapper> lstRecordTypeOptions = new List<PC_PicklistFieldManager.PicklistEntryWrapper>();
            lstRecordTypeOptions.add(new PC_PicklistFieldManager.PicklistEntryWrapper(PC_Constants.PICKLIST_NONE,System.Label.PC_Picklist_None));
            for(RecordType sRecordType : sRecordTypeList)
            {
                if (s == sRecordType.SobjectType) {
                    // Select options are added with key,value pairing
                    String recordTypeName = PC_System.getRecordTypeNameById(sRecordType.SobjectType, sRecordType.Id);
                    if (recordTypeName != null) {
                        options.add(new SelectOption(sRecordType.Id, recordTypeName));
                        lstRecordTypeOptions.add(new PC_PicklistFieldManager.PicklistEntryWrapper(sRecordType.Name,recordTypeName));
                    }
                }
            }
            
            FieldWrapper fieldWrapper = new FieldWrapper();
            
            Map<String, SObjectField> mapFields = describe.fields.getMap();
            for (String fieldName : mapFields.keySet()){
                SObjectField fieldToken = mapFields.get(fieldName);
                Schema.DescribeFieldResult f = fieldToken.getDescribe();
                
                fieldWrapper = new FieldWrapper(f,options, lstRecordTypeOptions);
                
                fDescribe.put(describe.getLocalName()+'_'+f.getLocalName(),fieldWrapper);
            }  
        }
        return fDescribe;
    }
    
    @AuraEnabled
    public static List<healthPlanPageWrapper> getHealthPlan(String patientId, String fieldSetName) {
        
        List<healthPlanPageWrapper> lstHealthPlanWrapper = new List<healthPlanPageWrapper>();
        try{
            if (String.isNotBlank(patientId)){
                List<String> fsList = new List<String>();
                if(String.isNotBlank(fieldSetName)) {
                    fsList = PC_FieldSetController.getFieldsByName(
                        PC_Constants.PC_HEALTH_PLAN, 
                        fieldSetName
                    );            
                }
                
                //FLS Added; TEJAS PATEL; Feb 09 2017
                List<String> fields = new List<String>{'LastModifiedDate','RecordType.Name',PC_Constants.getQualifiedAPIName('Group_No__c'),PC_Constants.getQualifiedAPIName('ID_Policy_No__c'),
                    PC_Constants.getQualifiedAPIName('PC_Card_Holder_Name__c'),PC_Constants.getQualifiedAPIName('PC_Cardholder_Employer__c'),PC_Constants.getQualifiedAPIName('PC_Cardholder_Relationship_to_Patient__c'),
                    PC_Constants.getQualifiedAPIName('PC_Cardholder_s_Date_of_Birth__c'),PC_Constants.getQualifiedAPIName('PC_Effective_Date__c'),PC_Constants.getQualifiedAPIName('PC_Expiration_Date__c'),
                    PC_Constants.getQualifiedAPIName('PC_Payer__c'),PC_Constants.getQualifiedAPIName('PC_Payer_Name__c'),PC_Constants.getQualifiedAPIName('PC_Plan_Claim_Card_No__c'),PC_Constants.getQualifiedAPIName('PC_Plan_Status__c'),
                    PC_Constants.getQualifiedAPIName('PC_Plan_Type__c'),PC_Constants.getQualifiedAPIName('PC_Rx_Bin__c'),PC_Constants.getQualifiedAPIName('PC_Rx_Grp__c'),PC_Constants.getQualifiedAPIName('PC_Rx_PCN__c')
                    };
                //check access before SOQL
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Health_Plan__c'),PC_Database.Operation.Reading, fields);
                  
                if(fsList != null && fsList.size() > 0) { fields.addAll(fsList); }
                
                Set<String> fieldsAsSet = new Set<String>();
                List<String> fieldsWithoutDuplicates = new List<String>();
                fieldsAsSet.addAll(fields);
                fieldsWithoutDuplicates.addAll(fieldsAsSet);

                // Had to go with dynamic query due to fieldsets
                String query = '' + String.join(fieldsWithoutDuplicates, ', ');
                query = 'SELECT ' + query + ' ' + 'FROM ' + PC_Constants.PC_HEALTH_PLAN + 
                    ' WHERE ' + PC_Constants.getQualifiedAPIName('Patient__c') + '=' + '\'' + patientId + '\'';

                List<PC_Health_Plan__c> lstHealthPlan = PC_Database.queryWithAccess(query, fieldsWithoutDuplicates);
                
                if (lstHealthPlan != null && lstHealthPlan.size() > 0){
                    for(PC_Health_Plan__c a : lstHealthPlan) {                    
                        lstHealthPlanWrapper.add(new healthPlanPageWrapper(a, fsList));
                    }                
                } 
            }
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);           
        }
        return lstHealthPlanWrapper;
    }
    
    static String getApplicantFieldFromHealthPlanField(String hpFieldName, Integer index, String replaceTarget, String replaceText) {
        String applicantField;
        String formattedReplaceText;
        if(index == 0) {
            formattedReplaceText = replaceText.replace('{n}', '');
        }
        else {
            formattedReplaceText = replaceText.replace('{n}', string.valueOf(index));
        }
        applicantField = hpFieldName.replace(replaceTarget,formattedReplaceText);
        return applicantField;
    }

    @AuraEnabled
    public static List<healthPlanPageWrapper> getApplicantHealthPlans(String enrollmentCaseId, Id activeApplicantId, 
                                                                      String fieldSetName, String[] ignoreFields, String replaceTarget, String replaceText) {
        
        try{
            if (String.isNotBlank(enrollmentCaseId)){
                List<String> fsList = new List<String>();
                if(String.isNotBlank(fieldSetName)) {
                    fsList = PC_FieldSetController.getFieldsByName(
                        PC_Constants.PC_HEALTH_PLAN, 
                        fieldSetName
                    );            
                }
                
                //FLS Added; TEJAS PATEL; Feb 09 2017
                List<String> fields = new List<String>{'LastModifiedDate','RecordType.Name',
                    PC_Constants.getQualifiedAPIName('PC_HP_Group_No__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP_ID_Policy_No__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP_Cardholder_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP_Cardholder_Employer__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP_Cardholder_Rel_to_Patient__c'), 
                    PC_Constants.getQualifiedAPIName('PC_HP_Cardholder_s_Date_of_Birth__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP_Effective_Date__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP_Expiration_Date__c'),                    
                    PC_Constants.getQualifiedAPIName('PC_HP_Payer_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP_Plan_Status__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP_Plan_Type__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP_Rx_Bin__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP_Rx_Grp__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP_Rx_PCN__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP_Record_Type__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP1_Group_No__c'),PC_Constants.getQualifiedAPIName('PC_HP1_ID_Policy_No__c'), PC_Constants.getQualifiedAPIName('PC_HP1_Cardholder_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP1_Cardholder_Employer__c'),PC_Constants.getQualifiedAPIName('PC_HP1_Cardholder_s_Date_of_Birth__c'), PC_Constants.getQualifiedAPIName('PC_HP1_Effective_Date__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP1_Expiration_Date__c'),PC_Constants.getQualifiedAPIName('PC_HP1_Plan_Status__c'), PC_Constants.getQualifiedAPIName('PC_HP1_Plan_Type__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP1_Record_Type__c'),PC_Constants.getQualifiedAPIName('PC_HP1_Rx_Bin__c'), PC_Constants.getQualifiedAPIName('PC_HP1_Rx_Grp__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP1_Payer_Name__c'),PC_Constants.getQualifiedAPIName('PC_HP1_Cardholder_Rel_to_Patient__c'), PC_Constants.getQualifiedAPIName('PC_HP1_Rx_PCN__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP2_Group_No__c'),PC_Constants.getQualifiedAPIName('PC_HP2_ID_Policy_No__c'), PC_Constants.getQualifiedAPIName('PC_HP2_Cardholder_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP2_Cardholder_Employer__c'),PC_Constants.getQualifiedAPIName('PC_HP2_Cardholder_s_Date_of_Birth__c'), PC_Constants.getQualifiedAPIName('PC_HP2_Effective_Date__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP2_Expiration_Date__c'),PC_Constants.getQualifiedAPIName('PC_HP2_Plan_Status__c'), PC_Constants.getQualifiedAPIName('PC_HP2_Plan_Type__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP2_Record_Type__c'),PC_Constants.getQualifiedAPIName('PC_HP2_Rx_Bin__c'), PC_Constants.getQualifiedAPIName('PC_HP2_Rx_Grp__c'),
                    PC_Constants.getQualifiedAPIName('PC_HP2_Payer_Name__c'),PC_Constants.getQualifiedAPIName('PC_HP2_Cardholder_Rel_to_Patient__c'), PC_Constants.getQualifiedAPIName('PC_HP2_Rx_PCN__c')
                    };
                
               	List<String> fsListNew = new List<String>();
                if(fsList != null && fsList.size() > 0) { 
                    
                    String fName;
                    for(String fsListField : fsList) {
                        for(integer i=0; i<=2; i++) {
                            fName = '';
                            fName = getApplicantFieldFromHealthPlanField(fsListField, i, replaceTarget, replaceText);
                            //fName = (i==0) ? fsListField.replace(replaceTarget,replaceText) : fsListField.replace(replaceTarget,replaceText+i);
                            fsListNew.add(fName);
                        }                        
                    }
                    fields.addAll(fsListNew);
                    
                }
                
                Set<String> fieldsAsSet = new Set<String>();
                List<String> fieldsWithoutDuplicates = new List<String>();
                fieldsAsSet.addAll(fields);
                
                List<String> ignoreFieldsOfApplicant = new List<String>();
                String applicantIgnoreFieldName;
                for(String ignoreField : ignoreFields) {
                    
                    for(integer i=0; i<=2; i++) {
                        applicantIgnoreFieldName = '';
                        applicantIgnoreFieldName = getApplicantFieldFromHealthPlanField(ignoreField, i, replaceTarget, replaceText);
                        //applicantIgnoreFieldName = (i==0) ? ignoreField.replace(replaceTarget,replaceText) : ignoreField.replace(replaceTarget,replaceText+i);
                        ignoreFieldsOfApplicant.add(applicantIgnoreFieldName);
                    }                    
                }
                fieldsAsSet.removeAll(ignoreFieldsOfApplicant);
                
                fieldsWithoutDuplicates.addAll(fieldsAsSet);
                
                //check access before SOQL
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Applicant__c'),PC_Database.Operation.Reading, fields);    
                
                // Had to go with dynamic query due to fieldsets
                String query = '' + String.join(fieldsWithoutDuplicates, ', ');
                query = 'SELECT ' + query + ' ' + 'FROM ' + PC_Constants.getQualifiedAPIName('PC_Applicant__c') + 
                    ' WHERE ' + 
                    PC_Constants.getQualifiedAPIName('PC_Applicant__c') + '.RecordType.Name' + '=' + '\'' + PC_Constants.APPLICANT_ONLINE_RECORD_TYPE_NAME + '\'' +  
                        ' and Id' + '=' + '\'' + activeApplicantId + '\'' + ' Limit 1';
                List<PC_Applicant__c> lstapplicant = PC_Database.queryWithAccess(query, fieldsWithoutDuplicates);
                
                List<healthPlanPageWrapper> lstHealthPlanWrapper = new List<healthPlanPageWrapper>();
                
                if (lstapplicant != null && !lstapplicant.isEmpty()){
                    
                    PC_Health_Plan__c c;
                    String fieldPrefix;
                    for(integer i=0; i<=2; i++) {
                        fieldPrefix = (i==0) ? 'PC_HP_': 'PC_HP'+i+'_';
                        if(!String.isEmpty((String)lstapplicant[0].get(fieldPrefix + 'Payer_Name__c'))) {
                            lstHealthPlanWrapper.add(new healthPlanPageWrapper(lstapplicant[0], fsList, fieldPrefix, i, replaceTarget, replaceText));
                        }
                    }            
                }
               return lstHealthPlanWrapper;
            }
        }catch(Exception ex) {
            system.debug('Exception -->' + ex.getLineNumber());
            PC_Utility.logAndThrowException(ex);           
        }
        return null;
        
    }
   
	@AuraEnabled
    Public static List<payerWrapper> getPayer(String searchString) {
        List<payerWrapper> lstPayers = new List<payerWrapper>();
        String recordType = PC_Constants.PAYER_RECORD_TYPE; 
        String soslSearchString = '*' + String.escapeSingleQuotes(searchString) + '*';
        
        try {
            List<String> fields = new List<String>{'Id','Name','Phone','Fax','Type','RecordTypeId','RecordType.Name',PC_Constants.getQualifiedAPIName('PC_Status__c'),PC_Constants.getQualifiedAPIName('PC_Email__c'),
                PC_Constants.getQualifiedAPIName('PC_Sub_Type__c')
                };
                    
            //check access before SOQL
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);

            List<Account> accts;
            if(String.isEmpty(searchString)) {
                accts = [SELECT Id, Name, PC_Status__c, PC_Email__c,
                         Phone, Fax, Type, RecordTypeId,
                         PC_Sub_Type__c, RecordType.Name FROM Account 
                         WHERE Account.RecordType.Name = :recordType];
            }
            else {
                List<List<SObject>> soslQueryResults = [FIND :soslSearchString IN ALL FIELDS
                                                        RETURNING Account
                                                        (Id, Name, PC_Status__c, PC_Email__c,
                                                         Phone, Fax, Type, RecordTypeId,
                                                         PC_Sub_Type__c, RecordType.Name
                                                         WHERE Account.RecordType.Name = :recordType)];
                accts = (List<Account>) soslQueryResults[0];
            }
            

            payerWrapper payerRecord;
            
            for(Account a : accts) {
                payerRecord = new payerWrapper(a);  
                lstPayers.add(payerRecord);
            }
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);           
        }
        
        return lstPayers;
    }
    

    public class healthPlanPageWrapper {
        @AuraEnabled public Id healthPlanId {get;set;}
        @AuraEnabled public String groupNo {get; set;}
        @AuraEnabled public String policyNo {get; set;}
        @AuraEnabled public String cardholderName {get; set;}
        @AuraEnabled public String cardholderEmployer {get; set;}
        @AuraEnabled public String cardholderRelationshipToPatient {get; set;}
        @AuraEnabled public Date cardholdersBirthDate {get; set;}
        @AuraEnabled public Date healthPlanEffectiveDate {get; set;}
        @AuraEnabled public Date healthPlanExpirationDate {get; set;}
        @AuraEnabled public String payerName {get; set;}
        @AuraEnabled public String payerRef {get; set;}
        @AuraEnabled public String healthPlanClaimCardNo {get; set;}
        @AuraEnabled public String healthPlanStatus {get; set;}
        @AuraEnabled public String healthPlanType {get; set;}
        @AuraEnabled public String healthPlanTypeLabel {get; set;}
        @AuraEnabled public String planRxBin {get; set;}
        @AuraEnabled public String planRxGrp {get; set;}
        @AuraEnabled public String planRxPCN {get; set;}
        @AuraEnabled public String recordName {get; set;}
        @AuraEnabled public String recordNameLabel {get; set;}
        @AuraEnabled public DateTime lastModifiedDate {get; set;}
        @AuraEnabled public String source {get; set;}
        @AuraEnabled public Map<String,Object> fsFields{get; set;}
        @AuraEnabled public String test {get; set;}
        @AuraEnabled public Boolean isValid {get; set;}
        @AuraEnabled public String applicantSourceId {get; set;}
        @AuraEnabled public Boolean isApplicantSelected {get; set;}
        
        
        public healthPlanPageWrapper(PC_Health_Plan__c c, List<String> fsList) {
            healthPlanId = c.Id;
            groupNo = c.Group_No__c;
            policyNo = c.ID_Policy_No__c;
            cardholderName = c.PC_Card_Holder_Name__c;
            cardholderEmployer = c.PC_Cardholder_Employer__c;
            cardholderRelationshipToPatient = c.PC_Cardholder_Relationship_to_Patient__c;
            cardholdersBirthDate = c.PC_Cardholder_s_Date_of_Birth__c;
            healthPlanEffectiveDate = c.PC_Effective_Date__c;
            healthPlanExpirationDate = c.PC_Expiration_Date__c;
            payerName = c.PC_Payer_Name__c;
            payerRef = c.PC_Payer__c;
            healthPlanClaimCardNo = c.PC_Plan_Claim_Card_No__c;
            healthPlanStatus = c.PC_Plan_Status__c;
            healthPlanType = c.PC_Plan_Type__c;
            healthPlanTypeLabel = c.PC_Plan_Type__c;
            planRxBin = c.PC_Rx_Bin__c;
            planRxGrp = c.PC_Rx_Grp__c;
            planRxPCN = c.PC_Rx_PCN__c;
            recordName = c.RecordType.Name;
            recordNameLabel = c.RecordType.Name;
            this.lastModifiedDate = c.LastModifiedDate;
            source = System.Label.PC_EWP_Source_Existing;
            test = String.join(fsList, ',');
            fsFields = new Map<String, Object>();
            Object fsFieldVal;
            for(String fieldName : fsList) {
                fsFieldVal = PC_FieldSetController.castFieldValueBasedOnType(fieldName, c.get(fieldName), c);
                if(fsFieldVal == null) {
                	fsFieldVal = '';
                }
                else {
                    
                }
                fsFields.put(fieldName, fsFieldVal);
            }
            isValid=true;
        }
        
        
        public healthPlanPageWrapper(PC_Applicant__c a, List<String> fsList, String fieldPrefix, Integer index, String replaceTarget, String replaceText) {
     		// Empty check to be done wherever string conversion happens. Otherwise, the property will not be available on the front end.
            groupNo = String.isEmpty(String.valueOf(a.get(fieldPrefix + 'Group_No__c'))) ? '' : String.valueOf(a.get(fieldPrefix + 'Group_No__c'));
            policyNo = String.isEmpty(String.valueOf(a.get(fieldPrefix + 'ID_Policy_No__c'))) ? '' : String.valueOf(a.get(fieldPrefix + 'ID_Policy_No__c'));
            cardholderName = String.isEmpty(String.valueOf(a.get(fieldPrefix + 'Cardholder_Name__c'))) ? '' : String.valueOf(a.get(fieldPrefix + 'Cardholder_Name__c'));
            cardholderEmployer = String.isEmpty(String.valueOf(a.get(fieldPrefix + 'Cardholder_Employer__c'))) ? '' : String.valueOf(a.get(fieldPrefix + 'Cardholder_Employer__c'));
            cardholderRelationshipToPatient = String.isEmpty(String.valueOf(a.get(fieldPrefix + 'Cardholder_Rel_to_Patient__c'))) ? '' : String.valueOf(a.get(fieldPrefix + 'Cardholder_Rel_to_Patient__c'));
            cardholdersBirthDate = (Date)a.get(fieldPrefix + 'Cardholder_s_Date_of_Birth__c');
            healthPlanEffectiveDate = (Date)a.get(fieldPrefix + 'Effective_Date__c');
            healthPlanExpirationDate = (Date)a.get(fieldPrefix + 'Expiration_Date__c');                        
            payerName = String.isEmpty(String.valueOf(a.get(fieldPrefix + 'Payer_Name__c'))) ? '' : String.valueOf(a.get(fieldPrefix + 'Payer_Name__c'));
            healthPlanClaimCardNo = '';
            healthPlanStatus = String.isEmpty(String.valueOf(a.get(fieldPrefix + 'Plan_Status__c'))) ? '' : String.valueOf(a.get(fieldPrefix + 'Plan_Status__c'));
            healthPlanType = String.isEmpty(String.valueOf(a.get(fieldPrefix + 'Plan_Type__c'))) ? '' : String.valueOf(a.get(fieldPrefix + 'Plan_Type__c'));
            healthPlanTypeLabel = String.isEmpty(String.valueOf(a.get(fieldPrefix + 'Plan_Type__c'))) ? '' : String.valueOf(a.get(fieldPrefix + 'Plan_Type__c'));
            planRxBin = String.isEmpty(String.valueOf(a.get(fieldPrefix + 'Rx_Bin__c'))) ? '' : String.valueOf(a.get(fieldPrefix + 'Rx_Bin__c'));
            planRxGrp = String.isEmpty(String.valueOf(a.get(fieldPrefix + 'Rx_Grp__c'))) ? '' : String.valueOf(a.get(fieldPrefix + 'Rx_Grp__c'));
            planRxPCN = String.isEmpty(String.valueOf(a.get(fieldPrefix + 'Rx_PCN__c'))) ? '' : String.valueOf(a.get(fieldPrefix + 'Rx_PCN__c'));
            recordName = String.isEmpty(String.valueOf(a.get(fieldPrefix + 'Record_Type__c'))) ? '' : String.valueOf(a.get(fieldPrefix + 'Record_Type__c'));
            recordNameLabel = String.isEmpty(String.valueOf(a.get(fieldPrefix + 'Record_Type__c'))) ? '' : String.valueOf(a.get(fieldPrefix + 'Record_Type__c'));
            source = System.Label.PC_EWP_Source_Online;
            fsFields = new Map<String, Object>();
            
            String position;
            position = index==0 ? PC_Constants.EMPTY_STRING : string.valueOf(index);
            Object fsFieldVal;
            String applicantFieldName;
            for(String fieldName : fsList) {
                try {
                	applicantFieldName = getApplicantFieldFromHealthPlanField(fieldName, index, replaceTarget, replaceText);
                    //applicantFieldName = fieldName.replace(replaceTarget,replaceText + position);
                    fsFieldVal = PC_FieldSetController.castFieldValueBasedOnType(applicantFieldName, a.get(applicantFieldName), a);
                }
                catch(Exception e) {
                    fsFieldVal = PC_Constants.EMPTY_STRING;
                }
                if(fsFieldVal == null) {
                    fsFieldVal = PC_Constants.EMPTY_STRING;
                }
                fsFields.put(fieldName, fsFieldVal);
            }
            
            isValid=true;            
            applicantSourceId = fieldPrefix;
            isApplicantSelected = false;
        }
        
    }
    
   
    
    /**
* payerWrapper definition   
*/
    public class payerWrapper {
        @AuraEnabled public Id payerId {get;set;}
        @AuraEnabled public String payerName {get; set;}
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public String email {get; set;}
        @AuraEnabled public String fax {get; set;}
        @AuraEnabled public String phone {get; set;}
        @AuraEnabled public String payerType {get; set;}
        @AuraEnabled public String payerTypeLabel {get; set;}
        @AuraEnabled public String subType {get; set;}
        @AuraEnabled public String recordName {get; set;}
        @AuraEnabled public String isSelected {get; set;}
        
        public payerWrapper(Account a) {
            payerId = a.Id;
            payerName = a.Name;
            status = a.PC_Status__c;
            email = a.PC_Email__c;
            fax = a.Fax;
            phone = a.Phone;
            payerType = a.Type;
            payerTypeLabel = a.Type;
            subType = a.PC_Sub_type__c;
            recordName = a.RecordType.Name;
            isSelected = PC_Constants.FALSE_STRING;
        }
    }
    
    public class FieldWrapper {
        @AuraEnabled public String fieldLabel { get; set; }
        @AuraEnabled public String fieldName { get; set; }
        @AuraEnabled public String fieldType { get; set; }
        @AuraEnabled public Boolean fieldRequired { get; set; }
        @AuraEnabled public String referenceTo { get; set; }
        @AuraEnabled public List<PC_PicklistFieldManager.PicklistEntryWrapper> lstOptions { get; set; }
        @AuraEnabled public List<PC_PicklistFieldManager.PicklistEntryWrapper> lstRecordTypeOptions { get; set; }
        @AuraEnabled public Map<Id,String> RecordTypes { get; set; }
        public FieldWrapper() { }
        public FieldWrapper(Schema.DescribeFieldResult f, List<SelectOption> recordType, List<PC_PicklistFieldManager.PicklistEntryWrapper> lstRecordTypeLabelOptions) {
            fieldType = String.valueOf(f.getType());
            fieldLabel = f.getLabel();
            fieldName = f.getName();
            
            if (f.isCreateable() && !f.isNillable() && !f.isDefaultedOnCreate()){
                fieldRequired = true;                
            } else {
                fieldRequired = false;
            }
            
            if (f.getReferenceTo() != null && f.getReferenceTo().size() > 0) {
                referenceTo = (f.getReferenceTo()[0]).getDescribe().getLabel();
            }
            
            if (String.valueOf(f.getType()) == String.valueOf(Schema.DisplayType.Multipicklist) || String.valueOf(f.getType()) == String.valueOf(Schema.DisplayType.Picklist)){
                lstOptions = new List<PC_PicklistFieldManager.PicklistEntryWrapper>();
                lstOptions.add(new PC_PicklistFieldManager.PicklistEntryWrapper(PC_Constants.PICKLIST_NONE,System.Label.PC_Picklist_None));
                lstOptions.addAll(PC_PicklistFieldManager.getPicklistEntryWrappersFordescFields(f));
            }
            
            if (f.getLocalName() == RECORDTYPEID_KEY){
                lstRecordTypeOptions = new List<PC_PicklistFieldManager.PicklistEntryWrapper>();
                lstRecordTypeOptions = lstRecordTypeLabelOptions;
                RecordTypes = new Map<Id,String>();
                for (SelectOption rt : recordType) {
                    RecordTypes.put(rt.getValue(),rt.getLabel());
                }
                fieldRequired = true;
            }
        }
    }
    
    @AuraEnabled
    public static List<PC_FieldSetController.FieldSetMember> getFieldSetFields(String typeName, String fsName){
        return PC_FieldSetController.getFields(typeName, fsName);
    }
    
}