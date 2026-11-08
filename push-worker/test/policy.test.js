import {test} from 'node:test';
import assert from 'node:assert/strict';
import {validateMessage,selectRecipients} from '../src/policy.js';
const message={id:'0a2f1661-fd43-4a69-9cb8-6c82c28be666',title:'Study material',body:'New notes are available.',route:'/study',category:'material',target:'all'};
test('validated audiences are selected only from server verified records',()=>{
 const users=[{uid:'a',verified:true,academicYear:1,campusId:'one'},{uid:'b',verified:true,academicYear:1,campusId:'two'},{uid:'c',verified:true,academicYear:2,campusId:'one'},{uid:'d',verified:false,academicYear:1,campusId:'one'}];
 assert.deepEqual(selectRecipients(users,{...message,target:'professional',year:1}),['a','b']);
 assert.deepEqual(selectRecipients(users,{...message,target:'college',college:'one'}),['a','c']);
});
test('unsafe routes, unbounded messages and unsupported schedules are rejected',()=>{
 assert.throws(()=>validateMessage({...message,route:'https://attacker.invalid'}));
 assert.throws(()=>validateMessage({...message,body:'x'.repeat(1001)}));
 assert.throws(()=>validateMessage({...message,sendAt:'tomorrow'}));
 assert.throws(()=>validateMessage({...message,target:'professional',year:6}));
 assert.equal(validateMessage(message).target,'all');
});
test('opt-out and duplicate profile rows cannot expand the audience',()=>{
 assert.deepEqual(selectRecipients([{uid:'a',verified:true},{uid:'a',verified:true},{uid:'b',verified:true,pushOptOut:true}],message),['a']);
});
