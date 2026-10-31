"""Download and reconstruct the CAM NESTING overview without extra packages."""
import hashlib,os,tempfile,urllib.request
from pathlib import Path
BASE='https://raw.githubusercontent.com/raevka190-lang/cam-/main/video/detailed/parts/'
EXPECTED='9d162c40d138666c540efeaee798e1e3eadfd659b931f0a0819799b45399799f'
def download(folder,fetch=None):
    folder=Path(folder)
    target=folder/'CAM_NESTING_Detailed_Overview.mp4'
    if target.exists():raise FileExistsError('The video already exists: '+str(target))
    fetch=fetch or (lambda url:urllib.request.urlopen(url,timeout=90).read())
    tmp=None
    try:
        with tempfile.NamedTemporaryFile('wb',dir=folder,delete=False,suffix='.partial') as f:
            tmp=Path(f.name);digest=hashlib.sha256()
            for index in range(1,15):
                print('Downloading',index,'/ 14',flush=True)
                data=fetch(BASE+f'overview.part{index:02}')
                if len(data)!=(3000000 if index<14 else 1587150):raise ValueError('Incomplete download')
                f.write(data);digest.update(data)
            f.flush();os.fsync(f.fileno())
        if digest.hexdigest()!=EXPECTED:raise ValueError('Video checksum mismatch')
        # Refuse to replace an existing video, including one created during download.
        with target.open('xb') as dst,tmp.open('rb') as src:
            import shutil
            try:shutil.copyfileobj(src,dst)
            except BaseException:dst.close();target.unlink(missing_ok=True);raise
        print('Saved:',target)
        return target
    finally:
        if tmp is not None:tmp.unlink(missing_ok=True)
if __name__=='__main__':
    try:download(Path(__file__).resolve().parent)
    except Exception as exc:print('Download failed:',exc)
    input('Press Enter to close...')
