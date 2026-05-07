({
    doInit : function(component, event, helper) {
        helper.getStarredActivities(component); 
        helper.getOverDueActivities(component); 
        helper.getTodayDueActivities(component);
        helper.getTomorrowDueActivities(component);
        //helper.getFormContent(component, candidatePatientId);
    },
    
    handleTaskUpdated : function(component, event, helper) {
        console.log("task Event occured");
        helper.getStarredActivities(component); 
        helper.getOverDueActivities(component); 
        helper.getTodayDueActivities(component);
        helper.getTomorrowDueActivities(component);
    }
    
})