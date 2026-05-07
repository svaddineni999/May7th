/*************************************************************************************************************************************
Class Name      : ACLS_DocumentSplitQueueable
Description     : Handler class for Document Split functionality
Created Date    : April 07, 2023
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------
Nandita Vyas            April 07, 2023             Initial Version - US-915/915
****************************************************************************************************************************************************/

public with sharing class ACLS_DocumentSplitQueueable implements Queueable,Database.AllowsCallouts {
    @testvisible private static HttpResponse res;
    public static final String CLASSNAME = 'ACLS_DocumentSplitQueueable';
    private PC_Document__c parentDoc;
    private List<PC_Document__c> childDocs;
    private Boolean isError;
    List<PC_Remote_Service_Log__c> lstRemoteServiceLogs;
    Map<Id, PC_Document__c> mapIdVsDoc;

    /********************************************************************************************************************
    Method Name    : ACLS_DocumentSplitQueueable
    Description    : Constructor to initialize variables
    Parameter      : PC_Document__c parentDoc,List<PC_Document__c> childDocs
    *********************************************************************************************************************/
    public ACLS_DocumentSplitQueueable(PC_Document__c parentDoc,List<PC_Document__c> childDocs){
        this.parentDoc = parentDoc;
        this.childDocs = childDocs;
        this.isError = false;
        this.lstRemoteServiceLogs = new List<PC_Remote_Service_Log__c>();
        this.mapIdVsDoc = new Map<Id, PC_Document__c>();
    }

    /********************************************************************************************************************
    Method Name    : execute
    Description    : perform operations to make callout and get splitted contentDocumentId
    Return Type    : void
    Parameter      : QueueableContext context
    *********************************************************************************************************************/
    public void execute(QueueableContext context) {
        try{
            //Set the status of the parent and all the child documents as Split Failure
            mapIdVsDoc = getDocumentStatus();

            //Get the Integration Configurations to perform Document Split
            ACLS_IntegrationConfig__mdt splitAPIDetails = ACLS_Utility.getIntegrationConfigs(ACLS_Constants.HC_SPLIT, ACLS_Utility.getCurrentEnvironment());
            
            if(splitAPIDetails!=null){
                Map<Id, ContentDocumentLink> mapParentVsCDL = ACLS_Utility.getContentDocumentLink(new List<Id>{parentDoc.Id});
                System.debug('parentDoc.Id '+parentDoc.Id);
                String ContentDocumentId =  (mapParentVsCDL!=null)? mapParentVsCDL.get(parentDoc.Id)?.ContentDocumentId : null;
                
                Map<String, String> mapHeader = (Map<String,String>) JSON.deserialize(splitAPIDetails.ACLS_Headers__c, Map<String,String>.class); 
                mapHeader.put(ACLS_Constants.AUTHORIZATION, (mapHeader?.get(ACLS_Constants.AUTHORIZATION)) + UserInfo.getSessionId());

                
                if(ContentDocumentId!=null){
                    
                    for(PC_Document__c objChild : childDocs){
                        if(Limits.getCallouts() > Limits.getLimitCallouts()){ 
                            objChild.PC_Document_Status__c = ACLS_Constants.SPLIT_FAILURE;
                            parentDoc.PC_Document_Status__c = ACLS_Constants.SPLIT_FAILURE;
                            mapIdVsDoc.put(objChild.Id,objChild);
                            mapIdVsDoc.put(parentDoc.Id,parentDoc);
                        }
                        else{
                            String endpoint = splitAPIDetails?.ACLS_Endpoint__c?.replace('{ContentDocumentId}', ContentDocumentId)?.replace('{LinkedEntityId}',objChild.Id);
                            
                            //Get the request body
                            String splitRequestBody = getRequestBody(objChild);
                            String ipName = splitAPIDetails.ACLS_Integration_Procedure_Name__c;
                            //perform the callout
                            //HttpResponse res = ACLS_Http_RequestResponse_Util.handleHTTPCallouts(ACLS_Constants.METHOD_POST, mapHeader, splitAPIDetails.ACLS_BaseURL__c + endpoint, splitRequestBody, Integer.valueOf(splitAPIDetails.ACLS_Timeout__c), null);
		                    //HttpResponse res = new HttpResponse();
                            if(!Test.isRunningTest()) {
                             res = ACLS_IP_Callouts_Utility.makeCalloutFromIP(splitAPIDetails.ACLS_BaseURL__c + endpoint,splitRequestBody,mapHeader,null, 120000,ipName);
                             System.debug('res '+res);
        }
                           
                            
                            //create remote service log record
                            createRemoteServiceLog(splitRequestBody, splitAPIDetails.ACLS_BaseURL__c + endpoint, res);
                            System.debug('Success Res --- '+res.getBody());
                            if(res!=null){
                                ACLS_DocumentSplit_IntegrationWrappers.SplitResponse responseWrapper = (ACLS_DocumentSplit_IntegrationWrappers.SplitResponse)JSON.deserialize(res.getBody(), ACLS_DocumentSplit_IntegrationWrappers.SplitResponse.class);
                                if(res.getStatusCode() == 201 && responseWrapper.isSuccess){
                                    System.debug('Success Response Get bOdy --- '+res.getBody());
                                    objChild.PC_Document_Status__c  = ACLS_Constants.REVIEW_NEEDED ;
                                    mapIdVsDoc.put(objChild.Id,objChild);
                                }
                                else{
                                    System.debug('Fail Response Get bOdy --- '+res.getBody());
                                    isError = true;
                                }  
                            }
                            else{
                                System.debug('Fail Response --- '+res.getBody());
                                isError = true;
                            }
                        }
                    }
                }
                else{
                    parentDoc.PC_Document_Status__c = ACLS_Constants.SPLIT_FAILURE;
           			mapIdVsDoc.put(parentDoc.Id,parentDoc);
                    ACLS_Utility.createINTErrorLogs(null, Label.ACLS_Split_Error, '', 'No Attachment is available under the Parent Document', '', CLASSNAME, '', parentDoc.Id);
                }
                parentDoc.PC_Document_Status__c = (!isError)? ACLS_Constants.COMPLETE_STATUS : ACLS_Constants.SPLIT_FAILURE;
                mapIdVsDoc.put(parentDoc.Id,parentDoc);
            }
            else{
                parentDoc.PC_Document_Status__c = ACLS_Constants.SPLIT_FAILURE;
            	mapIdVsDoc.put(parentDoc.Id,parentDoc);
                ACLS_Utility.createINTErrorLogs(null, ACLS_Constants.HC_SPLIT_ERRORLOG1, '', ACLS_Constants.HC_SPLIT_ERRORLOG2, '', CLASSNAME, '', parentDoc.Id);
            }

            if(isError){
                parentDoc.PC_Document_Status__c = ACLS_Constants.SPLIT_FAILURE;
            	mapIdVsDoc.put(parentDoc.Id,parentDoc);
                ACLS_Utility.createINTErrorLogs(null, Label.ACLS_Split_Error, '', 'Response received is null', '', CLASSNAME, '', parentDoc.Id);
            }
            update mapIdVsDoc.values();
            if(Schema.sObjectType.PC_Remote_Service_Log__c.isCreateable()){
				PC_Database.ins(this.lstRemoteServiceLogs);
            }
        }
        catch(Exception ex){
            parentDoc.PC_Document_Status__c = ACLS_Constants.SPLIT_FAILURE;
            mapIdVsDoc.put(parentDoc.Id,parentDoc);
            if(Schema.sObjectType.PC_Document__c.isUpdateable()){
			update mapIdVsDoc.values();
			}

            ACLS_Utility.createINTErrorLogs(ex, '', '', Label.ACLS_Split_Error, '', CLASSNAME, '', parentDoc.Id);
            //throw new PC_Document.SplitException(Label.ACLS_Split_Error);
        }
    }

    /********************************************************************************************************************
    Method Name    : createRemoteServiceLog
    Description    : Create instance of Remote service logs
    Return Type    : void
    Parameter      : String splitRequestBody, String endPoint, HttpResponse res
    *********************************************************************************************************************/
    public void createRemoteServiceLog(String splitRequestBody, String endPoint, HttpResponse res){
        PC_Remote_Service_Log__c splitDocumentRSL = PC_RemoteServiceLogHandler.getRemoteServiceLog(ACLS_Constants.HC_SPLIT, endPoint, splitRequestBody, res?.getBody(), 'Callout made to perform Document Split', PC_Constants.REMOTE_SERVICE_TYPE_OUTBOUND);
        splitDocumentRSL.PC_StatusCode__c = (res!=null)? String.valueOf(res.getStatusCode()) : '';
        this.lstRemoteServiceLogs.add(splitDocumentRSL);
    }
    
    /********************************************************************************************************************
    Method Name    : getRequestBody
    Description    : prepares the request body for the split Api. Page number format example : 1,2-3,5,7-9,10-11,14
    Return Type    : String
    Parameter      : PC_Document__c objChild
    *********************************************************************************************************************/
    public String getRequestBody(PC_Document__c objChild){
        Set<Integer> pageNumbers = new Set<Integer>();
        
        for(String pageNum : objChild.PC_Sorted_Parent_Pg_Num__c?.split(',')){
            if(!pageNum.contains('-')){                                         //When Page number is a single digit. example - 5
                pageNumbers.add(Integer.valueOf(pageNum));
            }else{
                List<String> pageRange = pageNum.split('-');                    //When Page number is a range. example - 5-9
                if(pageRange!=null && !pageRange.isEmpty()){
                    for(Integer i = Integer.valueOf(pageRange[0]); i<=Integer.valueOf(pageRange[1]); i++){
                        pageNumbers.add(i);
                    }
                }
            }
        }
        
        List<ACLS_DocumentSplit_IntegrationWrappers.PageSpecifications> pgList = new List<ACLS_DocumentSplit_IntegrationWrappers.PageSpecifications>();
        
        for(Integer page: pageNumbers){
            ACLS_DocumentSplit_IntegrationWrappers.PageSpecifications pageFile = new ACLS_DocumentSplit_IntegrationWrappers.PageSpecifications(page, 0, true);
            pgList.add(pageFile);
        }
        
        ACLS_DocumentSplit_IntegrationWrappers.PageSpecificationList pageSpec = new ACLS_DocumentSplit_IntegrationWrappers.PageSpecificationList(pgList);
        ACLS_DocumentSplit_IntegrationWrappers.SplitRequest requestBody = new ACLS_DocumentSplit_IntegrationWrappers.SplitRequest(pageSpec, false);
        return JSON.serialize(requestBody);
    }

    /********************************************************************************************************************
    Method Name    : getDocumentStatus
    Description    : Prepares a map for document and set the status as Split Failure
    Return Type    : Map<Id, PC_Document__c> mapIdVsDoc
    Parameter      : none
    *********************************************************************************************************************/
    public Map<Id, PC_Document__c> getDocumentStatus(){
        for(PC_Document__c doc: childDocs){
            doc.PC_Document_Status__c = ACLS_Constants.SPLIT_FAILURE;
            mapIdVsDoc.put(doc.Id, doc);
        }

        parentDoc.PC_Document_Status__c = ACLS_Constants.SPLIT_FAILURE;
        mapIdVsDoc.put(parentDoc.Id, parentDoc);

        return mapIdVsDoc;
    }
}