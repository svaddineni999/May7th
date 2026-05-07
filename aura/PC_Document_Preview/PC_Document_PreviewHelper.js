/**
 * Created by havalakki on 1/17/2018.
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

    getInit : function(component, event, helper) {
            //Testing code to capture the click event on child component to refresh the parent
            //helper.recordTypePicklist(component, event, helper);
            //helper.getFieldSetName(component, event, helper);
            var message = event.getParam("message");
            component.set("v.messageFromEvent", message);
            component.set("v.loadFaxContainer", false);
            component.set("v.loadEmailContainer", true);
    },
})