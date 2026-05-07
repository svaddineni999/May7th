/**************************************************************************************************************************************************************************
Class Name      : PC_Infinitus
Description     : This is the Infinitus Parent Class.
Created By      : Satheesh Kumar & Chetna Mohapatra
Created Date    : 01-Mar-2022
Modification Log:
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Developer                   Date                  Description
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Chetna Mohapatra
& Satheesh Kumar        01-Mar-2022             Initial Version
Satheesh Kumar          12-Oct-2022             [PC-9262] Added condition to avoid removing namespace prefix from sObject when sobject contains no namespace.
 **********************************************************************************************************************************************************************/
public abstract class PC_Infinitus {
    protected abstract void init();
    protected String apiKey;
    protected String endpoint;
    protected HttpMethod method;
    protected String payload;
    Map<String, String> queryParams, headerParams;

    public PC_Infinitus() {
        queryParams = new Map<String, String>();
        headerParams = new Map<String, String>();
    }
    //Http Method Type
    public enum HttpMethod { XGET, XPUT, XHEAD, XOPTIONS, XDELETE, XPOST }
    //Benefits Investigation Type
    public enum BITaskType { INF_TASK_TYPE_UNKNOWN, INF_TASK_TYPE_BENEFITS_VERIFICATION, INF_TASK_TYPE_PHARMACY_BENEFIT_MANAGER}
    //Practice Facility Type
    public enum FacilityType{INF_FACILITY_TYPE_UNKNOWN, INF_FACILITY_TYPE_SPECIALIST_OFFICE, INF_FACILITY_TYPE_HOSPITAL_OUTPATIENT, INF_FACILITY_TYPE_PHARMACY}
    //Provider Network Status
    public enum providerNetworkStatus{INF_INPUT_NETWORK_STATUS_UNKNOWN, INF_INPUT_NETWORK_STATUS_IN_NETWORK, INF_INPUT_NETWORK_STATUS_OUT_OF_NETWORK}

    public HttpResponse sendRequest(HttpRequest request) {
        HttpResponse response = new Http().send(request);
        return response;
    }

    public HttpRequest generateHttpRequest() {
        HttpRequest request = new HttpRequest();
        init();
        request.setMethod(method.name().removeStart('X'));
        for (String key : headerParams.keySet()) {
            request.setHeader(key, headerParams.get(key));
        }
        request.setEndpoint(endpoint);
        request.setBody(payload);
        return request;
    }

    protected void setHeader(String key, String value) {
        headerParams.put(key.toLowerCase(), value);
    }

    public static void handleInfinitusCallback(String requestBody, String requestURL,String infinitusServiceName) {
        String serviceType= PC_Constants.REMOTE_SERVICE_TYPE_INBOUND;
        PC_Remote_Service_Log__c record = PC_RemoteServiceLogHandler.createRemoteServiceLog(infinitusServiceName, requestURL, requestBody, '', '',serviceType);
        PC_RemoteServiceLogHandler.publishRemoteServiceLogInfo(record);

    }
    public static void processInfinitusCallbackDetails (List<PC_Remote_Service_Log_Info__e> callbackDetails){
        List<PC_Infinitus.Data> pbmCallbackData= new List<PC_Infinitus.Data>();
        List<PC_Infinitus.Data> bvCallbackData=new List<PC_Infinitus.Data>();
        System.debug('callback-Details--' +callbackDetails);
        for(PC_Remote_Service_Log_Info__e sc:callbackDetails) {
            PC_Infinitus.InfinitusBICallback callback=PC_Infinitus.parseInfinutusCallback(sc.PC_Callback_Request__c);
            for(PC_Infinitus.Data data:callback.data){
                if(data.taskType==PC_Infinitus.BITaskType.INF_TASK_TYPE_PHARMACY_BENEFIT_MANAGER.name()){
                    pbmCallbackData.add(data);
                }else if(data.taskType==PC_Infinitus.BITaskType.INF_TASK_TYPE_BENEFITS_VERIFICATION.name()){
                    bvCallbackData.add(data);
                }
            }
        }
        if(pbmCallbackData!=null && !pbmCallbackData.isEmpty()){
            PC_PharmacyBI_Infinitus.createProgramCoverageAndUpdateActivity(pbmCallbackData);
        }
        if(bvCallbackData!=null && !bvCallbackData.isEmpty()){
           PC_MedicalBI_Infinitus.createProgramCoverageAndUpdateActivity(bvCallbackData);
        }
    }
    public class TasksRequest {
        public List<Tasks> tasks;

        public TasksRequest() {
            List<Tasks> tasks = new List<Tasks>();
        }

        public TasksRequest(Id sourceRecordId, BITaskType requestType) {
            String objType = String.valueOf(sourceRecordId.getSobjectType());
            //remove namespace prefix from objType when objType contains namespace
            objType = objType.contains('__') ? (objType.countMatches('__') == 2 ? objType.substringAfter('__') : objType): objType;
            List<PC_CaseProduct__c> caseProductList = new List<PC_CaseProduct__c>();
            List<PC_Health_Plan__c> pharmacyHealthPlans = new List<PC_Health_Plan__c>();
            List<PC_Health_Plan__c> medicalHealthPlans = new List<PC_Health_Plan__c>();
            List<Account> providerDetails= new List<Account>();
            List<Account>patientDetails= new List<Account>();
            List<Account>hcoAccountList= new List<Account>();
            List<Case> caseList= new List<Case>();
            if (objType == PC_Constants.PC_CASE) {
                // SOQL query to fetch case record details
                caseList = [
                        SELECT Id, AccountId, PC_Engagement_Program__c,PC_Physician__c,
                        (SELECT PC_Role__c, PC_Account__c FROM Associations__r WHERE PC_AssociationStatus__c = 'Active' AND PC_Role__c=: PC_Constants.HCO_RecordType LIMIT 1)
                        FROM Case
                        WHERE Id = :sourceRecordId
                        WITH SECURITY_ENFORCED
                        LIMIT 1
                ];
            }else if(objType==PC_Constants.PC_CASEPRODUCT){
                List<PC_CaseProduct__c> caseProducts = [
                        SELECT Id, PC_Case__c
                        FROM PC_CaseProduct__c
                        WHERE Id = :sourceRecordId
                        WITH SECURITY_ENFORCED
                ];
                List<Id> caseIds= new List<Id>();
                for(PC_CaseProduct__c cp:caseProducts){
                    caseIds.add(cp.PC_Case__c);
                }
                if(caseIds!=null && caseIds.size()>0){
                    caseList=[
                            SELECT Id, AccountId, PC_Engagement_Program__c,PC_Physician__c,
                            (SELECT PC_Role__c, PC_Account__c FROM Associations__r WHERE PC_AssociationStatus__c = 'Active' AND PC_Role__c=: PC_Constants.HCO_RecordType LIMIT 1)
                            FROM Case
                            WHERE Id IN: caseIds
                            WITH SECURITY_ENFORCED
                            LIMIT 1
                    ];
                }
            }
            else if(objType == PC_Constants.PC_ACCOUNT){
                List<Account> accountList= [
                        SELECT (SELECT Id FROM Account.Cases WHERE Type =: PC_Constants.CASE_PROGRAM_TYPE LIMIT 1)
                        FROM Account
                        WHERE Id=:sourceRecordId WITH SECURITY_ENFORCED
                ];
                System.debug('AccList---'+accountList);
                List<Case> caseIds= new List<Case>();
                for(Account acc:accountList){
                    caseIds.add(acc.Cases);
                }
                if(accountList!=null && accountList.size()>0){
                    caseList=[
                            SELECT Id, AccountId, PC_Engagement_Program__c,PC_Physician__c,
                            (SELECT PC_Role__c, PC_Account__c FROM Associations__r WHERE PC_AssociationStatus__c = 'Active' AND PC_Role__c=: PC_Constants.HCO_RecordType LIMIT 1)
                            FROM Case
                            WHERE Id IN: caseIds
                            WITH SECURITY_ENFORCED
                            LIMIT 1
                    ];
                }
            }
            System.debug('CaseList---'+caseList);
            //Getting the physician for a case
            Set<Id> physicianIds = new Set<Id>();
            if (caseList.size() > 0) {
                for (Case eachCase : caseList) {
                    if (eachCase.PC_Physician__c!= null) {
                        physicianIds.add(eachCase.PC_Physician__c);
                    }
                }
            }
            if (physicianIds.size() > 0) {
                //SOQL to fetch the Physician details
                providerDetails = [
                        SELECT PC_First_Name__c,PC_Last_Name__c,PC_NPI__c, HealthCloudGA__TaxId__c, (SELECT PC_Address_1__c,PC_Address_2__c,PC_City__c,PC_State__c,PC_Zip_Code__c FROM Addresses__r WHERE PC_Primary_Address__c = true)
                        FROM Account
                        WHERE Id IN:physicianIds
                        WITH SECURITY_ENFORCED
                        LIMIT 1
                ];
            }
            // SOQL query to fetch all case products
            if (caseList.size() > 0) {
                if(objType== PC_Constants.PC_CASEPRODUCT) {
                    caseProductList = [
                            SELECT Id, PC_Product__c, PC_Product__r.Name,PC_Product__r.ProductCode, PC_Product__r.PC_CPT_Codes__c
                            FROM PC_CaseProduct__c
                            WHERE Id = :sourceRecordId
                            WITH SECURITY_ENFORCED
                    ];
                }else {
                    caseProductList = [
                            SELECT Id, PC_Product__c, PC_Product__r.Name,PC_Product__r.ProductCode, PC_Product__r.PC_CPT_Codes__c
                            FROM PC_CaseProduct__c
                            WHERE PC_Case__c = :caseList[0].Id
                            WITH SECURITY_ENFORCED
                    ];
                }
            }
            System.debug('Case Products--- '+caseProductList);
            //  The case practice details i.e. HCO via Association
            if(caseList!=null && caseList.size()>0){
                List<String> hcoAccountIds= new List<String>();
                for(Case eachCase:caseList) {
                    for (PC_Association__c association : eachCase.Associations__r) {
                        hcoAccountIds.add(association.PC_Account__c);
                    }
                }
                if(hcoAccountIds!=null && !hcoAccountIds.isEmpty()){
                    hcoAccountList= [SELECT PC_First_Name__c,PC_Last_Name__c,PC_NPI__c, HealthCloudGA__TaxId__c,
                    (SELECT PC_Address_1__c,PC_Address_2__c,PC_City__c,PC_State__c,PC_Zip_Code__c FROM Addresses__r WHERE PC_Primary_Address__c = true)
                    FROM Account
                    WHERE Id IN:hcoAccountIds
                    WITH SECURITY_ENFORCED
                    LIMIT 1   ];
                }
            }

            if (caseList.size() > 0) {
                // SOQL query to fetch account record details
                patientDetails = [
                        SELECT Id, PC_First_Name__c, PC_Last_Name__c, PC_Date_of_Birth__c, (SELECT PC_Address_1__c,PC_Address_2__c,PC_City__c,PC_State__c,PC_Zip_Code__c FROM Addresses__r WHERE PC_Primary_Address__c = true)
                        FROM Account
                        WHERE Id = :caseList[0].AccountId
                        WITH SECURITY_ENFORCED
                        LIMIT 1
                ];
                //SOQL to get all the health/member plans associated with the Patient account
                if (patientDetails != null && patientDetails.size() > 0) {
                    if(requestType== BITaskType.INF_TASK_TYPE_PHARMACY_BENEFIT_MANAGER){
                        //Pharmacy Health Plans
                        Id pharmacyHealthPlanRecord = PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_PHARMACY_PLAN_RECORD_TYPE);
                        List<Account> accountHealthPlans = [
                                SELECT (
                                        SELECT Id, Name, PC_Plan_Name__c, PC_Payer__r.Phone,PC_Payer__r.Name, Patient__c
                                        FROM Health_Plans__r
                                        WHERE RecordTypeId = :pharmacyHealthPlanRecord
                                        AND PC_Plan_Status__c =: PC_Constants.ACTIVE
                                )
                                FROM Account
                                WHERE Id IN:patientDetails
                                WITH SECURITY_ENFORCED
                        ];
                        for (Account acc : accountHealthPlans) {
                            if (acc.Health_Plans__r != null) {
                                for (PC_Health_Plan__c healthPlan : acc.Health_Plans__r) {
                                    System.debug('Pharmacy HP--'+healthPlan);
                                    pharmacyHealthPlans.add(healthPlan);//list of pharmacy health plan records
                                }
                            }
                        }
                    }else if(requestType== BITaskType.INF_TASK_TYPE_BENEFITS_VERIFICATION){
                        //Medical Health Plans
                        Id medicalHealthPlanRecord = PC_SYSTEM.recordTypeId(PC_Constants.PC_HEALTH_PLAN, PC_Constants.HEALTH_PLAN_MEDICAL_RECORD_TYPE);
                        List<Account> accountHealthPlans = [
                                SELECT (
                                        SELECT Id, Name, PC_Plan_Name__c, PC_Payer__r.Phone,PC_Payer__r.Name, Patient__c
                                        FROM Health_Plans__r
                                        WHERE RecordTypeId = :medicalHealthPlanRecord
                                        AND PC_Plan_Status__c =: PC_Constants.ACTIVE
                                )
                                FROM Account
                                WHERE Id IN:patientDetails
                                WITH SECURITY_ENFORCED
                        ];

                        for (Account acc : accountHealthPlans) {
                            if (acc.Health_Plans__r != null) {
                                for (PC_Health_Plan__c healthPlan : acc.Health_Plans__r) {
                                    System.debug('Med HP--'+healthPlan);
                                    medicalHealthPlans.add(healthPlan);//list of medical health plan records
                                }
                            }
                        }
                    }
                }
            }
           List<Tasks>tasksList = new List<Tasks>();
            // Iterate using Member/Health Plans of Pharmacy type to create Tasks wrapper by passing member, provider, product, payer, practice information for Task
            if(pharmacyHealthPlans!=null && !pharmacyHealthPlans.isEmpty()) {
                for (PC_Health_Plan__c healthPlan : pharmacyHealthPlans) {
                    System.debug('TaskDetails-->' + patientDetails + '-----' + providerDetails + '------' + caseProductList + '----' + healthPlan);
                    Tasks eachTask = new Tasks(patientDetails, providerDetails, caseProductList, healthPlan,hcoAccountList, requestType.name());
                    tasksList.add(eachTask);
                }
                this.tasks = tasksList;
            }else if(medicalHealthPlans!= null && !medicalHealthPlans.isEmpty()) {
                // Iterate using Member/Health Plans of Medical type to create Tasks wrapper by passing member, provider, product, payer, practice information for Task
                for (PC_Health_Plan__c healthPlan : medicalHealthPlans) {
                    System.debug('TaskDetails-->' + patientDetails + '-----' + providerDetails + '------' + hcoAccountList + '------' + caseProductList + '----' + healthPlan);
                    Tasks eachTask = new Tasks(patientDetails, providerDetails, caseProductList, healthPlan,hcoAccountList, requestType.name());
                    tasksList.add(eachTask);
                }
                this.tasks = tasksList;
            }
        }
    }
    public class Tasks {
        public String customerId;
        public String customerUrl;
        public String programId;
        public String webhookUrl;
        public WebhookBasicAuth webhookBasicAuth;
        public String taskType;
        public BvTaskInput bvTaskInput;
        public PbmTaskInput pbmTaskInput;
        public List<PreviousBvResults> previousBvResults;

        public Tasks(List<Account> patients, List<Account> providers,List<PC_CaseProduct__c> caseProducts, PC_Health_Plan__c healthPlan,List<Account> hco, String taskType){
            this.customerId = healthPlan.Id;
            this.taskType= taskType;
            this.webhookUrl=PC_SYSTEM.getIntegrationSetting('PC_InfinitusCallbackURL', '');//Setting the endpoint URL.
            if (String.isBlank(webhookUrl)) {
                PC_eBenefits2.eBenefits2Exception ex = new PC_eBenefits2.eBenefits2Exception();
                ex.setMessage(System.Label.PC_InfinitusCallbackURL_Missing);
                throw ex;
            }
            this.webhookBasicAuth= new WebhookBasicAuth();
            // Task creation depending on the task type
            if(taskType== BITaskType.INF_TASK_TYPE_PHARMACY_BENEFIT_MANAGER.name()){
                this.pbmTaskInput = new PbmTaskInput(patients, providers, caseProducts, healthPlan);
                System.debug('P-B-M-'+this.pbmTaskInput);
            }else if (taskType== BITaskType.INF_TASK_TYPE_BENEFITS_VERIFICATION.name()){
                this.bvTaskInput= new BvTaskInput(patients, providers,hco, caseProducts, healthPlan);
                System.debug('B-V-'+this.bvTaskInput);
            }
        }
    }
    public class WebhookBasicAuth {
        public String username=PC_Constants.NA;
        public String password=PC_Constants.NA;
        public WebhookBasicAuth(){
            this.username=username;
            this.password=password;
        }
    }
    public class Payer {
        public String infinitusPayerId;
        public String customerPayerName;
        public String customerPayerPhoneNumber;
        public String subscriberId;
        public String groupId;
        public String groupName;
        public String planName;

        public Payer(PC_Health_Plan__c healthPlan) {
            // Todo get infinitus payer id
            this.infinitusPayerId = '7b38f3ff-ccc8-47c8-8659-0629a9d1436d';
            if(healthPlan!=null) {
                this.subscriberId = healthPlan.Patient__c;
                this.customerPayerName = healthPlan.PC_Payer__r.Name;
                this.customerPayerPhoneNumber = healthPlan.PC_Payer__r.Phone;
            }
        }
    }

    public class Products {
        public String code;
        public String name;

        public Products(PC_CaseProduct__c caseProduct) {
            if(caseProduct != null) {
                this.code = caseProduct.PC_Product__r.ProductCode;
                this.name = caseProduct.PC_Product__r.Name;
            }
        }
    }
    public class Provider {
        public String firstName;
        public String lastName;
        public String npi;
        public String taxId;
        public String networkStatus=providerNetworkStatus.INF_INPUT_NETWORK_STATUS_UNKNOWN.name();
        public Address address;

        public Provider(Account providerAccount){
            if(providerAccount != null){
                this.firstName= providerAccount.PC_First_Name__c;
                this.lastName= providerAccount.PC_Last_Name__c;
                this.npi= providerAccount.PC_NPI__c;
                this.taxId=providerAccount.HealthCloudGA__TaxId__c;
                this.networkStatus=networkStatus;
                this.address= new Address(providerAccount.Addresses__r);
            }
        }
    }
    public class Address {
        public String streetAddress;
        public String streetAddressLine2;
        public String city;
        public String state;
        public String zip;

        public Address(PC_Address__c address){
            if(address!=null)
            this.streetAddress= address.PC_Address_1__c;
            this.streetAddressLine2= address.PC_Address_2__c;
            this.city= address.PC_City__c;
            this.state= address.PC_State__c;
            this.zip= address.PC_Zip_Code__c;
        }
    }
    public class Member {
        public String firstName;
        public String lastName;
        public String dateOfBirth;
        public Address address;

        public Member(Account patient){
            this.firstName= patient.PC_First_Name__c;
            this.lastName= patient.PC_Last_Name__c;
            this.dateOfBirth= String.valueOf(patient.PC_Date_of_Birth__c);
            this.address= new Address(patient.Addresses__r);
        }
    }
    public class PbmTaskInput {
        public Member member;
        public Provider provider;
        public List<Products> products;
        public List<Cpt> diagnosis;
        public Payer payer;

        public PbmTaskInput(List<Account> patients, List<Account> providers,List<PC_CaseProduct__c> caseProducts,PC_Health_Plan__c healthPlan){
            this.member = new Member(patients[0]);
            this.provider = new Provider(providers[0]);
            this.payer= new payer(healthPlan);
            List<Products> productList= new List<Products>();
            for(PC_CaseProduct__c caseProduct: caseProducts) {
              Products eachProduct= new Products(caseProduct);
               productList.add(eachProduct);
            }
            this.products= productList;
        }
    }

    public class BvTaskInput {
        public Member member;
        public Practice practice;
        public Provider provider;
        public List<Products> products;
        public List<Cpt> cpt;
        public List<Object> diagnosis;
        public Payer payer;
        public PlaceOfService placeOfService;
        public BvTaskInput(List<Account> patients, List<Account> providers,List<Account> hcoAccounts,List<PC_CaseProduct__c> caseProducts,PC_Health_Plan__c healthPlan){
            this.member = new Member(patients[0]);
            this.provider = new Provider(providers[0]);
            this.payer= new Payer(healthPlan);
            this.practice= new Practice(hcoAccounts[0]);
            List<Products> productList= new List<Products>();
            List<Cpt> cptList= new List<Cpt>();
            List<String>cptStrings= new List<String>();
            for(PC_CaseProduct__c caseProduct: caseProducts) {
                Products eachProduct= new Products(caseProduct);
                productList.add(eachProduct);
                if(caseProduct.PC_Product__r.PC_CPT_Codes__c !=null) {
                    cptStrings = caseProduct.PC_Product__r.PC_CPT_Codes__c .split(';');
                    for (String cptString : cptStrings) {
                        Cpt cptCode = new Cpt(cptString);
                        cptList.add(cptCode);
                    }
                }
            }
            this.products= productList;
            this.cpt=cptList;
            String facilityType= FacilityType.INF_FACILITY_TYPE_HOSPITAL_OUTPATIENT.name();
            this.placeOfService=new PlaceOfService(facilityType);
        }
    }

    public class Cpt {
        public String code;
        public Cpt(String codeString){
            this.code=codeString;
        }
    }

    public class Practice {
        public String name;
        public String npi;
        public String taxId;
        public Address address;
        public Practice(Account HCO){
            this.name= HCO.PC_First_Name__c;
            this.npi= HCO.PC_NPI__c;
            this.taxId=HCO.HealthCloudGA__TaxId__c;
            this.address= new Address(HCO.Addresses__r);
        }
    }

    public class PlaceOfService {
        public String facilityType;
        public Boolean specialtyPharmacyInfoRequired;
        public String treatmentDate;
        public PlaceOfService(String facilityType){
            this.facilityType= facilityType;
        }
    }

    public class OfficeBenefits {
        public Integer copay;
        public Integer coinsurance;
        public Boolean alwaysApplies;
        public Boolean deductibleApplies;
        public String additionalNotes;
    }

    public class ErrorInfo {
        public String failureReason;
    }

    public class PlanInfo {
        public String providerNetworkStatus;
        public String planType;
        public String planName;
        public String planGroupNumber;
        public String planGroupName;
        public Boolean isCobraPlan;
        public String cobraPaidThroughDate;
        public Boolean cobraHasGracePeriod;
        public String cobraGracePeriod;
        public Boolean isHealthExchangePlan;
        public Boolean patientReceivesSubsidies;
        public String healthExchangePaidThroughDate;
        public Boolean healthExchangeHasGracePeriod;
        public String healthExchangeGracePeriod;
        public String policyType;
        public Boolean hasStandardPlanLetter;
        public String standardPlanLetter;
        public Boolean followsMedicareGuidelines;
        public Boolean otherInsuranceExists;
        public String otherInsuranceName;
        public String currentPlanPriority;
        public String coordinationOfBenefits;
        public Boolean willCoverIfPrimaryDenies;
        public Boolean willCoverPartBDeductible;
        public String planEffectiveDate;
        public String planRenewalMonth;
        public String renewalType;
        public String fundingType;
        public String planTerminationDate;
        public String additionalNotes;
    }

    public class AccessInfo {
        public Boolean priorAuthRequired;
        public List<String> priorAuthRequiredCodes;
        public Boolean priorAuthOnFile;
        public String priorAuthStartDate;
        public String priorAuthEndDate;
        public String priorAuthApprovalNumber;
        public String obtainPriorAuthOrg;
        public String obtainPriorAuthPhone;
        public String obtainPriorAuthWebsite;
        public String obtainPriorAuthFax;
        public List<String> obtainPriorAuthRequirements;
        public String priorAuthTurnaroundTime;
        public String priorAuthResponsibleOrg;
        public String medicalGroupName;
        public String medicalGroupPhoneNumber;
        public Boolean preDeterminationRequired;
        public Boolean preDeterminationAvailable;
        public Boolean preDeterminationOnFile;
        public String preDeterminationNumber;
        public String obtainPreDeterminationOrg;
        public String obtainPredeterminationPhone;
        public String obtainPredeterminationWebsite;
        public String obtainPredeterminationFax;
        public String predeterminationTurnaroundTime;
        public Boolean stepTherapyRequired;
        public String stepTherapyMethod;
        public String stepTherapyTreatment;
        public String specialtyPharmacyAvailability;
        public String specialtyPharmacyName;
        public String specialtyPharmacyPhone;
        public Boolean hasSpecialtyPharmacyExclusions;
        public String specialtyPharmacyExclusions;
        public Boolean referralRequired;
        public Boolean referralOnFile;
        public String referralNumber;
        public String referralEffectiveDate;
        public String referralRecentDate;
        public String pcpName;
        public String pcpPhone;
        public String buyAndBillAvailability;
        public Address claimsAddress;
        public String additionalNotes;
    }
    /**
     * Wrapper for Medical Benefits Output fields
     */
    public class BvTaskOutput {
        public String payerAgentName;
        public String referenceNumber;
        public String additionalNotes;
        public String taskLink;
        public Boolean reviewRequired;
        public PlanInfo planInfo;
        public DeductiblesAndOops deductiblesAndOops;
        public List<ProductCodeBenefits> productCodeBenefits;
        public List<ProductCodeBenefits> cptCodeBenefits;
        public String reasonForNonCoverage;
        public OfficeBenefits officeBenefits;
        public AccessInfo accessInfo;
        public DenialInfo denialInfo;
        public ErrorInfo errorInfo;
        public String payerPhone;
        public String infinitusPayerId;
        public String chcControlNumber;
    }
    public class ProductCodeBenefits {
        public String code;
        public Boolean valid;
        public Integer copay;
        public Integer coinsurance;
        public Boolean deductibleApplies;
        public String additionalNotes;
    }

    public class DenialInfo {
        public String denialReason;
        public String denialDate;
        public Boolean peerToPeerAvailable;
        public Integer numberOfAppealsAvailable;
        public String appealsContactOrg;
        public String appealsContactPhone;
        public String appealsContactFax;
        public String appealsSubmissionDeadline;
        public String appealsRequiredDocuments;
        public String appealsTurnaroundTime;
        public String additionalNotes;
    }

    public class PreviousBvResults {
        public String taskId;
        public BvTaskOutput bvTaskOutput;
    }

    public class DeductiblesAndOops {
        public Boolean individualDeductibleExists;
        public Integer individualTotalDeductible;
        public Integer individualDeductibleMetAmount;
        public Boolean spendDownExists;
        public Integer spendDownTotal;
        public Integer spendDownMet;
        public Boolean familyDeductibleExists;
        public Integer familyTotalDeductible;
        public Integer familyDeductibleMetAmount;
        public Boolean individualOopMaximumExists;
        public Integer individualOopMaximum;
        public Integer individualOopMetAmount;
        public Boolean familyOopMaximumExists;
        public Integer familyOopMaximum;
        public Integer familyOopMetAmount;
        public Boolean deductibleIncludedInOop;
        public Boolean copayAppliesToOop;
        public Boolean copayWaivedAfterOop;
        public Boolean multipleCopayResponsibility;
        public Boolean lifetimeMaximumExists;
        public Integer lifetimeMaximum;
        public Integer lifetimeMaximumMetAmount;
        public Boolean annualBenefitCapExists;
        public Integer annualBenefitCap;
        public Integer annualBenefitCapMetAmount;
        public String additionalNotes;
    }
    /**Wrapper for Infinitus BI Response
     *
     */
    public class InfinitusBIResponse {
        public List<Data> data;
        public String message;
    }

    public static InfinitusBIResponse parseInfinitusBIResponse(String json) {
        return (InfinitusBIResponse) System.JSON.deserialize(json, InfinitusBIResponse.class);
    }

    public class Error {
        public String errorCode;
        public String errorMessage;
    }
    /**Data wrapper includes the Infinitus basic response as well as callback fields
     *
     */
    public class Data {
        public String customerId;
        public Error error;
        public String programId;
        public String taskId;
        public PbmTaskOutput pbmTaskOutput;
        public BvTaskOutput bvTaskOutput;
        public String taskCompletionDate;
        public String taskCreationDate;
        public String taskStatus;
        public String taskType;
    }

    /**
     * Wrapper for Infinitus Callback Data
     */
    public class InfinitusBICallback {
        public List<Data> data;
    }

    public static InfinitusBICallback parseInfinutusCallback(String json) {
        return (InfinitusBICallback) System.JSON.deserialize(json, InfinitusBICallback.class);
    }
    /**
     * Wrapper for Pharmacy Benefits Output fields
     */
    public class PbmTaskOutput {
        public AccessInfo accessInfo;
        public PlanInfo planInfo;
        public DeductiblesAndOops deductiblesAndOops;
        public ErrorInfo errorInfo;
        public String payerAgentName;
        public String payerPhone;
        public String pbmName;
        public String additionalNotes;
        public List<ProductCoverage> productCoverage;
        public String referenceNumber;
        public Object reviewRequired;
        public String taskLink;
    }

    public class ProductCoverage {
        public String code;
        public Boolean isProductCovered;
        public Integer specialtyPharmacyCoinsurance;
        public Integer specialtyPharmacyCopay;
        public Object isProductCoveredMailOrder;
        public Object isProductCoveredRetail;
        public Object mailOrderPharmacyCoinsurance;
        public Object mailOrderPharmacyCopay;
        public Object retailPharmacyCoinsurance;
        public Object retailPharmacyCopay;
    }

}