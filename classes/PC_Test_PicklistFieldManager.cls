/*********************************************************************************
  Class Name      : PC_Test_PicklistFieldManager
  Description     : This test class for PC_PicklistFieldManager
  Created By      : Deloitte
  Created Date    : July 12, 2017
  Modification Log:
  ----------------------------------------------------------------------------------
  Developer                   Date                   Description
  -----------------------------------------------------------------------------------
  Mike Klumpenaar             2017-07-12             PC-1885 Tests for new methods
  Mike Klumpenaar             2017-08-10             PC-2007 Updated picklistFieldMap test with additional dependent picklist fields.
  Vivek Kumar Mishra          2018-06-05             PC-2982 Added test for new method PC_PicklistFieldManager.picklistRecordTypeFieldList
  Vijay Kashikar              2018-03-27             PC-4666 Handled System.Visualforce thrown when Methods defined as TestMethod cannot support getContent call
 *********************************************************************************/

@IsTest
private class PC_Test_PicklistFieldManager {
    @IsTest
    static void testPicklistFieldMap() {
        Test.startTest();
        List<PC_PicklistFieldManager.PicklistEntryWrapper> fields = PC_PicklistFieldManager.getPicklistEntryWrappers(PC_Address__c.PC_Country__c);
        Map<String, List<PC_PicklistFieldManager.PicklistEntryWrapper>> myPicklistFieldMap =
                PC_PicklistFieldManager.picklistFieldMap(PC_Address__c.PC_Country__c, PC_Address__c.PC_State__c);
        System.assertEquals(fields.size(), myPicklistFieldMap.size());
        System.assertNotEquals(myPicklistFieldMap.size(), 0); //Added Tejas-Patel; 12-Apr-2017

        fields = PC_PicklistFieldManager.getPicklistEntryWrappers(Account.Type);
        myPicklistFieldMap = PC_PicklistFieldManager.picklistFieldMap(Account.Type, Account.Industry);
        System.assertEquals(fields.size(), myPicklistFieldMap.size());
        System.assertNotEquals(myPicklistFieldMap.size(), 0); //Added Tejas-Patel; 12-Apr-2017

        try {
            Map<String, String> myPicklistFieldList = PC_PicklistFieldManager.picklistRecordTypeFieldList(PC_Document__c.PC_EngagementProgramCode__c,
                    PC_Document__c.PC_Document_Category__c, PC_Constants.getQualifiedAPIName('PC_Document__c'),
                    getDefaultRecordType(), PC_Constants.PICKLIST_NONE_VAL);
            System.assert(!myPicklistFieldList.isEmpty(), 'Picklist has entries');
        } catch (System.VisualforceException ex) {
            system.assert(true, 'This was expected since Methods defined as TestMethod do not support getContent call');
        }
        catch(Exception ex) {
            system.assert(false, 'Something went wrong while fetching the picklist entries');
        }
        Test.stopTest();
    }

    static Id getDefaultRecordType() {
        Schema.DescribeSObjectResult dsr = PC_Document__c.SObjectType.getDescribe();
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