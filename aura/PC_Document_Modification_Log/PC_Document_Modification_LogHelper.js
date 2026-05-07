/**
 * Created by havalakki on 1/12/2018.
 */
({
    setNamespace : function(component) {
        var ns = CH_PC_Util.getNamespace(component);
        var nsPrefix = CH_PC_Util.getNamespacePrefix(component);
        component.set("v.namespace", ns);
        component.set("v.namespacePrefix", nsPrefix);
    },
    showHideSection : function(component,event,secId) {
	  var acc = component.find(secId);
        	for(var cmp in acc) {
        	$A.util.toggleClass(acc[cmp], 'slds-show');  
        	$A.util.toggleClass(acc[cmp], 'slds-hide');  
       }
	},
	goToSelectedLink : function(component,event,helper){
        var objectId = event.currentTarget.id;
        if(component.get("v.isCommunity")){
            var urlEvent = $A.get("e.force:navigateToURL");
            if(component.get("v.navigateToObjectPage")){
                var objectName = event.currentTarget.getAttribute("data-id");
                var namespace = component.get("v.namespace");
                var objectNameWithoutNamespace = objectName.replace(namespace.concat('__'),"");
                var objectNameWithoutC = objectNameWithoutNamespace.replace("__c", "");
                var objectPageName = objectNameWithoutC.replaceAll("_", "-").toLowerCase();
                urlEvent.setParams({
                    "url": '/'+ objectPageName +'/' + objectId,
                    "isredirect" :false
                });
            }else{
                urlEvent.setParams({
                    "url": '/detail/' + objectId,
                    "isredirect" :false
                });
            }
            urlEvent.fire();
        }else{
            window.open('/one/one.app#/sObject/' + objectId + '/view', '_blank', "toolbar=yes,scrollbars=yes,resizable=yes,left=1050,top=100,width=800,height=800");
        }
    },
    doneRendering : function(component, event) {
            if (typeof $ == 'undefined' || $(".detailsAccordion").find("h3").length == 0) { return; }
            $(".detailsAccordion").addClass("ui-accordion ui-accordion-icons ui-widget ui-helper-reset")
            .find("h3")
            .addClass("ui-accordion-header ui-helper-reset ui-state-default ui-corner-top ui-corner-bottom")
            .unbind("hover").hover(function() { $(this).toggleClass("ui-state-hover"); })
            .prepend('<span class="ui-icon ui-icon-triangle-1-e"></span>')
            .unbind("click").click(function() {
                $(this).find("> .ui-icon").toggleClass("ui-icon-triangle-1-e ui-icon-triangle-1-s")
                .end().next().toggleClass("ui-accordion-content-active").slideToggle();
                return false;
            })
            .next()
            .addClass("ui-accordion-content ui-helper-reset ui-widget-content ui-corner-bottom")
        },

   getLogs : function(component) {
           var action = component.get("c.getModificationLogs");
           action.setParams({
             docId : component.get("v.recordId")
           });
           action.setCallback(this, function(a) {
            var state = a.getState();
               if (state === "SUCCESS") {
                   if(component.isValid()) {
                        component.set("v.showDescriptionField", a.getReturnValue().showDocumentLogFieldVal);
              			component.set("v.lstDocumentsLogs", a.getReturnValue().documentLogWrapperList);
              			component.set("v.isCommunity", a.getReturnValue().isCommunity);
                   }
               } else if (state ==="ERROR"){
                   var errors = a.getError();
                   console.log(JSON.stringify(errors));
                   var errText = component.get("v.ErrorText");
                   if (errors) {
                       if (errors[0] && errors[0].message) {
                           console.log(errText);
                       }
                   } else {
                       console.log("Unknown error");
                   }
               }
           });
           $A.enqueueAction(action);
       },
})