({
    doInit : function(component, event, helper) {
        helper.setNamespace(component);
        helper.toList(component, event);
        helper.getUserAlerts(component);
    },
	gotoList : function (component, event, helper) {
        var context = component.get("v.userContext");
        var action = component.get("c.getListViews");
        action.setCallback(this, function(response){
            var state = response.getState();
            var nsPrefix = component.get("v.namespacePrefix");
            if (state === "SUCCESS") {
                var listviews = response.getReturnValue();
                if(context !== undefined) {
                   if(context === 'Theme4t' || context === 'Theme4d') {
                       sforce.one.navigateToSObject(listviews.Id, null, nsPrefix + "PC_Alert__c");
                   } else {
                       /*window.location.assign('/'+listviews.Id);*/
                       var url = component.get("v.listURL");
                       window.open(url + '?Id='+listviews.Id);
                   }
           		} else {
                    var navEvent = $A.get("e.force:navigateToList");
                    navEvent.setParams({
                        "listViewId": listviews.Id,
                        "listViewName": null,
                        "scope": nsPrefix + "PC_Alert__c"
                    });
                    navEvent.fire();
           		} 
            } else if (state ==="ERROR"){
                    var errors = response.getError();
                    console.log(JSON.stringify(errors));
                    var errText = component.get("v.errorText");
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log(errText);
                        }
                    } else {
                        console.log("Unknown error");
                    }
            }
        });
        $A.enqueueAction(action);
    },
    
    handleTaskUpdated : function(component, event, helper) {
        helper.getUserAlerts(component); 
    }
})