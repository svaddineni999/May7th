/*********************************************************************************************************
Class Name      : PC_ePA
Description     : This will have all the wrapper class and utility methods
Created By      : Vijay Kashikar
Created Date    : June 20, 2018
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Vijay Kashikar              20 June, 2019              Initial Version
Shishir Bansal              25 Feb, 2019               [PC-4491] removing recordtype check
                                                        for selected health plan in prior Auth
Kanteti Kishore             13-Dec-2019                 [PC-5795] Reduced parameters for updatePARequest method
Vijay Kashikar              21-Jan-2021                [PC-7102] Added sharing clause
*********************************************************************************************************/

global with sharing class PC_ePA {

    /**
    * Implementor of this interface will qualify to be called from ePA initiation form
    */
    global interface Client {
        /**
         * Get the response from search form.
         * @param request Holds values necessary to send to form search request
         */
        FormsResponse searchForms(FormsRequest formsRequest);

        /**
         * Create the necessary search form request.
         */
        FormsRequest createSearchFormsRequest();

        /**
         * Create the necessary create PA form request.
         */
        PARequest submitPA();

        /**
         * Create a PA form request.
         * @param request Holds values necessary to send to create PA request.
         */
        PAResponse createPA(PARequest request); //todo submitPA instead.

        /**
         * Update the PA case based on the response returned from the service.
         * @param paCase Case object that will get saved based on the response
         * @param response Holds values received from PA request.
         */
        void updatePACase(Case paCase, PC_ePA.PAResponse response);
    }

    /**
    * Class which holds properties necessary to create a search form request
    */
    global inherited sharing class FormsRequest {
        /**
        * Property to hold health plan info
        */
        global HealthPlan healthPlan;
        /**
        * Property to hold product info
        */
        global Drug product;

        /**
        * Constructor to initialize members
        */
        global FormsRequest() {
            healthPlan = new HealthPlan();
            product = new Drug();
        }
    }
    /**
    * Class which holds properties necessary to create a PA request
    */
    global inherited sharing class PARequest {
        /**
        * Property to hold patient info
        */
        @AuraEnabled global Patient patient;
        /**
        * Property to hold product info
        */
        @AuraEnabled global Drug drug;
        /**
        * Property to hold form id of the vendor form that is selected by the user
        */
        @AuraEnabled global String formId;
        /**
        * Property to hold payer info
        */
        @AuraEnabled global Payer payer;
        /**
        * Property to hold pharmacy info
        */
        @AuraEnabled global Prescriber prescriber;
        /**
        * Property to hold prescription info
        */
        @AuraEnabled global Prescription prescription;


        /**
        * Constructor to initialize members
        */
        global PARequest() {
            patient = new Patient();
            drug = new Drug();
            payer = new Payer();
            prescriber = new Prescriber();
            prescription = new Prescription();
        }
    }
    /**
    * Class which stores values returned from create a PA request
    */
    global inherited sharing class PAResponse {
        /**
        * Property to know if the PA request and PA case creation was successful and this will be used to show appropriate message to end user.
        */
        @AuraEnabled global boolean isSuccess;
        /**
        * Property to know if the PA request was successful and will be used to show appropriate message to end user.
        */
        @AuraEnabled global boolean is_ePA_created;
        /**
        * Property to hold error message.
        */
        @AuraEnabled global String errorMessage;
        /**
        * Property to hold url of the PA created.
        */
        @AuraEnabled global String htmlURL;
        /**
        * Property to hold PA id. This will be persisted in the PA case and will used to pick the right PA case for real time automated updates to the existing PA cases.
        */
        @AuraEnabled global String ePA_Id;
        /**
        * Property to hold status of the PA.
        */
        @AuraEnabled global String status;
        /**
        * Property to hold PA case id. Will be used for internal purposes.
        */
        @AuraEnabled global Id paCaseId;
        /**
        * Property to hold service response object. The implementing class can use this to additionally update the PA case.
        */
        @AuraEnabled global object serviceResponseObject;

    }
    /**
    * Method to update the form request
    * @param caseId Salesforce id of the program case
    * @param pbmId Salesforce id of the health plan
    * @param productId Salesforce id of the product
    * @param formsRequest Forms request object that needs to be updated.
    */
    public static void updateFormsRequest(Id caseId, Id pbmId, Id productId, FormsRequest formsRequest) {
        PC_Health_Plan__c sHealthPlan = getHealthPlan(pbmId);
        HealthPlan healthPlan = convertHealthPlan(sHealthPlan);

        Product2 sProduct = getProduct(productId);
        Drug product = convertDrug(sProduct);

        formsRequest.healthPlan = healthPlan;
        formsRequest.product = product;

    }

    /**
    * Method to update the PA request
    * @param caseId Salesforce id of the program case
    * @param pbmId Salesforce id of the health plan
    * @param productId Salesforce id of the product
    * @param request PA request object that needs to be updated.
    */

    public static void updatePARequest(Map<String,String> ePADetails, PARequest request) {
        Id caseId = (Id) ePADetails.get('caseId');
        Id pbmId = (Id) ePADetails.get('pbmId');
        Id prescriptionId = (Id) ePADetails.get('prescriptionId');
        Id programCoverageId = (Id) ePADetails.get('programCoverageId');
        String overridePrescriptionWithCoverage = '';
        overridePrescriptionWithCoverage = ePADetails.get('overridePrescriptionWithCoverage');
        String formId = '';
        formId = ePADetails.get('formId');
        PC_Health_Plan__c healthPlan = getHealthPlan(pbmId);

        Patient patient = getPatientByCaseId(caseId);
        //Drug drug = getDrugByCaseId(caseId);
        Payer payer = getPayerByHealthPlanId(pbmId);
        Prescription prescription = new Prescription();
        if(overridePrescriptionWithCoverage == PC_Constants.FALSE_STRING) {
             prescription = getPrescriptionsById(prescriptionId);
        }
        else{

            if(programCoverageId != null) {

                List<PC_Program_Coverage__c> presId = [Select PC_Prescription__c from PC_Program_Coverage__c where id = :programCoverageId LIMIT 1];
                if(presId != null) {
                    prescription = getPrescriptionsById(presId[0].PC_Prescription__c);
                }
            }
        }
        Prescriber prescriber = getPrescriberByCaseId(caseId);

        //patient.memberId = healthPlan.PC_PBMMember_Id__c;
        patient.pbmMemberId = healthPlan.PC_PBMMember_Id__c;

        //payer.drugBenefitName =drug.name;
        //payer.drugBenefitName = prescription.product.name;

        request.patient = patient;
        //request.drug = drug;
        request.drug = prescription.product;
        request.formId = formId;
        request.payer = payer;
        request.prescriber = prescriber;
        request.prescription = prescription;
    }
    /**
    * Get the instance of ePA class that implements ePA client interface
    */
    public static Client getClientService() {
        String handlerClass = PC_System_Settings__c.getInstance().PC_ePA_Class__c;
        system.debug('handler class = ' + handlerClass);
        if(String.isBlank(handlerClass)) {
            PC_Utility.throwAuraHandledException(Label.PC_ePA_Handler_Class_Not_Found);
        }
        Type t = Type.forName(handlerClass);
        if (t != null) {

            Object o = t.newInstance();

            if (o instanceof Client) {
                Client handler = (Client) o;
                return handler;
            }
            else {
                PC_Utility.throwAuraHandledException(Label.PC_ePA_Handler_Class_Not_Found);
            }
        }
        else {
            PC_Utility.throwAuraHandledException(Label.PC_ePA_Handler_Class_Not_Found);
        }
        return null;
    }
    public static List<HealthPlan> getHealthPlansByCaseId(Id caseId) {
        Id accountId = getAccountIdByCaseId(caseId);
        if(accountId != null) {
            List<PC_Health_Plan__c> sHealthPlans = getHealthPlansByAccountId(accountId);
            if(sHealthPlans != null && !sHealthPlans.isEmpty()) {
                return convertHealthPlans(sHealthPlans);
            }
        }
        return new List<HealthPlan>();
    }
    public static Patient getPatientByCaseId(Id caseId) {
        Id accountId = getAccountIdByCaseId(caseId);
        if(accountId != null) {
            Account sAccount = getAccount(accountId);
            return convertAccount(sAccount);
        }
        return null;
    }
    public static Prescriber getPrescriberByCaseId(Id caseId) {
        Case c = getCase(caseId);
        if(c != null && c.PC_Physician__c != null) {
            Account sAccount = getAccount(c.PC_Physician__c);
            return covertPrescriber(sAccount);
        }
        return null;
    }


    public static Prescription getPrescriptionsById(Id prescriptionId) {
        List<String> prescriptionFields = new List<String>();
        Prescription prescription = new Prescription();
        prescriptionFields.add('Id');
        prescriptionFields.add('Name');
        prescriptionFields.add(PC_Constants.getQualifiedAPIName('PC_Days_Supply__c'));
        prescriptionFields.add(PC_Constants.getQualifiedAPIName('PC_Requested_Quantity__c'));
        prescriptionFields.add(PC_Constants.getQualifiedAPIName('PC_Product__r') + '.' + 'Id');
        prescriptionFields.add(PC_Constants.getQualifiedAPIName('PC_Product__r') + '.' + 'Name');
        prescriptionFields.add(PC_Constants.getQualifiedAPIName('PC_Product__r') + '.' + 'PC_NDC__c');
        prescriptionFields.add(PC_Constants.getQualifiedAPIName('PC_Dosage__c'));
        prescriptionFields.add(PC_Constants.getQualifiedAPIName('PC_Rx_Refills__c'));

        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Prescription__c'), PC_Database.Operation.Reading, prescriptionFields);


        List<PC_Prescription__c> pres = [
                SELECT Id, Name,PC_Frequency__c,PC_Rx_Start_Date__c, PC_Rx_End_Date__c,
                        PC_Days_Supply__c, PC_Requested_Quantity__c,PC_Rx_Refills__c,
                        PC_Product__r.Id, PC_Product__r.Name, PC_Product__r.PC_NDC__c, PC_Dosage__c, PC_Product__r.PC_Unit_of_Measure_Code__c
                FROM PC_Prescription__c
                WHERE id = :prescriptionId
                LIMIT 1
        ];
        if(pres.size()>0){
            prescription.id = pres[0].Id;
            prescription.name = pres[0].Name;
            prescription.displayName = (pres[0].PC_Product__r.Name == null) ? pres[0].Name : pres[0].PC_Product__r.Name + ' : ' + pres[0].Name ;
            prescription.frequency = pres[0].PC_Frequency__c;
            prescription.requestedQuantity = pres[0].PC_Requested_Quantity__c ;
            prescription.daysSupply = pres[0].PC_Days_Supply__c;
            prescription.product = new Drug();
            prescription.product.ndc = pres[0].PC_Product__r.PC_NDC__c;
            prescription.product.name = pres[0].PC_Product__r.Name;
            prescription.product.id = String.valueOf(pres[0].PC_Product__r.Id);
            prescription.product.quantityUnitOfMeasure = pres[0].PC_Product__r.PC_Unit_of_Measure_Code__c;
            prescription.startDate = pres[0].PC_Rx_Start_Date__c;
            prescription.endDate = pres[0].PC_Rx_End_Date__c;
            prescription.refills  = pres[0].PC_Rx_Refills__c;
    }

        return prescription;
    }




    public static List<Prescription> getPrescriptionsByCaseId(Id caseId) {
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

        List<Prescription> prescriptions = new List<Prescription>();
        Prescription prescription;
        for(PC_Prescription__c pres :[SELECT Id, Name,PC_Frequency__c,PC_Rx_Start_Date__c, PC_Rx_End_Date__c,
                PC_Days_Supply__c, PC_Requested_Quantity__c,
                PC_Product__r.Id, PC_Product__r.Name, PC_Product__r.PC_NDC__c, PC_Dosage__c, PC_Product__r.PC_Unit_of_Measure_Code__c
        FROM PC_Prescription__c
        WHERE PC_Program_Case__c = :caseId  AND PC_hasActivePA__c = false AND  PC_Rx_Status__c = true ORDER BY LastModifiedDate DESC])
        {
            prescription = new Prescription();
            prescription.id = pres.Id;
            prescription.name = pres.Name;
            prescription.displayName = (pres.PC_Product__r.Name == null) ? pres.Name : pres.PC_Product__r.Name+ ' : '+ pres.Name ;
            prescription.frequency = pres.PC_Frequency__c;
            prescription.requestedQuantity = pres.PC_Requested_Quantity__c ;
            prescription.daysSupply = pres.PC_Days_Supply__c;
            prescription.product = new Drug();
            prescription.product.ndc = pres.PC_Product__r.PC_NDC__c;
            prescription.product.name = pres.PC_Product__r.Name;
            prescription.product.id = String.valueOf(pres.PC_Product__r.Id);
            prescription.product.quantityUnitOfMeasure = pres.PC_Product__r.PC_Unit_of_Measure_Code__c;
            prescription.startDate = pres.PC_Rx_Start_Date__c;
            prescription.endDate  = pres.PC_Rx_End_Date__c;
            //prescription.lengthOfTherapy =  (pres.PC_Rx_End_Date__c - pres.PC_Rx_Start_Date__c)> 0 ? null : (pres.PC_Rx_End_Date__c - pres.PC_Rx_Start_Date__c);



            /*prescription.requestedQuantity = pres.PC_Requested_Quantity__c;
            prescription.daysSupply = pres.PC_Days_Supply__c;
            prescription.dosage = pres.PC_Dosage__c;
            prescription.productId = pres.PC_Product__r.Id;
            prescription.productName = pres.PC_Product__r.Name;
            prescription.ndc = pres.PC_Product__r.PC_NDC__c;
            prescription.ndcLabel = Product2.PC_NDC__c.getDescribe().getLabel();
            prescriptions.put(pres.Id, prescription);*/
            prescriptions.add(prescription);
        }


        return prescriptions;
    }

    public static List<ProgramCoverage> getProgramCoveragesByCaseId(Id caseId){

        List<String> ProgramCoverageFields = new List<String>();
        ProgramCoverageFields.add('Id');
        ProgramCoverageFields.add('Name');
        ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Prescription__r'));
        ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Prescription__r')+'.'+('PC_Product__r') + '.' + 'Id');
        ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Prescription__r')+'.'+('PC_Product__r') + '.' + 'Name');
        ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Prescription__r')+'.'+('PC_Product__r') + '.' + 'PC_NDC__c');

        ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Prescription__r')+'.'+('PC_Days_Supply__c'));
        ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Prescription__r')+'.'+('PC_Requested_Quantity__c'));
        ProgramCoverageFields.add(PC_Constants.getQualifiedAPIName('PC_Prescription__r')+'.'+('PC_Dosage__c'));


        Id RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_PROGRAM_COVERAGE, PC_Constants.PROGRAM_COVERAGE_PHARMACY_PLAN_RECORD_TYPE);

        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Program_Coverage__c'), PC_Database.Operation.Reading, ProgramCoverageFields);
        List<ProgramCoverage> programCoverages = new List<ProgramCoverage>();
        ProgramCoverage programCoverage;
        for(PC_Program_Coverage__c pCoverage :[SELECT Id, Name,PC_Prescription__r.PC_Frequency__c,
                PC_Prescription__r.PC_Days_Supply__c, PC_Prescription__r.PC_Requested_Quantity__c,PC_Prescription__r.name,PC_Prescription__r.id,
                PC_Coverage_Status__c, PC_Coverage_Type__c,PC_Prescription__r.PC_hasActivePA__c,PC_Prescription__r.PC_Rx_Status__c,
                        PC_Prescription__r.PC_Product__r.Id, PC_Prescription__r.PC_Product__r.Name, PC_Prescription__r.PC_Product__r.PC_NDC__c, PC_Prescription__r.PC_Dosage__c, PC_Prescription__r.PC_Product__r.PC_Unit_of_Measure_Code__c
        FROM PC_Program_Coverage__c
        WHERE PC_Program__c = :caseId  AND PC_hasActivePA__c = false AND PC_Coverage_Status__c !=: PC_Constants.INACTIVE   ORDER BY LastModifiedDate DESC])
        {
            if( (pCoverage.PC_Prescription__c != null) && (pCoverage.PC_Prescription__r.PC_hasActivePA__c == false) && (pCoverage.PC_Prescription__r.PC_Rx_Status__c == true) ) {
                programCoverage = new ProgramCoverage();
                programCoverage.id = pCoverage.id;
                programCoverage.name = pCoverage.Name;
                programCoverage.recordType = PC_Constants.PROGRAM_COVERAGE_PHARMACY_PLAN_RECORD_TYPE;
                programCoverage.coverageStatus = pCoverage.PC_Coverage_Status__c;
                programCoverage.coverageType =pCoverage.PC_Coverage_Type__c;



                programCoverage.prescription = new Prescription();
                programCoverage.prescription.id = pCoverage.PC_Prescription__r.id;
                programCoverage.prescription.name = pCoverage.PC_Prescription__r.name;
                programCoverage.prescription.product = new Drug();
                programCoverage.prescription.product.id = String.valueOf(pCoverage.PC_Prescription__r.PC_Product__r.Id);
                programCoverage.prescription.product.name = pCoverage.PC_Prescription__r.PC_Product__r.Name;
                programCoverage.prescription.product.ndc = pCoverage.PC_Prescription__r.PC_Product__r.PC_NDC__c;
                programCoverage.prescription.product.quantityUnitOfMeasure = pCoverage.PC_Prescription__r.PC_Product__r.PC_Unit_of_Measure_Code__c;
                programCoverage.displayName = (pCoverage.PC_Prescription__r.PC_Product__r.Name == null) ? (pCoverage.Name) : (pCoverage.PC_Prescription__r.PC_Product__r.Name + ' : ' + pCoverage.Name);
                programCoverages.add(programCoverage);
            }

            /*if( programCoverage.displayName ==''){

                programCoverage.displayName = (pCoverage.Name);

            }*/
            else if(pCoverage.PC_Prescription__c == null){
                programCoverage = new ProgramCoverage();
                programCoverage.id = pCoverage.id;
                programCoverage.name = pCoverage.Name;
                programCoverage.recordType = PC_Constants.PROGRAM_COVERAGE_PHARMACY_PLAN_RECORD_TYPE;
                programCoverage.coverageStatus = pCoverage.PC_Coverage_Status__c;
                programCoverage.coverageType =pCoverage.PC_Coverage_Type__c;
                programCoverage.displayName = (pCoverage.Name);
                programCoverages.add(programCoverage);
            }

            else{
                system.debug('bypass the record-->'+ pCoverage);
            }

        }

        system.debug('programCoverage--> '+programCoverages);


        return programCoverages;

    }

    /*public static Id getProductIdByEngagementProgramProductId(Id engagmentProgramProductId) {
        List<String> product2Fields = new List<String>();
        product2Fields.add('Id');
        product2Fields.add(PC_Constants.getQualifiedAPIName('PC_Product__c'));

        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Engagement_Program_Product__c'), PC_Database.Operation.Reading, product2Fields);

        List<PC_Engagement_Program_Product__c> products = [Select id, PC_Product__c FROM PC_Engagement_Program_Product__c where id= :engagmentProgramProductId];
        if(products != null && !products.isEmpty()) {
            return products[0].PC_Product__c;
        }
        return null;
    }*/

   /* public static Drug getDrugByCaseId(Id caseId) {
        Product2 product = getProductByCaseId(caseId);
        if(product != null) {
            return convertDrug(product);
        }
        return null;
    }*/

    public static Payer getPayerByHealthPlanId(Id pbmId) {
        PC_Health_Plan__c healthPlan = getHealthPlan(pbmId);
        if(healthPlan != null) {
            return convertPayer(healthPlan);
        }
        return null;
    }

    public static Product2 getProductByCaseId(Id caseId) {
        Id productId = getProductIdByCaseId(caseId);
        if(productId != null) {
            return getProduct(productId);
        }
        return null;
    }

    public static Id getProductIdByCaseId(Id caseId) {
        List<String> fields = new List<String>();
        fields.add('Id');
        fields.add(PC_Constants.getQualifiedAPIName('PC_Program_Product__r') + '.' + PC_Constants.getQualifiedAPIName('PC_Product__c'));
        fields.add(PC_Constants.getQualifiedAPIName('PC_Program_Product__c'));

        PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, fields);

        List<Case> cases = [Select Id, PC_Program_Product__c, PC_Program_Product__r.PC_Product__c from Case where id=:caseId];

        if(cases != null && !cases.isEmpty()) {
            Id engagmentProductId = cases[0].PC_Program_Product__c;
            Id productId;
            if(engagmentProductId != null) {
                productId = cases[0].PC_Program_Product__r.PC_Product__c;
                return productId;
            }
        }
        return  null;
    }

    public static Case getCase(Id caseId) {
        List<String> fields = new List<String>();
        fields.add('Id');
        fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__c'));
        fields.add(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'));
        fields.add(PC_Constants.getQualifiedAPIName('PC_Program_Product__c'));


        PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, fields);

        List<Case> cases = [Select Id, PC_Physician__c, PC_Engagement_Program__c, PC_Program_Product__c from Case where id=:caseId];

        if(cases != null && !cases.isEmpty()) {
            return cases[0];
        }
        return  null;
    }

    public static Id getPhysicianIdByCaseId(Id caseId) {
        List<String> fields = new List<String>();
        fields.add('Id');
        fields.add(PC_Constants.getQualifiedAPIName('PC_Physician__c'));

        PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, fields);

        List<Case> cases = [Select Id, PC_Physician__c from Case where id=:caseId];

        if(cases != null && !cases.isEmpty()) {
            return cases[0].PC_Physician__c;
        }
        return  null;
    }



    public static Product2 getProduct(Id productId) {
        List<String> product2Fields = new List<String>();
        product2Fields.add('Id');
        product2Fields.add('Name');
        product2Fields.add('ProductCode');
        product2Fields.add(PC_Constants.getQualifiedAPIName('PC_NDC__c'));
        PC_Database.assertAccess('Product2', PC_Database.Operation.Reading, product2Fields);

        List<Product2> products = [Select id, ProductCode, Name, PC_NDC__c FROM Product2 where id= :productId];
        if(products != null && !products.isEmpty()) {
            return products[0];
        }
        return null;
    }

    public static Account getAccount(Id accountId) {
        List<String> accountFields = new List<String>();
        accountFields.add('Id');
        accountFields.add('Name');
        accountFields.add('Phone');
        accountFields.add('Fax');
        accountFields.add(PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c'));
        accountFields.add(PC_Constants.getQualifiedAPIName('PC_Gender__c'));
        accountFields.add(PC_Constants.getQualifiedAPIName('PC_Primary_Zip_Code__c'));
        accountFields.add(PC_Constants.getQualifiedAPIName('PC_Primary_State__c'));
        accountFields.add(PC_Constants.getQualifiedAPIName('PC_First_Name__c'));
        accountFields.add(PC_Constants.getQualifiedAPIName('PC_Last_Name__c'));
        accountFields.add(PC_Constants.getQualifiedAPIName('PC_Primary_Address_1__c'));
        accountFields.add(PC_Constants.getQualifiedAPIName('PC_Primary_Address_2__c'));
        accountFields.add(PC_Constants.getQualifiedAPIName('PC_Primary_Address_3__c'));
        accountFields.add(PC_Constants.getQualifiedAPIName('PC_Email__c'));
        accountFields.add(PC_Constants.getQualifiedAPIName('PC_NPI__c'));
        PC_Database.assertAccess('Account', PC_Database.Operation.Reading, accountFields);

        List<Account> accounts = [Select id, Name,
                PC_Date_of_Birth__c, PC_First_Name__c, PC_Last_Name__c,
                PC_Gender__c, PC_Primary_Zip_Code__c,
                PC_Primary_Address_1__c, PC_Primary_Address_2__c, PC_Primary_Address_3__c,
                PC_Primary_State__c,PC_Primary_City__c, Phone, Fax, PC_Email__c, PC_NPI__c
        FROM Account where id= :accountId];
        if(accounts != null && !accounts.isEmpty()) {
            return accounts[0];
        }
        return null;
    }
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
    public static List<PC_Health_Plan__c> getHealthPlansByAccountId(Id accountId) {
        String recordTypeId;
        recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PHARMACY_PLAN_RECORD_TYPE);

        List<String> healthPlanStatus = new List<String>();
        healthPlanStatus.add(PC_Constants.INACTIVE);
        healthPlanStatus.add('');

        List<String> healthPlanFields = new List<String>();
        healthPlanFields.add('Id');
        healthPlanFields.add('Name');
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Group_name__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('Patient__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Rx_PCN__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Rx_Bin__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Group_name__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Card_Holder_State__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_PBM_Name__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_PBM_Name_as_per_Card_Lookup_Service__c'));


        PC_Database.assertAccess(PC_Constants.PC_HEALTH_PLAN, PC_Database.Operation.Reading, healthPlanFields);

        List<PC_Health_Plan__c> sHealthPlans = [
                Select Id, Name,
                        PC_Group_name__c, Patient__c, PC_Rx_PCN__c, PC_Rx_Bin__c, PC_Card_Holder_State__c, PC_PBM_Name__c, PC_PBM_Name_as_per_Card_Lookup_Service__c,
                        PC_Payer__r.Name FROM PC_Health_Plan__c
                where Patient__c = :accountId  AND PC_Plan_Status__c NOT IN :healthPlanStatus ORDER BY LastModifiedDate DESC
        ];

        return sHealthPlans;
    }

    public static PC_Health_Plan__c getHealthPlan(Id sHealthPlanId) {
        String recordTypeId;
        recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PHARMACY_PLAN_RECORD_TYPE);

        List<String> healthPlanFields = new List<String>();
        healthPlanFields.add('Id');
        healthPlanFields.add('Name');
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Group_name__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('Patient__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Rx_PCN__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Rx_Bin__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Group_name__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_Card_Holder_State__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_PBM_Name__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('Group_No__c'));
        healthPlanFields.add(PC_Constants.getQualifiedAPIName('PC_PBMMember_Id__c'));



        PC_Database.assertAccess(PC_Constants.PC_HEALTH_PLAN, PC_Database.Operation.Reading, healthPlanFields);

        List<PC_Health_Plan__c> sHealthPlans = [
                Select Id, Name,
                        PC_Group_name__c, Patient__c, PC_Rx_PCN__c, PC_Rx_Bin__c,
                        PC_Card_Holder_State__c, PC_PBM_Name__c, Group_No__c, PC_PBMMember_Id__c, PC_Payer__r.Name, PC_PBM_Name_as_per_Card_Lookup_Service__c
                FROM PC_Health_Plan__c WHERE
                Id = :sHealthPlanId
                ];

        if(sHealthPlans != null && !sHealthPlans.isEmpty()) {
            return sHealthPlans[0];
        }
        return null;
    }
    public static List<HealthPlan> convertHealthPlans(List<PC_Health_Plan__c> sHealthPlans) {
        List<HealthPlan> healthPlans = new List<HealthPlan>();
        HealthPlan healthPlan;
        for(PC_Health_Plan__c sHealthPlan : sHealthPlans) {
            /*healthPlan =  new HealthPlan();
            healthPlan.id = sHealthPlan.id;
            healthPlan.name = sHealthPlan.Name;
            healthPlan.displayName = sHealthPlan.Name;
            healthPlan.groupName = sHealthPlan.PC_Group_name__c;
            healthPlan.bin = sHealthPlan.PC_Rx_Bin__c;
            healthPlan.pcn = sHealthPlan.PC_Rx_PCN__c;*/
            healthPlans.add(convertHealthPlan(sHealthPlan));
        }
        return healthPlans;
    }
    public static HealthPlan convertHealthPlan(PC_Health_Plan__c sHealthPlan) {

        HealthPlan healthPlan = new HealthPlan();
        healthPlan.id = sHealthPlan.id;
        healthPlan.name = sHealthPlan.Name;
        String healthPlanPrefix = String.isBlank(sHealthPlan.PC_PBM_Name__c) ? '' : sHealthPlan.PC_PBM_Name__c + ' : ';
        healthPlan.displayName =  healthPlanPrefix + sHealthPlan.Name;
        healthPlan.groupName = sHealthPlan.PC_Group_name__c;
        healthPlan.bin = sHealthPlan.PC_Rx_Bin__c;
        healthPlan.pcn = sHealthPlan.PC_Rx_PCN__c;
        healthPlan.state = sHealthPlan.PC_Card_Holder_State__c;
        //healthPlan.medicalBenefitName = sHealthPlan.PC_Payer__r.Name;
        healthPlan.drugBenefitName = sHealthPlan.PC_PBM_Name_as_per_Card_Lookup_Service__c;
        return healthPlan;
    }
    public static Drug convertDrug(Product2 sProduct) {

        Drug drug = new Drug();
        drug.id = sProduct.Id;
        drug.displayName = sProduct.Name;
        drug.name = sProduct.Name;
        drug.ndc = sProduct.PC_NDC__c;
        return  drug;

    }

    public static Payer convertPayer(PC_Health_Plan__c sHealthPlan) {
        Payer payer = new Payer();
        payer.bin = sHealthPlan.PC_Rx_Bin__c;
        payer.pcn = sHealthPlan.PC_Rx_PCN__c;
        payer.groupId = sHealthPlan.Group_No__c;
        payer.drugBenefitName = sHealthPlan.PC_PBM_Name_as_per_Card_Lookup_Service__c;
        //payer.medicalBenefitName = sHealthPlan.PC_Payer__r.Name;

        return payer;
    }
    public static Patient convertAccount(Account sAccount) {

        Patient patient = new Patient();
        patient.id = sAccount.Id;
        patient.displayName = sAccount.Name;
        patient.name = sAccount.Name;
        patient.firstName = sAccount.PC_First_Name__c;
        patient.lastName = sAccount.PC_Last_Name__c;
        patient.zipCode = sAccount.PC_Primary_Zip_Code__c;
        patient.birthDate = sAccount.PC_Date_of_Birth__c;
        patient.gender = sAccount.PC_Gender__c;
        patient.state = sAccount.PC_Primary_State__c;
        patient.phone = sAccount.Phone;
        patient.email = sAccount.PC_Email__c;

        Address address = new Address();
        address.postalCode = sAccount.PC_Primary_Zip_Code__c;
        address.state = sAccount.PC_Primary_State__c;
        address.city = sAccount.PC_Primary_City__c;
        address.addressOne = sAccount.PC_Primary_Address_1__c;
        address.addressTwo = sAccount.PC_Primary_Address_2__c;
        patient.address = address;

        return patient;
    }

    public static Prescriber covertPrescriber(Account sAccount) {

        Prescriber prescriber = new Prescriber();
        prescriber.id = sAccount.Id;
        prescriber.name = sAccount.Name;
        prescriber.firstName = sAccount.PC_First_Name__c;
        prescriber.lastName = sAccount.PC_Last_Name__c;
        prescriber.phone = sAccount.Phone;
        prescriber.fax = sAccount.Fax;
        prescriber.npi = sAccount.PC_NPI__c;

        Address address = new Address();
        address.postalCode = sAccount.PC_Primary_Zip_Code__c;
        address.city = sAccount.PC_Primary_City__c;
        address.state = sAccount.PC_Primary_State__c;
        address.addressOne = sAccount.PC_Primary_Address_1__c;
        address.addressTwo = sAccount.PC_Primary_Address_2__c;

        prescriber.address = address;

        return prescriber;
    }

    /**
    * Provides properties to hold health plan
    */
    global inherited sharing  class HealthPlan{
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
    }
    /**
    * Provides properties to hold prescription
    */
    global inherited sharing class Prescription{
        /**
        * Property to hold Salesforce ID
        */
        @AuraEnabled global string id;
        /**
        * Property to hold name
        */
        @AuraEnabled global string name;
        /**
        * Property to hold name label
        */
        @AuraEnabled global string nameLabel;
        /**
        * Property to hold display name
        */
        @AuraEnabled global string displayName;
        /**
        * Property to hold frequency
        */
        @AuraEnabled global string frequency ;
        /**
        * Property to hold frequency label
        */
        @AuraEnabled global string frequencyLabel;
        /**
        * Property to hold daysSupply
        */
        @AuraEnabled global Decimal daysSupply ;
        /**
        * Property to hold daysSupply label
        */
        @AuraEnabled global string daysSupplyLabel;
        /**
        * Property to hold  requested quantity
        */
        @AuraEnabled global Decimal requestedQuantity ;
        /**
        * Property to hold  start date
        */
        @AuraEnabled global date startDate;
        /**
        * Property to hold  end date
        */
        @AuraEnabled global date endDate;
        /**
        * Property to hold requestedQuantity label
        */
        @AuraEnabled global string reqQuantityLabel;
        /**
        * Property to hold product information
        */
        @AuraEnabled global Drug product;
        /**
        * Property to hold  refills info
        */
        @AuraEnabled global Decimal refills;

    }
    /**
    * Provides properties to hold pharmacy
    */
    global inherited sharing class Prescriber {
        /**
        * Property to hold Salesforce ID
        */
        @AuraEnabled global string id;
        /**
        * Property to hold name
        */
        @AuraEnabled global string name;
        /**
        * Property to hold first name
        */
        @AuraEnabled global string firstName;
        /**
        * Property to hold last name
        */
        @AuraEnabled global string lastName;
        /**
        * Property to hold name NCPDP
        */
        @AuraEnabled global string ncpdp;
        /**
        * Property to hold NPI
        */
        @AuraEnabled global string npi;
        /**
        * Property to hold phone number
        */
        @AuraEnabled global string phone;
        /**
        * Property to hold fax number
        */
        @AuraEnabled global string fax;
        /**
         * Property to hold address
         */
        @AuraEnabled global Address address;
    }
    /**
    * Provides properties to hold drug
    */
    global inherited sharing class Drug{
        /**
        * Property to hold Salesforce ID
        */
        @AuraEnabled global string id;
        /**
        * Property to hold name
        */
        @AuraEnabled global string name;
        /**
        * Property to hold name label
        */
        @AuraEnabled global string nameLabel;
        /**
        * Property to hold display name
        */
        @AuraEnabled global string displayName;
        /**
        * Property to hold name
        */
        @AuraEnabled global string ndc;
        /**
        * Property to hold ndc label
        */
        @AuraEnabled global string ndcLabel;
        /**
        * Property to hold quantity unit of measure info
        */
        @AuraEnabled global string quantityUnitOfMeasure;
    }
    /**
    * Provides properties to hold patient info
    */
    global inherited sharing class Patient{
        /**
        * Property to hold Salesforce ID
        */
        @AuraEnabled global string id;
        /**
        * Property to hold name
        */
        @AuraEnabled global string name;
        /**
        * Property to hold name label
        */
        @AuraEnabled global string nameLabel;
        /**
        * Property to hold first name
        */
        @AuraEnabled global string firstName;
        /**
        * Property to hold last name
        */
        @AuraEnabled global string lastName;
        /**
        * Property to hold display name
        */
        @AuraEnabled global string displayName;
        /**
        * Property to hold gender
        */
        @AuraEnabled global string gender;
        /**
        * Property to hold gender label
        */
        @AuraEnabled global string genderLabel;
        /**
        * Property to hold birthdate
        */
        @AuraEnabled global date birthDate;
        /**
        * Property to hold birth date label
        */
        @AuraEnabled global string birthDateLabel;
        /**
        * Property to hold birthdata in user locale
        */
        @AuraEnabled global date birthDateInUserLocale;
        /**
        * Property to hold birthdate in JSON
        */
        @AuraEnabled global string birthDateInJSONFormat;
        /**
        * Property to hold zip code
        */
        @AuraEnabled global string zipCode;
        /**
        * Property to hold zip code label
        */
        @AuraEnabled global string zipCodeLabel;
        /**
        * Property to hold state
        */
        @AuraEnabled global string state;
        /**
         * Property to hold addresss
         */
        @AuraEnabled global Address address;
        /**
        * Property to hold member_id
        */
        @AuraEnabled global string memberId;
        /**
        * Property to hold member_id
        */
        @AuraEnabled global string pbmMemberId;
        /**
        * Property to hold member_id
        */
        @AuraEnabled global string phone;
        /**
        * Property to hold member_id
        */
        @AuraEnabled global string email;

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
        //@auraEnabled global String postalCodeLabel = '';
        /**
        * Property to hold label for city.
        */
        //@auraEnabled global String cityLabel = '';
        /**
        * Property to hold label for state.
        */
        //@auraEnabled global String stateLabel = '';
        /**
        * Property to hold Salesforce ID of the address.
        */
        @auraEnabled global String id = PC_Constants.EMPTY_STRING;
    }
    /**
    * Wrapper class to get initiation form details.
    */
    global inherited sharing class InitiationFormData{
        /**
        * Property to hold Salesforce ID
        */
        @AuraEnabled global List<HealthPlan> healthPlans;
        /**
        * Property to hold products
        */
        @AuraEnabled global List<Drug> products;
        /**
        * Property to hold prescription information
        */
        @AuraEnabled global List<Prescription> prescriptions;
        /**
        * Property to hold health plan labels
        */
        @AuraEnabled global HealthPlan healthPlanLabels;
        /**
        * Property to hold health plan labels
        */
        @AuraEnabled global Drug drugLabels;
        /**
        * Property to hold patient details
        */
        @AuraEnabled global Patient patient;
        /**
        * Property to hold patient labels
        */
        @AuraEnabled global Patient patientLabels;
        /**
        * Property to hold search form labels
        */
        @AuraEnabled global FormLabel searchFormLabels;
        /**
        * Property to hold prescription labels
        */
        @AuraEnabled global Prescription prescriptionLabels;
        /**
        * Property to hold program Coverage labels
        */
        @AuraEnabled global List<ProgramCoverage> programCoverages;
        /**
        * Property to hold program Coverage labels
        */
        @AuraEnabled global ProgramCoverage programCoveragesLabel;
    }

    /**
   * Class which holds properties of Program Coverage
   */
    global inherited sharing class ProgramCoverage {
        /**
        * Property to hold  recordId
        */
        @AuraEnabled global String id;
        /**
        * Property to hold record type
        */
        @AuraEnabled global String recordType;
        /**
        * Property to hold Coverage Status
        */
        @AuraEnabled global String coverageStatus;
        /**
        * Property to hold Coverage Status Label
        */
        @AuraEnabled global String coverageStatusLabel;

        /**
        * Property to hold Covearge Type
        */
        @AuraEnabled global String coverageType;
        /**
        * Property to hold Covearge Type label
    */
        @AuraEnabled global String coverageTypeLabel;
        /**
        * Property to hold Prescrption
        */
        @AuraEnabled global Prescription prescription;
        /**
        * Property to hold Program Coverage name
        */
        @AuraEnabled global String name;
        /**
        * Property to hold name label
        */
        @AuraEnabled global string nameLabel;
        /**
        * Property to hold Program Coverage display name
        */
        @AuraEnabled global String displayName;
    }


    /**
    * class to hold PA form service response.
    */
    global inherited sharing class FormsResponse {
        @AuraEnabled global List<Form> forms;
    }

    /**
    * class to hold PA form data.
    */
    global inherited sharing class Form {
        /**
        * Property to hold id
        */
        @AuraEnabled global Integer id;	//31622
        /**
        * Property to hold link to form
        */
        @AuraEnabled global String href;	//https://master-api.integration.covermymeds.com/forms/31622
        /**
        * Property to hold form name
        */
        @AuraEnabled global String name;	//express_scripts_general_1
        /**
        * Property to hold form description
        */
        @AuraEnabled global String description;	//Express Scripts General Request Form
        /**
        * Property to hold form directions
        */
        @AuraEnabled global String directions;	//Prior Authorization Form for General Medication Requests. This form can be used for Medicare and non-Medicare requests (Use for Members with an Express Scripts logo on their ID card)
        /**
        * Property to hold form id
        */
        @AuraEnabled global String requestFormId;	//express_scripts_general_1_31622
        /**
        * Property to hold thumbnail URL
        */
        @AuraEnabled global String thumbnailUrl;	//https://master-api.integration.covermymeds.com/forms/pdf/thumbs/90/express_scripts_general_1_31622.jpg
        /**
        * Property to hold preview URL
        */
        @AuraEnabled global String previewUrl;	//https://master-api.integration.covermymeds.com/forms/pdf/thumbs/270/express_scripts_general_1_31622.jpg
        /**
        * Property to flag if form is for ePA
        */
        @AuraEnabled global boolean is_epa;
        /**
        * Property to hold payer info
        */
        @AuraEnabled global Payer payer;
        /**
        * Property to hold form score.
        */
        @AuraEnabled global Decimal score;	//14
        /**
        * Property to flag if form is active
        */
        @AuraEnabled global boolean active;
        /**
        * Property to flag if form is for enrollment
        */
        @AuraEnabled global boolean isEnrollment;
    }


    /**
    * Class to hold labels for form.
    */
    global inherited sharing class FormLabel {
        /**
        * Property to hold form ID label
        */
        @AuraEnabled global string formName;
        /**
        * Property to hold thumbnail url
        */
        @AuraEnabled global string thumbNailURL;
        /**
        * Property to hold directions
        */
        @AuraEnabled global string directions;
        /**
        * Property to hold description
        */
        @AuraEnabled global string description;
        /**
        * Property to hold is ePA values
        */
        @AuraEnabled global string is_ePA;
        /**
        * Property to hold payer contact
        */
        @AuraEnabled global string payerContact;
        /**
        * Property to hold payer info
        */
        @AuraEnabled global PayerLabel payerLabels;
    }

    /**
    * class to hold payer info.
    */
    global inherited sharing class Payer {
        /**
        * Property to hold payer name
        */
        @AuraEnabled global String name;	//Express Scripts
        /**
        * Property to hold payer phone
        */
        @AuraEnabled global String phone;	//(800) 417-8164
        /**
        * Property to hold payer fax
        */
        @AuraEnabled global String fax;	//(800) 357-9577
        /**
        * Property to hold payer BIN
        */
        @AuraEnabled global String bin;
        /**
        * Property to hold payer PCN
        */
        @AuraEnabled global String pcn;
        /**
        * Property to hold payer PCN
        */
        @AuraEnabled global String groupId;
        /**
        * Property to hold payer PCN
        */
        @AuraEnabled global String medicalBenefitName;
        /**
       * Property to hold payer PCN
       */
        @AuraEnabled global String drugBenefitName;
    }
    global inherited sharing class PayerLabel {
        /**
        * Property to hold name
        */
        @AuraEnabled global string name;
        /**
        * Property to hold phone #
        */
        @AuraEnabled global string phone;
        /**
        * Property to hold fax #
        */
        @AuraEnabled global string fax;
    }



    public static HealthPlan getHealthPlanLabels() {
        HealthPlan healthPlanLabels = new HealthPlan();
        healthPlanLabels.nameLabel = PC_Health_Plan__c.Name.getDescribe().getLabel();
        healthPlanLabels.stateLabel = 'State TBD';
        healthPlanLabels.binLabel = PC_Health_Plan__c.PC_Rx_Bin__c.getDescribe().getLabel();
        healthPlanLabels.pcnLabel = PC_Health_Plan__c.PC_Rx_PCN__c.getDescribe().getLabel();
        healthPlanLabels.groupNameLabel = PC_Health_Plan__c.PC_Group_name__c.getDescribe().getLabel();
        healthPlanLabels.stateLabel = PC_Health_Plan__c.PC_Card_Holder_State__c.getDescribe().getLabel();
        return healthPlanLabels;
    }

    /*public static Drug getDrugLabels() {
        Drug drugLabels = new Drug();
        drugLabels.nameLabel = Product2.Name.getDescribe().getLabel();
        drugLabels.ndcLabel = Product2.PC_NDC__c.getDescribe().getLabel();
        return drugLabels;
    }*/



    public static Prescription getPrescriptionLabels() {
        Prescription prescriptionLabels = new Prescription();
        prescriptionLabels.product = new Drug();
        prescriptionLabels.product.nameLabel = Product2.Name.getDescribe().getLabel();
        prescriptionLabels.product.ndcLabel = Product2.PC_NDC__c.getDescribe().getLabel();


        prescriptionLabels.daysSupplyLabel = PC_Prescription__c.PC_Days_Supply__c.getDescribe().getLabel();
        prescriptionLabels.nameLabel = PC_Prescription__c.Name.getDescribe().getLabel();
        prescriptionLabels.frequencyLabel = PC_Prescription__c.PC_Frequency__c.getDescribe().getLabel();
        prescriptionLabels.reqQuantityLabel = PC_Prescription__c.PC_Requested_Quantity__c.getDescribe().getLabel();

        return prescriptionLabels;
    }

    public static ProgramCoverage getProgramCoverageLabels() {
        ProgramCoverage programCoverageLabels = new ProgramCoverage();
        programCoverageLabels.prescription = new Prescription();
        programCoverageLabels.prescription.product = new Drug();
        programCoverageLabels.nameLabel = PC_Program_Coverage__c.Name.getDescribe().getLabel();
        programCoverageLabels.coverageStatusLabel = PC_Program_Coverage__c.PC_Coverage_Status__c.getDescribe().getLabel();
        programCoverageLabels.coverageTypeLabel = PC_Program_Coverage__c.PC_Coverage_Type__c.getDescribe().getLabel();
        programCoverageLabels.prescription.product.nameLabel = Product2.Name.getDescribe().getLabel();
        programCoverageLabels.prescription.product.ndcLabel =  Product2.PC_NDC__c.getDescribe().getLabel();
        programCoverageLabels.prescription.nameLabel = PC_Prescription__c.Name.getDescribe().getLabel();

        return programCoverageLabels;
    }





    public static Patient getPatientLabels() {
        Patient patientLabels = new Patient();
        patientLabels.nameLabel = Account.Name.getDescribe().getLabel();
        patientLabels.birthDateLabel = Account.PC_Date_of_Birth__c.getDescribe().getLabel();
        patientLabels.genderLabel = Account.PC_Gender__c.getDescribe().getLabel();
        patientLabels.zipCodeLabel = Account.PC_Primary_Zip_Code__c.getDescribe().getLabel();
        return patientLabels;
    }

    public static FormLabel getFormLabels() {
        FormLabel formLabels = new FormLabel();
        formLabels.formName = Label.PC_ePA_Form_Name;
        formLabels.directions = Label.PC_ePA_Form_Directions;
        formLabels.description = Label.PC_ePA_Form_Description;
        formLabels.is_ePA = Label.PC_ePA_Form_is_ePA;
        formLabels.payerContact = Label.PC_ePA_Form_PayerContact;
        PayerLabel payerLabel = new PayerLabel();
        payerLabel.name = Account.Name.getDescribe().getLabel();
        payerLabel.phone = Account.Phone.getDescribe().getLabel();
        payerLabel.fax = Account.Fax.getDescribe().getLabel();
        formLabels.payerLabels = payerLabel;
        return formLabels;

    }
    /*public static Prescription getPrescriptionLabels() {
        Prescription prescriptionLabels = new Prescription();
        prescriptionLabels.name = PC_Prescription__c.Name.getDescribe().getLabel();
        return prescriptionLabels;
    }*


    /*public static Id getProductIdByCaseId(Id caseId) {
        Id engagementProgramProductId = getEngagmentProgramProductIdByCaseId(caseId);
        Id productId;
        if(engagementProgramProductId != null) {
            productId = getProductIdByEngagementProgramProductId(engagementProgramProductId);
        }
        return productId;
    }*/

    /*public static Id getEngagmentProgramProductIdByCaseId(Id caseId) {
        List<String> fields = new List<String>();
        fields.add('Id');
        fields.add(PC_Constants.getQualifiedAPIName('PC_Program_Product__c'));
        PC_Database.assertAccess('Case', PC_Database.Operation.Reading, fields);

        List<Case> cases = [Select Id, PC_Program_Product__c from Case where id=:caseId];
        if(cases != null && !cases.isEmpty()) {
            return cases[0].PC_Program_Product__c;
        }
        return null;
    }*/

}