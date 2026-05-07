({
	doInit : function(component, event, helper) {
       	helper.getActivityTimelineGroups(component,event,helper);
    },

    showSpinner : function(component, event, helper) {
        component.set("v.isLoading", true);
    },

    hideSpinner : function(component, event, helper) {
        component.set("v.isLoading", false);
    },
})