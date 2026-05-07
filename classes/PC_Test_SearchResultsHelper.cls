/*********************************************************************************************************
Class Name      : PC_Test_SearchResultsHelper
Description     : Tests PC_SearchResultsHelper class
Created By      : Vijay Kashikar
Created Date    : Oct 19, 2019
Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                           Description
-----------------------------------------------------------------------------------------------------
Vijay Kashikar              10/19/2019                    Initial Version
Kanteti Kishore             13-Dec-2019                 [PC-5795] Updated search method signature
*********************************************************************************************************/
@IsTest(SeeAllData=false)
public with sharing class PC_Test_SearchResultsHelper {
    public with sharing class TestMockResults implements PC_SearchResults.SearchProcessor {
        public PC_SearchResults.SearchResult getResults(String identifier, List<PC_SearchResults.SearchParam> searchParams,
                String referenceObjectAPIName, String referenceResultFieldSetAPIName) {
            return null;
        }
    }

    static final Integer count = 2;
    @testSetup static void setup() {
        // Create common test  data
        List<Account> accounts = PC_Test_Setup.createAccounts('test', count, PC_Constants.PATIENT_RECORD_TYPE);
        accounts[0].PC_First_Name__c = 'test';
        accounts[0].PC_Last_Name__c = 'test';
        PC_Database.ins(accounts);

    }
    @isTest static void testIncorrectResultClass() {
        User adminUser;
        // running as system admin
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            List<Account> accounts = [Select Id from Account];

            String fieldSetName = PC_Constants.getQualifiedAPIName('PC_SearchForm');
            Map<String, String> params = new Map<String, String>();
            params.put(PC_Constants.getQualifiedAPIName('PC_First_Name__c'),'test');
            try {
                Map<String,String> searchDetails = new Map<String, String>();
                searchDetails.put('identifier', 'PC_PatientSearch');
                searchDetails.put('searchObjectAPIName', 'Account');
                searchDetails.put('searchFormFieldsetAPIName',fieldSetName);
                searchDetails.put('searchResultFieldsetAPIName', fieldSetName);
                searchDetails.put('searchParamsJSON', JSON.serialize(params));
                searchDetails.put('resultClass',  PC_Constants.OrgNamespace + '.PC_INVALID');

                PC_SearchResults.SearchResult searchResult = PC_SearchResultsHelper.search(searchDetails);
            }
            catch(Exception ex) {
                system.assert(true); // this is expected
            }
            Test.stopTest();
        }
    }
    @isTest static void testIncorrectFieldSet() {
        User adminUser;
        // running as system admin
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            List<Account> accounts = [Select Id from Account];

            String fieldSetName = PC_Constants.getQualifiedAPIName('PC_SearchForm1');
            Map<String, String> params = new Map<String, String>();
            params.put(PC_Constants.getQualifiedAPIName('PC_First_Name__c'),'test');
            try {
                Map<String,String> searchDetails1 = new Map<String, String>();
                searchDetails1.put('identifier', 'PC_PatientSearch');
                searchDetails1.put('searchObjectAPIName', 'Account');
                searchDetails1.put('searchFormFieldsetAPIName',fieldSetName);
                searchDetails1.put('searchResultFieldsetAPIName', fieldSetName);
                searchDetails1.put('searchParamsJSON', JSON.serialize(params));
                searchDetails1.put('resultClass',  PC_Constants.OrgNamespace + '.PC_GetSearchResults');

                PC_SearchResults.SearchResult searchResult = PC_SearchResultsHelper.search(searchDetails1);
            }
            catch(Exception ex) {
                system.assert(true); // this is expected
            }
            Test.stopTest();
        }
    }
    @isTest static void testWithNoFieldSet() {
        User adminUser;
        // running as system admin
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            List<Account> accounts = [Select Id from Account];

            //String fieldSetName = PC_Constants.getQualifiedAPIName('PC_SearchForm1');
            String fieldSetName = ''; // This is the test case
            Map<String, String> params = new Map<String, String>();
            params.put(PC_Constants.getQualifiedAPIName('PC_First_Name__c'),'test');
            try {
                Map<String,String> searchDetails1 = new Map<String, String>();
                searchDetails1.put('identifier', 'PC_PatientSearch');
                searchDetails1.put('searchObjectAPIName', 'Account');
                searchDetails1.put('searchFormFieldsetAPIName',fieldSetName);
                searchDetails1.put('searchResultFieldsetAPIName', fieldSetName);
                searchDetails1.put('searchParamsJSON', JSON.serialize(params));
                searchDetails1.put('resultClass',  PC_Constants.OrgNamespace + '.PC_GetSearchResults');

                PC_SearchResults.SearchResult searchResult = PC_SearchResultsHelper.search(searchDetails1);
            }
            catch(Exception ex) {
                system.assert(true); // this is expected
            }
            Test.stopTest();
        }
    }
    @isTest static void testBehavior() {
        User adminUser;
        // running as system admin
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            List<Account> accounts = [Select Id from Account];
            system.debug('Count of account = ' + accounts.size());

            Id [] fixedSearchResults= new Id[1];
            fixedSearchResults[0] = accounts[0].Id;
            Test.setFixedSearchResults(fixedSearchResults);
            // system assertion to test the created data
            System.assertEquals( (accounts.size() == count) , true);
            String fieldSetName = PC_Constants.getQualifiedAPIName('PC_SearchForm');
            Map<String, String> params = new Map<String, String>();
            params.put(PC_Constants.getQualifiedAPIName('PC_First_Name__c'),'test');

            Map<String,String> searchDetails2 = new Map<String, String>();
            searchDetails2.put('identifier', 'PC_PatientSearch');
            searchDetails2.put('searchObjectAPIName', 'Account');
            searchDetails2.put('searchFormFieldsetAPIName',fieldSetName);
            searchDetails2.put('searchResultFieldsetAPIName', fieldSetName);
            searchDetails2.put('searchParamsJSON', JSON.serialize(params));
            String orgNs = PC_Constants.OrgNamespace;
            String classPrefix = String.isEmpty(orgNs) ? '' : orgNs + '.';
            String getSearchResultClass =  classPrefix + 'PC_GetSearchResults';

            //String resultClasses = getSearchResultClass + ',' + mockResultClass;
            searchDetails2.put('resultClass', getSearchResultClass);
            searchDetails2.put('defaultRowActions', 'PC_SHOW_DETAILS,PC_LAUNCH_PAP,CUSTOM_ACTION');

            PC_SearchResults.SearchResult searchResult = PC_SearchResultsHelper.search(searchDetails2);
            system.debug(searchResult);
            system.assert(searchResult!=null, 'ERROR - Search result is null');
            system.assert(searchResult.rows.size() > 0, 'ERROR - no results are obtained');


            searchDetails2.remove('resultClass');
            String mockResultClass = classPrefix + 'PC_Test_SearchResultsHelper' +
                    '.' + 'TestMockResults';
            system.debug('**********');
            system.debug(mockResultClass);
            searchDetails2.put('resultClass', mockResultClass);
            PC_SearchResults.SearchResult searchResult2 = PC_SearchResultsHelper.search(searchDetails2);
            system.assert(searchResult2 == null, 'Success');


            Test.stopTest();


        }
    }
    @isTest static void testBehaviorWithoutShowDetailsRowAction() {
        User adminUser;
        // running as system admin
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.StartTest();
            List<Account> accounts = [Select Id from Account];
            system.debug('Count of account = ' + accounts.size());

            Id [] fixedSearchResults= new Id[1];
            fixedSearchResults[0] = accounts[0].Id;
            Test.setFixedSearchResults(fixedSearchResults);
            // system assertion to test the created data
            System.assertEquals( (accounts.size() == count) , true);
            String fieldSetName = PC_Constants.getQualifiedAPIName('PC_SearchForm');
            Map<String, String> params = new Map<String, String>();
            params.put(PC_Constants.getQualifiedAPIName('PC_First_Name__c'),'test');

            Map<String,String> searchDetails2 = new Map<String, String>();
            searchDetails2.put('identifier', 'PC_PatientSearch');
            searchDetails2.put('searchObjectAPIName', 'Account');
            searchDetails2.put('searchFormFieldsetAPIName',fieldSetName);
            searchDetails2.put('searchResultFieldsetAPIName', fieldSetName);
            searchDetails2.put('searchParamsJSON', JSON.serialize(params));
            String orgNs = PC_Constants.OrgNamespace;
            String classPrefix = String.isEmpty(orgNs) ? '' : orgNs + '.';
            String getSearchResultClass =  classPrefix + 'PC_GetSearchResults';

            //String resultClasses = getSearchResultClass + ',' + mockResultClass;
            searchDetails2.put('resultClass', getSearchResultClass);
            searchDetails2.put('defaultRowActions', 'PC_LAUNCH_PAP');

            PC_SearchResults.SearchResult searchResult = PC_SearchResultsHelper.search(searchDetails2);
            system.debug(searchResult);
            system.assert(searchResult!=null, 'ERROR - Search result is null');
            system.assert(searchResult.rows.size() > 0, 'ERROR - no results are obtained');

            Test.stopTest();


        }
    }
}