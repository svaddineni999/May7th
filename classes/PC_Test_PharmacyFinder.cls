/**
 * Class Name      : PC_Test_PharmacyFinder
 * Created By      : Vijay Kashikar
 * @Created Date   : May 19, 2018
 * Modification Log:
 * ----------------------------------------------------------------------------------
 * Developer              Date                      Description
 * -----------------------------------------------------------------------------------
 * Vijay Kashikar     19-May-2018           Initial Version
 * Shishir Bansal     5-July-2018           Getting the Default Pharmacies from the selected Prescription in RTBC
 */
@isTest
public class PC_Test_PharmacyFinder {

    private static User adminUser;
    private static String userName = 'user@test100.com';
    private static String alias = 'test100';

    @isTest static void run() {
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, userName, alias);
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();

            List<PC_Prescription__c> prescriptionList= [Select Id From PC_Prescription__c LIMIT 1];


            List<PC_eBenefits.Pharmacy> pBaseSObjects = PC_ViewSpecialtyPharmacyNetworkCtller.getPharmaciesFromDistributor(string.valueof(prescriptionList[0].Id));

            System.assertEquals(prescriptionList.size() == 1 , true);

            Test.StopTest();
        }
    }


    @testSetup static void setup() {


        List<Account> pharmacyAccList = PC_Test_Setup.createAccounts('testpayer', 2, PC_Constants.PHARMACY_RECORD_TYPE);
        pharmacyAccList = (List<Account>) PC_Database.ups(pharmacyAccList);

        Account manufacturerAcc = PC_Test_Setup.createTestAccount(PC_Constants.MANUFACTURER_RECORD_TYPE);
        PC_Database.ins(manufacturerAcc, false);


        Product2 productObj = PC_Test_Setup.newProduct('60 ACTUAT Budesonide 0.16 MG','ACTUATBudesonide',manufacturerAcc.Id);



        Database.insert(productObj , false);


        PC_Prescription__c presObj = new PC_Prescription__c(
                                        PC_Product__c = productObj.Id  ,
                                        PC_Dosage__c = '20' );
        Database.insert(presObj , false);


        PC_Distributor__c DistributorObj = PC_Test_Setup.newDistributionNetwork(productObj.Id, pharmacyAccList[0].Id);
        Database.insert(DistributorObj, false);




    }

}