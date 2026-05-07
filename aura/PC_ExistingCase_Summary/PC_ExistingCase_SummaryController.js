({
	getInit : function(component, event, helper) {
        helper.setNamespace(component);
        helper.getCustomcomp (component, event, helper);

        var searchPatient= {
                        fsFields:""
        };
         component.set("v.fieldSetName", '');
         component.set("v.searchPatient", searchPatient);
         var pageErrors = [];
         var validFieldSet = helper.validateFieldSetForm(component);
         if(!validFieldSet){
             var fieldsetErrorMessage = component.get("v.fieldsetErrorMessage");
             pageErrors.push(fieldsetErrorMessage);
         }
         component.set("v.pageErrors", pageErrors);
         component.find("viewCaseButton").getElement().focus();
	},
    
    hideModalBox : function(component, event, helper) {
        helper.hideModal(component, event, helper);
    },
    
    goToCase : function(component, event, helper) {
    	helper.goToCase(component, event, helper);        
    },
    
    linkEnrollDoc : function(component, event, helper) {        
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
                    helper.hideModal(component, event, helper);
                    helper.fireToastMessage(component, event, helper);
                    helper.goToCase(component, event, helper);
                    //helper.fireCloseParent(component, event, helper);
                }else if (state ==="ERROR") { //if server side call fails, log error in console
                   var errors = a.getError();
                    console.log(JSON.stringify(errors));
                    var errText = component.get("v.ErrorText");
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log(errText);
                        }
                    }else {
                        console.log("Unknown error");
                    }
                }
            });
            $A.enqueueAction(action);
        }        	
    },
     OpenNewComponent:function(component, event, helper) {
        var componentName=component.get("v.compDetails.componentName");
        var targetValueAttr = event.currentTarget.value;
     	var iconActionComponent = targetValueAttr;
        var iconLabel = event.currentTarget.name;
        component.set("v.iconLabel", iconLabel);
         try{
        $A.createComponent(
            componentName,{ "caseId" : component.get("v.reqCaseId")},
                    function(newComponent,status,error) {
                        component.set("v.body", newComponent);
                    });
         }catch(e){
             console.log(e);
         } 
       
    }
})