/**
 * Created by peharitha on 4/2/2019.
 */
({
    fetchProgramCoverageList: function (component, event, helper){
        component.set("v.isLoading", true);
        var action =  component.get("c.getRelProgramCoverages");
        action.setParams({
           caseId: component.get("v.caseId")
        });
        action.setCallback(this, function(response){
            var state= response.getState();
            if (state == "SUCCESS"){
                var returnValue =response.getReturnValue();
                component.set("v.programCoverageList", returnValue.programCoverageList);
                component.set("v.fieldLabels",returnValue.fieldLabels);
            }
            else{
                component.set("v.errors",response.getError());
            }
            component.set("v.isLoading", false);
        });
        $A.enqueueAction(action);
    },
})