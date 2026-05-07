/*********************************************************************************************************
Class Name      : PC_ActivityService
Description     : This class will be used to create task records on different events.
Created By      : Roxana Ivan
Created Date    : July 22, 2016
Modification Log:
-------------------------------------------------------------------------------------------------------------- 
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------            
Roxana Ivan                                  	Initial Version
Tejas Patel					Nov 7, 2017		 	Created variable eLetter_Label
************************************************************************************************************/
public with sharing class PC_ActivityService {
    private static String eLetter_Label = System.Label.PC_eLetter_Label;

    /*********************************************************************************
    Method Name    : eLetterTask
    Description    : Create a tasks of letter type for every created fax / document sent
    *********************************************************************************/
    public static Task eLetterTask(Id objId, Id documentId, String sSubject) {
        Task task = new Task();
        task.WhatId = objId;

        task.RecordTypeId = PC_SYSTEM.recordTypeId(PC_Constants.PC_TASK, PC_Constants.PC_ELETTER);
        if (documentId != null) {
            task.PC_Document__c = documentId;
        }
        task.Description = eLetter_Label + sSubject;
        task.Subject = (sSubject == null ? eLetter_Label : eLetter_Label + ' - ' + sSubject);
        task.ActivityDate = system.today();
        task.Status = Label.PC_Completed;

        return task;
    }
}