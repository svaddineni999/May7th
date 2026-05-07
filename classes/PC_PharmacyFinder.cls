/**
 * Created by vkashikar on 6/18/2018.
 */

public with sharing class PC_PharmacyFinder {

   /* @AuraEnabled
    public static List<PC_eBenefits.BaseSobject> getPharmacies() {
        return getAllPharmacies();
    }*/


    @AuraEnabled
    public static List<PC_eBenefits.Pharmacy> searchPharmacies(String pharmacySearchParamsJson){
        //String pharmacySearchParamsJson = '{"searchType":"SEARCH_BY_NPI","npi",""}';
        system.debug('pharmacySearchParamsJson = ' + pharmacySearchParamsJson);

        try {
            if (String.isNotBlank(pharmacySearchParamsJson)) {
                PC_eBenefits.PharmacyFinder handler = PC_eBenefits.getPharmacyFinderService();
                PC_eBenefits.PharmacySearchParams params = (PC_eBenefits.PharmacySearchParams) System.JSON.deserialize(pharmacySearchParamsJson, PC_eBenefits.PharmacySearchParams.class);
                //params.npi = '1790717650';
                List<PC_eBenefits.Pharmacy> pharmacies = handler.SearchPharmacies(params);
                return pharmacies;
            }
        }
        catch (exception ex){
            system.debug('message '+ex.getMessage()+' line '+ex.getStackTraceString());
            PC_Utility.logAndThrowException(ex);
        }

        return null;
    }
}