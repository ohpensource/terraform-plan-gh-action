// docs for colours:
// https://stackoverflow.com/questions/9781218/how-to-change-node-jss-console-font-color

const logWarning = (action) => {
  const fontYellow = "\x1b[33m"
  const resetColour = "\x1b[0m"
  console.log(`${fontYellow}${action} ...${resetColour}`);
};

const logTitle = (action) => {
  const fontMagenta = "\x1b[35m"
  const resetColour = "\x1b[0m"
  console.log(``);
  console.log(`${fontMagenta}${action} ...${resetColour}`);
};

const logAction = (action) => {
  console.log(``);
  console.log(`${action} ...`);
};

const logKeyValuePair = (key, value) => {
  console.log(`    ${key}: ${JSON.stringify(value, null, 4)}`);
};

const logSucceed = (msg) => {
  const fontGreen = "\x1b[32m"
  const resetColour = "\x1b[0m"
  console.log(`${fontGreen}${msg}${resetColour}`);
};

const logError = (msg) => {
  const fontRed = "\x1b[41m"
  const resetColour = "\x1b[0m"
  console.log(`${fontRed}${msg}${resetColour}`);
};

module.exports = {
  logAction,
  logKeyValuePair,
  logSucceed,
  logError,
  logWarning,
  logTitle
};
