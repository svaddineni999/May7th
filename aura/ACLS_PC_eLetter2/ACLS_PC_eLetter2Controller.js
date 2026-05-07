/**
 * Created by ronakbansal on 3/14/2023.
 */
({
    doInit: function (component, event, helper) {
        console.log('here');
        helper.setNamespace(component, event, helper);
        helper.setRecordId(component, event, helper);
        helper.setPageReferenceValues(component, event, helper);   // get and set recordId, showAttachments, showPreviewScreen from pageReference/query parameters
        if(component.get('v.launchFrom') == 'QUICK_ACTION'){
            helper.setEletterTabIconAndLabel(component, event, helper);
        }
        if(component.get('v.openInNewTab')){
            helper.launchEletter(component, event, helper);
        } else {
            helper.setScreenButtonValues(component, event, helper, 'step1');    // set screen button values for screen navigation
            helper.doCategorySplit(component, event, helper);
            helper.initELetter(component, event, helper);   // Only this method will do server call
        }
    },

    refreshView: function (component, event, helper) {
        helper.refreshComponent(component, event, helper);
    },

    /*
    * Handler method for ELetter template. It helps to load the recipients based on template selection
    */
    handleTemplateChange: function (component, event, helper){
        var selectedELetterValue = event.getParam("value");
        component.set('v.selectedELetterVal', selectedELetterValue);
        component.set('v.eLetterTemplateSubject', '');
        component.set('v.eLetterTemplateFaxComments', '');
        component.set('v.additionalEmailAddress', '');
        if(selectedELetterValue!=undefined){
            helper.setSelectedEletterTemplateObj(component, event, helper);
            helper.setTemplateDescription(component, event, helper);
            helper.checkEletterCategory(component, event, helper);
            helper.loadRecipients(component, event, helper);
        }
    },

    onFromAddressChange: function (component, event, helper){
        var selectedValue = event.getParam("value");
        var fromAddressList = component.get('v.fromAddressList');
        var selectedFromAddressObj = fromAddressList.find(opt => opt.fromId === selectedValue);
        component.set('v.selectedFromAddressObj', selectedFromAddressObj);
    },

    /*
    * Calls sendEletter helper method to send outbound email
    */
    onSend: function (component, event, helper){
        if(component.get('v.currentStep') == 'step1') {
            if(! (helper.checkFieldValidation(component, event, helper))){
                return false;
            }
        }
        var btnValue = event.getSource().get("v.value");
        var isSecureBtnPressed = (btnValue == 'secure')?true:false;
        component.set('v.isEmailSecure',isSecureBtnPressed);
        var eLetterValue = component.get('v.selectedELetterVal');
        if(eLetterValue != undefined){
            helper.addAdditionalEmailsToRecipientList(component, event, helper);
            helper.hideInfoMessage(component, event, helper);
            helper.sendEletter(component, event, helper);
        }
        helper.updatePreviewDocument(component, event, helper);
    },

    /*
    * handler for previous button for page navigation
    */
    onPrevious: function (component, event, helper){
        helper.setScreenButtonValues(component, event, helper, 'step1');
        helper.updatePreviewDocument(component, event, helper);
    },

    /*
    * handler for Next button for page navigation
    */
    onNext: function (component, event, helper){
        if(helper.checkFieldValidation(component, event, helper)){
            helper.addAdditionalEmailsToRecipientList(component, event, helper);
            helper.setScreenButtonValues(component, event, helper, 'step2');
            if(component.get('v.hasCategoryFax')){
                helper.createPreviewOnlyDocument(component, event, helper);
            }
        }
    }
})