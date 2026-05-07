/**
 * Created by havalakki on 2/5/2018.
 */
({
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

    hideModal : function(component, event, helper) {
            helper.hidePopupHelper(component, 'modaldialog', 'slds-fade-in-');
            helper.hidePopupHelper(component, 'backdrop', 'slds-backdrop--');
            event.preventDefault();
            //location.reload();
            return false;
        },

    hidePopupHelper: function(component, componentId, className){
        var modal = component.find(componentId);
        $A.util.addClass(modal, className+'hide');
        $A.util.removeClass(modal, className+'open');
    },
    getInit : function(component, event, helper) {
         var doclogcmp = component.find("documentLogLinkId");
                    $A.util.removeClass(doclogcmp, 'showComponent');
                    $A.util.addClass(doclogcmp, 'hideComponent');
            //Testing code to capture the click event on child component to refresh the parent
             helper.recordTypePicklist(component, event, helper);
            //helper.getFieldSetName(component, event, helper);
            var message = event.getParam("message");
            component.set("v.messageFromEvent", message);
            var action = component.get("c.getDocRecord");
            action.setParams({
                docId : component.get("v.recordId"),
            });
            action.setCallback(this, function(a) {
                var state = a.getState();
                if (state === "SUCCESS") {
                    if(component.isValid()) {
                        var returnValue = a.getReturnValue();
                        console.log(JSON.stringify(returnValue));
                        component.set("v.doc", returnValue.document);
                        /*
                         * Set the docManufacturer,docEngagementProgId to the one on document [PC-1598]
                         */
                        component.set("v.docManufacturerId",returnValue.docManufacturerId);
                        component.set("v.docEngagementProgId",returnValue.docEngagementProgId);
                    }
                } else if (state ==="ERROR") {
                    var errors = a.getError();
                    console.log(JSON.stringify(errors));
                    var errText = component.get("v.ErrorText");
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log(errText);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            });
            $A.enqueueAction(action);
        },

    // This method creates the dropdown of record types on search
        recordTypePicklist : function(component, event, helper) {
            var stringAll=component.get('v.labelAll');
            var action = component.get("c.accountRecordTypes");
            action.setCallback(this, function(a) {
                debugger;
                if(a.getState() ==="SUCCESS") {
                    var result = a.getReturnValue();
                    var arrayOfRt = [];
                    var allRecordTypes ='';
                    arrayOfRt.push({
                        "class": "optionClass", label: "--"+stringAll+"--", value: "All", selected: "true"
                    });
                    for(var i in result) {
                        if(allRecordTypes!=''){
                            allRecordTypes = allRecordTypes+','+result[i].DeveloperName;
                        }else{
                            allRecordTypes = result[i].DeveloperName;
                        }
                        arrayOfRt.push({
                            "class": "optionClass", label: result[i].Name, value: result[i].DeveloperName
                        });
                    }
                    component.set('v.allRecordTypeList',allRecordTypes);
                    component.find("selectAccountRt").set("v.options",arrayOfRt);
                } else if (a.getState() ==="ERROR") {
                    var errors = a.getError();
                    console.log(JSON.stringify(errors));
                }
            });
            $A.enqueueAction(action);
        },

    searchPatient : function(component) {
            var action = component.get("c.searchForPatient");
            var patSearchDetails = new Map();
                                   patSearchDetails['p_searchString'] = component.get("v.searchString");
                                   patSearchDetails['p_recordTypeName'] = component.get("v.recordType");
                                   patSearchDetails['docManufacturer'] = component.get("v.docManufacturerId");
                                   patSearchDetails['docEngagementProg'] = component.get("v.docEngagementProgId");
                                   patSearchDetails['allRecordTypeList'] = component.get("v.allRecordTypeList");
            action.setParams({
                    patSearchDetails    : patSearchDetails
            });
            action.setCallback(this, function(a) {
                var state = a.getState();
                if (state === "SUCCESS") {
                    if(component.isValid()) {
                        var returnValue = a.getReturnValue();
                        component.set("v.lstPatientsWrapper", returnValue);
                        if (returnValue.length == 0){
                            component.set("v.showNoPatients", true);
                        } else {
                            component.set("v.showNoPatients", false);
                        }
                    }
                } else if (state ==="ERROR") {
                    var errors = a.getError();
                    console.log(JSON.stringify(errors));
                    var errText = component.get("v.ErrorText");
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log(errText);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            });
            $A.enqueueAction(action);
        },

    refreshCmp : function(component, event, helper) {
            var appEventns = 'e.' + component.get("v.namespace") + ':PC_RefreshChildCmp';
            var appEvent = $A.get(appEventns);
            appEvent.fire();
        },
    setNamespace : function(component) {
            var component_to_string = component.toString();
            var markupTagLoc = component_to_string.indexOf('markup://');
            var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
            var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
           // var namespacePrefix = ns === "c" ?  namespacePrefix = "" :  namespacePrefix = ns + "__";
            component.set("v.namespace", ns);
            //component.set("v.namespacePrefix", namespacePrefix);
        },

   
        showToastMessage : function(title,type, message) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": title,
                    "type" : type,
                    "message": message
                });
                if(type=='Error'){
                    toastEvent.setParams({
                        "mode": 'sticky'
                    });
                }
                toastEvent.fire();
            },

        getPatientInfo : function(component, event, helper) {
           component.set("v.errors", []);
           var searchTerm = component.get("v.searchString");
           component.set("v.patiendId", '');
           component.set("v.lstPatientsWrapper",[]);
           if(searchTerm != null && searchTerm.trim().length >= 2 ) {
               helper.searchPatient(component);
               component.set("v.displayPatientsTable", true);
           }
           else {
               component.set("v.isInValidInput", true);
           }
        }

})