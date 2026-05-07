/*
Class Name      : PC_Case_ShowPatientAge_ExtController
Description     :
Created By      : Vijay Kashikar
Created Date    :
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Ajinkya Deshmukh            6/27/2017               with sharing keyword added
*/
public with sharing class PC_Case_ShowPatientAge_ExtController {
	private final Case c;
    
    // The extension constructor initializes the private member
    // variable acct by using the getRecord method from the standard
    // controller.
    public PC_Case_ShowPatientAge_ExtController(ApexPages.StandardController stdController) {
        this.c = (Case)stdController.getRecord();
    }
    
    public String getAge() {
        
        Id caseId = this.c.Id;
    	/*
        * FLS Check for PC_Association__c
        */
    	List<String> fields = new List<String>{'AccountId'};
        PC_Database.assertAccess(PC_Constants.PC_CASE,PC_Database.Operation.Reading, fields);
        Case currentCase = [SELECT AccountId FROM Case WHERE Id = :caseId];
        Id aId = currentCase.AccountId;
        
        integer age = -2;
        
        if(aId != null) {
        	/*
        * FLS Check for PC_Association__c
        */
    	fields = new List<String>{PC_Constants.getQualifiedAPIName('PC_Date_of_Birth__c')};
        PC_Database.assertAccess(PC_Constants.PC_ACCOUNT,PC_Database.Operation.Reading, fields);
            Account a = [SELECT PC_Date_of_Birth__c FROM Account where Id = :aId];
            Date Birthdate = a.PC_Date_of_Birth__c;
            Date thisDay = Date.today();
            
            if(Birthdate != null) {
                if( (Birthdate.month() * 100 + Birthdate.day()) <= (thisDay.month() * 100 + thisDay.day())) {
                    age = thisDay.year() - Birthdate.year();
                }
                else {
                    age = thisDay.year() - Birthdate.year() - 1;
                }
            }
            else {
                age = -1;
            }
        }    
        return age.format();
    }
    
}