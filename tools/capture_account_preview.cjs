// Captures the actual Flutter source, using fixture-only auth/content adapters.
const {chromium} = require('playwright');
const fs = require('node:fs');
(async () => {
  const output = 'hyzen_flutter/qa/account-redesign';
  fs.mkdirSync(output, {recursive: true});
  const browser = await chromium.launch({headless: true, args: ['--no-sandbox']});
  const errors = [];
  const evidence = {revision: process.env.GITHUB_SHA, captures: [], navigation: []};
  const destinations = ['Home', 'Study', 'Office Workspace', 'Shop', 'Downloads'];
  for (const theme of ['light', 'dark']) {
    for (const [name, path, title, height] of [
      ['account', '/profile', 'Account', 1100],
      ['account-info', '/profile/info', 'Account info', 1400],
      ['settings', '/settings', 'Settings', 1600],
      ['office', '/pdf-studio', 'Office Workspace', 844],
      ['downloads', '/downloads', 'Downloads', 844],
      ['office-narrow', '/pdf-studio', 'Office Workspace', 800],
    ]) {
      const width = name.endsWith('narrow') ? 320 : 390;
      const page = await browser.newPage({viewport: {width, height}, deviceScaleFactor: 2,
        reducedMotion: name.endsWith('narrow') ? 'reduce' : 'no-preference'});
      page.on('pageerror', error => errors.push(String(error)));
      page.on('console', message => {
        if (/overflowed by|Unhandled Exception/.test(message.text())) errors.push(message.text());
      });
      await page.goto(`http://127.0.0.1:8080/pharm-d-with-hyzen/ui-review/?theme=${theme}#${path}`);
      await page.waitForSelector('flutter-view', {timeout: 90000});
      await page.waitForTimeout(3500);
      const enable = page.getByRole('button', {name: 'Enable accessibility'});
      if (await enable.count()) await enable.evaluate(button => button.click());
      await page.getByLabel(title, {exact: true}).first().waitFor({timeout: 30000});
      if (name.startsWith('office') || name === 'downloads') {
        // Verify all five actual accessible hit areas and their visual order.
        const bounds = [];
        for (const label of destinations) {
          const item = page.getByRole('button', {name: label, exact: true});
          if (await item.count() !== 1) throw Error(`${theme}/${name}: expected one ${label}`);
          const box = await item.boundingBox();
          if (!box || box.width < 48 || box.height < 48) throw Error(`Small target: ${label}`);
          bounds.push(box.x);
        }
        if (bounds.some((x, i) => i > 0 && x <= bounds[i - 1])) throw Error('Incorrect tab order');
      }
      const filename = `${theme}-${name}.png`;
      await page.screenshot({path: `${output}/${filename}`});
      evidence.captures.push({filename, theme, path, width, height});
      if (name === 'office') {
        for (const [label, route] of [['Study', '/study'], ['Downloads', '/downloads'],
          ['Office Workspace', '/pdf-studio'], ['Shop', '/shop'], ['Home', '/home']]) {
          await page.getByRole('button', {name: label, exact: true}).click();
          await page.waitForURL(url => url.hash === `#${route}`);
          evidence.navigation.push({theme, label, route, passed: true});
        }
      }
      await page.close();
    }
  }
  fs.writeFileSync(`${output}/browser-evidence.json`, JSON.stringify(evidence, null, 2));
  await browser.close();
  if (errors.length) throw new Error(errors.join('\n'));
})();
