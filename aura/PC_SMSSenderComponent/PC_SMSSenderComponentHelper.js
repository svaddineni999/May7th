({

    /*********************************************************************************
    Method Name             : getCaseMessages
    Description             : makes a call to the apex PC_MessageManagementController controller, method getCaseMessages to retrieve the list of messages for the current case
                            : not used at the moment
    Return Type             : List
    Parameter               : Component
    Parameter sent to sfdc  : String caseId
    *********************************************************************************/
    getCaseMessages: function(component) {
        var action = component.get("c.getCaseMessages");
        action.setParams({
          "caseId": component.get("v.recordId")
        });
        var smsList = null;
        action.setCallback(this, function(a) {
            var state = a.getState();
            if(state ==="SUCCESS"){
                var q = a.getReturnValue();
                component.set("v.msgList", q); 
            }else if (state === "ERROR"){
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

    /*********************************************************************************
    Method Name             : sendMessageH
    Description             : makes a call to the apex PC_MessageManagementController controller, method sendMessage to insert a new message
    Return Type             : String
    Parameter               : Component
    Parameter sent to sfdc  : String caseId, String messageText
    *********************************************************************************/
    sendMessageH: function(component) {
        var action = component.get("c.sendMessage");
        action.setParams({
          "caseId": component.get("v.recordId"),
          "messageText": component.find("newSMS").get("v.value") 
        });
        
        action.setCallback(this, function(a) {
            var state = a.getState();
            if(state ==="SUCCESS"){
                var msg = '';
                var smsSuccess = component.get("v.smsSuccess");
                var smsError = component.get("v.smsError");
                msg = (a.getReturnValue()) ? smsSuccess : smsError;
                component.find("resultMsg").set("v.value", msg); 
                component.find("newSMS").set("v.value", ''); 
                //this.getCaseMessages(component);
            }else if (state === "ERROR"){
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