/*********************************************************************************************************
Class Name      : PC_ApplicantService
Description     : REST class for Applicant and otherObject object
Created By      : Deloitte
Created Date    : Aug 21, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar                 Aug 21, 2017           Initial Version
Subham Agarwal                 Nov 8, 2017            <PC-2468> - Review current API design and propose updates to framework
Vijay Kashikar                 Jan 11, 2018           <PC-2663> - Constants renamed.
****************************************************************************************************************/
/**
 * REST API class to create Applicants. Please refer Rest API Documentation for usage.
 */
@RestResource (urlMapping = '/1.0/applicant/*' )
global with sharing class PC_ApplicantService
{
    static final string PATIENT_KEY = 'patient';
    static final string APPLICANT_KEY = 'applicant';
    static final string ADDRESSES_KEY = 'addresses';
    static final string HEALTHPLANS_KEY = 'healthPlans';
    static final string PHYSICIAN_KEY = 'physician';
    static final string HCOs_KEY = 'hcos';
    @HttpPost
    global static void doPost()
    {
        processApplicantUpsert(PC_RestAPIConstants.ObjectOperation.oInsert);
    }
    private static void processApplicantUpsert(PC_RestAPIConstants.ObjectOperation operation)
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
        Blob reqBlob = req.requestBody;
        string reqString = reqBlob.toString();
        Map<string, object> applicantInfo;
        Savepoint sp = Database.setSavepoint();
        string requestURL;
        try
        {
            // Convert request info as Map
            applicantInfo = (Map<string, object>)JSON.deserializeUntyped(reqString);
            requestURL = PC_RestAPIUtilities.getRequestURL(req);
            Map<string, object> reqApplicant = (Map<string, object>)applicantInfo;
            List<object> reqApplicantAddressesObjList = new  List<object>();
            if(reqApplicant.containsKey(ADDRESSES_KEY))
            {
                reqApplicantAddressesObjList = (List<object>)reqApplicant.get(ADDRESSES_KEY);
                reqApplicant.remove(ADDRESSES_KEY);
            }
            List<object> reqApplicantHealthPlansObjList = new  List<object>();
            if(reqApplicant.containsKey(HEALTHPLANS_KEY))
            {
                reqApplicantHealthPlansObjList = (List<object>)reqApplicant.get(HEALTHPLANS_KEY);
                reqApplicant.remove(HEALTHPLANS_KEY);
            }
            /*
            List<Object> reqApplicantHCOsObjList = new List<Object>();
            if(reqApplicant.containsKey(HCOs_KEY)) {
            reqApplicantHCOsObjList = (List<Object>) reqApplicant.get(HCOs_KEY);
            reqApplicant.remove(HCOs_KEY);
            }

            Map<String, Object> reqPhysicianObj = new Map<String, Object>();
            if(reqApplicant.containsKey(PHYSICIAN_KEY)) {
            reqPhysicianObj = (Map<String, Object>) reqApplicant.get(PHYSICIAN_KEY);
            reqApplicant.remove(PHYSICIAN_KEY);
            }

            List<Object> reqPhysicianAddressesObjList = new List<Object>();
            if(reqPhysicianObj.containsKey(ADDRESSES_KEY)) {
            reqPhysicianAddressesObjList = (List<Object>) reqPhysicianObj.get(ADDRESSES_KEY);
            reqPhysicianObj.remove(ADDRESSES_KEY);
            }

            List<Object> reqPhysicianHealthPlansObjList = new List<Object>();
            if(reqPhysicianObj.containsKey(HEALTHPLANS_KEY)) {
            reqPhysicianHealthPlansObjList = (List<Object>) reqPhysicianObj.get(HEALTHPLANS_KEY);
            reqPhysicianObj.remove(HEALTHPLANS_KEY);
            }*/
            if(operation == PC_RestAPIConstants.ObjectOperation.oINSERT)
            {
                reqApplicant = PC_RestAPIUtilities.removeIdField(reqApplicant);
                reqApplicantAddressesObjList = PC_RestAPIUtilities.removeIdField(reqApplicantAddressesObjList);
                reqApplicantHealthPlansObjList = PC_RestAPIUtilities.removeIdField(reqApplicantHealthPlansObjList);
                //reqApplicantHCOsObjList = PC_RestAPIUtilities.removeIdField(reqApplicantHCOsObjList);
                //reqPhysicianObj = PC_RestAPIUtilities.removeIdField(reqPhysicianObj);
                //reqPhysicianAddressesObjList = PC_RestAPIUtilities.removeIdField(reqPhysicianAddressesObjList);
                //reqPhysicianHealthPlansObjList = PC_RestAPIUtilities.removeIdField(reqPhysicianHealthPlansObjList);
            }
            if(PC_RestAPIUtilities.validateMandatoryFieldsOfApplicant(reqApplicant))
            {
                Map<string, object> reqApplicantTrans = PC_RestAPIUtilities.transformRESTObject(reqApplicant, PC_RESTAPIConstants.REST_OBJECT_NAME_APPLICANT);
                List<object> reqApplicantAddressesObjListTrans = PC_RestAPIUtilities.transformRESTObjects(reqApplicantAddressesObjList, PC_RestAPIConstants.REST_OBJECT_NAME_APPLICANT_ADDRESS);
                List<object> reqApplicantHealthPlansObjListTrans = PC_RestAPIUtilities.transformRESTObjects(reqApplicantHealthPlansObjList, PC_RestAPIConstants.REST_OBJECT_NAME_APPLICANT_HEALTHPLAN);
                //List<Object> reqApplicantHCOsObjListTrans = PC_RestAPIUtilities.transformRESTHCOs(reqApplicantHCOsObjList, PC_RestAPIConstants.REST_OBJECT_NAME_APPLICANT_HCO);
                //Map<String, Object> reqPhysicianObjTrans = PC_RestAPIUtilities.transformRESTPatient(reqPhysicianObj);
                //List<Object> reqPhysicianAddressesObjListTrans = PC_RestAPIUtilities.transformRESTAddresses(reqPhysicianAddressesObjList, PC_RestAPIConstants.REST_OBJECT_NAME_ADDRESS);
                //List<Object> reqPhysicianHealthPlansObjListTrans = PC_RestAPIUtilities.transformRESTHealthPlans(reqPhysicianHealthPlansObjList, PC_RestAPIConstants.REST_OBJECT_NAME_HEALTHPLAN);
                // Create sObjects
                string applicantId = PC_RestAPIUtilities.upsertApplicant(reqApplicantTrans, reqApplicantAddressesObjListTrans, reqApplicantHealthPlansObjListTrans, operation);
                // Create responseBody
                Map<string, object> rsBodyList = new  Map<string, object>();
                rsBodyList.put(APPLICANT_KEY, applicantId);
                res.responseBody = Blob.valueOf(JSON.serialize(rsBodyList));
            }
            else
            {
                throw new  PC_RestException(string.valueOf(PC_RestAPIConstants.ErrorCode.MANDATORY_FIELDS_MISSING), string.valueOf(PC_RestAPIConstants.ErrorType.PATIENT_CONNECT), PC_RestAPIConstants.ERRORMESSAGE_APPLICANT_MANDATORY_FIELDS_MISSING);
            }
        }
        catch(Exception e)
        {
            Database.rollback(sp);
            PC_RestAPIUtilities.exceptionHandler(req, res, e, reqString);
        }
    }
}