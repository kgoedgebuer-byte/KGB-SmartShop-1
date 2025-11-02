let deferredPrompt;

window.addEventListener("beforeinstallprompt", e => {
  e.preventDefault();
  deferredPrompt = e;

  const installBtn = document.createElement("button");
  installBtn.textContent = "📲 Installeer KGB SmartShop";
  installBtn.style.position = "fixed";
  installBtn.style.bottom = "20px";
  installBtn.style.right = "20px";
  installBtn.style.zIndex = "1000";
  installBtn.style.background = "#007bff";
  installBtn.style.color = "white";
  installBtn.style.padding = "10px 16px";
  installBtn.style.border = "none";
  installBtn.style.borderRadius = "8px";
  installBtn.style.fontSize = "16px";
  installBtn.style.boxShadow = "0 2px 6px rgba(0,0,0,0.2)";
  installBtn.style.cursor = "pointer";
  document.body.appendChild(installBtn);

  installBtn.addEventListener("click", async () => {
    installBtn.disabled = true;
    deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;
    if (outcome === "accepted") {
      console.log("✅ App geïnstalleerd");
    } else {
      console.log("❌ Installatie geannuleerd");
    }
    deferredPrompt = null;
    installBtn.remove();
  });
});

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker.js").then(reg => {
    reg.addEventListener("updatefound", () => {
      const newWorker = reg.installing;
      newWorker.addEventListener("statechange", () => {
        if (newWorker.state === "installed" && navigator.serviceWorker.controller) {
          const updateBanner = document.createElement("div");
          updateBanner.textContent = "🔄 Nieuwe versie beschikbaar — klik om te vernieuwen";
          updateBanner.style.position = "fixed";
          updateBanner.style.bottom = "0";
          updateBanner.style.left = "0";
          updateBanner.style.width = "100%";
          updateBanner.style.background = "#ffc107";
          updateBanner.style.textAlign = "center";
          updateBanner.style.padding = "10px";
          updateBanner.style.cursor = "pointer";
          document.body.appendChild(updateBanner);
          updateBanner.onclick = () => window.location.reload();
        }
      });
    });
  });
}
