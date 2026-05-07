/**
 * Created by shisbansal on 6/26/2018.
 */
({
    doInit : function(component, event, helper) {
         debugger;
            var action = component.get("c.getAllPreferredPrayer");
            action.setCallback(this, function(response){
                var state = response.getState();
                if (state === "SUCCESS" ) {
                    if(response.getReturnValue().length > 0){
                        debugger;
                        component.set("v.records", response.getReturnValue());
                    }
                }
                else {
                    component.set("v.pageErrors", component.get("v.lightingErrorMessage"));
                }
            });
         $A.enqueueAction(action);
    }
})