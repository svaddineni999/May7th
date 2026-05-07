/*********************************************************************************************************
Class Name      : PC_PharmacyCardLookup_UBC
Description     : Utility class to store all the helper methods.
Created By      : Vijay Kashikar
Created Date    : May 10, 2018
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Vijay Kashikar               Mar 19, 2018              Initial Version
Shishir Bansal               July 18,2018              Adding latitude , longitude, phone, fax etc details
                                                       to the pharmacy record
Vijay Kashikar         		 Sep 06, 2018               Make service responses to be available as part of global response objects
Shishir Bansal               Oct 09, 2018               Make use of pharmacy API instead of depending on External ID while doing RTBC requests for Default Pharmacies
Vijay Kashikar               Sep 20, 2018               [PC-3778] Associated NCPDP value with the pharmacy
Vijay Kashikar               Sep 25, 2018               [PC-3629] Assigned requestDate to pharmacy card response.
Shishir Bansal               11-Dec-2019                 [PC-5792] Avoid hardcoding of string variable
*********************************************************************************************************/


public with sharing class PC_UBC_Utility {
    private static String accessToken = null;
    static integer timeoutSeconds = 40000;
    //private static final String eBENEFITS_API_URL = PC_Constants.END_POINT_UBC_PHARMACY_BENEFITS;

    public boolean authenticateViaNamedCreds() {
        if(accessToken != null) {
            system.debug('available token = ' + accessToken);
            return accessToken != null;
        }
        HttpRequest req = new HttpRequest();
        String namedCred = PC_eBenefits.getEbenefitsNamedCredential(PC_Constants.PC_eBENEFITS_TOKEN_SERVICE_TYPE);
        req.setEndpoint('callout:' + namedCred);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Cache-Control', 'no-cache');
        String clientId = '{!$Credential.UserName}';
        String clientSecret = '{!$Credential.Password}';
        String grantType = 'client_credentials';
        //String scope = 'benefits:pharmacy:read benefits:pharmacy:write benefits:rtbc:esi:read benefits:rtbc:esi:write plans:read';
        String scope = 'benefits:pharmacy:read benefits:pharmacy:write benefits:rtbc:esi:read benefits:rtbc:esi:write organizations:read logging:write pharmacies:read pharmacies:write products:read products:write benefits:medical:read benefits:medical:write plans:read';

        String body = 'client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8')
                + '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8')
                + '&grant_type=' + EncodingUtil.urlEncode(grantType, 'UTF-8')
                + '&scope=' + EncodingUtil.urlEncode(scope, 'UTF-8');
        system.debug(body);
        req.setBody(body);

        Http http = new Http();
        HTTPResponse res = http.send(req);

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        system.debug(responseMap);
        accessToken = (String) responseMap.get('access_token');
        system.debug('token = ' + accessToken);
        return accessToken != null;
    }

    public Map<String, Object> checkEligibility(PC_eBenefits.Patient patient,
            PC_eBenefits.Physician physician,
            PC_eBenefits.Drug product)
    {
        String exMsg=PC_Constants.EMPTY_STRING;
        PC_UBC.EligibilityServiceResponse ubcServiceResponse;
        HttpRequest req = new HttpRequest();
        String namedCred = PC_eBenefits.getEbenefitsNamedCredential(PC_Constants.PC_eBENEFITS_PHARMACY_CARD_SERVICE_TYPE);
        req.setEndpoint('callout:' + namedCred);
        req.setMethod('POST');
        req.setTimeout(timeoutSeconds);
        req.setHeader('Accept', 'application/json, text/json');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Cache-Control', 'no-cache');
        req.setHeader('Authorization', 'Bearer ' + accessToken);

        Map<String, Object> body = new Map<String, Object>();
        if(patient.birthdate!=null && !patient.birthdate.contains('Z')) {

            system.debug(patient.birthdate);
            patient.birthdate=PC_eBenefits_Utility.parseDateToJSONDate(patient.Birthdate);

        }
        body.put('Patient', patient);
        body.put('Physician', physician);
        if(product != null && (product.ndc != null && product.label != null)) {
            body.put('Product', product);
        }
        //body.put('requestDate', '');
        //body.put('pbms', new String[] {});
        //body.put('isError', false);
        system.debug('ubc service request body');
        system.debug(JSON.serialize(body));
        req.setBody(JSON.serialize(body));
        system.debug('printing request for checkeligibility');
        system.debug(JSON.serialize(body));
        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug('printing response for checkeligibility');
        system.debug('status code -> ' + res.getStatusCode());

        system.debug(res.getBody());




        if(res.getStatusCode() != null && res.getStatusCode() == 400) {

            try {
                ubcServiceResponse = (PC_UBC.EligibilityServiceResponse)JSON.deserialize(res.getBody(),Type.forName('PC_UBC.EligibilityServiceResponse'));
                ubcServiceResponse.serviceResponse = res.getBody();
            }
            catch(Exception ex) {
                // do nothing
                ubcServiceResponse = null;
                exMsg = res.getBody();

            }

            if(ubcServiceResponse != null  && null != ubcServiceResponse.modelState && !ubcServiceResponse.modelState.isEmpty() ) {


                List<String[]> msgs = ubcServiceResponse.modelState.values();

                String errorMessage = PC_Constants.EMPTY_STRING;
                List<String> new_m;
                for (String[] m : msgs) {
                    new_m = new List<String>();
                    system.debug(m);
                    for (String n : m) {
                        if (String.isNotEmpty(n) && !n.equalsIgnoreCase('null')) {
                            new_m.add(n);
                        }
                    }
                    errorMessage += String.join(new_m, ',');
                    errorMessage += '.';
                }
                exMsg = errorMessage;
            }

        }
        else if(res.getStatusCode() != null && res.getStatusCode()==200)  {

            //do nothing
            ubcServiceResponse = (PC_UBC.EligibilityServiceResponse)JSON.deserialize(res.getBody(),Type.forName('PC_UBC.EligibilityServiceResponse'));
            ubcServiceResponse.serviceResponse = res.getBody();
        }
        else {
            exMsg = Label.PC_Ebenefits_Invalid_Response + '\n'+ res.getBody();

        }
        if(exMsg.length()>0){
            PC_Utility.throwAuraHandledException(exMsg);
        }
        return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    }

    public PC_UBC.EligibilityServiceResponse lookUpPharmacyCard(PC_eBenefits.PharmacyCardRequest cardHolder) {
        PC_UBC_Utility client = new PC_UBC_Utility();
        String exMsg=PC_Constants.EMPTY_STRING;
        client.authenticateViaNamedCreds();
        PC_UBC.EligibilityServiceResponse ubcServiceResponse;
        if(cardHolder != null && cardHolder.patient != null && cardHolder.physician != null) {
            Map<String, Object> eligibility;
            if(cardHolder.product == null) {
                eligibility =  client.checkEligibility(cardHolder.patient, cardHolder.physician, null);
            }
            else {
                eligibility = client.checkEligibility(cardHolder.patient, cardHolder.physician, cardHolder.product);
            }
            String eligibilityString = JSON.serialize(eligibility, false);
            system.debug(eligibilityString);
            eligibilityString = eligibilityString.replaceAll('"group"', '"insuranceGroup"');

            ubcServiceResponse = (PC_UBC.EligibilityServiceResponse) JSON.deserialize(eligibilityString, Type.forName('PC_UBC.EligibilityServiceResponse'));
            system.debug('ubcServiceResponse');
            system.debug(ubcServiceResponse);
            ubcServiceResponse.serviceResponse = eligibilityString;
            if(ubcServiceResponse != null && ubcServiceResponse.responseStatus != null &&  null!= ubcServiceResponse.responseStatus.isError &&  ubcServiceResponse.responseStatus.isError) {

                if(null!=ubcServiceResponse.responseStatus.internalMessage && ubcServiceResponse.responseStatus.internalMessage.length()>0) {
                    exMsg=ubcServiceResponse.responseStatus.internalMessage;
                    PC_Utility.throwAuraHandledException(exMsg);
                }

            }

            PC_UBC.PlanNameServiceResponse planServiceResponse = client.getPlanDetails(ubcServiceResponse.pbms[0].name);
            system.debug('plan service response');
            system.debug(planServiceResponse);

            //String bin = client.getBinDetails(planServiceResponse);
            //String pcn = client.getPcnDetails(planServiceResponse);
            String planName = client.getPlanName(planServiceResponse);
            //ubcServiceResponse.pbms[0].plans[0].insurance.bin = bin;
            //ubcServiceResponse.pbms[0].plans[0].insurance.pcn = pcn;
            ubcServiceResponse.pbms[0].plans[0].name = planName;
            Map<String, String> serviceResponses = ubcServiceResponse.allServiceResponses;
            if(ubcServiceResponse.allServiceResponses == null) {
                serviceResponses = new Map<String, String>();
            }

            serviceResponses.put(PC_UBC.SERVICE_RESPONSE_PLAN, planServiceResponse.serviceResponse);
            serviceResponses.put(PC_UBC.SERVICE_RESPONSE_ELIGIBILITY, ubcServiceResponse.serviceResponse);

            ubcServiceResponse.allServiceResponses = serviceResponses;
            //system.debug('printing ubc service reponse');
            //system.debug(ubcServiceResponse);
        }
        else {
            PC_Utility.throwAuraHandledException('Unknown Error');
        }
        return ubcServiceResponse;
    }

    public static void updatePharmacy(PC_eBenefits.PharmacyBenefitsResponse pharmacyBenefitsDetails, Account pharmacy, PC_Address__c address) {
        system.debug(pharmacyBenefitsDetails);
        if(pharmacyBenefitsDetails.pharmacy != null) {
            system.debug('updating pharmacy fields');
            //Object objPharmacy = pharmacyBenefitsDetails.additinalInfo.get('pharmacy');
            //String objPharmacyJson = JSON.serialize(objPharmacy);
            //PC_UBC.Pharmacy ubc_pharmacy = (PC_UBC.Pharmacy) JSON.deserialize(objPharmacyJson, PC_UBC.Pharmacy.class);
            //PC_eBenefits.Pharmacy
            system.debug('pharmacy external -> '+ pharmacyBenefitsDetails.pharmacy);

            pharmacy.PC_NPI__c                              =   pharmacyBenefitsDetails.pharmacy.npi;
            pharmacy.PC_NCPDP__c                            =   pharmacyBenefitsDetails.pharmacy.ncpdp;
            pharmacy.PC_External_ID__c                      =   pharmacyBenefitsDetails.pharmacy.extId;
            pharmacy.Name                                   =   pharmacyBenefitsDetails.pharmacy.name;
            pharmacy.fax                                    =   pharmacyBenefitsDetails.pharmacy.fax;
            pharmacy.phone                                  =   pharmacyBenefitsDetails.pharmacy.phone;
            address.PC_Zip_Code__c                          =   pharmacyBenefitsDetails.pharmacy.zipCode;
            address.PC_Address_1__c                         =   pharmacyBenefitsDetails.pharmacy.address.addressOne;
            address.PC_City__c                              =   pharmacyBenefitsDetails.pharmacy.address.city;

            address.PC_Primary_Address__c                   =   true;
            pharmacy.PC_Geolocation__Latitude__s            =   Decimal.valueOf(pharmacyBenefitsDetails.pharmacy.address.geoLocation.latitude);
            pharmacy.PC_Geolocation__Longitude__s           =   Decimal.valueOf(pharmacyBenefitsDetails.pharmacy.address.geoLocation.longitude);
            //address.PC_Account__c                         =   pharmacyBenefitsDetails.pharmacy.extId;
            //address.PC_Address_1__c                       =   pharmacyBenefitsDetails.pharmacy.phone;
            //address.PC_Primary_Address__c                 =   true;
            // address.PC_Country__c                        =   pharmacyBenefitsDetails.pharmacy.address.country;
            //address.PC_State__c                             =   pharmacyBenefitsDetails.pharmacy.address.state;

        }
    }

    public PC_UBC.PlanNameServiceResponse getPlanDetails(String planName) {
        HttpRequest req = new HttpRequest();
        String namedCred = PC_eBenefits.getEbenefitsNamedCredential(PC_Constants.PC_eBENEFITS_PLAN_SERVICE_TYPE);
        req.setEndpoint('callout:' + namedCred + '/?AbbreviatedName=' + planName);
        req.setMethod('GET');
        req.setTimeout(timeoutSeconds);
        req.setHeader('Accept', 'application/json, text/json');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Cache-Control', 'no-cache');
        req.setHeader('Authorization', 'Bearer ' + accessToken);


        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug(res.getStatusCode() + ' -> ' + res.getBody());

        if(res.getStatusCode() == 200 ) {
            String resBody = res.getBody();

            List<Object> serviceResponseObj = (List<Object>)JSON.deserializeUntyped(resBody);
            system.debug(serviceResponseObj);
            if(serviceResponseObj != null && serviceResponseObj.size() > 0) {
                Map<String, Object> planDetailsMap = (Map<String, Object>) serviceResponseObj[0];
                PC_UBC.PlanNameServiceResponse planNameServiceResponse =  (PC_UBC.PlanNameServiceResponse) JSON.deserializeStrict(JSON.serialize(planDetailsMap), PC_UBC.PlanNameServiceResponse.class);
                planNameServiceResponse.serviceResponse = resBody;
                return planNameServiceResponse;
            }
            else {
                String exMsg = Label.PC_Ebenefits_Invalid_Response + '(' + res.getStatusCode() + ')' + res.getBody();
                PC_Utility.throwAuraHandledException(exMsg);
            }
        }
        else {
            String exMsg = Label.PC_Ebenefits_Invalid_Response + '(' + res.getStatusCode() + ')' + res.getBody();
            PC_Utility.throwAuraHandledException(exMsg);
        }
        return null;
    }

    /*public string getBinDetails(PC_UBC.PlanNameServiceResponse planServiceResponse) {
        if(planServiceResponse != null && planServiceResponse.AdditionalIds != null) {
            for(PC_UBC.AdditionalIds Id: planServiceResponse.AdditionalIds) {
                if(Id.Authority.toLowerCase() == 'rx.bin.primary') {
                    return Id.IssuedId;
                }
            }
        }
        return null;
    }*/

    /*public string getPcnDetails(PC_UBC.PlanNameServiceResponse planServiceResponse) {
        if(planServiceResponse != null && planServiceResponse.AdditionalIds != null) {
            for(PC_UBC.AdditionalIds Id: planServiceResponse.AdditionalIds) {
                if(Id.Authority.toLowerCase() == 'rx.pcn.primary') {
                    return Id.IssuedId;
                }
            }
        }
        return null;
    }*/

    public List<PC_UBC.Pharmacy> searchPharmacies(PC_eBenefits.PharmacySearchParams params) {

        string searchType = PC_Constants.PC_AND;
        List<String> specialtyTypes = new List<String>();
        String specialtySearchQuery =PC_Constants.EMPTY_STRING;


        if(params != null && params.searchBy != null) {
            PC_UBC_Utility client = new PC_UBC_Utility();
            client.authenticateViaNamedCreds();

            String searchQueryString = '/?';
            if(params.searchBy == PC_eBenefits.PharmacySearchBy.NPI) {
                if(String.isNotBlank(params.npi)) {
                    searchQueryString += '&NPI=' + params.npi;
                }
            }

            else if(params.searchBy == PC_eBenefits.PharmacySearchBy.NPI_NCPDP_POSTALCODE ){

                if(String.isNotBlank(params.npi)) {
                    searchQueryString += '&NPI=' + params.npi;
                }

                /*if (String.isNotBlank(params.ncpdp)) {
                    searchQueryString += '&NCPDP=' + params.ncpdp;
                }*/

                if ( String.isNotBlank(params.zipCode) && String.isNotBlank(params.npi) ) {
                    searchQueryString += '&PostalCode=' + params.zipCode;
                }

            }


            else {

                if (searchType == PC_Constants.PC_OR) {



                    if (params.isSpecialty) {
                        searchQueryString += '&SpecialtyTypes=' + 'Specialty';
                    }
                    if (params.isLongTerm) {
                        searchQueryString += '&SpecialtyTypes=' + 'LongTermCare';
                    }
                    if (params.isRetail) {
                        searchQueryString += '&SpecialtyTypes=' + 'Retail';
                    }
                    if (params.isMailOrder) {
                        searchQueryString += '&SpecialtyTypes=' + 'MailOrder';
                    }
                    if (String.isNotBlank(params.name)) {
                        searchQueryString += '&name=' + params.name;
                    }
                    if (String.isNotBlank(params.zipCode)) {
                        searchQueryString += '&postalCode=' + params.zipCode;
                    }
                }
                else{
                    specialtySearchQuery +='Filter=all({\"specialtyTypes\":';


                    if (params.isSpecialty) {
                        specialtyTypes.add('Specialty');
                    }
                    if (params.isLongTerm) {
                        specialtyTypes.add('LongTermCare');
                    }
                    if (params.isRetail) {
                        specialtyTypes.add('Retail');
                    }
                    if (params.isMailOrder) {
                        specialtyTypes.add('MailOrder');
                    }

                    if(specialtyTypes.size() > 0){

                        specialtySearchQuery +=JSON.serialize(specialtyTypes);
                        specialtySearchQuery += '})';
                        system.debug('specialtySearchQuery -->' +specialtySearchQuery);
                    }

                    if (String.isNotBlank(params.name)) {
                        searchQueryString += '&name=' + params.name;
                    }
                    if (String.isNotBlank(params.zipCode)) {
                        searchQueryString += '&postalCode=' + params.zipCode;
                    }
                }
            }

            if(searchQueryString =='/?' &&  specialtyTypes.size() >0){
                searchQueryString = 'And' + searchQueryString;
            }
            system.debug('searchQueryString = ' + searchQueryString);
            if(searchQueryString != '/?') {

                if(searchType != PC_Constants.PC_OR && specialtyTypes.size()>0){
                    system.debug('specialtySearchQuery before encoding-->'+specialtySearchQuery);
                    searchQueryString = '?'+specialtySearchQuery + searchQueryString.substringAfter('?');
                    system.debug('search string before encoding-->'+searchQueryString);
                    //searchQueryString= EncodingUtil.urlEncode(searchQueryString,'UTF-8').replace('+', '%20');
                    searchQueryString= EncodingUtil.urlEncode(searchQueryString,'UTF-8');
                    searchQueryString = '/'+searchQueryString;
                }else
                {
                    searchQueryString = searchQueryString.substringAfter('/');
                    searchQueryString= EncodingUtil.urlEncode(searchQueryString,'UTF-8');
                    searchQueryString = '/'+searchQueryString;
                }

                searchQueryString +=  '&Count=100';
                system.debug('searchQueryString after encoding = ' + searchQueryString);
                HttpRequest req = new HttpRequest();
                String namedCred = PC_eBenefits.getEbenefitsNamedCredential(PC_Constants.PC_eBENEFITS_PHARMACY_FINDER_SERVICE_TYPE);
                req.setEndpoint('callout:' +namedCred +searchQueryString);
                req.setMethod('GET');
                req.setTimeout(timeoutSeconds);
                req.setHeader('Accept', 'application/json, text/json');
                req.setHeader('accept-encoding', 'gzip, deflate');
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('Cache-Control', 'no-cache');
                req.setHeader('Authorization', 'Bearer ' + accessToken);

                Http http = new Http();
                HTTPResponse res = http.send(req);
                system.debug('printing response for search pharmacies');
                system.debug('status code -> ' + res.getStatusCode());
                system.debug('status code -> ' + res.getBody());
                if(res.getStatusCode() == 200) {
                    String resBody = res.getBody();
                    if (String.isNotBlank(resBody)) {
                        List<Object> pharmaciesObj = (List<Object>) JSON.deserializeUntyped(resBody);
                        List<PC_UBC.Pharmacy> pharmacies = new List<PC_UBC.Pharmacy>();
                        PC_UBC.Pharmacy pharmacy;
                        Map<String, Object> m;
                        String mapString;
                        for (Object pharmacyObj : pharmaciesObj) {
                            m = (Map<String, Object>) pharmacyObj;
                            mapString = System.JSON.serialize(m);

                            pharmacy = (PC_UBC.Pharmacy) System.JSON.deserialize(mapString, PC_UBC.Pharmacy.class);
                            pharmacies.add(pharmacy);

                        }

                        return pharmacies;
                    }
                }
                else if(res.getStatusCode() == 404){
                    return new List<PC_UBC.Pharmacy> ();
                }
                else {
                    PC_Utility.throwAuraHandledException(Label.PC_PharmacyFinder_UBC_No_Pharmacies_Found + res.getBody());

                }
            }
            else {
                system.debug('search pharmacy not fired since no query parameters found');
            }
        }
        return new List<PC_UBC.Pharmacy>();

    }

    public static String getPARequired(PC_eBenefits.PharmacyBenefitsResponse  coverageDetails) {
        if(coverageDetails != null && coverageDetails.eBenefitsServiceResponse != null) {
            PC_eBenefits.PharmacyEbenefitsServiceResponse benefitsResponse = coverageDetails.eBenefitsServiceResponse;
            /*List<PC_eBenefits.CoverageAlerts> coverageAlerts = benefitsResponse.coverageAlerts;
            for(PC_eBenefits.CoverageAlerts alert : coverageAlerts) {
                if(alert.name == PC_UBC.COVERAGE_ALERT_PA_Required) {
                    return PC_Constants.PROGRAM_COVERAGE_PRIOR_AUTHORIZATION_REQUIRED_YES;
                }
            }*/

            if( benefitsResponse.priorAuthorization !=null){
                boolean priorAuthValue = benefitsResponse.priorAuthorization.isRequired;
                if (priorAuthValue != null) {
                    if (priorAuthValue)
                        return PC_Constants.PROGRAM_COVERAGE_PRIOR_AUTHORIZATION_REQUIRED_YES;
                    else
                        return PC_Constants.PROGRAM_COVERAGE_PRIOR_AUTHORIZATION_REQUIRED_NO;
                }
            }
        }
        return PC_Constants.EMPTY_STRING;
    }

    public string getPlanName(PC_UBC.PlanNameServiceResponse planServiceResponse) {
        if(planServiceResponse != null && planServiceResponse.Name != null) {
            return planServiceResponse.Name;
        }
        return PC_Constants.EMPTY_STRING;
    }

    public PC_eBenefits.PharmacyCardResponse convertPharmaCardServiceResponse(PC_UBC.EligibilityServiceResponse planServiceResponse) {
        PC_eBenefits.PharmacyCardResponse response = new PC_eBenefits.PharmacyCardResponse();
        List<String> picklistvalues = new List<String>();

        response.BIN = planServiceResponse.pbms[0].plans[0].insurance.bin;
        response.insuranceGroupId = planServiceResponse.pbms[0].plans[0].insurance.insuranceGroup.groupId;
        response.insuranceGroupName = planServiceResponse.pbms[0].plans[0].insurance.insuranceGroup.name;
        response.id=planServiceResponse.id;
        response.PCN = planServiceResponse.pbms[0].plans[0].insurance.pcn;
        response.planName = planServiceResponse.pbms[0].plans[0].name;
        response.PolicyID = planServiceResponse.pbms[0].plans[0].insurance.policyId;
        response.extId = planServiceResponse.pbms[0].plans[0].insurance.id;
        PC_UBC_Utility client = new PC_UBC_Utility();
        response.retailCoverage = client.getCoverage(PC_eBenefits_Utility.RETAIL_PHARMACYTYPE_LABEL, planServiceResponse);
        response.mailCoverage = client.getCoverage(PC_eBenefits_Utility.MAILORDER_PHARMACYTYPE_LABEL, planServiceResponse);
        response.longTermCareCoverage = client.getCoverage(PC_eBenefits_Utility.LONGTERMCARE_PHARMACYTYPE_LABEL, planServiceResponse);
        response.specialtyCoverage = client.getCoverage(PC_eBenefits_Utility.SPECIALTY_PHARMACYTYPE_LABEL, planServiceResponse);


        PC_eBenefits.Patient member = new PC_eBenefits.Patient();
        member.firstName = planServiceResponse.pbms[0].plans[0].memberInfo.firstName;
        member.lastName = planServiceResponse.pbms[0].plans[0].memberInfo.lastName;
        picklistvalues=getPickListValuesIntoList(PC_Constants.getQualifiedAPIName('PC_Health_Plan__c'),PC_Constants.getQualifiedAPIName('PC_Card_Holder_Gender__c'));
        if(picklistvalues!=null && !picklistvalues.isEmpty() && planServiceResponse.pbms[0].plans[0].memberInfo.gender!=null) {
            for (String v : picklistvalues) {
                if (v.equals(planServiceResponse.pbms[0].plans[0].memberInfo.gender)) {
                    member.gender = planServiceResponse.pbms[0].plans[0].memberInfo.gender;
                }
            }
        }

        if(null!=planServiceResponse.pbms[0].plans[0].memberInfo.birthdate) {
            member.birthdate = Date.valueOf(planServiceResponse.pbms[0].plans[0].memberInfo.birthdate).format();
            member.dob = Date.valueOf(planServiceResponse.pbms[0].plans[0].memberInfo.birthdate);
        }
        picklistvalues=getPickListValuesIntoList(PC_Constants.getQualifiedAPIName('PC_Health_Plan__c'),PC_Constants.getQualifiedAPIName('PC_Cardholder_Relationship_to_Patient__c'));
        if(picklistvalues!=null && !picklistvalues.isEmpty() && planServiceResponse.pbms[0].plans[0].memberInfo.relationship!=null) {
           for(String v :picklistvalues){
               if(v.equals(planServiceResponse.pbms[0].plans[0].memberInfo.relationship)){
                   member.cardHolderRelationship = planServiceResponse.pbms[0].plans[0].memberInfo.relationship;
               }
           }
        }
        response.subscriber = member;

        PC_eBenefits.Address memberAddress = new PC_eBenefits.Address();
        memberAddress.city = planServiceResponse.pbms[0].plans[0].memberInfo.address.city;
        memberAddress.state = planServiceResponse.pbms[0].plans[0].memberInfo.address.state;
        memberAddress.postalCode = planServiceResponse.pbms[0].plans[0].memberInfo.address.postalCode;

        response.subscriber.address = memberAddress;
        response.allServiceResponses = planServiceResponse.allServiceResponses;

        if(String.isNotBlank(planServiceResponse.requestDate)) {
           response.requestDate = PC_eBenefits_Utility.parseDatetimeFromJSON(planServiceResponse.requestDate);
        }
        return response;
    }

    public boolean getCoverage(String coverageName, PC_UBC.EligibilityServiceResponse planServiceResponse) {
        for(PC_UBC.PBMSWrapper pbm : planServiceResponse.pbms) {
            for(PC_UBC.Plan pbmPlan : pbm.plans) {
                for(PC_UBC.Coverage pbmPlanCoverage : pbmPlan.coverage) {
                    if(pbmPlanCoverage.pharmacyType.toLowerCase() == coverageName.toLowerCase()){
                       if(pbmPlanCoverage.isCovered!=null && pbmPlanCoverage.isCovered){
                           return true;
                       }
                    }
                }
            }
        }
        return false;
    }
    public PC_eBenefits.PharmacyCardResponse setPharmacyCardResponseLabels(PC_eBenefits.PharmacyCardResponse response) {
        if(response != null) {
            response.planNameLabel = 'PN';
            response.pcnLabel = PC_Health_Plan__c.PC_Rx_PCN__c.getDescribe().getLabel();
            response.insuranceGroupNameLabel = PC_Health_Plan__c.PC_Group_name__c.getDescribe().getLabel();
            response.insuranceGroupIdLabel = PC_Health_Plan__c.Group_No__c.getDescribe().getLabel();
            response.binLabel = PC_Health_Plan__c.PC_Rx_Bin__c.getDescribe().getLabel();
            response.policyIDLabel = PC_Health_Plan__c.ID_Policy_No__c.getDescribe().getLabel();
            response.mailCoverageLabel = PC_Health_Plan__c.PC_Has_Mail_Coverage__c.getDescribe().getLabel();
            response.retailCoverageLabel = PC_Health_Plan__c.PC_Has_Retail_Coverage__c.getDescribe().getLabel();
            response.longTermCareCoverageLabel = PC_Health_Plan__c.PC_Has_LTC_Coverage__c.getDescribe().getLabel();
            response.specialtyCoverageLabel = PC_Health_Plan__c.PC_Has_Specialty_Coverage__c.getDescribe().getLabel();


            response.subscriber.nameLabel = Account.Name.getDescribe().getLabel();
            response.subscriber.birthdateLabel = Account.PC_Date_of_Birth__c.getDescribe().getLabel();
            response.subscriber.genderLabel = Account.PC_Gender__c.getDescribe().getLabel();
            response.subscriber.cardHolderRelationshipLabel =PC_Health_Plan__c.PC_Cardholder_Relationship_to_Patient__c.getDescribe().getLabel();


            response.subscriber.address.postalCodeLabel = PC_Address__c.PC_Zip_Code__c.getDescribe().getLabel();
            response.subscriber.address.cityLabel = PC_Address__c.PC_City__c.getDescribe().getLabel();
            response.subscriber.address.stateLabel = PC_Address__c.PC_State__c.getDescribe().getLabel();
            return response;
        }
        else {
            return null;
        }


    }


    //////////////////////////////////

    public PC_UBC.PharmacyCoverageServiceResponse checkPharmacyCoverageBenefits(PC_UBC.PharmacyCoverageServiceInput serviceInput) {
        HttpRequest req = new HttpRequest();
        String namedCred = PC_eBenefits.getEbenefitsNamedCredential(PC_Constants.PC_eBENEFITS_PHARMACY_COVERAGE_SERVICE_TYPE);
        req.setEndpoint('callout:' + namedCred);
        req.setMethod('POST');
        req.setTimeout(timeoutSeconds);
        req.setHeader('Accept', 'application/json, text/json');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Cache-Control', 'no-cache');
        req.setHeader('Authorization', 'Bearer ' + accessToken);

        Map<String, Object> body = new Map<String, Object>();
        body.put('Patient', serviceInput.patient);
        body.put('AdditionalIds', serviceInput.additionalIds);
        //body.put('Card', serviceInput.Card);
        body.put('Prescriber', serviceInput.prescriber);
        body.put('Prescription', serviceInput.prescription);
        //body.put('Pharmacy', serviceInput.Pharmacy);
        //body.put('NinetyDayPricing', null);
        //body.put('accumulators', serviceInput.accumulators);
        //body.put('CoverageAlerts', serviceInput.CoverageAlerts);
        //body.put('Id', null);

        system.debug('request body sent to RTBC');
        system.debug(JSON.serialize(body));
        req.setBody(JSON.serialize(body));

        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug('service2 response');
        system.debug(res.getStatusCode());
        system.debug(res.getBody());
        PC_UBC.PharmacyCoverageServiceResponse serviceResponse;
        if(res.getStatusCode() == 201 || res.getStatusCode() == 200) {
            serviceResponse = (PC_UBC.PharmacyCoverageServiceResponse) JSON.deserialize(res.getBody(), PC_UBC.PharmacyCoverageServiceResponse.class);
            serviceResponse.serviceResponse = res.getBody();
            system.debug(serviceResponse);
            //return serviceResponse;
        }
        else {
            system.debug('fail');
            system.debug(res.getBody());
            serviceResponse = (PC_UBC.PharmacyCoverageServiceResponse) JSON.deserialize(res.getBody(), PC_UBC.PharmacyCoverageServiceResponse.class);
            serviceResponse.serviceResponse = res.getBody();
            /*String errorMessage = '';
            if(serviceResponse.responseStatus != null) {
                errorMessage = serviceResponse.responseStatus.internalMessage;
            }
            else if(serviceResponse.modelState != null) {
                List<String[]> msgs = serviceResponse.modelState.values();
                for(String[] m : msgs) {
                    errorMessage += String.join(m, ',');
                    errorMessage += '.';
                }
            }*/



            //return serviceResponse;
        }
        Map<String, String> serviceResponses = serviceResponse.allServiceResponses;
        if(serviceResponse.allServiceResponses == null) {
            serviceResponses = new Map<String, String>();
        }

        serviceResponses.put(PC_UBC.SERVICE_RESPONSE_RTBC, res.getBody());

        serviceResponse.allServiceResponses = serviceResponses;

        return serviceResponse;
    }

    public PC_UBC.PharmacyCoverageServiceResponse example2() {
        //String response = '{"patient":{"firstName":"RONALD","lastName":"LACY","birthdate":"1972-03-15T00:00:00Z","authority":"","issuedId":""},"prescriber":{"npi":"1497827612","authority":"","issuedId":""},"prescription":{"product":{"name":"Entyvio","ndc":"64764030020","authority":"","issuedId":""},"quantity":1.0,"daysSupply":30,"includeHomeDelivery":true,"include90DaysRetail":true,"includeDrugAlternativePricing":false},"pharmacy":{"identifier":"1558443911","type":"NPI","authority":"","issuedId":""},"card":{"groupId":"332425055AG020","memberId":"9383998188","pbmMemberId":"332425055AG020%9383998188%001","authority":"","issuedId":""},"daysSupplyPriced":60,"metricQuantityPriced":2.0,"accumulators":{"deductible":{"individual":{"applied":0.0,"remaining":0.0}},"outOfPocket":{"individual":{"applied":100.0,"remaining":1625.0}}},"pricing":{"patient":100.0,"plan":11720.59},"coverageAlerts":[{"name":"DaysSupplyExceeded","id":"cf1304f6-095e-4228-8710-a81100f19c64"},{"name":"PriorAuthRequired","id":"e6e9dcd5-39bb-47b5-8441-a81100f19c64"}],"id":"4ac6ea98-b5c6-4c1d-ac28-a81100f19c64"}';
        String response = '{"additionalIds":[],"patient":{"firstName":"Teague","lastName":"Rodgersson","birthdate":"2010-05-01T00:00:00Z","gender":"M"},"prescriber":{"npi":"1104865617"},"prescription":{"product":{"name":"Pulmozyme 1mg/ml Ampule","ndc":"50242010039","unitOfMeasureCode":"C48473","drugDbSourceCode":"FDB","productCodeQualifier":"ND","codeListQualifier":"38"},"quantity":90.0,"daysSupply":90,"includeHomeDelivery":false,"include90DaysRetail":true,"includeDrugAlternativePricing":false},"pharmacy":{"type":"MailOrder","pharmacyType":["Retail","Specialty","LongTermCare","SupportsDigitalSignature"],"npi":"1801849179","ncpdpid":"9911557","name":"CA Pharmacy 10.6MU","phone":"7072107071"},"card":{"groupId":"R230036","memberId":"PBMF TESTKID 8951-001","pbmMemberId":"R230036%PBMF TESTKID 8951-001"},"daysSupplyPriced":15,"metricQuantityPriced":30.0,"quantityPricedUnitOfMeasurementCode":"C48473","accumulators":{"deductible":{"individual":{"applied":300.0,"remaining":750.0}},"outOfPocket":{"individual":{"applied":null,"remaining":null}},"refills":{"individual":{"remaining":1.0}}},"pricing":{"patient":3367.0,"plan":857.0},"isPriorAuthRequired":true,"coverageAlerts":[{"name":"QuantityLimits","description":"30 per 30 Days","id":"dcbe174b-3a91-49c4-b6a8-a8d9006a7b51"},{"name":"ResourceLink","description":"www.pulmozyme.com","id":"417d7b6d-4ca8-449c-85ed-a8d9006a7b51"},{"name":"TextMessage","description":"THIS DRUG REQUIRES A NEBULIZER","id":"afdbc864-4171-413f-9d88-a8d9006a7b51"},{"name":"PriorAuthRequired","description":"Prior authorization is required.","id":"0ecc7f9f-ac34-4b3d-9115-a8d9006a7b51"}],"responseStatus":{"statusCode":200.0,"ownerId":49,"culture":"EN-US","isError":false},"id":"72b36cfe-3b7f-45e3-ab79-a8d9006a7b51"}';
        PC_UBC.PharmacyCoverageServiceResponse responseObj = (PC_UBC.PharmacyCoverageServiceResponse) JSON.deserialize(response, PC_UBC.PharmacyCoverageServiceResponse.class);
        system.debug(responseObj);
        return responseObj;

    }

    public PC_UBC.PharmacyCoverageServiceInput getServiceInput(String caseId,
            String healthPlanId, String pharmacyId, String prescriptionId,
            String daysSupply, String quantity)
    {
        PC_UBC.PharmacyCoverageServiceInput serviceInput = new PC_UBC.PharmacyCoverageServiceInput();

        List<String> fields = new List<String>();
        fields.add('Id');
        fields.add('Account.Name');
        fields.add('Account' + '.' + PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c'));
        fields.add('Account' + '.' + PC_Constants.getQualifiedAPIName('PC_Gender__c'));
        fields.add('Account' + '.' + PC_Constants.getQualifiedAPIName('PC_First_Name__c'));
        fields.add('Account' + '.' + PC_Constants.getQualifiedAPIName('PC_Last_Name__c'));
        fields.add('Account' + '.' + PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'));
        fields.add('Account' + '.' + PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'));
        fields.add('Account' + '.' + PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'));
        fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + 'ID');
        fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + PC_Constants.getQualifiedAPIName('PC_First_Name__c'));
        fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Last_Name__c'));
        fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + 'Name');
        fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + PC_Constants.getQualifiedAPIName('PC_NPI__c'));
        fields.add(PC_Constants.getQualifiedAPIName('PC_Program_Product__r') + '.' + 'Id');
        fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Product__c'));
        PC_Database.assertAccess('Case', PC_Database.Operation.Reading, fields);

        Case currentCase = [Select Id,
                Account.Name, Account.PC_Date_of_Birth__c, Account.PC_Gender__c,
                Account.PC_First_Name__c, Account.PC_Last_Name__c,
                Account.PC_Primary_City__c, Account.PC_Primary_State__c, Account.PC_Primary_Zip_Code__c,
                PC_Physician__r.Id, PC_Physician__r.PC_First_Name__c, PC_Physician__r.PC_Last_Name__c,
                PC_Physician__r.Name, PC_Physician__r.PC_NPI__c,
                PC_Program_Product__r.Id, PC_Program_Product__r.PC_Product__c ,
                PC_Engagement_Program__c
        From Case where id=:caseId];

        //String productId = currentCase.PC_Program_Product__r.PC_Product__c;
        String productId;
        system.debug('prescriptoin = ' + prescriptionId);
        PC_Prescription__c[] prescriptions = [SELECT ID, PC_Product__c FROM PC_Prescription__c WHERE ID =:prescriptionId];
        if(prescriptions != null && !prescriptions.isEmpty() && prescriptions.size() == 1) {
            productId = prescriptions[0].PC_Product__c;
        }

        PC_UBC.Patient patient = new PC_UBC.Patient();
        patient.FirstName = currentCase.Account.PC_First_Name__c;
        patient.LastName = currentCase.Account.PC_Last_Name__c;
        patient.Birthdate = String.valueOf(currentCase.Account.PC_Date_of_Birth__c);
        patient.gender = currentCase.Account.PC_Gender__c;
        patient.Authority = PC_Constants.EMPTY_STRING;
        patient.IssuedId = PC_Constants.EMPTY_STRING;
        PC_UBC.MemberAddress address = new PC_UBC.MemberAddress();
        address.city = currentCase.Account.PC_Primary_City__c;
        address.state = currentCase.Account.PC_Primary_State__c;
        address.postalCode = currentCase.Account.PC_Primary_Zip_Code__c;
        patient.address = address;
        serviceInput.Patient = patient;

        List<String> accountFields = new List<String>();
        accountFields.add('Id');
        accountFields.add('Name');
        accountFields.add(PC_Constants.getQualifiedAPIName('PC_NPI__c'));
        accountFields.add(PC_Constants.getQualifiedAPIName('PC_Mail_Only__c'));
        PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, accountFields);

        PC_UBC.Prescription prescription = new PC_UBC.Prescription();
        Account selectedPharmacy = [SELECT ID, NAME, PC_NPI__c, PC_Mail_Only__c FROM Account where id =:pharmacyId];
        prescription.DaysSupply = daysSupply;
        prescription.Include90DaysRetail = true;
        prescription.Quantity = quantity;
        prescription.IncludeHomeDelivery = selectedPharmacy.PC_Mail_Only__c;

        PC_UBC.Product productInput = new PC_UBC.Product();
        if(String.isNotBlank(productId)) {

            List<String> product2Fields = new List<String>();
            product2Fields.add('Id');
            product2Fields.add('Name');
            product2Fields.add('ProductCode');
            product2Fields.add(PC_Constants.getQualifiedAPIName('PC_NDC__c'));
            PC_Database.assertAccess('Product2', PC_Database.Operation.Reading, product2Fields);

            Product2 product = [Select id, ProductCode, Name, PC_NDC__c FROM Product2 where id= :productId];
            productInput.Name = product.Name;
            productInput.NDC = product.PC_NDC__c;
            productInput.Authority = PC_Constants.EMPTY_STRING;
            productInput.issueId = PC_Constants.EMPTY_STRING;
            productInput.unitOfMeasureCode = getUnitOfMeasureCode(product.Name, product.PC_NDC__c);
            productInput.drugDbSourceCode = 'FDB';
            productInput.productCodeQualifier = 'ND';
            productInput.codeListQualifier = '38';
        }

        prescription.Product = productInput;
        serviceInput.Prescription = prescription;

        List<String> healthPlanFields = new List<String>();
        healthPlanFields.add('Id');
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('ID_Policy_No__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_PBMMember_Id__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('Group_No__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Group_name__c'));
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Health_Plan__c'), PC_Database.Operation.Reading, healthPlanFields);

        PC_Health_Plan__c currentHealthPlan = [Select id, ID_Policy_No__c,
                PC_PBMMember_Id__c, Group_No__c, PC_Group_name__c
        FROM PC_Health_Plan__c where id =:healthPlanId];

        PC_UBC.Card card = new PC_UBC.Card();
        card.GroupId = currentHealthPlan.Group_No__c;
        card.PbmMemberId = currentHealthPlan.PC_PBMMember_Id__c;
        card.MemberId = currentHealthPlan.ID_Policy_No__c;
        card.Authority = PC_Constants.EMPTY_STRING;
        card.IssuedId = PC_Constants.EMPTY_STRING;
        serviceInput.Card = card;

        PC_UBC.Pharmacy pharmacy = new PC_UBC.Pharmacy();
        pharmacy.Authority = PC_Constants.EMPTY_STRING;
        pharmacy.Type = 'NPI'; //todo...what value?
        pharmacy.Identifier = selectedPharmacy.PC_NPI__c;// todo...??
        pharmacy.IssuedId = PC_Constants.EMPTY_STRING;
        serviceInput.Pharmacy = pharmacy;

        PC_UBC.Prescriber prescriber = new PC_UBC.Prescriber();
        prescriber.Authority = PC_Constants.EMPTY_STRING;
        prescriber.IssuedId = PC_Constants.EMPTY_STRING;
        prescriber.NPI = currentCase.PC_Physician__r.PC_NPI__c;
        serviceInput.Prescriber = prescriber;

        serviceInput.NinetyDayPricing = null;
        serviceInput.accumulators = new PC_UBC.accumulators();
        serviceInput.pricing = new PC_UBC.pricing();
        serviceInput.CoverageAlerts = new List<String>();
        serviceInput.Id = null;

        system.debug('service2 input');
        system.debug(JSON.serialize(serviceInput));
        return serviceInput;
    }

    public PC_UBC.PharmacyCoverageServiceInput getServiceInput(PC_eBenefits.PharmacyBenefitsRequest request)
    {
        PC_UBC.PharmacyCoverageServiceInput serviceInput = new PC_UBC.PharmacyCoverageServiceInput();

        PC_UBC.Patient patient = new PC_UBC.Patient();
        patient.FirstName = request.patient.firstName;
        patient.LastName = request.patient.lastName;
        patient.Birthdate = String.valueOf(request.patient.birthdate);
        patient.gender = request.patient.gender;
        patient.Authority = PC_Constants.EMPTY_STRING;
        patient.IssuedId = PC_Constants.EMPTY_STRING;

        PC_UBC.MemberAddress address = new PC_UBC.MemberAddress();
        address.city = request.patient.address.city;
        address.state = request.patient.address.state;
        address.postalCode = request.patient.address.postalCode;

        patient.address = address;
        serviceInput.Patient = patient;



        PC_UBC.Prescription prescription = new PC_UBC.Prescription();

        Integer daysSupply;
        if(request.prescription.daysSupply != null) {
            daysSupply = request.prescription.daysSupply.intValue();
        }
        prescription.DaysSupply = String.valueOf(daysSupply);
        prescription.Include90DaysRetail = true;
        prescription.Quantity = String.valueOf(request.prescription.requestedQuantity);
        prescription.IncludeHomeDelivery = request.prescription.includeHomeDelivery;

        PC_UBC.Product productInput = new PC_UBC.Product();

        productInput.Name = request.drug.name;
        productInput.NDC = request.drug.ndc;
        productInput.Authority = PC_Constants.EMPTY_STRING;
        productInput.issueId = PC_Constants.EMPTY_STRING;
        productInput.unitOfMeasureCode = request.drug.unitOfMeasureCode;////getUnitOfMeasureCode(request.drug.name, request.drug.ndc);
        productInput.drugDbSourceCode = 'FDB';
        productInput.productCodeQualifier = 'ND';
        productInput.codeListQualifier = '38';


        prescription.Product = productInput;
        serviceInput.Prescription = prescription;

        PC_UBC.Card card = new PC_UBC.Card();
        card.GroupId = request.card.groupId;
        card.PbmMemberId = request.card.pbmMemberId;
        card.MemberId = request.card.memberId;
        card.Authority = PC_Constants.EMPTY_STRING;
        card.IssuedId = PC_Constants.EMPTY_STRING;
        serviceInput.Card = card;

        PC_UBC.Pharmacy pharmacy = new PC_UBC.Pharmacy();
        pharmacy.Authority = PC_Constants.EMPTY_STRING;
        pharmacy.Type = 'NPI'; //todo...what value?
        pharmacy.Identifier = request.pharmacy.npi;// todo...??
        //pharmacy.IssuedId = '';
        pharmacy.addresses = new List<PC_UBC.MemberAddress>();
        PC_UBC.MemberAddress memberAddress = new PC_UBC.MemberAddress();
        memberAddress.postalCode = request.pharmacy.zipCode;
        //pharmacy.addresses[0].postalCode =request.pharmacy.zipCode;
        pharmacy.addresses.add(memberAddress);
        pharmacy.ncpdp = request.pharmacy.ncpdp;
        pharmacy.npi =  request.pharmacy.npi;
        serviceInput.Pharmacy = pharmacy;


        PC_UBC.Prescriber prescriber = new PC_UBC.Prescriber();
        prescriber.Authority = PC_Constants.EMPTY_STRING;
        prescriber.IssuedId = PC_Constants.EMPTY_STRING;
        prescriber.NPI = request.physician.npi;
        serviceInput.Prescriber = prescriber;

        serviceInput.NinetyDayPricing = null;
        serviceInput.accumulators = new PC_UBC.accumulators();
        serviceInput.pricing = new PC_UBC.pricing();
        serviceInput.CoverageAlerts = new List<String>();
        serviceInput.Id = null;

        system.debug('service2 input');
        system.debug(JSON.serialize(serviceInput));
        return serviceInput;
    }

    public static string getUnitOfMeasureCode(String drugName, String ndc) {

        if(drugName.containsIgnoreCase('entyvio')) {
            return 'C48480';
        }
        else if(drugName.containsIgnoreCase('CLOMIPRAMINE')) {
            return 'C48480';
        }
        else if(drugName.containsIgnoreCase(PC_Constants.EMPTY_STRING)) {
            return 'C48540';
        }
        return 'C48480';
    }



    // This method is usually used to get the account details to be passed for UBC.
    private static Account getAccount(String id) {
        Account acc = [SELECT ID, PC_First_Name__c, PC_Last_Name__c, PC_Date_of_Birth__c,
                PC_Gender__c, PC_Primary_City__c, PC_Primary_State__c,
                PC_Primary_Zip_Code__c, PC_NPI__c
                FROM Account
        WHERE ID=:id];
        return acc;

    }

    public PC_eBenefits.PharmacyCardRequest getPharmacyCardRequest(String healthPlanId, String physicianId) {

        try {
            PC_eBenefits.PharmacyCardRequest cardHolderInfo = new PC_eBenefits.PharmacyCardRequest();

            PC_eBenefits.Physician physician = getPhysicianInfo(physicianId);
            PC_eBenefits.Patient cardHolder = getCardHolderInfo(healthPlanId);

            cardHolderInfo.patient = cardHolder;
            cardHolderInfo.physician = physician;

            return cardHolderInfo;

        }
        catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    public static PC_eBenefits.Patient getCardHolderInfo(Id healthPlanId) {
        try {
            PC_Health_Plan__c healthPlan;
            PC_eBenefits.Patient patient = new PC_eBenefits.Patient();

            //Check FLS/CRUD before SOQL

            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Card_Holder_First_Name__c'), PC_Constants.getQualifiedAPIName('PC_Card_Holder_Last_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Card_Holder_Gender__c'), PC_Constants.getQualifiedAPIName('PC_Cardholder_s_Date_of_Birth__c'), PC_Constants.getQualifiedAPIName('PC_Card_Holder_City__c'), PC_Constants.getQualifiedAPIName('PC_Card_Holder_State__c'), PC_Constants.getQualifiedAPIName('PC_Card_Holder_ZipCode__c')};

            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Health_Plan__c'),PC_Database.Operation.Reading, fields);

            if(healthPlanId!=null) {
                healthPlan = [
                        Select Id, PC_Card_Holder_First_Name__c, PC_Card_Holder_Last_Name__c, PC_Card_Holder_Gender__c,
                                PC_Cardholder_s_Date_of_Birth__c,PC_Card_Holder_City__c, PC_Card_Holder_State__c, PC_Card_Holder_ZipCode__c
                        FROM PC_Health_Plan__c
                        where Id = :healthPlanId
                ];


                patient.firstName = healthPlan.PC_Card_Holder_First_Name__c;
                patient.lastName = healthPlan.PC_Card_Holder_Last_Name__c;
                //patient.birthdate = healthPlan.PC_Cardholder_s_Date_of_Birth__c == null ? null : healthPlan.PC_Cardholder_s_Date_of_Birth__c.format();
                patient.birthdate = PC_eBenefits_Utility.parseDateToJSONDate(healthPlan.PC_Cardholder_s_Date_of_Birth__c);
                patient.dob = healthPlan.PC_Cardholder_s_Date_of_Birth__c;
                patient.gender = healthPlan.PC_Card_Holder_Gender__c;
                PC_eBenefits.Address primaryAddr = new PC_eBenefits.Address();

                primaryaddr.city = healthPlan.PC_Card_Holder_City__c;
                primaryaddr.state = healthPlan.PC_Card_Holder_State__c;
                primaryaddr.postalCode = healthPlan.PC_Card_Holder_ZipCode__c;
                patient.nameLabel = Account.Name.getDescribe().getLabel();
                patient.genderLabel = Account.PC_Gender__c.getDescribe().getLabel();
                patient.birthdateLabel = Account.PC_Date_of_Birth__c.getDescribe().getLabel();
                primaryaddr.cityLabel = PC_Address__c.PC_City__c.getDescribe().getLabel();
                primaryaddr.stateLabel = PC_Address__c.PC_State__c.getDescribe().getLabel();
                primaryaddr.postalCodeLabel = PC_Address__c.PC_Zip_Code__c.getDescribe().getLabel();
                patient.address = primaryAddr;
            }

            return patient;
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    public static PC_eBenefits.Physician getPhysicianInfo(Id physicianId) {
        try {
            List<String> fields = new List<String>();
            fields.add('Id');
            fields.add('Name');
            fields.add(PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_NPI__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Gender__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_First_Name__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Last_Name__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Primary_City__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Primary_State__c'));
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, fields);

            Account physicianAccount = getAccount(physicianId);

            PC_eBenefits.Physician physician = new PC_eBenefits.Physician();
            PC_eBenefits.Address physicianAddress = new PC_eBenefits.Address();
            physician.address = physicianAddress;
            physician.firstName = physicianAccount.PC_First_Name__c;
            physician.lastName = physicianAccount.PC_Last_Name__c;
            physician.birthdate = physicianAccount.PC_Date_of_Birth__c != null ?
                    physicianAccount.PC_Date_of_Birth__c.format() : PC_Constants.EMPTY_STRING;
            physician.npi = physicianAccount.PC_NPI__c;
            physician.gender = physicianAccount.PC_Gender__c;
            physicianAddress.postalCode = physicianAccount.PC_Primary_Zip_Code__c;
            physicianAddress.state = physicianAccount.PC_Primary_State__c;
            physicianAddress.city = physicianAccount.PC_Primary_City__c;


            return physician;
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    public static String getPharmacyAdditionalId(String pharmacyId) {
        Account account = [SELECT ID, PC_External_ID__c FROM Account WHERE ID =:pharmacyId];
        return  account.PC_External_ID__c;
    }

    public static List<String> getPickListValuesIntoList(String object_name, String field_name) {
        List<String> values = new List<String>();
        String[] types = new String[]{object_name};
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
            for(Schema.DescribeSobjectResult res : results) {
                    for (Schema.PicklistEntry entry : res.fields.getMap().get(field_name).getDescribe().getPicklistValues()) {
                        if (entry.isActive()) {
                            values.add(entry.getValue());
                        }
                    }
                }
                return values;
    }





}