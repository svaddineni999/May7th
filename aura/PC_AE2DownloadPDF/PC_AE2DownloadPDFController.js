/**
 * Created by kkanteti on 10/23/2019.
 */
({
    doInit: function(component,event,helper){
             var adverseEventRecId = component.get("v.recordId");
            // var action=component.get("c.getAEDownloadPDFPageName");
            var action=component.get("c.getAEDownloadParams");

            action.setParams({
                currentAE2_Id : adverseEventRecId
            });

             action.setCallback(this,function(response){

                 var state=response.getState();
                 debugger;
                 if(state=="SUCCESS"){
                   // var vfPage = response.getReturnValue();
                    var setParams = response.getReturnValue();
                    debugger;
                    var url = '/apex/'+setParams.vfPageName+'?adverseEventId='+setParams.latestAE2Id;
                    window.open(url);
                    component.find("overlayLib").notifyClose();
                 }
                 else if (state === "INCOMPLETE") {
                     // do something

                 }
                 else if (state === "ERROR") {
                    //var error = 'Something went wrong. Please contact administrator.'
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            //var error = errors[0]['message'];
                            //component.set("v.errors", [error]);
                            console.log("Error message: " + errors[0].message);
                            CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
                             component.find("overlayLib").notifyClose();
                        }
                    } else {
                        console.log("Unknown error");

                    }
                 }
             });
             $A.enqueueAction(action);
        },
})