/**
 * Created by vkashikar on 8/13/2018.
 */

public with sharing class PC_NewReferral {
    public static final String ACTIVE_STATUS_KEY = 'ACTIVE';

    public class InitData {
        @AuraEnabled public List<ProgramCoverage> programCoverages;
        @AuraEnabled public ProgramCoverageLabel programCoverageLabel;
        @AuraEnabled public PharmacyLabel pharmacyLabel;
        public initData() {
            programCoverages = new List<ProgramCoverage>();
            ProgramCoverageLabel = new ProgramCoverageLabel();
            pharmacyLabel = new PharmacyLabel();
        }
    }

    public class RelatedCase {
        @AuraEnabled public String id;
    }

    public class Patient {
        @AuraEnabled public String id;
    }
    public class ProgramCoverage {
        @AuraEnabled public Prescription prescription;
        @AuraEnabled public Pharmacy pharmacy;

        @AuraEnabled public String name;
        @AuraEnabled public String displayName;
        @AuraEnabled public String id;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String createdDateInUserFormat;
        @AuraEnabled public String patientId;
        @AuraEnabled public String defaultPriorAuthCaseId;

        @AuraEnabled public List<RelatedCase> relatedPriorAuthCases;

        public ProgramCoverage() {
            prescription = new Prescription();
            pharmacy = new Pharmacy();
            relatedPriorAuthCases = new List<RelatedCase>();
        }
    }
    public class ProgramCoverageLabel {
        @AuraEnabled public String name;
        @AuraEnabled public String displayName;
        @AuraEnabled public String id;
        //@AuraEnabled public String createdDate;

        public ProgramCoverageLabel() {

        }
    }
    public class Prescription {
        //@AuraEnabled public String name;
        //@AuraEnabled public String displayName;
        @AuraEnabled public String id;

        //@AuraEnabled public String zipCode;
        //@AuraEnabled public Datetime createdDate;
        public Prescription() {

        }
    }
    public class Pharmacy {
        @AuraEnabled public String name;
        @AuraEnabled public String displayName;
        @AuraEnabled public String id;

        @AuraEnabled public String zipCode;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String createdDateInUserFormat;
        public Pharmacy() {

        }
    }
    /*public class PrescriptionLabel {
        @AuraEnabled public String name;
        @AuraEnabled public String displayName;
        @AuraEnabled public String id;

        @AuraEnabled public String zipCode;
        @AuraEnabled public String createdDate;
        public PrescriptionLabel() {

        }
    }*/
    public class PharmacyLabel {
        @AuraEnabled public String name;
        @AuraEnabled public String displayName;
        @AuraEnabled public String id;

        @AuraEnabled public String zipCode;
        @AuraEnabled public String createdDate;
        public PharmacyLabel() {

        }
    }
    @AuraEnabled
    public static InitData getData(Id caseId) {
        try {
            InitData data = new InitData();
            data.programCoverages = getProgramCoveragesByCaseId(caseId);
            data.programCoverageLabel = getProgramCoverageLabels();
            data.pharmacyLabel = getPharmacyLabels();
            return data;
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return new InitData();
    }

    public static List<ProgramCoverage> getProgramCoveragesByCaseId(Id caseId){

        List<String> ProgramCoverageFields = new List<String>();
        ProgramCoverageFields.add('Id');
        ProgramCoverageFields.add('Name');
        ProgramCoverageFields.add('CreatedDate');

        ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Pharmacy__c'));
        ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Prescription__c'));
        ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Program__r')+ '.Account.Id');
        ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Pharmacy__r')+ '.' + 'Name');
        ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Pharmacy__r')+ '.' + 'CreatedDate');
        ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Pharmacy__r')+ '.' + PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'));


        //ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Prescription__r'));
        //ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Prescription__r')+'.'+('PC_Product__r') + '.' + 'Id');
        //ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Prescription__r')+'.'+('PC_Product__r') + '.' + 'Name');
        //ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Prescription__r')+'.'+('PC_Product__r') + '.' + 'PC_NDC__c');

        //ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Prescription__r')+'.'+('PC_Days_Supply__c'));
        //ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Prescription__r')+'.'+('PC_Requested_Quantity__c'));
        //ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Prescription__r')+'.'+('PC_Dosage__c'));


        //Id RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE, PC_Constants.PROGRAM_COVERAGE_PHARMACY_PLAN_RECORD_TYPE);

        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Program_Coverage__c'), PC_Database.Operation.Reading, ProgramCoverageFields);
        List<ProgramCoverage> programCoverages = new List<ProgramCoverage>();
        ProgramCoverage programCoverage;
        String pharmacyNamePrefix;
        String pharmacyName;
        String paRecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_CASE, PC_Constants.CASE_PA_RECORD_TYPE);
        List<RelatedCase> relatedPriorAuthCases;// = new List<RelatedCase>();
        RelatedCase relatedCase;
        for(PC_Program_Coverage__c pCoverage :[SELECT
        (SELECT Id, RecordTypeId FROM PC_Cases__r WHERE RecordTypeId =:paRecordTypeId), Id, Name,
                //PC_Prescription__r.PC_Frequency__c,
                //PC_Prescription__r.PC_Days_Supply__c, PC_Prescription__r.PC_Requested_Quantity__c,
                // PC_Prescription__r.name,PC_Prescription__r.id,
                //PC_Coverage_Status__c, PC_Coverage_Type__c,
                //PC_Prescription__r.PC_Product__r.Id, PC_Prescription__r.PC_Product__r.Name,
                //PC_Prescription__r.PC_Product__r.PC_NDC__c, PC_Prescription__r.PC_Dosage__c,
                CreatedDate, PC_Prescription__c,
                PC_Program__r.Account.Id,
                PC_Pharmacy__r.Name, PC_Pharmacy__r.PC_Primary_Zip_Code__c, PC_Pharmacy__r.CreatedDate

        FROM PC_Program_Coverage__c
        WHERE PC_Program__c = :caseId
        // ID = 'a0L1I000002RHJvUAO' AND
        AND PC_Coverage_Status__c =: ACTIVE_STATUS_KEY
        AND PC_Pharmacy__c != NULL
        ORDER BY CreatedDate DESC])
        {
            programCoverage = new ProgramCoverage();
            programCoverage.id = pCoverage.id;
            programCoverage.name = pCoverage.Name;
            programCoverage.patientId = pCoverage.PC_Program__r.Account.Id;
            //programCoverage.recordType = PC_Constants.PROGRAM_COVERAGE_PHARMACY_PLAN_RECORD_TYPE;
            //programCoverage.coverageStatus = pCoverage.PC_Coverage_Status__c;
            //programCoverage.coverageType =pCoverage.PC_Coverage_Type__c;
            //programCoverage.prescription = new Prescription();
            //programCoverage.prescription.id = pCoverage.PC_Prescription__r.id;
            //programCoverage.prescription.name = pCoverage.PC_Prescription__r.name;
            //programCoverage.prescription.product = new Drug();
            //programCoverage.prescription.product.id = String.valueOf(pCoverage.PC_Prescription__r.PC_Product__r.Id);
            //programCoverage.prescription.product.name= pCoverage.PC_Prescription__r.PC_Product__r.Name;
            //programCoverage.prescription.product.ndc = pCoverage.PC_Prescription__r.PC_Product__r.PC_NDC__c;
            programCoverage.pharmacy.id = pCoverage.PC_Pharmacy__c;
            programCoverage.prescription.id = pCoverage.PC_Prescription__c;
            programCoverage.pharmacy.createdDate = pCoverage.PC_Pharmacy__r.CreatedDate;
            programCoverage.pharmacy.createdDateInUserFormat = pCoverage.PC_Pharmacy__r.CreatedDate.format();
            if(String.isNotBlank(pCoverage.PC_Pharmacy__r.Name)) {
                pharmacyName = pCoverage.PC_Pharmacy__r.Name;
                programCoverage.pharmacy.name = pharmacyName;
                pharmacyNamePrefix = ' - ';
            }
            else {
                pharmacyName = PC_Constants.EMPTY_STRING;
                pharmacyNamePrefix = PC_Constants.EMPTY_STRING;
            }

            relatedPriorAuthCases = new List<RelatedCase>();

            for(Case c : pCoverage.PC_Cases__r) {
                system.debug('Case-->');
                system.debug(c);
                relatedCase = new RelatedCase();
                relatedCase.id = c.Id;
                relatedPriorAuthCases.add(relatedCase);
            }
            programCoverage.relatedPriorAuthCases = relatedPriorAuthCases;

            programCoverage.displayName = pCoverage.Name + pharmacyNamePrefix + pharmacyName;
            programCoverage.createdDate = pCoverage.CreatedDate;
            programCoverage.createdDateInUserFormat = pCoverage.CreatedDate.format();
            programCoverage.pharmacy.zipCode = pCoverage.PC_Pharmacy__r.PC_Primary_Zip_Code__c;
            if(programCoverage.relatedPriorAuthCases.size() == 1) {
                programCoverage.defaultPriorAuthCaseId = programCoverage.relatedPriorAuthCases[0].id;
            }

            system.debug('program coverage');
            system.debug(pCoverage);
            programCoverages.add(programCoverage);
        }

        System.debug('programCoverages -->'+programCoverages);

        return programCoverages;

    }
    public static ProgramCoverageLabel getProgramCoverageLabels() {
        ProgramCoverageLabel programCoverageLabels = new ProgramCoverageLabel();
        programCoverageLabels.name = PC_Program_Coverage__c.Name.getDescribe().getLabel();
        //programCoverageLabels.prescriptionLabel.name = PC_Prescription__c.Name.getDescribe().getLabel();
        //programCoverageLabels.prescriptionLabel.createdDate = PC_Prescription__c.CreatedDate.getDescribe().getLabel();
        //programCoverageLabels.createdDate = PC_Program_Coverage__c.CreatedDate.getDescribe().getLabel();
        return programCoverageLabels;
    }
    public static PharmacyLabel getPharmacyLabels() {
        PharmacyLabel pharmacyLabel = new PharmacyLabel();
        pharmacyLabel.name = Account.Name.getDescribe().getLabel();
        pharmacyLabel.zipCode = Account.PC_Primary_Zip_Code__c.getDescribe().getLabel();
        pharmacyLabel.createdDate = Account.CreatedDate.getDescribe().getLabel();
        return pharmacyLabel;
    }
}