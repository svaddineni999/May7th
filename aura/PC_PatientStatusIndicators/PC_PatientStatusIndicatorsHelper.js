({
    getPreviousStageH: function(component, caseId) {
        var action = component.get("c.hasPreviousStage");
        action.setParams({
          "caseID": caseId
        });
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS") {
            	component.set("v.hasPreviousStage", a.getReturnValue());
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

	getStages: function(component, caseId) {
        var action = component.get("c.getStages");
        action.setParams({
          "caseID": caseId
        });
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS") {
                var s = a.getReturnValue();
                component.set("v.stages", s);
                for (var i=0; i<s.length; i++){
                    // Process Dynamic Custom Labels for Program Journey Stage Name
                    var stageName = CH_PC_Util.getCustomLabelValue(s[i].stageName);
                    component.set('v.stages.'+i+'.stageName', stageName);
                }
                if (s && s.length > 0) {
                    component.set("v.showButton", true);
                }
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