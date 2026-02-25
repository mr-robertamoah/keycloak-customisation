<!DOCTYPE html>
<html lang="${locale.currentLanguageTag}">
<head>
  <meta charset="UTF-8" />
  <title>${msg("emailForgotTitle")}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="${resourcesPath}/css/styles.css" />
</head>
<body>
<div id="kc-container">

  <img class="brand-logo" src="${properties.logoUrl}" alt="${properties.brandName!realm.displayName}" />
  <h1 class="brand-title">Reset your password</h1>
  <p class="brand-subtitle">
    Enter your email and we&rsquo;ll send you a reset link.
  </p>

  <#if message?has_content>
    <div class="alert alert-${message.type}">
      ${kcSanitize(message.summary)?no_esc}
    </div>
  </#if>

  <form action="${url.loginAction}" method="post">
    <div class="form-group">
      <label for="username">
        <#if !realm.loginWithEmailAllowed>
          ${msg("username")}
        <#elseif !realm.registrationEmailAsUsername>
          ${msg("usernameOrEmail")}
        <#else>
          ${msg("email")}
        </#if>
      </label>
      <input
        type="text"
        id="username"
        name="username"
        class="form-control"
        autofocus
        value="${(auth.attemptedUsername!'')?html}"
      />
    </div>
    <input class="btn-primary" type="submit" value="${msg("doSubmit")}" />
  </form>

  <div class="kc-links">
    <a href="${url.loginUrl}">&larr; ${msg("backToLogin")}</a>
  </div>

</div>
</body>
</html>