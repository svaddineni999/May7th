/**
 * Created by havalakki on 1/30/2018.
 */
({
    setNamespace : function(component) {
        var component_to_string = component.toString();
        var markupTagLoc = component_to_string.indexOf('markup://');
        var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
        var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
        var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", namespacePrefix);
    },
    doneRendering : function(component, event) {
                if (typeof $ == 'undefined' || $(".detailsAccordion").find("h3").length == 0) { return; }
                $(".detailsAccordion").addClass("ui-accordion ui-accordion-icons ui-widget ui-helper-reset")
                .find("h3")
                .addClass("ui-accordion-header ui-helper-reset ui-state-default ui-corner-top ui-corner-bottom")
                .unbind("hover").hover(function() { $(this).toggleClass("ui-state-hover"); })
                .prepend('<span class="ui-icon ui-icon-triangle-1-e"></span>')
                .unbind("click").click(function() {
                    $(this).find("> .ui-icon").toggleClass("ui-icon-triangle-1-e ui-icon-triangle-1-s")
                    .end().next().toggleClass("ui-accordion-content-active").slideToggle();
                    return false;
                })
                .next()
                .addClass("ui-accordion-content ui-helper-reset ui-widget-content ui-corner-bottom")
            },

    getInit : function(component, event, helper) {
            //Testing code to capture the click event on child component to refresh the parent
            //helper.recordTypePicklist(component, event, helper);
            //helper.getFieldSetName(component, event, helper);
            var message = event.getParam("message");
            component.set("v.messageFromEvent", message);
            var action = component.get("c.getDocRecordForTags");
            action.setParams({
                docId : component.get("v.recordId"),
                useUserInterfaceAPI : component.get("v.useUserInterfaceAPI"),
                userInterfaceAPINamedCredential : component.get("v.userInterfaceAPINamedCredential")
            });
            action.setCallback(this, function(a) {
                var state = a.getState();
                if (state === "SUCCESS") {
                    if(component.isValid()) {
                        var returnValue = a.getReturnValue();
                        component.set("v.doc", returnValue.document);
                        component.set("v.categories", returnValue.lstCategories);
                    }
                }
                else if (state ==="ERROR") {
                    debugger;
                    var errors = a.getError();
                    console.log(JSON.stringify(errors));
                    var errText = component.get("v.ErrorText");
                    var allErrors = new Array();
                    allErrors.push(errText);

                    if (!$A.util.isEmpty(errors)) {
                        if (errors[0] && errors[0].message) {
                            console.log(errors[0].message + errText);
                            allErrors.push(errors[0].message);
                        }
                    } else {
                        console.log('Unknown Error');
                        allErrors.push('Unknown error');
                    }
                    component.set("v.errors", allErrors);
                }
                else {
                    var error = [];
                    if(!$A.util.isUndefinedOrNull(a.getError())){
                        error.push(a.getError());
                    }
                    console.log(a.getError());
                    component.set("v.errors", error);
                }
            });
            $A.enqueueAction(action);
        },

    updateCategorylist : function(component, helper, selectedCategory) {
        //set Categories list based on selection
        var categories = component.get("v.categories");
        for(var i=0; i < categories.length; i++) {
            if(!$A.util.isEmpty(categories[i].categoryName) && !$A.util.isEmpty(categories[i].isSelected) && categories[i].categoryName.toLowerCase() ==  selectedCategory.toLowerCase())
            {
                categories[i].isSelected = !categories[i].isSelected;
                component.set("v.selectedCategoryStatus", categories[i].isSelected);
            }
        }
        component.set("v.categories",categories);
    },

    saveCategory : function(component, event, helper, selectedCateg) {
        helper.showSpinner(component, event, helper);
        var docId = component.get("v.recordId");
        var action = component.get("c.saveDocumentCategoryV2");
        component.set("v.currentSelectedCategory", selectedCateg);
        action.setParams({
            docId : component.get("v.recordId"),
            selectedCategory: selectedCateg
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    helper.updateCategorylist(component, helper, selectedCateg);
                    var selectedCategoryStatus = component.get("v.selectedCategoryStatus");
                    helper.fireDocumentTagsChangedEvent(component, docId, selectedCateg, selectedCategoryStatus);
                }
            } else if (state ==="ERROR") {
                var errors = a.getError();
                helper.handleErrors(component, errors);
            }
            helper.hideSpinner(component, event, helper);
        });
        $A.enqueueAction(action);
    },
    
    showHideSection : function(component,event,secId) {
        var acc = component.find(secId);
            for(var cmp in acc) {
            $A.util.toggleClass(acc[cmp], 'slds-show');
            $A.util.toggleClass(acc[cmp], 'slds-hide');
        }
    },

    fireDocumentTagsChangedEvent : function(component, docId, selectedCategory, selectedCategoryStatus) {
        var appEventName = 'e.' + component.get("v.namespace") + ':PC_DocumentTagsChangedEvent';
        var appEvent = $A.get(appEventName);
        appEvent.setParams({
                     "documentId" : docId,
                     "selectedCategory": selectedCategory,
                     "selectedCategoryStatus" : selectedCategoryStatus
        });
        appEvent.fire();
    },

    handleErrors : function(component, errors) {
        let toastParams = {
            title: "Error",
            message: component.get("v.ErrorText"), // Default error message
            type: "error"
        };
        // Pass the error message if any
        if (errors && Array.isArray(errors) && errors.length > 0) {
            //top-level error.  there can be only one
            if(errors[0].message) {
                toastParams.message = errors[0].message;
            }

            //page-level errors (validation rules, etc)
            if (errors[0].pageErrors) {
                toastParams.message = errors[0].pageErrors[0].message;
            }
        }
        // Fire error toast
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams(toastParams);
        toastEvent.fire();
    },

    showSpinner: function(component, event, helper) {
        var spinner = component.find("documentTagSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    hideSpinner : function(component,event,helper){
        var spinner = component.find("documentTagSpinner");
        $A.util.addClass(spinner, "slds-hide");
    }
})