/**
 * Created by havalakki on 3/1/2018.
 */
({

        applyCSS: function(component){
            component.set("v.cssStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:0} .forceStyle.desktop .viewport{overflow:hidden}");
        },

        revertCssChange: function(component){
            component.set("v.cssStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:5} .forceStyle.desktop .viewport{overflow:visible}");
        },
        //init method
        getInit : function(component, event, helper) {
            //get page count for parent document
            helper.parentDocumentCount(component, event, helper);
            var ParentID = component.get("v.recordId");
            var isRelatedComp = component.get("v.isRelatedComponent");
            var isAdmin = component.get("v.isAdminAccess");
            var action = component.get("c.getChildDocs");
            action.setParams({
                "ParentID": ParentID,
                "isRelatedComponent": isRelatedComp,
                "isAdmin"   : isAdmin
            });
            action.setCallback(this, function(a) {
                if(a.getState() ==="SUCCESS") {
                    var childDocInfo=JSON.parse(a.getReturnValue());
                    var splitDocList=childDocInfo.childDocumentWrapperList;
                    //component.set("v.noSplitDocs",a.getReturnValue());
                    component.set("v.noSplitDocs",splitDocList);
                    component.set("v.hasAttachment",childDocInfo.hasAttachment);
                    component.set("v.noAttachment",!childDocInfo.hasAttachment);
                   	//component.set("v.isResubmit", true);
                   	component.set("v.isSplitbuttonActive", false);
                    for(var i=0; i < splitDocList.length; i++ ) {
                        if((splitDocList[i].DocumentStatus === 'Split Failure' || splitDocList[i].DocumentStatus === 'Ready for Split')
                            && (splitDocList[i].enableSplit === true)) {
                            component.set("v.isSplitbuttonActive", true);
                            break;
                        }
                    }
                   	if(splitDocList.length < 1) {
                        component.set("v.isSplitbuttonActive", false);
                    }
                } else if (a.getState() ==="ERROR"){
                    var errors = a.getError();
                    CH_PC_Util.showAllErrors(component.get("v.errorDocStatus"),errors);
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
            component.set("v.showEditLabel",true);
            component.set("v.showParentLabel",false);

            var modal = component.find("editModalBox");
            $A.util.removeClass(modal, 'slds-hide');
            $A.util.addClass(modal, 'slds-show');
            var parentModal = component.find("parentModalBox");
            $A.util.removeClass(parentModal, 'slds-show');
            $A.util.addClass(parentModal, 'slds-hide');
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
                    CH_PC_Util.showAllErrors(component.get("v.errorDocStatus"),errors);
                    console.log(JSON.stringify(errors));
                }
            });
            $A.enqueueAction(action);
        },

        //Function to execute split request
        sendSplit : function(component, event, helper) {
            helper.getInit(component, event, helper);
            var reSubmit = component.get("v.isResubmit");
            var isAdmin = component.get("v.isAdminAccess");
            if (reSubmit) {
                helper.showReSubmitModal(component, event, helper);
            } else {
                var ParentID = component.get("v.recordId");
                var action = component.get("c.updateStatus");
                action.setParams({
                    "parentDocId": ParentID,
                    "isAdmin"   : isAdmin
                });
                action.setCallback(this, function(a) {
                    if(a.getState() ==="SUCCESS") {
                        //Add code foe success here, if any.

                    } else if (a.getState() ==="ERROR") {
                        var errors = a.getError();
                        CH_PC_Util.showAllErrors(component.get("v.errorDocStatus"),errors);
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
                        CH_PC_Util.showAllErrors(component.get("v.errorDocStatus"),errors);
                        console.log(JSON.stringify(errors));
                    }
                });
                $A.enqueueAction(action);
                $A.get('e.force:refreshView').fire();
            }
        },

        //Function update the child documents
        updateSplit : function(component, event, helper) {
            //var checkSanity = helper.validatePageRange(component, event, helper);
            var resultString = helper.validatePageRange(component, event, helper);

            if(resultString=='SUCCESS') {
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

                            component.set("v.newChildDocPgRange", "");
                            component.find("pageRangeErrorEdit").set("v.errors", [{message: ""}]);
                            //component.set("v.isSplitbuttonActive", true);

                            var editModal=component.find('editModalBox');
                            $A.util.removeClass(editModal, 'slds-show');
                            $A.util.addClass(editModal, 'slds-hide');

                            var parentModal = component.find("parentModalBox");
                            $A.util.removeClass(parentModal, 'slds-hide');
                            $A.util.addClass(parentModal, 'slds-show');
                            component.set("v.showEditLabel",false);

                            helper.refreshCmp(component, event, helper);
                        } else if (a.getState() ==="ERROR"){
                            var errors = a.getError();
                            CH_PC_Util.showAllErrors(component.get("v.errorDocStatus"),errors);
                            //component.find("pageRangeErrorEdit").set("v.errors", [{message: component.get("v.invalidInputErrorMsg")}]);
                        }
                    });
                    $A.enqueueAction(action);
                }
            }
            else if(resultString=='INCORRECT_INPUT'){
                component.set("v.disableButton",false); //Reset the disabled button
                component.find("pageRangeErrorEdit").set("v.errors", [{message: component.get("v.errorMsg")}]);
            }
            else if(resultString=='INVALID_DATA'){
                component.set("v.disableButton",false); //Reset the disabled button
               component.find("pageRangeErrorEdit").set("v.errors", [{message: component.get("v.invalidInputErrorMsg")}]);
            }
        },

        //Hide modal window for editing page reference for an existing child document
        hideEditModalWindow : function(component, event, helper) {
            /*
             * Reset the popout window
             */
            component.set("v.newChildDocPgRange", "");
            component.find("pageRangeErrorEdit").set("v.errors", [{message: ""}]);
            component.set('v.showParentLabel',true);
            component.set('v.showEditLabel',false);
            component.set('v.showAddLabel',false);

            var editModal = component.find("editModalBox");
            $A.util.removeClass(editModal, 'slds-show');
            $A.util.addClass(editModal, 'slds-hide');

            var parentModal = component.find("parentModalBox");
            $A.util.removeClass(parentModal, 'slds-hide');
            $A.util.addClass(parentModal, 'slds-show');

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
            var parentModal=component.find('mainModalDialog');
            $A.util.addClass(parentModal, 'slds-backdrop slds-backdrop--open');

            var modal = component.find("splitInitmodal");
            $A.util.removeClass(modal, 'slds-fade-in-hide');
            $A.util.addClass(modal, 'slds-fade-in-open');

        },

        //Modal window for showing a warning message when split request is resubmitted
        showReSubmitModal : function(component, event, helper) {
            var parentModal=component.find('mainModalDialog');
            $A.util.addClass(parentModal, 'slds-backdrop slds-backdrop--open');

            var modal = component.find("resubmitmodal");
            $A.util.removeClass(modal, 'slds-fade-in-hide');
            $A.util.addClass(modal, 'slds-fade-in-open');

        },

        //Hide modal window for showing a warning message when split request is resubmitted
        hideReSubmitModal : function(component, event, helper) {
            var modal = component.find("resubmitmodal");
            $A.util.removeClass(modal, 'slds-fade-in-open');
            $A.util.addClass(modal, 'slds-fade-in-hide');

             var parentModal=component.find('mainModalDialog');
             $A.util.removeClass(parentModal, 'slds-backdrop slds-backdrop--open');

        },

        //Modal window to show a warning message on deletion of a child document
        showDeleteModal : function(component, event, helper) {
             var parentModal=component.find('mainModalDialog');
             $A.util.addClass(parentModal, 'slds-backdrop slds-backdrop--open');

            var index = event.currentTarget.dataset.index;
            console.log('index in helper:' + index);
            component.set("v.confirmDelIndex", index);
            var modal = component.find("delwarningmodal");
            $A.util.removeClass(modal, 'slds-fade-in-hide');
            $A.util.addClass(modal, 'slds-fade-in-open');

        },

        //Modal window to show a warning message on deletion of a child document
        hideDeleteModal : function(component, event, helper) {
            var modal = component.find("delwarningmodal");
            $A.util.removeClass(modal, 'slds-fade-in-open');
            $A.util.addClass(modal, 'slds-fade-in-hide');

            var parentModal=component.find('mainModalDialog');
            $A.util.removeClass(parentModal, 'slds-backdrop slds-backdrop--open');

        },

        saveChildDocument : function(component, event, helper) {

            		//var checkSanity = helper.validatePageRange(component, event, helper);
            		var resultString = helper.validatePageRange(component, event, helper);
                    if(resultString=='SUCCESS') {
                        var numbersArray = component.get("v.pageRange");
                        var action = component.get("c.createChildDoc");
                        action.setParams({"pgRange"		: component.get("v.newChildDocPgRange"),
                                          "ParentID"	: component.get("v.recordId"),
                                          "ParentPgNum"	: numbersArray.toString(),
                                          "pageCount"	: (numbersArray.length).toString()
                                         });
                        action.setCallback(this, function(a) {
                            if(a.getState() ==="SUCCESS") {
                                var modal = component.find("parentModalBox");
                                $A.util.removeClass(modal, 'slds-hide');
                                $A.util.addClass(modal, 'slds-show');

                                 var splitModal = component.find("addSplitModalBox");
                                 $A.util.removeClass(splitModal, 'slds-show');
                                 $A.util.addClass(splitModal, 'slds-hide');

                                component.set("v.newChildDocPgRange", "");
                                //component.set("v.isSplitbuttonActive", true);
                                component.set('v.showParentLabel',true);
                                helper.refreshCmp(component, event, helper);
                            } else if (a.getState() ==="ERROR"){
                                var errors = a.getError();
                                CH_PC_Util.showAllErrors(component.get("v.errorDocStatus"),errors);
                                console.log(JSON.stringify(errors));
                            }
                        });
                        $A.enqueueAction(action);
                    }
                    else if(resultString=='INCORRECT_INPUT'){
                        component.set("v.disableButton",false); //Reset the disabled button
                        component.find("pageRangeErrorSave").set("v.errors", [{message: component.get("v.errorMsg")}]);
                    }
                    else if(resultString=='INVALID_DATA'){
                        component.set("v.disableButton",false); //Reset the disabled button
                        component.find("pageRangeErrorSave").set("v.errors", [{message: component.get("v.invalidInputErrorMsg")}]);
                    }
                    event.preventDefault();
                },

        validatePageRange : function(component, event, helper) {
            var resultString='';
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

                    if(!checkInputSanity){
                        resultString='INCORRECT_INPUT';
                    }
                    else if(!(checkRange && checkPageCount && checkZeroInput)){
                        resultString='INVALID_DATA';
                    }
                    else{
                        resultString='SUCCESS';
                    }
                    return resultString;

                },

        checkAttachment: function(component,event){

            var action = component.get("c.checkDocHasAttachment");
            action.setParams({
                "docId": component.get("v.recordId")
            });
            action.setCallback(this, function(a) {
                if(a.getState() ==="SUCCESS") {
                    var hasAttachment=a.getReturnValue();
                    if(hasAttachment) {
                        component.set("v.hasAttachment", true);
                    }
                    else{
                        component.set("v.noAttachment", true);
                    }
                } else if (a.getState() ==="ERROR"){
                    var errors = a.getError();
                    CH_PC_Util.showAllErrors(component.get("v.errorDocStatus"),errors);
                    console.log(JSON.stringify(errors));
                }
            });
            $A.enqueueAction(action);

        }
})