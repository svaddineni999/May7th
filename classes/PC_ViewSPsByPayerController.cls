/*********************************************************************************
Class Name      : PC_ViewSPsByPayerController
Description     : This class is the controller for the  (PC_ViewSPsByPayer)Component to retrieve data from junction
                  object(Preferred Payer PBM) between Account and
                  Health Plan
Created By      : Deloitte
Created Date    : June 26, 2018
Modification Log:
----------------------------------------------------------------------------------
Developer                 	Date                   	Description
-----------------------------------------------------------------------------------
Shishir Bansal             	June 26, 2018         	Initial Version
Shishir Bansal              11-Dec-2019            [PC-5792] Avoid hardcoding of string variable
Haritha Reddy               May 05,2020            [PC-6249] Added limit to the SOQL query
Haritha Reddy           21-Jan-2021             [PC-7102] Added FLS Check
Haritha Reddy         21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/


public with sharing class PC_ViewSPsByPayerController {


    @AuraEnabled
    public static List<PreferredPayerPBM> getAllPreferredPrayer()
    {
        // checking for FLS and CRUD

        try {
            List<String> fields = new List<String>{
                    PC_Constants.getQualifiedAPIName('PC_Payer__r')+'.Name', PC_Constants.getQualifiedAPIName('PC_Specialty_Pharmacy__r'+'.Name'),
                    PC_Constants.getQualifiedAPIName('PC_PayerNameIfNoAccount__c'), PC_Constants.getQualifiedAPIName('PC_SpecialtyPharmacyNameIfNoAccount__c')
            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Preferred_SP_By_Payer__c'), PC_Database.Operation.Creating, fields);

            List<PreferredPayerPBM> prefPayerList = new List<PreferredPayerPBM>();

            List<PC_Preferred_SP_By_Payer__c> prefList = [SELECT PC_Payer__r.name, PC_Specialty_Pharmacy__r.name, PC_PayerNameIfNoAccount__c, PC_SpecialtyPharmacyNameIfNoAccount__c
            FROM PC_Preferred_SP_By_Payer__c LIMIT 2000];


            if (prefList != null && !prefList.isEmpty() ) {
                for (PC_Preferred_SP_By_Payer__c obj : prefList) {
                    PreferredPayerPBM obj1 = new PreferredPayerPBM();
                    if(obj.PC_Payer__r.name != null ) {
                        if(obj.PC_PayerNameIfNoAccount__c !=null) {
                            obj1.payer.name = obj.PC_Payer__r.name +'/'+ obj.PC_PayerNameIfNoAccount__c ;

                        }
                        else{
                            obj1.payer.name = obj.PC_Payer__r.name;
                        }
                    }
                    else if(obj.PC_PayerNameIfNoAccount__c != null){
                        obj1.payer.name = obj.PC_PayerNameIfNoAccount__c;
                    }
                    else{
                        obj1.payer.name =PC_Constants.EMPTY_STRING;
                    }


                    if(obj.PC_Specialty_Pharmacy__r.name != null) {
                        if(obj.PC_SpecialtyPharmacyNameIfNoAccount__c != null) {
                            obj1.sp.name = obj.PC_Specialty_Pharmacy__r.name +'/'+ obj.PC_SpecialtyPharmacyNameIfNoAccount__c ;

                        }
                        else{
                            obj1.sp.name = obj.PC_Specialty_Pharmacy__r.name;
                        }
                    }
                    else if(obj.PC_SpecialtyPharmacyNameIfNoAccount__c != null){
                        obj1.sp.name = obj.PC_SpecialtyPharmacyNameIfNoAccount__c;
                    }
                    else{
                        obj1.sp.name =PC_Constants.EMPTY_STRING;
                    }

                    prefPayerList.add(obj1);
                }
            }

            return prefPayerList;
        }
        catch (Exception ex){
            PC_Utility.logAndThrowException(ex);

        }
        return null;
    }

    public inherited sharing class PreferredPayerPBM{

        @AuraEnabled public Payer payer;
        @AuraEnabled public SpecialtyPharmacy sp;

        public PreferredPayerPBM(){
            this.payer = new Payer();
            this.sp   = new SpecialtyPharmacy();
        }
    }


    public inherited sharing class Payer{
        @AuraEnabled
        public String name;
    }


    public inherited sharing class SpecialtyPharmacy{
        @AuraEnabled
        public String name;


   }

}