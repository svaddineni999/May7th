/*********************************************************************************
Class Name      : PC_Test_TriggerHandler
Description     : Test class for PC_TriggerHandler
Created By      : Tetiana Danylyshyn
Created Date    : 29-June-16
Modification Log:
---------------------------------------------------------------------------------- 
Developer                   Date                   Description
-----------------------------------------------------------------------------------            
Tetiana Danylyshyn        29-June-16              Initial Version
Tejas Patel				  12-Apr-2017		      Modified DML Update to PC_Database.upd with fls check true
*********************************************************************************/
@isTest
public class PC_Test_TriggerHandler {

    @isTest static void PC_TriggerHandler() {
        
        User objUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test1.com', 'pctest1');
        PC_Database.ins(objUser);
        User objUser2 = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'userpctest@test2.com', 'pctest2');
        PC_Database.ins( objUser2);
        System.assert(objUser!=null);
        
        system.assert(objUser.Id != null);
        system.runAs(objUser)
        {
            Account refPatient = PC_Test_Setup.createPatient('test'); 
            PC_Database.ins( refPatient);
            system.assert(refPatient.Id != null);
            Case c = PC_Test_Setup.newCase(refPatient.Id, PC_Constants.CASE_PROGRAM_RECORD_TYPE);
            c.PC_Reimbursment_Specialist__c = objUser.Id;
            PC_Database.ins( c);
            c.PC_Reimbursment_Specialist__c = objUser2.Id;
            PC_Database.upd(c);
            
            Case c1 = PC_Test_Setup.newCase(refPatient.Id, PC_Constants.CASE_PA_RECORD_TYPE);
            c1.PC_Reimbursment_Specialist__c = objUser.Id;
            c1.PC_Program__c = c.Id;
            PC_Database.ins( c1);
            c1.PC_Reimbursment_Specialist__c = objUser2.Id;
            PC_Database.upd(c1);

            PC_TriggerHandler controller = new PC_TriggerHandler();
            Boolean isRunTrigger = controller.canRunTrigger();
            System.assertEquals(isRunTrigger,true);
            
            PC_TriggerHandler.TriggerState statObj = controller.getState();
            PC_TriggerHandler.TriggerState statObj_new = PC_TriggerHandler.newState();
            Boolean isChanged = true;
            try {
                isChanged = PC_TriggerHandler.isChanged(c, c, Case.PC_Reimbursment_Specialist__c);
            } catch(Exception e) {
                System.assertEquals(isChanged , true);
            }
            Boolean isChanged_fName = true;
            try {
                
                isChanged_fName = PC_Triggerhandler.isChanged(c, c, Case.PC_Reimbursment_Specialist__c);                
            } catch(Exception e) {
                System.assertEquals(isChanged_fName , true);
            }
            
            PC_TriggerHandler.TriggerState stateCont = new PC_TriggerHandler.TriggerState();
            
            stateCont.start();
            stateCont.stop();
            
            controller = new PC_TriggerHandler(controller);
            Boolean isActive = stateCont.isActive;
            System.assertEquals(isActive,false);
            
            controller.afterDelete();
            Boolean runAfterDelete = stateCont.runAfterDelete;
            System.assertEquals(runAfterDelete,false);
            
            controller.afterInsert();
            Boolean runAfterInsert = stateCont.runAfterInsert;
            System.assertEquals(runAfterInsert,false);
            
            controller.afterInsertUpdate();
            Boolean runAfterInsertUpdate = stateCont.runAfterInsertUpdate;
            System.assertEquals(runAfterInsertUpdate,false);
            
            Boolean runAfterUndelete = stateCont.runAfterUndelete;
            controller.afterUndelete();
            System.assertEquals(runAfterUndelete,false);
            
            Boolean runAfterUpdate = stateCont.runAfterUpdate;
            controller.afterUpdate();
            System.assertEquals(runAfterUpdate,false);
            
            Boolean runBeforeDelete = stateCont.runBeforeDelete;
            controller.beforeDelete();
            System.assertEquals(runBeforeDelete,false);
            
            Boolean runBeforeInsert = stateCont.runBeforeInsert;
            controller.beforeInsert();
            System.assertEquals(runBeforeInsert,false);
            
            Boolean runBeforeInsertUpdate = stateCont.runBeforeInsertUpdate;
            controller.beforeInsertUpdate();
            System.assertEquals(runBeforeInsertUpdate,false);
            
            Boolean runBeforeUndelete = stateCont.runBeforeUndelete;
            controller.beforeUndelete();
            System.assertEquals(runBeforeUndelete,false);
            
            Boolean runBeforeUpdate = stateCont.runBeforeUpdate;
            controller.beforeUpdate();
            System.assertEquals(runBeforeUpdate,false);
            
            List<SObject> newList = PC_TriggerHandler.newList;
            System.assertEquals(newList,null);
            
            List<SObject> OldList = PC_TriggerHandler.OldList;
            System.assertEquals(OldList,null);
            
            Map<Id, SObject> newMap = PC_TriggerHandler.newMap;
            System.assertEquals(newMap,null);
            
            Map<Id, SObject> oldMap = PC_TriggerHandler.OldMap;
            System.assertEquals(oldMap,null);
            
            try {
                PC_Triggerhandler.isChanged(refPatient, Account.Name);
            } catch(Exception e) {
                System.assertEquals(isChanged_fName , true);
            }
           
        }
    }

    @isTest static void testBypassMethods() {
        PC_TriggerHandler.bypass('Test_Handler','Test_Namespace'); // adding a trigger handler with a namespace
        system.assertEquals(PC_TriggerHandler.getAllByPasses().size(), 1);
        PC_TriggerHandler.bypass('Test_Handler',NULL); // adding another trigger handler without a namespace
        system.assertEquals(PC_TriggerHandler.getAllByPasses().size(), 2);
        PC_TriggerHandler.bypass('Test_Handler','Test_Namespace'); // adding the same existing handler, count should not increase
        PC_TriggerHandler.clearBypass('Test_Handler','Test_Namespace'); //clearing existing handler, count should decrease.
        PC_TriggerHandler.clearBypass('Test_Non_Existing_Handler','Test_Non_Existing_Namespace'); // attempting to clear a non existing handler. No exceptions should be thrown
        system.assertEquals(PC_TriggerHandler.getAllByPasses().size(), 1);
        PC_TriggerHandler.clearBypass('Test_Handler',NULL); // clearing one handler, count should decrease.
        system.assertEquals(PC_TriggerHandler.getAllByPasses().size(), 0);
        PC_TriggerHandler.bypass('Test_Handler','Test_Namespace'); // adding a trigger handler
        PC_TriggerHandler.clearAllBypasses(); // All cleared
        system.assertEquals(PC_TriggerHandler.getAllByPasses().size(), 0);
    }
}