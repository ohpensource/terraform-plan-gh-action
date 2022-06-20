// WHEN THIS FILE IS MERGE TO MAIN IT IS COMPILED WITH ALL ITS DEPENDENCIES into the `dist` directory
// In case you want to modify it and test it, execute npm run prepare to compile it locally and then push the changes in the `dist` directory

const fs = require('fs');
const core = require('@actions/core');
const parser = require('./modules/parser.js')
const logger = require('./modules/logger.js')

const file = process.env.FILE_CONTAINING_TF_SHOW_OUTPUT
const settingsPath = process.env.SETTINGS_FILE

if (!fs.existsSync(file)) {
    throw new Error(`file provided does not exist`)
}

const tf_show_output = fs.readFileSync(file)
const lines = tf_show_output.toString().split(`\n`).filter(x => x.length > 0)

let { numResourcesToAdd, numResourcesToChange, numResourcesToDelete, summary } = parser.extractSummary(lines)
let resources_to_be_deleted = parser.extractResourcesToBeDeleted(lines)

core.setOutput('resources_to_add', numResourcesToAdd);
core.setOutput('resources_to_change', numResourcesToChange);
core.setOutput('resources_to_delete', numResourcesToDelete);

let markdownSummary = summary;
if (resources_to_be_deleted.length > 0) {
    markdownSummary += `\nResources to be deleted:\n`
    resources_to_be_deleted.forEach(x => markdownSummary += `* ${x}\n`)
}

core.summary
    .addRaw(markdownSummary)
    .write()

if (fs.existsSync(settingsPath)) {
    const settings = JSON.parse(fs.readFileSync(settingsPath))
    logger.logKeyValuePair(`settings`, settings)
    if (settings.protectedResources) {
        logger.logAction(`checking protected resources are not been deleted`)

        const protectedResourcesToBeDeleted = []
        settings.protectedResources.forEach(x => {
            if (resources_to_be_deleted.some(y => y.includes(x))) {
                protectedResourcesToBeDeleted.push({
                    protectedKey: x,
                    resourcesMatching: resources_to_be_deleted.filter(y => y.includes(x))
                })
            }
        })

        if (protectedResourcesToBeDeleted.length > 0) {
            logger.logError("protected resources schedule to be deleted:")
            core.error("tf-plan: some protected resources are schedule to be deleted")
            protectedResourcesToBeDeleted.forEach(x => logger.logKeyValuePair(`resource`, x))
            process.exit(1)
        }
    }
}