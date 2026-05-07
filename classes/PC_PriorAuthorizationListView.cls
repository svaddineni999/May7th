/**
* ----------------------------------------------------------------------------------
* Developer              Date                   	Description
* -----------------------------------------------------------------------------------
* Tejas Patel            Aug 14, 2017			    Initial Version
* Prachi Nandgaonkar     Aug 22, 2017               [PC-1998] Updated class to use Case object instead of custom object for Prior Authorization
* Shabda Bhujad          Aug 22, 2017               [PC-1720][PC-2098] Added the getPARecordTypeId method to initiation form for case logic to list component
* Shabda Bhujad			 Aug 23, 2017				[PC-2017] Added method isPACaseActive to check if an ative PA already exists on case
* Shabda Bhujad	      	 Sep 05, 2017				[PC-2177] Change the query to pull prescription number instead of id
* Tejas Patel            Oct 11,2017                [PC-2398] Translation
*/
public with sharing class PC_PriorAuthorizationListView {
	@AuraEnabled
    public static FieldLabels getFieldLabels(){
        FieldLabels fieldlabels 	= new FieldLabels();
        fieldlabels.paID			= System.Label.PC_PA_Number;
        fieldlabels.prescription	= Case.PC_PA_Prescription__c.getDescribe().getLabel();
        fieldlabels.status			= Case.PC_PA_Status__c.getDescribe().getLabel();
        fieldlabels.submittedon		= Case.PC_PA_Submitted_On__c.getDescribe().getLabel();
        fieldlabels.lastupdatedon	= Case.LastModifiedDate.getDescribe().getLabel(); 
        fieldlabels.expireson		= Case.PC_PA_Expiration_Date__c.getDescribe().getLabel();
        fieldlabels.paOutcome		= Case.PC_PA_Outcome__c.getDescribe().getLabel();
        fieldlabels.paExtURL       = Case.PC_ePA_URL__c.getDescribe().getLabel();
        
        return fieldlabels;
    }
 
    @AuraEnabled
    public static Id getPARecordTypeId (String objName) {
        Id paRecType = PC_SYSTEM.recordTypeId(objName, PC_Constants.CASE_PA_RECORD_TYPE); 
        return paRecType;
    }
    
    @AuraEnabled 
    public static boolean isPACaseActive(ID programId){
        List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_PA_Status__c')};
        Id PARecordTypeId = PC_System.recordTypeId(PC_Constants.PC_CASE, PC_Constants.CASE_PA_RECORD_TYPE);
        String PARecordTypeName =PC_System.recordTypeName(PC_Constants.PC_CASE,PC_Constants.CASE_PA_RECORD_TYPE) ;
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
        	String[] nonActiveStatus  = new String[]{PC_Constants.PA_CASE_STATUS_Denied, PC_Constants.PA_CASE_STATUS_Canceled,PC_Constants.PA_CASE_STATUS_Expired};

            integer activePACount = [SELECT Count() FROM Case
                                         WHERE PC_Program__c =: programId 
                                         AND (RecordType.Name =: PARecordTypeName OR Type = : PARecordTypeName)
                                         AND (PC_PA_Status__c NOT IN :nonActiveStatus)
                                        ];            
        if (activePACount>0) {
            return true;
        }
        else {
            return false;	
        }
          
    }
    
    @AuraEnabled
    public static LIST<PAWrapper> getPARecords(ID programId){
        LIST<PAWrapper> painfo 	= new LIST <PAWrapper>();
        String PARecordTypeName = PC_System.recordTypeName(PC_Constants.PC_CASE,PC_Constants.CASE_PA_RECORD_TYPE) ;
        //FLS check
        try{
            List<String> fields = new List<String>{ PC_Constants.getQualifiedAPIName('PC_PA_Prescription__c'), 'LastModifiedDate', 
                    PC_Constants.getQualifiedAPIName('PC_PA_Status__c'),
                    PC_Constants.getQualifiedAPIName('PC_Submitted_On__c'),
                    PC_Constants.getQualifiedAPIName('PC_PA_Expiration_Date__c'),
                    PC_Constants.getQualifiedAPIName('PC_PA_Outcome__c'),
                    PC_Constants.getQualifiedAPIName('PC_ePA_URL__c')};
                                                        
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);

            LIST<Case> pa = [
                    SELECT CaseNumber, PC_PA_Prescription__r.Name,
                            toLabel(PC_PA_Status__c), PC_PA_Submitted_On__c, LastModifiedDate,
                            PC_PA_Expiration_Date__c, toLabel(PC_PA_Outcome__c), PC_ePA_URL__c
                    FROM Case
                    WHERE PC_Program__c = :programId AND (Case.RecordType.Name = :PARecordTypeName OR Case.Type = :PARecordTypeName) ORDER BY LastModifiedDate DESC

            ];
            
            for(Case p : pa){
                painfo.add(new PAWrapper(p));
            }
            
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);                
        }
        return painfo;
    }
    
    public class FieldLabels{
        @AuraEnabled public String paID { get; set; }
        @AuraEnabled public String prescription { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String submittedon { get; set; }
        @AuraEnabled public String lastupdatedon { get; set; }
        @AuraEnabled public String expireson { get; set; }
        @AuraEnabled public String paOutcome { get; set; }
        @AuraEnabled public String paExtURL { get; set; }
        
        public FieldLabels() {
        }
    }
    
    public class PAWrapper{
        @AuraEnabled public String paID { get; set; }
        @AuraEnabled public String prescription { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Date submittedon { get; set; }
        @AuraEnabled public Date lastupdatedon { get; set; }
        @AuraEnabled public Date expireson { get; set; }
        @AuraEnabled public String paUrl { get; set; }
        @AuraEnabled public String paOutcome { get; set; }
        @AuraEnabled public String paExtURL { get; set; }
        
        public PAWrapper(Case pa) {
            paID = pa.CaseNumber;
            prescription = pa.PC_PA_Prescription__r.Name;
            status = pa.PC_PA_Status__c;
            submittedon = pa.PC_PA_Submitted_On__c;
            lastupdatedon = date.ValueOf(pa.LastModifiedDate);
            expireson = pa.PC_PA_Expiration_Date__c;
            paUrl = '/'+ pa.Id;
            paOutcome = pa.PC_PA_Outcome__c;
            if(String.isBlank(pa.PC_ePA_URL__c)) {
                paExtURL = PC_Constants.EMPTY_STRING;
            }
            else {
                paExtURL = pa.PC_ePA_url__c;
            }
        }
        
        public PAWrapper() {}
    }
}