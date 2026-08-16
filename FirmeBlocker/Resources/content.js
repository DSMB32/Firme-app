// Lista de sitios bloqueados por Firme
const blockedSites = [
    "pornhub.com",
    "xvideos.com",
    "xnxx.com",
    "xhamster.com",
    "redtube.com",
    "youporn.com",
    "tube8.com",
    "spankbang.com"
];

function checkAndBlock() {
    const hostname = window.location.hostname.replace("www.", "");
    const isBlocked = blockedSites.some(site => hostname.includes(site));

    if (isBlocked) {
        document.documentElement.innerHTML = `
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {
                        margin: 0;
                        font-family: -apple-system, sans-serif;
                        background: linear-gradient(160deg, #3E6E58, #6FA089);
                        min-height: 100vh;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        padding: 24px;
                        box-sizing: border-box;
                    }
                    .card {
                        background: white;
                        border-radius: 24px;
                        padding: 40px 28px;
                        text-align: center;
                        max-width: 380px;
                        box-shadow: 0 20px 40px rgba(0,0,0,0.2);
                    }
                    .emoji { font-size: 48px; margin-bottom: 16px; }
                    h1 { color: #2E3B36; font-size: 20px; margin-bottom: 12px; }
                    p { color: #8A968F; font-size: 14px; line-height: 1.5; margin-bottom: 24px; }
                    a {
                        display: block;
                        background: #3E6E58;
                        color: white;
                        text-decoration: none;
                        padding: 14px;
                        border-radius: 10px;
                        font-weight: 600;
                        font-size: 15px;
                    }
                </style>
            </head>
            <body>
                <div class="card">
                    <div class="emoji">🌱</div>
                    <h1>Este sitio está bloqueado</h1>
                    <p>Si sientes la urgencia, abre Firme y dale a Pausar antes de continuar.</p>
                    <a href="firme://pausa">Abrir Firme</a>
                </div>
            </body>
        `;
    }
}

checkAndBlock();
