// Run against the Flutter web output, never an HTML recreation of its screens.
const {chromium} = require('playwright');
const fs = require('node:fs');
(async () => {
  fs.mkdirSync('hyzen_flutter/qa/account-redesign', {recursive: true});
  const browser = await chromium.launch({headless: true, args: ['--no-sandbox']});
  const errors = [];
  const page = await browser.newPage({viewport: {width: 390, height: 1400}, deviceScaleFactor: 2});
  page.on('pageerror', error => errors.push(String(error)));
  for (const [name, path] of [['account', '/profile'], ['account-info', '/profile/info'], ['settings', '/settings']]) {
    await page.goto(`http://127.0.0.1:8080/pharm-d-with-hyzen/ui-review/#${path}`);
    await page.waitForSelector('flutter-view', {timeout: 90000});
    await page.waitForTimeout(5000);
    // Ask Flutter to expose semantics so the test verifies the requested screen
    // actually rendered before saving a canvas screenshot.
    const enable = page.getByRole('button', {name: 'Enable accessibility'});
    if (await enable.count()) await enable.evaluate(button => button.click());
    const title = name === 'account-info' ? 'Account info' : name === 'account' ? 'Account' : 'Settings';
    await page.getByLabel(title, {exact: true}).first().waitFor({timeout: 30000});
    await page.screenshot({path: `hyzen_flutter/qa/account-redesign/${name}.png`});
  }
  await browser.close();
  if (errors.length) throw new Error(errors.join('\n'));
})();
