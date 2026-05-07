/**
 * Created by havalakki on 3/1/2018.
 */
({
    //Modal window for adding page reference for a new child document
        showModal : function(component, event, helper) {
            component.set("v.disableButton",false);

            var addModal = component.find("addSplitModalBox");
            var parentModal = component.find("parentModalBox");
            $A.util.removeClass(addModal, 'slds-hide');
            $A.util.addClass(addModal, 'slds-show');

            $A.util.removeClass(parentModal, 'slds-show');
            $A.util.addClass(parentModal, 'slds-hide');

            component.set('v.showParentLabel',false);
            component.set('v.showAddLabel',true);

        },

        //Hide modal window for adding page reference for a new child document
        hideModalBox : function(component, event, helper) {
            /*
             * Reset the popout window
             */
            component.set("v.newChildDocPgRange", "");
            component.find("pageRangeErrorSave").set("v.errors", [{message: ""}]);
            component.set("v.showEditLabel", false);

            var modal = component.find("parentModalBox");
            $A.util.removeClass(modal, 'slds-hide');
            $A.util.addClass(modal, 'slds-show');

            var addModal = component.find("addSplitModalBox");
            $A.util.removeClass(addModal, 'slds-show');
            $A.util.addClass(addModal, 'slds-hide');

            $A.get('e.force:refreshView').fire();
            event.preventDefault();
        },

        //Hide modal window for adding page reference for a new child document
        hideMainModalBox : function(component, event, helper) {
            /*
             * Reset the popout window
             */
            var hasAttachment=component.get('v.hasAttachment');
            var modal = component.find("mainModalDialog");
            var backdrop = component.find("backdrop");
            if(hasAttachment){

                 component.set("v.noSplitDocs", "");
                 component.find("pageRangeErrorSave").set("v.errors", [{message: ""}]);

                 $A.util.removeClass(modal, 'slds-fade-in-open');
                 $A.util.addClass(modal, 'slds-fade-in-hide');

                 $A.util.removeClass(backdrop, 'slds-backdrop--open');
                 $A.util.addClass(backdrop, 'slds-backdrop--hide');
                 $A.get('e.force:refreshView').fire();
                 event.preventDefault();
             }
             else{
                  $A.util.removeClass(modal, 'slds-fade-in-open');
                  $A.util.addClass(modal, 'slds-fade-in-hide');

                  $A.util.removeClass(backdrop, 'slds-backdrop--open');
                  $A.util.addClass(backdrop, 'slds-backdrop--hide');

             }

        },

        //Modal window for editing page reference for an existing child document
        showEditModal : function(component, event, helper) {
            component.set("v.disableButton",false);
    		helper.showEditMod(component, event, helper);
        },

        //Hide modal window for editing page reference for an existing child document
        hideEditModal : function(component, event, helper) {
            helper.hideEditModalWindow(component, event, helper);
        },

        //Modal window for showing an acknowledgement window when split request is sent
        sendSplitReq : function(component, event, helper){
            component.set("v.isSplitbuttonActive",false);
            helper.sendSplit(component, event, helper);
        },

        //Hide modal window for showing an acknowledgement window when split request is sent
        hideAckModal : function(component, event, helper) {
            var modal = component.find("splitInitmodal");
            $A.util.removeClass(modal, 'slds-fade-in-open');
            $A.util.addClass(modal, 'slds-fade-in-hide');

            var parentModal=component.find("mainModalDialog");
            $A.util.removeClass(parentModal, 'slds-backdrop slds-backdrop--open');

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
            helper.showDeleteModal(component, event, helper);
        },

        //Hide modal window to show a warning message on deletion of a child document
        hideDelete : function(component, event, helper) {
            helper.hideDeleteModal(component, event, helper);

        },

        //Function to populate the list of child documents if the document opened in the parent component is has children
        getChildDocList : function(component, event, helper){
            helper.setNamespace(component);
            component.set('v.showParentLabel',true);
            component.set('v.showAddLabel',false);
            var actionAttribute = component.get("v.actionAttribute");
            if(!$A.util.isEmpty(actionAttribute)){
                var cmpAttribute = JSON.parse(actionAttribute);
                var cmpAttributeValue = cmpAttribute.adminAccessAttributes['adminAccess'];
                if(!$A.util.isEmpty(cmpAttributeValue)){
                    component.set("v.isAdminAccess",cmpAttributeValue);
                }
            }

            helper.getInit(component, event, helper);
            var hasAttachment=component.get('v.hasAttachment');
            if(hasAttachment){
                component.find("pageRangeErrorSave").set("v.errors", [{message: ""}]);
            }
        },

        //Function to populate the list of child documents if the document opened in the parent component is has children
        deleteSplit : function(component, event, helper){
            helper.hideDeleteModal(component, event, helper);
            component.set("v.isSplitbuttonActive",false);
            helper.delSplit(component, event, helper);
        },

        //Function to edit the page range of the child docs
        editPageRange : function(component, event, helper) {
            component.set("v.disableButton",true);
            component.set("v.isSplitbuttonActive",false);
            helper.updateSplit(component, event, helper);
        },

        //Function to save the page range
        savePageRange : function(component, event, helper) {
            component.set("v.disableButton",true);
            component.set("v.isSplitbuttonActive",false);
            helper.saveChildDocument(component, event, helper);
        }
})