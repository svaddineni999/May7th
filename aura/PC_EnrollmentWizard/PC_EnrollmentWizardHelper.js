({
    setNamespace : function(component, event, helper) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    setupEnrollmentWizard : function(component, event) {
        var enrollmentCaseId = component.get("v.enrollmentCaseId");
        if(enrollmentCaseId != null && enrollmentCaseId !='' && enrollmentCaseId !=' '&& enrollmentCaseId !='undefined'){
            var action = component.get("c.setupEnrollmentWizard");
            action.setParams({
                "enrollmentCaseId": enrollmentCaseId
            });

            action.setCallback(this, function(response) {
                var state = response.getState();

                if (component.isValid() && state === "SUCCESS") {
                    var returnValue = response.getReturnValue();
                    var enrollmentCase = returnValue.enrollmentCase;
                    component.set("v.pageAttributeMap", JSON.parse(enrollmentCase.wizardState));
                    component.set("v.enrollmentCase", returnValue.enrollmentCase);
                    component.set("v.pageMetadata", returnValue.lstPageMetadata);
                    // Process Dynamic Custom Labels in Enrollment Wizard Page
                    var pageMetadata = component.get('v.pageMetadata');

                    //var pageLabels = component.get("v.pageLabels");
                    var dynamicTitle;
                    for(var i=0; i<pageMetadata.length; i++){
                        debugger;
                        if($A.util.isEmpty(pageMetadata[i].label)) {
                            dynamicTitle = pageMetadata[i].masterLabel;
                        }
                        else {
                            dynamicTitle = pageMetadata[i].label;
                        }
                        var pageLabel = CH_PC_Util.getCustomLabelValue(dynamicTitle);

                        component.set("v.pageLabels." + i + '.masterLabel', pageLabel);
                    }
                    if(component.get("v.pageMetadata").length == 0){
                        component.set("v.genericErrors", component.get("v.enrollmentWizardSetupError"));
                    }
                } else {
                    console.log("setupEnrollmentWizard: Failed with state: " + state);
                    var errors = response.getError();
                    if(!$A.util.isEmpty(errors) && errors.length > 0) {
                        var message = errors[0].message;
                        component.set("v.genericErrors", message);
                    }
                }
            });

            $A.enqueueAction(action);
        }

    },
    /*
     * Saves the current state of the wizard and sets Wizard page component for display.
     */
    setWizardPage : function(component, newPageIndex, prevPageIndex, helper) {
        helper.hideFooter(component);
        var pageMetadata = component.get("v.pageMetadata");
        var pageAttributeMap = component.get("v.pageAttributeMap");
        var currentPage = component.get("v.currentPage");
        var currentPageIndex = component.get("v.currentPageIndex");

        if (!$A.util.isUndefinedOrNull(currentPage)) {
        	this.saveWizardState(component, pageMetadata, pageAttributeMap, currentPage, currentPageIndex, false);
        }

        if (newPageIndex < pageMetadata.length) {
            var page = pageMetadata[newPageIndex]
            //var namespace = $A.util.isUndefinedOrNull(page.namespacePrefix) ? 'c:' : page.namespacePrefix + ':';
            var componentName = page.componentName;
            var componentAttributes = {};
            var pageAttributes = pageAttributeMap[page.developerName];

            if (!$A.util.isUndefinedOrNull(pageAttributes)) {
                for (var attributeName in pageAttributes) {
                    componentAttributes[attributeName] = pageAttributes[attributeName];
                }
            }

            componentAttributes["enrollmentCase"] = component.get("v.enrollmentCase");
            componentAttributes["config"] = page.config;
            componentAttributes["transientWizardState"] = component.get("v.transientWizardState");

            var enrollmentProcessingResult = component.get("v.enrollmentProcessingResult");
            if (!$A.util.isUndefinedOrNull(enrollmentProcessingResult)) {
                if (!enrollmentProcessingResult.success
                        && (enrollmentProcessingResult.errorPageDeveloperName == page.developerName)) {
                    component.set("v.isErrorComponentVisited", true);
                    componentAttributes["pageErrorHeader"] = 'Enrollment Processing Error Details';
                    componentAttributes["pageErrors"] = [enrollmentProcessingResult.errorMessage];
                }
            }

            $A.createComponent(
                componentName,
                componentAttributes,
                function(newComponent, status) {
                    if (status === "SUCCESS") {
                        component.set("v.currentPage", newComponent);
                        var content = component.find("body");
                        content.set("v.body", newComponent);
                    }
                    else {
                        console.error('Unable to create lightning component');
                    }
                    helper.showFooter(component);
                }
            );
        } else {
            component.find("body").set("v.body", "");
            component.set("v.currentPage", null);
            helper.showFooter(component);
        }

        component.set("v.prevPageIndex", prevPageIndex);
        component.set("v.currentPageIndex", newPageIndex);

        this.setWizardProgressBar(component);
    },
    /*
     * Retrieves persistent attributes from current page and updates the page attribute map and
     * then saves the wizard state to the server.
     */
    saveWizardState : function(component, pageMetadata, pageAttributeMap, currentPage, currentPageIndex, showToast) {

        var persistentAttributes = currentPage.get("v.persistentAttributes");
        var pageState = {};

        for (var i = 0; i < persistentAttributes.length; i++) {
            pageState[persistentAttributes[i]] = currentPage.get("v." + persistentAttributes[i]);
        }

        pageAttributeMap[pageMetadata[currentPageIndex].developerName] = pageState;
        this.setTransientWizardState(component, JSON.parse(JSON.stringify(pageAttributeMap)));
        this.saveWizardStateToServer(component, pageAttributeMap, showToast);
    },
    /*
     * Saves the current wizard state - persisitent attributes of each page - to the server
     * to support pause and resume functionality.
     */
    saveWizardStateToServer : function(component, pageAttributeMap, showToast) {

        var wizardState = JSON.stringify(pageAttributeMap);

    	var enrollmentCaseId = component.get("v.enrollmentCaseId");

    	// Setting below attribute to true when saveWizardState server call is started
        component.set("v.isSaveWizardStateCallInProgress", true);
        var action = component.get("c.saveWizardState");
        action.setParams({
            "enrollmentCaseId": enrollmentCaseId,
            "wizardState": wizardState
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                if (showToast) {
                	this.showToast(component, component.get("v.toastMessage"));
                }
            } else {
                console.log("Failed with state: " + state);
            }
            // Setting below attribute to false when saveWizardState call has been completed
            component.set("v.isSaveWizardStateCallInProgress", false);
        });

        $A.enqueueAction(action);
    },
    setTransientWizardState : function(component, wizardState) {
        var copyOfPageMetadata = wizardState;
        if(!$A.util.isUndefinedOrNull(copyOfPageMetadata)) {
            component.set("v.transientWizardState", copyOfPageMetadata);
        }
    },
    processEnrollment : function(component, event, helper) {
        this.hideFooter(component);
        component.set("v.showSpinner",true);

        var enrollmentCaseId = component.get("v.enrollmentCaseId");

        var action = component.get("c.processEnrollment");
        action.setParams({
            "enrollmentCaseId" : enrollmentCaseId,
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.enrollmentProcessingResult", result);
                if (result.success) {
                    component.set("v.enrollmentErrorHeader", "");
                    component.set("v.enrollmentErrors", "");
					component.set("v.enrollmentSuccessful", true);
					component.set("v.programCase",result.programCase);
					component.set("v.userMessages", result.userMessages);
					helper.setEnrollConfirmComponent(component, result);
                    this.showModelEnrollmentComplete(component);
                } else if ($A.util.isUndefinedOrNull(result.errorPageDeveloperName)) {
                    component.set("v.enrollmentErrorHeader", "System Error occured during enrollment");
                    component.set("v.enrollmentErrors", [result.errorMessage]);
                } else {
                    var pageMetadata = component.get("v.pageMetadata");
                    for (var i = 0; i < pageMetadata.length; i++) {
                        if (pageMetadata[i].developerName == result.errorPageDeveloperName) {
                            component.set("v.isErrorComponentVisited", false);
                            component.set("v.errorComponentName", pageMetadata[i].developerName);
                            var pageLabel = helper.getPageLabel(component, i);
                            component.set("v.errorComponentLabel", pageLabel);
                            //PC-1923 - made the error message dynamic
                            //PC-6789 - fix for dynamic custom label translation issue
                            component.set("v.enrollmentErrorHeader", pageLabel + ' ' + component.get("v.enrollPageErrorEnrollButton"));
                            component.set("v.enrollmentErrors", [result.errorMessage]);
                            break;
                        }
                    }
                }
				this.showFooter(component);
            } else {
                var errors = JSON.stringify(response.getError());
                console.log("processEnrollment failure: " + errors);
                //component.set("v.enrollmentErrorHeader", "System Error occured during enrollment");
                component.set("v.enrollmentErrorHeader", component.get("v.genericErrorHeader"));
                component.set("v.enrollmentErrors", [errors]);
				this.showFooter(component);
            }
            component.set("v.showSpinner",false);
        });

        $A.enqueueAction(action);
    },
    getPageLabel : function(component, pageLabelIndex) {
        return component.get("v.pageLabels." + pageLabelIndex + ".masterLabel");
    },
    setEnrollConfirmComponent : function(component, result) {
        debugger;
        var defaultCmp = result.enrollConfirmDefaultComponent;
        var customCmp = result.enrollConfirmCustomComponent;
        var resultCmp = $A.util.isEmpty(customCmp) ? defaultCmp : customCmp;
        try {
            $A.createComponent(
                resultCmp,
                {
                    enrollmentCaseId : component.get("v.enrollmentCaseId"),
                    programCaseId : component.get("v.programCase")
                },
                function(newCmp, status, errorMessage){
                    if (status === "SUCCESS") {
                        var body = component.get("v.body");
                        body.push(newCmp);
                        component.set("v.body", body);
                    }
                    else {
                        var unableToCreateCmpMessage = component.get("v.unableToCreateCmpMessage");
                        unableToCreateCmpMessage = unableToCreateCmpMessage.replace("{0}", resultCmp);
                        unableToCreateCmpMessage = unableToCreateCmpMessage.replace("{1}", status);
                        unableToCreateCmpMessage = unableToCreateCmpMessage.replace("{2}", errorMessage);
                        var enrollConfirmCmpErrors = [unableToCreateCmpMessage, component.get("v.genericClientErrorMessage")];
                        console.log("Unable to create the component")
                        console.log("Status: " + status);
                        console.log("Error: " + errorMessage);
                        component.set("v.enrollConfirmCmpErrors", enrollConfirmCmpErrors);
                        console.log("_____");
                    }
                }
            );
        }
        catch(e) {
            var unableToCreateCmpMessage = component.get("v.unableToCreateCmpMessage");
            unableToCreateCmpMessage = unableToCreateCmpMessage.replace("{0}", resultCmp);
            unableToCreateCmpMessage = unableToCreateCmpMessage.replace("{1}", 'Error');
            unableToCreateCmpMessage = unableToCreateCmpMessage.replace("{2}", 'No component found');
            var enrollConfirmCmpErrors = [unableToCreateCmpMessage, component.get("v.genericClientErrorMessage")];
            component.set("v.enrollConfirmCmpErrors", enrollConfirmCmpErrors);
        }
    },
    showModelEnrollmentComplete: function(component){
        var modal = component.find("modaldialog");
        var backdrop = component.find("backdrop");
        $A.util.removeClass(modal, 'slds-fade-in-hide');
        $A.util.addClass(modal, 'slds-fade-in-open');

        $A.util.removeClass(backdrop, 'slds-backdrop--hide');
        $A.util.addClass(backdrop, 'slds-backdrop--open');
    },
    hideModelEnrollmentComplete: function(component){
        var modal = component.find("modaldialog");
        var backdrop = component.find("backdrop");
        $A.util.addClass(modal, 'slds-fade-in-hide');
        $A.util.removeClass(modal, 'slds-fade-in-open');

        $A.util.addClass(backdrop, 'slds-backdrop--hide');
        $A.util.removeClass(backdrop, 'slds-backdrop--open');
    },
    setWizardProgressBar : function(component) {
        var pageCount = component.get("v.pageMetadata").length;
        if(pageCount != 0){
            var newPageIndex = component.get("v.currentPageIndex");
            var prevPageIndex = component.get("v.prevPageIndex");

            var newPageNodeElement = document.getElementById("slds-wizard__item" + newPageIndex);
            var prevPageNodeElement = document.getElementById("slds-wizard__item" + prevPageIndex);

            if (newPageIndex > prevPageIndex) {
                document.getElementById("slds-wizard__item" + newPageIndex).className =
                            newPageNodeElement.className + " slds-is-active";
            } else if (newPageIndex < prevPageIndex) {
                document.getElementById("slds-wizard__item" + prevPageIndex).className =
                    prevPageNodeElement.className.replace("slds-is-active", "");
            }

            var progressBarPercent = newPageIndex / pageCount * 100;
            var elementProgressBar = component.find('aura_progressBar').getElement();
            if(!$A.util.isUndefinedOrNull(elementProgressBar)){
                elementProgressBar.style = "width: " + progressBarPercent + "%;";
            }
        }
    },

    dismissToast: function(component) {
        var toast = component.find("toast");
    	$A.util.removeClass(toast, "transition-timing");
        $A.util.addClass(toast, "slds-transition-hide");
    },

    showToast: function(component, message) {
        var isCustomApp = component.get("v.isCustomApp");
        if(!isCustomApp){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Success!",
                "type": "success",
                "message": message
            });
            toastEvent.fire();
        }else{
            component.set("v.toastMessage", message);
            var toast = component.find("toast");

            $A.util.removeClass(toast, "slds-transition-hide");

            setTimeout($A.getCallback(function() {
                $A.util.addClass(toast, "transition-timing");
                $A.util.addClass(toast, "slds-transition-hide");
            }), 2500);
        }
    },
    resetErrorMessage : function (component, event, helper) {
        component.set("v.enrollmentProcessingResult", null);
        component.set("v.enrollmentErrorHeader", "");
        component.set("v.enrollmentErrors", "");
    },
    hideFooter : function (component) {
       var modal = component.find("aura_wfooter");
       $A.util.addClass(modal, 'disableFooter');
    },
    showFooter : function (component) {
        var modal = component.find("aura_wfooter");
        $A.util.removeClass(modal, 'disableFooter');
    }

})