({
	doInit : function(component, event, helper) {
        var caseId = component.get("v.recordId");
        helper.getStages(component, caseId); 
        helper.getPreviousStageH(component, caseId); 
    }
})