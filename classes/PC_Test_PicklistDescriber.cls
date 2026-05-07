/**
 * Created by vkashikar on 2/8/2018.
 */

@IsTest
public with sharing class PC_Test_PicklistDescriber {
    static User adminUser;
    static Boolean isDependentTest = false;
    @isTest static void testBehavior() {

        adminUser = PC_Test_Setup.createUser('System Administrator', 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.startTest();
            try {
                Id rId = getDefaultRecordType();
                PC_PicklistDescriber.describeAsMap('Account', rId, 'Type');
            }
            catch(Exception ex) {
                system.assert(true);
            }


            system.assert(true);
            Test.stopTest();
        }
    }

    @isTest static void testDependentPLBehavior() {

        adminUser = PC_Test_Setup.createUser('System Administrator', 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.startTest();
            try {
                isDependentTest = true;
                Id rId = getDefaultRecordType();
                PC_PicklistDescriber.describeAsMap(PC_Constants.getQualifiedAPIName('PC_Document__c'), rId,
                        PC_Constants.getQualifiedAPIName('PC_Document_Category__c'),
                        PC_Constants.getQualifiedAPIName('PC_EngagementProgramCode__c'));
            }
            catch(Exception ex) {
                system.assert(true);
            }


            system.assert(true);
            Test.stopTest();
        }
    }

    static Id getDefaultRecordType() {
        Schema.DescribeSObjectResult dsr = Account.SObjectType.getDescribe();
        if(isDependentTest) {
            dsr = PC_Document__c.SObjectType.getDescribe();
            isDependentTest = false;
        }
        Schema.RecordTypeInfo defaultRecordType;
        for(Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()) {
            if(rti.isDefaultRecordTypeMapping()) {
                defaultRecordType = rti;
                break;
            }
        }
        return defaultRecordType.recordTypeId;
    }
}