/**
 * Created by vkashikar on 7/7/2018.
 * Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Vijay Kashikar               July 7, 2018              Initial Version
Shishir Bansal               July 18,2018              Adding latitude , longitude, phone, fax etc details
                                                       to the pharmacy record
Vijay Kashikar               Sep 24, 2018              Added logic to handle NCPDP value
Haritha Reddy             21-Jan-2021                 [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************************************/


public with sharing class PC_SearchPharmacy_UBC implements PC_eBenefits.PharmacyFinder{
    public List<PC_eBenefits.Pharmacy> SearchPharmacies(PC_eBenefits.PharmacySearchParams params){
        PC_UBC_Utility client = new PC_UBC_Utility();
        List<PC_UBC.Pharmacy> pharmacies = client.searchPharmacies(params);



        List<PC_eBenefits.Pharmacy> retPharmacies = new List<PC_eBenefits.Pharmacy>();
        PC_eBenefits.Pharmacy retPharmacy;
        if(pharmacies !=null && !pharmacies.isEmpty()) {
            for (PC_UBC.Pharmacy pharmacy : pharmacies) {
                system.debug(pharmacy);

                retPharmacy = new PC_eBenefits.Pharmacy();
                retPharmacy.name = pharmacy.name;
                retPharmacy.npi = pharmacy.npi;
                retPharmacy.id = pharmacy.id;
                retPharmacy.extId = pharmacy.id;
                retPharmacy.displayName = pharmacy.name + ' : ' + pharmacy.npi;
                retPharmacy.specialtyType = pharmacy.specialtyType;
                // Mapping extra details on pharmacy record
                retPharmacy.fax = pharmacy.fax;
                retPharmacy.phone = pharmacy.phone;
                retPharmacy.isExternalPharmacy = true;
                retPharmacy.ncpdp = pharmacy.ncpdp;
                if(pharmacy.addresses != null && !pharmacy.addresses.isEmpty()) {
                    retPharmacy.zipCode = pharmacy.addresses[0].postalCode;
                    retPharmacy.address = new PC_eBenefits.Address();
                    retPharmacy.address.geoLocation = new PC_eBenefits.Geolocation();
                    retPharmacy.address.city = pharmacy.addresses[0].city;

                    retPharmacy.address.addressOne = pharmacy.addresses[0].addressOne;
                    retPharmacy.address.geoLocation.latitude = pharmacy.addresses[0].latitude;
                    retPharmacy.address.geoLocation.longitude = pharmacy.addresses[0].longitude;

                }
                //retPharmacy.address.latitude             =  pharmacy.addresses[0].latitude;
                //retPharmacy.address.longitude            = pharmacy.addresses[0].longitude;
                //retPharmacy.address.state = pharmacy.addresses[0].state;
                //retPharmacy.address.country              = pharmacy.addresses[0].country;

                retPharmacies.add(retPharmacy);
            }
        }
        return retPharmacies;

    }




}