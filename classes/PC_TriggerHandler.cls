/*********************************************************************************************************
Class Name      : PC_TriggerHandler
Description     :
Created By      : Deloitte
Created Date    : April 1, 2015
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------
Deloitte               April 1, 2015              Initial Version
Prachi Nandgaonkar     Jan 30 2017                Updated all class and methods to 'global' to allow derived classes
												  to inherit for trigger handlers
Xiukai Ning            Feb 28, 2019               PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                  Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                  We are removing all FLS and With Sharing keywords in the handlers.
Tushar Arora           Jan 03,2020                [PC-5816]Updating the Salesforce Api Version of PC_TriggerHandler Class.
Tushar Arora           feb 25,2020                [PC-6019]Updating the Salesforce Api Version to 48.0 of PC_TriggerHandler Class.
Vijay Kashikar         Jul 05, 2022               [PC-8722] Added logic to bypass Trigger Handler Registers
****************************************************************************************************************/
/**
 *   This class contains methods for each trigger event type which can be inherited by Trigger handlers.
 */
global virtual class PC_TriggerHandler {
    
    global virtual void beforeInsert(){}
    global virtual void afterInsert(){}
    global virtual void beforeUpdate(){}
    global virtual void afterUpdate(){}
    global virtual void beforeInsertUpdate(){}
    global virtual void afterInsertUpdate(){}
    global virtual void beforeDelete(){}
    global virtual void afterDelete(){}
    global virtual void beforeUndelete(){}
    global virtual void afterUndelete(){}
    protected PC_TriggerHandler NEXT_TRIGGER;

    /**
     * Collection to store bypassed handler. Implementation reference - https://github.com/kevinohara80/sfdc-trigger-framework. Enhanced to support Namespaces.
     */
    private static Set<String> bypassedHandlers;

    // static initialization of bypassedHandlers
    static {
        bypassedHandlers = new Set<String>();
    }

    /**
     * Method to add a handler to list of bypassed handlers.
     *
     * @param handlerName Developer name of the Trigger Handler Register
     */
    private static void bypass(String handlerName) {
        bypassedHandlers.add(handlerName);
    }

    /**
     * Method to add a handler to list of bypassed handlers.
     *
     * @param handlerName Developer name of the Trigger Handler Register
     * @param namespacePrefix Namespace Prefix of the Trigger Handler Register
     */
    global static void bypass(String handlerName, String namespacePrefix) {
        if(String.isNotBlank(namespacePrefix)) {
            bypassedHandlers.add(namespacePrefix + '__' + handlerName);
        }
        else {
            bypass(handlerName);
        }
    }

    /**
     * Get all the bypassed Trigger Handler Registers
     *
     * @return Collection of bypassed Trigger Handler Registers
     */
    global static Set<String> getAllByPasses() {
        return bypassedHandlers;
    }

    /**
     * Clears a Trigger Handler Register from the list of bypassed Trigger Handler Registers
     *
     * @param handlerName Developer name of the Trigger Handler Register
     */
    private static void clearBypass(String handlerName) {
        if(isBypassed(handlerName)) {
            bypassedHandlers.remove(handlerName);
        }
    }

    /**
     * Clears a Trigger Handler Register from the list of bypassed Trigger Handler Registers
     *
     * @param handlerName Developer name of the Trigger Handler Register
     * @param namespacePrefix Namespace Prefix of the Trigger Handler Register
     */
    global static void clearBypass(String handlerName, String namespacePrefix) {
        if(String.isNotBlank(namespacePrefix)) {
            if(isBypassed(namespacePrefix + '__' + handlerName)) {
                bypassedHandlers.remove(namespacePrefix + '__' + handlerName);
            }
        }
        else {
            clearBypass(handlerName);
        }
    }

    /**
     * Checks if a Trigger Handler Register is bypassed.
     *
     * @param handlerName Developer name of the Trigger Handler Register
     *
     * @return true if Trigger Handler is bypassed, otherwise false.
     */
    private static Boolean isBypassed(String handlerName) {
        return bypassedHandlers.contains(handlerName);
    }

    /**
     * Checks if a Trigger Handler Register is bypassed.
     *
     * @param handlerName Developer name of the Trigger Handler Register
     * @param namespacePrefix Namespace Prefix of the Trigger Handler Register
     *
     * @return true if Trigger Handler is bypassed, otherwise false.
     */
    global static Boolean isBypassed(String handlerName, String namespacePrefix) {
        if(String.isNotBlank(namespacePrefix)) {
            return bypassedHandlers.contains(namespacePrefix + '__' + handlerName);
        }
        else {
            return isBypassed(handlerName);
        }
    }

    /**
     * Clears all the bypassed Trigger Handler Registers.
     */
    global static void clearAllBypasses() {
        bypassedHandlers.clear();
    }
    
    global PC_TriggerHandler(){}
    
    global PC_TriggerHandler(PC_TriggerHandler pNextTrigger){
        NEXT_TRIGGER = pNextTrigger;
    }
    
    global static List<SObject> newList{get{return Trigger.new;}}
    global static List<SObject> oldList{get{return Trigger.old;}}
    global static Map<Id, SObject> newMap{get{return Trigger.newMap;}}
    global static Map<Id, SObject> oldMap{get{return Trigger.oldMap;}}
    
    public void execute(String source){
        try {
            PC_SYSTEM.setTriggerSource(source);
            execute();
        }
        catch(Exception ex) {
            if (PC_SYSTEM.isTriggerSource(source) && ApexPages.currentPage() != null) {
                PC_Utility.createExceptionLog(ex, PC_Utility.DISPLAY_ERROR);
            } else {
                throw ex;
            }
        }
    }
    
    public void execute(){
        System.Assert(Trigger.isExecuting, 'Cannot Execute Trigger: PC_TriggerHandler is called outside of trigger context');
        
        if(!getState().isActive || !canRunTrigger())
            return;
        
        if(getState().runBeforeInsert){
            beforeInsert();
        }
        else if(getState().runAfterInsert){
            afterInsert();
        }
        
        if(getState().runBeforeUpdate){
            beforeUpdate();
        }
        else if(getState().runAfterUpdate){
            afterUpdate();
        }
        
        if(getState().runBeforeInsertUpdate){
            beforeInsertUpdate();
        }
        else if(getState().runAfterInsertUpdate){
            afterInsertUpdate();
        }
        
        if(getState().runBeforeDelete){
            beforeDelete();
        }
        else if(getState().runAfterDelete){
            afterDelete();
        }
        
        if(getState().runBeforeUndelete){
            beforeUndelete();
        }
        else if(getState().runAfterUndelete){
            afterUndelete();
        }
        
        // Run next trigger in chain.
        if(NEXT_TRIGGER != null){
            NEXT_TRIGGER.Execute();
        }
    }
    
    public virtual Boolean canRunTrigger(){
        return true;
    }
    
    public static TriggerState triggerState = new TriggerState();
    public virtual TriggerState getState(){
        return triggerState;
    }
    
    // TriggerState, to manage trigger execution flow.
    public class TriggerState{
        public TriggerState(){
            start();
        }
        // INSERT
        public Boolean runBeforeInsert {
            get{return runBeforeInsert && Trigger.isBefore && Trigger.isInsert;}
            public set;
        }
        public Boolean runAfterInsert {
            get{return runAfterInsert && Trigger.isAfter && Trigger.isInsert;}
            public set;
        }
        // UPDATE
        public Boolean runBeforeUpdate {
            get{return runBeforeUpdate && Trigger.isBefore && Trigger.isUpdate;}
            public set;
        }
        public Boolean runAfterUpdate {
            get{return runAfterUpdate && Trigger.isAfter && Trigger.isUpdate;}
            public set;
        }
        // INSERT and UPDATE
        public Boolean runBeforeInsertUpdate {
            get{return runBeforeInsertUpdate && (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate));}
            public set;
        }
        public Boolean runAfterInsertUpdate {
            get{return runAfterInsertUpdate && (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate));}
            public set;
        }
        // DELETE
        public Boolean runBeforeDelete {
            get{return runBeforeDelete && Trigger.isBefore && Trigger.isDelete;}
            public set;
        }
        public Boolean runAfterDelete {
            get{return runAfterDelete && Trigger.isAfter && Trigger.isDelete;}
            public set;
        }
        // UNDELETE
        public Boolean runBeforeUndelete {
            get{return runBeforeUndelete && Trigger.isBefore && Trigger.isUndelete;}
            public set;
        }
        public Boolean runAfterUndelete {
            get{return runAfterUndelete && Trigger.isAfter && Trigger.isUndelete;}
            public set;
        }
        
        public boolean isActive {
            get{return (runBeforeInsert ||
                        runAfterInsert ||
                        runBeforeUpdate ||
                        runAfterUpdate ||
                        runBeforeInsertUpdate ||
                        runAfterInsertUpdate ||
                        runBeforeDelete ||
                        runAfterDelete ||
                        runBeforeUndelete ||
                        runAfterUndelete);
               }
        }
        
        public void start(){
            runBeforeInsert = true;
            runAfterInsert = true;
            runBeforeUpdate = true;
            runAfterUpdate = true;
            runBeforeInsertUpdate = true;
            runAfterInsertUpdate = true;
            runBeforeDelete = true;
            runAfterDelete = true;
            runBeforeUndelete = true;
            runAfterUndelete = true;
        }
        
        public void stop(){
            runBeforeInsert = false;
            runAfterInsert = false;
            runBeforeUpdate = false;
            runAfterUpdate = false;
            runBeforeInsertUpdate = false;
            runAfterInsertUpdate = false;
            runBeforeDelete = false;
            runAfterDelete = false;
            runBeforeUndelete = false;
            runAfterUndelete = false;
        }
    }
    
    public static TriggerState newState(){
        return new TriggerState();
    }
    
    // Security scan FALSE-POSITIVE: the delete call shows FALSE-POSITIVE because checkmarx ignores if isAccessible check.
    public static boolean isChanged(sObject pNewObj, sObjectField pField){
        if(Trigger.IsInsert)
            return pNewObj.get(pField) != null;
        
        sObject oldObj = oldMap.get(pNewObj.id);
        return isChanged(pNewObj, oldObj, pField);
    }
    
    // Security scan FALSE-POSITIVE: the delete call shows FALSE-POSITIVE because checkmarx ignores if isAccessible check.
    public static boolean isChanged(sObject pNewObj, sObject pOldObj, sObjectField pField){
        if(Trigger.IsInsert) {
            return pNewObj.get(pField) != null;
        }
        
        // Note: SFDC Bug: use field name string instead of field; using field fails on "rec. Owner Change".
        String fieldName = pField.getDescribe().getName();
        return isChanged(pNewObj, pOldObj, fieldName);
    }
    
    // Security scan FALSE-POSITIVE: the delete call shows FALSE-POSITIVE because checkmarx ignores if isAccessible check.
    public static boolean isChanged(sObject pNewObj, String fieldName){
        if (Trigger.IsInsert) {
            return pNewObj.get(fieldName) != null;
        }
        
        sObject oldObj = oldMap.get(pNewObj.id);
        return isChanged(pNewObj, oldObj, fieldName);
    }
    
    // Security scan FALSE-POSITIVE: the delete call shows FALSE-POSITIVE because checkmarx ignores if isAccessible check.
    public static boolean isChanged(sObject pNewObj, sObject pOldObj, String fieldName){
        if(Trigger.IsInsert) {
            return pNewObj.get(fieldName) != null;
        }
        return (pNewObj.get(fieldName) != pOldObj.get(fieldName));
    }
}