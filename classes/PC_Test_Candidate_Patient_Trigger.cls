/**************************************************************************************
Apex Class Name     : PC_Test_Candidate_Patient_Trigger
Description         : This class is used for testing PC_Candidate_Patient_Trigger;
Created By           : Tetiana Danylyshyn
Created Date        : 08 June 2016
Modification Log    :
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
----------------------------------------------------------------------------                 
Tetiana Danylyshyn        08-June-2016          Initial version
Tejas Patel				  12-July-2017          PC-1875 ignore test if trigger is disabled in metadata
Shabda Bhujad               Dec 14, 2017          PC-1884 Updated the name of the handler the test class should check for
*************************************************************************************/
@isTest
private class PC_Test_Candidate_Patient_Trigger {
    public static final String APPLICANT_NAME = 'Test Applicant';
    private static User adminUser;
    public static Boolean isTriggerActive = True;

    @isTest static void testPdfGeneration() {
        if(isTriggerActive){
            adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test100');
            PC_Database.ins(adminUser);
            System.runAs(adminUser) {
                // bulkification is not needed for this method as the forms would be submitted individually
                PC_Applicant__c testApplicant = PC_Test_Setup.createApplicant(APPLICANT_NAME);
                Test.StartTest();
                PC_Database.ins(testApplicant);
                Test.StopTest();
                // Check if the pdf is created with Applicant's name
                List<Attachment> att = [SELECT Name, Id FROM Attachment WHERE Name = 'Test Applicant.pdf' LIMIT 1];

                if(att.size() < 1){
                    List<ContentDocument> contentDocuments =   [SELECT Title, Id FROM ContentDocument where Title ='Test Applicant.pdf' LIMIT 1];
                    System.assertEquals(contentDocuments.size(), 1);
                }
                else {
                    System.assertEquals(att.size(), 1);
                }
            }
        }
        System.debug('The Trigger is DeActivated : ' + isTriggerActive);
    }
}