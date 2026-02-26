<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('username','password') displayInfo=realm.password && realm.registrationAllowed && !registrationDisabled??; section>

  <#if section = "header">
    <img class="brand-logo" src="${properties.logoUrl}" alt="${properties.brandName!realm.displayName}" />
    <h1 class="brand-title">🚀 ${properties.brandName!realm.displayName}</h1>
    <p class="brand-subtitle">Secure Authentication Made Easy</p>
  
  <#elseif section = "form">
    <form id="kc-form-login" action="${url.loginAction}" method="post">
      <div class="form-group">
        <label for="username">
          <#if !realm.loginWithEmailAllowed>${msg("username")}
          <#elseif !realm.registrationEmailAsUsername>${msg("usernameOrEmail")}
          <#else>${msg("email")}</#if>
        </label>
        <input type="text" id="username" name="username" class="form-control" value="${(login.username!'')?html}" autofocus autocomplete="username" />
      </div>

      <div class="form-group">
        <label for="password">${msg("password")}</label>
        <input type="password" id="password" name="password" class="form-control" autocomplete="current-password" />
      </div>

      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:1rem;">
        <#if realm.rememberMe && !usernameHidden??>
          <label class="checkbox-row">
            <input type="checkbox" name="rememberMe" <#if login.rememberMe??>checked</#if> />
            ${msg("rememberMe")}
          </label>
        <#else>
          <span></span>
        </#if>
        <#if realm.resetPasswordAllowed>
          <a href="${url.loginResetCredentialsUrl}">${msg("doForgotPassword")}</a>
        </#if>
      </div>

      <input type="hidden" name="credentialId" value="<#if auth.selectedCredential?has_content>${auth.selectedCredential}</#if>" />
      <input class="btn-primary" type="submit" value="${msg("doLogIn")}" />
    </form>

  <#elseif section = "info">
    <#if realm.password && realm.registrationAllowed && !registrationDisabled??>
      <div class="kc-links">
        ${msg("noAccount")} <a href="${url.registrationUrl}">${msg("doRegister")}</a>
      </div>
    </#if>
  </#if>

</@layout.registrationLayout>
