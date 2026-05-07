/*********************************************************************************************************
Class Name      : PC_VirMedica_MockWebServiceImp
Description     : Mock Implementation class to test VirMedica related functionality
Created By      : Shishir Bansal
Created Date    : April 07, 2019
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Shishir Bansal              April 07, 2019             Initial Version

*********************************************************************************************************/

@IsTest
public class PC_VirMedica_MockWebServiceImp implements WebServiceMock {
    public void doInvoke(
            Object stub,
            Object request,
            Map<String, Object> response,
            String endpoint,
            String soapAction,
            String requestName,
            String responseNS,
            String responseName,
            String responseType) {


        /*soapResponse ='GetMedeBVResponse_element:
        [apex_schema_type_info=(http://virmedica.com/api/soap, true, false),
        field_order_type_info=(response), response=medeBVResponse:[VMIPatientId=null,
        VMIPatientId_type_info=(VMIPatientId, http://virmedica.com/api/soap, null, 0, 1, false),
        apex_schema_type_info=(http://virmedica.com/api/soap, true, false), clientPatientId=null,
        clientPatientId_type_info=(clientPatientId, http://virmedica.com/api/soap, null, 0, 1, false),
        coordinatedPlanBenefits=null,
        coordinatedPlanBenefits_type_info=(coordinatedPlanBenefits, http://virmedica.com/api/soap, null, 0, 1, false),
        field_order_type_info=(responseId, responseTypeCode, clientPatientId, VMIPatientId, inputParameters,
        coordinatedPlanBenefits, policy1, policy2, policy3),
        inputParameters=medeBVRequest:[apex_schema_type_info=(http://virmedica.com/api/soap, true, false),
        clientPatientId=null, clientPatientId_type_info=(clientPatientId, http://virmedica.com/api/soap, null, 0, 1,
        false), cptCode1=null, cptCode1_type_info=(cptCode1, http://virmedica.com/api/soap, null, 0, 1, false),
        cptCode2=null, cptCode2_type_info=(cptCode2, http://virmedica.com/api/soap, null, 0, 1, false), cptCode3=null,
        cptCode3_type_info=(cptCode3, http://virmedica.com/api/soap, null, 0, 1, false), cptCode4=null,
        cptCode4_type_info=(cptCode4, http://virmedica.com/api/soap, null, 0, 1, false), cptCode5=null,
        cptCode5_type_info=(cptCode5, http://virmedica.com/api/soap, null, 0, 1, false),
        field_order_type_info=(clientPatientId, patientFirstName, patientLastName, patientDOB, patientGender,
        patientSSN, patientZip, product, cptCode1, cptCode2, ...), mfg=Amgen, mfg_type_info=(mfg,
        http://virmedica.com/api/soap, null, 1, 1, false), patientDOB=1965-08-12 00:00:00,
        patientDOB_type_info=(patientDOB, http://virmedica.com/api/soap, null, 1, 1, false),
        patientFirstName=Gerald, patientFirstName_type_info=(patientFirstName, http://virmedica.com/api/soap,
        null, 1, 1, false), patientGender=F, patientGender_type_info=(patientGender, http://virmedica.com/api/soap,
        null, 1, 1, false), patientLastName=Silva, patientLastName_type_info=(patientLastName,
        http://virmedica.com/api/soap, null, 1, 1, false), patientSSN=null, patientSSN_type_info=(patientSSN,
        http://virmedica.com/api/soap, null, 0, 1, false), patientZip=32003, patientZip_type_info=(patientZip,
        http://virmedica.com/api/soap, null, 0, 1, false),
        policy1Params=policyInfo:[apex_schema_type_info=(http://virmedica.com/api/soap, true, false),
        field_order_type_info=(policyMemberId, policyPayerId, policyPatientSubscriber, subscriberInfo),
        policyMemberId=A24825528, policyMemberId_type_info=(policyMemberId, http://virmedica.com/api/soap, null,
        1, 1, false), policyPatientSubscriber=null, policyPatientSubscriber_type_info=(policyPatientSubscriber,
        http://virmedica.com/api/soap, null, 0, 1, false), policyPayerId=19,
        policyPayerId_type_info=(policyPayerId, http://virmedica.com/api/soap, null, 1, 1, false),
        subscriberInfo=null, subscriberInfo_type_info=(subscriberInfo, http://virmedica.com/api/soap, null, 0,
        1, false)], policy1Params_type_info=(policy1Params, http://virmedica.com/api/soap, null, 1, 1, false),
        policy2Params=null, policy2Params_type_info=(policy2Params, http://virmedica.com/api/soap, null, 0, 1,
        false), policy3Params=null, policy3Params_type_info=(policy3Params, http://virmedica.com/api/soap, null,
        0, 1, false), pos=22, pos_type_info=(pos, http://virmedica.com/api/soap, null, 1, 1, false),
        practiceNPI=null, practiceNPI_type_info=(practiceNPI, http://virmedica.com/api/soap, null, 0, 1,
        false), practiceName=null, practiceName_type_info=(practiceName, http://virmedica.com/api/soap, null,
        0, 1, false), practiceState=null, practiceState_type_info=(practiceState, http://virmedica.com/api/soap,
        null, 0, 1, false), primaryDiagnosis=733.01, primaryDiagnosis_type_info=(primaryDiagnosis,
        http://virmedica.com/api/soap, null, 1, 1, false), product=Prolia, product_type_info=(product,
        http://virmedica.com/api/soap, null, 1, 1, false), providerFirstName=Parkas,
        providerFirstName_type_info=(providerFirstName, http://virmedica.com/api/soap, null, 1, 1, false),
        providerLastName=Wendy, providerLastName_type_info=(providerLastName, http://virmedica.com/api/soap,
        null, 1, 1, false), providerNPI=1306200621, providerNPI_type_info=(providerNPI,
        http://virmedica.com/api/soap, null, 1, 1, false), providerState=MN, providerState_type_info=
        (providerState, http://virmedica.com/api/soap, null, 1, 1, false), providerTaxId=null,
        providerTaxId_type_info=(providerTaxId, http://virmedica.com/api/soap, null, 0, 1, false),
        secondaryDiagnosis=null, secondaryDiagnosis_type_info=(secondaryDiagnosis, http://virmedica.com/api/soap,
        null, 0, 1, false)], inputParameters_type_info=(inputParameters, http://virmedica.com/api/soap, null, 1,
        1, false), policy1=medeBVPolicy:[apex_schema_type_info=(http://virmedica.com/api/soap, true, false),
        buyBill=yes, buyBill_type_info=(buyBill, http://virmedica.com/api/soap, null, 0, 1, false),
        clientField1=, clientField1_type_info=(clientField1, http://virmedica.com/api/soap, null, 0, 1, false),
        clientField2=, clientField2_type_info=(clientField2, http://virmedica.com/api/soap, null, 0, 1, false),
        clientField3=, clientField3_type_info=(clientField3, http://virmedica.com/api/soap, null, 0, 1, false),
        clientField4=, clientField4_type_info=(clientField4, http://virmedica.com/api/soap, null, 0, 1, false),
        clientField5=, clientField5_type_info=(clientField5, http://virmedica.com/api/soap, null, 0, 1, false),
        clientField6=, clientField6_type_info=(clientField6, http://virmedica.com/api/soap, null, 0, 1, false),
        cptCode1Result=null, cptCode1Result_type_info=(cptCode1Result, http://virmedica.com/api/soap, null, 0,
        1, false), cptCode2Result=null, cptCode2Result_type_info=(cptCode2Result, http://virmedica.com/api/soap,
        null, 0, 1, false), cptCode3Result=null, cptCode3Result_type_info=(cptCode3Result,
        http://virmedica.com/api/soap, null, 0, 1, false), cptCode4Result=null, cptCode4Result_type_info=
        (cptCode4Result, http://virmedica.com/api/soap, null, 0, 1, false), cptCode5Result=null,
        cptCode5Result_type_info=(cptCode5Result, http://virmedica.com/api/soap, null, 0, 1, false),
        customMessage1=, customMessage1_type_info=(customMessage1, http://virmedica.com/api/soap, null,
        0, 1, false), customMessage2=, customMessage2_type_info=(customMessage2, http://virmedica.com/api/soap,
        null, 0, 1, false),
        customMessage3=, customMessage3_type_info=(customMessage3, http://virmedica.com/api/soap, null, 0,
        1, false), customMessage4=, customMessage4_type_info=(customMessage4, http://virmedica.com/api/soap,
        null, 0, 1, false), dedFamAmt=NOT FOUND, dedFamAmtMet=NOT FOUND,
        dedFamAmtMet_type_info=(dedFamAmtMet, http://virmedica.com/api/soap, null, 0, 1, false),
        dedFamAmt_type_info=(dedFamAmt, http://virmedica.com/api/soap, null, 0, 1, false),
        dedIndAmt=$183.00, dedIndAmtMet=$183.00, dedIndAmtMet_type_info=(dedIndAmtMet,
        http://virmedica.com/api/soap, null, 0, 1, false), dedIndAmt_type_info=(dedIndAmt,
        http://virmedica.com/api/soap, null, 0, 1, false), effDate=2018-08-16 00:00:00,
        effDate_type_info=(effDate, http://virmedica.com/api/soap, null, 0, 1, false),
        eligibilityStatus=active, eligibilityStatus_type_info=(eligibilityStatus,
        http://virmedica.com/api/soap, null, 0, 1, false), endDate=null,
        endDate_type_info=(endDate, http://virmedica.com/api/soap, null, 0, 1, false),
        field_order_type_info=(transactionId, transactionDate, eligibilityStatus, effDate,
        endDate, payerName, planName, planType, groupNumber, groupName, ...),
        govInd=yes, govInd_type_info=(govInd, http://virmedica.com/api/soap, null, 0, 1, false),
        govPolicyType=Medicare, govPolicyType_type_info=(govPolicyType, http://virmedica.com/api/soap,
        null, 0, 1, false), groupName=, groupName_type_info=(groupName, http://virmedica.com/api/soap,
        null, 0, 1, false), groupNumber=, groupNumber_type_info=
        (groupNumber, http://virmedica.com/api/soap, null, 0, 1, false),
        medicalPolicy=null, medicalPolicy_type_info=(medicalPolicy, http://virmedica.com/api/soap,
        null, 0, 1, false), msgContent=null, msgContent_type_info=(msgContent,
        http://virmedica.com/api/soap, null, 0, 1, false), msgId=null,
        msgId_type_info=(msgId, http://virmedica.com/api/soap, null, 0, 1, false),
        officeCoinsAmt=20.00%, officeCoinsAmt_type_info=(officeCoinsAmt,
        http://virmedica.com/api/soap, null, 0, 1, false), officeCopayPCPAmt=NOT FOUND,
        officeCopayPCPAmt_type_info=(officeCopayPCPAmt, http://virmedica.com/api/soap,
        null, 0, 1, false), officeSpecCopayAmt=NOT FOUND, officeSpecCopayAmt_type_info=
        (officeSpecCopayAmt, http://virmedica.com/api/soap, null, 0, 1, false),
        officeVisitCoinsApplies=yes, officeVisitCoinsApplies_type_info=(officeVisitCoinsApplies,
        http://virmedica.com/api/soap, null, 0, 1, false), officeVisitCopayApplies=no,
        officeVisitCopayApplies_type_info=(officeVisitCopayApplies, http://virmedica.com/api/soap,
        null, 0, 1, false), officeVisitDedApplies=yes, officeVisitDedApplies_type_info=
        (officeVisitDedApplies, http://virmedica.com/api/soap, null, 0, 1, false),
        officeVisitOopMaxApplies=no, officeVisitOopMaxApplies_type_info=(officeVisitOopMaxApplies,
        http://virmedica.com/api/soap, null, 0, 1, false), officeVisitStatus=covered,
        officeVisitStatus_type_info=(officeVisitStatus, http://virmedica.com/api/soap,
        null, 0, 1, false), oopMaxFamAmt=null, oopMaxFamAmt_type_info=(oopMaxFamAmt,
        http://virmedica.com/api/soap, null, 0, 1, false), oopMaxFamMet=null,
        oopMaxFamMet_type_info=(oopMaxFamMet, http://virmedica.com/api/soap, null,
        0, 1, false), oopMaxIndAmt=null, oopMaxIndAmt_type_info=(oopMaxIndAmt,
        http://virmedica.com/api/soap, null, 0, 1, false), oopMaxIndMet=null,
        oopMaxIndMet_type_info=(oopMaxIndMet, http://virmedica.com/api/soap, null, 0, 1, false),
        payerName=Medicare, payerName_type_info=(payerName, http://virmedica.com/api/soap, null,
        0, 1, false), planName=, planName_type_info=(planName, http://virmedica.com/api/soap,
        null, 0, 1, false), planType=Medicare Part B, planType_type_info=(planType,
        http://virmedica.com/api/soap, null, 0, 1, false), predeterminationAvailable=no
        , predeterminationAvailable_type_info=(predeterminationAvailable,
        http://virmedica.com/api/soap, null, 0, 1, false), predeterminationRequired=no,
        predeterminationRequired_type_info=(predeterminationRequired,
        http://virmedica.com/api/soap, null, 0, 1, false), priorAuthRqd=no,
        priorAuthRqd_type_info=(priorAuthRqd, http://virmedica.com/api/soap,
        null, 0, 1, false), priorTherapyRequired=undetermined,
        priorTherapyRequired_type_info=(priorTherapyRequired, http://virmedica.com/api/soap,
        null, 1, 1, false), productCoinsAmt=20.00%, productCoinsAmt_type_info=(productCoinsAmt,
        http://virmedica.com/api/soap, null, 0, 1, false), productCoinsApplies=yes,
        productCoinsApplies_type_info=(productCoinsApplies, http://virmedica.com/api/soap,
        null, 0, 1, false), productCopayApplies=no, productCopayApplies_type_info=
        (productCopayApplies, http://virmedica.com/api/soap, null, 0, 1, false),
        productDedApplies=yes, productDedApplies_type_info=(productDedApplies,
        http://virmedica.com/api/soap, null, 0, 1, false), productOopMaxApplies=no,
        productOopMaxApplies_type_info=(productOopMaxApplies, http://virmedica.com/api/soap,
        null, 0, 1, false), productPCPCopayAmt=NOT FOUND, productPCPCopayAmt_type_info=
        (productPCPCopayAmt, http://virmedica.com/api/soap, null, 0, 1, false),
        productSpecCopayAmt=NOT FOUND,
        productSpecCopayAmt_type_info=(productSpecCopayAmt,
        http://virmedica.com/api/soap, null, 0, 1, false),
        productStatus=covered,
        productStatus_type_info=(productStatus, http://virmedica.com/api/soap, null, 0,
        1, false), spAvail=no, spAvail_type_info=(spAvail, http://virmedica.com/api/soap,
        null, 0, 1, false), spName=null,
        spName_type_info=(spName, http://virmedica.com/api/soap, null, 0, 1, false),
        spReq=no, spReq_type_info=(spReq, http://virmedica.com/api/soap, null, 0, 1,
        false), therapyRestrictionNotes=null,
        therapyRestrictionNotes_type_info=(therapyRestrictionNotes,
        http://virmedica.com/api/soap, null, 0, 1, false),
        transactionDate=2019-04-07 00:00:00,
        transactionDate_type_info=(transactionDate, http://virmedica.com/api/soap,
        null, 0, 1, false), transactionId=12120,
        transactionId_type_info=(transactionId,
        http://virmedica.com/api/soap, null, 0, 1, false)],
        policy1_type_info=(policy1, http://virmedica.com/api/soap,
        null, 0, 1, false), policy2=null,
        policy2_type_info=(policy2, http://virmedica.com/api/soap,
        null, 0, 1, false), policy3=null,
        policy3_type_info=(policy3, http://virmedica.com/api/soap,
        null, 0, 1, false), responseId=e2683ff7-ebb9-4b72-bd5a-9547b657c669,
        responseId_type_info=(responseId, http://virmedica.com/api/soap,
        null, 0, 1, false), responseTypeCode=1101,
        responseTypeCode_type_info=(responseTypeCode, http://virmedica.com/api/soap,
        null, 0, 1, false)], response_type_info=(response, http://virmedica.com/api/soap,
        null, 1, 1, false)]';

        */



            PC_VirMedicaWSDL2Apex.GetMedeBVResponse_element response_element =
                    new PC_VirMedicaWSDL2Apex.GetMedeBVResponse_element();





        response_element.response = getMedSoapResponse();
        response.put('response_x', response_element);
    }
    public static PC_VirMedicaWSDL2Apex.medeBVResponse getMedSoapResponse() {
            PC_VirMedicaWSDL2Apex.medeBVRequest soapRequest = new PC_VirMedicaWSDL2Apex.medeBVRequest();
            PC_VirMedicaWSDL2Apex.medeBVResponse soapResponse = new PC_VirMedicaWSDL2Apex.medeBVResponse();
            soapRequest.clientPatientId = null;
            soapRequest.patientFirstName = 'Gerald';
            soapRequest.patientLastName = 'Silva';
            soapRequest.patientDOB = Date.newInstance(1965, 08, 12);
            soapRequest.patientGender = 'F';
            soapRequest.patientSSN = null;
            soapRequest.patientZip = '32003';
            soapRequest.product = 'Prolia';
            soapRequest.cptCode1 = 'cptCode';
            soapRequest.cptCode2 = 'cptCode';
            soapRequest.cptCode3 = 'cptCode';
            soapRequest.cptCode4 = 'cptCode';
            soapRequest.cptCode5 = 'cptCode';
            soapRequest.cptCode5 = 'cptCode';
            soapRequest.primaryDiagnosis = '733.01';
            soapRequest.secondaryDiagnosis = null;
            soapRequest.pos = '22';
            soapRequest.providerFirstName = 'Parkas';
            soapRequest.providerLastName = 'Wendy';
            soapRequest.providerNPI = '1306200621';
            soapRequest.providerState = 'MN';
            soapRequest.providerTaxId = null;
            soapRequest.practiceName = null;
            soapRequest.practiceState = null;
            soapRequest.practiceNPI = null;
            soapRequest.mfg = 'Amgen';

            PC_VirMedicaWSDL2Apex.policyInfo policyInfo1 = new PC_VirMedicaWSDL2Apex.policyInfo();
            PC_VirMedicaWSDL2Apex.subscriberInfo subscriberInfo = new PC_VirMedicaWSDL2Apex.subscriberInfo();


            policyInfo1.policyMemberId = 'A24825528';
            policyInfo1.policyPayerId = '19';
            policyInfo1.policyPatientSubscriber = null ;

            soapRequest.policy1Params = policyInfo1;
            soapRequest.policy2Params = null;
            soapRequest.policy3Params = null;


            soapResponse.responseId = 'e2683ff7-ebb9-4b72-bd5a-9547b657c669';
            soapResponse.responseTypeCode = '1101';
            soapResponse.clientPatientId = null;
            soapResponse.VMIPatientId = null;
            soapResponse.inputParameters = soapRequest;
            soapResponse.coordinatedPlanBenefits = '22';

            PC_VirMedicaWSDL2Apex.medeBVPolicy medeBVPolicy1 = new PC_VirMedicaWSDL2Apex.medeBVPolicy();

            medeBVPolicy1.clientField1 = 'clientField';
            medeBVPolicy1.clientField2 = 'cf2';
            medeBVPolicy1.clientField3 = 'cf3';
            medeBVPolicy1.clientField4 = 'cf4';
            medeBVPolicy1.clientField5 = 'cf5';
            medeBVPolicy1.clientField6 = 'cf6';

            medeBVPolicy1.buyBill = 'buyBill';

            PC_VirMedicaWSDL2Apex.cptResult cptResult1 = new PC_VirMedicaWSDL2Apex.cptResult();
            cptResult1.coinsAmt = '1234';
            cptResult1.coinsApplies = '1123';
            cptResult1.copayApplies = '12323';
            cptResult1.cptStatus = '123';
            cptResult1.dedApplies = '1232';
            cptResult1.oopMaxApplies = '123';
            cptResult1.pcpCopayAmt = '121';
            cptResult1.specCopayAmt = '1232';

            medeBVPolicy1.cptCode1Result = cptResult1;
            medeBVPolicy1.cptCode2Result = cptResult1;
            medeBVPolicy1.cptCode3Result = cptResult1;
            medeBVPolicy1.cptCode4Result = cptResult1;
            medeBVPolicy1.cptCode5Result = cptResult1;

            medeBVPolicy1.customMessage1 = 'cm';
            medeBVPolicy1.customMessage2 = 'cm';
            medeBVPolicy1.customMessage3 = 'cm';
            medeBVPolicy1.customMessage4 = 'cm';

            medeBVPolicy1.dedFamAmt = '123';
            medeBVPolicy1.dedIndAmt = '123';
            medeBVPolicy1.dedFamAmtMet = '12';
            medeBVPolicy1.dedIndAmtMet = '123';

            medeBVPolicy1.effDate = Date.today();
            medeBVPolicy1.eligibilityStatus = 'Eligible';
            medeBVPolicy1.endDate = Date.today().addDays(5);

            soapResponse.policy1 = medeBVPolicy1;
            soapResponse.policy2 = medeBVPolicy1;
            soapResponse.policy3 = medeBVPolicy1;

            return soapResponse;

    }

}