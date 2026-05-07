export { deepCopy, arraysEqual } from './utility';
export {
    normalizeBoolean,
    normalizeString,
    normalizeArray,
    normalizeRecordId
} from './normalize';

import { DensityValues } from './constants';
export const densityValues = DensityValues;

export {
    getFieldsForLayout,
    getCompoundFields,
    compoundFieldIsUpdateable,
    compoundFieldIsCreateable,
    isCompoundField,
    extractLayoutFromLayouts,
    isPersonAccount,
    UNSUPPORTED_REFERENCE_FIELDS
} from './fieldUtils';