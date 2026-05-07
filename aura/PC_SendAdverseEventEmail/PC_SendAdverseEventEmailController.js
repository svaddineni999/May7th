/**
 * Created by havalakki on 3/6/2020.
 */
({

    doInit : function(component, event, helper) {
        var action = component.get("c.getEmailAddressAndTemplateDetails");
        action.setParams({'adverseEventRecordId': component.get('v.recordId')});
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    var returnValue = a.getReturnValue();
                    var orgWideEmailAddressDetailsList = returnValue.orgWideEmailAddressWrapperList;
                    var eLetterTemplateDetailsList = returnValue.eLetterTemplateWrapperList;
                    var eLetterTemplateEmailAddressMap = returnValue.eLetterTemplateIdAndConfiguredRecipientsMap;

                    component.set('v.eLetterTemplateIdAndConfiguredRecipientsMap',eLetterTemplateEmailAddressMap);
                    if(orgWideEmailAddressDetailsList.length != 0){
                        var orgWideAddressValuesList=[];
                        for (var i = 0; i < orgWideEmailAddressDetailsList.length; i++) {
                            orgWideAddressValuesList.push({
                                label: orgWideEmailAddressDetailsList[i].orgWideEmailAddress,
                                value: orgWideEmailAddressDetailsList[i].orgWideEmailAddress
                            });
                        }
                        component.set('v.orgWideEmailAddressList',orgWideAddressValuesList);
                    }
                    var eLetterTemplateValuesList=[];
                    var noneOptionName = component.get("v.noneOptionName");
                    eLetterTemplateValuesList.push({
                         label: noneOptionName,
                         value: 'None'
                    });
                    if(eLetterTemplateDetailsList.length == 0){
                        component.set("v.showWarning",true);
                    }else{
                        for (var j = 0; j < eLetterTemplateDetailsList.length; j++) {
                            eLetterTemplateValuesList.push({
                                label: eLetterTemplateDetailsList[j].eLetterTemplateName,
                                value: eLetterTemplateDetailsList[j].eLetterTemplateId
                            });
                        }
                        component.set("v.showWarning",false);
                    }
                    component.set('v.eLetterTemplateList',eLetterTemplateValuesList);
                }
            }else if (state === "ERROR") {
                   var errors = a.getError();
                   CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);

            }else {
                 console.log("Unknown error");
            }
        });
        $A.enqueueAction(action);
    },

    handleEmailAddressChange: function (component, event, helper) {
            //Get the Selected values
            var selectedEmailAddresses = event.getParam("value");

            //Update the Selected Values
            component.set("v.selectedEmailAddressList", selectedEmailAddresses);
            if(selectedEmailAddresses.length == 0){
                component.set("v.disableSend",true);
            }else{
                component.set("v.disableSend",false);
            }
    },

    sendEmail : function (component, event, helper) {
        var action = component.get("c.sendAdverseEventMail");
        var templateId = component.get("v.selectedELetterTemplateId");
        var eLetterId = templateId.split('-')[0];
        action.setParams({
            'toAddressList' : component.get("v.selectedEmailAddressList"),
            'eLetterId' : eLetterId,
            'recordId' : component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    helper.showSuccessToastMessage(component, event, helper);
                    $A.get("e.force:closeQuickAction").fire();
                }
            }else if (state === "ERROR") {
                   var errors = a.getError();
                   CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            }else {
                 console.log("Unknown error");
            }
        });
        $A.enqueueAction(action);
    },

    handleChange: function (component, event, helper) {
        component.set('v.emailAddressList', []);
        component.set('v.selectedEmailAddressList', []);
        component.set("v.disableSend",true);
        if(component.get('v.selectedELetterTemplateId') != 'None'){
            var templateId = component.get("v.selectedELetterTemplateId");
            var eLetterId = templateId.split('-')[0];
            component.set("v.selectedeLetterId",eLetterId);
            var eLetterTemplateAndEmailAddressRecipients = component.get('v.eLetterTemplateIdAndConfiguredRecipientsMap');
            for(var key in eLetterTemplateAndEmailAddressRecipients){
                  if(key == component.get('v.selectedELetterTemplateId')){
                        var addressValuesList=[];
                        var selectedAddressValuesList=[];
                        for (var i = 0; i < eLetterTemplateAndEmailAddressRecipients[key].length; i++) {
                            if(typeof eLetterTemplateAndEmailAddressRecipients[key][i].recipientEmailId != "undefined"){
                                var label ='';
                                var value = '';
                                if(eLetterTemplateAndEmailAddressRecipients[key][i].recipientName != ''){
                                    label = eLetterTemplateAndEmailAddressRecipients[key][i].recipientName +'(' + eLetterTemplateAndEmailAddressRecipients[key][i].recipientEmailId +')';
                                    value = eLetterTemplateAndEmailAddressRecipients[key][i].recipientEmailId;
                                }else{
                                    label= eLetterTemplateAndEmailAddressRecipients[key][i].recipientEmailId;
                                    value= eLetterTemplateAndEmailAddressRecipients[key][i].recipientEmailId;
                                }

                                addressValuesList.push({
                                    label: label,
                                    value: value
                                });
                                selectedAddressValuesList.push(eLetterTemplateAndEmailAddressRecipients[key][i].recipientEmailId);
                            }
                        }

                      if(selectedAddressValuesList.length == 0){
                          var orgWideEmailAddresses = component.get("v.orgWideEmailAddressList");
                          if(orgWideEmailAddresses.length != 0){
                              for(var j=0; j<orgWideEmailAddresses.length; j++){
                                  addressValuesList.push({
                                      label: orgWideEmailAddresses[j].label,
                                      value: orgWideEmailAddresses[j].value
                                  });
                                  selectedAddressValuesList.push(orgWideEmailAddresses[j].value);
                                  component.set("v.disableSend",false);
                              }
                          }else{
                            component.set("v.disableSend",true);
                          }
                      }else{
                          component.set("v.disableSend",false);
                      }
                      component.set('v.emailAddressList', addressValuesList);
                      component.set('v.selectedEmailAddressList', selectedAddressValuesList);
                  }
            }
        }
    }

})