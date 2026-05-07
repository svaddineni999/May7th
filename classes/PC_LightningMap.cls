/*********************************************************************************
Class Name      : PC_LightningMap
Description     : Wrapper for Lightning Map structure
Created By      : Deloitte               
Created Date    : June 03, 2016
Modification Log:
---------------------------------------------------------------------------------- 
Developer              Date                   Description
-----------------------------------------------------------------------------------            
Roxana Ivan        June 03, 2016            Initial Version
Vijay Kashikar     May 24, 2021             Added access modifiers to the aura enabled properties.
*********************************************************************************/
public with sharing class PC_LightningMap {
    public PC_LightningMap(String cName, String cValue) {
            name = cName;
            value = cValue;
     }
     @AuraEnabled
     public String name {get;set;}

    @AuraEnabled
     public String value {get;set;}
}