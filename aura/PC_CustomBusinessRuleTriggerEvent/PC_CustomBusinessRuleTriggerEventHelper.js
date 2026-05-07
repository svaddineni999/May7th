/**
 * Created by tusarora on 3/18/2020.
 */
({
    setTriggerEventObjectLabel : function(component, event, helper){
        var triggerEventObjectList = component.get('v.picklistTriggerEventObjectList');
        for(var i=0; i<triggerEventObjectList.length; i++){
            var triggerEventObject = triggerEventObjectList[i];
            var triggerEventObjectAPIName = triggerEventObject.value.toString();
            if(component.get('v.selectedTriggerEventObject') == triggerEventObjectAPIName){
                component.set('v.selectedTriggerEventObjectLabel',triggerEventObject.label.toString());
            }
        }
    },
    initiateConditionBuilderOnEdit : function(component, event, helper){
        component.set('v.isAddTriggerEventRow', true);
        var activityConditions = JSON.parse(component.get('v.triggerEventCondBldrLogic'));
        activityConditions.LstConditionsPerObject[0].ObjectType = component.get("v.selectedTriggerEventObject");
        component.set("v.recordConditions",activityConditions.LstConditionsPerObject);
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
    showTriggerEventConditionBuilder: function(component, event, helper){
        var recordType = component.get("v.selectedTriggerEventObject");
        if(recordType !='None'){
           component.set('v.isAddTriggerEventRow', true);
           var conditionalBuilder = component.find('triggerEventConditions');
           if(Array.isArray(conditionalBuilder)){
                conditionalBuilder[0].initializeComponent();
           }else{
                conditionalBuilder.initializeComponent();
           }
        } else{
            component.set('v.isAddTriggerEventRow', false);
        }
    },

    cacheConditions : function(component, event, helper){
    	component.set('v.prevRecordType', component.get('v.tempRecordType'));
    	component.set('v.tempRecordType', component.get('v.recordType'));
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
    },
    getTriggerEventConditions : function(component, event, helper){
        var triggerEvtConditionsComponent = component.find('triggerEventConditions');
        var conditionsJSON = [];
        var finalJSONList = [];
        if(typeof triggerEvtConditionsComponent != 'undefined' ){
            if(Array.isArray(triggerEvtConditionsComponent)){
                conditionsJSON = triggerEvtConditionsComponent[0].getBuilderJSONToSave();
            }else{
                conditionsJSON = triggerEvtConditionsComponent.getBuilderJSONToSave();
            }
            finalJSONList.push(conditionsJSON[0]);
            var finalJSONDetailsList = [];
            var finalJSONDetails = "";
            if(!$A.util.isEmpty(conditionsJSON[1])){
                finalJSONDetails = {
                   "Conditions" : conditionsJSON[1].LstConditionsPerObject[0].Conditions,
                   "Logic" : conditionsJSON[1].LstConditionsPerObject[0].Logic
                };
                if(finalJSONDetails.Conditions.length ==0){
                  return [true,''];
                }
            }
            finalJSONDetailsList.push(finalJSONDetails);
            var finalJSON = {
                "LstConditionsPerObject" : finalJSONDetailsList
            };
            finalJSONList.push(finalJSON);
        }
        return finalJSONList;
    },
    onTriggerEventObjectChange : function(component, event, helper){
        var triggerEventObject = component.get("v.selectedTriggerEventObject");
        var constantsWrapper=component.get('v.constantsWrapper');
        if(component.get('v.selectedTriggerEventObject') != null && component.get('v.selectedTriggerEventObject') != ''
                                      && component.get('v.selectedTriggerEventObject') != constantsWrapper.noneStr){
            component.set('v.isAddTriggerEventRow', false);
            helper.setTriggerEventObjectLabel(component, event, helper);
            helper.showTriggerEventConditionBuilder(component, event, helper);
        }else{
            var eventObjectListPath = component.find('eventObjectList');
            eventObjectListPath.showHelpMessageIfInvalid();
        }
    },
    validate: function(component, event, helper){
        var triggerEventObjectValidation = true;
        var eventObjectListPath = component.find('eventObjectList');
        eventObjectListPath.showHelpMessageIfInvalid();
        var isValidEventObject = eventObjectListPath.get('v.validity').valueMissing;
        if (isValidEventObject) {
            triggerEventObjectValidation = false;
        }
        var triggerEventTypeValidation = true;
        var eventTypePath = component.find('eventTypeList');
        eventTypePath.showHelpMessageIfInvalid();
        var isValidEventType = eventTypePath.get('v.validity').valueMissing;
        if (isValidEventType) {
             triggerEventTypeValidation = false;
        }
        var isValid;
        if(triggerEventObjectValidation && triggerEventTypeValidation) {
            isValid = true;
        } else {
            isValid = false;
        }
        return isValid;
    },
    clearErrorMessage : function (component, fieldArray){
        for (var i = 0; i < fieldArray.length; i++){
            var inputCmp = component.find(fieldArray[i]);
            inputCmp.set("v.errors", null);
        }
    },
    doValidationOnTriggerEventObject : function(component, event, helper){
        var eventObjectListPath = component.find('eventObjectList');
        var isTriggerEventObjectValid = true;
        var constantsWrapper=component.get('v.constantsWrapper');
        if(component.get('v.selectedTriggerEventObject') == null || component.get('v.selectedTriggerEventObject') == ''
            || component.get('v.selectedTriggerEventObject') == constantsWrapper.noneStr){
            eventObjectListPath.showHelpMessageIfInvalid();
            isTriggerEventObjectValid = false;
        }
        return isTriggerEventObjectValid;
    },
})