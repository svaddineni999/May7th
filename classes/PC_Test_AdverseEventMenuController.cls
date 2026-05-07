/*********************************************************************************
Class Name      :   PC_Test_AdverseEventMenuController
Description        : Test Class for PC_AdverseEventMenuController Class
Created By        : Shishir Bansal
Created Date     : 12-12-2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Shishir Bansal         12-12-2018            Initial Version
Haritha Reddy          14-01-2019            Added visitedTab Parameter to method calls of PC_AdverseEventMenuController
Shishir Bansal         1-Oct-2019            [PC-5530] Updating the Test Classes related to Track Adverse Event Version
Haritha Reddy          29-Oct-2019           [PC-5671] Added Code Coverage for getData Method and passing newSuspectPrscriptionList
Kanteti Kishore       4-Nov-2019             PC-5679 Updated testBehaviour method as create adverse event method has return values.
*********************************************************************************/
@IsTest
private class PC_Test_AdverseEventMenuController {

    private static User adminUser;
    private static final String engagementProgramName = 'engPgm';

    @isTest static void testBehavior() {

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);

        System.runAs(adminUser) {

            Id PatientRecordTypeId = PC_SYSTEM.recordTypeId('Account', PC_Constants.PATIENT_RECORD_TYPE);
            Account accountObj = [Select Id, Name from Account where RecordTypeId = :PatientRecordTypeId Limit 1];

            Map<Object, Object> patientInfoObj = new Map<Object, Object>{
                    'patId' => String.valueOf(accountObj.Id), 'age' => null, 'ageType' => 'Year(s)', 'dob' => '', 'gender' => '', 'weight' => null, 'weightType' => '', 'ethnicity' => '', 'race' => ''
            };
            Map<Object, Object> newsuspectProductObj = new Map<Object, Object>{'concomitant'=>'','diagnosis'=>'','dose'=>'','eventAbated'=>'','eventReappeared'=>'','frequency'=>'','lot'=>'',
                    'manufacturer'=>'','ndc'=>'','prescriptionId'=>'','prodCompounded'=>'','prodOTC'=>'','product'=>'','productStrength'=>'','route'=>''
                };
            List<Map<Object, Object>> newsuspectProductList = new List<Map<Object, Object>>();
            newsuspectProductList.add(newsuspectProductObj);
            Map<Object, Object> suspectProductInfo = new Map<Object, Object>{
                    'product' => '', 'productStrength' => '', 'manufacturer' => '', 'ndc' => '', 'lot' => '', 'concomitant' => '', 'dose' => '', 'frequency' => '', 'route' => '',
                     'therapyStartDate' => '', 'therapyEndDate' => '', 'diagnosis' => '', 'prodCompounded' => '', 'prodOTC' => '', 'expirationDate' => '', 'eventAbated' => '', 'eventReappeared' => '',
                        'newSuspectPrescriptionList'=>newsuspectProductList
            };
            Map<Object, Object> initialReporterObj = new Map<Object, Object>{
                    'firstName' => '', 'lastName' => '', 'address' => '', 'city' => '', 'state' => '', 'zip' => '', 'email' => '', 'phone' => '', 'occupation' => '', 'IRalsoSentReportToFDA' => ''
            };
            Map<Object, Object> manufacturerInfoData = new Map<Object, Object>{
                    'manufacturerName' => '', 'manufacturerAddress' => '', 'manufacturerEmail' => '', 'manufacturerCompOutsourcingFac' => false, 'manufacturerPhone' => '', 'aeReceivedByManufacturerDate' => '', 'reportSource' => '', 'nda' => '', 'anda' => ''
                    , 'ind' => '', 'bla' => '', 'pma510' => '', 'pre1938Flag' => false, 'indicationForProductUse' => '', 'productOTC' => '', 'productOTCcurrentVal' => '', 'combinationProductUse' => '', 'combinationProductCurrentVal' => '', 'manufacturerReportNumber' => '', 'typeOfReports' => '', 'ifIndProtocolLabel' => '', 'adverseEventTerms' => ''
            };
            Map<Object, Object> adverseEventInfo = new Map<Object, Object>{
                    'dateOfTheReport' => '', 'eventVerbatim' => '', 'eventPT' => '', 'eventLLT' => '', 'otherReleventHistory' => '', 'laboratoryData' => '', 'outcome' => '', 'eventOnsetDate' => '', 'description' => ''
                    , 'endDate' => '', 'causeOfDeath' => '', 'dateofDeath' => ''
            };
            Map<Object, Object> aeInfo = new Map<Object, Object>{
                    'type' => ''
            };
            Map<String, Map<Object, Object>> aeWrapper = new Map<String, Map<Object, Object>>{
                    'aeInfo' => aeInfo,'patInfo' => patientInfoObj, 'manufacturerInfo' => manufacturerInfoData, 'initialReporterInfo' => initialReporterObj, 'suspectProductInfo' => suspectProductInfo, 'adverseEventInfo' => adverseEventInfo
            };
            Map<String, Boolean> visitedTab = new Map<String, Boolean>{
                    'patientInfo' => false, 'adverseEvent' => false, 'suspectProducts' => false, 'initialReporter' => false, 'manufacturer' => false,'additionalInfo' => false
            };
            Map<String, Boolean> visitedTab1 = new Map<String, Boolean>{
                    'patientInfo' => false, 'adverseEvent' => false, 'suspectProducts' => true, 'initialReporter' => false, 'manufacturer' => false,'additionalInfo' => false
            };

            Test.StartTest();

            PC_AdverseEvent__c adverseObj = [
                    Select Id,PC_Patient_Identifier__c,PC_Gender__c,PC_Ethnicity__c,PC_Date_of_Birth__c,
                            PC_Age__c,PC_Weight__c,PC_Weight_Unit__c,PC_Race__c,PC_Age_Unit__c,PC_Manufacturer_Name__c,PC_Manufacturer_Address__c,
                            PC_Manufacturer_Email__c, PC_Manufacturer_Comp_Outsourcing_Fac__c, PC_Manufacturer_Phone__c, PC_NDA__c,
                            PC_ANDA__c, PC_IND__c, PC_BLA__c, PC_PMA_510k__c,PC_Pre_1938_Flag__c, PC_Product_OTC__c, PC_Combination_Product_Report__c,
                            PC_Manufacturer_Report_Number__c, PC_Report_Source__c, PC_Report_Type__c,PC_AE_Received_by_Manufacturer_Date__c,PC_If_IND_Give_Protocol__c,
                            PC_Adverse_Event_Terms__c, PC_Report_Source_Other_Text__c,PC_Report_Type_Other_Text__c, PC_Event_Verbatim__c,PC_Event_SOC_Code__c,PC_Event_HLGT_Code__c,PC_Event_HLT_Code__c,
                            PC_Event_PT_Code__c,PC_Event_LLT_Code__c,PC_EventType__c,
                            PC_Other_Relevent_History__c, PC_Laboratory_Data__c,PC_Date_of_the_Report__c,PC_Event_Onset_Date__c, PC_Stop_Date__c,PC_Description__c,PC_Event_Outcome__c,PC_CauseOfDeath__c,
                            PC_ReporterAddress__c,PC_Reporter_City__c, PC_Reporter_State__c, PC_Reporter_Country__c, PC_Reporter_Zip_Code__c, PC_Reporter_Email__c,
                            PC_Reporter_Phone__c, PC_Adverse_Event_Reporter__c, PC_Ini_Reporter_Also_Sent_Report_to_FDA__c, PC_SubmissionStatus__c, PC_LatestAdverseEvent__c,PC_ParentAdverseEvent__c,PC_VersionNumber__c

                    from PC_AdverseEvent__c
                    limit 1
            ];

            Case caseId = [Select Id from Case Limit 1];

            system.assert(adverseObj.PC_Manufacturer_Report_Number__c == '13245');

            PC_AdverseEventMenuController.getData(adverseObj.id);
            PC_AdverseEventMenuController.getData(null);

            Map<String,String> adverseEventMenuCmpAttributes = new Map <String,String>();

            adverseEventMenuCmpAttributes.put('hideAdditionalInfoTab', 'true');
            adverseEventMenuCmpAttributes.put('additionalInfoTabFieldSet', '');


            List<String> aeDetails =  PC_AdverseEventMenuController.createAdverseEvent(null, caseId.Id, aeWrapper, visitedTab,adverseEventMenuCmpAttributes);
            system.assertEquals(aeDetails.size(),3);
            List<String> aeDetails2 = PC_AdverseEventMenuController.createAdverseEvent(null, caseId.Id, aeWrapper, visitedTab1,adverseEventMenuCmpAttributes);
            system.assertEquals(aeDetails2.size(),3);
            List<String> aeDetails3 = PC_AdverseEventMenuController.createAdverseEvent(adverseObj.id, caseId.Id, aeWrapper, visitedTab,adverseEventMenuCmpAttributes);
            system.assertEquals(aeDetails3.size(),3);
            List<String> aeDetails4 = PC_AdverseEventMenuController.createAdverseEvent(adverseObj.id, caseId.Id, aeWrapper, visitedTab1 ,adverseEventMenuCmpAttributes);
            system.assertEquals(aeDetails4.size(),3);
            Test.stopTest();
        }

    }

    public static void createAddress(Id accounId) {

        PC_Address__c address = new PC_Address__c();
        address.PC_Account__c = accounId;
        address.PC_Address_1__c = 'test address line 1';
        address.PC_Address_2__c = 'test address line 2';
        address.PC_City__c = 'EDWARDSVILLE';
        address.PC_State__c = 'MA';
        address.PC_Zip_Code__c = '62025';
        //@@RemoveAddressPhone: address.PC_Phone__c = '0727555957';
        address.PC_Primary_Address__c = true;

        address = (PC_Address__c) PC_Database.ins(address, false);
    }

    @testSetup static void setup() {

        Account patient = PC_Test_Setup.createPatient('testpatient');
        patient.PC_Date_of_Birth__c = Date.today();
        patient.PC_Gender__c = 'Male';
        patient = (Account) PC_Database.ins(patient, false);
        createAddress(patient.Id);

        List<Account> manufacturers = PC_Test_Setup.createAccounts('testManufacturer', 1, 'Manufacturer');

        manufacturers = (List<Account>) PC_Database.ups(manufacturers);
        createAddress(manufacturers[0].Id);

        List<Account> physicians = PC_Test_Setup.createAccounts('PHY', 1, PC_Constants.PHYSICIAN_RECORD_TYPE);
        physicians[0].PC_NPI__c = '1306200621';
        physicians = PC_Database.ins(physicians);
        createAddress(physicians[0].Id);

        PC_Engagement_Program__c engagementProgram = PC_Test_Setup.createEngagementProgram(engagementProgramName, manufacturers[0].Id);
        engagementProgram.PC_Program_Code__c = engagementProgramName;
        engagementProgram.PC_Manufacturer__c = manufacturers[0].Id;
        engagementProgram = (PC_Engagement_Program__c) PC_Database.ups(engagementProgram);

        Product2 product = new Product2();
        product.PC_NDC__c = '24542131';
        product.ProductCode = 'Ambien';
        product.PC_Manufacturer__c = manufacturers[0].Id;
        product.Name = 'Ambien 10mg Tablet';
        product = (Product2) PC_Database.ins(product);

        PC_Engagement_Program_Product__c engagement_program_product = new PC_Engagement_Program_Product__c();
        engagement_program_product.PC_Product__c = product.Id;
        engagement_program_product.PC_Engagement_Program__c = engagementProgram.Id;
        engagement_program_product = (PC_Engagement_Program_Product__c) PC_Database.ins(engagement_program_product);

        PC_Prescription__c prescription =PC_Test_Setup.newPrescription(product.Id);
        prescription.PC_Rx_Start_Date__c = date.today().addDays(-10);
        prescription.PC_Rx_End_Date__c = date.today().addDays(10);
        PC_Database.ins(prescription, false);

        Case programCase = PC_Test_Setup.createProgram(patient);
        //programCase.AccountId = patient.Id;
        programCase.PC_Physician__c = physicians[0].Id;
        programCase.PC_Engagement_Program__c = engagementProgram.Id;
        programCase.PC_Program_Product__c = engagement_program_product.Id;
        programCase.PC_PA_Prescription__c = prescription.Id;
        programCase = (Case) PC_Database.ups(programCase);

        //insert Adverse Event Record
        PC_AdverseEvent__c aeRec = new PC_AdverseEvent__c();
        aeRec = new PC_AdverseEvent__c();
        aeRec.PC_Patient__c = patient.Id;
        aeRec.PC_Care_Program__c = programCase.Id;
        // patient data
        aeRec.PC_Patient_Identifier__c = patient.Id;
        aeRec.PC_Race__c = 'White';
        aeRec.PC_Gender__c= 'Male';
        aeRec.PC_Patient_Identifier__c = patient.Id;

        // adverse Event Data
        aeRec.PC_Event_Outcome__c = 'Death;Life-threatening;Disability or Permanent Damage';
        aeRec.PC_Event_Onset_Date__c = Date.newInstance(2018, 12, 14);
        aeRec.PC_Stop_Date__c = Date.newInstance(2020, 12, 14);
        aeRec.PC_Description__c = 'Adverse Event Descrpition';
        aeRec.PC_Laboratory_Data__c = 'Laboratory Data';
        aeRec.PC_Other_Relevent_History__c = 'Other Relevant Data';
        aeRec.PC_Event_Verbatim__c = 'Verbatim Data';
        aeRec.PC_Event_PT_Code__c = 'PT data';
        aeRec.PC_Event_LLT_Code__c ='LLT Data';
        aeRec.PC_CauseOfDeath__c = 'Cause of Death';
        aeRec.PC_Death_Date__c = Date.newInstance(2018, 12, 14);

        // manufacturer data
        aeRec.PC_Manufacturer_Name__c= 'Test';
        aeRec.PC_Manufacturer_Address__c= 'test address line 1';
        aeRec.PC_Manufacturer_Email__c= 'xyz@gmail.com';
        aeRec.PC_Manufacturer_Comp_Outsourcing_Fac__c= true;
        aeRec.PC_Manufacturer_Phone__c= '123456';
        aeRec.PC_NDA__c= 'NDA';
        aeRec.PC_ANDA__c= 'ANDA';
        aeRec.PC_IND__c= 'IND';
        aeRec.PC_BLA__c= 'BLA';
        aeRec.PC_PMA_510k__c= 'PMA';
        //aeRec.PC_Pre_1938_Flag__c= 'Yes';
        aeRec.PC_Product_OTC__c= 'Yes';
        aeRec.PC_Combination_Product_Report__c= 'Yes';
        aeRec.PC_Manufacturer_Report_Number__c= '13245';
        aeRec.PC_Adverse_Event_Terms__c= 'Test Test';
        aeRec.PC_Report_Source__c= 'Company Representative;User Facility;Distributor;Other';
        aeRec.PC_Report_Type__c= '5-day;7-day;10-day;15-day';
        aeRec.PC_Report_Source_Other_Text__c= 'Others';
        aeRec.PC_Report_Type_Other_Text__c= 'Others';
        aeRec.PC_SubmissionStatus__c= PC_Constants.PC_AE_SUBMISSION_STATUS;
        aeRec.PC_EventType__c= PC_Constants.EMPTY_STRING;
        PC_Database.ins(aeRec, false);
    }
}