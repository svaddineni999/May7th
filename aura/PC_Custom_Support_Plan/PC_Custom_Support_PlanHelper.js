/**
 * Created by havalakki on 10/11/2018.
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

    validateRequired: function(component){
        this.clearErrorMessage(component, ['spname']);
		var requiredFieldErrorMessage = component.get("v.requiredFieldErrorMessage");
        console.log('requiredFieldErrorMessage::::'+requiredFieldErrorMessage);
		component.set("v.isValid", true);
		console.log('isValid::::'+component.get("v.isValid"));
		var isSupportPlanNameValid = true;
		if($A.util.isEmpty(component.find("spname").get("v.value"))){
			isSupportPlanNameValid = false;
			component.find("spname").set("v.errors", [{message:requiredFieldErrorMessage}]);
			console.log('isSupportPlanNameValid::::'+isSupportPlanNameValid);
		}

		var triggerEventCmp = component.find('triggerEventComponent');
        console.log('triggerEventCmp::::'+triggerEventCmp);
        var isTriggerEventFieldsValid = triggerEventCmp.validate();
        console.log('isTriggerEventFieldsValid::::'+isTriggerEventFieldsValid);
        if(!isSupportPlanNameValid || !isTriggerEventFieldsValid){
            component.set('v.isValid',false);
        }
        var constantsWrapper = component.get("v.constantsWrapper");
        var setCondition = component.find("setCondition").get("v.value");;
        if(setCondition == constantsWrapper.condOptionApex && $A.util.isEmpty(component.find("className").get("v.value"))){
            component.set("v.isValid", false);
            component.find("className").set("v.errors", [{message:requiredFieldErrorMessage}]);
        }
	},

    clearErrorMessage : function (component, fieldArray){
		for (var i = 0; i < fieldArray.length; i++){
			var inputCmp = component.find(fieldArray[i]);
			inputCmp.set("v.errors", null);
		}
		//var triggerEventCmp = component.find('triggerEventComponent');
		//triggerEventCmp.set("v.triggerEventObjectError", null);
		//triggerEventCmp.set("v.triggerEventTypeError", null);
	},
	/*showSupportPlanConditionBuilder: function(component, event, helper){
		var conditionalBuilder = component.find("conditionalBuilder");
		$A.util.removeClass(conditionalBuilder,'slds-show');
		$A.util.addClass(conditionalBuilder,'slds-hide');
		var recordType = component.get('v.spTriggerEventObject');
		helper.cacheConditions(component, event, helper);
		var cachedConditionsMap = component.get('v.cachedConditionsMap');
		if(cachedConditionsMap!=null && cachedConditionsMap[recordType]!=null){
		component.set('v.conBldrLogic', JSON.stringify(cachedConditionsMap[recordType]));
		helper.displayConditions(component, event, helper);
		var conditionalBuilderCmp = component.find("conditionalBuilder");
		component.set('v.initiateCondition', false);
		$A.util.removeClass(conditionalBuilderCmp,'slds-hide');
		$A.util.addClass(conditionalBuilderCmp,'slds-show');
		component.set('v.isAddRow', true);
		}else{
			component.set('v.recordType',recordType);
			component.set('v.isAddRow', false);
			if(recordType !='None'){
				component.set('v.isAddRow', true);
			}
		}
	},

    cacheConditions : function(component, event, helper){
		component.set('v.prevRecordType', component.get('v.tempRecordType'));
		component.set('v.tempRecordType', component.get('v.spTriggerEventObject'));
		var prevRecordType = component.get('v.prevRecordType');
		if(component.get('v.cachedConditionsMap')==null){
			if(prevRecordType!='None' && prevRecordType!=''){
			  var activityConditions = helper.conditionsToSave(component, event, helper);
			  var cachedConditionsMap = {[prevRecordType]:activityConditions};
			  component.set('v.cachedConditionsMap', cachedConditionsMap);
			}
		} else{
			if(prevRecordType!='None' && prevRecordType!=''){
                 var conditions = helper.conditionsToSave(component, event, helper);
                 var conditionsMap = component.get('v.cachedConditionsMap');
                 conditionsMap[prevRecordType]=conditions;
                 component.set('v.cachedConditionsMap', conditionsMap);
			}
		}
    },*/
    getFieldLabels : function(component, event, helper){
		var action = component.get("c.getConditionFieldLabels");
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
				var returnValue = response.getReturnValue();
				component.set("v.fieldLabels", returnValue);
				helper.populatePicklistFields(component,event, helper);
			} else {
				console.log("Failed with state: " + state);
				var errors = response.getError();
                if(!$A.util.isEmpty(errors) && errors.length > 0) {
                    var message = errors[0].message;
                    component.set("v.spErrors", message);
                }
			}
		});
		$A.enqueueAction(action);
	},

    getPicklistEntryMap : function(component, helper){
		var action = component.get("c.getPicklistEntryMap");
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
				var returnValue = response.getReturnValue();
				component.set("v.picklistEntryMap", returnValue);
				console.log("returnValue");
				console.log(returnValue);
				console.log("picklistEntryMap");
				console.log(component.get("v.picklistEntryMap"));
				component.set("v.unAlteredpicklistEntryMap", returnValue);
				component.set("v.spPicklistTriggerEventMap", returnValue);

				//this.populateReferenceTypePickLists(component,event);
				//this.changeReferenceTypePicklist(component,event);

				this.populateCondOptionPickLists(component,event);
				this.changeConditionOptionPickList(component,event, helper);

			} else {
				console.log("Failed with state: " + state);
                var errors = response.getError();
                if(!$A.util.isEmpty(errors) && errors.length > 0) {
                    var message = errors[0].message;
                    component.set("v.spErrors", message);
                }
			}
		});
		$A.enqueueAction(action);
	},

	populatePicklistFields: function(component, event, helper){
		component.find('behaviorList').set('v.value',component.get('v.supportPlan.conditionbehavior'));
		component.find('setCondition').set('v.value',component.get('v.supportPlan.conditionoption'));
	},

    populateCondOptionPickLists: function(component,event){
		var allPickListMap=component.get('v.unAlteredpicklistEntryMap');

		var pickListEntryMapKey='setCondition';

		var constantsWrapper=component.get('v.constantsWrapper');

		var valueOne='';
		var valueTwo=constantsWrapper.condOptionApex;
		var valueThree=constantsWrapper.condOptionCondBuilder;

		var conditionOptionPickListOne='v.conditionOptionPickListOne';
		var conditionOptionPickListTwo='v.conditionOptionPickListTwo';
		var conditionOptionPickListThree='v.conditionOptionPickListThree';

		var specificPickList=allPickListMap[pickListEntryMapKey];

		var pickListOne=[];
		var pickListTwo=[];
		var pickListThree=[];

		for(var i=0;i<specificPickList.length;i++){
			var pickListObj=specificPickList[i];

			if(valueOne==pickListObj.value) {
			  pickListOne.push(pickListObj);

			}
			if(valueTwo==pickListObj.value) {
			  pickListTwo.push(pickListObj);

			}
			if(valueThree==pickListObj.value) {
				pickListThree.push(pickListObj);
			}
		}

		component.set(conditionOptionPickListOne,pickListOne);
		component.set(conditionOptionPickListTwo,pickListTwo);
		component.set(conditionOptionPickListThree,pickListThree);
	},

    changeConditionOptionPickList:  function(component, event, helper){
		var constantsWrapper=component.get('v.constantsWrapper');

		var activityObj=component.get('v.supportPlan');
		var allPickListMap=component.get('v.unAlteredpicklistEntryMap');
		if(null!=activityObj.conditionbehavior&&(constantsWrapper.condBehavNoCond==activityObj.conditionbehavior||undefined==activityObj.conditionbehavior)){
		   allPickListMap['setCondition']= component.get('v.conditionOptionPickListOne');
		}
		else if((null!=activityObj.conditionbehavior)
							  &&!(constantsWrapper.condBehavNoCond==activityObj.conditionbehavior)){
		  allPickListMap['setCondition']= component.get('v.conditionOptionPickListTwo').concat
										  (component.get('v.conditionOptionPickListThree'));
		}
		component.set('v.picklistEntryMap',allPickListMap);
		helper.showCondition(component, event, helper);
	},

    getConstantsValuesMap: function(component, event,helper){
		var action=component.get('c.getConstantsWrapper');

		action.setCallback(this,function(response){
			var state=response.getState();
			if('SUCCESS'==state){
				var constantsWrapper=response.getReturnValue();
				component.set('v.constantsWrapper',constantsWrapper);

			}else {
                var errors = response.getError();
                if(!$A.util.isEmpty(errors) && errors.length > 0) {
                    var message = errors[0].message;
                    component.set("v.spErrors", message);
                }
            }

		});
		$A.enqueueAction(action);
	},

    showCondition : function(component, event, helper){
		var constantsWrapper=component.get('v.constantsWrapper');
		var setCondition = component.find("setCondition").get("v.value");
	    var apexClass = component.find("apexClass");
		if(constantsWrapper.condBehavNoCond == component.find('behaviorList').get('v.value')
		    || setCondition == constantsWrapper.condOptionCondBuilder || (component.get('v.initiateCondition') &&
                          		component.get('v.supportPlan.conditionoption') == constantsWrapper.condOptionCondBuilder && setCondition == component.get('v.supportPlan.conditionoption'))){
            $A.util.removeClass(apexClass,'slds-show');
            $A.util.addClass(apexClass,'slds-hide');
        }else if(setCondition == constantsWrapper.condOptionApex ||
				 component.get('v.supportPlan.conditionoption') == constantsWrapper.condOptionApex){
			$A.util.addClass(apexClass,'slds-show');
			$A.util.removeClass(apexClass,'slds-hide');
		}else {
			$A.util.addClass(apexClass,'slds-hide');
			$A.util.removeClass(apexClass,'slds-show');
		}
	},

    displayConditions : function(component, event, helper){
        var activityConditions = JSON.parse(component.get('v.conBldrLogic'));
        var recordConditionsList = activityConditions.LstConditionsPerObject;
        component.set("v.recordConditions",recordConditionsList);
        var recordConditions = recordConditionsList[0];
        var objectType = recordConditions.ObjectType;
        component.set('v.spTriggerEventObject', objectType);
	},

    conditionsToSave : function(component, event, helper){
        var conditionalBuilder = component.find("ruleInfoConditions");
        var conditionsJSON = [];
        if(typeof conditionalBuilder != 'undefined'){
            conditionsJSON = conditionalBuilder.getBuilderJSONToSave();
        }
        return conditionsJSON;
	},

    changeConditionOption:  function(component, event, helper){
        var triggerEventCmp = component.find('triggerEventComponent');
        var isTriggerEventObjectValid = triggerEventCmp.doValidationOnTriggerEventObject();
        if(isTriggerEventObjectValid){
            var selectedConditionBehav=component.find('behaviorList').get('v.value');
            var constantsWrapper=component.get('v.constantsWrapper');
            var allPickListMap=component.get('v.unAlteredpicklistEntryMap');
            if((null!=selectedConditionBehav)&&(constantsWrapper.condBehavNoCond==selectedConditionBehav)){
                allPickListMap['setCondition']= component.get('v.conditionOptionPickListOne');
            }else if((null!=selectedConditionBehav)&&!(constantsWrapper.condBehavNoCond==selectedConditionBehav)){
                var tempPickList = component.get('v.conditionOptionPickListTwo').concat
                             (component.get('v.conditionOptionPickListThree'));
                allPickListMap['setCondition']= tempPickList;
            }
            var pickList=allPickListMap['setCondition'];
            component.find('setCondition').set('v.value', pickList[0].value);
            component.set('v.picklistEntryMap.setCondition',pickList);
            helper.showCondition(component, event, helper);
        } else {
            var pickListEntryMap = component.get('v.unAlteredpicklistEntryMap');
            var behaviorListPicklistValue = pickListEntryMap['behaviorList'];
            component.set('v.picklistEntryMap.behaviorList',pickListEntryMap['behaviorList']);
            component.find('behaviorList').set('v.value', behaviorListPicklistValue[0].value);
        }
    },

    hideModal : function(component, event, helper) {
        helper.hidePopupHelper(component, 'modaldialog', 'slds-fade-in-');
        helper.hidePopupHelper(component, 'backdrop', 'slds-backdrop--');
        event.preventDefault();
        helper.navigateToListView(component, event, helper);
        return false;
    },

    hidePopupHelper: function(component, componentId, className){
        var modal = component.find(componentId);
        $A.util.addClass(modal, className+'hide');
        $A.util.removeClass(modal, className+'open');
    },

	navigateToListView: function(component, componentId, className){
		var recordId = component.get("v.recordId");
		if($A.util.isEmpty(recordId)){
		var navEvt = $A.get("e.force:navigateToList");
			navEvt.setParams({
			"scope": component.get("v.namespacePrefix")+"PC_SupportPlan__c"
			});
			navEvt.fire();
		}else{
			var navigateEvent = $A.get("e.force:navigateToSObject");
			navigateEvent.setParams({
				"recordId": recordId,
				"slideDevName": "detail"
			});
			navigateEvent.fire();
		}
	},
	getAllInformation: function(component, event, helper){
    	var action= component.get("c.fetchInformation");
    	var recordID=component.get('v.recordId');
    	action.setParams({
    		"recordId": recordID
    	});
    	action.setCallback(this,function(response){
    		console.log('StateinAllInformation::::'+response.getState());
    		if(response.getState()=='SUCCESS'){
    			var infoResponse=response.getReturnValue();
    			component.set('v.supportPlan', infoResponse[0].baseSupportPlan);
    			component.set('v.constantsWrapper', infoResponse[0].constantsWrapper);
    			component.set('v.picklistEntryMap', infoResponse[0].picklistEntryWrapperMap);
    			component.set('v.unAlteredpicklistEntryMap', infoResponse[0].picklistEntryWrapperMap);
    			component.set('v.fieldLabels', infoResponse[0].fieldLabelsWrapper);
    			this.populateCondOptionPickLists(component,event);
    			this.changeConditionOptionPickList(component,event, helper);
    			component.set('v.disabled', component.get('v.supportPlan.isactive'));
                if((component.get('v.recordId') != null && component.get('v.recordId') != '') || component.get('v.supportPlan.isactive')){
                    component.set("v.spTriggerEventObjectDisabled",true);
                } else {
                    component.set("v.spTriggerEventObjectDisabled",false);
                }
    			if(component.get("v.supportPlan.conditionallogic")!=null
    				&& component.get("v.supportPlan.conditionallogic")!=''){
    					component.set('v.initiateCondition', true);
    			}
    			helper.setNamespace(component);
    			if(infoResponse[0].baseSupportPlan.triggerEventObject != null &&  infoResponse[0].baseSupportPlan.triggerEventObject != ''){
    				component.set('v.spTriggerEventObject', infoResponse[0].baseSupportPlan.triggerEventObject);
    			}
    			if(infoResponse[0].baseSupportPlan.triggerEventType != null &&  infoResponse[0].baseSupportPlan.triggerEventType != ''){
    				component.set('v.spTriggerEventType', component.get('v.supportPlan.triggerEventType'));
    			}
    			if(infoResponse[0].baseSupportPlan.triggerEventCondition != null &&  infoResponse[0].baseSupportPlan.triggerEventCondition != '') {
    				component.set('v.sptriggerEventCondBldrLogic', infoResponse[0].baseSupportPlan.triggerEventCondition);
    			    var triggerEventCmp = component.find('triggerEventComponent');
                    triggerEventCmp.initiateConditionBuilderOnEdit();
                }


    			if(infoResponse[0].baseSupportPlan.conditionbehavior != null &&  infoResponse[0].baseSupportPlan.conditionbehavior != '') {
    				component.set('v.selectedConditionBehaviour', infoResponse[0].baseSupportPlan.conditionbehavior);
    			}
    			if(infoResponse[0].baseSupportPlan.conditionoption != null &&  infoResponse[0].baseSupportPlan.conditionoption != '') {

    				var tempPickList = component.get('v.conditionOptionPickListTwo').concat
    										 (component.get('v.conditionOptionPickListThree'));
    				component.set('v.picklistEntryMap.setCondition',tempPickList);
    				component.set('v.selectedConditionOption', infoResponse[0].baseSupportPlan.conditionoption);
    			}
    			if(infoResponse[0].baseSupportPlan.conditionallogic != null &&  infoResponse[0].baseSupportPlan.conditionallogic != '') {
    				component.set('v.conBldrLogic', infoResponse[0].baseSupportPlan.conditionallogic);
    				var conditionalBuilderCmp = component.find("conditionalBuilderContainer");
    				$A.util.removeClass(conditionalBuilderCmp,'slds-hide');
    				$A.util.addClass(conditionalBuilderCmp,'slds-show');
    				var conditionalBuilder = component.find("conditionalBuilder");
    				$A.util.removeClass(conditionalBuilder,'slds-hide');
    				$A.util.addClass(conditionalBuilder,'slds-show');
    				helper.displayConditions(component, event, helper);

    			}
    		}
    		else{
    			 var errors = response.getError();
                 if(!$A.util.isEmpty(errors) && errors.length > 0) {
                     var message = errors[0].message;
                     component.set("v.spErrors", message);
                 }

    		}
    	});
    	$A.enqueueAction(action);
    },
	fetchSupportPlan: function(component, event, helper){
		var action= component.get("c.fetchSupportPlan");
		var recordID=component.get('v.recordId');

		action.setParams({
			"recordId": recordID
		});
		action.setCallback(this,function(response){

			if(response.getState()=='SUCCESS'){
				var supportPlanData=response.getReturnValue();
				component.set('v.supportPlan', supportPlanData);
                if(component.get('v.supportPlan.triggerEventObject') != null &&
                    				    component.get('v.supportPlan.triggerEventObject') != ''){
                    component.set('v.spTriggerEventObject', component.get('v.supportPlan.triggerEventObject'));
                }
                if(component.get('v.supportPlan.triggerEventType') != null &&
                                    				    component.get('v.supportPlan.triggerEventType') != ''){
                    component.set('v.spTriggerEventType', component.get('v.supportPlan.triggerEventType'));
                }
                if(component.get('v.supportPlan.triggerEventCondition') != null &&
                    component.get('v.supportPlan.triggerEventCondition') != ''){
                    component.set('v.spTriggerEventConditions', component.get('v.supportPlan.triggerEventCondition'));
                }
				component.set('v.disabled', supportPlanData.isactive);

				if(component.get("v.supportPlan.conditionallogic")!=null
				&& component.get("v.supportPlan.conditionallogic")!=''){
				component.set('v.initiateCondition', true);
				}
				helper.setNamespace(component);

			}
			else{
				console.log("Failed with state: " + state);
                var errors = response.getError();
                if(!$A.util.isEmpty(errors) && errors.length > 0) {
                    var message = errors[0].message;
                    component.set("v.spErrors", message);
                }
			}
		});
		$A.enqueueAction(action);
	},


	handleSave: function(component, event, helper) {
	    var isValid = component.get("v.isValid");
	    console.log('isValid::::'+isValid);
	    if(isValid){
            console.log('handleSave::::');
            var constantsWrapper=component.get('v.constantsWrapper');
            if(component.get('v.spTriggerEventObject') != null && component.get('v.spTriggerEventObject')!=''){
                var triggerEventCmp = component.find('triggerEventComponent');
                var triggerEventActivityConditions = triggerEventCmp.getTriggerEventConditions();
                if(triggerEventActivityConditions[0]){
                    triggerEventActivityConditions = triggerEventActivityConditions[1];
                }else{
                    component.set("v.isValid",false);
                }
                if(triggerEventActivityConditions != null && triggerEventActivityConditions != ''){
                    component.set('v.triggerEventCondBldrLogic', JSON.stringify(triggerEventActivityConditions));
                } else{
                    component.set('v.triggerEventCondBldrLogic', '');
                }
                component.set('v.isSaving',true);
            }
            var setCondition = [];
            setCondition = component.find("setCondition").get("v.value");
            if(setCondition == constantsWrapper.condOptionCondBuilder && component.get('v.spTriggerEventObject')!=null
            && component.get('v.spTriggerEventObject')!=''){
                component.set('v.isSaving',true);
                var activityConditions=helper.conditionsToSave(component, event, helper);
                if(activityConditions[0]){
                    activityConditions = activityConditions[1];
                }else{
                    component.set("v.isValid",false);
                }
                component.set('v.conBldrLogic', JSON.stringify(activityConditions));
            }
            if(!component.get("v.isValid")){
                return;
            }
            component.set("v.supportPlan.spname", component.find("spname").get("v.value"));
            component.set("v.supportPlan.description", component.find("description").get("v.value"));
            component.set("v.supportPlan.triggerEventObject", component.get("v.spTriggerEventObject"));
            component.set("v.supportPlan.triggerEventType", component.get("v.spTriggerEventType"));
            component.set("v.supportPlan.conditionbehavior", component.find("behaviorList").get("v.value"));
            component.set("v.supportPlan.startcondition", component.find("className").get("v.value"));
            component.set("v.supportPlan.conditionoption", component.find("setCondition").get("v.value"));
            if(component.get('v.spTriggerEventObject')!=null && component.get('v.spTriggerEventObject')!='') {
                if(setCondition == constantsWrapper.condOptionCondBuilder)
                {
                    component.set("v.supportPlan.conditionallogic", component.get('v.conBldrLogic'));
                } else {
                    component.set("v.supportPlan.conditionallogic", '');
                }
            }
            if(component.get('v.spTriggerEventObject')!=null && component.get('v.spTriggerEventObject')!=''){
                component.set("v.supportPlan.triggerEventCondition", component.get('v.triggerEventCondBldrLogic'));
            }
            console.log('supportPlanBeforeSave::::'+JSON.stringify(component.get("v.supportPlan")));
            var action;
            action	= component.get("c.determineSave");
            action.setParams({
                "spId"     	    : component.get("v.recordId"),
                "supJSON"	        : JSON.stringify(component.get("v.supportPlan"))
            });

            action.setCallback(this, function(response) {
                console.log('response.getState()::::'+response.getState());
                if (response.getState() == "SUCCESS") {
                    var returnValue = response.getReturnValue();
                    component.set("v.recordId",returnValue);
                    if(!$A.util.isEmpty(returnValue)){
                     var title   = "Success";
                     var saveMessage = component.get("v.saveMsg")
                     var type    = "success";
                     helper.showToast(component, event, title, saveMessage, type);
                     helper.hideModal(component, event, helper);
                    }
                } else {
                    var errors = response.getError();
                    console.log('errors::::'+JSON.stringify(errors));
                    if(!$A.util.isEmpty(errors) && errors.length > 0) {
                        var spErrorArray = [];
                        for(var i=0; i<errors.length; i++){
                            var message = '';
                            if(errors[i].message != null &&  errors[i].message != ''){
                                message = errors[i].message;
                                spErrorArray.push(message);
                            }
                            if(errors[i].pageErrors[i].message != null &&  errors[i].pageErrors[i].message != ''){
                                message = errors[i].pageErrors[i].message;
                                spErrorArray.push(message);
                            }
                        }

                        //var message = errors[0].message;
                        //console.log('message::::'+message);
                        //var spErrorArray = [];
                        //spErrorArray.push(message);
                        component.set("v.spErrors", spErrorArray);
                    }
                }
            });
            $A.enqueueAction(action);
        }
    },

	showToast : function(component, event, title, message, type) {
		var toastEvent=$A.get("e.force:showToast");

		toastEvent.setParams({
		 "title": title,
		 "message":  message,
		 "type": type,

		});

		toastEvent.fire();
	},

	onChangeSelectedObjectRecord : function(component, event, helper) {
	    var oldValue = event.getParam("oldValue");
	    //var currentValue = event.getParam("value");
	    var recordType = component.get("v.spTriggerEventObject");
	    if(recordType!='None' && oldValue != "" && component.get("v.selectedConditionOption") == 'Conditional Builder'){
            var conditionBuilder = component.find('ruleInfoConditions');
            conditionBuilder.initializeComponent();
        }
	   /* var conditionalBuilderContainer = component.find("conditionalBuilderContainer");
        console.log('conditionalBuilderContainer::::'+conditionalBuilderContainer);
        $A.util.removeClass(conditionalBuilderContainer,'slds-show');
        $A.util.addClass(conditionalBuilderContainer,'slds-hide');
        var conditionalBuilderCmp = component.find("conditionalBuilder");
        console.log('conditionalBuilderCmp::::'+conditionalBuilderCmp);
        $A.util.removeClass(conditionalBuilderCmp,'slds-show');
        $A.util.addClass(conditionalBuilderCmp,'slds-hide');
        component.set('v.isAddRow', false);
        var allPickListMap=component.get('v.unAlteredpicklistEntryMap');
        var behaviorListPicklistValue = allPickListMap['behaviorList'];
        component.set('v.picklistEntryMap.setCondition',component.get('v.conditionOptionPickListOne'));
        component.set('v.picklistEntryMap.behaviorList',allPickListMap['behaviorList']);
        component.find('behaviorList').set('v.value', behaviorListPicklistValue[0].value);
        component.find('setCondition').set('v.value','');
        component.set('v.conBldrLogic','');
        component.set('v.fetchedCondition',null);
        component.set("v.conditionalBuilderCount",0);
        var conditionalBuilder      = component.find("conditionalBuilder");
        var conditionalBuilderBody	= [];
        conditionalBuilder.set("v.body",conditionalBuilderBody);*/
    },
    clearErrors : function(component) {
    	component.set("v.spErrors", []);
    	component.set("v.isValid",true);
    },
    onChangeSupportPlanName :  function(component, event, helper){
        if(!$A.util.isEmpty(component.find("spname").get("v.value"))){
            component.set("v.isValid", true);
            this.clearErrorMessage(component, ['spname']);
        }
    }
})