({ 
    showSpinner : function (component, event, helper) {
        var spinner = component.find('spinner');
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : true });
        evt.fire();    
    },
    hideSpinner : function (component, event, helper) {
       var spinner = component.find('spinner');
       var evt = spinner.get("e.toggle");
       evt.setParams({ isVisible : false });
       evt.fire();    
    },
    
	doInit : function(component, event, helper) {
        helper.setNamespace(component);
        var patient = component.get("v.patientId");
        
        /*
         * [PC-1610] call to check if objects are excluded from linking
         */
        helper.getExcludedObjectsList (component, event);
        
        if(typeof patient != 'undefined') {
            helper.getAdverseEventObjectInUse(component, event, patient);
            helper.getProgramList(component, event, patient);
            helper.getAdverseEventsList(component, event, patient);
            helper.getInteractionList(component, event, patient);
            helper.getAccountDetails(component, event, patient);
        }
    },
    linkToProgram : function(component, event, helper) {
        helper.linkProgram(component, event, helper);
        
    },
    getSelectedAdverseEvents : function(component, event, helper) {
        helper.linkToSelectedAdverseEvents(component, event, helper);
    },
    getSelectedInteractions : function(component, event, helper) {
        helper.linkToSelectedInteractions(component, event, helper);
    },
    getAcctSelected : function(component, event, helper) {
    	helper.linkAccount(component, event, helper);
    },
    getSelectedAdverseEvents2 :function(component, event, helper) {
        helper.linkToSelectedAdverseEvents2(component, event, helper);
    },
    closeWindow : function(component, event, helper) {          
        component.set("v.patientId", null);
        component.set("v.account", []);
        component.set("v.accountSelected", null);
        component.set("v.programIds", []);
        component.set("v.selectedAdverseEventList", []);
        component.set("v.selectedAdverseEvent2List", []);
        component.set("v.selectedInteractionList", []);         
        component.set("v.showMessage", false);
        
        component.set("v.interactionList", []);
        component.set("v.programList", []);
        component.set("v.adverseEventList", []);
        
        helper.closeWindow(component);   
    },
    saveDocumentLogs : function(component, event, helper) {
        helper.saveLogs(component);    
    },
    goToSelectedLink : function(component, event, helper) {
        var objectId = event.currentTarget.id;
        window.open('/one/one.app#/sObject/' + objectId + '/view', '_blank',  "toolbar=yes,scrollbars=yes,resizable=yes,left=1050,top=100,width=800,height=800");
    },
   
})