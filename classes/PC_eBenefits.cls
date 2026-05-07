/****************************************************************************************************************************************************
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Vijay Kashikar         		   May 19, 2018           Initial Version
Vijay Kashikar         		   May 29, 2018           Added wrapper classes to avoid issues w.r.t namespace.
Shishir Bansal                 July 18, 2018          Added Geolocation class and it's instance in address
                                                      class to hold longitude and latitude values.
Vijay Kashikar         		   Sep 06, 2018           Make service responses to be available as part of global response objects
Vijay Kashikar         		   Sep 24, 2018           [PC-3580] Created a new method getValidityOfPharmacyCardLookupId()
                                                        to read PC_Pharmacy_Card_Lookup_ID_Validity__c from system settings
Vijay Kashikar         		   Sep 25, 2018           [PC-3629] Created a new property to hold the time when the pharmacy card response was generated. i.e PharmacyCardResponse.requestDate
Shishir Bansal                 Sep 28,2018            Added two new global variables to the global card class to store the pharmacyCardLookupID and pharmacyCardLookupRequestTime
Shishir Bansal                 Mar 11,2019            [PC-4577]  framework to submit the medical benefits request and receive the response from medical benefit vendor.
shishir Bansal                 Mar 24,2019            [PC-4579] added wrapper class and properties to store the response from medical benefit as program Coverage,
                                                       coverage benefits and coverage benefit items
Vijay Kashikar                  21-Jan-2021           [PC-7102] Added sharing clause
****************************************************************************************************************************************************/

/**
 * Provides interfaces, methods and classes necessary for eBi/Bv.
 */
global inherited sharing class PC_eBenefits {
    /**
    * Get the instance of pharmacy card class that implements PharmacyCard interface
    */
    global enum PharmacySearchBy {NPI, BEST_MATCH, NPI_NCPDP_POSTALCODE}
    //global enum PharmacySearchType {SEARCH_BY_NPI, BEST_MATCH}

    global static PharmacyCard getPharmacyCardService() {
        String handlerClass = getPharmacyCardClass();
        Type t = Type.forName(handlerClass);
        if (t != null) {

            Object o = t.newInstance();

            if (o instanceof PharmacyCard) {
                PharmacyCard handler = (PharmacyCard) o;
                return handler;
            }
            else {
                PC_Utility.throwAuraHandledException(Label.PC_Ebenefits_Handler_Class_Not_Found);
            }
        }
        else {
            PC_Utility.throwAuraHandledException(Label.PC_Ebenefits_Handler_Class_Not_Found);
        }
        return null;
    }
    /**
    * Get the pharmacy card class name configured in the custom meta data.
    */
    private static string getPharmacyCardClass() {
        return PC_eBenefits_Utility.getHandlerClass(PC_Constants.PC_eBENEFITS_PHARMACY_CARD_SERVICE_TYPE);
    }
    /**
    * Get the instance of pharmacy benefits class that implements PharmacyBenefits interface
    */
    global static PharmacyBenefits getPharmacyBenefitsService() {
        String handlerClass = getPharmacyCoverageClass();
        Type t = Type.forName(handlerClass);
        if (t != null) {

            Object o = t.newInstance();

            if (o instanceof PharmacyBenefits) {
                PharmacyBenefits handler = (PharmacyBenefits) o;
                return handler;
            }
            else {
                throw new AuraHandledException(Label.PC_Ebenefits_Handler_Class_Not_Found);
            }
        }
        else {
            throw new AuraHandledException(Label.PC_Ebenefits_Handler_Class_Not_Found);
        }
    }
    public static MedicalBenefits getMedicalBenefitsService() {
        String handlerClass = getMedicalBenefitsClass();
        Type t = Type.forName(handlerClass);
        if (t != null) {

            Object o = t.newInstance();

            if (o instanceof MedicalBenefits) {
                MedicalBenefits handler = (MedicalBenefits) o;
                return handler;
            }
            else {
                throw new AuraHandledException(Label.PC_Ebenefits_Handler_Class_Not_Found);
            }
        }
        else {
            throw new AuraHandledException(Label.PC_Ebenefits_Handler_Class_Not_Found);
        }
    }


    public static String getEbenefitsNamedCredential(String serviceType) {
        List<PC_eBenefits_Service_Configuration__mdt> config = [SELECT Id, PC_Named_Credential_Name__c
            FROM PC_eBenefits_Service_Configuration__mdt
            WHERE PC_Service_Type__c =: serviceType];
        if(config == null || config.isEmpty()) {
            PC_Utility.throwAuraHandledException('Named credential value not found in ebenefits configuration');
        }
        else if(config.size() == 1){

            return config[0].PC_Named_Credential_Name__c;
        }
        else {
            // todo throw exception? since size is greater than 1
            return config[0].PC_Named_Credential_Name__c;
        }
        return null;
    }


    /**
    * Get the instance of pharmacy finder class that implements PharmacyFinder interface
    */
    global static PharmacyFinder getPharmacyFinderService() {
        String handlerClass = getPharmacyFinderClass();
        Type t = Type.forName(handlerClass);
        if (t != null) {

            Object o = t.newInstance();

            if (o instanceof PharmacyFinder) {
                PharmacyFinder handler = (PharmacyFinder) o;
                return handler;
            }
            else {
                throw new AuraHandledException(Label.PC_Ebenefits_Handler_Class_Not_Found);
            }
        }
        else {
            throw new AuraHandledException(Label.PC_Ebenefits_Handler_Class_Not_Found);
        }
    }

    /**
     * Get the duration in seconds for validity of eligibility request.
     */
    public static Integer getValidityOfPharmacyCardLookupId() {
        Decimal duration = PC_System_Settings__c.getInstance().PC_Pharmacy_Card_Lookup_ID_Validity__c;
        if(duration == null) {
            return null;
        }
        else {
            return duration.intValue();
        }
    }

    /**
    * Get the pharmacy benefits class name configured in the custom meta data.
    */
    private static string getPharmacyCoverageClass() {
        return PC_eBenefits_Utility.getHandlerClass(PC_Constants.PC_eBENEFITS_PHARMACY_COVERAGE_SERVICE_TYPE);
    }

    /**
    * Get the pharmacy benefits class name configured in the custom meta data.
    */
    private static string getMedicalBenefitsClass() {
        return PC_eBenefits_Utility.getHandlerClass(PC_Constants.PC_eBENEFITS_MEDICAL_BENEFIT_SERVICE_TYPE);
    }

    /**
    * Get the pharmacy finder class name configured in the custom meta data.
    */
    private static string getPharmacyFinderClass() {
        return PC_eBenefits_Utility.getHandlerClass(PC_Constants.PC_eBENEFITS_PHARMACY_FINDER_SERVICE_TYPE);
    }

    /**
    * Implementor class will qualify to be called from PharmacyCardLookup.cmp.
    */
    global interface PharmacyCard {

        /**
         * Get the response from Pharma Card Lookup service.
         * @param request Holds information about Patient, Physician and Product.
         */
        PharmacyCardResponse lookupPharmacyCard(PharmacyCardRequest request);


        /**
         * Get the necessary patient info having patient's detials, physician and the product.
         */
        PharmacyCardRequest createPharmacyCardRequest();

        /**
         * Append any additional health plan information to the health plan object that is going to saved in the system.
         * @param response Response received from the pharmacy card lookup service.
         * @param healthPlan Health Plan being saved in the system.
         */
        void updateHealthPlan(PharmacyCardResponse response, PC_Health_Plan__c healthPlan);
    }
    /**
    * Defines aura enabled attributes to hold patient, physician and product information
    */
    global inherited sharing class PharmacyCardRequest {
        /**
        * Property to hold patient's information
        */
        @auraEnabled global Patient patient;
        /**
        * Property to hold physician's information
        */
        @auraEnabled global Physician physician;
        /**
        * Property to hold product's information
        */
        @auraEnabled global Drug product;

        /**
        * Constructor to initialize all the properties of the class
        */
        global  PharmacyCardRequest() {
            this.patient = new Patient();
            this.patient.address = new Address();

            this.physician = new Physician();
            this.physician.address = new Address();

            this.product = new Drug();
        }
    }
    /**
    * Defines aura enabled attributes for a patient/cardholder
    */
    global inherited sharing class Patient {

        /**
        * Property to hold salesforce ID of the patient.
        */
        @auraEnabled global String id = PC_Constants.EMPTY_STRING;
        /**
        * Property to hold first name.
        */
        @auraEnabled global String firstName;
        /**
        * Property to hold label for first name.
        */
        @auraEnabled global String firstNameLabel;
        /**
        * Property to hold label for name.
        */
        @auraEnabled global String nameLabel;
        /**
        * Property to hold last name.
        */
        @auraEnabled global String lastName;
        /**
        * Property to hold label for last name.
        */
        @auraEnabled global String lastNameLabel;
        /**
        * Property to hold middle name.
        */
        @auraEnabled global String middleName;
        /**
        * Property to hold label for middle name.
        */
        @auraEnabled global String middleNameLabel;
        /**
        * Property to hold birth date in JSON format
        */
        @auraEnabled global String birthdate;
        /**
        * Property to hold birth date in date format
        */
        @auraEnabled global Date dob;
        /**
        * Property to hold label for birth date.
        */
        @auraEnabled global String birthdateLabel;
        /**
        * Property to hold gender.
        */
        @auraEnabled global String gender;
        /**
        * Property to hold label for gender.
        */
        @auraEnabled global String genderLabel;
        /**
        * Property to hold prefix.
        */
        @auraEnabled global String prefix;
        /**
        * Property to hold suffix.
        */
        @auraEnabled global String suffix;
        /**
        * Property to hold address.
        */
        @auraEnabled global Address address;
        /**
       * Property to hold label for cardHolderRelationship.
       */
        @auraEnabled global String cardHolderRelationshipLabel;
        /**
        * Property to hold cardHolderRelationship.
        */
        @auraEnabled global String cardHolderRelationship;
        /**
        * Property to hold PBM Plan Coverage areas List{Retail , Mail , Speciality, Longtearm}.
        */
        @auraEnabled global List<coverageAlerts> coverageAlerts;
        /**
        * Property to hold zipcode.
        */
        @auraEnabled global String zipCode;
        /**
        * Property to hold SSN.
        */
        @auraEnabled global String ssn;
    }

    global inherited sharing class PatientLabels{
        /**
        * Property to hold label for first name.
        */
        @auraEnabled global String firstNameLabel;
        /**
        * Property to hold label for last name.
        */
        @auraEnabled global String lastNameLabel;
        /**
        * Property to hold label for dob name.
        */
        @auraEnabled global String dobLabel;
        /**
        * Property to hold label for gender.
        */
        @auraEnabled global String genderLabel;
        /**
        * Property to hold label for zip code.
        */
        @auraEnabled global String zipCodeLabel;
        /**
        * Property to hold label for SSN.
        */
        @auraEnabled global String ssnLabel;

        global PatientLabels(){
            firstNameLabel=Account.PC_First_Name__c.getDescribe().getLabel();
            lastNameLabel=Account.PC_Last_Name__c.getDescribe().getLabel();
            dobLabel=Account.PC_Date_of_Birth__c.getDescribe().getLabel();
            genderLabel=Account.PC_Gender__c.getDescribe().getLabel();
            zipCodeLabel=Account.PC_Primary_Zip_Code__c.getDescribe().getLabel();
            ssnLabel=Label.PC_MedicalBenefits_SSN_Label;
        }



    }

    /**
    * Defines aura enabled attributes for a physician
    */
    global inherited sharing class Physician {
        /**
        * Property to hold Salesforce ID of the physician.
        */
        @auraEnabled global String id = PC_Constants.EMPTY_STRING;
        /**
        * Property to hold label for name.
        */
        @auraEnabled global String nameLabel;
        /**
        * Property to hold first name.
        */
        @auraEnabled global String firstName;
        /**
        * Property to hold label for first name.
        */
        @auraEnabled global String firstNameLabel;
        /**
        * Property to hold last name.
        */
        @auraEnabled global String lastName;
        /**
        * Property to hold label for last name.
        */
        @auraEnabled global String lastNameLabel;
        /**
        * Property to hold middle name.
        */
        @auraEnabled global String middleName;
        /**
        * Property to hold label for middle name.
        */
        @auraEnabled global String middleNameLabel;
        /**
        * Property to hold birth date.
        */
        @auraEnabled global String birthdate;
        /**
        * Property to hold label for birth date.
        */
        @auraEnabled global String birthdateLabel;
        /**
        * Property to hold gender.
        */
        @auraEnabled global String gender;
        /**
        * Property to hold label for gender.
        */
        @auraEnabled global String genderLabel;
        /**
        * Property to hold prefix.
        */
        @auraEnabled global String prefix;
        /**
        * Property to hold suffix.
        */
        @auraEnabled global String suffix;
        /**
        * Property to hold NPI.
        */
        @auraEnabled global String npi = PC_Constants.EMPTY_STRING;
        /**
        * Property to hold label for NPI.
        */
        @auraEnabled global String npiLabel;
        /**
       * Property to hold address.
       */
        @auraEnabled global Address address;
    }

    /**
    * Defines aura enabled attributes for a product/drug
    */
    global inherited sharing class Drug {
        /**
        * Property to hold Salesforce ID of the product.
        */
        @auraEnabled global String id = PC_Constants.EMPTY_STRING;
        /**
        * Property to hold label.
        */
        @auraEnabled global String label;
        /**
        * Property to hold NDC.
        */
        @auraEnabled global String ndc;
        /**
        * Property to hold unitOfMeasureCode.
        */
        @auraEnabled global String unitOfMeasureCode;
    }

    /**
    * Defines aura enabled attributes for address
    */
    global inherited sharing class Address {
        /**
        * Property to hold address1.
        */
        @auraEnabled global String addressOne = PC_Constants.EMPTY_STRING;
        /**
        * Property to hold address2.
        */
        @auraEnabled global String addressTwo;
        /**
        * Property to hold city.
        */
        @auraEnabled global String city = PC_Constants.EMPTY_STRING;
        /**
        * Property to hold state.
        */
        @auraEnabled global String state = PC_Constants.EMPTY_STRING;
        /**
        * Property to hold postal code.
        */
        @auraEnabled global String postalCode = PC_Constants.EMPTY_STRING;
        /**
        * Property to hold label for postal code.
        */
        @auraEnabled global String postalCodeLabel = PC_Constants.EMPTY_STRING;
        /**
        * Property to hold label for city.
        */
        @auraEnabled global String cityLabel = PC_Constants.EMPTY_STRING;
        /**
        * Property to hold label for state.
        */
        @auraEnabled global String stateLabel = PC_Constants.EMPTY_STRING;
        /**
        * Property to hold Salesforce ID of the address.
        */
        @auraEnabled global String id = PC_Constants.EMPTY_STRING;
        /**
        * Property to hold country
        */
        @auraEnabled global String country;
        /**
        * Property to hold Lat and Long of the geoLocation
        */
        @auraEnabled global Geolocation geoLocation;
    }


    /**
    * Defines aura enabled attributes for geolocation latitude and longitude
    */
    global inherited sharing class Geolocation{
        /**
        * Property to hold latitude
        */
        @auraEnabled global String latitude;
        /**
        * Property to hold longitude
        */
        @auraEnabled global String longitude;

    }



    /**
    * Defines aura enabled attributes for pharmacy card lookup service response
    */
    global inherited sharing class PharmacyCardResponse {
        /**
        * Property to hold subscriber.
        */
        @auraEnabled global Patient subscriber;
        /**
        * Property to hold plan name.
        */
        @auraEnabled global string planName;
        /**
        * Property to hold plan name label.
        */
        @auraEnabled global string planNameLabel;

        /**
        * Property to hold PCN.
        */
        @auraEnabled global string pcn;
        /**
        * Property to hold PCN label.
        */
        @auraEnabled global string pcnLabel;

        /**
        * Property to hold insurance group name.
        */
        @auraEnabled global string insuranceGroupName;
        /**
        * Property to hold insurance group name label.
        */
        @auraEnabled global string insuranceGroupNameLabel;

        /**
        * Property to hold insurance group ID.
        */
        @auraEnabled global string insuranceGroupId;
        /**
        * Property to hold insurance group ID label.
        */
        @auraEnabled global string insuranceGroupIdLabel;

        /**
        * Property to hold BIN.
        */
        @auraEnabled global string bin;
        /**
       * Property to hold BIN label.
       */
        @auraEnabled global string binLabel;

        /**
        * Property to hold policy ID.
        */
        @auraEnabled global string policyID;
        /**
        * Property to hold policy ID label.
        */
        @auraEnabled global string policyIDLabel;

        /**
        * Property to hold whether mail coverage is available.
        */
        @auraEnabled global boolean mailCoverage;
        /**
        * Property to hold label for whether mail coverage is available.
        */
        @auraEnabled global string mailCoverageLabel;

        /**
        * Property to hold whether retail coverage is available.
        */
        @auraEnabled global boolean retailCoverage;
        /**
        * Property to hold label whether retail coverage is available.
        */
        @auraEnabled global string retailCoverageLabel;

        /**
       * Property to hold whether long term care coverage is available.
       */
        @auraEnabled global boolean longTermCareCoverage;
        /**
        * Property to hold label for whether long term care coverage is available.
        */
        @auraEnabled global string longTermCareCoverageLabel;

        /**
       * Property to hold whether specialty coverage is available.
       */
        @auraEnabled global boolean specialtyCoverage;
        /**
        * Property to hold label for whether specialty coverage is available.
        */
        @auraEnabled global string specialtyCoverageLabel;

        /**
        * Property to indicate whether the response obtained from the service is a success or failure. This is used to show an error message to the end user.
        */
        @auraEnabled global boolean isSuccess;
        /**
        * Property to hold error message that needs to be logged in case of failure.
        */
        @auraEnabled global string errorMessage;

        /**
        * Property to hold additionalInfo.
        */
        @auraEnabled global List<AdditionalInfo> additionalInfo;

        /**
       * Property to hold id for the response from UBC.
       */
        @auraEnabled global string id;
        /**
      * Property to hold any external id for the response from UBC.
      */
        @auraEnabled global string extId;
        /**
      * Property to hold the time when the pharmacy card response was generated.
      */
        @auraEnabled global Datetime requestDate;
        /**
          * Property to hold all service responses.
          */
        global Map<String, String> allServiceResponses;


    }
    /**
    * Property to hold any additional info in response. This is not yet supported in the product.
    */
    global inherited sharing class AdditionalInfo {
        /* TODO support this feature based on requirements */
        /**
        * Property to hold label for additional information.
        */
        @auraEnabled global string label;
        /**
        * Property to hold value for additional information.
        */
        @auraEnabled global string value;
    }

    /**
    * Implementor of this interface will qualify to be called from PC_PharmacyEbenefitsLookup.comp
    */
    global interface PharmacyBenefits {
        /**
         * Get the response from pharmacy benefits lookup service.
         * @param request Holds information about patient, cardholder, prescription, pharmacy, physician
         */
        PharmacyBenefitsResponse lookupPharmacyBenefits(PharmacyBenefitsRequest pharmacyBenefitsRequest);

        /**
         * Append any additional program coverage information to the program coverage object that is going to saved in the system.
         * @param pharmacyBenefitsResponse Holds information retrieved from the lookup service.
         * @param programCoverage Program Coverage being saved in the system.
         */
        void updateProgramCoverage(PharmacyBenefitsResponse pharmacyBenefitsResponse, PC_Program_Coverage__c programCoverage);

        /**
         * Get the necessary patient info having patient's detials, health plans, prescriptions, and pharmacies.
         */
        PharmacyBenefitsRequest createPharmacyBenefitsRequest();

    }

    /**
    * Implementor of this interface will qualify to be called from PC_PharmacyEbenefitsLookup.comp
    */
    global interface PharmacyBenefits2 extends PharmacyBenefits{
        /**
         * Append any additional pharmacy information that is going to saved in the system and linked to the program coverage.
         * This method will be called only when a non-existing pharmacy will have to linked to the program coverage.
         * @param pharmacyBenefitsResponse Holds information retrieved from the lookup service.
         * @param pharmacy Pharmacy being saved in the system.
         * @param address Pharmacy address being saved in the system.
         */
        void updatePharmacy(PharmacyBenefitsResponse pharmacyBenefitsResponse, Account pharmacy, PC_Address__c address);
    }

    /**
    * Implementor of this class will be qualified to be called for pharmacy search feature from PC_PharmacyEbenefitsLookup.comp
    */
    global interface PharmacyFinder {
        /**
         * Get the list of pharmacies
         */

        List<Pharmacy> SearchPharmacies(PharmacySearchParams params);
    }
    /**
    * Holds information about the pharmacy search parameters
    */
    global inherited sharing class PharmacySearchParams {
        /**
        * Property to hold name
        */
        @AuraEnabled global string name;
        /**
        * Property to hold NPI
        */
        @AuraEnabled global String npi{get;set;}
        /**
        * Property to hold zipcode
        */
        @AuraEnabled global String zipCode{get;set;}
        /**
        * Property to hold NCPDP VALUE
        */
        @AuraEnabled global String ncpdp{get;set;}
        /**
        * Property to identify search type
        */
        //@AuraEnabled global PharmacySearchType searchType {get;set;}
        /**
        * Property to identify search type
        */
        @AuraEnabled global PharmacySearchBy searchBy {get;set;}
        /**
        * Property to identify if search is filtered for specialty pharmacies
        */
        @AuraEnabled global Boolean isSpecialty {get;set;}
        /**
        * Property to identify if search is filtered for long term pharmacies
        */
        @AuraEnabled global Boolean isLongTerm {get;set;}
        /**
        * Property to identify if search is filtered for retail pharmacies
        */
        @AuraEnabled global Boolean isRetail {get;set;}
        /**
        * Property to identify if search is filtered for retail pharmacies
        */
        @AuraEnabled global Boolean isMailOrder {get;set;}

    }
    /**
    * Holds information about the information shown on the UI of PC_PharmacyEbenefitsLookup.comp
    */
    global inherited sharing class PharmacyBenefitsOptions {
        /**
        * Property to hold list of health plans
        */
        @AuraEnabled global List<BaseSObject> healthPlans;
        /**
        * Property to hold list of pharmacies
        */
        @AuraEnabled global List<BaseSObject> pharmacies;
        /**
        * Property to hold map of prescriptions. Each prescription must have these properties...
        * Name, PC_Days_Supply__c, PC_Requested_Quantity__c, PC_Product__r.Id, PC_Product__r.Name, PC_Dosage__c
        */
        @AuraEnabled global Map<String, Prescription> prescriptions;
        /**
        * Property to hold pharma card request object having patient, physician and product information
        */
        @AuraEnabled global PharmacyCardRequest cardHolder;

    }

    /**
    * Holds information such as pharmacy, prescription, cardHolder, patient, physician, drug, card which is necessary to call the pharmacy benefit lookup service
    */
    global inherited sharing class PharmacyBenefitsRequest {
        /**
        * Property to hold pharmacy info
        */
        @AuraEnabled global Pharmacy pharmacy;

        /**
        * Property to hold prescription info
        */
        @AuraEnabled global Prescription prescription;
        /**
        * Property to hold cardHolder info
        */
        @AuraEnabled global Patient cardHolder;
        /**
        * Property to hold cardHolder info
        */
        @AuraEnabled global Patient patient;
        /**
        * Property to hold physician info
        */
        @auraEnabled global Physician physician;
        /**
        * Property to hold drug info
        */
        @AuraEnabled global Product drug;
        /**
        * Property to hold health card info
        */
        @AuraEnabled global Card card;
        /**
        * index of the pharmacy in the list tof pharmacy options. Used for internal purpose and not to be changed
        */
        @AuraEnabled global integer index;
        /**
        * Id of the original caseId.
        */
        @AuraEnabled global String caseId;//Added new attribute - ACLS
        /**
        * Id of the selected healthPlanId.ss
        */
        @AuraEnabled global String healthPlanId;//Added new attribute - ACLS
        /**
        * Id of the selected prescriptionId.
        */
        @AuraEnabled global String prescriptionId; //Added new attribute - ACLS

        /**
        * Constructor to initialize the class members
        */
        global PharmacyBenefitsRequest() {
            this.pharmacy = new Pharmacy();
            this.prescription = new Prescription();
            this.cardHolder = new Patient();
            this.cardHolder.address = new Address();
            this.patient = new Patient();
            this.patient.address = new Address();
            this.physician = new Physician();
            this.physician.address = new Address();
            this.drug = new Product();
            this.card = new Card();
            this.caseId = '';
            this.healthPlanId = '';
            this.prescriptionId = '';
        }

    }

    /**
    * Provides properties to hold health card info
    */
    global inherited sharing class Card{
        /**
        * Property to hold PBM Member id
        */
        @AuraEnabled global String pbmMemberId{get;set;}
        /**
        * Property to hold member ID
        */
        @AuraEnabled global String memberId{get;set;}
        /**
        * Property to hold group id
        */
        @AuraEnabled global String groupId{get;set;}
        /**
        * Property to hold request Date coming from pharmacy Card Lookup
        */
        @AuraEnabled global Datetime pharmacyCardLookupRequestTime{get;set;}
        /**
        * Property to hold id of pharmacy Card Lookup record
        */
        @AuraEnabled global String pharmacyCardLookupID{get;set;}
    }

    /**
    * Provides properties to hold pharmacy info
    */
    global inherited sharing class Pharmacy  {
        /**
        * Property to hold Salesforce ID
        */
        @AuraEnabled global string id;
        /**
        * Property to hold name
        */
        @AuraEnabled global string name;
        /**
        * Property to hold display name
        */
        @AuraEnabled global string displayName;
        /**
        * Property to hold NPI
        */
        @AuraEnabled global String npi{get;set;}
        /**
        * Property to any external Id
        */
        @AuraEnabled global String extId{get;set;}
        /**
        * Property to hold info whether the Pharmacy is external or coming from salesforce
        */
        @AuraEnabled global Boolean isExternalPharmacy{get;set;}
        /**
        * Property to hold the type of pharmacy
        */
        @AuraEnabled global String specialtyType{get;set;}
        /**
        * Property to hold zip code
        */
        @AuraEnabled global string zipCode;
        /**
        * Property to hold phone
        */
        @AuraEnabled global string phone;
        /**
        * Property to hold phone
        */
        @AuraEnabled global string fax;
        /**
        * Property to hold NCPDP value
        */
        @AuraEnabled global string ncpdp;
        /**
        * Property to hold address.
        */
        @auraEnabled global Address address;


    }
    /**
    * Provides properties to hold pharmacy type info
    */
    global inherited sharing class PharmacyType {
        /**
         * Property to hold pharmacy type info
         */
        @AuraEnabled global string type;
    }

    /**
    * Provides properties to hold prescription info
    */
    global inherited sharing class Prescription  {
        /**
        * Property to hold Salesforce ID
        */
        @AuraEnabled global string id;
        /**
        * Property to hold name
        */
        @AuraEnabled global string name;
        /**
        * Property to hold days supply
        */
        @AuraEnabled global Decimal daysSupply;
        /**
        * Property to hold ddosage
        */
        @AuraEnabled global String dosage;
        /**
        * Property to hold requested quantity
        */
        @AuraEnabled global Decimal requestedQuantity;
        /**
        * Property to hold product Id
        */
        @AuraEnabled global string productId;
        /**
        * Property to hold product Name
        */
        @AuraEnabled global string productName;
        /**
        * Property to hold product  manufacturer Name
        */
        @AuraEnabled global string manufacturerName;
        /**
        * Property to hold product NDC
        */
        @AuraEnabled global string ndc;
        /**
        * Property to hold label for product NDC
        */
        @AuraEnabled global string ndcLabel;
        /**
        * Property to hold possibility of home delivery
        */
        @AuraEnabled global Boolean includeHomeDelivery{get;set;}
        /**
        * Property to hold 90 days of retail prescription
        */
        @AuraEnabled global Boolean include90DaysRetail{get;set;}
        /**
        * Property to hold product unitOfMeasureCode
        */
        @AuraEnabled global string unitOfMeasureCode;
        /**
        * Property to hold product unitOfMeasureCode label
        */
        @AuraEnabled global string unitOfMeasureCodeLabel;
        /**
        * Property to hold placeOfService value
        */
        @AuraEnabled global string placeOfService;
        /**
        * Property to hold product details
        */
        @AuraEnabled global Product drug;
        /**
        * Property to hold product details
        */
        @AuraEnabled global Physician physician;
        /**
        * Property to hold primaryDiagnosis details
        */
        @AuraEnabled global string primaryDiagnosis;
        /**
        * Property to hold secondaryDiagnosis details
        */
        @AuraEnabled global string  secondaryDiagnosis;
        /**
        * Property to hold adminCodes
        */
        @AuraEnabled global List<keyValue> adminCodes;

    }

    /**
     * Provides properties to hold Prescription labels
     */
    global inherited sharing class PrescriptionLabels{
        /**
        * Property to hold label of name label
        */
        @AuraEnabled global String name;
        /**
        * Property to hold label of productName label
        */
        @AuraEnabled global String productName;
        /**
        * Property to hold label of productName label
        */
        @AuraEnabled global String drugManufacturer;
        /**
        * Property to hold label of productName label
        */
        @AuraEnabled global String placeOfService;
        /**
        * Property to hold label of provider name label
        */
        @AuraEnabled global String providerName;
        /**
        * Property to hold label of provider state label
        */
        @AuraEnabled global String providerState;
         /**
        * Property to hold label of primaryDiagnosis label
        */
        @AuraEnabled global String primaryDiagnosis;
         /**
        * Property to hold label of secondaryDiagnosis   label
        */
        @AuraEnabled global String secondaryDiagnosis;
        /**
        * Property to hold label of strength   label
        */
        @AuraEnabled global String strength;
        /**
        * Property to hold label of provider NPI label
        */
        @AuraEnabled global String providerNPI;
        /**
        * Property to hold label of provider First Name label
        */
        @AuraEnabled global String providerFirstName;
        /**
        * Property to hold label of provider Last Name label
        */
        @AuraEnabled global String providerLastName;

        global PrescriptionLabels(){
            name =Label.PC_MedicalBenefits_Prescription;
            productName = Product2.name.getDescribe().getLabel();
            drugManufacturer =Label.PC_MedicalBenefits_DrugManufacturer;
            //  -todo-  once the field is created on the object

            placeOfService = PC_Prescription__c.PC_PlaceOfService__c.getDescribe().getLabel();
            primaryDiagnosis = PC_Prescription__c.PC_PrimaryDiagnosis__c.getDescribe().getLabel();
            secondaryDiagnosis = PC_Prescription__c.PC_SecondaryDiagnosis__c.getDescribe().getLabel();
            providerName = Label.PC_MedicalBenefits_ProviderName;
            providerFirstName = Label.PC_MedicalBenefits_ProviderFirstName;
            providerLastName = Label.PC_MedicalBenefits_ProviderLastName;
            providerState = Label.PC_MedicalBenefits_ProviderState;
            providerNPI = Label.PC_MedicalBenefits_ProviderNPI;
            strength = Product2.PC_Strength__c.getDescribe().getLabel();

        }
    }


    /**
    * Provides properties to hold basic information about anything
    */
    global inherited sharing class BaseSobject{
        /**
        * Property to hold Salesforce ID
        */
        @AuraEnabled global string id;
        /**
        * Property to hold name
        */
        @AuraEnabled global string name;
        /**
        * Property to hold display name
        */
        @AuraEnabled global string displayName;

        /**
        * Property to hold display name
        */
        @AuraEnabled global Map<String, Object> additionalInfo;


    }

    /**
    * Provides properties to hold extended response data received from pharmacy benefits lookup services.
    */
    global inherited sharing class PharmacyBenefitsResponse {
        /**
        * Property to hold Salesforce ID of the pharmacy. This is used internally.
        */
        @AuraEnabled global string pharmacyId;
        /**
        * Property to hold check if the pharmacy is an external pharmacy.
        */
        @AuraEnabled global boolean isExternalPharmacy;
        /**
        * Property to hold pharmacy name.
        */
        @AuraEnabled global string pharmacyName;
        /**
        * Property to hold Salesforce ID of the health plan. This is used internally.
        */
        @AuraEnabled global string healthPlanId;
        /**
        * Property to hold Salesforce ID of the case. This is used internally.
        */
        @AuraEnabled global string caseId;
        /**
        * Property to hold Salesforce ID of the prescription. This is used internally.
        */
        @AuraEnabled global string prescriptionId;
        /**
        * Property to indicate whether the response obtained from the service is a success or failure. This is used to show success/failure indicator to the end user.
        */
        @AuraEnabled global boolean isSuccess = true;
        /**
        * Property to hold look up service response.
        */
        @AuraEnabled global PharmacyEbenefitsServiceResponse eBenefitsServiceResponse;
        /**
        * Property to hold index of the row in the data set. This is used internally and is not be modified.
        */
        @AuraEnabled global integer index;
        /**
        * Property to hold index of the row in the data set. This is used internally and is not be modified.
        */
        @AuraEnabled global string errorMessage;
        /**
        * Property to hold additional info.
        */
        @AuraEnabled global Map<String, Object> additinalInfo;
        /**
         * Property to hold pharmacy object. This will be used to create a new pharmacy, if not exists, when creating the program coverage
         */
        @AuraEnabled global Pharmacy pharmacy;
        /**
        * Property to hold all service responses
        */
        global  Map<String, String> allServiceReponses {get;set;}



    }

    /**
    * Provides properties to hold response data received from pharmacy benefits lookup services.
    */
    global inherited sharing class PharmacyEbenefitsServiceResponse {
        /**
        * Property to hold priced quantity.
        */
        @AuraEnabled global Decimal metricQuantityPriced{get;set;}
        /**
        * Property to hold priced days of supply.
        */
        @AuraEnabled global Integer daysSupplyPriced{get;set;}
        /**
        * Property to hold information such as the deductible amount and the out of pocket
        */
        @AuraEnabled global accumulators accumulators{get;set;}
        /**
        * Property to hold pricing information.
        */
        @AuraEnabled global pricing pricing{get;set;}
        /**
        * Property to hold list of pharma coverage alerts.
        */
        @AuraEnabled global list<coverageAlerts> coverageAlerts{get;set;}
        /**
        * Property to hold list of pharmacy types.
        */
        @AuraEnabled global List<PharmacyType> pharmacyType{get; set;}
        /**
        * Property to hold list of pharmacy types.
        */
        @AuraEnabled global Map<String, Object> additionalInfo{get; set;}
        /**
        * Property to hold the information of the product
        */
        @AuraEnabled global Product product;
        /**
        * Property to hold prior authorization information
        */
        @AuraEnabled global PriorAuthorization priorAuthorization;
        /**
        * Property to hold service reponse
        */
        @AuraEnabled global String serviceResponse; //Added AuraEnabled - ACLS
        /**
        * Property to hold all the service reponses
        */
        global Map<String, String> allServiceReponses;


    }

    /**
    * Provides properties to hold deductible and out of pocket information of pharmacy benefit
    */
    global inherited sharing class accumulators{
        /**
        * Property to hold information about the deductible amount.
        */
        @AuraEnabled global deductible deductible{get;set;}
        /**
        * Property to hold information about out of pocket amount.
        */
        @AuraEnabled global outOfPocket outOfPocket{get;set;}
    }

    /**
    * Provides properties to hold deductible information of pharmacy benefit
    */
    global inherited sharing class deductible{
        /**
        * Property to hold information about individual's coverage information
        */
        @AuraEnabled global individual individual{get;set;}
    }


    /**
    * Provides properties to hold remaining and applied coverage information of pharmacy benefit
    */
    global inherited sharing class individual{
        /**
        * Property to hold information about remaining amount
        */
        @AuraEnabled global Decimal remaining{get;set;}
        /**
        * Property to hold information about remaining amount in dollar currency format
        */
        @AuraEnabled global String remainingInDollarCurrency{get; set;}
        /**
        * Property to hold information about the applied amount
        */
        @AuraEnabled global Decimal applied{get;set;}
        /**
        * Property to hold information about the applied amount in dollar currency format
        */
        @AuraEnabled global String appliedInDollarCurrency{get; set;}
    }

    /**
    * Provides properties to hold out of pocket information of pharmacy benefit
    */
    global inherited sharing class outOfPocket{
        /**
        * Property to hold information about individual's coverage information
        */
        @AuraEnabled global individual individual{get;set;}
    }

    /**
    * Provides properties to hold coverage alert information of pharmacy benefit
    */
    global inherited sharing class coverageAlerts{
        /**
        * Property to hold coverage id
        */
        @AuraEnabled global String id{get;set;}
        /**
        * Property to hold coverage name
        */
        @AuraEnabled global String name{get;set;}
        /**
        * Property to hold  health plan coverage area values
        */
        @AuraEnabled global boolean  value {get;set;}
        /**
        * Property to hold  health plan coverage description
         */
        @AuraEnabled global String description {get;set;}
    }

    /**
    * Provides properties to hold pricing information of pharmacy benefit
    */
    global inherited sharing class pricing{
        /**
        * Property to hold pricing to be paid by patient
        */
        @AuraEnabled global Decimal patient{get;set;}
        /**
        * Property to hold pricing to be paid by patient in dollar currency format
        */
        @AuraEnabled global String patientInDollarFormat{get;set;}
        /**
        * Property to hold pricing to be paid under the plan
        */
        @AuraEnabled global Decimal plan{get;set;}
    }

    /**
    * Implementor of this class will qualify to be called from PC_MedicalBenefitsLookup.comp
    */
    global interface MedicalBenefits {
        /**
         * Get the response from Medical Ebenefit service.
         * @param request Holds information about Patient, Clinc , Prescription and Health Plans.
         */
        MedicalBenefitsResponse lookupMedicalBenefits(PC_eBenefits.MedicalBenefitsRequest request);
        /**
        * Get the necessary  inputs for medical benefits.
        */
        MedicalBenefitsRequest createMedicalBenefitRequest();
        /**
        * Append any additional coverage benefit information to the record that is going to saved in the system.
        * @param response Response received from the medical ebenefits service.
        * @param sCoverage saving data on Program Coverage, Coverage Benefit and Coverage Benefit item
        */
        void updateCoverage(MedicalBenefitsResponse response, sCoverageDetail sCoverage);

    }
    /**
    * Provides properties to hold healthplans, prescriptions, cardholder information
    */
    global inherited sharing class MedicalBenefitsRequest {
        /**
        * Property to hold the value for primary health Plan details
       */
        @AuraEnabled global HealthPlan primaryHealthPlan;
        /**
        *  Property to hold the value for secondary health Plan details
       */
        @AuraEnabled global HealthPlan secondaryHealthPlan;
        /**
        *  Property to hold the value for tertiary health Plan details
       */
        @AuraEnabled global HealthPlan tertiaryHealthPlan;
        /**
         * Property the Prescription selected on the UI
        */
         @AuraEnabled global Prescription prescription;
        /**
         * Property the Patient selected on the UI
        */
         @AuraEnabled global Patient patient;
        /**
         * Property the Clinic selected on the UI
        */
         @AuraEnabled global Clinic clinic;
        /**
         * Property to hold the cptCodes
        */
         global List<String> cptCodes;
        /**
         * Property to hold the cptCodeMap
        */
         global Map<String, String> cptCodeMap;
        global MedicalBenefitsRequest(){

        primaryHealthPlan = null;
        secondaryHealthPlan = null;
        tertiaryHealthPlan = null;
        prescription = new Prescription();
        patient = new Patient();
        clinic = new Clinic();
        cptCodes = new List<String>();
        cptCodeMap = null;

        }

    }


    /**
    * Provides properties to hold sCoverage detials
    */
    global inherited sharing class sCoverageDetail {
       /**
        * Property to hold the caseId
        */
        global id caseId;
        /**
        * Property to hold the patientId
        */
        global id patientId;
        /**
        * Property to hold the program coverage data
        */
        global PC_Program_Coverage__c programCoverage;
        /**
        * Property to hold the primary MemberPlan
        */
        global MemberPlan primaryMemberPlan;
        /**
        * Property to hold the secondary MemberPlan
        */
        global MemberPlan secondaryMemberPlan;
        /**
        * Property to hold the tertiary MemberPlan
        */
        global MemberPlan tertiaryMemberPlan;
        /**
        * Property to hold the coverage Benefits
        */
        global CoverageBenefit primaryCoverageBenefit;
        /**
        * Property to hold the coverage Benefits
        */
        global CoverageBenefit secondaryCoverageBenefit;
        /**
        * Property to hold the coverage Benefits
        */
        global CoverageBenefit tertiaryCoverageBenefit;
        /**
        * Property to hold the benefit Items
        */
        global List<CoverageBenefitItem> primaryCoverageBenefitItems;
        /**
        * Property to hold the benefit Items
        */
        global List<CoverageBenefitItem> secondaryCoverageBenefitItems;
        /**
        * Property to hold the benefit Items
        */
        global List<CoverageBenefitItem> tertiaryCoverageBenefitItems;


        global sCoverageDetail(){

            programCoverage = new PC_Program_Coverage__c();
            //primaryMemberPlan = new MemberPlan();
            //secondaryMemberPlan = new MemberPlan();
            //tertiaryMemberPlan = new MemberPlan();
            primaryMemberPlan =null;
            secondaryMemberPlan = null;
            tertiaryMemberPlan =null;
            //primaryCoverageBenefit = new CoverageBenefit();
            //secondaryCoverageBenefit = new CoverageBenefit();
            //tertiaryCoverageBenefit = new CoverageBenefit();
            primaryCoverageBenefit = null;
            secondaryCoverageBenefit = null;
            tertiaryCoverageBenefit =null;
            primaryCoverageBenefitItems = new List<CoverageBenefitItem>();
            secondaryCoverageBenefitItems = new List<CoverageBenefitItem>();
            tertiaryCoverageBenefitItems = new List<CoverageBenefitItem>();


        }

    }

    /**
    * Provides properties to hold response from medical benefits service
    */
    global inherited sharing class MedicalBenefitsResponse {
       /**
        * Property to hold the patient id
        */
        global String patientId;
        /**
        * Property to hold the program coverage data
        */
        @AuraEnabled global ProgramCoverage programCoverage;
        /**
        * Property to hold the Program Coverage completion Status
        */
        @AuraEnabled global String completionStatus;
        /**
        * Property to hold additionalInfo
        */
        @AuraEnabled global Map<String, Object> additionalInfo;
        /**
        * Property to hold isSuccess.   error -- false , else true  success message as
        */
        @AuraEnabled global Boolean isSuccess;
        /**
        * Property to hold successMessages
        */
        @AuraEnabled global List<String> successMessages;
        /**
        * Property to hold errors
        */
        @AuraEnabled global List<String> errors;
        /* Default Constructor */
        global MedicalBenefitsResponse(){
            patientId = PC_Constants.EMPTY_STRING;
            programCoverage = new ProgramCoverage();
            isSuccess = false;
            successMessages = new List<String>();
            errors =new List<String>();

        }
    }

    /**
    * Provides properties to hold Coverage Benefit Item data
    */
    global inherited sharing class ProgramCoverageBenefit {

        /**
         * Property to hold the memeberPlan
        */
        global MemberPlanDetail memberPlan; // memberPlan  object
        /**
         * Property to hold the name of Coverage Benefit record
        */
        global String name;
        /**
         * Property to hold the id of the record
        */
        global Id id; //

        /**
         * Property to hold the type of health paln
        */
        global String coverageLevel;  // type of CoverageBenefit
        /**
         * Property to hold the transaction Id
        */
        global String transactionId;
        /**
         * Property to hold the transaction Date
        */
        global Date transactionDate;
        /**
        * Property to hold the coverage Status
       */
        global String coverageStatus;
        /**
        * Property to hold the Benefit Notes
       */
        global String benefitNotes;
        /**
         * Property to hold the start Date
        */
        global Date startDate;
        /**
         * Property to hold the end Date
        */
        global Date endDate;
        /**
         * Property to hold the payer Name
        */
        global String payerName;
        /**
         * Property to hold the plan Name
        */
        global String planName;
        /**
         * Property to hold the plan Type
        */
        global String planType;
        /**
         * Property to hold the group No
        */
        global String groupNo;
        /**
         * Property to hold the group Name
        */
        global String groupName;
        /**
         * Property to hold the Individual In Network Deductible Limit
        */
        global Decimal individualInNetworkDeductibleLimit;
        /**
         * Property to hold the Individual In Network Deductible Remaining
        */
        global Decimal individualInNetworkDeductibleRemaining;
        /**
         * Property to hold the Individual In Network Out of Pocket Limit
        */
        global Decimal individualInNetworkOutofPocketLimit;
        /**
         * Property to hold the individual In Network Out of Pocket Remaining
        */
        global Decimal individualInNetworkOutofPocketRemaining;
        /**
         * Property to hold the family In Network Deductible Limit
        */
        global Decimal familyInNetworkDeductibleLimit;
        /**
         * Property to hold the Family In Network Deductible Remaining
        */
        global Decimal familyInNetworkDeductibleRemaining;
        /**
         * Property to hold the Family ln Network Out of Pocket Remaining
        */
        global Decimal familyInNetworkOutofPocketRemaining;
        /**
         * Property to hold the family In Network Out of Pocket Limit
        */
        global Decimal familyInNetworkOutofPocketLimit;
        /**
         * Property to hold the pa Required
        */
        global String  paRequired;
        /**
         * Property to hold the buy And Bill
        */
        global String  buyAndBill;
        /**
         * Property to hold the specialty Pharmacy Required
        */
        global String specialtyPharmacyRequired;
        /**
         * Property to hold the specialty Pharmacy Info
        */
        global String specialtyPharmacyInfo;
        /**
         * Property to hold the is Government Plan
        */
        global String isGovernmentPlan;
        /**
         * Property to hold the government Plan Type
        */
        global String governmentPlanType;
        /**
         * Property to hold the transaction Message ID
        */
        global String transactionMessageID;
        /**
         * Property to hold the product Admin Message
        */
        global String productAdminMessage;
        /**
         * Property to hold the billing Message
        */
        global String billingMessage;
        /**
         * Property to hold the prior Auth Message
        */
        global String priorAuthMessage;
        /**
         * Property to hold the payer Message
        */
        global String payerMessage;
        /**
        * Property to hold the benefit Items
        */
        global List<ProgramCoverageBenefitItem> benefitItems;

        global ProgramCoverageBenefit(){

            transactionId = PC_Constants.EMPTY_STRING;
            transactionDate = null;
            coverageStatus = PC_Constants.EMPTY_STRING;
            startDate = null;
            endDate = null;
            payerName = PC_Constants.EMPTY_STRING;
            planType = PC_Constants.EMPTY_STRING;
            groupNo = PC_Constants.EMPTY_STRING;
            groupName = PC_Constants.EMPTY_STRING;
            paRequired = PC_Constants.EMPTY_STRING;
            buyAndBill = PC_Constants.EMPTY_STRING;
            specialtyPharmacyRequired = PC_Constants.EMPTY_STRING;
            specialtyPharmacyInfo = PC_Constants.EMPTY_STRING;
            isGovernmentPlan = PC_Constants.EMPTY_STRING;
            governmentPlanType = PC_Constants.EMPTY_STRING;
            transactionMessageID = PC_Constants.EMPTY_STRING;
            productAdminMessage = PC_Constants.EMPTY_STRING;
            billingMessage = PC_Constants.EMPTY_STRING;
            priorAuthMessage = PC_Constants.EMPTY_STRING;
            payerMessage = PC_Constants.EMPTY_STRING;
            benefitNotes = PC_Constants.EMPTY_STRING;
            benefitItems = new List<ProgramCoverageBenefitItem>();

        }


    }

    /**
    * Provides properties to hold MemberPlanDetail
    */
    global inherited sharing class MemberPlanDetail{
        /**
        * Property to hold  Member Id value
        */
        @AuraEnabled global id Id;
    }

    /**
    * Provides properties to hold Program Coverage details
    */
    global inherited sharing class ProgramCoverage {


        /**
         * Property to hold the coordinated Plan Benefits
        */
        global String coordinatedPlanBenefits;
        /**
         * Property to hold the completionStatus
        */
        global String completionStatus;
        /**
         * Property to hold the program coverage Id
        */
        @AuraEnabled global String id;
        /**
        * Property to hold the primaryCoverageBenefits
        */
        global ProgramCoverageBenefit primaryCoverageBenefit;
        /**
        * Property to hold the secondaryCoverageBenefits
        */
        global ProgramCoverageBenefit secondaryCoverageBenefit;
        /**
        * Property to hold the tertiaryCoverageBenefits
        */
        global ProgramCoverageBenefit tertiaryCoverageBenefit;

        global ProgramCoverage(){

            coordinatedPlanBenefits = PC_Constants.EMPTY_STRING;
            primaryCoverageBenefit = null;
            secondaryCoverageBenefit =null;
            tertiaryCoverageBenefit = null;
            completionStatus = PC_Constants.EMPTY_STRING;


        }
    }


    /**
    * Provides properties to hold Coverage Benefit Item data
    */
    global inherited sharing class ProgramCoverageBenefitItem {

        /**
         * Property to hold the name
        */
        global String name;
        /**
         * Property to hold the coverage level
        */
        global String coverageLevel;
        /**
         * Property to hold the benefitCategory
        */
        global String benefitCategory ;
        /**
        * Property to hold the deductable Applies
       */
        global String deductableApplies;
        /**
         * Property to hold the coplay Applies
        */
        global String copayApplies;
        /**
         * Property to hold the coinsurance Applies
        */
        global String coinsuranceApplies;
        /**
         * Property to hold the oop Max Applies
        */
        global String oopMaxApplies;
        /**
         * Property to hold the pcp Copay Amount
        */
        global Decimal pcpCopayAmount;
        /**
         * Property to hold the specialist Copay Amount
        */
        global Decimal specialistCopayAmount;
        /**
         * Property to hold the coinsurance Percent
        */
        global Decimal coinsurancePercent;
        /**
         * Property to hold the ServiceType
        */
        global String serviceType;
        /**
         * Property to hold the Service Type Code
        */
        global String serviceTypeCode;

        global ProgramCoverageBenefitItem(){

           // cptCodes = new List<CPT>();
            //code=PC_Constants.EMPTY_STRING;
            benefitCategory = PC_Constants.EMPTY_STRING;
            coverageLevel=PC_Constants.EMPTY_STRING;
            deductableApplies=PC_Constants.EMPTY_STRING;
            copayApplies=PC_Constants.EMPTY_STRING;
            coinsuranceApplies=PC_Constants.EMPTY_STRING;
            oopMaxApplies=PC_Constants.EMPTY_STRING;
            ServiceTypeCode =PC_Constants.EMPTY_STRING;
            ServiceType = PC_Constants.EMPTY_STRING;


        }
    }

    /**
    * Provides properties to individual and family deductible amounts
    */
    global inherited sharing class DeductibleAmount {
        /**
        * Property to hold deductible amount for the individual
        */
        @AuraEnabled global IndividualDeductible individual;
        /**
        * Property to hold deductible amount for the family
        */
        @AuraEnabled global FamilyDeductible family;
    }
    /**
    * Provides properties to hold individual deductible information
    */
    global inherited sharing class IndividualDeductible {
        /**
        * Property to hold individual's original deductible amount
        */
        @AuraEnabled global decimal original;
        /**
        * Property to hold individual's original deductible amount in currency format
        */
        @AuraEnabled global String originalInCurrencyFormat;
        /**
        * Property to hold individual's remaining deductible amount
        */
        @AuraEnabled global decimal remaining;
        /**
        * Property to hold individual's remaining deductible amount in currency format
        */
        @AuraEnabled global String remainingInCurrencyFormat;
    }
    /**
    * Provides properties to hold family deductible information
    */
    global inherited sharing class FamilyDeductible {
        /**
        * Property to hold family's original deductible amount
        */
        @AuraEnabled global decimal original;
        /**
        * Property to hold family's original deductible amount in currency format
        */
        @AuraEnabled global String originalInCurrencyFormat;
        /**
        * Property to hold family's remaining deductible amount
        */
        @AuraEnabled global decimal remaining;
        /**
        * Property to hold family's remaining deductible amount in currency format
        */
        @AuraEnabled global String remainingInCurrencyFormat;
    }
    /**
    * Provides properties to hold copay information
    */
    global inherited sharing class Copay {
        /**
        * Property to hold the amount towards office visit
        */
        @AuraEnabled global OfficeVisit officeVisit;
        /**
        * Property to hold the amount towards drug
        */
        @AuraEnabled global Product product;
    }
    /**
    * Provides properties to hold office visit charges information
    */
    global inherited sharing class OfficeVisit {
        /**
        * Property to hold amount
        */
        @AuraEnabled global decimal amount;
        /**
        * Property to hold amount in currency format
        */
        @AuraEnabled global String amountInCurrencyFormat;
    }
    /**
    * Provides properties to hold drug information
    */
    global inherited sharing class Product {
        /**
        * Property to hold amount
        */
        @AuraEnabled global decimal amount;
        /**
        * Property to hold amount in currency format
        */
        @AuraEnabled global String amountInCurrencyFormat;
        /**
        * Property to hold amountNDC
        */
        @AuraEnabled global string ndc {get; set;}
        /**
        * Property to hold name
        */
        @AuraEnabled global string name {get; set;}
        /**
        * Property to hold label
        */
        @AuraEnabled global string label {get; set;}
        /**
        * Property to hold unit of measure code
        */
        @AuraEnabled global string unitOfMeasureCode {get; set;}
        /**
        * Property to hold drug DB source code
        */
        @AuraEnabled global string drugDbSourceCode {get; set;}
        /**
        * Property to hold product code qualifier
        */
        @AuraEnabled global string productCodeQualifier {get; set;}
        /**
        * Property to hold code list qualifier
        */
        @AuraEnabled global string codeListQualifier {get; set;}
        /**
        * Property to hold drug manufacturer name
        */
        @AuraEnabled global string drugManufacturerName {get; set;}
        /**
        * Property to hold drug strength
        */
        @AuraEnabled global string strength {get; set;}

    }
    /**
    * Provides properties to hold prior auth related information
    */
    global inherited sharing class PriorAuthorization {
        /**
        * Property to indicate if prior authorization is required.
        */
        @AuraEnabled global boolean isRequired;
    }

    /**
    * Provides properties to hold health plan
    */
    global inherited sharing class HealthPlan{
        /**
        * Property to hold Salesforce ID
        */
        @AuraEnabled global string id;
        /**
        * Property to hold health plan name
        */
        @AuraEnabled global string name;
        /**
        * Property to hold health plan name label
        */
        @AuraEnabled global string nameLabel;
        /**
        * Property to hold health plan display name
        */
        @AuraEnabled global string displayName;
        /**
        * Property to hold health plan group name
        */
        @AuraEnabled global string groupName;
        /**
        * Property to hold health plan group name label
        */
        @AuraEnabled global string groupNameLabel;
        /**
        * Property to hold payer name
        */
        //@AuraEnabled global string medicalBenefitName ;
        /**
        * Property to hold PBM name as per card lookup service
        */
        @AuraEnabled global string drugBenefitName ;
        /**
        * Property to hold pcn
        */
        @AuraEnabled global string pcn;
        /**
        * Property to hold PCN label
        */
        @AuraEnabled global string pcnLabel;
        /**
        * Property to hold bin
        */
        @AuraEnabled global string bin;
        /**
        * Property to hold bin label
        */
        @AuraEnabled global string binLabel;
        /**
        * Property to hold state
        */
        @AuraEnabled global string state;
        /**
        * Property to hold state label
        */
        @AuraEnabled global string stateLabel;

        /*** Following properties have been added as a part of PC-4130-- START ***/

        /**
        * Property to hold health plan label
        */
        @AuraEnabled global String healthPlanLabel;
        /**
        * Property to hold the boolean value if a health plan has been selected
        */
        @AuraEnabled global Boolean isHealthPlanSelected;
        /**
        * Property to hold plan type of Health Plan
        */
        @AuraEnabled global String planType;

        /*** Following properties have been added as a part of PC-4130-- END ***/

        /*** Following properties have been added as a part of PC-4131-- START ***/

        /**
        * Property to hold health plan's payer name value
        */
        @AuraEnabled global String payerName;
        /**
        * Property to hold health plan's payer id value
        */
        @AuraEnabled global String payerId;
        /**
        * Property to hold Health Plan's plan name value
        */
        @AuraEnabled global String planName;
        /**
        * Property to hold Health Plan's Member Id value
        */
        @AuraEnabled global String memberId;
        /**
        * Property to hold Health Plan's Relationship To Cardholder value
        */
        @AuraEnabled global String relationshipToCardholder;
        /**
        * Property to hold Health Plan's Relationship To Cardholder API name
        */
        @AuraEnabled global String relationshipToCardholderLabel;
        /**
        * Property to hold Health Plan's  Cardholder first name value
        */
        @AuraEnabled global String cardholderFirstName;
        /**
        * Property to hold Health Plan's Cardholder Last name value
        */
        @AuraEnabled global String cardholderLastName;
        /**
        * Property to hold Health Plan's Cardholder Date of Birth
        */
        @AuraEnabled global date cardholderDoB;
        /**
        * Property to hold Health Plan's Relationship To Cardholder gender value
        */
        @AuraEnabled global String cardholderGender;
        /**
        * Property to hold Health Plan's Relationship To Cardholder Id policy value
        */
        @AuraEnabled global String cardholderIdPolicy;
        /**
        * Property to hold Health Plan's policyNumber value
        */
        @AuraEnabled global String policyNumber;
        /**
        * Property to hold medicareSupplementalPlanLetter
        */
        global String medicareSupplementalPlanLetter;

        /*** Following properties have been added as a part of PC-4131-- END ***/

        global HealthPlan(){
            healthPlanLabel=PC_Constants.EMPTY_STRING;
            isHealthPlanSelected=false;
            planType=PC_Constants.EMPTY_STRING;
            payerName=PC_Constants.EMPTY_STRING;
            planName=PC_Constants.EMPTY_STRING;
            memberId=PC_Constants.EMPTY_STRING;
            relationshipToCardholder=PC_Constants.EMPTY_STRING;
            relationshipToCardholderLabel = PC_Constants.EMPTY_STRING;
            policyNumber = PC_Constants.EMPTY_STRING;
            medicareSupplementalPlanLetter = null;
        }
    }

    /*********************************************************************************
    Method Name    : getAccountIdByCaseId
    Author         : Hitha Avalakki
    Description    : This method is used to fetch Account Id present on a Case object
    Return Type    : Id
    Parameter      : Id
    User Story     : PC-4130
    *********************************************************************************/
    public static Id getAccountIdByCaseId(Id caseId) {
        List<String> fields = new List<String>();
        fields.add('Id');
        fields.add('AccountId');
        PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, fields);

        Case currentCase = [Select Id, AccountId from Case where id=:caseId];
        Id accountId;
        if(currentCase != null) {
            accountId = currentCase.AccountId;
        }
        return accountId;
    }

    /**
    * Provides properties to hold health plan field labels
    */
    global inherited sharing class HealthPlanLabel{
        /**
        * Property to hold label of Payer name
        */
        @AuraEnabled global String payerNameLabel;
        /**
        * Property to hold label of Plan name
        */
        @AuraEnabled global String planNameLabel;
        /**
        * Property to hold health plan member Id label
        */
        @AuraEnabled global String memberIdLabel;
        /**
        * Property to hold label of health plan's relationship to cardholder field
        */
        @AuraEnabled global String relationshipToCardholderLabel;

        global HealthPlanLabel(){
            payerNameLabel=PC_Constants.EMPTY_STRING;
            planNameLabel=PC_Constants.EMPTY_STRING;
            memberIdLabel=PC_Constants.EMPTY_STRING;
            relationshipToCardholderLabel=PC_Constants.EMPTY_STRING;
        }

        global HealthPlanLabel(Boolean getFieldLabels){
            if(getFieldLabels){
                payerNameLabel=PC_Health_Plan__c.PC_Payer_Name__c.getDescribe().getLabel();
                planNameLabel=PC_Health_Plan__c.PC_Plan_Name__c.getDescribe().getLabel();
                memberIdLabel=Label.PC_Member_Id;
                relationshipToCardholderLabel=PC_Health_Plan__c.PC_Cardholder_Relationship_to_Patient__c.getDescribe().getLabel();
            }
        }
    }

    /**
    * Provides properties to hold Clinic details
    */
    global inherited sharing class Clinic{
        /**
        * Property to hold Clinic Id
        */
        @AuraEnabled global Id clinicId;
        /**
        * Property to hold placeOfService
        */
        @AuraEnabled global String placeOfService;
        /**
       * Property to hold Clinic Name
       */
        @AuraEnabled global String name;
        /**
        * Property to hold Clinic NPI field value
        */
        @AuraEnabled global String npi;
        global Clinic(){
            name=PC_Constants.EMPTY_STRING;
            npi=PC_Constants.EMPTY_STRING;
        }
    }

    /**
    * Provides properties to hold Clinic labels
    */
    global inherited sharing class ClinicLabels{
        /**
        * Property to hold label of Clinic
        */
        @AuraEnabled global String clinicLabel;
        /**
        * Property to hold label of Clinic NPI
        */
        @AuraEnabled global String clinicNpiLabel;

        global ClinicLabels(){
            clinicLabel=Label.PC_Clinic;
            clinicNpiLabel=Label.PC_Clinic_NPI;
        }
    }

    /**
    * Provides properties to hold key value pairs
    */
    global inherited sharing class keyValue{
        /**
        * Property to hold key
        */
        @AuraEnabled global String label;
        /**
        * Property to hold value
        */
        @AuraEnabled global String value;

        global keyValue(){
            label=PC_Constants.EMPTY_STRING;
            value=PC_Constants.EMPTY_STRING;
        }
    }
}