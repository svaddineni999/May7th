({	
    //Links enrollment document from which the enrollment case was launched to patient enrollment case 
    linkEnrollDoc : function(component, event, helper) {        
        helper.hideLinkModal(component, event, helper);
        var docId = component.get("v.docId");
        var enrollcaseId = component.get("v.reqCaseId");
        
        if(enrollcaseId && docId) {
            var action = component.get("c.linkDocToCase");
            action.setParams({
                "enrollmentCaseId": enrollcaseId,
                "documentId": docId 
            });
            action.setCallback(this, function(a) {
                var state = a.getState();
                //if server side call successful, create entries in document log and document modification log
                if (state === "SUCCESS") {
                    console.log("Document linking sucessful");
                    helper.hideLinkModal(component, event, helper);
                    helper.fireToastMessage(component, event, helper);
                }else if (state ==="ERROR") { //if server side call fails, log error in console
                   var errors = a.getError();
                    console.log(JSON.stringify(errors));
                    var errText = component.get("v.ErrorText");
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
        helper.goToCase(component, event, helper);	
    }
})