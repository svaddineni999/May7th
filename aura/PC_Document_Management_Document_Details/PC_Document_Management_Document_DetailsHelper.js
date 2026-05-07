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

    clearAttributes : function(component) {
        component.set("v.details",null);
        component.set("v.fieldsetMap",null);
    },
    
    getInit : function(component, event, helper) {
        //Testing code to capture the click event on child component to refresh the parent
        // helper.recordTypePicklist(component, event, helper);
        helper.getFieldSetName(component, event, helper);
        //var message = event.getParam("message");
        //   component.set("v.messageFromEvent", message);
        
        var action = component.get("c.getDocRecordForDetails");
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
                    //[PC-2565] Updated to show document's record type        By: Prachi Nandgaonkar
                    component.set("v.documentType",returnValue.document.RecordType.Name);
                    component.set("v.details", returnValue.lstDocFields);
                    var documentApiName = component.get("v.namespacePrefix")+'PC_Document_Name__c';
                    component.set("v.documentName", returnValue.document[documentApiName]);
                    
                    
                    //    component.set("v.loadFaxContainer", returnValue.loadFaxContainer);
                    //  component.set("v.loadEmailContainer", returnValue.loadEmailContainer);
                    
                    /*
                     * Set the docManufacturer,docEngagementProgId to the one on document [PC-1598]
                     */
                    //   component.set("v.docManufacturerId",returnValue.lstDocFields[0].docManufacturerId);
                    
                    //logic to fetch parent details, if exist
                    var parentDocId = returnValue.lstDocFields[0].parentDocId;
                    /*if(returnValue.lstDocFields[0].parentDocAttachments.length < 1){
                        component.set("v.parentHasAttachments",false);
                    }*/
                    //var componentName = "PC_Document_Management";//open the component for parent doc without the SF header
                    // var vfpage = component.get("v.namespacePrefix")+'PC_DocumentSplit';
                    //    var url = '/apex/'+ vfpage +'?documentId=' + parentDocId + '&componentName=' + componentName;
                    //var url = '#/sObject/' +parentDocId + '/view';
                    //  component.set("v.parentURL", url);
                    if(!(parentDocId == undefined)){
                        component.set("v.isParentDoc", false);
                    }
                    // logic to fetch parent details ends
                    // PC-1669 Set isSplit value to display split section for non split documents.
                    // component.set("v.isSplit", returnValue.lstDocFields[0].isSplit);
                    // this.updateDisplayVariables(component, event, returnValue);
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
    
    dynamicFieldSet: function(component, helper){
        var action = component.get('c.getFields');
        
        action.setParams({
            
            fsName:  component.get('v.fsName'),
            typeName: component.get('v.namespacePrefix') +  component.get('v.typeName'),
            recordId: component.get('v.recordId')
        });
        action.setCallback(this,
                           function(response) {
                               var fields = response.getReturnValue();
                               component.set('v.fieldset', fields);
                               helper.createMap(component, helper, fields);
                           });
        $A.enqueueAction(action);
    },
    
    createMap : function(component, helper, fields){
        // convert to map
        
        var createMap = {};
        var cmps =fields;
        var noOfItems = component.get("v.noOfItemsInARow");
        var noOfCols = [];
        var noOfRows = [];
        //Set Columns
        for(var k=1; k<=noOfItems; k++){
            noOfCols.push(k);
        }
        
        
        //Set Rows
        for(var l=1; l<=Math.ceil((cmps.length)/noOfItems); l++){
            noOfRows.push(l);
        }
        
        var cmpIndex = 0;
        for(var i=0; i<noOfRows.length; i++) {
            for(var j=0; j<noOfCols.length; j++) {
                if(cmpIndex < cmps.length) {
                    createMap[i + '' + j] = cmps[cmpIndex];
                } else {
                    createMap[i + '' + j] = {};
                }
                cmpIndex++;
            }
        }
        //component.set("v.showForm",false);
        component.set("v.fieldsetMap",createMap);
        component.set("v.noOfColumns",noOfCols);
        component.set("v.noOfRows",noOfRows);
        component.set("v.showForm",true);
        //helper.creteFieldSetComponent(componet, helper);
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
                        
                        component.set("v.fsName", fieldSet);
                        helper.dynamicFieldSet(component, helper);
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
    
    setNamespace : function(component) {
        var component_to_string = component.toString();
        var markupTagLoc = component_to_string.indexOf('markup://');
        var endOfNamespaceLoc = component_to_string.indexOf(':',markupTagLoc+9);
        var ns = component_to_string.substring(markupTagLoc+9,endOfNamespaceLoc);
        var namespacePrefix = (ns == "c" || ns == "C") ?  "" :  ns + "__";
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", namespacePrefix);
    },
    
    showHideSection : function(component,event,secId) {
        var acc = component.find(secId);
        for(var cmp in acc) {
            $A.util.toggleClass(acc[cmp], 'slds-show');  
            $A.util.toggleClass(acc[cmp], 'slds-hide');  
        }
    },
})