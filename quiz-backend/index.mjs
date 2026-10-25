import {initializeApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';
import {onCall,HttpsError} from 'firebase-functions/v2/https';
import {QuizImportService,ImportError} from './import-service.mjs';

initializeApp();
const service=new QuizImportService(getFirestore(),{
  adminUids:(process.env.HYZEN_QUIZ_ADMIN_UIDS??'').split(',').map(v=>v.trim()).filter(Boolean),
});
const options={enforceAppCheck:true,maxInstances:1,memory:'256MiB',timeoutSeconds:60};
const invoke=method=>async request=>{
  try{return await service[method](request.auth,request.data);}
  catch(error){
    if(!(error instanceof ImportError))throw new HttpsError('internal','Import did not complete. Retry the same confirmation.');
    const code=error.code==='unauthenticated'?'unauthenticated':error.code==='permission_denied'?'permission-denied':error.code==='invalid_request'||error.code==='invalid_csv'?'invalid-argument':'failed-precondition';
    throw new HttpsError(code,error.code,error.details);
  }
};
// No automatic deployment/configuration is included. Empty admin list and missing
// server-only control/taxonomy documents deny all work. No student endpoint exists.
export const previewQuizCsv=onCall(options,invoke('preview'));
export const commitQuizCsv=onCall(options,invoke('commit'));
