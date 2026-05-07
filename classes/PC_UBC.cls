/**
 * Created by vkashikar on 4/17/2018.
 * Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Vijay Kashikar               April 17, 2018              Initial Version
Shishir Bansal               July 18,2018                Adding Country attribute to MemberAddress
Vijay Kashikar         		 Sep 06, 2018                Make service responses to be available as part of global response objects
Shishir Bansal               OCt 09,2018                 Adding ncpdp parameter to the pharmacy class
Vijay Kashikar               Sep 25,2018                 [PC-3629] Created a new property to hold the time when the pharmacy card response was generated. i.e EligibilityServiceResponse.requestDate
Haritha Reddy                21-Jan-2021                 [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************************************/


public with sharing class PC_UBC {
    public static final String COVERAGE_ALERT_PA_Required = 'PriorAuthRequired';
    public static final String SERVICE_RESPONSE_ELIGIBILITY= 'eligibility';
    public static final String SERVICE_RESPONSE_PLAN= 'plan';
    public static final String SERVICE_RESPONSE_RTBC= 'RTBC';
    public inherited sharing class PBMSWrapper {
         public String id { get; set; }
         public List<Plan> plans { get; set; }
         public String pbmStatusMessage { get; set; }
         public String name { get; set; }
    }
    public inherited sharing class Plan {
         public String id {get; set;}
         public List<OutOfPocketRange> outOfPocketRanges {get; set;}
         public List<Coverage> coverage {get; set;}
         public Boolean isPriorAuthorizationRequired {get; set;}
         public String name {get; set;}
         public Insurance insurance {get; set;}
         public MemberInfo memberInfo {get; set;}
    }
    public inherited sharing class OutOfPocketRange {
        //public string id;
    }
    public inherited sharing class Coverage {
         public String id {get; set;}
         public Boolean isCovered {get; set;}
         public String pharmacyType {get; set;}
    }
    public inherited sharing class Insurance {
         public string id {get; set;}
         public string familyUnitNumber {get; set;}
         public string planNumber {get; set;}
         public boolean isEsi {get; set;}
         public string bin {get; set;}
         public string pcn {get; set;}
         public string participantId {get; set;}
         public string policyId {get; set;}
         public insuranceGroup insuranceGroup {get; set;}
    }
    public inherited sharing class InsuranceGroup {
         public String id {get; set;}
         public String name {get; set;}
         public String groupId {get; set;}
    }
    public inherited sharing class MemberInfo {
         public String id {get; set;}
         public MemberAddress address {get; set;}
         public String birthdate {get; set;}
         public String lastName {get; set;}
         public String gender {get; set;}
         public String firstName {get; set;}
         public Boolean changeFlag {get; set;}
         public String relationship {get; set;}
         public String memberId {get; set;}

    }
    public inherited sharing class MemberAddress {
         public String id {get; set;}
         public String postalCode {get; set;}
         public String state {get; set;}
         public String city {get; set;}
         public String type {get; set;}
         public String addressOne {get; set;}
        public String latitude {get; set;}
        public String longitude {get; set;}
        public String country {get;set;}
    }

    public inherited sharing class PlanNameServiceResponse {
        public String logoUri{get;set;}
        public String url{get;set;}
        public String description{get;set;}
        public String phone{get;set;}
        public List<AdditionalIds> additionalIds{get;set;}
        public String abbreviatedName{get;set;}
        public String id{get;set;}
        public String name{get;set;}
        public String serviceLevel {get;set;}
        public String payerID {get;set;}
        public String serviceResponse {get; set;}
    }
    public inherited sharing class AdditionalIds{
        public String issuedId{get;set;}
        public String id{get;set;}
        public String authority{get;set;}
    }


    public inherited sharing class EligibilityServiceResponse {
         public String id {get; set;}
         public List<PBMSWrapper> pbms {get; set;}
         public String message {get; set;}
         public String isError {get; set;}
         public Product product {get; set;}
         public ResponseStatus responseStatus {get; set;}
         public  Map<String, String[]> modelState {get; set;}
         public String serviceResponse {get; set;}
         public Map<String, String> allServiceResponses;
         public String requestDate {get; set;} // JSON date format

    }



    public inherited sharing class Product {
         public string issueId {get; set;}
         public string authority {get; set;}
         public string ndc {get; set;}
         public string name {get; set;}
         public string label {get; set;}
         public string unitOfMeasureCode {get; set;}
         public string drugDbSourceCode {get; set;}
         public string productCodeQualifier {get; set;}
         public string codeListQualifier {get; set;}
    }
    public inherited sharing class ResponseStatus {
         public double statusCode {get; set;}
         public string ownerId {get; set;}
         public boolean isError {get; set;}
         public string internalMessage {get; set;}
    }


    // EBenefitsServiceResponse
    public inherited sharing class PharmacyCoverageServiceResponse{
         public Pharmacy pharmacy{get;set;}
         public Decimal metricQuantityPriced{get;set;}
         public String quantityPricedUnitOfMeasurementCode{get;set;}
         public Integer daysSupplyPriced{get;set;}
         public Accumulators accumulators{get;set;}
         public Card card{get;set;}
         public Pricing pricing{get;set;}
         public Prescription prescription{get;set;}
         public List<CoverageAlerts> coverageAlerts{get;set;}
         public Prescriber prescriber{get;set;}
         public String id{get;set;}
         public Patient patient{get;set;}
         public Boolean isPriorAuthRequired {get;set;}
         public ResponseStatus responseStatus {get; set;}
         public  Map<String, String[]> modelState {get; set;}
         public String serviceResponse;
         public Map<String, String> allServiceResponses;
    }
    public inherited sharing class Pricing{
         public Decimal patient{get;set;}
         public String patientInDollarFormat{get;set;}
         public Decimal plan{get;set;}
         public String planInDollarFormat{get;set;}
    }
    public inherited sharing class Prescription{
         public Product product{get;set;}
         public String daysSupply{get;set;}
         public String quantity{get;set;}
         public Boolean includeHomeDelivery{get;set;}
         public Boolean includeDrugAlternativePricing{get;set;}
         public Boolean include90DaysRetail{get;set;}
    }
    public inherited sharing class Prescriber{
         public String issuedId{get;set;}
         public String authority{get;set;}
         public String npi{get;set;}
    }
    public inherited sharing class Pharmacy{
         public String identifier{get;set;}
         public String authority{get;set;}
         public String issuedId{get;set;}
         public String type{get;set;}
         public List<String> pharmacyType{get;set;}
         public String npi{get;set;}
         //public String ncpdpid{get;set;}
        public String ncpdp{get;set;}
         public String name{get;set;}
         public String phone{get;set;}
        public String fax{get;set;}
        public String specialtyType {get; set;}
        public String id {get; set;}
        public List<MemberAddress> addresses {get; set;}
    }
    public inherited sharing class Patient{
         public String issuedId{get;set;}
         public String birthdate{get;set;}
         public String authority{get;set;}
         public String lastName{get;set;}
         public String firstName{get;set;}
         public String gender{get;set;}
         public MemberAddress address{get;set;}
    }
    public inherited sharing class OutOfPocket{
         public Individual individual{get;set;}
    }
    public inherited sharing class Individual{
         public Decimal remaining{get;set;}
         public String remainingInDollarCurrency{get; set;}
         public Decimal applied{get;set;}
         public String appliedInDollarCurrency{get; set;}
    }
    public inherited sharing class Deductible{
         public Individual individual{get;set;}
    }
    public inherited sharing class Refills{
         public Individual individual{get;set;}
    }
    public inherited sharing class CoverageAlerts{
         public String id{get;set;}
         public String name{get;set;}
         public String description{get;set;}
    }
    public inherited sharing class Card{
         public String issuedId{get;set;}
         public String authority{get;set;}
         public String pbmMemberId{get;set;}
         public String memberId{get;set;}
         public String groupId{get;set;}
    }
    public inherited sharing class Accumulators{
         public Deductible deductible{get;set;}
         public OutOfPocket outOfPocket{get;set;}
         public Refills refills{get;set;}
    }

    // eBenefitsServiceInput
    public inherited sharing class PharmacyCoverageServiceInput {
        public List<AdditionalIds> additionalIds{get;set;}
        public Prescriber prescriber{get;set;}
        public Prescription prescription{get;set;}
        public Card card{get;set;}
        public Pharmacy pharmacy{get;set;}
        public Pricing pricing{get;set;}
        public Accumulators accumulators{get;set;}
        public List<String> coverageAlerts{get;set;}
        // to get the prior Authentication on UI
        public Boolean isPriorAuthorizationRequired {get; set;}
        public String ninetyDayPricing{get;set;}
        public String id{get;set;}
        public Patient patient{get;set;}

    }
}