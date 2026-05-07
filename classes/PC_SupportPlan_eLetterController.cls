/**
 * Created by tejapatel on 11/14/2018.
 *
 * --------------------------------------------------------------------------------------------------------------
    Developer                   Date                   	Description
    --------------------------------------------------------------------------------------------------------------
    Hitha Avalakki              Mar 19, 2021            PC-7533: Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
    Satheesh Kumar              Apr 14, 2021            PC-6528: Added eletter category check in geteLetterObject where condition
    Hitha Avalakki              Apr 15, 2021            PC-7538: Removed the condition of 'PC_Object_Record_Types__c' for fetching eletters configured for a case.
 */

public with sharing class PC_SupportPlan_eLetterController {
    @AuraEnabled
    public static eLetterObject geteLetterObject(){
        eLetterObject eLetterObjects            =   new eLetterObject();
        LIST<eLettres> eLetters                 =   new LIST<eLettres>();
        STRING caseObject                       =   PC_Constants.PC_CASE;
        List<PC_PicklistFieldManager.PicklistEntryWrapper> targetRecepientList = PC_PicklistFieldManager.getPicklistEntryWrappers(PC_eLetter__c.PC_Target_Recipients__c);
        PC_PicklistFieldManager.PicklistEntryWrapper patientRecepient = new PC_PicklistFieldManager.PicklistEntryWrapper(PC_Constants.PATIENT_ACCOUNT_TYPE_VALUE,System.label.PC_Patient);
        targetRecepientList.add(patientRecepient);
        List<PC_eLetter__c> eLetterObj =  new List<PC_eLetter__c>();

        try {
            List<String> eLetterFields = new List<String>();
            eLetterFields = new List<String>{
                    'Id', 'Name', PC_Constants.getQualifiedAPIName('PC_Communication_Language__c'), PC_Constants.getQualifiedAPIName('PC_Hide_From_eLetter_Page__c'),
                    PC_Constants.getQualifiedAPIName('PC_Target_Recipients__c'), PC_Constants.getQualifiedAPIName('PC_Template_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Allow_Send_to_Patient__c'), PC_Constants.getQualifiedAPIName('PC_Source_Object__c'),
                    PC_Constants.getQualifiedAPIName('PC_Send_to_User__c'), PC_Constants.getQualifiedAPIName('PC_Category__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_eLetter__c'), PC_Database.Operation.Reading, eLetterFields);

            //PC-7538: Removed the condition of 'PC_Object_Record_Types__c' for fetching eletters configured for a case
            //Only eLetters with PC_Send_to_User__c set to false and Category set to either Automated Email or/and Automated Fax
            eLetterObj = [
                    SELECT ID, Name, toLabel(PC_Communication_Language__c), PC_Target_Recipients__c, PC_Template_Name__c,
                            PC_Allow_Send_to_Patient__c,PC_Send_to_User__c
                    FROM PC_eLetter__c
                    WHERE PC_Source_Object__c = :caseObject AND PC_Send_to_User__c = false
                    AND PC_Category__c INCLUDES (:PC_Constants.PC_ELETTER_CATEGORY_AUTOMATED_EMAIL, :PC_Constants.PC_ELETTER_CATEGORY_AUTOMATED_FAX)
            ];

            for (PC_eLetter__c e : eLetterObj) {
                eLettres eLetter = new eLettres();
                LIST<targetRecepient> targetRecepients  =   new LIST<targetRecepient>();
                eLetter.eLetterID               = e.Id;
                eLetter.eLetterName             = e.Name;
                eLetter.targetRecepientMapping  = targetRecepientList;
                if(String.isNotBlank(e.PC_Target_Recipients__c)){
                    for (STRING t : e.PC_Target_Recipients__c.split(';')) {
                        targetRecepient targetRecepient = new targetRecepient();
                        targetRecepient.recepient = t;
                        targetRecepient.communicationLanguage = e.PC_Communication_Language__c;
                        targetRecepient.selected = true;
                        targetRecepients.add(targetRecepient);
                    }
                }
                if(e.PC_Allow_Send_to_Patient__c == true){
                    targetRecepient targetRecepient1         =   new targetRecepient();
                    targetRecepient1.recepient               =   PC_Constants.PATIENT_ACCOUNT_TYPE_VALUE;
                    targetRecepient1.communicationLanguage   =   e.PC_Communication_Language__c;
                    targetRecepient1.selected                =   true;
                    targetRecepients.add(targetRecepient1);
                }
                if(targetRecepients != null && !targetRecepients.isEmpty()){
                    eLetter.targetRecepient = targetRecepients;
                    eLetters.add(eLetter);
                }
            }
            eLetterObjects.eLettres = eLetters;

        } catch (Exception ex){
            PC_Utility.createExceptionLog(ex);
        }
        return eLetterObjects;
    }

    @AuraEnabled
    public static FieldLabels getFieldLabels(){
        FieldLabels fieldlabels 			= new FieldLabels();

        fieldlabels.eLetterName		        = PC_eLetter__c.Name.getDescribe().getLabel();
        fieldlabels.targetRecepient			= PC_eLetter__c.PC_Target_Recipients__c.getDescribe().getLabel();
        fieldlabels.communicationLanguage	= PC_eLetter__c.PC_Communication_Language__c.getDescribe().getLabel();

        return fieldlabels;
    }

    public class FieldLabels {
        //eLetter Fields
        @AuraEnabled public String eLetterName { get; set; }
        @AuraEnabled public String targetRecepient { get; set; }
        @AuraEnabled public String communicationLanguage { get; set; }

        public FieldLabels() {
        }
    }

    public class eLetterObject {
        //eLetter JSON Wrapper
        @AuraEnabled public LIST <eLettres> eLettres{ get; set; }

        public eLetterObject() {
            eLettres e              =   new eLettres();
            LIST<eLettres> eList    =   new LIST<eLettres>();
            eList.add(e);
            eLettres                =   eList;
        }
    }

    public class eLettres {
        //All eLetters
        @AuraEnabled public STRING eLetterID { get; set; }
        @AuraEnabled public STRING eLetterName { get; set; }
        @AuraEnabled public LIST <targetRecepient> targetRecepient{ get; set; }
        @AuraEnabled public List<PC_PicklistFieldManager.PicklistEntryWrapper> targetRecepientMapping{ get; set; }
        public eLettres() {
            eLetterID                       =   PC_Constants.EMPTY_STRING;
            eLetterName                     =   PC_Constants.EMPTY_STRING;
            targetRecepient tr              =   new targetRecepient();
            LIST<targetRecepient> trList    =   new LIST<targetRecepient>();
            trList.add(tr);
            targetRecepient                 =   trList;
        }
    }

    public class targetRecepient {
        //All eLetters
        @AuraEnabled public STRING recepient { get; set; }
        @AuraEnabled public STRING communicationLanguage { get; set; }
        @AuraEnabled public Boolean selected { get; set; }

        public targetRecepient() {
            recepient               =   PC_Constants.EMPTY_STRING;
            communicationLanguage   =   PC_Constants.EMPTY_STRING;
            selected                =   false;
        }
    }
}