/*********************************************************************************************************
Trigger Name    : PC_Trigger_Document
Description     : trigger on PC_Applicant__c object.
Created By      : Tetiana Danylyshyn
Created Date    : June 1, 2016
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#      	Date                   	Description
--------------------------------------------------------------------------------------------------------------
Tetiana Danylyshyn            	June 1, 2016          	Initial Version
Shabda Bhujad,        		  	Nov 4, 2016				Removed PC_Brand__c,  PC_Country__c field(Document Object)references annotated by @@RemoveBranCntryRef
Prachi Nandgaonkar
Shabda Bhujad					Dec 06, 2016			Added FLS check to attachGeneratedPDF methods
Ajinkya Deshmukh				March 30, 2017			Added afterDelete and afterInsert method. Updated updateParentDocumentStatus to handle scenario (PC-1053, PC-1345)
Mayuresh Patil                  June 27, 2017           PC-1668 Parent Doc status for Inbound emails with attachment should not be archived (should be review needed)
Mayuresh Patil                  Sep 07, 2017            PC-2193 FLS Check updated to new PC303 code
Shabda Bhujad                   Nov 14, 2017            PC-2485 Removing the reference to trigger state
Xiukai Ning                     Feb 28, 2019            PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                        Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                        We are removing all FLS and With Sharing keywords in the handlers.
Haritha Reddy                   May 05,2020             [PC-6249] Added limit to the inner SOQL query
Haritha Reddy                   21-Jan-2021             [PC-7102] Added FLS Check
Satheesh Kumar                  Nov 16, 2021            [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_Trigger_Document extends PC_TriggerHandler {

    override public void afterInsert() {
        updateParentDocumentStatus((List<PC_Document__c>) newList);
    }
    
    override public void afterUpdate() {
        updateParentDocumentStatus((List<PC_Document__c>) newList);
    }

    override public void afterDelete() {
        updateParentDocumentStatus((List<PC_Document__c>) oldList);
    }

    private void updateParentDocumentStatus(List<PC_Document__c> documents) {
        Set<Id> parentDocumentIds = new Set<Id>();
        Map<Id, List<PC_Document__c>> mapParentIdToChildDocs = new Map<Id, List<PC_Document__c>>();
        Map<Id, String> mapParentIdToNewStatus = new Map<Id,String>();
		Map<Id, String> mapParentIdToOldStatus = new Map<Id,String>();
        List<PC_Document__c> listDocumentToUpdate = new List<PC_Document__c>();
        List<PC_Document__c> allChildDocs = new List<PC_Document__c>();
        String queryString;

        // get all parent document ids
        for(PC_Document__c eachDocument : documents) {
            if(String.valueOf(eachDocument.PC_Parent_Document__c) != PC_Constants.EMPTY_STRING && eachDocument.PC_Parent_Document__c != NULL) {
                parentDocumentIds.add(String.valueOf(eachDocument.PC_Parent_Document__c));
            }
        }
        //FLS is NOT needed in Triggers, as they always run in System Mode.
        /*List<String> docFields = new List<String>{
                PC_Constants.getQualifiedAPIName('PC_Document_Status__c'),
                PC_Constants.getQualifiedAPIName('PC_Parent_Document__c')
        };
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, docFields);*/

        // get existing parent document status
		for (PC_Document__c eachDoc : [SELECT Id, PC_Document_Status__c FROM PC_Document__c WHERE Id IN: parentDocumentIds]) {
			mapParentIdToOldStatus.put(eachDoc.Id, eachDoc.PC_Document_Status__c);
		}
		
        // query to get all child documents
        queryString = 'SELECT Id, PC_Document_Status__c, PC_Parent_Document__c FROM PC_Document__c WHERE PC_Parent_Document__c IN: parentDocumentIds AND PC_IsSplit__c = true';
        if (trigger.isDelete) {
            queryString += ' AND Id NOT IN: documents';
            // query to handle no child document scenario
            List<PC_Document__c> allDocs =  [SELECT Id, (select Id from Documents__r LIMIT 2000) FROM PC_Document__c WHERE Id IN: parentDocumentIds];
            for (PC_Document__c eachDoc : allDocs) {
                if (eachDoc.Documents__r.size() == 0) {
                    mapParentIdToNewStatus.put(eachDoc.Id, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED);
                }
            }
        }

        // query to get all child docs
        allChildDocs = Database.query(queryString);

        // get all child document for parent document Id
        for(PC_Document__c eachDocument : allChildDocs) {
            if(!mapParentIdToChildDocs.containsKey(eachDocument.PC_Parent_Document__c)) {
                List<PC_Document__c> docList = new List<PC_Document__c>();
                docList.add(eachDocument);
                mapParentIdToChildDocs.put(eachDocument.PC_Parent_Document__c, docList);
            } else {
                mapParentIdToChildDocs.get(eachDocument.PC_Parent_Document__c).add(eachDocument);
            }
        }

        // iterate on parents
        for(Id parentId : mapParentIdToChildDocs.keySet()) {
            Map<String, Integer> mapChildStatusToCount = new Map<String, Integer>();

            // iterate on each child of a parent to get the status
            for (PC_Document__c childDoc : mapParentIdToChildDocs.get(parentId)) {
                if (!mapChildStatusToCount.containsKey(childDoc.PC_Document_Status__c)) {
                    mapChildStatusToCount.put(childDoc.PC_Document_Status__c, 1);
                } else {
                    integer count = mapChildStatusToCount.get(childDoc.PC_Document_Status__c);
                    mapChildStatusToCount.put(childDoc.PC_Document_Status__c, ++count);
                }
            }

            // check and assign the worst status
            if (mapChildStatusToCount.containsKey(PC_Constants.DOCUMENT_STATUS_SPLIT_FAILURE)) {
                mapParentIdToNewStatus.put(parentId, PC_Constants.DOCUMENT_STATUS_SPLIT_FAILURE);
            } else if (mapChildStatusToCount.containsKey(PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT)) {
                mapParentIdToNewStatus.put(parentId, PC_Constants.DOCUMENT_STATUS_READY_FOR_SPLIT);
            } else if (mapChildStatusToCount.containsKey(PC_Constants.DOCUMENT_STATUS_AWAITING_ATTACHMENT)) {
                mapParentIdToNewStatus.put(parentId, PC_Constants.DOCUMENT_STATUS_SPLIT_IN_PROGRESS);
            } else {
                Integer reviewNeededCount = (mapChildStatusToCount.containsKey(PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED) ? mapChildStatusToCount.get(PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED) : 0);
                Integer inReviewCount = (mapChildStatusToCount.containsKey(PC_Constants.DOCUMENT_STATUS_IN_REVIEW) ? mapChildStatusToCount.get(PC_Constants.DOCUMENT_STATUS_IN_REVIEW) : 0);
                // check if the status is either Review Needed or In Review
                system.debug('@@ mapParentIdToChildDocs '+mapParentIdToChildDocs.get(parentId));
                system.debug('@@ mapParentIdToNewStatus '+mapParentIdToNewStatus.get(parentId));
                if (mapParentIdToChildDocs.get(parentId).size() == (reviewNeededCount+inReviewCount) &&
                   	mapParentIdToOldStatus.get(parentId) != PC_Constants.DOCUMENT_STATUS_COMPLETED) {
						mapParentIdToNewStatus.put(parentId, PC_Constants.DOCUMENT_STATUS_ARCHIVED);
                }
            }
        }

        // set parent document status
        for(PC_Document__c eachDoc : [SELECT Id, PC_Document_Status__c FROM PC_Document__c WHERE Id IN: mapParentIdToNewStatus.keySet()]) {
            eachDoc.PC_Document_Status__c = mapParentIdToNewStatus.get(eachDoc.Id);
            listDocumentToUpdate.add(eachDoc);
        }

        // update operation
        if (listDocumentToUpdate.size() > 0) {
            try {
                PC_Database.upd(listDocumentToUpdate, false);
            } catch(Exception ex) {
                PC_Utility.createExceptionLog (ex);
            }
        }
    }
}