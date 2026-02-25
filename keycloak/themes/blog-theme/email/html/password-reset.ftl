<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <style>
    body { background:#F8FAFF; font-family:'Helvetica Neue',Arial,sans-serif; margin:0; padding:0; }
    .wrapper { max-width:600px; margin:40px auto; }
    .header  { background:#EF4444; padding:32px 40px; border-radius:8px 8px 0 0; text-align:center; }
    .header h1 { color:#fff; margin:0; font-size:24px; }
    .body    { background:#fff; padding:40px; border:1px solid #E2E8F0; }
    .footer  { background:#F1F5F9; padding:24px; text-align:center; font-size:13px;
               color:#64748B; border:1px solid #E2E8F0; border-top:0; border-radius:0 0 8px 8px; }
    .btn     { display:inline-block; padding:14px 32px; background:#EF4444; color:#fff !important;
               text-decoration:none; border-radius:6px; font-weight:600; margin:24px 0; }
    p        { color:#1E293B; line-height:1.7; font-size:15px; }
    .warning { background:#FEF2F2; border:1px solid #FECACA; border-radius:6px;
               padding:12px 16px; color:#B91C1C; font-size:13px; margin-top:16px; }
  </style>
</head>
<body>
<div class="wrapper">

  <div class="header">
    <h1>🔐 Password Reset</h1>
  </div>

  <div class="body">
    <p>Hi ${user.firstName!"there"},</p>

    <p>
      We received a request to reset the password for your
      <strong>${realmName}</strong> account.
    </p>

    <p style="text-align:center;">
      <a class="btn" href="${link}">Reset my password</a>
    </p>

    <div class="warning">
      ⚠️ This link expires in <strong>${linkExpirationFormatter(linkExpiration)}</strong>.
      If you didn&rsquo;t request a password reset, please ignore this email —
      your password will not change.
    </div>

    <p style="margin-top:24px; font-size:13px; color:#64748B;">
      Link not working? Copy and paste:<br/>
      <a href="${link}" style="color:#3B82F6; word-break:break-all;">${link}</a>
    </p>
  </div>

  <div class="footer">&copy; ${.now?string("yyyy")} ${realmName}</div>
</div>
</body>
</html>