const fs = require('fs');
const core = require('@actions/core');

const skip_summary_if_no_changes = (process.env.SKIP_SUMMARY_IF_NO_CHANGES === 'true')
const skip_summary = (process.env.SKIP_SUMMARY === 'true')
const file = process.env.TEMP_FILE

if (!fs.existsSync(file)) {
    throw new Error(`file provided does not exist`)
}

const tf_show_output = fs.readFileSync(file)
const lines = tf_show_output.toString().split(`\n`).filter(x => x.length > 0)

let { num_resources_to_add, num_resources_to_change, num_resources_to_delete, summary } = extractSummary(lines)
let resources_to_be_deleted = extractResourcesToBeDeleted(lines)

core.setOutput('resources_to_add', num_resources_to_add);
core.setOutput('resources_to_change', num_resources_to_change);
core.setOutput('resources_to_delete', num_resources_to_delete);

infra_changed = num_resources_to_add > 0 || num_resources_to_change > 0 || num_resources_to_delete > 0
show_summary = (infra_changed || !skip_summary_if_no_changes) && (!skip_summary)
if (show_summary) {
    let markdownSummary = summary;
    if (resources_to_be_deleted.length > 0) {
        markdownSummary += `\nResources to be deleted:\n`
        resources_to_be_deleted.forEach(x => markdownSummary += `* ${x}\n`)
    }

    core.summary
        .addRaw(markdownSummary)
        .write()
}

function extractSummary(lines) {

    const REGEX_TF_SUMMARY = /Plan: (?<resources_to_add>[\d]+) to add, (?<resources_to_change>[\d]+) to change, (?<resources_to_delete>[\d]+) to destroy./
    const REGEX_TF_OUTPUTS = /Changes to Outputs:/

    let result
    const resourcesChanged = lines.reverse().find(line => {
        const matchRegex = line.match(REGEX_TF_SUMMARY);
        if (matchRegex) {
            result = {
                num_resources_to_add: matchRegex.groups?.resources_to_add,
                num_resources_to_change: matchRegex.groups?.resources_to_change,
                num_resources_to_delete: matchRegex.groups?.resources_to_delete,
                summary: line
            }
        }
        return matchRegex;
    });

    const outputsChanged = lines.reverse().find(line => {
        const matchRegex = line.match(REGEX_TF_OUTPUTS);
        if (matchRegex) {
            if (result) {
                result.summary += 'Outputs changed.'
            } else {
                result = {
                    num_resources_to_add: 0,
                    num_resources_to_change: 0,
                    num_resources_to_delete: 0,
                    summary: 'Output changes detected only.'
                }
            }
        }
        return matchRegex;
    })

    if (!resourcesChanged && !outputsChanged) {
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

