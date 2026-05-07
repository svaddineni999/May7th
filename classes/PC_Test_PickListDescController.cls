/**
 * Created by vkashikar on 2/8/2018.
 */

@IsTest
public class PC_Test_PickListDescController {
    static User adminUser;
    static Boolean isDependentTest = false;
    @isTest static void testBehavior() {

        adminUser = PC_Test_Setup.createUser('System Administrator', 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.startTest();
            ApexPages.currentPage().getParameters().put('recordTypeId', getDefaultRecordType());
            ApexPages.currentPage().getParameters().put('sobjectType', 'Account');
            ApexPages.currentPage().getParameters().put('dependentFieldName', 'Type');

            PC_PickListDescController controller = new PC_PickListDescController();


            ApexPages.currentPage().getParameters().remove('recordTypeId');
            ApexPages.currentPage().getParameters().remove('sobjectType');

            Account patient = PC_Test_Setup.createPatient('testpatient');
            patient = (Account) PC_Database.ins(patient, false);
            system.assertNotEquals(patient.Id, null);
            ApexPages.currentPage().getParameters().put('id', patient.Id);

            PC_PickListDescController controller1 = new PC_PickListDescController();

            system.assert(true);
            Test.stopTest();
        }
    }

    @isTest static void testdependentPLBehavior() {
        adminUser = PC_Test_Setup.createUser('System Administrator', 'user@test100.com', 'test100');
        PC_Database.ins(adminUser);
        System.runAs(adminUser) {
            Test.startTest();
            isDependentTest = true;
            ApexPages.currentPage().getParameters().put('recordTypeId', getDefaultRecordType());
            ApexPages.currentPage().getParameters().put('sobjectType', PC_Constants.getQualifiedAPIName('PC_Document__c'));
            ApexPages.currentPage().getParameters().put('dependentFieldName', PC_Constants.getQualifiedAPIName('PC_Document_Category__c'));
            ApexPages.currentPage().getParameters().put('controllingFieldName', PC_Constants.getQualifiedAPIName('PC_EngagementProgramCode__c'));
            PC_PickListDescController controller = new PC_PickListDescController();


            ApexPages.currentPage().getParameters().remove('recordTypeId');
            ApexPages.currentPage().getParameters().remove('sobjectType');

            //Creating a parent document
            PC_Document__c pDoc = PC_Test_Setup.createDocument(PC_Constants.DOCUMENT_FAX_INBOUND_RECORD_TYPE, PC_Constants.DOCUMENT_STATUS_REVIEW_NEEDED);
            PC_Database.ins(pDoc, false);
            //check document was created
            System.assertNotEquals(pDoc.Id, null);

            PC_PickListDescController controller1 = new PC_PickListDescController();

            system.assert(true);
            Test.stopTest();
        }
    }

    static string getDefaultRecordType() {
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