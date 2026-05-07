/*******************************************************************************
 Modification Log:
 -------------------------------------------------------------------------------
 Developer              Date            Description
 -------------------------------------------------------------------------------
 Ajinkya Deshmukh       1/11/2017       Initial Version
 Prachi Nandgaonkar     2/16/2017       Updated documentSplitCallout() to handle scenario if parent document is deleted immediately after split has been executed [PC-1171]
 Tejas Patel			4/12/2017       Repalced DML update with PC_Database.upd
 Ajinkya Deshmukh		6/21/2017       FLS Check Added (Code Merge)
 Ajinkya Deshmukh       6/22/2017       [PC-1797] Added Null check in response if block
 Ajinkya Deshmukh       6/27/2017       with sharing keyword added
 Mayuresh Patil         6/29/2017       PC-1860 Refresh (F5) on the browser is removing the Child attachment documents if a Parent Email Inbounding document is Split.
 Mayuresh Patil         7/07/2017       PC-1867 Remove hardcoding of the Integration serive name.
 Mayuresh Patil         9/07/2017       PC-2193 FLS Check updated to new PC303 code
 Mike Klumpenaar        2/24/2019       PC-4474 Added implementation of PC_Document.Splitter interface
 Shishir Bansal         6/17/2019       PC-4913 Support Document Split Feature for both Attachments and Files
 Kishore Kanteti        5/21/2021       [PC-7739] Used method convertRangeToNumbers() to convert Range to Numbers for PC_Sorted_Parent_Pg_Num__c
 ******************************************************************************/

/**
 * Performs a callout to an HTTP endpoint using basic authentication based on the
 * configuration settings in PC_Integration_Settings__c for the PC_Document_Split_Service
 * record.
 * <p>
 * The body of the callout will include a JSON message with the following structure:
 * <pre>
 *   {
 *       "parentDocId": "&lt;Id of parent doc&gt;",
 *       "parentAttachmentId": "&lt;Id of parent doc attachment&gt;",
 *       "parentFileName": "&lt;[filename of parent doc attachment&gt;",
 *       "orgId": "&lt;Id of org that callout is initiated from&gt;",
 *       "userId": "&lt;user Id of user initiating callout&gt;",
 *       "correlationId": "&lt;value from the doc PC_CorrelationId__c field&gt;",
 *       "documentGroupings": [
 *           {
 *               "documentId": "&lt;Id of child doc&gt;",
 *               "pages": [&lt;parent first page&gt;, &lt;parent second page&gt;, ...]
 *           }
 *       ]
 *   }
 * </pre>
 *
 * The service that receives the call is expected to be able to perform a callback
 * to the org identified by <orgId> and retrieved the file attachment based on
 * <parentAttachmentId>. It then needs to split the attachment into separate files
 * based on the page ranges defined in the document groupings and created new attachments
 * for the corresponding child documents.
 * <p>
 * The correlation Id should be used to ensure that the service is still fulfilling the
 * most recent split request initiated by the server. If the correlation Id of the request
 * and the current value on the server do not match, then the request should be abandoned.
 * <p>
 * Upon successful splitting and creation of attachments on each child doc, the child doc
 * status should be updated to 'Complete and Ready for Use'. Otherwise, it should be updated
 * to 'Split Failure'.
 * .
 */
public with sharing class PC_DocumentSplitWebservice implements PC_Document.Splitter {
    /**
     * Performs an HTTP callout to initiate document splitting in an external service.
     *
     * @param parentDoc The document to split with a Id and PC_Correlation__c
     * @param childDocs The child documents to create attachments for with Id and PC_Sorted_Parent_Pg_Num__c
     */
    public void splitDocument(PC_Document__c parentDoc, PC_Document__c[] childDocs) {
        Map<String, PC_Integration_Settings__c> mapIntegrationSettings = PC_Integration_Settings__c.getAll();
        PC_Integration_Settings__c splitServiceSettings = mapIntegrationSettings.get(PC_Constants.DOCUMENT_SPLIT_SERVICE);



        if (splitServiceSettings == null) {
            throw new PC_Document.SplitException('Missing PC_Integration_Settings__c record for: ' + PC_Constants.DOCUMENT_SPLIT_SERVICE);
        } else if (String.isBlank(splitServiceSettings.endpoint_Url__c)) {
            throw new PC_Document.SplitException('Missing endpoint_Url__c for ' + PC_Constants.DOCUMENT_SPLIT_SERVICE);
        }

        // generate json body string
		String jsonBody = generateJson(parentDoc, childDocs);
        splitDocumentCallout(
                splitServiceSettings.endpoint_Url__c, jsonBody,
                splitServiceSettings.username__c, splitServiceSettings.password__c);
	}
    /**
     * Future HTTP callout to remote service. If the service response is anything other than 200 the status of the
     * parent and all child docs is updated to Split Failure.
     *
     * @param body
     */
    @future(callout=true)
    public static void splitDocumentCallout(String endpoint, String body, String username, String password) {
        HttpResponse response;

        try {
            response = PC_WebserviceCallout.callout('POST', endpoint, body, username, password);
        } catch (Exception ex) {
            PC_Utility.createExceptionLog(ex);
        }

        if (response != null && response.getStatusCode() != 200) {
            Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(body);

            Id parentDocId = (Id) requestMap.get('parentDocId');
            PC_Document__c parentDoc = new PC_Document__c(
                    Id = parentDocId, PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_SPLIT_FAILURE);

            List<PC_Document__c> childDocs = new List<PC_Document__c>();
            List<Object> childDocObjects = (List<Object>) requestMap.get('documentGroupings');
            for (Object childDocObject : childDocObjects) {
                Map<String, Object> childDocMap = (Map<String, Object>) childDocObject;
                Id childDocId = (Id) childDocMap.get('documentId');
                PC_Document__c childDoc = new PC_Document__c(
                        Id = childDocId, PC_Document_Status__c = PC_Constants.DOCUMENT_STATUS_SPLIT_FAILURE);
                childDocs.add(childDoc);
            }

            PC_Database.upd(parentDoc, false);
            PC_Database.upd(childDocs, false);
        }

    }

    /**
     * Generates the JSON request body.
     */
	public static String generateJson(PC_Document__c parentDoc, PC_Document__c[] childDocs) {

        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();

        Boolean useSalesforceFiles  = PC_SYSTEM.useSalesforceFiles();

        if(useSalesforceFiles) {

            // single query

            List<ContentDocumentLink> listContentDocumentLink =[SELECT ContentDocumentId, Id FROM ContentDocumentLink WHERE LinkedEntityId  =:parentDoc.Id];

            if(listContentDocumentLink.size()>0) {
                List<ContentDocument> listContentDocuments = [SELECT Id, Title FROM ContentDocument WHERE Id = :listContentDocumentLink[0].ContentDocumentId];
                if (listContentDocuments.size() == 0) {
                    throw new PC_Document.SplitException('Document without files cannot be split: ' + parentDoc.Id);
                }


                gen.writeStringField('parentAttachmentId', listContentDocuments[0].Id);
                gen.writeStringField('parentFileName', listContentDocuments[0].Title);
            }
            else{
                throw new PC_Document.SplitException('Document without files cannot be split: ' + parentDoc.Id);
            }
        }
        else{

            List<Attachment> docAttachment = [SELECT Id, Name FROM Attachment WHERE ParentId = :parentDoc.Id];
            if (docAttachment.size() == 0) {
                throw new PC_Document.SplitException('Document without attachment cannot be split: ' + parentDoc.Id);
            }
            gen.writeStringField('parentAttachmentId', docAttachment[0].Id);
            gen.writeStringField('parentFileName', docAttachment[0].Name);

        }

        gen.writeStringField('parentDocId', parentDoc.Id);
        gen.writeStringField('orgId', UserInfo.getOrganizationId());
        gen.writeStringField('userId', UserInfo.getUserId());
        gen.writeStringField('correlationId', parentDoc.PC_Correlation_Id__c);
        gen.writeFieldName('documentGroupings');
        gen.writeStartArray();
        for (PC_Document__c childDoc : childDocs){
            gen.writeStartObject();
            gen.writeStringField('documentId', childDoc.Id);
            gen.writeObjectField('pages', stringToIntList(PC_Utility.convertRangeToNumbers(childDoc.PC_Sorted_Parent_Pg_Num__c)));
            gen.writeEndObject();
        }

        gen.writeEndArray();
        gen.writeEndObject();

        return gen.getAsString();
    }

	/**
	 * Converts the comma separated string of page numbers to a List of Integers.
	 */
	private static List<Integer> stringToIntList(String sortedString){
        String[] items = sortedString.split(',');
        List<Integer> result = new List<Integer>();
        for (String item : items) {
            result.add(Integer.valueOf(item.trim()));
        }
        return result;
    }
}