/*********************************************************************************
Class Name      : PC_PostDeployment
Description     : Controller for PC_PostDeployment vf page
Created By      : Vijay Kashikar
Created Date    : 12 Dec 2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Vijay Kashikar              12-Dec-18                  Initial Version
Vijay Kashikar              04-Mar-19                  [PC-4426] Added messages for migration from 7.0 to 7.1
*********************************************************************************/

public with sharing class PC_PostDeployment {
    public v7Info v7{get;set;}
    public PC_PostDeployment(){
        //doPostDeploymentCheck('7.0');
        v7 = new v7Info();
    }

    public class v7Info {
        public Integer noOfPatientAccsToBeMigrated{get;set;}
        public Integer noOfPhysicianAccsToBeMigrated{get;set;}
        public String patientMigrationMessage{get;set;}
        public String physicianMigrationMessage {get;set;}
        private String additionalpatientMigrationMessage;
        private String additionalPhysicianMigrationMessage;

        public v7Info() {
            noOfPatientAccsToBeMigrated = 0;

            String PC_PATIENT_RECORD_TYPE = PC_Constants.PATIENT_RECORD_TYPE;
            Id contactIndividualRecordTypeId = PC_System.recordTypeId(PC_Constants.CONTACT, PC_Constants.CONTACT_INDIVIDUAL_RECORD_TYPE);
            String PC_NAMESPACE = PC_Constants.OrgNamespace;
            
            List<RecordType> pcPatientRecordTypes;
            
            try {
                pcPatientRecordTypes = [
                        SELECT ID
                        FROM RecordType
                        WHERE DeveloperName = :PC_PATIENT_RECORD_TYPE
                        AND NamespacePrefix = :PC_NAMESPACE AND SobjectType = 'Account'
                        //AND IsActive = TRUE
                ];
            }
            catch(Exception ex) {
                pcPatientRecordTypes = null;
            }


            if(pcPatientRecordTypes != null && pcPatientRecordTypes.size() == 1) {
                String pcPatientRecordTypeId = pcPatientRecordTypes[0].ID;
                Integer count = [
                        SELECT count()
                        FROM Account
                        WHERE RecordTypeId = :pcPatientRecordTypeId
                        AND
                        (
                                HealthCloudGA__IndividualId__c = NULL
                                OR
                                (HealthCloudGA__IndividualId__c != NULL AND HealthCloudGA__PrimaryContact__r.RecordTypeId = :contactIndividualRecordTypeId)
                        )
                ];
                noOfPatientAccsToBeMigrated = count;
                if(noOfPatientAccsToBeMigrated == 0) {
                    patientMigrationMessage = 'No ' + PC_PATIENT_RECORD_TYPE + ' accounts need to be migrated.';
                }
                else {
                    patientMigrationMessage = noOfPatientAccsToBeMigrated + ' accounts(' + PC_PATIENT_RECORD_TYPE + ') need to be migrated to be compatible with Individual Model of Health Cloud.';
                    additionalpatientMigrationMessage = ' These accounts either do not have Health Cloud Individual Id or have Patient Connect Individual contact record as their primary contact';
                    patientMigrationMessage = patientMigrationMessage + additionalpatientMigrationMessage;
                }
            }
            else {
                patientMigrationMessage = PC_PATIENT_RECORD_TYPE + ' was not found.';
            }
            
            noOfPhysicianAccsToBeMigrated = 0;
            List<RecordType> pcPhysicianRecordTypes;
            try {
                pcPhysicianRecordTypes = [
                        SELECT ID
                        FROM RecordType
                        WHERE DeveloperName = :PC_Constants.PHYSICIAN_RECORD_TYPE
                        AND NamespacePrefix = :PC_NAMESPACE AND SobjectType = 'Account'
                        //AND IsActive = TRUE
                ];
            }
            catch(Exception ex) {
                pcPhysicianRecordTypes = null;
            }
            if(pcPhysicianRecordTypes != null && pcPhysicianRecordTypes.size() == 1) {
                String pcPhysicianRecordTypeId = pcPhysicianRecordTypes[0].ID;
                /*Integer count = [
                        SELECT count()
                        FROM Account
                        WHERE RecordTypeId = :pcPhysicianRecordTypeId
                ];*/
                Integer c = [
                        select count()
                        from Contact
                        WHERE RecordTypeId = :contactIndividualRecordTypeId AND
                        Account.RecordTypeId =:pcPhysicianRecordTypeId];
                noOfPhysicianAccsToBeMigrated = c;
                if(noOfPhysicianAccsToBeMigrated == 0) {
                    physicianMigrationMessage = 'No ' + PC_Constants.PHYSICIAN_RECORD_TYPE + ' accounts need to be migrated.';
                }
                else {
                    physicianMigrationMessage = noOfPhysicianAccsToBeMigrated + ' accounts(' + PC_Constants.PHYSICIAN_RECORD_TYPE + ') need to be migrated.';
                    physicianMigrationMessage = physicianMigrationMessage + ' . These accounts are linked to Individual Contact and should be migrated so as to link them with PC_Physician contact.';
                }
            }
            else {
                physicianMigrationMessage = PC_Constants.PHYSICIAN_RECORD_TYPE + ' was not found.';
            }
        }
    }
}