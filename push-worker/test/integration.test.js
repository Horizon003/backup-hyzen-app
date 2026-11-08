import {test} from 'node:test';
import assert from 'node:assert/strict';
import {generateKeyPair,exportJWK,SignJWT} from 'jose';
import {fixture} from './sqlite.js';
import worker from '../src/index.js';

test('authenticated HTTP flow verifies tokens, roles, canonical membership and recipient inbox',async t=>{
  const {sql,db}=fixture();
  const {publicKey,privateKey}=await generateKeyPair('RS256');
  const jwk={...await exportJWK(publicKey),kid:'test-key',alg:'RS256',use:'sig'};
  const env={DB:db,FIREBASE_PROJECT_ID:'test-project',ADMIN_UID:'admin',
    ONESIGNAL_APP_ID:'test-app',ONESIGNAL_REST_API_KEY:'ephemeral-test-only',ALLOWED_ORIGIN:'https://horizon003.github.io'};
  let providerCalls=0,verified=true;
  const fields={verified:{booleanValue:true},academicYear:{integerValue:'1'},campusId:{stringValue:'college-a'},optOut:{booleanValue:false},alias:{stringValue:'Student'}};
  const doc=()=>({name:'projects/test-project/databases/(default)/documents/campusMemberships/student',fields:{...fields,verified:{booleanValue:verified}}});
  const originalFetch=globalThis.fetch;
  globalThis.fetch=async input=>{
    const url=String(input);
    if(url.startsWith('https://www.googleapis.com/'))return Response.json({keys:[jwk]});
    if(url.includes('/documents/campusMemberships?'))return Response.json({documents:[doc()]});
    if(url.endsWith('/documents/campusMemberships/student'))return Response.json(doc());
    if(url==='https://api.onesignal.com/notifications'){providerCalls++;return Response.json({id:'11111111-1111-4111-8111-111111111111',recipients:1});}
    throw Error(`Unexpected test request: ${url}`);
  };
  t.after(()=>{globalThis.fetch=originalFetch;sql.close();});
  async function token(uid,audience='test-project',expiry='1h') {
    return new SignJWT({auth_time:Math.floor(Date.now()/1000)-10}).setProtectedHeader({alg:'RS256',kid:'test-key'})
      .setIssuer('https://securetoken.google.com/test-project').setAudience(audience).setSubject(uid).setIssuedAt().setExpirationTime(expiry).sign(privateKey);
  }
  async function call(path,uid,body,override) {
    const jwt=override||await token(uid);
    return worker.fetch(new Request(`https://sender.invalid${path}`,{method:body?'POST':'GET',headers:{Authorization:`Bearer ${jwt}`,'Content-Type':'application/json'},...(body?{body:JSON.stringify(body)}:{})}),env);
  }
  await t.test('student cannot send; wrong-audience and expired JWTs fail before provider access',async()=>{
    assert.equal((await call('/send','student',{})).status,403);
    assert.equal((await call('/history','admin',null,await token('admin','other-project'))).status,401);
    assert.equal((await call('/history','admin',null,await token('admin','test-project',Math.floor(Date.now()/1000)-60))).status,401);
    assert.equal(providerCalls,0);
  });
  await t.test('client cannot choose its own professional year or continue after verification is withdrawn',async()=>{
    const session='a'.repeat(32);
    const response=await call('/studyPulse','student',{data:{session,action:'start',academicYear:5}});
    assert.equal(response.status,200);assert.equal(sql.prepare('SELECT academic_year FROM rank_leases').get().academic_year,1);
    verified=false;
    assert.equal((await call('/studyPulse','student',{data:{session,action:'heartbeat'}})).status,403);
    verified=true;
  });
  await t.test('admin send retry reuses provider ID; only server-selected recipients see inbox entry',async()=>{
    const message={id:'22222222-2222-4222-8222-222222222222',title:'Study update',body:'New study material',route:'/study',category:'material',target:'professional',year:1};
    const first=await call('/send','admin',message);assert.equal(first.status,200);
    assert.equal((await first.json()).state,'accepted');
    const retry=await call('/send','admin',message);assert.equal((await retry.json()).reused,true);assert.equal(providerCalls,1);
    assert.equal((await call('/send','admin',{...message,title:'Different'})).status,409);
    assert.equal((await (await call('/inbox','student')).json()).items.length,1);
    assert.equal((await (await call('/inbox','other-account')).json()).items.length,0);
    assert.equal((await (await call(`/inbox/${message.id}`,'student')).json()).items.length,1);
    assert.equal((await (await call(`/inbox/${message.id}`,'other-account')).json()).items.length,0);
    assert.equal(sql.prepare('SELECT state FROM messages').get().state,'accepted');
  });
});
