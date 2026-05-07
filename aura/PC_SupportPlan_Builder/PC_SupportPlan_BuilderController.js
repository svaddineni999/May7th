/**
* Created by vkashikar on 2/8/2018.
*/
({
    afterScriptsLoaded : function(component, event, helper) {
    },

    doInit : function(component, event, helper) {
        helper.setNamespace(component);
        helper.getActivities(component, event, helper);
    },

    refreshView : function(component, event, helper) {
        helper.refreshView(component, event, helper);
    },

    showClone : function(component, event, helper) {
        helper.showClone(component, event, helper);
    },

    editSP : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : component.get("v.namespace")+":"+"PC_Custom_Support_Plan",
            componentAttributes: {
                recordId : component.get("v.supportPlan.Id")
            }
        });
        evt.fire();
    },

    drag: function (component, event, helper) {
    	event.dataTransfer.setData("text", event.target.getAttribute('data-sid'));
    	event.dataTransfer.setData("type", event.target.getAttribute('data-type'));
    	event.dataTransfer.setData("seqId", event.target.getAttribute('data-seqId'));
        if(component.get("v.addInProgress") || component.get("v.activityOpen") || component.get("v.supportPlan.isactive")){
        	event.dataTransfer.dropEffect = "none";
            event.dataTransfer.effectAllowed = "none";
        }
	},

	onInternalArrowClick : function (component, event, helper){
	    event.preventDefault();
	    event.stopPropagation();
	    if(component.get("v.addInProgress") == true || component.get("v.addInProgressSeq") == true){
            return;
        }
        component.set("v.internalActivity",true);
        var activityId  = event.currentTarget.id;
        var nextActId = event.currentTarget.getAttribute('data-nextActivityId');
        var sequenceId = event.currentTarget.getAttribute('data-seqId');
        component.set("v.clickedSeqId",sequenceId);
        helper.setCurrentActivity(component, event, helper, nextActId, sequenceId, activityId);

        var x = event.clientX;
        var y = event.clientY;

        var scrollTop = document.getElementById("leftPanelScrollable").scrollTop;
        var element = component.find("popoverBlock").getElement();

        element.style.left = (x-78) + "px";
        element.style.top = (y-255) + scrollTop + "px";
        element.style.position = "absolute";
        if(element.classList.contains("slds-hide")  && component.get("v.supportPlan.isactive") == false) {
            element.classList.remove("slds-hide");
            element.classList.add("slds-show");
        }
        var addAct = component.find("addAct").getElement();
        var addSeq = component.find("addSeq").getElement();
        addAct.classList.remove("slds-size_1-of-2");
        addAct.classList.add("slds-size_1-of-1");
        //element.classList.remove("slds-popover");
        element.classList.add("slds-popover-small");
        addSeq.classList.add("slds-hide");

    },

	onArrowClick: function (component, event, helper) {
        event.stopPropagation();
        component.set("v.internalActivity",false);
        if(component.get("v.addInProgress") == true || component.get("v.addInProgressSeq") == true){
            return;
        }
        var seqId       = event.currentTarget.getAttribute('data-seqId');
        var nextActId	= event.currentTarget.getAttribute('data-nextActivityId');
        /*var checkSeq = helper.checkSeqCompletion(component, event, helper);
        if(!checkSeq){
            return;
        }*/
        helper.setCurrentActivity(component, event, helper, nextActId, seqId, null);
        var x = event.clientX;
        var y = event.clientY;

        var scrollTop = document.getElementById("leftPanelScrollable").scrollTop;
        var element = component.find("popoverBlock").getElement();

        element.style.left = (x-148) + "px";
        element.style.top = (y-255) + scrollTop + "px";
        element.style.position = "absolute";
        if(element.classList.contains("slds-hide") && component.get("v.supportPlan.isactive") == false) {
            element.classList.remove("slds-hide");
            element.classList.add("slds-show");
        }

        var addAct = component.find("addAct").getElement();
        var addSeq = component.find("addSeq").getElement();
            if(addSeq.classList.contains("slds-hide")){
                    addAct.classList.remove("slds-size_1-of-1");
                    addAct.classList.add("slds-size_1-of-2");
                    addSeq.classList.remove("slds-hide");
                    element.classList.remove("slds-popover-small");
                    element.classList.add("slds-popover");
            }
    },
    
    hideActions : function(component, event, helper) {
        helper.hideActions(component, event, helper);
	},

    allowDrop: function (component, event, helper) {
    	 event.preventDefault();
	},

    onDrop : function (component, event, helper) {
    	event.preventDefault();
    	event.stopPropagation();
    	var dropType = event.target.getAttribute('data-type');
    	var dragType = event.dataTransfer.getData("type");

    	var dropSeqId = event.target.getAttribute('data-seqId');
        var dragSeqId = event.dataTransfer.getData("seqId");
        if(dropType == "external" || dragType == "external"){
            if(dropType == dragType){
                //do nothing and continue;
            } else{
                return;
            }
        } else if(dropType == "internal" || dragType == "internal"){
            if(dropType == dragType && dropSeqId == dragSeqId){
                //do nothing and continue;
            } else{
                return;
            }
        }
        event.currentTarget.classList.toggle("highlightDragRegion");
        var draggedItemId = event.dataTransfer.getData("text");
        var droppedItemId = event.target.getAttribute('data-sid');
        if(draggedItemId == droppedItemId) {
            // do nothing
        }
        else if(component.get("v.addInProgress")) {
            // do nothing
        }
        else {
        	component.set("v.isDnDContext",true);
            var dragCounter = component.get("v.dragCounter");
            component.set("v.dragCounter",dragCounter+1);

            var spinner = component.find("mySpinner");
            $A.util.removeClass(spinner, 'slds-hide');
            $A.util.addClass(spinner, 'slds-show');
            helper.saveSwap(component, event, helper, draggedItemId, droppedItemId);
            component.set("v.isDnDContext",false);
        }
	},

    onArrowDrop : function (component, event, helper) {
        event.preventDefault();
        event.currentTarget.classList.toggle("highlightDragRegion");
        event.stopPropagation();
    	var dropType = event.target.getAttribute('data-type');
    	var dragType = event.dataTransfer.getData("type");

    	var dropSeqId = event.target.getAttribute('data-seqId');
        var dragSeqId = event.dataTransfer.getData("seqId");
        if(dropType == "external" || dragType == "external"){
            if(dropType == dragType){
                //do nothing and continue;
            } else{
                return;
            }
        } else if(dropType == "internal" || dragType == "internal"){
            if(dropType == dragType && dropSeqId == dragSeqId){
                //do nothing and continue;
            } else{
                return;
            }
        }
        var draggedItemId = event.dataTransfer.getData("text");
        var headActivityId = event.currentTarget.getAttribute('data-headActivityId');
        var droppedItemId;
        if(draggedItemId == headActivityId) {
            // do nothing
        }
        else if(component.get("v.addInProgress")) {
            // do nothing
        }
        else {
        	component.set("v.isDnDContext",true);
            var dragCounter = component.get("v.dragCounter");
            component.set("v.dragCounter",dragCounter+1);

            var spinner = component.find("mySpinner");
            $A.util.removeClass(spinner, 'slds-hide');
            $A.util.addClass(spinner, 'slds-show');
            helper.saveDropOnHead(component, event, helper, draggedItemId, headActivityId);
            component.set("v.isDnDContext",false);
        }
	},

    onDragEnter : function(component, event, helper) {
        event.preventDefault();
        event.currentTarget.classList.toggle("highlightDragRegion");
    },

    onDragLeave : function(component, event, helper) {
        event.preventDefault();
        event.currentTarget.classList.toggle("highlightDragRegion");
    },
    
    activation : function(component, event, helper) {
        helper.activation(component, event, helper);
    },

    addElement : function(component, event, helper) {
        var activity;
        var nextActivity = null;
        var sequence = null;
        var initialSeqAct = null;
        if(component.get("v.internalActivity")){
            if(component.get("v.addInProgress") == true){
                return;
            }
            component.set("v.addInProgress",true);
            activity = {
                            Id : component.get("v.defaultName")+" "+component.get("v.elementCount"),
                            internalactivitynumber : component.get("v.defaultName")+" "+component.get("v.elementCount"),
                            activityname : component.get("v.defaultName")+" "+component.get("v.elementCount"),
                            activitytype : "User Task",
                            internalactivitytype : "Sequence Task",
                            nextactivitynumber : "",
                            supportplan : component.get("v.supportPlan.Id"),
                            referenceoffset : "0",
                            groupactivityexecution : "",
                            activitysequence : component.get("v.clickedSeqId")
                        };
            sequence = {
                        Id : component.get("v.clickedSeqId"),
                        internalactivitynumber : component.get("v.clickedSeqId"),
                        groupactivityexecution : "",
                        activitysequence : ""
                    };
            helper.addActivity(component, event, helper, activity, nextActivity, sequence, initialSeqAct, null);
        } else{
            if(component.get("v.addInProgressSeq") == true){
                return;
            }
            component.set("v.addInProgress",true);
            activity = {
                Id : component.get("v.defaultName")+" "+component.get("v.elementCount"),
                internalactivitynumber : component.get("v.defaultName")+" "+component.get("v.elementCount"),
                activityname : component.get("v.defaultName")+" "+component.get("v.elementCount"),
                activitytype : "User Task",
                internalactivitytype : "User Task",
                nextactivitynumber : "",
                supportplan : component.get("v.supportPlan.Id"),
                referenceoffset : "0",
                groupactivityexecution : "",
                activitysequence : ""
            };
            helper.addActivity(component, event, helper, activity, nextActivity, sequence, initialSeqAct, null);
        }
        helper.hideActions(component, event, helper);
    },
    
    addSequence : function(component, event, helper) {
        var nextActivity = null;
        var sequence = null;
        var initialSeqAct = null;
        if(component.get("v.addInProgress") == true || component.get("v.addInProgressSeq") == true){
            return;
        }

		component.set("v.addInProgressSeq",true);

        var activity = {
            Id : component.get("v.defaultNameSeq")+" "+component.get("v.elementCount"),
            internalactivitynumber : component.get("v.defaultNameSeq")+" "+component.get("v.elementCount"),
            activityname : component.get("v.defaultNameSeq")+" "+component.get("v.elementCount"),
            activitytype : "",
            internalactivitytype : "Sequence",
            nextactivitynumber : "",
            supportplan : component.get("v.supportPlan.Id"),
            referenceoffset : "0",
            groupactivityexecution : "",
            activitysequence : ""
        };

        helper.addActivity(component, event, helper, activity, nextActivity, sequence, initialSeqAct, null);
        helper.hideActions(component, event, helper);
    },

    displayProperties : function(component, event, helper){
        var activityId  = event.target.id;
        var seqId       = event.target.getAttribute('data-seqId');
        helper.setCurrentActivity(component, event, helper, activityId, seqId, null);
        helper.displayProperties(component, event, helper, activityId);
        helper.hideActions(component, event, helper);
    },
    
    displayPropertiesHTML : function(component, event, helper){
        var activityName	= event.currentTarget.id;
        helper.displayProperties(component, event, helper, activityName);
    },

    //[PC-2720] List view of all Support Plans
    gotoList : function (component, event, helper) {
        var scope = component.get("v.namespacePrefix")+"PC_SupportPlan__c";
        var action = component.get("c.getListView");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var listviews = response.getReturnValue();
                var navEvent = $A.get("e.force:navigateToList");
                navEvent.setParams({
                    "listViewId": listviews.Id,
                    "listViewName": null,
                    "scope": scope
                });
                navEvent.fire();
            }
        });
        $A.enqueueAction(action);
    }
    
})