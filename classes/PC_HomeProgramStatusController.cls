/*********************************************************************************************************
Class Name      : PC_HomeProgramStatusController
Description     : Controller for the Home Page Status Indicators
Created By      : Deloitte
Created Date    : June 30, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------            
Cameron Reid                    June 30, 2016			Initial Version
Ajinkya Deshmukh				June 20, 2017			FLS Check Added (Code Merge)
Mayuresh Patil                  July 26, 2017           Updated CRUD/FLS Check
Tejas Patel						Nov 8, 2017				Removed unused variable private static final string PC_PROGRAMTYPE_AHDERENCE = 'Adherence';
Haritha Reddy                   Dec 16, 2019           [PC-5791] Replaced createExceptionLog method with logAndThrowException
Hitha Avalakki                  Feb 23, 2021           [PC-7442] Replaced the use of DeveloperName with 'Type' field of Case object to decide if its a program case record
Hitha Avalakki                  Mar 19, 2021           [PC-7533] Replaced constant CASE_PROGRAM_RECORD_TYPE_NAME to CASE_PROGRAM_TYPE
****************************************************************************************************************/
public with sharing class PC_HomeProgramStatusController {

    private static final string PC_CASE_RECORDTYPE_PROGRAM = 'PC_Program';
    
    /*********************************************************************************
    Method Name    : getProgramCaseStatus
    Description    : retrieve Overdue Activities
    Return Type    : List<programStatusResults>     
    *********************************************************************************/ 
    @AuraEnabled
    public static List<programStatusResults> getProgramCaseStatus() {
        List<programStatusResults> lstProgramStatus = new List<programStatusResults>();        
        
        try {
            
            List<String> fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Status_Indicator_4__c'), PC_Constants.getQualifiedAPIName('PC_Status_Indicator_2__c')};
            PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);

            fields = new List<String>{'ParentID', 'MemberID'};
            PC_Database.assertAccess(PC_Constants.PC_CASETEAMMEMBER,PC_Database.Operation.Reading, fields);

            /* [PC-7442] Replaced the use of DeveloperName with 'Type' field of Case object to decide if its a program case record */
            AggregateResult[] resultsCompliance = [SELECT count(Id) cnt, PC_Status_Indicator_4__c stat FROM Case WHERE Type=:PC_Constants.CASE_PROGRAM_TYPE AND ID IN (SELECT ParentID FROM CaseTeamMember WHERE MemberID = :userinfo.getUserID()) GROUP BY PC_Status_Indicator_4__c];
            AggregateResult[] resultsCoverage = [SELECT count(Id) cnt, PC_Status_Indicator_2__c stat FROM Case WHERE Type=:PC_Constants.CASE_PROGRAM_TYPE AND ID IN (SELECT ParentID FROM CaseTeamMember WHERE MemberID = :userinfo.getUserID()) GROUP BY PC_Status_Indicator_2__c];

            //Get results in a wrapper form
            programStatusResults psrCompliance = getProgramStatusResults(resultsCompliance, PC_Constants.CASE_PROGRAMTYPE_AHDERENCE );            
            programStatusResults psrCoverage = getProgramStatusResults(resultsCoverage, PC_Constants.CASE_PROGRAMTYPE_COVERAGE );    
            
            //Add to output
            lstProgramStatus.add(psrCompliance);
            lstProgramStatus.add(psrCoverage);
        }
        catch(exception e) {
            PC_Utility.logAndThrowException(e);
        }
        
        return lstProgramStatus;
    }
    
    /*********************************************************************************
    Method Name    : getProgramStatusResults
    Description    : extract the program status results from the aggregate results
    Return Type    : programStatusResults  
    @Param1        : results, a list of aggregate results to iterage through   
    @Param2        : type, the type of result
    *********************************************************************************/ 
    private static programStatusResults getProgramStatusResults(AggregateResult[] results, String type) {
        
        //Sum all the different statuses of results
        Double totalCount = 0;
        Double notCompletedCount = 0;
        
        for (AggregateResult ar1:results) {
            Double tmpCount = (Double)ar1.get('cnt');
            String tmpStat = (String)ar1.get('stat');
            
            //Don't count Completed activities in the to be completed count
            if(tmpStat != PC_Constants.CASE_INDICATOR_INCOMPLIANT ) {
                notCompletedCount += tmpCount;
            }                
            //Add all counts to totalCount, regardless of status
            totalCount += tmpCount;
        }         
        
        programStatusResults psr = new programStatusResults(type , notCompletedCount , totalCount);
        return psr;
    }
    
    public class programStatusResults {
        @AuraEnabled public Double completed {get;set;}
        @AuraEnabled public Double total {get;set;}        
        @AuraEnabled public Double completedPercentage {get;set;}
        @AuraEnabled public String type {get;set;}
        
        public programStatusResults (String type, Double iCompleted, Double iTotal) {
            this.type = type;
            
            if (iCompleted >= 0 && iTotal >= 0) {
                this.completed = iCompleted;
                this.total = iTotal;
                
                if (iTotal == 0) {
                    this.completedPercentage = 0.0;
                }
                else {
                    //Double perTmp = this.completed / this.total;
                    this.completedPercentage = (Decimal)(this.completed / this.total);
                }
            }
            else {
            	
                this.completed = 0;
                this.total = 0;
                this.completedPercentage = 0.0;
            }   
        }
    } 
 }