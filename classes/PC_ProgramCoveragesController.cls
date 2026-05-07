/**
 * Created by shisbansal on 8/27/2018.
 */
/*Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar                 21-Jan-21             [PC-7102] Added FLS Checks
Vijay Kashikar                 21-Jan-2021           [PC-7102] Added sharing clause
****************************************************************************************************************/
public with sharing class PC_ProgramCoveragesController {

    public inherited sharing class InitData {
        @AuraEnabled public List<Coverage> programCoveragesList;
        @AuraEnabled public FieldLabels fieldLabels ;


        public InitData() {
            programCoveragesList = new List<Coverage>();
            fieldLabels          = new FieldLabels();
        }
    }

    @AuraEnabled
    public static InitData getProgramCoverages(List<Id> caseIds){
        InitData initData = new InitData();

        LIST<Coverage> listInfo 	= new LIST <Coverage>();
        List<PC_Program_Coverage__c> programCoveragesList = new List <PC_Program_Coverage__c>();
        try{
            List<String> fields = new List<String>{
                    'Id',
                    'Name',
                    'RecordType',
                    PC_Constants.getQualifiedAPIName('PC_Health_Plan__r.Name'),
                    PC_Constants.getQualifiedAPIName('PC_Coverage_Type__c'),
                    PC_Constants.getQualifiedAPIName('PC_Coverage_Status__c'),
                    'LastActivityDate'};

            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Program_Coverage__c'),PC_Database.Operation.Reading, fields);

            programCoveragesList =
            [SELECT Id, Name,RecordType.name, PC_Health_Plan__r.Name, PC_Coverage_Type__c,
                    PC_Coverage_Status__c,PC_Health_Plan__c
            FROM PC_Program_Coverage__c
            WHERE  PC_Program__c in :caseIds
            ORDER BY  LastActivityDate DESC NULLS LAST];
            system.debug('programCoveragesList -->'+programCoveragesList);

            for(PC_Program_Coverage__c programCoverage : programCoveragesList){
                listInfo.add(new Coverage(programCoverage));
            }

        }catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        initData.programCoveragesList = listInfo;
        initData.fieldLabels = getFieldLabels();
        return initData;
    }


    public inherited sharing class Coverage{
        @AuraEnabled public String programCoverageId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String recordTypeName { get; set; }
        @AuraEnabled public String healthPlanName { get; set; }
        @AuraEnabled public String healtPlanId {get; set;}
        @AuraEnabled public String coverageType { get; set; }
        @AuraEnabled public String coverageStatus { get; set; }

        public Coverage(PC_Program_Coverage__c programCoverage) {
            programCoverageId = programCoverage.Id;
            name = programCoverage.Name;
            recordTypeName = programCoverage.RecordType.name;
            healthPlanName = programCoverage.PC_Health_Plan__r.Name;
            healtPlanId   = programCoverage.PC_Health_Plan__c;
            coverageType = programCoverage.PC_Coverage_Type__c;
            coverageStatus = programCoverage.PC_Coverage_Status__c;
        }

        public Coverage() {}
    }

    public static FieldLabels getFieldLabels(){
        FieldLabels fieldlabels         = new FieldLabels();
        fieldlabels.name                = PC_Program_Coverage__c.name.getDescribe().getLabel();
        fieldlabels.recordType          = PC_Program_Coverage__c.RecordTypeId.getDescribe().getLabel();
        fieldlabels.healthPlanName      = PC_Program_Coverage__c.PC_Health_Plan__c.getDescribe().getLabel();
        fieldlabels.coverageType        = PC_Program_Coverage__c.PC_Program_Coverage__c.getDescribe().getLabel();
        fieldlabels.coverageStatus      = PC_Program_Coverage__c.PC_Coverage_Status__c.getDescribe().getLabel();
        return fieldlabels;
    }

    public inherited sharing class FieldLabels{
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String recordType { get; set; }
        @AuraEnabled public String healthPlanName { get; set; }
        @AuraEnabled public String coverageType { get; set; }
        @AuraEnabled public String coverageStatus { get; set; }

        public FieldLabels() {
        }
    }

}