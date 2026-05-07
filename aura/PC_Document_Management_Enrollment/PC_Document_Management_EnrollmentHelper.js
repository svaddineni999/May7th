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
    
    goToCase : function(component, event, helper) {
        var recordId = component.get("v.caseDetails.caseId");
        var workspaceAPI = component.find("enrollmentDocumentWorkspace");
        /* workspaceAPI.isConsoleNavigation().then(function(isConsole) {

        if (isConsole) {

            workspaceAPI.getEnclosingTabId().then(function(enclosingTabId) {

                 workspaceAPI.openTab({
                        recordId:caseId,
                        focus: true
                 });
            });
        }else{

            var url = '/one/one.app#/sObject/' + caseId + '/view';
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                              "url": url
                            });
                    urlEvent.fire();
        }}); */
        CH_PC_Util.openRecordInNewTabAlways(workspaceAPI , recordId, true);
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
    
    
    launchWizard : function(component, event, helper) {
		var docId = component.get("v.recordId");
        /*[PC-4340] - Enrollment launch logic Change Start*/
        var workspaceAPI = component.find("enrollmentDocumentWorkspace");
        var namespace = component.get("v.namespace");
        var componentAPIName =  namespace+'__'+component.get("v.enrollmentComponentName");
        var pageAPIName = component.get("v.namespacePrefix") + component.get("v.enrollmentSearchPageName");
        var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component,'Id',namespace);
        var tabParamsObject = new Object();
        tabParamsObject.uid = 'ENA-'+docId;
        tabParamsObject[qualifiedIdName] = docId;

        //var urlParams = '?'+qualifiedIdName+'='+docId;
        var urlParams = new Object();
        urlParams[qualifiedIdName] = docId;
        var encodeUrlParams =CH_PC_Util.convertIntoURLParamsFormat(urlParams);
        encodeUrlParams= '?'+encodeUrlParams;



        var actionAttribute = component.get("v.actionAttribute");
        if(!$A.util.isEmpty(actionAttribute)){
            var jsonActionAttribute = JSON.parse(actionAttribute);

            if(!$A.util.isEmpty(jsonActionAttribute.openEnrollmentInNewTab) && (jsonActionAttribute.openEnrollmentInNewTab == true)){
                CH_PC_Util.openRecordInBrowserTab(pageAPIName,urlParams);
            }
            else{
                CH_PC_Util.openLightningComponentInNewTab(workspaceAPI,componentAPIName,pageAPIName,tabParamsObject,component.get("v.enrollmentTabLabel"),component.get("v.enrollmentTabIcon") ,true,encodeUrlParams);
            }
        }
        else{
             CH_PC_Util.openLightningComponentInNewTab(workspaceAPI,componentAPIName,pageAPIName,tabParamsObject,component.get("v.enrollmentTabLabel"),component.get("v.enrollmentTabIcon") ,true,encodeUrlParams);
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
                    console.log(JSON.stringify(returnValue));
                    component.set("v.caseId",returnValue.caseId);
                    helper.getCustomcomp (component, event, helper);
                }
                
            } else if (state === "ERROR") {

                var errors = response.getError();
                CH_PC_Util.showAllErrors(component.get("v.errorDocStatus"),errors);
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
                  CH_PC_Util.showAllErrors(component.get("v.errorDocStatus"),state);
            }
        });
        $A.enqueueAction(action);   
    },
     getCustomcomp : function(component, event, helper) {
           
        var action = component.get("c.CheckMetadata");
        action.setParams({
            "docID"		: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();  
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
             if(returnValue != null ){
				    component.set("v.compDetails",returnValue);
                    //component.set("v.NameComponent",returnValue.componentName);
                    console.log(returnValue);
                 	var custLabel = $A.get("$Label.c."+returnValue.buttonName);
                 	component.set("v.buttonlabel",custLabel);
                    helper.showPopupHelper(component, 'modaldialog', 'slds-fade-in-');
                    helper.showPopupHelper(component, 'backdrop', 'slds-backdrop--');
                } else if (returnValue == null){
                    helper.showPopupHelper(component, 'modaldialog', 'slds-fade-in-');
                    helper.showPopupHelper(component, 'backdrop', 'slds-backdrop--');
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                CH_PC_Util.showAllErrors(component.get("v.errorDocStatus"),errors);
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
               CH_PC_Util.showAllErrors(component.get("v.errorDocStatus"),state);
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);   
     }
})