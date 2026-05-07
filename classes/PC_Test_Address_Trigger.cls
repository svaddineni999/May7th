/*********************************************************************************
Class Name      : PC_Test_Address_Trigger
Description     : This test class for Address trigger
Created By      : Deloitte
Created Date    : May 17, 2016
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Tetiana Danylyshyn         May 17, 2016              Initial Version
Tejas Patel				   July 12, 2017             PC-1875 ignore test if trigger is disabled in metadata
Mayuresh Patil             Nov 1, 2017               Removed test related to google map API to be replaced by salesforce geocoding
Shabda Bhujad              Dec 18, 2017              PC-1884 Updated the handler name for checking if the trigger is active.
Kishore Kanteti            Jun 28, 2019              PC-4926 Added test related mock for google map api Line-33.
Hitha Avalakki             Nov 18, 2021              PC-8338 Added code coverage for bulk address insertion logic
*********************************************************************************/
@isTest
public class PC_Test_Address_Trigger {

    private static User adminUser;
    private static final Integer OBJECTS_NUMBER = 20;
    private static final Integer OBJECT_NUMBER = 1;
    public static Boolean isTriggerActive = True;
    /*********************************************************************************
Method Name    : testMethodAddress
Author         : Deloitte
Description    : This method is used for testing address insert and update scenarios
Return Type    : void
Parameter      :
*********************************************************************************/
    @isTest
    static void testMethodAddress() {
        if(isTriggerActive){
            Test.setMock(HttpCalloutMock.class, new PC_Test_MockHttpMapAddressGenerator ());
            adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser, false);
            List<Account> patientAccounts = PC_Test_Setup.createAccounts('Patient', OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
            PC_Database.ins(patientAccounts);
            List<PC_Address__c> patientAddresses = PC_Test_Setup.createAddresses(patientAccounts, OBJECTS_NUMBER, false);
            system.runAs(adminUser) {
                Test.StartTest();
                PC_Database.ins(patientAddresses);
                // check if 20 patients are created for bulk testing
                system.assertEquals(patientAccounts.size(), 20);
                // check if 20 patients are created for bulk testing
                system.assertEquals(patientAddresses.size(), 20);
                // check if primary address is true on address record
                system.assertEquals(patientAddresses[0].PC_Primary_Address__c, false);
                // update the status as inactive to check if the end date changes
                patientAddresses[0].PC_Status__c = PC_Constants.INACTIVE;
                patientAddresses[0].PC_End_Date__c = Date.today() +7;
                patientAddresses[1].PC_Primary_Address__c = true;
                PC_Database.upd(patientAddresses);
                // checking for end date
                //system.assertEquals(patientAddresses[0].PC_End_Date__c, Date.today());
                // check if the primary address field is updated
                system.assertEquals(patientAddresses[1].PC_Primary_Address__c, TRUE);
                List<PC_Address__c> patientAddress = PC_Test_Setup.createAddresses(patientAccounts, OBJECT_NUMBER, true);
                PC_Database.ins(patientAddress);
                //
                PC_Database.del(patientAddresses[0]);
                PC_Address__c onlyAddress = [SELECT PC_Primary_Address__c FROM PC_Address__c where PC_Account__c =: patientAddresses[0].PC_Account__c];
                system.assertEquals(onlyAddress.PC_Primary_Address__c, TRUE);
                Test.StopTest();
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }

    /*********************************************************************************
    Method Name    : testBulkAddressLogic
    Author         : Deloitte
    Description    : This method is used for testing bulk address insertion logic
    Return Type    : void
    Parameter      :
    *********************************************************************************/
    @isTest
    static void testBulkAddressLogic() {
        List<PC_Address__c> addressList = new List<PC_Address__c>();

        if(isTriggerActive){
            adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
            PC_Database.ins(adminUser);

            System.runAs(adminUser)
            {
                Test.StartTest();

                List<Account> listOfAccountsToBeInserted = new List<Account>();
                List<PC_Address__c> listOfAddressesToBeInserted = new List<PC_Address__c>();
                List<PC_Address__c> bulkAddressList = new List<PC_Address__c>();

                /* Test scenarios for Account which has a primary address:
                 * 1st Scenario description :When an account already has a primary address and in the new address records one or more are marked as primary address, then all the new address records are marked as non primary. */

                for(Integer i=0;i<9;i++){
                    Account  patientAccount = PC_Test_Setup.createEWPPatient('testpatient', '1988-05-30', 'Mr.' , PC_Constants.PATIENT_RECORD_TYPE);
                    listOfAccountsToBeInserted.add(patientAccount);
                }

                PC_Database.ins(listOfAccountsToBeInserted,false);
                //-----------------------------------------------
                PC_Address__c address1 = PC_Test_Setup.createAddress(listOfAccountsToBeInserted[0].Id);
                listOfAddressesToBeInserted.add(address1);

                PC_Address__c address2 = PC_Test_Setup.createAddress(listOfAccountsToBeInserted[1].Id);
                listOfAddressesToBeInserted.add(address2);

                PC_Address__c addressForPatientAccount1PA = PC_Test_Setup.createAddress(listOfAccountsToBeInserted[4].Id);
                listOfAddressesToBeInserted.add(addressForPatientAccount1PA);

                PC_Address__c addressForPatientAccount2PA = PC_Test_Setup.createAddress(listOfAccountsToBeInserted[5].Id);
                listOfAddressesToBeInserted.add(addressForPatientAccount2PA);

                PC_Database.ins(listOfAddressesToBeInserted,false);

                for(Integer i=0;i<200;i++){
                    PC_Address__c address = PC_Test_Setup.createAddress(listOfAccountsToBeInserted[0].Id);
                    addressList.add(address);
                }

                addressList[0].PC_Primary_Address__c = false;
                addressList[2].PC_Primary_Address__c = false;
                PC_Database.ins(addressList,false);

                /* 1st Scenario END */

                /* Test scenarios for Account which has a primary address:
                 * 2nd Scenario description: When an account already has a primary address and in the new address records only one primary address is present, then the latest address record is marked as primary on account.This is as per the existing logic. */

                addressList = new List<PC_Address__c>();

                for(Integer i=0;i<200;i++){
                    PC_Address__c address = PC_Test_Setup.createAddress(listOfAccountsToBeInserted[1].Id);
                    address.PC_Primary_Address__c =false;
                    addressList.add(address);
                }

                addressList[0].PC_Primary_Address__c = true;
                PC_Database.ins(addressList,false);
                /* 2nd Scenario END*/

                /* Test scenarios for Account which DOES NOT have a primary address:
                * 3rd Scenario Description: If account record does not have a primary address, and in the new address records we have one or more marked as primary, then we select the first primary address record as primary on the account record.
                * The rest of the address records would be marked as non-primary.*/

                addressList = new List<PC_Address__c>();

                for(Integer i=0;i<200;i++){
                    PC_Address__c address = PC_Test_Setup.createAddress(listOfAccountsToBeInserted[2].Id);
                    addressList.add(address);
                }

                addressList[0].PC_Primary_Address__c = false;
                addressList[3].PC_Primary_Address__c = false;
                PC_Database.ins(addressList,false);
                /* 3rd Scenario END*/

                /* Test scenarios for Account which DOES NOT have a primary address:
                *  4th Scenario Description: If account record does not have a primary address, and in the new address records we dont have any address record marked as primary, then we select the first non-primary address record and mark it as primary for the account record.
                *  The rest of the new address records remain unchanged (i.e. non-primary).
                */

                addressList = new List<PC_Address__c>();

                for(Integer i=0;i<200;i++){
                    PC_Address__c address = PC_Test_Setup.createAddress(listOfAccountsToBeInserted[3].Id);
                    address.PC_Primary_Address__c =false;
                    addressList.add(address);
                }

                PC_Database.ins(addressList,false);

                /*-------------------------------------------------------------------------------------------------------------------------------*/
                List<PC_Address__c> addressList1 = new List<PC_Address__c>();

                for(Integer i=0;i<2;i++){
                    PC_Address__c address = PC_Test_Setup.createAddress(listOfAccountsToBeInserted[4].Id);
                    address.PC_Primary_Address__c =true;
                    addressList1.add(address);
                }
                addressList1[1].PC_Primary_Address__c = false;

                bulkAddressList.addAll(addressList1);

                /*-------------------------------------------------------------------------------------------------------------------------------*/

                List<PC_Address__c> addressList2 = new List<PC_Address__c>();

                for(Integer i=0;i<3;i++){
                    PC_Address__c address = PC_Test_Setup.createAddress(listOfAccountsToBeInserted[5].Id);
                    address.PC_Primary_Address__c =true;
                    addressList2.add(address);
                }
                addressList2[2].PC_Primary_Address__c = false;

                bulkAddressList.addAll(addressList2);

                /*-------------------------------------------------------------------------------------------------------------------------------*/

                List<PC_Address__c> addressList3 = new List<PC_Address__c>();

                for(Integer i=0;i<3;i++){
                    PC_Address__c address = PC_Test_Setup.createAddress(listOfAccountsToBeInserted[6].Id);
                    address.PC_Primary_Address__c =true;
                    addressList3.add(address);
                }
                addressList3[1].PC_Primary_Address__c = false;

                bulkAddressList.addAll(addressList3);

                /*-------------------------------------------------------------------------------------------------------------------------------*/

                List<PC_Address__c> addressList4 = new List<PC_Address__c>();

                for(Integer i=0;i<3;i++){
                    PC_Address__c address = PC_Test_Setup.createAddress(listOfAccountsToBeInserted[7].Id);
                    address.PC_Primary_Address__c =true;
                    addressList4.add(address);
                }
                addressList4[0].PC_Primary_Address__c = false;
                addressList4[1].PC_Primary_Address__c = false;

                bulkAddressList.addAll(addressList4);

                /*-------------------------------------------------------------------------------------------------------------------------------*/

                List<PC_Address__c> addressList5 = new List<PC_Address__c>();

                for(Integer i=0;i<3;i++){
                    PC_Address__c address = PC_Test_Setup.createAddress(listOfAccountsToBeInserted[8].Id);
                    address.PC_Primary_Address__c =true;
                    addressList5.add(address);
                }

                bulkAddressList.addAll(addressList5);

                PC_Database.ins(bulkAddressList,false);

                /*-------------------------------------------------------------------------------------------------------------------------------*/

                /* 4th Scenario END*/


                Test.stopTest();
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }


}