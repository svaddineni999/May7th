/**
 * Created by shisbansal on 8/28/2018.
 */
({


        setNamespace : function(component) {

            var component_to_string = component.toString();
            console.log(component_to_string);
            var markupTagLoc = component_to_string.indexOf('markup://');
            console.log(markupTagLoc);
            var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
            console.log(endOfNamespaceLoc);

            var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
            console.log(ns);
            var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
            console.log(namespacePrefix);
      		component.set("v.namespace", ns);
            component.set("v.namespacePrefix", namespacePrefix);

        },


        fetchEngagementTasksList: function (component, event, helper){
            component.set("v.isLoading", true);
            var action =  component.get("c.getEngagementTasks");
            var caseId = component.get("v.recordId");
            console.log(caseId);
            action.setParams({
                caseId: caseId
            });
            action.setCallback(this, function(response){
                var state= response.getState();
                debugger;
                if (state === "SUCCESS"){
                    if(component.isValid()) {
                         var engagementTasksWrapper =response.getReturnValue();
                         console.log(engagementTasksWrapper);
                         component.set("v.upcomingActivity", engagementTasksWrapper.upcomingOpenTasks);
                         component.set("v.pastActivity",engagementTasksWrapper.pastClosedTasks);
                         component.set("v.fieldLabels",engagementTasksWrapper.fieldLabels);
                    }
                    else{
                         component.set("v.errors", "Component Is Invalid");
                    }
                }
                else if (state ==="ERROR") {
                    debugger;
                     var errors = response.getError();
                     console.log(JSON.stringify(errors));
                     component.set("v.errors", helper.getErrorsAsArray(errors, helper));
                }
                else{
                    debugger;
                     component.set("v.errors", "Unknown State " + state);
                }
                component.set("v.isLoading", false);

            });
            $A.enqueueAction(action);
        },

        clearErrorMessages : function(component) {
            var errors;
            component.set("v.errors", errors);
        },



        insertNewEngagementTask: function (component, event, helper){
            var createRecordEvent = $A.get("e.force:createRecord");
            var caseId = component.get("v.recordId");
            var namespacePrefix = component.get("v.namespacePrefix");
            var api = namespacePrefix +'PC_Program_Coverage__c';
            var caseField = namespacePrefix +'PC_Program__c';
            var parameters = {
                    "entityApiName": api,
                    "defaultFieldValues" : {
                    }
            }

            parameters["defaultFieldValues"][caseField] = caseId;
            createRecordEvent.setParams(parameters);
    		createRecordEvent.fire();
        },


        editExistingEngagementTask : function(component, event, helper) {
             debugger;
             var editRecordEvent = $A.get("e.force:editRecord");
             var id = event.getSource().get("v.value");
             debugger;
        	    editRecordEvent.setParams({
             	"recordId": id
        	    });
        	    editRecordEvent.fire();
        },


        getErrorsAsArray : function(errors, helper) {
            var errorArr = [];
            if(!$A.util.isEmpty(errors)) {

                for(var i=0; i<errors.length; i++) {
                    var errorObj = errors[i];
                    helper.setErrorArr(errorObj, errorArr);
                    for (var property in errorObj) {
                        if (errorObj.hasOwnProperty(property) && !$A.util.isEmpty(errorObj[property])) {
                            for(var j=0; j<errorObj[property].length; j++) {
                                helper.setErrorArr(errorObj[property][j], errorArr);
                            }
                        }
                    }
                }
            }
            return errorArr;
        },

       setErrorArr : function(errorObj, ret_errorArr) {
            if(!$A.util.isEmpty(errorObj.message)) {
                var msg = '';
                if(!$A.util.isEmpty(errorObj.statusCode)) {
                    msg = errorObj.statusCode + ' : ';
                }
                msg = msg + errorObj.message;
                ret_errorArr.push(msg);
            }
       },
})