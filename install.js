// ✅ KGB SmartShop install script (GitHub versie)
// Laatste update: automatische PWA-installatie + versiecontrole

let deferredPrompt;
const installButton = document.getElementById('installBtn');

// Controleer of service worker aanwezig is
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('service-worker.js')
    .then(() => console.log('✅ Service worker geregistreerd'))
    .catch(err => console.error('❌ Service worker fout:', err));
}

window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault();
  deferredPrompt = e;
  console.log('📱 Installatieprompt klaar');
  installButton.style.display = 'inline-block';
});

installButton.addEventListener('click', async () => {
  if (deferredPrompt) {
    deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;
    console.log(`Gebruikerkeuze: ${outcome}`);
    deferredPrompt = null;
    installButton.style.display = 'none';
  }
});

window.addEventListener('appinstalled', () => {
  console.log('✅ App geïnstalleerd');
  alert('KGB SmartShop is nu geïnstalleerd als app 🎉');
  installButton.style.display = 'none';
});

// 🔄 Versiecheck (optioneel)
fetch('manifest.json')
  .then(res => res.json())
  .then(data => console.log(`📦 Versie: ${data.version || '1.0.0'}`))
  .catch(() => {});
