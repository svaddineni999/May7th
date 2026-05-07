/**
 * Class Name      : PC_PatientInfo2WithAddressEWPProcessor
 * Created By      : Kishore Kanteti
 * @Created Date   : 01-Dec-2021
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                      Description
 * -----------------------------------------------------------------------------------
 * Kishore Kanteti      01-Dec-2021               Initial Version
 */
global virtual with sharing class PC_PatientInfo2WithAddressEWPProcessor implements PC_EnrollmentWizard.PageProcessor{
    global virtual void processEnrollment(Case enrollmentCase, Map<String, Object> pageState){
        if (pageState == null) {
            throw new PC_EnrollmentWizard.PageProcessorException('Missing Page State');
        }

        //Setting Account Page State
        Map<String,Object> patientInfoPageState = new Map<String, Object>();
        patientInfoPageState.put('persistentAccount',pageState.get('patientInfo'));

        //Creating Patient Account
        PC_PatientInfoEWP2Processor.createPatientAccount(enrollmentCase,patientInfoPageState);

        //Setting Address Page State
        Map<String,Object> addressInfoPageState = new Map<String, Object>();
        addressInfoPageState.put('persistentAddress',pageState.get('addressInfo'));

        //Creating Addresses
        PC_AddressInfoEWPProcessor addressInfoEWP = new PC_AddressInfoEWPProcessor();
        addressInfoEWP.processEnrollment(enrollmentCase,addressInfoPageState);

        //Creating Program Case
        PC_PatientInfoEWP2Processor.createProgramCase(enrollmentCase);
    }
}