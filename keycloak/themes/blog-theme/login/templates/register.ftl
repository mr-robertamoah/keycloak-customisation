<#--
  register.ftl — Custom registration page
  Extra variables available on this page (on top of the login set):
    - register         : Object with form field values (firstName, lastName, email, username)
    - passwordRequired : boolean — whether password fields are shown
    - recaptchaRequired: boolean — whether reCAPTCHA is enabled
    - recaptchaSiteKey : string  — public reCAPTCHA key
-->
<!DOCTYPE html>
<html lang="${locale.currentLanguageTag}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${msg("registerTitle")}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="${resourcesPath}/css/styles.css" />
</head>
<body>

<div id="kc-container">

  <img class="brand-logo" src="${properties.logoUrl}" alt="${properties.brandName!realm.displayName}" />
  <h1 class="brand-title">Create your account</h1>
  <p class="brand-subtitle">Join ${properties.brandName!realm.displayName} today</p>

  <#if message?has_content>
    <div class="alert alert-${message.type}">
      ${kcSanitize(message.summary)?no_esc}
    </div>
  </#if>

  <#--
    The form action must point to url.registrationAction — never hardcode it.
    Keycloak signs this URL with a session code and CSRF token.
  -->
  <form action="${url.registrationAction}" method="post">

    <#-- Two-column row for names -->
    <div style="display:grid; grid-template-columns:1fr 1fr; gap:1rem;">

      <div class="form-group">
        <label for="firstName">${msg("firstName")}</label>
        <input
          type="text"
          id="firstName"
          name="firstName"
          class="form-control <#if messagesPerField.existsError('firstName')>error</#if>"
          value="${(register.formData.firstName!'')?html}"
          autocomplete="given-name"
        />
        <#if messagesPerField.existsError('firstName')>
          <div class="field-error">${kcSanitize(messagesPerField.get('firstName'))?no_esc}</div>
        </#if>
      </div>

      <div class="form-group">
        <label for="lastName">${msg("lastName")}</label>
        <input
          type="text"
          id="lastName"
          name="lastName"
          class="form-control <#if messagesPerField.existsError('lastName')>error</#if>"
          value="${(register.formData.lastName!'')?html}"
          autocomplete="family-name"
        />
        <#if messagesPerField.existsError('lastName')>
          <div class="field-error">${kcSanitize(messagesPerField.get('lastName'))?no_esc}</div>
        </#if>
      </div>

    </div>

    <#-- Email -->
    <div class="form-group">
      <label for="email">${msg("email")}</label>
      <input
        type="email"
        id="email"
        name="email"
        class="form-control <#if messagesPerField.existsError('email')>error</#if>"
        value="${(register.formData.email!'')?html}"
        autocomplete="email"
      />
      <#if messagesPerField.existsError('email')>
        <div class="field-error">${kcSanitize(messagesPerField.get('email'))?no_esc}</div>
      </#if>
    </div>

    <#-- Username (only shown if email-as-username is disabled) -->
    <#if !realm.registrationEmailAsUsername>
      <div class="form-group">
        <label for="username">${msg("username")}</label>
        <input
          type="text"
          id="username"
          name="username"
          class="form-control <#if messagesPerField.existsError('username')>error</#if>"
          value="${(register.formData.username!'')?html}"
          autocomplete="username"
        />
        <#if messagesPerField.existsError('username')>
          <div class="field-error">${kcSanitize(messagesPerField.get('username'))?no_esc}</div>
        </#if>
      </div>
    </#if>

    <#-- Password fields (only shown when passwordRequired is true) -->
    <#if passwordRequired??>
      <div class="form-group">
        <label for="password">${msg("password")}</label>
        <input
          type="password"
          id="password"
          name="password"
          class="form-control <#if messagesPerField.existsError('password','password-confirm')>error</#if>"
          autocomplete="new-password"
        />
        <#if messagesPerField.existsError('password')>
          <div class="field-error">${kcSanitize(messagesPerField.get('password'))?no_esc}</div>
        </#if>
      </div>

      <div class="form-group">
        <label for="password-confirm">${msg("passwordConfirm")}</label>
        <input
          type="password"
          id="password-confirm"
          name="password-confirm"
          class="form-control <#if messagesPerField.existsError('password-confirm')>error</#if>"
          autocomplete="new-password"
        />
        <#if messagesPerField.existsError('password-confirm')>
          <div class="field-error">${kcSanitize(messagesPerField.get('password-confirm'))?no_esc}</div>
        </#if>
      </div>
    </#if>

    <#-- reCAPTCHA — only rendered when enabled in realm settings -->
    <#if recaptchaRequired??>
      <div style="margin-bottom:1.25rem;">
        <div class="g-recaptcha" data-size="normal" data-sitekey="${recaptchaSiteKey}"></div>
      </div>
    </#if>

    <input class="btn-primary" type="submit" value="${msg("doRegister")}" />
  </form>

  <div class="kc-links">
    Already have an account? <a href="${url.loginUrl}">${msg("backToLogin")}</a>
  </div>

</div>

<#if recaptchaRequired??>
  <script src="https://www.google.com/recaptcha/api.js" async defer></script>
</#if>
</body>
</html>