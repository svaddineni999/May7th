/*********************************************************************************
Class Name      : PC_Referral_Launch
Description     : Returns list of referral records to be displayed
Created By      : Prachi Nandgaonkar
Created Date    : 24-Aug-2017
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Prachi Nandgaonkar          24-Aug-17              [PC-1705] Initial Version
Tejas Patel                 11-Oct-17              [PC-2398] Translation
*********************************************************************************/
public with sharing class PC_Referral_Launch {
    
    /*********************************************************************************
    Method Name    : getFieldLabels
    Author         : Prachi Nandgaonkar 
    Description    : This method  displays column headers for referral list view
    Return Type    : FieldLabels
    Parameter      : void            
    *********************************************************************************/
    @AuraEnabled
    public static FieldLabels getFieldLabels(){
        FieldLabels fieldlabels 	= new FieldLabels();
        fieldlabels.refID			= System.Label.PC_Referral_Number;
        fieldlabels.pharmacy    	= PC_Pharmacy_Referral__c.PC_Target_Pharmacy__c.getDescribe().getLabel();
        fieldlabels.status			= PC_Pharmacy_Referral__c.PC_Referral_Status__c.getDescribe().getLabel();
        fieldlabels.submittedon		= PC_Pharmacy_Referral__c.CreatedDate.getDescribe().getLabel();
        fieldlabels.lastupdatedon	= PC_Pharmacy_Referral__c.LastModifiedDate.getDescribe().getLabel(); 
        
        return fieldlabels;
    }
    
    /*********************************************************************************
    Method Name    : isReferralActive
    Author         : Prachi Nandgaonkar 
    Description    : This method checks if a program case has any active referrals
    Return Type    : Boolean
    Parameter      : ProgramCase Id            
    *********************************************************************************/
    @AuraEnabled 
    public static boolean isReferralActive(ID programId){
        //FLS check
        List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Referral_Status__c')};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Pharmacy_Referral__c'),PC_Database.Operation.Reading, fields);
        
        //Inactive statuses
        String[] inactiveStatus  = new String[]{PC_Constants.REFERRAL_STATUS_DISCONTINUED, PC_Constants.REFERRAL_STATUS_CLOSED,PC_Constants.REFERRAL_STATUS_CANCELED};
            
        integer activeRefCount = [SELECT Count() 
                                     FROM PC_Pharmacy_Referral__c
                                     WHERE PC_Program__c =: programId AND PC_Referral_Status__c NOT IN :inactiveStatus];            
        if (activeRefCount>0) {
            return true;
        }
        else {
            return false;	
        }
        
    }
    
    /*********************************************************************************
    Method Name    : getRefRecords
    Author         : Prachi Nandgaonkar 
    Description    : This method checks if a program case has any active referrals
    Return Type    : List<refWrapper>
    Parameter      : ProgramCase Id            
    *********************************************************************************/
    @AuraEnabled
    public static LIST<refWrapper> getRefRecords(ID programId){
        LIST<refWrapper> refinfo = new LIST <refWrapper>();
        
        //FLS check
        try{
            List<String> fields = new List<String>{ PC_Constants.getQualifiedAPIName('PC_Target_Pharmacy__c'), 'LastModifiedDate', 
            PC_Constants.getQualifiedAPIName('PC_Referral_Status__c'), 'CreatedDate'};
			PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Pharmacy_Referral__c'),PC_Database.Operation.Reading, fields);
            
            LIST<PC_Pharmacy_Referral__c> ref = [SELECT Name, PC_Target_Pharmacy__r.Name, toLabel(PC_Referral_Status__c), CreatedDate, LastModifiedDate
                                                 FROM PC_Pharmacy_Referral__c
                                                 WHERE PC_Program__c =: programId Limit 5];
            
            for(PC_Pharmacy_Referral__c r : ref){
                refinfo.add(new refWrapper(r));
            }
            
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);                
        }
        return refinfo;
    }
    
    /* Wrapper for column titles */
    public class FieldLabels{
        @AuraEnabled public String refID { get; set; }
        @AuraEnabled public String pharmacy { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String submittedon { get; set; }
        @AuraEnabled public String lastupdatedon { get; set; }
        
        public FieldLabels() {
        }
    }
    
    /* Wrapper for Referral records */
    public class refWrapper{
        @AuraEnabled public String refID { get; set; }
        @AuraEnabled public String pharmacy { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Date submittedon { get; set; }
        @AuraEnabled public Date lastupdatedon { get; set; }
        @AuraEnabled public String refUrl { get; set; }
        
        public refWrapper(PC_Pharmacy_Referral__c ref) {
            refID = ref.Name;
            pharmacy = ref.PC_Target_Pharmacy__r.Name;
            status = ref.PC_Referral_Status__c;
            submittedon = date.ValueOf(ref.CreatedDate);
            lastupdatedon = date.ValueOf(ref.LastModifiedDate);
            refUrl = '/'+ ref.Id; 
        }
        
        
    }
}