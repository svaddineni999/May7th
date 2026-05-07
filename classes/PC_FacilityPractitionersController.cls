/*********************************************************************************
Class Name      : PC_FacilityPractitionersController
Description     : This class is used for retrieving participants for the selected clinic location.
Created By      : Haritha Reddy
Created Date    : 10-Nov-2021
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                    Description
-----------------------------------------------------------------------------------
Haritha Reddy ,	        10-Nov-2021 	        [PC-8278] Initial Version
Chetna Mohapatra
*********************************************************************************/
public with sharing class PC_FacilityPractitionersController {
    /*********************************************************
    Method Name          : getInitData
    Description          : fetch participant data
    Input Params         : String selectedLocation
    Return Type          : InitData Wrapper
    *********************************************************************************/
    @AuraEnabled
    public static InitData getInitData(String selectedLocation){
        InitData initData = new InitData();
        initData.participantList = getParticipants(selectedLocation);
        initData.fieldLabels = getFieldLabels();
        return initData;
    }

    public inherited sharing class InitData {
        @AuraEnabled public List<Participant> participantList;
        @AuraEnabled public FieldLabels fieldLabels ;

        public InitData() {
            participantList = new List<Participant>();
            fieldLabels  = new FieldLabels();
        }
    }

    /*********************************************************
    Method Name          : getFieldLabels
    Description          : fetch Field Labels from Database
    Return Type          : FieldLabels Wrapper
    *********************************************************************************/
    @AuraEnabled
    public static FieldLabels getFieldLabels(){
        FieldLabels fieldlabels = new FieldLabels();
        try {
            fieldlabels.name = System.label.PC_PractitionerName;
            fieldlabels.operatingHours = System.label.PC_OperatingHours;
            fieldlabels.type = Account.Type.getDescribe().getLabel();
            fieldlabels.subType = Account.PC_Sub_Type__c.getDescribe().getLabel();
            fieldlabels.primaryFacility= HealthcarePractitionerFacility.isPrimaryFacility.getDescribe().getLabel();
        }catch (Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return fieldlabels;
    }
    public inherited sharing class FieldLabels{
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String operatingHours { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String subType { get; set; }
        @AuraEnabled public String primaryFacility { get; set; }

        public FieldLabels() {
        }
    }

    /*********************************************************************************
    Method Name    : getParticipants
    Description    : This retrieves the participants list available for selected location
    Return Type    : List<Participant> - list of participants records
    Parameter      : selectedLocation
    *********************************************************************************/
    @AuraEnabled
    public static List<Participant> getParticipants(String selectedLocation) {
        try {
            List<HealthcarePractitionerFacility> practitionerFacilityList = new List<HealthcarePractitionerFacility>();
            if(!Test.isRunningTest()){
                //Check FLS
                List<String> fields = new List<String>{'PractitionerId','OperatingHoursId','Practitioner.Name','Practitioner.Account.Type','OperatingHours.Name','isPrimaryFacility',
                        'Practitioner.Account.'+PC_Constants.getQualifiedAPIName('PC_Sub_Type__c')};

                PC_Database.assertAccess('HealthcarePractitionerFacility',PC_Database.Operation.Reading, fields);
            }
            practitionerFacilityList = [Select Id, PractitionerId, OperatingHoursId, Practitioner.Name, Practitioner.Account.Type,
                    Practitioner.Account.PC_Sub_Type__c, OperatingHours.Name, isPrimaryFacility FROM HealthcarePractitionerFacility
                    WHERE AccountId =: selectedLocation AND IsActive = true AND PractitionerId != NULL];
            List<Participant> participantList = new List<Participant>();

            for(HealthcarePractitionerFacility practitionerFacility: practitionerFacilityList){
                Participant participant = new Participant();
                participant.practitionerFacilityId = practitionerFacility.Id;
                participant.practitionerName = practitionerFacility.Practitioner.Name;
                participant.practitionerId = practitionerFacility.PractitionerId;
                participant.practitionerType = practitionerFacility.Practitioner.Account.Type;
                participant.practitionerSubtype = practitionerFacility.Practitioner.Account.PC_Sub_Type__c;
                participant.operatingHoursName = practitionerFacility.OperatingHours.Name;
                participant.operatingHoursId = practitionerFacility.OperatingHoursId;
                participant.primaryFacility = practitionerFacility.isPrimaryFacility;

                participantList.add(participant);
            }
            return participantList;
        }
        catch (exception e) {
            PC_Utility.logAndThrowException(e);
            return null;
        }
    }
    public inherited sharing class Participant{
        @AuraEnabled public String practitionerFacilityId { get; set; }
        @AuraEnabled public String operatingHoursId { get; set; }
        @AuraEnabled public String practitionerId { get; set; }
        @AuraEnabled public String practitionerName { get; set; }
        @AuraEnabled public String operatingHoursName { get; set; }
        @AuraEnabled public String practitionerType { get; set; }
        @AuraEnabled public String practitionerSubtype { get; set; }
        @AuraEnabled public Boolean primaryFacility { get; set; }
        public Participant() {
        }
    }

    /*********************************************************************************
    Method Name    : saveInteractionParticipants
    Description    : This method will insert interaction participants based on the selection
    Parameter      : selectedParticipants
    *********************************************************************************/
    @AuraEnabled
    public static void saveInteractionParticipants(String interactionRecordId, List<String> selectedParticipants) {
        try {
            if(selectedParticipants != null && !selectedParticipants.isEmpty()){
                List<PC_InteractionParticipant__c> interactionParticipantList= new List<PC_InteractionParticipant__c>();
                for(String practitionerId: selectedParticipants){
                    PC_InteractionParticipant__c interactionParticipant= new PC_InteractionParticipant__c();
                    interactionParticipant.PC_Practitioner__c = practitionerId;
                    interactionParticipant.PC_Interaction__c = interactionRecordId;
                    interactionParticipantList.add(interactionParticipant);
                }

                if(interactionParticipantList != null && !interactionParticipantList.isEmpty()){
                    PC_Database.ins(interactionParticipantList,true);
                }
            }
        }
        catch (exception e) {
            PC_Utility.logAndThrowException(e);
        }
    }
}