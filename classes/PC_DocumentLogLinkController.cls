/*Class Name    : PC_DocumentLogLinkController
Description     : This class is helpful to attach document log to different objects.
Created By      : Md Khalid Munavar Ali
Created Date    : June 18, 2015
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   	Description
-----------------------------------------------------------------------------------            
Md Khalid Munavar Ali       June 18, 2015          	Initial Version
Shabda Bhujad       		Nov 14, 2016           	Removed references to PC_Brand__c 
Shabda Bhujad				Dec 06, 2016			Added FLS check to PC_DocumentLogLinkController, fetchTrainingRecord, Save method
Prachi Nandgaonkar          Feb 15, 2017            Updated save() to use PC_Account__c instead of PC_Patient__c. Deleted PC_Patient__c lookup from Document Log (PC-1148)
Ajinkya Deshmukh			Jun 08, 2017			FLS Check Updated
Mayuresh Patil              Jul 26, 2017            Updated CRUD/FLS Checks
Tejas Patel					Nov 7, 2017				Made use of PC_Constants.LINK_ASSOCIATION_TYPE_PROGRAM; and PC_Constants.LINK_ASSOCIATION_TYPE_COVERAGE;
Hitha Avalakki              Dec 02, 2020           [PC-6751] Forcereviewer scan issue: Commenting the class code as its no longer in use.
*********************************************************************************/
public with sharing class PC_DocumentLogLinkController {
    /*public List<Case> programList {get; set;}
    public String patientId;
    public String documentId {get; set;}
    public String DocumentLog;
    public string categoryValues {get; set;}
    public List<coverageWrapper> coverageList {get; set;}
    public boolean isProgramSelected {set; get;}
    public boolean programsPresent {set; get;}
    public String patientName{get;set;}
    public Map<Id, Case> programMap;
    public String programId;
    public Map<Id, PC_Document_Log__c> documentLogAssociationIdMap;*/

    /*********************************************************************************
    Method Name    : Constructor
    Description    : This method is the constructor for the DTPC_DocumentLogLinkController class.
    We initialize the program records with radio buttons.
    Return Type    : void
    Parameter      : none
    *********************************************************************************/
    /*public PC_DocumentLogLinkController() {
        patientId = ApexPages.currentPage().getParameters().get('PatientId').escapeHtml4();
        documentId = ApexPages.currentPage().getParameters().get('DocumentId').escapeHtml4();
        DocumentLog = ApexPages.currentPage().getParameters().get('LogName').escapeHtml4();
        categoryValues = ApexPages.currentPage().getParameters().get('CategoryValues').escapeHtml4();
        if(categoryValues != null && categoryValues != '') {
            categoryValues = categoryValues.mid(1,categoryValues.length()-1);
        }
        programList = new List<Case>();
        coverageList = new List<coverageWrapper>();
        isProgramSelected = false;

        List<String> caseFields = new List<String>{'CaseNumber'};
        List<String> accountFields = new List<String>{'Name'};
        List<String> docLogFields = new List<String>{'Id'};

        if(patientId!=null && PC_Database.chkAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, caseFields)
			&& PC_Database.chkAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, accountFields)
			&& PC_Database.chkAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'),PC_Database.Operation.Reading, docLogFields)) {
            programList = [SELECT AccountId, Account.Name, CaseNumber, (SELECT Id FROM Document_Logs__r)
            FROM Case WHERE AccountId =: PatientId];
        }
        if(programList.size()>0) {
            programsPresent = true;
            patientName = programList[0].Account.Name;
            programMap = new Map<Id,Case>();
            for(Case pObj : programList) {
                programMap.put(pObj.id,pObj);
            }
        } else{
            programsPresent = false;
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.INFO, 'no programs');//todo /*system.Label.DTPC_No_Programs*/
           /* ApexPages.addMessage(myMsg);
        }
    }*/
    /*********************************************************************************
    Method Name    : fetchTrainingRecords
    Description    : This method is Used to fetch related list of program selected.
    Return Type    : void
    Parameter      : none
    *********************************************************************************/
   /* public void fetchTrainingRecords() {
        isProgramSelected = true;
        programId = System.currentPagereference().getParameters().get('inputs');
        if(programId != null) {
            coverageList = new List<coverageWrapper>();
            coverageWrapper covObj;
            try{
                List<String> fields = new List<String>{'Name',PC_Constants.getQualifiedAPIName('PC_Payer__c'),PC_Constants.getQualifiedAPIName('PC_Program__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Program_Coverage__c'),PC_Database.Operation.Reading, fields);
                for(PC_Program_Coverage__c cobj :[SELECT Name, RecordType.Name, PC_Payer__c FROM PC_Program_Coverage__c WHERE PC_Program__c =:programId]) {
					covObj = new coverageWrapper();
					covObj.covRec = cobj;
					covObj.ischecked = false;
					coverageList.add(covObj);
                }
            }catch(Exception ex){
                PC_Utility.logAndThrowException(ex);
            }
        }
    }*/

    /*********************************************************************************
    Method Name    : Save
    Description    : This method is Used to create document log records and attach it to the different objects.
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    /*public void Save() {
        try {
            List<PC_Document_Log__c> toInsertDocumentLogList = new List<PC_Document_Log__c>();
            DocumentLogAssociationIdMap = new Map<Id,PC_Document_Log__c>();
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Association_Record_Id__c'), PC_Constants.getQualifiedAPIName('PC_Document_Log__c'), PC_Constants.getQualifiedAPIName('PC_Document__c')};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'),PC_Database.Operation.Reading, fields);
            List<PC_Document_Log__c> documentLogList = [SELECT Id, PC_Association_Record_Id__c, PC_Document_Log__c FROM PC_Document_Log__c WHERE PC_Document__c=:documentId];
            if(documentLogList != null && documentLogList.size() > 0) {
                for(PC_Document_Log__c obj : documentLogList) {
                    DocumentLogAssociationIdMap.put(obj.PC_Association_Record_Id__c,obj);
                }
            }

            PC_Document_Log__c docObj;
            if (documentId != null) {
                if (programId != null) {
                    docObj = new PC_Document_Log__c();
                    docObj.id = (DocumentLogAssociationIdMap!=null && DocumentLogAssociationIdMap.containsKey(programId)) ? DocumentLogAssociationIdMap.get(programId).id : null;
                    docObj.PC_Document_Log__c = (DocumentLogAssociationIdMap!=null && DocumentLogAssociationIdMap.containsKey(programId)) ? DocumentLogAssociationIdMap.get(programId).PC_Document_Log__c : null;
                    if(docObj.id == null){
                        docObj.PC_Document__c = documentId;
                        docObj.PC_Program__c = programId;

                        docObj.PC_Account__c = patientId; //Prachi Nandgaonkar PC-1148

                        docObj.PC_Association_Record_ID__c = programId;
                        docObj.PC_Association_Record_Name__c = (programMap!=null && programMap.containsKey(programId)) ? programMap.get(programId).CaseNumber : null;
                        docObj.PC_Association_Type__c = PC_Constants.LINK_ASSOCIATION_TYPE_PROGRAM;
                    }
                    toInsertDocumentLogList.add(docObj);
                }
                if(coverageList!=null && CoverageList.size()>0) {
                    for(coverageWrapper cWrapper : CoverageList) {
                        if(cWrapper.isChecked) {
                            docObj = new PC_Document_Log__c();
                            docObj.id = (DocumentLogAssociationIdMap!=null && DocumentLogAssociationIdMap.containsKey(cWrapper.covRec.id)) ? DocumentLogAssociationIdMap.get(cWrapper.covRec.id).id : null;
                            docObj.PC_Document_Log__c = (DocumentLogAssociationIdMap!=null && DocumentLogAssociationIdMap.containsKey(cWrapper.covRec.id))?DocumentLogAssociationIdMap.get(cWrapper.covRec.id).PC_Document_Log__c : null;
                            if(docObj.id == null){
                                docObj.PC_Document__c = documentId;
                                docObj.PC_Coverage__c = cWrapper.covRec.id;
                                docObj.PC_Association_Record_ID__c = cWrapper.covRec.id;
                                docObj.PC_Association_Record_Name__c = cWrapper.covRec.Name;
                                docObj.PC_Association_Type__c = PC_Constants.LINK_ASSOCIATION_TYPE_COVERAGE;

                                docObj.PC_Account__c = patientId; //Prachi Nandgaonkar PC-1148
                            }
                            toInsertDocumentLogList.add(docObj);
                        }
                    }
                }

                if(toInsertDocumentLogList!=null && toInsertDocumentLogList.size()>0) {
                    if(DocumentLog!=null) {
                        for(PC_Document_log__c logInst : toInsertDocumentLogList) {
                            if(logInst.PC_Document_Log__c==null) {
                                logInst.PC_Document_Log__c = categoryValues;
                            }
                            if(logInst.PC_Document_Log__c!=null && !logInst.PC_Document_Log__c.contains(DocumentLog)){
                                logInst.PC_Document_Log__c = logInst.PC_Document_Log__c + ';' + categoryValues;
                            }
                        }
                    }
                    PC_Database.ups (toInsertDocumentLogList);
                }
            }
        }catch(Exception ex){
                PC_Utility.logAndThrowException(ex);
        }
    }

    public class coverageWrapper {
        public PC_Program_Coverage__c covRec{get;set;}
        public boolean ischecked{get;set;}
    } */
}