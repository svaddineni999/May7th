/******************************************************************************
  Modification Log:
  -----------------------------------------------------------------------------
  Developer             Date        Description
  -----------------------------------------------------------------------------
  Vijay Kashikar       2019-20-04   Initial Version
  Kishore Kanteti      11-12-2019   [PC-5795] Reduced Parameters for createRemoteServiceLog method
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
Haritha Reddy         21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
 ******************************************************************************/

/**
 * Service Class for VMI Medical Benefits. Makes use of HTTP Post method instead of SOAP web callouts
 *
 * @author Vijay Kashikar
 * @date 4/20/2019.
 */
public with sharing class PC_MedicalBenefits_VirMedica2 implements PC_eBenefits.MedicalBenefits{
    static final String CREDENTIALS = 'PC_VMI_MedicalBenefits';

    static final String WSSE_PREFIX = 'wsse';
    static final String NS2_PREFIX = 'ns2';
    static final String SPRING_NS = 'http://springframework.org/spring-ws';
    static final String NS2_NS = 'http://virmedica.com/api/soap';
    static final String SOAP_ENV_NS = 'http://schemas.xmlsoap.org/soap/envelope/';
    static final String SOAP_NS = 'http://virmedica.com/api/soap';
    static final String WSSE_NS = 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd';
    static final String WSU_NS = 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd';
    static final String PASSWORD_TYPE = 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText';
    //static final String ENDPOINT = 'https://api-amgen-2.virmedica.com'; // GET FROM INTEGRATION SETTINGS

    private static string COMPLETE = 'Complete';
    private static string PARTIAL = 'Partial';
    private static string INCOMPLETE = 'Incomplete';
    private static string COULD_NOT_IDENTIFY = 'Could not identify';
    private static string NA = 'N/A';
    private static string COLON = ' : ';

    private static string usernameStartingHTMLTag = '<wsse:Username>';
    private static string usernameEndHTMLTag = '</wsse:Username>';
    private static string passwordStartHTMLTag = 'PasswordText">';
    private static string passwordEndHTMLTag = '</wsse:Password>';
    private static string maskText = 'XXXXXXX';

    private static string requestWithoutCredentials;

    public inherited sharing class VMIException extends Exception {}

    public PC_eBenefits.MedicalBenefitsRequest createMedicalBenefitRequest() {
        return new PC_eBenefits.MedicalBenefitsRequest();
    }

    public PC_eBenefits.MedicalBenefitsResponse lookupMedicalBenefits(PC_eBenefits.MedicalBenefitsRequest request) {
        PC_eBenefits.MedicalBenefitsResponse failureResponse = new PC_eBenefits.MedicalBenefitsResponse();
        failureResponse.isSuccess = false;
        try {
            Boolean isValid = validateRequest(request);
            PC_Integration_Settings__c integrationSettings = getCredentials();
            DOM.Document requestDocument = getRequestDOM(request, integrationSettings);
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(integrationSettings.endpoint_Url__c);
            req.setHeader('Content-Type', 'text/xml');
            req.setBodyDocument(requestDocument);
            Http http = new Http();
            HttpResponse res = http.send(req);

            Map<String,String> remoteServiceLogDetails = new Map<String, String>();
            remoteServiceLogDetails.put('serviceName','VMI');
            remoteServiceLogDetails.put('callbackURL',integrationSettings.endpoint_Url__c);
            remoteServiceLogDetails.put('request',requestDocument.toXmlString());
            remoteServiceLogDetails.put('response',res.getBody());
            remoteServiceLogDetails.put('additionalInfo','');
            remoteServiceLogDetails.put('statusCode',String.valueOf(res.getStatusCode()));
            remoteServiceLogDetails.put('serviceType',PC_Constants.REMOTE_SERVICE_TYPE_OUTBOUND);

            createRemoteServiceLog(remoteServiceLogDetails);
            Integer statusCode = res.getStatusCode();
            if (statusCode == 200) {
                // OK
                Dom.Document resDoc = res.getBodyDocument();
                return parseResponseEnvelop(resDoc.getRootElement(), request);
            } else {
                return handleException(res);
            }
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return failureResponse;
    }

    public static PC_eBenefits.MedicalBenefitsResponse handleException(HttpResponse res) {
        PC_eBenefits.MedicalBenefitsResponse exceptionResponse = new PC_eBenefits.MedicalBenefitsResponse();
        exceptionResponse.isSuccess = false;
        Integer statusCode = res.getStatusCode();
        List<String> errors = new List<String>();
        if(statusCode == 500) {
            errors = parseErrors(res);
        }
        else {
            errors.add(Label.PC_Lighting_Error_Message);
            String statusCodeLabel = Label.PC_HTTP_Status_Code;
            String formattedString = String.format(statusCodeLabel, new String[]{String.valueOf(statusCode)});
            errors.add(formattedString);
            errors.add(res.getBody());
        }
        exceptionResponse.errors = errors;
        return exceptionResponse;

    }

    public static List<String> parseErrors(HttpResponse res) {
        List<String> errors = new List<String>();
        try {
            Dom.Document resDoc = res.getBodyDocument();
            Dom.XmlNode envelope = resDoc.getRootElement();
            Dom.XmlNode body = envelope.getChildElement('Body', SOAP_ENV_NS);
            Dom.XmlNode fault = body.getChildElement('Fault', SOAP_ENV_NS);
            Dom.XmlNode faultString = fault.getChildElement('faultstring', NULL);
            String faultStringText = faultString.getText();
            errors.add(faultStringText + '...');
            Dom.XmlNode detail = fault.getChildElement('detail', NULL);
            Integer statusCode = res.getStatusCode();
            //String statusCodeLabel = Label.PC_HTTP_Status_Code;
            //String formattedString = String.format(statusCodeLabel, new String[]{String.valueOf(statusCode)});
            //errors.add(formattedString);
            if (detail != null) {
                for (Dom.XmlNode detailNode : detail.getChildElements()) {
                    errors.add(detailNode.getText());
                }
            }
            if(errors.size() == 0) {
                errors.add(Label.PC_Lighting_Error_Message);
            }
        }
        catch(Exception ex) {
            errors.add('Exception while parsing the VMI exception XML.');
            errors.add(Label.PC_Lighting_Error_Message);
            errors.add('Status Code - ' + res.getStatusCode());
            errors.add(res.getBody());
        }
        return errors;
    }

    public static PC_Integration_Settings__c getCredentials() {
        PC_Integration_Settings__c settings = PC_Integration_Settings__c.getValues(CREDENTIALS);
        if (settings == null) {
            PC_Utility.throwAuraHandledException('PC_VMI_MedicalBenefits Custom Setting not found for VMI');
        }
        return settings;
    }

    public static Boolean validateRequest(PC_eBenefits.MedicalBenefitsRequest request) {
        return true;
    }

    public static PC_eBenefits.MedicalBenefitsResponse parseResponseEnvelop(Dom.XmlNode envelope, PC_eBenefits.MedicalBenefitsRequest request) {
        PC_eBenefits.MedicalBenefitsResponse medicalBenefitsResponse = new PC_eBenefits.MedicalBenefitsResponse();
        PC_eBenefits.ProgramCoverage programCoverage = new PC_eBenefits.ProgramCoverage();

        Dom.XmlNode body = envelope.getChildElement('Body',SOAP_ENV_NS);
        Dom.XmlNode getMedEbvResponse = body.getChildElement('GetMedeBVResponse', NS2_NS);
        Dom.XmlNode response = getMedEbvResponse.getChildElement('response', NS2_NS);

        String responseTypeCode = response.getChildElement('responseTypeCode', NS2_NS).getText();
        medicalBenefitsResponse.completionStatus = PC_VirMedica_Utility.getCoverageCompletionStatus(Integer.valueOf(responseTypeCode));

        if(!String.isBlank( medicalBenefitsResponse.completionStatus)) {
            List<Object> formattingArguments = new List<Object>{ medicalBenefitsResponse.completionStatus};
            medicalBenefitsResponse.successMessages.add(
                    String.format(Label.PC_MedicalBenefits_ProgramCoverage_CompletionStatus,formattingArguments));

            if(! medicalBenefitsResponse.completionStatus.equalsIgnoreCase(COMPLETE)){
                medicalBenefitsResponse.successMessages.add(Label.PC_MedicalBenefits_InfoMessage);
            }
        }
        medicalBenefitsResponse.isSuccess = true;


        Dom.XmlNode policy1 = response.getChildElement('policy1', NS2_NS);
        Dom.XmlNode policy2 = response.getChildElement('policy2', NS2_NS);
        Dom.XmlNode policy3 = response.getChildElement('policy3', NS2_NS);



        programCoverage = parseResponse(response);
        programCoverage.primaryCoverageBenefit = parsePolicy(policy1, request.primaryHealthPlan, request.prescription,
                                                              PC_Constants.HEALTH_PLAN_TYPE_PRIMARY, request.cptCodes,
                                                              request.cptCodeMap );
        programCoverage.secondaryCoverageBenefit = parsePolicy(policy2, request.secondaryHealthPlan,request.prescription,
                                                              PC_Constants.HEALTH_PLAN_TYPE_SECONDARY, request.cptCodes,
                                                              request.cptCodeMap);
        programCoverage.tertiaryCoverageBenefit = parsePolicy(policy3, request.tertiaryHealthPlan, request.prescription,
                                                               PC_Constants.HEALTH_PLAN_TYPE_TERTIARY, request.cptCodes,
                                                              request.cptCodeMap);

        if(String.isNotEmpty(medicalBenefitsResponse.completionStatus)) {
            programCoverage.completionStatus = medicalBenefitsResponse.completionStatus;
        }

        medicalBenefitsResponse.programCoverage = programCoverage;
        return medicalBenefitsResponse;
    }

    public void updateCoverage(PC_eBenefits.MedicalBenefitsResponse response, PC_eBenefits.sCoverageDetail sCoverage) {
        if(response != null && response.isSuccess == true) {
            PC_eBenefits_Utility.updateCoverageDetails(sCoverage, response);
        }
    }

    private static PC_eBenefits.ProgramCoverage parseResponse(Dom.XmlNode response) {
        if(response != null) {
            PC_eBenefits.ProgramCoverage programCoverage = new PC_eBenefits.ProgramCoverage();
            Dom.XmlNode coordinatedPlanBenefits = response.getChildElement('coordinatedPlanBenefits', NS2_NS);
            if(coordinatedPlanBenefits != null) {
                programCoverage.coordinatedPlanBenefits = coordinatedPlanBenefits.getText();
            }
            return programCoverage;
        }
        return null;
    }

    private static PC_eBenefits.ProgramCoverageBenefit parsePolicy(Dom.XmlNode policy,
            PC_eBenefits.HealthPlan requestHealthPlan, PC_eBenefits.Prescription prescription, String healthPlanType,
            List<String> cptCodes, Map<String, String> cptCodeMap ) {
        if(policy != null && requestHealthPlan != null && prescription != null) {

            system.debug('Policy@@+'+policy);
            PC_eBenefits.ProgramCoverageBenefit programCoverageBenefit = new PC_eBenefits.ProgramCoverageBenefit();

            programCoverageBenefit.coverageLevel = healthPlanType;

            programCoverageBenefit.transactionDate = getTextAsDateOfChildElement(policy,'transactionDate');
            programCoverageBenefit.transactionId = getTextOfChildElement(policy,'transactionId');
            programCoverageBenefit.coverageStatus = getTextOfChildElement(policy,'eligibilityStatus');
            programCoverageBenefit.startDate = getTextAsDateOfChildElement(policy,'effDate');
            programCoverageBenefit.endDate = getTextAsDateOfChildElement(policy,'endDate');
            programCoverageBenefit.payerName = getTextOfChildElement(policy,'payerName');
            programCoverageBenefit.planType = getTextOfChildElement(policy,'planType');
            programCoverageBenefit.groupNo = getTextOfChildElement(policy,'groupNumber');
            programCoverageBenefit.groupName = getTextOfChildElement(policy,'groupName');

            Decimal  dedIndAmt =
                    PC_VirMedica_Utility.convertCurrenyToDecimal( getTextOfChildElement(policy,'dedIndAmt'));
            if(dedIndAmt !=null) {
                programCoverageBenefit.individualInNetworkDeductibleLimit =dedIndAmt;
            }

            Decimal dedIndAmtMet =
                    PC_VirMedica_Utility.convertCurrenyToDecimal(getTextOfChildElement(policy, 'dedIndAmtMet'));
            if( dedIndAmt != null && dedIndAmtMet != null) {
                programCoverageBenefit.individualInNetworkDeductibleRemaining =dedIndAmt -dedIndAmtMet;
            }

            Decimal oopMaxIndAmt =
                    PC_VirMedica_Utility.convertCurrenyToDecimal(getTextOfChildElement(policy,'oopMaxIndAmt'));
            if(oopMaxIndAmt !=null) {
                programCoverageBenefit.individualInNetworkOutofPocketLimit =oopMaxIndAmt;
            }

            Decimal oopMaxIndMet =
                    PC_VirMedica_Utility.convertCurrenyToDecimal(getTextOfChildElement(policy, 'oopMaxIndMet'));
            if( oopMaxIndAmt != null && oopMaxIndMet != null) {
                programCoverageBenefit.individualInNetworkOutofPocketRemaining =oopMaxIndAmt -oopMaxIndMet;
            }


            Decimal dedFamAmt =
                    PC_VirMedica_Utility.convertCurrenyToDecimal(getTextOfChildElement(policy,'dedFamAmt'));
            if(dedFamAmt !=null) {
                programCoverageBenefit.familyInNetworkDeductibleLimit = dedFamAmt;
            }

            Decimal dedFamAmtMet =
                    PC_VirMedica_Utility.convertCurrenyToDecimal(getTextOfChildElement(policy, 'dedFamAmtMet'));
            if( dedFamAmt != null && dedFamAmtMet!=null) {
                programCoverageBenefit.familyInNetworkDeductibleRemaining =dedFamAmt - dedFamAmtMet;
            }

            Decimal oopMaxFamAmt =
                    PC_VirMedica_Utility.convertCurrenyToDecimal(getTextOfChildElement(policy,'oopMaxFamAmt'));
            if(oopMaxFamAmt != null) {
                programCoverageBenefit.familyInNetworkOutofPocketLimit = oopMaxFamAmt;
            }

            Decimal oopMaxFamMet =
                    PC_VirMedica_Utility.convertCurrenyToDecimal(getTextOfChildElement(policy, 'oopMaxFamMet'));
            if(oopMaxFamAmt != null && oopMaxFamMet!= null) {
                programCoverageBenefit.familyInNetworkOutofPocketRemaining =oopMaxFamAmt - oopMaxFamMet;
            }


            programCoverageBenefit.paRequired = getTextOfChildElement(policy,'priorAuthRqd');
            programCoverageBenefit.buyAndBill = getTextOfChildElement(policy,'buyBill');
            programCoverageBenefit.specialtyPharmacyRequired = getTextOfChildElement(policy,'spReq');
            programCoverageBenefit.specialtyPharmacyInfo = getTextOfChildElement(policy,'spName');

            programCoverageBenefit.isGovernmentPlan = getTextOfChildElement(policy,'govInd');
            programCoverageBenefit.governmentPlanType = getTextOfChildElement(policy,'govPolicyType');
            programCoverageBenefit.transactionMessageID = getTextOfChildElement(policy,'msgId');
            programCoverageBenefit.benefitNotes = getTextOfChildElement(policy,'msgContent');
            programCoverageBenefit.productAdminMessage = getTextOfChildElement(policy,'customMessage1');
            programCoverageBenefit.billingMessage = getTextOfChildElement(policy,'customMessage2');
            programCoverageBenefit.priorAuthMessage = getTextOfChildElement(policy,'customMessage3');
            programCoverageBenefit.payerMessage = getTextOfChildElement(policy,'customMessage4');


            PC_eBenefits.ProgramCoverageBenefitItem officeCategory = new PC_eBenefits.ProgramCoverageBenefitItem();

            officeCategory.name = requestHealthPlan.memberId + COLON + String.valueOf(PC_Constants.BenefitCategory.OfficeVisit);
            officeCategory.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.OfficeVisit);
            officeCategory.serviceTypeCode =PC_Constants.NA;
            officeCategory.serviceType = PC_Constants.NA;
            officeCategory.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.OfficeVisit);
            officeCategory.coverageLevel = getTextOfChildElement(policy,'officeVisitStatus');
            officeCategory.deductableApplies = PC_VirMedica_Utility.categoryBasedCPTInfo(getTextOfChildElement(policy,'officeVisitDedApplies'));
            officeCategory.copayApplies = PC_VirMedica_Utility.categoryBasedCPTInfo(getTextOfChildElement(policy,'officeVisitCopayApplies'));
            officeCategory.coinsuranceApplies = PC_VirMedica_Utility.categoryBasedCPTInfo(getTextOfChildElement(policy,'officeVisitCoinsApplies'));
            officeCategory.oopMaxApplies = PC_VirMedica_Utility.categoryBasedCPTInfo(getTextOfChildElement(policy,'officeVisitOopMaxApplies'));
            officeCategory.pcpCopayAmount = getTextAsDecimalOfChildElement(policy,'officeCopayPCPAmt');
            officeCategory.specialistCopayAmount = getTextAsDecimalOfChildElement(policy,'officeSpecCopayAmt');
            officeCategory.coinsurancePercent = getTextAsPercentOfChildElement(policy,'officeCoinsAmt');

            programCoverageBenefit.benefitItems.add(officeCategory);

            PC_eBenefits.ProgramCoverageBenefitItem productCategory = new PC_eBenefits.ProgramCoverageBenefitItem();

            productCategory.name = requestHealthPlan.memberId +
                    COLON + String.valueOf(PC_Constants.BenefitCategory.Product);
            if(!String.isEmpty(prescription.productName)){
                productCategory.name += COLON + prescription.productName;
            }
            productCategory.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Product);
            productCategory.serviceType = PC_Constants.NA;
            productCategory.serviceTypeCode = prescription.productName;
            productCategory.coverageLevel = getTextOfChildElement(policy,'productStatus');
            productCategory.deductableApplies = PC_VirMedica_Utility.categoryBasedCPTInfo(getTextOfChildElement(policy,'productDedApplies'));
            productCategory.copayApplies = PC_VirMedica_Utility.categoryBasedCPTInfo(getTextOfChildElement(policy,'productCopayApplies'));
            productCategory.coinsuranceApplies = PC_VirMedica_Utility.categoryBasedCPTInfo(getTextOfChildElement(policy,'productCoinsApplies'));
            productCategory.oopMaxApplies = PC_VirMedica_Utility.categoryBasedCPTInfo(getTextOfChildElement(policy,'productOopMaxApplies'));
            productCategory.pcpCopayAmount = getTextAsDecimalOfChildElement(policy,'productPCPCopayAmt');
            productCategory.specialistCopayAmount = getTextAsDecimalOfChildElement(policy,'productSpecCopayAmt');
            productCategory.coinsurancePercent = getTextAsPercentOfChildElement(policy,'productCoinsAmt');
            programCoverageBenefit.benefitItems.add(productCategory);

            String cptElementName = '';
            Dom.XmlNode cptCodeResult;
            PC_eBenefits.ProgramCoverageBenefitItem cpt;

            if(cptCodes != null) {
                for (Integer i = 1; i <= cptCodes.size(); i++) {
                    cptElementName = 'cptCode' + i + 'Result';
                    cptCodeResult = policy.getChildElement(cptElementName, NS2_NS);
                    if (cptCodeResult != null) {
                        cpt = new PC_eBenefits.ProgramCoverageBenefitItem();
                        cpt.name = requestHealthPlan.memberId + COLON + String.valueOf(PC_Constants.BenefitCategory.Administration)
                                    + COLON + cptCodes[i-1];
                        cpt.benefitCategory = String.valueOf(PC_Constants.BenefitCategory.Administration);
                        cpt.serviceTypeCode =cptCodes[i-1];

                        if( String.isNotEmpty(cptCodeMap.get(cptCodes[i-1]))) {
                            cpt.serviceType = cptCodeMap.get(cptCodes[i - 1]);
                        }
                        cpt.coverageLevel = getTextOfChildElement(cptCodeResult, 'cptStatus');
                        cpt.deductableApplies = PC_VirMedica_Utility.categoryBasedCPTInfo(getTextOfChildElement(cptCodeResult, 'dedApplies'));
                        cpt.copayApplies = PC_VirMedica_Utility.categoryBasedCPTInfo(getTextOfChildElement(cptCodeResult, 'copayApplies'));
                        cpt.coinsuranceApplies = PC_VirMedica_Utility.categoryBasedCPTInfo(getTextOfChildElement(cptCodeResult, 'coinsApplies'));
                        cpt.oopMaxApplies = PC_VirMedica_Utility.categoryBasedCPTInfo(getTextOfChildElement(cptCodeResult, 'oopMaxApplies'));
                        cpt.pcpCopayAmount = getTextAsDecimalOfChildElement(cptCodeResult, 'pcpCopayAmt');
                        cpt.specialistCopayAmount = getTextAsDecimalOfChildElement(cptCodeResult, 'specCopayAmt');
                        cpt.coinsurancePercent = getTextAsPercentOfChildElement(cptCodeResult, 'coinsAmt');
                        programCoverageBenefit.benefitItems.add(cpt);
                    }
                }
            }
            return programCoverageBenefit;
        }
        return null;
    }

    private static String getTextOfChildElement(Dom.XmlNode node, String childElementName) {
        Dom.XmlNode childNode = node.getChildElement(childElementName, NS2_NS);
        if(childNode != null) {
            return childNode.getText();
        }
        return null;
    }
    private static Date getTextAsDateOfChildElement(Dom.XmlNode node, String childElementName) {
        String text = getTextOfChildElement(node, childElementName);
        if(String.isNotEmpty(text) && text.toLowerCase() != PC_Constants.NOT_FOUND.toLowerCase()) {
            return Date.valueOf(text);
        }
        return null;
    }
    private static Decimal getTextAsDecimalOfChildElement(Dom.XmlNode node, String childElementName) {
        String text = getTextOfChildElement(node, childElementName);
        return PC_VirMedica_Utility.convertCurrenyToDecimal(text);
    }
        private static Decimal getTextAsPercentOfChildElement(Dom.XmlNode node, String childElementName) {
        String text = getTextOfChildElement(node, childElementName);
        if(String.isNotEmpty(text) && text.toLowerCase() != PC_Constants.NOT_FOUND.toLowerCase()) {
            if(text.contains('%')) {
                text = text.replace('%','');
            }
            return Decimal.valueOf(text);
        }
        return null;
    }
    public DOM.Document getRequestDOM(PC_eBenefits.MedicalBenefitsRequest requestDetails, PC_Integration_Settings__c integrationSettings) {

        DOM.Document document = new DOM.Document();

        DOM.XmlNode envelope = document.createRootElement('soapenv:Envelope', NULL, NULL);
        envelope.setNamespace('soapenv', SOAP_ENV_NS);
        envelope.setNamespace('soap', SOAP_NS);

        DOM.XmlNode header = envelope.addChildElement('soapenv:Header', NULL, NULL);

        updateHeaderWithSecurity(header, integrationSettings);

        Dom.XmlNode body = envelope.addChildElement('soapenv:Body', NULL, NULL);

        Dom.XmlNode getMedeBVRequest = body.addChildElement('GetMedeBVRequest', NS2_NS, NS2_PREFIX);

        Dom.XmlNode request = getMedeBVRequest.addChildElement(NS2_PREFIX + ':' + 'request', NULL, NULL);

        updateRequestWithPatient(request, requestDetails.patient);
        updateRequestWithProduct(request, requestDetails.prescription, requestDetails.cptCodes, requestDetails.clinic );
        updateRequestWithPolicy(request, requestDetails.primaryHealthPlan, 1);
        updateRequestWithPolicy(request, requestDetails.secondaryHealthPlan, 2);
        updateRequestWithPolicy(request, requestDetails.tertiaryHealthPlan, 3);

        return document;
    }

    public static void updateHeaderWithSecurity(DOM.XmlNode header, PC_Integration_Settings__c integrationSettings) {
        DOM.XmlNode security = header.addChildElement('Security', WSSE_NS, WSSE_PREFIX);
        security.setNamespace('wsu', WSU_NS);
        security.setAttribute('soapenv:mustUnderstand', '1');

        DOM.XmlNode userNameToken = security.addChildElement(WSSE_PREFIX + ':' + 'UsernameToken', NULL, NULL);
        userNameToken.setAttribute('wsu:Id', 'UsernameToken-UUID');

        DOM.XmlNode userName = userNameToken.addChildElement(WSSE_PREFIX + ':' + 'Username', NULL, NULL);
        userName.addTextNode(integrationSettings.username__c); //Read from integration setting

        DOM.XmlNode password = userNameToken.addChildElement(WSSE_PREFIX + ':' + 'Password', NULL, NULL);
        password.setAttribute('Type', PASSWORD_TYPE);
        password.addTextNode(integrationSettings.password__c); //Read from integration setting
    }

    public static void updateRequestWithPatient(DOM.XmlNode request, PC_eBenefits.Patient patientDetails) {
        Dom.XmlNode clientPatientID = request.addChildElement(NS2_PREFIX + ':' + 'clientPatientId', NULL, NULL);
        //clientPatientID.addTextNode('PP00123');
        //clientPatientID.addTextNode(patientDetails.id);

        Dom.XmlNode patientFirstName = request.addChildElement(NS2_PREFIX + ':' + 'patientFirstName', NULL, NULL);
        //patientFirstName.addTextNode('Jane');
        patientFirstName.addTextNode(patientDetails.firstName);

        Dom.XmlNode patientLastName = request.addChildElement(NS2_PREFIX + ':' + 'patientLastName', NULL, NULL);
        //patientLastName.addTextNode('Doe');
        patientLastName.addTextNode(patientDetails.lastName);

        Dom.XmlNode patientDOB = request.addChildElement(NS2_PREFIX + ':' + 'patientDOB', NULL, NULL);
        Datetime now = Datetime.now();
        //patientDOB.addTextNode('1963-07-22');
        patientDOB.addTextNode(String.valueOf(patientDetails.dob));

        Dom.XmlNode patientGender = request.addChildElement(NS2_PREFIX + ':' + 'patientGender', NULL, NULL);
        //patientGender.addTextNode('F');
        String gender = patientDetails.gender.toLowerCase() == 'male' ? 'M' : 'F';
        patientGender.addTextNode(gender);

        if(String.isNotBlank(patientDetails.zipCode)) {
            Dom.XmlNode patientZip = request.addChildElement(NS2_PREFIX + ':' + 'patientZip', NULL, NULL);
            //patientZip.addTextNode('72205');
            patientZip.addTextNode(patientDetails.zipCode);
        }
    }

    public static void updateRequestWithProduct(DOM.XmlNode request, PC_eBenefits.Prescription prescription, List<String> cptCodes,
       PC_eBenefits.Clinic clinic ) {
        Dom.XmlNode product = request.addChildElement(NS2_PREFIX + ':' + 'product', NULL, NULL);
        //product.addTextNode('Prolia');
        product.addTextNode(prescription.drug.name);

        if(cptCodes != null && !cptCodes.isEmpty()) {
            Dom.XmlNode cptCode;
            Integer i = 1;
            for(String code : cptCodes) {
                cptCode = request.addChildElement(NS2_PREFIX + ':' + 'cptCode' + i, NULL, NULL);
                cptCode.addTextNode(code);
                i++;
            }
        }


        Dom.XmlNode primaryDiagnosis = request.addChildElement(NS2_PREFIX + ':' + 'primaryDiagnosis', NULL, NULL);
        //primaryDiagnosis.addTextNode('M81.0');
        primaryDiagnosis.addTextNode(prescription.primaryDiagnosis);


        Dom.XmlNode pos = request.addChildElement(NS2_PREFIX + ':' + 'pos', NULL, NULL);
        //pos.addTextNode('11');
        pos.addTextNode(prescription.placeOfService);

        Dom.XmlNode providerFirstName = request.addChildElement(NS2_PREFIX + ':' + 'providerFirstName', NULL, NULL);
        //providerFirstName.addTextNode('Avis');
        providerFirstName.addTextNode(prescription.physician.firstName);


        Dom.XmlNode providerLastName = request.addChildElement(NS2_PREFIX + ':' + 'providerLastName', NULL, NULL);
        //providerLastName.addTextNode('Ware');
        providerLastName.addTextNode(prescription.physician.lastName);

        Dom.XmlNode providerNPI = request.addChildElement(NS2_PREFIX + ':' + 'providerNPI', NULL, NULL);
        //providerNPI.addTextNode('1497783757');
        providerNPI.addTextNode(clinic.npi);

        Dom.XmlNode providerState = request.addChildElement(NS2_PREFIX + ':' + 'providerState', NULL, NULL);
        //providerState.addTextNode('AR');
        providerState.addTextNode(prescription.physician.address.state);

        Dom.XmlNode mfg = request.addChildElement(NS2_PREFIX + ':' + 'mfg', NULL, NULL);
        //mfg.addTextNode('Amgen');
        mfg.addTextNode(prescription.drug.drugManufacturerName);
    }

    public static void updateRequestWithPolicy(DOM.XmlNode request, PC_eBenefits.HealthPlan healthPlan, Integer index) {
        if(healthPlan != null) {
            String elementName = 'policy' + index + 'Params';

            Dom.XmlNode policy = request.addChildElement(NS2_PREFIX + ':' + elementName, NULL, NULL);

            if(String.isNotBlank(healthPlan.memberId)) {
                Dom.XmlNode policyMemberId = policy.addChildElement(NS2_PREFIX + ':' + 'policyMemberId', NULL, NULL);
                //policyMemberId.addTextNode('#########A');
                policyMemberId.addTextNode(healthPlan.memberId);
            }

            if(String.isNotBlank(healthPlan.payerId)) {
                Dom.XmlNode policyPayerId = policy.addChildElement(NS2_PREFIX + ':' + 'policyPayerId', NULL, NULL);
                //policyPayerId.addTextNode('19');
                policyPayerId.addTextNode(healthPlan.payerId);
            }


            if (healthPlan.relationshipToCardholder.equalsIgnoreCase(PC_Constants.SELF)) {
                Dom.XmlNode policyPatientSubscriber = policy.addChildElement(NS2_PREFIX + ':' + 'policyPatientSubscriber', NULL, NULL);
                policyPatientSubscriber.addTextNode('true');
            } else {
               // policyPatientSubscriber.addTextNode('false');
                //TODO
            }

            if( index == 2) {
                if(healthPlan.medicareSupplementalPlanLetter !=null) {
                    Dom.XmlNode mcSuppPlanLetter = policy.addChildElement(NS2_PREFIX + ':' + 'mcSuppPlanLetter', NULL, NULL);
                    mcSuppPlanLetter.addTextNode(healthPlan.medicareSupplementalPlanLetter);
                }
            }
        }
    }
    private static PC_Remote_Service_Log__c createRemoteServiceLog(Map<String,String> remoteServiceLogDetails) {
        String serviceName = '';
        serviceName = remoteServiceLogDetails.get('serviceName');
        String callbackURL = '';
        callbackURL = remoteServiceLogDetails.get('callbackURL');
        String request = '';
        request = remoteServiceLogDetails.get('request');
        String response = '';
        response = remoteServiceLogDetails.get('response');
        String additionalInfo = '';
        additionalInfo = remoteServiceLogDetails.get('additionalInfo');
        Integer statusCode = Integer.valueOf(remoteServiceLogDetails.get('statusCode'));
        String serviceType = '';
        serviceType = remoteServiceLogDetails.get('serviceType');

        request = maskRequest(request);
        PC_Remote_Service_Log__c record = new PC_Remote_Service_Log__c(
                PC_Running_User__c = UserInfo.getUserId(),
                PC_Additional_Information__c = additionalInfo,
                PC_Callback_URL__c = callbackURL,
                PC_Callback_Request__c = request,
                PC_Callback_Response__c = response,
                PC_Service_Name__c = serviceName,
                PC_Service_Type__c = serviceType,
                PC_StatusCode__c = String.valueOf(statusCode)

        );
        if(record != null){
            PC_Database.ins(record,true);
        }
        return record;
    }

    private static string maskRequest (String request){

        if(String.isNotBlank(request)) {
            String username = request.substring(request.indexOf(usernameStartingHTMLTag)+
                                          usernameStartingHTMLTag.length() , request.indexOf(usernameEndHTMLTag));
            String password = request.substring(request.indexOf(passwordStartHTMLTag)+ passwordStartHTMLTag.length()
                                                              , request.indexOf(passwordEndHTMLTag));
            request = request.replaceFirst(username, maskText);
            request = request.replaceFirst(password, maskText);
            return request;
        }

        return null;

    }


}