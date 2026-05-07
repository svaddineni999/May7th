/**
 * Created by tusarora on 7/22/2020.

Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------------
Haritha Reddy          21-Jan-2021                 [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/

public with sharing class PC_LaunchLogACallController {
    /*********************************************************************************
    Method Name    : getLogACallRecordTypeInfo
    Author         : Tushar Arora
    Description    : This method will fetch Log a call recordType Task.
    Return Type    : Id
    Parameter      : void
    *********************************************************************************/
    @AuraEnabled
    public static Id getLogACallRecordTypeInfo(){


        Id recordTypeLogACallId = Schema.SObjectType.TASK.getRecordTypeInfosByDeveloperName()
                .get(PC_Constants.PC_LOGACALL).getRecordTypeId();

        return recordTypeLogACallId;
    }
}