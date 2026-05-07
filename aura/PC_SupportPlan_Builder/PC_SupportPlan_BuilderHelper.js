({
    saveSwap : function(component, event, helper, draggedItemId, droppedItemId){
        var action = component.get("c.saveSwap");

        action.setParams({
            "draggedItemId"	: draggedItemId,
            "droppedItemId"	: droppedItemId,
            "supportPlanId"	: component.get("v.supportPlan.Id")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var divDynamicChild  	= component.find("Inner");
        		var divDynamicChildBody		= [];
        		divDynamicChild.set("v.body", divDynamicChildBody);
                helper.refreshView(component, event, helper);
            }else if (state === "ERROR") {
                 var errors = response.getError();
                 CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            }else {
                  console.log("Unknown error");
            }
            var spinner = component.find("mySpinner");
            $A.util.addClass(spinner, 'slds-hide');
            $A.util.removeClass(spinner, 'slds-show');
        });
        $A.enqueueAction(action);
    },

    saveDropOnHead : function(component, event, helper, draggedItemId, headItemId){
        var action = component.get("c.saveDropOnHead");

        action.setParams({
            "draggedItemId"	: draggedItemId,
            "headItemId"	: headItemId,
            "supportPlanId"	: component.get("v.supportPlan.Id")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var divDynamicChild  	= component.find("Inner");
        		var divDynamicChildBody		= [];
        		divDynamicChild.set("v.body", divDynamicChildBody);
        		helper.refreshView(component, event, helper);
            }else if (state === "ERROR") {
                  var errors = response.getError();
                  CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            }else{
                console.log("Unknown error");
            }
            var spinner = component.find("mySpinner");
            $A.util.addClass(spinner, 'slds-hide');
            $A.util.removeClass(spinner, 'slds-show');
        });
        $A.enqueueAction(action);
    },

    setCurrentActivity : function(component, event, helper, nextActId, seqId, activityId){
        var divName = "Inner";
        var findListAct = nextActId;
        var offSet = 0;
        if($A.util.isEmpty(nextActId) && !$A.util.isEmpty(seqId) && !$A.util.isEmpty(activityId)){
            findListAct =   activityId;
            offSet = 1;
        }
        if(!$A.util.isEmpty(seqId)){
            divName =   seqId;
        }
     	var curAct	= component.find(nextActId);
        var divDynamicChild  	= component.find(divName);
        var divDynamicChildBody = divDynamicChild.get("v.body");
        var curActUiIndex		= divDynamicChildBody.indexOf(curAct);
        if(!$A.util.isEmpty(seqId)&& !$A.util.isEmpty(nextActId)){
            if(seqId == nextActId && curActUiIndex == "-1"){
                curActUiIndex = 2;
            }
        }else if($A.util.isEmpty(nextActId)){
            curActUiIndex =  divDynamicChildBody.length;
        }
        var curActListIndex;
        var activityListSorted	= component.get("v.activityListSorted");
        for(var i=0; i < activityListSorted.length; i++){
            if(activityListSorted[i].internalactivitynumber == findListAct){
                curActListIndex = i + offSet;
                break;
            }
        }
        component.set("v.clickedActivityUiIndex",curActUiIndex);
        component.set("v.clickedActivityListIndex",curActListIndex);
    },

    checkSeqCompletion : function(component, event, helper){
        var nextAct = event.currentTarget.getAttribute('data-nextActivityId');
        var prevAct = event.currentTarget.id;

        var prevActName;
        var nextActName;

        var nextActCondition;
        var prevActCondition;
        if(nextAct){
            nextActName = component.find(nextAct).get("v.HTMLAttributes").label;
            var divDynamicChild  	= component.find(nextAct);
            var divDynamicChildBody = divDynamicChild.get("v.body");
            nextActCondition = divDynamicChildBody.length;
        }
        if(prevAct){
            prevActName = component.find(prevAct).get("v.HTMLAttributes").label;
            var previousActivity  	= component.find(prevAct);
            var previousActivityBody = previousActivity.get("v.body");
            prevActCondition = previousActivityBody.length;
        }
        var title = component.get("v.warning");
        var type = "warning";
        var message;
        if(prevActCondition == 2){
            message = component.get("v.warningMessage") + prevActName;
            helper.showToast(title, type, message);
            return false;
        } else if (nextActCondition == 2){
            message = component.get("v.warningMessage") + nextActName;
            helper.showToast(title, type, message);
            return false;
        } else {
            return true;
        }
    },

    setAuraId : function(component, event, helper, activity, dragCounter){
        var auraId;
        if(activity.internalactivitynumber == ""){
         	auraId = activity.activityname;
        } else {
           	auraId =  activity.internalactivitynumber;
        }
        component.set("v.auraId",auraId);
    },

    refreshView : function (component, event, helper){
    	//var refresh = event.getParam("refresh");
        //component.set("v.refresh",refresh);
        component.set("v.activityPropertiesShown",false);
        var divDynamicChild  	= component.find("Inner");
        var divDynamicChildBody		= [];
        divDynamicChild.set("v.body", divDynamicChildBody);

        helper.setNamespace(component);
        helper.getActivities(component, event, helper);
        helper.hideActions(component, event, helper);

        var propertiesPanel			= component.find("propertiesPanel");
        var propertiesPanelBody		= [];
        propertiesPanel.set("v.body", propertiesPanelBody);
    },

    activation : function (component, event, helper){
        component.set("v.disableActivate",true);
        var planStatus;
        if(component.get("v.supportPlan.isactive") == true){
        	planStatus = false;
        } else {
           	planStatus = true;
        }
        var action = component.get("c.activationStatus");
        action.setParams({
            "planStatus"	: planStatus,
            "supportPlanId"	: component.get("v.supportPlan.Id")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var divDynamicChild  	= component.find("Inner");
        		var divDynamicChildBody		= [];
        		divDynamicChild.set("v.body", divDynamicChildBody);
        		var title   = component.get("v.success");
        		var type    = "success";
        		var message = component.get("v.activationMsg");
        		helper.refreshView(component, event, helper);
                helper.showToast(title, type, message);
                $(".rightPanel").removeClass("expanded");
        		$(".leftPanel").removeClass("contracted");
            }else if (state === "ERROR") {
                component.set("v.disableActivate",false);
                var errors = response.getError();
                CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            }else{
                component.set("v.disableActivate",false);
                console.log("Unknown error");
            }
        });
        $A.enqueueAction(action);
    },

    showToast : function(title, type, message) {
        var toastEvent  = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,

        });
        toastEvent.fire();
    },

    reInitiateAttributes : function (component, event, helper){
    	component.set("v.elementCount",1);
        component.set("v.addInProgress",false);
        component.set("v.addInProgressSeq",false);
        component.set("v.activityOpen",false);
        component.set("v.dragCounter",0);
        component.set("v.isDnDContext",false);
       	component.set("v.clickedActivityListIndex",null);
        component.set("v.clickedActivityUiIndex",null);
        component.set("v.internalActivity",false);
        component.set("v.unSavedActId",null);
    },

    hideActions : function(component, event, helper) {
		//$A.util.toggleClass(component.find("popoverBlock"), 'slds-hide');
		var element = component.find("popoverBlock").getElement();
		if(element.classList.contains("slds-show")) {
            element.classList.remove("slds-show");
            element.classList.add("slds-hide");
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

    getActivities : function (component, event, helper){
        var action = component.get("c.getActivities");

        action.setParams({
            "supportPlanId"		: component.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();

                helper.reInitiateAttributes(component, event, helper);
                component.set("v.activityContainer", returnValue.supportActivity);
                component.set("v.supportPlan", returnValue.supportPlan);

                if(component.get("v.counter")==true){
                            var startSign = component.find("startSign");
                            helper.createSign(component, startSign, "START", component.get("v.startSign"));
                            var stopSign = component.find("stopSign");
                            helper.createSign(component, stopSign, "STOP", component.get("v.stopSign"));
                            component.set("v.counter","false");
                        }
                helper.buildActivities(component, event, helper, true);
                helper.validateFieldSet(component, event, helper);
            }else if (state === "ERROR") {
               var errors = response.getError();
               CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            }else {
                console.log("Unknown error");
            }
            component.set("v.disableActivate",false);
        });
        $A.enqueueAction(action);
    },

    buildActivityHierarchy : function (component, event, helper){
        var activityList	= [];
        var activityMap     = new Map();
        var j				= 0;
        var counter			= 0;
        var supportPlan 	= component.get("v.supportPlan");

        var activity		= component.get("v.activityContainer");
        var	firstActivity	= supportPlan.initialactivity;
        var nextActKey;
        var nextSeqActKey;

        var nextAct;
        var nextSeqAct;
        var doWhileCounter = 0;
        var doWhileCounterLimit = (activity.length)-1;

        //Create Map
        for(var i=0; i < activity.length; i++){
            activityMap.set(activity[i].internalactivitynumber, activity[i]);
        }
        if(activityMap.size > 0){
            //Get The First Activity
            activityList.push(activityMap.get(firstActivity));
            do{
                if(activityList[j].internalactivitytype == 'User Task'){
                    nextAct = activityList[j].nextactivitynumber;
                }else if(activityList[j].internalactivitytype == 'Sequence'){
                    nextAct      = activityList[j].nextactivitynumber;
                    nextSeqAct   = activityList[j].initialsequenceactivity;
                }else if(activityList[j].internalactivitytype == 'Sequence Task'){
                    nextSeqAct   = activityList[j].nextactivitynumber;
                }
                if(!$A.util.isEmpty(nextSeqAct)){
                    j++;
                    activityList.push(activityMap.get(nextSeqAct));
                }else{
                    if(!$A.util.isEmpty(nextAct)){
                        j++;
                        activityList.push(activityMap.get(nextAct));
                    }
                }
                doWhileCounter++;
            }while(doWhileCounter < doWhileCounterLimit);
        }
        component.set("v.activityListSorted",activityList);
    },

    buildActivities : function (component, event, helper, buildHierarchy){
        if(buildHierarchy == true) {
        	helper.buildActivityHierarchy(component, event, helper);
        }
        var activityList = JSON.parse(JSON.stringify(component.get("v.activityListSorted")));
        var SeqName;
        var unSavedActId;
        for(var i=0; i< activityList.length; i++){
            if(activityList[i].internalactivitytype == "Sequence"){
                SeqName = Object.assign({},activityList[i]);
                helper.addActivity(component, event, helper, activityList[i], activityList[i].nextactivitynumber, null, activityList[i].initialsequenceactivity, null);

                if($A.util.isEmpty(activityList[i].initialsequenceactivity)){
                    var activity = {
                                            Id : component.get("v.defaultName")+" "+component.get("v.elementCount"),
                                            internalactivitynumber : component.get("v.defaultName")+" "+component.get("v.elementCount"),
                                            activityname : component.get("v.defaultName")+" "+component.get("v.elementCount"),
                                            activitytype : "User Task",
                                            internalactivitytype : "Sequence Task",
                                            nextactivitynumber : null,
                                            supportplan : component.get("v.supportPlan.Id"),
                                            referenceoffset : "0",
                                            groupactivityexecution : "",
                                            activitysequence : activityList[i].internalactivitynumber
                                    };
                    helper.addActivity(component, event, helper, activity, activity.nextactivitynumber, SeqName, null, i);
                    component.set("v.clickedActivityListIndex",null);
                    component.set("v.clickedActivityUiIndex",null);
                    unSavedActId = activity.internalactivitynumber;
                }
            } else if(activityList[i].internalactivitytype == "Sequence Task"){
                helper.addActivity(component, event, helper, activityList[i], activityList[i].nextactivitynumber, SeqName, null, null);
            } else{
                helper.addActivity(component, event, helper, activityList[i], activityList[i].nextactivitynumber, null, null,null);
            }
        }
        helper.bindFirstAct(component, event, helper);
        if(unSavedActId){
            component.set("v.addInProgress",true);
            helper.displayProperties(component, event, helper, unSavedActId);
        }
        return true;
    },

    createPlusIcon : function (component, event, helper){
        $A.createComponent(
            "lightning:buttonIcon",
                {
                    "aura:id": "IconPlus",
                    "iconName":"utility:add",
                    "size":"medium",
                    "class":"slds-text-align_center slds-show arrowIcon",
                    "onclick":component.getReference("c.onPlusClick")
                },
            function(newButton, status, errorMessage){
                if (status === "SUCCESS") {
                    var cmp = component.find("startSign");
                    var cmpBody = cmp.get("v.body");
                    cmpBody.push(newButton);
                    cmp.set("v.body",cmpBody);
                }
                else if (status === "INCOMPLETE"){
                    console.log("No response from server or client is offline.");
                }
                else if (status === "ERROR") {
                console.log("Error: " + errorMessage);
                }
            }
        );
    },

    createActivityIcon: function (component, event, helper, activity, nextActivity, initialSeqAct){
        var NullHeadActivity;
        $A.createComponents(
           [
               ["lightning:icon",
            {
                "aura:id": "Icon"+activity.activityname+component.get("v.elementCount"),
                "iconName":"utility:arrowdown",
                "size":"medium",
                "class":"slds-text-align_center slds-show arrowIcon activeIcon"

            }],
               [
                   "aura:html",{
                "body" : "",
                "tag"  : "div",
                "aura:id" : "IconDiv"+activity.activityname+component.get("v.elementCount"),
                "HTMLAttributes" :
                {
                    "id": activity.internalactivitynumber,
                    "class" : "iconDiv",
                    "label"		: activity.activityname,
                    "value"		: "IconDiv"+activity.activityname+component.get("v.elementCount"),
                    "data-region" : "arrowDiv",
                    "data-type" : "external",
                    "data-headActivityId"	: nextActivity == null ? NullHeadActivity : nextActivity,
                    "data-nextActivityId"	: nextActivity == null ? NullHeadActivity : nextActivity,
                    "ondragover" : component.getReference("c.allowDrop"),
                    "ondrop":	component.getReference("c.onArrowDrop"),
                    "ondragenter" : component.getReference("c.onDragEnter"),
                    "ondragleave" : component.getReference("c.onDragLeave"),
                    "opacity" : 0,
					"onclick" : component.getReference("c.onArrowClick"),

                } }
               ]
               ],
            function(cmps, status, errorMessage){
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    var clickedActivityUiIndex	= component.get("v.clickedActivityUiIndex");
                    var divDynamicChild     	= component.find("Inner");
                    var divDynamicChildBody 	= divDynamicChild.get("v.body");
                    var isDndContext = component.get("v.isDnDContext");
                    var divBody = cmps[1].get("v.body");
                    if(clickedActivityUiIndex != null && !isDndContext){
                        divBody.push(cmps[0]);
                        cmps[1].set("v.body",divBody);
                    	divDynamicChildBody.splice((clickedActivityUiIndex+1),0,cmps[1]);
                    }else {
                        divBody.push(cmps[0]);
                        cmps[1].set("v.body",divBody);
                        //divDynamicChildBody.push(divBody);
                        divDynamicChildBody.push(cmps[1]);
                    }
                    divDynamicChild.set("v.body", divDynamicChildBody);
                    if(activity.internalactivitytype == "Sequence"){
                        var sequence = activity;
                        component.set("v.seqId",component.get("v.auraId"));
                    	helper.createInternalActivityIcon(component, event, helper, activity, initialSeqAct, sequence);
                    }
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                    else if (status === "ERROR") {
                        console.log("Error: " + errorMessage);
                        // Show error message
                    }
            }
        );
    },

    createInternalActivityButton: function (component, event, helper, activity, nextActivity, sequence){
        helper.setAuraId(component, event, helper, activity,component.get("v.dragCounter"));
        var seqId = component.get("v.defaultNameSeq")+" "+component.get("v.elementCount");
        var createIcon = false;
        if(sequence.internalactivitynumber != ''){
        	seqId =	sequence.internalactivitynumber;
            createIcon = true;
        }
        $A.createComponent(
            // vijay - changed from lightning button to HTML
            "aura:html",{
                "body" : activity.activityname,
                "tag"  : "button",
                "label"		: activity.activityname,
                "aura:id" : component.get("v.auraId"),
                HTMLAttributes :
                {
                    "id": component.get("v.auraId"),
                    "class" : "activity activityInt",
                    "onclick" : component.getReference("c.displayProperties"),
                    "label"		: activity.activityname,
                    "value"		: component.get("v.auraId"),
                    "data-sid"	: activity.internalactivitynumber,
                    "data-seqId" 	: sequence.internalactivitynumber,
                    "data-type" : "internal",
                    "draggable"	: "true",
                    "ondragstart" : component.getReference("c.drag"),
                    "ondragover" : component.getReference("c.allowDrop"),
                    "ondragenter" : component.getReference("c.onDragEnter"),
                    "ondragleave" : component.getReference("c.onDragLeave"),
                    "ondrop":	component.getReference("c.onDrop")


                }
            },

            function(newButton, status, errorMessage){

                if (status === "SUCCESS") {
                    /*var body = component.get("v.graphElementRegion");
            body.push(newButton);
            component.set("v.graphElementRegion", body);*/
                    var clickedActivityUiIndex	= component.get("v.clickedActivityUiIndex");
                    var divDynamicChild     = component.find(seqId);
                    var divDynamicChildBody = divDynamicChild.get("v.body");
                    var isDndContext = component.get("v.isDnDContext");
                    if(clickedActivityUiIndex != null && !isDndContext){
                    	divDynamicChildBody.splice((clickedActivityUiIndex),0,newButton);
                    }else {
                     	divDynamicChildBody.push(newButton);
                    }
                    //divDynamicChildBody.push(newButton);
                    divDynamicChild.set("v.body", divDynamicChildBody);
                    if(createIcon){
                    helper.createInternalActivityIcon(component, event, helper, activity, nextActivity, sequence);
                    }
                    /*if(component.get("v.addInProgress")){
                        var activityId = component.get("v.auraId");
        				helper.setCurrentActivity(component, event, helper, activityId);
                    }*/
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                    else if (status === "ERROR") {
                        console.log("Error: " + errorMessage);
                        // Show error message
                    }
            }
        );
    },

    createInternalActivityIcon: function (component, event, helper, activity, nextActivity, sequence){
		var NullHeadActivity;
        var actId =	sequence.internalactivitynumber;
        $A.createComponents(
           [
               ["lightning:icon",
            {
                "aura:id": "InternalIcon"+activity.activityname+component.get("v.elementCount"),
                "iconName":"utility:arrowdown",
                "size":"medium",
                "class":"slds-text-align_center slds-show arrowIcon activeIcon"

            }],
               [
                   "aura:html",{
                "body" : "",
                "tag"  : "div",
                "aura:id" : "InternalIconDiv"+activity.activityname+component.get("v.elementCount"),
                "HTMLAttributes" :
                {
                    "id": activity.internalactivitynumber,
                    "class" : "iconDivInt",
                    "label"		: activity.activityname,
                    "value"		: "IconDiv"+activity.activityname+component.get("v.elementCount"),
                    "data-region" : "arrowDiv",
                    "data-headActivityId"	: nextActivity == null ? NullHeadActivity : nextActivity,
                    "data-nextActivityId"	: nextActivity == null ? NullHeadActivity : nextActivity,
                    "data-seqId" 	: sequence.internalactivitynumber,
                    "data-type" : "internal",
                    "ondragover" : component.getReference("c.allowDrop"),
                    "ondrop":	component.getReference("c.onArrowDrop"),
                    "ondragenter" : component.getReference("c.onDragEnter"),
                    "ondragleave" : component.getReference("c.onDragLeave"),
                    "opacity" : 0,
					"onclick" : component.getReference("c.onInternalArrowClick"),

                } }
               ]
               ],
            function(cmps, status, errorMessage){
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    var clickedActivityUiIndex	= component.get("v.clickedActivityUiIndex");
                    var divDynamicChild     	= component.find(actId);
                    var divDynamicChildBody 	= divDynamicChild.get("v.body");
                    var isDndContext = component.get("v.isDnDContext");
                    var divBody = cmps[1].get("v.body");
                    if(clickedActivityUiIndex != null && !isDndContext){
                        divBody.push(cmps[0]);
                        cmps[1].set("v.body",divBody);
                    	divDynamicChildBody.splice((clickedActivityUiIndex+1),0,cmps[1]);
                    }else {
                        divBody.push(cmps[0]);
                        cmps[1].set("v.body",divBody);
                        //divDynamicChildBody.push(divBody);
                        divDynamicChildBody.push(cmps[1]);
                    }

                    //var divBody = cmps[1].get("v.body");
                    //divBody.push(cmps[0]);
                    //cmps[1].set("v.body",divBody);
                    //divDynamicChildBody.push(divBody);
                    //divDynamicChildBody.push(cmps[1]);

                    divDynamicChild.set("v.body", divDynamicChildBody);

                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                    else if (status === "ERROR") {
                        console.log("Error: " + errorMessage);
                        // Show error message
                    }
            }
        );
    },

    createActivityButton: function (component, event, helper, activity, nextActivity, initialSeqAct){
        helper.setAuraId(component, event, helper, activity,component.get("v.dragCounter"));
        $A.createComponent(
            // vijay - changed from lightning button to HTML
            "aura:html",{
                "body" : activity.activityname,
                "tag"  : "button",
                "label"		: activity.activityname,
                "aura:id" : component.get("v.auraId"),
                HTMLAttributes :
                {
                    "id": component.get("v.auraId"),
                    "class" : "activity",
                    "onclick" : component.getReference("c.displayProperties"),
                    "label"		: activity.activityname,
                    "value"		: component.get("v.auraId"),
                    "data-sid"	: activity.internalactivitynumber,
                    "data-type" : "external",
                    "draggable"	: "true",
                    "ondragstart" : component.getReference("c.drag"),
                    "ondragover" : component.getReference("c.allowDrop"),
                    "ondragenter" : component.getReference("c.onDragEnter"),
                    "ondragleave" : component.getReference("c.onDragLeave"),
                    "ondrop":	component.getReference("c.onDrop")


                }
            },

            function(newButton, status, errorMessage){

                if (status === "SUCCESS") {
                    /*var body = component.get("v.graphElementRegion");
            body.push(newButton);
            component.set("v.graphElementRegion", body);*/
                    var clickedActivityUiIndex	= component.get("v.clickedActivityUiIndex");
                    var divDynamicChild     = component.find("Inner");
                    var divDynamicChildBody = divDynamicChild.get("v.body");
                    var isDndContext = component.get("v.isDnDContext");
                    if(clickedActivityUiIndex != null && !isDndContext){
                    	divDynamicChildBody.splice((clickedActivityUiIndex),0,newButton);
                    }else {
                     	divDynamicChildBody.push(newButton);
                    }
                    divDynamicChild.set("v.body", divDynamicChildBody);
                    helper.createActivityIcon(component, event, helper, activity, nextActivity, initialSeqAct);
                    /*if(component.get("v.addInProgress")){
                        var activityId = component.get("v.auraId");
        				helper.setCurrentActivity(component, event, helper, activityId);
                    }*/
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                    else if (status === "ERROR") {
                        console.log("Error: " + errorMessage);
                        // Show error message
                    }
            }
        );
    },

    bindFirstAct : function (component, event, helper){
        var actId;
        var actName;
        var NullHeadActivity;
        if(component.get("v.activityListSorted").length > 0){
            actId = component.get("v.activityListSorted")[0].internalactivitynumber;
            actName = component.get("v.activityListSorted")[0].activityname;
        	NullHeadActivity = component.get("v.activityListSorted")[0].internalactivitynumber;
        	//var NextAcvtivityId  = component.get("v.activityListSorted")[0].nextactivitynumber;
        	component.find("IconDivSTARTArrow").set("v.HTMLAttributes.id",actId);
        	component.find("IconDivSTARTArrow").set("v.HTMLAttributes.label",actName);
            component.find("IconDivSTARTArrow").set("v.HTMLAttributes.data-headActivityId",NullHeadActivity);
            component.find("IconDivSTARTArrow").set("v.HTMLAttributes.data-nextActivityId",actId);
        }else{
            actId = 'STARTHTML';
            actName = '';
            NullHeadActivity = '';
            var NextAcvtivityId = '';
            component.find("IconDivSTARTArrow").set("v.HTMLAttributes.id",actId);
            component.find("IconDivSTARTArrow").set("v.HTMLAttributes.label",actName);
            component.find("IconDivSTARTArrow").set("v.HTMLAttributes.data-headActivityId",NullHeadActivity);
            component.find("IconDivSTARTArrow").set("v.HTMLAttributes.data-nextActivityId",NextAcvtivityId);
        }
	},

    createSign : function(component, cmp, cmpType, cmpString) {
        var NullHeadActivity;
        $A.createComponents(
                [
                    ["lightning:icon",{
                        "aura:id": "Icon"+cmpType+component.get("v.elementCount"),
                        "iconName":"utility:arrowdown",
                        "size":"medium",
                        "class":"slds-text-align_center slds-show arrowIcon activeIcon"
                    }],

                    ["aura:html",{
                        "body" : "",
                        "tag"  : "div",
                        "aura:id" : "IconDiv"+cmpType+"Arrow",
                        "HTMLAttributes" :
                        {
                            "id": "STARTHTML",
                            "class" : "iconDiv",
                            "label"		: NullHeadActivity,
                            "value"		: "IconDiv"+cmpType+component.get("v.elementCount"),
                            "data-region" : "arrowDiv",
                            "data-type" : "external",
                            "data-headActivityId"	: NullHeadActivity,
                            "data-nextActivityId"	: NullHeadActivity,
                            "ondragover" : component.getReference("c.allowDrop"),
                            "ondrop":	component.getReference("c.onArrowDrop"),
                            "ondragenter" : component.getReference("c.onDragEnter"),
                            "ondragleave" : component.getReference("c.onDragLeave"),
                            "opacity" : 0,
                            "onclick" : component.getReference("c.onArrowClick"),

                        }
                    }],

                    ["aura:html",{
                         "body" : cmpString,
                         "tag"  : "div",
                         HTMLAttributes :
                            {
                                "id"    : cmpType,
                                "class" : "processStart",
                            }
                    }]
                ],
                    function(newSign, status, errorMessage){
                        //Add the new button to the body array
                        if (status === "SUCCESS") {
                            var cmpBody = cmp.get("v.body");
                            cmpBody.push(newSign[2]);
                                if(cmpType == "START"){
                                    var divBody = newSign[1].get("v.body");
                                    divBody.push(newSign[0]);
                                    newSign[1].set("v.body",divBody);
                                    cmpBody.push(newSign[1]);
                                }
                            cmp.set("v.body", cmpBody);
                        }
                        else if (status === "INCOMPLETE") {
                            console.log("No response from server or client is offline.")
                            // Show offline error
                        }
                            else if (status === "ERROR") {
                                console.log("Error: " + errorMessage);
                                // Show error message
                            }
                    }
                );

    },

    addActivity: function(component, event, helper, activity, nextActivity, sequence, initialSeqAct, sequenceIndex) {
        if(activity.internalactivitytype == "Sequence Task"){
            helper.createInternalActivityButton(component, event, helper, activity ,nextActivity, sequence);
        }else{
            helper.createActivityButton(component, event, helper, activity, nextActivity, initialSeqAct);
        }

        var addActivity 				= component.get("v.activityListSorted");
        var index;
        var clickedActivityListIndex	= component.get("v.clickedActivityListIndex");
        var isDnDContext = component.get("v.isDnDContext");
        if(clickedActivityListIndex != null && !isDnDContext){
        	index =  clickedActivityListIndex;
        }else {
            index = addActivity.length;
        }
        if(activity.internalactivitynumber.includes(component.get("v.defaultName")+" "+component.get("v.elementCount")) || activity.internalactivitynumber.includes(component.get("v.defaultNameSeq")+" "+component.get("v.elementCount"))){
            if(sequenceIndex != null){
                index = sequenceIndex+1;
            }
            addActivity.splice((index),0,activity);
            component.set("v.activityListSorted",addActivity);

        }
        var activityId;
        if(component.get("v.addInProgress")){
            activityId = component.get("v.auraId");
            if(component.get("v.unSavedActId")){
                activityId = component.get("v.unSavedActId");
            }
            helper.displayProperties(component, event, helper, activityId);
        }else if(component.get("v.addInProgressSeq")){
            activityId = component.get("v.seqId");
            helper.displayProperties(component, event, helper, activityId);
        }
        component.set("v.elementCount",component.get("v.elementCount")+1);
    },

 	displayProperties: function(component, event, helper, activityId) {
        if(component.get('v.errors').length>0){
                    component.set('v.fieldSetNotValid', true);
        }else{
            component.set("v.activityOpen",true);
            var cmpTarget 		= component.find(activityId);
            //vijay
            //var activityName	= cmpTarget.get("v.label");
            var activityName	= (cmpTarget.get("v.HTMLAttributes")).label;
            var prvCmpName 		= component.get("v.prvCmpName");
            var prvCmp			= component.find(prvCmpName);

            $A.util.removeClass(prvCmp, 'activitysel');
            $A.util.addClass(prvCmp, 'activity');

            $A.util.removeClass(cmpTarget, 'activity');
            $A.util.addClass(cmpTarget, 'activitysel');

            component.set("v.prvCmpName",activityId);

            var activity = {
                Id : activityId,
                internalactivitynumber : activityId,
                activityname : activityName,
                internalactivitytype : "User Task",
                supportplan : component.get("v.supportPlan.Id"),
                referenceoffset : "0",
                groupactivityexecution : "",
                activitysequence : ""
            }
            var activityList = component.get("v.activityListSorted");
            var isFirstAct = false;
            var marked = 'empty';
            for(var i=0; i< activityList.length; i++){
                if(activityList[0].internalactivitytype == 'Sequence' && activityList[0].groupactivityexecution == 'All at once'){
                    marked = activityList[0].internalactivitynumber;
                }
                if(activityList[i].internalactivitynumber == activityId){
                    activity = activityList[i];
                    component.set("v.supportPlanID",null);
                    if(i == 0){
                        component.set("v.supportPlanID",component.get("v.supportPlan.Id"));
                        if(activity.internalactivitytype == "User Task"){
                            isFirstAct = true;
                            break;
                        }
                    }else if((i == 1 || marked == activity.activitysequence) && activity.internalactivitytype == "Sequence Task"){
                       isFirstAct = true;
                       break;
                    }
                    break;
                }
            }
            helper.sendPreviousActivity(component, event, helper, activity, activityName);
            helper.createPropertiesPanel(component, event, helper, activity, isFirstAct);
            $(".rightPanel").addClass("expanded");
            $(".leftPanel").addClass("contracted");
            $(".deleteDisabled").hide();
            $(".deleteEnabled").show();
        }
	},

    sendPreviousActivity : function(component, event, helper, activity, activityName) {
        var activitySortedList = component.get("v.activityListSorted");
        var prevActivity;
        var nextActivity;
        var k = 0;
        for(var i=0; i< activitySortedList.length; i++){
            if(activitySortedList[i].internalactivitynumber == activity.internalactivitynumber){
                //First Activity
                if(i==0){
                    prevActivity;
                    if($A.util.isEmpty(activitySortedList[i].nextactivitynumber)){
                        if((activitySortedList[i].internalactivitytype == "User Task" || activitySortedList[i].internalactivitytype == "Sequence" )
                            && (i+1) != activitySortedList.length){
                            nextActivity = activitySortedList[i+1].internalactivitynumber;
                        }
                    }else{
                        nextActivity = activitySortedList[i].nextactivitynumber;
                    }
                }else if(activitySortedList[i].internalactivitytype == "User Task"){
                    if($A.util.isEmpty(activitySortedList[i].nextactivitynumber) && (i+1) != activitySortedList.length){
                        nextActivity = activitySortedList[i+1].internalactivitynumber;
                    } else {
                        nextActivity = activitySortedList[i].nextactivitynumber;
                    }
                    for(var j=(i-1); j>=0; j--){
                        if(activitySortedList[j].internalactivitytype == "User Task" || activitySortedList[j].internalactivitytype == "Sequence"){
                            prevActivity = activitySortedList[j].internalactivitynumber;
                            break;
                        }
                    }
                }else if(activitySortedList[i].internalactivitytype == "Sequence"){
                    if($A.util.isEmpty(activitySortedList[i].nextactivitynumber) && (i+1) != activitySortedList.length){
                            //for(var j=(i+1); j<activitySortedList.length; j++){
                                //if(activitySortedList[j].internalactivitytype == "User Task"){
                                    nextActivity = activitySortedList[i+1].internalactivitynumber;
                                    //break;
                                //}
                            //}
                    } else {
                        nextActivity = activitySortedList[i].nextactivitynumber;
                    }
                    for(var m=(i-1); m>=0; m--){
                        if(activitySortedList[m].internalactivitytype == "User Task" || activitySortedList[m].internalactivitytype == "Sequence"){
                            prevActivity = activitySortedList[m].internalactivitynumber;
                            break;
                        }
                    }
                }
                else if(activitySortedList[i].internalactivitytype == "Sequence Task"){
                    if($A.util.isEmpty(activitySortedList[i].nextactivitynumber) && (i+1) != activitySortedList.length){
                            //for(var j=(i+1); j<activitySortedList.length; j++){
                                if(activitySortedList[i+1].internalactivitytype == "Sequence Task"){
                                    nextActivity = activitySortedList[i+1].internalactivitynumber;
                                    //break;
                                }
                            //}
                    } else {
                        nextActivity = activitySortedList[i].nextactivitynumber;
                    }
                    for(var l=(i-1); l>=0; l--){
                        if(activitySortedList[l].internalactivitytype == "Sequence Task" || activitySortedList[l].internalactivitytype == "Sequence"){
                            prevActivity = activitySortedList[l].internalactivitynumber;
                            break;
                        }
                    }
                }
            }
        }
        if($A.util.isUndefinedOrNull(nextActivity)){
            nextActivity;
        }
        if($A.util.isUndefinedOrNull(prevActivity)){
            prevActivity ;
        }
        component.set("v.prevActivity", prevActivity);
        component.set("v.nextActivity", nextActivity);
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

    swap : function(component, event, helper, draggedItemId, droppedItemId) {
            helper.reOrder(component, event, helper, draggedItemId, droppedItemId);
       },

       resetAttributes : function(component, event, helper) {

                var blankBody;
                var cmps = component.find("Inner");
                for(var i=0; i<cmps.length;i++) {
                    console.log(cmps[i].toString());
                }
                component.find("Inner").set("v.body", []);
       },

       reorder : function(component, event, helper, draggedItemId, headActivityId) {
           var unsortedItems = component.get("v.activityListSorted");
           // NOTE - activityIdAbove and activityIdBelow are relative to the arrow.
           // let us try placing the dragged item above the activity having the id equal to activityIdBelow
           var destinationIndex;
           var currentIndex;
           var activityAtDestinationIndex;
           var activityAtCurrentIndex;
           for(var i=0; i<unsortedItems.length;i++) {
               if(unsortedItems[i].internalactivitynumber == headActivityId) {
                   destinationIndex = i;
                   continue;
               }

               if(unsortedItems[i].internalactivitynumber == draggedItemId) {
                   currentIndex = i;
               }
           }
           var newActivityAtDestinationIndex = Object.assign({},unsortedItems[currentIndex]);
           //unsortedItems.push
           //unsortedItems.splice(currentIndex,1);
           var reorderedItems = [];
           for(var k=0; k<unsortedItems.length; k++) {
               if(k == currentIndex) {
                   continue;
               }
               if(k == destinationIndex) {
                   reorderedItems.push(newActivityAtDestinationIndex);
               }
               reorderedItems.push(Object.assign({},unsortedItems[k]));

           }

           component.set("v.activityListSorted", reorderedItems);
            helper.resetAttributes(component, event, helper);
            for(var j=0; j<reorderedItems.length;j++) {
            	console.log(reorderedItems[j].internalactivitynumber);
            }
            helper.buildActivities(component, event, helper,false);
       },

	createPropertiesPanel : function (component, event, helper, activity, isFirstAct){
	    component.set("v.activityPropertiesShown",true);
        var activityProperty = component.get("v.namespace")+":"+"PC_SupportPlan_ActivityProperties";
        /*console.log("Activity"+JSON.stringify(activity));
        console.log("Prev"+component.get("v.prevActivity"));
        console.log("Next"+component.get("v.nextActivity"));
        console.log("Sp ID"+component.get("v.supportPlanID"));
        console.log("Sorted"+JSON.stringify(component.get("v.activityListSorted")));
        console.log(isFirstAct);*/
        var fieldSet = '';
        if(component.get("v.supportPlan.triggerEventObjectApiName") == 'Case'){
            fieldSet =  component.get("v.fieldSet");
        }else{
            fieldSet =  component.get("v.fieldSetForNonCaseObjects");
        }
        $A.createComponent(
            activityProperty,
                {
                    "aura:id"		    : "PC_SupportPlan_ActivityProperties",
                    "supportPlanID"     : component.get("v.supportPlanID"),
                    "activity" 		    : activity,
                    "prevActivity"	    : component.get("v.prevActivity"),
                    "nextActivity"	    : component.get("v.nextActivity"),
                    "disabled"		    : component.get("v.supportPlan.isactive"),
                    "fieldSet"          : fieldSet,
                    "recordId"          : component.get("v.supportPlan.Id"),
                    "isFirstAct"        : isFirstAct,
                    "triggerEventObjectLabel"  : component.get("v.supportPlan.triggerEventObjectLabel"),
                    "triggerEventObjectApiName": component.get("v.supportPlan.triggerEventObjectApiName"),

                },

                 function(newCmp, status, errorMessage){
                            //Add the new button to the body array
                            if (status === "SUCCESS") {
                                //component.set("v.propertiesPanel", newCmp);
                                var propertiesPanel		= component.find("propertiesPanel");
                                var propertiesPanelBody		= [];
                                propertiesPanelBody.push(newCmp);
                                propertiesPanel.set("v.body",propertiesPanelBody);
                            }
                            else if (status === "INCOMPLETE") {
                                console.log("No response from server or client is offline.")
                                // Show offline error
                            }
                                else if (status === "ERROR") {
                                    console.log("Error: " + errorMessage);
                                    // Show error message
                                }
                        }
                    );
    },

    validateFieldSet : function(component, event, helper){
        var fieldSet = '';
            if(component.get("v.supportPlan.triggerEventObjectApiName") == 'Case'){
                fieldSet =  component.get("v.fieldSet");
            }else{
                fieldSet =  component.get("v.fieldSetForNonCaseObjects");
            }
            var action = component.get("c.isValidFieldSet");
            action.setParams({
                "objectTypeName"  : 'Task',
                "fieldSetName"    : fieldSet,
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS") {
                    return;
                } else {
                    var err = [component.get('v._label6')];
                    component.set('v.errors',err);
                    console.log("Failed with state: " + state);
                }
            });
            $A.enqueueAction(action);
    },

    showClone : function(component, event, helper){
        var supportPlanClone = component.get("v.namespace")+":"+"PC_SupportPlan_Clone";
        $A.createComponent(
            supportPlanClone,
                {
                    "aura:id"   : "PC_SupportPlan_Clone",
                    "recordId"  : component.get("v.recordId"),
                    "SPName"    : component.get("v.supportPlan.supportplanname"),
                },

                 function(newCmp, status, errorMessage){
                            //Add the new button to the body array
                            if (status === "SUCCESS") {
                                var cloneSP		    = component.find("cloneSP");
                                var cloneSPBody = [];
                                cloneSPBody.push(newCmp);
                                cloneSP.set("v.body",cloneSPBody);
                            }
                            else if (status === "INCOMPLETE") {
                                console.log("No response from server or client is offline.")
                                // Show offline error
                            }
                                else if (status === "ERROR") {
                                    console.log("Error: " + errorMessage);
                                    // Show error message
                                }
                        }
                    );
    }
})