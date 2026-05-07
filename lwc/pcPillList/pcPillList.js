import { LightningElement, api } from 'lwc';

export default class PC_PillList extends LightningElement {
    _pills;

    @api
    set pills(values) {
        if (Array.isArray(values)) {
            this._pills = values.map((value) => {
                return {
                    label: value.label,
                    value: value.value,
                    selected: value.selected === true
                };
            });
        } else {
            this._pills = [];
        }
    }
    get pills() {
        return this._pills;
    }

    handleClick(event) {
        const value = event.target.value;
        this._pills = this._pills.map((pill) => {
            if (pill.value === value) {
                return Object.assign({}, pill, { selected: !pill.selected });
            }
            return pill;
        });
        this.fireFiltersChangeEvent();
    }

    fireFiltersChangeEvent() {
        const pillLabels = this._pills
            .filter((pill) => pill.selected)
            .map((pill) => pill.value);
        this.dispatchEvent(
            new CustomEvent('filterschange', {
                detail: {
                    filters: pillLabels
                }
            })
        );
    }
}