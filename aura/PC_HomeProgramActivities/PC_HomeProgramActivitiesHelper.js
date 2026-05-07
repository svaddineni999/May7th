({
	getStarredActivities: function(component) {
        var action = component.get("c.getStarredActivities");
        var filter = component.get("v.filter");
        action.setParams({
            "fromDate":null,
            "toDate":null,
            "filter":filter
        });
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS"){
                component.set("v.lstStarredActivity", a.getReturnValue());
            } else if (a.getState() ==="ERROR"){
                var errors = a.getError();
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
    getOverDueActivities: function(component) {
        var action = component.get("c.getOverDueActivities");
        var filter = component.get("v.filter");
        action.setParams({
            "fromDate":null,
            "toDate":null,
            "filter": filter
        });
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS") {
                component.set("v.lstOverDueActivity", a.getReturnValue());
            } else if (a.getState() ==="ERROR"){
                var errors = a.getError();
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
    getTodayDueActivities: function(component) {
        var action = component.get("c.getActivitiesDueToday");
        var filter = component.get("v.filter");
        action.setParams({
            "fromDate":null,
            "toDate":null,
            "filter": filter
        });
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS"){
                component.set("v.lstTodayDueActivity", a.getReturnValue());
            } else if (a.getState() ==="ERROR"){
                var errors = a.getError();
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
    getTomorrowDueActivities: function(component) {
        var action = component.get("c.getActivitiesDueTomorrow");
        var filter = component.get("v.filter");
        action.setParams({
            "fromDate":null,
            "toDate":null,
            "filter": filter
        });
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS") {
                component.set("v.lstTomorrowDueActivity", a.getReturnValue());
            } else if (a.getState() ==="ERROR"){
                var errors = a.getError();
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
    }
})