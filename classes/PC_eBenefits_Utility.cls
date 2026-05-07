/**
 * Created by sahgarg on 5/4/2018.
 * ***************************************************
 * Modification Log:
 * Shishir Bansal                           [PC-3152]  Capture PBM name in text field on Health Plan Record
 * Vijay Kashikar       04 Jul, 2018        [PC-3151]  New health plan will be updated with PC_Created_By_Lookup_Service__c set to true
 * Shishir Bansal       09 Sep,2018         [PC-3628]  adding externalPharmacy parameter to check the pharmacy selected is coming from UBC or Salesforce
 * Vijay Kashikar       20 Sep,2018         [PC-3777]  Added eBenefitsException class and new method getPharmaciesBy_NPI_OR_NCPDP
 * Vijay Kashikar       24 Sep, 2018        [PC-3580] PBM plans are now filtered based on the duration of validity of pharmacy card lookup and if created using the service.
 * Vijay Kashikar       25 Sep, 2018        [PC-3629] Added new method to convert json date to datetime i.e parseDatetimeFromJSON()
 * Shishir Bansal       28 Sep, 2018        [PC-3629] Added new method to return pharmacyCardLookup time-window datetime as per the custom setting
 * Shishir Bansal       28 Sep,2018         [PC-3629] Added logic to filter PBM Plans that are out of time
 * Shishir Bansal       26 Mar,2019         [PC-4579] Added method to create request data from the values selected by the user on the UI
 *                                                    and saving the data in salesforce as Program Coverage of Medical Coverage type along
 *                                                    with Coverage Benefits and Coverage Benefit items
 * Vijay Kashikar       30 Apr, 2019        [PC-4720] Corrected the mapping of Family In Network Deductible amount between wrapper response and sObject.
 * Vijay Kashikar       18 Apr, 2022        [PC-8419] PA Required values is set to 'Yes' if isPARequired is true in the service response.
 *
 *
 */

public with sharing class PC_eBenefits_Utility {

    public class eBenefitsException extends Exception {

    }
    public static final String RETAIL_PHARMACYTYPE_LABEL = 'RetailPharmacy';
    public static final String MAILORDER_PHARMACYTYPE_LABEL = 'MailOrderPharmacy';
    public static final String LONGTERMCARE_PHARMACYTYPE_LABEL = 'LongTermCare';
    public static final String SPECIALTY_PHARMACYTYPE_LABEL = 'SpecialtyPharmacy';



    public static String getMissingAccountMessageEBV() {
        String lblString = Label.PC_PharmaCardLookup_Missing_Account;

        return lblString;

    }

    public static String getMissingCaseAccountInfoMessageEBV() {
        String lblString = Label.PC_PharmaCardLookup_Missing_PatientInfo;

        return lblString;
    }

    public static String getMissingCasePhysicianInfoMessageEBV() {
        String lblString = Label.PC_PharmaCardLookup_Missing_PhysicianInfo;

        return lblString;
    }

    public static List<Account> getPharmaciesBy_NPI_OR_NCPDP(String npi, String ncpdp) {
        Set<Account> accounts = new Set<Account>();
        List<Account> lstAccounts = new List<Account>();
        if(String.isNotBlank(npi) && String.isNotBlank(ncpdp))
        {
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_NPI__c'),PC_Constants.getQualifiedAPIName('PC_NCPDP__c')};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
            String recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_ACCOUNT, PC_Constants.PHARMACY_RECORD_TYPE);
            List<Account> pharmacies = [SELECT ID FROM Account WHERE RecordTypeId =: recordTypeId AND (PC_NPI__c = :npi OR PC_NCPDP__c = :ncpdp)];
            if(pharmacies != null && !pharmacies.isEmpty()) {
                accounts.addAll(pharmacies);
            }
            lstAccounts.addAll(accounts);
            return lstAccounts;
        }

        if(String.isNotBlank(npi))
        {
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_NPI__c')};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
            String recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_ACCOUNT, PC_Constants.PHARMACY_RECORD_TYPE);
            List<Account> pharmacies = [SELECT ID FROM Account WHERE RecordTypeId =: recordTypeId AND PC_NPI__c = :npi];
            if(pharmacies != null && !pharmacies.isEmpty()) {
                accounts.addAll(pharmacies);
            }
        }

        if(String.isNotBlank(ncpdp)) {
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_NCPDP__c')};
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
            String recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_ACCOUNT, PC_Constants.PHARMACY_RECORD_TYPE);
            List<Account> pharmacies = [SELECT ID FROM Account WHERE RecordTypeId =: recordTypeId AND PC_NCPDP__c = :ncpdp];
            if(pharmacies != null && !pharmacies.isEmpty()) {
                accounts.addAll(pharmacies);
            }
        }
        lstAccounts.addAll(accounts);
        return lstAccounts;
    }

   /* public static String getMissingCaseProductInfoMessageEBV() {
        String lblString = Label.PC_Ebenefits_Mandatory_ProductInfo;

        return lblString;
    }*/

    public static String parseDateToJSONDate(String dateString) {
        Date d = Date.parse(dateString);
        Datetime dt = Datetime.newInstance(d.year(), d.month(), d.day());

        String jsonDateString = dt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');

        return jsonDateString;
    }
    public static String parseDateToJSONDate(Date pDt) {
        if(pDt == null) {
            return  null;
        }
        else {
            Date d = pDt;
            Datetime dt = Datetime.newInstance(d.year(), d.month(), d.day());

            String jsonDateString = dt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');

            return jsonDateString;
        }
    }
    public static Datetime parseDatetimeFromJSON(String jsonDateTime) {
        // DateTime.parse() function does not work for json format datetime and hence this workaround.
        // Example of correct json format is 2018-05-07T05:23:52.7362363Z
        try {
            String JSONContent = '{"transactionDate":"' + jsonDateTime + '"}';
            JSONParser parser = JSON.createParser(JSONContent);
            // Advance to the start object marker.
            parser.nextToken();
            // Advance to the next value.
            parser.nextValue();
            // Get the transaction date.
            Datetime transactionDate = parser.getDatetimeValue();
            return transactionDate;
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    public static Datetime getCardLookupRequestDateThreshold(){
        Datetime createdAfter;

            Integer cardLookupValidityInSeconds = PC_eBenefits.getValidityOfPharmacyCardLookupId();
            if (cardLookupValidityInSeconds != null) {
                if (cardLookupValidityInSeconds < 0) {
                    // Following exception is for administrative purposes and hence not put into a custom label.
                    String exMessage = '\'Pharmacy Card Lookup Validity In Seconds\' cannot be negative. Please correct the value in system settings.';
                    AuraHandledException ex = new AuraHandledException(exMessage);
                    PC_Utility.logAndThrowException(ex, exMessage);
                } else {
                    createdAfter = Datetime.now();
                    createdAfter = createdAfter.addSeconds(-1 * cardLookupValidityInSeconds);
                }
            }


        return createdAfter;



        }



    public static string getHandlerClass(String serviceType) {
        //Todo make use of payername as one of the filters
        List<PC_eBenefits_Service_Configuration__mdt> config = [SELECT Id, DeveloperName, MasterLabel, Language,
                Label, QualifiedApiName,
                PC_Service_Type__c, PC_Class_Name__c
        FROM PC_eBenefits_Service_Configuration__mdt
        WHERE PC_Service_Type__c =: serviceType];
        if(config == null || config.isEmpty()) {
            return null;
        }
        else if(config.size() == 0){

            return config[0].PC_Class_Name__c;
        }
        else {
            // todo throw exception? since size is greater than 1
            return config[0].PC_Class_Name__c;
        }
    }

    public static void updatePharmacyCardRequest(String caseId, PC_eBenefits.PharmacyCardRequest cardHolderInfo) {

        try {
            system.debug('here in getPatientInfo');
            //PC_eBenefits.PharmacyCardRequest cardHolderInfo = new PC_eBenefits.PharmacyCardRequest();
            system.debug('here in getPatientInfo');
            List<String> fields = new List<String>();
            fields.add('Id');
            fields.add('Account.Name');
            fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c'));
            fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_Gender__c'));
            fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_First_Name__c'));
            fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_Last_Name__c'));
            fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + PC_Constants.ID_PARAM);
            fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + PC_Constants.getQualifiedAPIName('PC_First_Name__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Last_Name__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + 'Name');
            fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + PC_Constants.getQualifiedAPIName('PC_NPI__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Program_Product__r') + '.' + 'Id');
            fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Product__c'));
            PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, fields);
            Case currentCase = [Select Id,
                    AccountId, Account.Name, Account.PC_Date_of_Birth__c, Account.PC_Gender__c,
                    Account.PC_First_Name__c, Account.PC_Last_Name__c,
                    Account.PC_Primary_Zip_Code__c,Account.PC_Primary_City__c,Account.PC_Primary_State__c,
                    PC_Physician__r.Id, PC_Physician__r.PC_First_Name__c, PC_Physician__r.PC_Last_Name__c,
                    PC_Physician__r.Name, PC_Physician__r.PC_NPI__c, PC_Physician__r.PC_Primary_Zip_Code__c,
                    PC_Physician__r.PC_Primary_City__c,PC_Physician__r.PC_Primary_State__c,
                    PC_Program_Product__r.Id, PC_Program_Product__r.PC_Product__c
            from Case where id=:caseId];

            if(currentCase != null) {

                //PC_eBenefits.Patient patient = new PC_eBenefits.Patient();
                PC_eBenefits.Patient patient = cardHolderInfo.patient;
                if(String.isNotBlank(currentCase.AccountId)
                        && currentCase.Account!=null
                        && String.isNotBlank(currentCase.Account.PC_First_Name__c)
                        && String.isNotBlank(currentCase.Account.PC_Last_Name__c)
                        && String.isNotBlank(currentCase.Account.PC_Gender__c)
                        && currentCase.Account.PC_Date_of_Birth__c!=null
                        && String.isNotBlank(currentCase.Account.PC_Primary_Zip_Code__c)
                        && String.isNotBlank(currentCase.Account.PC_Primary_City__c)
                        && String.isNotBlank(currentCase.Account.PC_Primary_State__c)
                        ) {
                    Account.Type.getDescribe().getLabel();

                    patient.FirstName = currentCase.Account.PC_First_Name__c;
                    patient.LastName = currentCase.Account.PC_Last_Name__c;
                    //patient.Birthdate = currentCase.Account.PC_Date_of_Birth__c != null ? (currentCase.Account.PC_Date_of_Birth__c).format() : null;
                    patient.birthdate = PC_eBenefits_Utility.parseDateToJSONDate(currentCase.Account.PC_Date_of_Birth__c);
                    patient.dob = currentCase.Account.PC_Date_of_Birth__c;
                    PC_eBenefits.Address primaryAddr =  cardHolderInfo.patient.address; //new PC_eBenefits.Address();
                    primaryAddr.postalCode = currentCase.Account.PC_Primary_Zip_Code__c;
                    primaryAddr.city = currentCase.Account.PC_Primary_City__c;
                    primaryAddr.state = currentCase.Account.PC_Primary_State__c;
                    patient.Address = primaryAddr;
                    patient.Gender = currentCase.Account.PC_Gender__c;


                    patient.nameLabel = Account.Name.getDescribe().getLabel();
                    patient.genderLabel = Account.PC_Gender__c.getDescribe().getLabel();
                    patient.birthdateLabel = Account.PC_Date_of_Birth__c.getDescribe().getLabel();
                    primaryAddr.postalCodeLabel = PC_Address__c.PC_Zip_Code__c.getDescribe().getLabel();
                    primaryAddr.cityLabel = PC_Address__c.PC_City__c.getDescribe().getLabel();
                    primaryAddr.stateLabel = PC_Address__c.PC_State__c.getDescribe().getLabel();
                }
                else {
                    String exceptionMessage = PC_eBenefits_Utility.getMissingCaseAccountInfoMessageEBV();
                    PC_Utility.throwAuraHandledException(exceptionMessage);
                }

                cardHolderInfo.patient = patient;

                system.debug(cardHolderInfo.patient);

                PC_eBenefits.Physician physician = cardHolderInfo.physician;// new PC_eBenefits.Physician();
                if(String.isNotBlank(currentCase.PC_Physician__r.Id)
                        && currentCase.PC_Physician__c!=null
                        && String.isNotBlank(currentCase.PC_Physician__r.PC_NPI__c)
                        && String.isNotBlank(currentCase.PC_Physician__r.PC_First_Name__c)
                        && String.isNotBlank(currentCase.PC_Physician__r.PC_Primary_Zip_Code__c)
                        && String.isNotBlank(currentCase.PC_Physician__r.PC_Primary_City__c)
                        && String.isNotBlank(currentCase.PC_Physician__r.PC_Primary_State__c)
                        ) {
                    //physician.Id = currentCase.PC_Physician__r.Id;
                    physician.NPI = currentCase.PC_Physician__r.PC_NPI__c;
                    physician.FirstName = currentCase.PC_Physician__r.PC_First_Name__c;
                    physician.LastName = currentCase.PC_Physician__r.PC_Last_Name__c;

                    physician.nameLabel = Case.PC_Physician__c.getDescribe().getLabel();
                    physician.npiLabel = Account.PC_NPI__c.getDescribe().getLabel();

                    PC_eBenefits.Address primaryAddr = cardHolderInfo.physician.address; //new PC_eBenefits.Address();
                    primaryAddr.postalCode = currentCase.PC_Physician__r.PC_Primary_Zip_Code__c;
                    primaryAddr.city = currentCase.PC_Physician__r.PC_Primary_City__c;
                    primaryAddr.state = currentCase.PC_Physician__r.PC_Primary_State__c;

                    primaryAddr.postalCodeLabel = PC_Address__c.PC_Zip_Code__c.getDescribe().getLabel();
                    primaryAddr.cityLabel = PC_Address__c.PC_City__c.getDescribe().getLabel();
                    primaryAddr.stateLabel = PC_Address__c.PC_State__c.getDescribe().getLabel();
                    physician.Address = primaryAddr;
                }
                else {
                    String exceptionMessage = PC_eBenefits_Utility.getMissingCasePhysicianInfoMessageEBV();
                    PC_Utility.throwAuraHandledException(exceptionMessage);
                }

                cardHolderInfo.physician = physician;

                system.debug(cardHolderInfo.physician);

                system.debug(cardHolderInfo);
            }

        }
        catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
    }

     public static boolean isExternalPharmacy(String id) {
        if(String.isBlank(id)) {
            system.debug('pharmacy does not exist in the system.');
            return true;
        }

        String pharmacyId = getPharmacyIdBy_Id_Or_ExtId(id);

        if(String.isBlank(pharmacyId)){
            system.debug('pharmacy does not exist in the system.');
            return true;
        }
        else{
            system.debug('pharmacy exists in the system');
            return false;
        }

    }
    public static String getPharmacyIdBy_Id_Or_ExtId(String id) {
        List<Account> internalAccounts = [SELECT Id
        FROM Account
        WHERE Id =:id LIMIT 1];
        String sid = null;
        if(internalAccounts != null && !internalAccounts.isEmpty()) {
            sid = internalAccounts[0].Id;
            system.debug('Internal pharmacy id => ' + sid);
            return sid;
        }
        else {
            List<Account> externalAccounts = [SELECT Id
            FROM Account
            WHERE PC_External_ID__c =:id LIMIT 1];
            if(externalAccounts != null && !externalAccounts.isEmpty()) {
                sid = externalAccounts[0].Id;
                system.debug('External pharmacy id => ' + sid);
                return sid;
            }
        }
        return sid;
    }
    public static void updatePharmacyRequest(String caseId,
            String healthPlanId, String prescriptionId, String pharmacyId,Boolean isExternalPharmacy,
            Decimal daysSupply, Decimal requestedQuantity, Integer index, PC_eBenefits.PharmacyBenefitsRequest pharmacyRequest)
    {
        //PC_eBenefits.PharmacyBenefitsRequest pharmacyRequest = new PC_eBenefits.PharmacyBenefitsRequest();
        system.debug(daysSupply);
        system.debug(requestedQuantity);


        List<String> fields = new List<String>();
        fields.add('Id');
        fields.add('Account.Name');
        fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c'));
        fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_Gender__c'));
        fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_First_Name__c'));
        fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_Last_Name__c'));
        fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'));
        fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'));
        fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'));
        fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + PC_Constants.ID_PARAM);
        fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' +
                                                     PC_Constants.getQualifiedAPIName('PC_First_Name__c'));
        fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' +
                                                     PC_Constants.getQualifiedAPIName('PC_Last_Name__c'));
        fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + 'Name');
        fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' +
                                                    PC_Constants.getQualifiedAPIName('PC_NPI__c'));
        fields.add(PC_Constants.getQualifiedAPIName('PC_Program_Product__r') + '.' + 'Id');
        fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' +
                                                     PC_Constants.getQualifiedAPIName('PC_Product__c'));
        PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, fields);

        Case currentCase = [Select Id,
                Account.Name, Account.PC_Date_of_Birth__c, Account.PC_Gender__c,
                Account.PC_First_Name__c, Account.PC_Last_Name__c,
                Account.PC_Primary_City__c, Account.PC_Primary_State__c, Account.PC_Primary_Zip_Code__c,
                PC_Physician__r.Id, PC_Physician__r.PC_First_Name__c, PC_Physician__r.PC_Last_Name__c,
                PC_Physician__r.Name, PC_Physician__r.PC_NPI__c,
                PC_Program_Product__r.Id, PC_Program_Product__r.PC_Product__c ,
                PC_Engagement_Program__c
        From Case where id=:caseId];

        //String productId = currentCase.PC_Program_Product__r.PC_Product__c;
        String productId;
        system.debug('prescriptoin = ' + prescriptionId);
        PC_Prescription__c[] prescriptions = [SELECT ID, PC_Product__c FROM PC_Prescription__c
                                                                     WHERE ID =:prescriptionId];
        if(prescriptions != null && !prescriptions.isEmpty() && prescriptions.size() == 1) {
            productId = prescriptions[0].PC_Product__c;
        }

        PC_eBenefits.Patient patient = pharmacyRequest.patient;


        patient.firstName = currentCase.Account.PC_First_Name__c;
        patient.lastName = currentCase.Account.PC_Last_Name__c;
        //patient.birthdate = String.valueOf(currentCase.Account.PC_Date_of_Birth__c);
        patient.birthdate = PC_eBenefits_Utility.parseDateToJSONDate(currentCase.Account.PC_Date_of_Birth__c);
        patient.dob = currentCase.Account.PC_Date_of_Birth__c;
        patient.gender = currentCase.Account.PC_Gender__c;

        PC_eBenefits.Address  address = pharmacyRequest.patient.address;

        address.city = currentCase.Account.PC_Primary_City__c;
        address.state = currentCase.Account.PC_Primary_State__c;
        address.postalCode = currentCase.Account.PC_Primary_Zip_Code__c;
        patient.address = address;

        pharmacyRequest.patient = patient;


        List<String> accountFields = new List<String>();



        PC_eBenefits.Prescription prescription = pharmacyRequest.prescription;

        //Account selectedPharmacy = [SELECT ID, NAME, PC_NPI__c, PC_Mail_Only__c, PC_External_ID__c FROM Account where id =:pharmacyId];
        //List<Account> selectedPharmacies = [SELECT ID, NAME, PC_NPI__c, PC_Mail_Only__c, PC_External_ID__c FROM Account where id =:pharmacyId OR PC_External_ID__c =:pharmacyId];

        // removing external Id or part in SOQL and adding zip code in soql query too
        List<Account> selectedPharmacies =  new List<Account>();
        PC_eBenefits.Pharmacy pharmacy = new PC_eBenefits.Pharmacy();
        Account selectedPharmacy;

        if(!isExternalPharmacy) {
            accountFields.add('Id');
            accountFields.add('Name');
            accountFields.add(PC_Constants.getQualifiedAPIName('PC_NPI__c'));
            accountFields.add(PC_Constants.getQualifiedAPIName('PC_Mail_Only__c'));
            accountFields.add(PC_Constants.getQualifiedAPIName('PC_NCPDP__c'));
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, accountFields);
            selectedPharmacies = [SELECT ID, NAME, PC_NPI__c, PC_Mail_Only__c,PC_Primary_Zip_Code__c,PC_NCPDP__c, PC_External_ID__c FROM Account where id = :pharmacyId];

        }

        if(selectedPharmacies != null && !selectedPharmacies.isEmpty()) {
            selectedPharmacy = selectedPharmacies[0];
            prescription.includeHomeDelivery = selectedPharmacy.PC_Mail_Only__c;
            pharmacy.npi = selectedPharmacy.PC_NPI__c;
            pharmacy.extId = selectedPharmacy.PC_External_ID__c;
            pharmacy.zipCode = selectedPharmacy.PC_Primary_Zip_Code__c;
            pharmacy.ncpdp = selectedPharmacy.PC_NCPDP__c ;
        }
        else{
            pharmacy.extId = pharmacyId;
        }

        pharmacyRequest.Pharmacy = pharmacy;

        prescription.include90DaysRetail = true;
        prescription.daysSupply = daysSupply;
        prescription.requestedQuantity = requestedQuantity;


        pharmacyRequest.prescription = prescription;

        PC_eBenefits.Product productInput = pharmacyRequest.drug;
        if(String.isNotBlank(productId)) {

            List<String> product2Fields = new List<String>();
            product2Fields.add('Id');
            product2Fields.add('Name');
            product2Fields.add('ProductCode');
            product2Fields.add(PC_Constants.getQualifiedAPIName('PC_NDC__c'));
            product2Fields.add(PC_Constants.getQualifiedAPIName('PC_Unit_of_Measure_Code__c'));
            PC_Database.assertAccess('Product2', PC_Database.Operation.Reading, product2Fields);

            Product2 product = [Select id, ProductCode, Name, PC_NDC__c, PC_Unit_of_Measure_Code__c
                                       FROM Product2 where id= :productId];
            productInput.name = product.Name;
            productInput.ndc = product.PC_NDC__c;
            productInput.unitOfMeasureCode = product.PC_Unit_of_Measure_Code__c;

            prescription.unitOfMeasureCode = product.PC_Unit_of_Measure_Code__c;
        }
        pharmacyRequest.drug = productInput;

        List<String> healthPlanFields = new List<String>();
        healthPlanFields.add('Id');
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('ID_Policy_No__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_PBMMember_Id__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('Group_No__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Group_name__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Pharmacy_Card_Lookup_ID__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Pharmacy_Card_Lookup_Request_Time__c'));
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Health_Plan__c'),
                                 PC_Database.Operation.Reading, healthPlanFields);

        PC_Health_Plan__c currentHealthPlan = [Select id, ID_Policy_No__c,
                PC_PBMMember_Id__c, Group_No__c, PC_Group_name__c, PC_Pharmacy_Card_Lookup_ID__c,
                PC_Pharmacy_Card_Lookup_Request_Time__c
        FROM PC_Health_Plan__c where id =:healthPlanId];

        Id physicianId = getPrescriptionPhysicianId(prescriptionId);

        pharmacyRequest.cardHolder = getCardHolderInfo_helper(healthPlanId);
        pharmacyRequest.physician = getPhysicianInfo_helper(physicianId);
        PC_eBenefits.Card card = pharmacyRequest.card;
        card.GroupId = currentHealthPlan.Group_No__c;
        card.PbmMemberId = currentHealthPlan.PC_PBMMember_Id__c;
        card.MemberId = currentHealthPlan.ID_Policy_No__c;
        card.pharmacyCardLookupID =currentHealthPlan.PC_Pharmacy_Card_Lookup_ID__c;
        card.pharmacyCardLookupRequestTime = currentHealthPlan.PC_Pharmacy_Card_Lookup_Request_Time__c;
        pharmacyRequest.card = card;

    }

    public static Id getPrescriptionPhysicianId(Id prescriptionId) {
        PC_Prescription__c prescription = [SELECT Id, PC_Physician_Account__c FROM PC_Prescription__c WHERE Id=:prescriptionId];
        if(prescription != null) {
            return prescription.PC_Physician_Account__c;
        }
        return null;
    }


    public static void updatePharmacyHealthPlan(PC_Health_Plan__c healthPlan, PC_eBenefits.PharmacyCardResponse response) {
        healthPlan.PC_Has_Mail_Coverage__c = response.mailCoverage;
        healthPlan.PC_Has_Retail_Coverage__c = response.retailCoverage;
        healthPlan.PC_Has_LTC_Coverage__c = response.longTermCareCoverage;
        healthPlan.PC_Has_Specialty_Coverage__c = response.specialtyCoverage;
        healthPlan.PC_Pharmacy_Card_Lookup_ID__c = response.extId;
        healthPlan.PC_Pharmacy_Card_Lookup_Request_Time__c = response.requestDate;
        healthPlan.PC_Plan_Status__c = PC_Constants.ACTIVE;
        healthPlan.ID_Policy_No__c = response.policyID;
        healthPlan.PC_Rx_Bin__c = response.bin;
        healthPlan.PC_Rx_PCN__c = response.pcn;
        healthPlan.PC_Group_name__c = response.insuranceGroupName;
        healthPlan.Group_No__c = response.insuranceGroupId;
        healthPlan.PC_Plan_Type__c = PC_Constants.HEALTH_PLAN_TYPE_PRIMARY;
        healthPlan.PC_Cardholder_Relationship_to_Patient__c = response.subscriber.cardHolderRelationship;
        healthPlan.PC_Created_By_Lookup_Service__c = true;
        healthPlan.PC_PBM_Name_as_per_Card_Lookup_Service__c = response.planName; //  To store the PBM Plan  on health Plan record


        setCardHolderFields(healthPlan,response);

        String recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PHARMACY_PLAN_RECORD_TYPE);
        healthPlan.RecordTypeId = recordTypeId;

    }

    public static void  setCardHolderFields(PC_Health_Plan__c healthPlan, PC_eBenefits.PharmacyCardResponse response) {
        try {
            if(response != null && response.subscriber != null){
                if(String.isNotEmpty(response.subscriber.firstName)||String.isNotEmpty(response.subscriber.lastName)){



                    if(null!=response.subscriber.firstName) {
                        healthPlan.PC_Card_Holder_First_Name__c = response.subscriber.firstName;
                    }
                    if(null!=response.subscriber.lastName) {
                        healthPlan.PC_Card_Holder_Last_Name__c = response.subscriber.lastName;
                    }
                    if(null!=response.subscriber.gender) {
                        healthPlan.PC_Card_Holder_Gender__c = response.subscriber.gender;
                    }


                }

                if(String.isNotEmpty(response.subscriber.birthdate)) {
                    healthPlan.PC_Cardholder_s_Date_of_Birth__c = response.subscriber.dob;
                }
                if(response.subscriber.address!=null) {
                    if (String.isNotEmpty(response.subscriber.address.city)) {
                        healthPlan.PC_Card_Holder_City__c = response.subscriber.address.city ;
                    }
                    if (String.isNotEmpty(response.subscriber.address.state)){
                        healthPlan.PC_Card_Holder_State__c = response.subscriber.address.state ;
                    }
                    if (String.isNotEmpty(response.subscriber.address.postalCode)) {
                        healthPlan.PC_Card_Holder_ZipCode__c = response.subscriber.address.postalCode ;
                    }
                }

            }
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }

    }

    public static void updatePharmacyProgramCoverage(PC_Program_Coverage__c programCoverage, PC_eBenefits.PharmacyBenefitsResponse coverageDetails) {
        //Decimal ooPocketApplied = coverageDetails.eBenefitsServiceResponse.accumulators.outOfPocket.individual.applied;
        if(coverageDetails.eBenefitsServiceResponse != null &&
                coverageDetails.eBenefitsServiceResponse.accumulators != null &&
                coverageDetails.eBenefitsServiceResponse.accumulators.outOfPocket != null &&
                coverageDetails.eBenefitsServiceResponse.accumulators.outOfPocket.individual != null
                ) {
            Decimal ooPocketApplied = coverageDetails.eBenefitsServiceResponse.accumulators.outOfPocket.individual.applied;
            Decimal ooPocketTotal = ooPocketApplied;// + ooPocketRemaining;
            programCoverage.PC_Annual_Out_of_Pocket__c =  ooPocketTotal;
        }
        String recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE, PC_Constants.PROGRAM_COVERAGE_PHARMACY_PLAN_RECORD_TYPE);
        programCoverage.RecordTypeId = recordTypeId;
        programCoverage.PC_Coverage_Type__c = 'Pharmacy Plan Coverage';
        programCoverage.PC_Coverage_Status__c = PC_Constants.ACTIVE;
        String paRequired = '';
        if(coverageDetails != null
                && coverageDetails.eBenefitsServiceResponse != null
                && coverageDetails.eBenefitsServiceResponse.priorAuthorization != null &&
                coverageDetails.eBenefitsServiceResponse.priorAuthorization.isRequired == true) {
            programCoverage.PA_Required__c = 'Yes';
        }
    }



    public static PC_eBenefits.PharmacyBenefitsOptions getPharmacyBenefitsOptions(String caseId) {
        PC_eBenefits.PharmacyBenefitsOptions ebv = new PC_eBenefits.PharmacyBenefitsOptions();
        try {
            List<String> fields = new List<String>();
            fields.add('Id');
            fields.add('AccountId');
            PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, fields);

            Case currentCase = [Select Id, AccountId from Case where id=:caseId];
            String accountId ;
            if(currentCase != null) {
                accountId = currentCase.AccountId;
            }
            List<PC_eBenefits.BaseSobject> sObjectHps = new List<PC_eBenefits.BaseSobject>();
            if(String.isNotBlank(accountId)) {
                Datetime createdAfter = PC_eBenefits_Utility.getCardLookupRequestDateThreshold() ;

                String recordTypeId;
                List<String> healthPlanStatus = new List<String>();
                healthPlanStatus.add(PC_Constants.INACTIVE);
                healthPlanStatus.add('');
                recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PHARMACY_PLAN_RECORD_TYPE);

                List<String> healthPlanFields = new List<String>();
                healthPlanFields.add('Id');
                healthPlanFields.add('Name');
                healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Group_name__c'));
                healthPlanFields.add(PC_Constants.getQualifiedAPIName('Patient__c'));
                healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_PBM_Name__c'));
                healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Pharmacy_Card_Lookup_Request_Time__c'));
                PC_Database.assertAccess(PC_Constants.PC_HEALTH_PLAN, PC_Database.Operation.Reading, healthPlanFields);

                List<PC_Health_Plan__c> healthPlans;
                if(createdAfter == null) {
                    healthPlans = [
                            Select Id, Name, PC_Group_name__c, PC_PBM_Name__c
                            FROM PC_Health_Plan__c
                            where Patient__c = :accountId and
                            RecordTypeId = :recordTypeId AND PC_Created_By_Lookup_Service__c = TRUE
                            AND PC_Plan_Status__c NOT IN :healthPlanStatus ORDER BY LastModifiedDate DESC];

                }
                else {
                    healthPlans = [
                            Select Id, Name, PC_Group_name__c, PC_PBM_Name__c
                            FROM PC_Health_Plan__c
                            where Patient__c = :accountId and
                            RecordTypeId = :recordTypeId AND PC_Created_By_Lookup_Service__c = TRUE
                            AND PC_Plan_Status__c NOT IN :healthPlanStatus
                            AND (PC_Pharmacy_Card_Lookup_Request_Time__c = NULL OR PC_Pharmacy_Card_Lookup_Request_Time__c >= :createdAfter)
                            ORDER BY LastModifiedDate DESC];
                }

                PC_eBenefits.BaseSobject sObjectHp;
                String healthPlanSuffix;
                String healthPlanPrefix;
                for(PC_Health_Plan__c hp : healthPlans) {
                    sObjectHp = new PC_eBenefits.BaseSobject();
                    sObjectHp.Id = hp.Id;
                    sObjectHp.Name = hp.Name;
                    //healthPlanSuffix = hp.PC_Group_name__c == null ? '' : ' : ' + hp.PC_Group_name__c;
                    healthPlanPrefix = hp.PC_PBM_Name__c == null ? '' : hp.PC_PBM_Name__c + ' : ';
                    sObjectHp.displayName = healthPlanPrefix + hp.Name;
                    sObjectHps.add(sObjectHp);
                }
            }
            ebv.healthPlans = sObjectHps;

            List<PC_eBenefits.BaseSobject> sObjectPharmacies = new List<PC_eBenefits.BaseSobject>();
            String pharmacyRecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_ACCOUNT, PC_Constants.PHARMACY_RECORD_TYPE);
            List<Account> accounts = new List<Account>();
            PC_eBenefits.BaseSobject sObjectPharmacy;

            List<String> pharmacyFields = new List<String>();
            pharmacyFields.add('Id');
            pharmacyFields.add('Name');
            pharmacyFields.add('ParentId');
            pharmacyFields.add(PC_Constants.getQualifiedAPIName('PC_NPI__c'));
            PC_Database.assertAccess('Account', PC_Database.Operation.Reading, pharmacyFields);

            String pharmacySuffix;
            List<Account> pharmacies = [Select ID, Name, PC_NPI__c from Account where RecordTypeId = :pharmacyRecordTypeId AND ParentId = NULL Limit 100 ];
            if(pharmacies != null && !pharmacies.isEmpty()) {
                pharmacies.sort();
            }
            for(Account acc : pharmacies){
                sObjectPharmacy = new PC_eBenefits.BaseSobject();
                sObjectPharmacy.Id = acc.Id;
                sObjectPharmacy.Name = acc.Name;
                pharmacySuffix = acc.PC_NPI__c == null ? '' : ' : ' + acc.PC_NPI__c;
                sObjectPharmacy.displayName = acc.Name + pharmacySuffix;
                sObjectPharmacies.add(sObjectPharmacy);
            }
            ebv.pharmacies = sObjectPharmacies;

            //ebv.pharmaCardInfo_JSON = PC_LookupPharmaCardController.getPharmacyCardholderInfo(caseId);
            ebv.cardHolder = getPharmacyCardholderInfo(caseId);

            Map<String, PC_eBenefits.Prescription> prescriptions = new Map<String, PC_eBenefits.Prescription>();
            PC_eBenefits.Prescription prescription;

            List<String> prescriptionFields = new List<String>();
            prescriptionFields.add('Id');
            prescriptionFields.add('Name');
            prescriptionFields.add(PC_Constants.getQualifiedAPIName('PC_Days_Supply__c'));
            prescriptionFields.add(PC_Constants.getQualifiedAPIName('PC_Requested_Quantity__c'));
            prescriptionFields.add(PC_Constants.getQualifiedAPIName('PC_Product__r') + '.' + 'Id');
            prescriptionFields.add(PC_Constants.getQualifiedAPIName('PC_Product__r') + '.' + 'Name');
            prescriptionFields.add(PC_Constants.getQualifiedAPIName('PC_Product__r') + '.' + 'PC_NDC__c');
            prescriptionFields.add(PC_Constants.getQualifiedAPIName('PC_Dosage__c'));
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Prescription__c'), PC_Database.Operation.Reading, prescriptionFields);

            for(PC_Prescription__c pres :[SELECT Id, Name,
                    PC_Days_Supply__c, PC_Requested_Quantity__c,
                    PC_Product__r.Id, PC_Product__r.Name, PC_Product__r.PC_NDC__c, PC_Dosage__c, PC_Product__r.PC_Unit_of_Measure_Code__c
            FROM PC_Prescription__c
            WHERE PC_Program_Case__c = :caseId  AND  PC_Rx_Status__c = true ORDER BY Name])
            {
                prescription = new PC_eBenefits.Prescription();
                prescription.id = pres.Id;
                prescription.name = pres.Name;
                prescription.requestedQuantity = pres.PC_Requested_Quantity__c;
                prescription.daysSupply = pres.PC_Days_Supply__c;
                prescription.dosage = pres.PC_Dosage__c;
                prescription.productId = pres.PC_Product__r.Id;
                prescription.productName = pres.PC_Product__r.Name;
                prescription.ndc = pres.PC_Product__r.PC_NDC__c;
                prescription.ndcLabel = Product2.PC_NDC__c.getDescribe().getLabel();
                prescription.unitOfMeasureCodeLabel = Product2.PC_Unit_of_Measure_Code__c.getDescribe().getLabel();
                prescription.unitOfMeasureCode = pres.PC_Product__r.PC_Unit_of_Measure_Code__c;
                prescriptions.put(pres.Id, prescription);
            }
            ebv.prescriptions = prescriptions;

        }
        catch (exception ex){
            system.debug('message '+ex.getMessage()+' line '+ex.getStackTraceString());
            PC_Utility.logAndThrowException(ex);
        }
        return ebv;
    }


    public static PC_eBenefits.Physician getPhysicianInfo_helper(Id physicianId) {
        try {
            List<String> fields = new List<String>();
            fields.add('Id');
            fields.add('Name');
            fields.add(PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_NPI__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Gender__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_First_Name__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Last_Name__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Primary_City__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Primary_State__c'));
            PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, fields);

            Account physicianAccount = getAccount(physicianId);

            PC_eBenefits.Physician physician = new PC_eBenefits.Physician();
            PC_eBenefits.Address physicianAddress = new PC_eBenefits.Address();
            physician.address = physicianAddress;
            physician.firstName = physicianAccount.PC_First_Name__c;
            physician.lastName = physicianAccount.PC_Last_Name__c;
            physician.birthdate = physicianAccount.PC_Date_of_Birth__c != null ?
                    physicianAccount.PC_Date_of_Birth__c.format() : '';
            physician.npi = physicianAccount.PC_NPI__c;
            physician.gender = physicianAccount.PC_Gender__c;
            physicianAddress.postalCode = physicianAccount.PC_Primary_Zip_Code__c;
            physicianAddress.state = physicianAccount.PC_Primary_State__c;
            physicianAddress.city = physicianAccount.PC_Primary_City__c;


            return physician;
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    // This method is usually used to get the account details to be passed for UBC.
    private static Account getAccount(String id) {
        Account acc = [SELECT ID, PC_First_Name__c, PC_Last_Name__c, PC_Date_of_Birth__c,
                PC_Gender__c, PC_Primary_City__c, PC_Primary_State__c,
                PC_Primary_Zip_Code__c, PC_NPI__c
        FROM Account
        WHERE ID=:id];
        return acc;

    }

    public static PC_eBenefits.Patient getCardHolderInfo_helper(Id healthPlanId) {
        try {
            PC_Health_Plan__c healthPlan;
            PC_eBenefits.Patient patient = new PC_eBenefits.Patient();

            //Check FLS/CRUD before SOQL

            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Has_Specialty_Coverage__c'),PC_Constants.getQualifiedAPIName('PC_Has_Retail_Coverage__c'),
                    PC_Constants.getQualifiedAPIName('PC_Has_Mail_Coverage__c'),
                    PC_Constants.getQualifiedAPIName('PC_Has_LTC_Coverage__c'),
                    PC_Constants.getQualifiedAPIName('PC_Card_Holder_First_Name__c'), PC_Constants.getQualifiedAPIName('PC_Card_Holder_Last_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Card_Holder_Gender__c'), PC_Constants.getQualifiedAPIName('PC_Cardholder_s_Date_of_Birth__c'),
                    PC_Constants.getQualifiedAPIName('PC_Card_Holder_City__c'), PC_Constants.getQualifiedAPIName('PC_Card_Holder_State__c'),
                    PC_Constants.getQualifiedAPIName('PC_Card_Holder_ZipCode__c'), PC_Constants.getQualifiedAPIName('PC_Created_By_Lookup_Service__c')};

            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Health_Plan__c'),PC_Database.Operation.Reading, fields);

            if(healthPlanId!=null) {
                healthPlan = [
                        Select Id, PC_Card_Holder_First_Name__c, PC_Card_Holder_Last_Name__c, PC_Card_Holder_Gender__c,
                                PC_Cardholder_s_Date_of_Birth__c,PC_Card_Holder_City__c, PC_Card_Holder_State__c, PC_Card_Holder_ZipCode__c,
                                PC_Has_LTC_Coverage__c, PC_Has_Mail_Coverage__c, PC_Has_Retail_Coverage__c, PC_Has_Specialty_Coverage__c, PC_Created_By_Lookup_Service__c
                        FROM PC_Health_Plan__c
                        where Id = :healthPlanId
                ];


                patient.firstName = healthPlan.PC_Card_Holder_First_Name__c;
                patient.lastName = healthPlan.PC_Card_Holder_Last_Name__c;
                //patient.birthdate = healthPlan.PC_Cardholder_s_Date_of_Birth__c == null ? null : healthPlan.PC_Cardholder_s_Date_of_Birth__c.format();
                patient.birthdate = PC_eBenefits_Utility.parseDateToJSONDate(healthPlan.PC_Cardholder_s_Date_of_Birth__c);
                patient.dob = healthPlan.PC_Cardholder_s_Date_of_Birth__c;
                patient.gender = healthPlan.PC_Card_Holder_Gender__c;
                PC_eBenefits.Address primaryAddr = new PC_eBenefits.Address();

                primaryaddr.city = healthPlan.PC_Card_Holder_City__c;
                primaryaddr.state = healthPlan.PC_Card_Holder_State__c;
                primaryaddr.postalCode = healthPlan.PC_Card_Holder_ZipCode__c;
                patient.nameLabel = Account.Name.getDescribe().getLabel();
                patient.genderLabel = Account.PC_Gender__c.getDescribe().getLabel();
                patient.birthdateLabel = Account.PC_Date_of_Birth__c.getDescribe().getLabel();
                primaryaddr.cityLabel = PC_Address__c.PC_City__c.getDescribe().getLabel();
                primaryaddr.stateLabel = PC_Address__c.PC_State__c.getDescribe().getLabel();
                primaryaddr.postalCodeLabel = PC_Address__c.PC_Zip_Code__c.getDescribe().getLabel();
                patient.address = primaryAddr;
                patient.coverageAlerts = new List<PC_eBenefits.coverageAlerts>();

                if(healthPlan.PC_Created_By_Lookup_Service__c == true) {

                    PC_eBenefits.coverageAlerts obj;

                    obj = new PC_eBenefits.coverageAlerts();
                    obj.name = PC_Health_Plan__c.PC_Has_Specialty_Coverage__c.getDescribe().getLabel();
                    obj.value = healthPlan.PC_Has_Specialty_Coverage__c;
                    obj.id = healthPlan.Id;
                    patient.coverageAlerts.add(obj);

                    obj = new PC_eBenefits.coverageAlerts();
                    obj.name = PC_Health_Plan__c.PC_Has_Retail_Coverage__c.getDescribe().getLabel();
                    obj.value = healthPlan.PC_Has_Retail_Coverage__c;
                    obj.id = healthPlan.Id;
                    patient.coverageAlerts.add(obj);


                    obj = new PC_eBenefits.coverageAlerts();
                    obj.name = PC_Health_Plan__c.PC_Has_Mail_Coverage__c.getDescribe().getLabel();
                    obj.value = healthPlan.PC_Has_Mail_Coverage__c;
                    obj.id = healthPlan.Id;
                    patient.coverageAlerts.add(obj);


                    obj = new PC_eBenefits.coverageAlerts();
                    obj.name = PC_Health_Plan__c.PC_Has_LTC_Coverage__c.getDescribe().getLabel();
                    obj.value = healthPlan.PC_Has_LTC_Coverage__c;
                    obj.id = healthPlan.Id;
                    patient.coverageAlerts.add(obj);
                }

            }

            return patient;
        }
        catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    public static PC_eBenefits.PharmacyCardRequest getPharmacyCardholderInfo(String caseId) {

        try {
            system.debug('here in getPatientInfo');
            PC_eBenefits.PharmacyCardRequest cardHolderInfo = new PC_eBenefits.PharmacyCardRequest();
            system.debug('here in getPatientInfo');

            List<String> fields = new List<String>();
            fields.add('Id');
            fields.add('Account.Name');
            fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c'));
            fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_Gender__c'));
            fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_First_Name__c'));
            fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_Last_Name__c'));
            fields.add(PC_Constants.PC_ACCOUNT + '.' + PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + 'ID');
            fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + PC_Constants.getQualifiedAPIName('PC_First_Name__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Last_Name__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + 'Name');
            fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + PC_Constants.getQualifiedAPIName('PC_NPI__c'));
            fields.add(PC_Constants.getQualifiedAPIName('PC_Program_Product__r') + '.' + 'Id');
            fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Product__c'));
            PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, fields);

            Case currentCase = [Select Id,
                    AccountId, Account.Name, Account.PC_Date_of_Birth__c, Account.PC_Gender__c,
                    Account.PC_First_Name__c, Account.PC_Last_Name__c,
                    Account.PC_Primary_Zip_Code__c, Account.PC_Primary_City__c,Account.PC_Primary_State__c,
                    PC_Physician__r.Id, PC_Physician__r.PC_First_Name__c, PC_Physician__r.PC_Last_Name__c,
                    PC_Physician__r.Name, PC_Physician__r.PC_NPI__c,
                    PC_Program_Product__r.Id, PC_Program_Product__r.PC_Product__c
            from Case where id=:caseId];

            if(currentCase != null) {
                system.debug('1');
                PC_eBenefits.Patient patient = new PC_eBenefits.Patient();
                if(String.isNotBlank(currentCase.AccountId)) {
                    Account.Type.getDescribe().getLabel();

                    patient.FirstName = currentCase.Account.PC_First_Name__c;
                    patient.LastName = currentCase.Account.PC_Last_Name__c;
                    //patient.Birthdate = currentCase.Account.PC_Date_of_Birth__c != null ? (currentCase.Account.PC_Date_of_Birth__c).format() : null;
                    patient.birthdate = PC_eBenefits_Utility.parseDateToJSONDate(currentCase.Account.PC_Date_of_Birth__c);
                    patient.dob = currentCase.Account.PC_Date_of_Birth__c;
                    PC_eBenefits.Address primaryAddr = new PC_eBenefits.Address();
                    primaryAddr.city = currentCase.Account.PC_Primary_City__c;
                    primaryAddr.state = currentCase.Account.PC_Primary_State__c;
                    primaryAddr.postalCode = currentCase.Account.PC_Primary_Zip_Code__c;

                    patient.Gender = currentCase.Account.PC_Gender__c;


                    patient.nameLabel = Account.Name.getDescribe().getLabel();
                    patient.genderLabel = Account.PC_Gender__c.getDescribe().getLabel();
                    patient.birthdateLabel = Account.PC_Date_of_Birth__c.getDescribe().getLabel();
                    primaryAddr.cityLabel = PC_Address__c.PC_City__c.getDescribe().getLabel();
                    primaryAddr.stateLabel = PC_Address__c.PC_State__c.getDescribe().getLabel();
                    primaryAddr.postalCodeLabel = PC_Address__c.PC_Zip_Code__c.getDescribe().getLabel();
                    patient.Address = primaryAddr;
                }

                cardHolderInfo.patient = patient;

                system.debug(cardHolderInfo.patient);

                system.debug(cardHolderInfo);
            }
            return cardHolderInfo;
        }
        catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return null;
    }

    /**
    * Updating the request object after fetching and validating data from ids
    */
    public static void updateMedicalBenefitRequest( Id caseId,Id primaryHealthPlanId, Id secondaryHealthPlanId,
            Id tertiaryHealthPlanId, Id prescriptionId, Id clinicId, Id patientId, List<String> adminCodes,
            PC_eBenefits.MedicalBenefitsRequest request ){


        if( primaryHealthPlanId != null){
            // fetching primaryHealthPlan details by passing id and mapping it to request object
            request.primaryHealthPlan = new PC_eBenefits.HealthPlan();
            request.primaryHealthPlan = getHealthPlanDetails(primaryHealthPlanId);

             validateHealthPlan( request.primaryHealthPlan);
        }

        if( secondaryHealthPlanId != null){
            //fetching secondaryHealthPlan details by passing id and mapping it to request object
            request.secondaryHealthPlan = new PC_eBenefits.HealthPlan();
            request.secondaryHealthPlan = getHealthPlanDetails(secondaryHealthPlanId);

            validateHealthPlan( request.secondaryHealthPlan);
        }


        if( tertiaryHealthPlanId != null){
            // fetching tertiaryHealthPlan details by passing id and mapping it to request object
            request.tertiaryHealthPlan=  new PC_eBenefits.HealthPlan();
            request.tertiaryHealthPlan = getHealthPlanDetails(tertiaryHealthPlanId);

            validateHealthPlan( request.tertiaryHealthPlan);
        }


        // fetching patient details by passing patientId and mapping it to request object
        request.patient = getPatientDetails(patientId);
        validatePatientDetails( request.patient);



        //fetching prescription details by passing prescription id and mapping it to request object
        request.prescription = getPrescriptionDetails(prescriptionId);
        validatePrescription(request.prescription);

        //fetching clinic details by passing clinic id  and mapping it to request object
        request.clinic =getClinicDetails(clinicId);
        validateClinic(request.clinic);

        //fetching cptCodes details by passing List<String> admin codes and mapping it to request object
        request.cptCodes.addAll(adminCodes);

        if(!adminCodes.isEmpty()) {

            request.cptCodeMap = new Map<String, String>(getcptCodeMapLabelVal(adminCodes));
        }
    }

    /**
    * Fetching health plan details after valdiation and conversion to request object form
    */
    private static PC_eBenefits.HealthPlan  getHealthPlanDetails(Id healtPlanId){


        PC_Health_Plan__c currentHealthPlan = getHealthPlan(healtPlanId);
        if(currentHealthPlan !=null) {

            /*Map<String,Object> accountIndentifier = new Map<String,Object>();
            List<String> fieldApiNames = new List<String>();
            fieldApiNames.add(PC_Constants.getQualifiedAPIName('PC_VMI_Id__c'));*/

            String accIdentifierList = null;

            if(currentHealthPlan.PC_Payer__c !=null) {
                accIdentifierList = PC_SYSTEM.getAccountIdentifier(currentHealthPlan.PC_Payer__c,
                                                        PC_Constants.ACCOUNT_IDENTIFIER_TYPE_PAYER_ID,
                                                         PC_Constants.ACCOUNT_IDENTIFIER_ASSIGNER_VMI);
            }


            PC_eBenefits.HealthPlan selectedHealthPlan = new PC_eBenefits.HealthPlan();
            selectedHealthPlan=convertHealthPlan(currentHealthPlan);

            if(!String.isEmpty(accIdentifierList)) {

                selectedHealthPlan.payerId = accIdentifierList;
            }


            return selectedHealthPlan;
        }
        return null;
    }

    /**
    * Fetching health plan details by passing health plan id param
    */
    private static PC_Health_Plan__c  getHealthPlan(Id healtPlanId) {

        if (healtPlanId != null) {
            /*
            * FLS Check for PC_Health_Plan__c
            */
            List<String> healthPlanFields = new List<String>{
                    PC_Constants.getQualifiedAPIName('Name'),
                    PC_Constants.getQualifiedAPIName('PC_Plan_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Payer__c'),
                    PC_Constants.getQualifiedAPIName('PC_Plan_Type__c'),
                    PC_Constants.getQualifiedAPIName('PC_Payer_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Cardholder_Relationship_to_Patient__c'),
                    PC_Constants.getQualifiedAPIName('ID_Policy_No__c'),
                    PC_Constants.getQualifiedAPIName('PC_PBMMember_Id__c'),
                    PC_Constants.getQualifiedAPIName('PC_Card_Holder_First_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Card_Holder_Last_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Cardholder_s_Date_of_Birth__c'),
                    PC_Constants.getQualifiedAPIName('PC_Card_Holder_Gender__c'),
                    PC_Constants.getQualifiedAPIName('PC_Plan_Status__c'),
                    PC_Constants.getQualifiedAPIName('PC_MedicareSupplementalPlanLetter__c')


            };

            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Health_Plan__c'),
                    PC_Database.Operation.Reading, healthPlanFields);

            Id medicalHealthPlanRecTypeId = (Id) PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN,
                    PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE);
            List<PC_Health_Plan__c> healthplan = new List<PC_Health_Plan__c>();
            healthplan = [
                    SELECT Id, PC_Plan_Name__c, PC_Payer__c, toLabel(PC_Plan_Type__c), Name,
                            PC_Payer_Name__c, toLabel(PC_Cardholder_Relationship_to_Patient__c),ID_Policy_No__c,
                            PC_PBMMember_Id__c, PC_Card_Holder_First_Name__c,PC_MedicareSupplementalPlanLetter__c,
                            PC_Card_Holder_Last_Name__c, PC_Cardholder_s_Date_of_Birth__c, PC_Card_Holder_Gender__c
                    FROM PC_Health_Plan__c
                    WHERE id = :healtPlanId AND
                    RecordTypeId = :medicalHealthPlanRecTypeId AND
                    PC_Plan_Status__c = :PC_Constants.ACTIVE
                    LIMIT 1
            ];
            return healthplan[0];
        }
        return null;
    }


    /**
    * Converting Health plan details into request HP form
    */
    public static PC_eBenefits.HealthPlan  convertHealthPlan(PC_Health_Plan__c currentHealthPlan){

        PC_eBenefits.HealthPlan selectedHealthPlan = new PC_eBenefits.HealthPlan();
        if(currentHealthPlan != null) {
            //PC_Health_Plan__c healthplanObj = healthplanList[0];
            selectedHealthPlan.Name = currentHealthPlan.Name;
            selectedHealthPlan.policyNumber = currentHealthPlan.ID_Policy_No__c;
            selectedHealthPlan.cardholderFirstName = currentHealthPlan.PC_Card_Holder_First_Name__c;
            selectedHealthPlan.cardholderLastName = currentHealthPlan.PC_Card_Holder_Last_Name__c;
            selectedHealthPlan.cardholderDoB =
                    currentHealthPlan.PC_Cardholder_s_Date_of_Birth__c;
            selectedHealthPlan.relationshipToCardholder = currentHealthPlan.PC_Cardholder_Relationship_to_Patient__c;
            selectedHealthPlan.cardholderGender = currentHealthPlan.PC_Card_Holder_Gender__c;
            selectedHealthPlan.memberId = currentHealthPlan.ID_Policy_No__c;
            selectedHealthPlan.payerName = currentHealthPlan.PC_Payer_Name__c;
            if(currentHealthPlan.PC_MedicareSupplementalPlanLetter__c !=null){
                selectedHealthPlan.medicareSupplementalPlanLetter =
                                                                currentHealthPlan.PC_MedicareSupplementalPlanLetter__c;

            }
            return selectedHealthPlan;
        }


        return null;
    }

    /**
    * Fetching Patient information after converting into request object and validation of mandatory fields
    */
    public static PC_eBenefits.Patient getPatientDetails(Id patientId) {
        if (patientId != null) {
            Account currentPatient = getPatient(patientId);
            PC_eBenefits.Patient selectedPatient = new PC_eBenefits.Patient();
            selectedPatient = convertPatient(currentPatient);
            return selectedPatient;
            }
        return null;
    }


    /**
    * Fetching patient details by passing patient Id
    */
    public static Account getPatient(Id patientId) {
        if (patientId != null) {
            /*
            * FLS Check for Patient account
            */
            List<String> patientFields = new List<String>{

                    PC_Constants.getQualifiedAPIName('PC_First_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Last_Name__c'),
                    PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c'),
                    PC_Constants.getQualifiedAPIName('PC_Gender__c'),
                    PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c')
            };
            PC_Database.assertAccess(
                    PC_Constants.getQualifiedAPIName('Account'), PC_Database.Operation.Reading,patientFields
            );

            List<Account> patientRecList = new List<Account>();
            /*patientRecList=[SELECT Id,PC_First_Name__c, PC_Last_Name__c,PC_Date_of_Birth__c, PC_Gender__c,
                    PC_Primary_Zip_Code__c ,(Select PC_Social_Security_Number__c From PC_Account_Indentifiers__r)
            FROM Account WHERE Id=: patientId Limit 1];*/
            patientRecList=[SELECT Id,PC_First_Name__c, PC_Last_Name__c,PC_Date_of_Birth__c, PC_Gender__c,
                    PC_Primary_Zip_Code__c
            FROM Account WHERE Id=: patientId Limit 1];




            return patientRecList[0];
        }
        return null;
    }

    /**
    * Fetching patient details in request form by passing patient account
    */
    public static PC_eBenefits.Patient convertPatient(Account currentPatient) {


        if(currentPatient != null) {

            PC_eBenefits.Patient selectedPatient = new PC_eBenefits.Patient();


            selectedPatient = new PC_eBenefits.Patient();
            selectedPatient.firstName = currentPatient.PC_First_Name__c;
            selectedPatient.lastName = currentPatient.PC_Last_Name__c;
            selectedPatient.dob = currentPatient.PC_Date_of_Birth__c;
            selectedPatient.gender = currentPatient.PC_Gender__c;
            selectedPatient.zipCode = currentPatient.PC_Primary_Zip_Code__c;
            /*if (currentPatient.PC_Account_Indentifiers__r[0].PC_Social_Security_Number__c != null) {
                selectedPatient.ssn = currentPatient.PC_Account_Indentifiers__r[0].PC_Social_Security_Number__c;
            }*/
            selectedPatient.id = currentPatient.Id;
            return selectedPatient;
        }

        return null;
    }

    /**
    * Fetching Prescription information after converting into request object and validation of mandatory fields
    */
    public static PC_eBenefits.Prescription getPrescriptionDetails(Id prescriptionId) {


        if (prescriptionId != null) {


            PC_Prescription__c currentPrescription = getPrescription(prescriptionId);

            PC_eBenefits.Prescription selectedPrescription = new PC_eBenefits.Prescription();
            selectedPrescription = convertPrescription(currentPrescription);
            return selectedPrescription;
        }
        return null;
    }


    /**
    * Fetching Prescription data by passing prescription id
    */
    public static PC_Prescription__c getPrescription(Id prescriptionId) {
        if (prescriptionId != null) {
            /*
            * FLS Check for Prescription
            */
            List<String> prescriptionFields = new List<String>{
                    PC_Constants.getQualifiedAPIName('PC_PlaceOfService__c'),
                    PC_Constants.getQualifiedAPIName('PC_PrimaryDiagnosis__c'),
                    PC_Constants.getQualifiedAPIName('PC_SecondaryDiagnosis__c'),
                    PC_Constants.getQualifiedAPIName('PC_Physician_Account__r') + '.' + 'Name',
                    PC_Constants.getQualifiedAPIName('PC_Physician_Account__r') + '.' +
                            PC_Constants.getQualifiedAPIName('PC_Primary_State__c'),
                    PC_Constants.getQualifiedAPIName('PC_Physician_Account__r') + '.' +
                            PC_Constants.getQualifiedAPIName('PC_Primary_Address__r') + '.' +
                            PC_Constants.getQualifiedAPIName('PC_State__c'),
                    PC_Constants.getQualifiedAPIName('PC_Physician_Account__r') + '.' +
                            PC_Constants.getQualifiedAPIName('PC_NPI__c'),
                    PC_Constants.getQualifiedAPIName('PC_Product__r') + '.' + 'Name',
                    PC_Constants.getQualifiedAPIName('PC_Product__r') + '.' +
                            PC_Constants.getQualifiedAPIName('PC_Manufacturer__r') + '.' + 'Name',
                    PC_Constants.getQualifiedAPIName('PC_Product__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Strength__c')
            };


            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Prescription__c'),
                    PC_Database.Operation.Reading, prescriptionFields);

            if (prescriptionId != null) {
                List<PC_Prescription__c> prescriptionList = new List<PC_Prescription__c>();
                prescriptionList = [
                        SELECT PC_PlaceOfService__c, PC_PrimaryDiagnosis__c,
                                PC_SecondaryDiagnosis__c, PC_Physician_Account__c,PC_Physician_Account__r.PC_First_Name__c,
                                PC_Physician_Account__r.PC_Last_Name__c, PC_Physician_Account__r.PC_NPI__c,
                                PC_Physician_Account__r.PC_Primary_Address__r.PC_State__c,
                                PC_Product__r.Name,PC_Product__r.PC_Strength__c, PC_Product__r.PC_Manufacturer__r.Name,
                                PC_Product__r.PC_NDC__c, PC_Product__r.PC_Unit_of_Measure_Code__c
                        From PC_Prescription__c
                        where Id = :prescriptionId
                        AND PC_Rx_Status__c = :PC_Constants.TRUE_BOOLEAN
                        LIMIT 1
                ];
                return prescriptionList[0];
            }

        }
        return null;
    }



    /**
    * Converting Prescription data into request form
    */
    public static PC_eBenefits.Prescription convertPrescription(PC_Prescription__c currentPrescription) {


        if(currentPrescription != null) {

            PC_eBenefits.Prescription selectedPrescription = new PC_eBenefits.Prescription();
            selectedPrescription.primaryDiagnosis = currentPrescription.PC_PrimaryDiagnosis__c;
            selectedPrescription.secondaryDiagnosis = currentPrescription.PC_SecondaryDiagnosis__c;
            selectedPrescription.placeOfService = currentPrescription.PC_PlaceOfService__c;
            PC_eBenefits.Address addressValue = new PC_eBenefits.Address();
            addressValue.state = currentPrescription.PC_Physician_Account__r.PC_Primary_Address__r.PC_State__c;
            selectedPrescription.physician = new PC_eBenefits.Physician();
            selectedPrescription.physician.address = addressValue;


            selectedPrescription.physician.firstName =
                    currentPrescription.PC_Physician_Account__r.PC_First_Name__c;
            selectedPrescription.physician.lastName = currentPrescription.PC_Physician_Account__r.PC_Last_Name__c;
            selectedPrescription.physician.npi = currentPrescription.PC_Physician_Account__r.PC_NPI__c;

            selectedPrescription.productName = currentPrescription.PC_Product__r.Name;
            selectedPrescription.drug = new PC_eBenefits.Product();
            selectedPrescription.drug.strength = currentPrescription.PC_Product__r.PC_Strength__c;
            selectedPrescription.drug.name = currentPrescription.PC_Product__r.Name;
            selectedPrescription.drug.ndc = currentPrescription.PC_Product__r.PC_NDC__c;
            selectedPrescription.drug.unitOfMeasureCode =
                    currentPrescription.PC_Product__r.PC_Unit_of_Measure_Code__c;
            selectedPrescription.drug.drugManufacturerName =
                    currentPrescription.PC_Product__r.PC_Manufacturer__r.Name;
            selectedPrescription.drug.drugManufacturerName = currentPrescription.PC_Product__r.PC_Manufacturer__r.Name;
            return selectedPrescription;
        }

        return null;
    }



    /**
    * fetching Clinic data after converting into request object and validation of mandatory fields
    */
    public static PC_eBenefits.Clinic getClinicDetails(Id clinicId) {

        if (clinicId != null) {
            Account currentClinic = getClinic(clinicId);
            PC_eBenefits.Clinic selectedClinic = new PC_eBenefits.Clinic();
            selectedClinic = convertClinic(currentClinic);
            return selectedClinic;
        }
        return null;
    }



    /**
    * Fetching Clinic data by passing clinic id
    */
    public static Account getClinic(Id clinicId) {
        if (clinicId != null) {
            /*
            * FLS Check for Clinic
            */

            List<String> clinicFields = new List<String>{
                    PC_Constants.getQualifiedAPIName('Name'),
                    PC_Constants.getQualifiedAPIName('PC_NPI__c'),
                    PC_Constants.getQualifiedAPIName('PC_PlaceOfService__c')

            };
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName(PC_Constants.PC_ACCOUNT),
                    PC_Database.Operation.Reading, clinicFields);


            List<Account> hcoAccountList = new List<Account>();

            hcoAccountList=[SELECT Id,Name, PC_NPI__c,PC_PlaceOfService__c FROM Account WHERE Id =:clinicId LIMIT 1];

            return hcoAccountList[0];
        }
        return null;
    }



    /**
    * Converting clinic data by passing clinic account object
    */
    public static PC_eBenefits.Clinic convertClinic(Account currentClinic) {


        if(currentClinic != null) {

            PC_eBenefits.Clinic selectedClinic = new PC_eBenefits.Clinic();

            selectedClinic.clinicId=currentClinic.Id;
            selectedClinic.name=currentClinic.Name;
            selectedClinic.npi=currentClinic.PC_NPI__c;


            return selectedClinic;
        }

        return null;
    }

    /**
    * Converting cpt codes data by passing List<String> of admin codes to MAp<String, String>
    */
    public static Map<String, String> getcptCodeMapLabelVal(List<String> adminCodes){


        string val = '';

        if(!adminCodes.isEmpty()) {

            Map<String, String> cptCodeMap = new Map<String, String>();

            Schema.DescribeFieldResult fieldResult = Product2.PC_CPT_Codes__c.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry picklistValue : picklistValues){
                for(String adminCode : adminCodes) {
                    if(adminCode == picklistValue.getValue()){
                        //PC_eBenefits.keyValue option = new PC_eBenefits.keyValue();
                        //option.value =  picklistValue.getValue();
                        //option.label =  picklistValue.getLabel();

                        if( (picklistValue.getValue() !=null) && (picklistValue.getLabel() !=null)) {
                            val = picklistValue.getLabel();

                            integer len = val.length();
                            if(val.indexOf(':') > -1) {
                                val = val.substring(val.indexOf(':') + 1, len);

                                cptCodeMap.put(picklistValue.getValue(), val);
                                val = '';

                            }
                        }

                    }
                }
            }
            return cptCodeMap;
        }

        return null;

    }
    /**
    * Validation of mandatory fields on Health plan
    */
    public static void validateHealthPlan(PC_eBenefits.HealthPlan selectedHealthPlan){

        Boolean isValid = true;
        if(selectedHealthPlan !=null) {
            if(selectedHealthPlan.relationshipToCardholder !=null && !selectedHealthPlan.relationshipToCardholder.equalsIgnoreCase(PC_Constants.SELF)) {
                if (String.isBlank(selectedHealthPlan.payerName) || String.isBlank(selectedHealthPlan.memberId)){
                    isValid = false;
                }
            }
        }

        if(!isValid){
            PC_Utility.throwAuraHandledException(Label.PC_MedicalBenefits_HealthPlan_Validation_Message);
        }
    }

    /**
    * Validation of mandatory fields on patient
    */
    public static void  validatePatientDetails(PC_eBenefits.Patient selectedpatient ){
        Boolean isValid = false;


        if(selectedpatient !=null ) {
           if (!String.isBlank(selectedpatient.firstName) &&
                    !String.isBlank(selectedpatient.lastName) &&
                    (selectedpatient.dob != null) &&
                    !String.isBlank(selectedpatient.gender)) {

                isValid = true;
            }
        }

        if(!isValid){
            PC_Utility.throwAuraHandledException(Label.PC_MedicalBenefits_Patient_Validation_Message);
        }

    }


    /**
    * Validation of mandatory fields on prescription
    */
    public static void validatePrescription(PC_eBenefits.Prescription selectedPrescription) {

        boolean isvalid = false;

        if(selectedPrescription !=null) {

            if (!String.isBlank(selectedPrescription.drug.name) &&
                    !String.isBlank(selectedPrescription.drug.strength) &&
                    !String.isBlank(selectedPrescription.drug.drugManufacturerName) &&
                    !String.isBlank(selectedPrescription.primaryDiagnosis) &&
                    !String.isBlank(selectedPrescription.physician.firstName) &&
                    !String.isBlank(selectedPrescription.physician.lastName) &&
                    !String.isBlank(
                            selectedPrescription.physician.address.state) &&
                    !String.isBlank(selectedPrescription.physician.npi) &&
                    !String.isBlank(selectedPrescription.placeOfService)) {

                isvalid = true;
            }
        }
        if(!isvalid) {
            PC_Utility.throwAuraHandledException(Label.PC_MedicalBenefits_Prescription_Validation_Message);
        }

    }

    /**
    * Validation of mandatory fields on clinic
    */
    public static void validateClinic( PC_eBenefits.Clinic currentHCO_Account) {

        boolean isvalid = false;

        if(currentHCO_Account !=null) {
           if (!String.isBlank(currentHCO_Account.name) && !String.isBlank(currentHCO_Account.npi)) {
                isvalid = true;
            }
            if(!isvalid) {
                PC_Utility.throwAuraHandledException(Label.PC_MedicalBenefits_Clinic_Validation_Message);
            }
        }
    }




    /**
    * updating sCoverageDetail wrapper with the response coming from Medical Benefit callout
    */
    public static void updateCoverageDetails(PC_eBenefits.sCoverageDetail sCoverage,
            PC_eBenefits.MedicalBenefitsResponse response) {

        /**
        * updating program coverage record
        */
        updateProgramCoverageDetails(sCoverage,response);


        updateCoverageBenefitDetails(sCoverage,response.programCoverage.primaryCoverageBenefit );


        if(response.programCoverage.primaryCoverageBenefit !=null) {
            if (response.programCoverage.primaryCoverageBenefit.benefitItems.size() > 0) {


                updateCoverageBenefitItemsDetails(sCoverage,PC_Constants.HEALTH_PLAN_TYPE_PRIMARY,
                                                   response.programCoverage.primaryCoverageBenefit.benefitItems);
            }
        }


        updateCoverageBenefitDetails(sCoverage,response.programCoverage.secondaryCoverageBenefit );
        if(response.programCoverage.secondaryCoverageBenefit !=null) {
            if (response.programCoverage.secondaryCoverageBenefit.benefitItems.size() > 0) {
                updateCoverageBenefitItemsDetails(sCoverage,PC_Constants.HEALTH_PLAN_TYPE_SECONDARY,
                                                  response.programCoverage.secondaryCoverageBenefit.benefitItems);
            }
        }


        updateCoverageBenefitDetails(sCoverage,response.programCoverage.tertiaryCoverageBenefit );
        if(response.programCoverage.tertiaryCoverageBenefit !=null) {
            if (response.programCoverage.tertiaryCoverageBenefit.benefitItems.size() > 0) {
                updateCoverageBenefitItemsDetails(sCoverage,PC_Constants.HEALTH_PLAN_TYPE_TERTIARY,
                                                   response.programCoverage.tertiaryCoverageBenefit.benefitItems);
            }
        }



        response.isSuccess = true;
    }

    public static void updateProgramCoverageDetails(PC_eBenefits.sCoverageDetail sCoverage,
            PC_eBenefits.MedicalBenefitsResponse response){

        sCoverage.programCoverage.PC_CoordinatedPlanBenefits__c  = response.programCoverage.coordinatedPlanBenefits;
        sCoverage.programCoverage.PC_Coverage_Status__c = PC_Constants.ACTIVE;
        if(String.isNotEmpty(response.programCoverage.completionStatus)) {
            sCoverage.programCoverage.PC_CompletionStatus__c = response.programCoverage.completionStatus;

        }
        sCoverage.programCoverage.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE,
                PC_Constants.PROGRAM_COVERAGE_MEDICAL_RECORD_TYPE);

    }


    /**
    * updating  coverage benefit record by passing scoverage  and ProgramCoverageBenefit object
    */
    public static void updateCoverageBenefitDetails(PC_eBenefits.sCoverageDetail sCoverage,
            PC_eBenefits.ProgramCoverageBenefit coverageBenefit) {



        if (coverageBenefit != null) {
            CoverageBenefit coverageRecord = new CoverageBenefit();

            coverageRecord.PC_TransactionID__c = coverageBenefit.transactionId;
            if (coverageBenefit.transactionDate != null) {
                coverageRecord.PC_TransactionDate__c = coverageBenefit.transactionDate;
            }
            coverageRecord.PC_CoverageStatus__c = coverageBenefit.coverageStatus;
            if (coverageBenefit.startDate != null) {
                coverageRecord.PC_StartDate__c = coverageBenefit.startDate;
            }
            if (coverageBenefit.endDate != null) {
                coverageRecord.PC_EndDate__c = coverageBenefit.endDate;
            }
            coverageRecord.PC_PayerName__c = coverageBenefit.payerName;
            coverageRecord.PC_PlanName__c = coverageBenefit.planName;
            coverageRecord.PC_PlanType__c = coverageBenefit.planType;
            coverageRecord.PC_GroupNo__c = coverageBenefit.groupNo;
            coverageRecord.PC_GroupName__c = coverageBenefit.groupName;
            coverageRecord.PC_TransactionMessageID__c = coverageBenefit.transactionMessageID;



            if(coverageBenefit.individualInNetworkDeductibleLimit != null){

                coverageRecord.IndividualInNetworkDeductibleLimit = coverageBenefit.individualInNetworkDeductibleLimit;


            }
            if(coverageBenefit.individualInNetworkDeductibleRemaining != null){

                coverageRecord.IndividualInNetworkDeductibleRemaining =
                                          coverageBenefit.individualInNetworkDeductibleRemaining;


            }

            if(coverageBenefit.individualInNetworkOutofPocketLimit != null){

                coverageRecord.IndividualInNetworkOutofPocketLimit =
                                          coverageBenefit.individualInNetworkOutofPocketLimit;


            }


            if(coverageBenefit.individualInNetworkOutofPocketRemaining != null){

                coverageRecord.IndividualInNetworkOutofPocketRemaining =
                        coverageBenefit.individualInNetworkOutofPocketRemaining;


            }



            if(coverageBenefit.familyInNetworkDeductibleLimit != null){

                coverageRecord.FamilyInNetworkDeductibleLimit = coverageBenefit.familyInNetworkDeductibleLimit;


            }
            if(coverageBenefit.familyInNetworkDeductibleRemaining != null){

                coverageRecord.FamilyInNetworkDeductibleRemaining = coverageBenefit.familyInNetworkDeductibleRemaining;


            }

            if(coverageBenefit.familyInNetworkOutofPocketLimit != null){

                coverageRecord.FamilyInNetworkOutofPocketLimit = coverageBenefit.familyInNetworkOutofPocketLimit;


            }
            if(coverageBenefit.familyInNetworkOutofPocketRemaining != null){

                coverageRecord.FamilyInNetworkOutofPocketRemaining = coverageBenefit.familyInNetworkOutofPocketRemaining;


            }




            coverageRecord.PC_PA_Required__c = coverageBenefit.paRequired;
            coverageRecord.PC_BuyAndBill__c = coverageBenefit.buyAndBill;
            coverageRecord.PC_SpecialtyPharmacyRequired__c = coverageBenefit.specialtyPharmacyRequired;

            if (coverageBenefit.isGovernmentPlan != null) {
                if (coverageBenefit.isGovernmentPlan.equalsIgnoreCase(PC_Constants.YES_STRING)) {
                    coverageRecord.PC_IsGovernmentPlan__c = PC_Constants.YES_STRING;
                } else if (coverageBenefit.isGovernmentPlan.equalsIgnoreCase(PC_Constants.NO_STRING)) {
                    coverageRecord.PC_IsGovernmentPlan__c = PC_Constants.NO_STRING;
                } else if (coverageBenefit.isGovernmentPlan.equalsIgnoreCase(PC_Constants.UNDETERMINED)) {
                    coverageRecord.PC_IsGovernmentPlan__c = PC_Constants.UNDETERMINED;
                } else if (coverageBenefit.isGovernmentPlan.equalsIgnoreCase(PC_Constants.NA)) {
                    coverageRecord.PC_IsGovernmentPlan__c = PC_Constants.NA;
                }
            }
            if (coverageBenefit.governmentPlanType != null) {
                if (coverageBenefit.governmentPlanType.equalsIgnoreCase(
                        PC_Constants.COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_MANAGED_MEDICAID)) {
                    coverageRecord.PC_GovernmentPlanType__c =
                            PC_Constants.COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_MANAGED_MEDICAID;
                } else if (coverageBenefit.governmentPlanType.equalsIgnoreCase(
                        PC_Constants.COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_MEDICAID)) {
                    coverageRecord.PC_GovernmentPlanType__c =
                            PC_Constants.COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_MEDICAID;
                } else if (coverageBenefit.governmentPlanType.equalsIgnoreCase(
                        PC_Constants.COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_MEDICARE)) {
                    coverageRecord.PC_GovernmentPlanType__c =
                            PC_Constants.COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_MEDICARE;
                } else if (coverageBenefit.governmentPlanType.equalsIgnoreCase(
                        PC_Constants.COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_MEDICARE_ADVANTAGE)) {
                    coverageRecord.PC_GovernmentPlanType__c =
                            PC_Constants.COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_MEDICARE_ADVANTAGE;
                } else if (coverageBenefit.governmentPlanType.equalsIgnoreCase(
                        PC_Constants.COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_MEDICARE_SUPPLEMENT)) {
                    coverageRecord.PC_GovernmentPlanType__c =
                            PC_Constants.COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_MEDICARE_SUPPLEMENT;
                } else if (coverageBenefit.governmentPlanType.equalsIgnoreCase(
                        PC_Constants.COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_TRICARE_VA)) {
                    coverageRecord.PC_GovernmentPlanType__c =
                            PC_Constants.COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_TRICARE_VA;
                } else if (coverageBenefit.governmentPlanType.equalsIgnoreCase(
                        PC_Constants.COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_FEP)) {
                    coverageRecord.PC_GovernmentPlanType__c =
                            PC_Constants.COVERAGE_BENEFIT_GOVERNMENT_PLAN_TYPE_FEP;
                }
            }
            coverageRecord.BenefitNotes = coverageBenefit.benefitNotes;
            coverageRecord.PC_ProductAdminMessag__c = coverageBenefit.productAdminMessage;
            coverageRecord.PC_BillingMessage__c = coverageBenefit.billingMessage;
            coverageRecord.PC_PriorAuthMessage__c = coverageBenefit.priorAuthMessage;
            coverageRecord.PC_PayerMessage__c = coverageBenefit.payerMessage;
            coverageRecord.PC_CoverageLevel__c = coverageBenefit.coverageLevel;

            if(coverageBenefit.coverageLevel.equalsIgnoreCase(PC_Constants.HEALTH_PLAN_TYPE_PRIMARY)) {
                sCoverage.primaryCoverageBenefit = coverageRecord ;
            }
            if(coverageBenefit.coverageLevel.equalsIgnoreCase(PC_Constants.HEALTH_PLAN_TYPE_SECONDARY)) {
                sCoverage.secondaryCoverageBenefit = coverageRecord ;
            }
            if(coverageBenefit.coverageLevel.equalsIgnoreCase(PC_Constants.HEALTH_PLAN_TYPE_TERTIARY)) {
                sCoverage.tertiaryCoverageBenefit = coverageRecord ;
            }
        }
    }


    /**
    * updating coverageBenefitItems by passing scoverage, coveragelevel and list of benefititems.
    */
    public static void updateCoverageBenefitItemsDetails(PC_eBenefits.sCoverageDetail sCoverage, String coverageLevel,
            List<PC_eBenefits.ProgramCoverageBenefitItem> benefitItems){

        for (PC_eBenefits.ProgramCoverageBenefitItem childObj : benefitItems) {
            CoverageBenefitItem coverageBenefitItem = new CoverageBenefitItem();

            coverageBenefitItem.Name = childObj.name;
            coverageBenefitItem.ServiceType = childObj.serviceType;
            coverageBenefitItem.ServiceTypeCode = childObj.serviceTypeCode;
            coverageBenefitItem.BenefitCategory = childObj.benefitCategory;
            coverageBenefitItem.CoverageLevel = childObj.coverageLevel;
            coverageBenefitItem.PC_DeductibleApplies__c = childObj.deductableApplies;
            coverageBenefitItem.PC_CopayApplies__c = childObj.copayApplies;
            coverageBenefitItem.PC_CoinsuranceApplies__c = childObj.coinsuranceApplies;
            coverageBenefitItem.PC_OOPMaxApplies__c = childObj.oopMaxApplies;
            coverageBenefitItem.PC_PCPCopayAmount__c = childObj.pcpCopayAmount;
            coverageBenefitItem.PC_SpecialistCopayAmount__c = childObj.specialistCopayAmount;
            coverageBenefitItem.PC_CoinsurancePercent__c = childObj.coinsurancePercent;

            if(coverageLevel.equalsIgnoreCase(PC_Constants.HEALTH_PLAN_TYPE_PRIMARY)){
                sCoverage.primaryCoverageBenefitItems.add(coverageBenefitItem);
            }
            if(coverageLevel.equalsIgnoreCase(PC_Constants.HEALTH_PLAN_TYPE_SECONDARY)){
                sCoverage.secondaryCoverageBenefitItems.add(coverageBenefitItem);
            }
            if(coverageLevel.equalsIgnoreCase(PC_Constants.HEALTH_PLAN_TYPE_TERTIARY)){
                sCoverage.tertiaryCoverageBenefitItems.add(coverageBenefitItem);
            }
        }
    }

    public static void insertingMedicalBenefitsData(PC_eBenefits.sCoverageDetail sCoverage){

        insertProgramCoverage(sCoverage);
        insertMemberPlan(sCoverage);

        insertPrimaryCoverageBenefit(sCoverage);
        insertPrimaryCoverageBenefitItems(sCoverage);

        insertSecondaryCoverageBenefit(sCoverage);
        insertSecondaryCoverageBenefitItems(sCoverage);

        insertTertiaryCoverageBenefit(sCoverage);
        insertTertiaryCoverageBenefitItems(sCoverage);
    }

    public static void insertProgramCoverage(PC_eBenefits.sCoverageDetail sCoverage){



        sCoverage.programCoverage.PC_Program__c =sCoverage.caseId;
        PC_Database.ins(sCoverage.programCoverage);
    }

    public static void insertMemberPlan(PC_eBenefits.sCoverageDetail sCoverage){

        sCoverage.primaryMemberPlan = new MemberPlan();
        sCoverage.primaryMemberPlan.MemberId = sCoverage.patientId;
        sCoverage.primaryMemberPlan.Name  =PC_Constants.PC_MEMBER_PLAN_ABBREVIATION  +
                                                        PC_Constants.HEALTH_PLAN_TYPE_PRIMARY;
        PC_Database.ins(sCoverage.primaryMemberPlan);

        if(sCoverage.secondaryCoverageBenefit != null) {
            sCoverage.secondaryMemberPlan = new MemberPlan();
            sCoverage.secondaryMemberPlan.MemberId = sCoverage.patientId;
            sCoverage.secondaryMemberPlan.Name =PC_Constants.PC_MEMBER_PLAN_ABBREVIATION +
                                                             PC_Constants.HEALTH_PLAN_TYPE_SECONDARY;
            PC_Database.ins(sCoverage.secondaryMemberPlan);
        }

        if(sCoverage.tertiaryCoverageBenefit != null) {
            sCoverage.tertiaryMemberPlan = new MemberPlan();
            sCoverage.tertiaryMemberPlan.MemberId = sCoverage.patientId;
            sCoverage.tertiaryMemberPlan.Name = PC_Constants.PC_MEMBER_PLAN_ABBREVIATION +
                                                      PC_Constants.HEALTH_PLAN_TYPE_TERTIARY;
            PC_Database.ins(sCoverage.tertiaryMemberPlan);
        }



    }

    public static void insertPrimaryCoverageBenefit(PC_eBenefits.sCoverageDetail sCoverage){

        if(sCoverage.primaryCoverageBenefit  !=null) {
            sCoverage.primaryCoverageBenefit.PC_ProgramCoverage__c = sCoverage.programCoverage.Id;
            sCoverage.primaryCoverageBenefit.MemberPlanId = sCoverage.primaryMemberPlan.id;
            PC_Database.ins(sCoverage.primaryCoverageBenefit);


        }
    }

    public static void insertPrimaryCoverageBenefitItems(PC_eBenefits.sCoverageDetail sCoverage){

        if(sCoverage.primaryCoverageBenefitItems.size()>0) {
            for (CoverageBenefitItem cbItem : sCoverage.primaryCoverageBenefitItems) {
                cbItem.CoverageBenefitId = sCoverage.primaryCoverageBenefit.id;
            }
            PC_Database.ins(sCoverage.primaryCoverageBenefitItems);
        }
    }


    public static void insertSecondaryCoverageBenefit(PC_eBenefits.sCoverageDetail sCoverage){

        if(  sCoverage.secondaryCoverageBenefit != null) {
            sCoverage.secondaryCoverageBenefit.PC_ProgramCoverage__c = sCoverage.programCoverage.Id;
            sCoverage.secondaryCoverageBenefit.MemberPlanId = sCoverage.secondaryMemberPlan.id;
            /*sCoverage.secondaryCoverageBenefit.Name ='CB:'+PC_Constants.HEALTH_PLAN_TYPE_SECONDARY;*/
            PC_Database.ins(sCoverage.secondaryCoverageBenefit);


        }
    }

    public static void insertSecondaryCoverageBenefitItems(PC_eBenefits.sCoverageDetail sCoverage){

        if(sCoverage.secondaryCoverageBenefitItems.size()>0) {
            for (CoverageBenefitItem cbItem : sCoverage.secondaryCoverageBenefitItems) {
                cbItem.CoverageBenefitId = sCoverage.secondaryCoverageBenefit.id;
            }
            PC_Database.ins(sCoverage.secondaryCoverageBenefitItems);
        }
    }

    public static void insertTertiaryCoverageBenefit(PC_eBenefits.sCoverageDetail sCoverage){

        if(sCoverage.tertiaryCoverageBenefit !=null) {
            sCoverage.tertiaryCoverageBenefit.PC_ProgramCoverage__c = sCoverage.programCoverage.Id;
            sCoverage.tertiaryCoverageBenefit.MemberPlanId = sCoverage.tertiaryMemberPlan.id;
            /*sCoverage.tertiaryCoverageBenefit.Name = 'CB:'+PC_Constants.HEALTH_PLAN_TYPE_TERTIARY;*/
            PC_Database.ins(sCoverage.tertiaryCoverageBenefit);
        }
    }

    public static void insertTertiaryCoverageBenefitItems(PC_eBenefits.sCoverageDetail sCoverage){

        if(sCoverage.tertiaryCoverageBenefitItems.size()>0) {
            for (CoverageBenefitItem cbItem : sCoverage.tertiaryCoverageBenefitItems) {
                cbItem.CoverageBenefitId = sCoverage.tertiaryCoverageBenefit.id;
            }
            PC_Database.ins(sCoverage.tertiaryCoverageBenefitItems);
        }
    }
}