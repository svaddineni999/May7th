({
    //Modal window for adding page reference for a new child document
    showModal : function(component, event, helper) {
        var modal = component.find("modaldialog");
        var backdrop = component.find("backdrop");
        $A.util.removeClass(modal, 'slds-fade-in-hide');
        $A.util.addClass(modal, 'slds-fade-in-open');
        
        $A.util.removeClass(backdrop, 'slds-backdrop--hide');
        $A.util.addClass(backdrop, 'slds-backdrop--open');
    },
    
    //Hide modal window for adding page reference for a new child document
    hideModalBox : function(component, event, helper) {
        /*
         * Reset the popout window
         */
        component.set("v.newChildDocPgRange", "");
        component.find("pageRangeErrorSave").set("v.errors", [{message: ""}]);
        
        var modal = component.find("modaldialog");
        var backdrop = component.find("backdrop");
        $A.util.removeClass(modal, 'slds-fade-in-open');
        $A.util.addClass(modal, 'slds-fade-in-hide');
        
        $A.util.removeClass(backdrop, 'slds-backdrop--open');
        $A.util.addClass(backdrop, 'slds-backdrop--hide');
        $A.get('e.force:refreshView').fire();
        event.preventDefault();
    },
    
    //Modal window for editing page reference for an existing child document
    showEditModal : function(component, event, helper) {
		helper.showEditMod(component, event, helper);
    },
    
    //Hide modal window for editing page reference for an existing child document
    hideEditModal : function(component, event, helper) {
        helper.hideEditModalWindow(component, event, helper);
    },
    
    //refresh list of child documents
    refreshDocSplitCmp : function(component, event, helper) {
		helper.refreshCmp(component, event, helper);
    },
    
    //Modal window for showing an acknowledgement window when split request is sent
    sendSplitReq : function(component, event, helper){
        helper.sendSplit(component, event, helper);
    },
    
    //Hide modal window for showing an acknowledgement window when split request is sent
    hideAckModal : function(component, event, helper) {
        var modal = component.find("splitInitmodal");
        var backdrop = component.find("backdrop");
        $A.util.removeClass(modal, 'slds-fade-in-open');
        $A.util.addClass(modal, 'slds-fade-in-hide');
        
        $A.util.removeClass(backdrop, 'slds-backdrop--open');
        $A.util.addClass(backdrop, 'slds-backdrop--hide'); 
    },
    
    //Hide modal window for showing a warning message when split request is resubmitted
    hideReSubmit : function(component, event, helper) {
        helper.hideReSubmitModal(component, event, helper); 
    },
    
	//Modal window for showing a warning message when split request is resubmitted
    resubmitSplitReq : function(component, event, helper){
        component.set("v.isResubmit", false);
        helper.hideReSubmitModal(component, event, helper); 
        helper.sendSplit(component, event, helper);
    },
    
    //Modal window to show a warning message on deletion of a child document
    showDeleteWarning: function(component, event, helper){
	    //var index = event.currentTarget.dataset.index;
        helper.showDeleteModal(component, event, helper); 
    },
    
    //Hide modal window to show a warning message on deletion of a child document
    hideDelete : function(component, event, helper) {
        helper.hideDeleteModal(component, event, helper); 
        
    },
    
    //Function to populate the list of child documents if the document opened in the parent component is has children
    getChildDocList : function(component, event, helper){
        helper.setNamespace(component);
        helper.getInit(component, event, helper);      
    },
    
    //Function to populate the list of child documents if the document opened in the parent component is has children
    deleteSplit : function(component, event, helper){
        helper.hideDeleteModal(component, event, helper);
        helper.delSplit(component, event, helper);      
    },
    
    //Function to edit the page range of the child docs
    editPageRange : function(component, event, helper) {
        helper.updSplit(component, event, helper);
    },    
    
    //Function to save the page range
    savePageRange : function(component, event, helper) {
        helper.saveChildDocument(component, event, helper);
    }
})