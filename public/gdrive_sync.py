# ~/Desktop/Oud_SmartShop/smartshoplist_v140/gdrive_sync.py
"""
Google Drive synchronisatie voor SmartShop.
Uploadt automatisch sync_data.json naar je Drive-map 'KGB_SmartShop'.
Eerste keer vraagt om autorisatie in browser.
"""

import os, pickle, time, json
from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

SCOPES = ["https://www.googleapis.com/auth/drive.file"]
CRED_FILE = os.path.expanduser("~/Desktop/Oud_SmartShop/smartshoplist_v140/credentials.json")
TOKEN_FILE = os.path.expanduser("~/Desktop/Oud_SmartShop/smartshoplist_v140/token.pickle")
DATA_FILE = os.path.expanduser("~/Desktop/Oud_SmartShop/smartshoplist_v140/sync_data.json")

def auth():
    creds = None
    if os.path.exists(TOKEN_FILE):
        with open(TOKEN_FILE, "rb") as t: creds = pickle.load(t)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(CRED_FILE, SCOPES)
            creds = flow.run_local_server(port=0)
        with open(TOKEN_FILE, "wb") as t: pickle.dump(creds, t)
    return creds

def ensure_folder(service):
    results = service.files().list(q="name='KGB_SmartShop' and mimeType='application/vnd.google-apps.folder' and trashed=false", fields="files(id)").execute()
    files = results.get("files", [])
    if files: return files[0]["id"]
    file_metadata = {"name": "KGB_SmartShop", "mimeType": "application/vnd.google-apps.folder"}
    folder = service.files().create(body=file_metadata, fields="id").execute()
    return folder["id"]

def upload_loop():
    creds = auth()
    service = build("drive", "v3", credentials=creds)
    folder_id = ensure_folder(service)
    last = None
    print("Drive-sync actief → map: 'KGB_SmartShop'")
    while True:
        if os.path.exists(DATA_FILE):
            mtime = os.path.getmtime(DATA_FILE)
            if last != mtime:
                last = mtime
                file_name = os.path.basename(DATA_FILE)
                print("Upload:", file_name)
                # Bestaat er al een file?
                results = service.files().list(q=f"name='{file_name}' and '{folder_id}' in parents and trashed=false", fields="files(id)").execute()
                files = results.get("files", [])
                media = MediaFileUpload(DATA_FILE, mimetype="application/json", resumable=False)
                if files:
                    service.files().update(fileId=files[0]["id"], media_body=media).execute()
                else:
                    service.files().create(body={"name": file_name, "parents": [folder_id]}, media_body=media).execute()
        time.sleep(10)

if __name__ == "__main__":
    try:
        upload_loop()
    except KeyboardInterrupt:
        print("Drive-sync gestopt.")
