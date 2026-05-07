({
    doInit : function(component, event, helper) {
        helper.getStarredActivities(component); 
        helper.getOverDueActivities(component); 
        helper.getTodayDueActivities(component);
        helper.getTomorrowDueActivities(component);
        //helper.getFormContent(component, candidatePatientId);
    },
	starActivity : function (component, event, helper) {
		console.log('In Controller');
        helper.starActivity(component); 
    },
    navigateToRecord : function(component, event, helper) {
    	var context = component.get("v.usersContext");
        var objTask  = component.get("v.objTask");
        var rid = objTask.relatedToRecordID ;
        if(context != undefined) {
        	if(context == 'Theme4t' || context == 'Theme4d') {
                sforce.one.navigateToSObject(rid);
            } else {
            	console.log('VF in Classic'); 
                //window.location.assign('/'+rid);
                window.open('/' + rid);
			}
		} else {
			var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
            	"recordId": rid,
                "slideDevName": "related"
            });
            navEvt.fire();
    	}
    }
})