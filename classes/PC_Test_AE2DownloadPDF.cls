/**************************************************************************************
Apex Class Name     : PC_Test_AE2DownloadPDF
Description         : This class is used for testing PC_AE2DownloadPDF;
CreatedBy           : Deloitte
Created Date        : 16 October 2019
Modification Log    :
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------
Kanteti Kishore        	16 October 2019           Initial version
*************************************************************************************/
@isTest(seeAllData=False)
public with sharing class PC_Test_AE2DownloadPDF {

    private static User objUser;
    /*********************************************************************************
    Method Name    : createTestData
    Author         : Kishore Kanteti
    Description    : This method is used for creating test data
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    private static void createTestData() {

        objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test95.com', 'test95');
        PC_Database.ins(objUser, false);
        system.assertNotEquals(objUser.Id, Null);

    }
    /*********************************************************************************
 Method Name    : testGetAdverseEventConfigData
 Author         : Kishore Kanteti
 Description    : This method is used for testing "getAEDownloadPDFPageName"
 Return Type    : void
 Parameter      :
 *********************************************************************************/
    @isTest public static void testGetAEDownloadPDFPageName() {
        createTestData();
        system.runAs(objUser) {
            List<PC_AdverseEvent2__c> ae2List = [Select Id,PC_Gender__c  from PC_AdverseEvent2__c ];

            PC_AE2DownloadPDF.AE2Wrapper ae2wrapper = new PC_AE2DownloadPDF.AE2Wrapper();
           // String vfPage =  PC_AE2DownloadPDF.getAEDownloadPDFPageName();
            ae2wrapper = PC_AE2DownloadPDF.getAEDownloadParams(ae2List[0].Id);

            //system.assertEquals(vfPage,PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AE_VF_PAGE_NAME,PC_Constants.PC_AE2_DEFAULT_VF_PAGE_NAME));
            system.assertEquals(ae2wrapper.vfPageName, PC_SYSTEM.getPatientConnectSetting(PC_Constants.PC_AE_VF_PAGE_NAME,PC_Constants.PC_AE2_DEFAULT_VF_PAGE_NAME) );
            ae2wrapper =PC_AE2DownloadPDF.getAEDownloadParams(ae2List[1].Id);
            ae2wrapper =PC_AE2DownloadPDF.getAEDownloadParams(ae2List[2].Id);
            ae2wrapper =PC_AE2DownloadPDF.getAEDownloadParams(ae2List[3].Id);
            ae2wrapper =PC_AE2DownloadPDF.getAEDownloadParams(ae2List[4].Id);


            system.assert(ae2List.size()==5);
        }
    }


    @testSetup static void setup() {

        Account patient = PC_Test_Setup.createPatient('testpatient');
        patient.PC_Date_of_Birth__c = Date.today();
        patient.PC_Gender__c = 'Male';
        patient = (Account) PC_Database.ins(patient, false);
        Case programCase = PC_Test_Setup.createProgram(patient);
        //insert Adverse Event Record
        PC_AdverseEvent2__c aeRec = new PC_AdverseEvent2__c();

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



        PC_AdverseEvent2__c ae2 = PC_Test_Setup.newAdverseEvent2(patient.Id);
        ae2 = (PC_AdverseEvent2__c)PC_Database.ins(ae2, false);



        PC_AdverseEvent2__c ae3 = PC_Test_Setup.newAdverseEvent2(patient.Id);
        ae3 = (PC_AdverseEvent2__c)PC_Database.ins(ae3, false);

        ae2.PC_LatestAdverseEvent__c =ae3.Id;
        PC_Database.upd(ae2);




        PC_AdverseEvent2__c ae4 = PC_Test_Setup.newAdverseEvent2(patient.Id);
        ae4 = (PC_AdverseEvent2__c)PC_Database.ins(ae4, false);



        PC_AdverseEvent2__c ae5 = PC_Test_Setup.newAdverseEvent2(patient.Id);
        ae5 = (PC_AdverseEvent2__c)PC_Database.ins(ae5, false);

        ae4.PC_ParentAdverseEvent__c = ae5.Id;
        ae5.PC_LatestAdverseEvent__c =ae4.Id;
        PC_Database.upd(ae4);
        PC_Database.upd(ae5);

    }
}