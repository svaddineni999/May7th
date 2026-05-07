/******************************************************************************
  Modification Log:
  -----------------------------------------------------------------------------
  Developer             Date        Description
  -----------------------------------------------------------------------------
  Mike Klumpenaar       2018-01-25  New wrapper class for document plugins
Haritha Reddy         21-Jan-2021              [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
 ******************************************************************************/

/**
 * The PC_Document class provides support for custom document service implementations.
 *
 * @author mklumpenaar
 * @date 1/25/2018.
 */
global with sharing class PC_Document {
    /**
     * The Splitter interface can be implemented and registered in the
     * <code>PC_System_Settings.PC_PC_Document_Splitter_Class__c</code> custom setting to provide a
     * document splitter service implementation. The Splitter is responsible for calling the external
     * service with the necessary information to perform splitting.
     */
    global interface Splitter {
        /**
         * Splits the parent attachment into a separate attachment for each child document.
         * The split documents should be attached to the corresponding child documents.
         * This method should throw a <code>SplitException</code> if there is a problem calling
         * the external service.
         *
         * @param parentDoc The parent document containing the attachment to split.
         * @param childDocs The child document containing the page ranges to split on.
         */
        void splitDocument(PC_Document__c parentDoc, PC_Document__c[] childDocs);
    }

    /**
     * Exception to be thrown when there is a problem with the Splitter.
     */
    global inherited sharing class SplitException extends Exception {}
}