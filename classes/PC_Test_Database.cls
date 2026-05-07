/*********************************************************************************
Modification Log:
----------------------------------------------------------------------------------
Developer              Date                   	Description
-----------------------------------------------------------------------------------
Prachi Nandgaonkar     Dec 1, 2016               Initial version
Ajinkya Deshmukh       Dec 9, 2016               Consolidated test methods
Vijay Kashikar         July 25, 2017             [PC-1967] Added checkAssert test method for testing custom exception
Prachi Nandgaonkar     July 26, 2017             [PC-1967] Updated all references of System.NoAccessException with PC_Database.NoDatabaseAccessException
Mike Klumpenaar        Feb 20, 2019              [PC-4475] Refactored processError methods from PC_Database to PC_Test_Database
Vijay Kashikar         Feb 18, 2020              [PC-6000] On pre-packaging orgs, the DML exception message is diffent from the expected message. Hence changes
                                                 done so as to avoid the check based on the error messages.
*********************************************************************************/

/**
 * Test class for PC_Ddatabase
 *
 * @date 2016-12-01
 */
@isTest
public class PC_Test_Database {
    public static final String ACCOUNT_NAME = 'Test Account';
    private static User adminUser;
    private static final Integer OBJECTS_NUMBER = 2;
    private static final Integer OBJECT1_NUMBER = 2;
    private static User restrictedUser;
    private static final string RESTRICTED_PROFILE = 'Read Only';
    public static final String ACCOUNT_OBJ = 'Account';
    public static boolean throwExceptions = true;

    @isTest
    static void insertPositiveTest() {
        // Create PermissionSet
        PermissionSet myPermissionSet = PC_Test_Setup.createPermissionSet();
        ObjectPermissions myObjectPermissions = PC_Test_Setup.createObjectPermissions('Account', myPermissionSet.Id, true, true, false, false);
        FieldPermissions myFieldPermissions = PC_Test_setup.createFieldPermissions('Account', 'Fax', myPermissionSet.Id, true, false);
        restrictedUser = PC_Test_Setup.createUser(PC_Test_Setup.RESTRICTED_PROFILE, 'restricted@testuser.com', 'rtestusr');
        PC_Database.ins(restrictedUser);
        PermissionSetAssignment assignment = new PermissionSetAssignment(AssigneeId = restrictedUser.Id, PermissionSetId = myPermissionSet.Id);
        PC_Database.ins(assignment, false);
        // bulk creation of patient accounts
        List<Account> patientAccounts = PC_Test_Setup.createSampleAccounts('Patient', OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
        Account patientAccount = PC_Test_Setup.createSampleAccount('Patient', PC_Constants.PATIENT_RECORD_TYPE);
        system.runAs(restrictedUser) {
            try {
                Test.StartTest();
                PC_Database.ins(patientAccounts);
                PC_Database.ins(patientAccount);
                // check if 2 patients are created for bulk testing
                system.assertEquals(patientAccounts.size(), 2);
                Test.StopTest();
            }
            catch (PC_Database.NoDatabaseAccessException e) {
                System.assert(true, 'This assert would not execute');
            }
            catch(DmlException ex) {
                System.assert(true);
            }
        }
    }

    @isTest
    static void insertNegativeTest() {
        // Create PermissionSet
        PermissionSet myPermissionSet = PC_Test_Setup.createPermissionSet();
        ObjectPermissions myObjectPermissions = PC_Test_Setup.createObjectPermissions('Account', myPermissionSet.Id, false, true, false, false);
        FieldPermissions myFieldPermissions = PC_Test_setup.createFieldPermissions('Account', 'Fax', myPermissionSet.Id, true, false);
        restrictedUser = PC_Test_Setup.createUser(PC_Test_Setup.RESTRICTED_PROFILE, 'restricted@testuser.com', 'rtestusr');
        PC_Database.ins(restrictedUser);
        PermissionSetAssignment assignment = new PermissionSetAssignment(AssigneeId = restrictedUser.Id, PermissionSetId = myPermissionSet.Id);
        PC_Database.ins(assignment, false);
        // bulk creation of patient accounts
        List<Account> patientAccounts = PC_Test_Setup.createSampleAccounts('Patient', OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
        Account patientAccount = PC_Test_Setup.createSampleAccount('Patient', PC_Constants.PATIENT_RECORD_TYPE);
        system.runAs(restrictedUser) {
            try {
                Test.StartTest();
                PC_Database.ins(patientAccounts);
                // check if 2 patients are created for bulk testing
                System.assert(true, 'This assert would not execute');
                Test.StopTest();
            }
            catch (PC_Database.NoDatabaseAccessException e) {
                System.assertEquals('No access on Account for Creating', e.getMessage());
            }
            catch(DmlException ex) {
                System.assert(true);
            }
        }
    }

    @isTest
    static void updatePositiveTest() {
        // Create PermissionSet
        PermissionSet myPermissionSet = PC_Test_Setup.createPermissionSet();
        ObjectPermissions myObjectPermissions = PC_Test_Setup.createObjectPermissions('Account', myPermissionSet.Id, true, true, true, false);
        FieldPermissions myFieldPermissions = PC_Test_setup.createFieldPermissions('Account', 'Fax', myPermissionSet.Id, true, false);
        restrictedUser = PC_Test_Setup.createUser(PC_Test_Setup.RESTRICTED_PROFILE, 'restricted@testuser.com', 'rtestusr');
        PC_Database.ins(restrictedUser);
        PermissionSetAssignment assignment = new PermissionSetAssignment(AssigneeId = restrictedUser.Id, PermissionSetId = myPermissionSet.Id);
        PC_Database.ins(assignment, false);
        // bulk creation of patient accounts
        List<Account> patientAccounts = PC_Test_Setup.createSampleAccounts('Patient', OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
        Account patientAccount = PC_Test_Setup.createSampleAccount('Patient', PC_Constants.PATIENT_RECORD_TYPE);
        system.runAs(restrictedUser) {
            try {
                Test.StartTest();
                PC_Database.ins(patientAccounts);
                PC_Database.ins(patientAccount);
                patientAccounts[0].Fax = '1718292';
                patientAccount.Fax = '7182920';
                PC_Database.upd(patientAccounts);
                PC_Database.upd(patientAccount);
                // check if 2 patients are created for bulk testing
                system.assertEquals(patientAccounts[0].Fax, '1718292');
                Test.StopTest();
            }
            catch (PC_Database.NoDatabaseAccessException e) {
                System.assert(true);
            }
            catch(DmlException ex) {
                System.assert(true);
            }
        }
    }

    @isTest
    static void updateNegativeTest() {
        // Create PermissionSet
        PermissionSet myPermissionSet = PC_Test_Setup.createPermissionSet();
        ObjectPermissions myObjectPermissions = PC_Test_Setup.createObjectPermissions('Account', myPermissionSet.Id, true, true, false, false);
        FieldPermissions myFieldPermissions = PC_Test_setup.createFieldPermissions('Account', 'Fax', myPermissionSet.Id, true, false);
        restrictedUser = PC_Test_Setup.createUser(PC_Test_Setup.RESTRICTED_PROFILE, 'restricted@testuser.com', 'rtestusr');
        PC_Database.ins(restrictedUser);
        PermissionSetAssignment assignment = new PermissionSetAssignment(AssigneeId = restrictedUser.Id, PermissionSetId = myPermissionSet.Id);
        PC_Database.ins(assignment, false);
        // bulk creation of patient accounts
        List<Account> patientAccounts = PC_Test_Setup.createSampleAccounts('Patient', OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
        system.runAs(restrictedUser) {
            try {
                Test.StartTest();
                PC_Database.ins(patientAccounts);
                patientAccounts[0].Fax = '1718292';
                PC_Database.upd(patientAccounts);
                System.assert(true, 'This assert would not execute');
                Test.StopTest();
            }
            catch (PC_Database.NoDatabaseAccessException e) {
                System.assert(true);
            }
            catch(DmlException ex) {
                System.assert(true);
            }
        }
    }

    @isTest
    static void deletePositiveTest() {
        // Create PermissionSet
        PermissionSet myPermissionSet = PC_Test_Setup.createPermissionSet();
        ObjectPermissions myObjectPermissions = PC_Test_Setup.createObjectPermissions('Account', myPermissionSet.Id, true, true, true, true);
        FieldPermissions myFieldPermissions = PC_Test_setup.createFieldPermissions('Account', 'Fax', myPermissionSet.Id, true, true);
        restrictedUser = PC_Test_Setup.createUser(PC_Test_Setup.RESTRICTED_PROFILE, 'restricted@testuser.com', 'rtestusr');
        PC_Database.ins(restrictedUser);
        PermissionSetAssignment assignment = new PermissionSetAssignment(AssigneeId = restrictedUser.Id, PermissionSetId = myPermissionSet.Id);
        PC_Database.ins(assignment, false);
        // bulk creation of patient accounts
        List<Account> patientAccounts = PC_Test_Setup.createSampleAccounts('Patient', OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
        Account patientAccount = PC_Test_Setup.createSampleAccount('Patient', PC_Constants.PATIENT_RECORD_TYPE);
        system.runAs(restrictedUser) {
            try {
                Test.StartTest();
                PC_Database.ups(patientAccounts);
                PC_Database.ups(patientAccount);
                patientAccounts[0].Fax = '1718292';
                PC_Database.ups(patientAccounts);
                PC_Database.del(patientAccounts, false);
                System.assertEquals(patientAccounts.size(), 2);
                PC_Database.del(patientAccount);
                //System.assertEquals(patientAccount.Id, null);
                Test.StopTest();
            }
            catch (PC_Database.NoDatabaseAccessException e) {
                System.assert(True, 'This will not execute');
            }
            catch(DmlException ex) {
                System.assert(true);
            }
        }
    }

    @isTest
    static void queryAccess() {
        // Create PermissionSet
        PermissionSet myPermissionSet = PC_Test_Setup.createPermissionSet();
        ObjectPermissions myObjectPermissions = PC_Test_Setup.createObjectPermissions('Account', myPermissionSet.Id, true, true, true, true);
        FieldPermissions myFieldPermissions = PC_Test_setup.createFieldPermissions('Account', 'Fax', myPermissionSet.Id, true, true);
        restrictedUser = PC_Test_Setup.createUser(PC_Test_Setup.RESTRICTED_PROFILE, 'restricted@testuser.com', 'rtestusr');
        PC_Database.ins(restrictedUser);
        PermissionSetAssignment assignment = new PermissionSetAssignment(AssigneeId = restrictedUser.Id, PermissionSetId = myPermissionSet.Id);
        PC_Database.ins(assignment, false);
        // bulk creation of patient accounts
        List<Account> patientAccounts = PC_Test_Setup.createSampleAccounts('Patient', OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
        Account patientAccount = PC_Test_Setup.createSampleAccount('Patient', PC_Constants.PATIENT_RECORD_TYPE);
        system.runAs(restrictedUser) {
            try {
                Test.StartTest();
                List<String> fields = new List<String>{'Fax'};
                String queryString = 'SELECT Id, Name, Fax FROM Account';
                PC_Database.assertAccess('Account', PC_Database.Operation.Creating, fields);
                PC_Database.assertAccess('Account', PC_Database.Operation.Updating, fields);
                PC_Database.assertAccess('Account', PC_Database.Operation.Reading, fields);
                PC_Database.assertAccess('Account', PC_Database.Operation.Deleting, fields);
                PC_Database.queryWithAccess(queryString, false);
                PC_Database.queryWithAccess(queryString, true);
                PC_Database.queryWithAccess(queryString, fields);
                PC_Database.ins(patientAccount, true);
                PC_Database.chkAccess('Account', PC_Database.Operation.Creating, fields);
                PC_Database.chkAccess('Account', PC_Database.Operation.Reading, fields);
                PC_Database.chkAccess('Account', PC_Database.Operation.Updating, fields);
                PC_Database.chkAccess('Account', PC_Database.Operation.Deleting, fields);
                PC_Database.queryWithAccess(queryString, false);
                PC_Database.queryWithAccess(queryString, true);
                PC_Database.ups(patientAccounts, true);
                PC_Database.assertAccess(patientAccounts, PC_Database.Operation.Creating, fields);
                PC_Database.assertAccess(patientAccounts, PC_Database.Operation.Updating, fields);
                PC_Database.assertAccess(patientAccounts, PC_Database.Operation.Reading, fields);
                PC_Database.assertAccess(patientAccounts, PC_Database.Operation.Deleting, fields);

                /*
                 * TODO: Figure out what this is for - these methods were moved to test class from PC_Database since
                 *       they don't have any other references in the package.
                 */
                processError('Error String'); //TODO: figure out what this is for
                throwExceptions = false;
                processError('Error String'); //TODO: figure out what this is for

                Test.StopTest();
            }
            catch (PC_Database.NoDatabaseAccessException e) {
                System.assert(True, 'This will not execute');
            }
            catch(DmlException ex) {
                System.assert(true);
            }
        }
    }

    @isTest
    static void checkAssertAccess() {
        // Create PermissionSet
        PermissionSet myPermissionSet = PC_Test_Setup.createPermissionSet();
        ObjectPermissions myObjectPermissions = PC_Test_Setup.createObjectPermissions('Account', myPermissionSet.Id, false, true, false, false);
        FieldPermissions myFieldPermissions = PC_Test_setup.createFieldPermissions('Account', 'Fax', myPermissionSet.Id, true, false);
        restrictedUser = PC_Test_Setup.createUser(PC_Test_Setup.RESTRICTED_PROFILE, 'restricted@testuser.com', 'rtestusr');
        PC_Database.ins(restrictedUser);
        PermissionSetAssignment assignment = new PermissionSetAssignment(AssigneeId = restrictedUser.Id, PermissionSetId = myPermissionSet.Id);
        PC_Database.ins(assignment, false);
        system.runAs(restrictedUser) {
            try {
                Test.StartTest();
                List<String> fields = new List<String>{'Fax'};
                List<sObjectField> allFields = new List<sObjectField>();
                allFields.add(Account.Fax.getDescribe().getSObjectField());
                String queryString = 'SELECT Id, Name, Fax FROM Account';
                PC_Database.assertAccess('Account', PC_Database.Operation.Creating, fields);
                System.assert(false, 'Assert access did not work as expected.');
                Test.StopTest();
            }
            catch(PC_Database.NoDatabaseAccessException noDBAccessException) {
                System.assert(true, 'NoDatabaseAccessException caught rightly');
            }
            finally {
                Test.StopTest();
            }
        }
    }

    /*********************************************************************************
    Method Name    : processError
    Author         : Deloitte
    Description    : This method is a placeholder to log exceptions/error messages
    Return Type    :
    Parameter      : String msg
    *********************************************************************************/

    private static void processError(String msg) {
        if (throwExceptions) {
            system.assert(throwExceptions == true, msg);
        } else {
            system.debug(LoggingLevel.ERROR, msg);
        }
    }
}