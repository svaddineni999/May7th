/*
 * Created by cmohapatra on 10/15/2020.
 */
({
   doInit: function (component, event, helper) {
      helper.setNamespace(component, event, helper);
      helper.setPageReferenceValues(component, event, helper);
      helper.getInit(component,event,helper);
      var messageLength= component.get("v.messageLength");
      if((isNaN(messageLength) || (messageLength ==''))){
           var error = component.get("v.incorrectMessageLength");
           component.set("v.errors", [error]);
           component.set("v.disableMessageBody",true);
      }
   },

   handleTemplateChange: function (component, event, helper){
       var selectedELetterValue = event.getParam("value");
       component.set('v.selectedELetterVal', selectedELetterValue);
       if(selectedELetterValue!=undefined && selectedELetterValue!= ''){
            component.set("v.onTemplateSelection",true);
            component.set("v.multipleRecipientsSelected",false);
            component.set("v.selectAllRecipients",false);
            component.set("v.smsBody","");
            component.set("v.errors", []);
            helper.loadRecipients(component, event, helper);
       }else{
           helper.clearSelection(component, event, helper);
           component.set('v.onTemplateSelection', false);
           component.set('v.multipleRecipientsSelected', false);
           component.set('v.disableMessageBody', false);
           component.set('v.disableSendButton',false);
           component.set("v.errors", []);
       }
   },

   onSenderNumberChange:function(component, event, helper){
       component.set("v.errors", []);
   },

  onRecipientChange:function(component, event, helper){
       // var selectedRecipientId=  event.getSource().get("v.value");
       var selectedELetterValue=component.get("v.selectedELetterVal");
       helper.onRecipientChange(component, event, helper);
       if( selectedELetterValue!=undefined && selectedELetterValue!= ''){
           component.set("v.onTemplateSelection", false);
           helper.setFirstSelectedRecipient(component, event, helper);
       }
  },

   selectRecipients:function(component,event,helper){
     var allRecipientsSelected =component.get("v.selectAllRecipients");
     var selectedELetterValue=component.get("v.selectedELetterVal");
     if(selectedELetterValue!=undefined && selectedELetterValue!=''){
        if(allRecipientsSelected){
            component.set("v.multipleRecipientsSelected", true);
            component.set("v.onTemplateSelection", false);
        }else{
            component.set("v.multipleRecipientsSelected", false);
            component.set("v.smsBody","");
        }
     }
     helper.selectAllRecipients(component,event,helper);
   },

  onSmsBodyChange:function(component, event, helper){
    component.set("v.messageLengthLimit",false);
    helper.onSmsBodyChange(component, event, helper);
  },

  onSend: function (component, event, helper){
    helper.checkRecipientsValidity(component, event, helper);
    helper.reportValidity(component,event,helper);
    helper.onSendValidation(component,event,helper);
    var reportValidityResult= helper.reportValidity(component,event,helper);
    var onSendValidationResult= helper.onSendValidation(component,event,helper);
      if(reportValidityResult || !onSendValidationResult){
      return false;
    }
    helper.sendMessage(component,event,helper);
  }



})