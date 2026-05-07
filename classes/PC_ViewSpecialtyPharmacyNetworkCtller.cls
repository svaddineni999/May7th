/**
 * Created by vkashikar on 7/10/2018.
 */

public with sharing class PC_ViewSpecialtyPharmacyNetworkCtller {
    @AuraEnabled
    public static List<PC_eBenefits.Pharmacy> getPharmaciesFromDistributor(String prescriptionId){
        System.debug('Testing id invalid ' + prescriptionID);
        try {
            if (!String.isBlank(prescriptionID)) {

                List<String> pharmacyFields = new List<String>();
                List <String> distributorFields = new List<String>();

                pharmacyFields.add(PC_Constants.getQualifiedAPIName('Name'));
                pharmacyFields.add(PC_Constants.getQualifiedAPIName('PC_Sub_Type__c'));
                pharmacyFields.add(PC_Constants.getQualifiedAPIName('Type'));
                pharmacyFields.add(PC_Constants.getQualifiedAPIName('Id'));
                pharmacyFields.add(PC_Constants.getQualifiedAPIName('PC_NPI__c'));

                PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, pharmacyFields);

                distributorFields.add(PC_Constants.getQualifiedAPIName('PC_Pharmacy__c'));
                distributorFields.add(PC_Constants.getQualifiedAPIName('PC_Product__c'));

                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Distributor__c'), PC_Database.Operation.Reading, distributorFields);

                String pharmacyRecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_ACCOUNT, PC_Constants.PHARMACY_RECORD_TYPE);

                List<PC_Prescription__c> prescriptions = [SELECT PC_Product__r.Id from PC_Prescription__c where Id = :prescriptionID LIMIT 1];



                if (prescriptions != null && !prescriptions.isEmpty() && !String.isBlank(prescriptions[0].PC_Product__r.Id)) {
                    system.debug('product ID --->' + prescriptions[0].PC_Product__r.Id);
                    List <PC_Distributor__c> pharmaciesList = [
                            SELECT PC_Pharmacy__r.Name, PC_Pharmacy__r.PC_Sub_Type__c,PC_Pharmacy__r.PC_NPI__c,
                                    PC_Pharmacy__r.Type, PC_Pharmacy__r.PC_Primary_Zip_Code__c ,PC_Pharmacy__r.Id, Id,
                                    PC_Product__r.Id, PC_Pharmacy__r.Phone, PC_Pharmacy__r.Fax
                            FROM PC_Distributor__c
                            Where PC_Product__r.Id = :prescriptions[0].PC_Product__r.Id AND PC_Pharmacy__r.RecordTypeId = :pharmacyRecordTypeId
                    ];

                    system.debug('PC_Distributor__c  -->' + pharmaciesList);

                    if (pharmaciesList != null && !pharmaciesList.isEmpty()) {
                        pharmaciesList.sort();
                    }
                    List<PC_eBenefits.Pharmacy> sObjectPharmacies = new List<PC_eBenefits.Pharmacy>();
                    PC_eBenefits.Pharmacy sObjectPharmacy;
                    String pharmacySuffix;


                    for (PC_Distributor__c dis : pharmaciesList) {

                        sObjectPharmacy = new PC_eBenefits.Pharmacy();
                        sObjectPharmacy.id = dis.PC_Pharmacy__r.Id;
                        sObjectPharmacy.name = dis.PC_Pharmacy__r.Name;
                        sObjectPharmacy.displayName = dis.PC_Pharmacy__r.Name;

                        pharmacySuffix = dis.PC_Pharmacy__r.PC_NPI__c == null ? '' : ' : ' + dis.PC_Pharmacy__r.PC_NPI__c;

                        sObjectPharmacy.displayName = dis.PC_Pharmacy__r.Name + pharmacySuffix;

                        sObjectPharmacy.specialtyType = dis.PC_Pharmacy__r.PC_Sub_Type__c;
                        sObjectPharmacy.zipCode = dis.PC_Pharmacy__r.PC_Primary_Zip_Code__c;
                        sObjectPharmacy.phone = dis.PC_Pharmacy__r.Phone;
                        sObjectPharmacy.fax = dis.PC_Pharmacy__r.Fax;
                        sObjectPharmacy.isExternalPharmacy = false;

                        sObjectPharmacies.add(sObjectPharmacy);
                    }
                    return sObjectPharmacies;
                }
            }


        }

        catch (Exception ex) {
            PC_Utility.logAndThrowException(ex);


        }
        return new List<PC_eBenefits.Pharmacy>();
    }

}