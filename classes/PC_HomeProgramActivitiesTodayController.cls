/*********************************************************************************************************
Class Name      : PC_HomeProgramActivitiesTodayController 
Description     : Controller for the Home Page Status Indicators
Created By      : Deloitte
Created Date    : June 30, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Cameron Reid                    June 30, 2016         	Initial Version
Ajinkya Deshmukh				June 08, 2017			FLS Check Added
Mayuresh Patil                  July 26, 2017           Updated FLS/CRUD Checks
Haritha Reddy                   Dec 16, 2019           [PC-5791] Replaced createExceptionLog method with logAndThrowException
****************************************************************************************************************/
public with sharing class PC_HomeProgramActivitiesTodayController {
    //Completed
    public static final String PC_ACTIVITY_STATUS_COMPLETED = 'Completed';
    
    /*********************************************************************************
    Method Name    : getTodaysActivities
    Description    : retrieve Today's Activities
    Return Type    : activityTotalWrapper     
    *********************************************************************************/ 
    @AuraEnabled
    public static activityTotalWrapper getTodaysActivities() {
        
        Integer totalCount = 0;
        Integer completedCount = 0;
        try {
			/*
			* FLS Check for Task
			*/
			List<String> fields = new List<String>{'Status', 'ActivityDate'};
            PC_Database.assertAccess(PC_Constants.PC_TASK,PC_Database.Operation.Reading, fields);

            AggregateResult[] results = [SELECT count(ID) cnt, status stat FROM Task
                                         WHERE OwnerId =: userinfo.getUserID() AND ActivityDate = TODAY GROUP BY status];

            //Sum all the different statuses of results
            for (AggregateResult ar1:results) {
                Integer tmpCount = (Integer)ar1.get('cnt');
                String tmpStat = (String)ar1.get('stat');
                
                //Don't count Completed activities in to be completed count
                if(tmpStat == PC_ACTIVITY_STATUS_COMPLETED) {
                    completedCount += tmpCount;
                }                
                //Add all counts to totalCount, regardless of status
                totalCount += tmpCount;
            }
        }
        catch(exception e) {
            PC_Utility.logAndThrowException(e);
        }
        activityTotalWrapper atw = new activityTotalWrapper(completedCount,totalCount);    
        return atw;
    }
    
    /*********************************************************************************
    Class Name    : activityTotalWrapper
    Author        : Cameron Reid
    Description   : Wrapper class for Activity Total Information
    *********************************************************************************/
    public class activityTotalWrapper {
        @AuraEnabled public Double completed {get;set;}
        @AuraEnabled public Double total {get;set;}        
        @AuraEnabled public Double completedPercentage {get;set;}
        
        public activityTotalWrapper (Double iCompleted, Double iTotal) {
            
            if(iCompleted >= 0 && iTotal > 0) {
                this.completed = iCompleted;
                this.total = iTotal;
                
                //Double perTmp = this.completed / this.total;
                this.completedPercentage = (Decimal)(this.completed / this.total);               
            }
            else {            
                this.completed = 0;
                this.total = 0;
                this.completedPercentage = 0.0;
            }
        }
    }
 }