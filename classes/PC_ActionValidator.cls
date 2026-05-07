/**
 * Class Name      : PC_ActionValidator
 * Description     : Class would be containing interface for Validation Framework as well as for Wrapper for Validation for Document Action Setting
 * Created By      : Tushar Arora
 * Created Date    : 24/01/2020
 * Modification Log:
-----------------------------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------------------------
Deloitte               Jan 24, 2020              Initial Version
Vijay Kashikar         May 04, 2020              Made the class global so that subscribers can implement it.
Vijay Kashikar         21-Jan-21                 [PC-7102] Added sharing clause

 */

/**
 * This class provides the interface to control the accessibility and the visibility of Document Actions
 */
global inherited sharing class PC_ActionValidator {

    /**
     * The ValidationProcessor interface is implemented by the configured Document Action Setting class
     * that need to perform server side Validation processing .
     */
    global interface Validator {
        /**
         * @param actionParams parameter needed for doing visibility check.
         */
        Boolean isVisible(Params actionParams);
        /**
         * @param actionParams instance of Params - parameters needed for doing accessibility check.
         */
        AccessibilityResponse isAccessible(Params actionParams);
    }

    /**
     * Contains properties to capture the result of accessibility check.
     */
    global inherited sharing class AccessibilityResponse {

        /**
        to check the record isAccessible for further process
        */
        @AuraEnabled global Boolean isAccessible ;
        /**
         * In case record doesn't pass the condition then to retrieve Validation Message
         */
        @AuraEnabled global String message ;
        /**
         * to double check the component attribute for which validation needs to be processed
         */
        @AuraEnabled global String componentName ;
    }
    /**
     * Contains properties that act as input to the interface methods.
     */
    global inherited sharing class Params {
        /**
        *Salesforce Id of the record being validated.
        */
        @AuraEnabled global String recordId ;
        /**
         * Component name of the Document Action.
         */
        @AuraEnabled global String componentName ;
    }

}