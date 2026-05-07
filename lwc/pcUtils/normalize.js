export function normalizeString(value, config = {}) {
    const { fallbackValue = '', validValues, toLowerCase = true } = config;
    let normalized = (typeof value === 'string' && value.trim()) || '';
    normalized = toLowerCase ? normalized.toLowerCase() : normalized;
    if (validValues && validValues.indexOf(normalized) === -1) {
        normalized = fallbackValue;
    }
    return normalized;
}

export function normalizeBoolean(value) {
    return typeof value === 'string' || !!value;
}

export function normalizeArray(value) {
    if (Array.isArray(value)) {
        return value;
    }
    return [];
}

export function normalizeRecordId(recordId) {
    if (!recordId) {
        return null;
    }

    if (recordId.length === 15) {
        let suffix = '';
        const CASE_DECODE_STRING = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456';

        for (let set = 0; set < 3; ++set) {
            let decodeValue = 0;
            for (let bit = 0; bit < 5; bit++) {
                const c = recordId.charAt(set * 5 + bit);
                if (c >= 'A' && c <= 'Z') {
                    decodeValue += 1 << bit;
                }
            }

            suffix += CASE_DECODE_STRING.charAt(decodeValue);
        }

        return recordId + suffix;
    } else if (recordId.length === 18) {
        return recordId;
    }
    return null;
}