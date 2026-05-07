/**
 * Created by mklumpenaar on 1/26/2018.
 * Modification Log:
----------------------------------------------------------------------------------
Developer              Date                   Description
-----------------------------------------------------------------------------------
Shishir Bansal        Dec-16-2019       [PC-5792] Avoid hardcoding of string variable
 */

@IsTest
private class PC_Test_DocumentService {
    @isTest static void testSplitDocument() {
        PC_Document__c parentDocument = new PC_Document__c();
        PC_Document__c[] childDocuments = new PC_Document__c[1];
        childDocuments[0] = new PC_Document__c();

        try {
            PC_DocumentService.splitDocument(parentDocument, childDocuments);
            System.assert(false, 'Expected a SplitException since we need to register a Splitter');
        } catch (PC_Document.SplitException e) {
            //PC_Utility.logAndThrowException(ex);

        }

        PC_System_Settings__c cSetting = new PC_System_Settings__c();
        cSetting.PC_Document_Splitter_Class__c = 'Does not exist';
        PC_Database.ins(cSetting);

        try {
            PC_DocumentService.splitDocument(parentDocument, childDocuments);
            System.assert(false, 'Expected a SplitException since registered class does not exit');
        } catch (PC_Document.SplitException e) {
            // Already mentioned above in system.assert

        }

        cSetting.PC_Document_Splitter_Class__c = 'PC_Test_DocumentService';
        PC_Database.upd(cSetting);

        try {
            PC_DocumentService.splitDocument(parentDocument, childDocuments);
            System.assert(false, 'Expected a SplitException since registered class does not implement the correct interface');
        } catch (PC_Document.SplitException e) {
            // Already mentioned above in system.assert
        }

        cSetting.PC_Document_Splitter_Class__c = 'PC_Test_DocumentService.TestSplitter';
        PC_Database.upd(cSetting);

        try {
            PC_DocumentService.splitDocument(parentDocument, null);
        } catch (PC_Document.SplitException e) {
            System.assert(false, 'Was not expecting a failure, since everything was setup properly');
        }
    }

    public class TestSplitter implements PC_Document.Splitter {
        public void splitDocument(PC_Document__c parentDoc, PC_Document__c[] childDocs) {
            System.debug('splitting!');
        }
    }
}