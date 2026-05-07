/*********************************************************************************
Class Name      : PC_DocumentLogLightningController
Description     : Controller class used for PC_DocumentLog (lightning)
Created By      : Deloitte               
Created Date    : June 15, 2016
Modification Log:
---------------------------------------------------------------------------------- 
Developer              Date                   	Description
-----------------------------------------------------------------------------------            
Tetiana Danylyshyn     	15-June-2016           	Initial Version
Shabda Bhujad,         	Nov 3, 2016			  	Removed references to 'Date Received By Manufacturer' - annotated by @@RemoveDateRecByManf
Prachi Nandgaonkar
Shabda Bhujad          	Nov 14, 2016			Removed references to PC_Brand__c from getProgramRecords method
Shabda Bhujad			Dec 05,2016				Added FLS check to getProgramRecords, getAdversEventsRecords, getInteractionRecords, getUserName, fetchTrainingRecords and save methods
Prachi Nandgaonkar		Jan 26, 2017			Added a wrapper class for Account 
Shabda Bhujad			Jan 26, 2017 			Added a method getAccountDetails to populate the patient account details to link the document to patient
Shabda Bhujad			Jan 27, 2017 			Updated the Save method to populate the record type of the object linked and ability to link account to the document 
Shabda Bhujad 			Jan 30,2017				Updated save method with the code to change status to 'In Review' when document is linked 
Prachi Nandgaonkar      Feb 15, 2017            Updated save() to prefix word 'Account' for record type in document modification log. For ex: 'Account: Physician' PC-1094
Shabda Bhujad			May 18, 2017 			Added the method getExcludedRelatedObjects to retrieve custom metadata configurations [PC-1610]
Shabda Bhujad		  	May 29, 2017			Added the Manufacturer,docEngagementProgId attributes to the search logic for results relevant to Engagement Program on Document [PC-1598]
												Modified methods - getProgramRecords, getAdversEventsRecords, getInteractionRecords
Shabda Bhujad			Jun 13, 2017			Updated the document log creation call for case to populate the Type instead of recordtype for case [PC-1701]
Ajinkya Deshmukh		Jun 08, 2017			FLS Check Added
Tejas Patel             Jul 06, 2017            Removed the SOQL from for loop from class fetchTrainingRecords
Mayuresh Patil          Jul 26, 2017            Additional FLS Check Added
Hitha Avalakki          Oct 25, 2017            [PC-5624] Modified getAdversEventsRecords method to fetch PC_AdverseEvent2__c as well. Added
                                                getAdverseEventObjectInUse method to get the adverse event object in use.
Haritha Reddy           Dec 13, 2019            [PC-5791] Added Error handling for methods where it was missing
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
Haritha Reddy           21-Jan-2021           [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/

public with sharing class PC_DocumentLogLightningController {
    
    /*********************************************************************************
    Method Name    : getProgramRecords
    Author         : Tetiana Danylyshyn
    Description    : This method retrieves program cases for the Patient and for the engagement program, if available.            
    *********************************************************************************/
    @AuraEnabled
    public static List<Case> getProgramRecords(Id patientId, String docEngagementProgId) {
        if (docEngagementProgId!='' && docEngagementProgId!= null) {
            return PC_DocumentManagementHelper.getProgramRecords(patientId, docEngagementProgId);
        }
        else {
        	return PC_DocumentManagementHelper.getProgramRecords(patientId);
        }
    }

    /*********************************************************************************
    Method Name    : getAdversEventsRecords
    Author         : Tetiana Danylyshyn
    Description    : This method retrieves adverse events for the Patient and relevant for the engagement program, if available. 
    *********************************************************************************/
    @AuraEnabled
    public static List<sObject> getAdversEventsRecords(Id patientId, String docEngagementProgId) {
        List<sObject> sobjectList=new List<SObject>();
        try {
            String adverseEventObjectName = getAdverseEventObjectInUse();
            if (docEngagementProgId != '' && docEngagementProgId != null) {
                //PC-5624: Added a check for Adverse Event and Adverse Event 2 objects
                if (adverseEventObjectName.equals('PC_AdverseEvent__c')) {
                    return (List<sObject>) PC_DocumentManagementHelper.getAdverseEventsRecords(patientId, docEngagementProgId);
                } else if (adverseEventObjectName.equals('PC_AdverseEvent2__c')) {
                    return (List<sObject>) PC_DocumentManagementHelper.getAdverseEvents2Records(patientId, docEngagementProgId);
                }
            } else {
                //PC-5624: Added a check for Adverse Event and Adverse Event 2 objects
                if (adverseEventObjectName.equals('PC_AdverseEvent__c')) {
                    return (List<sObject>) PC_DocumentManagementHelper.getAdverseEventsRecords(patientId);
                } else if (adverseEventObjectName.equals('PC_AdverseEvent2__c')) {
                    return (List<sObject>) PC_DocumentManagementHelper.getAdverseEvents2Records(patientId);
                }
            }
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }

        return sobjectList;
    }
    
    /*********************************************************************************
    Method Name    : getInteractionRecords
    Author         : Tetiana Danylyshyn
    Description    : This method retrieves Interactions for the Patient and relevant for the engagement program, if available.            
    *********************************************************************************/
    @AuraEnabled
    public static List<PC_Interaction__c> getInteractionRecords(Id patientId, String docEngagementProgId) {
        if (docEngagementProgId!='' && docEngagementProgId!= null) {
            return PC_DocumentManagementHelper.getInteractionRecords(patientId,docEngagementProgId);
        }
        else {
            return PC_DocumentManagementHelper.getInteractionRecords(patientId);
        }
    }
    
    /*********************************************************************************
    Method Name    : getExcludedRelatedObjects
    Author         : Shabda Bhujad
    Description    : This method queries the Doc Management configuration metadata to exclude the objects available for linking 
					 for an account record type                 
    *********************************************************************************/
    @AuraEnabled
    public static  List<String> getExcludedRelatedObjects(String accountRecordType) {
        try{
            List<String> excludedObjects = new List<String> () ;
            List<PC_Doc_Management_View_Configuration__mdt> exConfig = [SELECT PC_Objects_excluded_from_linking__c FROM PC_Doc_Management_View_Configuration__mdt WHERE PC_Account_Record_Type__c =:accountRecordType];
            if (!exConfig.isEmpty()){
                for( integer i=0;i< exConfig.size();i++) {
                    excludedObjects.add(exConfig[i].PC_Objects_excluded_from_linking__c);
                }
                return excludedObjects;
            }else {
                return null;
            }
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
            return null;
        }
    }
    
    /*********************************************************************************
    Method Name    : getAccountDetails
    Author         : Shabda Bhujad
    Description    : This method retrieve patient name
    Return Type    : Account
    Parameter      : Id accountId              
    *********************************************************************************/
    @AuraEnabled
    public static AccountWrapper getAccountDetails(String accountId) {
        Account acc = new Account();
        AccountWrapper acctWrapper = new AccountWrapper(acc);
        try {
            List<String> fields = new List<String>{'Type',PC_Constants.getQualifiedAPIName('PC_Last_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_First_Name__c'),PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c'),
                    PC_Constants.getQualifiedAPIName('PC_Status__c'), PC_Constants.getQualifiedAPIName('PC_Primary_Address_1__c'),
                    PC_Constants.getQualifiedAPIName('PC_Primary_City__c'), PC_Constants.getQualifiedAPIName('PC_Primary_State__c'),
                    PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c')};
                    PC_Database.assertAccess('Account',PC_Database.Operation.Reading, fields);    
            //check access before SOQL    
            acc = [SELECT Id, PC_Last_Name__c, PC_First_Name__c, Name, Type, PC_Date_of_Birth__c, PC_Status__c, PC_Primary_Address_1__c, PC_Primary_City__c, PC_Primary_State__c, PC_Primary_Zip_Code__c 
            		FROM Account 
            		WHERE Id =: accountId];
            acctWrapper = new AccountWrapper(acc);
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return acctWrapper; 
    }

    /*********************************************************************************
    Method Name    : fetchTrainingRecords
    Author         : Tetiana Danylyshyn
    Description    : This method is Used to fetch related list of program selected.    
    Return Type    : List<CoverageWrapper>
    Parameter      : Id programId
    *********************************************************************************/
    @AuraEnabled
    public static List<ProgramCoverageWrapper> fetchTrainingRecords(List<String> programId) {
        List<ProgramCoverageWrapper> programCoverageList = new List<ProgramCoverageWrapper>();
        if(programId != null && programId.size() > 0) {
            try {
                List<String> fields = new List<String>{'CaseNumber'};
                PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
                //check access before SOQL    
                Map<Id, Case> casesMap = new Map<Id, Case>([SELECT Id, CaseNumber FROM Case WHERE Id IN :programId]);
                ProgramCoverageWrapper pcw;
                List<CoverageWrapper> covList;
                CoverageWrapper covObj;
                fields = new List<String>{'Name', PC_Constants.getQualifiedAPIName('PC_Payer__c'), PC_Constants.getQualifiedAPIName('PC_Program__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Program_Coverage__c'),PC_Database.Operation.Reading, fields);
                List<PC_Program_Coverage__c> programCoverage = [SELECT Id, Name, RecordType.Name, PC_Payer__c FROM PC_Program_Coverage__c WHERE PC_Program__c IN :programId];
                for (String s : programId) { 
                    pcw = new ProgramCoverageWrapper();
                    pcw.idProgram = s;
                    pcw.programNumber = casesMap.get(s).CaseNumber;
                    covList = new List<CoverageWrapper>();
                    for(PC_Program_Coverage__c cobj : programCoverage) {
                        covObj = new CoverageWrapper();
                        covObj.covRec = cobj;
                        covObj.ischecked = false;
                        covList.add(covObj);
                    }
                    pcw.coverageList = covList;
                    programCoverageList.add(pcw);
                }
            }catch(Exception ex) {
                PC_Utility.logAndThrowException(ex);
            }
        }
        return programCoverageList;
    }


    
    /*********************************************************************************
    Method Name    : save
    Author         : Tetiana Danylyshyn
    Description    : This method is Used to create document log records and attach it to the different objects.
    Return Type    : void
    Parameter      : Id documentId, Id programId, Id patientId, String coverage
    *********************************************************************************/
    @AuraEnabled
    public static void save(Id documentId, Id patientId, List<String> programs, String coverage, List<String> adverseEvents,List<String> adverseEvents2, List<String> interactions, List<String> accountSelected) {
        List<ProgramCoverageWrapper> programCoverageWrapperList = (List<ProgramCoverageWrapper>)JSON.deserialize(coverage, List<ProgramCoverageWrapper>.class);
        List<PC_Document_Log__c> toInsertDocumentLogList = new List<PC_Document_Log__c>();
        try {
            //check access before SOQL             
            List<String> fields = new List<String>{'CaseNumber','Type'};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
            List<Case> programList = [SELECT Id, CaseNumber,RecordType.Name, Type FROM Case WHERE Id IN: programs];
            
            //Adding code to link Account of the patient and document
            fields = new List<String>{'Name'};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
            List<Account> accountList = [SELECT Id, Name,RecordType.Name FROM Account WHERE Id =:accountSelected];
            
            fields = new List<String>{'Name'};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent__c'),PC_Database.Operation.Reading, fields);    
            List<PC_AdverseEvent__c> adverseEventsList = [SELECT Id, Name FROM PC_AdverseEvent__c WHERE Id IN: adverseEvents];

            fields = new List<String>{'Name'};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_AdverseEvent2__c'),PC_Database.Operation.Reading, fields);
            List<PC_AdverseEvent2__c> adverseEvents2List = [SELECT Id, Name FROM PC_AdverseEvent2__c WHERE Id IN: adverseEvents2];
            
            fields = new List<String>{'Name'};
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Interaction__c'),PC_Database.Operation.Reading, fields);    
            List<PC_Interaction__c> interactionsList = [SELECT Id, Name FROM PC_Interaction__c WHERE Id IN: interactions];
            
            
            if (documentId != null) {
                fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Document_Category__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'),PC_Database.Operation.Reading, fields);    
                //check access before SOQL  
                List<PC_Document__c> documents = [SELECT Id, PC_Document_Category__c FROM PC_Document__c WHERE Id=:documentId];
                String categoryValues;
                if(documents != null && documents.size() == 1 && documents[0].PC_Document_Category__c != null && documents[0].PC_Document_Category__c != '') {
                    categoryValues = documents[0].PC_Document_Category__c.mid(1,documents[0].PC_Document_Category__c.length()-1);
                }
                Map<Id,PC_Document_Log__c> documentLogAssociationIdMap = new Map<Id,PC_Document_Log__c>();
                fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Association_Record_Id__c'),PC_Constants.getQualifiedAPIName('PC_Document_Log__c'),PC_Constants.getQualifiedAPIName('PC_Document__c')};
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'),PC_Database.Operation.Reading, fields);    
            	//check access before SOQL  
            	for(PC_Document_Log__c obj : [SELECT Id, PC_Association_Record_Id__c, PC_Document_Log__c FROM PC_Document_Log__c WHERE PC_Document__c=:documentId]) {
                    documentLogAssociationIdMap.put(obj.PC_Association_Record_Id__c,obj);
                }
                
                //link to program records
                if (programList != null && programList.size() > 0) {
                    PC_Document_Log__c docObj;
                    for(Case c : programList) {
                        /*
                         * Updated the document log link to populate Type instead of Record Type of case - PC-1701
                         */
                        docObj = checkDocumentLog(documentLogAssociationIdMap, documentId, c.Id, c.CaseNumber, PC_Constants.LINK_ASSOCIATION_TYPE_PROGRAM, c.Type);
                        toInsertDocumentLogList.add(docObj);
                    }
                }
                
                //link document to coverage records
                for (ProgramCoverageWrapper pcw : programCoverageWrapperList) {
                    if (pcw.coverageList != null && pcw.coverageList.size() > 0) {
                        PC_Document_Log__c docObj;
                        for(CoverageWrapper cWrapper : pcw.coverageList) {
                            if(cWrapper.isChecked) {
                                docObj = checkDocumentLog(documentLogAssociationIdMap, documentId, cWrapper.covRec.id, cWrapper.covRec.Name, PC_Constants.LINK_ASSOCIATION_TYPE_COVERAGE, PC_Constants.LINK_ASSOCIATION_TYPE_COVERAGE);
                                toInsertDocumentLogList.add(docObj);
                            }
                        }
                    }
                }
                
                //link to document to account
                if (accountList != null && accountList.size() > 0) {
                    PC_Document_Log__c docObj;
                    for(Account a : accountList) {
                        docObj = checkDocumentLog(documentLogAssociationIdMap, documentId, a.Id, a.Name, PC_Constants.LINK_ASSOCIATION_TYPE_PATIENT, 'Account: '+ a.RecordType.Name);
                        toInsertDocumentLogList.add(docObj);
                    }
                }
                
                //link document to Adverse Event records
                if (adverseEventsList != null && adverseEventsList.size() > 0) {
                    PC_Document_Log__c docObj;
                    for(PC_AdverseEvent__c ae : adverseEventsList) {
                        docObj = checkDocumentLog(documentLogAssociationIdMap, documentId, ae.Id, ae.Name, PC_Constants.LINK_ASSOCIATION_TYPE_ADVERSE_EVENT,PC_Constants.LINK_ASSOCIATION_TYPE_ADVERSE_EVENT);
                        toInsertDocumentLogList.add(docObj);
                    }
                }

                //link document to Adverse Event 2 records
                if (adverseEvents2List != null && adverseEvents2List.size() > 0) {
                    PC_Document_Log__c docObj;
                    for(PC_AdverseEvent2__c ae2 : adverseEvents2List) {
                        docObj = checkDocumentLog(documentLogAssociationIdMap, documentId, ae2.Id, ae2.Name, PC_Constants.LINK_ASSOCIATION_TYPE_ADVERSE_EVENT2,PC_Constants.LINK_ASSOCIATION_TYPE_ADVERSE_EVENT2);
                        toInsertDocumentLogList.add(docObj);
                    }
                }
                
                //link document to Interaction records
                if (interactionsList != null && interactionsList.size() > 0) {
                    PC_Document_Log__c docObj;
                    for(PC_Interaction__c i : interactionsList) {
                        docObj = checkDocumentLog(documentLogAssociationIdMap, documentId, i.Id, i.Name, PC_Constants.LINK_ASSOCIATION_TYPE_INTERACTION,PC_Constants.LINK_ASSOCIATION_TYPE_INTERACTION);
                        toInsertDocumentLogList.add(docObj);
                    }
                }
            }
            
            if(toInsertDocumentLogList != null && toInsertDocumentLogList.size() > 0) {
            	fields = new List<String> {PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Constants.getQualifiedAPIName('PC_Program__c'),
            								PC_Constants.getQualifiedAPIName('PC_Coverage__c'), PC_Constants.getQualifiedAPIName('PC_Adverse_Event__c'),
            								PC_Constants.getQualifiedAPIName('PC_Interaction__c'), PC_Constants.getQualifiedAPIName('PC_Account__c'),
            								PC_Constants.getQualifiedAPIName('PC_Association_Record_ID__c'), PC_Constants.getQualifiedAPIName('PC_Association_Record_Name__c')};
        		PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document_Log__c'),PC_Database.Operation.Updating, fields);
                PC_Database.ups(toInsertDocumentLogList);
                //Extending method to set the status of linked document to 'In review' 
                if(documentId != null) {
                	fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Document_Status__c')};
                    PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'),PC_Database.Operation.Reading, fields);
            		PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'),PC_Database.Operation.Updating, fields);
                    PC_Document__c docObj = [select Id, PC_Document_Status__c from PC_Document__c where Id=:documentId];
                    if(docObj != null) { 
                        if(docObj.PC_Document_Status__c == PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED) {
                            docObj.PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_IN_REVIEW;
                        }                    
                        PC_Database.upd(docObj);
                    }        
                }
            }
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }

    /*********************************************************************************
    Method Name    : getAdverseEventObjectInUse
    Author         : Hitha Avalakki
    Description    : This method is used to get the Adverse Event Object in use.
    Return Type    : String
    Parameter      :
    *********************************************************************************/
    @AuraEnabled
    public static String getAdverseEventObjectInUse(){
        String adverseEventObjectName;
        try {
            List<PC_Patient_Connect_Setting__mdt> patientConnectSettingList = [
                    SELECT Id, PC_SettingName__c,PC_SettingValue__c
                    FROM PC_Patient_Connect_Setting__mdt
                    WHERE PC_SettingName__c = 'PC_AdverseEventObjectInUse' AND PC_Active__c = :PC_Constants.TRUE_BOOLEAN
            ];

            if (patientConnectSettingList != null && !patientConnectSettingList.isEmpty()) {
                adverseEventObjectName = patientConnectSettingList[0].PC_SettingValue__c;
            }
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return adverseEventObjectName;
    }

    /*********************************************************************************
    Method Name    : checkDocumentLog
    Author         : Tetiana Danylyshyn
    Description    : This method retrieve patient name
    Return Type    : Account
    Parameter      : documentLogAssociationIdMap - list of existed documentLogs,
                     documentId - Id of the document, 
                     recordId - Id of record to which document is going to be linked,
                     recordName - name of record to which document is going to be linked,
                     recordType - type of record (Coverage, Program, Adverse Event, Interaction)
    *********************************************************************************/
    private static PC_Document_Log__c checkDocumentLog(Map<Id,PC_Document_Log__c> documentLogAssociationIdMap, Id documentId, Id recordId, String recordName, String recordType,String defaultRecType) {
        PC_Document_Log__c docObj = new PC_Document_Log__c();
        docObj.id = (documentLogAssociationIdMap!=null && documentLogAssociationIdMap.containsKey(recordId)) ? documentLogAssociationIdMap.get(recordId).id : null;
        docObj.PC_Document_Log__c = (documentLogAssociationIdMap!=null && documentLogAssociationIdMap.containsKey(recordId))? documentLogAssociationIdMap.get(recordId).PC_Document_Log__c : null;
        if(docObj.id == null){
            docObj.PC_Document__c = documentId;
            docObj.PC_Program__c = (recordType == PC_Constants.LINK_ASSOCIATION_TYPE_PROGRAM) ? recordId : null;
            docObj.PC_Coverage__c = (recordType == PC_Constants.LINK_ASSOCIATION_TYPE_COVERAGE) ? recordId : null;
            docObj.PC_Adverse_Event__c = (recordType == PC_Constants.LINK_ASSOCIATION_TYPE_ADVERSE_EVENT) ? recordId : null;
            docObj.PC_Adverse_Event2__c = (recordType == PC_Constants.LINK_ASSOCIATION_TYPE_ADVERSE_EVENT2) ? recordId : null;
            docObj.PC_Interaction__c = (recordType == PC_Constants.LINK_ASSOCIATION_TYPE_INTERACTION) ? recordId : null;
            docObj.PC_Account__c = (recordType == PC_Constants.LINK_ASSOCIATION_TYPE_PATIENT) ? recordId : null;
            docObj.PC_Association_Record_ID__c = recordId;
            docObj.PC_Association_Record_Name__c = recordName;
            docObj.PC_Association_Type__c = defaultRecType;
        }
        return docObj;
    }

    /*********************************************************************************
    Class Name    : ProgramCoverageWrapper
    Author        : Tetiana Danylyshyn
    Description   : Wrapper class for coverage and programId
    *********************************************************************************/
    public inherited sharing class ProgramCoverageWrapper {
        @AuraEnabled public String idProgram {get; set;}
        @AuraEnabled public List<CoverageWrapper> coverageList {get; set;}
        @AuraEnabled public String programNumber {get; set;}
    }

    /*********************************************************************************
    Class Name    : CoverageWrapper
    Author        : Tetiana Danylyshyn
    Description   : Wrapper class for coverage
    *********************************************************************************/
    public inherited sharing class CoverageWrapper {
        @AuraEnabled public PC_Program_Coverage__c covRec {get; set;}
        @AuraEnabled public Boolean ischecked {get; set;}
    }
    
    /*********************************************************************************
    Class Name    : AccountWrapper
    Author        : Prachi Nandgaonkar
    Description   : Wrapper class for Account
    *********************************************************************************/
    public inherited sharing class AccountWrapper {
        @AuraEnabled public Id AccId{get; set;}
        @AuraEnabled public String AccLastName{get; set;}
        @AuraEnabled public String AccFirstName{get; set;}
        @AuraEnabled public String AccName{get; set;}
        @AuraEnabled public String AccType{get; set;}
        @AuraEnabled public Date AccDoB{get; set;}
        @AuraEnabled public String AccStatus{get; set;}
        @AuraEnabled public String AccAddr{get; set;}
        @AuraEnabled public String AccCity{get; set;}
        @AuraEnabled public String AccState{get; set;}
        @AuraEnabled public String AccZipCode{get; set;}
        @AuraEnabled public String isSelected{get; set;}
        
        
        public AccountWrapper(Account a) {
            this.AccId = a.Id;
            this.AccLastName = a.PC_Last_Name__c;
            this.AccFirstName = a.PC_First_Name__c;
            this.AccName = a.Name;
            this.AccType = a.Type;
            this.AccDoB = a.PC_Date_of_Birth__c;
            this.AccStatus = a.PC_Status__c;
            this.AccAddr = a.PC_Primary_Address_1__c;
            this.AccCity = a.PC_Primary_City__c;
            this.AccState = a.PC_Primary_State__c;
            this.AccZipCode = a.PC_Primary_Zip_Code__c;
            this.isSelected = PC_Constants.FALSE_STRING;
            
        }
    }
}