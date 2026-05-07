/**
 * Created by shisbansal on 12/3/2018.
 */

@IsTest
private class PC_Test_AE2_AdverseEventRendController {
    private static User adminUser;
    private static final String engagementProgramName = 'engPgm';
    private static Map<Object, Object> adverseEventInfo = new Map<Object, Object>{'dateOfTheReport'=>'','eventVerbatim'=>'','eventPT'=>'','eventLLT'=>'','otherReleventHistory'=>'','laboratoryData'=>'','outcome'=>'','eventOnsetDate'=>'','description'=>''
    ,'endDate'=>'','causeOfDeath'=>'','dateofDeath'=>''};


    @isTest static void testBehavior() {

        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);

        System.runAs(adminUser) {

            //aeWrapper.put('adverseEventInfo', adverseEventInfo);

            PC_AE2_AdverseEventRendererController adveseEventObj = new PC_AE2_AdverseEventRendererController();
            Test.StartTest();

            Case caseId = [Select Id from Case Limit 1];




            PC_AdverseEvent2__c adverseObj = [Select Id,PC_Date_of_the_Report__c,PC_Event_Outcome__c,PC_Event_Onset_Date__c,PC_Stop_Date__c,PC_Description__c,PC_Laboratory_Data__c,
                    PC_Other_Relevent_History__c,PC_Event_Verbatim__c,PC_Death_Date__c,PC_CauseOfDeath__c,PC_Event_HLGT_Code__c,
                    PC_Event_SOC_Code__c,PC_Event_HLT_Code__c,PC_Event_PT_Code__c,PC_Event_LLT_Code__c
            from PC_AdverseEvent2__c limit 1];

            system.assert(adverseObj.PC_Laboratory_Data__c == 'Laboratory Data');
            PC_AE2_AdverseEventRendererController.AdverseEventFormData formDataWrapperTest = new PC_AE2_AdverseEventRendererController.AdverseEventFormData();
            formDataWrapperTest =  PC_AE2_AdverseEventRendererController.getAdverseEventData('',adverseEventInfo);
            Map<Object,Object> loadManufacturerWrapper= PC_AE2_AdverseEventRendererController.loadDataFromAE(adverseObj.Id,adverseEventInfo);
            adveseEventObj.updateAdverseEvent(adverseObj,adverseEventInfo);
            PC_AE2_AdverseEventRendererController.AdverseEventFormData formDataWrapper = new PC_AE2_AdverseEventRendererController.AdverseEventFormData();

            formDataWrapper =  PC_AE2_AdverseEventRendererController.getAdverseEventData(adverseObj.Id,adverseEventInfo);
            adveseEventObj.getAdverseEventPDFLabels();


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



        PC_Database.ins(aeRec, false);


    }




}