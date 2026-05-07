/* eslint-disable no-console */
/* eslint-disable no-debugger */
import { LightningElement, wire } from 'lwc';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';

export default class DocumentTagsEventHandler extends LightningElement {

    @wire(CurrentPageReference) pageRef;
    
    connectedCallback() {
        registerListener('documenttagupdateevent', this.handleEvent, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handleEvent(event) {
        let documentId = event.detail.documentId;
        let selectedCategory = event.detail.selectedCategory;
        let selectedCategoryStatus = event.detail.selectedCategoryStatus;

        const toAuraEvent = new CustomEvent('documenttagupdateevent', {detail:{'documentId': documentId,
        "selectedCategory": selectedCategory,
        "selectedCategoryStatus" : selectedCategoryStatus }});
        this.dispatchEvent(toAuraEvent);
      }    
}