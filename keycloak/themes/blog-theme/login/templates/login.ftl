<#-- 
  login.ftl — custom login page for blog-theme
  Keycloak injects these variables into every login template:
    - url         : URLs object (loginAction, registrationUrl, etc.)
    - realm       : Realm config (name, registrationAllowed, rememberMe, etc.)
    - login       : Login state (username, rememberMe)
    - auth         : Social/identity provider links
    - registrationDisabled : boolean
    - messagesPerField     : per-field error helper
    - message              : top-level message object (type, summary)
    - properties           : all theme.properties values
-->
<!DOCTYPE html>
<html lang="${locale.currentLanguageTag}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${msg("loginTitle", realm.displayName)}</title>

  <#-- Load Google Fonts (optional — remove if offline) -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">

  <#-- Load our custom CSS via ${resourcesPath} which Keycloak resolves at runtime -->
  <link rel="stylesheet" href="${resourcesPath}/css/styles.css" />
</head>
<body>

<div id="kc-container">

  <#-- ── Brand header ── -->
  <img class="brand-logo"
       src="${properties.logoUrl}"
       alt="${properties.brandName!realm.displayName}" />
  <h1 class="brand-title">${properties.brandName!realm.displayName}</h1>
  <p class="brand-subtitle">${msg("loginTitleHtml", realm.displayName)}</p>

  <#-- ── Top-level alert messages ──
       message.type can be: error | warning | success | info              -->
  <#if message?has_content>
    <div class="alert alert-${message.type}">
      ${kcSanitize(message.summary)?no_esc}
    </div>
  </#if>

  <#-- ── Login form ── -->
  <form action="${url.loginAction}" method="post">

    <#-- Hidden field required by Keycloak for CSRF -->
    <input type="hidden" name="credentialId"
           value="<#if auth.selectedCredential?has_content>${auth.selectedCredential}</#if>" />

    <#-- Username / Email field -->
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
        class="form-control <#if messagesPerField.existsError('username','password')>error</#if>"
        value="${(login.username!'')?html}"
        autofocus
        autocomplete="username"
      />
      <#-- Per-field error for username -->
      <#if messagesPerField.existsError('username')>
        <div class="field-error">
          ${kcSanitize(messagesPerField.get('username'))?no_esc}
        </div>
      </#if>
    </div>

    <#-- Password field -->
    <div class="form-group">
      <label for="password">${msg("password")}</label>
      <input
        type="password"
        id="password"
        name="password"
        class="form-control <#if messagesPerField.existsError('username','password')>error</#if>"
        autocomplete="current-password"
      />
      <#if messagesPerField.existsError('password')>
        <div class="field-error">
          ${kcSanitize(messagesPerField.get('password'))?no_esc}
        </div>
      </#if>
    </div>

    <#-- Remember me + Forgot password row -->
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:1rem;">
      <#if realm.rememberMe && !usernameHidden??>
        <label class="checkbox-row">
          <input type="checkbox" name="rememberMe"
            <#if login.rememberMe??>checked</#if> />
          ${msg("rememberMe")}
        </label>
      <#else>
        <span></span>
      </#if>

      <#if realm.resetPasswordAllowed>
        <a href="${url.loginResetCredentialsUrl}" style="font-size:0.875rem; color:var(--brand-primary);">
          ${msg("doForgotPassword")}
        </a>
      </#if>
    </div>

    <#-- Submit button -->
    <input class="btn-primary" type="submit" value="${msg("doLogIn")}" />
  </form>

  <#-- ── Registration link ── -->
  <#if realm.password && realm.registrationAllowed && !registrationDisabled??>
    <div class="kc-links">
      ${msg("noAccount")} <a href="${url.registrationUrl}">${msg("doRegister")}</a>
    </div>
  </#if>

  <#-- ── Social / Identity Provider buttons ──
       Only rendered if the realm has any configured identity providers -->
  <#if auth.showSocialProviders()>
    <hr style="margin: 1.5rem 0; border-color: var(--brand-border);" />
    <p style="text-align:center; font-size:0.875rem; color:var(--brand-muted);">
      ${msg("identity-provider-login-label")}
    </p>
    <#list auth.providers as provider>
      <a href="${provider.loginUrl}"
         style="display:block; text-align:center; padding:0.6rem; margin-bottom:0.5rem;
                border:1.5px solid var(--brand-border); border-radius:var(--radius);
                text-decoration:none; color:var(--brand-text); font-size:0.9rem;">
        ${provider.displayName}
      </a>
    </#list>
  </#if>

</div><!-- /#kc-container -->

</body>
</html>