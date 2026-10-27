"""Read-only paired network benchmark. Never writes to academic Drive files."""
import argparse
import json
import os
import time
import urllib.request
import urllib.error
from pathlib import Path

IDS = ['15VBPzYX1RR5P2OrRSIqugg60oGjAp2j1', '1CirF5vwLaUDK77YaxlCpNLaIxtQYrFkZ', '1a-QB7oOZy7peCpaCjqXWPIOAD3kk1hVU']

def measure(label, url, headers):
    start = time.perf_counter()
    result = {'method': label}
    try:
        request = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(request, timeout=25) as response:
            result.update(status=response.status, ttfb_ms=round((time.perf_counter()-start)*1000), bytes=0)
            result['content_type'] = response.headers.get('Content-Type')
            result['content_range'] = response.headers.get('Content-Range')
            while True:
                data=response.read(65536)
                if not data: break
                if result['bytes'] == 0: result['pdf_signature'] = data.startswith(b'%PDF-')
                result['bytes']+=len(data)
                if result['bytes'] > 100*1024*1024 or time.perf_counter()-start>35:
                    result['truncated_for_benchmark']=True
                    break
    except urllib.error.HTTPError as error:
        result.update(status=error.code,error='HTTP request rejected')
    except Exception as error:
        result.update(error=type(error).__name__)
    result['elapsed_ms']=round((time.perf_counter()-start)*1000)
    return result

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--output',default='qa/drive_benchmark_results.json')
    args=parser.parse_args()
    key=os.environ.get('HYZEN_DRIVE_API_KEY','')
    bearer=os.environ.get('HYZEN_DRIVE_BENCHMARK_TOKEN','')
    headers={'Accept-Encoding':'identity'}
    if bearer: headers['Authorization']='Bearer '+bearer
    result={'has_configured_api_key':bool(key),'has_authorized_account':bool(bearer),'first_page_render':'not measured by HTTP benchmark','files':[]}
    for file_id in IDS:
        api=f'https://www.googleapis.com/drive/v3/files/{file_id}?alt=media'
        if key: api+='&key='+key
        result['files'].append({'file_id':file_id,'measurements':[
            measure('old_preview_html',f'https://drive.google.com/file/d/{file_id}/preview',{}),
            measure('old_full_download',f'https://drive.usercontent.google.com/download?id={file_id}&export=download&confirm=t',{}),
            measure('api_first_64k',api,{**headers,'Range':'bytes=0-65535'}),
            measure('api_full_download',api,headers),
        ]})
    Path(args.output).parent.mkdir(parents=True,exist_ok=True)
    Path(args.output).write_text(json.dumps(result,indent=2))
    print(json.dumps(result,indent=2))

if __name__=='__main__': main()
