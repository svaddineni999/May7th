({
	doInit : function(component, event, helper) {
        helper.getEmailDetails(component);
    },
    doneRendering: function(component, event, helper) {
    	helper.doneRendering(component, event);
    },
    showAccordion : function(component, event, helper) {
       helper.showHideSection(component,event,'articleOne');
    },
    goToSelectedLink : function(component, event, helper) {
    	var objectId = event.currentTarget.id;
       window.open('/one/one.app#/sObject/' + objectId + '/view', '_blank',  "toolbar=yes,scrollbars=yes,resizable=yes,left=1050,top=100,width=800,height=800");
        /*
        var navEvt = $A.get("e.force:navigateToSObject");
    	navEvt.setParams({
      		"recordId": objectId,
      		"slideDevName": "detail"
        });
    	navEvt.fire();
        */
    }
})