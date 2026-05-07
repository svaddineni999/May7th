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
    
    getInit : function(component, event, helper) {
        //Testing code to capture the click event on child component to refresh the parent
        helper.recordTypePicklist(component, event, helper);
        helper.getFieldSetName(component, event, helper);
        var message = event.getParam("message");
        component.set("v.messageFromEvent", message);
       
        var action = component.get("c.getDocRecord");
        var recordId = component.get("v.recordId");
        action.setParams({
            docId : recordId,
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    var returnValue = a.getReturnValue();
                    component.set("v.doc", returnValue.document);
                    if (returnValue.document.RecordType.DeveloperName === 'PC_Fax_Inbound') {
                        component.set("v.documentType", component.get("v.InboundFax"));
                    } else if (returnValue.document.RecordType.DeveloperName === 'PC_Email_Inbound') {
                        component.set("v.documentType", component.get("v.InboundEmail"));
                    } else {
                        component.set("v.documentType", component.get("v.Document"));
                    }
                    component.set("v.categories", returnValue.lstCategories);
                    component.set("v.details", returnValue.lstDocFields);
                    component.set("v.loadFaxContainer", returnValue.loadFaxContainer);
                    component.set("v.loadEmailContainer", returnValue.loadEmailContainer);
                    
                    /*
                     * Set the docManufacturer,docEngagementProgId to the one on document [PC-1598]
                     */
                    component.set("v.docManufacturerId",returnValue.lstDocFields[0].docManufacturerId);
                    component.set("v.docEngagementProgId",returnValue.lstDocFields[0].docEngagementProgId);
                    //logic to fetch parent details, if exist 
                    var parentDocId = returnValue.lstDocFields[0].parentDocId;
                    /*if(returnValue.lstDocFields[0].parentDocAttachments.length < 1){
                        component.set("v.parentHasAttachments",false);
                    }*/
                    var componentName = "PC_Document_Management";//open the component for parent doc without the SF header
                    var vfpage = component.get("v.namespacePrefix")+'PC_DocumentSplit';
                    var url = '/apex/'+ vfpage +'?documentId=' + parentDocId + '&componentName=' + componentName;
                    //var url = '#/sObject/' +parentDocId + '/view';
                    component.set("v.parentURL", url);
                    if(!(parentDocId == undefined)){
                        component.set("v.isParentDoc", false);
                    }
                    // logic to fetch parent details ends
                    // PC-1669 Set isSplit value to display split section for non split documents.
                    component.set("v.isSplit", returnValue.lstDocFields[0].isSplit);
                    this.updateDisplayVariables(component, event, returnValue);
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
    
    getSubComponentList: function (component, event, helper) {
        var action = component.get("c.getSubComponentsList");
        /*PC-1980 - Method updated to get multiple components from metadata*/
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                var result =  a.getReturnValue();
                var noOfComponents = result.length;
                if(noOfComponents) {
                    var parameters = [];
                    var componentName=[];
                    var attributes = {recordId : component.get("v.recordId")};
                    var i;
                    for(i=0; i< result.length; i++) {
                        parameters[i] = [result[i].componentName, attributes]; //PC-2637
                    }
                    $A.createComponents(                       
                        parameters,
                        function(components) {
                            var targetCmp = component.find('body');
                            var content = [];
                            for(i=0; i< components.length; i++) {
                                content.push(components[i]); 
                            }
                            targetCmp.set("v.body", content );
                        }
                    );
                }
            } else if (a.getState() ==="ERROR") {
                var errors = a.getError();
                console.log(JSON.stringify(errors));
            }
        });
        $A.enqueueAction(action);
    },

    createDocumentLog : function (component, event, helper, accountId, docId){
        var action = component.get("c.createDocumentLog");
        action.setParams({
            accountId	: accountId,
            documentId	: docId
        });
        action.setCallback(this, function(a) {
            if (a.getState() ==="ERROR"){
                var errors = a.getError();
                console.log(JSON.stringify(errors));
            }
        });
        $A.enqueueAction(action);
        //$A.get('e.force:refreshView').fire();
        location.reload();
    },
    
    updateDisplayVariables : function(component, event, docWrapper) {
        var doc = docWrapper.document;
        var loggedInUserId = docWrapper.loggedInUserId;
        //     var ownerLogedIn = (doc != null && doc.OwnerId == component.get("v.userId"));
        var documentCategory = component.get('v.namespacePrefix') + 'PC_Document_Category__c';  
        var documentStatus = component.get('v.namespacePrefix') + 'PC_Document_Status__c';  
        var toShowAssignToMe = (doc.OwnerId != loggedInUserId && doc[documentCategory] != null && doc[documentCategory] != '');
        var toShowReassign = (doc.OwnerId == loggedInUserId && doc[documentCategory] != null && doc[documentCategory] != '');
        var showSpam = doc[documentStatus] != "Spam" && (doc[documentCategory] == null || doc[documentCategory] == '');
        var showArchive = (doc[documentStatus] != "Spam" && doc[documentStatus] != "Archived");
        //PC-2496 Removing additional condition to show Archive button && (doc[documentCategory] == null || doc[documentCategory] == '')) || doc[documentCategory] == "Categorized";
        var showUnspam = doc[documentStatus] == "Spam";
        var showIllegible = doc[documentStatus] != "Spam" && doc[documentStatus] != "Illegible" && (doc[documentCategory] == null || doc[documentCategory] == '');
        if (!toShowReassign) {component.set("v.showReassignSection", false);}
        //       component.set("v.isOwnerLogedIn", ownerLogedIn);
        component.set("v.showAssignToMe", toShowAssignToMe);
        component.set("v.showReassign", toShowReassign);
        component.set("v.showSpam", showSpam);
        component.set("v.showArchive", showArchive);
        component.set("v.showUnspam", showUnspam);
        component.set("v.showIllegible", showIllegible);
    },
    updateCategorylist : function(component, helper, selectedCategory) {
        //set Categories list based on selection
        var categories = component.get("v.categories");
        for(var i=0; i < categories.length; i++) {
            if(!$A.util.isEmpty(categories[i].categoryName) &&
                !$A.util.isEmpty(categories[i].isSelected) &&
                categories[i].categoryName.toLowerCase() ==  selectedCategory.toLowerCase())
            {
                if(categories[i].isSelected){
                    categories[i].isSelected = false;
                    if (categories[i].categoryName == component.get("v.EnrollmentForm")) {
                        categories[i].isEnrollmentForm = false;
                    }
                }else{
                    categories[i].isSelected = true;
                    if (categories[i].categoryName == component.get("v.EnrollmentForm")) {
                        categories[i].isEnrollmentForm = true;
                    }
                }
            }
        }
        component.set("v.categories",categories);
    },
    saveCategory : function(component, event, helper, selectedCateg) {
        var action = component.get("c.saveDocumentCategory");
        action.setParams({
            docId : component.get("v.recordId"),
            selectedCategory: selectedCateg
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    helper.updateCategorylist(component, helper, selectedCateg);
                    var returnValue = a.getReturnValue();
                    component.set("v.doc", returnValue.document);
                    //component.set("v.categories", returnValue.lstCategories);
                    component.set("v.details", returnValue.lstDocFields);
                    this.updateDisplayVariables(component, event, returnValue);
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
        var action = component.get("c.accountRecordTypes");
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS") {
                var result = a.getReturnValue();
                var arrayOfRt = [];
                var allRecordTypes ='';
                arrayOfRt.push({
                    "class": "optionClass", label: "--All--", value: "All", selected: "true"
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
    
    getFieldSetName : function(component, event, helper) {
        var action = component.get("c.fieldSetName");
        action.setParams({
            docId : component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    var fieldSet = a.getReturnValue();
                    if(fieldSet != 'false'){
                        var componentName = component.get("v.namespace") + ':' + component.get("v.fieldSetComponent");
                        $A.createComponent(
                            componentName,
                            {
                                "recordId"	: component.get("v.recordId"),
                                "fsName"	: fieldSet,
                                "typeName"	: 'PC_Document__c'
                            },
                            function(newComponent) {
                                var dynamicComponent = component.find("fieldSetCmp");
                                dynamicComponent.set("v.body", newComponent);
                            }
                        );
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
    
    assignToMe : function(component, event, helper) {
        var action = component.get("c.changeDocumentOwner");
        action.setParams({
            docId : component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    this.getLogs(component);
                    this.updateDisplayVariables(component, event, a.getReturnValue());
                }
            }else if (state ==="ERROR"){
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
    
    reassignDoc : function(component, event) {
        var action = component.get("c.reassignDocumentOwner");
        action.setParams({
            docId : component.get("v.recordId"),
            ownerId : component.get("v.userId"),
            sUserName : component.get("v.userName")
        });
        if (component.get("v.userId") === undefined || component.get("v.userId") == null || component.get("v.userId") == '') {
            return;
        }
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    component.set("v.showReassignSection", false);
                    this.getLogs(component);
                    this.updateDisplayVariables(component, event, a.getReturnValue());
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
    
    doArchive : function(component) {
        var action = component.get("c.archiveDocumentFax");
        action.setParams({
            docId : component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    //Added for PC-1018
                    this.updateDisplayVariables(component, event, a.getReturnValue());
                    location.reload();
                }
            } else if (state ==="ERROR"){
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
    
    markSpam : function(component) {
        var action = component.get("c.updateReportSpam");
        action.setParams({
            docId : component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {                    
                    //Added for PC-1018
                    this.updateDisplayVariables(component, event, a.getReturnValue());
                    location.reload();                    
                }
            }else if (state ==="ERROR"){
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
    
    markUnspam : function(component, event) {
        var action = component.get("c.updateReportUnspam");
        action.setParams({
            docId : component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    this.updateDisplayVariables(component, event, a.getReturnValue());
                    location.reload(); 
                }
            } else if (state ==="ERROR"){
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
    
    markIllegible : function(component) {
        var action = component.get("c.reportIllegible");
        action.setParams({
            docId : component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    // Added for PC-1018
                    this.updateDisplayVariables(component, event, a.getReturnValue());
                    location.reload(); 
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
    
    markComplete : function (component) {
        var action = component.get("c.reportComplete");
        action.setParams({
            docId : component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    this.updateDisplayVariables(component, event, a.getReturnValue());
                    location.reload();
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
    
    searchPatient : function(component) {
        var action = component.get("c.searchForPatient");
        action.setParams({
            p_searchString		: component.get("v.searchString"),
            p_recordTypeName	: component.get("v.recordType"),
            docManufacturer		: component.get("v.docManufacturerId"),
            docEngagementProg	: component.get("v.docEngagementProgId"),
            allRecordTypeList	: component.get("v.allRecordTypeList")
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
    
    getLogs : function(component) {
        var action = component.get("c.getModificationLogs");
        action.setParams({
            docId : component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    component.set("v.showDescriptionField", a.getReturnValue().showDocumentLogFieldVal);
                    component.set("v.lstDocumentsLogs", a.getReturnValue().documentLogWrapperList);
                }
            } else if (state ==="ERROR"){
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
    
    returnToList : function(component) {
        var action = component.get("c.getReturnUrl");
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                if(component.isValid()) {
                    var url = a.getReturnValue();
                    var res = url.split("/");
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": '/' + res[res.length - 1]
                    });
                    urlEvent.fire();
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
    
    showAckModal : function(component, event, helper) {
        var elementBackGroundSection = component.find('aura_backGroundSectionId').getElement();
        var elementLinkSectionId = component.find('aura_linkSectionId').getElement();
        elementBackGroundSection.style.display = "block";
        elementLinkSectionId.style.display = "block";
    },
    
    hideAckModal : function(component, event, helper) {        
        var elementBackGroundSection = component.find('aura_backGroundSectionId').getElement();
        var elementLinkSectionId = component.find('aura_linkSectionId').getElement();
        elementBackGroundSection.style.display = "none";
        elementLinkSectionId.style.display = "none";
    },
    
    setNamespace : function(component) {
        var component_to_string = component.toString();
        var markupTagLoc = component_to_string.indexOf('markup://');
        var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
        var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
        var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", namespacePrefix);
    },
    
    refreshCmp : function(component, event, helper) {
        var appEventns = 'e.' + component.get("v.namespace") + ':PC_RefreshChildCmp';
        var appEvent = $A.get(appEventns);
        appEvent.fire();
    },
    

})