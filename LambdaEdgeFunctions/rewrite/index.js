'use strict';

const RuleSet = require('./api/rules.js');

let ruleSet = new RuleSet();

module.exports.handler = (e, ctx, cb) => {
  var request = e.Records[0].cf.request;
  console.log('Request:');
  console.log(JSON.stringify(request));
  return ruleSet
    .loadRules(request)
    .then(() => {
      var res = ruleSet.applyRules(e).res
      if (res.uri !== undefined && res.uri.includes('?')) {
        // We split the string this way because the query string could contain 
        // multiple ? characters
        const [uri, ...qsArray] = res.uri.split('?');
        res.uri = uri;
        res.querystring = qsArray.join('?');
        console.log(`uri: ${res.uri} querystring: ${res.querystring}`);
      }
      else
        console.log(`uri: ${res.uri}`);
      console.log('Result:');
      console.log(JSON.stringify(res));
      cb(null, res);
    });
};