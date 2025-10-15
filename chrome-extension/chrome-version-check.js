// Chrome version check utility
function getChromeVersion() {
  const raw = navigator.userAgent.match(/Chrom(e|ium)\/([0-9]+)\./);
  return raw ? parseInt(raw[2], 10) : false;
}

function isSidePanelSupported() {
  const version = getChromeVersion();
  return version && version >= 114 && !!chrome.sidePanel;
}

console.log('Chrome version:', getChromeVersion());
console.log('Side panel supported:', isSidePanelSupported());
