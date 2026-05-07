/*********************************************************************************************************
Class Name      : PC_Test_Trigger_PA_NameFieldsUpdate
Description     : Tests PC_Test_Trigger_NameFieldsUpdate .
Created By      : Kanteti Kishore
Created Date    : July 24, 2019
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                     Description
--------------------------------------------------------------------------------------------------------------
Kanteti Kishore        July 24, 2019                Initial version
Vijay Kashikar         Aug 20, 2019                 [PC-5326] - Replaced PC_Patient hardcoding with constant
****************************************************************************************************************/
@isTest
public class PC_Test_Trigger_PA_NameFieldsUpdate {


    /*********************************************************************************
    Method Name    : testPopulatePatientName
    Author         : Kishore Kanteti
    Description    : This method populates patient name for person account associated before person account record is created.
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest public static void testPopulatePatientName() {
        Account testAcc = PC_Test_Setup.createPA('Test Person Account',PC_Constants.PATIENT_RECORD_TYPE);
        PC_Database.ins(testAcc);
    }
    /*********************************************************************************
    Method Name    : testPopulatePatientName
    Author         : Kishore Kanteti
    Description    : This method populates patient name for person account associated before person account record is created.
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest public static void testPopulatePatientName2() {
        Account testAcc = PC_Test_Setup.createPAPatient('Test Person Account',PC_Constants.PATIENT_RECORD_TYPE);
        PC_Database.ins(testAcc);
    }

}