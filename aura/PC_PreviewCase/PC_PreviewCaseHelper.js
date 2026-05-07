({
    //Shows link confirmation modal dialog
    showLinkModal : function(component, event, helper) {
        var docId = component.get("v.docId");
        var enrollcaseId = component.get("v.reqCaseId");
        
        //Show modal dialog only when document id and enrollment case id present
        if(enrollcaseId && docId) {
            var modal = component.find("linkmodal");
            var backdrop = component.find("backdropss");
            $A.util.removeClass(modal, 'slds-fade-in-hide');
            $A.util.addClass(modal, 'slds-fade-in-open');            
            $A.util.removeClass(backdrop, 'slds-backdrop--hide');
            $A.util.addClass(backdrop, 'slds-backdrop--open');            
            //else directly show the enrollment case
        }else if(enrollcaseId){
            helper.goToCase(component, event, helper);
        }else{
            return;
        }
    },
    
    //Hide link confirmation modal dialog
    hideLinkModal : function(component, event, helper) {
        debugger;
        var modal = component.find("linkmodal");
        var backdrop = component.find("backdropss");
        $A.util.removeClass(modal, 'slds-fade-in-open');
        $A.util.addClass(modal, 'slds-fade-in-hide');
        
        $A.util.removeClass(backdrop, 'slds-backdrop--open');
        $A.util.addClass(backdrop, 'slds-backdrop--hide'); 
        
        helper.goToCase(component, event, helper);
        event.preventDefault();        
        return false;
    },
    
    closeParentCmp : function(component, event, helper){
        var closeEvent = component.getEvent("closeEvent");
        //test parameter set for event - to be removed later
        closeEvent.setParams({
            "message" : "A component event fired me."
        });
        closeEvent.fire();        
    },  
    
    goToCase : function(component, event, helper) {
       debugger;
       var caseId = component.get("v.reqCaseId");
       window.open('/one/one.app#/sObject/' + caseId + '/view', '_blank', "toolbar=yes,scrollbars=yes,resizable=yes,left=1050,top=100,width=800,height=800");        
       return false;
    },
    
    fireToastMessage : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "type": "success",
            "message": "This is the message"
        });
        toastEvent.fire();
    }
})