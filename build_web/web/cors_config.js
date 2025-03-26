window.flutterWebRenderer = "html";
window.addEventListener('load', function() {
    if (window.location.hostname === 'localhost') {
        // Configura CORS per lo sviluppo locale
        var meta = document.createElement('meta');
        meta.httpEquiv = "Content-Security-Policy";
        meta.content = "default-src * 'unsafe-inline' 'unsafe-eval'; connect-src * 'unsafe-inline'";
        document.head.appendChild(meta);
    }
});
