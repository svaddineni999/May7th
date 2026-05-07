/**
 * Created by kkanteti on 6/18/2020.
 */
({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    showSpinner: function(component,event,helper){
        var spinner = component.find("spinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    hideSpinner: function(component,event,helper){
        var spinner = component.find("spinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    initializeAttributes : function(component,event,helper){
        helper.setNamespace(component);
        var fetchedTriggerEventObject  = {
            "objectLabel"   : component.get("v.triggerEventObjectLabel"),
            "objectApiName" : component.get("v.triggerEventObjectApiName"),
            "type"          : "updateTriggerRecord",
            "selected"      : false
        };
        component.set("v.triggerEventObject",fetchedTriggerEventObject);
        var createUpdateTaskJSON = component.get("v.createUpdateTaskJSON");
        if(typeof createUpdateTaskJSON != "undefined" && createUpdateTaskJSON != "" && createUpdateTaskJSON != '{}'){
            var fetchedTaskJSON = JSON.parse(createUpdateTaskJSON);
            if(fetchedTaskJSON.type != null){
                var selectedObjectNameAndType = "";
                if(fetchedTaskJSON.type != "updateTriggerRecord"){
                    if(typeof fetchedTaskJSON.objectDetails.relativeQualifiedApiPath != "undefined"){
                        selectedObjectNameAndType = fetchedTaskJSON.objectDetails.qualifiedApiName+','+fetchedTaskJSON.type+','+fetchedTaskJSON.objectDetails.relativeQualifiedApiPath;
                    }else{
                        selectedObjectNameAndType = fetchedTaskJSON.objectDetails.qualifiedApiName+','+fetchedTaskJSON.type+','+"";
                    }
                }else{
                    selectedObjectNameAndType = fetchedTaskJSON.objectDetails.qualifiedApiName+','+fetchedTaskJSON.type;

                }
                component.set("v.selectedObjectNameType",selectedObjectNameAndType);
                helper.getObjectsAndOptions(component,event,helper,true,fetchedTaskJSON);
            }else{
                var errors = [{
                    message : component.get("v.invalidJSONErrorMessage")
                }]
                CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
                helper.hideSpinner(component,event,helper);
            }
        }else{
            helper.getObjectsAndOptions(component,event,helper,false,null);//If fetched JSON is null i.e. for new update record activity scenario
        }
    },
    /*getObjectsAndOptions used to fetch the objects(Objects that are shown in groups)
     and in case of edit mode orderByOptions,orderOptions,nullOptions,criteriaOptions are also fetched.*/
    getObjectsAndOptions : function(component,event,helper,editMode,fetchedTaskJSON){
        var action = component.get("c.getObjectsAndChildUpdateOptions");
        var selectedChildObject = "";
        if(editMode){
            selectedChildObject = fetchedTaskJSON.objectDetails.qualifiedApiName;
        }
        action.setParams({
            "triggerEventObject" : component.get("v.triggerEventObjectApiName"),
            "selectedChildObject" : selectedChildObject
        });
        action.setCallback(this,function(response){
            var state=response.getState();
            if('SUCCESS'==state){
                var allObjectsAndOptions = response.getReturnValue();
                component.set("v.lookupChildObjects",allObjectsAndOptions.lookupAndChildObjects);
                if(editMode){
                    component.set("v.childUpdateOptions",allObjectsAndOptions.childUpdateOptions);
                    helper.setAllFetchedValues(component,event,helper,fetchedTaskJSON);//only if edit mode.
                }
            }else if (state === "ERROR") {
                  var errors = response.getError();
                  CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            }else{
                console.log("Unknown error");
            }
            helper.hideSpinner(component,event,helper);
        });
        $A.enqueueAction(action);

    },
    setAllFetchedValues: function(component,event,helper,fetchedTaskJSON){
        helper.setSelectedObjectDetails(component,event,helper,true);
        if(fetchedTaskJSON.type == "updateChildRecords"){
            component.set("v.selectedOrderByFields",fetchedTaskJSON.sortOrderInfo[0].orderBy);
            component.set("v.selectedOrder",fetchedTaskJSON.sortOrderInfo[0].order);
            component.set("v.selectedNullsOrder",fetchedTaskJSON.sortOrderInfo[0].nullsOrder);
            component.set("v.selectedCriteria",fetchedTaskJSON.updateCriteria);
            helper.setChildUpdateOptions(component,event,helper);
            component.set("v.recordConditions",fetchedTaskJSON.LstConditionsPerObject);
        }
        component.set("v.recordProperties",fetchedTaskJSON.fieldMapping);
        var fetchedContinueRuntime = fetchedTaskJSON.continueWhenNoUpdates;
        var continueRuntime = false;
        if(fetchedContinueRuntime == "TRUE"){
            continueRuntime = true;
        }
        component.set("v.continueRuntimeWhenNoUpdates",continueRuntime);
        component.set("v.createOutcomeTask",fetchedTaskJSON.outcomeTaskDetails.create);
    },
    handleObjectChange : function(component,event,helper){
        helper.setSelectedObjectDetails(component,event,helper,false);
        if(component.get("v.selectedObjectNameType") != ""){
            if(component.get("v.updateObjectType") == 'updateChildRecords'){
                var noValues = [];
                component.set("v.selectedComboboxOptions",noValues);
                component.set("v.selectedOrderByFields",noValues);
                helper.getChildRecordUpdateOptions(component,event,helper);
            }
        }
    },
    getChildRecordUpdateOptions : function(component,event,helper){
        var action = component.get("c.getChildUpdateOptions");
        action.setParams({
            "selectedChildObject" : component.get("v.selectedObject.objectApiName")
        });
        action.setCallback(this,function(response){
            var state=response.getState();
            if('SUCCESS'==state){
                var childUpdateOptions = response.getReturnValue();
                component.set("v.childUpdateOptions",childUpdateOptions);
                helper.setChildUpdateOptions(component,event,helper);
            }else if (state === "ERROR") {
                var errors = response.getError();
                CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            }else{
                console.log("Unknown error");
            }
            helper.hideSpinner(component,event,helper);
        });

        $A.enqueueAction(action);
    },
    setChildUpdateOptions : function(component,event,helper){
        var childUpdateOptions = component.get("v.childUpdateOptions");
        component.set("v.comboboxOptions",childUpdateOptions.orderByFields);
        var fetchedOrder = component.get("v.selectedOrder");
        var  orderOptions = childUpdateOptions.orderOptions;
        if(fetchedOrder != ""){
            for(var key in orderOptions){
                if(orderOptions[key].value == fetchedOrder){
                    orderOptions[key].selected = true;
                    break;
                }
            }
        }else {
            for(var orderKey in orderOptions){
                if(orderOptions[orderKey].value == "ASC"){
                    orderOptions[orderKey].selected = true;
                    component.set("v.selectedOrder",orderOptions[orderKey].value);
                    break;
                }
            }
        }
        var fetchedNullsOrder = component.get("v.selectedNullsOrder");
        var  nullsOptions = childUpdateOptions.nullsOptions;
        if(!$A.util.isEmpty(fetchedNullsOrder)){
            for(var i in nullsOptions){
                if(nullsOptions[i].value == fetchedNullsOrder){
                    nullsOptions[i].selected = true;
                    break;
                }
            }
        }else {
             for(var j in nullsOptions){
                 if(nullsOptions[j].value == "LAST"){
                     nullsOptions[j].selected = true;
                     component.set("v.selectedNullsOrder",nullsOptions[j].value);
                     break;
                 }
             }
        }
        var fetchedCriteria = component.get("v.selectedCriteria");
        var criteriaOptions = childUpdateOptions.criteriaOptions;
        if(!$A.util.isEmpty(fetchedCriteria)){
            for(var k in criteriaOptions){
                if(criteriaOptions[k].value == fetchedCriteria){
                    criteriaOptions[k].selected = true;
                    break;
                }
            }
        }else {
            for(var x in criteriaOptions){
                if(criteriaOptions[x].value == "ALL_RECORDS"){
                    criteriaOptions[x].selected = true;
                    component.set("v.selectedCriteria",criteriaOptions[x].value);
                    break;
                }
            }
        }
        var selectedOrderByFields = component.get("v.selectedOrderByFields");
        component.set("v.selectedComboboxOptions",selectedOrderByFields);
        var singleMultiSelectCmp =  component.find("singleMultiSelectCombobox");
        singleMultiSelectCmp.initiateCombobox();
    },
    setSelectedObjectDetails : function(component,event,helper,editMode){
        var selectObjectDropdown = component.find("selectObject");
        $A.util.removeClass(selectObjectDropdown,'slds-has-error');
        var selectedObjectNameAndType = component.get("v.selectedObjectNameType");
        component.set("v.selectedObject","");
        if(selectedObjectNameAndType == ""){
            component.set("v.updateObjectType","");
            return;
        }
        if(selectedObjectNameAndType.split(',')[1] == "updateTriggerRecord"){
            var triggerEventObject = component.get("v.triggerEventObject");
            if(triggerEventObject.objectApiName == selectedObjectNameAndType.split(',')[0] &&
                    triggerEventObject.type == selectedObjectNameAndType.split(',')[1] ){
                triggerEventObject.selected = true;
                component.set("v.triggerEventObject",triggerEventObject);
                component.set("v.selectedObject",triggerEventObject);
                component.set("v.updateObjectType",triggerEventObject.type);
            }
        }
        if(selectedObjectNameAndType.split(',')[1] == "updateLookupRecord"){
            var allLookupObjects = component.get("v.lookupChildObjects.triggerEventLookupObjects");
            for(var obj in allLookupObjects){
                if(allLookupObjects[obj].objectApiName == selectedObjectNameAndType.split(',')[0] &&
                    allLookupObjects[obj].type == selectedObjectNameAndType.split(',')[1] &&
                    allLookupObjects[obj].lookupFieldApiName == selectedObjectNameAndType.split(',')[2]){
                    component.set("v.selectedObject",allLookupObjects[obj]);
                    component.set("v.updateObjectType",allLookupObjects[obj].type);
                    allLookupObjects[obj].selected = true;
                    break;
                }
            }
        }
        if(selectedObjectNameAndType.split(',')[1] == "updateChildRecords"){
            var allChildObjects = component.get("v.lookupChildObjects.triggerEventChildObjects");
            for(var eaObject in allChildObjects){
                if(allChildObjects[eaObject].objectApiName == selectedObjectNameAndType.split(',')[0] &&
                    allChildObjects[eaObject].type == selectedObjectNameAndType.split(',')[1]){
                    if(selectedObjectNameAndType.split(',')[2] != ""){
                        if(allChildObjects[eaObject].childRelationshipName == selectedObjectNameAndType.split(',')[2]){
                            component.set("v.selectedObject",allChildObjects[eaObject]);
                            component.set("v.updateObjectType",allChildObjects[eaObject].type);
                            allChildObjects[eaObject].selected = true;
                            break;
                        }
                    }else{
                        component.set("v.selectedObject",allChildObjects[eaObject]);
                        component.set("v.updateObjectType",allChildObjects[eaObject].type);
                        allChildObjects[eaObject].selected = true;
                        break;
                    }
                }
            }
        }

        var propertyBuilder = component.find('updateRecordPropertyBuilder');
        propertyBuilder.initializeComponent();
        if(component.get("v.updateObjectType") == 'updateChildRecords' && !editMode){
            var conditionBuilder = component.find('relatedObjectRecordsFilter');
            conditionBuilder.initializeComponent();
        }
    },
    onChangeOrderByFields : function(component,event,helper){
        component.set("v.selectedOrderByFields",component.get("v.selectedComboboxOptions"));
    },
    getTaskJSONToSave : function(component, event, helper){
        component.set("v.isSaving",true); //validates data,set to false if data validation not required.
        component.set("v.isValid", true);
        var invalidJSON =[false,JSON.stringify({})];
        if(component.get("v.selectedObjectNameType") == ""){
            var selectObjectDropdown = component.find("selectObject");
            $A.util.addClass(selectObjectDropdown,'slds-has-error');
            component.set("v.isValid",false);
            return invalidJSON;
        }
        var fieldMappingList = helper.getFieldMappingJSON(component,event,helper);
        if(fieldMappingList[0]){
            fieldMappingList = fieldMappingList[1];
        }else{
            return invalidJSON;
        }
        var filterConditionsJSON  = [];
        var relativeQualifiedApiPath = '';
        var selectedObjectType = component.get("v.selectedObject.type");
        if(selectedObjectType != "updateTriggerRecord"){
            relativeQualifiedApiPath = component.get("v.selectedObject.lookupFieldApiName");
        }
        if(selectedObjectType == "updateChildRecords"){
            relativeQualifiedApiPath = component.get("v.selectedObject.childRelationshipName");//relationship
            var conditionsJSONList = helper.getFilterConditionsJSON(component,event,helper);
            if(conditionsJSONList[0]){
                filterConditionsJSON = conditionsJSONList[1];
            }else{
                return invalidJSON;
            }
        }
        if(selectedObjectType != "updateChildRecords"){
            component.set("v.selectedOrder","");
            component.set("v.selectedCriteria","");
            var noValues = [];
            component.set("v.selectedOrderByFields",noValues);
        }
        var continueRuntime = "";
        if(selectedObjectType == "updateTriggerRecord"){
            continueRuntime = "N/A";
        }else{
            var optedContinueRuntime = component.get("v.continueRuntimeWhenNoUpdates");
            if(optedContinueRuntime){
                continueRuntime = "TRUE";
            }else{
                continueRuntime = "FALSE";
            }
        }
        var createUpdateTaskJSON = {
        	"type": selectedObjectType,
        	"sortOrderInfo":[
        	    {
        	    "orderBy": component.get("v.selectedOrderByFields"),
        	    "order": component.get("v.selectedOrder"),
        	    "nullsOrder": component.get("v.selectedNullsOrder")
        	    }
        	],
        	"updateCriteria": component.get("v.selectedCriteria"),
        	"continueWhenNoUpdates": continueRuntime,
        	"objectDetails": {
        		"qualifiedApiName": component.get("v.selectedObject.objectApiName"),
        		"relativeQualifiedApiPath": relativeQualifiedApiPath
        	},
        	"LstConditionsPerObject": filterConditionsJSON.LstConditionsPerObject,
        	"fieldMapping": fieldMappingList,
        	"outcomeTaskDetails": {
        		"create": component.get("v.createOutcomeTask")
        	}
        }
        var returnJSON =[component.get("v.isValid"),JSON.stringify(createUpdateTaskJSON)];

        return returnJSON;
    },
    getFieldMappingJSON : function(component, event, helper){
        var fieldMapper = component.find("updateRecordPropertyBuilder");
        var fieldMappingList = [];
        if(typeof fieldMapper != 'undefined'){
            fieldMappingList = fieldMapper.getBuilderJSONToSave();
        }
        return fieldMappingList;
    },
    getFilterConditionsJSON : function(component, event, helper){
        var conditionalBuilder = component.find("relatedObjectRecordsFilter");
        var recordConditionsList = [];
        if(typeof conditionalBuilder != 'undefined'){
            recordConditionsList = conditionalBuilder.getBuilderJSONToSave();
        }
        return recordConditionsList;
    }
})