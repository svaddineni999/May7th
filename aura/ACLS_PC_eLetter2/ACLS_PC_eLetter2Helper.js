/**
 * Created by ronakbansal on 3/14/2023.
 */
({

    setEletterTabIconAndLabel : function(component, event, helper) {
        var workspaceAPI = component.find("eLetterWorkspace");
        workspaceAPI.getEnclosingTabId().then(function(tabId) {
            workspaceAPI.setTabIcon({
                tabId: tabId,
                icon: component.get('v.eletterTabIcon'),
                iconAlt: component.get('v.eletterTabLabel')
            });
            workspaceAPI.setTabLabel({
                tabId: tabId,
                label: component.get('v.eletterTabLabel')
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    },

    launchEletter : function(component, event, helper){
        var workspaceAPI = component.find("eLetterWorkspace");
        var showAttachments = component.get('v.showAttachments');
        var showPreviewScreen = component.get('v.showPreviewScreen');
        var showSendSecureOption = component.get('v.showSendSecureOption');
        var closeTabAfterSend = component.get('v.closeTabAfterSend');
        var enableEmailWorkflow = component.get('v.emailWorkflow');
        var enableFaxWorkflow = component.get('v.faxWorkflow');
        var eletterContext = component.get('v.eletterContext');
        var moreEmailRecipients = component.get('v.moreEmailRecipients');
        var hideConsent = component.get('v.hideConsent');
        var launchFrom = component.get('v.launchFrom');

        var recordId = component.get('v.recordId');
        var namespace = component.get("v.namespace");
        var componentAPIName =  namespace+'__'+component.get("v.eletterComponentName");
        var pageAPIName = component.get("v.namespacePrefix") +component.get("v.eletterPageName");
        var qualifiedIdName = CH_PC_Util.getQualifiedQueryParam(component,'recordId',namespace);
        var qualifiedShowAttachmentsName = CH_PC_Util.getQualifiedQueryParam(component,'showAttachments',namespace);
        var qualifiedShowPreviewScreenName = CH_PC_Util.getQualifiedQueryParam(component,'showPreviewScreen',namespace);
        var qualifiedShowSendSecureOptionName = CH_PC_Util.getQualifiedQueryParam(component,'showSendSecureOption',namespace);
        var qualifiedOpenInNewTabName = CH_PC_Util.getQualifiedQueryParam(component,'openInNewTab',namespace);
        var qualifiedCloseTabAfterSendName = CH_PC_Util.getQualifiedQueryParam(component,'closeTabAfterSend',namespace);
        var qualifiedEnableEmailWorkflowName = CH_PC_Util.getQualifiedQueryParam(component,'emailWorkflow',namespace);
        var qualifiedEnableFaxWorkflowName = CH_PC_Util.getQualifiedQueryParam(component,'faxWorkflow',namespace);
        var qualifiedEletterContextName = CH_PC_Util.getQualifiedQueryParam(component,'eletterContext',namespace);
        var qualifiedMoreEmailRecipientsName = CH_PC_Util.getQualifiedQueryParam(component,'moreEmailRecipients',namespace);
        var qualifiedHideConsentName = CH_PC_Util.getQualifiedQueryParam(component,'hideConsent',namespace);
        var qualifiedlaunchFromName = CH_PC_Util.getQualifiedQueryParam(component,'launchFrom',namespace);

        var tabParamsObject = new Object();
        tabParamsObject.uid = 'EL-'+recordId;
        tabParamsObject[qualifiedIdName] = recordId;
        tabParamsObject[qualifiedShowAttachmentsName] = showAttachments;
        tabParamsObject[qualifiedShowPreviewScreenName] = showPreviewScreen;
        tabParamsObject[qualifiedShowSendSecureOptionName] = showSendSecureOption;
        tabParamsObject[qualifiedOpenInNewTabName] = false;
        tabParamsObject[qualifiedCloseTabAfterSendName] = closeTabAfterSend;
        tabParamsObject[qualifiedEnableEmailWorkflowName] = enableEmailWorkflow;
        tabParamsObject[qualifiedEnableFaxWorkflowName] = enableFaxWorkflow;
        tabParamsObject[qualifiedEletterContextName] = eletterContext;
        tabParamsObject[qualifiedMoreEmailRecipientsName] = moreEmailRecipients;
        tabParamsObject[qualifiedHideConsentName] = hideConsent;
        tabParamsObject[qualifiedlaunchFromName] = launchFrom;

        var urlParams = '?'+qualifiedIdName+'='+recordId+'&'+qualifiedShowAttachmentsName+'='+showAttachments+'&'+qualifiedShowPreviewScreenName+'='+showPreviewScreen+'&'+qualifiedShowSendSecureOptionName+'='+showSendSecureOption+'&'+qualifiedOpenInNewTabName+'=false&'+qualifiedCloseTabAfterSendName+'='+closeTabAfterSend+'&'+qualifiedEnableEmailWorkflowName+'='+enableEmailWorkflow+'&'+qualifiedEnableFaxWorkflowName+'='+enableFaxWorkflow+'&'+qualifiedEletterContextName+'='+eletterContext+'&'+qualifiedMoreEmailRecipientsName+'='+moreEmailRecipients+'&'+qualifiedlaunchFromName+'='+launchFrom+'&'+qualifiedHideConsentName+'='+hideConsent;

        workspaceAPI.isConsoleNavigation().then(function(isConsole) {
            if (isConsole) {
                // this block of code helps to open the component in new console tab if it is console app
                CH_PC_Util.openLightningComponentInNewTab(workspaceAPI,componentAPIName,pageAPIName,tabParamsObject,
                        component.get("v.eletterTabLabel"),component.get("v.eletterTabIcon"),true,urlParams);
            } else {
                // this block of code helps to open the component in new tab if it is lightning app
                var url = '/lightning/cmp/' + componentAPIName + urlParams;
                window.open(url,"_blank");
            }
        })
        .catch(function(error) {
            console.log(error);
        });
    },

    refreshComponent: function(component, event, helper){
        helper.clearAllValues(component, event, helper);    // Reset all attribute values for force:refreshView
        helper.setScreenButtonValues(component, event, helper, 'step1');    // set screen button values for screen navigation
        helper.initELetter(component, event, helper);   // Only this method will do server call
    },

    /*
    * clear values of all attributes to default value when force:refreshView
    */
    clearAllValues: function(component, event, helper) {
        component.set('v.fromOptions', []);
        component.set('v.templateOptions', []);
        component.set('v.showPreviousBtn', false);
        component.set('v.showNextBtn', false);
        component.set('v.showSendBtn', false);
        component.set('v.showSecureBtn', false);
        component.set('v.isSendToMeEnabled', false);
        component.set('v.isEmailSecure', false);
        component.set('v.currentStep', 'step1');
        component.set('v.targetRecipientList', []);
        component.set("v.finalRecipientList", []);
        component.set('v.selectedELetterVal', '');
        component.set('v.selectedFromAddress', '');
        component.set("v.errors", []);
        component.set("v.message", '');
        component.set("v.templateDescription", '');
        component.set("v.selectedAttachmentCount", 0);
        component.set("v.eLetterTemplateSubject", '');
        component.set("v.eLetterTemplateFaxComments", '');
        component.set("v.eLetterTemplateType", '');
        component.set("v.eLetterTemplateTextBody", '');
        component.set("v.eLetterTemplateHTMLBody", '');
        component.set("v.additionalEmailAddress", '');
        helper.hideInfoMessage(component, event, helper);
    },

    setNamespace : function(component, event, helper) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },

    /*
    * get and set recordId, showAttachments, showPreviewScreen from pageReference/query parameters
    */
    setPageReferenceValues: function(component, event, helper) {
        var namespace = component.get("v.namespace");
        var pageReference = component.get("v.pageReference");
        var recordIdName = CH_PC_Util.getQualifiedQueryParam(component,'recordId',namespace);
        var showAttachmentsName = CH_PC_Util.getQualifiedQueryParam(component,'showAttachments',namespace);
        var showPreviewScreenName = CH_PC_Util.getQualifiedQueryParam(component,'showPreviewScreen',namespace);
        var showSendSecureOptionName = CH_PC_Util.getQualifiedQueryParam(component,'showSendSecureOption',namespace);
        var openInNewTabName = CH_PC_Util.getQualifiedQueryParam(component,'openInNewTab',namespace);
        var closeTabAfterSendName = CH_PC_Util.getQualifiedQueryParam(component,'closeTabAfterSend',namespace);
        var enableEmailWorkflowName = CH_PC_Util.getQualifiedQueryParam(component,'emailWorkflow',namespace);
        var enableFaxWorkflowName = CH_PC_Util.getQualifiedQueryParam(component,'faxWorkflow',namespace);
        var eletterContextName = CH_PC_Util.getQualifiedQueryParam(component,'eletterContext',namespace);
        var moreEmailRecipientsName = CH_PC_Util.getQualifiedQueryParam(component,'moreEmailRecipients',namespace);
        var launchFromName = CH_PC_Util.getQualifiedQueryParam(component,'launchFrom',namespace);
        var hideConsentName = CH_PC_Util.getQualifiedQueryParam(component,'hideConsent',namespace);

        var recordId, showAttachments, showPreviewScreen, showSendSecureOption, openInNewTab, closeTabAfterSend, enableEmailWorkflow, enableFaxWorkflow, eletterContext, moreEmailRecipients, launchFrom, hideConsent;
        if(pageReference && pageReference.state){
            if(pageReference.state[recordIdName] != 'NULL' && pageReference.state[recordIdName] != 'undefined'){
                recordId = pageReference.state[recordIdName];
            }
            if(pageReference.state[showAttachmentsName] != 'NULL' && pageReference.state[showAttachmentsName] != 'undefined'){
                showAttachments = pageReference.state[showAttachmentsName];
            }
            if(pageReference.state[showPreviewScreenName] != 'NULL' && pageReference.state[showPreviewScreenName] != 'undefined'){
                showPreviewScreen = pageReference.state[showPreviewScreenName];
            }
            if(pageReference.state[showSendSecureOptionName] != 'NULL' && pageReference.state[showSendSecureOptionName] != 'undefined'){
                showSendSecureOption = pageReference.state[showSendSecureOptionName];
            }
            if(pageReference.state[openInNewTabName] != 'NULL' && pageReference.state[openInNewTabName] != 'undefined'){
                openInNewTab = pageReference.state[openInNewTabName];
            }
            if(pageReference.state[closeTabAfterSendName] != 'NULL' && pageReference.state[closeTabAfterSendName] != 'undefined'){
                closeTabAfterSend = pageReference.state[closeTabAfterSendName];
            }
            if(pageReference.state[enableEmailWorkflowName] != 'NULL' && pageReference.state[enableEmailWorkflowName] != 'undefined'){
                enableEmailWorkflow = pageReference.state[enableEmailWorkflowName];
            }
            if(pageReference.state[enableFaxWorkflowName] != 'NULL' && pageReference.state[enableFaxWorkflowName] != 'undefined'){
                enableFaxWorkflow = pageReference.state[enableFaxWorkflowName];
            }
            if(pageReference.state[eletterContextName] != 'NULL' && pageReference.state[eletterContextName] != 'undefined'){
                eletterContext = pageReference.state[eletterContextName];
            }
            if(pageReference.state[moreEmailRecipientsName] != 'NULL' && pageReference.state[moreEmailRecipientsName] != 'undefined'){
                moreEmailRecipients = pageReference.state[moreEmailRecipientsName];
            }
            if(pageReference.state[launchFromName] != 'NULL' && pageReference.state[launchFromName] != 'undefined'){
                launchFrom = pageReference.state[launchFromName];
            }
            if(pageReference.state[hideConsentName] != 'NULL' && pageReference.state[hideConsentName] != 'undefined'){
                hideConsent = pageReference.state[hideConsentName];
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
            showAttachments = ($A.util.isUndefinedOrNull(showAttachments))?result[showAttachmentsName]:showAttachments;
            showPreviewScreen = ($A.util.isUndefinedOrNull(showPreviewScreen))?result[showPreviewScreenName]:showPreviewScreen;
            showSendSecureOption = ($A.util.isUndefinedOrNull(showSendSecureOption))?result[showSendSecureOptionName]:showSendSecureOption;
            openInNewTab = ($A.util.isUndefinedOrNull(openInNewTab))?result[openInNewTabName]:openInNewTab;
            closeTabAfterSend = ($A.util.isUndefinedOrNull(closeTabAfterSend))?result[closeTabAfterSendName]:closeTabAfterSend;
            enableEmailWorkflow = ($A.util.isUndefinedOrNull(enableEmailWorkflow))?result[enableEmailWorkflowName]:enableEmailWorkflow;
            enableFaxWorkflow = ($A.util.isUndefinedOrNull(enableFaxWorkflow))?result[enableFaxWorkflowName]:enableFaxWorkflow;
            eletterContext = ($A.util.isUndefinedOrNull(eletterContext))?result[eletterContextName]:eletterContext;
            moreEmailRecipients = ($A.util.isUndefinedOrNull(moreEmailRecipients))?result[moreEmailRecipientsName]:moreEmailRecipients;
            hideConsent = ($A.util.isUndefinedOrNull(hideConsent))?result[hideConsentName]:hideConsent;
        }
        component.set("v.recordId", (recordId != undefined)? recordId :component.get("v.recordId"));
        component.set("v.showAttachments", (showAttachments != undefined)? this.getBooleanValue(showAttachments) : this.getBooleanValue(component.get("v.showAttachments")));
        component.set("v.showPreviewScreen", (showPreviewScreen != undefined)? this.getBooleanValue(showPreviewScreen) :this.getBooleanValue(component.get("v.showPreviewScreen")));
        component.set("v.showSendSecureOption", (showSendSecureOption != undefined)? this.getBooleanValue(showSendSecureOption) :this.getBooleanValue(component.get("v.showSendSecureOption")));
        component.set("v.openInNewTab", (openInNewTab != undefined)? this.getBooleanValue(openInNewTab) :this.getBooleanValue(component.get("v.openInNewTab")));
        component.set("v.closeTabAfterSend", (closeTabAfterSend != undefined)? this.getBooleanValue(closeTabAfterSend) :this.getBooleanValue(component.get("v.closeTabAfterSend")));
        component.set("v.emailWorkflow", (enableEmailWorkflow != undefined)? this.getBooleanValue(enableEmailWorkflow) :this.getBooleanValue(component.get("v.emailWorkflow")));
        component.set("v.faxWorkflow", (enableFaxWorkflow != undefined)? this.getBooleanValue(enableFaxWorkflow) :this.getBooleanValue(component.get("v.faxWorkflow")));
        component.set("v.eletterContext", (eletterContext != undefined && eletterContext.toUpperCase() == 'REPLY')? eletterContext.toUpperCase() : component.get("v.eletterContext"));
        component.set("v.moreEmailRecipients", (moreEmailRecipients != undefined)? this.getBooleanValue(moreEmailRecipients) :this.getBooleanValue(component.get("v.moreEmailRecipients")));
        component.set("v.launchFrom", (launchFrom != undefined && (launchFrom.toUpperCase()) == 'QUICK_ACTION')? launchFrom.toUpperCase() : component.get("v.launchFrom"));
        component.set("v.hideConsent", (hideConsent != undefined)? this.getBooleanValue(hideConsent) :this.getBooleanValue(component.get("v.hideConsent")));
    },

    /*
    * this method converts the given value to a boolean value (true or false)
    */
    getBooleanValue: function(value){
        value = (typeof value == 'string') ? value.toLowerCase() : value;
        switch(value){
            case true:
            case "true":
                return true;
            default:
                return false;
        }
    },

    /*
    * create a dummy document record and attach the generated pdf under it to render the preview
    */
    createPreviewOnlyDocument: function(component, event, helper){
        var action = component.get("c.createPreviewOnlyDocument");
        var selectedRecipients =  component.get("v.finalRecipientList");
        action.setParams({
            "recordId": component.get("v.recordId"),
            "eletterId" : (component.get('v.selectedELetterVal') == 'None')?null:component.get('v.selectedELetterVal'),
            "subject": component.get("v.eLetterTemplateSubject"),
            "comments": component.get("v.eLetterTemplateFaxComments"),
            "pagecount": component.get("v.eLetterPageCount"),
            "recipientsString": JSON.stringify(selectedRecipients)
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            console.log('State-->'+state);
            if (state === 'SUCCESS'){
                console.log('Preview ID -->'+res.getReturnValue().docJobRecordId);
                console.log('DOC ID -->'+res.getReturnValue().documentRecordId);
                if(res.getReturnValue().docJobRecordId == '' || res.getReturnValue().docJobRecordId === undefined || res.getReturnValue().documentRecordId == '' || res.getReturnValue().documentRecordId == undefined){
                    var error = $A.get("$Label.c.ACLS_Fax_PreviewError");
                    component.set("v.errors", [error]);
                    helper.disableNavigation(component,event,helper);
                }else{
                component.set("v.generatedDocumentJobId", res.getReturnValue().docJobRecordId);
                component.set("v.generatedPreviewDocument", res.getReturnValue().documentRecordId);
                }
		   }else if (state === "ERROR") {
                var error = component.get("v.lightingErrorMessage");
                var errors = res.getError();
                console.log('errors-->'+errors);
                  if (errors && errors[0] && errors[0].message) {
                      error = errors[0]['message'];
                      component.set("v.errors", [error]);
                  } else {
                      component.set("v.errors", [error]);
                  }
                  helper.disableNavigation(component,event,helper);
		   }
	    });
	    $A.enqueueAction(action);
    },

    /*
    * Remove the enegagement program lookup from the preview only document to revoke visibility to users.
    */
    updatePreviewDocument: function(component, event, helper){
        var docId = component.get("v.generatedPreviewDocument");
        var action = component.get("c.updateDocumentRecord");
        var mapToSend = {};
        mapToSend['PC_Engagement_Program__c'] = '';

        console.log('docId',docId);

        action.setParams({
            "docId": docId,
            "mapFieldValue" : mapToSend
        });
        action.setCallback(this, function(res) {
            //var state = res.getState();
           
        });
        $A.enqueueAction(action);
    },

    /*
    * set screen button values based on step name
    */
    setScreenButtonValues: function(component, event, helper, stepName) {
        component.set('v.currentStep', stepName);
        if(stepName == 'step1'){
            if(component.get('v.showPreviewScreen')){
                component.set('v.showPreviousBtn', false);
                component.set('v.showNextBtn', true);
                component.set('v.showSendBtn', false);
                component.set('v.showSecureBtn', false);
            }else{
                component.set('v.showPreviousBtn', false);
                component.set('v.showNextBtn', false);
                component.set('v.showSendBtn', true);
                component.set('v.showSecureBtn', true);
            }
        }
        else if(stepName == 'step2'){
            component.set('v.showPreviousBtn', true);
            component.set('v.showNextBtn', false);
            component.set('v.showSendBtn', true);
            component.set('v.showSecureBtn', true);
        }
    },

    /*
    * Calls server and retrives all eletter templates based on recordId
    */
    initELetter: function(component, event, helper) {
        var action = component.get("c.getEletterTemplates");
        helper.showSpinner(component, event, helper);
        if(component.get("v.recordId")!=null && component.get("v.recordId")!=undefined) {
            action.setParams({
                "recordId": component.get("v.recordId"),
                "emailCategoryList": component.get("v.emailCategoryList"),
                "faxCategoryList" : component.get("v.faxCategoryList")
            });
            action.setCallback(this, function(response) {
    			var state = response.getState();
    			if (state === 'SUCCESS'){
    			    var returnValue = response.getReturnValue();
    				var availableTemplateList = returnValue.eletterTemplateList;
    				var fromAddressList = returnValue.eletterFromAddressList;
                    console.log('fromAddressList'+fromAddressList);
                    helper.setFromOptions(component, (fromAddressList !== undefined)? fromAddressList:[]);
    				//Set Template Options
    				helper.setTemplateValues(component, event, helper, availableTemplateList);
                    if(availableTemplateList.length == 0){
                        component.set("v.message", component.get("v.msgNoEngagementProgram"));
                        helper.showInfoMessage(component, event, helper);
                    }
    			} else if (state === "ERROR") {
    			    var error = component.get("v.lightingErrorMessage");
    				var errors = response.getError();
                    if (errors && errors[0] && errors[0].message) {
                        error = errors[0]['message'];
                        component.set("v.errors", [error]);
                    } else {
                        component.set("v.errors", [error]);
                    }
    			}
                if ($A.util.isEmpty(component.get("v.message"))) {
                    helper.hideInfoMessage(component, event, helper);
                }
                helper.hideSpinner(component, event, helper);
    		});
            $A.enqueueAction(action);
        }
    },

    /*
    * Set Template Options
    */
    setTemplateValues : function(component, event, helper, availableTemplateList)
    {
        var templateOpts=[];
        for(var i=0;i< availableTemplateList.length;i++){
            var currentVal = availableTemplateList[i];
            templateOpts.push({
                "label": currentVal.name,
                "value": currentVal.value
                });
        }
        if(component.get("v.eletterContext").toUpperCase() == 'REPLY'){
            var templateNoneOption = {
                                      "label": component.get('v.picklistNone'),
                                      "value": 'None'
                                      };
            templateOpts.unshift(templateNoneOption);
        }
        component.set("v.templateOptions", templateOpts);

        var templateMap = availableTemplateList.map(function(template) {
                              var o = Object.assign({}, template);
                              o.categories = ((!$A.util.isEmpty(template.categories))? template.categories : '');
                              o.description = ((!$A.util.isEmpty(template.description))? template.description : '');
                              o.allowAdditionalRecipients = ((!$A.util.isEmpty(template.allowAdditionalRecipients))? template.allowAdditionalRecipients : false);
                              o.engProgEletterDescription = ((!$A.util.isEmpty(template.engProgEletterDescription))? template.engProgEletterDescription : '');
                              return o;
                          });
        var noneOption = {
                         "name": 'None',
                         "value": 'None',
                         "categories" : 'Email;Fax',
                         "description" : '',
                         "engProgEletterDescription" : '',
                         "allowAdditionalRecipients" : true
                         };
        templateMap.unshift(noneOption);
        component.set("v.eletterTemplateList", templateMap);

        if(component.get("v.eletterContext").toUpperCase() == 'REPLY'){
            component.set("v.selectedELetterVal", 'None');
            helper.setSelectedEletterTemplateObj(component, event, helper);
            helper.setTemplateDescription(component, event, helper);
            helper.checkEletterCategory(component, event, helper);
            helper.loadRecipients(component, event, helper);
        }
        else if(templateOpts.length == 1){
            component.set("v.selectedELetterVal", templateOpts[0].value);
            helper.setSelectedEletterTemplateObj(component, event, helper);
            helper.setTemplateDescription(component, event, helper);
            helper.checkEletterCategory(component, event, helper);
            helper.loadRecipients(component, event, helper);
        }
    },

    /*
    * Get and set the template description based on selected template.
    */
    setTemplateDescription : function(component, event, helper)
    {
        var selectedEletter = component.get('v.selectedELetterVal');
        var eletterTemplateList = component.get("v.eletterTemplateList");
        var eLetterTemplate = eletterTemplateList.find(template => template.value === selectedEletter);
        component.set("v.templateDescription", eLetterTemplate.description+' '+eLetterTemplate.engProgEletterDescription);
    },

    setSelectedEletterTemplateObj : function(component, event, helper)
    {
        var selectedEletter = component.get('v.selectedELetterVal');
        var eletterTemplateList = component.get("v.eletterTemplateList");
        var eLetterTemplate = eletterTemplateList.find(template => template.value === selectedEletter);
        component.set('v.selectedEletterTemplateObj', eLetterTemplate);
    },

    doCategorySplit : function(component, event, helper)
    {
        var emailCategoryListStr = component.get('v.emailCategoryListStr');
        var faxCategoryListStr = component.get('v.faxCategoryListStr');
        component.set("v.emailCategoryList", (component.get('v.emailWorkflow'))? (emailCategoryListStr.length ? emailCategoryListStr.split(',') : []) : []);
        component.set("v.faxCategoryList", (component.get('v.faxWorkflow'))? (faxCategoryListStr.length ? faxCategoryListStr.split(',') : []) : []);
    },

    checkEletterCategory : function(component, event, helper)
    {
        var selectedEletter = component.get('v.selectedELetterVal');
        var eletterTemplateList = component.get("v.eletterTemplateList");
        var eLetterTemplate = eletterTemplateList.find(template => template.value === selectedEletter);
        var emailCategoryList = component.get("v.emailCategoryList");
        var faxCategoryList = component.get("v.faxCategoryList");
        let isEmailSelected = ((eLetterTemplate.categories).split(";")).some(category=> emailCategoryList.includes(category));
        let isFaxSelected = ((eLetterTemplate.categories).split(";")).some(category=> faxCategoryList.includes(category));
        component.set("v.hasCategoryEmail", (isEmailSelected && component.get('v.emailWorkflow')));
        component.set("v.hasCategoryFax", (isFaxSelected && component.get('v.faxWorkflow')));
    },

    /*
    * Create from address options
    */
    setFromOptions: function(component, fromAddressList) {
        component.set("v.fromAddressList", fromAddressList);
        var fromOpts=[];
        for(var i=0;i< fromAddressList.length;i++){
                    var currentVal = fromAddressList[i];
                    fromOpts.push({
                        "label": currentVal.displayName+' <'+currentVal.emailAddress+'>',
                        "value": currentVal.fromId
                        });
                }
        component.set("v.fromOptions", fromOpts);
        if(fromOpts.length > 0){
            component.set('v.selectedFromAddressObj', fromAddressList[0]);
            component.set('v.selectedFromAddress', fromOpts[0].value);
        }
    },


    /*
    * Makes Server call and get all recipients based on recordId and Selected ELetter (letterId)
    */
    loadRecipients: function(component, event, helper) {
        component.set("v.isRecipientLoading", true);
        component.set("v.disablePickTemplate", true);
        helper.showSpinner(component, event, helper);
        helper.clearRecipientAttributes(component, event, helper);
        helper.clearAllErrors(component, event, helper);
        helper.disableNavigation(component,event,helper);
        var action = component.get("c.getEletterInfo");
        action.setParams({
            "recordId": component.get("v.recordId"),
            "letterId": (component.get('v.selectedELetterVal') != 'None')?component.get('v.selectedELetterVal'): null,
            "eletterContext": component.get("v.eletterContext").toUpperCase(),
            "hideConsent":component.get('v.hideConsent')
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === 'SUCCESS'){
                var eLetterInfoObj = a.getReturnValue();
                var recipientList = (eLetterInfoObj.eLetterRecipients !== undefined)? eLetterInfoObj.eLetterRecipients:[];
                var renderedMailTemplate = eLetterInfoObj.renderedMailTemplate;
                var eletter = eLetterInfoObj.eLetterRecord;
                if(renderedMailTemplate !== undefined){
                    component.set("v.eLetterTemplateSubject", renderedMailTemplate.subject);
                    component.set("v.eLetterTemplateType", renderedMailTemplate.templateType);
                    if(renderedMailTemplate.templateAttachments != undefined && renderedMailTemplate.templateAttachments.length > 0){
                        component.set('v.eLetterTemplateAttachments',renderedMailTemplate.templateAttachments);
                    }else{
                        component.set('v.eLetterTemplateAttachments',[]);
                    }
                    if(component.find('attachmentCmp') != undefined){
                        var attachmentCmp = component.find('attachmentCmp');
                        attachmentCmp = Array.isArray(attachmentCmp) ? attachmentCmp[0] : attachmentCmp;
                        attachmentCmp.addAdditionalAttachments(component.get('v.eLetterTemplateAttachments'));
                    }
                }
                else if(eletter !== undefined && eletter.PC_Category__c !== undefined){
                    var categories = eletter.PC_Category__c.split(";");
                    if(categories.includes("Fax")){
                        component.set("v.eLetterTemplateSubject", eletter.ACLS_Subject__c);
                        component.set("v.eLetterPageCount", eletter.ACLS_Number_of_Pages__c);
                    }
                }
                var noContactEmailList = [];
                var noContactFaxList = [];
                var emailMessage = '', faxMessage = '';
                component.set("v.recipients", recipientList);
                var recipientsObj = component.get("v.recipients");
                var targetRecipientsObj = recipientsObj.map(function(el) {
                    var o = Object.assign({}, el);
                    return o;
                });
                component.set("v.targetRecipientList", targetRecipientsObj);
                if(typeof recipientList !== 'undefined' && recipientList.length > 0){
                    component.set('v.isSendToMeEnabled',recipientList[0].sendToMe);
                }

                if($A.util.isEmpty(recipientList)) {
                    component.set("v.message", component.get("v.msgNoRecipient"));
                }else{
                    for(var i=0; i<recipientList.length; i++){
                        if(recipientList[i].hasContactEmail == false){
                            noContactEmailList.push(recipientList[i].recipient.name);
                        }
                        if(recipientList[i].hasContactFax == false){
                            noContactFaxList.push(recipientList[i].recipient.name);
                        }
                    }
                    if(noContactEmailList.length > 0 && component.get('v.hasCategoryEmail') === true){
                        emailMessage = component.get("v.msgNoEmailAddress")+noContactEmailList.join(" ; ");
                    }
                    if(noContactFaxList.length > 0 && component.get('v.hasCategoryFax') === true){
                        faxMessage = component.get("v.msgNoFaxNumber")+noContactFaxList.join(" ; ");
                    }
                    component.set("v.message", emailMessage.concat(((emailMessage != '' && faxMessage != '') ?' and ':''),faxMessage));
                }
            } else if (state === "ERROR") {
                var error = component.get("v.lightingErrorMessage");
                var errors = a.getError();
                  if (errors && errors[0] && errors[0].message) {
                      error = errors[0]['message'];
                      component.set("v.errors", [error]);
                  } else {
                      component.set("v.errors", [error]);
                  }
            }
            if($A.util.isEmpty(component.get("v.message"))){
                helper.hideInfoMessage(component, event, helper);
            } else {
                helper.showInfoMessage(component, event, helper);
            }
            component.set("v.isRecipientLoading", false);
            component.set("v.disablePickTemplate", false);
            helper.hideSpinner(component, event, helper);
            helper.enableNavigation(component,event,helper);
        });
        $A.enqueueAction(action);
    },

    /*
    * Make server call for sending E-letter to selected recipient with selected attachments
    */
    sendEletter: function(component, event, helper){
        helper.clearAllErrors(component, event, helper);
        helper.disableNavigation(component,event,helper);
        var attachmentsIds = (component.find('attachmentCmp') != undefined)? component.find('attachmentCmp').getSelectedRows() : [];
        var selectedRecipients =  component.get("v.finalRecipientList");
        var selectedFromAddressObj = component.get("v.selectedFromAddressObj");
        var action = component.get("c.sendOutboundDocuments");
        var actionParams = {
            "fromAddress": {
                "name" : selectedFromAddressObj.displayName,
                "address" : selectedFromAddressObj.emailAddress,
                "fromId" : selectedFromAddressObj.fromId
            },
            "eletterId" : (component.get('v.selectedELetterVal') == 'None')?null:component.get('v.selectedELetterVal'),
            "eletterContext": component.get("v.eletterContext").toUpperCase(),
            "recordId": component.get("v.recordId"),
            "isSecureEmail" : component.get("v.isEmailSecure"),
            "sendToCurrentUser" : component.get("v.isSendToMeEnabled"),
            "attachmentIds" : attachmentsIds,
            "subject": component.get("v.eLetterTemplateSubject"),
            "comments": component.get("v.eLetterTemplateFaxComments"),
            "pagecount": component.get("v.eLetterPageCount"),
            "textBody": component.get("v.eLetterTemplateTextBody"),
            "htmlBody": component.get("v.eLetterTemplateHTMLBody"),
            "communicationMethod": component.get('v.hasCategoryFax')? 'Fax' : 'Email',
            "generatedContentVersionJobId": component.get("v.generatedDocumentJobId")
        };
        action.setParams({
            "eLetterSenderJSON": JSON.stringify(actionParams),
            "recipientsString": JSON.stringify(selectedRecipients)
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === 'SUCCESS'){
                component.set("v.message", a.getReturnValue());
                helper.showInfoMessage2(component, event, helper);
                helper.showSuccessToast(component, event, helper);

                if(component.get('v.closeTabAfterSend')){
                    helper.closeTab(component, event, helper);
                }
                helper.refreshComponent(component, event, helper);
            } else if (state === "ERROR") {
                var error = component.get("v.lightingErrorMessage");
                var errors = a.getError();
                  if (errors && errors[0] && errors[0].message) {
                      error = errors[0]['message'];
                      component.set("v.errors", [error]);
                  } else {
                      component.set("v.errors", [error]);
                  }
            }
            if($A.util.isEmpty(component.get("v.message"))){
                helper.hideInfoMessage(component, event, helper);
            } else {
                helper.showInfoMessage(component, event, helper);
            }
            helper.enableNavigation(component,event,helper);
        });
        $A.enqueueAction(action);
    },

    /*
    * Methods helps to close the currently focused tab when in Lightning console apps.
    */
    closeTab : function(component, event, helper) {
        var workspaceAPI = component.find("eLetterWorkspace");
        workspaceAPI.isConsoleNavigation().then(function(isConsole) {
            if (isConsole) {
                workspaceAPI.getFocusedTabInfo().then(function(info) {
                    workspaceAPI.closeTab({tabId: info.tabId});
                });
            }
            else{
                window.close();
            }
        }).catch(function(error) {
            console.log(error);
        });
    },

    /*
    *  validate aura fields
    */
    checkFieldValidation : function(component, event, helper) {
        var recipientCmp = component.find('recipientCmp');
        var isRecipientsSelected = (recipientCmp != undefined)? recipientCmp.checkRecipientsValidity() : false;
        //Validating all input fields together by providing the same aura id 'eletterField'
        let isAllValid = component.find('eletterField').reduce(function(isValidSoFar, inputCmp){
            //display the error messages
            inputCmp.reportValidity();
            //check if the validity condition are met or not.
            return isValidSoFar && inputCmp.checkValidity();
        },true);

        //Validate Additional To field
        var isAdditionalToValid = false;
        var recipientError = false;
        if(component.find('additionalEmail') != undefined){
            var additionalEmailCmp = component.find("additionalEmail");
            var additionalEmailAddress = component.get('v.additionalEmailAddress');
            additionalEmailAddress = additionalEmailAddress.replace(/\s/g, '');
            if(!$A.util.isEmpty(additionalEmailAddress)) {
                isAdditionalToValid = helper.validateAdditionalEmails(component, event, helper);
                if(isAdditionalToValid){
                    additionalEmailCmp.setCustomValidity(""); // if there was a custom error before, reset it
                } else {
                    recipientError = true;
                    additionalEmailCmp.setCustomValidity(component.get('v.invalidAdditionalTo'));
                    component.find("additionalEmailField").getElement().scrollIntoView({behavior: "smooth", block: "center"});
                }
            } else {
                component.set('v.validAdditionalEmailAddresses', []);
                additionalEmailCmp.setCustomValidity("");
            }
            additionalEmailCmp.reportValidity();
        }

        var anyRecipientsSelectedOrEntered = true;
        if(!isRecipientsSelected && !isAdditionalToValid){
            anyRecipientsSelectedOrEntered = false;
        }

        if(anyRecipientsSelectedOrEntered){
            component.set('v.messageWhenRecipientNotSelected', '');
        }
        else {
            component.set('v.messageWhenRecipientNotSelected', component.get("v.noRecipientSelected"));
            // Scroll to the recipient list section when no recipient is selected
            if(component.find('recipientError') != undefined){
               component.find("recipientError").getElement().scrollIntoView({behavior: "smooth", block: "center"});
            }
        }

        return (isAllValid && anyRecipientsSelectedOrEntered && !recipientError);
    },

    addAdditionalEmailsToRecipientList: function(component, event, helper){
        var validEmailList = component.get('v.validAdditionalEmailAddresses');
        var additionalEmailRecipientList = [];
        for (let email of validEmailList) {
            var newRecipient = helper.newRecipientJson();
            newRecipient.recipientEmail = newRecipient.recipient.email = email;
            additionalEmailRecipientList.push(newRecipient);
        }
        component.set("v.additionalEmailRecipientList", additionalEmailRecipientList);
        var selectedRecipients = (component.find('recipientCmp') != undefined)? component.find('recipientCmp').getSelectedRecipients() : [];
        selectedRecipients = selectedRecipients.concat(additionalEmailRecipientList);
        component.set('v.finalRecipientList', selectedRecipients);
    },

    newRecipientJson: function(){
        var newRecipient = {
                               "bDisableEmail": false,
                               "bDisableFax": false,
                               "bDisableSendToMe": false,
                               "communicationLanguage": "",
                               "hasContactEmail": true,
                               "hasContactFax": false,
                               "isValidEmail": true,
                               "recipient": {
                                   "communicationLanguage": "",
                                   "email": "",
                                   "fax": "",
                                   "name": "",
                                   "type": "PRE_CONFIGURED_EMAIL"
                               },
                               "recipientEmail": "",
                               "recipientFax": "",
                               "recipientName": "",
                               "recipientRole": "",
                               "recipientRoleLabel": "",
                               "recipientTypeLabel": "",
                               "sendEmail": true,
                               "sendFax": false,
                               "sendToMe": false
                           };
        return newRecipient;
    },

    validateAdditionalEmails: function(component, event, helper){
        var additionalEmailAddress = component.get('v.additionalEmailAddress');
        // Trim the white spaces
        additionalEmailAddress = additionalEmailAddress.replace(/\s/g, '');
        var isValid = true;
        var validAdditionalEmailAddresses = [];
        // Convert this semi-colon separated string value to array
        var inputsArr = additionalEmailAddress.split(';').filter(Boolean);
        for (let email of inputsArr) {
            email = email.replace(/\s/g, '');
            if (! (helper.isValidEmail(email))) {
                isValid = false;
                break;
            }
            validAdditionalEmailAddresses.push(email);
        }
        component.set('v.validAdditionalEmailAddresses', validAdditionalEmailAddresses);
        return isValid;
    },

    isValidEmail: function(emailString){
    	//Regex value to validate email
       	//var emailPattern = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;
       	var emailPattern = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
      	return emailPattern.test(emailString); // Return true if the value is valid and false if not valid
    },

    clearRecipientAttributes: function(component, event, helper){
        component.set("v.recipients", []);
        component.set("v.targetRecipientList", []);
        component.set("v.finalRecipientList", []);
    },

    clearAllErrors : function(component, event, helper){
        component.set("v.errors", []);
        helper.hideInfoMessage(component, event, helper);
    },

    /*
    * Method for show error info message
    */
    showInfoMessage: function(component, event, helper){
        var toggleText = component.find("msgResult");
        $A.util.removeClass(toggleText, 'slds-hide');
        $A.util.addClass(toggleText, 'slds-show');
    },

    /*
    * Method for show error info message
    */
    showInfoMessage2: function(component, event, helper){
        var toggleText = component.find("msgResult2");
        $A.util.removeClass(toggleText, 'slds-hide');
        $A.util.addClass(toggleText, 'slds-show');
    },

    /*
    * Method for hide error info message
    */
    hideInfoMessage: function(component, event, helper){
        var toggleText = component.find("msgResult");
        $A.util.removeClass(toggleText, 'slds-show');
        $A.util.addClass(toggleText, 'slds-hide');
    },

    // function for disable navigation buttons
    disableNavigation: function(component, event, helper) {
        component.set('v.disableNavigationBtns', true);
    },

    // function for enable navigation buttons
    enableNavigation : function(component,event,helper){
        component.set('v.disableNavigationBtns', false);
    },

    // function for email send success toast message
    showSuccessToast : function(component, event, helper){
        component.find('eletterNotifLib').showToast({
            "variant": "success",
            "message": component.get("v.toastSendSuccessMessage"),
            "mode" : "dismissable"
        });
    },

    setRecordId : function(component, event, helper) {
        if(!$A.util.isEmpty(component.get("v.relatedToId")) && !$A.util.isEmpty("v.relatedToObject") && component.get("v.relatedToObject").toLowerCase() == 'case') {
            component.set("v.openInNewTab", false); //  if (relatedTo*) attributes have any value, then set openInNewTab to false
            if(!$A.util.isEmpty(component.get("v.taskDocumentId"))){
                component.set("v.recordId", component.get("v.taskDocumentId"));
                component.set("v.eletterContext", "REPLY");
            }
            else{
                component.set("v.recordId", component.get("v.relatedToId"));
            }
        }
    },

    /*
    *  Show the Spinner
    */
    showSpinner: function(component, event, helper) {
        // remove slds-hide class from eletterSpinner
        var spinner = component.find("eletterSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    /*
    *  Hides the spinner
    */
    hideSpinner : function(component,event,helper){
        // add slds-hide class to eletterSpinner
        var spinner = component.find("eletterSpinner");
        $A.util.addClass(spinner, "slds-hide");
    }

})