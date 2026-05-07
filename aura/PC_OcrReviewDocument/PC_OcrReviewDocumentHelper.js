/**
 * Created by sathekumar on 10/8/2021.
 */
({
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
        var templateCategoriesName = CH_PC_Util.getQualifiedQueryParam(component,'templateCategories',namespace);
        var createDocumentLinkLogName = CH_PC_Util.getQualifiedQueryParam(component,'createDocumentLinkLog',namespace);
        var hideDocTypeSelectionWhenAutoSelectedName = CH_PC_Util.getQualifiedQueryParam(component,'hideDocTypeSelectionWhenAutoSelected',namespace);
        var launchFromName = CH_PC_Util.getQualifiedQueryParam(component,'launchFrom',namespace);

        var recordId, templateCategories, createDocumentLinkLog, hideDocTypeSelectionWhenAutoSelected, launchFrom;
        if(pageReference && pageReference.state){
            if(pageReference.state[recordIdName] != 'NULL' && pageReference.state[recordIdName] != 'undefined'){
                recordId = pageReference.state[recordIdName];
            }
            if(pageReference.state[templateCategoriesName] != 'NULL' && pageReference.state[templateCategoriesName] != 'undefined'){
                templateCategories = (typeof pageReference.state[templateCategoriesName] == 'string') ? ((pageReference.state[templateCategoriesName] == '') ? [] : (pageReference.state[templateCategoriesName]).split(',')): Object.values(pageReference.state[templateCategoriesName]);
            }
            if(pageReference.state[createDocumentLinkLogName] != 'NULL' && pageReference.state[createDocumentLinkLogName] != 'undefined'){
                createDocumentLinkLog = pageReference.state[createDocumentLinkLogName];
            }
            if(pageReference.state[hideDocTypeSelectionWhenAutoSelectedName] != 'NULL' && pageReference.state[hideDocTypeSelectionWhenAutoSelectedName] != 'undefined'){
                hideDocTypeSelectionWhenAutoSelected = pageReference.state[hideDocTypeSelectionWhenAutoSelectedName];
            }
            if(pageReference.state[launchFromName] != 'NULL' && pageReference.state[launchFromName] != 'undefined'){
                launchFrom = pageReference.state[launchFromName];
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
            templateCategories = ($A.util.isUndefinedOrNull(templateCategories))?result[templateCategoriesName]:templateCategories;
            createDocumentLinkLog = ($A.util.isUndefinedOrNull(createDocumentLinkLog))?result[createDocumentLinkLogName]:createDocumentLinkLog;
            hideDocTypeSelectionWhenAutoSelected = ($A.util.isUndefinedOrNull(hideDocTypeSelectionWhenAutoSelected))?result[hideDocTypeSelectionWhenAutoSelectedName]:hideDocTypeSelectionWhenAutoSelected;
        }
        component.set("v.recordId", (recordId != undefined)? recordId :component.get("v.recordId"));
        component.set("v.templateCategories", (templateCategories != undefined)? templateCategories : component.get("v.templateCategories"));
        component.set("v.createDocumentLinkLog", (createDocumentLinkLog != undefined)? this.getBooleanValue(createDocumentLinkLog) : this.getBooleanValue(component.get("v.createDocumentLinkLog")));
        component.set("v.hideDocTypeSelectionWhenAutoSelected", (hideDocTypeSelectionWhenAutoSelected != undefined)? this.getBooleanValue(hideDocTypeSelectionWhenAutoSelected) : this.getBooleanValue(component.get("v.hideDocTypeSelectionWhenAutoSelected")));
        component.set("v.launchFrom", (launchFrom != undefined && (launchFrom.toUpperCase()) == 'TRIGGER')? launchFrom.toUpperCase() : component.get("v.launchFrom"));
    },

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

    doInit: function(component, event, helper){
        this.setPageReferenceValues(component, event, helper);
        if(component.get('v.launchFrom') != 'ACTION_RIBBON') {
            helper.setComponentTabIconAndLabel(component, event, helper);
        }
        this.validateDocument(component, event, helper);
    },

     setComponentTabIconAndLabel : function(component, event, helper) {
        var workspaceAPI = component.find("reviewOcrWorkspace");
        workspaceAPI.getEnclosingTabId().then(function(tabId) {
            workspaceAPI.setTabIcon({
                tabId: tabId,
                icon: component.get('v.ocrTabIcon'),
                iconAlt: component.get('v.ocrTabLabel')
            });
            workspaceAPI.setTabLabel({
                tabId: tabId,
                label: component.get('v.ocrTabLabel')
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    },

    validateDocument: function(component, event, helper) {
        helper.showSpinner(component, event, helper);
        var action = component.get('c.validateDocument');
        action.setParams({
            documentId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                console.log(response.getReturnValue());
                //component.set('v.isValidDocumentForOCR', true);
                this.getDocumentInfo(component, event, helper);
            } else {
                var error = component.get("v.lightingErrorMessage");
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    error = errors[0]['message'];
                    component.set("v.errors", [error]);
                } else {
                    component.set("v.errors", [error]);
                }
                helper.disableActions(component, event, helper);
            }
            helper.hideSpinner(component, event, helper);
        });
        $A.enqueueAction(action);
    },

    getDocumentInfo: function(component, event, helper){
        var namespacePrefix = component.get('v.namespacePrefix');
        this.showSpinner(component, event, helper);
        var action = component.get('c.getDocumentInfo');
        action.setParams({
            documentId : component.get("v.recordId"),
            templateCategoriesString : JSON.stringify(component.get("v.templateCategories"))
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                console.log(JSON.stringify(response.getReturnValue()));
                var documentInfo = response.getReturnValue();
                component.set('v.documentInfoObj', documentInfo);
                var templateTypeId = documentInfo.templateTypeId;

                // Document
                if(!$A.util.isEmpty(documentInfo.documentObj)) {
                    component.set('v.documentName', documentInfo.documentObj[namespacePrefix+'PC_Document_Name__c']);
                    component.set('v.engagementProgram', documentInfo.documentObj[namespacePrefix+'PC_Engagement_Program__c']);
                    ($A.util.isEmpty(component.get('v.engagementProgram'))) ? component.set('v.isDocumentEngagementProgram', false) : component.set('v.isDocumentEngagementProgram', true);
                }

                // OCR Queue Check
                if(!$A.util.isEmpty(documentInfo.ocrQueue)) {
                    component.set('v.ocrQueueId', documentInfo.ocrQueue.Id);
                    component.set('v.isTemplateTypeIdPreConfigured', true);
                } else {
                    component.set('v.templateTypeId', '');
                    component.set('v.isTemplateTypeIdPreConfigured', false);
                }

                // OCR Template Type Check
                if(!$A.util.isEmpty(documentInfo.templateTypeId)) {
                    component.set('v.templateTypeId', documentInfo.templateTypeId);
                    component.set('v.templateTypeName', documentInfo.templateTypeName);
                    component.set('v.templateTypeNameCopy', documentInfo.templateTypeName);
                    component.set('v.isTemplateTypeIdPreConfigured', true);
                } else {
                    component.set('v.templateTypeId', '');
                    component.set('v.isTemplateTypeIdPreConfigured', false);
                }

                // OCR Template Mapping Check
                if(!$A.util.isEmpty(documentInfo.ocrTemplateMappings)){
                    component.set('v.ocrTemplateMappings', documentInfo.ocrTemplateMappings);
                    if(documentInfo.ocrTemplateMappings.length >= 1){
                        component.set('v.targetObjectApiName', documentInfo.ocrTemplateMappings[0][namespacePrefix+'PC_TargetObject__c']);
                        component.set('v.targetRecordTypeName', documentInfo.ocrTemplateMappings[0][namespacePrefix+'PC_TargetObjectRecordType__c']);
                        component.set('v.targetRecordTypeId', $A.util.isEmpty(documentInfo.targetObjectRecordTypeId) ? '' : documentInfo.targetObjectRecordTypeId);
                        component.set('v.targetObjectLabel', documentInfo.targetObjectLabel);
                    }
                } else {
                    component.set('v.ocrTemplateMappings', []);
                }

                // OCR Response Check
                if(!$A.util.isEmpty(documentInfo.ocrResponse) && documentInfo.ocrResponse[namespacePrefix+'PC_OcrStatus__c'] == 'Success'){
                    component.set('v.ocrResponseId', documentInfo.ocrResponse.Id);
                } else {
                    component.set('v.ocrResponseId', '');
                }

                // OCR Result Check
                if(!$A.util.isEmpty(documentInfo.ocrResults)){
                    component.set('v.ocrResultList', documentInfo.ocrResults);
                    if(documentInfo.ocrResults.length >= 1 && documentInfo.ocrResults[0][namespacePrefix+'PC_ResultStatus__c'] == 'Success'){
                        component.set('v.targetRecordId', documentInfo.ocrResults[0][namespacePrefix+'PC_ResultingRecordId__c']);
                        component.set('v.saveBtnLabel', component.get('v.updateLabel'));
                    }
                } else {
                    component.set('v.ocrResultList', []);
                }

                if(!$A.util.isEmpty(component.get('v.templateTypeId'))){
                    helper.getOcrDocumentFieldsMap(component, event, helper);
                } else {
                    helper.setupSection(component, event, helper);
                }
            } else {
                console.log('Error');
                var error = component.get("v.lightingErrorMessage");
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    error = errors[0]['message'];
                    component.set("v.errors", [error]);
                } else {
                    component.set("v.errors", [error]);
                }
                helper.disableActions(component, event, helper);
            }
            helper.hideSpinner(component, event, helper);
        });
        $A.enqueueAction(action);
    },

    getOcrDocumentFieldsMap: function(component, event, helper){
        this.showSpinner(component, event, helper);
        var namespacePrefix = component.get('v.namespacePrefix');
        var action = component.get('c.getOcrDocumentFieldsMap');
        action.setParams({
            templateTypeId : component.get('v.templateTypeId'),
            ocrResponseId : component.get('v.ocrResponseId')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                var data = response.getReturnValue();
                if($A.util.isUndefinedOrNull(data)){
                    component.set("v.defaultFieldValues", null);
                } else {
                    component.set("v.defaultFieldValues", data.fieldValueMap);
                    if(!$A.util.isEmpty(data.ocrTemplateMappings)){
                        component.set("v.ocrTemplateMappings", data.ocrTemplateMappings);
                        if(data.ocrTemplateMappings.length >= 1){
                            component.set('v.targetObjectApiName', data.ocrTemplateMappings[0][namespacePrefix+'PC_TargetObject__c']);
                            component.set('v.targetRecordTypeName',data.ocrTemplateMappings[0][namespacePrefix+'PC_TargetObjectRecordType__c']);
                            component.set('v.targetRecordTypeId', data.recordTypeId);
                            component.set('v.targetObjectLabel', data.objectLabel);
                        }
                    } else {
                        component.set('v.ocrTemplateMappings', []);
                    }
                }
                helper.setupSection(component, event, helper);
                console.log(JSON.stringify(data.fieldValueMap));
            } else {
                component.set('v.targetObjectApiName', '');
                component.set('v.targetRecordTypeName', '');
                component.set('v.targetRecordTypeId', '');
                component.set('v.targetObjectLabel', '');
                console.log('Error');
                var error = component.get("v.lightingErrorMessage");
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    error = errors[0]['message'];
                    component.set("v.errors", [error]);
                } else {
                    component.set("v.errors", [error]);
                }
                //helper.disableActions(component, event, helper);
            }
            //helper.disableActions(component, event, helper);
            helper.hideSpinner(component, event, helper);
        });
        $A.enqueueAction(action);
    },

    disableActions: function(component, event, helper) {
        let saveButton = component.find('saveBtn');
        (saveButton != undefined) ? saveButton.set('v.disabled',true) : '';
        let previousButton = component.find('previousBtn');
        (previousButton != undefined) ? previousButton.set('v.disabled',true) : '';
        let nextButton = component.find('nextBtn');
        (nextButton != undefined) ? nextButton.set('v.disabled',true) : '';
    },

    enableActions: function(component, event, helper) {
        let saveButton = component.find('saveBtn');
        (saveButton != undefined) ? saveButton.set('v.disabled',false) : '';
        let previousButton = component.find('previousBtn');
        (previousButton != undefined) ? previousButton.set('v.disabled',false) : '';
        let nextButton = component.find('nextBtn');
        (nextButton != undefined) ? nextButton.set('v.disabled',false) : '';
    },

    showSpinner: function(component, event, helper) {
        component.set('v.showSpinner', true);
    },

    hideSpinner : function(component,event,helper){
        component.set('v.showSpinner', false);
    },

    setupSection: function(component, event, helper) {
        var objectRecordType = component.get('v.targetObjectLabel');
        if(!$A.util.isEmpty(objectRecordType)){
            if(!$A.util.isEmpty(component.get('v.targetRecordId'))) {
                component.set('v.recordFormSectionHeader', component.get('v.ocrReviewPageFormHeaderUpdateLabel').replace("{0}", objectRecordType));
            } else {
                component.set('v.recordFormSectionHeader', component.get('v.ocrReviewPageFormHeaderCreateLabel').replace("{0}", objectRecordType));
            }
        }

        if($A.util.isEmpty(component.get('v.templateTypeId'))){
            component.set('v.currentSection', 1);
        }
        else if(!$A.util.isEmpty(component.get('v.targetObjectApiName'))){
            component.set('v.currentSection', 2);
        }
        helper.openCurrentSection(component, event, helper);
    },

    openCurrentSection: function(component, event, helper) {
        var currentSection = component.get('v.currentSection');
        if(currentSection === 1){
            component.set('v.showTemplateSelectionSection', true);
            component.set('v.showRecordFormSection', false);
            component.set('v.hasPrevious', false);
            component.set('v.hasNext', true);
            component.set('v.hasSave', false);
        } else if(currentSection === 2){
            component.set('v.showTemplateSelectionSection', false);
            component.set('v.showRecordFormSection', true);
            if (component.get('v.documentInfoObj.isTemplateTypeIdPreConfigured') || (component.get('v.documentInfoObj.isTemplateTypeAutoSelected') && component.get('v.hideDocTypeSelectionWhenAutoSelected'))) {
                component.set('v.hasPrevious', false) ;
            } else {
                component.set('v.hasPrevious', true);
            }
            //(component.get('v.documentInfoObj.isTemplateTypeAutoSelected') == true) ? component.set('v.hasPrevious', true) : component.set('v.hasPrevious', false);
            component.set('v.hasNext', false);
            component.set('v.hasSave', true);
        }
    },

    handlePrevious: function(component, event, helper) {
        component.set('v.errors', []);
        var currentSection = component.get('v.currentSection');
        component.set('v.currentSection', currentSection-1);
        helper.openCurrentSection(component, event, helper);
    },

    handleNext: function(component, event, helper) {
        component.set('v.errors', []);
        var currentSection = component.get('v.currentSection');
        if(currentSection === 1) {
            if(!$A.util.isEmpty(component.get('v.templateTypeId'))){
                helper.getOcrDocumentFieldsMap(component, event, helper);
            } else {
                if(component.find('templateSelectCmp') != undefined){
                    var templateSelectCmp = component.find("templateSelectCmp");
                    return templateSelectCmp.validate();
                }
            }
        } else {
            component.set('v.currentSection', currentSection+1);
            helper.openCurrentSection(component, event, helper);
        }
        //component.set('v.currentSection', currentSection+1);
        //helper.openCurrentSection(component, event, helper);
    },

    handleSubmit: function(component, event, helper) {
        var pcRecordFormCmp = component.find('pcRecordForm');
        var fieldsValues = pcRecordFormCmp.submit();
    },

    handleSuccess: function(component, event, helper) {
        var record = event.getParams();
        var successMessage = 'Record Created Successfully';
        if(!$A.util.isEmpty(component.get('v.targetRecordId'))) {
            successMessage = component.get('v.ocrReviewUpdateSuccessMessage').replace("{0}", component.get('v.targetObjectLabel'));
        } else {
            successMessage = component.get('v.ocrReviewCreateSuccessMessage').replace("{0}", component.get('v.targetObjectLabel'));
        }
        component.set('v.targetRecordId', record.id);
        if(!$A.util.isEmpty(component.get("v.ocrQueueId"))){
            helper.completeOcrQueueAndCreateResults(component, event, helper);
        }
        if(component.get("v.createDocumentLinkLog")){
            helper.createLinkLog(component, event, helper);
        }
        this.navigateToRecordPage(component, event, helper);
        this.showToast(component, successMessage, 'success');
        helper.closeTab(component, event, helper);
    },

    completeOcrQueueAndCreateResults: function(component, event, helper) {
        var action = component.get('c.completeOcrQueueAndCreateOcrResults');
        action.setParams({
            ocrQueueId : component.get("v.ocrQueueId"),
            targetRecordId : component.get('v.targetRecordId'),
            templateTypeId : component.get("v.templateTypeId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                console.log(JSON.stringify(response.getReturnValue()));
            } else {
                console.log('Error');
                var error = component.get("v.lightingErrorMessage");
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    error = errors[0]['message'];
                    component.set("v.errors", [error]);
                } else {
                    component.set("v.errors", [error]);
                }
            }
        });
        $A.enqueueAction(action);
    },

    createLinkLog: function(component, event, helper) {
        var action = component.get('c.createLinkLog');
        action.setParams({
            documentId : component.get("v.recordId"),
            targetRecordId :  component.get('v.targetRecordId')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS'){
                console.log(response.getReturnValue());
            } else {
                var error = component.get("v.lightingErrorMessage");
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    error = errors[0]['message'];
                    component.set("v.errors", [error]);
                } else {
                    component.set("v.errors", [error]);
                }
            }
        });
        $A.enqueueAction(action);
    },

    navigateToRecordPage: function(component, event, helper) {
        var navService = component.find("documentReviewNavService");
        // Uses the pageReference definition in the init handler
        var pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: component.get("v.targetRecordId"),
                actionName: "view"
            }
        };
        event.preventDefault();
        event.stopPropagation();
        navService.navigate(pageReference);
    },

    handleLoad: function(component, event, helper) {
        this.enableActions(component, event, helper);
    },

    handleError: function(component, event, helper) {
        //this.showToast(component, component.get('v.standardClientSideErrorMessage'), 'error');
    },

    showToast: function(component, message, type){
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'dismissable',
            message: message,
            type: $A.util.isEmpty(type) ? "info" : type,
        });
        toastEvent.fire();
    },

    closeTab: function(component, event, helper) {
        var workspaceAPI = component.find("reviewOcrWorkspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log(error);
        });
    }
})