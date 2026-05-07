/*********************************************************************************************************
Class Name      : PC_Trigger_UpdatePatientFields
Description     : On Creation of Person Account, sync First Name, Last Name, Email, Date of birth
                  Salutation fields of Person Account and Individual Business Account.
Created By      : Kanteti Kishore
Created Date    : July 24, 2019
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                     Description
--------------------------------------------------------------------------------------------------------------
Kanteti Kishore        July 24, 2019                Initial version
Tushar Arora           Jul 31,2019                [PC-5179] Added isPersonAccountExists method from PC_System Class checking ispersonaccount field in Schema.
Tushar Arora           Aug 13,2019                [PC-5308] Removed hardcorded strings with PC_Constants Strings as well as changing the location of PersonAccount Enabled Condition
Tushar Arora           Aug 13,2019                [PC-5263] Updated Code for Birthdate Field population using custom Date of birth field
Tushar Arora           Aug 16,2019                [PC-5183] Updated Code for Email(PersonEmail) field from PC_Email field.
Tushar Arora           Aug 28,2019                [PC-5346] Updated code for adding Update logic to Sync Patient Person Account Fields such as First Name, Last Name, Email, Date of Birth, Salutation
Satheesh Kumar         Nov 16, 2021               [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/

public inherited sharing class PC_Trigger_UpdatePatientFields extends PC_TriggerHandler {

    override public void beforeInsert(){
        insertPopulatePatientName((List<Account>) newList);
    }
    override public void beforeUpdate(){
        updatePopulatePatientName((List<Account>)newList,(Map<Id, Account>) oldMap);
    }

/*********************************************************************************
Method Name    : insertPopulatePatientName
Author         : Kishore Kanteti
Description    : This method populates Patient person account fields associated before person account record is created on Insert.
Return Type    : void
Parameter      : List of incoming account records - Trigger.new
*********************************************************************************/
    public static void insertPopulatePatientName(List<Account> newListAcc) {
        try{
            if(PC_SYSTEM.isPersonAccountEnabled()) {
                Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT , PC_Constants.PATIENT_RECORD_TYPE) ;
                for(Account acc : newListAcc){
                    if(acc.RecordTypeId == recordTypeId) {
                        if(String.IsNotBlank(String.valueof(acc.get(PC_Constants.PC_PA_LAST_NAME))))
                            acc.PC_Last_Name__c = (String) (acc.get(PC_Constants.PC_PA_LAST_NAME)) ;
                        else if (String.IsNotBlank(acc.PC_Last_Name__c))
                            acc.put(PC_Constants.PC_PA_LAST_NAME,acc.PC_Last_Name__c);
                        if(String.IsNotBlank(String.valueof(acc.get(PC_Constants.PC_PA_FIRST_NAME))))
                            acc.PC_First_Name__c =(String) (acc.get(PC_Constants.PC_PA_FIRST_NAME));
                        else if(String.IsNotBlank(acc.PC_First_Name__c))
                            acc.put(PC_Constants.PC_PA_FIRST_NAME,(String) (acc.PC_First_Name__c));
                        if(String.IsNotBlank(String.valueof(acc.get(PC_Constants.PC_PA_PERSON_EMAIL))))
                            acc.PC_Email__c = String.valueof(acc.get(PC_Constants.PC_PA_PERSON_EMAIL));
                        else if(String.IsNotBlank(String.valueof(acc.PC_Email__c)))
                            acc.put(PC_Constants.PC_PA_PERSON_EMAIL,String.valueof(acc.PC_Email__c));
                        if(String.IsNotBlank(String.valueof(acc.get(PC_Constants.PC_PA_PERSON_SALUTATION))))
                            acc.PC_Salutation__c = String.valueof(acc.get(PC_Constants.PC_PA_PERSON_SALUTATION));
                        else if(String.IsNotBlank(acc.PC_Salutation__c))
                            acc.put(PC_Constants.PC_PA_PERSON_SALUTATION,acc.PC_Salutation__c);
                    }
                }
            }
        }
        Catch(Exception ex){
            PC_Utility.createExceptionLog(ex);
        }
    }

    /*********************************************************************************
Method Name    : updatePopulatePatientName
Author         : Tushar Arora
Description    : This method populates Patient person account fields associated before person account record is created on Update.
Return Type    : void
Parameter      : List of incoming account records - Trigger.new
*********************************************************************************/
    public static void updatePopulatePatientName(List<Account> newListAcc, Map<Id, Account> oldAccountMap) {
        try{
            if(PC_SYSTEM.isPersonAccountEnabled()) {
                Id recordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PATIENT_OBJECT , PC_Constants.PATIENT_RECORD_TYPE) ;
                for(Account acc : newListAcc){
                    if(acc.RecordTypeId == recordTypeId) {
                        if(String.IsNotBlank(acc.PC_Last_Name__c) && acc.PC_Last_Name__c != oldAccountMap.get(acc.id).PC_Last_Name__c)
                            acc.put(PC_Constants.PC_PA_LAST_NAME,(String) (acc.PC_Last_Name__c));
                        else if(String.IsNotBlank(String.valueof(acc.get(PC_Constants.PC_PA_LAST_NAME))) && String.valueof(acc.get(PC_Constants.PC_PA_LAST_NAME)) != oldAccountMap.get(acc.id).get(PC_Constants.PC_PA_LAST_NAME))
                            acc.PC_Last_Name__c = String.valueof(acc.get(PC_Constants.PC_PA_LAST_NAME));
                        if(String.IsNotBlank(acc.PC_First_Name__c) && acc.PC_First_Name__c != oldAccountMap.get(acc.id).PC_First_Name__c)
                            acc.put(PC_Constants.PC_PA_FIRST_NAME,(String) (acc.PC_First_Name__c));
                        else if(String.IsNotBlank(String.valueof(acc.get(PC_Constants.PC_PA_FIRST_NAME))) && String.valueof(acc.get(PC_Constants.PC_PA_FIRST_NAME)) != oldAccountMap.get(acc.id).get(PC_Constants.PC_PA_FIRST_NAME))
                            acc.PC_First_Name__c = String.valueof(acc.get(PC_Constants.PC_PA_FIRST_NAME));
                        if(String.IsNotBlank(String.valueof(acc.PC_Email__c)) && String.valueof(acc.PC_Email__c) != oldAccountMap.get(acc.id).PC_Email__c)
                            acc.put(PC_Constants.PC_PA_PERSON_EMAIL,String.valueof(acc.PC_Email__c));
                        else if(String.IsNotBlank(String.valueof(acc.get(PC_Constants.PC_PA_PERSON_EMAIL))) && String.valueof(acc.get(PC_Constants.PC_PA_PERSON_EMAIL)) != oldAccountMap.get(acc.id).get(PC_Constants.PC_PA_PERSON_EMAIL))
                            acc.PC_Email__c = String.valueof(acc.get(PC_Constants.PC_PA_PERSON_EMAIL));
                        if(String.IsNotBlank(acc.PC_Salutation__c) && acc.PC_Salutation__c != oldAccountMap.get(acc.id).PC_Salutation__c)
                            acc.put(PC_Constants.PC_PA_PERSON_SALUTATION,acc.PC_Salutation__c);
                        else if(String.IsNotBlank(String.valueof(acc.get(PC_Constants.PC_PA_PERSON_SALUTATION))) && String.valueof(acc.get(PC_Constants.PC_PA_PERSON_SALUTATION)) != oldAccountMap.get(acc.id).get(PC_Constants.PC_PA_PERSON_SALUTATION))
                            acc.PC_Salutation__c = String.valueof(acc.get(PC_Constants.PC_PA_PERSON_SALUTATION));
                    }
                }
            }
        }
        Catch(Exception ex){
            PC_Utility.createExceptionLog(ex);
        }
    }
}