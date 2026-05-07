/**
 * Created by sathekumar on 6/29/2020.
 */
({
    doInit: function(component, event, helper) {
        helper.checkHeaderCheckbox(component, event, helper);
    },

    selectAllRecipients: function(component, event, helper) {
        helper.selectAllRecipients(component, event, helper);
    },

    /*
    *  returns the all selected recipients
    */
    getSelectedRecipients: function(component, event, helper){
        var recipientList = component.get("v.eLetterRecipients");
        return helper.getSelectedRecipients(recipientList);
    },

    onSelectRecipient: function(component, event, helper){
        helper.calculateRecipientCount(component, event, helper);
    },

    /*
    *  Returns the valid property value (Boolean) to indicate whether the recipient is selected or not.
    */
    checkRecipientsValidity : function(component, event, helper){
        var selectedRecipients = helper.getSelectedRecipients(component.get('v.eLetterRecipients'));
        if(selectedRecipients.length < 1){
            component.set('v.isRecipientsSelected', false);
        }
        else {
            component.set('v.isRecipientsSelected', true);
        }
        return component.get('v.isRecipientsSelected');
    },

    /*
    *  Display error messages if the recipient is not selected.
    */
    reportValidity : function(component, event, helper){
        if(component.get('v.isRecipientsSelected')){
            component.set('v.messageWhenRecipientNotSelected', '');
        }
        else{
            component.set('v.messageWhenRecipientNotSelected', component.get("v.noRecipientSelected"));
        }
    },

    navigateToConsentRecord : function(component, event, helper){
      var navEvt = $A.get("e.force:navigateToSObject");
      debugger;
      var recordIDValue= event.currentTarget.id;
          navEvt.setParams({
            "recordId": recordIDValue
          });
          navEvt.fire();
     }
})