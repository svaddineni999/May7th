/*********************************************************************************
Class Name      : PC_Test_Program_Service_Per_Trigger
Description     : The test class for PC_Program_Service_Permission trigger
Created By      : Tejas Patel
Created Date    : May 26, 2017
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Tejas Patel		           May 26, 2017            Initial Version
Tejas Patel				   July 12, 2017           PC-1875 ignore test if trigger is disabled in metadata
Haritha Reddy			   Feb 17, 2021            PC-7423 Modified code to set TODAY_DATE to GMT value of today's date
*********************************************************************************/
@isTest
public class PC_Test_Program_Service_Per_Trigger {
    public static final String SERVICE_NAME = 'TestService';
    private static User adminUser;
    private static final Integer SERVICE_NUMBER = 3;
    private static final Date TODAY_DATE = Datetime.now().dateGMT();
    
    public static List<PC_Service__c> services;
    public static List<PC_Program_Service_Permission__c> programServicePermissions;
    
    public static List<PC_Service__c> soqlServices = new List<PC_Service__c>();
    public static List<PC_Program_Service_Permission__c> soqlProgramServicePermissions = new List<PC_Program_Service_Permission__c>();
    public static Boolean isTriggerActive = PC_TriggerHandlerHelper.getTriggerState('PC_Program_Service_Permission__c', 'PC_Trigger_Program_Service_Permission');

    /*********************************************************************************
Method Name    : beforeInsertandUpdateTest
Author         : Tejas Patel
Description    : This method is used for testing the after update positive scenarios
Return Type    : void 
Parameter      : 
*********************************************************************************/
    @isTest 
    static void beforeInsertandUpdateTest() {
        if(isTriggerActive){
            adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'test2');
            PC_Database.ins(adminUser);
            system.runAs(adminUser) {
                Test.StartTest();
                //Bulk Creation of Services
                services 					= PC_Test_Setup.createServices(SERVICE_NAME, SERVICE_NUMBER);
                PC_Database.ins(services,false);

                //Bulk Creation of Program Service Permission
                programServicePermissions 	= PC_Test_Setup.createProgramServicePermissions(services, SERVICE_NUMBER);
                PC_Database.ins(programServicePermissions,false);

                // check if Services and Program Service Permission are created for bulk testing
                system.assertEquals(services.size(), SERVICE_NUMBER);
                system.assertEquals(programServicePermissions.size(), SERVICE_NUMBER);

                //Get the req fields from Services
                for (PC_Service__c s : services){
                    PC_Service__c tempServices					= [SELECT Id, PC_Default_Expiration_Days__c FROM  PC_Service__c where Id =: s.Id];
                    soqlServices.add(tempServices);
                }

                //Get the req fields from Program_Service_Permission
                for (PC_Program_Service_Permission__c ps : programServicePermissions){
                    PC_Program_Service_Permission__c tempProgramServicePermissions	= [SELECT Id, PC_Service__c, PC_Start_Date__c, PC_End_Date__c FROM  PC_Program_Service_Permission__c where Id =: ps.Id];
                    soqlProgramServicePermissions.add(tempProgramServicePermissions);
                }

                //Case 1 : No End Date; Defaults days 0
                system.assertEquals(soqlServices[0].PC_Default_Expiration_Days__c, 0);
                system.assertEquals(soqlProgramServicePermissions[0].PC_Start_Date__c, TODAY_DATE);
                system.assertEquals(soqlProgramServicePermissions[0].PC_End_Date__c, NULL);

                //Case 2 : End Date = Start Date + Defaults Days; Defaults Days 1
                system.assertEquals(soqlServices[1].PC_Default_Expiration_Days__c, 1);
                system.assertEquals(soqlProgramServicePermissions[1].PC_Start_Date__c, TODAY_DATE);
                system.assertEquals(soqlProgramServicePermissions[1].PC_End_Date__c, TODAY_DATE + 1);

                //Case 3 : End Date = Start Date + Defaults Days; Defaults Days 2
                system.assertEquals(soqlServices[2].PC_Default_Expiration_Days__c, 2);
                system.assertEquals(soqlProgramServicePermissions[2].PC_Start_Date__c, TODAY_DATE);
                system.assertEquals(soqlProgramServicePermissions[2].PC_End_Date__c, TODAY_DATE + 2);

                //Update Record
                PC_Program_Service_Permission__c updateProgramServicePermissions = new PC_Program_Service_Permission__c (
                    Id					= soqlProgramServicePermissions[1].Id,
                    PC_Service__c 		= soqlServices[1].Id,
                    PC_Start_Date__c	= TODAY_DATE,
                    PC_End_Date__c		= TODAY_DATE
                );
                PC_Database.upd(updateProgramServicePermissions,false);

                //Case 4 : User Entered End Date; with exsisting Defaults Days 1
                system.assertEquals(updateProgramServicePermissions.PC_Start_Date__c, TODAY_DATE);
                system.assertEquals(updateProgramServicePermissions.PC_End_Date__c, TODAY_DATE);
                system.assertNotEquals(updateProgramServicePermissions.PC_End_Date__c, soqlProgramServicePermissions[1].PC_End_Date__c);
                Test.StopTest();
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }
}