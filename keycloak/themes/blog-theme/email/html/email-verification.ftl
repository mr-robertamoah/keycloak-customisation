<#--
  Keycloak injects:
    realmName       - realm display name
    user.firstName  - recipient's first name
    link            - the verification URL
    linkExpiration  - expiry in minutes
-->
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <!--[if mso]><xml><o:OfficeDocumentSettings><o:PixelsPerInch>96</o:PixelsPerInch></o:OfficeDocumentSettings></xml><![endif]-->
  <style>
    body { margin: 0; padding: 0; background-color: #F8FAFF; font-family: 'Helvetica Neue', Arial, sans-serif; }
    .email-wrapper { max-width: 600px; margin: 40px auto; }
    .email-header  { background: #EF4444; padding: 32px 40px; border-radius: 8px 8px 0 0; text-align: center; }
    .email-header h1 { color: #ffffff; font-size: 24px; margin: 0; }
    .email-body    { background: #FFFFFF; padding: 40px; border: 1px solid #E2E8F0; }
    .email-footer  { background: #FEE2E2; padding: 24px 40px; border-radius: 0 0 8px 8px; text-align: center;
                     font-size: 13px; color: #64748B; border: 1px solid #E2E8F0; border-top: 0; }
    .btn           { display: inline-block; padding: 14px 32px; background: #EF4444; color: #FFFFFF !important;
                     text-decoration: none; border-radius: 6px; font-weight: 600; font-size: 16px;
                     margin: 24px 0; }
    p              { color: #1E293B; line-height: 1.7; font-size: 15px; }
    .expiry-note   { background: #FEE2E2; border: 1px solid #FED7AA; border-radius: 6px;
                     padding: 12px 16px; color: #9A3412; font-size: 13px; margin-top: 16px; }
  </style>
</head>
<body>
  <div class="email-wrapper">

    <div class="email-header">
      <h1>🚀 The Blog</h1>
    </div>

    <div class="email-body">
      <p>Hi ${user.firstName!"there"},</p>

      <p>
        Welcome to <strong>${realmName}</strong>! We just need to verify your
        email address to activate your account.
      </p>

      <p style="text-align:center;">
        <a class="btn" href="${link}">Verify my email address</a>
      </p>

      <div class="expiry-note">
        ⏳ This link expires in
        <strong>${linkExpirationFormatter(linkExpiration)}</strong>.
        If you didn&rsquo;t create an account, you can safely ignore this email.
      </div>

      <p style="margin-top:24px;">
        If the button doesn&rsquo;t work, copy and paste this link into your browser:
      </p>
      <p style="word-break:break-all; font-size:13px; color:#3B82F6;">
        <a href="${link}">${link}</a>
      </p>
    </div>

    <div class="email-footer">
      &copy; ${.now?string("yyyy")} ${realmName}. All rights reserved.
    </div>

  </div>
</body>
</html>