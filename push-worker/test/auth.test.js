import {test} from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/index.js';
const env={ALLOWED_ORIGIN:'https://horizon003.github.io',FIREBASE_PROJECT_ID:'pharmawhisper-debd2'};
test('unauthenticated sends stop before database or provider access',async()=>{
 const response=await worker.fetch(new Request('https://sender.invalid/send',{method:'POST',body:'{}'}),env);
 assert.equal(response.status,401);
});
test('cross-origin browser sends are rejected',async()=>{
 const response=await worker.fetch(new Request('https://sender.invalid/send',{method:'POST',headers:{Origin:'https://attacker.invalid'},body:'{}'}),env);
 assert.equal(response.status,403);
});
