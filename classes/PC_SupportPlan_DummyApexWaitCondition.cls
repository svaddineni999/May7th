/**
 * Created by mapatil on 4/4/2018.
 */
/*********************************************************************************
Class Name      : PC_SupportPlan_DummyApexWaitCondition
Description        : Dummy class for testing Support plan
Created By        : mapatil
Created Date     : 4/4/2018
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------           
mapatil                   4/4/2018                   Initial Version
<Developer Name>          <DD-Mon-YY>               [JIRA ticket#]<Methods added/updated; Short description of change, if relevant>
*********************************************************************************/

public with sharing class PC_SupportPlan_DummyApexWaitCondition implements PC_SupportPlan.Condition {

    public boolean evaluate(Id caseId)
    {
        Boolean result;
        Case selectedCase = [SELECT Id, PC_Enrollment_Date__c, PC_Treatment_Start_Date__c
                 FROM Case
                WHERE Id =:caseId];

        if(selectedCase.PC_Enrollment_Date__c != null){
            result= true;
        }
        else{
            result = false;
        }
        return result;
    }
}