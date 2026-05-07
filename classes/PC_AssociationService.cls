/************************************************************************************************************************************
Class Name      : PC_AssociationService
Description     : REST class for Association object
Created By      : Deloitte
Created Date    : Jan 17, 2019
Modification Log:
---------------------------------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
---------------------------------------------------------------------------------------------------------------------------------------
Shishir Bansal                 Jan 17, 2019           Initial Version
Xiukai Ning                    Jan 24, 2019           [PC-4230] added method doPut

******************************************************************************************************************************************/
/**
 * REST API class to create, update and delete Associations. Please refer Rest API Documentation for usage.
 */
@RestResource(urlMapping='/1.0/association/*')
global with sharing class PC_AssociationService {

    static final string ASSOCIATION_KEY = 'association';
    static final string ASSOCIATION_PROGRAM_CASE_ID_KEY = 'programId';

    @HttpPost
    global static void doPost()
    {
        processAssociationUpsert(PC_RestAPIConstants.ObjectOperation.oInsert);
    }

    @HttpPut
    global static void doPut()
    {
        processAssociationUpsert(PC_RestAPIConstants.ObjectOperation.oUPDATE);
    }

    @HttpDelete
    global static void doDelete()
    {
        processAssociationDelete(PC_RestAPIConstants.ObjectOperation.oDELETE);
    }

    private static void processAssociationUpsert(PC_RestAPIConstants.ObjectOperation operation)
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        Blob reqBlob = req.requestBody;
        string reqString = reqBlob.toString();

        Map<string, object> associationInfo;
        string programId;
        List<Object> reqAssociationsObjList = new List<Object>();
        Map<string, object> rsBodyList = new  Map<string, object>();
        List<string> associationIds = new List<string>();
        try
        {
            // Convert request info as Map
            associationInfo = (Map<string, object>)JSON.deserializeUntyped(reqString);


            programId = String.valueOf(associationInfo.get(ASSOCIATION_PROGRAM_CASE_ID_KEY));
            reqAssociationsObjList.add(associationInfo);
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT) {
                reqAssociationsObjList = PC_RestAPIUtilities.removeIdField(reqAssociationsObjList);
            }

            List<object> reqAssociationsObjListTrans = PC_RestAPIUtilities.transformRESTObjects(reqAssociationsObjList, PC_RestAPIConstants.REST_OBJECT_NAME_ASSOCIATION);

            associationIds = PC_RestAPIUtilities.upsertAssociations(reqAssociationsObjListTrans, programId, operation);

            if (associationIds !=null || !associationIds.isEmpty() ) {
                rsBodyList.put(ASSOCIATION_KEY, associationIds[0]);
                res.responseBody = Blob.valueOf(JSON.serialize(rsBodyList));
            }
            else{
               throw new PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.NO_RESULTS),string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT),PC_RestAPIConstants.ERRORMESSAGE_ASSOCIATION_UNEXPECTED_ERROR);
            }

        }
        catch(Exception e)
        {

            PC_RestAPIUtilities.exceptionHandler(req, res, e, reqString);
        }
    }

    private static void processAssociationDelete(PC_RestAPIConstants.ObjectOperation operation)
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = 202;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        Map<string, object> rsBodyList = new  Map<string, object>();
        string associationId;
        associationId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
        associationId = string.escapeSingleQuotes(associationId);
        try{
            if(string.isBlank(associationId)){
                throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.MANDATORY_FIELDS_MISSING), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_ID_MISSING);
            }else if( !(associationId instanceof Id)){
                throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), string.valueOf(PC_RestAPIConstants.ErrorType.APPLICATION), PC_RestAPIConstants.INVALID_ASSOCIATION_ID);
            }else if(!associationId.startsWith(PC_Association__c.sObjectType.getDescribe().getKeyPrefix())){
                throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.INVALID_ARGUMENTS), string.valueOf(PC_RestAPIConstants.ErrorType.APPLICATION), PC_RestAPIConstants.INVALID_ASSOCIATION_ID);
            }else if(associationId.startsWith(PC_Association__c.sObjectType.getDescribe().getKeyPrefix())){
                PC_Association__c association = PC_RestAPIUtilities.deleteAssociationById(associationId);
                //If same Association Id is requested for deletion twice, the PC_Database class throws general exception handled in catch block
                if(association != null){
                    rsBodyList.put(PC_RestAPIConstants.RESPONSE_MESSAGE_KEY, 'Association record was successfully deleted.');
                    res.responseBody = Blob.valueOf(JSON.serialize(rsBodyList));
                }
            }
        }catch(Exception e){
            PC_RestAPIUtilities.exceptionHandler(req, res, e, PC_Constants.EMPTY_STRING);
        }
    }

}