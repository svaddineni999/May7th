({
    goToCase : function(component, event, helper) {
        var caseId = component.get("v.enrollCaseId");
        //window.open('/one/one.app#/sObject/' + caseId + '/view', '_blank', "toolbar=yes,scrollbars=yes,resizable=yes,left=1050,top=100,width=800,height=800");
        //PC-4340 : Navigation based on context
        var workspaceAPI = component.find("workspace");
        var device = $A.get("$Browser.formFactor");
        if(device != 'DESKTOP'){
            var navService = component.find("navService");
            // Uses the pageReference definition in the init handler
            var pageReference = {
                "type": "standard__recordPage",
                "attributes": {
                   "recordId": caseId,
                   "actionName": "view"
               }
            };
            event.preventDefault();
            navService.navigate(pageReference);
        }else{
            var isCustomApp = component.get("v.isCustomApp");
            if(isCustomApp){
                var url = '/one/one.app#/sObject/' + caseId + '/view';
                window.open(url,'_blank');
            }else{
                CH_PC_Util.openRecordInNewTab(workspaceAPI,caseId);
            }
        }
        return false;
    },
    
    hideModal : function(component, event, helper) {
        helper.hidePopupHelper(component, 'modaldialog', 'slds-fade-in-');
        helper.hidePopupHelper(component, 'backdrop', 'slds-backdrop--');
        event.preventDefault();
        return false;
    },
    
    hidePopupHelper: function(component, componentId, className) { 
        var modal = component.find(componentId); 
        $A.util.addClass(modal, className+'hide'); 
        $A.util.removeClass(modal, className+'open'); 
    }
})