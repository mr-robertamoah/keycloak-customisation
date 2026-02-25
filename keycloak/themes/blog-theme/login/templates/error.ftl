<!DOCTYPE html>
<html lang="${locale.currentLanguageTag}">
<head>
  <meta charset="UTF-8" />
  <title>${msg("errorTitle")}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="${resourcesPath}/css/styles.css" />
</head>
<body>
<div id="kc-container">
  <h1 class="brand-title" style="color:#EF4444;">${msg("errorTitle")}</h1>
  <div class="alert alert-error">${kcSanitize(message.summary)?no_esc}</div>
  <#if skipLink??>
    <p style="text-align:center;">
      <a href="${url.loginRestartFlowUrl}">Restart</a>
    </p>
  </#if>
</div>
</body>
</html>