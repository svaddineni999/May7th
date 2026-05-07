({
    setNamespace : function(component, event, helper) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    setPageReferenceValues: function(component, event, helper) {
        var namespace = component.get("v.namespace");
        var pageReference = component.get("v.pageReference");
        var selectedLocationQualifiedApiName = CH_PC_Util.getQualifiedQueryParam(component,'selectedLocation',namespace);
        var selectedLocation;
        if(pageReference && pageReference.state){
            if(pageReference.state[selectedLocationQualifiedApiName] != 'NULL' && pageReference.state[selectedLocationQualifiedApiName] != 'undefined'){
                selectedLocation = pageReference.state[selectedLocationQualifiedApiName];
            }
        }else{
            var query = location.search.substr(1);
            var result = {};
            query.split("&").forEach(function(part) {
                var item = part.split("=");
                if(!$A.util.isUndefinedOrNull(item[0]) && !$A.util.isUndefinedOrNull(item[1])){
                    result[item[0]] = decodeURIComponent(item[1]);
                }
            });
            selectedLocation = ($A.util.isUndefinedOrNull(selectedLocation))?result[selectedLocationQualifiedApiName]:selectedLocation;
        }
        component.set("v.selectedLocation", (selectedLocation != undefined)? selectedLocation :component.get("v.selectedLocation"));
    },

    getParticipantData : function(component, event, helper) {
        var selectedLocation = component.get("v.selectedLocation");
        var action =  component.get("c.getInitData");
        action.setParams({
            selectedLocation: selectedLocation
        });
        action.setCallback(this, function(response){
            var state= response.getState();
            if (state == "SUCCESS"){
                var initData =response.getReturnValue();
                component.set("v.participantList" , initData.participantList);
                component.set("v.fieldLabels",initData.fieldLabels);
            }else{
                console.log('getParticipantData failed with state>>'+state);
            }
        });
        $A.enqueueAction(action);
    },

    saveParticipantData : function(component, event, helper) {
        helper.getSelectedParticipantsList(component, event, helper);
        var interactionRecordId = component.get("v.interactionRecordId");
        var selectedParticipants = component.get("v.selectedParticipants");
        if(!$A.util.isUndefinedOrNull(interactionRecordId) && !$A.util.isUndefinedOrNull(selectedParticipants) &&
        interactionRecordId != '' && selectedParticipants.length != 0){
            var action =  component.get("c.saveInteractionParticipants");
            action.setParams({
                interactionRecordId: interactionRecordId,
                selectedParticipants: selectedParticipants
            });
            action.setCallback(this, function(response){
                var state= response.getState();
                if (state == "SUCCESS"){
                    console.log('saving Participants successfull');
                }else{
                    console.log('saveParticipantInfo failed with state>>'+state);
                }
            });
            $A.enqueueAction(action);
        }
    },

    getSelectedParticipantsList : function(component, event, helper) {
        var selectedParticipants = [];
        var checkvalue = component.find("checkParticipant");
        if(!$A.util.isUndefinedOrNull(checkvalue)){
            if(!Array.isArray(checkvalue)){
                if (checkvalue.get("v.value") == true) {
                    selectedParticipants.push(checkvalue.get("v.text"));
                }
            }else{
                for (var i = 0; i < checkvalue.length; i++) {
                    if (checkvalue[i].get("v.value") == true) {
                        selectedParticipants.push(checkvalue[i].get("v.text"));
                    }
                }
            }
            console.log('selectedParticipants-' + selectedParticipants);
            component.set("v.selectedParticipants",selectedParticipants);
        }
    },
})