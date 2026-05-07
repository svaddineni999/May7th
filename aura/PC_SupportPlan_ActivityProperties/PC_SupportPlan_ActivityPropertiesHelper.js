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
    
    fetchActivity : function(component, event, helper){

        var action = component.get("c.fetchActivity");
        var activityMap = new Map();
        activityMap["activityId"] = component.get("v.activity.Id");
        activityMap["internalactivitynumber"] = component.get("v.activity.internalactivitynumber");
        activityMap["activityName"] = component.get("v.activity.activityname");
        activityMap["internalactivitytype"] = component.get("v.activity.internalactivitytype");
        activityMap["supportPlanID"] = component.get("v.activity.supportplan");

        action.setParams({
            "fieldSetNm"            : component.get("v.fieldSet"),
            "activityMap"			: activityMap
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.newActivity", returnValue);
                helper.setNamespace(component);

                if( returnValue.activitytype == 'Automation Task' || returnValue.activitytype == 'User Task'){

                    component.set("v.isCriteriaRequired",true);
                    component.set("v.isDueDateRequired",true);
                    if(returnValue.activitytype == 'Automation Task'){
                        component.set("v.AutomationTaskDisplay",true);
                        component.set("v.taskJSON",component.get("v.newActivity.automationtaskjson"));
                        helper.getSupportPlanAutomationTaskData(component, event, helper,component.get("v.newActivity.subType"));
                    }

                }else if(returnValue.activitytype == 'Create Record' || returnValue.activitytype == 'Publish Platform Event' || returnValue.activitytype == 'Update Record'){
                    component.set("v.isCriteriaRequired",true);
                    if(returnValue.activitytype == 'Create Record' || returnValue.activitytype == 'Publish Platform Event'){
                        component.set("v.storedObjectApiName",JSON.parse(returnValue.objectDetails).QualifiedApiName);
                        component.set("v.selectedRecord",JSON.parse(returnValue.objectDetails));
                    }
                    component.set("v.AutomationTaskDisplay",false);
                    component.set("v.showTaskFields",false);
                    if(returnValue.activitytype == 'Create Record' || returnValue.activitytype == 'Publish Platform Event'){
                        component.set("v.isRecordCreation",true);
                    }
                    if(returnValue.activitytype == 'Update Record'){
                        component.set("v.isRecordUpdation",true);
                        component.set("v.taskJSON",component.get("v.newActivity.objectFieldsMap"));
                    }
                    if(returnValue.activitytype == 'Publish Platform Event'){
                        component.set("v.isPlatformContext",true);
                        component.set("v.objectType",'Platform Event Object');
                    }else{
                        component.set("v.objectType",'Data Object');
                    }
                    if(returnValue.activitytype == 'Create Record' || returnValue.activitytype == 'Publish Platform Event'){
                        component.set("v.createOutcomeTask",JSON.parse(returnValue.outcomeTaskDetails).create);
                    }
                }

                if(component.get("v.newActivity.conditionallogic")!=null && component.get("v.newActivity.conditionallogic")!=''){
                    component.set('v.initiateCondition', true);
                }

                if(returnValue.internalactivitytype=='Sequence'){
                    component.set('v.showTaskFields', false);
                    component.set('v.showGroupExecution', true);
                    component.set("v.isCriteriaRequired",true);
                }
                else if(returnValue.usertaskfields!='' || returnValue.objectFieldsMap != '' ){

                     if(returnValue.activitytype == 'Automation Task' || returnValue.activitytype == 'User Task'){
                         component.set("v.showTaskFields",true);
                        helper.initiateUserTaskProperties(component, event, helper, returnValue.usertaskfields);
                     }else if(returnValue.activitytype == 'Create Record' || returnValue.activitytype == 'Publish Platform Event'){
                           component.set("v.isAddFieldMapRow",true);
                            var allFieldsMap = [];
                            if(returnValue.fieldMapping !=null && !$A.util.isEmpty(returnValue.fieldMapping)){
                                allFieldsMap = JSON.parse(returnValue.fieldMapping);
                            }
                            component.set("v.recordProperties",allFieldsMap);
                     }

                }
                if(returnValue.internalactivitytype=='Sequence Task'){
                    component.set('v.isCriteriaRequired', false);
                }
                if(!$A.util.isEmpty(returnValue.Id)){
                    component.set('v.isDeleteAvailable', true);
                }
            }else if (state === "ERROR") {
                 var errors = response.getError();
                 CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            }else {
                console.log("Unknown error");
            }
        });
        $A.enqueueAction(action);

    },

	toggleHelper : function(component,event) {
    var toggleText = component.find("tooltip");
    $A.util.toggleClass(toggleText, "toggle");
   },

    handleSave: function(component, event, helper) {
        var constantsWrapper=component.get('v.constantsWrapper');
        component.set('v.isSaving',true);
        if(component.get('v.showTaskFields')){
            helper.taskPropertiesToSave(component, event, helper);
        }else if(component.get("v.isRecordCreation") && component.get("v.selectedRecord") != '{}'){
            helper.recordFieldsToSave(component, event, helper);
        }else if(component.get("v.isRecordUpdation")){
            component.set("v.taskProperties",null);
            var createUpdateAutomationTaskCmp =  component.find("createUpdateAutomationTask");
            var createUpdateJSON = createUpdateAutomationTaskCmp.getTaskJSONToSave();
            if(component.get("v.isValid")){
                component.set("v.isValid",createUpdateJSON[0]);
            }
            component.set("v.taskJSON",createUpdateJSON[1]);
        }
        var setCondition = [];
        if(component.get('v.isCriteriaRequired')){
            setCondition = component.find("setCondition").get("v.value");
            var conditionalBuilderObject = component.get("v.recordType");
            if(setCondition == constantsWrapper.condOptionCondBuilder && !$A.util.isEmpty(conditionalBuilderObject)
                && conditionalBuilderObject != 'None'){
                component.set('v.isSaving',true);
                var activityConditions = helper.conditionsToSave(component, event, helper);
                if(!activityConditions[0]){
                    component.set("v.isValid",activityConditions[0]);
                }
                component.set('v.isSaving',false);
                if(activityConditions[0]){
                    component.set('v.conBldrLogic', JSON.stringify(activityConditions[1]));
                }
            }
        }
        
        component.set("v.newActivity.activityname", component.find("activityname").get("v.value"));
        var activityType = component.find("activityType").get("v.value");
        if(activityType == "__none"){
            activityType = null;
        }
        component.set("v.newActivity.activitytype", activityType);
        if(component.get("v.isDueDateRequired")){
            component.set("v.newActivity.referencedate", component.find("refDate").get("v.value"));
            component.set("v.newActivity.referenceoffset", component.find("refOffset").get("v.value"));
            component.set("v.newActivity.referenceoffsetunit", component.find("refOffsetUnit").get("v.value"));
            component.set("v.newActivity.referencetype", component.find("referenceType").get("v.value"));
        }
        if(component.get("v.showGroupExecution")){
            component.set("v.newActivity.groupactivityexecution", component.find("groupAtivityExecution").get("v.value"));
        }
        //component.set("v.newActivity.assigntorole", component.find("assignToRole").get("v.value"));
        if(component.get('v.isCriteriaRequired')){
            component.set("v.newActivity.conditionbehavior", component.find("behaviorList").get("v.value"));
            component.set("v.newActivity.apexcondition", component.find("className").get("v.value"));
            component.set("v.newActivity.conditionoption", component.find("setCondition").get("v.value"));
            var setConditions = [];
            setConditions = component.find("setCondition").get("v.value");
            if(component.find('behaviorList').get('v.value') != 'No Condition'){
                if(setConditions == constantsWrapper.condOptionCondBuilder && component.get('v.recordType') != null && component.get('v.recordType') != ''){
                    component.set("v.newActivity.conditionallogic", component.get('v.conBldrLogic'));
                    component.set("v.newActivity.apexcondition", "");
                } else {
                    component.set("v.newActivity.conditionallogic", "");
                }
            } else {
                component.set("v.newActivity.apexcondition", "");
                component.set("v.newActivity.conditionallogic", "");
            }
        }

        var subTypeActive = component.get('v.AutomationTaskDisplay');

        if(subTypeActive){
           helper.automationJSONToSave(component, event, helper);
           component.set("v.newActivity.subType", component.find("subType").get("v.value"));
           var actionClassMap  = component.get("v.actionClassMap");
           var actionClass     = actionClassMap.get(component.find("subType").get("v.value"));
           component.set("v.newActivity.actionClass", actionClass);
           component.set("v.newActivity.automationtaskjson", component.get("v.taskJSON"));
        }else if(component.get("v.isRecordCreation") || component.get("v.isRecordUpdation")){
            component.set("v.newActivity.automationtaskjson", component.get("v.taskJSON"));
        }
        if(!component.get("v.isValid")){
            component.set("v.disabled",false);
            return;
        }

        component.set("v.newActivity.usertaskfields", component.get('v.taskProperties'));
        var action;
        action	= component.get("c.determineSave");
        var saveActivityMap = new Map();
        saveActivityMap['activityId'] = component.get("v.activity.internalactivitynumber");
        saveActivityMap['supportPlanID'] = component.get("v.supportPlanID");
        saveActivityMap['supActivityJSON'] = JSON.stringify(component.get("v.newActivity"));
        saveActivityMap['prevActivityJSON'] = component.get("v.prevActivity");
        saveActivityMap['nextActivity'] = component.get("v.nextActivity");

        action.setParams({
            "saveActivityMap"     	: saveActivityMap
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var returnValue = response.getReturnValue();
                if(returnValue){
                    var title   = "Success";
                    var message;
                    if(component.get("v.newActivity.internalactivitytype") == "User Task"){
                         message = component.get("v.saveMsg");
                    } else{
                        message = component.get("v.saveMsgGrp");
                    }
                    var type    = "success";
                    helper.showToast(component, event, title, message, type);
                    $(".rightPanel").removeClass("expanded");
        			$(".leftPanel").removeClass("contracted");
                }
            }else if (state === "ERROR") {
                 var errors = response.getError();
                 CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            }else {
                console.log("Unknown error");
            }
        });
        $A.enqueueAction(action);  
    },
    automationJSONToSave : function (component, event, helper){
        if(component.find("subType").get("v.value") != "__none"){
            var AutomationTaskLightningComponent    = component.find("AutomationTaskLightningComponent");
            var lightningComponent                  = AutomationTaskLightningComponent.get("v.body");
            var taskJSON                            = lightningComponent[0].get("v.taskJSON");
            component.set("v.taskJSON",taskJSON);
        }
    },
    showToast : function(component, event, title, message, type) {
        var toastEvent=$A.get("e.force:showToast");
        var compEvent = component.getEvent("refresh");

        toastEvent.setParams({
            "title": title,
            "message":  message,
            "type": type,
            
        });

        compEvent.setParam("refresh", true);
        toastEvent.fire();
        compEvent.fire();
    },

    closeComponent : function(component, event, helper){
    	var compEvent = component.getEvent("refresh");
        compEvent.setParam("refresh", true);
        compEvent.fire();
        $(".rightPanel").removeClass("expanded");
        $(".leftPanel").removeClass("contracted");
    },

    fetchPickListValues: function(component) {
        this.fetchPickListVal(component,  'activityType');
        this.fetchPickListVal(component,  'behaviorList');
        this.fetchPickListVal(component, 'setCondition');
        this.fetchPickListVal(component, 'refOffsetUnit');
        this.fetchPickListVal(component,  'referenceType');
        
    },

    getPicklistEntryMap : function(component, helper){

        var action = component.get("c.getPicklistEntryMap");
        action.setParams({

        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.picklistEntryMap", returnValue);
                component.set("v.unAlteredpicklistEntryMap", returnValue);

                this.populateReferenceTypePickLists(component,event);
                this.changeReferenceTypePicklist(component,event);
                this.populateCondOptionPickLists(component,event);
                this.changeConditionOptionPickList(component,event, helper);

            }else if (state === "ERROR") {
                  var errors = response.getError();
                  CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            }else {
                console.log("Unknown error");
            }
        });
        $A.enqueueAction(action);
    },
    
    getFieldLabels : function(component){
        var action = component.get("c.getFieldLabels");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                component.set("v.fieldLabels", returnValue);
            }else if (state === "ERROR") {
                  var errors = response.getError();
                  CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            }else {
                console.log("Unknown error");
            }
        });
        $A.enqueueAction(action);     
    },
    
    validateRequired: function(component, event, helper){
        var requiredFieldErrorMessage = component.get("v.requiredFieldErrorMessage");
        var customMetadataErrorMessage = component.get("v.customMetadataErrorMessage");
        
        //this.clearErrorMessage(component, ['activityname','activityType','subject','priority','channel','refOffset','referenceType','record']);
        var fieldArray = ['activityname','activityType','record'];
        if(component.get("v.isDueDateRequired")){
            fieldArray.push('refOffset');
            fieldArray.push('referenceType');
        }
        this.clearErrorMessage(component, fieldArray);
        component.set("v.isValid", true);

        if($A.util.isEmpty(component.find("activityname").get("v.value"))){
            component.set("v.isValid", false); 
            component.find("activityname").set("v.errors", [{message:requiredFieldErrorMessage}]);
        }
        
        if($A.util.isEmpty(component.find("activityType").get("v.value")) || component.find("activityType").get("v.value") =="__none"
          	&& component.get("v.newActivity.internalactivitytype") != component.get("v.activityType")){
            component.set("v.isValid", false); 
            component.find("activityType").set("v.errors", [{message:requiredFieldErrorMessage}]);
        }
        var activityType = component.find("activityType").get("v.value");
        if(activityType == "Create Record" || activityType == "Publish Platform Event"){
            var subTypeError = component.find("subTypeError");
            if(component.get("v.selectedRecord") == "{}"){
                component.set("v.isValid", false);
                $A.util.removeClass(subTypeError,'slds-hide');
                $A.util.addClass(subTypeError,'slds-show');
            }else{
                $A.util.removeClass(subTypeError,'slds-show');
                $A.util.addClass(subTypeError,'slds-hide');
            }
        }
        var subTypeActive = component.get('v.AutomationTaskDisplay');

        if(subTypeActive == true){
            if(component.find("subType").get("v.options").length == 1){
                component.set("v.isValid", false);
                component.find("subType").set("v.errors", [{message:customMetadataErrorMessage}]);


            }else if ($A.util.isEmpty(component.find("subType").get("v.value")) || component.find("subType").get("v.value") =="__none"){
                component.set("v.isValid", false);
                component.find("subType").set("v.errors", [{message:requiredFieldErrorMessage}]);

            }else if (!$A.util.isEmpty(component.find("subType").get("v.errors"))){
                component.set("v.isValid", false);
            }else{
                try{
                    var AutomationTaskLightningComponent    = component.find("AutomationTaskLightningComponent");
                    var lightningComponent                  = AutomationTaskLightningComponent.get("v.body");
                    lightningComponent[0].validateData();
                    var isValid = lightningComponent[0].get("v.isValid");
                    component.set("v.isValid", isValid);
                }catch(err){
                    var title   = "Warning";
                    var message = component.get("v.validateDataErrorMessage");
                    var type    = "warning";
                    helper.showToast(component, event, title, message, type);
                }
            }
        }
        if(component.get('v.isCriteriaRequired')){
            var constantsWrapper=component.get('v.constantsWrapper');
            var setCondition = component.find("setCondition").get("v.value");
            if(setCondition == constantsWrapper.condOptionApex && $A.util.isEmpty(component.find("className").get("v.value"))){
                component.set("v.isValid", false);
                component.find("className").set("v.errors", [{message:requiredFieldErrorMessage}]);
            }else if(setCondition == constantsWrapper.condOptionCondBuilder && component.get('v.recordType')=='None'){
                component.set("v.isValid", false);
                component.find("record").set("v.errors", [{message:requiredFieldErrorMessage}]);
            }
        }
        if(!component.get("v.isValid")){
            component.set("v.disabled",false);
        }
    },
    
    clearErrorMessage : function (component, fieldArray){
        for (var i = 0; i < fieldArray.length; i++){
            if((!component.get('v.isCriteriaRequired'))&&fieldArray[i]=='record'){
                continue;
            }
            var inputCmp = component.find(fieldArray[i]);
            inputCmp.set("v.errors", null);
        }
    },
    
    handleDelete: function(component, event, helper) {
        var action = component.get("c.deleteRecord");
        action.setParams({
            "supportPlanID" : component.get("v.supportPlanID"),
            "activityId"	: component.get("v.newActivity.Id"),
            "prevActivityJSON"	: component.get("v.prevActivity")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var returnValue = response.getReturnValue();
                if(returnValue){
                    var title   = "Success";
                    var message;
                    var type    = "success";
                    if(component.get("v.newActivity.internalactivitytype") == "User Task"){
                        message = component.get("v.deleteMsg");
                    } else{
                        message = component.get("v.deleteMsgGrp");
                    }
            	    helper.showToast(component, event, title, message, type);
                    $(".rightPanel").removeClass("expanded");
        			$(".leftPanel").removeClass("contracted");
            	}
            }else if (state === "ERROR") {
                  var errors = response.getError();
                  CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors)
            }else {
                 console.log("Unknown error");
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
    
    getReferenceDatePicklist: function(component, event, helper){

        var action=component.get('c.getReferenceDatePickistVal');
        action.setParams({
            "triggerEventObjectLabel" : component.get("v.triggerEventObjectLabel"),
            "triggerEventObjectApiName" : component.get("v.triggerEventObjectApiName")
        });
        action.setCallback(this,function(response){
            var state=response.getState();

            if('SUCCESS'==state){
                var refDatePickList=JSON.parse(response.getReturnValue());
                component.set('v.refDatePicklist',refDatePickList);
                this.populatePicklistFields(component, event, helper);

            }else {
                console.log("Failed with state: " + state);
             }

        });
        $A.enqueueAction(action);

    },

    changeReferenceTypePicklist:  function(component, event){

        var constantsWrapper=component.get('v.constantsWrapper');

        var activityObj=component.get('v.newActivity');
        var referenceTypePickListMap=component.get('v.unAlteredpicklistEntryMap');

        if((null!=activityObj.referencedate)
                    &&!(constantsWrapper.noneStr==activityObj.referencedate)){

            referenceTypePickListMap['referenceType']= component.get('v.pickListValWhenRefDateNotBlank');
        }
        else if(constantsWrapper.noneStr==activityObj.referencedate||undefined==activityObj.referencedate){
            referenceTypePickListMap['referenceType']= component.get('v.pickListValWhenRefDateIsBlank');
            if(component.get("v.isFirstAct")){
                referenceTypePickListMap['referenceType'] = component.get("v.pickListValWhenRefDateIsBlankFirstAct");
            }
        }

        component.set('v.picklistEntryMap',referenceTypePickListMap);
    },

    populateReferenceTypePickLists: function(component, event){
        var referenceTypePickListMap=component.get('v.unAlteredpicklistEntryMap');

        var referenceTypePickList=referenceTypePickListMap['referenceType'];

        var constantsWrapper=component.get('v.constantsWrapper');

        var pickListValListWithReferenceDate=[];
        var pickListValListWithOutReferenceDate=[];
        var pickListValListWithOutReferenceDateFirstAct=[];
        for(var i=0;i<referenceTypePickList.length;i++){
            var referenceType=referenceTypePickList[i];

            if(constantsWrapper.beforeRefDate==referenceType.value||constantsWrapper.afterRefDate==referenceType.value) {
                 pickListValListWithReferenceDate.push(referenceType);
            }

            if(constantsWrapper.afterCompletionOfPrevActivity==referenceType.value || constantsWrapper.activityCreationDate == referenceType.value) {
               pickListValListWithOutReferenceDate.push(referenceType);
            }

            if(constantsWrapper.activityCreationDate == referenceType.value) {
                pickListValListWithOutReferenceDateFirstAct.push(referenceType);
            }


        }
        component.set('v.pickListValWhenRefDateNotBlank',pickListValListWithReferenceDate);
        component.set('v.pickListValWhenRefDateIsBlank',pickListValListWithOutReferenceDate);
        component.set('v.pickListValWhenRefDateIsBlankFirstAct',pickListValListWithOutReferenceDateFirstAct);

    },

    changeReferenceType:  function(component, event){
        var selectedRefDateField=component.find('refDate').get('v.value');

        var referenceTypePickListMap=component.get('v.unAlteredpicklistEntryMap');

        var constantsWrapper=component.get('v.constantsWrapper');

       if((null!=selectedRefDateField)
                           &&!(constantsWrapper.noneStr==selectedRefDateField)){
                   referenceTypePickListMap['referenceType']= component.get('v.pickListValWhenRefDateNotBlank');
               }
               else if(constantsWrapper.noneStr==selectedRefDateField){
                   referenceTypePickListMap['referenceType']= component.get('v.pickListValWhenRefDateIsBlank');
                   if(component.get("v.isFirstAct")){
                    referenceTypePickListMap['referenceType'] = component.get("v.pickListValWhenRefDateIsBlankFirstAct");
                   }
               }

        var pickList=referenceTypePickListMap['referenceType'];

        component.find('referenceType').set('v.value', pickList[0].value);

        component.set('v.picklistEntryMap',referenceTypePickListMap);

    },

    populatePicklistFields: function(component, event, helper){
        if(component.get("v.isDueDateRequired")){
            component.find('refDate').set('v.value',component.get('v.newActivity.referencedate'));
            component.find('referenceType').set('v.value',component.get('v.newActivity.referencetype'));
            component.find('refOffsetUnit').set('v.value',component.get('v.newActivity.referenceoffsetunit'));
        }
        component.find('activityType').set('v.value',component.get('v.newActivity.activitytype'));

        if(component.get("v.showGroupExecution")){
            component.find('groupAtivityExecution').set('v.value',component.get('v.newActivity.groupactivityexecution'));
        }

        if(component.get("v.isCriteriaRequired")){
            component.find('behaviorList').set('v.value',component.get('v.newActivity.conditionbehavior'));
            component.find('setCondition').set('v.value',component.get('v.newActivity.conditionoption'));
        }
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

        var activityObj=component.get('v.newActivity');
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
      if(component.get("v.isCriteriaRequired")){
        helper.showCondition(component, event, helper);
      }
    },

    changeConditionOption:  function(component, event, helper){
        var selectedConditionBehav=component.find('behaviorList').get('v.value');

        var constantsWrapper=component.get('v.constantsWrapper');

        var allPickListMap=component.get('v.unAlteredpicklistEntryMap');

            if((null!=selectedConditionBehav)&&(constantsWrapper.condBehavNoCond==selectedConditionBehav)){
                   allPickListMap['setCondition']= component.get('v.conditionOptionPickListOne');
            }
            else if((null!=selectedConditionBehav)&&!(constantsWrapper.condBehavNoCond==selectedConditionBehav)){
                    var tempPickList = component.get('v.conditionOptionPickListTwo').concat
                                   (component.get('v.conditionOptionPickListThree'));

                    allPickListMap['setCondition']= tempPickList;
            }

        var pickList=allPickListMap['setCondition'];
        component.find('setCondition').set('v.value', pickList[0].value);
        component.set('v.picklistEntryMap',allPickListMap);
        helper.showCondition(component, event, helper);
    },

    showCondition : function(component, event, helper){
        var constantsWrapper=component.get('v.constantsWrapper');
        var setCondition = component.find("setCondition").get("v.value");
        var apexClass = component.find("apexClass");
        var conditionalBuilder = component.find("conditionalBuilderContainer");
        if(setCondition == constantsWrapper.condOptionCondBuilder || (component.get('v.initiateCondition') &&
        component.get('v.newActivity.conditionoption') == constantsWrapper.condOptionCondBuilder)){
            $A.util.removeClass(apexClass,'slds-show');
            $A.util.addClass(apexClass,'slds-hide');
            $A.util.removeClass(conditionalBuilder,'slds-hide');
            $A.util.addClass(conditionalBuilder,'slds-show');
            var recordCmp = component.find("record");
            recordCmp.set("v.options", component.get('v.recordOptions'));
            component.set('v.recordType', 'None');
            if(component.get('v.initiateCondition')||(component.get('v.newActivity.conditionallogic')!=null
            && component.get('v.newActivity.conditionallogic')!='' && component.get('v.cachedConditionsMap')==null)){
                component.set('v.currentConditions', component.get('v.newActivity.conditionallogic'));
                helper.displayConditions(component, event, helper);
                component.set('v.initiateCondition', false);
            }
            component.set('v.prevRecordType', component.get('v.recordType'));
            component.set('v.tempRecordType', component.get('v.recordType'));
        }else if(setCondition == constantsWrapper.condOptionApex ||
                 component.get('v.newActivity.conditionoption') == constantsWrapper.condOptionApex){
            $A.util.addClass(apexClass,'slds-show');
            $A.util.removeClass(apexClass,'slds-hide');
            $A.util.removeClass(conditionalBuilder,'slds-show');
            $A.util.addClass(conditionalBuilder,'slds-hide');
        }else {
            $A.util.addClass(apexClass,'slds-hide');
            $A.util.removeClass(apexClass,'slds-show');
            $A.util.removeClass(conditionalBuilder,'slds-show');
            $A.util.addClass(conditionalBuilder,'slds-hide');
        }
        //helper.cacheConditions(component, event, helper);
    },
    getConstantsValuesMap: function(component, event,helper){
        var action=component.get('c.getConstantsWrapper');

        action.setCallback(this,function(response){
            var state=response.getState();
            if('SUCCESS'==state){
                var constantsWrapper=response.getReturnValue();
                component.set('v.constantsWrapper',constantsWrapper);
            }else {
                console.log("Failed with state: " + state);
             }

        });
        $A.enqueueAction(action);
   },

   setRecordValues : function(component){
       var optionsReceived =   [];
       var noneOptionName = component.get("v.noneOptionName");
       if(component.get('v.supportPlanID')!=null){
             optionsReceived =   [
                                 {'label': noneOptionName, 'value': 'None'},
                                // {'label': component.get('v._label12'), 'value': 'Case'},
                                 {'label': component.get("v.triggerEventObjectLabel"), 'value': component.get("v.triggerEventObjectApiName")},
                              ];
       } else{
            optionsReceived =   [
                                {'label': noneOptionName, 'value': 'None'},
                               // {'label': component.get('v._label12'), 'value': 'Case'},
                                {'label': component.get("v.triggerEventObjectLabel"), 'value': component.get("v.triggerEventObjectApiName")},
                                {'label': component.get('v._label13'), 'value': 'Previous Task'},
                              ];
       }
       var options = [];
       for(var opt of optionsReceived){
           var item = {
               "label" : opt.label,
               "value" : opt.value,
           };
           options.push(item);
       }

       component.set('v.recordOptions', options);
   },

   onRecordChange : function(component, event, helper){
       var recordType = event.getSource().get("v.value");

       if(recordType == 'Previous Task'){
        component.set('v.conditionalBuilderRecordType','Task');
        component.set('v.conditionalBuilderRecordValue','previousActivity');
        this.showConditionalBuilderInfoDiv(component, event, helper);
       }
       else{
        component.set('v.conditionalBuilderRecordType',recordType);
        component.set('v.conditionalBuilderRecordValue',recordType);
        this.hideConditionalBuilderInfoDiv(component, event, helper);
       }

       if(recordType!='None'){
            var conditionBuilder = component.find('conditionalBuilder');
            conditionBuilder.initializeComponent();
       }
   },




   conditionsToSave : function(component, event, helper){
        var conditionalBuilder = component.find("conditionalBuilder");
        var conditionsJSON = [];
        if(typeof conditionalBuilder != 'undefined'){
            if(!Array.isArray(conditionalBuilder)){
                conditionsJSON = conditionalBuilder.getBuilderJSONToSave();
            }else{
                conditionsJSON = conditionalBuilder[0].getBuilderJSONToSave();
            }
        }
        return conditionsJSON;
   },

   displayConditions : function(component, event, helper){
       var activityConditions = JSON.parse(component.get('v.currentConditions'));
       var recordConditionsList = [];
       if(!$A.util.isEmpty(activityConditions)){
           recordConditionsList = activityConditions.LstConditionsPerObject;
           if(typeof recordConditionsList != 'undefined'){
               var recordConditions = recordConditionsList[0];
               var objectType = recordConditions.ObjectType;
               component.set('v.conditionalBuilderRecordType',objectType);
               component.set('v.conditionalBuilderRecordValue', objectType);

               if(!$A.util.isUndefinedOrNull(recordConditions.RecordValue)){
                    var recordValue = recordConditions.RecordValue;
                    component.set("v.conditionalBuilderRecordValue",recordValue);

                    if(recordValue == 'previousActivity'){
                       objectType = 'Previous Task';
                       component.set('v.conditionalBuilderRecordValue', recordValue);
                       this.showConditionalBuilderInfoDiv(component,event, helper);
                   }
               }
               else if(objectType == 'Task' && component.get('v.triggerEventObjectApiName')!='Task'){
                   objectType = 'Previous Task';
                   component.set('v.conditionalBuilderRecordValue', 'previousActivity');
                   this.hideConditionalBuilderInfoDiv(component,event, helper);
               }

               component.set('v.recordType', objectType);
               component.set("v.recordConditions",recordConditionsList);
           }
       }
   },

   showConditionalBuilderInfoDiv : function(component, event, helper, taskFields) {
        var infoDivId = component.find('infoDivId');
        $A.util.removeClass(infoDivId,'slds-hide');
        $A.util.addClass(infoDivId,'slds-show');
   },

   hideConditionalBuilderInfoDiv : function(component, event, helper, taskFields) {
        var infoDivId = component.find('infoDivId');
        $A.util.removeClass(infoDivId,'slds-show');
        $A.util.addClass(infoDivId,'slds-hide');
    },

   initiateUserTaskProperties : function(component, event, helper, taskFields) {

       var taskFieldsList = JSON.parse(taskFields);
       component.set("v.taskProperties",taskFieldsList);
   },
   recordFieldsToSave : function(component,event,helper){
       component.set('v.taskProperties',null);
       var fieldMapper = component.find("fieldMappingBuilder");
       var fieldMappingList = [];
       var fieldMappingJSON = [];
       if(typeof fieldMapper != 'undefined'){
           fieldMappingJSON = fieldMapper.getBuilderJSONToSave();
       }else{
           return;
       }
       if(component.get("v.isValid") && !fieldMappingJSON[0]){
           component.set("v.isValid",fieldMappingJSON[0]);
       }
       if(!fieldMappingJSON[0]){
           return;
       }
       fieldMappingList = fieldMappingJSON[1];
       var objectDetails ={
          "qualifiedApiName" : component.get("v.selectedRecord.QualifiedApiName")
       };
       var outcomeTaskDetails ={
          "create" : component.get("v.createOutcomeTask")
       };

       var recordFieldsMapping =
       {
           "fieldMapping" : fieldMappingList,
           "objectDetails" : objectDetails,
           "outcomeTaskDetails" : outcomeTaskDetails
       };
       component.set('v.taskJSON', JSON.stringify(recordFieldsMapping));
   },
   taskPropertiesToSave : function(component, event, helper){
        var userTaskProperties = component.find("userTaskProperties");
        var userTaskPropertiesList = [];
        var fieldMappingJSON = [];
        if(typeof userTaskProperties != 'undefined'){
            fieldMappingJSON = userTaskProperties.getBuilderJSONToSave();
        }else{
          return;
        }
        if(component.get("v.isValid") && !fieldMappingJSON[0]){
          component.set("v.isValid",fieldMappingJSON[0]);
        }
        if(!fieldMappingJSON[0]){
            return;
        }
        userTaskPropertiesList = fieldMappingJSON[1];
        var taskProperties = {"requiredFieldSet" : userTaskPropertiesList};
        component.set('v.taskProperties', JSON.stringify(taskProperties));
   },

   onSingleSelectChange: function(component, event, helper) {

        var selectCmp = component.find("activityType").get("v.value");
        //Below the order of "if" conditions should not be changed.
        //Changes will impact the working of type and subtype of BRE.
        if (selectCmp =='Automation Task' || selectCmp == 'User Task')
            {
                component.set("v.isRecordUpdation",false);
                if(component.get('v.newActivity.internalactivitytype') != 'Sequence Task'){
                    component.set("v.isCriteriaRequired",true);
                }
                component.set("v.isDueDateRequired",true);
                component.set("v.AutomationTaskDisplay",true);
                component.set("v.createOutcomeTask",false);
                if(component.get("v.selectedRecord") != "{}"){
                    component.set("v.selectedRecord","{}");
                }
                component.set("v.isRecordCreation",false);

                if(selectCmp =='Automation Task'){
                    helper.getSupportPlanAutomationTaskData(component, event, helper, null);
                }
                if(component.get("v.showTaskFields") == false){
                     component.set("v.showTaskFields",true);
                     var activity = component.get("v.newActivity");
                     helper.initiateUserTaskProperties(component, event, helper, activity.usertaskfields);
                }
                if(selectCmp =='User Task'){
                    component.set("v.AutomationTaskDisplay",false);
                }


            }
        else if(selectCmp == 'Create Record' || selectCmp == 'Publish Platform Event' || selectCmp == 'Update Record'){
                component.set("v.AutomationTaskDisplay",false);
                component.set("v.userTaskPropertiesCount",0);
                component.set("v.isPlatformContext",false);
                component.set("v.showTaskFields",false);
                component.set("v.isDueDateRequired",false);
                if(selectCmp == 'Create Record' || selectCmp == 'Publish Platform Event'){
                    component.set("v.isRecordCreation",true);
                    component.set("v.isRecordUpdation",false);
                }
                if(selectCmp == 'Update Record'){
                    component.set("v.taskJSON",'');
                    component.set("v.isRecordUpdation",true);
                    component.set("v.isRecordCreation",false);
                }
                if(component.get('v.newActivity.internalactivitytype') != 'Sequence Task'){
                    component.set("v.isCriteriaRequired",true);
                }
                if(component.get("v.selectedRecord") != "{}"){
                    component.set("v.selectedRecord","{}");
                }

                if(selectCmp == 'Publish Platform Event'){
                    component.set("v.isPlatformContext",true);
                    component.set("v.objectType",'Platform Event Object');
                }else{
                    component.set("v.objectType",'Data Object');
                }
        }
        if(component.get("v.isCriteriaRequired")){
            if(component.find('behaviorList').get('v.value') == 'No Condition'){
                var apexClass = component.find("apexClass");
                $A.util.addClass(apexClass,'slds-hide');
                $A.util.removeClass(apexClass,'slds-show');
                var fieldMappingContainer = component.find("fieldMappingContainer");
                $A.util.removeClass(fieldMappingContainer,'slds-show');
                $A.util.addClass(fieldMappingContainer,'slds-hide');
                var conditionalBuilder = component.find("conditionalBuilderContainer");
                $A.util.removeClass(conditionalBuilder,'slds-show');
                $A.util.addClass(conditionalBuilder,'slds-hide');
            }
        }
   },

   getSupportPlanAutomationTaskData: function(component, event, helper, subTypeValue){

        var action=component.get('c.getSupportPlanAutomationTaskData');
        var subTypeArray = [];
        var actionClassMap = new Map();
        action.setParams({
                            "supportPlanID" : component.get("v.recordId"),
                            "triggerEventObjectName" : component.get("v.triggerEventObjectApiName")
                        });
        var subType;

        action.setCallback(this,function(response){
            var state=response.getState();
            if('SUCCESS'==state){
                var dependentOptions = [{'label': component.get("v.noneOptionName"), 'value': '__none'}];
                var customMetadataWrapper=response.getReturnValue();

                for (var i = 0; i < customMetadataWrapper.length; i++) {

                    if( customMetadataWrapper[i].subTypePicklist !=undefined){
                        dependentOptions.push({
                            class: "optionClass",
                            label: customMetadataWrapper[i].subTypePicklist ,
                            value: customMetadataWrapper[i].subTypePicklist
                        });

                        if(customMetadataWrapper[i].automationTaskLightningComponent != undefined){

                            subTypeArray.push({
                                picklistvalue: customMetadataWrapper[i].subTypePicklist,
                                lightningComponent: customMetadataWrapper[i].automationTaskLightningComponent

                            });

                            actionClassMap.set(customMetadataWrapper[i].subTypePicklist, customMetadataWrapper[i].actionClass);
                        }
                    }



                }
                component.set("v.typeSubtypeMap",subTypeArray);
                component.set("v.actionClassMap" , actionClassMap);

                component.find("subType").set("v.options",dependentOptions );
                subType = dependentOptions[0].value;
                if(!$A.util.isUndefinedOrNull(subTypeValue)){
                    subType = subTypeValue;
                    component.find("subType").set("v.value",subTypeValue );
                }
                helper.dynamicSubtypeComponent(component, event, helper, subType);

            }else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);

   },
   dynamicSubtypeComponent:function(component, event, helper, picklistValue){
       var componentName;
       var subTypeArray = component.get("v.typeSubtypeMap");

       for(var i=0; i< subTypeArray.length ; i++){

           if (subTypeArray[i].picklistvalue == picklistValue ){
               componentName = subTypeArray[i].lightningComponent;
               console.log('componentName'+componentName);
               break;
           }
       }


        if(componentName != undefined){
        $A.createComponent(
            componentName,
            {
                "aura:id"       : componentName,
                "supportPlanID" : component.get("v.activity.supportplan"),
                "activityID"    : component.get("v.activity.Id"),
                "taskJSON"      : component.get("v.taskJSON"),
                "isDisabled"    : component.get("v.disabled"),
            },

            function(newCmp, status, errorMessage){
                var subType    = component.find("subType");
                subType.set("v.errors",null);
                if (status === "SUCCESS") {
                    var childComponentDiv    = component.find("AutomationTaskLightningComponent");
                   // var childComponentBody	= childComponentDiv.get("v.body");
                             /*if(reInitiate){
                             childComponentBody 		= [];
                             }*/
                             var childComponentBody 		= [];
                             childComponentBody.push(newCmp);
                             childComponentDiv.set("v.body",childComponentBody);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                          // Show offline error
                }
                else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    subType.set("v.errors",[{message:component.get("v.customMetadataErrorMessage")}]);
                }
            }
        );

   }
   }

})