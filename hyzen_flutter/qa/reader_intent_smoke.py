"""Exercise the installed release's document UI through Android accessibility.
Run only after native tests have created external_fixture.pdf in the emulator.
"""
import re
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path


def adb(*args):
    return subprocess.check_output(['adb', *map(str, args)], text=True)


def snapshot(name):
    adb('shell', 'uiautomator', 'dump', '/sdcard/hyzen-reader.xml')
    adb('pull', '/sdcard/hyzen-reader.xml', name + '.xml')
    return ET.parse(name + '.xml').getroot()


def label(node):
    return node.get('content-desc', '') or node.get('text', '')


def find(root, text):
    exact = [n for n in root.iter('node') if label(n) == text]
    matches = exact or [n for n in root.iter('node') if text in label(n)]
    assert matches, f'Missing accessible action: {text}'
    return matches[-1]


def tap(node):
    x1, y1, x2, y2 = map(int, re.findall(r'\d+', node.attrib['bounds']))
    adb('shell', 'input', 'tap', (x1+x2)//2, (y1+y2)//2)
    time.sleep(.5)


root = snapshot('reader-visible')
find(root, 'external_fixture.pdf')
size = list(map(int, re.findall(r'\d+', adb('shell', 'wm', 'size'))))[-2:]
adb('shell', 'input', 'tap', size[0]//2, size[1]//2)
time.sleep(.5)
root = snapshot('reader-hidden')
assert not any('external_fixture.pdf' in label(n) for n in root.iter('node')), 'Header did not hide'
adb('shell', 'screencap', '-p', '/sdcard/reader-hidden.png')
adb('pull', '/sdcard/reader-hidden.png', 'reader-hidden.png')
adb('shell', 'input', 'tap', size[0]//2, size[1]//2)
time.sleep(.5)
root = snapshot('reader-restored')
find(root, 'external_fixture.pdf')
tap(find(root, 'File options'))
root = snapshot('reader-options')
tap(find(root, 'Save copy & enable tools'))
time.sleep(3)
root = snapshot('reader-saved')
tap(find(root, 'File options'))
root = snapshot('reader-saved-options')
find(root, 'Edit / highlight')
assert not any('Save copy & enable tools' in label(n) for n in root.iter('node'))
adb('shell', 'input', 'keyevent', '4')
adb('shell', 'am', 'start', '-W', '-n', 'com.hyzen.pharmd/.MainActivity',
    '-a', 'android.intent.action.VIEW', '-t', 'application/pdf', '-d',
    'content://com.hyzen.pharmd.updates/shares/external_fixture.pdf')
time.sleep(4)
root = snapshot('reader-reopened')
tap(find(root, 'File options'))
root = snapshot('reader-reopened-options')
find(root, 'Edit / highlight')
assert not any('Save copy & enable tools' in label(n) for n in root.iter('node')), 'Saved copy link was lost'
Path('reader-ui-result.txt').write_text('PASS: tap-to-hide header, restore, Save copy, editing tools and same-file reopen\n')
print('PASS: installed release document UI and saved-copy reopening')
