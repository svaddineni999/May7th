@isTest
public class ACLS_Test_OverlapServiceDatePSPHandler{
    
    @testsetup
	private static void setup(){
        User usr1 = ACLS_TestDataFactory.createUser('ACLS Base Profile', 'userpctest@test2.com', 'test2');
        PC_Database.ins(usr1);
        
        User adminUser = PC_Test_Setup.createUser('System Administrator', 'eletteruser1@test.com', 'user1');
        PC_Database.ins(adminUser);

        // Assigning Required Permission set to Test user
        List<PermissionSetAssignment> lstPsAssignment = new List<PermissionSetAssignment>();
        PermissionSetAssignment psAssignment = ACLS_Utility.assignPermissions(usr1.Id, 'ACLS_Base_RW_Permissions');
        PermissionSetAssignment psAssignment1 = ACLS_Utility.assignPermissions(usr1.Id, 'ACLS_Base_Permissions');
        PermissionSetAssignment psAssignment2 = ACLS_Utility.assignPermissions(adminUser.Id, 'ACLS_IT_Admin_Permissions');
        PermissionSetAssignment psAssignment3 = ACLS_Utility.assignPermissions(adminUser.Id, 'ACLS_Base_Permissions');
        lstPsAssignment.add(psAssignment);
        lstPsAssignment.add(psAssignment1);
        lstPsAssignment.add(psAssignment2);
        lstPsAssignment.add(psAssignment3);
        insert lstPsAssignment;
        
        System.runAs(adminUser){
           User u = [Select id from User where id=: usr1.id LIMIT 1];
           u.ACLS_Meeting_Link__c='www.sdah.invalid';
           update u;
        }

        System.runAs(usr1) {
            Map<String, Id> mapAccRecordTypes = ACLS_Utility.getMapOfRecordtype(ACLS_Constants.ACCOUNT);

            //Creating Manufacturer 
            List<Account> lstAcct = ACLS_TestDataFactory.createAccount(2);
            lstAcct[0].recordtypeId = mapAccRecordTypes.get(ACLS_Constants.ACCOUNT_MANUFACTURER_RT);
            lstAcct[1].recordtypeId = mapAccRecordTypes.get(ACLS_Constants.ACCOUNT_MANUFACTURER_RT);
            insert lstAcct;

            //Creating Engagement Program
            List<PC_Engagement_Program__c> lstEngageProgram = ACLS_TestDataFactory.createEngagmentProgram(1);
            lstEngageProgram[0].PC_Program_Code__c = 'ASHF';
            insert lstEngageProgram;
            
            //Creating Program Case
            List<Case> lstProgramCase = ACLS_TestDataFactory.createProgramCase(1, lstAcct[1].Id);
            lstProgramCase[0].PC_Engagement_Program__c = lstEngageProgram[0].Id;
            lstProgramCase[0].OwnerId = UserInfo.getUserId();
            lstProgramCase[0].Subject='Test Subject1';
            insert lstProgramCase;
            
            //create service record
            List<PC_Service__c> lstService = ACLS_TestDataFactory.PC_ServiceTestDataMethod(1);
            lstService[0].Name='HIPAA Authorization';
			insert lstService;
            
            //create psp record
            List<PC_Program_Service_Permission__c> lstpsp = ACLS_TestDataFactory.PC_Program_Service_PermissioncTestDataMethod(1);
            lstpsp[0].PC_ProgramCase__c = lstProgramCase[0].id;
        	lstpsp[0].ACLS_Engagement_Program_Code__c='ASHF';
        	lstpsp[0].PC_Service__c=lstService[0].id;
            lstpsp[0].PC_Start_Date__c = system.today()+1;
            lstpsp[0].PC_End_Date__c = system.today()+2;
        	insert lstpsp;

            List<PC_Program_Service_Permission__c> lstpsp1 = ACLS_TestDataFactory.PC_Program_Service_PermissioncTestDataMethod(1);
            lstpsp1[0].PC_ProgramCase__c = lstProgramCase[0].id;
        	lstpsp1[0].ACLS_Engagement_Program_Code__c='ASHF';
        	lstpsp1[0].PC_Service__c=lstService[0].id;
            lstpsp1[0].PC_Start_Date__c = system.today()+3;
            lstpsp1[0].PC_End_Date__c = system.today()+4;
        	insert lstpsp1;
            
            List<PC_Program_Service_Permission__c> lstpsp2 = ACLS_TestDataFactory.PC_Program_Service_PermissioncTestDataMethod(3);
            lstpsp2[0].PC_ProgramCase__c = lstProgramCase[0].id;
        	lstpsp2[0].ACLS_Engagement_Program_Code__c='ASHF';
        	lstpsp2[0].PC_Service__c=lstService[0].id;
            lstpsp2[0].ACLS_HCP_Permission_Required__c = true;
            lstpsp2[0].ACLS_HCP_Signed_Date__c = system.today()+5;
            lstpsp2[0].ACLS_HCP_Expiration_Date__c = system.today()+6;
            
            lstpsp2[1].PC_ProgramCase__c = lstProgramCase[0].id;
        	lstpsp2[1].ACLS_Engagement_Program_Code__c='ASHF';
        	lstpsp2[1].PC_Service__c=lstService[0].id;
            lstpsp2[1].ACLS_HCP_Permission_Required__c = false;
            lstpsp2[1].ACLS_HCP_Signed_Date__c = null;
            lstpsp2[1].ACLS_HCP_Expiration_Date__c = null;
            lstpsp2[1].PC_HCP_Response__c = null;
            lstpsp2[1].PC_HCP_Response_Date__c = null;
            lstpsp2[1].ACLS_PT_Legal_GUA_Permission_Required__c = true;
            lstpsp2[1].ACLS_Patient_Signed_Date__c = system.today()+7;
            lstpsp2[1].ACLS_Patient_Expiration_Date__c = system.today()+8;  
            lstpsp2[1].PC_Start_Date__c = system.today()+7;
            lstpsp2[1].PC_End_Date__c = system.today()+8;
            
            lstpsp2[2].PC_ProgramCase__c = lstProgramCase[0].id;
        	lstpsp2[2].ACLS_Engagement_Program_Code__c='ASHF';
        	lstpsp2[2].PC_Service__c=lstService[0].id;
            lstpsp2[2].ACLS_HCP_Permission_Required__c = true;
            lstpsp2[2].ACLS_HCP_Signed_Date__c = system.today()+9;
            lstpsp2[2].ACLS_HCP_Expiration_Date__c = system.today()+10;
            
        	//insert lstpsp2[0];
            insert lstpsp2[1];
            
            Case programCase1 = new Case();
            programCase1.RecordTypeID = Schema.getGlobalDescribe().get('Case').getDescribe()
                                        .getRecordTypeInfosByDeveloperName()
                                        .get(ACLS_Constants.CASE_PROGRAM_RT)
                                        .getRecordTypeId(); 
            programCase1.PC_Engagement_Program__c = lstEngageProgram[0].id;
            programCase1.Subject='Test Subject2';
            insert programCase1;
                
        }
        
	}

     
    @isTest
    public static void updateMissingInfoOnPSPTest1(){
      	User usr1 = [select id from User where Alias = 'test2'];
        
        System.runAs(usr1) {     
            Test.startTest();
            List<PC_Engagement_Program__c> lstEP = [Select Id from PC_Engagement_Program__c where PC_Program_Code__c = 'ASHF'];
            List<PC_Program_Service_Permission__c> lstpspRecord = [Select id, ACLS_HCP_Permission_Required__c, ACLS_Engagement_Program_Code__c, ACLS_HCP_Signed_Date__c, ACLS_HCP_Expiration_Date__c from PC_Program_Service_Permission__c];
        	lstpspRecord[0].ACLS_Engagement_Program_Code__c='ASHF';
            lstpspRecord[0].ACLS_HCP_Permission_Required__c = true;
            lstpspRecord[0].ACLS_HCP_Signed_Date__c = system.today()+5;
            lstpspRecord[0].ACLS_HCP_Expiration_Date__c = system.today()+6;
        	update lstpspRecord;
            system.assertEquals(lstpspRecord[0].ACLS_Engagement_Program_Code__c, 'ASHF');  
            Test.stopTest();
        }
    }
    
        @isTest
    public static void updateInactivePSPTest(){
      	User usr1 = [select id from User where Alias = 'test2'];
        
        System.runAs(usr1) {
            Test.startTest();
            List<PC_Engagement_Program__c> lstEP = [Select Id from PC_Engagement_Program__c where PC_Program_Code__c = 'ASHF'];
            List<PC_Program_Service_Permission__c> lstpspRecord = [Select id, PC_Active__c from PC_Program_Service_Permission__c];
        	lstpspRecord[0].ACLS_Engagement_Program_Code__c='ASHF';
            lstpspRecord[0].PC_Start_Date__c = system.today()-5;
            lstpspRecord[0].PC_End_Date__c = system.today()-4;
        	update lstpspRecord;
            Test.stopTest();
            system.assertEquals(lstpspRecord[0].ACLS_Engagement_Program_Code__c, 'ASHF');

            
        }
    }
    
    @isTest
    public static void updateMissingInfoForHCP(){
      	User usr1 = [select id from User where Alias = 'test2'];        
        System.runAs(usr1) {
            try{
                Test.startTest();
                List<PC_Engagement_Program__c> lstEP = [Select Id from PC_Engagement_Program__c where PC_Program_Code__c = 'ASHF'];
                List<PC_Program_Service_Permission__c> lstpspRecord = [Select id, ACLS_HCP_Permission_Required__c, ACLS_Engagement_Program_Code__c, ACLS_HCP_Signed_Date__c, ACLS_HCP_Expiration_Date__c from PC_Program_Service_Permission__c where ACLS_HCP_Permission_Required__c = true];
                lstpspRecord[0].ACLS_Engagement_Program_Code__c='ASHF';
                lstpspRecord[0].ACLS_HCP_Signed_Date__c = system.today()+5;
                lstpspRecord[0].ACLS_HCP_Expiration_Date__c = system.today()+8;
                update lstpspRecord[0];
                
                lstpspRecord[1].ACLS_HCP_Signed_Date__c = system.today()+6;
                lstpspRecord[1].ACLS_HCP_Expiration_Date__c = system.today()+7;
                update lstpspRecord[1];
                Test.stopTest();
                system.assertEquals(lstpspRecord[0].ACLS_Engagement_Program_Code__c, 'ASHF');
        	}
            catch(Exception e){
                Boolean expectedExceptionThrown =  e.getMessage().contains((System.Label.ACLS_PSPDuplicateServiceErrorMsg)) ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }            
        }       
    }
}