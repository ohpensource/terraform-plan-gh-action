function extractSummary(lines) {

    const REGEX_TF_SUMMARY = /Plan: (?<resources_to_add>[\d]+) to add, (?<resources_to_change>[\d]+) to change, (?<resources_to_delete>[\d]+) to destroy./

    let result
    const validOutput = lines.reverse().find(line => {
        const matchRegex = line.match(REGEX_TF_SUMMARY);
        if (matchRegex) {
            result = {
                numResourcesToAdd: matchRegex.groups?.resources_to_add,
                numResourcesToChange: matchRegex.groups?.resources_to_change,
                numResourcesToDelete: matchRegex.groups?.resources_to_delete,
                summary: line
            }
        }
        return matchRegex;
    });

    if (!validOutput) {
        throw new Error(`terraform plan provided is not valid`);
    }

    return result
}

function extractResourcesToBeDeleted(lines) {

    const REGEX_DETECT_DESTROY = /[\s]?# (?<resource>.*)[\s]+will be destroyed/
    const REGEX_DETECT_REPLACE = /[\s]?# (?<resource>.*)[\s]+must be replaced/

    let result = []
    lines.forEach(line => {
        extractResourceUsingRegex(line, REGEX_DETECT_DESTROY, result);
        extractResourceUsingRegex(line, REGEX_DETECT_REPLACE, result);
    });

    return result
}

function extractResourceUsingRegex(line, regex, result) {
    const match = line.match(regex);
    if (match) {
        const resource = match.groups.resource;
        if (resource) {
            result.push(resource);
        }
    }
}

module.exports = {
    extractSummary,
    extractResourcesToBeDeleted
};