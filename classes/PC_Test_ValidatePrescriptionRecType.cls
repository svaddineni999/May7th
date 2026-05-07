/*********************************************************************************************************
Class Name      : PC_Test_ValidatePrescriptionRecType
Description     : Tests PC_Trigger_ValidatePatientOnPrescription .
Created By      : Kanteti Kishore
Created Date    : Sep 17, 2019
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                     Description
--------------------------------------------------------------------------------------------------------------
Kanteti Kishore        Sep 17, 2019               Initial version
****************************************************************************************************************/
@isTest
public class PC_Test_ValidatePrescriptionRecType{


/*********************************************************************************
    Method Name    : testPrescPatient
    Author         : Kishore Kanteti
    Description    : This method populates patient name for person account associated before person account record is created.
    Return Type    : void
    Parameter      :
*********************************************************************************/
    @isTest public static void testPrescPatient() {
        Account testAcc = PC_Test_Setup.createTestAccount(PC_Constants.PC_PATIENT_PERSONACCOUNT_RECORDTYPE_API);
        PC_Database.ins(testAcc);

        Test.startTest();
        PC_Prescription__c presc = new PC_Prescription__c(PC_Patient_Account__c = testAcc.Id);
        PC_Database.ins(presc);
        presc.PC_Dosage__c = PC_Constants.PC_PATIENT_PERSONACCOUNT_RECORDTYPE_API;
        PC_Database.upd(presc);
        Test.stopTest();
    }

}