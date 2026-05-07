/**
 * Created by vkashikar on 7/8/2018.
 */

@IsTest
private class PC_Test_SearchPharmacy_UBC {
    private static User adminUser;
    @isTest static void testBehavior() {
        adminUser = PC_Test_Setup.createUser('System Administrator', 'pcuser@test100.com', 'test100');

        PC_Database.ins(adminUser);

        System.runAs(adminUser) {
            Test.StartTest();

            Test.setMock(HttpCalloutMock.class, new PC_UBC_MockHttpResponseGenerator());

            PC_SearchPharmacy_UBC client = new PC_SearchPharmacy_UBC();
            PC_eBenefits.PharmacySearchParams params = new PC_eBenefits.PharmacySearchParams();
            params.searchBy = PC_eBenefits.PharmacySearchBy.NPI;
            params.npi = 'test';
            client.searchPharmacies(params);

            PC_eBenefits.PharmacySearchParams params2 = new PC_eBenefits.PharmacySearchParams();
            params2.searchBy = PC_eBenefits.PharmacySearchBy.BEST_MATCH;
            params2.name = 'test';
            params2.zipCode = '3333';
            params2.isMailOrder = true;
            params2.isRetail = true;
            params2.zipCode = '33';
            params2.isLongTerm = true;
            client.searchPharmacies(params);

            PC_eBenefits.PharmacySearchParams params3 = new PC_eBenefits.PharmacySearchParams();
            params3.searchBy = PC_eBenefits.PharmacySearchBy.NPI_NCPDP_POSTALCODE ;
            params3.name = 'test';
            params3.zipCode = '3333';
            params3.isMailOrder = true;
            params3.isRetail = true;
            params3.zipCode = '33';
            params3.isLongTerm = true;
            client.searchPharmacies(params);

            Test.stopTest();

        }



    }
}