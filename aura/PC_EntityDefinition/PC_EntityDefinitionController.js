/**
 * Created by tusarora on 3/11/2020.
 */
({

    doInit : function(component,event,helper){
        debugger;
        component.set("v.defaultPill",true); 
		var getInputkeyWord = '';
        var isPlatformEventContext = false;

        if(component.get("v.selectedRecord") != "{}" ){
           
        	if(component.get("v.selectedRecord.QualifiedApiName").endsWith('__e')){
            	isPlatformEventContext = true;
        	}
    		
            helper.searchHelper(component, event, getInputkeyWord, isPlatformEventContext); 
        }else{
            var a = component.get('c.clear');
            $A.enqueueAction(a);

        }
        
        
    },
   onfocus : function(component,event,helper){
       $A.util.addClass(component.find("mySpinner"), "slds-show");
        var forOpen = component.find("searchRes");
            $A.util.addClass(forOpen, 'slds-is-open');
            $A.util.removeClass(forOpen, 'slds-is-close');
        // Get Default 5 Records order by createdDate DESC
         var getInputkeyWord = '';
         var isPlatformEventContext = component.get("v.isPlatformEventContext");
         helper.searchHelper(component, event, getInputkeyWord, isPlatformEventContext);
    },
    onblur : function(component,event,helper){
        component.set("v.listOfSearchRecords", null );
        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
    },
    keyPressController : function(component, event, helper) {
       // get the search Input keyword
         var getInputkeyWord = component.get("v.SearchKeyWord");
         var isPlatformEventContext = component.get("v.isPlatformEventContext");
       // check if getInputKeyWord size id more then 0 then open the lookup result List and
       // call the helper
       // else close the lookup result List part.
        if( getInputkeyWord.length > 0 ){
             var forOpen = component.find("searchRes");
               $A.util.addClass(forOpen, 'slds-is-open');
               $A.util.removeClass(forOpen, 'slds-is-close');
            helper.searchHelper(component, event, getInputkeyWord, isPlatformEventContext);
        }
        else{
             component.set("v.listOfSearchRecords", null );
             var forclose = component.find("searchRes");
               $A.util.addClass(forclose, 'slds-is-close');
               $A.util.removeClass(forclose, 'slds-is-open');
          }
	},

  // function for clear the Record Selaction
    clear :function(component,event,helper){
        if(!component.get("v.disabled")){
            
         var pillTarget = component.find("lookup-pill");
         var lookUpTarget = component.find("lookupField");

         $A.util.addClass(pillTarget, 'slds-hide');
         $A.util.removeClass(pillTarget, 'slds-show');

         $A.util.addClass(lookUpTarget, 'slds-show');
         $A.util.removeClass(lookUpTarget, 'slds-hide');

         component.set("v.SearchKeyWord",null);
         component.set("v.listOfSearchRecords", null );
         component.set("v.selectedRecord", "{}" );

        } 
    },

    handleComponentEvent : function(component, event, helper) {
        // get the selected Account record from the Component event
       console.log('ParentEventCapture::::');
       var selectedEntityDefinitionFromEvent = event.getParam("recordByEvent");
	   component.set("v.selectedRecord" , selectedEntityDefinitionFromEvent);
       
        var lookupPill = component.find("lookup-pill");
           $A.util.addClass(lookupPill, 'slds-show');
           $A.util.removeClass(lookupPill, 'slds-hide');

        var forclose = component.find("searchRes");
           $A.util.addClass(forclose, 'slds-is-close');
           $A.util.removeClass(forclose, 'slds-is-open');

        var lookUpTarget = component.find("lookupField");
            $A.util.addClass(lookUpTarget, 'slds-hide');
            $A.util.removeClass(lookUpTarget, 'slds-show');

	},
    changeSelectedRecord : function(component, event, helper){

        var currentValue =event.getParam("value") ;
        var oldValue = event.getParam("oldValue");
        if( currentValue == "{}" && oldValue != currentValue){
            var a = component.get('c.clear');
        	$A.enqueueAction(a);
        }
    }
})