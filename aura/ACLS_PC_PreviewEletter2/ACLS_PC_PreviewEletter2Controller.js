/**
 * Created by ronakbansal on 3/28/2023.
 */
({

    doInit:  function(component, event, helper){
        var currentUserEmail = $A.get("$SObjectType.CurrentUser.Email"); // getting current user email address
        component.set('v.currentUserEmail', currentUserEmail);
        var targetRecipientList = component.get("v.targetRecipientList");
        var recipientListCopy = JSON.parse(JSON.stringify(targetRecipientList));
        var recipientList = helper.getAllSelectedRecipients(recipientListCopy);
        component.set('v.selectedRecipientList', recipientList);
        if(component.get('v.selectedELetterVal') != 'None') {
            helper.selectFirstRecipient(component, event, helper);
            helper.setShowPreviewLabel(component, event, helper);
            if(component.get('v.isFaxWorkflowEnabled')){
                helper.getFaxPreviewContent(component, event, helper);
            }else{
                helper.getPreviewContent(component, event, helper);
            }
        }
    },

    getRecipientPreview :  function(component, event, helper){
        var selectedELetterVal = component.get('v.selectedELetterVal');
        if(component.get('v.selectedRecipientId') != event.currentTarget.id && selectedELetterVal != 'None'){
            component.set('v.selectedRecipientId', (event.currentTarget.id).startsWith("R-") ? null : event.currentTarget.id);
            helper.setSelectedRecipientObj(component, event, helper);
            if(component.get('v.isFaxWorkflowEnabled')){
                helper.getFaxPreviewContent(component, event, helper);
            }else{
                helper.getPreviewContent(component, event, helper);
            }
        }
    },

    openAttachment : function(component, event, helper){
        var attId = event.currentTarget.dataset.attid;
        var openUrl = '/servlet/servlet.FileDownload?file='+attId;
        window.open(openUrl,"_blank");
    }
})