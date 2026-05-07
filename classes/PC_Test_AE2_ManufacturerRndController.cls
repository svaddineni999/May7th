/*********************************************************************************
Class Name      :   PC_Test_AE2_ManufacturerRndController
Description        : Test Class for PC_AE2_ManufacturerRendererController Class
Created By        : Shishir Bansal
Created Date     : 30-11-2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Shishir Bansal         30-11-2018             Initial Version
*********************************************************************************/
@IsTest
private class PC_Test_AE2_ManufacturerRndController {
    private static User adminUser;
    private static final String engagementProgramName = 'engPgm';
    //private static PC_AdverseEvent2__c aeRec1 ;
    private static Map<Object, Object> manufacturerInfoData = new Map<Object, Object>{'manufacturerName'=>'','manufacturerAddress'=>'','manufacturerEmail'=>'','manufacturerCompOutsourcingFac'=>false,'manufacturerPhone'=>'','aeReceivedByManufacturerDate'=>'','reportSource'=>'','nda'=>'','anda'=>''
    ,'ind'=>'','bla'=>'','pma510'=>'','pre1938Flag'=>false,'indicationForProductUse'=>'','productOTC'=>'','productOTCcurrentVal'=>'','combinationProductUse'=>'','combinationProductCurrentVal'=>'','manufacturerReportNumber'=>'','typeOfReports'=>'','ifIndProtocolLabel'=>'','adverseEventTerms'=>''};

    @isTest static void testBehavior() {

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);

        System.runAs(adminUser) {

            PC_AE2_ManufacturerRendererController manufacturerObj = new PC_AE2_ManufacturerRendererController();
            Test.StartTest();

            Case caseId = [Select Id from Case Limit 1];

            Map<Object,Object> fetchData=PC_AE2_ManufacturerRendererController.fetchDataFromManufacturer(caseId.Id ,manufacturerInfoData );
            PC_AdverseEvent2__c adverseObj = [Select Id,PC_Manufacturer_Name__c,PC_Manufacturer_Address__c,
                    PC_Manufacturer_Email__c, PC_Manufacturer_Comp_Outsourcing_Fac__c, PC_Manufacturer_Phone__c, PC_NDA__c,
                    PC_ANDA__c, PC_IND__c, PC_BLA__c, PC_PMA_510k__c, PC_Product_OTC__c,PC_Pre_1938_Flag__c,
                    PC_Combination_Product_Report__c,
                    PC_Manufacturer_Report_Number__c, PC_Report_Source__c, PC_Report_Type__c,PC_AE_Received_by_Manufacturer_Date__c,PC_Adverse_Event_Terms__c,
                    PC_If_IND_Give_Protocol__c,PC_Report_Source_Other_Text__c,PC_Report_Type_Other_Text__c
            from PC_AdverseEvent2__c limit 1];

            system.assert(adverseObj.PC_Manufacturer_Name__c == 'Test');
            Map<Object,Object> loadManufacturerWrapper= PC_AE2_ManufacturerRendererController.loadDataFromAE(adverseObj.Id,manufacturerInfoData);
            manufacturerObj.updateAdverseEvent(adverseObj,manufacturerInfoData);
            PC_AE2_ManufacturerRendererController.ManufacturerFormData formDataWrapper = new PC_AE2_ManufacturerRendererController.ManufacturerFormData();
            formDataWrapper =  PC_AE2_ManufacturerRendererController.getManufacturerData(adverseObj.Id, caseId.Id);

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


        Case programCase = PC_Test_Setup.createProgram(patient);
        //programCase.AccountId = patient.Id;
        programCase.PC_Physician__c = physicians[0].Id;
        programCase.PC_Engagement_Program__c = engagementProgram.Id;
        programCase.PC_Program_Product__c = engagement_program_product.Id;
        programCase = (Case) PC_Database.ups(programCase);


        //insert Adverse Event Record
        PC_AdverseEvent2__c aeRec = new PC_AdverseEvent2__c();

        aeRec = new PC_AdverseEvent2__c();
        aeRec.PC_Patient__c = patient.Id;
        aeRec.PC_Care_Program__c = programCase.Id;
        aeRec.PC_Patient_Identifier__c = patient.Id;
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
        PC_Database.ins(aeRec, false);


    }


}