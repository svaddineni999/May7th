({
    setNamespace : function(component) {  		
        var component_to_string = component.toString();        
        var markupTagLoc = component_to_string.indexOf('markup://');
        var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
        var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);        
        var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
  		component.set("v.namespace", ns);
        component.set("v.namespacePrefix", namespacePrefix);
    },
    
    hideModal : function(component, event, helper) {
        helper.hidePopupHelper(component, 'modaldialog', 'slds-fade-in-');
        helper.hidePopupHelper(component, 'backdrop', 'slds-backdrop--');
        event.preventDefault();
        return false;
    },
    
    hidePopupHelper: function(component, componentId, className){ 
        var modal = component.find(componentId); 
        $A.util.addClass(modal, className+'hide'); 
        $A.util.removeClass(modal, className+'open'); 
    },
    
    showPopupHelper: function(component, componentId, className){ 
        var modal = component.find(componentId); 
        $A.util.removeClass(modal, className+'hide'); 
        $A.util.addClass(modal, className+'open'); 
    },
    
    goToCase : function(component, event, helper) {
        var caseId = component.get("v.caseDetails.caseId");
    	var url = '/one/one.app#/sObject/' + caseId + '/view';
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
                  "url": url
                });
        urlEvent.fire();
    },
    
    launchWizard : function(component, event, helper) {
		var docId = component.get("v.recordId");
        /*[PC-4340] - Enrollment launch logic Change Start*/
        var workspaceAPI = component.find("enrollmentHomeWorkspace");
        var namespace = component.get("v.namespace");
        var componentAPIName =  namespace+'__'+component.get("v.enrollmentComponentName");
        var pageAPIName = component.get("v.namespacePrefix") + component.get("v.enrollmentSearchPageName");
        var urlParams;
        var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component,'Id',namespace);
        var tabParamsObject = new Object();
        var viewEnrollmentInNewBrowserTab = component.get("v.viewEnrollmentInNewBrowserTab");
        if(docId != 'NULL'){
            tabParamsObject[qualifiedIdName] = docId;
            tabParamsObject.uid = 'ENA-'+docId;

        }
        else if ($A.util.isEmpty(docId) || docId == 'NULL'){
            var today = new Date();
            tabParamsObject.uid = 'Enrollment'+today;
        }
        if(viewEnrollmentInNewBrowserTab == true){
            urlParams = {'qualifiedIdName' :docId };
            CH_PC_Util.openRecordInBrowserTab(pageAPIName,urlParams);
        }

        else if(viewEnrollmentInNewBrowserTab ==false){
            if(docId != 'NULL'){
                urlParams = '?'+qualifiedIdName+'='+docId;
            }
            else {
                urlParams = "";
            }
            CH_PC_Util.openLightningComponentInNewTab(workspaceAPI,componentAPIName,pageAPIName,tabParamsObject,component.get("v.enrollmentTabLabel")
                                                            ,component.get("v.enrollmentTabIcon"),true,urlParams);

        }




        /*[PC-4340] - Enrollment launch logic Change End*/
	},
    
    launchPopUp : function(component, event, helper) {
       
        var action = component.get("c.checkEnrollment");
        action.setParams({
            "docID"		: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                if(returnValue == null ){
                    helper.launchWizard (component, event, helper);
                }else{
                    component.set("v.caseDetails",returnValue);
                    helper.showPopupHelper(component, 'modaldialog', 'slds-fade-in-');
        			helper.showPopupHelper(component, 'backdrop', 'slds-backdrop--');
                }
                
            } else if (state === "ERROR") {
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
            } else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
        
    },


})