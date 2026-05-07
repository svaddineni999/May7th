/*********************************************************************************************************
Class Name    	: PC_Conditional_Bldr_Controller
Description     : Control the conditional builder component inside activity properties panel on support
                  plan builder screen
Created By      : Deloitte
Created Date    : Jun 19, 2018
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                  Date                   Description
--------------------------------------------------------------------------------------------------------------
Vivek Kumar Mishra       Jun 19, 2018           Initial Version
Tejas Patel              Feb 22, 2019           [PC-3491] Sorting the Picklist Values
Haritha Reddy            Dec 11, 2019           [PC-5791] Implemented Error handling for all methods
Kishore Kanteti          Mar 19,2020            [PC-6057] Added boolean parameter in getAllPicklistValue,getPicklistValues methods
Tushar Arora             Apr 04,2020            [PC-6052] Added functionality for pulling lookup field Object detail.
Tushar Arora             Apr 22,2020            [PC-6210] modified logic for retrieving qualifiedAPIName instead of the developer Name.
Kishore Kanteti          Jun 4,2020            [PC-6202] Added logic at line 74 for removing isDeleted and autonumber fields.
Kishore Kanteti          July 27,2020          [PC-6494] Added logic for removing non-updateable fields in update record context.
****************************************************************************************************************/


public with sharing class PC_Conditional_Bldr_Controller {
    //Class deprecated. Instead of this class we are currently using PC_PropertiesAndConditionsBuilder.
}