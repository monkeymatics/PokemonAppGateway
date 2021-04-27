"use strict";

const fs = require('fs');
const path = require("path");
const refs = require("refs");

const templates = ["api-specification", "cloud-formation"];
const buildDir = `${__dirname}/build-artifacts`;

if (!fs.existsSync(buildDir))
    fs.mkdirSync(buildDir);

try {
  templates.every(template => {
    let templateDir = `${__dirname}/${template}`;

    let inputTemplate = path.resolve(`${templateDir}/main.yaml`);
    let outputFile = path.resolve(`${buildDir}/${template}.yaml`);

    refs(inputTemplate, outputFile).then(results => {
      console.log(`\n  File written: ${results.outputFile}`);
    });
  });
} catch (ex) {
  console.error(ex.message);
  console.error(ex.stack);
}
