({
    doInit : function(component, event, helper) {
      helper.setNamespace(component)  ;
      helper.setCaseType(component);  
    },
    launchWizard : function(component, event, helper) {
		var id = component.get("v.recordId");
		var caseNumber = component.get("v.caseRecord").CaseNumber;
        /*[PC-4340] - Enrollment launch logic Change Start*/
        var workspaceAPI = component.find("enrollmentCaseWorkspace");
        var namespace = component.get("v.namespace");
        var componentAPIName =  namespace+'__'+component.get("v.enrollmentWizardComponentName");
        var pageAPIName = component.get("v.namespacePrefix") +component.get("v.enrollmentWizardPageName");
        var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component,'Id',namespace);
        var tabParamsObject = new Object();
        tabParamsObject.uid = 'ENA-'+id;
        tabParamsObject[qualifiedIdName] = id;
        var urlParams = '?'+qualifiedIdName+'='+id;
        var device = $A.get("$Browser.formFactor");
            if(device != 'DESKTOP'){
                var navService = component.find("navService");
                // Uses the pageReference definition in the init handler
                var pageReference = {
                    "type": "standard__component",
                    "attributes": {
                        "componentName": componentAPIName
                    },
                    "state": tabParamsObject
                };
                event.preventDefault();
                navService.navigate(pageReference);
            }else{
                CH_PC_Util.openLightningComponentInNewTab(workspaceAPI,componentAPIName,pageAPIName,tabParamsObject,component.get("v.enrollmentWizardTabLabel")+' : '+caseNumber
                                                                    ,component.get("v.enrollmentWizardTabIcon"),true,urlParams);
            }
        /*[PC-4340] - Enrollment launch logic Change End*/
	}
})