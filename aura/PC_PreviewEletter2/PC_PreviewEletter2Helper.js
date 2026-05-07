/**
 * Created by sathekumar on 11/18/2020.
 */
({
    getPreviewContent: function(component, event, helper){
        component.set('v.isPreviewLoading', true);
        var action = component.get("c.getTemplatePreviewForRecipients");
        action.setParams({
            "eLetterId": component.get('v.selectedELetterVal'),
            "recordId":  component.get("v.recordId"),
            "recipientId": component.get('v.selectedRecipientId')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                var emailTemplateObj = response.getReturnValue();
                component.set('v.eLetterTemplateObj', emailTemplateObj);
                component.set("v.eLetterTemplateType", emailTemplateObj.templateType);
                component.set("v.eLetterTemplateTextBody", emailTemplateObj.plainTextBody);
                component.set("v.eLetterTemplateHTMLBody", emailTemplateObj.htmlBody);
                console.log('response.getReturnValue()-->'+JSON.stringify(response.getReturnValue()));
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    component.set("v.errors", [errors[0]['message']]);
                }
            }
            component.set('v.isPreviewLoading', false);
        });
        $A.enqueueAction(action);
    },

    selectFirstRecipient : function(component, event, helper){
        var recipientList = component.get('v.selectedRecipientList');
        if(recipientList.length > 0){
            recipientList[0].isHighlighted = true;
            component.set('v.selectedRecipientId', ((recipientList[0].recipient.Id != undefined) && !((recipientList[0].recipient.Id).startsWith("R-"))) ? recipientList[0].recipient.Id : null);
            component.set('v.selectedRecipientObj', recipientList[0]);
        }
    },

    setShowPreviewLabel : function(component, event, helper){
        var recipientList = component.get("v.selectedRecipientList");
        var isSendToMeEnabled = component.get("v.isSendToMeEnabled");
        if(recipientList.length > 1 && !isSendToMeEnabled){
            component.set('v.showPreviewAsLabel', true);
        }
    },

    setSelectedRecipientObj: function(component, event, helper){
        var recipientList = component.get("v.selectedRecipientList");
        recipientList.forEach(function(obj) {
            obj.isHighlighted = false;
        });
        var selectedRecipientObj = recipientList.find(function (element) {
            return element.recipient.Id == event.currentTarget.id;
        });
        selectedRecipientObj.isHighlighted = true;
        console.log('selectedRecipientObj'+ JSON.stringify(selectedRecipientObj));
        component.set('v.selectedRecipientObj', selectedRecipientObj);
        component.set('v.selectedRecipientList', recipientList);
    },

    getAllSelectedRecipients: function(recipientList){
        return recipientList.filter(function(obj) {
            return (obj.sendEmail || obj.sendFax);
        }).map(function(obj, index) {
            obj.recipient.Id = (obj.recipient.Id) ? obj.recipient.Id : 'R-'+index ;
            obj.isHighlighted = false;
            return obj;
        });
    }
})