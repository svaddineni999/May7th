({
	//init method
    getInit : function(component, event, helper) {
        //get page count for parent document
        helper.parentDocumentCount(component, event, helper);
        var ParentID = component.get("v.recordId");
        var action = component.get("c.getChildDocs");
        action.setParams({
            "ParentID": ParentID
        });
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS") {
                component.set("v.noSplitDocs",a.getReturnValue());
               	component.set("v.isResubmit", true);
                for(var i=0; i < a.getReturnValue().length; i++ ) {
                    if(!(a.getReturnValue()[i].DocumentStatus === 'Awaiting Attachment')) {
                        component.set("v.isResubmit", false);
                        break;
                    }                    
                }
               	if(a.getReturnValue().length < 1) {
                    component.set("v.isSplitbuttonActive", false);
                }
            } else if (a.getState() ==="ERROR"){
                var errors = a.getError();
                console.log(JSON.stringify(errors));
            }
        });
        $A.enqueueAction(action);       
    }, 
    
    //Modal window for editing page reference for an existing child document
    showEditMod:function(component, event, helper){
        var noSplitDocs = component.get("v.noSplitDocs");
        var index = event.currentTarget.dataset.index;
        var newChildDocPgRange = noSplitDocs[index].DocumentPageRange;
        component.set("v.newChildDocPgRange",newChildDocPgRange);
        component.set("v.selDocIndex",index);
        var modal = component.find("editModal");
        var backdrop = component.find("backdrop");
        $A.util.removeClass(modal, 'slds-fade-in-hide');
        $A.util.addClass(modal, 'slds-fade-in-open');
        
        $A.util.removeClass(backdrop, 'slds-backdrop--hide');
        $A.util.addClass(backdrop, 'slds-backdrop--open');
    },
    
	refreshCmp : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
        var cmpEvent = component.getEvent("cmpEvent");
        //test parameter set for event - to be removed later
        cmpEvent.setParams({
            "message" : "A component event fired me."
        });
        cmpEvent.fire();
    },
    
    parentDocumentCount : function(component, event, helper) {
        var ParentID = component.get("v.recordId");
        var action = component.get("c.getParentDocumentCount");
        action.setParams({
            "ParentID": ParentID
        });
        action.setCallback(this, function(a) {
            if(a.getState() ==="SUCCESS") {
                component.set("v.pageCount",a.getReturnValue());
            } else if (a.getState() ==="ERROR") {
                var errors = a.getError();
                console.log(JSON.stringify(errors));
            }
        });
        $A.enqueueAction(action);
    },
    
    //Function to execute split request
    sendSplit : function(component, event, helper) {
        helper.getInit(component, event, helper);
        var reSubmit = component.get("v.isResubmit");
        if (reSubmit) {
            helper.showReSubmitModal(component, event, helper);
        } else {
            var ParentID = component.get("v.recordId");
            var action = component.get("c.updateStatus");
            action.setParams({
                "parentDocId": ParentID
            });
            action.setCallback(this, function(a) {
                if (a.getState() ==="ERROR") {
                    var errors = a.getError();
                    console.log(JSON.stringify(errors));
                }
            });
            $A.enqueueAction(action);    
            $A.get('e.force:refreshView').fire();
            var cmpEvent = component.getEvent("cmpEvent");
            //test parameter set for event - to be removed later
            cmpEvent.setParams({
                "message" : "A component event fired me. "
            });
            cmpEvent.fire();//'Execute Split' fires an event to refresh the parent component    
            helper.showAckModal(component, event, helper);
        }
    },
    
    //Function remove the child documents 
    delSplit : function(component, event, helper){
        var noSplitDocs = component.get("v.noSplitDocs");
        var index = component.get("v.confirmDelIndex");
        if (index > -1) {
            var action = component.get("c.deleteChildDoc");
            action.setParams({
                "docId": noSplitDocs[index].DocumentId                
            });
            action.setCallback(this, function(a) {
                if(a.getState() ==="SUCCESS") {
                    noSplitDocs.splice(index, 1);
                    component.set("v.noSplitDocs",noSplitDocs);
                    helper.refreshCmp(component, event, helper);
                } else if (a.getState() ==="ERROR"){
                    var errors = a.getError();
                    console.log(JSON.stringify(errors));
                }
            });
            $A.enqueueAction(action);
            $A.get('e.force:refreshView').fire();
        }
    },
    
    //Function update the child documents 
    updSplit : function(component, event, helper) {
        var checkSanity = helper.validatePageRange(component, event, helper);
        if(checkSanity) {
            var noSplitDocs = component.get("v.noSplitDocs");
            var index = component.get("v.selDocIndex");
            var numbersArray = component.get("v.pageRange");
            if (index > -1) {
                var action = component.get("c.updChildDoc");
                action.setParams({
                    "docId"			: noSplitDocs[index].DocumentId,
                    "pgRange" 		: component.get("v.newChildDocPgRange"),
                    "ParentPgNum"	: numbersArray.toString(),
                    "pageCount"		: (numbersArray.length).toString()
                });
                action.setCallback(this, function(a) {
                    if(a.getState() ==="SUCCESS") {
                        helper.hideEditModalWindow(component, event, helper);
                        component.set("v.newChildDocPgRange", "");
                        component.set("v.isSplitbuttonActive", true);
                        helper.refreshCmp(component, event, helper);
                    } else if (a.getState() ==="ERROR"){
                        var errors = a.getError();
                        console.log(JSON.stringify(errors));
                    }
                });
                $A.enqueueAction(action);
            }
        } else {
            component.find("pageRangeErrorEdit").set("v.errors", [{message: component.get("v.errorMsg")}]);
        }
    },
    
    //Hide modal window for editing page reference for an existing child document
    hideEditModalWindow : function(component, event, helper) {
        /*
         * Reset the popout window
         */
        component.set("v.newChildDocPgRange", "");
        component.find("pageRangeErrorEdit").set("v.errors", [{message: ""}]);
        
        var modal = component.find("editModal");
        var backdrop = component.find("backdrop");
        $A.util.removeClass(modal, 'slds-fade-in-open');
        $A.util.addClass(modal, 'slds-fade-in-hide');
        
        $A.util.removeClass(backdrop, 'slds-backdrop--open');
        $A.util.addClass(backdrop, 'slds-backdrop--hide'); 
        $A.get('e.force:refreshView').fire();
        event.preventDefault();
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
    
    //Modal window for showing an acknowledgement window when split request is sent
    showAckModal : function(component, event, helper) {
        var modal = component.find("splitInitmodal");
        var backdrop = component.find("backdrop");
        $A.util.removeClass(modal, 'slds-fade-in-hide');
        $A.util.addClass(modal, 'slds-fade-in-open');
        
        $A.util.removeClass(backdrop, 'slds-backdrop--hide');
        $A.util.addClass(backdrop, 'slds-backdrop--open');
    },
    
    //Modal window for showing a warning message when split request is resubmitted
    showReSubmitModal : function(component, event, helper) {
        var modal = component.find("resubmitmodal");
        var backdrop = component.find("backdrop");
        $A.util.removeClass(modal, 'slds-fade-in-hide');
        $A.util.addClass(modal, 'slds-fade-in-open');
        
        $A.util.removeClass(backdrop, 'slds-backdrop--hide');
        $A.util.addClass(backdrop, 'slds-backdrop--open');
    },
    
    //Hide modal window for showing a warning message when split request is resubmitted
    hideReSubmitModal : function(component, event, helper) {
        var modal = component.find("resubmitmodal");
        var backdrop = component.find("backdrop");
        $A.util.removeClass(modal, 'slds-fade-in-open');
        $A.util.addClass(modal, 'slds-fade-in-hide');
        
        $A.util.removeClass(backdrop, 'slds-backdrop--open');
        $A.util.addClass(backdrop, 'slds-backdrop--hide'); 
    },
    
    //Modal window to show a warning message on deletion of a child document
    showDeleteModal : function(component, event, helper) {
        var index = event.currentTarget.dataset.index;
        console.log('index in helper:' + index);
        component.set("v.confirmDelIndex", index);
        var modal = component.find("delwarningmodal");
        var backdrop = component.find("backdrop");
        $A.util.removeClass(modal, 'slds-fade-in-hide');
        $A.util.addClass(modal, 'slds-fade-in-open');
        
        $A.util.removeClass(backdrop, 'slds-backdrop--hide');
        $A.util.addClass(backdrop, 'slds-backdrop--open');
    },
    
    //Modal window to show a warning message on deletion of a child document
    hideDeleteModal : function(component, event, helper) {
        var modal = component.find("delwarningmodal");
        var backdrop = component.find("backdrop");
        $A.util.removeClass(modal, 'slds-fade-in-open');
        $A.util.addClass(modal, 'slds-fade-in-hide');
        
        $A.util.removeClass(backdrop, 'slds-backdrop--open');
        $A.util.addClass(backdrop, 'slds-backdrop--hide');   
        
    },
    
    saveChildDocument : function(component, event, helper) {
		var checkSanity = helper.validatePageRange(component, event, helper);
        if(checkSanity) {
            var numbersArray = component.get("v.pageRange");
            var action = component.get("c.createChildDoc");
            action.setParams({"pgRange"		: component.get("v.newChildDocPgRange"),
                              "ParentID"	: component.get("v.recordId"),
                              "ParentPgNum"	: numbersArray.toString(),
                              "pageCount"	: (numbersArray.length).toString()
                             });
            action.setCallback(this, function(a) {
                if(a.getState() ==="SUCCESS") {
                    var modal = component.find("modaldialog");
                    var backdrop = component.find("backdrop");
                    $A.util.removeClass(modal, 'slds-fade-in-open');
                    $A.util.addClass(modal, 'slds-fade-in-hide');
                    
                    $A.util.removeClass(backdrop, 'slds-backdrop--open');
                    $A.util.addClass(backdrop, 'slds-backdrop--hide');
                    component.set("v.newChildDocPgRange", "");
                    component.set("v.isSplitbuttonActive", true);
                    helper.refreshCmp(component, event, helper);
                } else if (a.getState() ==="ERROR"){
                    var errors = a.getError();
                    console.log(JSON.stringify(errors));
                }
            });
            $A.enqueueAction(action);  
        }
        else {
            component.find("pageRangeErrorSave").set("v.errors", [{message: component.get("v.errorMsg")}]);
        }
        event.preventDefault();
    },
    
    validatePageRange : function(component, event, helper) {
        var checkRange = true;
        var expand = function(text) {
            var list = text.split('-');
            if(Number(list[0]) < Number(list[1])){
                var result = [];
                for(var from = + list[0], to = +list[1]; from <= to; from++) {
                    result.push(from);
                }
                checkRange = true;
                return result;
            } else {
                checkRange = false;
            } 
        },
            toArray = function(str) {
                var list = str.split(',');
                var result = [];
                list.forEach(function(item) {
                    item.match(/\d.*-.*\d/) ? 
                        result = result.concat(expand(item)) : result.push(+item)
                });
                return result;
            };
        function sort_unique(arr) {
            if (arr.length === 0) return arr;
            var sortedArray = arr.sort(function (a, b) { return a*1 - b*1; });
            arr = sortedArray;
            var ret = [arr[0]];
            for (var i = 1; i < arr.length; i++) { // start loop at 1 as element 0 can never be a duplicate
                if (arr[i-1] !== arr[i]) {
                    ret.push(arr[i]);
                }
            }
            return ret;
        }
        //Create a page range
        var inputString = component.get("v.newChildDocPgRange");
        var numbersArray = [];
        //Check for last value of array
        var checkPageCount = false;
        var checkZeroInput = false;
        if (typeof inputString != 'undefined') {
            numbersArray = sort_unique(toArray(inputString));
            component.set("v.pageRange", numbersArray);
            var lastElement = numbersArray[numbersArray.length - 1];
            if ((component.get("v.pageCount") === 0) || (lastElement <= component.get("v.pageCount"))) {
                checkPageCount = true;
            }
            if (numbersArray[0] > 0) {
                checkZeroInput = true;
            }
        }
        //Regular expression for Page Range validation 
        var regularEx = new RegExp("^(\\s*\\d+\\s*\\-\\s*\\d+\\s*,?|\\s*\\d+\\s*,?)+$");
        var checkInputSanity = regularEx.test(component.get("v.newChildDocPgRange"));
        var sanityResult = false;
        if (checkInputSanity && checkRange && checkPageCount && checkZeroInput){
            sanityResult = true;
        }
        return sanityResult;
        
    }
})