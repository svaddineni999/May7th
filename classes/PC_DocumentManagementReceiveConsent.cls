/*********************************************************************************
Modification Log:
----------------------------------------------------------------------------------
User                          Date                   Description
-----------------------------------------------------------------------------------           
Sheela Sathyanarayana		 12-Aug-2018	        Initial Version
Vijay Kashikar               07-Marc-2019           [PC-4556] Changed reference from PC_Program_Service_Permission__c.PC_Program__c to PC_Program_Service_Permission__c.PC_ProgramCase__c
Haritha Reddy               Dec 13, 2019            [PC-5791] Added Error handling for getFieldLabels() method
Haritha Reddy              21-Jan-2021             [PC-7102] Added FLS Check
Haritha Reddy             21-Jan-2021               [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/
public with sharing class PC_DocumentManagementReceiveConsent {
    
    public inherited sharing class InitData {
        @AuraEnabled public List<ListWrapper> consentsList;
        @AuraEnabled public FieldLabels fieldLabels ;

        public InitData() {
            consentsList = new List<ListWrapper>();
            fieldLabels  = new FieldLabels();
        }
    }
    
    @AuraEnabled
    public static FieldLabels getFieldLabels(){
        FieldLabels fieldlabels 		= new FieldLabels();
        try {
            fieldlabels.service = PC_Program_Service_Permission__c.PC_Service__c.getDescribe().getLabel();
            fieldlabels.patientResponse = PC_Program_Service_Permission__c.PC_Patient_Response__c.getDescribe().getLabel();
            fieldlabels.patientResponseDate = PC_Program_Service_Permission__c.PC_Patient_Response_Date__c.getDescribe().getLabel();
            fieldlabels.hcpResponse = PC_Program_Service_Permission__c.PC_HCP_Response__c.getDescribe().getLabel();
            fieldlabels.hcpResponseDate = PC_Program_Service_Permission__c.PC_HCP_Response_Date__c.getDescribe().getLabel();
            fieldlabels.startDate = PC_Program_Service_Permission__c.PC_Start_Date__c.getDescribe().getLabel();
            fieldlabels.endDate = PC_Program_Service_Permission__c.PC_End_Date__c.getDescribe().getLabel();
            fieldlabels.caseId = PC_Program_Service_Permission__c.PC_ProgramCase__c.getDescribe().getLabel();
        } catch (Exception e) {
            PC_Utility.logAndThrowException(e);
        }
               
        return fieldlabels;
    }
    
    @AuraEnabled
    public static InitData getConsentCases(List<Id> docIds){
        
        InitData initData = new InitData();
        LIST<ListWrapper> listInfo 	= new LIST <ListWrapper>();
        LIST<PC_Program_Service_Permission__c> consentCasesList = new LIST <PC_Program_Service_Permission__c>();

        try{
            List<String> fields = new List<String>{
                    PC_Constants.getQualifiedAPIName('PC_Service__c'), 
                    PC_Constants.getQualifiedAPIName('PC_Service__r.Name'),
                    PC_Constants.getQualifiedAPIName('PC_Patient_Response__c'),
                    PC_Constants.getQualifiedAPIName('PC_Patient_Response_Date__c'),
                    PC_Constants.getQualifiedAPIName('PC_HCP_Response__c'),
                    PC_Constants.getQualifiedAPIName('PC_HCP_Response_Date__c'),
                    PC_Constants.getQualifiedAPIName('PC_Start_Date__c'),
                    PC_Constants.getQualifiedAPIName('PC_End_Date__c'),
                    PC_Constants.getQualifiedAPIName('PC_Consent_Type__c'),
                    PC_Constants.getQualifiedAPIName('PC_Signed_Request_Form__c'),
                    PC_Constants.getQualifiedAPIName('PC_ProgramCase__c'),
                    PC_Constants.getQualifiedAPIName('PC_Signed_Request_Form__r.Name'),
                    PC_Constants.getQualifiedAPIName('PC_ProgramCase__r.CaseNumber')};
                        
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Program_Service_Permission__c'),PC_Database.Operation.Reading, fields);
            
            consentCasesList =
            [SELECT Id, PC_Service__c, PC_Service__r.Name, PC_Patient_Response__c, PC_Patient_Response_Date__c, 
             PC_HCP_Response__c,PC_HCP_Response_Date__c, PC_Start_Date__c, PC_End_Date__c, 
             PC_Consent_Type__c, PC_Signed_Request_Form__c, PC_Signed_Request_Form__r.Name, PC_ProgramCase__c,
             PC_ProgramCase__r.CaseNumber 
             FROM PC_Program_Service_Permission__c  
             WHERE PC_Signed_Request_Form__c in :docIds 
             ORDER BY PC_Patient_Response_Date__c DESC NULLS LAST];
        	system.debug(consentCasesList);
            
            for(PC_Program_Service_Permission__c p : consentCasesList){
                listInfo.add(new ListWrapper(p));
            }            
        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);                
        } 
        
        initData.consentsList = listInfo;
        initData.fieldLabels = getFieldLabels();
        return initData;        
     
    }
    
    public inherited sharing class FieldLabels{
        @AuraEnabled public String service { get; set; }
        @AuraEnabled public String patientResponse { get; set; }
        @AuraEnabled public String patientResponseDate { get; set; }
        @AuraEnabled public String hcpResponse { get; set; }
        @AuraEnabled public String hcpResponseDate { get; set; }
        @AuraEnabled public String startDate { get; set; }
        @AuraEnabled public String endDate { get; set; }
        @AuraEnabled public String caseId { get; set; }     
        
        public FieldLabels() {
        }
    }

    public inherited sharing class ListWrapper{
        @AuraEnabled public String pspId { get; set; }
        @AuraEnabled public String service { get; set; }
        @AuraEnabled public String serviceId { get; set; }
        @AuraEnabled public String patientResponse { get; set; }
        @AuraEnabled public Date patientResponseDate { get; set; }
        @AuraEnabled public String hcpResponse { get; set; }
        @AuraEnabled public Date hcpResponseDate { get; set; }
        @AuraEnabled public Date startDate { get; set; }
        @AuraEnabled public Date endDate { get; set; }
        @AuraEnabled public String consentType { get; set; }
        @AuraEnabled public String document { get; set; }
        @AuraEnabled public String documentId { get; set; }
        @AuraEnabled public String caseNumber { get; set; }
        @AuraEnabled public String caseId { get; set; }        
  
        public ListWrapper(PC_Program_Service_Permission__c psp) {
            pspId = psp.Id;
            service = psp.PC_Service__r.Name;
            serviceId = psp.PC_Service__c;
            patientResponse = psp.PC_Patient_Response__c;
            patientResponseDate = date.ValueOf(psp.PC_Patient_Response_Date__c);
            hcpResponse = psp.PC_HCP_Response__c;
            hcpResponseDate = date.ValueOf(psp.PC_HCP_Response_Date__c);
            startDate = date.ValueOf(psp.PC_Start_Date__c);
            endDate = date.ValueOf(psp.PC_End_Date__c);
            consentType = psp.PC_Consent_Type__c;
            document = psp.PC_Signed_Request_Form__r.Name;
            documentId = psp.PC_Signed_Request_Form__c;
            caseNumber = psp.PC_ProgramCase__r.CaseNumber;
            caseId = psp.PC_ProgramCase__c;
        }
        
        public ListWrapper() {}
    }
}