/*********************************************************************************
Class Name      : PC_Test_Trigger_Referral_Notification
Description     : Test class for Pharmacy Referrer Notification sending trigger handler class
Created By      : Tejas Patel
Created Date    : Oct 9, 2017
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   	Description
-----------------------------------------------------------------------------------
Tejas Patel              	Oct 9, 2017       		Initial Version
Vijay Kashikar              07-Marc-2019            [PC-4556] Changed reference from PC_Program_Service_Permission__c.PC_Program__c to PC_Program_Service_Permission__c.PC_ProgramCase__c
Hitha Avalakki              Feb 26, 2021            [PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
Hitha Avalakki              Mar 19, 2021            [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
*********************************************************************************/
@isTest
public class PC_Test_Trigger_Referral_Notification {
    private static User adminUser1;
    private static final Integer OBJECTS_NUMBER = 3;
    static final String MOCK_SENDER 			= 'PC_Test_MockELetterSender';
    public static Boolean isTriggerActive 		= PC_TriggerHandlerHelper.getTriggerState('PC_Pharmacy_Referral__c', 'PC_Trigger_Referral_Notification');
    
    @isTest
    static void testTaskCreation() {
        if(isTriggerActive) {
            //Create admin user
            adminUser1 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser1);
            
            // create a record for the custom setting
            PC_System_Settings__c cSetting 		= new PC_System_Settings__c();
            cSetting.PC_eLetter_Sender_Class__c = MOCK_SENDER;
            PC_Database.ins(cSetting);
            
            //Create multiple patient accounts
            List<Account> patientAccounts = PC_Test_Setup.createAccounts('Patient', OBJECTS_NUMBER, PC_Constants.PATIENT_RECORD_TYPE);
            system.runAs(adminUser1) {
                Test.StartTest();
                PC_Database.ins(patientAccounts);
                // check if 3 patients are created for bulk testing
                system.assertEquals(OBJECTS_NUMBER, patientAccounts.size());
                
                //Create Physicain
                List<Account> physicianAccounts = PC_Test_Setup.createAccounts('Physician', OBJECTS_NUMBER, PC_Constants.CASE_PHYSICIAN_RECORD_TYPE);
                PC_Database.ins(physicianAccounts);
                // check if 3 Physicain are created for bulk testing
                system.assertEquals(OBJECTS_NUMBER, physicianAccounts.size());
                
                //Manufacturer
                Account  manufacturer = PC_Test_Setup.createEWPPatient('testmanufacturer', '1988-05-30', 'Mr.' , 'Manufacturer');
                manufacturer = (Account)PC_Database.ins(manufacturer, false);
                
                //Engagement Program
                LIST<PC_Engagement_Program__c> engagement = new LIST<PC_Engagement_Program__c>();
                //#1
                PC_Engagement_Program__c  engagement1 = PC_Test_Setup.createEngagementProgram('programA', manufacturer.Id);
                engagement.add(engagement1);
                //#2
                PC_Engagement_Program__c  engagement2 = PC_Test_Setup.createEngagementProgram('programB', manufacturer.Id);
                engagement.add(engagement2);
                engagement = (LIST<PC_Engagement_Program__c>)PC_Database.ins(engagement, false);
                
                //Creatae multiple program cases
                //[PC-7442] Replaced PC_Test_Setup.createCases() with PC_Test_Setup.createProgramCases() method.
                List<Case> programCases = PC_Test_Setup.createProgramCases(patientAccounts, OBJECTS_NUMBER);
                List<Case> newCases = new List<Case>();
                //#1
                    programCases[0].PC_Engagement_Program__c 	= engagement[0].Id;
                    programCases[0].PC_Physician__c		   		= physicianAccounts[0].Id;
                    newCases.add(programCases[0]);
                //#2
                	programCases[1].PC_Engagement_Program__c 	= engagement[0].Id;
                    programCases[1].PC_Physician__c		   		= physicianAccounts[0].Id;
                    newCases.add(programCases[1]);
                //#3
                	programCases[2].PC_Engagement_Program__c 	= engagement[1].Id;
                    programCases[2].PC_Physician__c		   		= physicianAccounts[0].Id;
                    newCases.add(programCases[2]);

                newCases = (LIST<Case>)PC_Database.ins(newCases);
                // check if 3 cases are created for bulk testing
                system.assertEquals(OBJECTS_NUMBER, newCases.size());
                
                //Service
                LIST<PC_Service__c>  services 	= PC_Test_Setup.createServices('Referal Notification', OBJECTS_NUMBER);
                List<PC_Service__c> newServices = new List<PC_Service__c>();
                for(PC_Service__c s : services){
                    s.PC_Service_Function__c 				= PC_Constants.SERVICE_FUNCTION;
                    s.PC_Service_Communication_Channel__c	= PC_Constants.SERVICE_COMMUNICATION_CHANNEL;
                    s.PC_HCP_Permission_Required__c 		= true;
                    newServices.add(s);
                }
                newServices = (LIST<PC_Service__c>)PC_Database.ins(newServices, false);
                
                //Eletter
                LIST<PC_eLetter__c> eLetter = new LIST<PC_eLetter__c>();
                //#1
                PC_eLetter__c eLetter1 = new PC_eLetter__c();
                eLetter1.Name							= 'Referral Sent Notification A';
                eLetter1.PC_Source_Object__c			= 'Case';
                eLetter1.PC_Object_Record_Types__c 		= PC_Constants.CASE_PROGRAM_TYPE;
                eLetter1.PC_Communication_Language__c 	= 'English';
                eLetter1.PC_Target_Recipients__c		= PC_Constants.ROLE_TREATING_PHYSICIAN;
                eLetter1.PC_Template_Name__c			= 'PC_Referral_Notification';
                eLetter1.PC_Send_to_User__c				= true;
                eLetter1.PC_Allow_Send_to_Patient__c	= true;
                eLetter1.PC_Hide_From_eLetter_Page__c	= true;
                eLetter.add(eLetter1);
                
                //#2
                PC_eLetter__c eLetter2 = new PC_eLetter__c();
                eLetter2.Name							= 'Referral Sent Notification B';
                eLetter2.PC_Source_Object__c			= 'Case';
                eLetter2.PC_Object_Record_Types__c 		= PC_Constants.CASE_PROGRAM_TYPE;
                eLetter2.PC_Communication_Language__c 	= 'English';
                eLetter2.PC_Target_Recipients__c		= PC_Constants.ROLE_TREATING_PHYSICIAN;
                eLetter2.PC_Template_Name__c			= 'PC_Referral_Notification';
                eLetter2.PC_Send_to_User__c				= true;
                eLetter2.PC_Allow_Send_to_Patient__c	= true;
                eLetter2.PC_Hide_From_eLetter_Page__c	= true;
                eLetter.add(eLetter2);

                eLetter = (LIST<PC_eLetter__c>)PC_Database.ins(eLetter, false);
                
                //Engagement Program Service
                LIST<PC_Engagement_Program_Service__c> prgService 	= new LIST<PC_Engagement_Program_Service__c>();
                //#1
                PC_Engagement_Program_Service__c prgService1 		= new PC_Engagement_Program_Service__c();
                prgService1.PC_Service__c							= newServices[0].Id;
                prgService1.PC_Notification_Template__c				= eLetter[0].Id;
                prgService1.PC_Engagement_Program__c				= engagement[0].Id;
                prgService1.PC_Start_Date__c						= (DATE) (DATE.TODAY() - 10);
                prgService1.PC_End_Date__c							= (DATE) (DATE.TODAY() + 10);
                prgService.add(prgService1);
                //#2
                PC_Engagement_Program_Service__c prgService2 		= new PC_Engagement_Program_Service__c();
                prgService2.PC_Service__c							= newServices[1].Id;
                prgService2.PC_Notification_Template__c				= eLetter[1].Id;
                prgService2.PC_Engagement_Program__c				= engagement[0].Id;
                prgService2.PC_Start_Date__c						= (DATE) (DATE.TODAY() - 10);
                prgService2.PC_End_Date__c							= (DATE) (DATE.TODAY() + 10);
                prgService.add(prgService2);
                //#3
                PC_Engagement_Program_Service__c prgService3 		= new PC_Engagement_Program_Service__c();
                prgService3.PC_Service__c							= newServices[2].Id;
                prgService3.PC_Notification_Template__c				= eLetter[1].Id;
                prgService3.PC_Engagement_Program__c				= engagement[1].Id;
                prgService3.PC_Start_Date__c						= (DATE) (DATE.TODAY() - 10);
                prgService3.PC_End_Date__c							= (DATE) (DATE.TODAY() + 10);
                prgService.add(prgService3);
                
                prgService = (LIST<PC_Engagement_Program_Service__c>)PC_Database.ins(prgService, false);
                
                //Program Service
                LIST<PC_Program_Service_Permission__c>  newProgramServicePermissions = PC_Test_Setup.createProgramServicePermissions(newServices, OBJECTS_NUMBER);

				newProgramServicePermissions[0].PC_HCP_Response__c = 'Granted';
                newProgramServicePermissions[0].PC_Patient_Response__c = 'Granted';
                newProgramServicePermissions[0].PC_ProgramCase__c = newCases[0].Id;

                newProgramServicePermissions[1].PC_HCP_Response__c = 'Granted';
                newProgramServicePermissions[1].PC_Patient_Response__c = 'Revoked';
                newProgramServicePermissions[1].PC_ProgramCase__c = newCases[1].Id;

                newProgramServicePermissions[2].PC_HCP_Response__c = 'Revoked';
                newProgramServicePermissions[2].PC_Patient_Response__c = 'Revoked';
                newProgramServicePermissions[2].PC_ProgramCase__c = newCases[2].Id;

                newProgramServicePermissions = (LIST<PC_Program_Service_Permission__c>)PC_Database.ins(newProgramServicePermissions, false);
                
                //Create multiple pharmacy referrals
                List<PC_Pharmacy_Referral__c> referrals = PC_Test_Setup.createReferrals(newCases, 2);
                referrals = (List<PC_Pharmacy_Referral__c>)PC_Database.ins(referrals,false);
                // check if 3 referrals are created for bulk testing
                system.assertEquals(2, referrals.size());
                
                Test.stopTest();
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }
}