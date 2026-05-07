/**
 * Created by cmohapatra on 10/16/2020.
 */
({
  //To get the namespace
  setNamespace : function(component, event, helper) {
      var ns = CH_PC_Util.getNamespace(component);
      var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
      component.set("v.namespace", ns);
      component.set("v.namespacePrefix", nsPrefix);
  },

 //To set the page reference values
  setPageReferenceValues: function(component, event, helper) {
    var namespace = component.get("v.namespace");
    var pageReference = component.get("v.pageReference");
    var recordIdName = CH_PC_Util.getQualifiedQueryParam(component,'recordId',namespace);
    var recordId;
    if(pageReference && pageReference.state){
        if(pageReference.state[recordIdName] != 'NULL' && pageReference.state[recordIdName] != 'undefined'){
            recordId = pageReference.state[recordIdName];
        }
    }
    else{
        var query = location.search.substr(1);
        var result = {};
        query.split("&").forEach(function(part) {
        var item = part.split("=");
        if(!$A.util.isUndefinedOrNull(item[0]) && !$A.util.isUndefinedOrNull(item[1])){
            result[item[0]] = decodeURIComponent(item[1]);
        }
        });
        recordId = ($A.util.isUndefinedOrNull(recordId))?result[recordIdName]:recordId;
    }
    component.set("v.recordId", (recordId != undefined)? recordId :component.get("v.recordId"));
  },
//Getting the sender and recipient data from remote method call
  getInit: function(component, event, helper){
       helper.showSpinner(component, event, helper);
        var action = component.get("c.getInitInfo");
         action.setParams({
            caseId: component.get("v.recordId"),
            smsCategoryList: component.get("v.smsCategoryList")
        });
        action.setCallback(this, function(response) {
        let state = response.getState();
        if (state === "SUCCESS") {
            //Sender Data
            var senderPhoneNumberObj = (response.getReturnValue().senders !== undefined)? response.getReturnValue().senders:[];
            console.log('senderPhoneNumberObj'+senderPhoneNumberObj);
            helper.setSenderData(component, event, helper,senderPhoneNumberObj);

           //Recipient Data
            var recipientPhoneNumberObj=(response.getReturnValue().recipients !== undefined)? response.getReturnValue().recipients:[];
            console.log('recipientPhoneNumberObj' +recipientPhoneNumberObj);
            component.set("v.smsRecipientsData",recipientPhoneNumberObj);
            helper.validateRecipientPhoneNumber(component,event,helper,recipientPhoneNumberObj);

            //Template Data
            var availableTemplateList =(response.getReturnValue().eletterTemplateList !== undefined)? response.getReturnValue().eletterTemplateList:[];
            console.log('availableTemplateList-->' +availableTemplateList);
            //Set Template Options
            helper.setTemplateValues(component, event, helper, availableTemplateList);
            if(availableTemplateList.length == 0){
                component.set("v.message", component.get("v.msgNoEngagementProgram"));
                helper.showInfoMessage(component, event, helper);
            }
        }else{
            //Error Panel
            var  allErrors = component.get("v.errors");
            var errorMessage=component.get("v.lightingErrorMessage");
            var error =  response.getError();
            if (error && error[0] && error[0].message) {
                allErrors.push(error[0].message);
                component.set("v.errors", allErrors);
            }
            else{
                allErrors.push(errorMessage);
                component.set("v.errors", allErrors);
            }
        }
        helper.hideSpinner(component, event, helper);
        });

        $A.enqueueAction(action);
  },

// Set Template Options
  setTemplateValues : function(component, event, helper, availableTemplateList){
      var templateOpts=[];
      templateOpts.push({
          "label": component.get("v.noneOptionName"),
          "value": ''
      });
      for(var i=0;i< availableTemplateList.length;i++){
          var currentVal = availableTemplateList[i];
          templateOpts.push({
              "label": currentVal.name,
              "value": currentVal.value
              });
      };
      component.set("v.templateOptions", templateOpts);
      var templateMap = availableTemplateList.map(function(template) {
                            var o = Object.assign({}, template);
                            o.category = ((!$A.util.isEmpty(template.category))? template.category : '');
                            o.description = ((!$A.util.isEmpty(template.description))? template.description : '');
                            o.engProgDescription = ((!$A.util.isEmpty(template.engProgEletterDescription))? template.engProgEletterDescription : '');
                            return o;
                        });
      var noneOption = {
                       "name": 'None',
                       "value": '',
                       "category" : '',
                       "description" : '',
                       "engProgDescription" : ''
                       };
      templateMap.unshift(noneOption);
      component.set("v.eletterTemplateList", templateMap);
      if(templateOpts.length >= 1){
          component.set("v.selectedELetterVal", templateOpts[0].value);
      }
  },
  // Makes Server call and get all recipients based on recordId and Selected ELetter (letterId)
  loadRecipients: function(component, event, helper) {
      component.set("v.isRecipientLoading", true);
      helper.enableElements(component, event, helper);
      var action = component.get("c.getEletterInfo");
      action.setParams({
          "recordId": component.get("v.recordId"),
          "letterId": (component.get('v.selectedELetterVal') != '')?component.get('v.selectedELetterVal'): null
      });
      action.setCallback(this, function(response) {
          var state =response.getState();
          if (state === 'SUCCESS'){
             var eLetterInfoObj = response.getReturnValue();
             var recipientList = (eLetterInfoObj.eLetterRecipients !== undefined)? eLetterInfoObj.eLetterRecipients:[];
             var templatePlainTextBody= eLetterInfoObj.templatePlainTextBody;
             component.set("v.eLetterTemplateTextBody",templatePlainTextBody);
             if(templatePlainTextBody !== undefined){
                component.set("v.smsBody",templatePlainTextBody );
                helper.onSendValidation(component, event, helper);
                component.set("v.disableMessageBody", true);
             }
             if($A.util.isEmpty(recipientList)){
                component.set("v.onTemplateSelection",false);
                var error = component.get("v.noRecipientAvailableError");
                component.set("v.errors", [error]);
             }
             component.set("v.smsRecipientsData", recipientList);
            helper.validateRecipientPhoneNumber(component,event,helper,eLetterInfoObj.eLetterRecipients);
            helper.getTemplateBodyForAllRecipients(component,event,helper);
            component.set("v.isRecipientLoading", false);
          }else{
            //Error Panel
            helper.disableElements(component, event, helper);
            helper.onSendValidation(component, event, helper);
            component.set("v.isRecipientLoading", false);
            component.set("v.onTemplateSelection", false);
            component.set("v.smsRecipientsData",[]);
            helper.validateRecipientPhoneNumber(component,event,helper,[]);
            var  allErrors = component.get("v.errors");
            var errorMessage=component.get("v.lightingErrorMessage");
            var error =  response.getError();
            if (error && error[0] && error[0].message) {
                allErrors.push(error[0].message);
                component.set("v.errors", allErrors);
            }else{
                allErrors.push(errorMessage);
                component.set("v.errors", allErrors);
            }
          }
      });
      $A.enqueueAction(action);
  },
//Setting the sender data
 setSenderData: function(component,event, helper, senderPhoneNumberObj){
    var senderPhoneNumberOptions= [];
    senderPhoneNumberOptions.push({
        "label": component.get("v.noneOptionName"),
        "value": ''
    });
    for(var i=0;i<senderPhoneNumberObj.length;i++){
        var sender = senderPhoneNumberObj[i];
        senderPhoneNumberOptions.push({
            "label": sender.name+' <'+sender.phone+'>',
            "value": sender.phone
        });
         //check if sender phoneNumber is blank.
         if(($A.util.isEmpty(sender.phone)) || (sender.phone== ' ')){
            var error = component.get("v.incorrectPhoneNumber");
            var  allErrors = component.get("v.errors");
            allErrors.push(error);
            component.set("v.errors", allErrors);
         }
    }
    component.set("v.senderPhoneNumberOptions", senderPhoneNumberOptions);
    if(senderPhoneNumberOptions.length == 2){
        component.set('v.selectedSenderNumber', senderPhoneNumberOptions[1].value);
    }
 },

 //To disable header check box
 checkHeaderCheckbox: function(component, event, helper) {
     var listOfSmsRecipients = component.get("v.smsRecipientsData");
     // check for each recipient, disabled or not
     const checkValidRecipient = listOfSmsRecipients.every(recipient => recipient.disableSms);
     console.log('checkValidRecipient-->' +checkValidRecipient);
     if(checkValidRecipient){
         component.set("v.disableHeaderCheckbox", true);
     }
     else{
         component.set("v.disableHeaderCheckbox", false);
     }
 },

//Onchange of Recipient
 onRecipientChange:function(component, event, helper){
   var listOfSmsRecipients = component.get("v.smsRecipientsData");
   var selectAllRecipients=component.get("v.selectAllRecipients");
   for (var i = 0; i < listOfSmsRecipients.length; i++) {
       if(selectAllRecipients && !(listOfSmsRecipients[i].sendSms)){
           component.set("v.selectAllRecipients",false);
       }
   }
    //Calculate Recipients
    var selectedRecipientCount=0;
    var disabledRecipientCount= 0;
    var recipientListLength= listOfSmsRecipients.length;
    listOfSmsRecipients.forEach(recipient => {
         selectedRecipientCount = selectedRecipientCount + (recipient.sendSms == true ? 1 : 0);
         disabledRecipientCount= disabledRecipientCount + (recipient.disableSms == true ? 1 : 0);
    });
    recipientListLength= recipientListLength - disabledRecipientCount ;
    //If all recipients are selected, header checkbox should get selected.
    if(selectedRecipientCount == recipientListLength ){
     component.set("v.selectAllRecipients", true);
    }
    //On Template Selection
   var selectedELetterValue=component.get("v.selectedELetterVal");
   if(selectedELetterValue!=undefined && selectedELetterValue!= ''){
      if(selectedRecipientCount>1){
        component.set("v.multipleRecipientsSelected", true);
      }else{
        component.set("v.multipleRecipientsSelected", false);
      }
   }
 },

  setFirstSelectedRecipient: function(component, event, helper){
     var selectedRecipientId=  event.getSource().get("v.value");
     // var isRecipientSelected= event.getSource().get("v.checked");
     var selectedRecipients = helper.getSelectedRecipients(component.get('v.smsRecipientsData'));
     var selectedRecipientObj;
     var allRecipientSelected= component.get("v.selectAllRecipients");
     if(!$A.util.isEmpty(selectedRecipients)){
         for (var i = 0; i < selectedRecipients.length; i++) {
             if(allRecipientSelected || selectedRecipients.length > 1){
                 selectedRecipientObj= selectedRecipients[0];
                 break;
             }else if(selectedRecipientId == selectedRecipients[i].Id){
                selectedRecipientObj= selectedRecipients[i];
                break;
             }else{
                 selectedRecipientObj= selectedRecipients[0];
             }
         }
         if(!$A.util.isUndefinedOrNull(selectedRecipientObj)){
            component.set("v.smsBody",selectedRecipientObj.msgBody);
         }
         component.set("v.disableMessageBody",true);
         component.set('v.selectedRecipientObj', selectedRecipientObj);
     }else if($A.util.isEmpty(selectedRecipients) || !allRecipientSelected){
       var templatePlainTextBody= component.get("v.eLetterTemplateTextBody");
       component.set("v.smsBody",templatePlainTextBody);
       component.set("v.multipleRecipientsSelected", false);
       component.set("v.onTemplateSelection",true);
       component.set("v.disableMessageBody",true);
     }
  },

 //To show message body content specific to the recipient for a Template.
  getTemplateBodyForAllRecipients:function(component,event,helper){
      var allRecipients = component.get('v.smsRecipientsData');
      var action = component.get("c.getRenderedMailTemplate");
      action.setParams({
          "recordId": component.get("v.recordId"),
          "selectedRecipients":JSON.stringify(allRecipients),
          "eletterId": (component.get('v.selectedELetterVal') != '')?component.get('v.selectedELetterVal'): null
      });
      action.setCallback(this, function(response) {
            var state =response.getState();
            if (state === 'SUCCESS'){
                var recipientSpecificContent = response.getReturnValue();
                for(var k=0; k < allRecipients.length ; k++){
                    for (var i = 0; i < recipientSpecificContent.length; i++) {
                        if(allRecipients[k].Id == recipientSpecificContent[i].recipientId){
                            allRecipients[k].msgBody = recipientSpecificContent[i].renderedTextBody;
                        }
                    }
                }
                component.set("v.smsRecipientsData",allRecipients);
            }else{
                //Error Panel
                var  allErrors = component.get("v.errors");
                var errorMessage=component.get("v.lightingErrorMessage");
                var error =  response.getError();
                if (error && error[0] && error[0].message) {
                    allErrors.push(error[0].message);
                    component.set("v.errors", allErrors);
                }else{
                    allErrors.push(errorMessage);
                    component.set("v.errors", allErrors);
                }
            }
    });
    $A.enqueueAction(action);
  },

//To select all the recipients
 selectAllRecipients: function(component, event, helper) {
     var selectedHeaderCheck = event.getSource().get("v.checked");
     var updateRecipients = [];
     var listOfSmsRecipients = component.get("v.smsRecipientsData");
     var selectedELetterValue=component.get("v.selectedELetterVal");
      console.log("listOfSmsRecipients.length" +listOfSmsRecipients.length);
     //for loop on all records list
     for (var i = 0; i < listOfSmsRecipients.length; i++) {
         // check if header checkbox is 'true' then update all checkbox with true else update all records with false
         if (selectedHeaderCheck == true) {
             if(!(listOfSmsRecipients[i].disableSms)){
                listOfSmsRecipients[i].sendSms = true;
             }
         }else {
             listOfSmsRecipients[i].sendSms = false;
         }
         updateRecipients.push(listOfSmsRecipients[i]);
     }
     component.set("v.smsRecipientsData", updateRecipients);
     if(!$A.util.isEmpty(selectedELetterValue) && !$A.util.isUndefinedOrNull(selectedHeaderCheck)){
         helper.setFirstSelectedRecipient(component,event,helper);
     }
},

//validation for  the recipient phone number
 validateRecipientPhoneNumber:function(component,event, helper,recipientPhoneNumberObj){
   var noContactNameList = [];
   for (var i = 0; i <recipientPhoneNumberObj.length; i++) {
      var recipient= recipientPhoneNumberObj[i]
     if(recipient.hasNoPhoneNumber == true){
        noContactNameList.push(recipient.name);
     }
    console.log('noContactNameList-->' +noContactNameList);
   }
   component.set("v.message","");
    if(noContactNameList.length > 0){
      for(var j=0;j<noContactNameList.length ;j++){
        component.set("v.message", component.get("v.msgNoPhoneAvailable")+' '+noContactNameList.join(' ; '));
      }
    }
    if($A.util.isEmpty(component.get("v.message"))){
      helper.hideInfoMessage(component, event, helper);
    } else {
        helper.showInfoMessage(component, event, helper);
    }
     helper.checkHeaderCheckbox(component,event,helper);
 },
  // Method to show warning info message
 showInfoMessage: function(component, event, helper){
     var toggleText = component.find("msgResult");
     $A.util.removeClass(toggleText, 'slds-hide');
     $A.util.addClass(toggleText, 'slds-show');
 },

 //Method to hide warning info message
 hideInfoMessage: function(component, event, helper){
     var toggleText = component.find("msgResult");
     $A.util.removeClass(toggleText, 'slds-show');
     $A.util.addClass(toggleText, 'slds-hide');
 },

//Get the selected recipients
 getSelectedRecipients: function(recipientList){
    return recipientList.filter(function(obj) {
        return (obj.sendSms);
      }).map(function(obj) { return obj; });
 },

 // Returns the valid property value (Boolean) to indicate whether the recipient is selected or not.
 checkRecipientsValidity : function(component, event, helper){
     var selectedRecipients = helper.getSelectedRecipients(component.get('v.smsRecipientsData'));
     console.log("selectedRecipients-->" +selectedRecipients);
     if(selectedRecipients.length < 1){
         component.set('v.isRecipientsSelected', false);
     }
     else {
         component.set('v.isRecipientsSelected', true);
     }
     return component.get('v.isRecipientsSelected');
 },


 //Display error messages if the recipient is not selected.
  reportValidity : function(component, event, helper){
      var validationError = component.get('v.validationError');
     if(component.get('v.isRecipientsSelected')){
         component.set('v.messageWhenRecipientNotSelected', '');
     }
     else{
         component.set('v.messageWhenRecipientNotSelected', component.get("v.noRecipientSelected"));
         validationError= true;
     }
     return validationError;
 },

//Validation of From & Message body fields on send
 onSendValidation: function(component, event, helper){
     var smsSenderField= component.find('smsSenderField');
     if(smsSenderField!= undefined){
        let isAllValid = smsSenderField.reduce(function(isValidSoFar, inputCmp){
        inputCmp.reportValidity();
        return isValidSoFar && inputCmp.checkValidity();
        },true);
        return isAllValid;
     }
    else{
        return false;
    }
},

 sendMessage: function(component,event,helper) {
    var action = component.get("c.sendMessage");
    var selectedRecipients =helper.getSelectedRecipients(component.get('v.smsRecipientsData'));
    console.log('getSelectedRecipients-->' +selectedRecipients);
    action.setParams({
        "caseId": component.get("v.recordId"),
        "messageBody": component.get("v.smsBody"),
        "sender":component.get("v.selectedSenderNumber"),
        "selectedRecipients":JSON.stringify(selectedRecipients),
        "eletterId":(component.get('v.selectedELetterVal') != '')?component.get('v.selectedELetterVal'): null
    });

    action.setCallback(this, function(response) {
        var state = response.getState();
        if(state ==="SUCCESS"){
            var returnValue= response.getReturnValue();
            var messages = returnValue.messages;
            var messageObjectName = returnValue.messageObjectName;
            var messageRelationshipName= returnValue.messageRelationshipName;
            var eachResponseNew;
            debugger;
            if(messages.length<=1){
                eachResponseNew = [];
                eachResponseNew.push(messages[0].Name);
                eachResponseNew.push(messages[0].Id);
                eachResponseNew.push(messageObjectName);
                helper.singleRecipientToast(component, event, helper,eachResponseNew);
            }else{
                eachResponseNew = [];
                var caseApiName=component.get('v.namespace')+'__'+component.get('v.caseFieldApiName');
                eachResponseNew.push(messages[0][caseApiName]);
                eachResponseNew.push(messageRelationshipName);
                helper.multiRecipientToast(component, event, helper,eachResponseNew);
            }
            helper.closeCmp(component, event, helper);
            component.set("v.multipleRecipientsSelected",false);
            component.set("v.disableMessageBody",false);
            helper.clearSelection(component,event,helper);
        }
        else if (state === "ERROR"){
            var  allErrors = component.get("v.errors");
            var errorMessage=component.get("v.smsError");
            var error =  response.getError();
            if (error && error[0] && error[0].message) {
                allErrors.push(error[0].message);
                component.set("v.errors", allErrors);
            }
          else{
            allErrors.push(errorMessage);
            component.set("v.errors", allErrors);
          }
        }
        else {
           console.log("Failed with state: " + state);
        }
    });
    $A.enqueueAction(action);
 },

 //Show toast message for single recipient
 singleRecipientToast: function(component, event, helper,response) {
     var toastEvent = $A.get("e.force:showToast");
     var msg = component.get("v.toastSendSuccessMessage");
     var title = component.get("v.toastSuccessTitle");
     toastEvent.setParams({
         "title": title,
          "message": msg,
          "messageTemplate": component.get("v.toastLabelForSingleRecipient"),
          "messageTemplateData": [ {
             url:'/lightning/r/'+response[2]+'/'+response[1]+'/view',
             label:component.get("v.toastLinkForSingleRecipient"), },
           ],
         "type": "success",
         "mode":"dismissable"
     });
     toastEvent.fire();
 },

  //Show toast message for multi recipients
  multiRecipientToast : function(component, event, helper,response) {
      debugger;
      var toastEvent = $A.get("e.force:showToast");
      var msg =component.get("v.toastSendSuccessMessage");
      var title = component.get("v.toastSuccessTitle");
      toastEvent.setParams({
          "title": title,
           "message": msg,
           "messageTemplate":component.get("v.toastLabelForMultipleRecipients"),
           "messageTemplateData": [ {
              url:'/lightning/r/'+response[0]+'/related/'+response[1]+'/view' ,
              label:component.get("v.messageRelatedListLabel"), },
            ],
          "type": "success",
          "mode":"dismissable"
      });
      toastEvent.fire();
  },

//on change of message body
 onSmsBodyChange:function(component, event, helper){
    var messageLength= component.get('v.messageLength');
    var smsBody= component.get('v.smsBody');
    var smsBodyLength= smsBody.length;
    if(smsBodyLength >0 && smsBodyLength == messageLength){
        component.set('v.messageLengthLimit', true);
    }
 },

//To clear all selected field values
 clearSelection:function(component,event,helper){
    component.set('v.smsBody', '');
    component.set('v.selectedSenderNumber','');
    component.set("v.selectAllRecipients",false);
    helper.getInit(component,event,helper);
 },

 //To disable elements
 disableElements: function(component, event, helper){
     component.set("v.disableMessageBody", true);
     component.set("v.disableSendButton", true);
 },

 //To enable disabled elements
 enableElements:function(component, event, helper){
   component.set("v.disableMessageBody", false);
   component.set("v.disableSendButton", false);
 },

//To close the component
 closeCmp:function(component, event, helper){
     var compEvent = component.getEvent("actionPanel");
     compEvent.setParams({"actionPanel" : false });
     compEvent.fire();
     component.find("overlayLib").notifyClose();
 },

  //To show the spinner
  showSpinner: function(component, event, helper) {
     // remove slds-hide class from smsSpinner
     var spinner = component.find("smsSpinner");
     $A.util.removeClass(spinner, "slds-hide");
  },

  //To hide the spinner
  hideSpinner : function(component,event,helper){
     // add slds-hide class to smsSpinner
     var spinner = component.find("smsSpinner");
     $A.util.addClass(spinner, "slds-hide");
  }

  })