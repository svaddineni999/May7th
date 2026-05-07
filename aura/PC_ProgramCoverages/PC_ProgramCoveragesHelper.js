/**
 * Created by shisbansal on 8/27/2018.
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

       fetchProgramCoveragesList: function (component, event, helper){
           component.set("v.isLoading", true);
           var action =  component.get("c.getProgramCoverages");
           var caseId = component.get("v.recordId");
           console.log(caseId);
           action.setParams({
               caseIds: caseId
           });
           action.setCallback(this, function(response){
               var state= response.getState();
               debugger;
               if (state === "SUCCESS"){
                   if(component.isValid()) {
                        var programCoveragesWrapper =response.getReturnValue();
                        console.log(programCoveragesWrapper);
                        component.set("v.programCoveragesList", programCoveragesWrapper.programCoveragesList);
                        component.set("v.fieldLabels",programCoveragesWrapper.fieldLabels);
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

      /* getFieldLabels : function(component){
           var action = component.get("c.getFieldLabels");
           action.setCallback(this, function(response) {
               var state = response.getState();
               if (component.isValid() && state === "SUCCESS") {
                   var returnValue = response.getReturnValue();
                   component.set("v.fieldLabels", returnValue);
               } else {
                   console.log("Failed with state: " + state);
               }
           });
           $A.enqueueAction(action);
       },*/


       insertNewProgramCoverage: function (component, event, helper){
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

       editExistingProgramCoverage : function(component, event, helper) {
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