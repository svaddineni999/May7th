/*Modification Log:
----------------------------------------------------------------------------------
Developer              Date                   Description
-----------------------------------------------------------------------------------
Vijay Kashikar        21-Jan-2021            [PC-7102] Added sharing clause
*********************************************************************************/
/**
 * Example class to perform search on Pharmacies. This implements PharmacyFinder of PC_eBenefits.
 */
global with sharing class PC_PharmacyFinderExample implements PC_eBenefits.PharmacyFinder{
    /**
     * Performs search and returns list of pharmacies that match the criteria.
     */
    @AuraEnabled
    global static List<PC_eBenefits.Pharmacy> searchPharmacies(PC_eBenefits.PharmacySearchParams params){
        try {
            //if (String.isNotBlank(pharmacySearchParamsJson)) {
            List<PC_eBenefits.Pharmacy> pharmacies = new List<PC_eBenefits.Pharmacy>();

            for(Integer i = 0 ; i< 10; i++) {
               // PC_eBenefits.PharmacyFinder handler = PC_eBenefits.getPharmacyFinderService();

                PC_eBenefits.Pharmacy pharmacy = new PC_eBenefits.Pharmacy();

                pharmacy.address = new PC_eBenefits.Address();

                pharmacy.address.addressOne = '350 LONGWOOD AVENUE';
                pharmacy.address.addressTwo = null;
                pharmacy.address.city = 'BOSTON';
                pharmacy.address.cityLabel = null;
                pharmacy.address.country = null;
                pharmacy.address.geoLocation = new PC_eBenefits.Geolocation();
                pharmacy.address.geoLocation.latitude = '42.338772';
                pharmacy.address.geoLocation.longitude = '-71.1072';
                pharmacy.address.id = null;
                pharmacy.address.postalCode = null;
                pharmacy.address.postalCodeLabel = null;
                pharmacy.address.state = null;
                pharmacy.address.stateLabel = null;

                pharmacy.extId = 'extId';
                pharmacy.fax = '6172328268';
                pharmacy.id = 'xyz' +i+ i;
                pharmacy.isExternalPharmacy = true;
                if (!String.isEmpty(params.name)) {
                    pharmacy.name = params.name + ' ' + i + i;
                }
                if (String.isEmpty(params.name)) {
                    pharmacy.name = 'Cvs/Pharmacy #0524' + i + i;
                }
                //pharmacy.name='Cvs/Pharmacy #0524';
                pharmacy.ncpdp = '2235198';
                if (!String.isEmpty(params.npi)) {
                    pharmacy.npi = params.npi;
                }
                if (String.isEmpty(params.npi)) {
                    pharmacy.npi = '1316046618';
                }
                pharmacy.phone = '6177315753';
                if (params.isRetail != null && params.isRetail == true) {
                    pharmacy.specialtyType = 'Retail';
                }
                if (params.isMailOrder != null && params.isMailOrder == true) {
                    if (!String.isEmpty(pharmacy.specialtyType)) {
                        pharmacy.specialtyType = pharmacy.specialtyType + ';' + 'Mail Order';
                    } else {
                        pharmacy.specialtyType = 'Mail Order';
                    }
                }
                if (params.isLongTerm != null && params.isLongTerm == true) {
                    if (!String.isEmpty(pharmacy.specialtyType)) {
                        pharmacy.specialtyType = pharmacy.specialtyType + ';' + 'Longterm';
                    } else {
                        pharmacy.specialtyType = 'Longterm';
                    }
                }
                if (params.isSpecialty != null && params.isSpecialty == true) {
                    if (!String.isEmpty(pharmacy.specialtyType)) {
                        pharmacy.specialtyType = pharmacy.specialtyType + ';' + 'Specialty';
                    } else {
                        pharmacy.specialtyType = 'Specialty';
                    }
                }
                pharmacy.displayName = pharmacy.name + ' : ' + pharmacy.npi;
                pharmacies.add(pharmacy);
            }
                return pharmacies;
        }
        catch (exception ex){
            system.debug('message '+ex.getMessage()+' line '+ex.getStackTraceString());
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }
}