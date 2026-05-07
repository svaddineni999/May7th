/**
 * Created by sathekumar on 7/1/2020.
 */
({
    checkHeaderCheckbox: function(component, event, helper) {
        var listOfeLetterRecipients = component.get("v.eLetterRecipients");
        // Check if all recipients are disabled, then make disableHeaderCheckbox = true
        let checkValidRecipient;
        if(component.get('v.isEmailWorkflowEnabled')){
            checkValidRecipient = (recipient) => ((!recipient.bDisableEmail) || recipient.sendToMe);
        } else {
            checkValidRecipient = (recipient) => ((!recipient.bDisableFax) || recipient.sendToMe);
        }
        if(!(listOfeLetterRecipients.some(checkValidRecipient))){
            component.set("v.disableHeaderCheckbox", true);
        }
        else{
            component.set("v.disableHeaderCheckbox", false);
        }
        var totalValidEmailRecipientCount = 0;
        var totalValidFaxRecipientCount = 0;
        listOfeLetterRecipients.forEach(recipient => {
            totalValidEmailRecipientCount = totalValidEmailRecipientCount + (recipient.bDisableEmail == false ? 1 : 0);
            totalValidFaxRecipientCount = totalValidFaxRecipientCount + (recipient.bDisableFax == false ? 1 : 0);
        });
        component.set('v.totalValidEmailRecipientCount', totalValidEmailRecipientCount);
        component.set('v.totalValidFaxRecipientCount', totalValidFaxRecipientCount);
        helper.calculateRecipientCount(component, event, helper);
    },

    selectAllRecipients: function(component, event, helper) {
        var selectedHeaderCheck = event.getSource().get("v.checked");
        var selectedType = event.getSource().get("v.name");
        var updatedAllRecords = [];
        var listOfeLetterRecipients = component.get("v.eLetterRecipients");
        // play a for loop on all records list
        for (var i = 0; i < listOfeLetterRecipients.length; i++) {
            // check if header checkbox is 'true' then update all checkbox with true else update all records with false
            if (selectedHeaderCheck == true) {
                if(!(listOfeLetterRecipients[i].bDisableEmail) && selectedType == 'Email'){
                    listOfeLetterRecipients[i].sendEmail = true;
                }
                else if(!(listOfeLetterRecipients[i].bDisableFax) && selectedType == 'Fax'){
                    listOfeLetterRecipients[i].sendFax = true;
                }
            } else {
                (selectedType == 'Email') ? listOfeLetterRecipients[i].sendEmail = false : listOfeLetterRecipients[i].sendFax = false;
            }
            updatedAllRecords.push(listOfeLetterRecipients[i]);
        }
        component.set("v.eLetterRecipients", updatedAllRecords);
    },

    /*
    *  returns the all selected recipients
    */
    getSelectedRecipients: function(recipientList){
        return recipientList.filter(function(obj) {
            return (obj.sendEmail || obj.sendFax);
          }).map(function(obj) { return obj; });
    },

    /*
    *  calculate count of selected email and fax recipients and check whether all recipients are selected or not
    */
    calculateRecipientCount : function(component, event, helper){
        var listOfeLetterRecipients = component.get("v.eLetterRecipients");
        var totalValidEmailRecipientCount = component.get('v.totalValidEmailRecipientCount');
        var totalValidFaxRecipientCount = component.get('v.totalValidFaxRecipientCount');
        var selectedEmailCount = 0;
        var selectedFaxCount = 0;

        listOfeLetterRecipients.forEach(recipient => {
            selectedEmailCount = selectedEmailCount + (recipient.sendEmail == true ? 1 : 0);
            selectedFaxCount = selectedFaxCount + (recipient.sendFax == true ? 1 : 0);
        });
        component.set('v.selectedEmailCount', selectedEmailCount);
        component.set('v.selectedFaxCount', selectedFaxCount);
        component.set('v.selectAllEmail', (totalValidEmailRecipientCount > 0 && selectedEmailCount == totalValidEmailRecipientCount));
        component.set('v.selectAllFax', (totalValidFaxRecipientCount > 0 && selectedFaxCount == totalValidFaxRecipientCount));
    }
})