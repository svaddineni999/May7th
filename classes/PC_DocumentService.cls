/******************************************************************************
 Modification Log:
 -----------------------------------------------------------------------------
 Developer              Date        Description
 -----------------------------------------------------------------------------
 Mike Klumpenaar        2018-01-25  New document service class
*******************************************************************************/

/**
 * The PC_DocumentService class provides support for calling document service
 * implementations, such as custom splitting services.
 *
 * @author mklumpenaar
 * @date 1/25/2018.
 */
public with sharing class PC_DocumentService {
    /**
     * Splits the parent document attachment based on the page ranges in the list of child documents
     * and attach the new split files to the corresponding child documents.
     *
     * @param parentDoc The parent document containing the attachment to split.
     * @param childDocs The child documents containing pages ranges for splitting.
     */
    public static void splitDocument(PC_Document__c parentDoc, PC_Document__c[] childDocs) {
        try {
            String documentSplitterClassName = PC_System_Settings__c.getInstance().PC_Document_Splitter_Class__c;
            if (String.isBlank(documentSplitterClassName)) {
                throw new PC_Document.SplitException('No splitter class registered in PC_SystemSettings custom setting');
            }

            Type t = Type.forName(documentSplitterClassName);

            if (t != null) {
                Object o = t.newInstance();

                if (o instanceof PC_Document.Splitter) {
                    PC_Document.Splitter splitter = (PC_Document.Splitter) o;
                    splitter.splitDocument(parentDoc, childDocs);
                } else {
                    throw new PC_Document.SplitException('Registered PC_Document.Splitter, '
                            +  documentSplitterClassName
                            + ' does not implement required interface.');
                }
            } else {
                throw new PC_Document.SplitException('Registered PC_Document.Splitter, '
                        + documentSplitterClassName
                        + ' class not found. Check PC_System_Settings.');
            }
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }
}