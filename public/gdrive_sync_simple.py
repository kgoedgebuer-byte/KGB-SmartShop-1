# ~/Desktop/Oud_SmartShop/smartshoplist_v140/gdrive_sync_simple.py
# SmartShop - Google Drive synchronisatie (met extern JSON)
# Eerste keer: vraagt login, daarna automatisch sync

import os
import time
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = os.path.expanduser("~/Desktop/Oud_SmartShop/smartshoplist_v140/client_secret.json")
os.environ["GOOGLE_CLOUD_PROJECT"] = "KGB-SmartShop"


# Rechten beperken tot bestanden die de app zelf maakt
SCOPES = ['https://www.googleapis.com/auth/drive.file']

# Paden
BASE = os.path.expanduser('~/Desktop/Oud_SmartShop/smartshoplist_v140')
TOKEN_PATH = os.path.join(BASE, 'token.json')
DATA_FILE = os.path.join(BASE, 'sync_data.json')
CLIENT_FILE = os.path.join(BASE, 'client_secret.json')


def get_service():
    creds = None
    if os.path.exists(TOKEN_PATH):
        creds = Credentials.from_authorized_user_file(TOKEN_PATH, SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(CLIENT_FILE, SCOPES)
            creds = flow.run_local_server(port=0)
        with open(TOKEN_PATH, 'w') as token:
            token.write(creds.to_json())
    return build('drive', 'v3', credentials=creds)

def ensure_folder(service):
    res = service.files().list(
        q="name='KGB_SmartShop' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        fields="files(id)"
    ).execute()
    files = res.get('files', [])
    if files:
        return files[0]['id']
    meta = {'name': 'KGB_SmartShop', 'mimeType': 'application/vnd.google-apps.folder'}
    folder = service.files().create(body=meta, fields='id').execute()
    print("✅ Nieuwe map 'KGB_SmartShop' aangemaakt in Drive.")
    return folder['id']

def upload_loop(service, folder_id):
    print("☁️ Drive-sync actief — wijzigingen worden elke 10s geüpload.\n")
    last = 0
    while True:
        if os.path.exists(DATA_FILE):
            mtime = os.path.getmtime(DATA_FILE)
            if mtime != last:
                last = mtime
                name = os.path.basename(DATA_FILE)
                res = service.files().list(
                    q=f"name='{name}' and '{folder_id}' in parents and trashed=false",
                    fields="files(id)"
                ).execute()
                files = res.get('files', [])
                media = MediaFileUpload(DATA_FILE, mimetype='application/json', resumable=False)
                if files:
                    service.files().update(fileId=files[0]['id'], media_body=media).execute()
                else:
                    service.files().create(
                        body={'name': name, 'parents': [folder_id]},
                        media_body=media
                    ).execute()
                print(f"☁️ Back-up geüpload: {name}")
        time.sleep(10)

if __name__ == '__main__':
    try:
        svc = get_service()
        fid = ensure_folder(svc)
        upload_loop(svc, fid)
    except KeyboardInterrupt:
        print("⛔️ Drive-sync gestopt.")


