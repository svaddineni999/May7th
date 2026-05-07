/**
 * Created by sathekumar on 6/29/2020.
 */
({
    doInit: function(component, event, helper){
        console.log('doInit attachments');
        helper.getAllAttachments(component, event, helper);
    },

    selectAllAttachments: function(component, event, helper){
        var selectedHeaderCheck = event.getSource().get("v.checked");
        var updatedAllRecords = [];
        var listOfAttachments = component.get("v.attachmentList");
        // play a for loop on all records list
        for (var i = 0; i < listOfAttachments.length; i++) {
            // check if header checkbox is 'true' then update all checkbox with true else update all records with false
            if (selectedHeaderCheck == true) {
                listOfAttachments[i].isChecked = true;
                component.set("v.selectedCount", listOfAttachments.length);
            } else {
                listOfAttachments[i].isChecked = false;
                component.set("v.selectedCount", 0);
            }
            updatedAllRecords.push(listOfAttachments[i]);
        }
        component.set("v.attachmentList", updatedAllRecords);
    },

    /*
    * this method will execute when user select/unselect the attachment
    */
    attachmentSelect: function(component, event, helper) {
        // on each checkbox selection update the selected record count
        var selectedRec = event.getSource().get("v.checked");
        var getSelectedNumber = component.get("v.selectedCount");
        if (selectedRec == true) {
            getSelectedNumber++;
        } else {
            getSelectedNumber--;
            component.find("selectAllId").set("v.checked", false);
        }
        component.set("v.selectedCount", getSelectedNumber);
        // if all checkboxes are checked then set header checkbox with true
        if (getSelectedNumber == component.get("v.totalRecordsCount")) {
            component.find("selectAllId").set("v.checked", true);
        }
    },

    /*
    *  returns only selected attachments from the list of attachments
    */
    getSelectedAttachments: function(component, event, helper){
        var allAttachments = component.get("v.attachmentList");
        return allAttachments.filter(function(obj) {
            return obj.isChecked;
          }).map(function(obj) { return obj.id; });
    },

    /*
    *  Adds additional attachments to the attachment list
    */
    addAdditionalAttachments: function(component, event, helper){
        var params = event.getParam('arguments');
        var actualAttachments = component.get("v.attachmentListOriginalCopy");
        var additionalAttachments = params.attachments;
        additionalAttachments = additionalAttachments.map(function(el) {
            var o = Object.assign({}, el);
            o.isChecked = true;
            o.contentSizeInString = helper.formatBytes(o.contentSize,2);
            return o;
        });
        component.set("v.additionalAttachmentList", additionalAttachments);
        let attachmentList = additionalAttachments.concat(actualAttachments);
        console.log('actualAttachments--->'+actualAttachments);
        component.set('v.attachmentList', attachmentList);
        helper.calculateSelectedCount(component, event, helper);
    }
})