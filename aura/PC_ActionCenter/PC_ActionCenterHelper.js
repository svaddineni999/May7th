/**
 * Created by mapatil on 8/8/2017.
 * Modified Tejas Patel Sep 21 2017 new attribute taskRecordTypes
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

    showToast : function(title, type, message) {
        var toastEvent  = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
        });
        toastEvent.fire();
    },

    setupActionCenter : function(component, event, helper) {
        var caseId = component.get("v.recordId");
        var action = component.get("c.setupActionCenter");
        action.setParams({
            "caseId": caseId
        });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (component.isValid() && state === "SUCCESS") {
                var returnValue = response.getReturnValue();
                console.log(returnValue);
                component.set("v.actionCenterConfigExists", returnValue.actionCenterConfigExists);
                component.set("v.communicationsMetadata", returnValue.lstCommunicationsMetadata);
                component.set("v.workflowMetadata", returnValue.lstWorkflowsMetadata);
                component.set("v.toolsMetadata", returnValue.lstToolsMetadata);
                component.set("v.caseDetails", returnValue.caseDetails);
                component.set("v.taskRecordTypes", returnValue.taskRecordTypes);
                console.log('lstCommunicationsMetadata: ' + returnValue.lstCommunicationsMetadata);
                console.log('lstWorkflowsMetadata: ' + returnValue.lstWorkflowsMetadata);
                console.log('lstToolsMetadata: ' + returnValue.lstToolsMetadata);
                helper.setMetadataActionLabel(component, event , helper);
                helper.createDivsDynamically(component, event , helper);
            } else {
                console.log("setupActionCenter: Failed with state: " + state);
            }
        });

        $A.enqueueAction(action);
    },

    //The following method helps to create the action center icons dynamically.
    createDivsDynamically : function(component, event , helper){

        var communicationsMetadataList=component.get('v.communicationsMetadata');
        var workflowMetadataList=component.get('v.workflowMetadata');
        var toolsMetadataList=component.get('v.toolsMetadata');
        /*In the following method callouts the third paramter is the section index on the component which helps to decide
        which section needs to be populated on the screen. i.e. 1:Communication, 2:Workflow, 3:Tools*/
        helper.createDynamicSection(component,communicationsMetadataList,1);
        helper.createDynamicSection(component,workflowMetadataList,2);
        helper.createDynamicSection(component,toolsMetadataList,3);

    },

    createDynamicSection: function(component,metadataList,metadataSectionIndex){
        var divIndex=0;

        if(undefined!=metadataList&&metadataList.length>0){

            for(var j=0;j<3;j++){
                divIndex=0;

                if(j==0){
                    divIndex=1;
                }
                else if(j==1){
                    divIndex=2;
                }
                else if(j==2){
                    divIndex=3;
                }

                for(var i=j;i<metadataList.length;i+=3){

                /*The following list has the components which need to be created for every icon under the section
                The structure which would be created is as follows:
                <div>
                    <button>
                        <lightning:icon></lightning:icon>
                        <p></p>
                    </button>
                </div>
                */
                    if(undefined!=metadataList[i]){
                            var dynamicCmps = [
                                                ["aura:html", {
                                                    "tag": "div",
                                                    "body": "",
                                                    "HTMLAttributes": {
                                                        "class": "slds-align-top slds-p-bottom_xxx-small slds-text-align_center"
                                                     }
                                                }],
                                                ["aura:html", {
                                                    "body": "",
                                                    "tag" : "button",
                                                    "HTMLAttributes": {
                                                        "class":"slds-button slds-button_icon iconButtonClass",
                                                        "value":metadataList[i].actionComponent,
                                                        "name": metadataList[i].actionLabel,
                                                        "disabled":"false",
                                                        "data-componentAttributes" : metadataList[i].actionComponentAttributes,
                                                        "onclick": component.getReference("c.callActionComponent")
                                                }}],
                                                ["lightning:icon", {
                                                    "body": "",
                                                    "iconName":metadataList[i].actionIcon,
                                                    "alternativeText": metadataList[i].actionLabel,
                                                    "HTMLAttributes": {
                                                        "class":"slds-button slds-button_icon",
                                                        "size":"medium"
                                                    }
                                                }],
                                                ["lightning:formattedText", {
                                                     "value": component.getReference('v.'+component.get('v.actionTypeMap')[metadataSectionIndex]+'.'+i+'.actionLabel'),
                                                     "title": component.getReference('v.'+component.get('v.actionTypeMap')[metadataSectionIndex]+'.'+i+'.actionLabel'),
                                                     "class":"slds-p-top_xx-small lineheight pc-display-block"
                                                }]
                                            ];
                    console.log('dynamicCmps: '+JSON.stringify(dynamicCmps));

                    this.createDivComponents(component,dynamicCmps,divIndex,metadataSectionIndex);

                    }

                }
            }

         }
    },

    //The following method created the components dynamically and places them under proper html element: div's body
    createDivComponents: function(component,dynamicComponentsList,divIndex,metadataSectionIndex){
        $A.createComponents(dynamicComponentsList,
              function (newCmps, status, errorMessage) {
                   if (status === "SUCCESS")
                   {
                        console.log('components:!! '+newCmps);
                        var parentDiv;
                       if(divIndex==1||divIndex==2||divIndex==3){
                           if(metadataSectionIndex==1){
                                parentDiv = component.get('v.metadataDiv_C_'+divIndex);
                           }
                           else if(metadataSectionIndex==2){
                                parentDiv = component.get('v.metadataDiv_W_'+divIndex);
                           }
                           else if(metadataSectionIndex==3){
                                parentDiv = component.get('v.metadataDiv_T_'+divIndex);
                           }
                       }

                        if(undefined!=parentDiv){
                              var parentDivBody=parentDiv;
                              console.log('parentDivBody: '+parentDivBody);

                              console.log('newCmps[0]: '+newCmps[0]);
                              var innerDiv=newCmps[0];
                              var buttonElement=newCmps[1];
                              var buttonIconElement=newCmps[2];
                              var buttonLabelElement=newCmps[3];

                              var buttonElementBody=buttonElement.get('v.body');
                              buttonElementBody.push(buttonIconElement);
                              buttonElementBody.push(buttonLabelElement);
                              buttonElement.set('v.body',buttonElementBody);

                              innerDiv.set('v.body',buttonElement);
                              parentDivBody.push(innerDiv);

                                if(divIndex==1||divIndex==2||divIndex==3){

                                    if(metadataSectionIndex==1){
                                            parentDiv = component.set('v.metadataDiv_C_'+divIndex, parentDivBody);
                                    }
                                    else if(metadataSectionIndex==2){
                                            parentDiv = component.set('v.metadataDiv_W_'+divIndex, parentDivBody);
                                    }
                                    else if(metadataSectionIndex==3){
                                            parentDiv = component.set('v.metadataDiv_T_'+divIndex, parentDivBody);
                                    }

                                }

                          }

                   }
              }
         );
    },

    //The following method helps to set Action Label dynamically for all metadata types
    setMetadataActionLabel :  function(component, event, helper){
    	helper.setActionLabel(component, component.get("v.actionTypeMap")[1], helper);
    	helper.setActionLabel(component, component.get("v.actionTypeMap")[2], helper);
    	helper.setActionLabel(component, component.get("v.actionTypeMap")[3], helper);
    },

    //The following method helps to set dynamic custom Label for action center
    setActionLabel :  function(component, attributeName, helper){
        var actionMetadata = component.get('v.'+attributeName);
        for(var i=0; i<actionMetadata.length; i++) {
            var actionIconLabel = CH_PC_Util.getCustomLabelValue(actionMetadata[i].actionLabel);
            component.set('v.'+attributeName+'.'+i+'.actionLabel', actionIconLabel);
        }
    }

})